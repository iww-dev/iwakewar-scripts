-- ultrafling v1 | pendulum ram | no fluent, ancient style
-- by iwakewar team
-- Visual: main.luau palette (Code font, flat 16,16,16 panels, 1px 70,70,70
-- borders, 0 corners, acid-green 0,255,0 accents, terminal console).
-- Engine: asymmetric pendulum ram. NOT the "fly around them" spinbot:
-- every Heartbeat we snap between two points on opposite sides of the
-- victim, offset toward the fling axis (A = full amplitude, B = 0.3 back),
-- spinning the whole time, noclipped. Contact transfers momentum along
-- the axis instead of random chaos. Then we stop and snap back home.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer

local F = Enum.Font.Code
local C_PANEL = Color3.fromRGB(16, 16, 16)
local C_LINE = Color3.fromRGB(70, 70, 70)
local C_TXT = Color3.fromRGB(220, 220, 220)
local C_DIMTXT = Color3.fromRGB(140, 140, 140)
local C_GREEN = Color3.fromRGB(0, 255, 0)
local C_DGREEN = Color3.fromRGB(0, 180, 0)
local C_RED = Color3.fromRGB(255, 60, 60)

local cfg = { spin = true, upbias = true, power = 3, dur = 4.0 }
local POWERS = { 2, 3, 5 }

local genv0 = getgenv and getgenv() or {}
genv0.__ufGen = (genv0.__ufGen or 0) + 1
local myGen = genv0.__ufGen
if genv0.__ufGui and genv0.__ufGui.Parent then
    pcall(function() genv0.__ufGui:Destroy() end)
end

-- state
local active = false
local targetPlr = nil
local backPos = nil
local savedCollide = {}
local spinA = 0
local t0 = 0
local lineN = 0
local conBox = nil
local statusLbl = nil

local function myHRP()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function myAlive()
    local c = LP.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0 or false
end

local function log(t, good)
    lineN = lineN + 1
    if not conBox then return end
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Font = F
    l.Size = UDim2.new(1, 0, 0, 15)
    l.Text = "> " .. tostring(t):sub(1, 60)
    l.TextColor3 = good == false and C_RED or (good == true and C_GREEN or C_DIMTXT)
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextTruncate = Enum.TextTruncate.AtEnd
    l.LayoutOrder = lineN
    l.Parent = conBox
    if lineN > 8 then
        for _, d in ipairs(conBox:GetChildren()) do
            if d:IsA("TextLabel") and d.LayoutOrder <= lineN - 8 then
                d:Destroy()
            end
        end
    end
end

local function setStatus(t, bad)
    if statusLbl then
        statusLbl.Text = "status: " .. t
        statusLbl.TextColor3 = bad and C_RED or C_GREEN
    end
end

local function noclipOn()
    savedCollide = {}
    local c = LP.Character
    if not c then return end
    for _, v in ipairs(c:GetDescendants()) do
        if v:IsA("BasePart") then
            savedCollide[v] = v.CanCollide
            v.CanCollide = false
        end
    end
end

local function noclipOff()
    for p, v in pairs(savedCollide) do
        pcall(function()
            if p and p.Parent then p.CanCollide = v end
        end)
    end
    savedCollide = {}
end

local function stop(silent)
    active = false
    targetPlr = nil
    noclipOff()
    local hrp = myHRP()
    if hrp and backPos then
        pcall(function()
            hrp.CFrame = CFrame.new(backPos)
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end)
    end
    backPos = nil
    setStatus("idle")
    if not silent then log("stopped, back home") end
end

