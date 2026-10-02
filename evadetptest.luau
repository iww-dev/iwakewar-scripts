local LP = game.Players.LocalPlayer
local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
if not hrp then return "no char" end
local res = {}
for i = 1, 5 do
  local p0 = hrp.Position
  hrp.CFrame = CFrame.new(p0 + Vector3.new(80, 3, 0))
  task.wait(0.5)
  local p1 = hrp.Position
  local kept = (Vector3.new(p1.X, 0, p1.Z) - Vector3.new(p0.X, 0, p0.Z)).Magnitude
  table.insert(res, math.floor(kept))
  if job.cancelled() then break end
end
return { jumps = table.concat(res, ","), alive = LP.Character:FindFirstChildOfClass("Humanoid").Health }
