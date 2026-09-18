-- Evade helper by iwakewar team
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local isPhone = UIS.TouchEnabled and not UIS.KeyboardEnabled

local cfg = { bhop = false, hopMode = "OnlyGround", speedMult = 1.0, botCham = false, plrCham = false,
  helpCham = false, autoTake = false, shield = false, autoRevive = false }

local genv0 = getgenv()
if genv0.__evadeFluent and type(genv0.__evadeFluent.Destroy) == "function" then
  pcall(function() genv0.__evadeFluent:Destroy() end)
end
local Fluent = loadstring(readfile("_fluent.lua"))()
genv0.__evadeFluent = Fluent
local Window = Fluent:CreateWindow({
  Title = "Evade Helper",
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
  Title = "Evade Helper",
  Content = "Helper for Evade\nby iwakewar team\n\n- BunnyHop (WASD + Space, jump every 0.082s)\n- Speedhack dropdown\n- Bots / Players / NeedHelp chams\n- Auto-take items (TP + prompt + back)",
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
    Fluent:Notify({ Title = "Evade Helper", Content = ok and "Discord link copied" or "No clipboard API", Duration = 3 })
  end,
})
if isPhone then
do
  pcall(function() game:GetService("CoreGui").EVADEtoggle:Destroy() end)
  local sg = Instance.new("ScreenGui")
  sg.Name = "EVADEtoggle" sg.ResetOnSpawn = false
  pcall(function() sg.Parent = game:GetService("CoreGui") end)
  if sg.Parent == nil then sg.Parent = LP.PlayerGui end
  local b = Instance.new("TextButton")
  b.Size = UDim2.fromOffset(40, 40)
  b.Position = UDim2.new(0.5, -20, 0.5, -260)
  b.Text = "E" b.TextSize = 18
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

local function clearChams()
  for _, d in ipairs(workspace:GetDescendants()) do
    if d.Name == "EVADEcham" or d.Name == "EVADEchamH" then pcall(function() d:Destroy() end) end
  end
end
local bhopTog = Tabs.Main:AddToggle("BhopTog", { Title = "BunnyHop", Description = "Jump spam while moving (0.082s)", Default = false })
bhopTog:OnChanged(function() cfg.bhop = bhopTog.Value end)
local hopDrop = Tabs.Main:AddDropdown("HopDrop", {
  Title = "Bhop mode", Description = "OnlyGround = jump on landing, Any = always",
  Values = { "OnlyGround", "Any" }, Multi = false, Default = 1,
})
hopDrop:OnChanged(function(v) cfg.hopMode = v end)
local speedDrop = Tabs.Main:AddDropdown("SpeedDrop", {
  Title = "Speedhack", Description = "WalkSpeed multiplier",
  Values = { "x1.0", "x1.05", "x1.10", "x1.11", "x1.14", "x1.18", "x1.19+" },
  Multi = false, Default = 1,
})
speedDrop:OnChanged(function(v)
  if v:sub(-1) == "+" then cfg.speedMult = tonumber(v:sub(2, -2)) or 1.0
  else cfg.speedMult = tonumber(v:sub(2)) or 1.0 end
end)
local botTog = Tabs.Main:AddToggle("BotCham", { Title = "Bots Chams", Description = "Highlight nextbots red", Default = false })
botTog:OnChanged(function() cfg.botCham = botTog.Value clearChams() end)
local plrTog = Tabs.Main:AddToggle("PlrCham", { Title = "Player's Chams", Description = "Highlight players blue", Default = false })
plrTog:OnChanged(function() cfg.plrCham = plrTog.Value clearChams() end)
local helpTog = Tabs.Main:AddToggle("HelpCham", { Title = "NeedHelpPlayers Chams", Description = "Highlight downed players green", Default = false })
helpTog:OnChanged(function() cfg.helpCham = helpTog.Value clearChams() end)
local shieldTog = Tabs.Main:AddToggle("ShieldTog", { Title = "Bot Shield", Description = "Collision bubble around bots", Default = false })
shieldTog:OnChanged(function() cfg.shield = shieldTog.Value end)
local takeTog = Tabs.Main:AddToggle("TakeTog", { Title = "Auto-take items", Description = "TP to item, prompt, TP back", Default = false })
takeTog:OnChanged(function() cfg.autoTake = takeTog.Value end)

local genv = getgenv()
genv.__evadeGen = (genv.__evadeGen or 0) + 1
local myGen = genv.__evadeGen
STATE = STATE or {}
local running = true
if STATE.onCleanup then STATE.onCleanup(function() running = false end) end
local function alive()
  if genv.__evadeGen ~= myGen then return false end
  if not running then return false end
  if STATE.alive then return STATE.alive() end
  return true
