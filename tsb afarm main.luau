local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local TARGET_POS = Vector3.new(-40.44, 29.25, 20389.99)
local LOOK_TARGET = Vector3.new(-36.46, 29.25, 20393.31)

local isLocked = false
local loopConnection
local clickConnection
local bodyVelocity

-- anti-afk loop to keep main account active

LocalPlayer.Idled:Connect(function()
VirtualUser:CaptureController()
VirtualUser:ClickButton2(Vector2.new(0, 0))
end)

-- hardcore server-side physical velocity replication engine

local function setServerSidePosition(state)
local character = LocalPlayer.Character
if character then
local hrp = character:FindFirstChild("HumanoidRootPart")
local humanoid = character:FindFirstChild("Humanoid")
if hrp and hrp:IsA("BasePart") and humanoid then
if state then
hrp.Anchored = false
hrp.Velocity = Vector3.new(0, 0, 0)
hrp.RotVelocity = Vector3.new(0, 0, 0)
hrp.CFrame = CFrame.lookAt(TARGET_POS, LOOK_TARGET)
if not bodyVelocity or bodyVelocity.Parent ~= hrp then
if bodyVelocity then bodyVelocity:Destroy() end
bodyVelocity = Instance.new("BodyVelocity")
bodyVelocity.MaxForce = Vector3.new(1e7, 1e7, 1e7)
bodyVelocity.Velocity = Vector3.new(0, 0, 0)
bodyVelocity.Name = "ServerLockForce"
bodyVelocity.Parent = hrp
end
pcall(function()
local rawPart = hrp :: any
rawPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
rawPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
end)
else
if bodyVelocity then
bodyVelocity:Destroy()
bodyVelocity = nil
end
end
end
end
end

-- ultra minimalistic draggable dark ui setup with N keybind info

local Gui = Instance.new("ScreenGui")
Gui.Name = "MainLockSystemGui"
Gui.ResetOnSpawn = false
Gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")

local Button = Instance.new("TextButton")
Button.Size = UDim2.new(0, 130, 0, 35)
Button.Position = UDim2.new(0.8, 0, 0.15, 0)
Button.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Button.Text = "[N] STATUS: UNLOCK"
Button.TextColor3 = Color3.fromRGB(255, 65, 65)
Button.TextSize = 12
Button.Font = Enum.Font.RobotoMono
Button.BorderSizePixel = 1
Button.BorderColor3 = Color3.fromRGB(40, 40, 40)
Button.Parent = Gui

local function startLock()
if loopConnection then loopConnection:Disconnect() end
if clickConnection then task.cancel(clickConnection) end

setServerSidePosition(true)

loopConnection = RunService.Heartbeat:Connect(function()
setServerSidePosition(true)
end)

local keyEnums = {
["1"] = Enum.KeyCode.One,
["2"] = Enum.KeyCode.Two,
["3"] = Enum.KeyCode.Three,
["4"] = Enum.KeyCode.Four,
["G"] = Enum.KeyCode.G
}

local canUseG = true
local blockFour = false
local lastGTime = os.clock() - 20 -- ready immediately on startup

clickConnection = task.spawn(function()
while isLocked do
local now = os.clock()

-- sophisticated timing checks for smart skill rotations
if canUseG and (now - lastGTime >= 20) then
canUseG = false
blockFour = true
lastGTime = now

pcall(function()
VirtualInputManager:SendKeyEvent(true, keyEnums["G"], false, game)
task.wait(0.005)
VirtualInputManager:SendKeyEvent(false, keyEnums["G"], false, game)
end)

-- independent skill blocking scheduler threads
task.spawn(function()
task.wait(49)
blockFour = false
task.wait(20)
canUseG = true
end)
end

-- dynamically reshaping available input pools based on active lock flags
local currentInputs = {"LKM", "1", "2", "3"}
if not blockFour then
table.insert(currentInputs, "4")
end

local choice = currentInputs[math.random(1, #currentInputs)]
pcall(function()
if choice == "LKM" then
local vpSize = workspace.CurrentCamera.ViewportSize
local x = vpSize.X / 2
local y = vpSize.Y / 2
VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
task.wait(0.005)
VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
else
local keyCode = keyEnums[choice]
VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
task.wait(0.005)
VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
end
end)
task.wait(0.01)
end
end)
end

local function stopLock()
if loopConnection then loopConnection:Disconnect() end
if clickConnection then task.cancel(clickConnection) end
setServerSidePosition(false)
end

local function toggleLockState()
isLocked = not isLocked
if isLocked then
Button.Text = "[N] STATUS: LOCKED"
Button.TextColor3 = Color3.fromRGB(65, 255, 65)
Button.BackgroundColor3 = Color3.fromRGB(15, 25, 15)
startLock()
else
Button.Text = "[N] STATUS: UNLOCK"
Button.TextColor3 = Color3.fromRGB(255, 65, 65)
Button.BackgroundColor3 = Color3.fromRGB(25, 15, 15)
stopLock()
end
end

-- binding key N for activation via user input service

UserInputService.InputBegan:Connect(function(input, gameProcessed)
if not gameProcessed and input.KeyCode == Enum.KeyCode.N then
toggleLockState()
end
end)

-- smooth modern drag detector injection 

pcall(function()
local dragDetector = Instance.new("UIDragDetector")
dragDetector.Parent = Button
end)

-- legacy fallback drag logic for raw environments

local dragging, dragInput, dragStart, startPos
Button.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
dragging = true
dragStart = input.Position
startPos = Button.Position
input.Changed:Connect(function()
if input.UserInputState == Enum.UserInputState.End then dragging = false end
end)
end
end)
Button.InputChanged:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
RunService.RenderStepped:Connect(function()
if dragging and dragInput then
local delta = dragInput.Position - dragStart
Button.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
dragInput = nil
end
end)

LocalPlayer.CharacterAdded:Connect(function()
if isLocked then
task.wait(0.5)
setServerSidePosition(true)
end
end)
