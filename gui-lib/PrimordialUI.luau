--[[
    PrimordialUI 1.1 — flat dark hub UI for Roblox executors.
    Style: left category sidebar, top sub-tab strip, cards with header strips,
    compact rows, soft shadows, gradients and glassy dropdowns.
    Sibling of "Primordial Loader" (Lib:Loader) — the same visual system for
    splash screens. No external dependencies.

    Usage:
        local UI = loadstring(game:HttpGet(".../gui-lib/PrimordialUI.luau"))()
        local Window = UI:CreateWindow({ Title = "My Script", Subtitle = "v1.0" })
        local Tab = Window:Tab({ Title = "Aim Assist", Subtitle = "Help your aim" })
        Tab:Section({ Title = "General" })
        Tab:Toggle({ Title = "Enable", Default = true, Callback = function(v) end })
        UI:Notify({ Title = "Loaded", Content = "Ready", Duration = 4 })

    API stays close to WindUI so existing scripts port with minimal edits:
    :Tab, :Section, :Paragraph, :Toggle, :Dropdown, :Keybind, :Slider,
    :Button, :Notify, :SelectTab, :SetToggleKey, :OnLangChanged, :SetLang,
    plus SetTitle / SetDesc / SetContent / SetValue on every element.
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")

local plr = Players.LocalPlayer

-- ======================================================================
-- palette
-- ======================================================================
local P = {
    bg = Color3.fromRGB(42, 42, 45),
    chrome = Color3.fromRGB(36, 36, 39),
    stroke = Color3.fromRGB(86, 86, 94),
    card = Color3.fromRGB(53, 53, 57),
    cardHead = Color3.fromRGB(62, 62, 67),
    cardHover = Color3.fromRGB(59, 59, 64),
    element = Color3.fromRGB(68, 68, 74),
    elementHover = Color3.fromRGB(80, 80, 88),
    text = Color3.fromRGB(236, 236, 241),
    sub = Color3.fromRGB(160, 160, 171),
    dim = Color3.fromRGB(118, 118, 128),
    accent = Color3.fromRGB(216, 132, 171),
    track = Color3.fromRGB(86, 86, 94),
    knob = Color3.fromRGB(238, 238, 244),
    danger = Color3.fromRGB(214, 94, 103),
    checkMark = Color3.fromRGB(26, 18, 22),

    -- градиентные пары (верх/низ) для объёма: окно, карточки, элементы.
    -- Всё в тех же тёмных оттенках, чтобы не выбиваться из палитры.
    bgTop = Color3.fromRGB(47, 47, 51),
    bgBottom = Color3.fromRGB(36, 36, 39),
    chromeTop = Color3.fromRGB(41, 41, 44),
    chromeBottom = Color3.fromRGB(31, 31, 34),
    sidebarTop = Color3.fromRGB(41, 41, 44),
    sidebarBottom = Color3.fromRGB(34, 34, 37),
    cardTop = Color3.fromRGB(58, 58, 63),
    cardBottom = Color3.fromRGB(48, 48, 52),
    cardHoverTop = Color3.fromRGB(64, 64, 70),
    cardHoverBottom = Color3.fromRGB(54, 54, 59),
    headTop = Color3.fromRGB(71, 71, 77),
    headBottom = Color3.fromRGB(59, 59, 64),
    elemTop = Color3.fromRGB(75, 75, 82),
    elemBottom = Color3.fromRGB(62, 62, 68),
    elemHoverTop = Color3.fromRGB(88, 88, 96),
    elemHoverBottom = Color3.fromRGB(72, 72, 80),
    accentTop = Color3.fromRGB(233, 157, 192),
    accentBottom = Color3.fromRGB(188, 105, 145),
    rim = Color3.fromRGB(255, 255, 255),
}

local FONT_FAMILY = "rbxasset://fonts/families/JosefinSans.json"
local W_REG = Enum.FontWeight.Regular
local W_MED = Enum.FontWeight.Medium
local W_SEMI = Enum.FontWeight.SemiBold
local W_BOLD = Enum.FontWeight.Bold

-- JosefinSans вместо стандартного Gotham: свой шрифт без "роблоксовского" вида.
-- Если семейство не подгрузилось — молча падаем на Gotham.
local function applyFont(o, weight)
    local ok = pcall(function()
        o.FontFace = Font.new(FONT_FAMILY, weight or W_REG)
    end)
    if not ok then o.Font = Enum.Font.Gotham end
end

-- ======================================================================
-- builders
-- ======================================================================
local function new(class, props, parent)
    local o = Instance.new(class)
    if props then
        for k, v in pairs(props) do o[k] = v end
    end
    if parent then o.Parent = parent end
    return o
end

local function corner(o, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 3)
    c.Parent = o
    return c
end

local function stroke(o, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or P.stroke
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = o
    return s
end

local function padAll(o, l, t, r, b)
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, l or 0)
    p.PaddingTop = UDim.new(0, t or 0)
    p.PaddingRight = UDim.new(0, r or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.Parent = o
    return p
end

local function listLayout(o, gap, dir)
    local l = Instance.new("UIListLayout")
    l.FillDirection = dir or Enum.FillDirection.Vertical
    l.Padding = UDim.new(0, gap or 0)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.VerticalAlignment = Enum.VerticalAlignment.Top
    l.Parent = o
    return l
end

local function text(parent, props, weight)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.BorderSizePixel = 0
    l.TextSize = 13
    l.TextColor3 = P.text
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Text = ""
    l.RichText = false
    if props then
        for k, v in pairs(props) do l[k] = v end
    end
    applyFont(l, weight)
    l.Parent = parent
    return l
end

local function button(parent, props, weight)
    local b = Instance.new("TextButton")
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.TextSize = 13
    b.TextColor3 = P.text
    b.Text = ""
    b.TextXAlignment = Enum.TextXAlignment.Left
    if props then
        for k, v in pairs(props) do b[k] = v end
    end
    applyFont(b, weight)
    b.Parent = parent
    return b
end

-- рисованный логотип: не зависим от того, есть ли символ в шрифте
local function drawLogoMark(parent, size, color)
    local mark = new("Frame", {
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(size, size),
        Position = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Rotation = 45,
    }, parent)
    corner(mark, 2)
    local inner = new("Frame", {
        BackgroundColor3 = P.chrome,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(size * 0.42, size * 0.42),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
    }, mark)
    corner(inner, 1)
    return mark
end

local function tween(o, time, props)
    TweenService:Create(o, TweenInfo.new(time or 0.12, Enum.EasingStyle.Quad), props):Play()
end

-- ======================================================================
-- gradients / depth helpers
-- ======================================================================
local function colorSeq(list)
    local kps = {}
    for _, k in ipairs(list) do
        kps[#kps + 1] = ColorSequenceKeypoint.new(k[1], k[2])
    end
    return ColorSequence.new(kps)
end

local function numberSeq(list)
    local kps = {}
    for _, k in ipairs(list) do
        kps[#kps + 1] = NumberSequenceKeypoint.new(k[1], k[2])
    end
    return NumberSequence.new(kps)
end

-- вертикальный градиент (сверху -> снизу): основной приём объёма
local function vgrad(o, top, bottom, trans)
    local g = Instance.new("UIGradient")
    g.Rotation = 90
    g.Color = colorSeq({ { 0, top }, { 1, bottom } })
    if trans then g.Transparency = trans end
    g.Parent = o
    return g
end

-- горизонтальный градиент (слева -> справа)
local function hgrad(o, left, right, trans)
    local g = Instance.new("UIGradient")
    g.Rotation = 0
    g.Color = colorSeq({ { 0, left }, { 1, right } })
    if trans then g.Transparency = trans end
    g.Parent = o
    return g
end

-- градиентная обводка: верх светлее, низ темнее (мягкий объём вместо плоской рамки)
local function strokeGrad(st, top, bottom, transSeq)
    if not st then return nil end
    local g = Instance.new("UIGradient")
    g.Rotation = 90
    g.Color = colorSeq({ { 0, top }, { 1, bottom } })
    if transSeq then g.Transparency = transSeq end
    g.Parent = st
    return g
end

-- тонкая световая линия по верхней кромке: "стеклянный" блик
local function rimLight(o, inset, transparency, thickness, radius)
    local r = new("Frame", {
        BackgroundColor3 = P.rim,
        BorderSizePixel = 0,
        BackgroundTransparency = transparency or 0.93,
        Size = UDim2.new(1, -2 * (inset or 1), 0, thickness or 1),
        Position = UDim2.fromOffset(inset or 1, 1),
        ZIndex = 0,
    }, o)
    corner(r, radius or 1)
    hgrad(r, Color3.new(1, 1, 1), Color3.new(1, 1, 1), numberSeq({
        { 0, 1 },
        { 0.12, math.clamp((transparency or 0.93) - 0.06, 0, 1) },
        { 0.5, math.clamp((transparency or 0.93) - 0.1, 0, 1) },
        { 0.88, math.clamp((transparency or 0.93) - 0.06, 0, 1) },
        { 1, 1 },
    }))
    return r
end

-- мягкая тень вокруг произвольного элемента: несколько слоёв, растущих наружу.
-- host — контейнер, в котором лежит тень; target — сам элемент.
local function softShadow(host, target, opts)
    opts = opts or {}
    local layers = opts.Layers or 4
    local spread = opts.Spread or 8
    local base = opts.Alpha or 0.55
    local yOff = opts.Y or 3
    local color = opts.Color or Color3.new(0, 0, 0)
    local radius = opts.Radius or 6
    local z = opts.ZIndex or 0
    local frames = {}

    for i = 1, layers do
        local f = new("Frame", {
            BackgroundColor3 = color,
            BackgroundTransparency = math.clamp(base + (i - 1) * (0.24 / math.max(1, layers - 1)), 0, 1),
            BorderSizePixel = 0,
            ZIndex = z,
            Visible = false,
        }, host)
        corner(f, radius + i)
        frames[i] = f
    end

    local function sync()
        local ok = pcall(function()
            local tx, ty = target.AbsolutePosition.X, target.AbsolutePosition.Y
            local tw, th = target.AbsoluteSize.X, target.AbsoluteSize.Y
            local hx, hy = host.AbsolutePosition.X, host.AbsolutePosition.Y
            local visible = target.Visible and tw > 0
            for i, f in ipairs(frames) do
                local grow = (spread / layers) * i
                f.Position = UDim2.fromOffset(tx - hx - grow, ty - hy - grow + yOff)
                f.Size = UDim2.fromOffset(tw + grow * 2, th + grow * 2)
                f.Visible = visible
            end
        end)
        return ok
    end

    sync()
    task.defer(sync)
    pcall(function()
        target:GetPropertyChangedSignal("AbsolutePosition"):Connect(sync)
        target:GetPropertyChangedSignal("AbsoluteSize"):Connect(sync)
        target:GetPropertyChangedSignal("Visible"):Connect(sync)
    end)
    return sync, frames
end

local function measureHeight(str, width, size)
    if not str or str == "" then return 12 end
    local ok, res = pcall(function()
        return TextService:GetTextSize(str, size or 12, Enum.Font.Gotham, Vector2.new(math.max(20, width), 10000))
    end)
    if ok and res then return math.ceil(res.Y) end
    return math.ceil((size or 12) * 1.5)
end

-- ======================================================================
-- library root
-- ======================================================================
local Lib = {}
Lib.__index = Lib
Lib.Unloaded = false
Lib.Options = {}
Lib.Version = "1.1.0"
Lib.Brand = "Primordial UI"
Lib.LoaderBrand = "Primordial Loader"
Lib.Lang = "ru"
Lib.Palette = P
Lib.__loader = nil

local langListeners = {}

function Lib:OnLangChanged(fn)
    if type(fn) ~= "function" then return end
    langListeners[#langListeners + 1] = fn
    return #langListeners
end

function Lib:SetLang(l)
    Lib.Lang = l or "ru"
    for _, fn in ipairs(langListeners) do
        pcall(fn, Lib.Lang)
    end
end

function Lib:Destroy()
    Lib.Unloaded = true
    if Lib.__window then
        pcall(function() Lib.__window:Destroy() end)
    end
    if Lib.GUI then
        pcall(function() Lib.GUI:Destroy() end)
        Lib.GUI = nil
    end
end

-- ======================================================================
-- window prototype
-- ======================================================================
local WindowProto = {}
WindowProto.__index = WindowProto
local TabProto = {}
TabProto.__index = TabProto

function Lib:CreateWindow(cfg)
    cfg = cfg or {}

    if Lib.__window then
        pcall(function() Lib.__window:Destroy() end)
    end
    if Lib.GUI then
        pcall(function() Lib.GUI:Destroy() end)
        Lib.GUI = nil
    end

    local W = setmetatable({
        Title = cfg.Title or "Menu",
        Subtitle = cfg.Subtitle or ("v" .. Lib.Version),
        Tabs = {},
        Active = nil,
        ToggleKey = cfg.ToggleKey or Enum.KeyCode.RightShift,
        Minimized = false,
    }, WindowProto)
    if cfg.Accent then P.accent = cfg.Accent end

    local gui = Instance.new("ScreenGui")
    gui.Name = "PrimordialUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 100
    local coreOk = pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not coreOk or not gui.Parent then
        gui.Parent = plr:WaitForChild("PlayerGui")
    end
    Lib.GUI = gui

    local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    local wantW = (cfg.Size and cfg.Size.X.Offset > 0) and cfg.Size.X.Offset or 760
    local wantH = (cfg.Size and cfg.Size.Y.Offset > 0) and cfg.Size.Y.Offset or 500
    local winW = math.min(wantW, math.floor(viewport.X * 0.95))
    local winH = math.min(wantH, math.floor(viewport.Y * 0.92))

    -- window ------------------------------------------------------------
    local root = new("Frame", {
        Name = "Window",
        BackgroundColor3 = P.bg,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(winW, winH),
        Position = UDim2.new(0.5, -winW / 2, 0.5, -winH / 2),
        Visible = cfg.Open ~= false,
        ZIndex = 2,
    }, gui)
    corner(root, 6)
    vgrad(root, P.bgTop, P.bgBottom)
    local rootStroke = stroke(root, P.stroke, 1, 0.1)
    strokeGrad(rootStroke,
        Color3.fromRGB(108, 108, 120),
        Color3.fromRGB(46, 46, 50),
        numberSeq({ { 0, 0.1 }, { 0.55, 0.35 }, { 1, 0.62 } }))
    -- окно лежит на игре без внешней тени: оригинальный primordial не даёт
    -- ореола вокруг GUI, а тёмный ореол на светлом фоне читается как грязь
    W.Frame = root
    -- верхний блик по кромке окна
    local rootRim = new("Frame", {
        BackgroundColor3 = P.rim,
        BackgroundTransparency = 0.92,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -2, 0, 1),
        Position = UDim2.fromOffset(1, 1),
        ZIndex = 3,
    }, root)
    corner(rootRim, 1)
    hgrad(rootRim, Color3.new(1, 1, 1), Color3.new(1, 1, 1), numberSeq({
        { 0, 1 }, { 0.1, 0.9 }, { 0.5, 0.84 }, { 0.9, 0.9 }, { 1, 1 },
    }))

    -- top bar -----------------------------------------------------------
    local top = new("Frame", {
        Name = "Top",
        BackgroundColor3 = P.chrome,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 42),
        ClipsDescendants = true,
    }, root)
    corner(top, 6)
    vgrad(top, P.chromeTop, P.chromeBottom)
    rimLight(top, 1, 0.94, 1, 3)
    -- акцентное свечение под логотипом: очень слабое, только чтобы верх "жил"
    local topGlow = new("Frame", {
        BackgroundColor3 = P.accent,
        BackgroundTransparency = 0.94,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(150, 42),
        Position = UDim2.fromOffset(-24, 0),
    }, top)
    hgrad(topGlow, P.accent, P.accent, numberSeq({
        { 0, 0.84 }, { 0.45, 0.94 }, { 1, 1 },
    }))

    local logoWrap = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(230, 42) }, top)
    local markHolder = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(16, 16),
        Position = UDim2.new(0, 16, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
    }, logoWrap)
    drawLogoMark(markHolder, 12, P.accent)
    local titleLbl = text(logoWrap, {
        Text = W.Title,
        TextSize = 19,
        Position = UDim2.fromOffset(42, 0),
        Size = UDim2.new(1, -48, 0, 42),
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, W_SEMI)
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(240, 240, 244)),
        ColorSequenceKeypoint.new(1, P.accent),
    })
    grad.Parent = titleLbl

    local topLine = new("Frame", {
        BackgroundColor3 = P.stroke,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
    }, top)
    hgrad(topLine, P.stroke, P.stroke, numberSeq({
        { 0, 0.35 }, { 0.2, 0 }, { 0.8, 0 }, { 1, 0.5 },
    }))

    local function topBtn(xOffset, color, onClick)
        local b = button(top, {
            Text = "",
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Center,
            Size = UDim2.fromOffset(28, 22),
            Position = UDim2.new(1, xOffset, 0, 10),
            BackgroundColor3 = P.element,
            BackgroundTransparency = 1,
        }, W_MED)
        corner(b, 3)
        b.MouseEnter:Connect(function() b.BackgroundTransparency = 0 end)
        b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
        b.MouseButton1Click:Connect(function() if onClick then pcall(onClick) end end)
        return b
    end

    -- иконки рисуем фреймами: JosefinSans не гарантирует наличие глифов ✕/–,
    -- из-за чего кнопка закрытия выглядела пустой
    local function drawCross(parent, size, color, thickness)
        local holder = new("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(size, size),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
        }, parent)
        for i = 1, 2 do
            local line = new("Frame", {
                BackgroundColor3 = color,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, thickness or 1.5),
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Rotation = (i == 1) and 45 or -45,
            }, holder)
            corner(line, 1)
        end
        return holder
    end

    local function drawMinus(parent, width, color, thickness)
        return new("Frame", {
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(width, thickness or 1.5),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
        }, parent)
    end

    local closeBtn = topBtn(-38, P.sub, function() root.Visible = false end)
    local closeIcon = drawCross(closeBtn, 9, P.sub, 1.5)
    local function tintIcon(holder, color)
        for _, line in ipairs(holder:GetChildren()) do
            if line:IsA("Frame") then line.BackgroundColor3 = color end
        end
    end
    closeBtn.MouseEnter:Connect(function() tintIcon(closeIcon, P.danger) end)
    closeBtn.MouseLeave:Connect(function() tintIcon(closeIcon, P.sub) end)

    local minBtn = topBtn(-72, P.sub, function()
        W.Minimized = not W.Minimized
        W.Body.Visible = not W.Minimized
        root.Size = W.Minimized and UDim2.fromOffset(root.AbsoluteSize.X, 42) or UDim2.fromOffset(winW, winH)
    end)
    local minIcon = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(9, 9),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
    }, minBtn)
    local minLine = drawMinus(minIcon, 9, P.sub, 1.5)
    minBtn.MouseEnter:Connect(function() minLine.BackgroundColor3 = P.text end)
    minBtn.MouseLeave:Connect(function() minLine.BackgroundColor3 = P.sub end)

    -- drag --------------------------------------------------------------
    local dragging, dragStart, startPos = false, nil, nil
    top.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, root.Position
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local d = input.Position - dragStart
            root.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)

    -- body --------------------------------------------------------------
    local body = new("Frame", {
        Name = "Body",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, -74),
        Position = UDim2.fromOffset(0, 42),
    }, root)
    W.Body = body

    local topShade = new("Frame", {
        BackgroundColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 10),
        ZIndex = 5,
    }, body)
    vgrad(topShade, Color3.new(0, 0, 0), Color3.new(0, 0, 0), numberSeq({
        { 0, 0.88 }, { 1, 1 },
    }))

    local sidebar = new("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = P.chrome,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 196, 1, 0),
        ClipsDescendants = true,
    }, body)
    vgrad(sidebar, P.sidebarTop, P.sidebarBottom)
    local sbPad = Instance.new("UIPadding")
    sbPad.PaddingTop = UDim.new(0, 8)
    sbPad.PaddingBottom = UDim.new(0, 8)
    sbPad.Parent = sidebar
    listLayout(sidebar, 2)

    -- разделитель сайдбара: от низа топбара и до самого низа окна.
    -- Градиент по вертикали, чтобы линия растворялась к краям окна.
    local sbLine = new("Frame", {
        BackgroundColor3 = P.stroke,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 1, 1, -42),
        Position = UDim2.new(0, 196, 0, 42),
        ZIndex = 10,
    }, root)
    vgrad(sbLine, P.stroke, P.stroke, numberSeq({
        { 0, 0.25 }, { 0.25, 0 }, { 0.75, 0 }, { 1, 0.4 },
    }))

    -- footer ------------------------------------------------------------
    local footer = new("Frame", {
        Name = "Footer",
        BackgroundColor3 = P.chrome,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 32),
        Position = UDim2.new(0, 0, 1, -32),
    }, root)
    vgrad(footer, P.chromeBottom, P.chromeTop)
    local footLine = new("Frame", {
        BackgroundColor3 = P.stroke,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
    }, footer)
    hgrad(footLine, P.stroke, P.stroke, numberSeq({
        { 0, 0.5 }, { 0.25, 0 }, { 0.75, 0 }, { 1, 0.5 },
    }))
    -- футер: текст слева, версия акцентом и чуть жирнее, с отдельным отступом
    local footerRow = new("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 0),
        Size = UDim2.new(1, -32, 1, 0),
    }, footer)
    local footLayout = listLayout(footerRow, 16, Enum.FillDirection.Horizontal)
    footLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    text(footerRow, {
        Text = cfg.Footer or (W.Title .. "   |   " .. W.Subtitle),
        TextColor3 = P.dim,
        TextSize = 12,
        Size = UDim2.new(0, 0, 0, 32),
        AutomaticSize = Enum.AutomaticSize.X,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    if cfg.Version and cfg.Version ~= "" then
        local accentHex = string.format("%02X%02X%02X",
            math.floor(P.accent.R * 255 + 0.5),
            math.floor(P.accent.G * 255 + 0.5),
            math.floor(P.accent.B * 255 + 0.5))
        local ver = text(footerRow, {
            Text = tostring(cfg.Version),
            TextColor3 = P.accent,
            TextSize = 12,
            Size = UDim2.new(0, 0, 0, 32),
            AutomaticSize = Enum.AutomaticSize.X,
        }, W_SEMI)
        ver.Name = "Version"
    end

    -- content -----------------------------------------------------------
    local content = new("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -197, 1, 0),
        Position = UDim2.fromOffset(197, 0),
    }, body)
    W.Content = content

    -- notifications ------------------------------------------------------
    local ngui = Instance.new("ScreenGui")
    ngui.Name = "PrimordialNotify"
    ngui.ResetOnSpawn = false
    -- false, а не true: в CoreGui при IgnoreGuiInset = true канвас уезжает
    -- вверх на высоту топбара, и уведомления уходят за край экрана
    ngui.IgnoreGuiInset = false
    ngui.DisplayOrder = 120
    local nOk = pcall(function() ngui.Parent = game:GetService("CoreGui") end)
    if not nOk or not ngui.Parent then ngui.Parent = plr:WaitForChild("PlayerGui") end

    local notifyHolder = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 268, 1, -24),
        Position = UDim2.new(1, -284, 0, 12),
    }, ngui)
    local nLayout = Instance.new("UIListLayout")
    nLayout.Padding = UDim.new(0, 8)
    nLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    nLayout.SortOrder = Enum.SortOrder.LayoutOrder
    nLayout.Parent = notifyHolder

    -- Notify: типы, акцентная полоска, прогресс-линия и закрытие по клику.
    -- Полоска/прогресс — дети card, а card несёт UIPadding ради AutomaticSize,
    -- поэтому их координаты компенсируют паддинг (иначе их сдвигает на текст).
    local NOTIFY_PAD_L, NOTIFY_PAD_R, NOTIFY_PAD_V = 16, 14, 9
    local NOTIFY_TYPES = {
        info = P.accent,
        success = Color3.fromRGB(126, 214, 155),
        warn = Color3.fromRGB(231, 190, 120),
        error = Color3.fromRGB(214, 94, 103),
    }

    local notifyOrder = 0
    function W:Notify(opts)
        opts = opts or {}
        notifyOrder = notifyOrder + 1
        local hold = math.max(0.6, tonumber(opts.Duration) or 4)
        local accent = opts.Accent
            or NOTIFY_TYPES[tostring(opts.Type or "info"):lower()]
            or P.accent
        local padX = NOTIFY_PAD_L + NOTIFY_PAD_R
        local closed = false

        local card = new("TextButton", {
            Text = "",
            AutoButtonColor = false,
            BackgroundColor3 = P.card,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            LayoutOrder = notifyOrder,
        }, notifyHolder)
        corner(card, 5)
        vgrad(card, P.cardTop, P.cardBottom)
        rimLight(card, 1, 0.95, 1, 3)
        local st = stroke(card, P.stroke, 1, 1)
        strokeGrad(st, Color3.fromRGB(112, 112, 124), Color3.fromRGB(46, 46, 50),
            numberSeq({ { 0, 1 }, { 1, 1 } }))
        -- отступы прямо на карточке: AutomaticSize учитывает UIPadding,
        -- поэтому высота всегда совпадает с текстом
        padAll(card, NOTIFY_PAD_L, NOTIFY_PAD_V, NOTIFY_PAD_R, NOTIFY_PAD_V)

        local inner = new("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
        }, card)
        listLayout(inner, 4)

        -- акцентная полоска: 5 px от левой кромки, высоту берём у inner,
        -- а не scale — иначе AutomaticSize зацикливается
        local bar = new("Frame", {
            BackgroundColor3 = accent,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 2, 0, 0),
            Position = UDim2.fromOffset(-NOTIFY_PAD_L + 5, 4),
            BackgroundTransparency = 1,
            ZIndex = 2,
        }, card)
        corner(bar, 1)
        vgrad(bar, accent:Lerp(Color3.new(1, 1, 1), 0.22), accent:Lerp(Color3.new(0, 0, 0), 0.15))
        local barGlow = new("Frame", {
            BackgroundColor3 = accent,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 7, 0, 0),
            Position = UDim2.fromOffset(-NOTIFY_PAD_L + 2, 2),
            BackgroundTransparency = 1,
            ZIndex = 1,
        }, card)
        corner(barGlow, 3)
        local function syncBar()
            local h = math.max(0, inner.AbsoluteSize.Y - 8)
            bar.Size = UDim2.new(0, 2, 0, h)
            barGlow.Size = UDim2.new(0, 7, 0, h + 4)
        end
        syncBar()
        inner:GetPropertyChangedSignal("AbsoluteSize"):Connect(syncBar)

        -- прогресс-линия внизу: сколько уведомление ещё проживёт
        local progHolder = new("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0.65,
            BorderSizePixel = 0,
            Size = UDim2.new(1, padX, 0, 2),
            Position = UDim2.new(0, -NOTIFY_PAD_L, 1, NOTIFY_PAD_V - 2),
            ClipsDescendants = true,
            ZIndex = 3,
        }, card)
        local prog = new("Frame", {
            BackgroundColor3 = accent,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 0.55,
            ZIndex = 4,
        }, progHolder)

        local t1 = text(inner, {
            Text = tostring(opts.Title or "Notification"),
            TextSize = 14,
            Size = UDim2.new(1, -6, 0, 18),
            TextTransparency = 1,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 2,
            LayoutOrder = 1,
        }, W_SEMI)
        local c1 = text(inner, {
            Text = tostring(opts.Content or ""),
            TextColor3 = P.sub,
            TextSize = 13,
            Size = UDim2.new(1, -6, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            TextWrapped = true,
            TextTransparency = 1,
            ZIndex = 2,
            LayoutOrder = 2,
        })

        local function dismiss(instant)
            if closed then return end
            closed = true
            local t = instant and 0.12 or 0.22
            tween(card, t, { BackgroundTransparency = 1 })
            tween(st, t, { Transparency = 1 })
            tween(bar, t, { BackgroundTransparency = 1 })
            tween(barGlow, t, { BackgroundTransparency = 1 })
            tween(progHolder, t, { BackgroundTransparency = 1 })
            tween(prog, t, { BackgroundTransparency = 1 })
            tween(t1, t, { TextTransparency = 1 })
            tween(c1, t, { TextTransparency = 1 })
            task.delay(t + 0.05, function() pcall(function() card:Destroy() end) end)
        end

        -- клик по уведомлению закрывает его сразу
        card.MouseEnter:Connect(function()
            if closed then return end
            tween(st, 0.12, { Transparency = 0.05 })
        end)
        card.MouseLeave:Connect(function()
            tween(st, 0.12, { Transparency = 0.25 })
        end)
        card.MouseButton1Click:Connect(function() dismiss(true) end)

        tween(card, 0.16, { BackgroundTransparency = 0 })
        tween(st, 0.16, { Transparency = 0.25 })
        tween(bar, 0.16, { BackgroundTransparency = 0 })
        tween(barGlow, 0.16, { BackgroundTransparency = 0.86 })
        tween(progHolder, 0.16, { BackgroundTransparency = 0.65 })
        tween(t1, 0.16, { TextTransparency = 0 })
        tween(c1, 0.16, { TextTransparency = 0 })
        TweenService:Create(prog, TweenInfo.new(hold, Enum.EasingStyle.Linear), {
            Size = UDim2.new(0, 0, 1, 0),
        }):Play()
        task.delay(hold, function() dismiss(false) end)
        return card
    end

    -- popup ---------------------------------------------------------------
    local openPopup = nil
    local openPopupAnchor = nil

    local function closePopup(instant)
        local pop = openPopup
        openPopup = nil
        openPopupAnchor = nil
        if not pop then return end
        if instant then
            pcall(function() pop:Destroy() end)
            return
        end
        -- задвигаем обратно: высота 0 + гаснущий текст
        pcall(function()
            pop.ClipsDescendants = true
            local w = pop.AbsoluteSize.X
            local st = pop:FindFirstChildOfClass("UIStroke")
            if st then tween(st, 0.12, { Transparency = 1 }) end
            for _, row in ipairs(pop:GetChildren()) do
                if row:IsA("TextButton") then tween(row, 0.1, { TextTransparency = 1 }) end
            end
            tween(pop, 0.13, { Size = UDim2.fromOffset(w, 0) })
        end)
        task.delay(0.16, function() pcall(function() pop:Destroy() end) end)
    end

    local function isPopupFor(anchor)
        return openPopup ~= nil and openPopupAnchor == anchor
    end

    local function showPopup(anchor, items, current, onPick)
        closePopup(true)
        local popW = math.max(anchor.AbsoluteSize.X, 130)
        local popH = #items * 26 + math.max(0, #items - 1) + 8
        local pop = new("Frame", {
            BackgroundColor3 = P.card,
            BackgroundTransparency = 0.03,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(popW, 0),
            Position = UDim2.fromOffset(
                anchor.AbsolutePosition.X - root.AbsolutePosition.X,
                anchor.AbsolutePosition.Y - root.AbsolutePosition.Y + anchor.AbsoluteSize.Y + 4
            ),
            ZIndex = 40,
            ClipsDescendants = true,
        }, root)
        corner(pop, 4)
        vgrad(pop, Color3.fromRGB(58, 58, 64), Color3.fromRGB(48, 48, 52))
        local popStroke = stroke(pop, P.stroke, 1, 0.05)
        strokeGrad(popStroke,
            Color3.fromRGB(120, 120, 134),
            Color3.fromRGB(48, 48, 52),
            numberSeq({ { 0, 0.05 }, { 0.6, 0.35 }, { 1, 0.62 } }))
        rimLight(pop, 1, 0.93, 1, 3)
        padAll(pop, 4, 4, 4, 4)
        listLayout(pop, 1)
        openPopup = pop
        openPopupAnchor = anchor

        for i, item in ipairs(items) do
            local isCur = (item == current)
            local row = button(pop, {
                Text = tostring(item),
                TextSize = 13,
                Size = UDim2.new(1, 0, 0, 26),
                BackgroundColor3 = (isCur and P.element or P.card),
                BackgroundTransparency = (isCur and 0 or 1),
                TextColor3 = (isCur and P.text or P.sub),
                LayoutOrder = i,
                ZIndex = 41,
            })
            corner(row, 3)
            -- акцентная полоска выбранного пункта. Живёт внутри кнопки, поэтому
            -- её сдвигает тот же UIPadding, что и текст: компенсируем отступ,
            -- иначе полоска наезжает на первую букву.
            local rowPad = 14
            padAll(row, rowPad, 0, 8, 0)
            if isCur then
                local curBar = new("Frame", {
                    BackgroundColor3 = P.accent,
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 2, 1, -12),
                    Position = UDim2.fromOffset(rowPad * -1 + 5, 6),
                    ZIndex = 42,
                }, row)
                corner(curBar, 1)
                vgrad(curBar, P.accentTop, P.accentBottom)
            end
            row.MouseEnter:Connect(function()
                row.BackgroundTransparency = 0
                row.BackgroundColor3 = P.elementHover
                row.TextColor3 = P.text
            end)
            row.MouseLeave:Connect(function()
                row.BackgroundColor3 = (isCur and P.element or P.card)
                row.BackgroundTransparency = (isCur and 0 or 1)
                row.TextColor3 = (isCur and P.text or P.sub)
            end)
            row.MouseButton1Click:Connect(function()
                closePopup()
                onPick(item)
            end)
        end

        -- выдвигаем: высота 0 -> полная высота
        tween(pop, 0.15, { Size = UDim2.fromOffset(popW, popH) })
    end
    W.ClosePopup = closePopup

    -- ==================================================================
    -- shared element pieces
    -- ==================================================================
    local function makeCard(parent, titleStr, asButton)
        local class = asButton and "TextButton" or "Frame"
        local props = {
            BackgroundColor3 = P.card,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
        }
        if asButton then
            props.Text = ""
            props.AutoButtonColor = false
        end
        local card = new(class, props, parent)
        corner(card, 4)
        vgrad(card, P.cardTop, P.cardBottom)
        local cardStroke = stroke(card, P.stroke, 1, 0.3)
        strokeGrad(cardStroke,
            Color3.fromRGB(100, 100, 112),
            Color3.fromRGB(46, 46, 50),
            numberSeq({ { 0, 0.35 }, { 0.5, 0.55 }, { 1, 0.7 } }))
        rimLight(card, 1, 0.955, 1, 3)
        listLayout(card, 0)

        local head = new("Frame", {
            BackgroundColor3 = P.cardHead,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 30),
            Visible = titleStr ~= nil and titleStr ~= "",
        }, card)
        corner(head, 4)
        vgrad(head, P.headTop, P.headBottom)
        rimLight(head, 1, 0.94, 1, 3)
        -- тень под шапкой: шапка "приподнята" над телом карточки
        local headShade = new("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0.55,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 1, 0),
        }, head)
        hgrad(headShade, Color3.new(0, 0, 0), Color3.new(0, 0, 0), numberSeq({
            { 0, 0.35 }, { 0.5, 0.55 }, { 1, 0.35 },
        }))
        padAll(head, 10, 0, 8, 0)
        local headLabel = text(head, {
            Text = titleStr or "",
            TextSize = 15,
            Size = UDim2.new(1, 0, 1, 0),
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, W_SEMI)

        local bodyBox = new("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
        }, card)
        padAll(bodyBox, 10, 8, 10, 8)
        listLayout(bodyBox, 6)

        return card, head, headLabel, bodyBox
    end

    local function setCardHover(card, on)
        tween(card, 0.1, { BackgroundColor3 = on and P.cardHover or P.card })
        local st = card:FindFirstChildOfClass("UIStroke")
        if st then tween(st, 0.12, { Transparency = on and 0.2 or 0.45 }) end
    end

    -- row = description on the left, control on the right
    local function makeRow(bodyBox, desc, controlWidth, cardWidthHint)
        local row = new("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
        }, bodyBox)

        local descLabel
        if desc and desc ~= "" then
            descLabel = text(row, {
                Text = desc,
                TextColor3 = P.sub,
                TextSize = 15,
                TextWrapped = true,
                TextYAlignment = Enum.TextYAlignment.Top,
                Size = UDim2.new(1, -(controlWidth + 10), 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
            })
        else
            row.Size = UDim2.new(1, 0, 0, 24)
            row.AutomaticSize = Enum.AutomaticSize.None
        end

        local holder = new("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(controlWidth, 24),
            Position = UDim2.new(1, 0, 0, 0),
            AnchorPoint = Vector2.new(1, 0),
        }, row)
        return row, holder, descLabel
    end

    local function makeCheckbox(parent, isOn, onChange)
        -- тень под чекбоксом + мягкое свечение, когда он включён
        local halo = new("Frame", {
            BackgroundColor3 = P.accent,
            BackgroundTransparency = isOn and 0.86 or 1,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(27, 27),
            Position = UDim2.fromOffset(-5, -2),
            ZIndex = 0,
        }, parent)
        corner(halo, 7)
        local drop = new("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0.62,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(17, 17),
            Position = UDim2.fromOffset(0, 4),
            ZIndex = 0,
        }, parent)
        corner(drop, 3)

        local box = new("Frame", {
            BackgroundColor3 = isOn and P.accent or P.element,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(17, 17),
            Position = UDim2.fromOffset(0, 3),
            ZIndex = 2,
        }, parent)
        corner(box, 3)
        local boxGrad = vgrad(box, P.accentTop, P.accentBottom)
        boxGrad.Enabled = isOn == true
        local innerTop = new("Frame", {
            BackgroundColor3 = P.rim,
            BackgroundTransparency = 0.75,
            BorderSizePixel = 0,
            Size = UDim2.new(1, -2, 0, 1),
            Position = UDim2.fromOffset(1, 1),
            ZIndex = 3,
        }, box)
        hgrad(innerTop, P.rim, P.rim, numberSeq({ { 0, 1 }, { 0.5, 0.75 }, { 1, 1 } }))
        local boxStroke = stroke(box, isOn and P.accent or P.stroke, 1, 0)
        local check = text(box, {
            Text = "\u{2713}",
            TextSize = 14,
            TextColor3 = P.checkMark,
            TextXAlignment = Enum.TextXAlignment.Center,
            Size = UDim2.fromScale(1, 1),
            TextTransparency = isOn and 0 or 1,
            ZIndex = 4,
        }, W_BOLD)
        local hit = button(parent, {
            Size = UDim2.fromOffset(17, 17),
            Position = UDim2.fromOffset(0, 3),
            BackgroundTransparency = 1,
            ZIndex = 5,
        })
        local state = isOn == true
        local api = {}
        function api:SetValue(v)
            state = v and true or false
            tween(box, 0.14, { BackgroundColor3 = state and P.accent or P.element })
            boxGrad.Enabled = state
            tween(innerTop, 0.14, { BackgroundTransparency = state and 0.75 or 0.94 })
            tween(check, 0.14, { TextTransparency = state and 0 or 1 })
            tween(halo, 0.2, { BackgroundTransparency = state and 0.86 or 1 })
            tween(drop, 0.14, { BackgroundTransparency = state and 0.5 or 0.62 })
            local st = boxStroke
            if st then tween(st, 0.14, { Color = state and P.accent or P.stroke }) end
        end
        function api:GetValue()
            return state
        end
        hit.MouseButton1Click:Connect(function()
            api:SetValue(not state)
            if onChange then task.spawn(onChange, state) end
        end)
        box.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                api:SetValue(not state)
                if onChange then task.spawn(onChange, state) end
            end
        end)
        return api
    end

    local function makeSlider(parent, min, max, value, onChange)
        local holder = new("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 22),
        }, parent)
        local track = new("Frame", {
            BackgroundColor3 = P.track,
            BorderSizePixel = 0,
            Size = UDim2.new(1, -12, 0, 4),
            Position = UDim2.new(0, 6, 0.5, -2),
        }, holder)
        corner(track, 2)
        vgrad(track, Color3.fromRGB(52, 52, 57), Color3.fromRGB(78, 78, 86))
        local fill = new("Frame", {
            BackgroundColor3 = P.accent,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 0, 1, 0),
            ZIndex = 2,
        }, track)
        corner(fill, 2)
        hgrad(fill, P.accentTop, P.accentBottom)
        local fillShine = new("Frame", {
            BackgroundColor3 = P.rim,
            BackgroundTransparency = 0.8,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.fromOffset(0, 1),
            ZIndex = 3,
        }, fill)
        local halo = new("Frame", {
            BackgroundColor3 = P.accent,
            BackgroundTransparency = 0.84,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(20, 20),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0, 0.5),
            ZIndex = 1,
        }, track)
        corner(halo, 10)
        local knob = new("Frame", {
            BackgroundColor3 = P.knob,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(10, 10),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0, 0.5),
            ZIndex = 4,
        }, track)
        corner(knob, 5)
        vgrad(knob, Color3.fromRGB(255, 255, 255), Color3.fromRGB(205, 205, 214))
        stroke(knob, Color3.fromRGB(120, 120, 132), 1, 0.55)

        local function redraw()
            local n = math.clamp((value - min) / math.max(1e-6, max - min), 0, 1)
            fill.Size = UDim2.new(n, 0, 1, 0)
            fillShine.Visible = n > 0.02
            knob.Position = UDim2.fromScale(n, 0.5)
            halo.Position = UDim2.fromScale(n, 0.5)
            halo.BackgroundTransparency = 0.84
        end
        redraw()

        local dragging = false
        local hit = button(holder, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })
        local function apply(input)
            local rel = math.clamp((input.Position.X - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
            value = min + rel * (max - min)
            redraw()
            if onChange then task.spawn(onChange, value) end
        end
        hit.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                apply(input)
            end
        end)
        UIS.InputChanged:Connect(function(input)
            if not dragging then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                apply(input)
            end
        end)
        UIS.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        local api = {}
        function api:SetValue(v)
            value = math.clamp(v, min, max)
            redraw()
        end
        function api:GetValue() return value end
        return api
    end

    -- ==================================================================
    -- tab
    -- ==================================================================
    local function setTabActive(tab)
        for _, other in ipairs(W.Tabs) do
            local active = (other == tab)
            other.Page.Visible = active
            tween(other.BtnBg, 0.12, { BackgroundTransparency = active and 0 or 1 })
            tween(other.Bar, 0.12, { BackgroundTransparency = active and 0 or 1 })
            if other.BtnStroke then
                tween(other.BtnStroke, 0.12, { Transparency = active and 0.35 or 1 })
            end
            if other.BarGlow then
                tween(other.BarGlow, 0.16, { BackgroundTransparency = active and 0.82 or 1 })
            end
            if other.ActiveTint then
                tween(other.ActiveTint, 0.16, { BackgroundTransparency = active and 0.9 or 1 })
            end
            other.NameLabel.TextColor3 = active and P.text or P.sub
            other.DescLabel.TextColor3 = active and P.sub or P.dim
            applyFont(other.NameLabel, active and W_MED or W_REG)
        end
        W.Active = tab
    end

    function WindowProto:Tab(opts)
        opts = opts or {}
        local tab = setmetatable({
            Title = opts.Title or "Tab",
            Description = opts.Subtitle or opts.Description or "",
            Sections = {},
            W = W,
        }, TabProto)

        -- sidebar entry
        local btnBg = new("Frame", {
            BackgroundColor3 = P.element,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 48),
            LayoutOrder = #W.Tabs + 1,
        }, sidebar)
        corner(btnBg, 3)
        vgrad(btnBg, P.elemTop, P.elemBottom)
        local btnStroke = stroke(btnBg, P.stroke, 1, 1)
        local activeTint = new("Frame", {
            BackgroundColor3 = P.accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 0,
        }, btnBg)
        corner(activeTint, 3)
        hgrad(activeTint, P.accent, P.accent, numberSeq({
            { 0, 0.8 }, { 0.55, 0.92 }, { 1, 1 },
        }))

        local barGlow = new("Frame", {
            BackgroundColor3 = P.accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 7, 0, 30),
            Position = UDim2.new(0, 2, 0.5, -15),
            ZIndex = 1,
        }, btnBg)
        corner(barGlow, 4)

        local bar = new("Frame", {
            BackgroundColor3 = P.accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 2, 0, 26),
            Position = UDim2.new(0, 4, 0.5, -13),
            ZIndex = 2,
        }, btnBg)
        corner(bar, 2)
        vgrad(bar, P.accentTop, P.accentBottom)

        local nameLabel = text(btnBg, {
            Text = tab.Title,
            TextSize = 15,
            TextColor3 = P.sub,
            Position = UDim2.fromOffset(16, 5),
            Size = UDim2.new(1, -24, 0, 20),
            TextTruncate = Enum.TextTruncate.AtEnd,
        })
        local descLabel = text(btnBg, {
            Text = tab.Description,
            TextSize = 12,
            TextColor3 = P.dim,
            Position = UDim2.fromOffset(16, 24),
            Size = UDim2.new(1, -24, 0, 20),
            TextTruncate = Enum.TextTruncate.AtEnd,
            Visible = tab.Description ~= "",
        })
        local hit = button(btnBg, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })
        hit.MouseButton1Click:Connect(function() setTabActive(tab) end)
        btnBg.MouseEnter:Connect(function()
            if W.Active ~= tab then tween(btnBg, 0.1, { BackgroundTransparency = 0.45 }) end
        end)
        btnBg.MouseLeave:Connect(function()
            if W.Active ~= tab then tween(btnBg, 0.1, { BackgroundTransparency = 1 }) end
        end)

        tab.BtnBg, tab.Bar, tab.NameLabel, tab.DescLabel = btnBg, bar, nameLabel, descLabel
        tab.BtnStroke, tab.ActiveTint, tab.BarGlow = btnStroke, activeTint, barGlow
        tab.btn = setmetatable({ Text = tab.Title }, {
            __index = function(_, k)
                if k == "Text" then return nameLabel.Text end
                return tab[k]
            end,
            __newindex = function(_, k, v)
                if k == "Text" then
                    nameLabel.Text = tostring(v)
                    tab.Title = tostring(v)
                else
                    tab[k] = v
                end
            end,
        })

        -- page
        local page = new("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Visible = false,
        }, content)
        tab.Page = page

        local strip = new("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 34),
        }, page)
        local stripLayout = listLayout(strip, 0, Enum.FillDirection.Horizontal)
        stripLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        local stripPad = Instance.new("UIPadding")
        stripPad.PaddingLeft = UDim.new(0, 6)
        stripPad.PaddingRight = UDim.new(0, 14)
        stripPad.Parent = strip
        -- линия-разделитель живёт в page, а не в strip: иначе она участвует
        -- в горизонтальном UIListLayout и выдавливает чипсы за экран
        local stripLine = new("Frame", {
            BackgroundColor3 = P.stroke,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 0, 33),
            ZIndex = 2,
        }, page)
        hgrad(stripLine, P.stroke, P.stroke, numberSeq({
            { 0, 0.35 }, { 0.12, 0 }, { 0.9, 0 }, { 1, 0.25 },
        }))

        local scroll = new("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, -34),
            Position = UDim2.fromOffset(0, 34),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Color3.fromRGB(96, 96, 104),
            ScrollBarImageTransparency = 0.35,
            ScrollingDirection = Enum.ScrollingDirection.Y,
        }, page)
        new("UIListLayout", {
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, scroll)
        padAll(scroll, 14, 10, 10, 14)

        tab.Stack = new("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
        }, scroll)
        listLayout(tab.Stack, 10)
        tab.Scroll = scroll
        tab.Strip = strip

        -- default chip (tab name) until a real Section arrives
        local defaultChip = text(strip, {
            Text = tab.Title,
            TextSize = 14,
            TextColor3 = P.sub,
            Size = UDim2.new(0, 0, 1, -1),
            AutomaticSize = Enum.AutomaticSize.X,
            TextXAlignment = Enum.TextXAlignment.Center,
        }, W_MED)
        padAll(defaultChip, 14, 0, 14, 0)
        tab.DefaultChip = defaultChip

        function tab:_addChip(sectionEntry)
            if defaultChip then
                defaultChip:Destroy()
                defaultChip = nil
                tab.DefaultChip = nil
            end
            local chip = button(strip, {
                Text = sectionEntry.Title,
                TextSize = 14,
                TextColor3 = P.sub,
                BackgroundColor3 = P.element,
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 0, 1, -1),
                AutomaticSize = Enum.AutomaticSize.X,
                TextXAlignment = Enum.TextXAlignment.Center,
                LayoutOrder = #tab.Sections * 2,
                ZIndex = 2,
            }, W_MED)
            padAll(chip, 16, 0, 16, 0)
            corner(chip, 3)
            local chipGlow = new("Frame", {
                BackgroundColor3 = P.accent,
                BorderSizePixel = 0,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -14, 0, 7),
                Position = UDim2.new(0, 7, 1, -5),
                ZIndex = 1,
            }, chip)
            corner(chipGlow, 3)
            hgrad(chipGlow, P.accent, P.accent, numberSeq({
                { 0, 1 }, { 0.5, 0.86 }, { 1, 1 },
            }))
            local chipLine = new("Frame", {
                BackgroundColor3 = P.accent,
                BorderSizePixel = 0,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -18, 0, 2),
                Position = UDim2.new(0, 9, 1, -3),
                ZIndex = 3,
            }, chip)
            corner(chipLine, 1)
            hgrad(chipLine, P.accentTop, P.accentBottom)

            -- тонкий разделитель между чипсами, как в оригинальном primordial
            if #tab.Sections > 1 then
                local sep = new("Frame", {
                    BackgroundColor3 = P.stroke,
                    BorderSizePixel = 0,
                    BackgroundTransparency = 0.45,
                    Size = UDim2.new(0, 1, 0, 16),
                    LayoutOrder = #tab.Sections * 2 - 1,
                }, strip)
                vgrad(sep, P.stroke, P.stroke, numberSeq({
                    { 0, 1 }, { 0.25, 0.3 }, { 0.75, 0.3 }, { 1, 1 },
                }))
            end

            chip.MouseEnter:Connect(function()
                chip.TextColor3 = P.text
                tween(chip, 0.12, { BackgroundTransparency = 0.9 })
            end)
            chip.MouseLeave:Connect(function()
                chip.TextColor3 = (tab.SelectedSection == sectionEntry) and P.text or P.sub
                tween(chip, 0.12, { BackgroundTransparency = 1 })
            end)
            chip.MouseButton1Click:Connect(function()
                tab:_selectSection(sectionEntry)
            end)
            sectionEntry.Chip = chip
            sectionEntry.ChipLine = chipLine
            sectionEntry.ChipGlow = chipGlow
            if tab.SelectedSection == sectionEntry then
                chip.TextColor3 = P.text
                chipLine.BackgroundTransparency = 0
                chipGlow.BackgroundTransparency = 0.85
            end
        end

        -- переключение секций: показываем только выбранную, остальные прячем
        function tab:_selectSection(sectionEntry)
            for _, s in ipairs(tab.Sections) do
                local active = (s == sectionEntry)
                if s.Container then s.Container.Visible = active end
                if s.Chip then s.Chip.TextColor3 = active and P.text or P.sub end
                if s.ChipLine then s.ChipLine.BackgroundTransparency = active and 0 or 1 end
                if s.ChipGlow then s.ChipGlow.BackgroundTransparency = active and 0.85 or 1 end
            end
            tab.SelectedSection = sectionEntry
            pcall(function()
                tween(scroll, 0.18, { CanvasPosition = Vector2.new(0, 0) })
            end)
        end

        W.Tabs[#W.Tabs + 1] = tab
        if not W.Active then
            setTabActive(tab)
        else
            page.Visible = false
        end
        return tab
    end

    -- ==================================================================
    -- tab elements
    -- ==================================================================
    -- элементы кладём в контейнер текущей секции, а не в общий стек:
    -- так каждая секция живёт на своём месте и не висит под предыдущей
    local function sectionParent(tab)
        local sec = tab.CurrentSection
        if sec and sec.Container then return sec.Container end
        return tab.Stack
    end

    function TabProto:Section(opts)
        opts = opts or {}
        local entry = {
            Title = opts.Title or "Section",
            Container = new("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Visible = false,
            }, self.Stack),
        }
        listLayout(entry.Container, 10)
        self.Sections[#self.Sections + 1] = entry
        self.CurrentSection = entry
        if #self.Sections == 1 then
            entry.Container.Visible = true
            self.SelectedSection = entry
        end
        self:_addChip(entry)
        local api = {}
        function api:SetTitle(v)
            entry.Title = v
            if entry.Chip then entry.Chip.Text = v end
        end
        return api
    end

    function TabProto:Paragraph(opts)
        opts = opts or {}
        local card, _, headLabel, bodyBox = makeCard(sectionParent(self), opts.Title or "")
        local lbl = text(bodyBox, {
            Text = opts.Content or "",
            TextColor3 = P.sub,
            TextSize = 15,
            TextWrapped = true,
            TextYAlignment = Enum.TextYAlignment.Top,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
        })
        local api = { Frame = card }
        function api:SetTitle(v) headLabel.Text = v or "" end
        function api:SetContent(v) lbl.Text = v or "" end
        function api:SetDesc(v) lbl.Text = v or "" end
        return api
    end

    function TabProto:Toggle(opts)
        opts = opts or {}
        local api = {}
        local card, _, headLabel, bodyBox = makeCard(sectionParent(self), opts.Title or "")
        local _, holder, descLabel = makeRow(bodyBox, opts.Description, 17, 200)
        local cb = makeCheckbox(holder, opts.Default == true, opts.Callback)
        api.Frame = card
        api.SetValue = function(_, v) cb:SetValue(v) end
        api.GetValue = function() return cb:GetValue() end
        function api:SetTitle(v) headLabel.Text = v or "" end
        function api:SetDesc(v) if descLabel then descLabel.Text = v or "" end end
        -- allow obj.SetValue(x) (dot call) as well as obj:SetValue(x)
        local rawSetValue = api.SetValue
        api.SetValue = function(a, b)
            if b == nil then return rawSetValue(nil, a) end
            return rawSetValue(nil, b)
        end
        return api
    end

    function TabProto:Slider(opts)
        opts = opts or {}
        local min = opts.Min or 0
        local max = opts.Max or 100
        local value = opts.Value or min
        local api = {}
        local card, _, headLabel, bodyBox = makeCard(sectionParent(self), opts.Title or "")

        local topRow = new("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 16),
        }, bodyBox)
        local valueLbl = text(topRow, {
            Text = tostring(value),
            TextSize = 13,
            TextColor3 = P.sub,
            TextXAlignment = Enum.TextXAlignment.Right,
            Size = UDim2.fromScale(1, 1),
        })
        local slider = makeSlider(bodyBox, min, max, value, function(v)
            api.Value = v
            valueLbl.Text = string.format(opts.Format or "%.2f", v)
            if opts.Callback then task.spawn(opts.Callback, v) end
        end)
        api.Value = value
        api.Frame = card
        function api:SetTitle(v) headLabel.Text = v or "" end
        function api:SetValue(v)
            slider:SetValue(v)
            api.Value = v
            valueLbl.Text = string.format(opts.Format or "%.2f", v)
        end
        function api:GetValue() return slider:GetValue() end
        return api
    end

    function TabProto:Dropdown(opts)
        opts = opts or {}
        local values = opts.Values or {}
        local api = { Value = opts.Value or values[1] }
        local card, _, headLabel, bodyBox = makeCard(sectionParent(self), opts.Title or "")
        local _, holder, descLabel = makeRow(bodyBox, opts.Description, 150, 200)

        local box = button(holder, {
            BackgroundColor3 = P.element,
            Size = UDim2.fromOffset(150, 24),
            ZIndex = 2,
        })
        corner(box, 3)
        vgrad(box, P.elemTop, P.elemBottom)
        local boxStroke = stroke(box, P.stroke, 1, 0.4)
        local boxShadow = new("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0.7,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(150, 24),
            Position = UDim2.fromOffset(0, 1),
            ZIndex = 0,
        }, holder)
        corner(boxShadow, 3)
        padAll(box, 9, 0, 22, 0)
        local valueLbl = text(box, {
            Text = tostring(api.Value),
            TextSize = 14,
            Size = UDim2.new(1, 0, 1, 0),
            TextTruncate = Enum.TextTruncate.AtEnd,
        })
        local chev = text(box, {
            Text = "v",
            TextSize = 11,
            TextColor3 = P.sub,
            TextXAlignment = Enum.TextXAlignment.Right,
            Size = UDim2.new(1, -9, 1, -1),
        }, W_SEMI)
        box.MouseEnter:Connect(function()
            tween(box, 0.1, { BackgroundColor3 = P.elementHover })
            tween(boxStroke, 0.1, { Color = P.dim, Transparency = 0.15 })
            chev.TextColor3 = P.text
        end)
        box.MouseLeave:Connect(function()
            tween(box, 0.1, { BackgroundColor3 = P.element })
            tween(boxStroke, 0.1, { Color = P.stroke, Transparency = 0.4 })
            chev.TextColor3 = P.sub
        end)
        box.MouseButton1Click:Connect(function()
            if isPopupFor(box) then
                closePopup()
                return
            end
            showPopup(box, values, api.Value, function(picked)
                api.Value = picked
                valueLbl.Text = tostring(picked)
                if opts.Callback then task.spawn(opts.Callback, picked) end
            end)
        end)

        api.Frame = card
        function api:SetTitle(v) headLabel.Text = v or "" end
        function api:SetDesc(v) if descLabel then descLabel.Text = v or "" end end
        function api:SetValue(v)
            api.Value = v
            valueLbl.Text = tostring(v)
        end
        function api:GetValue() return api.Value end
        return api
    end

    function TabProto:Keybind(opts)
        opts = opts or {}
        local keys = {}
        local function keyName()
            local parts = {}
            for _, k in ipairs(keys) do parts[#parts + 1] = k.Name end
            return #parts > 0 and table.concat(parts, " + ") or "None"
        end

        local api = {}
        local card, _, headLabel, bodyBox = makeCard(sectionParent(self), opts.Title or "")
        local _, holder, descLabel = makeRow(bodyBox, opts.Description, 104, 200)

        local box = button(holder, { BackgroundColor3 = P.element, Size = UDim2.fromOffset(104, 24), ZIndex = 2 })
        corner(box, 3)
        vgrad(box, P.elemTop, P.elemBottom)
        local kbStroke = stroke(box, P.stroke, 1, 0.4)
        local kbShadow = new("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0.7,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(104, 24),
            Position = UDim2.fromOffset(0, 1),
            ZIndex = 0,
        }, holder)
        corner(kbShadow, 3)
        local boxLabel = text(box, {
            Text = keyName(),
            TextSize = 14,
            TextColor3 = P.sub,
            TextXAlignment = Enum.TextXAlignment.Center,
            Size = UDim2.fromScale(1, 1),
        })
        box.MouseEnter:Connect(function()
            tween(box, 0.1, { BackgroundColor3 = P.elementHover })
            tween(kbStroke, 0.1, { Transparency = 0.15, Color = P.dim })
        end)
        box.MouseLeave:Connect(function()
            tween(box, 0.1, { BackgroundColor3 = P.element })
            tween(kbStroke, 0.1, { Transparency = 0.4, Color = P.stroke })
        end)

        local listening = false
        local conn
        local function stopListening()
            listening = false
            if conn then conn:Disconnect() conn = nil end
            boxLabel.TextColor3 = P.sub
        end

        box.MouseButton1Click:Connect(function()
            if listening then
                stopListening()
                boxLabel.Text = keyName()
                return
            end
            listening = true
            boxLabel.Text = "Press a key..."
            boxLabel.TextColor3 = P.accent
            if conn then conn:Disconnect() end
            conn = UIS.InputBegan:Connect(function(input, processed)
                if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
                if processed then return end
                stopListening()
                local k = input.KeyCode
                if k == Enum.KeyCode.Escape then
                    boxLabel.Text = keyName()
                    return
                end
                if opts.Mode == "Hold" then
                    keys = { k }
                else
                    local found = false
                    for i, existing in ipairs(keys) do
                        if existing == k then
                            table.remove(keys, i)
                            found = true
                            break
                        end
                    end
                    if not found then keys[#keys + 1] = k end
                    if #keys > 3 then table.remove(keys, 1) end
                end
                boxLabel.Text = keyName()
                if opts.Callback then task.spawn(opts.Callback, keys) end
            end)
        end)

        if opts.Default then
            for part in string.gmatch(tostring(opts.Default), "[^%s+]+") do
                local ok, kc = pcall(function() return Enum.KeyCode[part] end)
                if ok and kc then keys[#keys + 1] = kc end
            end
            boxLabel.Text = keyName()
        end

        api.Frame = card
        api.Keys = keys
        function api:SetTitle(v) headLabel.Text = v or "" end
        function api:SetDesc(v) if descLabel then descLabel.Text = v or "" end end
        function api:SetValue(v)
            keys = {}
            for part in string.gmatch(tostring(v), "[^%s+]+") do
                local ok, kc = pcall(function() return Enum.KeyCode[part] end)
                if ok and kc then keys[#keys + 1] = kc end
            end
            boxLabel.Text = keyName()
        end
        function api:GetValue() return keys end
        return api
    end

    function TabProto:Button(opts)
        opts = opts or {}
        local card, _, _, bodyBox = makeCard(sectionParent(self), nil, true)

        local row = new("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
        }, bodyBox)
        local titleLabel = text(row, {
            Text = opts.Title or "Button",
            TextSize = 14,
            Size = UDim2.new(1, -18, 0, 20),
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, W_MED)
        local arrowLbl = text(row, {
            Text = "\u{203A}",
            TextSize = 16,
            TextColor3 = P.sub,
            TextXAlignment = Enum.TextXAlignment.Right,
            Size = UDim2.new(1, 0, 0, 20),
        }, W_BOLD)
        local descLabel
        if opts.Description and opts.Description ~= "" then
            descLabel = text(bodyBox, {
                Text = opts.Description,
                TextColor3 = P.sub,
                TextSize = 15,
                TextWrapped = true,
                TextYAlignment = Enum.TextYAlignment.Top,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
            })
        end

        card.MouseEnter:Connect(function()
            setCardHover(card, true)
            arrowLbl.TextColor3 = P.accent
        end)
        card.MouseLeave:Connect(function()
            setCardHover(card, false)
            arrowLbl.TextColor3 = P.sub
        end)
        card.MouseButton1Click:Connect(function()
            if opts.Callback then task.spawn(opts.Callback) end
        end)

        local api = { Frame = card }
        return setmetatable(api, {
            __index = function(_, k)
                if k == "Text" then return titleLabel.Text end
                return nil
            end,
            __newindex = function(_, k, v)
                if k == "Text" then
                    titleLabel.Text = tostring(v)
                elseif k == "Desc" then
                    if descLabel then descLabel.Text = tostring(v) end
                else
                    rawset(api, k, v)
                end
            end,
        })
    end

    -- ==================================================================
    function WindowProto:SelectTab(indexOrTab)
        local tab = indexOrTab
        if type(indexOrTab) == "number" then tab = W.Tabs[indexOrTab] end
        if tab then setTabActive(tab) end
    end

    function WindowProto:SetToggleKey(key)
        W.ToggleKey = key
    end

    function WindowProto:Toggle()
        root.Visible = not root.Visible
    end

    function WindowProto:Show() root.Visible = true end
    function WindowProto:Hide() root.Visible = false end
    function WindowProto:IsOpen() return root.Visible end

    function WindowProto:Destroy()
        closePopup()
        pcall(function() gui:Destroy() end)
        pcall(function() ngui:Destroy() end)
        if Lib.GUI == gui then Lib.GUI = nil end
        if Lib.__window == W then Lib.__window = nil end
    end

    -- global key / popup dismissal --------------------------------------
    UIS.InputBegan:Connect(function(input, processed)
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if processed then return end
        if W.ToggleKey and input.KeyCode == W.ToggleKey then
            root.Visible = not root.Visible
        elseif input.KeyCode == Enum.KeyCode.Escape and root.Visible then
            closePopup()
        end
    end)

    UIS.InputBegan:Connect(function(input)
        if not openPopup then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local pos = input.Position
            local ap = openPopup.AbsolutePosition
            local sz = openPopup.AbsoluteSize
            if pos.X < ap.X or pos.X > ap.X + sz.X or pos.Y < ap.Y or pos.Y > ap.Y + sz.Y then
                closePopup()
            end
        end
    end)

    Lib.__window = W
    return W
end

-- ======================================================================
-- loader mode: отдельный сплэш для main.luau и любого лоадстринга
-- ======================================================================
function Lib:Loader(cfg)
    cfg = cfg or {}
    local plr = game:GetService("Players").LocalPlayer
    local hasConsole = cfg.Console ~= false

    local gui = Instance.new("ScreenGui")
    gui.Name = cfg.Name or "PrimordialLoader"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = cfg.DisplayOrder or 180
    local ok = pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not ok or not gui.Parent then gui.Parent = plr:WaitForChild("PlayerGui") end

    local dim = new("Frame", {
        Name = "Dim",
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = cfg.DimTransparency or 0.35,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
    }, gui)

    local winW = cfg.Width or 440
    local winH = cfg.Height or (hasConsole and 318 or 214)
    local win = new("Frame", {
        Name = "Loader",
        BackgroundColor3 = P.bg,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(winW, winH),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
    }, gui)
    corner(win, 6)
    vgrad(win, P.bgTop, P.bgBottom)
    local winStroke = stroke(win, P.stroke, 1, 0.05)
    strokeGrad(winStroke,
        Color3.fromRGB(108, 108, 120),
        Color3.fromRGB(46, 46, 50),
        numberSeq({ { 0, 0.08 }, { 1, 0.6 } }))
    rimLight(win, 1, 0.92, 1, 3)

    local markHolder = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(18, 18),
        Position = UDim2.fromOffset(18, 17),
    }, win)
    drawLogoMark(markHolder, 13, P.accent)

    -- бренд лоадера: отдельное имя "Primordial Loader" в экосистеме Primordial
    local title = text(win, {
        Text = string.format('<font color="#E9E9EE">%s</font> <font color="#%s">%s</font>',
            tostring(cfg.Brand or "Primordial"),
            string.format("%02X%02X%02X",
                math.floor(P.accent.R * 255 + 0.5),
                math.floor(P.accent.G * 255 + 0.5),
                math.floor(P.accent.B * 255 + 0.5)),
            tostring(cfg.BrandSuffix or "Loader")),
        RichText = true,
        TextSize = 20,
        Position = UDim2.fromOffset(45, 12),
        Size = UDim2.new(1, -66, 0, 28),
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, W_SEMI)

    local subParts = {}
    if cfg.Title and cfg.Title ~= "" then subParts[#subParts + 1] = tostring(cfg.Title) end
    if cfg.Subtitle and cfg.Subtitle ~= "" then subParts[#subParts + 1] = tostring(cfg.Subtitle) end
    text(win, {
        Text = #subParts > 0 and table.concat(subParts, "  ·  ") or "loader",
        TextSize = 12,
        TextColor3 = P.dim,
        Position = UDim2.fromOffset(46, 37),
        Size = UDim2.new(1, -66, 0, 16),
        TextTruncate = Enum.TextTruncate.AtEnd,
    })

    new("Frame", {
        BackgroundColor3 = P.stroke,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -36, 0, 1),
        Position = UDim2.fromOffset(18, 58),
    }, win)

    local statusLbl = text(win, {
        Name = "Status",
        Text = cfg.Status or "Starting...",
        TextSize = 14,
        TextColor3 = P.sub,
        Position = UDim2.fromOffset(18, 70),
        Size = UDim2.new(1, -36, 0, 20),
        TextTruncate = Enum.TextTruncate.AtEnd,
    })

    local track = new("Frame", {
        BackgroundColor3 = P.element,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -36, 0, 4),
        Position = UDim2.fromOffset(18, 96),
    }, win)
    corner(track, 2)
    vgrad(track, Color3.fromRGB(52, 52, 57), Color3.fromRGB(78, 78, 86))
    local fill = new("Frame", {
        BackgroundColor3 = P.accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 1, 0),
        ClipsDescendants = true,
    }, track)
    corner(fill, 2)
    hgrad(fill, P.accentTop, P.accentBottom)
    local fillShine = new("Frame", {
        BackgroundColor3 = P.rim,
        BackgroundTransparency = 0.72,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.fromOffset(0, 1),
    }, fill)

    local logScroll, logCount = nil, 0
    if hasConsole then
        local box = new("Frame", {
            BackgroundColor3 = P.chrome,
            BorderSizePixel = 0,
            Size = UDim2.new(1, -36, 1, -132),
            Position = UDim2.fromOffset(18, 110),
            ClipsDescendants = true,
        }, win)
        corner(box, 4)
        vgrad(box, Color3.fromRGB(26, 26, 30), Color3.fromRGB(20, 20, 23))
        local logStroke = stroke(box, P.stroke, 1, 0.5)
        strokeGrad(logStroke, Color3.fromRGB(80, 80, 90), Color3.fromRGB(40, 40, 44),
            numberSeq({ { 0, 0.45 }, { 1, 0.7 } }))
        rimLight(box, 1, 0.96, 1, 3)
        padAll(box, 10, 8, 10, 8)
        logScroll = new("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = P.sub,
            ScrollBarImageTransparency = 0.5,
        }, box)
        listLayout(logScroll, 2)
    end

    local L = {
        GUI = gui,
        Frame = win,
        Dim = dim,
        Status = statusLbl,
        Progress = fill,
    }
    local closed = false

    -- Рисованный крестик: в JosefinSans нет глифа ✕, а рамка на его месте
    -- выглядит как битый символ, поэтому рисуем двумя повёрнутыми полосками.
    local function makeCloseIcon(host, color)
        local parts = {}
        for _, rot in ipairs({ 45, -45 }) do
            parts[#parts + 1] = new("Frame", {
                BackgroundColor3 = color,
                BorderSizePixel = 0,
                Size = UDim2.fromOffset(9, 1.5),
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Rotation = rot,
                ZIndex = 7,
            }, host)
        end
        return parts
    end

    local closeBtn = button(win, {
        Name = "Close",
        BackgroundColor3 = P.element,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(22, 22),
        Position = UDim2.new(1, -30, 0, 12),
        ZIndex = 6,
    })
    corner(closeBtn, 3)
    local closeIcon = makeCloseIcon(closeBtn, P.dim)
    local function tintClose(color)
        for _, bar in ipairs(closeIcon) do bar.BackgroundColor3 = color end
    end
    closeBtn.MouseEnter:Connect(function()
        tintClose(P.danger)
        closeBtn.BackgroundTransparency = 0.82
    end)
    closeBtn.MouseLeave:Connect(function()
        tintClose(P.dim)
        closeBtn.BackgroundTransparency = 1
    end)

    function L:SetStatus(v)
        if closed then return end
        statusLbl.TextColor3 = P.sub
        statusLbl.Text = tostring(v or "")
    end

    function L:SetProgress(alpha, text)
        if closed then return end
        alpha = math.clamp(tonumber(alpha) or 0, 0, 1)
        tween(fill, 0.18, { Size = UDim2.new(alpha, 0, 1, 0) })
        if text then self:SetStatus(text) end
    end

    function L:Log(line, color)
        if closed or not logScroll then return nil end
        logCount = logCount + 1
        local row = text(logScroll, {
            Text = tostring(line),
            TextSize = 12,
            TextColor3 = color or P.sub,
            Size = UDim2.new(1, 0, 0, 16),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            LayoutOrder = logCount,
        })
        pcall(function()
            logScroll.CanvasPosition = Vector2.new(0, math.max(0, logScroll.AbsoluteCanvasSize.Y))
        end)
        return row
    end

    function L:Done(text, delay)
        if closed then return end
        statusLbl.TextColor3 = P.accent
        statusLbl.Text = tostring(text or "Done")
        tween(fill, 0.2, { Size = UDim2.new(1, 0, 1, 0) })
        task.delay(delay or cfg.CloseDelay or 0.9, function() L:Destroy() end)
    end

    function L:Fail(text)
        if closed then return end
        statusLbl.TextColor3 = P.danger
        statusLbl.Text = tostring(text or "Failed")
        tween(fill, 0.2, { BackgroundColor3 = P.danger })
    end

    function L:Destroy()
        if closed then return end
        closed = true
        pcall(function() gui:Destroy() end)
        if Lib.__loader == L then Lib.__loader = nil end
    end

    closeBtn.MouseButton1Click:Connect(function() L:Destroy() end)

    -- Сколько лоадер живёт максимум. Если за это время никто не вызвал
    -- :Done()/:Destroy(), он покажет ошибку и сам уйдёт с экрана, чтобы
    -- не остаться вечной картинкой поверх игры.
    local watchdog = nil
    function L:SetTimeout(sec)
        if watchdog then pcall(task.cancel, watchdog) end
        watchdog = task.delay(tonumber(sec) or 20, function()
            if closed then return end
            L:Fail("Timed out")
            task.delay(2.5, function() L:Destroy() end)
        end)
    end

    -- Подсветить кнопку закрытия (кнопка и так есть; метод для интеграций,
    -- которые раньше звали ui.showClose()).
    function L:ShowClose()
        if closed then return end
        tintClose(P.danger)
        tween(closeBtn, 0.15, { BackgroundTransparency = 0.82 })
    end

    Lib.__loader = L
    return L
end

function Lib:Notify(opts)
    if Lib.__window then
        return Lib.__window:Notify(opts)
    end
    return nil
end
Lib.CreateNotification = Lib.Notify

-- мягкая тень вокруг произвольного элемента (оставлена как публичный хелпер:
-- окно/лоадер/дропдаун её больше не используют — в оригинальном primordial
-- внешних ореолов нет).
Lib.SoftShadow = softShadow

local genv = getgenv and getgenv() or _G
genv.PrimordialUI = Lib

return Lib