end

local function hum() local c = LP.Character return c and c:FindFirstChildOfClass("Humanoid") end
local function hrp() local c = LP.Character return c and c:FindFirstChild("HumanoidRootPart") end
local baseWS = 16
local function refreshBase()
  local h = hum()
  if h and h.WalkSpeed > 0 then baseWS = h.WalkSpeed end
end
refreshBase()
LP.CharacterAdded:Connect(function()
  task.wait(2)
  refreshBase()
end)

local function isCarrying()
  local c = LP.Character
  if not c then return false end
  for _, w in ipairs(c:GetDescendants()) do
    if w:IsA("Weld") or w:IsA("WeldConstraint") or w:IsA("Motor6D") then
      local p1 = w.Part1 or w.Part0
      if p1 then
        local m = p1:FindFirstAncestorOfClass("Model")
        if m and m ~= c then
          if Players:GetPlayerFromCharacter(m) then return true end
          for _, p in ipairs(Players:GetPlayers()) do
            if p.Character == m then return true end
          end
        end
      end
    end
  end
  if c:GetAttribute("Carrying") == true then return true end
  return false
end
local function moving()
  return UIS:IsKeyDown(Enum.KeyCode.W) or UIS:IsKeyDown(Enum.KeyCode.A)
    or UIS:IsKeyDown(Enum.KeyCode.S) or UIS:IsKeyDown(Enum.KeyCode.D)
end
local function wantBhop()
  return UIS:IsKeyDown(Enum.KeyCode.Space) and moving()
end

local function botsFolder()
  local g = workspace:FindFirstChild("Game")
  local gp = g and g:FindFirstChild("Players")
  if gp then return gp end
  return workspace:FindFirstChild("Players")
end
local function isBot(m)
  if m:GetAttribute("AI") == true then return true end
  if m:GetAttribute("Team") == "Nextbot" then return true end
  for _, p in ipairs(Players:GetPlayers()) do
    if p.Name == m.Name or (p.Character == m) then return false end
  end
  return Players:GetPlayerFromCharacter(m) == nil and m:FindFirstChildOfClass("Humanoid") ~= nil
end
local function isDown(m)
  if m:GetAttribute("Downed") == true then return true end
  local h = m:FindFirstChildOfClass("Humanoid")
  if h and h:GetAttribute("Downed") == true then return true end
  local rigs = workspace:FindFirstChild("Rigs")
  local rig = rigs and rigs:FindFirstChild(m.Name)
  if rig then
    if rig:GetAttribute("Downed") == true then return true end
    local rh = rig:FindFirstChildOfClass("Humanoid")
    if rh and rh:GetAttribute("Downed") == true then return true end
  end
  return false
end
local function makeTag(hrp2, text, color)
  local ts = game:GetService("TextService")
  local sz = ts:GetTextSize(text, 14, Enum.Font.GothamBold, Vector2.new(1000, 24))
  local w = math.max(120, math.ceil(sz.X) + 16)
  local bb = Instance.new("BillboardGui")
  bb.Name = "EVADEcham"
  bb.Size = UDim2.fromOffset(w, 24)
  bb.StudsOffset = Vector3.new(0, 4, 0)
  bb.AlwaysOnTop = true
  bb.Adornee = hrp2
  bb:SetAttribute("C", tostring(color))
  local tl = Instance.new("TextLabel")
  tl.Size = UDim2.fromScale(1, 1)
  tl.BackgroundColor3 = color
  tl.BackgroundTransparency = 0.3
  tl.Text = text
  tl.TextColor3 = Color3.new(1, 1, 1)
  tl.TextSize = 14
  tl.Font = Enum.Font.GothamBold
  tl.Parent = bb
  local oc = Instance.new("UICorner") oc.CornerRadius = UDim.new(0, 4) oc.Parent = tl
  local ow = Instance.new("UIStroke") ow.Color = Color3.new(1, 1, 1) ow.Thickness = 1 ow.Parent = tl
  bb.Parent = hrp2
