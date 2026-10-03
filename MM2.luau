-- MM2 helper by iwakewar team
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local isPhone = UIS.TouchEnabled and not UIS.KeyboardEnabled

local cfg = { farm = false, getgun = false, flingsher = false, noclip = false, clicktp = false,
  murdEsp = false, sherEsp = false }

local genv0 = getgenv()
if genv0.__mm2Fluent and type(genv0.__mm2Fluent.Destroy) == "function" then
  pcall(function() genv0.__mm2Fluent:Destroy() end)
end
local function loadGUI()
  local ok, src = pcall(readfile, "_iwakewar_gui.lua")
  if ok and src and #src > 1000 then
    return (loadstring(src))()
  end
  local url = "https://raw.githubusercontent.com/iww-dev/iwakewar-scripts/refs/heads/main/gui-lib/iwakewar-gui.luau"
  return (loadstring(game:HttpGet(url, true)))()
end
local GUI = loadGUI()
genv0.__mm2Fluent = GUI
pcall(function() GUI:SetLang("ru") end)
local Window = GUI:CreateWindow({
  Title = "MM2 Helper",
  SubTitle = "by iwakewar team",
  TabWidth = 140,
  Size = UDim2.fromOffset(640, 460),
  ToggleKey = Enum.KeyCode.RightAlt,
})
GUI._selfUrl = "https://raw.githubusercontent.com/iww-dev/iwakewar-scripts/refs/heads/main/MM2.luau"
local Tabs = {
  Info = Window:AddTab({ Title = "Info", Icon = "badge-check" }),
  Main = Window:AddTab({ Title = "Main", Icon = "" }),
  Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
}
Window:SelectTab(1)

-- Settings: пока только язык, по умолчанию русский
Tabs.Settings:AddDropdown("Lang", {
  Title = "Language / Язык",
  Values = { "Русский", "English" },
  Default = "Русский",
  Callback = function(v)
    pcall(function()
      if v == "English" then GUI:SetLang("en") else GUI:SetLang("ru") end
    end)
  end,
})
Tabs.Info:AddParagraph({
  Title = "MM2 Helper",
    Content = "Helper for Murder Mystery 2\nby iwakewar team\n\n- Coin farm (fly + noclip, nearest first)\n- Auto Get Gun (TP to dropped gun + back)\n- Auto Fling Sheriff (pendulum-ram off map at round start)\n- Murderer / Sheriff ESP\n- Ctrl+Click teleport, noclip",
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
    GUI:Notify({ Title = "MM2 Helper", Content = ok and "Discord link copied" or "No clipboard API", Duration = 3 })
  end,
})
-- mobile floating toggle is built into iwakewar-gui, nothing to do here

local function hrp() local c = LP.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function myHead()
  local c = LP.Character
  return c and (c:FindFirstChild("Head") or c:FindFirstChild("HumanoidRootPart"))
end
-- пинг для предикта (дефолт 0.12 если не прочитался)
local function getPing()
  local ok, v = pcall(function()
    return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
  end)
  if ok and typeof(v) == "number" then return v / 1000 end
  return 0.12
end
-- предсказанная позиция части с учётом велосити и пинга
local function predictPos(part)
  local base = part.Position
  local ok, vel = pcall(function() return part.Velocity end)
  if ok and vel and vel.Magnitude > 0.5 then
    return base + vel * (getPing() + 0.08)
  end
  return base
end
-- видимый аим как в Hooked: камера реально едет на врага (как шифтлок),
-- поэтому выстрел и выглядит, и валидируется как «глядя»
local function aimCameraAt(pos)
  local cam = workspace.CurrentCamera
  if not cam then return end
  pcall(function()
    cam.CFrame = CFrame.lookAt(cam.CFrame.Position, pos)
  end)
