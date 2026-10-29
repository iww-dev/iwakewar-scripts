-- BFNFR Auto-Play
-- by iwakewar team
-- Premium GUI. Presses the REAL lane keys through VirtualInputManager
-- so the game's own KeyPress -> NoteInput runs: arrow/skin animation, character
-- animation, combo, sound and the remote, exactly like a human press.
-- Works with the player's own keybinds.
--
-- Timing model (read from the game's own songPlay/NoteInput):
--   the game judges INSTANTLY, client-side, off the note's current Y.Scale:
--   |off|<=16.5ms PERFECT, <=43.5 SICK, <=76.5 GOOD, <=106.5 OK, <=130.5 BAD,
--   where off = 2000*|Y.Scale|/(11*NoteSpeed) - exactly our curMs.
--   So we aim the keypress at curMs == target (4.5ms for Always Perfect) and
--   pick the frame whose offset lands closest to it. No adaptive "input lead":
--   the game judges off the exact note position we read, so any learned lead
--   only ever drifted and pushed Perfect notes into Sick.

local plr = game.Players.LocalPlayer
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local mf = plr.PlayerGui:WaitForChild("Main"):WaitForChild("MatchFrame")
local DataF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("DataF")

local genv0 = getgenv()
if genv0.__bfnfrFluent and type(genv0.__bfnfrFluent.Destroy) == "function" then
  pcall(function() genv0.__bfnfrFluent:Destroy() end)
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
    warn("[BFNFR] PrimordialUI failed to load (" .. tostring(res) .. "), falling back to WindUI")
    GUI = loadstring(game:HttpGet(WINDUI_URL))()
    GUI.__fallback = true
  end
end
genv0.__bfnfrFluent = GUI
local isPhone = UIS.TouchEnabled and not UIS.KeyboardEnabled
local Window = GUI:CreateWindow({
    Title = "iwakewar: BFNFR",
    Subtitle = "by iwakewar team",
    Footer = "by iwakewar team",
    Version = "v3.1",
    Folder = "iwakewar-bfnfr",
    Icon = "music",
    Theme = "Rose",
    Size = UDim2.fromOffset(760, 500),
    ToggleKey = Enum.KeyCode.RightShift,
    Topbar = { Height = 40, ButtonsType = "Default" },
    OpenButton = { Enabled = true, Draggable = true, OnlyMobile = true, Scale = 1.1, CornerRadius = UDim.new(0, 6) },
})
GUI._selfUrl = "https://raw.githubusercontent.com/iww-dev/iwakewar-scripts/refs/heads/main/BFNFR%20Auto-Play.luau"
local Tabs = {
    Info = Window:Tab({ Title = "Info", Subtitle = "About the script", Icon = "sfsymbols:info.circle", Border = true }),
    Main = Window:Tab({ Title = "Controls", Subtitle = "Auto-play settings", Icon = "sfsymbols:gamecontroller", Border = true }),
}
pcall(function() Window:SelectTab(1) end)
-- mobile floating toggle restored (always visible, like Fluent epoch)
if isPhone then
  pcall(function() game:GetService("CoreGui").BFNFRtoggle:Destroy() end)
  local sg = Instance.new("ScreenGui")
  sg.Name = "BFNFRtoggle" sg.ResetOnSpawn = false
  pcall(function() sg.Parent = game:GetService("CoreGui") end)
  if sg.Parent == nil then sg.Parent = plr.PlayerGui end
  local b = Instance.new("TextButton")
  b.Size = UDim2.fromOffset(40, 40)
  b.Position = UDim2.new(0.5, -20, 0.5, -260)
  b.Text = "B" b.TextSize = 18
  b.BackgroundColor3 = Color3.fromRGB(30, 32, 40) b.TextColor3 = Color3.new(1, 1, 1)
  b.Parent = sg
  local cc = Instance.new("UICorner") cc.CornerRadius = UDim.new(0, 8) cc.Parent = b
  local glow = Instance.new("UIStroke")
  glow.Thickness = 2 glow.Color = Color3.fromRGB(0, 220, 255) glow.Transparency = 0.2
  glow.Parent = b
  task.spawn(function()
    local ts = game:GetService("TweenService")
    while b.Parent do
      pcall(function()
        ts:Create(glow, TweenInfo.new(0.8), { Transparency = 0.7 }):Play()
        task.wait(0.85)
        ts:Create(glow, TweenInfo.new(0.8), { Transparency = 0.2 }):Play()
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
    if moved < 12 then
      local g = GUI.GUI
      if g then g.Enabled = not g.Enabled end
    end
  end)
end

-- engine state
local enabled = false
local antiAfk = true
local mySide: number? = nil
-- 0 = авто (как назначила игра), 1 = P1, 2 = P2 (ручной override)
local selectedSide = 0
local speed = 1
local dir = -1
local laneKeys: { [number]: Enum.KeyCode } = {}
local speedLock = false
local tracked = setmetatable({}, { __mode = "k" })
local held = {}
local lastJump = 0
local hits = 0

local noNotifications = false

local DEFAULT_KEYS = { "D", "F", "J", "K", "Left", "Down", "Up", "Right" }

local PERFECT_CENTER = 11
local SICK_CENTER = 31
-- Mix: доля Perfect случайная в диапазоне 56-64% (перебрасывается на каждую песню)
local MIX_PERFECT_MIN = 56
local MIX_PERFECT_MAX = 64
local perfectMode = "mix"
local perfectChance = MIX_PERFECT_MIN + math.random() * (MIX_PERFECT_MAX - MIX_PERFECT_MIN)

local function rollMixChance()
    perfectChance = MIX_PERFECT_MIN + math.random() * (MIX_PERFECT_MAX - MIX_PERFECT_MIN)
end

-- === Humanizer / Accuracy ===
-- Игра считает точность за ноту непрерывно от |off|: acc(off) ~= 1 - (off/130.5)^2
-- (проверено по живым Acc/AccWeight: 95.93% у FC-игрока => средний |off| ~27мс).
-- Поэтому целевой процент переводится в целевой |off|, а факт. точность
-- читается из атрибутов Acc/AccWeight и подправляет прицел по ходу песни.
local HIT_WINDOW = 130.5
local ACC_ALWAYS = 99.88
local ACC_NEVER_MIN = 91.14
local ACC_NEVER_MAX = 96.32
local HUMAN_JITTER = 3.5        -- мс, разброс прицела на каждую ноту
local accTarget: number? = nil  -- желаемая accuracy текущей песни, %
local aimTarget = PERFECT_CENTER
local accBaseAcc, accBaseW = nil, nil
local lastRunAcc: number? = nil
local msIndicOn = false

local function aimForAccuracy(pct: number): number
    local a = math.clamp(pct, 0, 100) / 100
    return HIT_WINDOW * math.sqrt(math.max(0, 1 - a))
end

pcall(function() delfile("iwakewar_bfnfr_inputlead.txt") end)
pcall(function() delfile("iwakewar_bfnfr_lead_v3.txt") end)

local rateCache = setmetatable({}, { __mode = "k" })

local function clampNum(v: number, a: number, b: number): number
    if v < a then return a elseif v > b then return b end
    return v
end

local function copyToClipboard(text: string): boolean
    local funcs = { setclipboard, toclipboard }
    local genv = getgenv and getgenv() or {}
    for _, name in ipairs({ "writeclipboard", "clipboard", "setclipboard", "toclipboard" }) do
        local v = genv[name]
        if v == nil then
            v = rawget(_G, name)
        end
        if typeof(v) == "function" then
            funcs[#funcs + 1] = v
        end
    end
    for _, fn in ipairs(funcs) do
        if typeof(fn) == "function" then
            local ok = pcall(fn, text)
            if ok then return true end
        end
    end
    return false
end

local function fetchSettings(): boolean
    local ok, res = pcall(function()
        return DataF:InvokeServer("Get")
    end)
    if not ok or not res or not res[1] then return false end
    local st = res[1]
    speed = clampNum(st.NoteSpeed or 1, 0.8, 5)
    dir = st.Direction or -1
    laneKeys = {}
    for i = 1, 4 do
        local name = st.Inputs and st.Inputs[i] or DEFAULT_KEYS[i]
        local kc = Enum.KeyCode[name]
        if kc then laneKeys[i] = kc end
    end
    return true
end

-- Сторона берётся из данных самой игры: Players.LocalPlayer.File.CurrentPlayer —
-- это ObjectValue с именем "Player1"/"Player2" (слот Config той сцены, где ты стоишь),
-- и его .Value указывает на твоего Player. Игра сама использует это поле:
-- Player1 -> GetNotes1 -> KeySync1, Player2 -> GetNotes2 -> KeySync2.
-- Проверено вживую: Player1 всегда стоит на части P1, Player2 на P2.
local function gameSide(): number?
    local file = plr:FindFirstChild("File")
    local cp = file and file:FindFirstChild("CurrentPlayer")
    local v = cp and cp.Value
    if v and v:IsA("ObjectValue") and v.Value == plr then
        if v.Name == "Player1" then return 1 end
        if v.Name == "Player2" then return 2 end
    end
    return nil
end

local function resolveSide(): number?
    if selectedSide == 1 or selectedSide == 2 then return selectedSide end
    return gameSide()
end

local function applyHumanizerMode()
    if perfectChance >= 100 then
        accTarget = ACC_ALWAYS
        aimTarget = aimForAccuracy(ACC_ALWAYS)
    elseif perfectChance <= 0 then
        if not accTarget or accTarget < ACC_NEVER_MIN or accTarget > ACC_NEVER_MAX then
            accTarget = ACC_NEVER_MIN + math.random() * (ACC_NEVER_MAX - ACC_NEVER_MIN)
        end
        aimTarget = math.max(aimForAccuracy(accTarget), 20)
    else
        accTarget = nil
        aimTarget = PERFECT_CENTER
    end
end

-- фиксируем базу Acc/AccWeight на старте песни и выбираем цель по режиму
local function beginHumanizer()
    accBaseAcc = plr:GetAttribute("Acc")
    accBaseW = plr:GetAttribute("AccWeight")
    lastRunAcc = nil
    -- Mix: своя случайная доля Perfect на каждую песню (56-64%)
    if perfectMode == "mix" then rollMixChance() end
    applyHumanizerMode()
end

-- Включаем msIndic/HitLatency сами: getsenv даёт настоящую _G.Settings игры.
local function enableMsIndic(): boolean
    if type(getsenv) ~= "function" then return false end
    local main = plr.PlayerGui:FindFirstChild("Main")
    local fnf = main and main:FindFirstChild("FNFMain")
    if not fnf then return false end
    local ok, env = pcall(getsenv, fnf)
    if not ok or type(env) ~= "table" then return false end
    local okG, g = pcall(function() return env._G end)
    if not okG or type(g) ~= "table" then return false end
    local settings = g.Settings
    if type(settings) ~= "table" then return false end
    local hl = settings.HitLate
    if type(hl) ~= "table" then return false end
    if hl.Value ~= true then hl.Value = true end
    msIndicOn = true
    pcall(function()
        local btn = main.MainFrame.Menu.Settings.ScrollGameplay.Gameplay.HitLate.Button
        if btn.Text ~= "On" then btn.Text = "On" end
    end)
    return true
end

local function pickTarget(): number
    if accTarget then
        local t = aimTarget + (math.random() * 2 - 1) * HUMAN_JITTER
        -- Never Perfect не должен выдавать Perfect даже с джиттером
        if perfectChance <= 0 then t = math.max(t, 19) end
        return clampNum(t, 0, 120)
    end
    if perfectChance <= 0 then
        return SICK_CENTER
    end
    if perfectChance >= 100 then
        return PERFECT_CENTER
    end
    if math.random() <= perfectChance / 100 then
        return PERFECT_CENTER
    end
    return SICK_CENTER
end

-- сколько мс осталось ноте до линии (ровно то, чем игра считает оффсет)
local function offsetMs(note: Instance): number
    return math.abs(note.Position.Y.Scale) / (11 * speed) * 2000
end

local function pressKey(lane: number)
    local kc = laneKeys[lane]
    if kc then
        VIM:SendKeyEvent(true, kc, false, game)
    end
end

local function releaseKey(lane: number)
    local kc = laneKeys[lane]
    if kc then
        VIM:SendKeyEvent(false, kc, false, game)
    end
end

local function releaseAll()
    for lane in pairs(held) do
        held[lane] = nil
        releaseKey(lane)
    end
end

local function findHoldInHitbox(ar: Instance, noteName: string): Instance?
    local Hold = ar:FindFirstChild("Hold")
    local hb = Hold and Hold:FindFirstChild("Hitbox")
    return hb and hb:FindFirstChild("Hold_" .. noteName) or nil
end

local function findHoldFrame(ar: Instance, noteName: string): Instance?
    local Notes = ar:FindFirstChild("Notes")
    if Notes then
        local f = Notes:FindFirstChild("Hold_" .. noteName)
        if f then return f end
    end
    local Hold = ar:FindFirstChild("Hold")
    local hb = Hold and Hold:FindFirstChild("Hitbox")
    if hb then
        local f = hb:FindFirstChild("Hold_" .. noteName)
        if f then return f end
    end
    return nil
end

local function startHold(lane: number, noteName: string, ks: Instance)
    if held[lane] then return end
    held[lane] = true
    task.spawn(function()
        local guard = os.clock() + 120
        while held[lane] do
            local ar = ks:FindFirstChild("Arrow" .. lane)
            local frame = ar and findHoldFrame(ar, noteName)
            if not frame or not frame.Parent then break end
            local v6 = math.abs(frame.Size.Y.Scale)
            local v7 = frame.Position.Y.Scale * dir
            if v6 + v7 <= 1.5 or os.clock() > guard then break end
            RunService.Heartbeat:Wait()
        end
        if held[lane] then
            held[lane] = nil
            releaseKey(lane)
        end
    end)
end

-- Нажатие ноты с проверкой результата и добором.
-- Игра судит только попадания в окно ±130.5 мс (NoteInput: |v4| <= 0.06525,
-- v4 = |Y|/(11*NoteSpeed), off = 2000*v4). Успешное нажатие стирает ноту
-- (v3.Parent = nil; v3:Destroy()) и, для холда, кладёт Hold_<name> в Hold.Hitbox.
-- Вне окна игра только проигрывает Tap(): ноту можно нажать ещё раз.
--
-- Момент пресса: позиция ноты обновляется раз в кадр, поэтому оффсет меняется
-- шагами ~16мс. Ждём кадр, который окажется ближе всего к цели: если до цели
-- осталось меньше половины кадра — жмём сейчас, а не после перелёта.
local function pressNote(lane: number, note: Instance, ar: Instance, ks: Instance, st: table)
    if st.fired then return end
    st.fired = true

    task.spawn(function()
        local sweetSpot = clampNum(st.target, 0, 150)
        local dt = 1 / 60
        local prev = nil
        while true do
            if not note.Parent then return end
            local cur = offsetMs(note)
            if cur > 400 then return end
            if cur <= sweetSpot or (cur - sweetSpot) <= 1000 * dt * 0.5 then break end
            -- offsetMs возвращает МОДУЛЬ расстояния: если нота между кадрами
            -- перепрыгнула линию (просадка кадра / твин догнал время), cur после
            -- цели снова РАСТЁТ, и ждать "пока cur <= sweetSpot" бессмысленно —
            -- раньше цикл молча уходил в return, и нота проезжала в NM.
            -- Поэтому: как только cur перестала убывать — жмём сразу (лучше
            -- Sick/Good в окне, чем пропуск).
            if prev and cur > prev + 2 then
                -- уже вне окна: пресс всё равно уйдёт в "M"-мисс, жать нет смысла
                if cur > 130.5 then return end
                break
            end
            prev = cur
            local ok, newDt = pcall(function() return RunService.Heartbeat:Wait() end)
            dt = (ok and tonumber(newDt)) or (1 / 60)
            if not dt or dt <= 0 or dt > 0.2 then dt = 1 / 60 end
        end

        -- пресс строго в цель. никакой адаптивной калибровки: игра судит ровно по той
        -- позиции ноты, которую читаем мы, поэтому лид только вредил и уползал.
        local function doPress()
            pressKey(lane)
        end

        -- Подтверждение попадания: единственный надёжный признак того, что игра
        -- засчитала пресс — она уничтожает ноту (v3.Parent = nil; v3:Destroy()).
        -- НЕЛЬЗЯ считать подтверждением наличие Hold_<name>: игра кладёт этот
        -- фрейм в Notes ещё при создании ноты, и он висит там до попадания —
        -- именно из-за этого провалившиеся прессы холдов вообще не добирались.
        local function verify(attempt: number)
            task.spawn(function()
                local confirmed = false
                for _ = 1, 4 do
                    RunService.Heartbeat:Wait()
                    if not note.Parent then
                        confirmed = true
                        break
                    end
                end

                if confirmed then
                    hits = hits + 1
                    if findHoldInHitbox(ar, note.Name) then
                        startHold(lane, note.Name, ks)
                    else
                        releaseKey(lane)
                    end
                    return
                end

                -- Не засчиталось. Сначала отпускаем клавишу: повторный keydown по уже
                -- зажатой клавише игра просто не видит. Потом жмём ещё раз, но только
                -- пока нота внутри окна (off <= 110), иначе повтор уйдёт в "M"-мисс.
                releaseKey(lane)
                local off = offsetMs(note)
                if attempt < 2 and off <= 110 then
                    local waitMore = math.clamp((off - st.target) / 1000, 0, 0.1)
                    if waitMore > 0 then task.wait(waitMore) end
                    RunService.Heartbeat:Wait()
                    if not note.Parent then return end
                    doPress()
                    verify(attempt + 1)
                    return
                end

                RunService.Heartbeat:Wait()
                if not held[lane] then releaseKey(lane) end
            end)
        end

        doPress()
        verify(0)
    end)
end

local function resetRun()
    releaseAll()
    mySide = nil
    speedLock = false
    tracked = setmetatable({}, { __mode = "k" })
    accTarget = nil
    accBaseAcc, accBaseW = nil, nil
    lastRunAcc = nil
end

local function rerollTargets()
    for note, st in pairs(tracked) do
        if not st.fired then
            st.target = pickTarget()
        end
    end
end

-- GUI elements
local MainSection = Tabs.Main:Section({ Title = "Main Functions" })

local Status = Tabs.Main:Paragraph({
    Title = "Status",
    Content = "Idle - waiting for a track...",
})
local Live = Tabs.Main:Paragraph({
    Title = "Live",
    Content = "state: OFF | side: - | speed: - | hits: 0",
})

local sideDrop = Tabs.Main:Dropdown({
    Title = "My side",
    Description = "Auto reads the side from the game (File.CurrentPlayer), the rest is an override",
    Values = { "Auto (game)", "Left (P1)", "Right (P2)" },
    Value = "Auto (game)",
    Callback = function(value)
        if value == "Left (P1)" then
            selectedSide = 1
        elseif value == "Right (P2)" then
            selectedSide = 2
        else
            selectedSide = 0
        end
        if mySide then
            local target = resolveSide()
            if target and target ~= mySide then
                resetRun()
            end
        end
    end,
})

local function notify(title: string, content: string, duration: number)
    if noNotifications then return end
    GUI:Notify({
        Title = title,
        Content = content,
        Duration = duration,
    })
end

local enabledTog = Tabs.Main:Toggle({
    Title = "Auto-Play",
    Description = "Toggle automatic key presses",
    Default = false,
    Callback = function(state)
        enabled = state
        if not enabled then
            resetRun()
        end
        notify("BFNFR Auto-Play", enabled and "Auto-Play enabled" or "Auto-Play disabled", 2)
    end,
})

-- вкладки секций: одновременно видна только выбранная
Tabs.Main:Section({ Title = "Humanizer" })

local perfectDrop = Tabs.Main:Dropdown({
    Title = "Perfect mode",
    Description = "Never ~91-96% / Mix 56-64% / Always ~99.88%",
    Values = {
        "Never Perfect",
        "Mix (56-64% Perfect)",
        "Always Perfect",
    },
    Value = "Mix (56-64% Perfect)",
    Callback = function(value)
        if value == "Never Perfect" then
            perfectMode = "never"
            perfectChance = 0
        elseif value == "Always Perfect" then
            perfectMode = "always"
            perfectChance = 100
        else
            perfectMode = "mix"
            rollMixChance()
        end
        applyHumanizerMode()
        rerollTargets()
    end,
})

Tabs.Main:Section({ Title = "Misc" })

local antiAfkTog = Tabs.Main:Toggle({
    Title = "Anti-AFK",
    Description = "Jump every 10s while in a track",
    Default = true,
    Callback = function(state)
        antiAfk = state
    end,
})

local noNotifTog2 = Tabs.Main:Toggle({
    Title = "Do not send notifications",
    Description = "Hide all notifications",
    Default = false,
    Callback = function(state)
        noNotifications = state
    end,
})

local togKey2 = Tabs.Main:Keybind({
    Title = "Toggle keybind",
    Description = "Quickly turn Auto-Play on/off",
    Mode = "Toggle",
    Default = "H",
    Callback = function()
        enabledTog:SetValue(not enabled)
    end,
})

local bfnfrInfo = Tabs.Info:Paragraph({
    Title = "BFNFR Auto-Play",
    Content = "Premium auto player for Basically FNF: Remix\nby iwakewar team\n\n- Plays your lane with your own keybinds\n- Full Hit/Release animations (real key events)\n- Holds pressed and released correctly\n- Accuracy modes: Never ~91-96%, Mix 56-64%, Always ~99.88%\n- Side: auto from the game (File.CurrentPlayer) + manual override\n- msIndic auto-enabled, no timing drift\n- Anti-AFK built in\n\nPress RightShift to open / close the menu.",
})

local discordBtn = Tabs.Info:Button({
    Title = "Our Discord Server",
    Description = "Copy invite link to clipboard",
    Callback = function()
        local copied = copyToClipboard("https://discord.gg/GgshjzxxFS")
        notify("BFNFR Auto-Play", copied and "Discord link copied" or "No clipboard API on this executor", 2)
    end,
})


-- live status refresh
task.spawn(function()
    while true do
        task.wait(1)
        if GUI.Unloaded then break end
        local inTrack = mf.Visible
        local state = enabled and (inTrack and "IN TRACK" or "ON - waiting for a track...") or "OFF"
        pcall(function()
            Status:SetContent(state .. (inTrack and ("  |  side: P" .. (mySide or "-")) or ""))
        end)
        local stxt = enabled and "ON" or "OFF"
        local side = mySide and tostring(mySide) or "-"
        local jf = mf:FindFirstChild("JudgmentsFrame")
        local counts = {}
        if jf then
            local function grab(name)
                local f = jf:FindFirstChild(name)
                if not f then return "0" end
                if f:IsA("TextLabel") then return f.Text end
                local lb = f:FindFirstChildOfClass("TextLabel")
                return lb and lb.Text or "0"
            end
            counts.Perfect = grab("Perfect")
            counts.Sick = grab("Sick")
            counts.Good = grab("Good")
            counts.Bad = grab("Bad")
        end

        -- включаем msIndic и ведём accuracy по реальным данным игры
        if enabled and inTrack then
            enableMsIndic()
            local a = plr:GetAttribute("Acc")
            local w = plr:GetAttribute("AccWeight")
            if a and w and accBaseAcc and accBaseW then
                if w < accBaseW or a < accBaseAcc then
                    -- песня сменилась / сервер сбросил аккумулятор
                    accBaseAcc, accBaseW = a, w
                    lastRunAcc = nil
                else
                    local dw = w - accBaseW
                    if dw >= 6 then
                        local runAcc = (a - accBaseAcc) / dw * 100
                        lastRunAcc = runAcc
                        if accTarget then
                            local err = runAcc - accTarget
                            local gain = (math.abs(err) > 1) and 1.5 or 0.4
                            local delta = clampNum(err * gain, -8, 8)
                            local oldAim = aimTarget
                            aimTarget = clampNum(aimTarget + delta, 0, 60)
                            if perfectChance <= 0 then aimTarget = math.max(aimTarget, 18) end
                            if math.abs(aimTarget - oldAim) >= 1 then rerollTargets() end
                        end
                    end
                end
            end
        end

        local accStr = "-"
        if lastRunAcc then
            accStr = string.format("%.2f%%", lastRunAcc)
            if accTarget then accStr = accStr .. string.format(" (target %.2f%%)", accTarget) end
        elseif accTarget then
            accStr = string.format("target %.2f%%", accTarget)
        end

        pcall(function()
            Live:SetContent(string.format(
                "state: %s  |  side: P%s  |  speed: %.2f"
                    .. "  |  acc: %s  |  P %s / S %s / G %s / B %s  |  hits: %d",
                stxt, side, speed, accStr,
                counts.Perfect or "-", counts.Sick or "-", counts.Good or "-", counts.Bad or "-", hits
            ))
        end)
        if enabled and inTrack and tick() % 2 < 1 then
            print(string.format(
                "BFNFR-counts | Perfect=%s Sick=%s Good=%s Bad=%s hits=%d acc=%s aim=%.1fms speed=%.2f",
                counts.Perfect, counts.Sick, counts.Good, counts.Bad, hits, accStr, aimTarget, speed
            ))
        end
    end
end)

-- core loop
RunService.Heartbeat:Connect(function()
    if not enabled then
        if mySide ~= nil then resetRun() end
        return
    end
    if not mf.Visible then
        if mySide ~= nil then resetRun() end
        return
    end
    if not speedLock then
        if fetchSettings() then
            speedLock = true
        end
    end
    if not mySide then
        local resolved = resolveSide()
        if not resolved then return end
        mySide = resolved
        enableMsIndic()
        beginHumanizer()
        notify("BFNFR Auto-Play", "Side: P" .. resolved
            .. (selectedSide == 0 and " (auto: File.CurrentPlayer)" or " (manual)")
            .. " / speed " .. speed, 3)
    elseif selectedSide == 0 then
        -- новая игра может поменять стороны: если игра назначила другую — перезапуск
        local assigned = gameSide()
        if assigned and assigned ~= mySide then
            resetRun()
            return
        end
    end
    if antiAfk then
        local now = os.clock()
        if now - lastJump >= 10 then
            lastJump = now
            local ch = plr.Character
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                hum.Jump = true
            end
        end
    end
    local sideNum = mySide :: number
    local ks = mf:FindFirstChild("KeySync" .. sideNum)
    if not ks then return end
    for lane = 1, 4 do
        if not laneKeys[lane] then continue end
        if held[lane] then continue end
        local ar = ks:FindFirstChild("Arrow" .. lane)
        if not ar then continue end
        local Notes = ar:FindFirstChild("Notes")
        if not Notes then continue end
        for _, note in ipairs(Notes:GetChildren()) do
            if note:IsA("ImageLabel") and note:GetAttribute("HoldHead") == true then
                local t = note:GetAttribute("T")
                if t == nil then continue end
                local st = tracked[note]
                if not st then
                    st = { target = pickTarget(), lastSign = nil, fired = false }
                    tracked[note] = st
                end
                local scale = note.Position.Y.Scale
                if math.abs(scale) > 11 * speed + 1 then
                    st.lastSign = nil
                end
                local s = scale
                local crossing = false
                if st.lastSign then
                    if s < 0 and st.lastSign >= 0 then crossing = true end
                    if s > 0 and st.lastSign <= 0 then crossing = true end
                end
                st.lastSign = s
                if not st.fired then
                    local curMs = offsetMs(note)
                    if curMs <= st.target + 30 or crossing then
                        pressNote(lane, note, ar, ks, st)
                    end
                end
            end
        end
    end
end)

notify("BFNFR Auto-Play", "Loaded. Toggle with RightShift.", 4)
pcall(function() Window:SetToggleKey(Enum.KeyCode.RightShift) end)

-- live note scroll-rate measurement: derive the game's real NoteSpeed
-- (the server value always clamps to 0.8, which is wrong for most songs).
-- Game judges off = 2000*|Y|/(11*v12); a note is 2000ms from the line
-- when |Y| = 11*v12, so scroll rate r = 11*v12/2 scale/sec -> v12 = 2r/11.
local speedMeas = nil
RunService.Heartbeat:Connect(function()
    if not enabled or not mf.Visible or not mySide then
        speedMeas = nil
        return
    end
    local ks = mf:FindFirstChild("KeySync" .. mySide)
    if not ks then speedMeas = nil return end
    local best = nil
    for lane = 1, 4 do
        local ar = ks:FindFirstChild("Arrow" .. lane)
        local Notes = ar and ar:FindFirstChild("Notes")
        if Notes then
            for _, n in ipairs(Notes:GetChildren()) do
                if n:IsA("ImageLabel") and n:GetAttribute("HoldHead") == true then
                    local y = math.abs(n.Position.Y.Scale)
                    if y >= 3 and y <= 60 then
                        if not best or y < best.y then
                            best = { n = n, y = y }
                        end
                    end
                end
            end
        end
    end
    if not best then speedMeas = nil return end
    local now = os.clock()
    if speedMeas and speedMeas.n == best.n then
        local dt = now - speedMeas.t
        if dt >= 0.008 then
            local rate = (speedMeas.y - best.y) / dt
            if rate > 0.3 and rate < 40 then
                local s = math.clamp(2 * rate / 11, 0.8, 5)
                speed = speed + (s - speed) * 0.3
            end
        end
    end
    speedMeas = { n = best.n, t = now, y = best.y }
end)
