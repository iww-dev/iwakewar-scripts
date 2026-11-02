-- Hello printer (Primordial UI) — phone-friendly, minimal
local LIB_URL = "https://raw.githubusercontent.com/iww-dev/iwakewar-scripts/refs/heads/main/gui-lib/PrimordialUI.luau"

local genv = getgenv()
if genv.__helloUI and type(genv.__helloUI.Destroy) == "function" then pcall(function() genv.__helloUI:Destroy() end) end

local GUI = loadstring(game:HttpGet(LIB_URL))()
genv.__helloUI = GUI

local Window = GUI:CreateWindow({
    Title = "Hello Printer",
    Subtitle = "by iwakewar team",
    Size = UDim2.fromOffset(360, 200),
    ToggleKey = Enum.KeyCode.RightShift,
})

local Tab = Window:Tab({ Title = "Main", Subtitle = "Print Hello" })
Window:SelectTab(1)

Tab:Section({ Title = "Control" })
local status = Tab:Paragraph({ Title = "Status", Content = "stopped" })

local running = false
local conn
Tab:Button({
    Title = "Print Hello every 2 seconds",
    Description = "Tap to start / stop",
    Callback = function()
        running = not running
        if running then
            status:SetContent("printing...")
            conn = task.spawn(function()
                while running do
                    print("Hello")
                    task.wait(2)
                end
            end)
        else
            running = false
            if conn then task.cancel(conn) end
            conn = nil
            status:SetContent("stopped")
        end
    end,
})
