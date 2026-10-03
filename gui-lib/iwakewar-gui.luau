-- iwakewar-gui v1 | ancient style, no fluent needed
-- palette/font from main.luau: Code font, flat 16,16,16 panels,
-- 1px 70,70,70 borders, 0 corners, acid-green accents, terminal vibes.
-- form factor like classic hubs: title bar, left tab sidebar, right content,
-- toggles, sliders, dropdowns, colorpicker, keybinds, RightAlt to hide/show.
--
-- load: local GUI = loadstring(readfile("_iwakewar_gui.lua"))()
-- API mirrors the Fluent subset our scripts use.

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TW = game:GetService("TweenService")
local TS = game:GetService("TextService")
local LP = Players.LocalPlayer
local isPhoneGlobal = UIS.TouchEnabled and not UIS.KeyboardEnabled
local SC = isPhoneGlobal and 0.7 or 1

-- iwakewar-gui v3 | violet night, top tabs, groupboxes. no fluent needed.
-- Было: ancient flat style. Стало: тёмный фиолет, табы сверху,
-- секции-групбоксы, компактные строки. API тот же.
local F = Enum.Font.Code
local C_BG = Color3.fromRGB(12, 11, 24)
local C_PANEL = Color3.fromRGB(18, 16, 32)
local C_PANEL2 = Color3.fromRGB(26, 24, 48)
local C_LINE = Color3.fromRGB(62, 56, 108)
local C_LINE_DARK = Color3.fromRGB(38, 34, 66)
local C_TXT = Color3.fromRGB(236, 236, 246)
local C_DIMTXT = Color3.fromRGB(154, 150, 175)
local C_GREEN = Color3.fromRGB(0, 255, 0)
local C_DGREEN = Color3.fromRGB(0, 180, 0)
local C_RED = Color3.fromRGB(255, 60, 60)
local C_ACCENT = Color3.fromRGB(150, 112, 255)
local C_ACCENT_DARK = Color3.fromRGB(96, 70, 180)

local GUI = {}
GUI.Options = {}
GUI.Unloaded = false
GUI.Lang = "ru"
GUI.Strings = {
    ru = {
        close = "Закрыть",
        minimize = "Свернуть",
        terminal = "Терминал",
        inputHint = "введи help",
        helpHead = "команды: executor | game | playtime | iw-barock | ce | loadstring | reload | timer | ping | raknet",
        unknown = "не знаю: ",
        needArg = "нужен аргумент",
    },
    en = {
        close = "Close",
        minimize = "Minimize",
        terminal = "Terminal",
        inputHint = "type help",
        helpHead = "commands: executor | game | playtime | iw-barock | ce | loadstring | reload | timer | ping | raknet",
        unknown = "unknown: ",
        needArg = "argument required",
    },
}
function GUI:SetLang(l)
    if l == "ru" or l == "en" then self.Lang = l end
end
function GUI:T(key)
    local t = self.Strings[self.Lang] or self.Strings.ru
    return t[key] or key
end

local function stroke(p, c)
    local s = Instance.new("UIStroke")
    s.Color = c or C_LINE
    s.Thickness = 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p
    return s
end

-- авто-ширина под текст: DIWIDAWIADWDAW растянет фон сам
local function measureX(text, size)
    local ok, v = pcall(function()
        return TS:GetTextSize(tostring(text), size, F, Vector2.new(4000, 100))
    end)
    if ok and v then return math.ceil(v.X) end
    return #tostring(text) * math.floor(size * 0.6)
end

local function fitWidth(base, text, size, padX)
    return base + measureX(text, size) + (padX or 16)
end

local function label(parent, text, size, color, xalign)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Font = F
    l.Text = text
    l.TextSize = size or 13
    l.TextColor3 = color or C_TXT
    l.TextXAlignment = xalign or Enum.TextXAlignment.Left
    l.TextTruncate = Enum.TextTruncate.AtEnd
    l.Parent = parent
    return l
end

local function btn(parent, text, textcolor)
    local b = Instance.new("TextButton")
    b.BackgroundColor3 = C_PANEL2
    b.BorderSizePixel = 0
    b.Font = F
    b.Text = text
    b.TextSize = 13
    b.TextColor3 = textcolor or C_TXT
    b.AutoButtonColor = false
    b.Parent = parent
    stroke(b)
    b.MouseEnter:Connect(function() b.BackgroundColor3 = Color3.fromRGB(34, 34, 34) end)
    b.MouseLeave:Connect(function() b.BackgroundColor3 = C_PANEL2 end)
    return b
end

