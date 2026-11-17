local P = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local U = "https://iwakewar.fun"
local K = "5c03f42e392c0f1bbe531eb23315ecc1b452b0587d17024e"
local B = U .. "/scripts/"
local R = "https://raw.githubusercontent.com/iww-dev/iwakewar-scripts/main/"
local V = "v3.2.0"

local G = {
    ["6520999642"] = { n = "Basically FNF: Remix", f = "BFNFR Auto-Play.luau" },
    ["6447798030"] = { n = "Funky Friday", f = "FunkyFriday Auto-Play.luau" },
    ["71106427459865"] = { n = "Игра в Слова", f = "WordGame Auto-Play.luau" },
    ["537413528"] = { n = "Build A Boat For Treasure", f = "BABFT.luau" },
    ["93466613073564"] = { n = "Scoped FPS", f = "UnAim.luau" },
    ["114689356953798"] = { n = "Scoped FPS", f = "UnAim.luau" },
}

local T: string? = nil
local UI: any = nil
local C: any = nil

local function en(v: any): string
    return (tostring(v):gsub("[^%w%-%._~]", function(c: string): string
        return string.format("%%%02X", string.byte(c))
    end))
end

local function gg(): any
    local ok, t = pcall(function() return getgenv() end)
    if ok and typeof(t) == "table" then return t end
    return _G
end

local function q(u: string): string?
    local g = gg()
    local f = (g.syn and g.syn.request) or (g.http and g.http.request) or g.http_request
        or (g.fluxus and g.fluxus.request) or g.request
    if typeof(f) == "function" then
        local ok, r = pcall(f, { Url = u, Method = "GET" })
        if ok then
            if typeof(r) == "table" then return tostring(r.Body or "") end
            if typeof(r) == "string" then return r end
        end
    end
    local ok, r = pcall(function() return game:HttpGet(u) end)
    if ok and typeof(r) == "string" then return r end
    local ok2, r2 = pcall(function() return game:GetService("HttpService"):GetAsync(u) end)
    if ok2 and typeof(r2) == "string" then return r2 end
    return nil
end

local function qp(u: string, data: any): string?
    local okj, body = pcall(function()
        return game:GetService("HttpService"):JSONEncode(data)
    end)
    if not okj then return nil end
    local g = gg()
    local f = (g.syn and g.syn.request) or (g.http and g.http.request) or g.http_request
        or (g.fluxus and g.fluxus.request) or g.request
    if typeof(f) == "function" then
        local ok, r = pcall(f, { Url = u, Method = "POST", Body = body, Headers = { ["content-type"] = "application/json" } })
        if ok and typeof(r) == "table" then return tostring(r.Body or "") end
        if ok and typeof(r) == "string" then return r end
    end
    local ok, r = pcall(function()
        return game:GetService("HttpService"):PostAsync(u, body, Enum.HttpContentType.ApplicationJson)
    end)
    if ok and typeof(r) == "string" then return r end
    return nil
end

local function hw(): string
    local ok, v = pcall(function() return gethwid() end)
    if ok and typeof(v) == "string" and #v > 0 then return v end
    local ok2, c = pcall(function() return game:GetService("RbxAnalyticsService"):GetClientId() end)
    if ok2 and typeof(c) == "string" and #c > 0 then return c end
    local p = P.LocalPlayer
    return "uid-" .. tostring(p and p.UserId or 0)
end

local function ex(): string
    local ok, a = pcall(function() return identifyexecutor() end)
    if ok and typeof(a) == "string" and #a > 0 then return a end
    return "unknown"
end

local function ck(s: string): number
    local n = #s
    local t = 0
    local i = 1
    while i <= n do
        local j = math.min(i + 511, n)
        local b = { string.byte(s, i, j) }
        for k = 1, #b do
            t += b[k] * (i + k - 1)
        end
        i = j + 1
    end
    return (n * 2654435761 + t) % 4294967296
end

local function num(s: string, k: string): number?
    return tonumber(s:match('"' .. k .. '"%s*:%s*(-?%d+%.?%d*)'))
