-- AdaptiveSpeed v1 (Forsaken-safe): не трогает WalkSpeed, только CFrame-дотяжка
local AdaptiveSpeed = {}
AdaptiveSpeed.Config = {
	BaseAuto = true, BaseFallback = 16,
	MinMult = 1.0, MaxMult = 1.25, StepUp = 0.05, StepUpEvery = 1.5,
	StepDown = 0.20, RubberDist = 3.0, Cooldown = 3.0, PanicAfter = 3, PanicFor = 10,
}
local S = { mult = 1.0, base = 16, lastPos = nil, lastUp = 0, detects = {}, safeUntil = 0, offUntil = 0, conn = nil }
local function now() return os.clock() end
local function median(t)
	table.sort(t)
	return t[math.ceil(#t / 2)]
end
function AdaptiveSpeed.MeasureBaseline(hum, n)
	local s = {}
	for i = 1, (n or 10) do
		if hum and hum.Parent then table.insert(s, hum.WalkSpeed) end
		task.wait(0.1)
	end
	if #s == 0 then return AdaptiveSpeed.Config.BaseFallback end
	return median(s)
end
local function pruneDetects(t)
	local out = {}
	for _, v in ipairs(S.detects) do
		if t - v < 15 then table.insert(out, v) end
	end
	S.detects = out
end
local function isRubberband(prevPos, curPos, moveDir, expectedStep)
	if not prevPos or moveDir.Magnitude < 0.1 then return false end
	local delta = curPos - prevPos
	local forward = delta:Dot(moveDir)
	local backJump = expectedStep - forward
	if backJump > AdaptiveSpeed.Config.RubberDist and forward < expectedStep * 0.3 then
		return true
	end
	if delta.Magnitude > 8 and forward < -2 then
		return true
	end
	return false
end
function AdaptiveSpeed.Start()
	local C = AdaptiveSpeed.Config
	local plr = game.Players.LocalPlayer
	local rs = game:GetService("RunService")
	if S.conn then S.conn:Disconnect() end
	S.conn = nil
	task.spawn(function()
		local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
		if C.BaseAuto and hum then S.base = AdaptiveSpeed.MeasureBaseline(hum, 10) end
	end)
	S.lastPos = nil
	S.conn = rs.Heartbeat:Connect(function(dt)
		dt = math.min(dt, 0.1)
		local t = now()
		local char = plr.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hum or not hrp or hum.Health <= 0 then S.lastPos = nil return end
		if hrp.Anchored or hum.Seated then S.lastPos = nil return end
		local cur = hrp.Position
		local md = hum.MoveDirection
		if S.lastPos then
			local expected = S.base * S.mult * dt
			if isRubberband(S.lastPos, cur, md, expected) then
				table.insert(S.detects, t)
				pruneDetects(t)
				S.mult = math.max(C.MinMult, S.mult - C.StepDown)
				S.safeUntil = t + C.Cooldown
				if #S.detects >= C.PanicAfter then
					S.offUntil = t + C.PanicFor
					S.mult = C.MinMult
					S.detects = {}
					warn(("[AdaptiveSpeed] PANIC: пауза %ds"):format(C.PanicFor))
				else
					warn(("[AdaptiveSpeed] rollback -> mult=%.2f"):format(S.mult))
				end
				S.lastPos = cur
				return
			end
		end
		if t > S.safeUntil and t > S.offUntil and md.Magnitude > 0.1 then
			if t - S.lastUp > C.StepUpEvery and S.mult < C.MaxMult then
				S.mult = math.min(C.MaxMult, S.mult + C.StepUp)
				S.lastUp = t
			end
			local extra = S.base * (S.mult - 1.0) * dt
			if extra > 0.001 then
				local flat = Vector3.new(md.X, 0, md.Z)
				if flat.Magnitude > 0.01 then
					hrp.CFrame = hrp.CFrame + flat.Unit * extra
				end
			end
		end
		S.lastPos = hrp.Position
	end)
	return S.conn
end
function AdaptiveSpeed.Stop()
	if S.conn then S.conn:Disconnect() S.conn = nil end
	S.mult = 1.0
	S.lastPos = nil
end
function AdaptiveSpeed.State() return { mult = S.mult, base = S.base, detects = #S.detects } end
return AdaptiveSpeed
