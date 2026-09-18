-- DOORS helper by iwakewar team
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local isPhone = UIS.TouchEnabled and not UIS.KeyboardEnabled

local cfg = { loot = false, esp = false, itemEsp = false, doorEsp = false, speedMult = 1.0, antiScreech = false }

local genv0 = getgenv()
if genv0.__doorsFluent and type(genv0.__doorsFluent.Destroy) == "function" then
  pcall(function() genv0.__doorsFluent:Destroy() end)
end
local Fluent = loadstring(readfile("_fluent.lua"))()
genv0.__doorsFluent = Fluent
local Window = Fluent:CreateWindow({
  Title = "DOORS Helper",
  SubTitle = "by iwakewar team",
  TabWidth = 140,
  Size = isPhone and UDim2.fromOffset(452, 344) or UDim2.fromOffset(566, 430),
  Acrylic = false,
  Theme = "Dark",
  MinimizeKey = Enum.KeyCode.RightControl,
})
local Tabs = {
  Info = Window:AddTab({ Title = "Info", Icon = "badge-check" }),
  Main = Window:AddTab({ Title = "Main", Icon = "" }),
}
Window:SelectTab(1)
Tabs.Info:AddParagraph({
  Title = "DOORS Helper",
  Content = "Helper for DOORS\nby iwakewar team\n\n- Auto-open drawers, chests, lockers\n- Auto-loot items, gold, keys\n- Entity ESP (Rush, Ambush, Figure, Dupe...)",
})
local function copyToClipboard(text)
  local g = getgenv and getgenv() or {}
  for _, name in ipairs({ "setclipboard", "toclipboard", "writeclipboard" }) do
    local v = g[name] or rawget(_G, name)
    if typeof(v) == "function" then if pcall(v, text) then return true end end
  end
  return false
end
Tabs.Info:AddButton({
  Title = "Our Discord Server",
  Description = "Copy invite link to clipboard",
  Callback = function()
    local ok = copyToClipboard("https://discord.gg/GgshjzxxFS")
    Fluent:Notify({ Title = "DOORS Helper", Content = ok and "Discord link copied" or "No clipboard API", Duration = 3 })
  end,
})
if isPhone then
do
  pcall(function() game:GetService("CoreGui").DOORStoggle:Destroy() end)
  local sg = Instance.new("ScreenGui")
  sg.Name = "DOORStoggle" sg.ResetOnSpawn = false
  pcall(function() sg.Parent = game:GetService("CoreGui") end)
  if sg.Parent == nil then sg.Parent = LP.PlayerGui end
  local b = Instance.new("TextButton")
  b.Size = UDim2.fromOffset(40, 40)
  b.Position = UDim2.new(0.5, -20, 0.5, -260)
  b.Text = "D" b.TextSize = 18
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
      local g = Fluent.GUI
      if g then g.Enabled = not g.Enabled end
    end
  end)
end
end

local PROMPTS = {
  ActivateEventPrompt = true,
  LootPrompt = true,
  ModulePrompt = true,
  InteractPrompt = true,
  ManualOpenPrompt = true,
  UnlockPrompt = false,
  HidePrompt = false,
  SeatPrompt = false,
}
local SKIP_PARENT = { Painting_Big = true, Painting_Small = true, Painting_Tall = true,
  Painting_VeryBig = true, Fireplace_Logs = true, Desk_Bell = true, Flush = true, Toilet = true }
local firedSet = {}
local function bypassPrompt(d)
  pcall(function()
    d.RequiresLineOfSight = false
  end)
end
local function promptPartPos(par)
  if par == nil then return nil end
  if par:IsA("BasePart") then return par.Position end
  local ok, cf = pcall(function() return par:GetPivot() end)
  if ok and cf then return cf.Position end
  return nil
end
local function lootRoom(room)
  local h = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
  local meP = h and h.Position or nil
  for _, d in ipairs(room:GetDescendants()) do
    if d:IsA("ProximityPrompt") and PROMPTS[d.Name] and not firedSet[d] then
      local par = d.Parent
      if not (par and SKIP_PARENT[par.Name]) then
      bypassPrompt(d)
      local okI = true
      pcall(function()
        local inter = d:GetAttribute("Interactions")
        if inter ~= nil and tonumber(inter) ~= nil and tonumber(inter) <= 0 then okI = false end
      end)
      local pp = promptPartPos(par)
      local maxD = 6
      pcall(function() maxD = d.MaxActivationDistance end)
      if okI and d.Enabled and meP and pp and (pp - meP).Magnitude <= maxD then
        pcall(function() fireproximityprompt(d) end)
      end
      end
    end
  end
