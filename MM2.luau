-- MM2 helper by iwakewar team
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local isPhone = UIS.TouchEnabled and not UIS.KeyboardEnabled

local cfg = { farm = false, autoshoot = false, noclip = false, clicktp = false,
  murdEsp = false, sherEsp = false }

local genv0 = getgenv()
if genv0.__mm2Fluent and type(genv0.__mm2Fluent.Destroy) == "function" then
  pcall(function() genv0.__mm2Fluent:Destroy() end)
end
local Fluent = loadstring(readfile("_fluent.lua"))()
genv0.__mm2Fluent = Fluent
local Window = Fluent:CreateWindow({
  Title = "MM2 Helper",
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
  Title = "MM2 Helper",
  Content = "Helper for Murder Mystery 2\nby iwakewar team\n\n- Coin farm (fly + noclip, nearest first)\n- Shoot murderer keybind\n- Murderer / Sheriff ESP\n- Auto-shoot with wall check\n- Ctrl+Click teleport, noclip",
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
    Fluent:Notify({ Title = "MM2 Helper", Content = ok and "Discord link copied" or "No clipboard API", Duration = 3 })
  end,
})
if isPhone then
do
  pcall(function() game:GetService("CoreGui").MM2toggle:Destroy() end)
  local sg = Instance.new("ScreenGui")
  sg.Name = "MM2toggle" sg.ResetOnSpawn = false
  pcall(function() sg.Parent = game:GetService("CoreGui") end)
  if sg.Parent == nil then sg.Parent = LP.PlayerGui end
  local b = Instance.new("TextButton")
  b.Size = UDim2.fromOffset(40, 40)
  b.Position = UDim2.new(0.5, -20, 0.5, -260)
  b.Text = "M" b.TextSize = 18
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

local function hrp() local c = LP.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function hasTool(name)
  local c = LP.Character
  if c and c:FindFirstChild(name) then return c:FindFirstChild(name) end
  local b = LP:FindFirstChild("Backpack")
  if b and b:FindFirstChild(name) then return b:FindFirstChild(name) end
  return nil
end
local function findRole(toolName)
  for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP then
      local c = p.Character
      local h = c and c:FindFirstChildOfClass("Humanoid")
      if c and h and h.Health > 0 then
        if c:FindFirstChild(toolName) then return p end
        local b = p:FindFirstChild("Backpack")
        if b and b:FindFirstChild(toolName) then return p end
      end
    end
  end
  return nil
end
local function hasLOS(targetPos)
  local cam = workspace.CurrentCamera
  local org = cam and cam.CFrame.Position or (hrp() and hrp().Position)
  if not org then return false end
  local dir = targetPos - org
  local rp = RaycastParams.new()
  rp.FilterType = Enum.RaycastFilterType.Exclude
  rp.FilterDescendantsInstances = { LP.Character }
  local hit = workspace:Raycast(org, dir, rp)
  if not hit then return true end
  local m = hit.Instance and hit.Instance:FindFirstAncestorOfClass("Model")
  return m and Players:GetPlayerFromCharacter(m) ~= nil
end
local function shootAt(target)
  if not target then return false, "no target" end
  local c = target.Character
  local th = c and c:FindFirstChild("HumanoidRootPart")
  local hh = c and c:FindFirstChildOfClass("Humanoid")
  if not th or not hh or hh.Health <= 0 then return false, "target dead" end
  local gun = hasTool("Gun")
  if not gun then return false, "no gun" end
  local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
  if hum and gun.Parent ~= LP.Character then pcall(function() hum:EquipTool(gun) end) task.wait(0.25) end
  local shoot = gun:FindFirstChild("ShootGun", true)
  if not shoot then return false, "no ShootGun" end
  local ok, err = pcall(function()
    return shoot:InvokeServer(1, th.Position, "AH2")
  end)
  return ok, tostring(err):sub(1, 60)
end

