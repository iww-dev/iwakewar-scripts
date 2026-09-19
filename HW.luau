-- Hidden Within ESP + Aimbot by iwakewar team
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local LP = Players.LocalPlayer
local CAM = workspace.CurrentCamera
local isPhone = UIS.TouchEnabled and not UIS.KeyboardEnabled

local cfg = { esp = true, aimbot = true, maxDist = 50, speed = 34, hitbox = true, hitboxSize = 1.4, gundis = true, god = false }
local gunOrig = nil

local genv0 = getgenv()
if genv0.__hwFluent and type(genv0.__hwFluent.Destroy) == "function" then
  pcall(function() genv0.__hwFluent:Destroy() end)
end
local Fluent = loadstring(readfile("_fluent.lua"))()
genv0.__hwFluent = Fluent
local Window = Fluent:CreateWindow({
  Title = "Hidden Within",
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
  Title = "Hidden Within",
  Content = "ESP + Aimbot for Hidden Within\nby iwakewar team\n\n- ESP: roles, HP, distance\n- Aimbot: instant snap to nearest survivor (killer only)",
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
    Fluent:Notify({ Title = "Hidden Within", Content = ok and "Discord link copied" or "No clipboard API", Duration = 3 })
  end,
})
if isPhone then
do
  pcall(function() game:GetService("CoreGui").HWtoggle:Destroy() end)
  local sg = Instance.new("ScreenGui")
  sg.Name = "HWtoggle" sg.ResetOnSpawn = false
  pcall(function() sg.Parent = game:GetService("CoreGui") end)
  if sg.Parent == nil then sg.Parent = LP.PlayerGui end
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
      local g = Fluent.GUI
      if g then g.Enabled = not g.Enabled end
    end
  end)
end
end

local espTog = Tabs.Main:AddToggle("EspTog", { Title = "ESP", Description = "Roles, HP, distance", Default = true })
espTog:OnChanged(function() cfg.esp = espTog.Value end)
local aimBtn = nil
local aimTog = Tabs.Main:AddToggle("AimTog", { Title = "Aimbot", Description = "Killer: snap to survivors. Survivor: snap to killers.", Default = true })
aimTog:OnChanged(function()
  cfg.aimbot = aimTog.Value
  if aimBtn then pcall(function()
    aimBtn.BackgroundColor3 = aimTog.Value and Color3.fromRGB(0, 170, 80) or Color3.fromRGB(30, 32, 40)
  end) end
end)
local distSld = Tabs.Main:AddSlider("DistSld", {
  Title = "Max aim distance", Description = "Studs",
  Default = 50, Min = 10, Max = 500, Rounding = 0,
})
distSld:OnChanged(function(v) cfg.maxDist = v end)
local speedSld = Tabs.Main:AddSlider("SpeedSld", {
  Title = "Speed hack", Description = "WalkSpeed",
  Default = 34, Min = 16, Max = 120, Rounding = 0,
})
speedSld:OnChanged(function(v) cfg.speed = v end)
local hbTog = Tabs.Main:AddToggle("HbTog", { Title = "Hitbox Expander", Description = "Inflate enemy Head+Torso locally", Default = true })
hbTog:OnChanged(function() cfg.hitbox = hbTog.Value end)
local hbSld = Tabs.Main:AddSlider("HbSld", {
  Title = "Hitbox size", Description = "Multiplier",
  Default = 1.4, Min = 1, Max = 5, Rounding = 1,
})
hbSld:OnChanged(function(v) cfg.hitboxSize = v end)
local gdTog = Tabs.Main:AddToggle("GdTog", { Title = "Gun Disbalance", Description = "FireRate/Range/Clip/Reload maxed", Default = true })
gdTog:OnChanged(function() cfg.gundis = gdTog.Value end)

-- Floating AIM button (phone only)
if isPhone then
do
  pcall(function() game:GetService("CoreGui").HWaim:Destroy() end)
  local sg = Instance.new("ScreenGui")
  sg.Name = "HWaim" sg.ResetOnSpawn = false
  pcall(function() sg.Parent = game:GetService("CoreGui") end)
  if sg.Parent == nil then sg.Parent = LP.PlayerGui end
  local b = Instance.new("TextButton")
  b.Size = UDim2.fromOffset(52, 52)
  b.Position = UDim2.new(1, -70, 0.5, -26)
  b.Text = "AIM" b.TextSize = 14
  b.BackgroundColor3 = cfg.aimbot and Color3.fromRGB(0, 170, 80) or Color3.fromRGB(30, 32, 40)
  b.TextColor3 = Color3.new(1, 1, 1)
  b.Parent = sg
  local cc = Instance.new("UICorner") cc.CornerRadius = UDim.new(1, 0) cc.Parent = b
  aimBtn = b
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
      pcall(function() aimTog:SetValue(not cfg.aimbot) end)
    end
  end)
