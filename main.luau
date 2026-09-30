-- iwakewar-scripts | main loader
-- Splash + progress UI, no external UI libraries.
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/iww-dev/iwakewar-scripts/refs/heads/main/main.luau"))()

local Players = game:GetService("Players")

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
    ["6839171747"] = {
        name = "DOORS",
        url = "https://raw.githubusercontent.com/iww-dev/iwakewar-scripts/refs/heads/main/Doors.luau",
    },
    ["9872472334"] = {
        name = "Evade",
        url = "https://raw.githubusercontent.com/iww-dev/iwakewar-scripts/refs/heads/main/Evade.luau",
    },
    ["123907164579958"] = {
        name = "Hidden Within",
        url = "https://raw.githubusercontent.com/iww-dev/iwakewar-scripts/refs/heads/main/HW.luau",
    },
    ["537413528"] = {
        name = "Build A Boat For Treasure",
        url = "https://raw.githubusercontent.com/iww-dev/iwakewar-scripts/refs/heads/main/BABFT.luau",
    },
}

local function escapeUrl(path: string): string
    return (path:gsub(" ", "%%20"))
end

local function fetch(url: string): (string?, string?)
    local src: string? = nil
    if typeof(game.HttpGet) == "function" then
        local ok, res = pcall(function()
            return game:HttpGet(url)
        end)
        if ok and typeof(res) == "string" and #res > 0 then
            src = res
        else
            if not ok then
                return nil, "HttpGet failed: " .. tostring(res):sub(1, 200)
            end
        end
    end
    if not src then
        local ok, res = pcall(function()
            return game:GetService("HttpService"):GetAsync(url)
        end)
        if ok and typeof(res) == "string" and #res > 0 then
            src = res
        else
            return nil, "GetAsync failed: " .. tostring(res):sub(1, 200)
        end
    end
    return src, nil
end

local function runSource(src: string, name: string): (boolean, string?)
    if typeof(loadstring) ~= "function" then
        return false, "loadstring() missing on this executor"
    end
    local fn, err = loadstring(src)
    if not fn then
        return false, "compile error in " .. name .. ": " .. tostring(err)
    end
    local ok, rerr = pcall(fn)
    if not ok then
        return false, "runtime error in " .. name .. ": " .. tostring(rerr)
    end
    return true, nil
end

local function detectGame()
    local placeId = tostring(game.PlaceId or "")
    local info = GAME_INFO[placeId]
    if info then
        return info, placeId
    end
    return nil, placeId
end

local function getExecutorName(): string
    local name = "unknown"
    pcall(function()
        if typeof(identifyexecutor) == "function" then
            name = tostring(identifyexecutor())
        end
    end)
    return name
end

local function copyText(text: string): boolean
    local g: any = nil
    if typeof(getgenv) == "function" then
        local ok, gg = pcall(getgenv)
        if ok and typeof(gg) == "table" then g = gg end
    end
    if not g then g = _G end
    for _, name in ipairs({ "setclipboard", "toclipboard", "writeclipboard" }) do
        local v = g[name]
        if v == nil then v = rawget(_G, name) end
        if typeof(v) == "function" then
            if pcall(v, text) then return true end
        end
    end
    if typeof(setclipboard) == "function" and pcall(setclipboard, text) then return true end
    if typeof(toclipboard) == "function" and pcall(toclipboard, text) then return true end
    return false
end