end

local function bool(s: string, k: string): boolean
    return s:match('"' .. k .. '"%s*:%s*(%a+)') == "true"
end

local function str(s: string, k: string): string?
    return s:match('"' .. k .. '"%s*:%s*"([^"]*)"')
end

local function lb(): any
    local g = gg()
    if typeof(g.__iwL) == "table" then return g.__iwL end
    local s = q(R .. "gui-lib/PrimordialUI.luau")
    if not s or #s < 100 then
        s = q(B .. "gui-lib/PrimordialUI.luau?k=" .. K)
    end
    if not s or #s < 100 then return nil end
    local ok, r = pcall(function()
        return loadstring(s)()
    end)
    if ok and typeof(r) == "table" and typeof(r.Loader) == "function" then
        g.__iwL = r
        return r
    end
    return nil
end

local function pr(b: any): any
    local ok, L = pcall(function()
        return b:Loader({
            Title = "iwakewar-scripts",
            Subtitle = V,
            Status = "Booting...",
            Console = true,
            Width = 470,
            Delay = 0,
            KeepOpen = true,
        })
    end)
    if not ok or typeof(L) ~= "table" then return nil end

    local o: any = {}
    local dn = false
    local OC = Color3.fromRGB(148, 219, 168)
    local DC = Color3.fromRGB(139, 139, 150)

    o.raw = L
    o.log = function(t: string, c: Color3?)
        pcall(function() L:Log(t, c) end)
    end
    o.status = function(t: string, c: Color3?)
        pcall(function() L:SetStatus(t) end)
        pcall(function() L:Log("> " .. t, c or DC) end)
    end
    o.fail = function(m: string, d: string?)
        dn = true
        local full = m
        if d and #d > 0 then full = m .. "  |  " .. d end
        warn("[iwakewar-scripts] " .. full)
        pcall(function() L:Fail(full:sub(1, 160)) end)
        pcall(function() L:ShowClose() end)
        pcall(function() L:CancelTimeout() end)
    end
    o.ok = function(m: string)
        pcall(function() L:Done(m or "Loaded") end)
        pcall(function() L:Log(m or "Loaded", OC) end)
        pcall(function() L:CancelTimeout() end)
    end
    o.close = function()
        pcall(function() L:Destroy() end)
    end
    o.hide = function()
        pcall(function() L:Hide() end)
    end
    o.show = function()
        pcall(function() L:Show() end)
    end
    o.hidden = function(): boolean
        local okh, h = pcall(function() return L:IsHidden() end)
        return okh and h == true
    end
    o.df = function(): boolean
        return dn
    end

    pcall(function() L:SetTimeout(90) end)
    return o
end

local function localPlayer(): Player?
    local p = P.LocalPlayer
    if p then return p end
    local n = 0
    while not p and n < 20 do
        task.wait(0.25)
        n += 1
        p = P.LocalPlayer
    end
    return p
end

local function msg(t: string)
    if UI then UI.log(t) end
end

local function st(t: string)
    if UI then UI.status(t) else warn("[iwakewar-scripts] " .. t) end
end

local function bad(m: string, d: string?)
    if UI then UI.fail(m, d) else warn("[iwakewar-scripts] " .. m .. (d and (" | " .. d) or "")) end
end

