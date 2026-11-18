-- Fisch Auto-Fishing
-- by iwakewar team
-- GUI: gui-lib/PrimordialUI.luau
--
-- Everything here was read off the LIVE client (saiko remote spy + decompile),
-- not guessed. The real fishing networking lives in ReplicatedStorage.packages.Net
-- (conch-style: RF/ = RemoteFunction, RE/ = RemoteEvent), NOT the events/ folder.
--
-- Rod lifecycle (ReplicatedStorage.shared.modules.fishing.BiteTypes -> RodState):
--   Destroyed=0, Unequipped=1, Equipping=2, Equipped=3, Casting=4, Searching=5,
--   Luring=6, PreReel=7, Reeling=8, CatchFinished=9
-- The deployed rod model lives in Workspace.<player>.<RodName> and carries a
-- `rodClient` LocalScript plus a `values` folder (state, power, lure, casted, ...).
-- `values.state.Value` is the RodState number above. Idle/ready == Equipped (3).
--
-- AUTO-CAST  (rodClient: local v_u_3 = Net:RemoteFunction("FishingRod/Cast", -1))
--   The client charges a power bar (power += random(1.5,3.0) every 0.01 s, it
--   oscillates 6..100) and on release calls
--       Cast:InvokeServer(math.clamp(power,0,100), power >= 96 - v14*2)
--   The server trusts the client, so we skip the whole charge minigame and call
--       RF/FishingRod/Cast:InvokeServer(100, true)   -> guaranteed perfect cast.
--   Only fires while values.state.Value == Equipped(3); after the catch the state
--   walks back to 3 and we recast.
--
-- AUTO-SHAKE  (legacyControllers.LureShakeController, decompiled)
--   The lure-shake is a SERVER-triggered minigame: server invokes RF/LureShake/Start
--   -> StartMinigame clones `shakeui` into PlayerGui and binds func_2 to Return /
--   ButtonA / button-Activated. func_2 fires RE/LureShake/Shake but is gated by a
--   client cooldown v_u_6 = 0.25 / ShakeScale, and the server ends the session with
--   RE/LureShake/Stop (Trove:Clean -> shakeui removed).
--   Firing the raw Shake remote 25/s BREAKS the catch (stray packets land after the
--   session closes and abort fishing). The reliable path is to drive the REAL input:
--   VirtualInputManager:SendKeyEvent(Return) while `shakeui` is alive. func_2 then
--   runs with its own bookkeeping and self-throttles to the legit ~4 shakes/s.
--   We also flip GuiService.AutoSelectGuiEnabled = true ("UI Navigation") because
--   most players have it off and the shake button expects to be selectable.
--
-- AUTO-REEL  (legacyControllers.ReelController)
--   The catch minigame is ReelController.ActiveReel: a moving fish marker you keep
--   inside the white player bar; progress fills while on-bar and drains off-bar.
--   `barSize` is recomputed every logic step, so we re-apply EVERY frame:
--       ar.barSize = ar.minBarSize = BIG
--       ar.reel_playerbar.Size = UDim2.new(BIG, 0, <keep Y>, 0)
--   With BIG >= 2 the white bar covers the whole track -> progress can never drop,
--   the reel self-completes and the client sends RE/Reel/Finish{e~100,p=true}.
--   The server starts the reel by itself (RF/Reel/Start OnClientInvoke -> StartReel),
--   so no separate "hook" input is needed - auto-reel IS the auto-catch.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local VIM = game:GetService("VirtualInputManager")

local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")
local isPhone = UIS.TouchEnabled and not UIS.KeyboardEnabled

local genv0 = getgenv()

-- one live instance only: a stale Heartbeat/shake loop from a previous copy would
-- keep firing under the new one and desync the catch.
genv0.__fischGen = (genv0.__fischGen or 0) + 1
local myGen = genv0.__fischGen

if genv0.__fischUI and type(genv0.__fischUI.Destroy) == "function" then
    pcall(function() genv0.__fischUI:Destroy() end)
end

-- GUI loader: our own gui-lib/PrimordialUI.luau, silent WindUI fallback so the
-- script never dies on a download hiccup.
local LIB_URL = "https://raw.githubusercontent.com/iww-dev/iwakewar-scripts/refs/heads/main/gui-lib/PrimordialUI.luau"
local WINDUI_URL = "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
local GUI
do
    local ok, res = pcall(function()
        return loadstring(game:HttpGet(LIB_URL))()
    end)
    if ok and type(res) == "table" and type(res.CreateWindow) == "function" then
        GUI = res
    else
        warn("[Fisch] PrimordialUI failed to load (" .. tostring(res) .. "), falling back to WindUI")
        GUI = loadstring(game:HttpGet(WINDUI_URL))()
        GUI.__fallback = true
    end