-- ============ 2014-style splash + terminal console ============
-- Строгий олдскульный лоадер: плоские панели, шрифт Code, углы 0,
-- бордеры 1px, кислотно-зелёный акцент. Фулскрин-дим оставлен.
-- Вместо "Game:/Status:"-лейблов -- маленькое окошко командной строки
-- с искусственными задержками + шагающий бар без процентов.
local function buildSplash()
    local player = Players.LocalPlayer
    if not player then
        return nil
    end
    local playerGui = player:WaitForChild("PlayerGui")

    local F = Enum.Font.Code
    local C_PANEL = Color3.fromRGB(16, 16, 16)
    local C_LINE = Color3.fromRGB(70, 70, 70)
    local C_TXT = Color3.fromRGB(220, 220, 220)
    local C_DIMTXT = Color3.fromRGB(140, 140, 140)
    local C_GREEN = Color3.fromRGB(0, 255, 0)
    local C_DGREEN = Color3.fromRGB(0, 180, 0)
    local C_RED = Color3.fromRGB(255, 60, 60)
    local C_BARBG = Color3.fromRGB(28, 28, 28)
    local C_CONSOLE = Color3.fromRGB(5, 5, 5)

    local lastError: string? = nil

    local sgui = Instance.new("ScreenGui")
    sgui.Name = "iwakewar-scripts"
    sgui.DisplayOrder = 100
    sgui.IgnoreGuiInset = true
    sgui.ResetOnSpawn = false
    sgui.Parent = playerGui

    -- fullscreen dim (оставлен)
    local dim = Instance.new("Frame")
    dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    dim.BorderSizePixel = 0
    dim.Size = UDim2.fromScale(1, 1)
    dim.Parent = sgui

    local win = Instance.new("Frame")
    win.AnchorPoint = Vector2.new(0.5, 0.5)
    win.BackgroundColor3 = C_PANEL
    win.BorderSizePixel = 0
    win.Position = UDim2.fromScale(0.5, 0.5)
    win.Size = UDim2.fromOffset(460, 380)
    win.Parent = sgui

    local winBorder = Instance.new("UIStroke")
    winBorder.Color = C_LINE
    winBorder.Thickness = 1
    winBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    winBorder.Parent = win

    -- верхняя кислотная полоса 2px, без скруглений
    local accent = Instance.new("Frame")
    accent.BackgroundColor3 = C_GREEN
    accent.BorderSizePixel = 0
    accent.Size = UDim2.new(1, 0, 0, 2)
    accent.Position = UDim2.fromScale(0, 0)
    accent.Parent = win

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Font = F
    title.Position = UDim2.new(0, 10, 0, 10)
    title.Size = UDim2.new(1, -20, 0, 22)
    title.Text = "> iwakewar-scripts_"
    title.TextColor3 = C_TXT
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = win

    local sub = Instance.new("TextLabel")
    sub.BackgroundTransparency = 1
    sub.Font = F
    sub.Position = UDim2.new(0, 10, 0, 32)
    sub.Size = UDim2.new(1, -20, 0, 16)
    sub.Text = "[loader v1] :: terminal"
    sub.TextColor3 = C_DGREEN
    sub.TextSize = 13
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Parent = win

    local sep = Instance.new("Frame")
    sep.BackgroundColor3 = C_LINE
    sep.BorderSizePixel = 0
    sep.Position = UDim2.new(0, 10, 0, 54)
    sep.Size = UDim2.new(1, -20, 0, 1)
    sep.Parent = win

    -- окошко командной строки
    local console = Instance.new("Frame")
    console.BackgroundColor3 = C_CONSOLE
    console.BorderSizePixel = 0
    console.Position = UDim2.new(0, 10, 0, 62)
    console.Size = UDim2.new(1, -20, 0, 168)
    console.Parent = win
    local conStroke = Instance.new("UIStroke")
    conStroke.Color = Color3.fromRGB(50, 50, 50)
    conStroke.Thickness = 1
    conStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    conStroke.Parent = console
    local conPad = Instance.new("UIPadding")
    conPad.PaddingLeft = UDim.new(0, 8)
    conPad.PaddingRight = UDim.new(0, 8)
    conPad.PaddingTop = UDim.new(0, 6)
    conPad.PaddingBottom = UDim.new(0, 6)
    conPad.Parent = console
    local conLayout = Instance.new("UIListLayout")
    conLayout.FillDirection = Enum.FillDirection.Vertical
    conLayout.Padding = UDim.new(0, 2)
    conLayout.SortOrder = Enum.SortOrder.LayoutOrder
    conLayout.Parent = console

    -- шагающий бар без процентов (появляется снизу на loading-степе)
    local barBG = Instance.new("Frame")
    barBG.BackgroundColor3 = C_BARBG
    barBG.BorderSizePixel = 0
    barBG.Position = UDim2.new(0, 10, 0, 238)
    barBG.Size = UDim2.new(1, -20, 0, 14)
    barBG.Visible = false
    barBG.Parent = win
    local barStroke = Instance.new("UIStroke")
    barStroke.Color = Color3.fromRGB(90, 90, 90)
    barStroke.Thickness = 1
    barStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    barStroke.Parent = barBG

    -- бегающий чанк вместо fill с процентами
    local chunk = Instance.new("Frame")
    chunk.BackgroundColor3 = C_GREEN
    chunk.BorderSizePixel = 0
    chunk.Position = UDim2.fromScale(0, 0)
    chunk.Size = UDim2.fromScale(0.25, 1)
    chunk.Parent = barBG

    -- поле ошибки (показывается только при fail)
    local errBox = Instance.new("TextLabel")
    errBox.BackgroundColor3 = Color3.fromRGB(24, 10, 10)
    errBox.BorderSizePixel = 0
    errBox.Font = F
    errBox.Position = UDim2.new(0, 10, 0, 260)
    errBox.Size = UDim2.new(1, -20, 0, 62)
    errBox.Text = ""
    errBox.TextColor3 = C_RED
    errBox.TextSize = 12
    errBox.TextWrapped = true
    errBox.TextXAlignment = Enum.TextXAlignment.Left
    errBox.TextYAlignment = Enum.TextYAlignment.Top
    errBox.Visible = false
    errBox.Parent = win
    local errStroke = Instance.new("UIStroke")
    errStroke.Color = Color3.fromRGB(120, 30, 30)
    errStroke.Thickness = 1
    errStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    errStroke.Parent = errBox
    local errPad = Instance.new("UIPadding")
    errPad.PaddingLeft = UDim.new(0, 6)
    errPad.PaddingRight = UDim.new(0, 6)
    errPad.PaddingTop = UDim.new(0, 4)
    errPad.PaddingBottom = UDim.new(0, 4)
    errPad.Parent = errBox

    local function mkBtn(text: string, xScale: number, wScale: number): TextButton
        local b = Instance.new("TextButton")
        b.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
        b.BorderSizePixel = 0
        b.Font = F
        b.Position = UDim2.new(xScale, 0, 1, -40)
        b.Size = UDim2.new(wScale, -5, 0, 30)
        b.Text = text
        b.TextColor3 = C_TXT
        b.TextSize = 14
        b.AutoButtonColor = false
        b.Parent = win
        local st = Instance.new("UIStroke")
        st.Color = C_LINE
        st.Thickness = 1
        st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        st.Parent = b
        b.MouseEnter:Connect(function()
            b.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
        end)
        b.MouseLeave:Connect(function()
            b.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
        end)
        return b
    end

    local closeBtn = mkBtn("[ close ]", 0.022, 0.466)
    closeBtn.Visible = false
    closeBtn.MouseButton1Click:Connect(function()
        sgui:Destroy()
    end)

    local copyBtn = mkBtn("[ copy the error ]", 0.512, 0.466)
    copyBtn.Visible = false
    copyBtn.MouseButton1Click:Connect(function()
        local txt = lastError or "no error captured"
        local full = "[iwakewar-scripts] " .. txt
            .. "\nplace=" .. tostring(game.PlaceId)
            .. "\nexecutor=" .. getExecutorName()
        if copyText(full) then
            copyBtn.Text = "[ copied! ]"
        else
            copyBtn.Text = "[ no clipboard api ]"
        end
        task.delay(1.5, function()
            if copyBtn.Parent then
                copyBtn.Text = "[ copy the error ]"
            end
        end)
    end)

    local ui: any = {}
    local lineN = 0
    local marqueeOn = false

    -- строка в терминале
    ui.log = function(text: string, color: Color3?)
        lineN += 1
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Font = F
        l.Size = UDim2.new(1, 0, 0, 16)
        l.Text = text
        l.TextColor3 = color or C_DIMTXT
        l.TextSize = 13
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextTruncate = Enum.TextTruncate.AtEnd
        l.LayoutOrder = lineN
        l.Parent = console
        return l
    end

    ui.startMarquee = function()
        barBG.Visible = true
        if marqueeOn then return end
        marqueeOn = true
        task.spawn(function()
            local pos = 0
            local dir = 1
            while marqueeOn and barBG.Parent do
                pos += dir * 0.05
                if pos >= 0.75 then dir = -1 end
                if pos <= 0 then dir = 1 end
                chunk.Position = UDim2.fromScale(pos, 0)
                task.wait(0.06)
            end
        end)
    end

    ui.stopMarquee = function(ok: boolean)
        marqueeOn = false
        if ok then
            -- успех: залить весь бар зелёным
            chunk.Position = UDim2.fromScale(0, 0)
            chunk.Size = UDim2.fromScale(1, 1)
            chunk.BackgroundColor3 = C_GREEN
        else
            chunk.Position = UDim2.fromScale(0, 0)
            chunk.Size = UDim2.fromScale(1, 1)
            chunk.BackgroundColor3 = C_RED
        end
    end

    -- совместимость со старым кодом (больше не проценты, просто лог)
    ui.progress = function(_frac: number, text: string, _color: Color3?)
        ui.log("> " .. text, C_DIMTXT)
    end

    ui.setGame = function(name: string, supported: boolean)
        ui.log("game: " .. name, C_TXT)
        if supported then
            ui.log("status: SUPPORTED", C_GREEN)
        else
            ui.log("status: NOT SUPPORTED", C_RED)
        end
    end

    ui.fail = function(msg: string, detail: string?)
        local full = msg
        if detail and #detail > 0 then
            full = msg .. " | " .. detail
        end
        lastError = full
        warn("[iwakewar-scripts] " .. full)
        ui.stopMarquee(false)
        ui.log("> " .. msg, C_RED)
        errBox.Text = full:sub(1, 400)
        errBox.Visible = true
        copyBtn.Visible = true
    end

    ui.ok = function(msg: string)
        ui.stopMarquee(true)
        ui.log("> " .. msg, C_GREEN)
    end

    ui.showClose = function()
        closeBtn.Visible = true
    end

    ui.close = function()
        sgui:Destroy()
    end

    ui.getError = function(): string?
        return lastError
    end

    return ui