local function askKey(id: string): boolean
    local p = P.LocalPlayer
    if not p then return false end
    local pg = p:FindFirstChildOfClass("PlayerGui")
    if not pg then return false end

    local C3 = Color3.fromRGB
    local sg = Instance.new("ScreenGui")
    sg.Name = "iwakewar-access"
    sg.DisplayOrder = 1000
    sg.IgnoreGuiInset = true
    sg.ResetOnSpawn = false
    sg.Parent = pg

    local w = Instance.new("Frame")
    w.AnchorPoint = Vector2.new(0.5, 0.5)
    w.Position = UDim2.fromScale(0.5, 0.5)
    w.Size = UDim2.fromOffset(380, 200)
    w.BackgroundColor3 = C3(14, 14, 16)
    w.BorderSizePixel = 0
    w.Parent = sg
    local uc = Instance.new("UICorner")
    uc.CornerRadius = UDim.new(0, 10)
    uc.Parent = w
    local us = Instance.new("UIStroke")
    us.Color = C3(60, 60, 66)
    us.Parent = w

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamMedium
    title.Position = UDim2.new(0, 18, 0, 14)
    title.Size = UDim2.new(1, -36, 0, 22)
    title.Text = "Enter your access key"
    title.TextColor3 = C3(235, 235, 240)
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = w

    local sub = Instance.new("TextLabel")
    sub.BackgroundTransparency = 1
    sub.Font = Enum.Font.Gotham
    sub.Position = UDim2.new(0, 18, 0, 38)
    sub.Size = UDim2.new(1, -36, 0, 18)
    sub.Text = "the whitelist is on, activate a key to continue"
    sub.TextColor3 = C3(140, 140, 148)
    sub.TextSize = 12
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Parent = w

    local box = Instance.new("TextBox")
    box.BackgroundColor3 = C3(24, 24, 28)
    box.BorderSizePixel = 0
    box.Font = Enum.Font.Code
    box.Position = UDim2.new(0, 18, 0, 66)
    box.Size = UDim2.new(1, -36, 0, 34)
    box.PlaceholderText = "IW-XXXX-XXXX-XXXX"
    box.Text = ""
    box.TextColor3 = C3(240, 240, 245)
    box.PlaceholderColor3 = C3(90, 90, 96)
    box.TextSize = 14
    box.ClearTextOnFocus = false
    box.Parent = w
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 8)
    bc.Parent = box

    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = C3(210, 60, 75)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamMedium
    btn.Position = UDim2.new(0, 18, 0, 110)
    btn.Size = UDim2.new(1, -36, 0, 36)
    btn.Text = "Activate"
    btn.TextColor3 = C3(255, 255, 255)
    btn.TextSize = 14
    btn.Parent = w
    local br = Instance.new("UICorner")
    br.CornerRadius = UDim.new(0, 8)
    br.Parent = btn

    local err = Instance.new("TextLabel")
    err.BackgroundTransparency = 1
    err.Font = Enum.Font.Gotham
    err.Position = UDim2.new(0, 18, 0, 152)
    err.Size = UDim2.new(1, -36, 0, 30)
    err.Text = ""
    err.TextColor3 = C3(230, 90, 100)
    err.TextSize = 12
    err.TextWrapped = true
    err.TextXAlignment = Enum.TextXAlignment.Left
    err.Parent = w

    local done = false
    btn.MouseButton1Click:Connect(function()
        local key = box.Text:gsub("%s", "")
        if #key < 4 then
            err.Text = "key is too short"
            return
        end
        btn.Text = "checking..."
        err.Text = ""
        task.spawn(function()
            local r = qp(U .. "/api/key/activate?k=" .. K, {
                key = key,
                username = p.Name,
                uid = tostring(p.UserId),
                hwid = hw(),
            })
            if r and r:find('"ok"%s*:%s*true') then
                done = true
                w:Destroy()
                return
            end
            local e = r and str(r, "error") or "network error"
            btn.Text = "Activate"
            err.Text = tostring(e)
        end)
    end)

    box.FocusLost:Connect(function()
        if box.Text ~= "" then
            err.Text = ""
        end
    end)

    local n = 0
    while not done and sg.Parent and n < 300 do
        task.wait(0.1)
        n += 1
    end
    pcall(function() sg:Destroy() end)
    return done
end

local S = gg().__iwV
if typeof(S) ~= "table" then
    S = {}
    gg().__iwV = S
end

local function guiOf(name: string): any
    local p = P.LocalPlayer
    local pg = p and p:FindFirstChildOfClass("PlayerGui")
    if not pg then return nil end
    local old = pg:FindFirstChild(name)
    if old then old:Destroy() end
    local sg = Instance.new("ScreenGui")
    sg.Name = name
    sg.DisplayOrder = 1001
    sg.IgnoreGuiInset = true
    sg.ResetOnSpawn = false
    sg.Parent = pg
    return sg
