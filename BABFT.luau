-- BABFT autofarm by iwakewar team (Primordial UI)
-- GUI: gui-lib/PrimordialUI.luau
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local isPhone = UIS.TouchEnabled and not UIS.KeyboardEnabled

local cfg = {
    farm = false, speed = 461, mode = "Old (fastest)", yOffset = 0,
    antiAfk = true,          -- по умолчанию включён
    afkSpace = 600,          -- пробел раз в 10 минут
    idleReset = 5,           -- как часто обнулять idle-таймер, сек
}

-- Experimental — это Old, но на один вейпоинт дальше и с ресетом без паузы.
-- Поэтому «быстрый» профиль общий у Old и Experimental.
local function fastMode()
    return cfg.mode ~= "New"
end
local function isExperimental()
    return cfg.mode == "Experimental"
end

local LIB_URL = "https://raw.githubusercontent.com/iww-dev/iwakewar-scripts/refs/heads/main/gui-lib/PrimordialUI.luau"

local genv0 = getgenv()
if genv0.__babftUI and type(genv0.__babftUI.Destroy) == "function" then
    pcall(function() genv0.__babftUI:Destroy() end)
end

local GUI = loadstring(game:HttpGet(LIB_URL))()
genv0.__babftUI = GUI

local Window = GUI:CreateWindow({
    Title = "BABFT Farm",
    Subtitle = "by iwakewar team",
    Size = isPhone and UDim2.fromOffset(507, 325) or UDim2.fromOffset(780, 500),
    ToggleKey = Enum.KeyCode.LeftAlt,
})

local Tabs = {
    Info = Window:Tab({ Title = "Info", Subtitle = "About the script" }),
    Farm = Window:Tab({ Title = "Farm", Subtitle = "Automation and flight" }),
    Rates = Window:Tab({ Title = "Rates", Subtitle = "Gold per minute" }),
    Misc = Window:Tab({ Title = "Misc", Subtitle = "Utility" }),
}
Window:SelectTab(1)

-- Info ------------------------------------------------------------------
Tabs.Info:Section({ Title = "About" })
Tabs.Info:Paragraph({
    Title = "BABFT Farm",
    Content = "Autofarm for Build A Boat For Treasure\nby iwakewar team\n\nLaunch your boat, ride the stage line, open the golden chest, respawn.",
})
Tabs.Info:Button({
    Title = "Our Discord Server",
    Description = "Copy invite link to clipboard",
    Callback = function()
        pcall(setclipboard, "https://discord.gg/GgshjzxxFS")
        GUI:Notify({
            Title = "BABFT Farm",
            Content = "Discord link copied",
            Type = "success",
            Duration = 3,
        })
    end,
})

-- Farm ------------------------------------------------------------------
Tabs.Farm:Section({ Title = "Automation" })
local farmTog = Tabs.Farm:Toggle({
    Title = "Farm",
    Description = "Launch -> fly -> chest -> reset",
    Default = false,
    Callback = function(v) cfg.farm = v end,
})

Tabs.Farm:Section({ Title = "Settings" })
local speedSld = Tabs.Farm:Slider({
    Title = "Fly speed",
    Description = "Studs per second",
    Min = 20,
    Max = 461,
    Value = 461,
    Format = "%.0f",
    Callback = function(v) cfg.speed = v end,
})
local modeDrop = Tabs.Farm:Dropdown({
    Title = "Mode",
    Description = "New is slower but safer, Old is the fastest route, Experimental goes one waypoint further",
    Values = { "Old (fastest)", "Experimental", "New" },
    Value = "Old (fastest)",
    Callback = function(v)
        cfg.mode = v
        cfg.yOffset = (v == "New") and 0 or -9.5
    end,
})

-- Rates -----------------------------------------------------------------
Tabs.Rates:Section({ Title = "Gold" })
local ratePara = Tabs.Rates:Paragraph({ Title = "Gold / 15 min", Content = "-" })
local ratePara75 = Tabs.Rates:Paragraph({ Title = "Gold / 75 s", Content = "-" })
local ratePara120 = Tabs.Rates:Paragraph({ Title = "Gold / 2 min", Content = "-" })