end
genv0.__fischUI = GUI

-- loader integration: main.luau registers __iwClean before running us and calls
-- every registered fn from runCleanup() when it switches/reloads a script.
local STATE = STATE or {}
local running = true
if STATE.onCleanup then STATE.onCleanup(function() running = false end)
if type(genv0.__iwClean) == "function" then
    pcall(genv0.__iwClean, function()
        running = false
        genv0.__fischGen = (genv0.__fischGen or 0) + 1
    end)
end

local function alive()
    if genv0.__fischGen ~= myGen then return false end
    if not running then return false end
    if STATE.alive then return STATE.alive() end
    return true
end

-- ================================================================= config
local ROD_STATE = {
    Equipped = 3, Casting = 4, Searching = 5, Luring = 6,
    PreReel = 7, Reeling = 8, CatchFinished = 9,
}

local cfg = {
    autoCast = false,
    autoShake = true,
    autoReel = true,
    castPower = 100,
    perfectCast = true,
    castDelay = 1.0,       -- s, pause between finishing a catch and recasting
    reelBarSize = 2.0,     -- white-bar scale; >= 2 covers the whole track
    shakeRate = 0.1,       -- s between Return presses (func_2 self-throttles to 0.25)
    enableUiNav = true,    -- force GuiService.AutoSelectGuiEnabled on
    antiAfk = true,
    noNotifications = false,
}

-- ================================================================ services
local Net = ReplicatedStorage:WaitForChild("packages"):WaitForChild("Net")
local CastRF = Net:FindFirstChild("RF/FishingRod/Cast")

local ReelController
do
    local ok, m = pcall(function()
        return require(ReplicatedStorage.client.legacyControllers:WaitForChild("ReelController"))
    end)
    if ok then ReelController = m end
end

-- ================================================================= helpers
local function copyToClipboard(text)
    local g = getgenv and getgenv() or {}
    for _, name in ipairs({ "writeclipboard", "clipboard", "setclipboard", "toclipboard" }) do
        local v = g[name]
        if v == nil then v = rawget(_G, name) end
        if typeof(v) == "function" then
            if pcall(v, text) then return true end
        end
    end
    return false
end

local function notify(title, content, duration)
    if cfg.noNotifications then return end
    pcall(function()
        GUI:Notify({ Title = title, Content = content, Duration = duration or 3 })
    end)
end

local function enableUiNavigation()
    if not cfg.enableUiNav then return end
    pcall(function() GuiService.AutoSelectGuiEnabled = true end)
end

-- =============================================================== discovery
-- the deployed rod model (Workspace.<player>.<Rod>) carries rodClient + values
local function getRod()
    local pc = workspace:FindFirstChild(LP.Name)
    if not pc then return nil end
    for _, m in ipairs(pc:GetChildren()) do
        if m:FindFirstChild("rodClient") and m:FindFirstChild("values") then
            return m
        end
    end
    return nil
end

local function rodState(rod)
    rod = rod or getRod()
    local v = rod and rod:FindFirstChild("values")
    local s = v and v:FindFirstChild("state")
    if s then
        local ok, val = pcall(function() return s.Value end)
        if ok then return val end
    end
    return nil
end

-- make sure a rod is deployed: if not, equip the first rod tool from the Backpack
local function ensureRod()
    local rod = getRod()
    if rod then return rod end
    local chr = LP.Character
    local hum = chr and chr:FindFirstChildOfClass("Humanoid")
    local bp = LP:FindFirstChild("Backpack")
    if hum and bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and (t:FindFirstChild("rodClient", true) or t:FindFirstChild("values", true)) then
                pcall(function() hum:EquipTool(t) end)
                break
            end
        end
    end
    local t0 = os.clock()
    while alive() and os.clock() - t0 < 3 do
        rod = getRod()
        if rod then return rod end
        task.wait(0.15)
    end
    return getRod()
end

local function findShakeUI()
    for _, d in ipairs(PG:GetDescendants()) do
        if d.Name == "shakeui" then return d end
    end
    return nil
end

-- ================================================================= engine
local stats = { casts = 0, shakes = 0, reels = 0 }

-- AUTO-CAST: perfect cast via the client-authoritative Cast RemoteFunction
local function doCast()
    if not CastRF then return false end
    local rod = ensureRod()
    if not rod then return false end
    if rodState(rod) ~= ROD_STATE.Equipped then return false end
    local ok, res = pcall(function()
        return CastRF:InvokeServer(math.clamp(cfg.castPower, 0, 100), cfg.perfectCast)
    end)
    if ok and res == true then
        stats.casts = stats.casts + 1
        return true
    end
    return false
