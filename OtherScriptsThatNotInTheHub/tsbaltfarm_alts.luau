local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local TARGET_POS = Vector3.new(-36.46, 29.25, 20393.31)
local function teleportToTarget(character)
if not character then return end
local hrp = character:WaitForChild("HumanoidRootPart", 5)
local humanoid = character:WaitForChild("Humanoid", 5)
if hrp and humanoid and humanoid.Health > 0 then
hrp.Velocity = Vector3.new(0, 0, 0)
hrp.RotVelocity = Vector3.new(0, 0, 0)
hrp.CFrame = CFrame.new(TARGET_POS)
end
end
LocalPlayer.CharacterAdded:Connect(function(character)
teleportToTarget(character)
end)
if LocalPlayer.Character then
task.spawn(teleportToTarget, LocalPlayer.Character)
end
local loopConnection
loopConnection = RunService.Heartbeat:Connect(function()
local character = LocalPlayer.Character
if character then
local hrp = character:FindFirstChild("HumanoidRootPart")
local humanoid = character:FindFirstChild("Humanoid")
if hrp and humanoid and humanoid.Health > 0 then
hrp.Velocity = Vector3.new(0, 0, 0)
hrp.CFrame = CFrame.new(TARGET_POS)
end
end
end)
if _G.ResetLoopGoto then
_G.ResetLoopGoto()
end
_G.ResetLoopGoto = function()
if loopConnection then
loopConnection:Disconnect()
end
end
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
if setfpscap then
setfpscap(13)
elseif set_fps_cap then
set_fps_cap(0.5)
end
task.spawn(function()
pcall(function()
RunService:Set3dRenderingEnabled(false)
end)
end)
SoundService.MasterVolume = 0
for _, sound in pairs(game:GetDescendants()) do
if sound:IsA("Sound") then
sound:Stop()
sound.Volume = 0
end
end
game.DescendantAdded:Connect(function(descendant)
if descendant:IsA("Sound") then
descendant:Stop()
descendant.Volume = 0
end
end)
for _, obj in pairs(Workspace:GetDescendants()) do
if obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
obj.Enabled = false
elseif obj:IsA("Light") then
obj.Enabled = false
end
end
local Gui = Instance.new("ScreenGui")
Gui.Name = "UltraOptimizationGui"
Gui.IgnoreGuiInset = true
Gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(1, 0, 1, 0)
Frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
Frame.Parent = Gui
local Text = Instance.new("TextLabel")
Text.Size = UDim2.new(1, 0, 1, 0)
Text.Text = "\nFPS: 0.5\n3D Render: OFF\nSounds: OFF"
Text.TextColor3 = Color3.fromRGB(255, 65, 65)
Text.TextSize = 22
Text.Font = Enum.Font.RobotoMono
Text.Parent = Frame
local VirtualUser = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:Connect(function()
VirtualUser:CaptureController()
VirtualUser:ClickButton2(Vector2.new(0, 0))
end)
if setfpscap then
setfpscap(0.4)
elseif set_fps_cap then
set_fps_cap(0.5)
end
task.spawn(function()
while task.wait(15) do
pcall(function()
collectgarbage("count")
end)
end
end)
pcall(function()
local renderSettings = settings().Rendering :: any
local rawEnum = Enum :: any
    
renderSettings.QualityLevel = rawEnum.QualityLevel.Level01
renderSettings.SavedQualityLevel = rawEnum["SavedQualityLevel"].Level01
renderSettings.FrameRateManager = rawEnum["FrameRateManager"].Off
renderSettings.EagerBulkExecution = false
end)
local CoreGui = (gethui and gethui()) or game:GetService("CoreGui")
pcall(function()
local physicsSettings = settings().Physics :: any
local rawEnum = Enum :: any
physicsSettings.PhysicsEnvironmentalThrottle = rawEnum["EnvironmentalPhysicsThrottle"].AlwaysSkip
physicsSettings.AllowSleep = true
physicsSettings.GjkMargin = 0
end)
local GuiService = game:GetService("GuiService")
pcall(function()
GuiService:ToggleCoreGuiMenu() 
end)
pcall(function()
GuiService.MenuIsOpen = false
game:GetService("UserInputService").ModalEnabled = true 
end)

-- fflag section, some shit that NOT ANY executor can do, better use Real Executor for this 
-- (https://projectreal.gg) i swear this is not an ad they not paid me, just really REALly good executor.

-- P.s i dont even know if some of they work but i hope so
if setfflag then
 -- (events/stats)
setfflag("FFlagDebugDisableTelemetryV2Event", "True")
setfflag("FFlagDebugDisableTelemetryV2Stat", "True")
-- (wastes yo CPU cores and threads. 
-- you can google what these all fflag means)
setfflag("FFlagDebugDisableSimLogging", "True")
setfflag("FFlagDebugDisableLuaProfiling", "True")
setfflag("FFlagEnableScriptProfiling", "False")
-- (disabling built-in sending's of crash dumps and background-metric.)
setfflag("FFlagCrashReporterUploadToBacktrace", "False")
setfflag("FFlagCrashUploadToBacktracePercentage", "0")
setfflag("FFlagGoogleAnalyticsTrackingId", "")
-- (disabling data collection of voice chat and etc.)
setfflag("FFlagDebugDisableVoiceTelemetry", "True")
setfflag("FFlagTelemetryV2EnableDataOptOut", "True")
end
if setfflag then
-- (killing complex character collision and contact clipping)
setfflag("FFlagPhysicsSkipCharacterContactClipping", "True")
setfflag("FFlagDisableCharacterCollisionResolution", "True")
-- (forcing physics to sleep so engine completely ignores inactive parts)
setfflag("FFlagPhysicsAllowSleep", "True")
setfflag("FFlagPhysicsEnableSleepingParts", "True")
setfflag("FFlagPhysicsGjkMargin", "0")
setfflag("FFlagPhysicsEnvironmentalThrottleAlwaysSkip", "True")
end
-- deep engine optimization section (canCollide magic cock-and-balls tricks)
pcall(function()
for _, part in pairs(game:GetService("Workspace"):GetDescendants()) do
if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
-- (disabling part touch (touch grass) & query signals so raycasts won't trigger lag spikes)
part.CanTouch = false
part.CanQuery = false
end
end
end)
if setfflag then
-- (disabling lighting post-effects and framework antialiasing)
setfflag("FFlagDisablePostFx", "True")
setfflag("FFlagFrameRateManager", "False")
setfflag("FFlagAntialiasingDetection", "False")
-- (forcing ultra low texture override to make it pure pixel blocks)
setfflag("FFlagDebugForceTextureQualityOverrideEnabled", "True")
setfflag("FFlagDebugForceTextureQualityOverride", "0")
-- (turning off advanced lighting shadow maps like future is bright)
setfflag("FFlagDebugForceFutureIsBrightPhase3", "False")
setfflag("FFlagDebugForceFutureIsBrightPhase2", "False")
end
local function stripHumanoidPhysics(humanoid)
pcall(function()
-- (disabling state updates like climbing, swimming and falling down)
humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
-- (freezing humanoid rotation and putting physics calculation to sleep mode)
humanoid.AutoRotate = false
humanoid.PlatformStand = true
-- (making torso anchored so no any high-velocity punch can push them away)
local root = humanoid.Parent:FindFirstChild("HumanoidRootPart")
if root and root:IsA("BasePart") then
root.Anchored = true
end
end)
end

