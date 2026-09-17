-- iwakewar-scripts | main loader
-- Splash + progress UI, no external UI libraries.
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/iww-dev/iwakewar-scripts/refs/heads/main/main.luau"))()

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local BASE = "https://raw.githubusercontent.com/iww-dev/iwakewar-scripts/refs/heads/main/"

local GAME_INFO = {
    ["6520999642"] = {
        name = "Basically FNF: Remix",
        url = "https://raw.githubusercontent.com/iww-dev/iwakewar-scripts/refs/heads/main/BFNFR%20Auto-Play.luau",
    },
    ["107778070777162"] = {
        name = "Steal An Egg",
        url = "https://raw.githubusercontent.com/iww-dev/iwakewar-scripts/refs/heads/main/StealAnEgg.luau",
    },
    ["142823291"] = {
        name = "Murder Mystery 2",
        url = "https://raw.githubusercontent.com/iww-dev/iwakewar-scripts/refs/heads/main/MM2.luau",
    },
}

local function escapeUrl(path: string): string
    return (path:gsub(" ", "%%20"))
end

local function fetch(url: string): string?
    local src = nil
    if typeof(game.HttpGet) == "function" then
        local ok, res = pcall(function()
            return game:HttpGet(url)
        end)
        if ok and typeof(res) == "string" then
            src = res
        end
    end
    if not src then
        local ok, res = pcall(function()
            return game:GetService("HttpService"):GetAsync(url)
        end)
        if ok and typeof(res) == "string" then
            src = res
        end
    end
    return src
end

local function runSource(src: string, name: string): boolean
    if not loadstring then
        warn("[iwakewar-scripts] no loadstring on this executor")
        return false
    end
    local fn, err = loadstring(src)
    if not fn then
        warn("[iwakewar-scripts] compile error in " .. name .. ": " .. tostring(err))
        return false
    end
    local ok, rerr = pcall(fn)
    if not ok then
        warn("[iwakewar-scripts] runtime error in " .. name .. ": " .. tostring(rerr))
        return false
    end
    return true
end

local function detectGame()
    local placeId = tostring(game.PlaceId or "")
    local info = GAME_INFO[placeId]
    if info then
        return info, placeId
    end
    return nil, placeId
end