end
local function chamModel(m, color, force, tag)
  local target = m
  local rigs = workspace:FindFirstChild("Rigs")
  local rig = rigs and rigs:FindFirstChild(m.Name)
  if rig and rig:IsA("Model") then target = rig end
  local old = target:FindFirstChild("EVADEcham")
  if old then
    if not force and old:GetAttribute("C") == tostring(color) then return end
    pcall(function() old:Destroy() end)
  end
  if tag then
    local hrp2 = target:FindFirstChild("HumanoidRootPart")
    if hrp2 then makeTag(hrp2, m.Name, color) end
    return
  end
  if target:GetAttribute("AI") == true or m:GetAttribute("AI") == true then
    local hrp2 = target:FindFirstChild("HumanoidRootPart")
    if not hrp2 then return end
    makeTag(hrp2, m.Name, color)
    local nparts = 0
    for _, v in ipairs(target:GetDescendants()) do
      if v:IsA("BasePart") then nparts = nparts + 1 end
    end
    if nparts > 2 then
      local h = Instance.new("Highlight")
      h.Name = "EVADEchamH"
      h.FillColor = color
      h.FillTransparency = 0.4
      h.OutlineColor = color
      h.OutlineTransparency = 0
      h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
      h.Adornee = target
      h.Parent = target
    end
    return
  end
  local h = Instance.new("Highlight")
  h.Name = "EVADEcham"
  h:SetAttribute("C", tostring(color))
  h.FillColor = color
  h.FillTransparency = 0.3
  h.OutlineColor = color
  h.OutlineTransparency = 0
  h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
  local parts = {}
  for _, v in ipairs(target:GetDescendants()) do
    if v:IsA("BasePart") then table.insert(parts, v) end
  end
  if #parts == 0 then return end
  if #parts <= 2 then h.Adornee = parts[1]
  else h.Adornee = target end
  h.Parent = target
end

task.spawn(function()
  local lastJump = 0
  local landT = 0
  local wasAir = false
  while alive() do
    local h = hum()
    if h and cfg.bhop and wantBhop() then
      local grounded = true
      pcall(function() grounded = h.FloorMaterial ~= Enum.Material.Air end)
      if not grounded then wasAir = true end
      if grounded and wasAir then landT = os.clock() wasAir = false end
      local carry = false
      pcall(function() carry = isCarrying() end)
      local rate = carry and 0.3 or 0.082
      local groundWait = (cfg.hopMode == "OnlyGround" and not carry) and (os.clock() - landT >= 0.1) or true
      if (cfg.hopMode == "Any" or grounded) and groundWait and os.clock() - lastJump >= rate then
        lastJump = os.clock()
        pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end)
      end
    else
      wasAir = false
    end
    task.wait()
  end
end)

task.spawn(function()
  local shields = {}
  game:GetService("RunService").Heartbeat:Connect(function()
    if genv.__evadeGen ~= myGen then return end
    if not cfg.shield then
      for _, s in pairs(shields) do pcall(function() s:Destroy() end) end
      shields = {}
      return
    end
    local seen = {}
    local bf = botsFolder()
    if bf then
      for _, m in ipairs(bf:GetChildren()) do
        if m:IsA("Model") and isBot(m) then
          seen[m] = true
          local hrp2 = m:FindFirstChild("HumanoidRootPart")
          if hrp2 then
            local s = shields[m]
            if not s or s.Parent == nil then
              s = Instance.new("Part")
              s.Name = "EVADEshield"
              s.Size = Vector3.new(14, 14, 14)
              s.Shape = Enum.PartType.Ball
              s.Transparency = 1
              s.CanCollide = true
              s.Anchored = false
              s.CanQuery = false
              s.Massless = true
              s.Parent = workspace
              local w = Instance.new("WeldConstraint")
              w.Part0 = s
              w.Part1 = hrp2
              w.Parent = s
              shields[m] = s
            end
          end
        end
      end
    end
    for m, s in pairs(shields) do
      if not seen[m] then pcall(function() s:Destroy() end) shields[m] = nil end
    end
  end)
end)