end
end
local godTog = Tabs.Main:AddToggle("GodTog", { Title = "Godmode", Description = "Server gets fake hitbox position", Default = false })
godTog:OnChanged(function() cfg.god = godTog.Value end)

local genv = getgenv()
genv.__hwGen = (genv.__hwGen or 0) + 1
local myGen = genv.__hwGen
STATE = STATE or {}
local running = true
if STATE.onCleanup then STATE.onCleanup(function() running = false end) end
local function alive()
  if genv.__hwGen ~= myGen then return false end
  if not running then return false end
  if STATE.alive then return STATE.alive() end
  return true
end

local function log(m) print("[HW] " .. m) end
local function isKiller(p) return p:GetAttribute("Killer") == true end
local function roundLive()
  local st = game.ReplicatedStorage:FindFirstChild("Shared")
  st = st and st:FindFirstChild("States")
  st = st and st:FindFirstChild("RoundState")
  return st == nil or st.Value == "RoundInProgress"
end
local function charOf(p)
  local alive1 = workspace:FindFirstChild("Alive")
  alive1 = alive1 and alive1:FindFirstChild("Players")
  local m = alive1 and alive1:FindFirstChild(p.Name)
  if m then return m end
  return p.Character
end
local function hpOf(model)
  local h = model and model:FindFirstChildOfClass("Humanoid")
  return h and h.Health or nil
end
local function headPosOf(model)
  local hp = model and (model:FindFirstChild("Head") or model:FindFirstChild("Torso") or model:FindFirstChild("HumanoidRootPart"))
  return hp and hp.Position or nil
end
local function roleOf(p)
  if isKiller(p) then return "KILLER", Color3.fromRGB(255, 60, 60) end
  if p:GetAttribute("Vigilante") == true then return "VIGILANTE", Color3.fromRGB(255, 200, 60) end
  return "SURVIVOR", Color3.fromRGB(80, 255, 120)
end

-- ESP (Drawing text)
local drawings = {}
local function clearDrawings()
  for _, d in ipairs(drawings) do pcall(function() d:Remove() end) end
  drawings = {}
end
if STATE.onCleanup then STATE.onCleanup(clearDrawings) end
task.spawn(function()
  while alive() do
    RS.RenderStepped:Wait()
    if not cfg.esp then
      if #drawings > 0 then clearDrawings() end
      continue
    end
    local myChar = charOf(LP)
    local myPos = headPosOf(myChar)
    local want = {}
    for _, p in ipairs(Players:GetPlayers()) do
      if p ~= LP then
        local m = charOf(p)
        local hp = hpOf(m)
        if m and hp and hp > 0 then
          local pos = headPosOf(m)
          if pos then
            local sp, onScreen = CAM:WorldToViewportPoint(pos + Vector3.new(0, 1.5, 0))
            if onScreen then
              local role, col = roleOf(p)
              local dist = myPos and math.floor((pos - myPos).Magnitude) or -1
              table.insert(want, { x = sp.X, y = sp.Y, col = col,
                txt = "[" .. role .. "] " .. p.Name .. " | " .. math.floor(hp) .. "hp | " .. dist .. "m" })
            end
          end
        end
      end
    end
    while #drawings < #want do
      local t = Drawing.new("Text")
      t.Size = 14 t.Center = true t.Outline = true
      t.Font = 2
      table.insert(drawings, t)
    end
    while #drawings > #want do
      local d = table.remove(drawings)
      pcall(function() d:Remove() end)
    end
    for i, w in ipairs(want) do
      local d = drawings[i]
      d.Visible = true
      d.Position = Vector2.new(w.x, w.y)
      d.Color = w.col
      d.Text = w.txt
    end
  end
end)

-- Aimbot: sticky lock by UserId, holds last position through flicker
local lockedUid, lockedPos, invalidSince, amKiller = nil, nil, nil, false
local function validTarget(p)
  if p == LP then return false end
  local m = charOf(p)
  local hp = hpOf(m)
  if not m or not hp or hp <= 0 then return false end
  if amKiller then
    if isKiller(p) then return false end
  else
    if not isKiller(p) then return false end
  end
  return true
end
local function nearestSurvivor(maxD)
  local myChar = charOf(LP)
  local myPos = headPosOf(myChar)
  if not myPos then return nil end
  local best, bestD = nil, maxD or math.huge
  for _, p in ipairs(Players:GetPlayers()) do
    if validTarget(p) then
      local pos = headPosOf(charOf(p))
      if pos then
        local d = (pos - myPos).Magnitude
        if d < bestD then best, bestD = p, d end
      end
    end
  end
  return best
