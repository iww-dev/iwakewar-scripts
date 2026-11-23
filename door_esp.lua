-- TSB — Door + Penyta ESP + instant prompts + candy farm. Single-file, re-execution safe.
-- ESP is built from Highlight + BillboardGui: the Drawing API silently renders
-- nothing in some clients (Saiko included), which is why the old version showed
-- no boxes at all. Instances always render.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local lp = Players.LocalPlayer

-- ===== state =====
-- Keep the old table around (a previous version's loop may still hold it) but
-- move to a fresh one so a stale loop can never draw/teleport anymore.
local old = getgenv().TsbState
local st = {
	door = true,
	penyta = true,
	scream = (old and old.scream ~= nil) and old.scream or true,
	farm = false,
	farmMode = (old and old.farmMode) or "Old",
	v = 3,
}
if type(old) == "table" then
	old.door, old.penyta, old.farm = false, false, false
end
getgenv().TsbState = st

-- tear down the previous run of THIS version (only our own objects/connections)
local prev = getgenv().__tsbEsp
if type(prev) == "table" and type(prev.cleanup) == "function" then
	pcall(prev.cleanup)
end

local esp = { doors = {}, peny = {}, conns = {}, objects = {} }
getgenv().__tsbEsp = esp

local function track(o)
	esp.objects[#esp.objects + 1] = o
	return o
end
local function trackConn(c)
	esp.conns[#esp.conns + 1] = c
	return c
end

function esp.cleanup()
	for _, c in ipairs(esp.conns) do pcall(function() c:Disconnect() end) end
	table.clear(esp.conns)
	for _, o in ipairs(esp.objects) do pcall(function() o:Destroy() end) end
	table.clear(esp.objects)
	table.clear(esp.doors)
	table.clear(esp.peny)
	if getgenv().__tsbEsp == esp then getgenv().__tsbEsp = nil end
	local pc = getgenv()._tsbPromptConn
	if pc then
		pcall(function() pc:Disconnect() end)
		getgenv()._tsbPromptConn = nil
	end
end

-- ===== Penyta spawn scream (5s looped alarm) =====
local function playScream()
	if not st.scream then return end
	local s = Instance.new("Sound")
	s.Name = "TsbScream"
	s.SoundId = "rbxassetid://9118400465"
	s.Volume = 12
	s.Looped = true
	s.Parent = SoundService
	s:Play()
	task.delay(5, function() pcall(function() s:Stop() s:Destroy() end) end)
end

-- ===== ESP helpers =====
local DOOR_COLOR = Color3.fromRGB(255, 176, 32)
local PENY_COLOR = Color3.fromRGB(255, 60, 120)

local function makeHighlight(model, color)
	local hl = Instance.new("Highlight")
	hl.Name = "TsbEspHighlight"
	hl.Adornee = model
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.FillColor = color
	hl.FillTransparency = 1
	hl.OutlineColor = color
	hl.OutlineTransparency = 0
	hl.Parent = model
	return track(hl)
end

local function makeLabel(part, color, worldOffsetY)
	local bg = Instance.new("BillboardGui")
	bg.Name = "TsbEspLabel"
	bg.Adornee = part
	bg.AlwaysOnTop = true
	bg.LightInfluence = 0
	bg.MaxDistance = 3000
	bg.Size = UDim2.fromOffset(150, 26)
	bg.StudsOffsetWorldSpace = Vector3.new(0, worldOffsetY, 0)
	bg.Parent = part
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.BorderSizePixel = 0
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 14
	lbl.TextColor3 = color
	lbl.TextStrokeTransparency = 0.35
	lbl.Text = ""
	lbl.Parent = bg
	track(bg)
	return bg, lbl
end

-- ===== DOOR trees =====
local function addDoor(tree)
	if esp.doors[tree] or not tree.Parent then return end
	local door = tree:FindFirstChild("DOOR 1 NEW", true)
	if not door then return end
	local part = door.PrimaryPart or door:FindFirstChild("Frame", true)
	if not part then return end
	local e = {
		model = door,
		part = part,
		hl = makeHighlight(door, DOOR_COLOR),
	}
	e.gui, e.label = makeLabel(part, DOOR_COLOR, part.Size.Y / 2 + 1.2)
	esp.doors[tree] = e
end

-- ===== PENYTA (model under Workspace/Live named Penyta/pinata) =====
local function isPeny(n)
	n = string.lower(tostring(n))
	return n:find("peny") ~= nil or n:find("pinata") ~= nil
end

local function hpOf(obj)
	local hp = obj:GetAttribute("PinataHP")
	local mx = obj:GetAttribute("PinataMax")
	if hp == nil or mx == nil then
		local h = obj:FindFirstChildOfClass("Humanoid")
		if h then hp = hp or h.Health mx = mx or h.MaxHealth end
	end
	return hp, mx
end

local function addPeny(obj)
	if esp.peny[obj] or not obj.Parent then return end
	local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
	if not part then return end
	local e = {
		model = obj,
		part = part,
		hl = makeHighlight(obj, PENY_COLOR),
	}
	e.gui, e.label = makeLabel(part, PENY_COLOR, part.Size.Y / 2 + 1.6)
	esp.peny[obj] = e
	playScream()
end

local function prune(map, field)
	for obj, e in pairs(map) do
		if not obj.Parent or not e.part.Parent then
			pcall(function() e.hl:Destroy() e.gui:Destroy() end)
			map[obj] = nil
		end
	end
end

local function scan()
	local dt = workspace:FindFirstChild("HalloweenDoorTrees")
	if dt then
		for _, t in ipairs(dt:GetChildren()) do
			if t:IsA("Model") then pcall(addDoor, t) end
		end
	end
	local live = workspace:FindFirstChild("Live")
	if live then
		for _, c in ipairs(live:GetChildren()) do
			if c:IsA("Model") and isPeny(c.Name) then pcall(addPeny, c) end
		end
	end
	prune(esp.doors)
	prune(esp.peny)
end
scan()

-- ===== update loop (single, ours only) =====
local uiAcc, scanAcc = 0, 0
trackConn(RunService.Heartbeat:Connect(function(dt)
	uiAcc = uiAcc + dt
	scanAcc = scanAcc + dt
	if scanAcc >= 1.5 then
		scanAcc = 0
		pcall(scan)
	end
	if uiAcc < 0.1 then return end
	uiAcc = 0
	local cam = workspace.CurrentCamera
	local cpos = cam and cam.CFrame.Position or Vector3.zero
	for _, e in pairs(esp.doors) do
		local on = st.door and e.part.Parent ~= nil
		e.hl.Enabled = on
		e.gui.Enabled = on
		if on then
			e.label.Text = string.format("DOOR  %.0fm", (e.part.Position - cpos).Magnitude)
		end
	end
	for obj, e in pairs(esp.peny) do
		local on = st.penyta and e.part.Parent ~= nil
		e.hl.Enabled = on
		e.gui.Enabled = on
		if on then
			local hp, mx = hpOf(obj)
			hp = hp and (math.floor(hp * 10 + 0.5) / 10) or "?"
			mx = mx and (math.floor(mx * 10 + 0.5) / 10) or "?"
			e.label.Text = string.format("PENYTA  hp %s/%s  %.0fm", tostring(hp), tostring(mx), (e.part.Position - cpos).Magnitude)
		end
	end
end))

-- ===== CandyFarm (teleport to every dropped candy as fast as possible) =====
local candyNames = {}
pcall(function()
	for _, d in ipairs(game:GetService("ReplicatedStorage").HalloweenEvent.Candy:GetChildren()) do
		candyNames[d.Name] = true
	end
end)
candyNames.BloxRoll = true candyNames.MrBloxBar = true

local function isLiveCandy(d)
	return d:IsA("BasePart") and candyNames[d.Name] ~= nil and d.Position.Y > -5000
end
local function getCandies()
	local out = {}
	local cv = workspace:FindFirstChild("CandyVisuals")
	if cv then
		for _, d in ipairs(cv:GetDescendants()) do
			if isLiveCandy(d) then table.insert(out, d) end
		end
	end
	return out
end
local function getHRP()
	local char = lp.Character
	return char and (char.PrimaryPart or char:FindFirstChild("HumanoidRootPart"))
end
local function getComm()
	local char = lp.Character
	return char and char:FindFirstChild("Communicate", true)
end
local function teleport(pos)
	local hrp = getHRP()
	if not hrp then return end
	hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
	local comm = getComm()
	if comm then pcall(function() comm:FireServer({ Goal = "LeftClick", MousePos = CFrame.new(pos) }) end) end
end

local farmAccum = 1
trackConn(RunService.Heartbeat:Connect(function(dt)
	if not st.farm then farmAccum = 1 return end
	farmAccum = farmAccum + dt
	if farmAccum < 0.12 then return end
	farmAccum = 0
	local me = getHRP()
	if not me then return end
	local mp = me.Position
	local best, bd
	for _, c in ipairs(getCandies()) do
		local dd = (c.Position - mp).Magnitude
		if not bd or dd < bd then bd = dd best = c end
	end
	if best then teleport(best.Position) end
end))

-- ===== instant prompts =====
local function patchPrompt(p)
	p.HoldDuration = 0
	p.MaxActivationDistance = math.max(p.MaxActivationDistance, 32)
	if p.Parent and p.Parent:IsA("BasePart") then p.RequiresLineOfSight = false end
end
local function patchAllPrompts()
	for _, r in ipairs({ workspace, game:GetService("ReplicatedStorage"), game:GetService("StarterGui") }) do
		pcall(function()
			for _, d in ipairs(r:GetDescendants()) do
				if d:IsA("ProximityPrompt") then patchPrompt(d) end
			end
		end)
	end
end
local function setPromptPatch(on)
	if on then
		patchAllPrompts()
		if not getgenv()._tsbPromptConn then
			getgenv()._tsbPromptConn = workspace.DescendantAdded:Connect(function(d)
				if d:IsA("ProximityPrompt") then task.defer(patchPrompt, d) end
			end)
		end
	elseif getgenv()._tsbPromptConn then
		pcall(function() getgenv()._tsbPromptConn:Disconnect() end)
		getgenv()._tsbPromptConn = nil
	end
end

-- ===== GUI (anchor-centered; no stretched parent frame) =====
local gparent = (gethui and gethui()) or game:GetService("CoreGui")
local existing = gparent:FindFirstChild("DoorEspUi")
if existing then existing:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "DoorEspUi"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = gparent

local W, H = 200, 130
local win = Instance.new("Frame")
win.AnchorPoint = Vector2.new(0.5, 0.5)
win.Position = UDim2.new(0.5, 0, 0.5, 0)
win.Size = UDim2.new(0, W, 0, H)
win.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
win.BorderSizePixel = 0
win.Active = true
win.Draggable = true
win.Parent = gui
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 4, 0, 2)
title.Size = UDim2.new(0, 160, 0, 16)
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(180, 180, 190)
title.Text = "TSB"
title.Parent = win

local ON = Color3.fromRGB(70, 160, 90)
local OFF = Color3.fromRGB(40, 40, 48)
local function mkbtn(y, text)
	local b = Instance.new("TextButton")
	b.Position = UDim2.new(0, 6, 0, y)
	b.Size = UDim2.new(0, W - 12, 0, 24)
	b.BackgroundColor3 = OFF
	b.BorderSizePixel = 0
	b.Font = Enum.Font.GothamMedium
	b.TextSize = 13
	b.TextColor3 = Color3.fromRGB(235, 235, 240)
	b.AutoButtonColor = false
	b.Parent = win
	b.Text = text
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	return b
end

local btnDoor = mkbtn(22, "Toggle Door's: " .. (st.door and "ON" or "OFF"))
local btnPen = mkbtn(50, "Toggle Penyta's: " .. (st.penyta and "ON" or "OFF"))
local btnScream = mkbtn(78, "Scream: " .. (st.scream and "ON" or "OFF"))
local btnFarm = mkbtn(106, "CandyFarm: " .. (st.farm and "ON" or "OFF"))
if st.door then btnDoor.BackgroundColor3 = ON end
if st.penyta then btnPen.BackgroundColor3 = ON end
if st.scream then btnScream.BackgroundColor3 = ON end
if st.farm then btnFarm.BackgroundColor3 = ON end

btnDoor.MouseButton1Click:Connect(function()
	st.door = not st.door
	btnDoor.Text = "Toggle Door's: " .. (st.door and "ON" or "OFF")
	TweenService:Create(btnDoor, TweenInfo.new(0.15), { BackgroundColor3 = st.door and ON or OFF }):Play()
	setPromptPatch(st.door)
end)

btnPen.MouseButton1Click:Connect(function()
	st.penyta = not st.penyta
	btnPen.Text = "Toggle Penyta's: " .. (st.penyta and "ON" or "OFF")
	TweenService:Create(btnPen, TweenInfo.new(0.15), { BackgroundColor3 = st.penyta and ON or OFF }):Play()
end)

btnScream.MouseButton1Click:Connect(function()
	st.scream = not st.scream
	btnScream.Text = "Scream: " .. (st.scream and "ON" or "OFF")
	TweenService:Create(btnScream, TweenInfo.new(0.15), { BackgroundColor3 = st.scream and ON or OFF }):Play()
end)

btnFarm.MouseButton1Click:Connect(function()
	st.farm = not st.farm
	btnFarm.Text = "CandyFarm: " .. (st.farm and "ON" or "OFF")
	TweenService:Create(btnFarm, TweenInfo.new(0.15), { BackgroundColor3 = st.farm and ON or OFF }):Play()
end)

setPromptPatch(st.door)

task.delay(0.6, function()
	local dn, pn = 0, 0
	for _ in pairs(esp.doors) do dn = dn + 1 end
	for _ in pairs(esp.peny) do pn = pn + 1 end
	print("[TSB] loaded; doors:", dn, "peny:", pn)
end)