end

local function black(on: boolean)
    if on then
        if S.black and S.black.Parent then return end
        local sg = guiOf("iw_black")
        if not sg then return end
        local f = Instance.new("Frame")
        f.Size = UDim2.fromScale(1, 1)
        f.BackgroundColor3 = Color3.new(0, 0, 0)
        f.BorderSizePixel = 0
        f.Parent = sg
        S.black = sg
    elseif S.black then
        pcall(function() S.black:Destroy() end)
        S.black = nil
    end
end

local function fakeban(on: boolean)
    if not on then
        if S.fake and S.fake.Parent then pcall(function() S.fake:Destroy() end) end
        S.fake = nil
        return
    end
    local sg = guiOf("iw_fakeban")
    if not sg then return end
    S.fake = sg
    local f = Instance.new("Frame")
    f.Size = UDim2.fromScale(1, 1)
    f.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
    f.BorderSizePixel = 0
    f.Parent = sg
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.AnchorPoint = Vector2.new(0.5, 0.5)
    t.Position = UDim2.fromScale(0.5, 0.42)
    t.Size = UDim2.fromOffset(520, 60)
    t.Font = Enum.Font.GothamBold
    t.Text = "You have been banned"
    t.TextColor3 = Color3.fromRGB(235, 70, 80)
    t.TextSize = 30
    t.Parent = sg
    local s2 = Instance.new("TextLabel")
    s2.BackgroundTransparency = 1
    s2.AnchorPoint = Vector2.new(0.5, 0)
    s2.Position = UDim2.fromScale(0.5, 0.5)
    s2.Size = UDim2.fromOffset(520, 24)
    s2.Font = Enum.Font.Gotham
    s2.Text = "reason: suspicious activity (code 4021)"
    s2.TextColor3 = Color3.fromRGB(150, 150, 160)
    s2.TextSize = 14
    s2.Parent = sg
    local b2 = Instance.new("TextButton")
    b2.AnchorPoint = Vector2.new(0.5, 0)
    b2.Position = UDim2.fromScale(0.5, 0.62)
    b2.Size = UDim2.fromOffset(160, 34)
    b2.BackgroundColor3 = Color3.fromRGB(200, 55, 70)
    b2.BorderSizePixel = 0
    b2.Font = Enum.Font.GothamMedium
    b2.Text = "Dismiss"
    b2.TextColor3 = Color3.new(1, 1, 1)
    b2.TextSize = 14
    b2.Parent = sg
    local cr = Instance.new("UICorner")
    cr.CornerRadius = UDim.new(0, 8)
    cr.Parent = b2
    b2.MouseButton1Click:Connect(function()
        if S.fake and S.fake.Parent then S.fake:Destroy() end
        S.fake = nil
    end)
end

local function coregui(on: boolean)
    pcall(function()
        game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, on)
    end)
end

local function rainbow(on: boolean)
    local L = game:GetService("Lighting")
    if not on then
        if S.rbow then pcall(task.cancel, S.rbow) end
        S.rbow = nil
        if S.cc then pcall(function() S.cc:Destroy() end) end
        S.cc = nil
        if S.lg then
            pcall(function()
                L.Ambient = S.lg.a
                L.OutdoorAmbient = S.lg.o
            end)
            S.lg = nil
        end
        return
    end
    if S.rbow then return end
    S.lg = { a = L.Ambient, o = L.OutdoorAmbient }
    local cc = Instance.new("ColorCorrectionEffect")
    cc.Name = "iw_rainbow"
    cc.Parent = L
    S.cc = cc
    S.rbow = task.spawn(function()
        local h = 0
        while S.rbow do
            h = (h + 0.01) % 1
            local c = Color3.fromHSV(h, 0.75, 0.9)
            pcall(function()
                L.Ambient = c
                L.OutdoorAmbient = c
                cc.TintColor = c
            end)
            task.wait(0.05)
        end
    end)