end

local ENTITIES = { "rush", "ambush", "figure", "eyes", "screech", "halt", "dupe", "seek", "a60", "a120", "snare", "timothy", "jack", "hault", "blitz", "lookman", "dread", "giggle" }
local ITEM_COLORS = {
  { "keyobtain", Color3.fromRGB(255, 220, 60) },
  { "key_holder", Color3.fromRGB(255, 220, 60) },
  { "lockpick", Color3.fromRGB(200, 200, 200) },
  { "lighter", Color3.fromRGB(255, 140, 40) },
  { "flashlight", Color3.fromRGB(255, 255, 150) },
  { "bandage", Color3.fromRGB(255, 255, 255) },
  { "crucifix", Color3.fromRGB(120, 180, 255) },
  { "vitamin", Color3.fromRGB(80, 255, 140) },
  { "skeleton", Color3.fromRGB(180, 120, 255) },
  { "livehintbook", Color3.fromRGB(90, 140, 255) },
  { "goldpile", Color3.fromRGB(255, 180, 0) },
  { "gold", Color3.fromRGB(255, 180, 0) },
}
local function isEntity(inst)
  local n = inst.Name:lower()
  for _, e in ipairs(ENTITIES) do
    if n:find(e) then
      local m = inst
      if not m:IsA("Model") then
        m = m:FindFirstAncestorOfClass("Model")
      end
      return e, m or inst
    end
  end
  return nil
end
local function espModel(m, label, color)
  if m:FindFirstChild("DOORSesp") then return end
  local h = Instance.new("Highlight")
  h.Name = "DOORSesp"
  h.FillColor = color
  h.FillTransparency = 0.4
  h.OutlineColor = color
  h.Adornee = m
  h.Parent = m
  print("[DOORS] ESP " .. label .. ": " .. m:GetFullName())
end
local function findScreech(maxD)
  local h = hrp()
  if not h then return nil end
  local best, bestD = nil, nil
  for _, d in ipairs(workspace:GetDescendants()) do
    if d:IsA("Model") and d.Name:lower():find("screech") then
      if not d:IsDescendantOf(game.ReplicatedStorage) then
        local pivOK, piv = pcall(function() return d:GetPivot() end)
        if pivOK and piv then
          local dist = (piv.Position - h.Position).Magnitude
          if dist <= (maxD or 60) and (bestD == nil or dist < bestD) then
            best, bestD = piv.Position, dist
          end
        end
      end
    end
  end
  return best
end

local function scanESP()
  for _, d in ipairs(workspace:GetDescendants()) do
    if d ~= workspace then
      local e, m = isEntity(d)
      if e and m then
        espModel(m, e, Color3.fromRGB(255, 40, 40))
      elseif cfg.itemEsp and (d:IsA("Model") or d:IsA("Tool")) then
        local n = d.Name:lower()
        for _, it in ipairs(ITEM_COLORS) do
          if n:find(it[1]) then espModel(d, it[1], it[2]) break end
        end
      end
    end
  end
end
local lastDoorN = nil
local function doorESP()
  local cr = workspace:FindFirstChild("CurrentRooms")
  if not cr then return end
  local latest = nil
  pcall(function()
    local gd = RS:FindFirstChild("GameData")
    local lr = gd and gd:FindFirstChild("LatestRoom")
    latest = lr and lr.Value
  end)
  if latest == nil then return end
  local nextN = tostring(latest + 1)
  if latest == 50 then nextN = "51" end
  if lastDoorN ~= nil and lastDoorN ~= nextN then
    local old = cr:FindFirstChild(lastDoorN)
    local oh = old and old:FindFirstChild("DOORSdoor", true)
    if oh then oh:Destroy() end
  end
  lastDoorN = nextN
  local room = cr:FindFirstChild(nextN)
  local door = room and room:FindFirstChild("Door", true)
  if door and not door:FindFirstChild("DOORSdoor") then
    local h = Instance.new("Highlight")
    h.Name = "DOORSdoor"
    h.FillColor = Color3.fromRGB(60, 255, 90)
    h.FillTransparency = 0.4
    h.OutlineColor = Color3.fromRGB(60, 255, 90)
    h.Adornee = door
    h.Parent = door
  end