end

-- wait for one full fishing cycle to end (state walks back to Equipped)
local function waitCycleEnd(rod, limit)
    local t0 = os.clock()
    -- first let it leave idle (the state may still read 3 for a frame after cast)
    while alive() and cfg.autoCast and os.clock() - t0 < 3 do
        local st = rodState(rod)
        if st and st ~= ROD_STATE.Equipped then break end
        task.wait(0.1)
    end
    -- then wait until it is idle again
    t0 = os.clock()
    while alive() and cfg.autoCast and os.clock() - t0 < (limit or 90) do
        local st = rodState(rod)
        if not st or st == ROD_STATE.Equipped then return true end
        task.wait(0.2)
    end
    return false
end

task.spawn(function()
    while alive() do
        if cfg.autoCast then
            local rod = ensureRod()
            if rod and rodState(rod) == ROD_STATE.Equipped then
                if doCast() then
                    waitCycleEnd(rod)
                    task.wait(cfg.castDelay)
                else
                    task.wait(0.4)
                end
            else
                task.wait(0.4)
            end
        else
            task.wait(0.3)
        end
    end
end)

-- AUTO-SHAKE: drive the real Return input while the shake minigame is on screen
local shakeuiAlive = findShakeUI() ~= nil
local lastPress = 0
do
    local conns = {}
    conns[#conns + 1] = PG.DescendantAdded:Connect(function(d)
        if d.Name == "shakeui" then shakeuiAlive = true end
    end)
    conns[#conns + 1] = PG.DescendantRemoving:Connect(function(d)
        if d.Name == "shakeui" then shakeuiAlive = false end
    end)
    genv0.__fischShakeConns = conns
end

local function pressReturn()
    pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game) end)
    pcall(function() VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game) end)
end

-- AUTO-REEL: stretch the white player bar over the whole track, every frame
local function applyReelHack()
    if not cfg.autoReel or not ReelController then return end
    local ar = ReelController.ActiveReel
    if not ar then return end
    local BIG = cfg.reelBarSize
    pcall(function()
        ar.barSize = BIG
        ar.minBarSize = BIG
    end)
    local pb = ar.reel_playerbar
    if pb then
        pcall(function()
            local y = pb.Size.Y
            pb.Size = UDim2.new(BIG, 0, y.Scale, y.Offset)
        end)
    end
    stats.reels = stats.reels + 1
end

-- ============================================================ cleanup hook
genv0.__fischCleanup = function()
    if genv0.__fischGen ~= myGen then return end
    running = false
    genv0.__fischGen = genv0.__fischGen + 1
    local conns = genv0.__fischShakeConns
    if conns then
        for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    end
    if GUI and type(GUI.Destroy) == "function" then
        pcall(function() GUI:Destroy() end)
    end
end

-- ==================================================================== GUI
local Window = GUI:CreateWindow({
    Title = "iwakewar: Fisch",
    Subtitle = "by iwakewar team",
    Footer = "by iwakewar team",
    Version = "v1.0.0",
    Folder = "iwakewar-fisch",
    Icon = "fish",
    Theme = "Ocean",
    Size = isPhone and UDim2.fromOffset(507, 325) or UDim2.fromOffset(760, 500),
    ToggleKey = Enum.KeyCode.RightShift,
    Topbar = { Height = 40, ButtonsType = "Default" },
    OpenButton = { Enabled = true, Draggable = true, OnlyMobile = true, Scale = 1.1, CornerRadius = UDim.new(0, 6) },
})
GUI._selfUrl = "https://raw.githubusercontent.com/iww-dev/iwakewar-scripts/refs/heads/main/Fisch.luau"

local Tabs = {
    Info = Window:Tab({ Title = "Info", Subtitle = "About the script", Icon = "sfsymbols:info.circle", Border = true }),
    Main = Window:Tab({ Title = "Controls", Subtitle = "Auto-fishing settings", Icon = "sfsymbols:gamecontroller", Border = true }),
}
pcall(function() Window:SelectTab(1) end)

