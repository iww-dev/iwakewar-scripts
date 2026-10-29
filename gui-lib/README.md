# PrimordialUI

Своя GUI-либа для наших скриптов: плоский тёмный хаб в стиле «primordial» —
слева категории, сверху полоска под-табов, справа карточки с шапкой и
компактными строками. Без зависимостей, один файл.

```lua
local UI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/iww-dev/iwakewar-scripts/refs/heads/main/gui-lib/PrimordialUI.luau"
))()

local Window = UI:CreateWindow({
    Title = "iwakewar: BFNFR",
    Subtitle = "by iwakewar team",
    Footer = "by iwakewar team",
    Version = "v3.1",
    Size = UDim2.fromOffset(760, 500),
})

local Tab = Window:Tab({ Title = "Controls", Subtitle = "Auto-play settings" })
Tab:Section({ Title = "Main Functions" })

Tab:Paragraph({ Title = "Status", Content = "OFF" })
Tab:Toggle({ Title = "Auto-Play", Description = "Toggle automatic key presses", Default = true, Callback = print })
Tab:Dropdown({ Title = "Side", Values = { "Auto", "P1", "P2" }, Value = "Auto", Callback = print })
Tab:Keybind({ Title = "Toggle keybind", Mode = "Toggle", Default = "H", Callback = print })
Tab:Slider({ Title = "Delay", Min = 0, Max = 100, Value = 42, Callback = print })
Tab:Button({ Title = "Discord", Description = "Copy invite link", Callback = print })

UI:Notify({ Title = "Loaded", Content = "Ready", Duration = 4 })
```

Шрифт — JosefinSans (Light/Regular/Medium/SemiBold/Bold), подгружается из
`rbxasset://fonts/families/JosefinSans.json`; если рендер шрифта недоступен,
либа молча падает на Gotham. Глифы `✓ ✕ – › • — →` в нём есть, поэтому
крестик/галочку/стрелку рисуем символами, а логотип — фреймом (ромб).

## API

| Метод | Что делает |
|---|---|
| `UI:CreateWindow(cfg)` | окно: `Title`, `Subtitle`, `Footer`, `Size`, `Accent`, `ToggleKey` |
| `Window:Tab(cfg)` | вкладка в сайдбаре: `Title`, `Subtitle` |
| `Window:SelectTab(n)` / `Window:SetToggleKey(key)` | выбрать вкладку / клавиша показа окна |
| `Window:Show()`, `Hide()`, `Toggle()`, `Destroy()` | видимость и удаление |
| `Tab:Section({Title})` | отдельная секция: чипсы сверху, видна только одна секция |
| `Tab:Paragraph({Title, Content})` | карточка с текстом |
| `Tab:Toggle({Title, Description, Default, Callback})` | чекбокс |
| `Tab:Dropdown({Title, Description, Values, Value, Callback})` | выпадающий список |
| `Tab:Keybind({Title, Description, Mode, Default, Callback})` | бинд, `Mode = "Toggle"` или `"Hold"` |
| `Tab:Slider({Title, Min, Max, Value, Callback})` | ползунок |
| `Tab:Button({Title, Description, Callback})` | кнопка-строка |
| `UI:Notify({Title, Content, Duration, Accent})` | уведомление справа сверху |
| `UI:Loader({Title, Subtitle, Status, Console, Width, Height, CloseDelay})` | сплэш-лоадер: `:SetStatus`, `:SetProgress(0-1)`, `:Log(line)`, `:Done()`, `:Fail()`, `:Destroy()` |
| `UI:OnLangChanged(fn)` / `UI:SetLang(l)` | подписка на смену языка |

## Loader mode

Для `main.luau` и любого лоадстринга — отдельный сплэш без окна и табов:

```lua
local Loader = UI:Loader({ Title = "iwakewar-scripts", Subtitle = "loader v3.1", Console = true })
Loader:SetStatus("Fetching script...")
Loader:SetProgress(0.35)
Loader:Log("GET BFNFR Auto-Play.luau")
Loader:Done("Loaded")
-- Loader:Fail("HttpGet failed") при ошибке (сам не закрывается)
```

`Console = false` убирает лог-панель, окно становится компактным. `CloseDelay`
задаёт паузу перед закрытием после `:Done()`.

## Секции

`Tab:Section()` создаёт отдельный контейнер: элементы, объявленные после него,
живут только в этой секции. Наверху вкладки появляются чипсы, первая секция
подсвечена и видна, остальные скрыты до клика. Так «Main Functions» и
«Humanizer» не висят друг под другом — переключение реально подменяет контент.

У всех элементов есть `SetTitle`, `SetDesc` (у Paragraph — `SetContent`),
у тоглов/дропдаунов/биндов/слайдеров — `SetValue`. У вкладки `Tab.btn.Text`
меняет подпись в сайдбаре, у кнопки `obj.Text` — заголовок.

API специально близок к WindUI, чтобы существующие скрипты переезжали почти
без правок.