end

local function fp(on: boolean)
    local p = P.LocalPlayer
    if not p then return end
    local L = game:GetService("Lighting")
    if not on then
        pcall(function() p.CameraMode = Enum.CameraMode.Classic end)
        if S.lgt then
            pcall(function()
                L.Brightness = S.lgt.b
                L.Ambient = S.lgt.a
                L.OutdoorAmbient = S.lgt.o
                L.FogEnd = S.lgt.fe
                L.FogStart = S.lgt.fs
            end)
            S.lgt = nil
        end
        return
    end
    S.lgt = { b = L.Brightness, a = L.Ambient, o = L.OutdoorAmbient, fe = L.FogEnd, fs = L.FogStart }
    pcall(function() p.CameraMode = Enum.CameraMode.LockFirstPerson end)
    pcall(function()
        L.Brightness = 0
        L.Ambient = Color3.new(0, 0, 0)
        L.OutdoorAmbient = Color3.new(0, 0, 0)
        L.FogStart = 0
        L.FogEnd = 20
    end)
end

local function fps(cap: number)
    if typeof(setfpscap) == "function" then
        pcall(setfpscap, cap)
    else
        pcall(function() setfpscap(cap) end)
    end
end

local function fling()
    local p = P.LocalPlayer
    local ch = p and p.Character
    local hr = ch and ch:FindFirstChild("HumanoidRootPart")
    if hr then
        pcall(function()
            hr.AssemblyLinearVelocity = Vector3.new(1e5, 1e5, 1e5)
        end)
    end
end

local function ctrl(on: boolean)
    local p = P.LocalPlayer
    if not p then return end
    local ps = p:FindFirstChild("PlayerScripts")
    local pm = ps and ps:FindFirstChild("PlayerModule")
    if not pm then return end
    local ok, controls = pcall(function()
        local m = require(pm)
        return m:GetControls()
    end)
    if not ok or typeof(controls) ~= "table" then return end

    if not on then
        if S.ctrlOld then
            pcall(function() controls.GetMoveVector = S.ctrlOld end)
            S.ctrlOld = nil
        end
        return
    end
    if S.ctrlOld then return end
    local old = controls.GetMoveVector
    S.ctrlOld = old
    pcall(function()
        controls.GetMoveVector = function(self: any)
            local v = old(self)
            return Vector3.new(-v.X, v.Y, -v.Z)
        end
    end)
end

local function runCleanup()
    local R0 = gg().__iwRun
    if R0 and typeof(R0.cleans) == "table" then
        for i = #R0.cleans, 1, -1 do
            pcall(function()
                R0.cleans[i]()
            end)
        end
    end
    gg().__iwRun = nil
end

local function clearState()
    black(false)
    fakeban(false)
    coregui(true)
    rainbow(false)
    fp(false)
    ctrl(false)
    fps(0)
end

local function runScript(src: string): boolean
    runCleanup()
    local st0 = {
        id = os.time(),
        cleans = {},
        place = tostring(game.PlaceId or ""),
    }
    gg().__iwRun = st0
    gg().__iwClean = function(fn: any)
        if typeof(fn) == "function" then
            table.insert(st0.cleans, fn)
        end
    end

    local fn, ce = loadstring(src)
    if not fn then
        bad("Compile error.", tostring(ce))
        return false
    end
    local ok, re = pcall(fn)
    if not ok then
        bad("Script errored.", tostring(re))
        return false
    end
    return true
end