function GUI:Notify(cfg)
    if self.Unloaded or not self.GUI then return end
    local sg = self.GUI
    local n = Instance.new("Frame")
    n.BackgroundColor3 = C_PANEL
    n.BorderSizePixel = 0
    n.AnchorPoint = Vector2.new(1, 1)
    local y = 0
    for _, d in ipairs(sg:GetChildren()) do
        if d.Name == "iwkToast" then y = y + 64 end
    end
    n.Position = UDim2.new(1, -12, 1, -12 - y)
    n.Size = UDim2.fromOffset(280, 56)
    n.Name = "iwkToast"
    n.Parent = sg
    stroke(n)
    local bar = Instance.new("Frame")
    bar.BackgroundColor3 = C_GREEN
    bar.BorderSizePixel = 0
    bar.Size = UDim2.new(0, 3, 1, 0)
    bar.Parent = n
    local t = label(n, tostring(cfg.Title or ""), 13, C_TXT)
    t.Position = UDim2.new(0, 10, 0, 4)
    t.Size = UDim2.new(1, -16, 0, 18)
    local c = label(n, tostring(cfg.Content or ""), 11, C_DIMTXT)
    c.Position = UDim2.new(0, 10, 0, 24)
    c.Size = UDim2.new(1, -16, 0, 28)
    c.TextWrapped = true
    task.delay(tonumber(cfg.Duration) or 3, function()
        if n.Parent then
            pcall(function()
                TW:Create(n, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
            end)
            task.wait(0.3)
            n:Destroy()
        end
    end)
end

-- close hooks registered by scripts: table.insert(GUI._onClose, fn)
GUI._onClose = {}
-- self url for `reload`: scripts set GUI._selfUrl = "https://...raw.../script.luau"
GUI._selfUrl = nil
GUI._t0 = os.clock()

local function fmtDur(s)
    s = math.max(0, math.floor(s))
    local h = math.floor(s / 3600)
    local m = math.floor((s % 3600) / 60)
    local ss = s % 60
    if h > 0 then return string.format("%dh %02dm %02ds", h, m, ss) end
    if m > 0 then return string.format("%dm %02ds", m, ss) end
    return string.format("%ds", ss)
end

-- rock state
local rockOn = false
local rockSaved = {}
local rockBoxes = {}

local function rockSet(on, say)
    local c = LP.Character
    if not c then
        say("нет персонажа", false)
        return
    end
    if on == rockOn then
        say(rockOn and "уже камень" or "уже flesh")
        return
    end
    rockOn = on
    if on then
        rockSaved = {}
        for _, v in ipairs(c:GetDescendants()) do
            if v:IsA("BasePart") then
                rockSaved[v] = { v.Material, v.Color, v.Transparency }
                v.Material = Enum.Material.Slate
                v.Color = Color3.fromRGB(110, 110, 115)
            elseif v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") then
                rockSaved[v] = { "cloth" }
                v.Transparency = 1
            elseif v:IsA("Accessory") then
                local h = v:FindFirstChild("Handle")
                if h and h:IsA("BasePart") then
                    rockSaved[h] = { h.Material, h.Color, h.Transparency }
                    h.Material = Enum.Material.Slate
                    h.Color = Color3.fromRGB(90, 90, 95)
                end
            elseif v:IsA("Decal") and v.Parent and v.Parent.Name == "Head" then
                rockSaved[v] = { "face", v.Transparency }
                v.Transparency = 1
            end
        end
        -- широкая collide-коробка: толкаемся с дистанции, ходим/прыгаем как раньше
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, sz in ipairs({ Vector3.new(8, 6, 4) }) do
                local b = Instance.new("Part")
                b.Name = "iwkRockBox"
                b.Size = sz
                b.Transparency = 1
                b.CanCollide = true
                b.Massless = true
                b.CanQuery = false
                b.CanTouch = false
                b.CFrame = hrp.CFrame
                b.Parent = c
                local w = Instance.new("WeldConstraint")
                w.Part0 = hrp
                w.Part1 = b
                w.Parent = b
                table.insert(rockBoxes, b)
            end
        end
        say("камень ON (сланец + широкая коллизия)", true)
    else
        for inst, s in pairs(rockSaved) do
            pcall(function()
                if inst and inst.Parent then
                    if s[1] == "cloth" then
                        inst.Transparency = 0
                    elseif s[1] == "face" then
                        inst.Transparency = s[2]
                    else
                        inst.Material, inst.Color, inst.Transparency = s[1], s[2], s[3]
                    end
                end
            end)
        end
        rockSaved = {}
        for _, b in ipairs(rockBoxes) do
            pcall(function() b:Destroy() end)
        end
        rockBoxes = {}
        say("камень OFF", true)
    end
end

local function buildTerminal(Window)
    local tab = Window:AddTab({ Title = GUI:T("terminal") })
    local page = tab.page
    local out = Instance.new("ScrollingFrame")
    out.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
    out.BorderSizePixel = 0
    out.Position = UDim2.new(0, 0, 0, 0)
    out.Size = UDim2.new(1, 0, 1, -34)
    out.ScrollBarThickness = 3
    out.ScrollBarImageColor3 = C_LINE
    out.AutomaticCanvasSize = Enum.AutomaticSize.Y
    out.CanvasSize = UDim2.new(0, 0, 0, 0)
    out.Parent = page
    stroke(out, Color3.fromRGB(50, 50, 50))
    local lay = Instance.new("UIListLayout")
    lay.FillDirection = Enum.FillDirection.Vertical
    lay.Padding = UDim.new(0, 2)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Parent = out
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 5)
    pad.PaddingLeft = UDim.new(0, 7)
    pad.PaddingRight = UDim.new(0, 7)
    pad.PaddingBottom = UDim.new(0, 5)
    pad.Parent = out
    local inp = Instance.new("TextBox")
    inp.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
    inp.BorderSizePixel = 0
    inp.Font = F
    inp.Text = ""
    inp.PlaceholderText = GUI:T("inputHint")
    inp.PlaceholderColor3 = Color3.fromRGB(90, 90, 90)
    inp.TextColor3 = C_GREEN
    inp.TextSize = 13
    inp.TextXAlignment = Enum.TextXAlignment.Left
    inp.ClearTextOnFocus = false
    inp.Position = UDim2.new(0, 0, 1, -30)
    inp.Size = UDim2.new(1, 0, 0, 30)
    inp.Parent = page
    stroke(inp, Color3.fromRGB(50, 50, 50))
    local n = 0
    local function scrollDown()
        task.defer(function()
            pcall(function()
                out.CanvasPosition = Vector2.new(0, math.max(0, out.AbsoluteCanvasSize.Y - out.AbsoluteWindowSize.Y))
            end)
        end)
    end
    local function line(t, color)
        n = n + 1
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Font = F
        l.Text = tostring(t)
        l.TextSize = 12
        l.TextColor3 = color or C_DIMTXT
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextWrapped = true
        l.AutomaticSize = Enum.AutomaticSize.Y
        l.Size = UDim2.new(1, 0, 0, 15)
        l.LayoutOrder = n
        l.Parent = out
        scrollDown()
    end
    local say = function(t) line(t, C_DIMTXT) end
    local ok2 = function(t) line(t, C_GREEN) end
    local err = function(t) line(t, C_RED) end

    local cmds = {}

    cmds.help = function()
        ok2(GUI:T("helpHead"))
        say("альясы: i-want-to-be-a-rock, closentire, close-entire, re, st, tr")
    end

    cmds.executor = function()
        local name = nil
        pcall(function()
            if typeof(identifyexecutor) == "function" then name = identifyexecutor() end
        end)
        if not name then
            pcall(function()
                if typeof(getexecutorname) == "function" then name = getexecutorname() end
            end)
        end
        ok2("экзекьютор: " .. tostring(name or "unknown"))
    end

    cmds.game = function()
        say("placeId: " .. tostring(game.PlaceId))
        say("universeId: " .. tostring(game.GameId))
        say("jobId: " .. tostring(game.JobId))
        say("игроков: " .. #Players:GetPlayers())
        local nm = nil
        pcall(function()
            nm = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
        end)
        say("плейс: " .. tostring(nm or game.Name))
    end

    cmds.playtime = function()
        local srv = nil
        pcall(function() srv = workspace:GetServerTimeNow() end)
        if type(srv) ~= "number" then
            pcall(function() srv = workspace.DistributedGameTime end)
        end
        say("время сервера: " .. (type(srv) == "number" and fmtDur(srv) or "unknown"))
        say("аптайм скрипта: " .. fmtDur(os.clock() - GUI._t0))
    end

    cmds["i-want-to-be-a-rock"] = function(arg)
        if arg == "on" then rockSet(true, say)
        elseif arg == "off" then rockSet(false, say)
        else rockSet(not rockOn, say) end
    end
    cmds["iw-barock"] = cmds["i-want-to-be-a-rock"]

    local function fullClose()
        GUI.Unloaded = true
        for _, fn in ipairs(GUI._onClose) do pcall(fn) end
        pcall(function()
            local c = LP.Character
            local hrp = c and c:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.Anchored = false end
        end)
        pcall(function() workspace.Gravity = 196.2 end)
        if rockOn then rockSet(false, function() end) end
        pcall(function() GUI.GUI:Destroy() end)
        pcall(function()
            local cg = game:GetService("CoreGui"):FindFirstChild("iwkToggle")
            if cg then cg:Destroy() end
        end)
        print("[iwk] closed entirely")
    end
    cmds["close-entire"] = fullClose
    cmds["closentire"] = fullClose
    cmds["ce"] = fullClose

    cmds.loadstring = function(arg)
        if not arg or arg == "" then err("юз: loadstring <url|code>") return end
        task.spawn(function()
            local src = arg
            if arg:match("^https?://") then
                local ok, res = pcall(function() return game:HttpGet(arg) end)
                if not ok then err("http не сработал") return end
                src = res
            end
            local fn, e = loadstring(src)
            if not fn then err("компиляция: " .. tostring(e)) return end
            local ok, r = pcall(fn)
            ok2(ok and ("готово -> " .. tostring(r)) or ("рантайм: " .. tostring(r)))
        end)
    end

    local function doReload()
        local url = GUI._selfUrl
        if not url or url == "" then
            err("релоад: скрипт не задал GUI._selfUrl")
            return
        end
        say("релоад с " .. url .. " ...")
        task.spawn(function()
            GUI.Unloaded = true
            for _, fn in ipairs(GUI._onClose) do pcall(fn) end
            pcall(function() GUI.GUI:Destroy() end)
            task.wait(0.5)
            local ok, src = pcall(function() return game:HttpGet(url) end)
            if not ok then warn("[iwk] reload http failed") return end
            local fn, e = loadstring(src)
            if not fn then warn("[iwk] reload compile: " .. tostring(e)) return end
            task.spawn(fn)
        end)
    end
    cmds.rexecute = doReload
    cmds.restart = doReload
    cmds.reload = doReload
    cmds.re = doReload
    cmds["re-execute"] = doReload

    cmds["set-timer"] = function(arg)
        local s = tonumber(arg)
        if not s or s <= 0 then err("юз: timer <секунды>") return end
        ok2("таймер: " .. s .. "s")
        task.delay(s, function()
            for i = 1, 5 do
                GUI:Notify({ Title = "TIMER", Content = "ТАЙМЕР КОНЧИЛСЯ", Duration = 3 })
                task.wait(0.45)
            end
        end)
    end
    cmds.timer = cmds["set-timer"]
    cmds.st = cmds["set-timer"]

    cmds.ping = function(arg)
        if not arg or arg == "" then err("юз: ping <host>") return end
        local a = string.lower(arg)
        if a == "roblox" or a:match("^roblox%.com") then
            say("меряю пинг 10с ...")
            task.spawn(function()
                local sum, n = 0, 0
                for i = 1, 10 do
                    local ok, v = pcall(function()
                        return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
                    end)
                    if ok and typeof(v) == "number" then sum, n = sum + v, n + 1 end
                    task.wait(1)
                end
                if n > 0 then ok2(string.format("роблокс пинг: %.0f мс (%d замеров)", sum / n, n))
                else err("пинг unknown") end
            end)
            return
        end
        task.spawn(function()
            local url = arg:match("^https?://") and arg or ("https://" .. arg)
            local t0 = os.clock()
            local ok = pcall(function() game:HttpGet(url) end)
            if ok then ok2(string.format("%s: %.0f ms (http)", arg, (os.clock() - t0) * 1000))
            else err("пинг unknown") end
        end)
    end

    cmds.testraknet = function()
        if typeof(RakNet) == "table" then
            local fns = {}
            pcall(function()
                for k, v in pairs(RakNet) do
                    if typeof(v) == "function" then table.insert(fns, k) end
                end
            end)
            ok2("RakNet: есть (" .. #fns .. " функций: " .. table.concat(fns, ", "):sub(1, 120) .. ")")
        else
            err("RakNet тут нет")
        end
    end
    cmds["test-raknet"] = cmds.testraknet
    cmds.raknet = cmds.testraknet
    cmds.tr = cmds.testraknet

    local function run(raw)
        line("root@alpine:~# " .. raw, C_GREEN)
        local cmd, arg = raw:match("^(%S+)%s*(.-)%s*$")
        if not cmd then return end
        cmd = string.lower(cmd)
        local fn = cmds[cmd]
        if fn then
            local ok, e = pcall(fn, arg)
            if not ok then err("ошибка: " .. tostring(e)) end
        else
            err(GUI:T("unknown") .. cmd)
        end
    end

    inp.FocusLost:Connect(function(enter)
        if not enter then return end
        local t = inp.Text
        inp.Text = ""
        if t and t ~= "" then
            task.spawn(run, t)
        end
    end)

    line("iwakewar terminal tty0 — type help", C_DGREEN)
    return tab
end

function GUI:CreateWindow(wcfg)
    wcfg = wcfg or {}
    local title = wcfg.Title or "iwakewar"
    local sub = wcfg.SubTitle or "by iwakewar team"
    local tabW = wcfg.TabWidth or 150
    local size = wcfg.Size or UDim2.fromOffset(640, 460)
    local toggleKey = wcfg.ToggleKey or Enum.KeyCode.RightAlt
    local isPhone = UIS.TouchEnabled and not UIS.KeyboardEnabled

    local sgui = Instance.new("ScreenGui")
    sgui.Name = "iwakewar-gui"
    sgui.ResetOnSpawn = false
    sgui.DisplayOrder = 50
    sgui.IgnoreGuiInset = true
    pcall(function() sgui.Parent = game:GetService("CoreGui") end)
    if sgui.Parent == nil then sgui.Parent = LP:WaitForChild("PlayerGui") end
    self.GUI = sgui
    self.Unloaded = false

    local win = Instance.new("Frame")
    win.AnchorPoint = Vector2.new(0.5, 0.5)
    win.BackgroundColor3 = C_PANEL
    win.BorderSizePixel = 0
    win.Position = UDim2.fromScale(0.5, 0.5)
    win.Size = size
    win.Parent = sgui
    stroke(win)
    -- внутренняя рамка: двойной контур = премиально
    local inner = Instance.new("Frame")
    inner.BackgroundTransparency = 1
    inner.AnchorPoint = Vector2.new(0.5, 0.5)
    inner.Position = UDim2.fromScale(0.5, 0.5)
    inner.Size = UDim2.new(1, -8, 1, -8)
    inner.Parent = win
    stroke(inner, Color3.fromRGB(38, 38, 38))
    -- универсальный масштаб: на телефоне всё ×0.7 разом
    local uiscale = Instance.new("UIScale")
    uiscale.Scale = SC
    uiscale.Parent = win

    local accent = Instance.new("Frame")
    accent.BackgroundColor3 = C_ACCENT
    accent.BorderSizePixel = 0
    accent.Size = UDim2.new(1, 0, 0, 2)
    accent.Parent = win

    -- title bar (56px, шрифты 18/13)
    local bar = Instance.new("Frame")
    bar.BackgroundTransparency = 1
    bar.Size = UDim2.new(1, 0, 0, 56)
    bar.Parent = win
    local tt = label(bar, "> " .. title .. "_", 18, C_TXT)
    tt.Position = UDim2.new(0, 12, 0, 6)
    tt.Size = UDim2.new(1, -140, 0, 24)
    local st = label(bar, sub, 13, C_DGREEN)
    st.Position = UDim2.new(0, 12, 0, 30)
    st.Size = UDim2.new(1, -140, 0, 18)
    -- tty-отголосок alpine
    local tty = label(bar, "root@alpine:~#", 11, Color3.fromRGB(90, 90, 90), Enum.TextXAlignment.Right)
    tty.Position = UDim2.new(1, -250, 0, 30)
    tty.Size = UDim2.new(0, 120, 0, 16)
    local x = Instance.new("TextButton")
    x.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
    x.BorderSizePixel = 0
    x.Font = F
    x.Text = GUI:T("close")
    x.TextSize = 13
    x.TextColor3 = Color3.new(1, 1, 1)
    x.AutoButtonColor = false
    x.Size = UDim2.fromOffset(fitWidth(0, GUI:T("close"), 13, 24), 28)
    x.Position = UDim2.new(1, -(x.Size.X.Offset + 10), 0, 14)
    x.Parent = bar
    stroke(x, Color3.fromRGB(200, 60, 60))
    x.MouseEnter:Connect(function() x.BackgroundColor3 = Color3.fromRGB(180, 40, 40) end)
    x.MouseLeave:Connect(function() x.BackgroundColor3 = Color3.fromRGB(150, 30, 30) end)

    -- minimize: рядом с закрыть, работает везде (пк + телефон)
    local minBtn = Instance.new("TextButton")
    minBtn.BackgroundColor3 = C_PANEL2
    minBtn.BorderSizePixel = 0
    minBtn.Font = F
    minBtn.Text = GUI:T("minimize")
    minBtn.TextSize = 13
    minBtn.TextColor3 = C_TXT
    minBtn.AutoButtonColor = false
    minBtn.Size = UDim2.fromOffset(fitWidth(0, GUI:T("minimize"), 13, 24), 28)
    minBtn.Position = UDim2.new(1, -(x.Size.X.Offset + minBtn.Size.X.Offset + 16), 0, 14)
    minBtn.Parent = bar
    stroke(minBtn)
    minBtn.MouseEnter:Connect(function() minBtn.BackgroundColor3 = Color3.fromRGB(34, 34, 34) end)
    minBtn.MouseLeave:Connect(function() minBtn.BackgroundColor3 = C_PANEL2 end)

    -- плавающая кнопка: появляется при сворачивании, таскается, тап = развернуть по центру
    local floatBtn = Instance.new("TextButton")
    floatBtn.Name = "iwkFloat"
    floatBtn.Visible = false
    floatBtn.Size = UDim2.fromOffset(52, 52)
    floatBtn.Position = UDim2.new(0, 24, 0.5, -26)
    floatBtn.Text = string.sub(title, 1, 1)
    floatBtn.Font = F
    floatBtn.TextSize = 22
    floatBtn.BackgroundColor3 = C_PANEL2
    floatBtn.TextColor3 = C_TXT
    floatBtn.AutoButtonColor = false
    floatBtn.Parent = sgui
    do
        local cc = Instance.new("UICorner")
        cc.CornerRadius = UDim.new(0, 12)
        cc.Parent = floatBtn
    end
    stroke(floatBtn, C_ACCENT)
    local function setMinimized(on)
        if GUI.Unloaded then return end
        if on then
            if not win.Visible then return end
            win.Visible = false
            floatBtn.Visible = true
        else
            if win.Visible then floatBtn.Visible = false return end
            win.Visible = true
            win.Position = UDim2.fromScale(0.5, 0.5)
            floatBtn.Visible = false
        end
    end
    minBtn.MouseButton1Click:Connect(function() setMinimized(true) end)
    minBtn.Activated:Connect(function() setMinimized(true) end)
    do
        local drag, ds, sp, moved = false, nil, nil, 0
        floatBtn.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                drag, ds, sp, moved = true, i.Position, floatBtn.Position, 0
            end
        end)
        floatBtn.InputEnded:Connect(function() drag = false end)
        UIS.InputChanged:Connect(function(i)
            if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local d = i.Position - ds
                moved = d.Magnitude
                floatBtn.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
            end
        end)
        floatBtn.Activated:Connect(function()
            if moved < 14 then setMinimized(false) end
        end)
    end

    -- ресайз: всегда, за нижний-правый угол пальцем/мышкой
    do
        local grip = Instance.new("TextButton")
        grip.Name = "iwkResize"
        grip.AnchorPoint = Vector2.new(1, 1)
        grip.Position = UDim2.new(1, -2, 1, -2)
        grip.Size = UDim2.fromOffset(26, 26)
        grip.BackgroundTransparency = 1
        grip.Font = F
        grip.Text = "◢"
        grip.TextSize = 16
        grip.TextColor3 = C_DIMTXT
        grip.TextXAlignment = Enum.TextXAlignment.Right
        grip.TextYAlignment = Enum.TextYAlignment.Bottom
        grip.AutoButtonColor = false
        grip.ZIndex = 50
        grip.Parent = win
        local resizing, startPos, startSize = false, nil, nil
        grip.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                resizing, startPos, startSize = true, i.Position, win.Size
            end
        end)
        grip.InputEnded:Connect(function() resizing = false end)
        UIS.InputChanged:Connect(function(i)
            if resizing and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local sc = 1
                pcall(function() sc = uiscale.Scale end)
                if type(sc) ~= "number" or sc <= 0 then sc = 1 end
                local d = (i.Position - startPos) / sc
                local nw = math.clamp(startSize.X.Offset + d.X, 340, 1200)
                local nh = math.clamp(startSize.Y.Offset + d.Y, 280, 800)
                win.Size = UDim2.fromOffset(nw, nh)
            end
        end)
        grip.MouseEnter:Connect(function() grip.TextColor3 = C_ACCENT end)
        grip.MouseLeave:Connect(function() grip.TextColor3 = C_DIMTXT end)
    end

    -- drag (мышь + тач, чтобы на андроиде тоже таскалось за шапку)
    do
        local drag, ds, sp = false, nil, nil
        bar.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                drag, ds, sp = true, i.Position, win.Position
            end
        end)
        bar.InputEnded:Connect(function() drag = false end)
        UIS.InputChanged:Connect(function(i)
            if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local d = i.Position - ds
                win.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
            end
        end)
    end

    -- верхняя панель табов (как у классики, новее)
    local tabbar = Instance.new("Frame")
    tabbar.BackgroundTransparency = 1
    tabbar.Position = UDim2.new(0, 10, 0, 60)
    tabbar.Size = UDim2.new(1, -20, 0, 28)
    tabbar.Parent = win
    local tabLay = Instance.new("UIListLayout")
    tabLay.FillDirection = Enum.FillDirection.Horizontal
    tabLay.Padding = UDim.new(0, 6)
    tabLay.SortOrder = Enum.SortOrder.LayoutOrder
    tabLay.Parent = tabbar

    -- content holder
    local holder = Instance.new("Frame")
    holder.BackgroundTransparency = 1
    holder.Position = UDim2.new(0, 10, 0, 94)
    holder.Size = UDim2.new(1, -20, 1, -104)
    holder.Parent = win

    local Window = { _tabs = {}, _sel = nil, _sgui = sgui, _win = win }
    self._win = Window

    function Window:SelectTab(i)
        local t = self._tabs[i]
        if not t then return end
        self._sel = t
        for _, tb in ipairs(self._tabs) do
            tb.page.Visible = (tb == t)
            tb.btn.TextColor3 = (tb == t) and C_ACCENT or C_TXT
            if tb.bar then tb.bar.Visible = (tb == t) end
        end
    end

    function Window:AddTab(tcfg)
        local name = tcfg.Title or ("Tab" .. (#self._tabs + 1))
        local b = btn(tabbar, name, C_TXT)
        b.AutomaticSize = Enum.AutomaticSize.X
        b.Size = UDim2.new(0, 0, 0, 28)
        b.TextXAlignment = Enum.TextXAlignment.Center
        local bp = Instance.new("UIPadding")
        bp.PaddingLeft = UDim.new(0, 16)
        bp.PaddingRight = UDim.new(0, 16)
        bp.Parent = b
        -- акцентная черта активного таба снизу
        local bar2 = Instance.new("Frame")
        bar2.BackgroundColor3 = C_ACCENT
        bar2.BorderSizePixel = 0
        bar2.Position = UDim2.new(0, 0, 1, -2)
        bar2.Size = UDim2.new(1, 0, 0, 2)
        bar2.Visible = false
        bar2.Parent = b
        local page = Instance.new("ScrollingFrame")
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.Size = UDim2.fromScale(1, 1)
        page.Visible = false
        page.ScrollBarThickness = 3
        page.ScrollBarImageColor3 = C_LINE
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.Parent = holder
        local lay = Instance.new("UIListLayout")
        lay.FillDirection = Enum.FillDirection.Vertical
        lay.Padding = UDim.new(0, 6)
        lay.SortOrder = Enum.SortOrder.LayoutOrder
        lay.Parent = page
        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 2)
        pad.PaddingRight = UDim.new(0, 6)
        pad.PaddingLeft = UDim.new(0, 2)
        pad.Parent = page
        local tab = { name = name, btn = b, page = page, _win = self, bar = bar2 }
        b.MouseButton1Click:Connect(function()
            for i, tb in ipairs(self._tabs) do
                if tb == tab then self:SelectTab(i) break end
            end
        end)
        table.insert(self._tabs, tab)
        tab._box = nil

        function tab:AddSection(text)
            -- групбокс как у классики: рамка + акцентный заголовок, элементы ниже едут внутрь
            local box = Instance.new("Frame")
            box.BackgroundColor3 = C_PANEL
            box.BorderSizePixel = 0
            box.Size = UDim2.new(1, 0, 0, 40)
            box.AutomaticSize = Enum.AutomaticSize.Y
            box.LayoutOrder = #page:GetChildren() * 10
            box.Parent = page
            stroke(box)
            local ht = label(box, tostring(text), 13, C_ACCENT)
            ht.Position = UDim2.new(0, 10, 0, 4)
            ht.Size = UDim2.new(1, -20, 0, 18)
            local sep = Instance.new("Frame")
            sep.BackgroundColor3 = C_LINE_DARK
            sep.BorderSizePixel = 0
            sep.Position = UDim2.new(0, 10, 0, 24)
            sep.Size = UDim2.new(1, -20, 0, 1)
            sep.Parent = box
            local inner = Instance.new("Frame")
            inner.BackgroundTransparency = 1
            inner.Position = UDim2.new(0, 10, 0, 30)
            inner.Size = UDim2.new(1, -20, 0, 10)
            inner.AutomaticSize = Enum.AutomaticSize.Y
            inner.Parent = box
            local il = Instance.new("UIListLayout")
            il.FillDirection = Enum.FillDirection.Vertical
            il.Padding = UDim.new(0, 6)
            il.SortOrder = Enum.SortOrder.LayoutOrder
            il.Parent = inner
            local ip = Instance.new("UIPadding")
            ip.PaddingBottom = UDim.new(0, 8)
            ip.Parent = inner
            tab._box = inner
        end

        local function host()
            return tab._box or page
        end

        function tab:AddParagraph(pcfg)
            local f = Instance.new("Frame")
            f.BackgroundColor3 = C_PANEL2
            f.BorderSizePixel = 0
            f.Size = UDim2.new(1, 0, 0, 54)
            f.AutomaticSize = Enum.AutomaticSize.Y
            f.Parent = host()
            stroke(f)
            local t = label(f, tostring(pcfg.Title or ""), 13, C_TXT)
            t.Position = UDim2.new(0, 10, 0, 4)
            t.Size = UDim2.new(1, -20, 0, 18)
            local c = label(f, tostring(pcfg.Content or ""), 11, C_DIMTXT)
            c.Position = UDim2.new(0, 10, 0, 22)
            c.Size = UDim2.new(1, -16, 0, 28)
            c.AutomaticSize = Enum.AutomaticSize.Y
            c.TextWrapped = true
            local o = {}
            function o:SetContent(t2) c.Text = tostring(t2) end
            function o:SetTitle(t2) t.Text = tostring(t2) end
            function o:SetDesc(t2) c.Text = tostring(t2) end
            return o
        end

        function tab:AddButton(bcfg)
            local b2 = btn(host(), tostring(bcfg.Title or "Button"), C_TXT)
            b2.Size = UDim2.new(1, 0, 0, 30)
            b2.TextXAlignment = Enum.TextXAlignment.Left
            if bcfg.Description then
                b2.Text = tostring(bcfg.Title) .. "  [" .. tostring(bcfg.Description) .. "]"
            end
            b2.MouseButton1Click:Connect(function()
                if bcfg.Callback then task.spawn(bcfg.Callback) end
            end)
            return b2
        end

        function tab:AddToggle(id, tcfg)
            -- строка-чекбокс как у классики: квадрат слева + текст, без отдельной панели
            local f = Instance.new("TextButton")
            f.BackgroundTransparency = 1
            f.BorderSizePixel = 0
            f.Size = UDim2.new(1, 0, 0, 24)
            f.Text = ""
            f.AutoButtonColor = false
            f.Parent = host()
            local box = Instance.new("Frame")
            box.BackgroundColor3 = C_PANEL2
            box.BorderSizePixel = 0
            box.Position = UDim2.new(0, 2, 0.5, -8)
            box.Size = UDim2.fromOffset(16, 16)
            box.Parent = f
            stroke(box)
            local mark = Instance.new("Frame")
            mark.BackgroundColor3 = C_ACCENT
            mark.BorderSizePixel = 0
            mark.AnchorPoint = Vector2.new(0.5, 0.5)
            mark.Position = UDim2.fromScale(0.5, 0.5)
            mark.Size = UDim2.new(1, -6, 1, -6)
            mark.Visible = false
            mark.Parent = box
            local t = label(f, tostring(tcfg.Title or id), 13, C_TXT)
            t.Position = UDim2.new(0, 26, 0, 0)
            t.Size = UDim2.new(1, -30, 1, 0)
            t.TextYAlignment = Enum.TextYAlignment.Center
            t.TextTruncate = Enum.TextTruncate.AtEnd
            local tog = { Value = false, _cbs = {} }
            local function paint()
                mark.Visible = tog.Value
                box.BackgroundColor3 = tog.Value and C_ACCENT_DARK or C_PANEL2
                t.TextColor3 = tog.Value and C_TXT or C_DIMTXT
            end
            function tog:SetValue(v)
                v = (v == true)
                if tog.Value == v then return end
                tog.Value = v
                paint()
                for _, fn in ipairs(tog._cbs) do task.spawn(fn, v) end
                for _, fn in ipairs(tog._clicks or {}) do task.spawn(fn, v) end
                if tcfg.Callback then task.spawn(tcfg.Callback, v) end
            end
            function tog:OnChanged(fn) table.insert(tog._cbs, fn) end
            function tog:OnClick(fn) table.insert(tog._clicks or {}, fn) end
            f.MouseButton1Click:Connect(function() tog:SetValue(not tog.Value) end)
            tog.Value = (tcfg.Default == true)
            paint()
            GUI.Options[id] = tog
            if tcfg.Callback and tog.Value then task.spawn(tcfg.Callback, true) end
            return tog
        end

        function tab:AddSlider(id, scfg)
            local min, max = tonumber(scfg.Min) or 0, tonumber(scfg.Max) or 100
            local round = tonumber(scfg.Rounding) or 0
            local mult = 10 ^ round
            local function fmt(v)
                v = math.clamp(v, min, max)
                v = math.floor(v * mult + 0.5) / mult
                return v
            end
            local f = Instance.new("Frame")
            f.BackgroundTransparency = 1
            f.BorderSizePixel = 0
            f.Size = UDim2.new(1, 0, 0, 40)
            f.Parent = host()
            local t = label(f, tostring(scfg.Title or id), 13, C_TXT)
            t.Position = UDim2.new(0, 2, 0, 0)
            t.Size = UDim2.new(1, -70, 0, 18)
            local val = label(f, "", 12, C_ACCENT, Enum.TextXAlignment.Right)
            val.Position = UDim2.new(1, -62, 0, 0)
            val.Size = UDim2.new(0, 60, 0, 18)
            local rail = Instance.new("TextButton")
            rail.BackgroundColor3 = C_PANEL2
            rail.BorderSizePixel = 0
            rail.Position = UDim2.new(0, 2, 0, 22)
            rail.Size = UDim2.new(1, -4, 0, 12)
            rail.Text = ""
            rail.AutoButtonColor = false
            rail.Parent = f
            stroke(rail, C_LINE_DARK)
            local fill = Instance.new("Frame")
            fill.BackgroundColor3 = C_ACCENT
            fill.BorderSizePixel = 0
            fill.Size = UDim2.new(0, 0, 1, 0)
            fill.Parent = rail
            -- белый knob как у классики
            local knob = Instance.new("Frame")
            knob.BackgroundColor3 = Color3.new(1, 1, 1)
            knob.BorderSizePixel = 0
            knob.AnchorPoint = Vector2.new(0.5, 0.5)
            knob.Position = UDim2.new(0, 0, 0.5, 0)
            knob.Size = UDim2.fromOffset(10, 16)
            knob.Parent = rail
            local sld = { Value = fmt(tonumber(scfg.Default) or min), _cbs = {} }
            local function paint()
                local r = (sld.Value - min) / math.max(0.0001, (max - min))
                r = math.clamp(r, 0, 1)
                fill.Size = UDim2.new(r, 0, 1, 0)
                knob.Position = UDim2.new(r, 0, 0.5, 0)
                val.Text = tostring(sld.Value)
            end
            function sld:SetValue(v)
                v = fmt(tonumber(v) or min)
                sld.Value = v
                paint()
                for _, fn in ipairs(sld._cbs) do task.spawn(fn, v) end
                if scfg.Callback then task.spawn(scfg.Callback, v) end
            end
            function sld:OnChanged(fn) table.insert(sld._cbs, fn) end
            do
                local drag = false
                local function apply(x)
                    local p0, sz = rail.AbsolutePosition.X, rail.AbsoluteSize.X
                    if sz <= 0 then return end
                    sld:SetValue(min + math.clamp((x - p0) / sz, 0, 1) * (max - min))
                end
                rail.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1
                        or i.UserInputType == Enum.UserInputType.Touch then
                        drag = true
                        apply(i.Position.X)
                    end
                end)
                rail.InputEnded:Connect(function() drag = false end)
                UIS.InputChanged:Connect(function(i)
                    if drag and (i.UserInputType == Enum.UserInputType.MouseMovement
                        or i.UserInputType == Enum.UserInputType.Touch) then
                        apply(i.Position.X)
                    end
                end)
            end
            paint()
            GUI.Options[id] = sld
            return sld
        end

        function tab:AddDropdown(id, dcfg)
            local vals = dcfg.Values or {}
            local cur = dcfg.Default
            if typeof(cur) == "number" then cur = vals[cur] end
            if cur == nil then cur = vals[1] end
            local f = Instance.new("Frame")
            f.BackgroundTransparency = 1
            f.BorderSizePixel = 0
            f.Size = UDim2.new(1, 0, 0, 26)
            f.Parent = host()
            local t = label(f, tostring(dcfg.Title or id), 13, C_TXT)
            t.Position = UDim2.new(0, 2, 0, 0)
            t.Size = UDim2.new(0.5, 0, 1, 0)
            t.TextYAlignment = Enum.TextYAlignment.Center
            local b2 = btn(f, tostring(cur) .. " [+]", C_ACCENT)
            b2.Size = UDim2.new(0.45, -16, 0, 22)
            b2.Position = UDim2.new(0.55, 8, 0.5, -11)
            b2.TextSize = 12
            local dd = { Value = cur, _cbs = {} }
            local pop = nil
            local function close()
                if pop then pop:Destroy() pop = nil end
                b2.Text = tostring(dd.Value) .. " [+]"
            end
            function dd:SetValue(v)
                dd.Value = v
                close()
                for _, fn in ipairs(dd._cbs) do task.spawn(fn, v) end
                if dcfg.Callback then task.spawn(dcfg.Callback, v) end
            end
            function dd:OnChanged(fn) table.insert(dd._cbs, fn) end
            b2.MouseButton1Click:Connect(function()
                if pop then close() return end
                b2.Text = tostring(dd.Value) .. " [-]"
                pop = Instance.new("Frame")
                pop.BackgroundColor3 = C_PANEL
                pop.BorderSizePixel = 0
                pop.Size = UDim2.new(0, b2.AbsoluteSize.X, 0, math.min(#vals, 6) * 24 + 8)
                pop.Position = UDim2.fromOffset(b2.AbsolutePosition.X, b2.AbsolutePosition.Y + 24)
                pop.ZIndex = 100
                pop.Parent = sgui
                stroke(pop)
                local ll = Instance.new("UIListLayout")
                ll.Padding = UDim.new(0, 2)
                ll.Parent = pop
                local pd = Instance.new("UIPadding")
                pd.PaddingTop = UDim.new(0, 4)
                pd.PaddingLeft = UDim.new(0, 4)
                pd.PaddingRight = UDim.new(0, 4)
                pd.Parent = pop
                for _, v in ipairs(vals) do
                    local ob = btn(pop, tostring(v), (v == dd.Value) and C_ACCENT or C_TXT)
                    ob.Size = UDim2.new(1, 0, 0, 22)
                    ob.TextSize = 12
                    ob.ZIndex = 101
                    ob.MouseButton1Click:Connect(function() dd:SetValue(v) end)
                end
            end)
            GUI.Options[id] = dd
            return dd
        end

        function tab:AddColorpicker(id, ccfg)
            local cur = ccfg.Default
            if typeof(cur) ~= "Color3" then cur = C_ACCENT end
            local f = Instance.new("Frame")
            f.BackgroundTransparency = 1
            f.BorderSizePixel = 0
            f.Size = UDim2.new(1, 0, 0, 26)
            f.Parent = host()
            local t = label(f, tostring(ccfg.Title or id), 13, C_TXT)
            t.Position = UDim2.new(0, 2, 0, 0)
            t.Size = UDim2.new(1, -70, 1, 0)
            t.TextYAlignment = Enum.TextYAlignment.Center
            local sw = Instance.new("TextButton")
            sw.BackgroundColor3 = cur
            sw.BorderSizePixel = 0
            sw.Size = UDim2.fromOffset(64, 22)
            sw.Position = UDim2.new(1, -70, 0.5, -11)
            sw.Text = ""
            sw.AutoButtonColor = false
            sw.Parent = f
            stroke(sw)
            local cp = { Value = cur, _cbs = {} }
            local pop = nil
            local function fire()
                sw.BackgroundColor3 = cp.Value
                for _, fn in ipairs(cp._cbs) do task.spawn(fn, cp.Value) end
                if ccfg.Callback then task.spawn(ccfg.Callback, cp.Value) end
            end
            function cp:SetValue(c)
                if typeof(c) == "Color3" then cp.Value = c fire() end
            end
            function cp:OnChanged(fn) table.insert(cp._cbs, fn) end
            sw.MouseButton1Click:Connect(function()
                if pop then pop:Destroy() pop = nil return end
                pop = Instance.new("Frame")
                pop.BackgroundColor3 = C_PANEL
                pop.BorderSizePixel = 0
                pop.Size = UDim2.fromOffset(220, 118)
                pop.Position = UDim2.fromOffset(sw.AbsolutePosition.X - 156, sw.AbsolutePosition.Y + 24)
                pop.ZIndex = 100
                pop.Parent = sgui
                stroke(pop)
                local rgb = { math.floor(cur.R * 255), math.floor(cur.G * 255), math.floor(cur.B * 255) }
                local names = { "R", "G", "B" }
                for i = 1, 3 do
                    local rl = label(pop, names[i], 12, C_DIMTXT)
                    rl.Position = UDim2.new(0, 8, 0, 6 + (i - 1) * 28)
                    rl.Size = UDim2.new(0, 14, 0, 18)
                    rl.ZIndex = 101
                    local rail = Instance.new("TextButton")
                    rail.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
                    rail.BorderSizePixel = 0
                    rail.Position = UDim2.new(0, 26, 0, 8 + (i - 1) * 28)
                    rail.Size = UDim2.new(1, -70, 0, 12)
                    rail.Text = ""
                    rail.AutoButtonColor = false
                    rail.ZIndex = 101
                    rail.Parent = pop
                    stroke(rail, Color3.fromRGB(50, 50, 50))
                    local fill = Instance.new("Frame")
                    fill.BackgroundColor3 = C_GREEN
                    fill.BorderSizePixel = 0
                    fill.Size = UDim2.new(rgb[i] / 255, 0, 1, 0)
                    fill.Parent = rail
                    local vl = label(pop, tostring(rgb[i]), 12, C_GREEN, Enum.TextXAlignment.Right)
                    vl.Position = UDim2.new(1, -40, 0, 6 + (i - 1) * 28)
                    vl.Size = UDim2.new(0, 32, 0, 18)
                    vl.ZIndex = 101
                    do
                        local idx = i
                        local drag = false
                        local function apply(x)
                            local p0, sz = rail.AbsolutePosition.X, rail.AbsoluteSize.X
                            if sz <= 0 then return end
                            rgb[idx] = math.floor(math.clamp((x - p0) / sz, 0, 1) * 255 + 0.5)
                            fill.Size = UDim2.new(rgb[idx] / 255, 0, 1, 0)
                            vl.Text = tostring(rgb[idx])
                            cp.Value = Color3.fromRGB(rgb[1], rgb[2], rgb[3])
                            sw.BackgroundColor3 = cp.Value
                        end
                        rail.InputBegan:Connect(function(inp)
                            if inp.UserInputType == Enum.UserInputType.MouseButton1
                                or inp.UserInputType == Enum.UserInputType.Touch then
                                drag = true
                                apply(inp.Position.X)
                            end
                        end)
                        rail.InputEnded:Connect(function()
                            if drag then drag = false fire() end
                        end)
                        UIS.InputChanged:Connect(function(inp)
                            if drag and (inp.UserInputType == Enum.UserInputType.MouseMovement
                                or inp.UserInputType == Enum.UserInputType.Touch) then
                                apply(inp.Position.X)
                            end
                        end)
                    end
                end
                local okb = btn(pop, "[ done ]", C_GREEN)
                okb.Size = UDim2.new(1, -16, 0, 22)
                okb.Position = UDim2.new(0, 8, 0, 90)
                okb.ZIndex = 101
                okb.MouseButton1Click:Connect(function()
                    if pop then pop:Destroy() pop = nil end
                    fire()
                end)
            end)
            GUI.Options[id] = cp
            return cp
        end

        function tab:AddKeybind(id, kcfg)
            local key = tostring(kcfg.Default or "H")
            local mode = kcfg.Mode or "Toggle"
            local f = Instance.new("Frame")
            f.BackgroundTransparency = 1
            f.BorderSizePixel = 0
            f.Size = UDim2.new(1, 0, 0, 26)
            f.Parent = host()
            local t = label(f, tostring(kcfg.Title or id), 13, C_TXT)
            t.Position = UDim2.new(0, 2, 0, 0)
            t.Size = UDim2.new(1, -80, 1, 0)
            t.TextYAlignment = Enum.TextYAlignment.Center
            local kb = btn(f, "[ " .. key .. " ]", C_ACCENT)
            kb.AutomaticSize = Enum.AutomaticSize.X
            kb.Size = UDim2.new(0, 0, 0, 22)
            kb.AnchorPoint = Vector2.new(1, 0.5)
            kb.Position = UDim2.new(1, -10, 0.5, 0)
            kb.TextSize = 12
            local k = { Value = key, _state = false, _cbs = {}, _clicks = {}, _mode = mode }
            local capturing = false
            function k:GetState() return k._state end
            function k:SetValue(nk, nmode)
                if nk then
                    key = tostring(nk)
                    k.Value = key
                    kb.Text = "[ " .. key .. " ]"
                end
                if nmode then mode = nmode k._mode = nmode end
            end
            function k:OnChanged(fn) table.insert(k._cbs, fn) end
            function k:OnClick(fn) table.insert(k._clicks, fn) end
            local function fire(st)
                k._state = st
                for _, fn in ipairs(k._clicks) do task.spawn(fn, st) end
                for _, fn in ipairs(k._cbs) do task.spawn(fn, st) end
                if kcfg.Callback then task.spawn(kcfg.Callback, st) end
            end
            kb.MouseButton1Click:Connect(function()
                capturing = true
                kb.Text = "[ ... ]"
            end)
            k._fire = fire
            k._isCapturing = function() return capturing end
            k._capture = function(nk)
                capturing = false
                k:SetValue(nk)
                if kcfg.ChangedCallback then task.spawn(kcfg.ChangedCallback, nk) end
            end
            GUI.Options[id] = k
            k._toggleKey = key
            return k
        end
        return tab
    end

    -- global key handling: capture + keybind toggles + window toggle
    do
        UIS.InputBegan:Connect(function(input, gpe)
            if GUI.Unloaded then return end
            local kc = input.KeyCode
            if kc == Enum.KeyCode.Unknown then return end
            -- capture mode
            for _, tb in ipairs(Window._tabs) do
                -- handled per-keybind below via Options
            end
            for _, k in pairs(GUI.Options) do
                if type(k) == "table" and k._capture and k._isCapturing and k:_isCapturing() then
                    if UIS:GetFocusedTextBox() == nil then
                        k:_capture(kc.Name)
                        return
                    end
                end
            end
            if gpe then return end
            if kc == toggleKey then
                sgui.Enabled = not sgui.Enabled
                return
            end
            if UIS:GetFocusedTextBox() ~= nil then return end
            for _, k in pairs(GUI.Options) do
                if type(k) == "table" and k._fire and tostring(k.Value) == kc.Name then
                    if kcfg_mode(k) == "Toggle" then
                        k:_fire(not k:GetState())
                    elseif kcfg_mode(k) == "Hold" then
                        k:_fire(true)
                    else
                        k:_fire(true)
                        task.delay(0.1, function() k:_fire(false) end)
                    end
                end
            end
        end)
        UIS.InputEnded:Connect(function(input)
            if GUI.Unloaded then return end
            local kc = input.KeyCode
            if kc == Enum.KeyCode.Unknown then return end
            for _, k in pairs(GUI.Options) do
                if type(k) == "table" and k._fire and tostring(k.Value) == kc.Name and kcfg_mode(k) == "Hold" then
                    k:_fire(false)
                end
            end
        end)
    end

    x.MouseButton1Click:Connect(function()
        GUI:Destroy()
    end)

    -- старый отдельный тоггл для телефонов удалён: теперь универсальная
    -- плавающая кнопка iwkFloat (см. выше) работает везде через "Свернуть".
    -- отдельный ScreenGui iwkToggle больше не создаём, чтобы не было дублей.

    -- terminal tab: всегда последняя, максимально снизу
    task.defer(function()
        if GUI.Unloaded then return end
        pcall(function()
            buildTerminal(Window)
            if #Window._tabs > 0 and (Window._sel == nil or Window._sel == Window._tabs[1]) then
                -- не трогаем выбор скрипта; терминал просто в конце списка
            end
        end)
    end)

    return Window
end

-- keybind mode reader (modes stored per keybind object)
function kcfg_mode(k)
    return (k and k._mode) or "Toggle"
end

-- ============ LOADER MODE ============
-- Отдельный режим под лоадер: как main.luau, но на стилях либы.
-- local L = GUI:Loader({ title = "> iwakewar-scripts_" })
-- L.log("boot...") L.startMarquee() L.stopMarquee(true) L.fail(msg) L.ok(msg)
-- L.showClose() L.close()
function GUI:Loader(ocfg)
    ocfg = ocfg or {}
    local title = ocfg.title or "> iwakewar-scripts_"
    local sub = ocfg.sub or "[loader v2] :: terminal"
    local sgui = Instance.new("ScreenGui")
    sgui.Name = ocfg.name or "iwakewar-loader"
    sgui.DisplayOrder = 100
    sgui.IgnoreGuiInset = true
    sgui.ResetOnSpawn = false
    pcall(function() sgui.Parent = game:GetService("CoreGui") end)
    if sgui.Parent == nil then sgui.Parent = LP:WaitForChild("PlayerGui") end
    if ocfg.dim ~= false then
        local dim = Instance.new("Frame")
        dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        dim.BorderSizePixel = 0
        dim.Size = UDim2.fromScale(1, 1)
        dim.Parent = sgui
    end
    local win = Instance.new("Frame")
    win.AnchorPoint = Vector2.new(0.5, 0.5)
    win.BackgroundColor3 = C_PANEL
    win.BorderSizePixel = 0
    win.Position = UDim2.fromScale(0.5, 0.5)
    win.Size = UDim2.fromOffset(480, 400)
    win.Parent = sgui
    stroke(win)
    local inner = Instance.new("Frame")
    inner.BackgroundTransparency = 1
    inner.AnchorPoint = Vector2.new(0.5, 0.5)
    inner.Position = UDim2.fromScale(0.5, 0.5)
    inner.Size = UDim2.new(1, -8, 1, -8)
    inner.Parent = win
    stroke(inner, Color3.fromRGB(38, 38, 38))
    local accent = Instance.new("Frame")
    accent.BackgroundColor3 = C_ACCENT
    accent.BorderSizePixel = 0
    accent.Size = UDim2.new(1, 0, 0, 2)
    accent.Parent = win
    local tt = label(win, title, 18, C_TXT)
    tt.Position = UDim2.new(0, 12, 0, 10)
    tt.Size = UDim2.new(1, -150, 0, 24)
    local tty = label(win, "root@alpine:~#", 11, Color3.fromRGB(90, 90, 90), Enum.TextXAlignment.Right)
    tty.Position = UDim2.new(1, -140, 0, 12)
    tty.Size = UDim2.new(0, 128, 0, 16)
    local sb = label(win, sub, 13, C_DGREEN)
    sb.Position = UDim2.new(0, 12, 0, 34)
    sb.Size = UDim2.new(1, -24, 0, 16)
    local sep = Instance.new("Frame")
    sep.BackgroundColor3 = C_LINE
    sep.BorderSizePixel = 0
    sep.Position = UDim2.new(0, 12, 0, 56)
    sep.Size = UDim2.new(1, -24, 0, 1)
    sep.Parent = win
    local console = Instance.new("Frame")
    console.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
    console.BorderSizePixel = 0
    console.Position = UDim2.new(0, 12, 0, 64)
    console.Size = UDim2.new(1, -24, 0, 180)
    console.Parent = win
    stroke(console, Color3.fromRGB(50, 50, 50))
    local cpad = Instance.new("UIPadding")
    cpad.PaddingLeft = UDim.new(0, 8)
    cpad.PaddingRight = UDim.new(0, 8)
    cpad.PaddingTop = UDim.new(0, 6)
    cpad.PaddingBottom = UDim.new(0, 6)
    cpad.Parent = console
    local clay = Instance.new("UIListLayout")
    clay.FillDirection = Enum.FillDirection.Vertical
    clay.Padding = UDim.new(0, 2)
    clay.SortOrder = Enum.SortOrder.LayoutOrder
    clay.Parent = console
    local barBG = Instance.new("Frame")
    barBG.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    barBG.BorderSizePixel = 0
    barBG.Position = UDim2.new(0, 12, 0, 252)
    barBG.Size = UDim2.new(1, -24, 0, 14)
    barBG.Visible = false
    barBG.Parent = win
    stroke(barBG, Color3.fromRGB(90, 90, 90))
    local chunk = Instance.new("Frame")
    chunk.BackgroundColor3 = C_GREEN
    chunk.BorderSizePixel = 0
    chunk.Position = UDim2.fromScale(0, 0)
    chunk.Size = UDim2.fromScale(0.25, 1)
    chunk.Parent = barBG
    local function mkB(text, xs, ws, red)
        local b = Instance.new("TextButton")
        b.BackgroundColor3 = red and Color3.fromRGB(150, 30, 30) or Color3.fromRGB(24, 24, 24)
        b.BorderSizePixel = 0
        b.Font = F
        b.Position = UDim2.new(xs, 0, 1, -40)
        b.Size = UDim2.new(ws, -5, 0, 30)
        b.Text = text
        b.TextColor3 = red and Color3.new(1, 1, 1) or C_TXT
        b.TextSize = 14
        b.AutoButtonColor = false
        b.Visible = false
        b.Parent = win
        stroke(b, red and Color3.fromRGB(200, 60, 60) or nil)
        local base = b.BackgroundColor3
        b.MouseEnter:Connect(function()
            b.BackgroundColor3 = red and Color3.fromRGB(180, 40, 40) or Color3.fromRGB(34, 34, 34)
        end)
        b.MouseLeave:Connect(function() b.BackgroundColor3 = base end)
        return b
    end
    local closeB = mkB("Close", 0.022, 0.466, true)
    closeB.MouseButton1Click:Connect(function() sgui:Destroy() end)
    local L = { _marquee = false, _n = 0, _failed = false }
    function L.log(text, color)
        L._n = L._n + 1
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Font = F
        l.Size = UDim2.new(1, 0, 0, 16)
        l.Text = tostring(text)
        l.TextColor3 = color or C_DIMTXT
        l.TextSize = 13
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextTruncate = Enum.TextTruncate.AtEnd
        l.LayoutOrder = L._n
        l.Parent = console
    end
    function L.startMarquee()
        barBG.Visible = true
        if L._marquee then return end
        L._marquee = true
        task.spawn(function()
            local pos, dir = 0, 1
            while L._marquee and barBG.Parent do
                pos = pos + dir * 0.05
                if pos >= 0.75 then dir = -1 end
                if pos <= 0 then dir = 1 end
                chunk.Position = UDim2.fromScale(pos, 0)
                task.wait(0.06)
            end
        end)
    end
    function L.stopMarquee(ok)
        L._marquee = false
        barBG.Visible = true
        chunk.Position = UDim2.fromScale(0, 0)
        chunk.Size = UDim2.fromScale(1, 1)
        chunk.BackgroundColor3 = ok and C_GREEN or C_RED
    end
    function L.fail(msg)
        L._failed = true
        warn("[iwk-loader] " .. tostring(msg))
        L.stopMarquee(false)
        L.log("> " .. tostring(msg), C_RED)
        closeB.Visible = true
    end
    function L.ok(msg)
        L.stopMarquee(true)
        L.log("> " .. tostring(msg), C_GREEN)
    end
    function L.showClose() closeB.Visible = true end
    function L.close()
        if sgui.Parent then sgui:Destroy() end
    end
    function L.didFail() return L._failed end
    return L
end

function GUI:Destroy()
    self.Unloaded = true
    pcall(function()
        if self.GUI then self.GUI:Destroy() end
    end)
    pcall(function()
        local cg = game:GetService("CoreGui"):FindFirstChild("iwkToggle")
        if cg then cg:Destroy() end
    end)
    table.clear(self.Options)
end

return GUI