end
-- выбор части для выстрела: Head или HRP, у кого есть LOS с камеры.
-- полностью автономная (свой рейкаст и предикт внутри), возвращает часть или nil
local function pickAimPart(target)
  local ok, part = pcall(function()
    local c = target.Character
    if not c then return nil end
    local cam = workspace.CurrentCamera
    local me = hrp()
    local org = cam and cam.CFrame.Position or (me and me.Position)
    if not org then return nil end
    local ping = 0.12
    pcall(function()
      local v = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
      if typeof(v) == "number" then ping = v / 1000 end
    end)
    local cands = {}
    local head, hrpT = c:FindFirstChild("Head"), c:FindFirstChild("HumanoidRootPart")
    if head and head:IsA("BasePart") then table.insert(cands, head) end
    if hrpT and hrpT:IsA("BasePart") then table.insert(cands, hrpT) end
    local best, bestD = nil, nil
    for _, p in ipairs(cands) do
      local pos = p.Position
      local vel = p.Velocity
      if vel and vel.Magnitude > 0.5 then
        pos = pos + vel * (ping + 0.08)
      end
      local rp = RaycastParams.new()
      rp.FilterType = Enum.RaycastFilterType.Exclude
      rp.FilterDescendantsInstances = { LP.Character }
      local hit = workspace:Raycast(org, pos - org, rp)
      local clear = false
      if not hit then
        clear = true
      else
        local m2 = hit.Instance and hit.Instance:FindFirstAncestorOfClass("Model")
        if m2 and Players:GetPlayerFromCharacter(m2) ~= nil then clear = true end
      end
      if clear then
        local d = me and (p.Position - me.Position).Magnitude or 0
        if bestD == nil or d < bestD then best, bestD = p, d end
      end
    end
    return best
  end)
  if ok then return part end
  return nil
end
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
  local hh = c and c:FindFirstChildOfClass("Humanoid")
  if not c or not hh or hh.Health <= 0 then return false, "target dead" end
  local gun = hasTool("Gun")
  if not gun then return false, "no gun" end
  local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
  if not hum or hum.Health <= 0 then return false, "we dead" end
  if gun.Parent ~= LP.Character then pcall(function() hum:EquipTool(gun) end) task.wait(0.3) end
  local part = pickAimPart(target)
  if not part then return false, "no clear shot" end
  local shoot = gun:FindFirstChild("ShootGun", true)
  if not shoot then return false, "no ShootGun" end
  -- Hooked-style: сначала ПЕРС разворачивается на врага (как шифтлок),
  -- потом камера, потом выстрел в предсказанную точку. без разворота
  -- перса сервер режет выстрел (смотрит в стену, попадает в спину себе).
  local aimPos = predictPos(part)
  local myHrp = hrp()
  if myHrp then
    pcall(function()
      myHrp.CFrame = CFrame.lookAt(myHrp.Position, Vector3.new(aimPos.X, myHrp.Position.Y, aimPos.Z))
    end)
  end
  aimCameraAt(aimPos)
  task.wait(0.05)
  local ok, res = pcall(function()
    return shoot:InvokeServer(1, aimPos, "AH2")
  end)
  if not ok then return false, "invoke: " .. tostring(res):sub(1, 40) end
  return true, tostring(res):sub(1, 40)
end
-- выстрел с проверкой результата: если мёртв/уронил нож — попали
local function shootUntilDead(target, tries)
  local lastWhy = "?"
  for i = 1, (tries or 3) do
    local ok, why = shootAt(target)
    lastWhy = why
    if not ok and why ~= "invoked" then
      -- тех.проблема (нет пушки/прицела), а не промах — дальше нет смысла
      if why == "no gun" or why == "no ShootGun" or why == "no clear shot" or why == "we dead" or why == "target dead" then
        return false, why
      end
    end
    task.wait(0.5)
    local c = target.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    local hasKnife = c and c:FindFirstChild("Knife")
    if not c or not h or h.Health <= 0 or not hasKnife then
      return true, "down"
    end
  end
  return false, lastWhy
end

local farmTog = Tabs.Main:AddToggle("FarmTog", { Title = "Coin's Farm", Description = "Fly 36 studs/s, noclip, nearest first", Default = false })
farmTog:OnChanged(function() cfg.farm = farmTog.Value end)
local getGunTog = Tabs.Main:AddToggle("GetGun", { Title = "Auto Get Gun", Description = "TP to dropped gun, grab it, TP back", Default = false })
getGunTog:OnChanged(function() cfg.getgun = getGunTog.Value end)
local flingTog = Tabs.Main:AddToggle("FlingSher", { Title = "Auto Fling Sheriff", Description = "Pendulum-ram sheriff off map at round start", Default = false })
flingTog:OnChanged(function()
  cfg.flingsher = flingTog.Value
  if cfg.flingsher then task.spawn(function() task.wait(2) tryFlingSheriff() end) end
end)
local function espTog(id, title, desc, key, tool, color)
  local t = Tabs.Main:AddToggle(id, { Title = title, Description = desc, Default = false })
  t:OnChanged(function() cfg[key] = t.Value end)
  return t
end
espTog("MurdESP", "Murderer ESP", "Highlight murderer red", "murdEsp", "Knife", Color3.fromRGB(255, 40, 40))
espTog("SherESP", "Sheriff ESP", "Highlight sheriff blue", "sherEsp", "Gun", Color3.fromRGB(60, 140, 255))
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