end

local lootTog = Tabs.Main:AddToggle("LootTog", { Title = "Auto-loot", Description = "Open containers, take items, gold, keys", Default = false })
lootTog:OnChanged(function() cfg.loot = lootTog.Value end)
local espTog = Tabs.Main:AddToggle("ESPTog", { Title = "Entity ESP", Description = "Rush, Ambush, Figure, Dupe...", Default = false })
espTog:OnChanged(function() cfg.esp = espTog.Value end)
local itemTog = Tabs.Main:AddToggle("ItemTog", { Title = "Item ESP", Description = "Keys, lockpicks, lighter, flashlight, bandage, books, gold", Default = false })
itemTog:OnChanged(function() cfg.itemEsp = itemTog.Value end)
local doorTog = Tabs.Main:AddToggle("DoorTog", { Title = "Door ESP", Description = "Highlight next correct door green", Default = false })
doorTog:OnChanged(function() cfg.doorEsp = doorTog.Value end)
local speedSld = Tabs.Main:AddSlider("SpeedSld", {
  Title = "Speedhack", Description = "WalkSpeed multiplier (with bypass)",
  Default = 100, Min = 100, Max = 200, Rounding = 0,
})
speedSld:OnChanged(function(v) cfg.speedMult = v / 100 end)
local baseWS = 16
do
  local ch0 = LP.Character
  local h0 = ch0 and ch0:FindFirstChildOfClass("Humanoid")
  if h0 and h0.WalkSpeed > 0 then baseWS = h0.WalkSpeed end
end
pcall(function()
  local oldIndex
  oldIndex = hookmetamethod(game, "__index", function(self, key)
    if not checkcaller() and key == "WalkSpeed"
      and typeof(self) == "Instance" and self:IsA("Humanoid")
      and LP.Character and self:IsDescendantOf(LP.Character) then
      return 16
    end
    return oldIndex(self, key)
  end)
end)

local genv = getgenv()
genv.__doorsGen = (genv.__doorsGen or 0) + 1
local myGen = genv.__doorsGen
STATE = STATE or {}
local running = true
if STATE.onCleanup then STATE.onCleanup(function() running = false end) end
local function alive()
  if genv.__doorsGen ~= myGen then return false end
  if not running then return false end
  if STATE.alive then return STATE.alive() end
  return true
end

workspace.ChildAdded:Connect(function(c)
  if genv.__doorsGen ~= myGen then return end
  if not cfg.esp then return end
  local e, m = isEntity(c)
  if e and m then espModel(m, e, Color3.fromRGB(255, 40, 40)) end
end)

task.spawn(function()
  print("[DOORS] ready")
  local tick = 0
  while alive() do
    tick = tick + 1
    if tick % 30 == 0 then
      local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
      if h then
        if cfg.speedMult <= 1.0 then baseWS = h.WalkSpeed
        else pcall(function() h.WalkSpeed = baseWS * cfg.speedMult end) end
      end
    end
    if cfg.loot then
      local cr = workspace:FindFirstChild("CurrentRooms")
      if cr then
        local latest = nil
        pcall(function()
          local gd = RS:FindFirstChild("GameData")
          local lr = gd and gd:FindFirstChild("LatestRoom")
          latest = lr and lr.Value
        end)
        for _, room in ipairs(cr:GetChildren()) do
          if not alive() or not cfg.loot then break end
          local rn = tonumber(room.Name)
          if rn == nil or latest == nil or math.abs(rn - latest) <= 1 then
            lootRoom(room)
          end
        end
      end
      task.wait(0.1)
    else
      task.wait(0.5)
    end
    if cfg.esp or cfg.itemEsp then
      pcall(scanESP)
    end
    if cfg.doorEsp then
      pcall(doorESP)
    end
    if cfg.esp or cfg.itemEsp or cfg.doorEsp then
      task.wait(1)
    end
    if cfg.antiScreech then
      local sp = findScreech(60)
      if sp then
        local cam = workspace.CurrentCamera
        local t0 = os.clock()
        while alive() and cfg.antiScreech and os.clock() - t0 < 2.5 do
          local cur = findScreech(80)
          if not cur then break end
          pcall(function()
            cam.CFrame = CFrame.lookAt(cam.CFrame.Position, cur)
          end)
          task.wait(0.05)
        end
      else
        task.wait(0.3)
      end
    end
  end
end)