task.spawn(function()
  print("[EVADE] ready")
  local revBusy = false
  local function downedList()
    local out = {}
    local bf = botsFolder()
    if bf then
      for _, m in ipairs(bf:GetChildren()) do
        if m:IsA("Model") and not isBot(m) and isDown(m) then
          local r = m:FindFirstChild("HumanoidRootPart")
          if r then table.insert(out, { m = m, pos = r.Position }) end
        end
      end
    end
    local me = hrp() and hrp().Position
    if me then
      table.sort(out, function(a, b)
        return (a.pos - me).Magnitude < (b.pos - me).Magnitude
      end)
    end
    return out
  end
  local function firePromptsOn(m)
    for _, d in ipairs(m:GetDescendants()) do
      if d:IsA("ProximityPrompt") and d.Enabled then
        pcall(function() fireproximityprompt(d) end)
        task.wait(0.3)
      end
    end
  end
  local function botDist(p)
    local bd = nil
    local bf = botsFolder()
    if bf then
      for _, m in ipairs(bf:GetChildren()) do
        if m:IsA("Model") and isBot(m) then
          local r = m:FindFirstChild("HumanoidRootPart")
          if r then
            local d = (r.Position - p).Magnitude
            if bd == nil or d < bd then bd = d end
          end
        end
      end
    end
    return bd or 1e9
  end
  local function safeSpot(from)
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local best, bestD = nil, -1
    for a = 0, 11 do
      local ang = a * (math.pi * 2 / 12)
      for _, dist in ipairs({ 80, 140, 200 }) do
        local cand = from + Vector3.new(math.cos(ang) * dist, 20, math.sin(ang) * dist)
        rp.FilterDescendantsInstances = { LP.Character }
        local hit = workspace:Raycast(cand, Vector3.new(0, -120, 0), rp)
        if hit and hit.Instance and hit.Instance.CanCollide then
          local p = hit.Position + Vector3.new(0, 4, 0)
          local bd = botDist(p)
          if bd > bestD then best, bestD = p, bd end
        end
      end
    end
    return best
  end
  local function aimAt(p)
    pcall(function()
      local cam = workspace.CurrentCamera
      cam.CFrame = CFrame.lookAt(cam.CFrame.Position, p)
    end)
  end
  local function holdE(sec)
    local VIM = game:GetService("VirtualInputManager")
    pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game) end)
    task.wait(sec)
    pcall(function() VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game) end)
  end
  local function doRevive(entry)
    local me = hrp()
    if not me then return end
    me.CFrame = CFrame.new(entry.pos + Vector3.new(0, 3, 0))
    task.wait(0.4)
    aimAt(entry.pos)
    holdE(3)
    task.wait(0.6)
    if not isDown(entry.m) then return true end
    local spot = safeSpot(entry.pos)
    if spot then
      me = hrp()
      if me then me.CFrame = CFrame.new(spot) end
      task.wait(0.5)
      aimAt(entry.pos)
      holdE(3)
      task.wait(1.0)
    end
    return not isDown(entry.m)
  end
  while alive() do
    local h = hum()
    if h then
      if cfg.speedMult <= 1.0 then baseWS = h.WalkSpeed
      else
        local eff = cfg.speedMult
        if math.abs(cfg.speedMult - 1.19) < 0.001 and (os.clock() % 0.24) < 0.11 then eff = 1.28 end
        pcall(function() h.WalkSpeed = baseWS * eff end)
      end
    end
    if cfg.botCham or cfg.plrCham or cfg.helpCham then
      local bf = botsFolder()
      if bf then
        for _, m in ipairs(bf:GetChildren()) do
          if m:IsA("Model") then
            local bot = isBot(m)
            local down = isDown(m)
            if down and cfg.helpCham then
              chamModel(m, Color3.fromRGB(60, 255, 90), true, true)
            elseif bot and cfg.botCham then
              chamModel(m, Color3.fromRGB(255, 40, 40))
            elseif not bot and not down and cfg.plrCham then
              chamModel(m, Color3.fromRGB(60, 140, 255))
            end
          end
        end
      end
    else
      clearChams()
    end
    if cfg.autoRevive and not revBusy then
      local list = downedList()
      if list[1] then
        revBusy = true
        task.spawn(function()
          for _, e in ipairs(list) do
            if not alive() or not cfg.autoRevive then break end
            if isDown(e.m) then
              pcall(function() doRevive(e) end)
              task.wait(1)
            end
          end
          revBusy = false
        end)
      end
    end
    if cfg.autoTake then
      local g = workspace:FindFirstChild("Game")
      local ef = g and g:FindFirstChild("Effects")
      local me = hrp()
      if ef and me then
        local best, bestD, bestP = nil, nil, nil
        for _, f in ipairs(ef:GetChildren()) do
          if f:IsA("Folder") then
            for _, it in ipairs(f:GetChildren()) do
              local tp = it:IsA("BasePart") and it or it:FindFirstChild("HumanoidRootPart", true)
              local pp = nil
              if it:IsA("BasePart") then pp = it.Position
              elseif tp and tp:IsA("BasePart") then pp = tp.Position end
              if pp then
                local d = (pp - me.Position).Magnitude
                if bestD == nil or d < bestD then best, bestD, bestP = it, d, pp end
              end
            end
          end
        end
        if best and bestP then
          local back = me.Position
          me.CFrame = CFrame.new(bestP + Vector3.new(0, 3, 0))
          task.wait(0.25)
          for _, d in ipairs(best:GetDescendants()) do
            if d:IsA("ProximityPrompt") then pcall(function() fireproximityprompt(d) end) end
          end
          task.wait(0.2)
          local m2 = hrp()
          if m2 then m2.CFrame = CFrame.new(back) end
          task.wait(0.3)
        else
          task.wait(0.5)
        end
      else
        task.wait(0.5)
      end
    else
      task.wait(0.1)
    end
  end
end)
