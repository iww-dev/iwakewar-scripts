-- Autoplay v2 for Basically FNF: Remix
-- Presses the REAL lane keys through VirtualInputManager instead of firing
-- the hit remote directly, so the game's own KeyPress -> NoteInput runs:
-- arrow/skin animation, character animation, combo, sound and the remote,
-- exactly like a human press. Works with the player's own keybinds.
-- Press H to toggle.
-- Holds: the key is kept down until the hold body has fully scrolled past,
-- then released, matching the game's own v6+v7<=1.5 completion check.
-- Anti-AFK: jumps every 10s while a match is on screen (the simulated key
-- presses also reset the game's own 45s AFK timer anyway).
local plr = game.Players.LocalPlayer
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local mf = plr.PlayerGui:WaitForChild("Main"):WaitForChild("MatchFrame")
local DataF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("DataF")

local enabled = true
local mySide: number? = nil
local speed = 1
local dir = -1
local laneKeys: { [number]: Enum.KeyCode } = {}
local speedLock = false
local tracked = setmetatable({}, { __mode = "k" })
local held = {} -- lane -> true while we keep a hold key down
local lastJump = 0

local DEFAULT_KEYS = { "D", "F", "J", "K", "Left", "Down", "Up", "Right" }

local function clampNum(v: number, a: number, b: number): number
    if v < a then return a elseif v > b then return b end
    return v
end

local function fetchSettings()
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
    if math.random() <= 0.59 then
        return math.random() * 16.5
    end
    return 16.5 + math.random() * 27.0
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

local function startHold(lane: number, noteName: string, ks: Instance)
    if held[lane] then return end
    held[lane] = true
    task.spawn(function()
        local ar = ks:FindFirstChild("Arrow" .. lane)
        local hitbox = ar and ar:FindFirstChild("Hold") and ar.Hold:FindFirstChild("Hitbox")
        local guard = os.clock() + 120
        while held[lane] do
            local frame = hitbox and hitbox:FindFirstChild("Hold_" .. noteName)
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

RunService.Heartbeat:Connect(function()
    if not enabled then return end
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
        print("[autoplay] side = " .. mySide .. " speed = " .. speed)
    end
    local now = os.clock()
    if now - lastJump >= 10 then
        lastJump = now
        local ch = plr.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            hum.Jump = true
        end
    end
    local sideNum = mySide :: number
    local ks = mf:FindFirstChild("KeySync" .. sideNum)
    if not ks then return end
    local dirV = dir
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
                    if crossing or curMs <= st.target then
                        st.fired = true
                        pressKey(lane)
                        if note:GetAttribute("LNHold") == true then
                            startHold(lane, note.Name, ks)
                        else
                            task.spawn(function()
                                RunService.Heartbeat:Wait()
                                if not held[lane] then releaseKey(lane) end
                            end)
                        end
                    end
                end
            end
        end
    end
end)

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.H then
        enabled = not enabled
        if not enabled then
            resetRun()
        end
        print("[autoplay] " .. (enabled and "ON" or "OFF"))
    end
end)