-- dropped gun: Tool "Gun" lying in workspace (sheriff died)
local function findDroppedGun()
  for _, w in ipairs(workspace:GetDescendants()) do
    if (w:IsA("Tool") or w:IsA("BackpackItem")) and w.Name == "Gun" and w.Parent == workspace then
      local handle = w:FindFirstChild("Handle") or w:FindFirstChildWhichIsA("BasePart")
      if handle then return w, handle end
    end
  end
  return nil
end

local gunBusy = false
local function tryGetGun()
  if gunBusy or hasTool("Gun") then return end
  local h = hrp()
  if not h then return end
  local _, handle = findDroppedGun()
  if not handle then return end
  gunBusy = true
  task.spawn(function()
    local back = hrp() and hrp().Position
    local t0 = os.clock()
    while os.clock() - t0 < 4 and not hasTool("Gun") do
      local hh = hrp()
      if not hh then break end
      if handle.Parent then
        hh.CFrame = CFrame.new(handle.Position + Vector3.new(0, 3, 0))
      else
        break
      end
      task.wait(0.15)
    end
    task.wait(0.3)
    local hb = hrp()
    if hb and back then hb.CFrame = CFrame.new(back) end
    gunBusy = false
  end)
end

-- pendulum ram (same idea as UltraFling): asymmetric snap across the
-- victim with spin + noclip, momentum goes along fling axis, then release
local flingBusy = false
local function mapOutward(fromPos)
  local cc = coinContainer()
  if cc then
    local sum, n = Vector3.new(0, 0, 0), 0
    for _, c in ipairs(cc:GetChildren()) do
      if c:IsA("BasePart") then sum = sum + c.Position n = n + 1 end
    end
    if n > 0 then
      local center = sum / n
      local flat = Vector3.new(fromPos.X - center.X, 0, fromPos.Z - center.Z)
      if flat.Magnitude > 1 then return flat.Unit end
    end
  end
  return Vector3.new(0, 0, 1)
end

local function pendulumFling(target, dur)
  if flingBusy then return end
  local tc = target.Character
  local th = tc and tc:FindFirstChild("HumanoidRootPart")
  local me = hrp()
  if not th or not me then return end
  flingBusy = true
  task.spawn(function()
    local back = me.Position
    local saved = {}
    local c = LP.Character
    local axis = mapOutward(th.Position) + Vector3.new(0, 0.7, 0)
    local spin, phase, t0 = 0, false, os.clock()
    while os.clock() - t0 < (dur or 4) and flingBusy do
      local h = hrp()
      local ch = target.Character
      local hh = ch and ch:FindFirstChildOfClass("Humanoid")
      th = ch and ch:FindFirstChild("HumanoidRootPart")
      if not h or not th or not hh or hh.Health <= 0 then break end
      for _, v in ipairs(LP.Character:GetDescendants()) do
        if v:IsA("BasePart") then
          if saved[v] == nil then saved[v] = v.CanCollide end
          v.CanCollide = false
        end
      end
      phase = not phase
      local k = phase and 3 or -0.9
      spin = spin + 1.1
      pcall(function()
        h.CFrame = CFrame.new(th.Position + Vector3.new(0, 1.5, 0) + axis * k) * CFrame.Angles(0, spin, 0.4)
        h.AssemblyAngularVelocity = Vector3.new(0, 60, 12)
      end)
      game:GetService("RunService").Heartbeat:Wait()
    end
    local h = hrp()
    if h then
      pcall(function()
        h.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        h.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        h.CFrame = CFrame.new(back)
      end)
    end
    for p, v in pairs(saved) do
      pcall(function() if p and p.Parent then p.CanCollide = v end end)
    end
    flingBusy = false
  end)
end

function tryFlingSheriff()
  if not cfg.flingsher then return end
  local h = hrp()
  local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
  if not h or not hum or hum.Health <= 0 then return end
  if not inMatch() then return end
  local s = findRole("Gun")
  if s and s.Character then
    local sh = s.Character:FindFirstChildOfClass("Humanoid")
    if sh and sh.Health > 0 then
      pendulumFling(s, 4)
    end
  end
end

-- round start (coins pop) -> fling sheriff off map
pcall(function()
  local gp = RS.Remotes.Gameplay
  local rs = gp and gp:FindFirstChild("RoundStart")
  if rs then
    rs.OnClientEvent:Connect(function()
      if cfg.flingsher then
        task.spawn(function()
          task.wait(4)
          tryFlingSheriff()
        end)
      end
    end)
  end
end)

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
    if cfg.getgun and not dead and inMatch() and not hasTool("Gun") then
      tryGetGun()
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