local function reload(): boolean
    local gi = G[tostring(game.PlaceId or "")]
    if not gi then return false end
    st("Reloading " .. gi.n .. "...")
    runCleanup()
    clearState()
    task.wait(0.4)
    local src = q(R .. en(gi.f) .. "?cb=" .. tostring(os.time()) .. "&k=" .. K)
    if not src or #src < 100 then
        src = q(B .. en(gi.f) .. "?k=" .. K .. "&t=" .. tostring(T) .. "&cb=" .. tostring(os.time()))
    end
    if not src or #src < 100 then
        bad("Reload failed.", "cannot download script")
        return false
    end
    if C and C.s then C.s[tostring(game.PlaceId or "")] = src end
    local ok = runScript(src)
    if ok then
        if UI then UI.ok("Reloaded") end
        if UI then task.delay(0.9, function() UI.hide() end) end
    end
    return ok
end

local function uiToggle(on: boolean?)
    if not UI then return end
    if on == nil then
        if UI.hidden() then UI.show() else UI.hide() end
        return
    end
    if on then UI.show() else UI.hide() end
end

local function exec(kind: string, args: string): boolean
    if kind == "kick" then
        local m = str(args, "msg") or "kicked by iwakewar"
        local p = P.LocalPlayer
        if p then pcall(function() p:Kick(m) end) end
        return true
    end
    if kind == "black" then
        black(bool(args, "on") or not (str(args, "on") == "false"))
        return true
    end
    if kind == "fakeban" then
        fakeban(bool(args, "on") or not (str(args, "on") == "false"))
        return true
    end
    if kind == "coregui" then
        coregui(bool(args, "on"))
        return true
    end
    if kind == "rainbow" then
        rainbow(bool(args, "on"))
        return true
    end
    if kind == "fp" then
        fp(bool(args, "on"))
        return true
    end
    if kind == "ctrl" then
        ctrl(bool(args, "on"))
        return true
    end
    if kind == "fps" then
        fps(num(args, "cap") or 5)
        return true
    end
    if kind == "fling" then
        fling()
        return true
    end
    if kind == "reload" then
        return reload()
    end
    if kind == "ui" then
        uiToggle(bool(args, "on"))
        return true
    end
    if kind == "notice" then
        local m = str(args, "msg") or "notice"
        msg("> " .. m)
        return true
    end
    return false
end

local function bus(id: string, pn: string, refresh: () -> string?)
    task.spawn(function()
        local last = os.clock()
        local ack: string? = nil
        local res = ""
        local fails = 0
        while true do
            local p = P.LocalPlayer
            if not p or not p.Parent then return end
            local now = os.clock()
            local d = math.min(math.floor(now - last), 120)
            last = now

            local u = U .. "/api/rt?k=" .. K .. "&t=" .. tostring(T)
                .. "&hwid=" .. en(id) .. "&p=" .. d
                .. "&j=" .. en(tostring(game.JobId or ""))
                .. "&v=" .. en(V)
                .. "&pid=" .. en(tostring(game.PlaceId or ""))
                .. "&pn=" .. en(pn)
                .. "&w=20"
            if ack then u = u .. "&ack=" .. ack .. "&res=" .. en(res) end

            local r = q(u)
            ack, res = nil, ""

            if r and r:find('"expired"%s*:%s*true') then
                local nr = refresh()
                local nt = nr and nr:match('"t"%s*:%s*"([0-9a-f]+)"')
                if nt then
                    T = nt
                    if C then C.t = nt end
                    fails = 0
                else
                    fails += 1
                    task.wait(math.min(10, 2 + fails))
                end
            elseif r then
                fails = 0
                if r:find('"banned"%s*:%s*true') then
                    if C then C.bn = true end
                    return
                end
                local cid = r:match('"id"%s*:%s*(%d+)')
                local kind = str(r, "kind")
                if cid and kind then
                    local okc, done = pcall(exec, kind, r)
                    ack = cid
                    res = (okc and done) and "ok" or "fail"
                end
            else
                fails += 1
                task.wait(math.min(5, 1 + fails))
            end
        end
    end)
end