local function buildSplash()
    local player = Players.LocalPlayer
    if not player then
        return nil
    end
    local playerGui = player:WaitForChild("PlayerGui")

    local sgui = Instance.new("ScreenGui")
    sgui.Name = "iwakewar-scripts"
    sgui.DisplayOrder = 100
    sgui.IgnoreGuiInset = true
    sgui.ResetOnSpawn = false
    sgui.Parent = playerGui

    local dim = Instance.new("Frame")
    dim.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
    dim.BorderSizePixel = 0
    dim.Size = UDim2.fromScale(1, 1)
    dim.Parent = sgui

    local win = Instance.new("Frame")
    win.AnchorPoint = Vector2.new(0.5, 0.5)
    win.BackgroundColor3 = Color3.fromRGB(19, 23, 31)
    win.BorderSizePixel = 0
    win.Position = UDim2.fromScale(0.5, 0.5)
    win.Size = UDim2.fromOffset(460, 220)
    win.Parent = sgui
    local winCorner = Instance.new("UICorner")
    winCorner.CornerRadius = UDim.new(0, 12)
    winCorner.Parent = win

    local accent = Instance.new("Frame")
    accent.BackgroundColor3 = Color3.fromRGB(94, 138, 255)
    accent.BorderSizePixel = 0
    accent.Size = UDim2.fromScale(1, 0.045)
    accent.Parent = win
    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(0, 12)
    accentCorner.Parent = accent

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Position = UDim2.fromScale(0.06, 0.06)
    title.Size = UDim2.fromScale(0.9, 0.16)
    title.Text = "iwakewar-scripts"
    title.TextColor3 = Color3.fromRGB(230, 236, 255)
    title.TextSize = 22
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = win

    local gameLabel = Instance.new("TextLabel")
    gameLabel.BackgroundTransparency = 1
    gameLabel.Font = Enum.Font.Gotham
    gameLabel.Position = UDim2.fromScale(0.06, 0.26)
    gameLabel.Size = UDim2.fromScale(0.88, 0.14)
    gameLabel.Text = "Game: detecting..."
    gameLabel.TextColor3 = Color3.fromRGB(170, 180, 205)
    gameLabel.TextSize = 15
    gameLabel.TextXAlignment = Enum.TextXAlignment.Left
    gameLabel.Parent = win

    local statLabel = Instance.new("TextLabel")
    statLabel.BackgroundTransparency = 1
    statLabel.Font = Enum.Font.GothamBold
    statLabel.Position = UDim2.fromScale(0.06, 0.41)
    statLabel.Size = UDim2.fromScale(0.88, 0.14)
    statLabel.Text = "Status: checking..."
    statLabel.TextColor3 = Color3.fromRGB(120, 130, 160)
    statLabel.TextSize = 16
    statLabel.TextXAlignment = Enum.TextXAlignment.Left
    statLabel.Parent = win

    local barBG = Instance.new("Frame")
    barBG.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    barBG.BackgroundTransparency = 0.92
    barBG.BorderSizePixel = 0
    barBG.Position = UDim2.fromScale(0.06, 0.58)
    barBG.Size = UDim2.fromScale(0.88, 0.045)
    barBG.Parent = win
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 6)
    barCorner.Parent = barBG

    local barFill = Instance.new("Frame")
    barFill.BackgroundColor3 = Color3.fromRGB(94, 138, 255)
    barFill.BorderSizePixel = 0
    barFill.Position = UDim2.fromScale(0, 0)
    barFill.Size = UDim2.fromScale(0, 1)
    barFill.Parent = barBG
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 6)
    fillCorner.Parent = barFill

    local stepLabel = Instance.new("TextLabel")
    stepLabel.BackgroundTransparency = 1
    stepLabel.Font = Enum.Font.Gotham
    stepLabel.Position = UDim2.fromScale(0.06, 0.7)
    stepLabel.Size = UDim2.fromScale(0.88, 0.12)
    stepLabel.Text = "Starting..."
    stepLabel.TextColor3 = Color3.fromRGB(150, 160, 185)
    stepLabel.TextSize = 14
    stepLabel.TextXAlignment = Enum.TextXAlignment.Left
    stepLabel.Parent = win

    local function label(label: TextLabel, text: string, color: Color3)
        label.Text = text
        label.TextColor3 = color
    end

    local ui = {}

    ui.progress = function(frac: number, text: string, color: Color3?)
        frac = math.clamp(frac, 0, 1)
        if color then
            barFill.BackgroundColor3 = color
        end
        stepLabel.Text = text
        TweenService:Create(barFill, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.fromScale(frac, 1),
        }):Play()
    end

    ui.setGame = function(name: string, supported: boolean)
        if supported then
            label(gameLabel, "Game: " .. name, Color3.fromRGB(170, 180, 205))
            label(statLabel, "Status: supported", Color3.fromRGB(110, 220, 150))
        else
            label(gameLabel, "Game: " .. name, Color3.fromRGB(170, 180, 205))
            label(statLabel, "Status: not supported", Color3.fromRGB(240, 120, 120))
        end
    end

    ui.fail = function(msg: string)
        ui.progress(1, msg, Color3.fromRGB(240, 120, 120))
    end

    local closeBtn = Instance.new("TextButton")
    closeBtn.AnchorPoint = Vector2.new(0.5, 1)
    closeBtn.BackgroundColor3 = Color3.fromRGB(230, 90, 90)
    closeBtn.BorderSizePixel = 0
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Position = UDim2.fromScale(0.5, 0.98)
    closeBtn.Size = UDim2.fromOffset(140, 34)
    closeBtn.Text = "Close"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 16
    closeBtn.Visible = false
    closeBtn.MouseButton1Click:Connect(function()
        sgui:Destroy()
    end)
    closeBtn.Parent = win
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = closeBtn

    ui.showClose = function()
        closeBtn.Visible = true
        closeBtn.BackgroundTransparency = 1
        closeBtn.TextTransparency = 1
        TweenService:Create(closeBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0,
            TextTransparency = 0,
        }):Play()
    end

    ui.close = function()
        sgui:Destroy()
    end

    return ui
end

local function runWithoutSplash()
    local info, idShown = detectGame()
    if not info then
        warn("[iwakewar-scripts] This game is not supported (place " .. tostring(idShown) .. ")")
        return
    end
    local src = fetch(info.url)
    if not src then
        warn("[iwakewar-scripts] could not fetch " .. info.url)
        return
    end
    runSource(src, info.name)
end

local function loadWithSplash(ui)
    ui.progress(0.05, "Checking environment...")
    task.wait(0.25)

    ui.progress(0.2, "Detecting game...")
    task.wait(0.2)

    local info, idShown = detectGame()

    if not info then
        ui.setGame("Unknown (" .. tostring(idShown) .. ")", false)
        ui.fail("This game is not supported by iwakewar-scripts (yet).")
        ui.showClose()
        warn("[iwakewar-scripts] unsupported game, place " .. tostring(idShown))
        return
    end

    ui.setGame(info.name, true)

    ui.progress(0.45, "Downloading " .. info.name .. "...")
    task.wait(0.2)

    local url = info.url
    local src = fetch(url)
    if not src then
        ui.fail("Failed to download script. Check your connection.")
        ui.showClose()
        warn("[iwakewar-scripts] could not fetch " .. url)
        return
    end

    ui.progress(0.8, "Injecting...")
    task.wait(0.2)

    local okRun = runSource(src, info.name)
    if okRun then
        ui.progress(1, "Done! Enjoy.")
        task.delay(1.2, function()
            ui.close()
        end)
    else
        ui.fail("Script errored. Check the log.")
        ui.showClose()
    end
end

local okBuild, splashUi = pcall(buildSplash)
if okBuild and splashUi then
    task.spawn(function()
        local okRun = pcall(loadWithSplash, splashUi)
        if not okRun then
            warn("[iwakewar-scripts] loader error: " .. tostring(okRun))
            splashUi.fail("Loader error. Check the log.")
            splashUi.showClose()
        end
    end)
else
    runWithoutSplash()
end
