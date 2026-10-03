-- Hooked! Silent Aim + Movement
-- by iwakewar team
-- Fluent GUI 1:1 with BFNFR Auto-Play (same flags/settings structure).
--
-- Reversing notes (client authoritative):
--   Hook hit = client OverlapParams GetPartsInPart on workspace Part "HookHitbox_Local"
--   size = HookConfig.HITBOX_SIZE (4,4,4) * hookScale * HookAssist.GetHitboxScale()
--   HookFire FireServer {hookId,batchId,startPosition=HRP+dir*2,direction(XZ unit),distance=80,...}
--   HookHit FireServer {hookId,targetPlayer(RemoteRef),targetPartName}
--   server tolerances: HIT_POSITION 40 / FIRE_POSITION 10
--   WalkSpeed overwritten every Stepped from Buff Speed (=18); TeleportReport/AnchoredReport/MoveDistance via TEvent.FireRemote

local plr = game.Players.LocalPlayer
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local function loadGUI()
    local src
    local ok, read = pcall(readfile, "_iwakewar_gui.lua")
    if ok and read and #read > 1000 then
        src = read
    else
        src = game:HttpGet("https://raw.githubusercontent.com/iww-dev/iwakewar-scripts/refs/heads/main/gui-lib/iwakewar-gui.luau", true)
    end
    if not src or #src < 1000 then
        error("iwakewar-gui source could not be loaded")
    end
    return (loadstring(src))()
end

local GUI = loadGUI()
-- reload-safe: kill previous Fluent window so toggles don't double
pcall(function()
    local g0 = getgenv and getgenv() or {}
    if g0.__hookedFluent and type(g0.__hookedFluent.Destroy) == "function" then
        g0.__hookedFluent:Destroy()
    end
end)
if getgenv then
    getgenv().__hookedFluent = GUI
end
local genv0 = getgenv and getgenv() or {}
genv0.__hookedGen = (genv0.__hookedGen or 0) + 1
local myGen = genv0.__hookedGen

