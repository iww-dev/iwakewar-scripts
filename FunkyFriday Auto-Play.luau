-- FunkyFriday Auto-Play
-- by iwakewar team
-- Premium auto player for Funky Friday.
--
-- How pressing works (read from the game's own source):
--   FF creates PlayerGui.VSRGContext with InputActions "Lane1".."LaneN"
--   (InputHandler:BindField). InputHandler keeps its own ActionDown[lane]:
--     Pressed  -> if not ActionDown[lane] then ActionDown[lane]=true;
--                 Field:HitLane(lane, true, os.clock())
--     Released -> if ActionDown[lane] then ActionDown[lane]=nil;
--                 Field:HitLane(lane, false, os.clock())
--   So an action must be released before it can be pressed again - otherwise
--   the second Fire(true) is ignored by the game (that was a real source of
--   "sometimes it presses, sometimes it doesn't"). We always fire a clean
--   true -> false pair and never leave a lane down without a real hold.
--
-- How notes are read (VSRG/Core/Note, Lane, Field.Update):
--   Every note is a real Frame in
--       PlayerGui.Window.Game.Fields.<Side>.Inner.LaneN.Notes
--   Frame.Name = note.Index (unique per chart note).
--   Frame.Position = Spline:GetPoint(1 - (Time - songTime)/playback/RenderTime)
--   and the spline is linear in that parameter, so the note's centre moves at
--   constant speed towards the receptor: hit time == centre crosses the
--   receptor centre.
--   A note Frame has children:
--       Sprite.Frame  - the arrow head (AnchorPoint 0,0)
--       Streak.Frame  - the hold tail (AnchorPoint 0.5,1)
--   The tail is created ONLY when note.Length > 0, so:
--       has tail child  -> HOLD
--       no tail child   -> TAP
--   Note visuals are pooled and Frames are reused (SpriteHandler), so state
--   is keyed by Frame.Name, never by the Frame object alone.
--
-- When to press / hold / release:
--   TAP   : Fire(true) when the head centre reaches the receptor, Fire(false)
--           after a human-like random hold of 5.4-13.7 ms (the release only
--           clears ActionDown).
--   HOLD  : Fire(true) at the head, keep it down. The game freezes the head
--           on the receptor, hides it (Sprite.Frame.Visible = false) and
--           shrinks the tail (Field.Update, CanMove = false). Release when
--           the tail height reaches 0 == note.Time + note.Length. Releasing
--           at >= 80% of Length already gives the full 100 release score.
--
-- Judgement (Configs VSRG + Lane:Hit):
--   HitWindow = 200 ms, DeathNoteHitWindow = 50 ms.
--   acc = clamp((1000 - |HitMS|)/10, 0, 100);  acc >= 95 -> 100
--   |HitMS| <=  50 ms -> Sick (100)
--   |HitMS|  50..100  -> Good (95..90)
--   |HitMS| 100..150  -> Ok   (90..85)
--   |HitMS| 150..200  -> Bad  (85..80)
--   >200 ms           -> Miss  (and every press with no note inside 200 ms
--                                is also recorded as a Miss - no spam!)
--   Death / Poison need |HitMS| <= 50 AND accuracy == 100 -> always aim exact.
--   Hold total = headAccuracy*0.75 + releaseScore*0.25.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local plr = Players.LocalPlayer
local pg = plr.PlayerGui

local genv0 = getgenv()

-- one live instance only: stop the previous run first. Its Heartbeat loop would
-- otherwise keep pressing/releasing the same lanes under the new copy, which is
-- exactly what breaks holds and makes presses look instant.
if type(genv0.__funkyfridayCleanup) == "function" then
  pcall(genv0.__funkyfridayCleanup)
end
local INSTANCE = {}
genv0.__funkyfridayInstance = INSTANCE

if genv0.__funkyfridayGUI and type(genv0.__funkyfridayGUI.Destroy) == "function" then
  pcall(function() genv0.__funkyfridayGUI:Destroy() end)
end

-- GUI loader: our own gui-lib/PrimordialUI.luau (flat dark "primordial" style).
-- If it cannot be downloaded - silently fall back to WindUI so the script never dies.
local LIB_URL = "https://raw.githubusercontent.com/iww-dev/iwakewar-scripts/refs/heads/main/gui-lib/PrimordialUI.luau"
local WINDUI_URL = "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
local GUI
do
  local ok, res = pcall(function()
    return loadstring(game:HttpGet(LIB_URL))()
  end)
  if ok and type(res) == "table" and type(res.CreateWindow) == "function" then
    GUI = res
  else
    warn("[FunkyFriday] PrimordialUI failed to load (" .. tostring(res) .. "), falling back to WindUI")
    GUI = loadstring(game:HttpGet(WINDUI_URL))()
    GUI.__fallback = true
  end
end
genv0.__funkyfridayGUI = GUI

local isPhone = UIS.TouchEnabled and not UIS.KeyboardEnabled

local Window = GUI:CreateWindow({
    Title = "iwakewar: Funky Friday",
    Subtitle = "by iwakewar team",
    Footer = "by iwakewar team",
    Version = "v2.1.2 (v2.1-patch2)",
    Folder = "iwakewar-funkyfriday",
    Icon = "music",
    Theme = "Rose",
    Size = UDim2.fromOffset(760, 500),
    ToggleKey = Enum.KeyCode.RightShift,
    Topbar = { Height = 40, ButtonsType = "Default" },
    OpenButton = { Enabled = true, Draggable = true, OnlyMobile = true, Scale = 1.1, CornerRadius = UDim.new(0, 6) },
})
GUI._selfUrl = "https://raw.githubusercontent.com/iww-dev/iwakewar-scripts/refs/heads/main/FunkyFriday%20Auto-Play.luau"

local Tabs = {
    Info = Window:Tab({ Title = "Info", Subtitle = "About the script", Icon = "sfsymbols:info.circle", Border = true }),
    Main = Window:Tab({ Title = "Controls", Subtitle = "Auto-play settings", Icon = "sfsymbols:gamecontroller", Border = true }),
}
pcall(function() Window:SelectTab(1) end)

-- mobile floating toggle (always visible)
if isPhone then
  pcall(function() game:GetService("CoreGui").FunkyFridayToggle:Destroy() end)
  local sg = Instance.new("ScreenGui")
  sg.Name = "FunkyFridayToggle" sg.ResetOnSpawn = false
  pcall(function() sg.Parent = game:GetService("CoreGui") end)
  if sg.Parent == nil then sg.Parent = pg end
  local b = Instance.new("TextButton")
  b.Size = UDim2.fromOffset(40, 40)
  b.Position = UDim2.new(0.5, -20, 0.5, -260)
  b.Text = "F" b.TextSize = 18
  b.BackgroundColor3 = Color3.fromRGB(30, 32, 40) b.TextColor3 = Color3.new(1, 1, 1)
  b.Parent = sg
  local cc = Instance.new("UICorner") cc.CornerRadius = UDim.new(0, 8) cc.Parent = b
  local glow = Instance.new("UIStroke")
  glow.Thickness = 2 glow.Color = Color3.fromRGB(0, 220, 255) glow.Transparency = 0.2
  glow.Parent = b
  task.spawn(function()
    while b.Parent do
      pcall(function()
        TweenService:Create(glow, TweenInfo.new(0.8), { Transparency = 0.7 }):Play()
        task.wait(0.85)
        TweenService:Create(glow, TweenInfo.new(0.8), { Transparency = 0.2 }):Play()
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
      local d = i.Position - ds moved = d.Magnitude
      b.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
    end
  end)
  b.Activated:Connect(function()
    if moved < 12 then pcall(function() Window:Toggle() end) end
  end)
end

-- ================================================================= state
local enabled = false
local antiAfk = true
local noNotifications = false
local presses = 0
local holdsFired = 0
local tapsFired = 0
local retries = 0
local lastJump = 0

local TAP_HOLD_MIN = 0.0054       -- s, shortest human key press
local TAP_HOLD_MAX = 0.0137       -- s, longest human key press
local VERIFY_DELAY = 0.025       -- s, check that the press actually landed
local RETRY_PAST = 0.14          -- s, do not retry a note that is already too late
local PRESS_LEAD = 0.060         -- s, start scheduling presses this early
local HOLD_TIMEOUT = 12          -- s, hard release safety

-- Accuracy modes: Funky Friday tiers
local MODE_MIX, MODE_NEVER, MODE_ALWAYS = "mix", "never", "always"
local mode = MODE_MIX
local mixChance = 0.60           -- fraction of notes aimed at exact 100

-- aim offsets in ms, positive = press early (note above the receptor)
local GOOD_MIN_MS = 55           -- >= ~94.5% accuracy, still not Sick
local GOOD_MAX_MS = 95           -- ~90.5%, inside the 200 ms window

-- ================================================================= helpers
local function copyToClipboard(text)
    local genv = getgenv and getgenv() or {}
    for _, name in ipairs({ "writeclipboard", "clipboard", "setclipboard", "toclipboard" }) do
        local v = genv[name]
        if v == nil then v = rawget(_G, name) end
        if typeof(v) == "function" then
            if pcall(v, text) then return true end
        end
    end
    return false
end

local function notify(title, content, duration)
    if noNotifications then return end
    pcall(function()
        GUI:Notify({ Title = title, Content = content, Duration = duration })
    end)
end

-- =============================================================== discovery
local sideCache, sideCacheAt = nil, 0

local function findSide()
    local map = workspace:FindFirstChild("Map")
    local stages = map and map:FindFirstChild("Stages")
    if not stages then return nil end
    for _, st in ipairs(stages:GetChildren()) do
        local wss = st:FindFirstChild("Workspaces")
        if wss then
            for _, w in ipairs(wss:GetChildren()) do
                if w:FindFirstChild(plr.Name) then
                    return (w.Name:gsub("_%d+$", "")), w
                end
            end
        end
    end
    return nil
end

local function getSide()
    if sideCache and os.clock() - sideCacheAt < 2 then return sideCache end
    local ok, side, ws = pcall(findSide)
    if ok and side then
        sideCache, sideCacheAt = side, os.clock()
        return side, ws
    end
    sideCache = nil
    return nil
end

local function getFieldsRoot()
    local w = pg:FindFirstChild("Window")
    local g = w and w:FindFirstChild("Game")
    return g and g:FindFirstChild("Fields")
end

local function fieldHasNotes(f)
    local inner = f:FindFirstChild("Inner")
    if not inner then return false end
    for i = 1, 5 do
        local l = inner:FindFirstChild("Lane" .. i)
        local nf = l and l:FindFirstChild("Notes")
        if nf and #nf:GetChildren() > 0 then return true end
    end
    return false
end

local function getField()
    local fields = getFieldsRoot()
    if not fields then return nil end
    local side = getSide()
    local f = side and fields:FindFirstChild(side)
    if f and f:FindFirstChild("Inner") then return f, side end
    for _, c in ipairs(fields:GetChildren()) do
        if fieldHasNotes(c) then return c, side or c.Name end
    end
    return nil, side
end

local function getConfig(ws)
    if not ws then return nil end
    return ws:FindFirstChild(plr.Name)
end

-- ================================================================ engine
local ctx = nil
local field = nil
local fieldSide = nil
local lanes = {}            -- [lane] = { frame, notes, receptor }
local actions = {}          -- [lane] = InputAction
local noteState = {}        -- [Frame] = { uid, samples, phase, attempt, aim, head, tail }
local imageSeen = {}        -- [lane] = { [imageId] = count }
local laneDown = {}         -- [lane] = true while the InputAction is held
local lanePressAt = {}      -- [lane] = os.clock() of the press
local holds = {}            -- [lane] = { note, tail, at, limit }
local pending = {}          -- scheduled presses

local function fire(lane, state)
    local act = actions[lane]
    if not act then return false end
    return (pcall(function() act:Fire(state) end))
end

-- real presses are never instant: hold the key for a random human duration
local function randomHoldDuration()
    return TAP_HOLD_MIN + math.random() * (TAP_HOLD_MAX - TAP_HOLD_MIN)
end

local function releaseLane(lane)
    if laneDown[lane] then
        laneDown[lane] = nil
        fire(lane, false)
    end
end

local function releaseAll()
    for lane in pairs(laneDown) do releaseLane(lane) end
    holds = {}
    pending = {}
end

-- registered for the next run: kills this run before a new copy starts
genv0.__funkyfridayCleanup = function()
    if genv0.__funkyfridayInstance ~= INSTANCE then return end
    enabled = false
    pcall(releaseAll)
    if GUI and type(GUI.Destroy) == "function" then
        pcall(function() GUI:Destroy() end)
    end
end

-- head = arrow frame (AnchorPoint ~0,0), tail = hold streak (AnchorPoint 0.5,1)
local function noteParts(n)
    local head, tail = nil, nil
    for _, c in ipairs(n:GetChildren()) do
        if c:IsA("Frame") then
            if c.AnchorPoint.Y >= 0.5 then
                tail = c
            else
                head = head or c
            end
        end
    end
    return head, tail
end

local function noteHeadImage(n, head)
    head = head or select(1, noteParts(n))
    if not head then return nil end
    local img = head:FindFirstChildWhichIsA("ImageLabel", true)
    return img and img.Image or nil
end

local function pickAimMs(lane, n, head)
    local img = noteHeadImage(n, head)
    if not img then return 0 end
    local seen = imageSeen[lane]
    if not seen then return 0 end
    local count = seen[img] or 0
    seen[img] = count + 1
    -- Unknown/rare sprite = Death / Poison / Mechanic note. Always aim exact.
    if count < 3 then return 0 end
    if mode == MODE_ALWAYS then return 0 end
    if mode == MODE_NEVER then return math.random(GOOD_MIN_MS, GOOD_MAX_MS) end
    if math.random() < mixChance then return 0 end
    return math.random(GOOD_MIN_MS, GOOD_MAX_MS)
end

local function doPress(lane, n, st)
    if not enabled then return end
    if not n.Parent or not n.Visible then st.phase = "done" return end
    if holds[lane] then st.phase = "done" return end
    local head = st.head
    if head and not head.Visible then st.phase = "done" return end

    -- always start from a clean released state: InputHandler ignores Pressed
    -- while its own ActionDown[lane] is still true.
    if laneDown[lane] then releaseLane(lane) end
    if not fire(lane, true) then st.phase = "done" return end

    laneDown[lane] = true
    lanePressAt[lane] = os.clock()
    st.phase = "pressed"
    presses = presses + 1
    st.pressCount = (st.pressCount or 0) + 1
    if st.pressCount == 1 then tapsFired = tapsFired + 1 end

    local wasHold = st.tail ~= nil
    local tailRef = st.tail

    -- TAP: don't release instantly - a human key press lasts ~5.4-13.7 ms.
    if not wasHold then
        local pressAt = lanePressAt[lane]
        task.delay(randomHoldDuration(), function()
            if not enabled then return end
            if lanePressAt[lane] ~= pressAt then return end
            if holds[lane] then return end
            releaseLane(lane)
        end)
    end

    task.delay(VERIFY_DELAY, function()
        if not enabled then return end
        if st.phase ~= "pressed" then return end

        local headNow, tailNow = noteParts(n)
        local gone = (n.Parent == nil)
        local hit = gone or (headNow ~= nil and not headNow.Visible)

        if hit then
            st.phase = "done"
            if wasHold and (tailNow or tailRef) then
                -- hold started: keep the lane down, release at the tail end
                local tail = tailNow or tailRef
                local h = { note = n, tail = tail, at = os.clock(), limit = HOLD_TIMEOUT }
                -- estimate Length from tail pixels / note pixels-per-second
                local vy = st.lastVy
                if vy and vy > 30 and tail and tail.AbsoluteSize.Y > 0 then
                    h.limit = math.min(HOLD_TIMEOUT, tail.AbsoluteSize.Y / vy + 0.8)
                end
                holds[lane] = h
                holdsFired = holdsFired + 1
            else
                releaseLane(lane)
            end
        else
            -- the press never reached the game: release and try once more
            releaseLane(lane)
            retries = retries + 1
            local eta = st.lastEta or 0
            if not st.retried and eta > -RETRY_PAST then
                st.retried = true
                st.phase = "wait"
                st.samples = {}
                st.lastVy = nil
            else
                st.phase = "done"
            end
        end
    end)
end

local function updateHolds()
    local now = os.clock()
    for lane, h in pairs(holds) do
        local n, tail = h.note, h.tail
        local done = false
        if not n or not n.Parent then
            done = true
        elseif not tail or not tail.Parent then
            done = true
        elseif not tail.Visible then
            done = true
        elseif tail.AbsoluteSize.Y <= 1 then
            done = true
        elseif now - h.at > (h.limit or HOLD_TIMEOUT) then
            done = true
        end
        if done then
            holds[lane] = nil
            releaseLane(lane)
        end
    end
end

local function bindField()
    field, fieldSide = getField()
    ctx = pg:FindFirstChild("VSRGContext")
    lanes, actions = {}, {}
    noteState = {}
    imageSeen = {}
    holds, pending = {}, {}
    for lane in pairs(laneDown) do fire(lane, false) end
    laneDown = {}
    if not field then return false end
    local inner = field:FindFirstChild("Inner")
    for i = 1, 5 do
        local laneFrame = inner:FindFirstChild("Lane" .. i)
        if laneFrame then
            lanes[i] = {
                frame = laneFrame,
                notes = laneFrame:FindFirstChild("Notes"),
                receptor = laneFrame:FindFirstChild("Receptor"),
            }
            actions[i] = ctx and ctx:FindFirstChild("Lane" .. i)
            imageSeen[i] = {}
        end
    end
    return true
end

local function unloadField()
    releaseAll()
    field, fieldSide = nil, nil
    ctx = nil
    lanes, actions = {}, {}
    noteState = {}
    imageSeen = {}
end

local function laneAlive()
    if not field or not field.Parent then return false end
    if not ctx or not ctx.Parent then return false end
    for i = 1, 5 do
        local l = lanes[i]
        if l and l.notes and l.notes.Parent then return true end
    end
    return false
end

-- Returns ETA (seconds until the head centre crosses the receptor centre) and
-- the note's vertical speed. Motion is linear so two samples are enough; we
-- keep a few for stability against frame quantisation.
local function sampleEta(st, y, recY, now)
    table.insert(st.samples, { y = y, t = now })
    while #st.samples > 5 do table.remove(st.samples, 1) end
    if #st.samples < 2 then return nil, nil end

    local a = st.samples[1]
    local b = st.samples[#st.samples]
    local dt = b.t - a.t
    if dt < 0.012 then return nil, nil end

    local vy = (b.y - a.y) / dt
    if math.abs(vy) < 25 then return nil, nil end
    return (recY - y) / vy, vy
end

local function stepField()
    if not laneAlive() then
        if not bindField() then return end
        if not laneAlive() then return end
    end

    updateHolds()

    local now = os.clock()

    -- scheduled presses (deal with them before sampling)
    for i = #pending, 1, -1 do
        local p = pending[i]
        if now >= p.at then
            table.remove(pending, i)
            if enabled and p.note.Parent and p.st.phase == "armed" then
                doPress(p.lane, p.note, p.st)
            end
        end
    end

    -- watchdog: never leave a lane down without a real hold
    for lane in pairs(laneDown) do
        if not holds[lane] and now - (lanePressAt[lane] or 0) > 0.4 then
            releaseLane(lane)
        end
    end

    for lane = 1, 5 do
        local info = lanes[lane]
        if info and info.notes and info.notes.Parent and not holds[lane] and not laneDown[lane] then
            local receptor = info.receptor
            local recY = receptor
                and (receptor.AbsolutePosition.Y + receptor.AbsoluteSize.Y / 2)
                or (info.frame.AbsolutePosition.Y + info.frame.AbsoluteSize.Y / 2)

            local best, bestSt, bestEta = nil, nil, nil
            for _, n in ipairs(info.notes:GetChildren()) do
                if n:IsA("Frame") and n.Visible then
                    local st = noteState[n]
                    if not st or st.uid ~= n.Name then
                        local head0, tail0 = noteParts(n)
                        st = {
                            uid = n.Name,
                            lane = lane,
                            samples = {},
                            phase = "wait",
                            attempt = 0,
                            head = head0,
                            tail = tail0,
                            aim = pickAimMs(lane, n, head0) / 1000,
                        }
                        noteState[n] = st
                    end

                    if st.phase ~= "done" then
                        local head = st.head
                        if head and head.Visible then
                            local y = n.AbsolutePosition.Y + n.AbsoluteSize.Y / 2
                            local eta, vy = sampleEta(st, y, recY, now)
                            if eta then
                                st.lastEta = eta
                                st.lastVy = vy
                                if not bestEta or eta < bestEta then
                                    best, bestSt, bestEta = n, st, eta
                                end
                            end
                        else
                            st.phase = "done"
                        end
                    end
                end
            end

            if best and bestSt and bestSt.phase == "wait" then
                if bestEta < -0.20 then
                    bestSt.phase = "done"      -- already out of the window
                elseif bestEta <= PRESS_LEAD then
                    bestSt.phase = "armed"
                    local delay = bestEta - bestSt.aim
                    if delay <= 0.004 then
                        doPress(lane, best, bestSt)
                    else
                        pending[#pending + 1] = { at = now + delay, lane = lane, note = best, st = bestSt }
                    end
                end
            end
        end
    end
end

-- debug helpers for a live session
genv0.__ffDebug = function()
    local down = {}
    for lane in pairs(laneDown) do down[#down + 1] = lane end
    local hs = {}
    for lane, h in pairs(holds) do
        hs[#hs + 1] = string.format("%d:%s", lane, h.tail and tostring(math.floor(h.tail.AbsoluteSize.Y)) or "?")
    end
    return {
        enabled = enabled,
        side = fieldSide,
        presses = presses,
        taps = tapsFired,
        holds = holdsFired,
        retries = retries,
        down = table.concat(down, ","),
        holding = table.concat(hs, " "),
        pending = #pending,
    }
end

genv0.__ffProbe = function()
    local res = { side = fieldSide, lanes = {} }
    for lane = 1, 5 do
        local info = lanes[lane]
        if info and info.notes then
            local rec = info.receptor
            local recY = rec and (rec.AbsolutePosition.Y + rec.AbsoluteSize.Y / 2)
            local list = {}
            for _, n in ipairs(info.notes:GetChildren()) do
                local head, tail = noteParts(n)
                list[#list + 1] = string.format(
                    "%s y=%.1f vis=%s head=%s tail=%s[%s]",
                    n.Name,
                    n.AbsolutePosition.Y + n.AbsoluteSize.Y / 2,
                    tostring(n.Visible),
                    tostring(head and head.Visible),
                    tostring(tail ~= nil),
                    tail and tostring(math.floor(tail.AbsoluteSize.Y)) or "-"
                )
            end
            res.lanes[lane] = { recY = recY, notes = table.concat(list, " || ") }
        end
    end
    return res
end

-- ==================================================================== GUI
local MainSection = Tabs.Main:Section({ Title = "Main Functions" })

local Status = Tabs.Main:Paragraph({
    Title = "Status",
    Content = "Idle - waiting for a match...",
})
local Live = Tabs.Main:Paragraph({
    Title = "Live",
    Content = "state: OFF | side: - | lanes: - | hits: 0",
})

Tabs.Main:Paragraph({
    Title = "Playfield",
    Content = "Auto-detect: PlayerGui.Window.Game.Fields.<YourSide> (no side pick needed)",
})

Tabs.Main:Toggle({
    Title = "Auto-Play",
    Description = "Toggle automatic lane presses",
    Default = false,
    Callback = function(state)
        enabled = state
        if not enabled then
            releaseAll()
            unloadField()
        end
        notify("FunkyFriday Auto-Play", enabled and "Auto-Play enabled" or "Auto-Play disabled", 2)
    end,
})

Tabs.Main:Section({ Title = "Humanizer" })

Tabs.Main:Dropdown({
    Title = "Accuracy mode",
    Description = "Never ~90-95% / Mix ~60% Sick / Always ~100%",
    Values = {
        "Never Sick",
        "Mix (~60% Sick)",
        "Always Sick",
    },
    Value = "Mix (~60% Sick)",
    Callback = function(value)
        if value == "Never Sick" then
            mode = MODE_NEVER
        elseif value == "Always Sick" then
            mode = MODE_ALWAYS
        else
            mode = MODE_MIX
        end
    end,
})

Tabs.Main:Section({ Title = "Misc" })

Tabs.Main:Toggle({
    Title = "Anti-AFK",
    Description = "Jump every 10s while in a match",
    Default = true,
    Callback = function(state)
        antiAfk = state
    end,
})

Tabs.Main:Toggle({
    Title = "Do not send notifications",
    Description = "Hide all notifications",
    Default = false,
    Callback = function(state)
        noNotifications = state
    end,
})

Tabs.Main:Button({
    Title = "Hide menu",
    Description = "Close the window while a song is running",
    Callback = function()
        pcall(function() Window:Hide() end)
    end,
})

Tabs.Info:Paragraph({
    Title = "FunkyFriday Auto-Play",
    Content = "Premium auto player for Funky Friday\nby iwakewar team\n\n"
        .. "- Fires the game's own InputActions (real press path)\n"
        .. "- Full hit animation, combo, splash, sound and score\n"
        .. "- Reads the rendered note frames (head + hold tail)\n"
        .. "- Holds detected from the real tail frame, not guesswork\n"
        .. "- Every press verified; failed press retried once\n"
        .. "- Accuracy modes: Never ~90-95%, Mix ~60% Sick, Always ~100%\n"
        .. "- Death / Poison notes always hit exact\n"
        .. "- Playfield auto-detected from your own side\n"
        .. "- Anti-AFK built in\n\n"
        .. "Press RightShift to open / close the menu.",
})

Tabs.Info:Button({
    Title = "Our Discord Server",
    Description = "Copy invite link to clipboard",
    Callback = function()
        local copied = copyToClipboard("https://discord.gg/GgshjzxxFS")
        notify("FunkyFriday Auto-Play", copied and "Discord link copied" or "No clipboard API on this executor", 2)
    end,
})

-- =========================================================== status thread
local runBaseAcc, runBaseHits = nil, nil

task.spawn(function()
    while true do
        task.wait(0.5)
        if genv0.__funkyfridayInstance ~= INSTANCE then break end
        if GUI.Unloaded then break end

        local okField = field ~= nil and field.Parent ~= nil
        local inMatch = okField and ctx ~= nil and ctx.Parent ~= nil
        local stateTxt = enabled and (inMatch and "IN MATCH" or "ON - waiting for a match...") or "OFF"

        local laneCount = 0
        for _ in pairs(lanes) do laneCount = laneCount + 1 end

        pcall(function()
            Status:SetContent(string.format("%s  |  side: %s  |  lanes: %d  |  retries: %d",
                stateTxt, tostring(fieldSide or "-"), laneCount, retries))
        end)

        local accTxt, meanTxt = "-", "-"
        local score, combo, misses = 0, 0, 0
        local cfg = inMatch and getConfig(select(2, getSide())) or nil
        if cfg then
            local a = cfg:GetAttribute("Accuracy") or 0
            local h = cfg:GetAttribute("Hits") or 0
            local m = cfg:GetAttribute("Misses") or 0
            combo = cfg:GetAttribute("Combo") or 0
            score = cfg:GetAttribute("Score") or 0
            misses = m
            if h > 0 then accTxt = string.format("%.2f%%", a / h) end
            local mean = cfg:GetAttribute("MeanMS")
            if mean and h > 0 then meanTxt = string.format("%.1f ms", mean / h) end

            if not runBaseHits or h < runBaseHits then
                runBaseAcc, runBaseHits = a, h
            end
            local dh = h - (runBaseHits or h)
            if dh >= 5 then
                accTxt = accTxt .. string.format("  (run %.2f%% over %d)", (a - (runBaseAcc or a)) / dh, dh)
            end
        end

        pcall(function()
            local modeTxt = mode == MODE_ALWAYS and "Always Sick"
                or (mode == MODE_NEVER and "Never Sick" or "Mix")
            Live:SetContent(string.format(
                "state: %s  |  mode: %s  |  score: %d  |  acc: %s  |  mean: %s  |  combo: %d  |  misses: %d\npresses: %d  |  taps: %d  |  holds: %d  |  retries: %d",
                enabled and "ON" or "OFF", modeTxt, score, accTxt, meanTxt, combo, misses,
                presses, tapsFired, holdsFired, retries))
        end)
    end
end)

-- =============================================================== main loop
RunService.Heartbeat:Connect(function()
    if genv0.__funkyfridayInstance ~= INSTANCE then return end
    if not enabled then return end

    if antiAfk then
        local now = os.clock()
        if now - lastJump >= 10 then
            lastJump = now
            local ch = plr.Character
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then hum.Jump = true end
        end
    end

    pcall(stepField)
end)

notify("FunkyFriday Auto-Play", "Loaded. Toggle with RightShift.", 4)
pcall(function() Window:SetToggleKey(Enum.KeyCode.RightShift) end)