-- asymmetric pendulum ram
local function flingLoop()
    local phase = false
    local axis = Vector3.new(0, 0.7, 0)
    local me0 = myHRP()
    local tp0 = targetPlr and targetPlr.Character and targetPlr.Character:FindFirstChild("HumanoidRootPart")
    if me0 and tp0 then
        local flat = Vector3.new(tp0.Position.X - me0.Position.X, 0, tp0.Position.Z - me0.Position.Z)
        if flat.Magnitude > 1 then
            axis = flat.Unit + Vector3.new(0, cfg.upbias and 0.7 or 0.25, 0)
        end
    end
    log("ramming " .. (targetPlr and targetPlr.Name or "?") .. " amp=" .. cfg.power)
    while active and genv0.__ufGen == myGen do
        local hrp = myHRP()
        local tc = targetPlr and targetPlr.Character
        local th = tc and tc:FindFirstChild("HumanoidRootPart")
        local thh = tc and tc:FindFirstChildOfClass("Humanoid")
        if not hrp or not th or not thh or thh.Health <= 0 or not myAlive() then
            log("target lost/dead", false)
            break
        end
        if os.clock() - t0 > cfg.dur then
            log("time up, released with momentum", true)
            break
        end
        -- keep noclip (game may reset it)
        for _, v in ipairs(LP.Character:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
        end
        phase = not phase
        local k = phase and cfg.power or (cfg.power * -0.3)
        local dest = th.Position + Vector3.new(0, 1.5, 0) + axis * k
        spinA = spinA + 1.1
        pcall(function()
            hrp.CFrame = CFrame.new(dest) * CFrame.Angles(0, spinA, 0.4)
            if cfg.spin then
                hrp.AssemblyAngularVelocity = Vector3.new(0, 60, 12)
            end
        end)
        RunService.Heartbeat:Wait()
    end
    -- release: freeze us, victim keeps velocity
    local hrp = myHRP()
    if hrp then
        pcall(function()
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end)
    end
    stop(true)
    log("done", true)
    setStatus("idle")
end

local function start(plr)
    if active then stop(true) end
    if not plr then log("no target", false) return end
    local tc = plr.Character
    local th = tc and tc:FindFirstChild("HumanoidRootPart")
    if not th then log("target has no HRP", false) return end
    local me = myHRP()
    if not me or not myAlive() then log("we are dead", false) return end
    targetPlr = plr
    backPos = me.Position
    noclipOn()
    active = true
    t0 = os.clock()
    spinA = 0
    setStatus("RAMMING " .. plr.Name)
    task.spawn(flingLoop)
end

local function findByNamePart(n)
    n = string.lower(n)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and string.find(string.lower(p.Name), n, 1, true) then
            return p
        end
    end
    return nil
end

local function nearestPlr()
    local me = myHRP()
    if not me then return nil end
    local best, bd = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local h = p.Character:FindFirstChildOfClass("Humanoid")
            local hr = p.Character:FindFirstChild("HumanoidRootPart")
            if h and h.Health > 0 and hr then
                local d = (hr.Position - me.Position).Magnitude
                if d < bd then best, bd = p, d end
            end
        end
    end
    return best
end

-- ============ GUI (ancient style, no fluent) ============
local sgui = Instance.new("ScreenGui")
sgui.Name = "ultrafling"
sgui.ResetOnSpawn = false
sgui.DisplayOrder = 50
pcall(function() sgui.Parent = game:GetService("CoreGui") end)
if sgui.Parent == nil then sgui.Parent = LP:WaitForChild("PlayerGui") end
genv0.__ufGui = sgui

local win = Instance.new("Frame")
win.AnchorPoint = Vector2.new(0.5, 0.5)
win.BackgroundColor3 = C_PANEL
win.BorderSizePixel = 0
win.Position = UDim2.fromScale(0.5, 0.5)
win.Size = UDim2.fromOffset(360, 330)
win.Parent = sgui
local wb = Instance.new("UIStroke")
wb.Color = C_LINE wb.Thickness = 1
wb.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
wb.Parent = win

local accent = Instance.new("Frame")
accent.BackgroundColor3 = C_GREEN
accent.BorderSizePixel = 0
accent.Size = UDim2.new(1, 0, 0, 2)
accent.Parent = win

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Font = F
title.Position = UDim2.new(0, 10, 0, 8)
title.Size = UDim2.new(1, -70, 0, 20)
title.Text = "> ultrafling_ [pendulum v1]"
title.TextColor3 = C_TXT
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = win

local sub = Instance.new("TextLabel")
sub.BackgroundTransparency = 1
sub.Font = F
sub.Position = UDim2.new(0, 10, 0, 28)
sub.Size = UDim2.new(1, -70, 0, 14)
sub.Text = "pendulum ram // no-fluent ancient style"
sub.TextColor3 = C_DGREEN
sub.TextSize = 12
sub.TextXAlignment = Enum.TextXAlignment.Left
sub.Parent = win

local closeB = Instance.new("TextButton")
closeB.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
closeB.BorderSizePixel = 0
closeB.Font = F
closeB.Position = UDim2.new(1, -34, 0, 8)
closeB.Size = UDim2.fromOffset(24, 24)
closeB.Text = "x"
closeB.TextColor3 = C_RED
closeB.TextSize = 14
closeB.Parent = win
local cs = Instance.new("UIStroke")
cs.Color = C_LINE cs.Thickness = 1
cs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
cs.Parent = closeB
closeB.MouseButton1Click:Connect(function()
    stop(true)
    sgui:Destroy()
end)

-- drag by title
do
    local drag, ds, sp = false, nil, nil
    title.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag, ds, sp = true, i.Position, win.Position
        end
    end)
    title.InputEnded:Connect(function() drag = false end)
    UIS.InputChanged:Connect(function(i)
        if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - ds
            win.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end)
end