-- Misc -------------------------------------------------------------------
Tabs.Misc:Section({ Title = "Anti-AFK" })
local antiTog = Tabs.Misc:Toggle({
    Title = "Anti-AFK",
    Description = "Holds the idle timer at 0 so the server never kicks you",
    Default = true,
    Callback = function(v) cfg.antiAfk = v end,
})
local idleDrop = Tabs.Misc:Dropdown({
    Title = "Idle reset",
    Description = "How often the idle timer is zeroed",
    Values = { "2 s", "5 s", "10 s", "30 s" },
    Value = "5 s",
    Callback = function(v) cfg.idleReset = tonumber(v:sub(1, -3)) or 5 end,
})
local spaceDrop = Tabs.Misc:Dropdown({
    Title = "Space tap",
    Description = "Extra Space press on top of the idle reset",
    Values = { "5 min", "10 min", "20 min", "30 min", "Off" },
    Value = "10 min",
    Callback = function(v)
        if v == "Off" then
            cfg.afkSpace = 0
        else
            cfg.afkSpace = (tonumber(v:sub(1, -5)) or 10) * 60
        end
    end,
})
local afkPara = Tabs.Misc:Paragraph({
    Title = "Anti-AFK status",
    Content = "on | idle reset: 0 s | space taps: 0",
})

-- ===== core farm logic =====
local genv = getgenv()
genv.__babftGen = (genv.__babftGen or 0) + 1
local myGen = genv.__babftGen
local STATE = STATE or {}
local running = true
if STATE.onCleanup then STATE.onCleanup(function() running = false end) end
local function alive()
    if genv.__babftGen ~= myGen then return false end
    if not running then return false end
    if STATE.alive then return STATE.alive() end
    return true
end

-- ждём только респавн: health падает до 0 и возвращается к 100.
-- если LoadCharacter отработал мгновенно и нуля мы не увидели — не висим,
-- считаем живым, как только health снова 100.
local function waitRespawn(limit)
    limit = limit or 30
    local t0 = os.clock()
    local sawZero = false
    while alive() and cfg.farm and os.clock() - t0 < limit do
        local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if not h then
            sawZero = true
        elseif h.Health <= 0 then
            sawZero = true
        elseif h.Health >= 100 and (sawZero or os.clock() - t0 > 0.5) then
            return true
        end
        task.wait(0.05)
    end
    return false
end

-- ===== anti-afk =====
-- Сервер кикает за ~20 минут без ввода. Держим idle-таймер на нуле:
-- VirtualUser:CaptureController + ClickButton2 — тот же приём, что в штатном
-- обработчике Idled, только повторяем его по кругу.
local VirtualUser = game:GetService("VirtualUser")
local VIM = game:GetService("VirtualInputManager")
local afk = { resets = 0, taps = 0, lastReset = os.clock(), lastTap = os.clock() }

local function resetIdle()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
    afk.resets = afk.resets + 1
    afk.lastReset = os.clock()
end

local function tapSpace()
    pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game) end)
    task.delay(0.1, function()
        pcall(function() VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end)
    end)
    afk.taps = afk.taps + 1
    afk.lastTap = os.clock()
end

-- страховка: если клиент всё-таки решил, что мы афк, гасим это до дисконнекта
if genv0.__babftIdled then pcall(function() genv0.__babftIdled:Disconnect() end) end
genv0.__babftIdled = LP.Idled:Connect(function()
    if not cfg.antiAfk then return end
    if not alive() then return end
    resetIdle()
end)

task.spawn(function()
    local lastUi = 0
    while alive() do
        if cfg.antiAfk then
            local gap = cfg.idleReset or 5
            if os.clock() - afk.lastReset >= gap then resetIdle() end
            if (cfg.afkSpace or 0) > 0 and os.clock() - afk.lastTap >= cfg.afkSpace then
                -- во время фарма персонаж и так в движении, прыжок может сбить маршрут
                if not cfg.farm then tapSpace() else afk.lastTap = os.clock() end
            end
        else
            afk.lastTap = os.clock()
        end
        if os.clock() - lastUi >= 5 then
            lastUi = os.clock()
            local line
            if cfg.antiAfk then
                line = string.format("on | idle reset: %ds ago (x%d) | space taps: %d",
                    math.floor(os.clock() - afk.lastReset), afk.resets, afk.taps)
            else
                line = string.format("off | idle reset paused (x%d) | space taps: %d", afk.resets, afk.taps)
            end
            pcall(function() afkPara:SetContent(line) end)
        end
        task.wait(0.5)
    end
end)

local WAYPOINTS = {
    Vector3.new(-54, 27, 1108), Vector3.new(-54, 27, 1368), Vector3.new(-54, 27, 2138), Vector3.new(-54, 27, 2908), Vector3.new(-54, 27, 3678), Vector3.new(-54, 27, 4448),
    Vector3.new(-54, 27, 5218), Vector3.new(-54, 27, 5988), Vector3.new(-54, 27, 6758),
    Vector3.new(-54, 27, 7528), Vector3.new(-54, 27, 8298), Vector3.new(-54, 9, 8447),
}
local CHEST = Vector3.new(-55.7, -356, 9492)

