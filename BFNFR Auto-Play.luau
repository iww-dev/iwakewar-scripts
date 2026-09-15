-- BFNFR Auto-Play
-- by iwakewar team
-- Premium Fluent GUI. Presses the REAL lane keys through VirtualInputManager
-- so the game's own KeyPress -> NoteInput runs: arrow/skin animation, character
-- animation, combo, sound and the remote, exactly like a human press.
-- Works with the player's own keybinds.
--
-- Timing model (read from the game's own songPlay/NoteInput):
--   the game judges INSTANTLY, client-side, off the note's current Y.Scale:
--   |off|<=16.5ms PERFECT, <=43.5 SICK, <=76.5 GOOD, <=106.5 OK, <=130.5 BAD,
--   where off = 2000*|Y.Scale|/(11*NoteSpeed) - exactly our curMs.
--   So we aim the keypress at curMs == target (8=Perfect, 30=Sick) and only
--   pre-compensate the tiny press->NoteInput processing delay, which the
--   self-tuning inputLead learns in real ms (*1000, /1000 conversions).
--   The old code used *2000 / *2000 and a bogus latency lead, which pushed
--   presses early: Perfect notes drifted into Sick and Sick notes into Good.

local plr = game.Players.LocalPlayer
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local mf = plr.PlayerGui:WaitForChild("Main"):WaitForChild("MatchFrame")
local DataF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("DataF")

local function loadFluent()
    local src
    local ok, read = pcall(readfile, "_fluent.lua")
    if ok and #read > 1000 then
        src = read
    else
        src = game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua", true)
    end
    if #src < 1000 then
        error("Fluent source could not be loaded")
    end
    return (loadstring(src))()
end

local Fluent = loadFluent()
local Window = Fluent:CreateWindow({
    Title = "BFNFR Auto-Play",
    SubTitle = "by iwakewar team",
    TabWidth = 150,
    Size = UDim2.fromOffset(566, 430),
    Acrylic = true,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.RightControl,
})
local Tabs = {
    Info = Window:AddTab({ Title = "Info", Icon = "badge-check" }),
    Main = Window:AddTab({ Title = "Controls", Icon = "gamepad-2" }),
}
local Options = Fluent.Options
Window:SelectTab(1)

-- engine state
local enabled = false
local antiAfk = true
local mySide: number? = nil
local speed = 1
local dir = -1
local perfectChance = 61
local laneKeys: { [number]: Enum.KeyCode } = {}
local speedLock = false
local tracked = setmetatable({}, { __mode = "k" })
local held = {}
local lastJump = 0
local hits = 0

local DEFAULT_KEYS = { "D", "F", "J", "K", "Left", "Down", "Up", "Right" }

local PERFECT_CENTER = 8
local SICK_CENTER = 30
local inputLead = 20

local rateCache = setmetatable({}, { __mode = "k" })

local function clampNum(v: number, a: number, b: number): number
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

local function fetchSettings(): boolean
    local ok, res = pcall(function()
        return DataF:InvokeServer("Get")
    end)
    if not ok or not res or not res[1] then return false end
    local st = res[1]
    speed = clampNum(st.NoteSpeed or 1, 0.8, 5)
    dir = st.Direction or -1
    laneKeys = {}
    for i = 1, 4 do
        local name = st.Inputs and st.Inputs[i] or DEFAULT_KEYS[i]
        local kc = Enum.KeyCode[name]
        if kc then laneKeys[i] = kc end
    end
    return true
end

local function detectSide(): number?
    for s = 1, 2 do
        local ks = mf:FindFirstChild("KeySync" .. s)
        if ks then
            for l = 1, 4 do
                local ar = ks:FindFirstChild("Arrow" .. l)
                if ar then
                    local notes = ar:FindFirstChild("Notes")
                    if notes then
                        for _, n in ipairs(notes:GetChildren()) do
                            if n:IsA("ImageLabel") and n:GetAttribute("HoldHead") == true then
                                return s
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function pickTarget(): number
    local chance = clampNum(perfectChance + math.random(-2, 1), 0, 100)
    if math.random() <= chance / 100 then
        return PERFECT_CENTER
    end
    return SICK_CENTER
end

local function pressKey(lane: number)
    local kc = laneKeys[lane]
    if kc then VIM:SendKeyEvent(true, kc, false, game) end
end

local function releaseKey(lane: number)
    local kc = laneKeys[lane]
    if kc then VIM:SendKeyEvent(false, kc, false, game) end
end

local function releaseAll()
    for lane in pairs(held) do
        held[lane] = nil
        releaseKey(lane)
    end
end

local function findHoldFrame(ar: Instance, noteName: string): Instance?
    local Notes = ar:FindFirstChild("Notes")
    if Notes then
        local f = Notes:FindFirstChild("Hold_" .. noteName)
        if f then return f end
    end
    local Hold = ar:FindFirstChild("Hold")
    local hb = Hold and Hold:FindFirstChild("Hitbox")
    if hb then
        local f = hb:FindFirstChild("Hold_" .. noteName)
        if f then return f end
    end
    return nil
end

local function startHold(lane: number, noteName: string, ks: Instance)
    if held[lane] then return end
    held[lane] = true
    task.spawn(function()
        local guard = os.clock() + 120
        while held[lane] do
            local ar = ks:FindFirstChild("Arrow" .. lane)
            local frame = ar and findHoldFrame(ar, noteName)
            if not frame or not frame.Parent then break end
            local v6 = math.abs(frame.Size.Y.Scale)
            local v7 = frame.Position.Y.Scale * dir
            if v6 + v7 <= 1.5 or os.clock() > guard then break end
            RunService.Heartbeat:Wait()
        end
        if held[lane] then
            held[lane] = nil
            releaseKey(lane)
        end
    end)
end

local function resetRun()
    releaseAll()
    mySide = nil
    speedLock = false
    tracked = setmetatable({}, { __mode = "k" })
end

-- GUI elements
local MainSection = Tabs.Main:AddSection("Main Functions")

local Status = Tabs.Main:AddParagraph({
    Title = "Status",
    Content = "Idle — waiting for a track…",
})
local Live = Tabs.Main:AddParagraph({
    Title = "Live",
    Content = "state: OFF • side: - • speed: - • hits: 0",
})

MainSection:AddToggle("Enabled", {
    Title = "Auto-Play",
    Description = "Toggle automatic key presses",
    Default = false,
    Callback = function(state)
        enabled = state
        if not enabled then
            resetRun()
        end
        Fluent:Notify({
            Title = "BFNFR Auto-Play",
            Content = enabled and "Auto-Play enabled" or "Auto-Play disabled",
            Duration = 2,
        })
    end,
})

MainSection:AddToggle("AntiAfk", {
    Title = "Anti-AFK",
    Description = "Jump every 10s while in a track",
    Default = true,
    Callback = function(state)
        antiAfk = state
    end,
})

MainSection:AddSlider("PerfectChance", {
    Title = "Perfect chance",
    Description = "Base chance for a Perfect; each note randomizes 59-62%",
    Default = perfectChance,
    Min = 0,
    Max = 100,
    Rounding = 1,
    Callback = function(Value)
        perfectChance = Value
    end,
})

MainSection:AddKeybind("ToggleKey", {
    Title = "Toggle keybind",
    Description = "Quickly turn Auto-Play on/off",
    Mode = "Toggle",
    Default = "H",
    Callback = function()
        Options.Enabled:SetValue(not Options.Enabled.Value)
    end,
})

Tabs.Info:AddParagraph({
    Title = "BFNFR Auto-Play",
    Content = "Premium auto player for Basically FNF: Remix\nby iwakewar team\n\n- Plays your lane with your own keybinds\n- Full Hit/Release animations (real key events)\n- Holds pressed and released correctly\n- Perfect chance randomizes 59-62%\n- Anti-AFK built in\n\nPress H (or your keybind) to toggle.",
})

Tabs.Info:AddButton({
    Title = "Our Discord Server",
    Description = "Copy invite link to clipboard",
    Callback = function()
        local copied = copyToClipboard("https://discord.gg/GgshjzxxFS")
        Fluent:Notify({
            Title = "BFNFR Auto-Play",
            Content = copied and "Discord link copied" or "No clipboard API on this executor",
            Duration = 2,
        })
    end,
})

-- live status refresh
task.spawn(function()
    while true do
        task.wait(1)
        if Fluent.Unloaded then break end
        local inTrack = mf.Visible
        local state = enabled and (inTrack and "IN TRACK" or "ON — waiting for a track…") or "OFF"
        pcall(function()
            Status:SetContent(state .. (inTrack and ("  •  side: P" .. (mySide or "-")) or ""))
        end)
        local stxt = enabled and "ON" or "OFF"
        local side = mySide and tostring(mySide) or "-"
        local jf = mf:FindFirstChild("JudgmentsFrame")
        local counts = {}
        if jf then
            local function grab(name)
                local f = jf:FindFirstChild(name)
                local lb = f and f:FindFirstChildOfClass("TextLabel")
                return lb and lb.Text or "0"
            end
            counts.Perfect = grab("Perfect")
            counts.Sick = grab("Sick")
            counts.Good = grab("Good")
            counts.Bad = grab("Bad")
        end
        pcall(function()
            Live:SetContent(
                "state: " .. stxt .. "  •  side: P" .. side .. "  •  speed: " .. speed
                    .. "  •  Perfect " .. (counts.Perfect or "-")
                    .. " / Sick " .. (counts.Sick or "-")
                    .. " / Good " .. (counts.Good or "-")
                    .. " / Bad " .. (counts.Bad or "-")
                    .. "  •  hits: " .. hits
            )
        end)
    end
end)

-- core loop
RunService.Heartbeat:Connect(function()
    if not enabled then
        if mySide ~= nil then resetRun() end
        return
    end
    if not mf.Visible then
        if mySide ~= nil then resetRun() end
        return
    end
    if not speedLock then
        if fetchSettings() then
            speedLock = true
        end
    end
    if not mySide then
        mySide = detectSide()
        if not mySide then return end
        Fluent:Notify({
            Title = "BFNFR Auto-Play",
            Content = "Side detected: P" .. mySide .. " / speed " .. speed,
            Duration = 3,
        })
    end
    if antiAfk then
        local now = os.clock()
        if now - lastJump >= 10 then
            lastJump = now
            local ch = plr.Character
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                hum.Jump = true
            end
        end
    end
    local sideNum = mySide :: number
    local ks = mf:FindFirstChild("KeySync" .. sideNum)
    if not ks then return end
    for lane = 1, 4 do
        if not laneKeys[lane] then continue end
        if held[lane] then continue end
        local ar = ks:FindFirstChild("Arrow" .. lane)
        if not ar then continue end
        local Notes = ar:FindFirstChild("Notes")
        if not Notes then continue end
        for _, note in ipairs(Notes:GetChildren()) do
            if note:IsA("ImageLabel") and note:GetAttribute("HoldHead") == true then
                local t = note:GetAttribute("T")
                if t == nil then continue end
                local st = tracked[note]
                if not st then
                    st = { target = pickTarget(), lastSign = nil, fired = false }
                    tracked[note] = st
                end
                local scale = note.Position.Y.Scale
                if math.abs(scale) > 11 * speed + 1 then
                    st.lastSign = nil
                end
                local s = scale
                local crossing = false
                if st.lastSign then
                    if s < 0 and st.lastSign >= 0 then crossing = true end
                    if s > 0 and st.lastSign <= 0 then crossing = true end
                end
                st.lastSign = s
                if not st.fired then
                    local curMs = math.abs(scale) / (11 * speed) * 2000
                    local aimAt = st.target + inputLead + 30
                    if crossing or curMs <= aimAt then
                        st.fired = true
                        hits = hits + 1
                        local dt = math.max(0, math.min((curMs - (st.target + inputLead)) / 1000, 0.08))
                        task.delay(dt, function()
                            if not note.Parent then return end
                            pressKey(lane)
                            local pressClock = os.clock()
                            task.spawn(function()
                                for i = 1, 8 do
                                    if not note.Parent then
                                        local latMs = math.clamp((os.clock() - pressClock) * 1000, 0, 200)
                                        inputLead = clampNum(inputLead + (latMs - inputLead) * 0.25, 0, 80)
                                        break
                                    end
                                    RunService.Heartbeat:Wait()
                                end
                            end)
                            if findHoldFrame(ar, note.Name) then
                                startHold(lane, note.Name, ks)
                            else
                                task.spawn(function()
                                    RunService.Heartbeat:Wait()
                                    if not held[lane] then releaseKey(lane) end
                                end)
                            end
                        end)
                    end
                end
            end
        end
    end
end)

Fluent:Notify({
    Title = "BFNFR Auto-Play",
    Content = "Loaded. Toggle with H.",
    Duration = 4,
})