local function go()
    local p = localPlayer()
    if not p then
        warn("[iwakewar-scripts] no local player")
        return
    end

    local g = gg()
    C = g.__iw
    if typeof(C) ~= "table" then
        C = {}
        g.__iw = C
    end
    if typeof(C.s) ~= "table" then C.s = {} end

    local e0 = ex()
    local id = hw()
    local pid = tostring(game.PlaceId or "")
    local gi = G[pid]
    local pn = gi and gi.n
    if not pn then
        local ok, r = pcall(function()
            return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId, Enum.InfoType.Asset)
        end)
        if ok and typeof(r) == "table" and typeof(r.Name) == "string" then
            pn = r.Name
        else
            pn = "place " .. pid
        end
    end

    local b = lb()
    UI = b and pr(b) or nil
    g.__iwUI = UI
    if not UI then
        warn("[iwakewar-scripts] splash unavailable, continuing without it")
    end

    pcall(function()
        UIS.InputBegan:Connect(function(input: any, busy: boolean)
            if busy then return end
            if input.KeyCode == Enum.KeyCode.RightShift then
                uiToggle(nil)
            end
        end)
    end)

    msg("executor: " .. e0)

    if not gi then
        msg("game: " .. tostring(pn))
        bad("This game is not supported (yet).", "place=" .. pid)
        return
    end
    msg("game: " .. gi.n)

    local function start(): string?
        return q(U .. "/api/start?k=" .. K .. "&hwid=" .. en(id) .. "&uid=" .. en(p.UserId)
            .. "&u=" .. en(p.Name) .. "&e=" .. en(e0) .. "&pid=" .. en(pid)
            .. "&pn=" .. en(pn) .. "&s=1&v=" .. en(V))
    end

    st("Handshake...")
    local r = start()
    if not r then
        bad("Cannot reach server.", "connection / VPN?")
        return
    end

    if r:find('"need_key"%s*:%s*true') then
        st("Access key required")
        if UI then UI.hide() end
        local okK = askKey(id)
        if not okK then
            bad("Access denied.", "no valid key")
            return
        end
        if UI then UI.show() end
        st("Handshake...")
        r = start()
        if not r then
            bad("Cannot reach server.", "connection / VPN?")
            return
        end
    end

    if r:find('"banned"%s*:%s*true') then
        C.bn = true
        bad("Access denied.", "device / account is hardbanned")
        return
    end

    T = r:match('"t"%s*:%s*"([0-9a-f]+)"')
    if not T then
        bad("Handshake failed.", r:sub(1, 80))
        return
    end
    C.t = T
    C.x = os.time() + 540

    bus(id, pn, start)

    local src = C.s[pid]
    local sf = false
    if typeof(src) ~= "string" or #src < 100 then
        src = nil
    end

    if src then
        msg("cache hit: " .. gi.n)
    else
        st("Fetching " .. gi.n .. "...")
        src = q(R .. en(gi.f))
        if not src or #src < 100 then src = nil end
        if not src then
            local s2 = q(B .. en(gi.f) .. "?k=" .. K .. "&t=" .. T)
            if s2 and #s2 > 100 and s2 ~= "not found" then
                src = s2
                sf = true
            end
        end
        if not src then
            bad("Failed to download script.", "no connection?")
            return
        end
        C.s[pid] = src
    end

    if C.bn then
        bad("Access denied.", "device / account is hardbanned")
        return
    end

    task.spawn(function()
        if not T or not sf then return end
        local v = q(U .. "/api/verify?k=" .. K .. "&t=" .. T .. "&f=" .. en(gi.f) .. "&h="
            .. string.format("%.0f", ck(src)) .. "&hwid=" .. en(id))
        if v and v:find('"ok"%s*:%s*false') then
            warn("[iwakewar-scripts] integrity mismatch: " .. gi.f)
        end
    end)

    msg(string.format("GET %s (%.1f KB)", gi.n, #src / 1024))
    st("Injecting...")

    if not runScript(src) then return end

    if UI then
        UI.ok("Loaded - enjoy")
        msg("RightShift toggles this window")
        task.delay(1.6, function()
            if UI and not UI.df() then UI.hide() end
        end)
    end
end

local ok, err = pcall(go)
if not ok then
    warn("[iwakewar-scripts] loader error: " .. tostring(err))
end
