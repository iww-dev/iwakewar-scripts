-- BABFT autofarm by iwakewar team (WindUI port)
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local isPhone = UIS.TouchEnabled and not UIS.KeyboardEnabled

local cfg = { farm = false, speed = 461, mode = "Old (fastest)", yOffset = 0 }

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "BABFT Farm",
    Folder = "iwakewar-babft",
    Icon = "boat",
    Theme = "Rose",
    Size = isPhone and UDim2.fromOffset(507, 325) or UDim2.fromOffset(780, 500),
    Position = isPhone and UDim2.new(0, 9, 1, -334) or UDim2.new(0, 7, 1, -507),
    Topbar = { Height = 40, ButtonsType = "Default" },
    OpenButton = {
        Enabled = true,
        Draggable = true,
        OnlyMobile = true,
        Scale = isPhone and 1.1 or 0.5,
        CornerRadius = UDim.new(0, 6),
    },
})

local lang = "ru"
local function LT(ru, uk, en)
  if lang == "en" then return en or ru end
  if lang == "uk" then return uk or ru end
  return ru
end

local Tabs = {
    Info = Window:Tab({ Title = LT("Инфо", "Інфо", "Info"), Icon = "sfsymbols:info.circle", Border = true }),
    Main = Window:Tab({ Title = LT("Главная", "Головна", "Main"), Icon = "sfsymbols:house", Border = true }),
    Settings = Window:Tab({ Title = LT("Настройки", "Налаштування", "Settings"), Icon = "sfsymbols:gear", Border = true }),
}

Tabs.Settings:Dropdown({
    Title = "Language / Язык / Мова",
    Values = { "Русский", "Українська", "English" },
    Value = "Русский",
    Callback = function(v)
        if v == "English" then lang = "en"
        elseif v == "Українська" then lang = "uk"
        else lang = "ru" end
        WindUI:Notify({ Title = "BABFT Farm", Content = "Language changed", Duration = 2 })
    end,
})

Tabs.Settings:Dropdown({
    Title = LT("Тема", "Тема", "Theme"),
    Values = { "Rose", "Dark", "Mellowsi" },
    Value = "Rose",
    Callback = function(v)
        pcall(function() Window:SetTheme(v) end)
        pcall(function() WindUI:SetTheme(v) end)
        WindUI:Notify({ Title = "BABFT Farm", Content = "Theme: " .. v, Duration = 2 })
    end,
})

Tabs.Info:Paragraph({
    Title = "BABFT Farm",
    Desc = "Autofarm for Build A Boat For Treasure\nby iwakewar team",
})

Tabs.Info:Button({
    Title = LT("Наш Discord сервер", "Наш Discord сервер", "Our Discord Server"),
    Desc = "Copy invite link to clipboard",
    Callback = function()
        pcall(setclipboard, "https://discord.gg/GgshjzxxFS")
        WindUI:Notify({ Title = "BABFT Farm", Content = "Discord link copied", Duration = 3 })
    end,
})

local farmTog = Tabs.Main:Toggle({
    Title = LT("Фарм", "Фарм", "Farm"),
    Desc = "Launch -> fly -> chest -> reset",
    Value = false,
    Callback = function(v) cfg.farm = v end,
})

local ratePara = Tabs.Main:Paragraph({ Title = LT("Голда за 15 минут", "Золото за 15 хвилин", "Gold per 15 minutes"), Desc = "-" })
local ratePara75 = Tabs.Main:Paragraph({ Title = LT("Голда за 75 секунд", "Золото за 75 секунд", "Gold per 75 seconds"), Desc = "-" })
local ratePara120 = Tabs.Main:Paragraph({ Title = LT("Голда за 2 минуты", "Золото за 2 хвилини", "Gold per 2 min"), Desc = "-" })

local speedSld = Tabs.Main:Slider({
    Title = LT("Скорость полёта", "Швидкість польоту", "Fly speed"),
    Desc = "Studs per second",
    Step = 1,
    Value = { Min = 20, Max = 461, Default = 461 },
    Callback = function(v) cfg.speed = v end,
})