local farmTog = Tabs.Main:AddToggle("FarmTog", { Title = "Coin's Farm", Description = "Fly 36 studs/s, noclip, nearest first", Default = false })
farmTog:OnChanged(function() cfg.farm = farmTog.Value end)
local shootKey = Tabs.Main:AddKeybind("ShootKey", {
  Title = "Shoot Murderer Bind", Description = "Equip gun and fire at murderer",
  Mode = "Toggle", Default = "G",
  Callback = function()
    local m = findRole("Knife")
    if m and hasLOS(m.Character.HumanoidRootPart.Position) then
      local ok, why = shootAt(m)
      Fluent:Notify({ Title = "Shoot", Content = ok and "Fired" or tostring(why), Duration = 2 })
    else
      Fluent:Notify({ Title = "Shoot", Content = "No clear shot", Duration = 2 })
    end
  end,
})
local function espTog(id, title, desc, key, tool, color)
  local t = Tabs.Main:AddToggle(id, { Title = title, Description = desc, Default = false })
  t:OnChanged(function() cfg[key] = t.Value end)
  return t
end
espTog("MurdESP", "Murderer ESP", "Highlight murderer red", "murdEsp", "Knife", Color3.fromRGB(255, 40, 40))
espTog("SherESP", "Sheriff ESP", "Highlight sheriff blue", "sherEsp", "Gun", Color3.fromRGB(60, 140, 255))
local autoTog = Tabs.Main:AddToggle("AutoShoot", { Title = "Auto-Shoot Murderer", Description = "Auto fire when murderer visible", Default = false })
autoTog:OnChanged(function() cfg.autoshoot = autoTog.Value end)
local tpTog = Tabs.Main:AddToggle("ClickTP", { Title = "ClickTP", Description = "Ctrl + click to teleport", Default = false })
tpTog:OnChanged(function() cfg.clicktp = tpTog.Value end)
local ncTog = Tabs.Main:AddToggle("NoClip", { Title = "NoClip", Description = "Walk through walls", Default = false })
ncTog:OnChanged(function() cfg.noclip = ncTog.Value end)

local function setESP(p, color)
  local c = p.Character
  if not c then return end
  local h = c:FindFirstChildOfClass("Highlight")
  if not h then
    h = Instance.new("Highlight")
    h.Name = "MM2esp"
    h.FillTransparency = 0.5
    h.Parent = c
  end
  h.FillColor = color
  h.Enabled = true
end
local function clearESP()
  for _, p in ipairs(Players:GetPlayers()) do
    local c = p.Character
    local h = c and c:FindFirstChild("MM2esp")
    if h then h:Destroy() end
  end
end

game:GetService("RunService").Stepped:Connect(function()
  if getgenv().__mm2Gen ~= _G.__mm2GenRef then return end
  local c = LP.Character
  if c and cfg.noclip then
    for _, v in ipairs(c:GetDescendants()) do
      if v:IsA("BasePart") then v.CanCollide = false end
    end
  end
end)
UIS.InputBegan:Connect(function(input, gpe)
  if gpe then return end
  if getgenv().__mm2Gen ~= _G.__mm2GenRef then return end
  if cfg.clicktp and UIS:IsKeyDown(Enum.KeyCode.LeftControl)
    and input.UserInputType == Enum.UserInputType.MouseButton1 then
    local h = hrp()
    local m = LP:GetMouse()
    if h and m and m.Hit then
      h.CFrame = CFrame.new(m.Hit.Position + Vector3.new(0, 3, 0))
    end
  end
end)

local genv = getgenv()
genv.__mm2Gen = (genv.__mm2Gen or 0) + 1
_G.__mm2GenRef = genv.__mm2Gen
local myGen = genv.__mm2Gen
STATE = STATE or {}
local running = true
if STATE.onCleanup then STATE.onCleanup(function() running = false end) end
local function alive()
  if genv.__mm2Gen ~= myGen then return false end
  if not running then return false end
  if STATE.alive then return STATE.alive() end
  return true
end

local function bagCount()
  local mg = LP.PlayerGui:FindFirstChild("MainGUI")
  local g = mg and mg:FindFirstChild("Game")
  local cb = g and g:FindFirstChild("CoinBags")
  local c = cb and cb:FindFirstChild("Container")
  local coin = c and c:FindFirstChild("Coin")
  local cf = coin and coin:FindFirstChild("CurrencyFrame")
  local ic = cf and cf:FindFirstChild("Icon")
  local t = ic and ic:FindFirstChild("Coins")
  return tonumber(t and t.Text) or 0
