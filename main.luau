-- iwakewar-scripts | loader
-- loadstring(game:HttpGet("https://iwakewar.fun/scripts/main.luau?k=5c03f42e392c0f1bbe531eb23315ecc1b452b0587d17024e"))()

local P = game:GetService("Players")
local U = "https://iwakewar.fun"
local K = "5c03f42e392c0f1bbe531eb23315ecc1b452b0587d17024e"
local B = U .. "/scripts/"

local function su(p: string): string
    return B .. (p:gsub(" ", "%%20"))
end

local G = {
    ["6520999642"] = {
        name = "Basically FNF: Remix",
        file = "BFNFR Auto-Play.luau",
        url = su("BFNFR Auto-Play.luau"),
    },
    ["6447798030"] = {
        name = "Funky Friday",
        file = "FunkyFriday Auto-Play.luau",
        url = su("FunkyFriday Auto-Play.luau"),
    },
    ["71106427459865"] = {
        name = "Игра в Слова",
        file = "WordGame Auto-Play.luau",
        url = su("WordGame Auto-Play.luau"),
    },
    ["537413528"] = {
        name = "Build A Boat For Treasure",
        file = "BABFT.luau",
        url = su("BABFT.luau"),
    },
    ["93466613073564"] = {
        name = "Scoped FPS",
        file = "UnAim.luau",
        url = su("UnAim.luau"),
    },
    ["114689356953798"] = {
        name = "Scoped FPS",
        file = "UnAim.luau",
        url = su("UnAim.luau"),
    },
}

local T: string? = nil -- run ticket from the server

local function en(v: any): string
    return (tostring(v):gsub("[^%w%-%._~]", function(c: string): string
        return string.format("%%%02X", string.byte(c))
    end))
end

local function gv(): any
    local ok, t = pcall(function() return getgenv() end)
    if ok and typeof(t) == "table" then return t end
    return _G
end

local function rq(u: string): string?
    local g = gv()
    local f = (g.syn and g.syn.request) or (g.http and g.http.request) or g.http_request
        or (g.fluxus and g.fluxus.request) or g.request
    if typeof(f) == "function" then
        local ok, r = pcall(f, { Url = u, Method = "GET" })
        if ok then
            if typeof(r) == "table" then return tostring(r.Body or "") end
            if typeof(r) == "string" then return r end
        end
    end
    local ok, r = pcall(function()
        return game:HttpGet(u)
    end)
    if ok and typeof(r) == "string" then return r end
    local ok2, r2 = pcall(function()
        return game:GetService("HttpService"):GetAsync(u)
    end)
    if ok2 and typeof(r2) == "string" then return r2 end
    return nil
end

local function hw(): string
    local ok, v = pcall(function() return gethwid() end)
    if ok and typeof(v) == "string" and #v > 0 then return v end
    local ok2, c = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    if ok2 and typeof(c) == "string" and #c > 0 then return c end
    local p = P.LocalPlayer
    return "uid-" .. tostring(p and p.UserId or 0)
end

local function ex(): string
    local ok, a = pcall(function() return identifyexecutor() end)
    if ok and typeof(a) == "string" and #a > 0 then return a end
    return "unknown"
end

-- integrity digest: must match checksum() in the worker
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

local function fallback()
    local p = P.LocalPlayer
    if not p then return nil end
    local pg = p:FindFirstChildOfClass("PlayerGui") or p:WaitForChild("PlayerGui", 10)
    if not pg then return nil end

    local C = Color3.fromRGB
    local F = Enum.Font.Code
    local TXT = C(220, 220, 220)
    local DIM = C(140, 140, 140)
    local GRN = C(0, 255, 0)
    local RED = C(255, 60, 60)
    local LINE = C(70, 70, 70)

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
    st.Color = LINE
    st.Thickness = 1
    st.Parent = w

    local ac = Instance.new("Frame")
    ac.Size = UDim2.new(1, 0, 0, 2)
    ac.BackgroundColor3 = GRN
    ac.BorderSizePixel = 0
    ac.Parent = w

    local ti = Instance.new("TextLabel")
    ti.BackgroundTransparency = 1
    ti.Font = F
    ti.Position = UDim2.new(0, 12, 0, 8)
    ti.Size = UDim2.new(1, -24, 0, 22)
    ti.Text = "> iwakewar-scripts_"
    ti.TextColor3 = TXT
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
    ln.BackgroundColor3 = LINE
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
    er.TextColor3 = RED
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
    local ui: any = {}
    local dead = false

    ui.log = function(t: string, c: Color3?)
        n += 1
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Font = F
        l.Size = UDim2.new(1, 0, 0, 15)
        l.Text = t
        l.TextColor3 = c or DIM
        l.TextSize = 12
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextTruncate = Enum.TextTruncate.AtEnd
        l.LayoutOrder = n
        l.Parent = co
        local kids = co:GetChildren()
        if #kids > 12 then
            for _, v in ipairs(kids) do
                if v:IsA("TextLabel") and v.LayoutOrder <= n - 11 then
                    v:Destroy()
                end
            end
        end
    end

    ui.status = function(t: string)
        ui.log("> " .. t)
    end

    ui.fail = function(m: string, d: string?)
        dead = true
        local full = m
        if d and #d > 0 then full = m .. " | " .. d end
        warn("[iwakewar-scripts] " .. full)
        ui.log("> " .. m, RED)
        er.Text = full:sub(1, 120)
        er.Visible = true
        bs.Visible = true
    end

    ui.ok = function(m: string)
        ui.log("> " .. m, GRN)
    end

    ui.close = function()
        if sg.Parent then sg:Destroy() end
    end

    ui.didFail = function(): boolean
        return dead
    end

    return ui
end

local LIB = su("gui-lib/PrimordialUI.luau")