-- mobile floating toggle (always visible)
if isPhone then
    pcall(function() game:GetService("CoreGui").FischToggle:Destroy() end)
    local sg = Instance.new("ScreenGui")
    sg.Name = "FischToggle" sg.ResetOnSpawn = false
    pcall(function() sg.Parent = game:GetService("CoreGui") end)
    if sg.Parent == nil then sg.Parent = PG end
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(40, 40)
    b.Position = UDim2.new(0.5, -20, 0.5, -260)
    b.Text = "F" b.TextSize = 18
    b.BackgroundColor3 = Color3.fromRGB(30, 32, 40) b.TextColor3 = Color3.new(1, 1, 1)
    b.Parent = sg
    local cc = Instance.new("UICorner") cc.CornerRadius = UDim.new(0, 8) cc.Parent = b
    local glow = Instance.new("UIStroke")
    glow.Thickness = 2 glow.Color = Color3.fromRGB(0, 200, 255) glow.Transparency = 0.2
    glow.Parent = b
    task.spawn(function()
        while b.Parent do
            pcall(function()
                TweenService:Create(glow, TweenInfo.new(0.8), { Transparency = 0.7 }):Play()
                task.wait(0.85)
                TweenService:Create(glow, TweenInfo.new(0.8), { Transparency = 0.2 }):Play()
                task.wait(0.85)
            end)
        end
    end)
    local drag, ds, sp, moved = false, nil, nil, 0
    b.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag, ds, sp, moved = true, i.Position, b.Position, 0
        end
    end)
    b.InputEnded:Connect(function() drag = false end)
    UIS.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
            local d = i.Position - ds moved = d.Magnitude
            b.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end)
    b.Activated:Connect(function()
        if moved < 12 then pcall(function() Window:Toggle() end) end
    end)
end

-- ---------------------------------------------------------------- Controls
Tabs.Main:Section({ Title = "Main Functions" })

local Status = Tabs.Main:Paragraph({
    Title = "Status",
    Content = "Idle - equip a rod and turn on Auto-Cast...",
})
local Live = Tabs.Main:Paragraph({
    Title = "Live",
    Content = "state: - | rod: - | casts: 0 | shakes: 0 | reels: 0",
})

Tabs.Main:Toggle({
    Title = "Auto-Cast (AFK loop)",
    Description = "Perfect-casts, waits out the catch, then recasts forever",
    Default = false,
    Callback = function(v)
        cfg.autoCast = v
        if v then enableUiNavigation() end
        notify("Fisch", v and "Auto-Cast enabled" or "Auto-Cast disabled", 2)
    end,
})

Tabs.Main:Toggle({
    Title = "Auto-Shake",
    Description = "Drives the real Return input through the lure-shake minigame",
    Default = true,
    Callback = function(v)
        cfg.autoShake = v
        if v then enableUiNavigation() end
        notify("Fisch", v and "Auto-Shake enabled" or "Auto-Shake disabled", 2)
    end,
})

Tabs.Main:Toggle({
    Title = "Auto-Reel (huge bar)",
    Description = "Stretches the white bar over the whole track - the catch self-completes",
    Default = true,
    Callback = function(v)
        cfg.autoReel = v
        notify("Fisch", v and "Auto-Reel enabled" or "Auto-Reel disabled", 2)
    end,
})

Tabs.Main:Section({ Title = "Cast Settings" })

Tabs.Main:Slider({
    Title = "Cast power",
    Description = "0-100; 100 + perfect = max-distance perfect cast",
    Min = 0, Max = 100, Value = 100, Format = "%.0f",
    Callback = function(v) cfg.castPower = v end,
})

Tabs.Main:Toggle({
    Title = "Perfect cast",
    Description = "Send the cast flagged as perfect (server trusts the client)",
    Default = true,
    Callback = function(v) cfg.perfectCast = v end,
})

Tabs.Main:Slider({
    Title = "Recast delay",
    Description = "Seconds to wait after a catch before casting again",
    Min = 0, Max = 5, Value = 1, Format = "%.1f s",
    Callback = function(v) cfg.castDelay = v end,
})

Tabs.Main:Section({ Title = "Reel Settings" })

Tabs.Main:Slider({
    Title = "White bar size",
    Description = "Bar scale during the catch; >= 2 covers the whole track",
    Min = 1, Max = 4, Value = 2, Format = "%.1f x",
    Callback = function(v) cfg.reelBarSize = v end,
})

Tabs.Main:Section({ Title = "Misc" })

Tabs.Main:Toggle({
    Title = "Force UI Navigation",
    Description = "Keeps GuiService.AutoSelectGuiEnabled on (off by default for most players)",
    Default = true,
    Callback = function(v)
        cfg.enableUiNav = v
        if v then enableUiNavigation() end
    end,
})

Tabs.Main:Toggle({
    Title = "Anti-AFK",
    Description = "Resets the idle timer so the server never kicks you while AFK",
    Default = true,
    Callback = function(v) cfg.antiAfk = v end,
})

Tabs.Main:Toggle({
    Title = "Do not send notifications",
    Description = "Hide all notifications",
    Default = false,
    Callback = function(v) cfg.noNotifications = v end,
})

