local LP = game.Players.LocalPlayer
local ch = LP.Character
local hum = ch and ch:FindFirstChildOfClass("Humanoid")
local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
if not hum or not hrp then return "no char" end
local seat = game.Workspace.Blocks.Sfsxs0:FindFirstChild("CarSeat", true)
if seat and seat:IsA("Model") then seat = seat:FindFirstChildOfClass("VehicleSeat") or seat:FindFirstChildOfClass("Seat") end
if not seat then
  for _, v in ipairs(game.Workspace.Blocks.Sfsxs0:GetDescendants()) do
    if v:IsA("Seat") or v:IsA("VehicleSeat") then seat = v break end
  end
end
if not seat then return "no seat" end
hrp.CFrame = seat.CFrame + Vector3.new(0, 3, 0)
task.wait(0.5)
pcall(function() seat:Sit(hum) end)
task.wait(1.0)
local sat = hum.SeatPart ~= nil
job.log("seated=" .. tostring(sat))
if not sat then return "sit failed" end
local z = game.Workspace:FindFirstChild("Really redZone")
z.VoteLaunchRE:FireServer()
task.wait(2)
return { seated = sat, launched = z.Launched.Value }