local function lib(): any
    local g = gv()
    if typeof(g.__iwPrimordial) == "table" then return g.__iwPrimordial end
    local s = rq(LIB .. "?k=" .. K)
    if not s or #s < 100 then return nil end
    local ok, r = pcall(function()
        return loadstring(s)()
    end)
    if ok and typeof(r) == "table" and typeof(r.Loader) == "function" then
        g.__iwPrimordial = r
        return r
    end
    return nil
end

local function prim(UI: any)
    local ok, L = pcall(function()
        return UI:Loader({
            Title = "iwakewar-scripts",
            Subtitle = "v3.0.0",
            Status = "Booting...",
            Console = true,
            Width = 470,
            CloseDelay = 0.8,
        })
    end)
    if not ok or typeof(L) ~= "table" then return nil end

    local ui: any = {}
    local dead = false
    local OKC = Color3.fromRGB(148, 219, 168)
    local BADC = Color3.fromRGB(214, 94, 103)
    local DIMC = Color3.fromRGB(139, 139, 150)

    ui.log = function(t: string, c: Color3?)
        pcall(function() L:Log(t, c) end)
    end
    ui.status = function(t: string, c: Color3?)
        pcall(function() L:SetStatus(t) end)
        pcall(function() L:Log("> " .. t, c or DIMC) end)
    end
    ui.fail = function(m: string, d: string?)
        dead = true
        local full = m
        if d and #d > 0 then full = m .. "  |  " .. d end
        warn("[iwakewar-scripts] " .. full)
        pcall(function() L:Fail(full:sub(1, 160)) end)
        pcall(function() L:ShowClose() end)
    end
    ui.ok = function(m: string)
        pcall(function() L:Done(m or "Loaded") end)
        pcall(function() L:Log(m or "Loaded", OKC) end)
    end
    ui.close = function()
        pcall(function() L:Destroy() end)
    end
    ui.didFail = function(): boolean
        return dead
    end
    pcall(function() L:SetTimeout(30) end)
    return ui
end

local function makeUI()
    local b = lib()
    if b then
        local p = prim(b)
        if p then return p end
    end
    return fallback()
end

local function loop(id: string, pid: string, pn: string, sup: boolean)
    task.spawn(function()
        local last = os.clock()
        while true do
            local p = P.LocalPlayer
            if not p or not p.Parent then return end
            local now = os.clock()
            local d = math.min(math.floor(now - last), 120)
            last = now
            local r = rq(U .. "/api/ping?k=" .. K .. "&t=" .. tostring(T) .. "&hwid=" .. en(id) .. "&p=" .. d)
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

    local ui = makeUI()
    local function say(t: string)
        if ui then ui.log(t) end
    end

    if not p then
        if ui then ui.fail("No player.") end
        return
    end

    if ui then ui.status("Checking executor...") end
    local e = ex()
    local id = hw()
    local pid = tostring(game.PlaceId or "")
    local gi = G[pid]
    local pn = gi and gi.name
    if not pn then
        local ok, pr = pcall(function()
            return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId, Enum.InfoType.Asset)
        end)
        if ok and typeof(pr) == "table" and typeof(pr.Name) == "string" then
            pn = pr.Name
        else
            pn = "place " .. pid
        end
    end
    say("executor: " .. e)

    if ui then ui.status("Handshake...") end
    local r = rq(U .. "/api/start?k=" .. K .. "&hwid=" .. en(id) .. "&uid=" .. en(p.UserId) .. "&u=" .. en(p.Name)
        .. "&e=" .. en(e) .. "&pid=" .. en(pid) .. "&pn=" .. en(pn) .. "&s=" .. (gi and "1" or "0"))
    if not r then
        if ui then ui.fail("Cannot reach server.", "connection / VPN?") end
        return
    end
    if r:find('"banned"%s*:%s*true') then
        warn("[iwakewar-scripts] access denied: this device / account is hardbanned")
        if ui then ui.fail("Access denied.", "device / account is hardbanned") end
        return
    end
    T = r:match('"t"%s*:%s*"([0-9a-f]+)"')
    if not T then
        if ui then ui.fail("Handshake failed.", r:sub(1, 80)) end
        return
    end
    loop(id, pid, pn, gi ~= nil)

    if not gi then
        say("game: " .. pn)
        if ui then ui.fail("This game is not supported (yet).", "place=" .. pid) end
        return
    end
    say("game: " .. gi.name)

    if ui then ui.status("Fetching " .. gi.name .. "...") end
    local src = rq(gi.url .. "?k=" .. K .. "&t=" .. T)
    if not src or #src < 8 then
        if ui then ui.fail("Failed to download script.") end
        return
    end

    local v = rq(U .. "/api/verify?k=" .. K .. "&t=" .. T .. "&f=" .. en(gi.file) .. "&h=" .. string.format("%.0f", ck(src)) .. "&hwid=" .. en(id))
    if v and v:find('"ok"%s*:%s*false') then
        if ui then ui.fail("Integrity check failed.", "code does not match the server copy") end
        return
    end
    say(string.format("GET %s (%.1f KB)", gi.name, #src / 1024))

    if ui then ui.status("Injecting...") end
    local fn, ce = loadstring(src)
    if not fn then
        if ui then ui.fail("Compile error.", tostring(ce)) end
        return
    end
    local ok, re = pcall(fn)
    if not ok then
        if ui then ui.fail("Script errored.", tostring(re)) end
        return
    end
    if ui then
        ui.ok("Loaded - enjoy")
        task.delay(1.4, function()
            if not ui.didFail() then ui.close() end
        end)
    end
end

local ok, err = pcall(go)
if not ok then
    warn("[iwakewar-scripts] loader error: " .. tostring(err))
end