Tabs.Main:Dropdown({
    Title = LT("Режим", "Режим", "Mode"),
    Values = { "New", "Old (fastest)" },
    Value = "Old (fastest)",
    Callback = function(v)
        cfg.mode = v
        cfg.yOffset = (v == "Old (fastest)") and -9.5 or 0
        WindUI:Notify({ Title = "BABFT Farm", Content = "Mode: " .. v, Duration = 2 })
    end,
})

-- ===== core farm logic (unchanged) =====
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

local WAYPOINTS = {
    Vector3.new(-54, 27, 1108), Vector3.new(-54, 27, 1368), Vector3.new(-54, 27, 2138),
    Vector3.new(-54, 27, 2908), Vector3.new(-54, 27, 3678), Vector3.new(-54, 27, 4448),
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
        if os.clock() - t0 > (cfg.mode == "Old (fastest)" and 60 or 180) then done = true end
    end)
    local waitStep = (cfg.mode == "Old (fastest)") and 0.03 or 0.1
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
            pcall(function() ratePara:SetDesc(tostring(sum15) .. " gold / 15 min (now: " .. g .. ")") end)
            pcall(function() ratePara75:SetDesc(tostring(sum75) .. " gold / 75 s (now: " .. g .. ")") end)
            pcall(function() ratePara120:SetDesc(tostring(sum120) .. " gold / 2 min (now: " .. g .. ")") end)
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
    print("[BABFT] ready (WindUI)")
    while alive() do
        if cfg.farm then
            local wt0 = os.clock()
            local waitStep = (cfg.mode == "Old (fastest)") and 0.1 or 0.5
            local waitMax = (cfg.mode == "Old (fastest)") and 3 or 15
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
                    if cfg.mode ~= "Old (fastest)" then task.wait(0.2) end
                end
                if cfg.mode ~= "Old (fastest)" then flyTo(Vector3.new(-54, 27, 300), cfg.speed) end
                local stageT0 = nil
                for i, wp in ipairs(WAYPOINTS) do
                    if not alive() or not cfg.farm then break end
                    if cfg.mode == "Old (fastest)" and i >= #WAYPOINTS - 1 then break end
                    local sp = cfg.speed
                    if cfg.mode == "Old (fastest)" then
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
                if cfg.mode == "Old (fastest)" and alive() and cfg.farm then
                    local h2 = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
                    if h2 then
    local okL = pcall(function() LP:LoadCharacter() end)
    if not okL then pcall(function() h2.Health = 0 end) end
end
                    task.wait(2)
                end
                if alive() and cfg.farm and cfg.mode ~= "Old (fastest)" then
                    flyTo(Vector3.new(-55.7, 9, 9492), cfg.speed)
                    flyTo(CHEST, cfg.speed * 1.5)
                    local g0 = gold()
                    local t1 = os.clock()
                    while alive() and cfg.farm and os.clock() - t1 < (cfg.mode == "Old (fastest)" and 0.1 or 8) do
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
                        if cfg.mode == "Old (fastest)" then task.wait(0) else task.wait(1.7) end
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
                            if cfg.mode == "Old (fastest)" then task.wait(0.2) else task.wait(1) end
                        end
                    end
                end
            end
        else
            task.wait(0.5)
        end
    end
end)

print("[BABFT-WindUI] loaded")
pcall(function() Window:SetToggleKey(Enum.KeyCode.LeftAlt) end)

pcall(function() Window:SetPosition(isPhone and UDim2.new(0, 9, 1, -334) or UDim2.new(0, 7, 1, -507)) end)
pcall(function() Window:SelectTab(1) end)

-- ===== console mirror to localhost =====
do
    local _print = print
    local _warn = warn
    local sockRef
    -- hook ws connect to store socket
    task.spawn(function()
        -- wait for socket variable? We'll re-connect tracking below
    end)
end

-- (websocket debug removed)