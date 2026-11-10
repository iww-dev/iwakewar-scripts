-- WordGame Auto-Play  (Игра в Слова)
-- by iwakewar team
-- placeId 71106427459865
--
-- How the game actually works (read from the game's own client script):
--   Client sends answers through ReplicatedStorage.WordGame.Action:
--       Action:FireServer("word", letter .. TextBox.Text, {
--           requestId = n, tableId = t, round = r, generation = g })
--   The hidden TextBox is PlayerGui.WordGameUI.Canvas.Match.TypingCapture and
--   it must contain ONLY the word without its first letter: the client itself
--   builds the full word as state.letter .. TextBox.Text.
--   Choosing the next starting letter:
--       Action:FireServer("choose", letter)        (phase == "choosing")
--   Server state comes through ReplicatedStorage.WordGame.State as events with
--   a `kind` field. The full snapshot is kind == "match" and it carries:
--       phase, letter, turn, you, choices, chooser, tableId, round, generation,
--       history (already accepted words, ours AND the opponent's), deadline.
--   Every event is broadcast for every table, so we only accept the snapshot
--   whose ids[you] == LocalPlayer.UserId.
--
-- Bot behaviour:
--   - download a russian noun list once (not embedded in this file), cache it
--     in getgenv().__wordgameDict and index it by first letter;
--   - when we have to choose a letter, pick the one with the biggest pool;
--   - on our turn type the answer without the first letter, character by
--     character, at the configured WPM with human jitter, then fire "word";
--   - never reuse a word from history / already accepted words;
--   - if the server rejects a word, blacklist it and try the next candidate.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local plr = Players.LocalPlayer

local genv0 = getgenv()

-- one live instance only
if type(genv0.__wordgameCleanup) == "function" then
    pcall(genv0.__wordgameCleanup)
end
local INSTANCE = {}
genv0.__wordgameInstance = INSTANCE

if genv0.__wordgameGUI and type(genv0.__wordgameGUI.Destroy) == "function" then
    pcall(function() genv0.__wordgameGUI:Destroy() end)
end

local DICT_URL = "https://raw.githubusercontent.com/Harrix/Russian-Nouns/main/dist/russian_nouns.txt"
local VERSION = "v0.3.0"

-- ==================================================================== GUI
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
        warn("[WordGame] PrimordialUI failed to load (" .. tostring(res) .. "), falling back to WindUI")
        GUI = loadstring(game:HttpGet(WINDUI_URL))()
        GUI.__fallback = true
    end
end
genv0.__wordgameGUI = GUI

local Window = GUI:CreateWindow({
    Title = "iwakewar: Игра в Слова",
    Subtitle = "by iwakewar team",
    Footer = "by iwakewar team",
    Version = VERSION,
    Folder = "iwakewar-wordgame",
    Icon = "text",
    Theme = "Rose",
    Size = UDim2.fromOffset(720, 480),
    ToggleKey = Enum.KeyCode.RightShift,
    Topbar = { Height = 40, ButtonsType = "Default" },
    OpenButton = { Enabled = true, Draggable = true, OnlyMobile = true, Scale = 1.1, CornerRadius = UDim.new(0, 6) },
})
GUI._selfUrl = "https://raw.githubusercontent.com/iww-dev/iwakewar-scripts/refs/heads/main/WordGame%20Auto-Play.luau"

local Tabs = {
    Info = Window:Tab({ Title = "Info", Subtitle = "About the script", Icon = "sfsymbols:info.circle", Border = true }),
    Main = Window:Tab({ Title = "Controls", Subtitle = "Auto-play settings", Icon = "sfsymbols:gamecontroller", Border = true }),
}
pcall(function() Window:SelectTab(1) end)

-- ================================================================== state
local enabled = false
local wpm = 80
local pickBestLetter = true
local wordOrder = "long"   -- long | short | random
local brainrot = false     -- only words ending with "е"
local notificationsEnabled = true

local Status, Live, DictInfo   -- filled in after the window is built

local Dict = { byFirst = {}, count = 0, ready = false, error = nil }
local match = nil            -- latest state snapshot for OUR table
local usedWords = {}         -- words accepted in the current match
local badWords = {}          -- words the server rejected
local lastChooseKey = nil
local lastSubmitKey = nil
local lastWord = nil
local lastReject = nil
local busy = false
local reqId = 0

local stats = { sent = 0, accepted = 0, rejected = 0, misses = 0 }

local function log(msg)
    if Status then
        pcall(function() Status:SetContent(msg) end)
    end
    print("[WordGame] " .. msg)
end

-- ============================================================== dictionary
local function buildDict(body)
    local byFirst = {}
    local n = 0
    for w in body:gmatch("[^\r\n]+") do
        w = w:gsub("%s+$", "")
        if #w >= 2 and not w:find("%-") and not w:find("%s") then
            local k = w:sub(1, 2)
            local list = byFirst[k]
            if not list then
                list = {}
                byFirst[k] = list
            end
            list[#list + 1] = w
            n = n + 1
        end
    end
    for _, list in pairs(byFirst) do
        table.sort(list, function(a, b) return #a > #b end)
    end
    return { byFirst = byFirst, count = n, ready = true, error = nil }
end

local function ensureDict(force)
    if not force then
        local cached = genv0.__wordgameDict
        if type(cached) == "table" and cached.ready then
            return cached
        end
    end
    local ok, res = pcall(function()
        return game:HttpGet(DICT_URL)
    end)
    if ok and type(res) == "string" and #res > 1000 then
        local d = buildDict(res)
        genv0.__wordgameDict = d
        return d
    end
    return nil, tostring(res)
end

task.spawn(function()
    if Status then pcall(function() Status:SetContent("Скачиваю словарь...") end) end
    local d, err = ensureDict(false)
    if d then
        Dict = d
        if Status then pcall(function() Status:SetContent(string.format("Словарь готов: %d слов", d.count)) end) end
        print(string.format("[WordGame] dictionary ready: %d words", d.count))
    else
        Dict.error = err
        if Status then pcall(function() Status:SetContent("Словарь не скачался: " .. tostring(err)) end) end
        warn("[WordGame] dictionary failed: " .. tostring(err))
    end
end)

-- ================================================================= events
local WG = RS:WaitForChild("WordGame")
local Action = WG:WaitForChild("Action")
local State = WG:WaitForChild("State")

local function isOurSnapshot(a)
    if type(a) ~= "table" then return false end
    if type(a.ids) ~= "table" or a.you == nil then return false end
    return a.ids[a.you] == plr.UserId
end

local function sameRound(a, b)
    return a and b
        and a.tableId == b.tableId
        and a.round == b.round
        and (a.generation or 0) == (b.generation or 0)
end

State.OnClientEvent:Connect(function(a)
    if type(a) ~= "table" then return end

    if a.kind == "match" then
        if isOurSnapshot(a) then
            local prev = match
            match = a
            if not sameRound(prev, a) then
                lastSubmitKey = nil
            end
            if prev and (prev.tableId ~= a.tableId or (prev.generation or 0) ~= (a.generation or 0)) then
                usedWords = {}
            end
        end
    elseif a.kind == "accepted" then
        if match and a.tableId == match.tableId and a.word then
            usedWords[a.word] = true
            if a.actor == match.you then
                stats.accepted = stats.accepted + 1
            end
        end
    elseif a.kind == "invalid" or a.kind == "wordRejected" then
        if match and a.tableId == match.tableId and (a.actor == nil or a.actor == match.you) then
            if a.word then badWords[a.word] = true end
            stats.rejected = stats.rejected + 1
            lastReject = { word = a.word, reason = a.reason, kind = a.kind }
            lastSubmitKey = nil   -- allow another candidate this same turn
        end
    elseif a.kind == "missed" then
        if match and a.tableId == match.tableId then
            stats.misses = stats.misses + 1
        end
    end
end)

-- ================================================================ gameplay
local function getTextBox()
    local sg = plr.PlayerGui:FindFirstChild("WordGameUI")
    local canvas = sg and sg:FindFirstChild("Canvas")
    local m = canvas and canvas:FindFirstChild("Match")
    return m and m:FindFirstChild("TypingCapture")
end

local function roundKey(st)
    return tostring(st.tableId) .. ":" .. tostring(st.round) .. ":" .. tostring(st.generation or 0)
end

local function bestLetter(choices)
    local best, bestN = nil, -1
    for _, L in ipairs(choices or {}) do
        local k = tostring(L):lower():sub(1, 2)
        local list = Dict.byFirst[k]
        local n = list and #list or 0
        if n > bestN then
            best, bestN = tostring(L), n
        end
    end
    return best, bestN
end

local function pickFromList(list, ok, needE)
    local function good(w)
        if not ok(w) then return false end
        if needE and w:sub(-2) ~= "е" then return false end
        return true
    end

    -- top-24 longest / top-24 shortest, then random inside that pool
    if wordOrder == "long" or wordOrder == "short" then
        local pool = {}
        if wordOrder == "long" then
            for i = 1, #list do
                local w = list[i]
                if good(w) then
                    pool[#pool + 1] = w
                    if #pool >= 24 then break end
                end
            end
        else
            for i = #list, 1, -1 do
                local w = list[i]
                if good(w) then
                    pool[#pool + 1] = w
                    if #pool >= 24 then break end
                end
            end
        end
        if #pool > 0 then
            return pool[math.random(1, #pool)]
        end
        return nil
    end

    -- random: start at a random offset, take the first free word
    local start = math.random(1, #list)
    for i = 0, #list - 1 do
        local w = list[(start + i - 1) % #list + 1]
        if good(w) then
            return w
        end
    end
    return nil
end

local function pickWord(st)
    local letter = tostring(st.letter or ""):lower()
    if letter == "" then return nil end
    local list = Dict.byFirst[letter:sub(1, 2)]
    if not list or #list == 0 then return nil end

    local used = {}
    if type(st.history) == "table" then
        for _, w in ipairs(st.history) do used[w] = true end
    end
    for w in pairs(usedWords) do used[w] = true end

    local function ok(w)
        return not used[w] and not badWords[w]
    end

    if brainrot then
        local w = pickFromList(list, ok, true)
        if w then return w end
        -- no "е"-ending word for this letter: better to play something than lose the turn
        return pickFromList(list, ok, false)
    end

    return pickFromList(list, ok, false)
end

local function typeRemainder(st, word)
    local tb = getTextBox()
    if not tb then return false, "no TextBox" end

    local rest = word:sub(utf8.offset(word, 2))
    local chars = {}
    for _, code in utf8.codes(rest) do
        chars[#chars + 1] = utf8.char(code)
    end

    tb:CaptureFocus()
    tb.Text = ""

    local delay = 12 / math.max(20, wpm)   -- 5 chars per word
    for _, ch in ipairs(chars) do
        if not enabled or genv0.__wordgameInstance ~= INSTANCE then
            tb:ReleaseFocus()
            return false, "disabled"
        end
        local cur = match
        if cur and not sameRound(cur, st) then
            tb:ReleaseFocus()
            return false, "round changed"
        end
        tb.Text = tb.Text .. ch
        task.wait(delay * (0.75 + math.random() * 0.5))
    end

    task.wait(0.08 + math.random() * 0.12)
    return true, rest
end

local function playTurn(st, key)
    local word = pickWord(st)
    if not word then
        log(string.format("Нет слов на «%s» — пропуск", tostring(st.letter)))
        return
    end

    local ok, err = typeRemainder(st, word)
    if not ok then
        log("Ввод прерван: " .. tostring(err))
        return
    end

    local cur = match
    if not cur or not sameRound(cur, st) or cur.phase ~= "playing" or cur.turn ~= cur.you then
        log("Ход уже сменился — не отправляю")
        return
    end

    reqId = reqId + 1
    lastSubmitKey = key
    stats.sent = stats.sent + 1
    lastWord = word

    if brainrot and word:sub(-2) ~= "е" then
        log(string.format("Мозгоёб: на «%s» нет слова на «е», играю %s", tostring(st.letter), word))
    end

    Action:FireServer("word", word, {
        requestId = reqId,
        tableId = st.tableId,
        round = st.round,
        generation = st.generation or 0,
    })

    log(string.format("Отправил: %s (%d букв)", word, #word))
end

task.spawn(function()
    while genv0.__wordgameInstance == INSTANCE do
        task.wait(0.05)
        local st = match
        if enabled and Dict.ready and st then
            if st.phase == "choosing" and st.chooser == st.you then
                local key = roundKey(st)
                if lastChooseKey ~= key then
                    local L = pickBestLetter and bestLetter(st.choices) or (st.choices and st.choices[1])
                    if L then
                        lastChooseKey = key
                        Action:FireServer("choose", L)
                        log("Выбрал букву: " .. tostring(L))
                    end
                end
            elseif st.phase == "playing" and st.turn == st.you and st.letter and st.letter ~= "" then
                local key = roundKey(st)
                if not busy and lastSubmitKey ~= key then
                    busy = true
                    task.spawn(function()
                        local ok, err = pcall(playTurn, st, key)
                        if not ok then
                            log("Ошибка хода: " .. tostring(err))
                        end
                        busy = false
                    end)
                end
            end
        end
    end
end)

-- ==================================================================== GUI
local MainSection = Tabs.Main:Section({ Title = "Auto-Play" })

Status = Tabs.Main:Paragraph({
    Title = "Status",
    Content = "Скачиваю словарь...",
})

Live = Tabs.Main:Paragraph({
    Title = "Live",
    Content = "state: OFF | letter: - | sent: 0 | ok: 0 | bad: 0",
})

Tabs.Main:Toggle({
    Title = "Auto-Play",
    Description = "Сам отвечает и сам выбирает букву",
    Default = false,
    Callback = function(state)
        enabled = state
        if not enabled and match then
            lastChooseKey = nil
            lastSubmitKey = nil
        end
        if notificationsEnabled then
            GUI:Notify({
                Title = "WordGame Auto-Play",
                Content = enabled and "Auto-Play включён" or "Auto-Play выключен",
                Duration = 2,
            })
        end
    end,
})

Tabs.Main:Slider({
    Title = "Скорость печати (WPM)",
    Min = 40,
    Max = 160,
    Value = 80,
    Format = "%.0f WPM",
    Callback = function(v)
        wpm = tonumber(v) or 80
    end,
})

Tabs.Main:Toggle({
    Title = "Выбирать лучшую букву",
    Description = "Берёт букву с самым большим словарём",
    Default = true,
    Callback = function(state)
        pickBestLetter = state
    end,
})

Tabs.Main:Dropdown({
    Title = "Приоритет слов",
    Description = "Длинные = больше очков, короткие = быстрее печатать",
    Values = { "Самые длинные", "Самые короткие", "Рандом" },
    Value = "Самые длинные",
    Callback = function(value)
        if value == "Самые короткие" then
            wordOrder = "short"
        elseif value == "Рандом" then
            wordOrder = "random"
        else
            wordOrder = "long"
        end
    end,
})

Tabs.Main:Toggle({
    Title = "Режим Мозгоёб",
    Description = "Писать только слова, заканчивающиеся на «е» (соперник получает «е»)",
    Default = false,
    Callback = function(state)
        brainrot = state
        if notificationsEnabled then
            GUI:Notify({
                Title = "Режим Мозгоёб",
                Content = brainrot and "Включён: только слова на «е»" or "Выключен",
                Duration = 2,
            })
        end
    end,
})

Tabs.Main:Section({ Title = "Словарь" })

local DictInfo
DictInfo = Tabs.Main:Paragraph({
    Title = "Словарь",
    Content = "ещё не загружен",
})

Tabs.Main:Button({
    Title = "Перекачать словарь",
    Description = "Сбросить кэш и скачать заново",
    Callback = function()
        genv0.__wordgameDict = nil
        Dict = { byFirst = {}, count = 0, ready = false }
        task.spawn(function()
            local d, err = ensureDict(true)
            if d then
                Dict = d
                pcall(function() DictInfo:SetContent(string.format("%d слов, %d букв", d.count, (function()
                    local n = 0
                    for _ in pairs(d.byFirst) do n = n + 1 end
                    return n
                end)())) end)
                pcall(function() Status:SetContent("Словарь готов: " .. d.count .. " слов") end)
            else
                pcall(function() DictInfo:SetContent("Ошибка: " .. tostring(err)) end)
            end
        end)
    end,
})

Tabs.Main:Toggle({
    Title = "Уведомления",
    Description = "Показывать всплывашки при включении",
    Default = true,
    Callback = function(state)
        notificationsEnabled = state
    end,
})

Tabs.Info:Paragraph({
    Title = "WordGame Auto-Play",
    Content = "Автоответчик для «Игры в Слова»\nby iwakewar team\n\n"
        .. "- Словарь русских существительных качается с GitHub (51k слов)\n"
        .. "- Слова с дефисами и пробелами отбрасываются\n"
        .. "- Буква выбирается по самому большому пулу слов\n"
        .. "- Приоритет: самые длинные / самые короткие / рандом\n"
        .. "- Режим Мозгоёб: только слова, заканчивающиеся на «е»\n"
        .. "- Ввод посимвольный, скорость настраивается (WPM)\n"
        .. "- Уже использованные слова (свои и соперника) не повторяются\n"
        .. "- Если сервер не принял слово — берётся следующее\n\n"
        .. "Toggle: RightShift",
})

Tabs.Info:Button({
    Title = "iwakewar team — Discord",
    Description = "https://discord.gg/GgshjzxxFS",
    Callback = function()
        local ok = pcall(function() setclipboard("https://discord.gg/GgshjzxxFS") end)
        if notificationsEnabled then
            GUI:Notify({
                Title = "Discord",
                Content = ok and "Ссылка скопирована" or "Нет clipboard API",
                Duration = 2,
            })
        end
    end,
})

-- ================================================================ updater
task.spawn(function()
    while genv0.__wordgameInstance == INSTANCE do
        task.wait(0.5)
        if GUI.Unloaded then break end

        local st = match
        local stateTxt = enabled and (st and ("IN MATCH (" .. tostring(st.phase) .. ")") or "ON - жду матч...") or "OFF"
        local letter = st and st.letter ~= "" and st.letter or "-"
        pcall(function()
            Live:SetContent(string.format(
                "state: %s | letter: %s | sent: %d | ok: %d | bad: %d | miss: %d",
                stateTxt, tostring(letter), stats.sent, stats.accepted, stats.rejected, stats.misses))
        end)
        if Dict.ready then
            pcall(function()
                DictInfo:SetContent(string.format("%d слов, WPM %d", Dict.count, math.floor(wpm + 0.5)))
            end)
        end
    end
end)

genv0.__wordgameCleanup = function()
    if genv0.__wordgameInstance ~= INSTANCE then return end
    enabled = false
    if GUI and type(GUI.Destroy) == "function" then
        pcall(function() GUI:Destroy() end)
    end
end

genv0.__wordgameDebug = function()
    local st = match
    return {
        enabled = enabled,
        wpm = wpm,
        dictReady = Dict.ready,
        dictCount = Dict.count,
        phase = st and st.phase or nil,
        letter = st and st.letter or nil,
        turn = st and st.turn or nil,
        you = st and st.you or nil,
        round = st and st.round or nil,
        sent = stats.sent,
        accepted = stats.accepted,
        rejected = stats.rejected,
        misses = stats.misses,
        lastWord = lastWord,
        wordOrder = wordOrder,
        brainrot = brainrot,
        lastReject = lastReject and (tostring(lastReject.kind) .. ":" .. tostring(lastReject.reason) .. ":" .. tostring(lastReject.word)) or nil,
        histCount = (function()
            if type(match) == "table" and type(match.history) == "table" then return #match.history end
            return 0
        end)(),
        busy = busy,
    }
end
genv0.__wordgameSetEnabled = function(v)
    enabled = v and true or false
end
genv0.__wordgameSetBrainrot = function(v)
    brainrot = v and true or false
end
genv0.__wordgameSetOrder = function(v)
    if v == "short" or v == "long" or v == "random" then wordOrder = v end
end

if notificationsEnabled then
    GUI:Notify({
        Title = "WordGame Auto-Play " .. VERSION,
        Content = "Загружен. RightShift — меню.",
        Duration = 3,
    })
end
pcall(function() Window:SetToggleKey(Enum.KeyCode.RightShift) end)