local function mkBtn(text, x, w, y)
    local b = Instance.new("TextButton")
    b.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
    b.BorderSizePixel = 0
    b.Font = F
    b.Position = UDim2.new(0, x, 0, y)
    b.Size = UDim2.new(0, w, 0, 26)
    b.Text = text
    b.TextColor3 = C_TXT
    b.TextSize = 13
    b.AutoButtonColor = false
    b.Parent = win
    local st = Instance.new("UIStroke")
    st.Color = C_LINE st.Thickness = 1
    st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    st.Parent = b
    b.MouseEnter:Connect(function() b.BackgroundColor3 = Color3.fromRGB(34, 34, 34) end)
    b.MouseLeave:Connect(function() b.BackgroundColor3 = Color3.fromRGB(24, 24, 24) end)
    return b
end

local nameBox = Instance.new("TextBox")
nameBox.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
nameBox.BorderSizePixel = 0
nameBox.Font = F
nameBox.Position = UDim2.new(0, 10, 0, 50)
nameBox.Size = UDim2.new(0, 190, 0, 26)
nameBox.Text = ""
nameBox.PlaceholderText = "target name..."
nameBox.TextColor3 = C_TXT
nameBox.TextSize = 13
nameBox.TextXAlignment = Enum.TextXAlignment.Left
nameBox.ClearTextOnFocus = false
nameBox.Parent = win
local ns = Instance.new("UIStroke")
ns.Color = Color3.fromRGB(50, 50, 50) ns.Thickness = 1
ns.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
ns.Parent = nameBox

local setB = mkBtn("[ set ]", 206, 66, 50)
local nearB = mkBtn("[ near ]", 278, 72, 50)
local curTarget: Player? = nil
setB.MouseButton1Click:Connect(function()
    curTarget = findByNamePart(nameBox.Text)
    log(curTarget and ("target: " .. curTarget.Name) or "not found", curTarget ~= nil)
end)
nearB.MouseButton1Click:Connect(function()
    curTarget = nearestPlr()
    if curTarget then nameBox.Text = curTarget.Name end
    log(curTarget and ("target: " .. curTarget.Name) or "nobody near", curTarget ~= nil)
end)

local spinB = mkBtn("[spin: on]", 10, 106, 84)
local upB = mkBtn("[upbias: on]", 122, 116, 84)
local powB = mkBtn("[power: 3]", 244, 106, 84)
spinB.MouseButton1Click:Connect(function()
    cfg.spin = not cfg.spin
    spinB.Text = cfg.spin and "[spin: on]" or "[spin: off]"
end)
upB.MouseButton1Click:Connect(function()
    cfg.upbias = not cfg.upbias
    upB.Text = cfg.upbias and "[upbias: on]" or "[upbias: off]"
end)
powB.MouseButton1Click:Connect(function()
    local i = 1
    for k, v in ipairs(POWERS) do if v == cfg.power then i = k break end end
    cfg.power = POWERS[(i % #POWERS) + 1]
    powB.Text = "[power: " .. cfg.power .. "]"
end)

local flingB = mkBtn("[ FLING ]", 10, 170, 118)
flingB.TextColor3 = C_GREEN
local stopB = mkBtn("[ STOP ]", 186, 164, 118)
stopB.TextColor3 = C_RED
flingB.MouseButton1Click:Connect(function() start(curTarget) end)
stopB.MouseButton1Click:Connect(function() stop() end)

statusLbl = Instance.new("TextLabel")
statusLbl.BackgroundTransparency = 1
statusLbl.Font = F
statusLbl.Position = UDim2.new(0, 10, 0, 150)
statusLbl.Size = UDim2.new(1, -20, 0, 16)
statusLbl.Text = "status: idle"
statusLbl.TextColor3 = C_GREEN
statusLbl.TextSize = 13
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.Parent = win

conBox = Instance.new("Frame")
conBox.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
conBox.BorderSizePixel = 0
conBox.Position = UDim2.new(0, 10, 0, 172)
conBox.Size = UDim2.new(1, -20, 0, 148)
conBox.Parent = win
local cst = Instance.new("UIStroke")
cst.Color = Color3.fromRGB(50, 50, 50) cst.Thickness = 1
cst.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
cst.Parent = conBox
local lay = Instance.new("UIListLayout")
lay.FillDirection = Enum.FillDirection.Vertical
lay.Padding = UDim.new(0, 1)
lay.SortOrder = Enum.SortOrder.LayoutOrder
lay.Parent = conBox
local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0, 6)
pad.PaddingTop = UDim.new(0, 4)
pad.Parent = conBox

LP.CharacterAdded:Connect(function()
    if active then stop(true) log("respawned, stopped", false) end
end)

log("ultrafling ready. pick target, press FLING.", true)
setStatus("idle")
print("[ultrafling] ready")
