-- Hello printer (no network, minimal GUI)
local plr = game.Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "HelloPrinter"
gui.ResetOnSpawn = false
gui.Parent = plr:WaitForChild("PlayerGui")

local f = Instance.new("Frame")
f.Size = UDim2.fromOffset(260, 120)
f.Position = UDim2.new(0.5, -130, 0.5, -60)
f.BackgroundColor3 = Color3.fromRGB(30, 32, 40)
f.BorderSizePixel = 0
f.Parent = gui
local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = f

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -30, 0, 24)
title.Position = UDim2.fromOffset(10, 4)
title.BackgroundTransparency = 1
title.Text = "Hello Printer"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.Parent = f

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(22, 22)
close.Position = UDim2.new(1, -26, 0, 4)
close.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
close.Text = "X"
close.TextColor3 = Color3.new(1, 1, 1)
close.TextSize = 14
close.Font = Enum.Font.GothamBold
close.BorderSizePixel = 0
close.Parent = f
local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 4); cc.Parent = close

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 20)
status.Position = UDim2.fromOffset(10, 32)
status.BackgroundTransparency = 1
status.Text = "stopped"
status.TextColor3 = Color3.fromRGB(180, 180, 180)
status.TextSize = 13
status.Font = Enum.Font.Gotham
status.Parent = f

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(1, -20, 0, 40)
btn.Position = UDim2.fromOffset(10, 60)
btn.BackgroundColor3 = Color3.fromRGB(0, 140, 200)
btn.Text = "Print Hello every 2 seconds"
btn.TextColor3 = Color3.new(1, 1, 1)
btn.TextSize = 14
btn.Font = Enum.Font.GothamBold
btn.BorderSizePixel = 0
btn.Parent = f
local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 6); bc.Parent = btn

local running = false
local thread
btn.Activated:Connect(function()
    running = not running
    if running then
        status.Text = "printing..."
        btn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        thread = task.spawn(function()
            while running do
                print("Hello")
                task.wait(2)
            end
        end)
    else
        running = false
        if thread then task.cancel(thread) end
        thread = nil
        status.Text = "stopped"
        btn.BackgroundColor3 = Color3.fromRGB(0, 140, 200)
    end
end)

close.Activated:Connect(function()
    running = false
    if thread then task.cancel(thread) end
    gui:Destroy()
end)
