--[[
    PrimordialUI — flat dark hub UI for Roblox executors.
    Style: left category sidebar, top sub-tab strip, flat cards with header
    strips and compact rows. No external dependencies.

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
    bg = Color3.fromRGB(19, 19, 21),
    chrome = Color3.fromRGB(15, 15, 17),
    stroke = Color3.fromRGB(46, 46, 52),
    card = Color3.fromRGB(29, 29, 33),
    cardHead = Color3.fromRGB(38, 38, 43),
    cardHover = Color3.fromRGB(35, 35, 40),
    element = Color3.fromRGB(43, 43, 49),
    elementHover = Color3.fromRGB(54, 54, 61),
    text = Color3.fromRGB(233, 233, 238),
    sub = Color3.fromRGB(139, 139, 150),
    dim = Color3.fromRGB(94, 94, 104),
    accent = Color3.fromRGB(216, 132, 171),
    track = Color3.fromRGB(54, 54, 61),
    knob = Color3.fromRGB(238, 238, 244),
    danger = Color3.fromRGB(214, 94, 103),
    checkMark = Color3.fromRGB(26, 18, 22),
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
Lib.Version = "1.0.0"
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
    stroke(root, P.stroke, 1, 0.1)
    W.Frame = root

    -- мягкая тень вокруг окна: несколько полупрозрачных слоёв
    local shadowHost = new("Frame", {
        Name = "Shadow",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 1,
    }, gui)
    local shadows = {}
    for i = 1, 9 do
        local sh = new("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0.62 + i * 0.035,
            BorderSizePixel = 0,
            ZIndex = 1,
        }, shadowHost)
        corner(sh, 8 + i * 2)
        shadows[i] = sh
    end
    local function syncShadow()
        for i, sh in ipairs(shadows) do
            sh.Size = UDim2.new(
                root.Size.X.Scale, root.Size.X.Offset + i * 5,
                root.Size.Y.Scale, root.Size.Y.Offset + i * 3.5
            )
            sh.Position = UDim2.new(
                root.Position.X.Scale, root.Position.X.Offset - i * 2.5,
                root.Position.Y.Scale, root.Position.Y.Offset - i * 1.75 + 3
            )
        end
        shadowHost.Visible = root.Visible
    end
    syncShadow()
    root:GetPropertyChangedSignal("Size"):Connect(syncShadow)
    root:GetPropertyChangedSignal("Position"):Connect(syncShadow)
    root:GetPropertyChangedSignal("Visible"):Connect(syncShadow)

    -- top bar -----------------------------------------------------------
    local top = new("Frame", {
        Name = "Top",
        BackgroundColor3 = P.chrome,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 42),
        ClipsDescendants = true,
    }, root)
    corner(top, 6)

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

    new("Frame", {
        BackgroundColor3 = P.stroke,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
    }, top)

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

    local sidebar = new("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = P.chrome,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 196, 1, 0),
    }, body)
    local sbPad = Instance.new("UIPadding")
    sbPad.PaddingTop = UDim.new(0, 8)
    sbPad.PaddingBottom = UDim.new(0, 8)
    sbPad.Parent = sidebar
    listLayout(sidebar, 2)

    -- разделитель сайдбара: от низа топбара и до самого низа окна
    new("Frame", {
        BackgroundColor3 = P.stroke,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 1, 1, -42),
        Position = UDim2.new(0, 196, 0, 42),
        ZIndex = 10,
    }, root)

    -- footer ------------------------------------------------------------
    local footer = new("Frame", {
        Name = "Footer",
        BackgroundColor3 = P.chrome,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 32),
        Position = UDim2.new(0, 0, 1, -32),
    }, root)
    new("Frame", {
        BackgroundColor3 = P.stroke,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
    }, footer)
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

    local notifyOrder = 0
    function W:Notify(opts)
        opts = opts or {}
        notifyOrder = notifyOrder + 1
        local hold = math.max(0.6, tonumber(opts.Duration) or 4)
        local card = new("Frame", {
            BackgroundColor3 = P.card,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            LayoutOrder = notifyOrder,
        }, notifyHolder)
        corner(card, 4)
        local st = stroke(card, P.stroke, 1, 1)
        -- отступы прямо на карточке: AutomaticSize учитывает UIPadding,
        -- поэтому высота всегда совпадает с текстом
        padAll(card, 16, 9, 14, 9)
        local inner = new("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
        }, card)
        listLayout(inner, 3)
        -- акцентная полоска слева: высоту берём у inner, а не scale,
        -- иначе AutomaticSize зацикливается и карточка растягивается на весь экран
        local bar = new("Frame", {
            BackgroundColor3 = opts.Accent or P.accent,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 2, 0, 0),
            Position = UDim2.fromOffset(-15, 8),
            BackgroundTransparency = 1,
        }, card)
        corner(bar, 1)
        local function syncBar()
            bar.Size = UDim2.new(0, 2, 0, math.max(0, inner.AbsoluteSize.Y - 16))
        end
        syncBar()
        inner:GetPropertyChangedSignal("AbsoluteSize"):Connect(syncBar)
        local t1 = text(inner, {
            Text = tostring(opts.Title or "Notification"),
            TextSize = 14,
            Size = UDim2.new(1, 0, 0, 18),
            TextTransparency = 1,
            TextTruncate = Enum.TextTruncate.AtEnd,
            LayoutOrder = 1,
        }, W_SEMI)
        local c1 = text(inner, {
            Text = tostring(opts.Content or ""),
            TextColor3 = P.sub,
            TextSize = 13,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            TextWrapped = true,
            TextTransparency = 1,
            LayoutOrder = 2,
        })
        tween(card, 0.16, { BackgroundTransparency = 0 })
        tween(st, 0.16, { Transparency = 0.25 })
        tween(bar, 0.16, { BackgroundTransparency = 0 })
        tween(t1, 0.16, { TextTransparency = 0 })
        tween(c1, 0.16, { TextTransparency = 0 })
        task.delay(hold, function()
            if not card.Parent then return end
            tween(card, 0.22, { BackgroundTransparency = 1 })
            tween(st, 0.22, { Transparency = 1 })
            tween(bar, 0.22, { BackgroundTransparency = 1 })
            tween(t1, 0.22, { TextTransparency = 1 })
            tween(c1, 0.22, { TextTransparency = 1 })
            task.wait(0.25)
            pcall(function() card:Destroy() end)
        end)
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
        stroke(pop, P.stroke, 1, 0)
        padAll(pop, 4, 4, 4, 4)
        listLayout(pop, 1)
        openPopup = pop
        openPopupAnchor = anchor

        for i, item in ipairs(items) do
            local row = button(pop, {
                Text = tostring(item),
                TextSize = 13,
                Size = UDim2.new(1, 0, 0, 26),
                BackgroundColor3 = (item == current) and P.element or P.card,
                BackgroundTransparency = (item == current) and 0 or 1,
                TextColor3 = (item == current) and P.text or P.sub,
                LayoutOrder = i,
                ZIndex = 41,
            })
            padAll(row, 8, 0, 8, 0)
            corner(row, 3)
            row.MouseEnter:Connect(function()
                row.BackgroundTransparency = 0
                row.BackgroundColor3 = P.elementHover
                row.TextColor3 = P.text
            end)
            row.MouseLeave:Connect(function()
                row.BackgroundColor3 = (item == current) and P.element or P.card
                row.BackgroundTransparency = (item == current) and 0 or 1
                row.TextColor3 = (item == current) and P.text or P.sub
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
        stroke(card, P.stroke, 1, 0.45)
        listLayout(card, 0)

        local head = new("Frame", {
            BackgroundColor3 = P.cardHead,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 30),
            Visible = titleStr ~= nil and titleStr ~= "",
        }, card)
        corner(head, 4)
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
        local box = new("Frame", {
            BackgroundColor3 = isOn and P.accent or P.element,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(17, 17),
            Position = UDim2.fromOffset(0, 3),
        }, parent)
        corner(box, 3)
        stroke(box, isOn and P.accent or P.stroke, 1, 0)
        local check = text(box, {
            Text = "\u{2713}",
            TextSize = 14,
            TextColor3 = P.checkMark,
            TextXAlignment = Enum.TextXAlignment.Center,
            Size = UDim2.fromScale(1, 1),
            TextTransparency = isOn and 0 or 1,
        }, W_BOLD)
        local hit = button(parent, {
            Size = UDim2.fromOffset(17, 17),
            Position = UDim2.fromOffset(0, 3),
            BackgroundTransparency = 1,
        })
        local state = isOn == true
        local api = {}
        function api:SetValue(v)
            state = v and true or false
            tween(box, 0.12, { BackgroundColor3 = state and P.accent or P.element })
            tween(check, 0.12, { TextTransparency = state and 0 or 1 })
            local st = box:FindFirstChildOfClass("UIStroke")
            if st then tween(st, 0.12, { Color = state and P.accent or P.stroke }) end
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
        local fill = new("Frame", {
            BackgroundColor3 = P.accent,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 0, 1, 0),
        }, track)
        corner(fill, 2)
        local knob = new("Frame", {
            BackgroundColor3 = P.knob,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(10, 10),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0, 0.5),
        }, track)
        corner(knob, 5)

        local function redraw()
            local n = math.clamp((value - min) / math.max(1e-6, max - min), 0, 1)
            fill.Size = UDim2.new(n, 0, 1, 0)
            knob.Position = UDim2.fromScale(n, 0.5)
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

        local bar = new("Frame", {
            BackgroundColor3 = P.accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 2, 0, 26),
            Position = UDim2.new(0, 4, 0.5, -13),
        }, btnBg)
        corner(bar, 2)

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
        listLayout(strip, 0, Enum.FillDirection.Horizontal)
        local stripPad = Instance.new("UIPadding")
        stripPad.PaddingLeft = UDim.new(0, 6)
        stripPad.PaddingRight = UDim.new(0, 14)
        stripPad.Parent = strip
        -- линия-разделитель живёт в page, а не в strip: иначе она участвует
        -- в горизонтальном UIListLayout и выдавливает чипсы за экран
        new("Frame", {
            BackgroundColor3 = P.stroke,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 0, 33),
            ZIndex = 2,
        }, page)

        local scroll = new("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, -34),
            Position = UDim2.fromOffset(0, 34),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Color3.fromRGB(72, 72, 80),
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
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 0, 1, -1),
                AutomaticSize = Enum.AutomaticSize.X,
                TextXAlignment = Enum.TextXAlignment.Center,
                LayoutOrder = #tab.Sections,
            }, W_MED)
            padAll(chip, 16, 0, 16, 0)
            local chipLine = new("Frame", {
                BackgroundColor3 = P.accent,
                BorderSizePixel = 0,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -18, 0, 2),
                Position = UDim2.new(0, 9, 1, -3),
            }, chip)
            corner(chipLine, 1)

            chip.MouseEnter:Connect(function() chip.TextColor3 = P.text end)
            chip.MouseLeave:Connect(function()
                chip.TextColor3 = (tab.SelectedSection == sectionEntry) and P.text or P.sub
            end)
            chip.MouseButton1Click:Connect(function()
                tab:_selectSection(sectionEntry)
            end)
            sectionEntry.Chip = chip
            sectionEntry.ChipLine = chipLine
            if tab.SelectedSection == sectionEntry then
                chip.TextColor3 = P.text
                chipLine.BackgroundTransparency = 0
            end
        end

        -- переключение секций: показываем только выбранную, остальные прячем
        function tab:_selectSection(sectionEntry)
            for _, s in ipairs(tab.Sections) do
                local active = (s == sectionEntry)
                if s.Container then s.Container.Visible = active end
                if s.Chip then s.Chip.TextColor3 = active and P.text or P.sub end
                if s.ChipLine then s.ChipLine.BackgroundTransparency = active and 0 or 1 end
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
        })
        corner(box, 3)
        padAll(box, 9, 0, 22, 0)
        local valueLbl = text(box, {
            Text = tostring(api.Value),
            TextSize = 14,
            Size = UDim2.new(1, 0, 1, 0),
            TextTruncate = Enum.TextTruncate.AtEnd,
        })
        text(box, {
            Text = "v",
            TextSize = 11,
            TextColor3 = P.sub,
            TextXAlignment = Enum.TextXAlignment.Right,
            Size = UDim2.new(1, -9, 1, -1),
        }, W_SEMI)
        box.MouseEnter:Connect(function() tween(box, 0.1, { BackgroundColor3 = P.elementHover }) end)
        box.MouseLeave:Connect(function() tween(box, 0.1, { BackgroundColor3 = P.element }) end)
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

        local box = button(holder, { BackgroundColor3 = P.element, Size = UDim2.fromOffset(104, 24) })
        corner(box, 3)
        local boxLabel = text(box, {
            Text = keyName(),
            TextSize = 14,
            TextColor3 = P.sub,
            TextXAlignment = Enum.TextXAlignment.Center,
            Size = UDim2.fromScale(1, 1),
        })

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
        text(row, {
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

        card.MouseEnter:Connect(function() setCardHover(card, true) end)
        card.MouseLeave:Connect(function() setCardHover(card, false) end)
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
    stroke(win, P.stroke, 1, 0.05)

    local markHolder = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(18, 18),
        Position = UDim2.fromOffset(18, 17),
    }, win)
    drawLogoMark(markHolder, 13, P.accent)

    local title = text(win, {
        Text = cfg.Title or "iwakewar-scripts",
        TextSize = 20,
        Position = UDim2.fromOffset(45, 12),
        Size = UDim2.new(1, -66, 0, 28),
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, W_SEMI)
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(240, 240, 244)),
        ColorSequenceKeypoint.new(1, P.accent),
    })
    grad.Parent = title

    text(win, {
        Text = cfg.Subtitle or "loader",
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
    local fill = new("Frame", {
        BackgroundColor3 = P.accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 1, 0),
    }, track)
    corner(fill, 2)

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
        stroke(box, P.stroke, 1, 0.5)
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

local genv = getgenv and getgenv() or _G
genv.PrimordialUI = Lib

return Lib