Tabs.Main:Button({
    Title = "Hide menu",
    Description = "Close the window while fishing",
    Callback = function() pcall(function() Window:Hide() end) end,
})

-- ------------------------------------------------------------------- Info
Tabs.Info:Paragraph({
    Title = "Fisch Auto-Fishing",
    Content = "Auto-cast, auto-shake and auto-reel for Fisch\nby iwakewar team\n\n"
        .. "- Auto-Cast: calls RF/FishingRod/Cast(100, true) - guaranteed perfect cast,\n"
        .. "  only while the rod is idle (RodState Equipped), recasts after every catch\n"
        .. "- Auto-Shake: drives the real Return key through the lure-shake minigame\n"
        .. "  (the game's own func_2), self-throttled to the legit ~4 shakes/s\n"
        .. "- Auto-Reel: stretches the white player bar over the whole track every\n"
        .. "  frame, so the catch minigame can never fail and self-completes\n"
        .. "- Force UI Navigation so the shake button is selectable on any account\n"
        .. "- Anti-AFK built in\n\n"
        .. "Equip a rod, then turn on Auto-Cast. Press RightShift to open / close.",
})

Tabs.Info:Button({
    Title = "Our Discord Server",
    Description = "Copy invite link to clipboard",
    Callback = function()
        local copied = copyToClipboard("https://discord.gg/GgshjzxxFS")
        notify("Fisch", copied and "Discord link copied" or "No clipboard API on this executor", 2)
    end,
})

-- =========================================================== status thread
local STATE_NAMES = {
    [0] = "Destroyed", [1] = "Unequipped", [2] = "Equipping", [3] = "Equipped",
    [4] = "Casting", [5] = "Searching", [6] = "Luring", [7] = "PreReel",
    [8] = "Reeling", [9] = "CatchFinished",
}

task.spawn(function()
    while true do
        task.wait(0.5)
        if not alive() then break end
        if GUI.Unloaded then break end

        local rod = getRod()
        local st = rodState(rod)
        local stTxt = st and (STATE_NAMES[st] or tostring(st)) or "-"
        local reelActive = ReelController and ReelController.ActiveReel ~= nil

        local head
        if cfg.autoCast then
            head = reelActive and "REELING (auto)" or (stTxt .. (st == ROD_STATE.Equipped and " - casting..." or ""))
        else
            head = "Auto-Cast OFF"
        end

        pcall(function()
            Status:SetContent(string.format("%s  |  shake: %s  |  reel: %s  |  rod: %s",
                head,
                cfg.autoShake and (shakeuiAlive and "ACTIVE" or "ready") or "off",
                cfg.autoReel and (reelActive and "ACTIVE" or "ready") or "off",
                rod and rod.Name or "none"))
        end)

        pcall(function()
            Live:SetContent(string.format(
                "state: %s  |  casts: %d  |  shakes: %d  |  reel-frames: %d\nauto-cast: %s  |  power: %d  |  perfect: %s  |  bar: %.1fx",
                stTxt, stats.casts, stats.shakes, stats.reels,
                cfg.autoCast and "ON" or "OFF", cfg.castPower,
                cfg.perfectCast and "yes" or "no", cfg.reelBarSize))
        end)
    end
end)

-- =============================================================== main loop
local lastAfk = os.clock()

RunService.Heartbeat:Connect(function()
    if not alive() then return end

    -- auto-shake: press Return while the shake minigame is on screen
    if cfg.autoShake and shakeuiAlive then
        local now = os.clock()
        if now - lastPress >= cfg.shakeRate then
            lastPress = now
            enableUiNavigation()
            pressReturn()
            stats.shakes = stats.shakes + 1
        end
    end

    -- auto-reel: re-apply the huge bar every frame (barSize is recomputed)
    pcall(applyReelHack)

    -- anti-afk
    if cfg.antiAfk and os.clock() - lastAfk >= 10 then
        lastAfk = os.clock()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

-- the bar size is also recomputed on the render step, so cover that too
RunService.RenderStepped:Connect(function()
    if not alive() then return end
    pcall(applyReelHack)
end)

if LP.Idled then
    pcall(function()
        genv0.__fischIdled = LP.Idled:Connect(function()
            if not alive() or not cfg.antiAfk then return end
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end)
    end)
end

enableUiNavigation()
notify("Fisch", "Loaded. Equip a rod and turn on Auto-Cast. Toggle with RightShift.", 4)
pcall(function() Window:SetToggleKey(Enum.KeyCode.RightShift) end)
print("[Fisch] loaded (Primordial UI)")
