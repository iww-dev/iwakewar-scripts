local P = game:GetService("Players")
local U = "https://iwakewar.fun"
local K = "5c03f42e392c0f1bbe531eb23315ecc1b452b0587d17024e"
local B = U .. "/scripts/"
local R = "https://raw.githubusercontent.com/iww-dev/iwakewar-scripts/main/"

local G = {
    ["6520999642"] = { n = "Basically FNF: Remix", f = "BFNFR Auto-Play.luau" },
    ["6447798030"] = { n = "Funky Friday", f = "FunkyFriday Auto-Play.luau" },
    ["71106427459865"] = { n = "Игра в Слова", f = "WordGame Auto-Play.luau" },
    ["537413528"] = { n = "Build A Boat For Treasure", f = "BABFT.luau" },
    ["93466613073564"] = { n = "Scoped FPS", f = "UnAim.luau" },
    ["114689356953798"] = { n = "Scoped FPS", f = "UnAim.luau" },
}

local T: string? = nil

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

local function sp()
    local p = P.LocalPlayer
    if not p then return nil end
    local pg = p:FindFirstChildOfClass("PlayerGui") or p:WaitForChild("PlayerGui", 10)
    if not pg then return nil end

    local C = Color3.fromRGB
    local F = Enum.Font.Code
    local TX = C(220, 220, 220)
    local DM = C(140, 140, 140)
    local GN = C(0, 255, 0)
    local RD = C(255, 60, 60)
    local LN = C(70, 70, 70)

    local sg = Instance.new("ScreenGui")
    sg.Name = "iwakewar-scripts"
    sg.DisplayOrder = 999
    sg.IgnoreGuiInset = true
    sg.ResetOnSpawn = false
    sg.Parent = pg

    local w = Instance.new("Frame")
    w.AnchorPoint = Vector2.new(0.5, 0.5)
    w.Position = UDim2.fromScale(0.5, 0.5)
    w.Size = UDim2.fromOffset(470, 300)
    w.BackgroundColor3 = C(16, 16, 16)
    w.BorderSizePixel = 0
    w.Parent = sg

    local st = Instance.new("UIStroke")
    st.Color = LN
    st.Thickness = 1
    st.Parent = w

    local ac = Instance.new("Frame")
    ac.Size = UDim2.new(1, 0, 0, 2)
    ac.BackgroundColor3 = GN
    ac.BorderSizePixel = 0
    ac.Parent = w

    local ti = Instance.new("TextLabel")
    ti.BackgroundTransparency = 1
    ti.Font = F
    ti.Position = UDim2.new(0, 12, 0, 8)
    ti.Size = UDim2.new(1, -24, 0, 22)
    ti.Text = "> iwakewar-scripts_"
    ti.TextColor3 = TX
    ti.TextSize = 17
    ti.TextXAlignment = Enum.TextXAlignment.Left
    ti.Parent = w

    local sb = Instance.new("TextLabel")
    sb.BackgroundTransparency = 1
    sb.Font = F
    sb.Position = UDim2.new(0, 12, 0, 28)
    sb.Size = UDim2.new(1, -24, 0, 14)
    sb.Text = "[loader v3]"
    sb.TextColor3 = C(0, 180, 0)
    sb.TextSize = 12
    sb.TextXAlignment = Enum.TextXAlignment.Left
    sb.Parent = w

    local ln = Instance.new("Frame")
    ln.BackgroundColor3 = LN
    ln.BorderSizePixel = 0
    ln.Position = UDim2.new(0, 12, 0, 48)
    ln.Size = UDim2.new(1, -24, 0, 1)
    ln.Parent = w

    local co = Instance.new("Frame")
    co.BackgroundColor3 = C(5, 5, 5)
    co.BorderSizePixel = 0
    co.Position = UDim2.new(0, 12, 0, 54)
    co.Size = UDim2.new(1, -24, 0, 170)
    co.Parent = w

    local cs = Instance.new("UIStroke")
    cs.Color = C(50, 50, 50)
    cs.Thickness = 1
    cs.Parent = co

    local cp = Instance.new("UIPadding")
    cp.PaddingLeft = UDim.new(0, 8)
    cp.PaddingRight = UDim.new(0, 8)
    cp.PaddingTop = UDim.new(0, 6)
    cp.Parent = co

    local cl = Instance.new("UIListLayout")
    cl.FillDirection = Enum.FillDirection.Vertical
    cl.Padding = UDim.new(0, 2)
    cl.SortOrder = Enum.SortOrder.LayoutOrder
    cl.Parent = co

    local er = Instance.new("TextLabel")
    er.BackgroundColor3 = C(24, 10, 10)
    er.BorderSizePixel = 0
    er.Font = F
    er.Position = UDim2.new(0, 12, 0, 232)
    er.Size = UDim2.new(1, -24, 0, 30)
    er.Text = ""
    er.TextColor3 = RD
    er.TextSize = 11
    er.TextWrapped = true
    er.TextXAlignment = Enum.TextXAlignment.Left
    er.TextYAlignment = Enum.TextYAlignment.Top
    er.Visible = false
    er.Parent = w

    local bs = Instance.new("TextButton")
    bs.AnchorPoint = Vector2.new(0, 1)
    bs.BackgroundColor3 = C(150, 30, 30)
    bs.BorderSizePixel = 0
    bs.Font = F
    bs.Position = UDim2.new(0, 12, 1, -12)
    bs.Size = UDim2.new(1, -24, 0, 26)
    bs.Text = "Close"
    bs.TextColor3 = C(255, 255, 255)
    bs.TextSize = 13
    bs.Visible = false
    bs.Parent = w
    bs.MouseButton1Click:Connect(function()
        sg:Destroy()
    end)

    local n = 0
    local Hs = {}
    local o: any = {}
    local dn = false

    o.Hs = Hs
    o.gu = sg

    o.log = function(t: string, c: Color3?)
        Hs[#Hs + 1] = { t, c }
        n += 1
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Font = F
        l.Size = UDim2.new(1, 0, 0, 15)
        l.Text = t
        l.TextColor3 = c or DM
        l.TextSize = 12
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextTruncate = Enum.TextTruncate.AtEnd
        l.LayoutOrder = n
        l.Parent = co
        local ks = co:GetChildren()
        if #ks > 12 then
            for _, v in ipairs(ks) do
                if v:IsA("TextLabel") and v.LayoutOrder <= n - 11 then
                    v:Destroy()
                end
            end
        end
    end

    o.status = function(t: string, c: Color3?)
        o.log("> " .. t, c)
    end

    o.fail = function(m: string, d: string?)
        dn = true
        local full = m
        if d and #d > 0 then full = m .. " | " .. d end
        warn("[iwakewar-scripts] " .. full)
        o.log("> " .. m, RD)
        er.Text = full:sub(1, 120)
        er.Visible = true
        bs.Visible = true
    end

    o.ok = function(m: string)
        o.log("> " .. m, GN)
    end

    o.close = function()
        if sg.Parent then sg:Destroy() end
    end

    o.df = function(): boolean
        return dn
    end

    return o
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

local function pr(b: any, Hs: any): any
    local ok, L = pcall(function()
        return b:Loader({
            Title = "iwakewar-scripts",
            Subtitle = "v3.0.0",
            Status = "Booting...",
            Console = true,
            Width = 470,
            CloseDelay = 0.8,
        })
    end)
    if not ok or typeof(L) ~= "table" then return nil end

    local o: any = {}
    local dn = false
    local OC = Color3.fromRGB(148, 219, 168)
    local DC = Color3.fromRGB(139, 139, 150)

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
    end
    o.ok = function(m: string)
        pcall(function() L:Done(m or "Loaded") end)
        pcall(function() L:Log(m or "Loaded", OC) end)
    end
    o.close = function()
        pcall(function() L:Destroy() end)
    end
    o.df = function(): boolean
        return dn
    end
    o.Hs = Hs

    for _, v in ipairs(Hs) do
        pcall(function() L:Log(v[1], v[2]) end)
    end
    pcall(function() L:SetTimeout(30) end)
    return o
end

local function pl(id: string)
    task.spawn(function()
        local last = os.clock()
        while true do
            local p = P.LocalPlayer
            if not p or not p.Parent then return end
            local now = os.clock()
            local d = math.min(math.floor(now - last), 120)
            last = now
            local r = q(U .. "/api/ping?k=" .. K .. "&t=" .. tostring(T) .. "&hwid=" .. en(id) .. "&p=" .. d)
            if r and r:find('"banned"%s*:%s*true') then return end
            task.wait(60)
        end
    end)
end

local function go()
    local p = P.LocalPlayer
    local n = 0
    while not p and n < 20 do
        task.wait(0.5)
        n += 1
        p = P.LocalPlayer
    end

    local D = sp()
    local W: any = {}
    W.k = D
    W.log = function(t: string, c: Color3?)
        if W.k then W.k.log(t, c) end
    end
    W.status = function(t: string, c: Color3?)
        if W.k then W.k.status(t, c) end
    end
    W.fail = function(m: string, d: string?)
        if W.k then W.k.fail(m, d) end
    end
    W.ok = function(m: string)
        if W.k then W.k.ok(m) end
    end
    W.close = function()
        if W.k then W.k.close() end
    end
    W.df = function(): boolean
        if W.k then return W.k.df() end
        return true
    end

    if not p then
        W.fail("No player.")
        return
    end

    local g = gg()
    local C = g.__iw
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

    W.log("executor: " .. e0)

    local t0 = C.t
    if t0 and C.x and C.x > os.time() then
        T = t0
    end

    task.spawn(function()
        local r = q(U .. "/api/start?k=" .. K .. "&hwid=" .. en(id) .. "&uid=" .. en(p.UserId) .. "&u=" .. en(p.Name)
            .. "&e=" .. en(e0) .. "&pid=" .. en(pid) .. "&pn=" .. en(pn) .. "&s=" .. (gi and "1" or "0"))
        if not r then return end
        if r:find('"banned"%s*:%s*true') then
            C.bn = true
            W.fail("Access denied.", "device / account is hardbanned")
            return
        end
        local t = r:match('"t"%s*:%s*"([0-9a-f]+)"')
        if t then
            T = t
            C.t = t
            C.x = os.time() + 540
            pl(id)
        end
    end)

    task.spawn(function()
        local b = lb()
        if not b then return end
        if W.df() then return end
        if D and D.gu and not D.gu.Parent then return end
        local L = pr(b, D and D.Hs or {})
        if not L then return end
        W.k = L
        if D then D.close() end
    end)

    if not gi then
        W.log("game: " .. tostring(pn))
        W.fail("This game is not supported (yet).", "place=" .. pid)
        return
    end
    W.log("game: " .. gi.n)

    local s = C.s[pid]
    local sf = false
    if typeof(s) ~= "string" or #s < 100 then
        s = nil
    end

    if s then
        W.log("cache hit: " .. gi.n)
    else
        W.status("Fetching " .. gi.n .. "...")
        s = q(R .. en(gi.f))
        if not s or #s < 100 then s = nil end
        if not s then
            local w = 0
            while not T and w < 30 do
                task.wait(0.1)
                w += 1
            end
            if T then
                local x = q(B .. en(gi.f) .. "?k=" .. K .. "&t=" .. T)
                if x and #x > 100 and x ~= "not found" then
                    s = x
                    sf = true
                end
            end
        end
        if not s then
            W.fail("Failed to download script.", "no connection?")
            return
        end
        C.s[pid] = s
    end

    if C.bn then
        W.fail("Access denied.", "device / account is hardbanned")
        return
    end

    task.spawn(function()
        local t = T
        if not t or not sf then return end
        local v = q(U .. "/api/verify?k=" .. K .. "&t=" .. t .. "&f=" .. en(gi.f) .. "&h="
            .. string.format("%.0f", ck(s)) .. "&hwid=" .. en(id))
        if v and v:find('"ok"%s*:%s*false') then
            warn("[iwakewar-scripts] integrity mismatch: " .. gi.f)
        end
    end)

    W.log(string.format("GET %s (%.1f KB)", gi.n, #s / 1024))
    W.status("Injecting...")

    local fn, ce = loadstring(s)
    if not fn then
        W.fail("Compile error.", tostring(ce))
        return
    end
    local ok, re = pcall(fn)
    if not ok then
        W.fail("Script errored.", tostring(re))
        return
    end

    W.ok("Loaded - enjoy")
    task.delay(1.4, function()
        if not W.df() then W.close() end
    end)
end

local ok, err = pcall(go)
if not ok then
    warn("[iwakewar-scripts] loader error: " .. tostring(err))
end