local isPhone = UIS.TouchEnabled and not UIS.KeyboardEnabled
pcall(function() GUI:SetLang("ru") end)
local Window = GUI:CreateWindow({
    Title = "Hooked",
    SubTitle = "by iwakewar team",
    TabWidth = 150,
    Size = UDim2.fromOffset(640, 460),
    ToggleKey = Enum.KeyCode.RightAlt,
})
GUI._selfUrl = "https://raw.githubusercontent.com/iww-dev/iwakewar-scripts/refs/heads/main/Hooked.luau"
local Tabs = {
    Info = Window:AddTab({ Title = "Info", Icon = "badge-check" }),
    Main = Window:AddTab({ Title = "Controls", Icon = "gamepad-2" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
}
local Options = GUI.Options
Window:SelectTab(1)

-- Settings: пока только язык, по умолчанию русский
Tabs.Settings:AddDropdown("Lang", {
  Title = "Language / Язык",
  Values = { "Русский", "English" },
  Default = "Русский",
  Callback = function(v)
    pcall(function()
      if v == "English" then GUI:SetLang("en") else GUI:SetLang("ru") end
    end)
  end,
})
-- mobile floating toggle is built into iwakewar-gui, nothing to do here

-- engine state
local hitboxMult = 3.0
local maxDist = 80
local targetPart = "HumanoidRootPart"
local targetMode = "Nearest"
local infJump = false
local speedOn = false
local speedMult = 1.25
local noNotifications = false
-- RAGE: один тогл на всё (длина 200 / полёт 500 / подтяжка 240, кд 1.2, без мульти)
local rage = true
local rageCooldown = 1.2
local origCooldown = nil
-- AUTOKILL: висим якорем под спавном врагов, жертвы стекаются к нам вниз
local autokill = false
local killDepth = -5
local savedGravity = nil
local killTarget = nil
local currentTarget = nil
local baseSpeed = 18

local function clampNum(v: number, a: number, b: number): number
    if typeof(v) ~= "number" then return a end
    if v < a then return a elseif v > b then return b end
    return v
end

local function copyToClipboard(text: string): boolean
    local funcs = { setclipboard, toclipboard }
    local genv = getgenv and getgenv() or {}
    for _, name in ipairs({ "writeclipboard", "clipboard", "setclipboard", "toclipboard" }) do
        local v = genv[name]
        if v == nil then
            v = rawget(_G, name)
        end
        if typeof(v) == "function" then
            funcs[#funcs + 1] = v
        end
    end
    for _, fn in ipairs(funcs) do
        if typeof(fn) == "function" then
            local ok = pcall(fn, text)
            if ok then return true end
        end
    end
    return false
end

-- game modules (lazy, tolerate lobby without hook modules loaded yet)
local TargetDirection, HookAssist, TEventMod, BuffMod, BuffObj
local PlayerEntityMod, BotEntityMod, HookStatsMod, HookCollisionMod, HookTransitionMod
local origGetHookDir, origGetDir, origHitboxScale, origFireRemote, origCompute, origUpdatePos

local function resolveModules()
    pcall(function()
        if not TargetDirection then
            TargetDirection = require(RS.Client.Core.TargetDirection)
            if TargetDirection and not origGetHookDir then
                origGetHookDir = TargetDirection.GetHookDirection
                origGetDir = TargetDirection.GetDirection
            end
        end
    end)
    pcall(function()
        if not HookAssist then
            HookAssist = require(RS.Client.System.Hook.HookAssist)
            if HookAssist and not origHitboxScale then
                origHitboxScale = HookAssist.GetHitboxScale
            end
        end
    end)
    pcall(function()
        if not TEventMod then
            TEventMod = require(RS.Shared.Core.TEvent)
            if TEventMod and not origFireRemote then
                origFireRemote = TEventMod.FireRemote
                TEventMod.FireRemote = function(name, ...)
                    if (rage or speedOn) and (name == "TeleportReport" or name == "AnchoredReport" or name == "MoveDistance") then
                        return
                    end
                    return origFireRemote(name, ...)
                end
            end
        end
    end)
    pcall(function()
        if not PlayerEntityMod then
            PlayerEntityMod = require(RS.Client.System.Hook.Entity.PlayerEntity)
        end
        if not BotEntityMod then
            BotEntityMod = require(RS.Client.System.Hook.Entity.BotEntity)
        end
    end)
    pcall(function()
        if not HookStatsMod then
            HookStatsMod = require(RS.Shared.Features.HookStats)
            if HookStatsMod and not origCompute then
                origCompute = HookStatsMod.Compute
            end
        end
        if not HookCollisionMod then
            HookCollisionMod = require(RS.Client.System.Hook.Core.HookCollision)
            if HookCollisionMod and not origUpdatePos then
                origUpdatePos = HookCollisionMod.UpdatePosition
            end
        end
        if not HookTransitionMod then
            local ok, mod = pcall(require, RS.Client.Core.PlayerFSM.Transitions.HookTransition)
            if ok and mod then HookTransitionMod = mod end
        end
    end)
    pcall(function()
        if not BuffMod then
            BuffMod = require(RS.Shared.Features.Buff)
            BuffObj = BuffMod.Get and BuffMod.Get()
            if BuffObj then
                local ok, v = pcall(function() return BuffObj:GetTypeValue("Speed") end)
                if ok and typeof(v) == "number" and v > 0 then
                    baseSpeed = v
                end
                if not BuffObj.__hookedSpeed then
                    BuffObj.__hookedSpeed = true
                    local orig = BuffObj.GetTypeValue
                    BuffObj.GetTypeValue = function(self, t, ...)
                        if t == "Speed" and speedOn then
                            return baseSpeed * speedMult
                        end
                        return orig(self, t, ...)
                    end
                end
            end
        end
    end)
end
resolveModules()

local function myChar() return LP.Character end
local function myHRP()
    local c = myChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function myHum()
    local c = myChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function isAliveChar(m)
    local h = m and m:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

-- точка AutoKill: под спавном врагов на глубине killDepth (дефолт -5).
-- спавн ищем по цвету команды, иначе ближайший спавн к врагу, иначе под ближайшим врагом
local function enemyKillPos(): Vector3?
    local myT = LP.Team
    local enemies: { Instance } = {}
    for _, t in ipairs(game:GetService("Teams"):GetChildren()) do
        if t ~= myT and t.Name ~= "Lobby" then
            for _, p in ipairs(t:GetPlayers()) do
                if p ~= LP then
                    table.insert(enemies, p)
                end
            end
        end
    end
    if #enemies == 0 then return nil end
    local spawns: { Instance } = {}
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("SpawnLocation") and d.Enabled ~= false then
            table.insert(spawns, d)
        end
    end
    local seen: { Instance } = {}
    for _, p in ipairs(enemies) do
        local t = p.Team
        if t and seen[t] == nil then
            seen[t] = t
            for _, s in ipairs(spawns) do
                local ok, bc = pcall(function() return (s :: SpawnLocation).BrickColor end)
                if ok and bc == t.TeamColor then
                    local sp = (s :: BasePart).Position
                    return Vector3.new(sp.X, killDepth, sp.Z)
                end
            end
        end
    end
    -- фолбэк: спавн ближайший к любому врагу
    local best: Vector3? = nil
    local bestD = math.huge
    for _, p in ipairs(enemies) do
        local c = p.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, s in ipairs(spawns) do
                local d = ((s :: BasePart).Position - hrp.Position).Magnitude
                if d < bestD then
                    bestD = d
                    local sp = (s :: BasePart).Position
                    best = Vector3.new(sp.X, killDepth, sp.Z)
                end
            end
        end
    end
    if best then return best end
    -- последний шанс: прямо под ближайшим врагом
    local me = myHRP()
    local bp: Vector3? = nil
    local bd = math.huge
    for _, p in ipairs(enemies) do
        local c = p.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        if hrp and isAliveChar(c) then
            local d = me and (hrp.Position - me.Position).Magnitude or 0
            if d < bd then
                bd = d
                bp = hrp.Position
            end
        end
    end
    if bp then return Vector3.new(bp.X, killDepth, bp.Z) end
    return nil
end

local function setAutoKill(on: boolean)
    autokill = on
    if autokill then
        if not Options.Rage.Value then
            Options.Rage:SetValue(true)
        end
        if savedGravity == nil then
            savedGravity = workspace.Gravity
        end
        pcall(function() workspace.Gravity = 0 end)
        killTarget = enemyKillPos()
        notify("Hooked", killTarget and "AutoKill: висим под спавном врагов" or "AutoKill: врагов не видно, жду цель", 3)
    else
        if savedGravity ~= nil then
            pcall(function() workspace.Gravity = savedGravity end)
            savedGravity = nil
        end
        local hrp = myHRP()
        if hrp then
            pcall(function() hrp.Anchored = false end)
        end
        killTarget = nil
        notify("Hooked", "AutoKill disabled", 2)
    end
end

local function myTeam()
    local ok, ent = pcall(function()
        return PlayerEntityMod and PlayerEntityMod.new(LP)
    end)
    if ok and ent then
        local ok2, t = pcall(function() return ent:GetTeam() end)
        if ok2 then return t end
    end
    return LP.Team
end

local function sameTeamPlayer(p): boolean
    local mine = myTeam()
    -- 1) обычное сравнение команд роблокса
    if p.Team and LP.Team and p.Team == LP.Team then return true end
    -- 2) игровое сравнение через PlayerEntity (как делает сама игра)
    if PlayerEntityMod then
        local ok, isMate = pcall(function()
            local me = PlayerEntityMod.new(LP)
            local other = PlayerEntityMod.new(p)
            local t1 = me:GetTeam()
            local t2 = other:GetTeam()
            return t1 and t2 and t1 == t2
        end)
        if ok and isMate then return true end
    end
    return false
end

local function sameTeamBot(m): boolean
    if not BotEntityMod then return false end
    local ok, isMate = pcall(function()
        local me = PlayerEntityMod and PlayerEntityMod.new(LP)
        local bot = BotEntityMod.new(m)
        local t1 = me and me:GetTeam()
        local t2 = bot:GetTeam()
        return t1 and t2 and t1 == t2
    end)
    if ok and isMate then return true end
    return false
end

local function collectTargets()
    local out = {}
    local me = myHRP()
    if not me then return out end
    local myPos = me.Position
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local part = p.Character:FindFirstChild(targetPart)
            if hrp and part and isAliveChar(p.Character) then
                if p.Character:FindFirstChildOfClass("ForceField") then continue end
                if sameTeamPlayer(p) then continue end
                local d = (hrp.Position - myPos).Magnitude
                if d <= maxDist then
                    table.insert(out, { pos = part.Position, hrp = hrp, dist = d, name = p.Name })
                end
            end
        end
    end
    for _, m in ipairs(workspace:GetDescendants()) do
        if m:IsA("Model") and m:GetAttribute("IsBot") == true then
            if m == myChar() then continue end
            if Players:GetPlayerFromCharacter(m) then continue end
            if sameTeamBot(m) then continue end
            local hrp = m:FindFirstChild("HumanoidRootPart")
            local part = m:FindFirstChild(targetPart) or hrp
            if hrp and part and isAliveChar(m) then
                local d = (hrp.Position - myPos).Magnitude
                if d <= maxDist then
                    table.insert(out, { pos = part.Position, hrp = hrp, dist = d, name = m.Name })
                end
            end
        end
    end
    table.sort(out, function(a, b) return a.dist < b.dist end)
    return out
end

local function pickTargetEntry(list)
    if #list == 0 then return nil end
    if targetMode == "Random" then
        return list[math.random(1, #list)]
    end
    return list[1] -- Nearest (список уже отсортирован по дистанции)
end

local function aimDirection()
    local me = myHRP()
    if not me then return nil end
    currentTarget = pickTargetEntry(collectTargets())
    if not currentTarget then return nil end
    local v = currentTarget.pos - me.Position
    local flat = Vector3.new(v.X, 0, v.Z)
    if flat.Magnitude < 0.001 then return nil end
    return flat.Unit
end

local function applyPatches()
    resolveModules()
    if HookAssist and origHitboxScale then        HookAssist.GetHitboxScale = function()
            if rage then
                return hitboxMult
            end
            return origHitboxScale()
        end
    end
    if TargetDirection and origGetHookDir then
        TargetDirection.GetHookDirection = function(...)
            if rage then
                local d = aimDirection()
                if d then return d end
            end
            return origGetHookDir(...)
        end
        TargetDirection.GetDirection = function(...)
            if rage then
                local d = aimDirection()
                if d then return d end
            end
            return origGetDir(...)
        end
    end
    -- RAGE stats: единая точка всех статов хука (в пределах легитимных капов 200/500/240/3)
    if HookStatsMod and origCompute then
        HookStatsMod.Compute = function(...)
            local r = origCompute(...)
            if rage and type(r) == "table" then
                r.hookLength = 200
                r.hookFlySpeed = 500
                r.hookBackSpeed = 240
                r.hookScale = 3
                r.hookCooldown = rageCooldown
            end
            return r
        end
    end
    -- Инстант-хит: подмена UpdatePosition — хитбокс оказывается на враге ДО
    -- CheckOverlap в том же кадре (старый PreRender-костыль этим и проигрывал:
    -- хук перезаписывал позицию после нас).
    if HookCollisionMod and origUpdatePos then
        HookCollisionMod.UpdatePosition = function(a1, a2)
            if rage and currentTarget then
                local tp = currentTarget.hrp
                if tp and tp.Parent then
                    if a1._hitbox then
                        local want = 4 * hitboxMult
                        pcall(function()
                            if a1._hitbox.Size.X < want then
                                a1._hitbox.Size = Vector3.new(want, want, want)
                            end
                        end)
                    end
                    return origUpdatePos(a1, tp.Position)
                end
            end
            return origUpdatePos(a1, a2)
        end
    end
    if HookTransitionMod and HookTransitionMod.SetCooldown then
        pcall(function()
            if HookTransitionMod.GetCooldown and origCooldown == nil then
                origCooldown = HookTransitionMod.GetCooldown()
            end
            if rage then
                HookTransitionMod.SetCooldown(rageCooldown)
            elseif origCooldown then
                HookTransitionMod.SetCooldown(origCooldown)
            end
        end)
    end
end
applyPatches()

-- GUI elements
local MainSection = Tabs.Main:AddSection("Main Functions")

local Status = Tabs.Main:AddParagraph({
    Title = "Status",
    Content = "Idle — join a match to test hits.",
})
local Live = Tabs.Main:AddParagraph({
    Title = "Live",
    Content = "aim: OFF • target: - • speed: 18",
})

local function notify(title: string, content: string, duration: number)
    if noNotifications then return end
    GUI:Notify({
        Title = title,
        Content = content,
        Duration = duration,
    })
end

MainSection:AddToggle("Rage", {
    Title = "RAGE",
    Description = "Aim + direction + move hook + team check + no reports + 200/500/240 + CD 1.2",
    Default = true,
    Callback = function(state)
        rage = state
        if not rage then
            currentTarget = nil
        end
        applyPatches()
        notify("Hooked", rage and "RAGE enabled" or "RAGE disabled", 2)
    end,
})

MainSection:AddToggle("InfJump", {
    Title = "InfJump",
    Description = "Jump in air via JumpRequest",
    Default = false,
    Callback = function(state)
        infJump = state
        notify("Hooked", infJump and "InfJump enabled" or "InfJump disabled", 2)
    end,
})

MainSection:AddToggle("Speedhack", {
    Title = "Speedhack",
    Description = "Buff Speed override + WalkSpeed",
    Default = false,
    Callback = function(state)
        speedOn = state
        applyPatches()
        notify("Hooked", speedOn and ("Speed enabled x" .. speedMult) or "Speed disabled", 2)
    end,
})

MainSection:AddToggle("Rage", {
    Title = "RAGE",
    Description = "Long hook 200 / instant fly / vacuum pull / CD 1.2 + full aim pack",
    Default = true,
    Callback = function(state)
        rage = state
        if not rage then
            currentTarget = nil
        end
        applyPatches()
        notify("Hooked", rage and "RAGE enabled" or "RAGE disabled", 2)
    end,
})

MainSection:AddToggle("NoNotifications", {
    Title = "Do not send notifications",
    Description = "Hide all Fluent notifications",
    Default = false,
    Callback = function(state)
        noNotifications = state
    end,
})

MainSection:AddToggle("AutoKill", {
    Title = "AutoKill (void anchor)",
    Description = "RAGE + hang anchored under enemy spawn, victims drop to you",
    Default = false,
    Callback = function(state)
        setAutoKill(state)
    end,
})

MainSection:AddSlider("KillDepth", {
    Title = "Kill depth",
    Description = "Y to hang at (void below 0, arena ~190)",
    Default = -5,
    Min = -50,
    Max = 50,
    Rounding = 0,
    Callback = function(value)
        killDepth = clampNum(tonumber(value) or -5, -50, 50)
        if autokill then
            pcall(function() killTarget = enemyKillPos() end)
        end
    end,
})

MainSection:AddDropdown("TargetPart", {
    Title = "Target part",
    Description = "Which part to aim/teleport to",
    Values = {
        "HumanoidRootPart",
        "Head",
        "Torso",
    },
    Default = "HumanoidRootPart",
    Callback = function(value)
        if typeof(value) == "string" then
            targetPart = value
        end
    end,
})

MainSection:AddDropdown("TargetMode", {
    Title = "Target mode",
    Description = "Nearest = ближайший враг, Random = случайный враг",
    Values = {
        "Nearest",
        "Random",
    },
    Default = "Nearest",
    Callback = function(value)
        if value == "Random" or value == "Nearest" then
            targetMode = value
        end
    end,
})

MainSection:AddSlider("HitboxSize", {
    Title = "Hitbox multiplier",
    Description = "4 x N studs (server tolerance 40)",
    Default = 3,
    Min = 1,
    Max = 5,
    Rounding = 1,
    Callback = function(value)
        hitboxMult = clampNum(tonumber(value) or 3, 1, 5)
        applyPatches()
    end,
})

MainSection:AddSlider("MaxDist", {
    Title = "Max target distance",
    Description = "Hook length is 80",
    Default = 80,
    Min = 20,
    Max = 120,
    Rounding = 0,
    Callback = function(value)
        maxDist = clampNum(tonumber(value) or 80, 20, 120)
    end,
})

MainSection:AddSlider("SpeedMult", {
    Title = "Speed multiplier",
    Description = "Base 18; >1.5 risks TeleportReport",
    Default = 1.25,
    Min = 1,
    Max = 2,
    Rounding = 2,
    Callback = function(value)
        speedMult = clampNum(tonumber(value) or 1.25, 1, 2)
    end,
})

MainSection:AddKeybind("ToggleKey", {
    Title = "Toggle keybind",
    Description = "Quickly turn RAGE on/off",
    Mode = "Toggle",
    Default = "H",
    Callback = function()
        Options.Rage:SetValue(not Options.Rage.Value)
    end,
})

Tabs.Info:AddParagraph({
    Title = "Hooked",
    Content = "Silent aim + movement for Hooked! [TRAIT]\nby iwakewar team\n\n- RAGE: long hook 200 + instant fly + vacuum pull + CD 1.2\n- Direction + hitbox teleport into enemy\n- Team check везде: игроки по PlayerEntity + боты по BotEntity\n- InfJump, Speedhack x1-2, report blocker\n\nPress H (or your keybind) to toggle.",
})

Tabs.Info:AddButton({
    Title = "Our Discord Server",
    Description = "Copy invite link to clipboard",
    Callback = function()
        local copied = copyToClipboard("https://discord.gg/GgshjzxxFS")
        notify("Hooked", copied and "Discord link copied" or "No clipboard API on this executor", 2)
    end,
})

-- live status refresh
task.spawn(function()
    while genv0.__hookedGen == myGen do
        task.wait(1)
        if GUI.Unloaded then break end
        local stxt = autokill and "AUTOKILL" or (rage and "ON" or "OFF")
        local tname = currentTarget and currentTarget.name or "-"
        local tdist = currentTarget and math.floor(currentTarget.dist) or 0
        local h = myHum()
        local ws = h and math.floor(h.WalkSpeed * 10) / 10 or 0
        if autokill and tick() % 3 < 1 then
            pcall(function() killTarget = enemyKillPos() end)
        end
        pcall(function()
            Status:SetContent("state: " .. stxt .. (currentTarget and ("  •  target: " .. tname .. " " .. tdist .. "st") or "  •  no target"))
        end)
        pcall(function()
            Live:SetContent(
                "aim: " .. stxt .. "  •  target: " .. tname .. (currentTarget and (" " .. tdist .. "st") or "")
                    .. "  •  speed: " .. ws .. " (x" .. speedMult .. ")"
                    .. "  •  hitbox: x" .. hitboxMult
            )
        end)
        if rage and currentTarget and tick() % 2 < 1 then
            print(string.format(
                "Hooked | target=%s dist=%d hitbox=x%.1f speed=x%.2f ws=%s",
                tname, tdist, hitboxMult, speedMult, tostring(ws)
            ))
        end
    end
end)

-- кэш цели держим свежим фоном, чтобы UpdatePosition не тормозил
task.spawn(function()
    while genv0.__hookedGen == myGen do
        task.wait(0.15)
        if GUI.Unloaded then break end
        if rage then
            pcall(aimDirection)
        else
            currentTarget = nil
        end
        if not speedOn then
            local h = myHum()
            if h and h.WalkSpeed > 0 and h.WalkSpeed < 60 then
                baseSpeed = h.WalkSpeed
            end
        end
    end
end)

-- AutoKill loopgoto: якорь + ноль гравитации + ноль велосити каждый кадр.
-- мы висим (якорь под килл-плейном не падает), жертва своим клиентом
-- тянется к нам вниз и падает/дохает. бонус: якорем нас самих не утащить.
RunService.Heartbeat:Connect(function()
    if genv0.__hookedGen ~= myGen then return end
    if GUI.Unloaded then return end
    if not autokill then return end
    local hrp = myHRP()
    if not hrp then return end
    if not killTarget then
        killTarget = enemyKillPos()
        if not killTarget then return end
    end
    pcall(function()
        if not hrp.Anchored then hrp.Anchored = true end
        hrp.CFrame = CFrame.new(killTarget)
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end)
end)

-- speed fallback (Heartbeat runs after WalkSpeed Stepped overwrite)
RunService.Heartbeat:Connect(function()
    if genv0.__hookedGen ~= myGen then return end
    if GUI.Unloaded then return end
    if not speedOn then return end
    local h = myHum()
    if h and h.Health > 0 then
        local want = baseSpeed * speedMult
        if math.abs(h.WalkSpeed - want) > 0.01 then
            pcall(function() h.WalkSpeed = want end)
        end
    end
end)

-- inf jump
UIS.JumpRequest:Connect(function()
    if genv0.__hookedGen ~= myGen then return end
    if GUI.Unloaded then return end
    if not infJump then return end
    local h = myHum()
    if h and h.Health > 0 then
        pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end)
    end
end)

LP.CharacterAdded:Connect(function()
    task.wait(1)
    applyPatches()
end)

notify("Hooked", "Loaded. Toggle with H.", 4)
print("[Hooked] v1 ready, baseSpeed=" .. tostring(baseSpeed))