local function hrp() local c = LP.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function noclipOn()
    local c = LP.Character
    if c then for _, v in ipairs(c:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end end
end
local function flyTo(target, speed)
    target = target + Vector3.new(0, cfg.yOffset or 0, 0)
    local h = hrp()
    if not h then return false end
    local t0 = os.clock()
    local conn
    local done = false
    conn = game:GetService("RunService").Heartbeat:Connect(function(dt)
        if not alive() or not cfg.farm then done = true return end
        local hh = hrp()
        if not hh then done = true return end
        noclipOn()
        local d = target - hh.Position
        if d.Magnitude < 8 then done = true return end
        hh.AssemblyLinearVelocity = Vector3.zero
        hh.AssemblyAngularVelocity = Vector3.zero
        local step = d.Unit * math.min(speed * math.min(dt, 0.05), d.Magnitude)
        hh.CFrame = CFrame.lookAt(hh.Position + step, hh.Position + step + d.Unit)
        if os.clock() - t0 > (fastMode() and 60 or 180) then done = true end
    end)
    local waitStep = fastMode() and 0.03 or 0.1
    while not done and alive() and cfg.farm do task.wait(waitStep) end
    pcall(function() conn:Disconnect() end)
    return done
end
local function doLaunch()
    local btn = LP.PlayerGui:FindFirstChild("LaunchBoatGui")
    btn = btn and btn:FindFirstChild("PromptLaunch")
    btn = btn and btn:FindFirstChild("Yes")
    if not btn then return false end
    local ok = false
    for _, c in ipairs(getconnections(btn.MouseButton1Click)) do
        local s = pcall(function() c.Function() end)
        if s then ok = true end
    end
    return ok
end
local function gold()
    local g = LP.PlayerGui:FindFirstChild("GoldGui")
    g = g and g:FindFirstChild("Frame")
    g = g and g:FindFirstChild("Amount")
    return tonumber(g and g.Text) or nil
end

task.spawn(function()
    local lastG = gold()
    local lastP = nil
    local hist = {}
    while alive() do
        task.wait(2)
        local now = os.clock()
        local g = gold()
        if g ~= nil and lastG ~= nil and g ~= lastG then print("[BABFT] GOLD " .. lastG .. " -> " .. g) end
        if g ~= nil then
            if lastG ~= nil and g > lastG then table.insert(hist, { t = now, v = g - lastG }) end
            lastG = g
            local cut = now - 900
            local sum15 = 0
            local sum75 = 0
            local sum120 = 0
            local fresh = {}
            for _, e in ipairs(hist) do
                if e.t >= cut then
                    sum15 = sum15 + e.v
                    if e.t >= now - 75 then sum75 = sum75 + e.v end
                    if e.t >= now - 120 then sum120 = sum120 + e.v end
                    table.insert(fresh, e)
                end
            end
            hist = fresh
            pcall(function() ratePara:SetContent(tostring(sum15) .. " gold (now: " .. g .. ")") end)
            pcall(function() ratePara75:SetContent(tostring(sum75) .. " gold (now: " .. g .. ")") end)
            pcall(function() ratePara120:SetContent(tostring(sum120) .. " gold (now: " .. g .. ")") end)
        end
        local h = hrp()
        local p = h and h.Position or nil
        if p and lastP and (p - lastP).Magnitude > 500 then print("[BABFT] TELEPORT") end
        if p then lastP = p end
    end
end)

game:GetService("RunService").Heartbeat:Connect(function()
    if genv.__babftGen ~= myGen then return end
    if cfg.farm then
        local h = hrp()
        if h then
            h.AssemblyLinearVelocity = Vector3.zero
            h.AssemblyAngularVelocity = Vector3.zero
            local c = LP.Character
            if c then for _, v in ipairs(c:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end end
        end
        pcall(function()
            for _, d in ipairs(LP.PlayerGui:GetDescendants()) do
                if (d:IsA("TextButton") or d:IsA("ImageButton")) and d.Visible then
                    local hit = d.Name:lower():find("claim") ~= nil
                    if not hit then
                        for _, ch in ipairs(d:GetDescendants()) do
                            if (ch:IsA("TextLabel") or ch:IsA("TextButton")) and tostring(ch.Text or ""):lower():find("claim") then hit = true break end
                        end
                    end
                    if hit then
                        for _, cn in ipairs(getconnections(d.MouseButton1Click)) do pcall(function() cn.Function() end) end
                        for _, cn in ipairs(getconnections(d.Activated)) do pcall(function() cn.Function() end) end
                    end
                end
            end
        end)
    end
end)

task.spawn(function()
    print("[BABFT] ready (Primordial UI)")
    while alive() do
        if cfg.farm then
            local wt0 = os.clock()
            local waitStep = fastMode() and 0.1 or 0.5
            local waitMax = fastMode() and 3 or 15
            while alive() and cfg.farm and hrp() == nil and os.clock() - wt0 < waitMax do task.wait(waitStep) end
            if hrp() ~= nil then
                local z = nil
                pcall(function()
                    for _, zz in ipairs(workspace:GetChildren()) do
                        if zz.Name:find("Zone") then
                            local tc = zz:FindFirstChild("TeamColor")
                            if tc and LP.Team and tostring(tc.Value) == tostring(LP.Team.TeamColor) then z = zz break end
                        end
                    end
                end)
                for _ = 1, 3 do
                    if not alive() or not cfg.farm then break end
                    if z and z.Launched.Value then break end
                    doLaunch()
                    if not fastMode() then task.wait(0.2) end
                end
                if not fastMode() then flyTo(Vector3.new(-54, 27, 300), cfg.speed) end
                local stageT0 = nil
                -- Old останавливается за два вейпоинта до конца, Experimental
                -- проходит ещё один
                local stopAt = isExperimental() and #WAYPOINTS or (#WAYPOINTS - 1)
                for i, wp in ipairs(WAYPOINTS) do
                    if not alive() or not cfg.farm then break end
                    if fastMode() and i >= stopAt then break end
                    local sp = cfg.speed
                    if fastMode() then
                        if i >= #WAYPOINTS - 2 then
                            sp = 555
                        elseif i <= 2 then
                            sp = 1400
                        else
                            if stageT0 == nil then stageT0 = os.clock() end
                            if os.clock() - stageT0 < 2 then sp = cfg.speed * 0.9 end
                        end
                    end
                    sp = sp * (1.0144 ^ i)
                    flyTo(wp, sp)
                    if i <= 3 then task.wait(0.06)
                    elseif i < 5 then task.wait(0.17)
                    elseif i >= #WAYPOINTS - 1 then task.wait(0.17 * (0.603 ^ (#WAYPOINTS - i)))
                    else task.wait(0.17 * (0.914 ^ (i - 4))) end
                end
                if fastMode() and alive() and cfg.farm then
                    local h2 = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
                    if h2 then
                        local okL = pcall(function() LP:LoadCharacter() end)
                        if not okL then pcall(function() h2.Health = 0 end) end
                    end
                    if isExperimental() then
                        -- Experimental не ждёт фиксированную паузу: только респавн
                        waitRespawn()
                    else
                        task.wait(2)
                    end
                end
                if alive() and cfg.farm and not fastMode() then
                    flyTo(Vector3.new(-55.7, 9, 9492), cfg.speed)
                    flyTo(CHEST, cfg.speed * 1.5)
                    local g0 = gold()
                    local t1 = os.clock()
                    while alive() and cfg.farm and os.clock() - t1 < (fastMode() and 0.1 or 8) do
                        local hh = hrp()
                        if hh then hh.CFrame = CFrame.new(CHEST + Vector3.new(0, math.sin(os.clock() * 6) * 2, 0)) end
                        local g1 = gold()
                        if g0 ~= nil and g1 ~= nil and g1 > g0 then break end
                        task.wait(0.1)
                    end
                    local hend = hrp()
                    local chestPos = Vector3.new(-55.7, -358.7, 9492)
                    local cdist = hend and (hend.Position - chestPos).Magnitude or -1
                    if hend and cdist < 40 then
                        local h2 = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
                        if h2 then
                            local okL = pcall(function() LP:LoadCharacter() end)
                            if not okL then pcall(function() h2.Health = 0 end) end
                        end
                        local wt = os.clock()
                        while alive() and cfg.farm and hrp() ~= nil and os.clock() - wt < 3 do task.wait(0.2) end
                        wt = os.clock()
                        while alive() and cfg.farm and hrp() == nil and os.clock() - wt < 15 do task.wait(0.5) end
                        if fastMode() then task.wait(0) else task.wait(1.7) end
                        local hn = hrp()
                        local spawn = Vector3.new(470, -10, -25)
                        pcall(function()
                            local tm = LP.Team and game.Workspace.Teams:FindFirstChild(LP.Team.Name .. "Team")
                            local sp = tm and tm:FindFirstChild("Spawns", true)
                            sp = sp and (sp:FindFirstChildOfClass("SpawnLocation") or sp:FindFirstChildWhichIsA("BasePart", true))
                            if sp then spawn = sp.Position + Vector3.new(0, 3, 0) end
                        end)
                        hn = hrp()
                        if hn and (hn.Position - spawn).Magnitude > 200 then
                            hn.CFrame = CFrame.new(spawn)
                            if fastMode() then task.wait(0.2) else task.wait(1) end
                        end
                    end
                end
            end
        else
            task.wait(0.5)
        end
    end
end)

print("[BABFT] loaded (Primordial UI)")
