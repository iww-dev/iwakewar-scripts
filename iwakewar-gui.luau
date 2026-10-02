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

local F = Enum.Font.Code
local C_PANEL = Color3.fromRGB(16, 16, 16)
local C_PANEL2 = Color3.fromRGB(24, 24, 24)
local C_LINE = Color3.fromRGB(70, 70, 70)
local C_TXT = Color3.fromRGB(220, 220, 220)
local C_DIMTXT = Color3.fromRGB(140, 140, 140)
local C_GREEN = Color3.fromRGB(0, 255, 0)
local C_DGREEN = Color3.fromRGB(0, 180, 0)
local C_RED = Color3.fromRGB(255, 60, 60)

local GUI = {}
GUI.Options = {}
GUI.Unloaded = false

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
    accent.BackgroundColor3 = C_GREEN
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
    x.Text = "Close"
    x.TextSize = 13
    x.TextColor3 = Color3.new(1, 1, 1)
    x.AutoButtonColor = false
    x.Size = UDim2.fromOffset(fitWidth(0, "Close", 13, 24), 28)
    x.Position = UDim2.new(1, -(x.Size.X.Offset + 10), 0, 14)
    x.Parent = bar
    stroke(x, Color3.fromRGB(200, 60, 60))
    x.MouseEnter:Connect(function() x.BackgroundColor3 = Color3.fromRGB(180, 40, 40) end)
    x.MouseLeave:Connect(function() x.BackgroundColor3 = Color3.fromRGB(150, 30, 30) end)

    -- drag
    do
        local drag, ds, sp = false, nil, nil
        bar.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                drag, ds, sp = true, i.Position, win.Position
            end
        end)
        bar.InputEnded:Connect(function() drag = false end)
        UIS.InputChanged:Connect(function(i)
            if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
                local d = i.Position - ds
                win.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
            end
        end)
    end

    -- sidebar
    local side = Instance.new("Frame")
    side.BackgroundColor3 = C_PANEL2
    side.BorderSizePixel = 0
    side.Position = UDim2.new(0, 10, 0, 66)
    side.Size = UDim2.new(0, tabW, 1, -76)
    side.Parent = win
    stroke(side)
    local sideLay = Instance.new("UIListLayout")
    sideLay.FillDirection = Enum.FillDirection.Vertical
    sideLay.Padding = UDim.new(0, 4)
    sideLay.SortOrder = Enum.SortOrder.LayoutOrder
    sideLay.Parent = side
    local sidePad = Instance.new("UIPadding")
    sidePad.PaddingTop = UDim.new(0, 6)
    sidePad.PaddingLeft = UDim.new(0, 6)
    sidePad.PaddingRight = UDim.new(0, 6)
    sidePad.Parent = side

    -- content holder
    local holder = Instance.new("Frame")
    holder.BackgroundTransparency = 1
    holder.Position = UDim2.new(0, tabW + 20, 0, 66)
    holder.Size = UDim2.new(1, -(tabW + 30), 1, -76)
    holder.Parent = win

    local Window = { _tabs = {}, _sel = nil, _sgui = sgui, _win = win }
    self._win = Window

    function Window:SelectTab(i)
        local t = self._tabs[i]
        if not t then return end
        self._sel = t
        for _, tb in ipairs(self._tabs) do
            tb.page.Visible = (tb == t)
            tb.btn.TextColor3 = (tb == t) and C_GREEN or C_TXT
            tb.btn.Text = ((tb == t) and "> " or "  ") .. tb.name
        end
    end

    function Window:AddTab(tcfg)
        local name = tcfg.Title or ("Tab" .. (#self._tabs + 1))
        local b = btn(side, name, C_TXT)
        b.Size = UDim2.new(1, 0, 0, 30)
        b.AutomaticSize = Enum.AutomaticSize.Y
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.TextWrapped = true
        local bp = Instance.new("UIPadding")
        bp.PaddingLeft = UDim.new(0, 10)
        bp.PaddingRight = UDim.new(0, 6)
        bp.PaddingTop = UDim.new(0, 6)
        bp.PaddingBottom = UDim.new(0, 6)
        bp.Parent = b
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
        pad.Parent = page
        local tab = { name = name, btn = b, page = page, _win = self }
        b.MouseButton1Click:Connect(function()
            for i, tb in ipairs(self._tabs) do
                if tb == tab then self:SelectTab(i) break end
            end
        end)
        table.insert(self._tabs, tab)

        function tab:AddSection(text)
            local s = label(page, "-- " .. tostring(text) .. " --", 12, C_DGREEN, Enum.TextXAlignment.Center)
            s.Size = UDim2.new(1, 0, 0, 18)
            s.LayoutOrder = #page:GetChildren() * 10
        end

        function tab:AddParagraph(pcfg)
            local f = Instance.new("Frame")
            f.BackgroundColor3 = C_PANEL2
            f.BorderSizePixel = 0
            f.Size = UDim2.new(1, 0, 0, 54)
            f.AutomaticSize = Enum.AutomaticSize.Y
            f.Parent = page
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
            local b2 = btn(page, tostring(bcfg.Title or "Button"), C_TXT)
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
            local f = Instance.new("Frame")
            f.BackgroundColor3 = C_PANEL2
            f.BorderSizePixel = 0
            f.Size = UDim2.new(1, 0, 0, 30)
            f.Parent = page
            stroke(f)
            local t = label(f, tostring(tcfg.Title or id), 13, C_TXT)
            t.Position = UDim2.new(0, 10, 0, 0)
            t.Size = UDim2.new(1, -90, 1, 0)
            t.TextYAlignment = Enum.TextYAlignment.Center
            if tcfg.Description then
                t.Text = tostring(tcfg.Title) .. "  [" .. tostring(tcfg.Description):sub(1, 40) .. "]"
            end
            local s = btn(f, "[ off ]", C_DIMTXT)
            s.AutomaticSize = Enum.AutomaticSize.X
            s.Size = UDim2.new(0, 0, 0, 22)
            s.AnchorPoint = Vector2.new(1, 0.5)
            s.Position = UDim2.new(1, -10, 0.5, 0)
            s.TextSize = 12
            local tog = { Value = false, _cbs = {} }
            local function paint()
                local txt = tog.Value and "[ on ]" or "[ off ]"
                s.Text = txt
                s.Size = UDim2.new(0, measureX(txt, 12) + 20, 0, 22)
                s.TextColor3 = tog.Value and C_GREEN or C_DIMTXT
            end
            function tog:SetValue(v)
                v = (v == true)
                if tog.Value == v then return end
                tog.Value = v
                paint()
                for _, fn in ipairs(tog._cbs) do task.spawn(fn, v) end
                if tcfg.Callback then task.spawn(tcfg.Callback, v) end
            end
            function tog:OnChanged(fn) table.insert(tog._cbs, fn) end
            function tog:OnClick(fn) table.insert(tog._cbs, fn) end
            s.MouseButton1Click:Connect(function() tog:SetValue(not tog.Value) end)
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
            f.BackgroundColor3 = C_PANEL2
            f.BorderSizePixel = 0
            f.Size = UDim2.new(1, 0, 0, 52)
            f.Parent = page
            stroke(f)
            local t = label(f, tostring(scfg.Title or id), 13, C_TXT)
            t.Position = UDim2.new(0, 10, 0, 2)
            t.Size = UDim2.new(1, -90, 0, 18)
            local val = label(f, "", 12, C_GREEN, Enum.TextXAlignment.Right)
            val.Position = UDim2.new(1, -78, 0, 2)
            val.Size = UDim2.new(0, 70, 0, 18)
            local rail = Instance.new("TextButton")
            rail.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
            rail.BorderSizePixel = 0
            rail.Position = UDim2.new(0, 8, 0, 26)
            rail.Size = UDim2.new(1, -20, 0, 14)
            rail.Text = ""
            rail.AutoButtonColor = false
            rail.Parent = f
            stroke(rail, Color3.fromRGB(50, 50, 50))
            local fill = Instance.new("Frame")
            fill.BackgroundColor3 = C_GREEN
            fill.BorderSizePixel = 0
            fill.Size = UDim2.new(0, 0, 1, 0)
            fill.Parent = rail
            local sld = { Value = fmt(tonumber(scfg.Default) or min), _cbs = {} }
            local function paint()
                local r = (sld.Value - min) / math.max(0.0001, (max - min))
                fill.Size = UDim2.new(math.clamp(r, 0, 1), 0, 1, 0)
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
            f.BackgroundColor3 = C_PANEL2
            f.BorderSizePixel = 0
            f.Size = UDim2.new(1, 0, 0, 30)
            f.Parent = page
            stroke(f)
            local t = label(f, tostring(dcfg.Title or id), 13, C_TXT)
            t.Position = UDim2.new(0, 10, 0, 0)
            t.Size = UDim2.new(0.55, -8, 1, 0)
            local b2 = btn(f, tostring(cur) .. " [+]", C_GREEN)
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
                    local ob = btn(pop, tostring(v), (v == dd.Value) and C_GREEN or C_TXT)
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
            if typeof(cur) ~= "Color3" then cur = Color3.fromRGB(0, 255, 0) end
            local f = Instance.new("Frame")
            f.BackgroundColor3 = C_PANEL2
            f.BorderSizePixel = 0
            f.Size = UDim2.new(1, 0, 0, 30)
            f.Parent = page
            stroke(f)
            local t = label(f, tostring(ccfg.Title or id), 13, C_TXT)
            t.Position = UDim2.new(0, 10, 0, 0)
            t.Size = UDim2.new(1, -80, 1, 0)
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
            f.BackgroundColor3 = C_PANEL2
            f.BorderSizePixel = 0
            f.Size = UDim2.new(1, 0, 0, 30)
            f.Parent = page
            stroke(f)
            local t = label(f, tostring(kcfg.Title or id), 13, C_TXT)
            t.Position = UDim2.new(0, 10, 0, 0)
            t.Size = UDim2.new(1, -100, 1, 0)
            t.TextYAlignment = Enum.TextYAlignment.Center
            local kb = btn(f, "[ " .. key .. " ]", C_GREEN)
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

    -- mobile floating toggle
    if isPhone then
        pcall(function() game:GetService("CoreGui").iwkToggle:Destroy() end)
        local sg2 = Instance.new("ScreenGui")
        sg2.Name = "iwkToggle"
        sg2.ResetOnSpawn = false
        pcall(function() sg2.Parent = game:GetService("CoreGui") end)
        if sg2.Parent == nil then sg2.Parent = LP:WaitForChild("PlayerGui") end
        local b = Instance.new("TextButton")
        b.Size = UDim2.fromOffset(48, 48)
        b.Position = UDim2.new(0.5, -24, 0.5, -260)
        b.Text = string.sub(title, 1, 1)
        b.Font = F
        b.TextSize = 20
        b.BackgroundColor3 = C_PANEL2
        b.TextColor3 = C_TXT
        b.Parent = sg2
        local cc = Instance.new("UICorner")
        cc.CornerRadius = UDim.new(0, 10)
        cc.Parent = b
        local glow = Instance.new("UIStroke")
        glow.Thickness = 3
        glow.Color = C_GREEN
        glow.Transparency = 0.4
        glow.Parent = b
        task.spawn(function()
            while b.Parent do
                pcall(function()
                    TW:Create(glow, TweenInfo.new(0.8), { Transparency = 0.75 }):Play()
                    task.wait(0.85)
                    TW:Create(glow, TweenInfo.new(0.8), { Transparency = 0.25 }):Play()
                    task.wait(0.85)
                end)
            end
        end)
        local drag, ds, sp, moved = false, nil, nil, 0
        b.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
                drag, ds, sp, moved = true, i.Position, b.Position, 0
            end
        end)
        b.InputEnded:Connect(function() drag = false end)
        UIS.InputChanged:Connect(function(i)
            if drag and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
                local d = i.Position - ds
                moved = d.Magnitude
                b.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
            end
        end)
        b.Activated:Connect(function()
            if moved < 12 and sgui.Parent then
                sgui.Enabled = not sgui.Enabled
            end
        end)
    end

    return Window
end

-- keybind mode reader (modes stored per keybind object)
function kcfg_mode(k)
    return (k and k._mode) or "Toggle"
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