end

local function runWithoutSplash()
    local info, idShown = detectGame()
    if not info then
        warn("[iwakewar-scripts] This game is not supported (place " .. tostring(idShown) .. ")")
        return
    end
    local src, ferr = fetch(info.url)
    if not src then
        warn("[iwakewar-scripts] could not fetch " .. info.url .. " | " .. tostring(ferr))
        return
    end
    local ok, rerr = runSource(src, info.name)
    if not ok then
        warn("[iwakewar-scripts] " .. tostring(rerr))
    end
end

local function loadWithSplash(ui)
    -- 1) скрипт ждёт...
    task.wait(math.random(40, 110) / 100) -- 0.4-1.1с искусственной задержки
    ui.log("> boot...", Color3.fromRGB(140, 140, 140))

    -- 2) Executor
    task.wait(math.random(50, 120) / 100) -- *ждёт* перед executor
    ui.log("executor: " .. getExecutorName(), Color3.fromRGB(220, 220, 220))

    -- 3) скрипт ждёт...
    task.wait(math.random(50, 120) / 100)
    local info, idShown = detectGame()

    -- 4) Game + 5) Status БЕЗ паузы между ними
    if not info then
        ui.log("game: unknown (" .. tostring(idShown) .. ")", Color3.fromRGB(220, 220, 220))
        ui.log("status: NOT SUPPORTED", Color3.fromRGB(255, 60, 60))
        task.wait(math.random(80, 150) / 100) -- *ждёт после Status*
        ui.fail(
            "This game is not supported (yet).",
            "place=" .. tostring(idShown)
        )
        ui.showClose()
        return
    end
    ui.log("game: " .. info.name, Color3.fromRGB(220, 220, 220))
    ui.log("status: SUPPORTED", Color3.fromRGB(0, 255, 0))

    -- 6) ждёт после Status...
    task.wait(math.random(80, 150) / 100)

    -- 7) Loading...... + снизу шагающий бар (без процентов)
    local loadLabel: any = ui.log("loading", Color3.fromRGB(140, 140, 140))
    ui.startMarquee()

    -- задержка loading-степа: рандом 0.5 - 14 секунд
    local loadTime = 0.5 + math.random() * 13.5
    local t0 = os.clock()
    task.spawn(function()
        local dots = 0
        while os.clock() - t0 < loadTime do
            dots = (dots % 6) + 1
            if loadLabel and loadLabel.Parent then
                loadLabel.Text = "loading" .. string.rep(".", dots)
            end
            task.wait(0.25)
        end
    end)

    -- качаем ПАРАЛЛЕЛЬНО с анимацией, чтобы точки не врали
    local src: string? = nil
    local ferr: string? = nil
    local done = false
    task.spawn(function()
        src, ferr = fetch(info.url)
        done = true
    end)
    while not done and os.clock() - t0 < loadTime do
        task.wait(0.1)
    end
    -- если скачалось быстрее задержки -- дотягиваем паузу до конца (вайб 2014),
    -- если дольше -- ждём дальше
    while os.clock() - t0 < loadTime do
        task.wait(0.1)
    end
    while not done do
        task.wait(0.1)
    end

    if not src then
        if loadLabel then loadLabel.Text = "loading... failed" end
        ui.fail("Failed to download script.", tostring(ferr) .. " :: " .. info.url)
        ui.showClose()
        return
    end

    if loadLabel then loadLabel.Text = "loading...... ok" end
    ui.log("> injecting " .. info.name .. "...", Color3.fromRGB(140, 140, 140))

    local okRun, rerr = runSource(src :: string, info.name)
    if okRun then
        ui.ok("done! enjoy.")
        task.delay(1.2, function()
            ui.close()
        end)
    else
        ui.fail("Script errored.", tostring(rerr))
        ui.showClose()
    end
end

local okBuild, splashUi = pcall(buildSplash)
if okBuild and splashUi then
    task.spawn(function()
        local okRun, err = pcall(loadWithSplash, splashUi)
        if not okRun then
            local msg = "Loader error: " .. tostring(err)
            warn("[iwakewar-scripts] " .. msg)
            pcall(function()
                splashUi.fail("Loader error.", tostring(err))
                splashUi.showClose()
            end)
        end
    end)
else
    warn("[iwakewar-scripts] splash build failed: " .. tostring(splashUi))
    runWithoutSplash()
end