end
task.spawn(function()
  while alive() do
    RS.RenderStepped:Wait()
    amKiller = LP:GetAttribute("Killer") == true
    if not cfg.aimbot or not roundLive() then
      lockedUid, lockedPos, invalidSince = nil, nil, nil
      continue
    end
    local engage = false
    if isPhone then
      engage = true
    else
      engage = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    end
    if not engage then
      lockedUid, lockedPos, invalidSince = nil, nil, nil
      continue
    end
    local target = lockedUid and Players:GetPlayerByUserId(lockedUid) or nil
    if target and validTarget(target) then
      invalidSince = nil
    else
      if target and invalidSince == nil then invalidSince = os.clock() end
      if target == nil or (invalidSince and os.clock() - invalidSince > 1.0) then
        target = nearestSurvivor(cfg.maxDist)
        if target then
          lockedUid = target.UserId
          invalidSince = nil
        else
          lockedUid = nil
        end
      end
    end
    local m = target and charOf(target) or nil
    local tp = m and headPosOf(m) or nil
    if tp then lockedPos = tp end
    if lockedPos then
      CAM.CFrame = CFrame.lookAt(CAM.CFrame.Position, lockedPos)
    end
  end
end)

log("ready")

-- Godmode: lie to ALL server hitbox queries (one handler per player, hook them all)
local godHooks = {}
local function setGodmode(on)
  if on then
    local n = 0
    for _, f in filtergc("function", {}, false) do
      local okS, src = pcall(debug.info, f, "s")
      local _, ln = pcall(debug.info, f, "l")
      if okS and type(src) == "string" and string.find(src, "HitboxController", 1, true) and ln == 15 and not godHooks[f] then
        local okH, orig = pcall(hookfunction, f, function() return CFrame.new(0, -10000, 0) end)
        if okH then godHooks[f] = orig n = n + 1 end
      end
    end
    if n > 0 then log("godmode hooked " .. n) end
  else
    local n = 0
    for f, orig in pairs(godHooks) do
      if pcall(hookfunction, f, orig) then n = n + 1 end
    end
    godHooks = {}
    if n > 0 then log("godmode off (" .. n .. ")") end
  end
end
task.spawn(function()
  while alive() do
    task.wait(5)
    if cfg.god then setGodmode(true) end
  end
end)
LP.CharacterAdded:Connect(function()
  if cfg.god then task.wait(2) if alive() and cfg.god then setGodmode(true) end end
end)

-- Hitbox Expander: invisible inflated hitboxes (visual unchanged, raycast still hits)
local hbOrig = {}
task.spawn(function()
  while alive() do
    task.wait(0.5)
    if cfg.hitbox then
      for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
          local m = charOf(p)
          if m then
            for _, n in ipairs({ "Head", "Torso" }) do
              local part = m:FindFirstChild(n)
              if part and part:IsA("BasePart") then
                if not hbOrig[part] then
                  hbOrig[part] = { part.Size, part.Transparency }
                  pcall(function() part.Massless = true end)
                  pcall(function() part.CanCollide = false end)
                  pcall(function() part.CanTouch = false end)
                end
                local s = hbOrig[part][1] * cfg.hitboxSize
                pcall(function() part.Size = s end)
                pcall(function() part.Transparency = 1 end)
              end
            end
          end
        end
      end
    elseif next(hbOrig) then
      for part, o in pairs(hbOrig) do
        pcall(function() part.Size = o[1] end)
        pcall(function() part.Transparency = o[2] end)
      end
      hbOrig = {}
    end
  end
end)

-- Gun Disbalance: max out shared GunConfig table
task.spawn(function()
  while alive() do
    task.wait(0.5)
    local ok, GC = pcall(require, game.ReplicatedStorage.Shared.Modules.Configs.GunConfig)
    if ok and type(GC) == "table" then
      if cfg.gundis and not gunOrig then
        gunOrig = {}
        for name, t in pairs(GC) do
          if type(t) == "table" then
            gunOrig[name] = {}
            for _, k in ipairs({ "FireRate", "ClipSize", "Range", "ReloadTime", "Auto" }) do
              gunOrig[name][k] = t[k]
            end
            t.FireRate = 0.01
            t.ClipSize = 999
            t.Range = 2000
            t.ReloadTime = 0.1
            t.Auto = true
            if t.RecoilForce ~= nil then t.RecoilForce = Vector3.zero end
          end
        end
        log("guns maxed")
      elseif not cfg.gundis and gunOrig then
        for name, t in pairs(GC) do
          if type(t) == "table" and gunOrig[name] then
            for k, v in pairs(gunOrig[name]) do t[k] = v end
          end
        end
        gunOrig = nil
        log("guns restored")
      end
    end
  end
end)

-- Speed hack: WalkSpeed + physical push along move direction
task.spawn(function()
  while alive() do
    local dt = RS.Heartbeat:Wait()
    if cfg.speed ~= 16 then
      local c = LP.Character
      local h = c and c:FindFirstChildOfClass("Humanoid")
      local hrp = c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso"))
      if h and hrp then
        pcall(function() h.WalkSpeed = cfg.speed end)
        local md = h.MoveDirection
        if md.Magnitude > 0.1 then
          local extra = math.max(0, cfg.speed - 16) * math.min(dt, 0.05)
          hrp.CFrame = hrp.CFrame + md * extra
        end
      end
    end
  end
end)