end
local function bagCap()
  if LP:GetAttribute("Elite") == true then return 50 end
  return 40
end

local function coinContainer()
  for _, m in ipairs(workspace:GetChildren()) do
    if m:IsA("Model") and m.Name ~= "Lobby" and m.Name ~= "RegularLobby" then
      local cc = m:FindFirstChild("CoinContainer")
      if cc then return cc end
    end
  end
  return nil
end

local function inMatch()
  local cc = coinContainer()
  return cc ~= nil and #cc:GetChildren() > 0
end

task.spawn(function()
  print("[MM2] ready")
  local lastShot = 0
  local lastTP, lastTT = nil, 0
  local gotCoins = {}
  local dead = false
  local function watchChar(ch)
    dead = false
    local h = ch:WaitForChild("Humanoid", 10)
    if h then
      h.Died:Connect(function() dead = true end)
    end
  end
  if LP.Character then task.spawn(watchChar, LP.Character) end
  LP.CharacterAdded:Connect(function(ch)
    task.wait(2)
    watchChar(ch)
  end)
  local roundOver = false
  pcall(function()
    local gp = RS.Remotes.Gameplay
    local re = gp:FindFirstChild("RoundEndFade")
    if re then re.OnClientEvent:Connect(function() roundOver = true end) end
    local go = gp:FindFirstChild("GameOver")
    if go then go.OnClientEvent:Connect(function() roundOver = true end) end
    local rs = gp:FindFirstChild("RoundStart")
    if rs then rs.OnClientEvent:Connect(function() roundOver = false gotCoins = {} end) end
  end)
  while alive() do
    if cfg.murdEsp or cfg.sherEsp then
      clearESP()
      if cfg.murdEsp then local m = findRole("Knife") if m then setESP(m, Color3.fromRGB(255, 40, 40)) end end
      if cfg.sherEsp then local s = findRole("Gun") if s then setESP(s, Color3.fromRGB(60, 140, 255)) end end
    else
      clearESP()
    end
    if cfg.autoshoot and os.clock() - lastShot > 1.5 then
      local m = findRole("Knife")
      if m and m.Character and m.Character:FindFirstChild("HumanoidRootPart")
        and hasLOS(m.Character.HumanoidRootPart.Position) then
        local ok = shootAt(m)
        if ok then lastShot = os.clock() end
      end
    end
    if cfg.farm and not dead and inMatch() then
      local cc = coinContainer()
      if not cc or #cc:GetChildren() == 0 then gotCoins = {} end
      if bagCount() >= bagCap() then
        local h = hrp()
        if h then
          local top = h.Position + Vector3.new(0, 200, 0)
          h.CFrame = CFrame.new(top)
          while alive() and cfg.farm and not dead and not roundOver and bagCount() >= bagCap() do
            local hh = hrp()
            if hh then hh.CFrame = CFrame.new(top) end
            task.wait(0.2)
          end
        end
      end
      local h = hrp()
      if cc and h and bagCount() < bagCap() then
        local best, bestD = nil, nil
        local nowT = os.clock()
        for _, c in ipairs(cc:GetChildren()) do
          if c:IsA("BasePart") and c.Parent ~= nil and not gotCoins[c] then
            if not (lastTP and nowT - lastTT < 1.5 and (c.Position - lastTP).Magnitude < 8) then
              local d = (c.Position - h.Position).Magnitude
              if bestD == nil or d < bestD then best, bestD = c, d end
            end
          end
        end
        if best then
          local hp0 = hrp()
          if hp0 then
            hp0.CFrame = CFrame.new(best.Position + Vector3.new(0, 3, 0))
            lastTP, lastTT = best.Position, nowT
            gotCoins[best] = true
          end
          coinN = (coinN or 0) + 1
          if coinN % 2 == 0 then task.wait(2.21 + math.random() * 0.47)
          else task.wait(1.61 + math.random() * 0.41) end
        else
          task.wait(0.3)
        end
      else
        task.wait(0.3)
      end
    else
      task.wait(0.3)
    end
  end
end)
