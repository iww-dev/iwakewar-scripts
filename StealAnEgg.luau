-- steal egg farm
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local PFS = game:GetService("PathfindingService")
local Remotes = require(RS.Shared.Remotes)
local EggWorld = Remotes.EggWorld
local Treadmill = Remotes.Treadmill

local cfg = { farm = false, margin = 1.08, speedMult = 1.15,
  placeEgg = true, treadBreak = true, upTread = true, upTrails = true,
  wearBest = true, autoHatch = true }

-- zones read from signs
local function parseNum(s)
  s = tostring(s):gsub("%s+", ""):upper()
  local mult = 1
  if s:sub(-1) == "K" then mult = 1e3 s = s:sub(1, -2)
  elseif s:sub(-1) == "M" then mult = 1e6 s = s:sub(1, -2)
  elseif s:sub(-1) == "B" then mult = 1e9 s = s:sub(1, -2)
  elseif s:sub(-1) == "T" then mult = 1e12 s = s:sub(1, -2) end
  return (tonumber(s) or 0) * mult
end
local ZONES = {}
local function refreshZones()
  local okG, Guards = pcall(function() return require(RS.Data.Guards) end)
  local areas = workspace:FindFirstChild("__OBJECTS")
  areas = areas and areas:FindFirstChild("Areas")
  areas = areas and areas:FindFirstChild("GuardAreas")
  if not areas then return end
  for _, m in ipairs(areas:GetChildren()) do
    local reqObj = m:FindFirstChild("RequiredSpeedSign", true)
    local speedTxt = nil
    if reqObj then
      for _, d in ipairs(reqObj:GetDescendants()) do
        if d:IsA("TextLabel") and d.Name == "Speed" then speedTxt = d.Text break end
      end
    end
    local gws = 50
    if okG and Guards.Directory and Guards.Directory[m.Name] then
      gws = Guards.Directory[m.Name].WalkSpeed or 50
    end
    local b = m:FindFirstChild("Bounds")
    if speedTxt then
      ZONES[m.Name] = { req = parseNum(speedTxt), gws = gws, pos = b and b.Position or nil }
    end
  end
end
refreshZones()

for _, g in ipairs(LP.PlayerGui:GetChildren()) do if g.Name == "FarmV4" or g.Name == "FarmV3" then g:Destroy() end end
for _, g in ipairs(game:GetService("CoreGui"):GetChildren()) do if g.Name == "FarmToggle" then g:Destroy() end end
local UIS = game:GetService("UserInputService")
local isPhone = UIS.TouchEnabled and not UIS.KeyboardEnabled
local genv0 = getgenv()
if genv0.__farmFluent and type(genv0.__farmFluent.Destroy) == "function" then
  pcall(function() genv0.__farmFluent:Destroy() end)
end
local Fluent = loadstring(readfile("_fluent.lua"))()
genv0.__farmFluent = Fluent
local Window = Fluent:CreateWindow({
  Title = "StealAnEgg Farm",
  SubTitle = "by iwakewar team",
  TabWidth = 140,
  Size = isPhone and UDim2.fromOffset(416, 336) or UDim2.fromOffset(520, 420),
  Acrylic = false,
  Theme = "Dark",
  MinimizeKey = Enum.KeyCode.RightControl,
})
local Tabs = {
  Info = Window:AddTab({ Title = "Info", Icon = "badge-check" }),
  Main = Window:AddTab({ Title = "Farm", Icon = "" }),
}
Window:SelectTab(2)
if isPhone then
do
  local sg = Instance.new("ScreenGui")
  sg.Name = "FarmToggle" sg.ResetOnSpawn = false
  pcall(function() sg.Parent = game:GetService("CoreGui") end)
  if sg.Parent == nil then sg.Parent = LP.PlayerGui end
  local b = Instance.new("TextButton")
  b.Size = UDim2.fromOffset(40, 40)
  b.Position = UDim2.new(0.5, -20, 0.5, -265)
  b.Text = "F" b.TextSize = 18
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
Tabs.Info:AddParagraph({
  Title = "StealAnEgg Farm",
  Content = "Full auto-farmer for Steal An Egg\nby iwakewar team\n\n- Steals eggs on foot (no teleports, anticheat-safe)\n- Instant escape the moment of steal\n- Places eggs on a free PetArea grid slot\n- Auto-hatches ready eggs, wears best pets\n- Upgrades treadmill, buys and equips trails\n- 1 minute on treadmill every 3 circles\n- Adaptive speedhack with server rollback control\n\nEnable Farm and watch the Log tab.",
})
local function copyToClipboard(text)
  local genv = getgenv and getgenv() or {}
  for _, name in ipairs({ "setclipboard", "toclipboard", "writeclipboard" }) do
    local v = genv[name] or rawget(_G, name)
    if typeof(v) == "function" then if pcall(v, text) then return true end end
  end
  return false
end
Tabs.Info:AddButton({
  Title = "Our Discord Server",
  Description = "Copy invite link to clipboard",
  Callback = function()
    local ok = copyToClipboard("https://discord.gg/GgshjzxxFS")
    Fluent:Notify({ Title = "StealAnEgg Farm", Content = ok and "Discord link copied" or "No clipboard API", Duration = 3 })
  end,
})
local farmTog = Tabs.Main:AddToggle("FarmTog", { Title = "Farm", Description = "Steal -> place -> hatch", Default = false })
farmTog:OnChanged(function() cfg.farm = farmTog.Value end)
local function featTog(id, title, desc, key)
  local t = Tabs.Main:AddToggle(id, { Title = title, Description = desc, Default = true })
  t:OnChanged(function() cfg[key] = t.Value end)
  return t
end
featTog("PlaceEgg", "Place eggs", "Place carried egg on base", "placeEgg")
featTog("TreadBreak", "Treadmill breaks", "1 minute on treadmill every 3 circles", "treadBreak")
featTog("UpTread", "Upgrade treadmill", "Buy treadmill upgrades for Money", "upTread")
featTog("UpTrails", "Buy trails", "Buy and equip best trails", "upTrails")
featTog("WearBest", "Wear best pets", "Equip strongest pets", "wearBest")
featTog("AutoHatch", "Auto-hatch", "Hatch eggs when their timer ends", "autoHatch")
local speedDrop = Tabs.Main:AddDropdown("SpeedDrop", {
  Title = "Speedhack",
  Description = "WalkSpeed multiplier",
  Values = { "x1.0", "x1.15", "x1.17", "x1.18" },
  Multi = false,
  Default = 2,
})
speedDrop:OnChanged(function(v) cfg.speedMult = tonumber(v:sub(2)) or 1.0 end)
Tabs.Main:AddButton({ Title = "Step off treadmill", Description = "Treadmill AskDoff",
  Callback = function() pcall(function() Treadmill.AskDoff:InvokeServer() end) end })
local function addLog(text, ok)
  print("[FARMv4]", text)
end
local function setPlace(t, ok)
  addLog("Place: " .. t, ok)
end
local baseWS = 50
do
  local ch0 = LP.Character
  local h0 = ch0 and ch0:FindFirstChildOfClass("Humanoid")
  if h0 and h0.WalkSpeed > 0 then baseWS = h0.WalkSpeed end
end

local genv = getgenv()
genv.__farmGen = (genv.__farmGen or 0) + 1
local myGen = genv.__farmGen
local running = true
if STATE ~= nil and type(STATE.onCleanup) == "function" then
  STATE.onCleanup(function() running = false end)
end
local function stillAlive()
  if STATE ~= nil and type(STATE.alive) == "function" then return STATE.alive() end
  return running
end
local function alive()
  if genv.__farmGen ~= myGen then return false end
  if not running then return false end
  return stillAlive()
end
local rbHist, rbTimes, rbLast = {}, {}, 0
game:GetService("RunService").Heartbeat:Connect(function()
  if genv.__farmGen ~= myGen then return end
  local hh = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
  local rr = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
  if not hh or not rr then return end
  if cfg.speedMult <= 1.0 then baseWS = hh.WalkSpeed
  else
    -- resync base
    rbTick = (rbTick or 0) + 1
    if rbTick % 300 == 0 then baseWS = hh.WalkSpeed
    else
      -- pulse x1.20
      local eff = cfg.speedMult
      if math.abs(cfg.speedMult - 1.18) < 0.001 and (os.clock() % 0.5) < 0.1 then eff = 1.20 end
      pcall(function() hh.WalkSpeed = baseWS * eff end)
    end
  end
  -- rollback watch
  local now = os.clock()
  if now - rbLast >= 0.5 then
    rbLast = now
    table.insert(rbHist, rr.Position)
    if #rbHist > 4 then table.remove(rbHist, 1) end
    if #rbHist == 4 and cfg.speedMult > 1.0 then
      local back = (rbHist[4] - rbHist[2]).Magnitude
      local fwd = (rbHist[3] - rbHist[2]).Magnitude
      if back > 20 and fwd > 5 then
        table.insert(rbTimes, now)
        local fresh = {}
        for _, t in ipairs(rbTimes) do if now - t < 10 then table.insert(fresh, t) end end
        rbTimes = fresh
        if #rbTimes >= 2 then
          rbTimes = {}
          addLog("Server rubberband detected (mult stays x" .. string.format("%.2f", cfg.speedMult) .. ")", false)
        end
      end
    end
  end
end)

local function hrp() local c = LP.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c = LP.Character return c and c:FindFirstChildOfClass("Humanoid") end
local function mySpeed() local l = LP:FindFirstChild("leaderstats") local s = l and l:FindFirstChild("Speed") return s and s.Value or 0 end
local function myWS() local h = hum() return h and h.WalkSpeed or 50 end
local function maxWalk() return math.clamp(myWS() * 12, 300, 9000) end

local function autoTrail()
  local okT, T = pcall(function() return require(RS.Data.Trails) end)
  if not okT then return end
  local okS, Save = pcall(function() return require(RS.Shared.Save) end)
  if not okS then return end
  local d = Save.Get() if not d then return end
  local best, bestPr = nil, -1
  for name, t in pairs(T.Directory or {}) do
    if t.DisplayInShop and (t.Price or 0) <= d.Money and (t.Price or 0) > bestPr
      and d.TrailInventory and not d.TrailInventory[name] then
      best, bestPr = name, t.Price
    end
  end
  if best then
    local ok1 = pcall(function() return Remotes.Trailwear.AskPurchase:InvokeServer(best) end)
    addLog("Trail buy " .. best .. ": " .. tostring(ok1), ok1)
  end
  local be, beMu = nil, 0
  for name, t in pairs(T.Directory or {}) do
    if d.TrailInventory and d.TrailInventory[name] and (t.SpeedMultiplier or 0) > beMu then
      be, beMu = name, t.SpeedMultiplier
    end
  end
  if be and d.EquippedTrail ~= be then
    pcall(function() return Remotes.Trailwear.AskChoose:InvokeServer(be) end)
    addLog("Trail equip " .. be .. " x" .. tostring(beMu), true)
  end
end

local function autoUpgrade()
  local okS, Save = pcall(function() return require(RS.Shared.Save) end)
  if not okS then return end
  local d = Save.Get() if not d then return end
  local okT, T = pcall(function() return require(RS.Data.Treadmills) end)
  if not okT then return end
  local lvl = d.TreadmillUpgradeLevel or 0
  local next = T.GetByUpgradeLevel and T.GetByUpgradeLevel(lvl + 1)
  if next and (next.Price or math.huge) <= d.Money then
    local ok, a = pcall(function() return Remotes.Treadmill.AskTierRaise:InvokeServer(next._id) end)
    addLog("Treadmill upgrade " .. tostring(next._id) .. ": " .. tostring(a), a == true)
  end
end

local function myPlot()
  local ok, st = pcall(function() return Remotes.Homestead.AskState:InvokeServer() end)
  if ok and type(st) == "table" and type(st.OwnersBySlot) == "table" then
    for slot, uid in pairs(st.OwnersBySlot) do
      if tostring(uid) == tostring(LP.UserId) then
        local p = workspace.Plots:FindFirstChild(tostring(slot))
        if p then return p end
      end
    end
  end
  return nil
end

local function findKid(inst, name)
  if not inst then return nil end
  local d = inst:FindFirstChild(name, true)
  if d then return d end
  return inst:FindFirstChild(name)
end

local function safeZones()
  local s, ws = mySpeed(), myWS()
  local out = {}
  for n, z in pairs(ZONES) do
    if s >= z.req * cfg.margin and ws >= z.gws * 0.8 then table.insert(out, { n = n, req = z.req }) end
  end
  return out
end

local function walkSmart(pos, timeout)
  if typeof(pos) ~= "Vector3" then return false end
  local h, r = hum(), hrp() if not h or not r then return false end
  h:MoveTo(pos)
  local t0 = os.clock()
  timeout = timeout or 100
  local last, lastT = r.Position, os.clock()
  while (r.Position - pos).Magnitude > 7 do
    task.wait(0.3)
    if not running then return false end
    h, r = hum(), hrp() if not h or not r then return false end
    if hum().Health <= 0 then return false end
    if (r.Position - last).Magnitude > 2 then last, lastT = r.Position, os.clock()
    elseif os.clock() - lastT > 2 then h.Jump = true task.wait(0.15) h:MoveTo(r.Position + r.CFrame.RightVector * 10) task.wait(0.5) h:MoveTo(pos) last, lastT = r.Position, os.clock() end
    if os.clock() - t0 > timeout then return false end
    h:MoveTo(pos)
  end
  return true
end

local function dismount()
  pcall(function() Treadmill.AskDoff:InvokeServer() end)
  local h = hum() if h then h.Jump = true end
  task.wait(0.6)
end

local function equipEgg()
  local c = LP.Character if not c then return end
  local h = hum()
  for _, t in ipairs(c:GetChildren()) do
    if t:IsA("Tool") and t.Name:lower():find("egg") and h then pcall(function() h:EquipTool(t) end) end
  end
  local b = LP:FindFirstChild("Backpack")
  if b then for _, t in ipairs(b:GetChildren()) do
    if t:IsA("Tool") and t.Name:lower():find("egg") and h then pcall(function() h:EquipTool(t) end) task.wait(0.3) end
  end end
end

local function tryPlace(plot, uid)
  local cp = findKid(plot, "CenterPoint")
  if not cp then setPlace("no CenterPoint", false) return false end
  equipEgg()
  task.wait(0.3)
  local wok, wokR = pcall(function()
    local EggState0 = require(RS.Client.EggState)
    return EggState0.WearEggTool(uid)
  end)
  addLog("WearEggTool: " .. tostring(wok) .. " " .. tostring(wokR):sub(1, 60), wok)
  task.wait(0.5)
  equipEgg()
  local c2 = LP.Character
  local toolNow, toolUid = nil, nil
  if c2 then for _, t in ipairs(c2:GetChildren()) do
    if t:IsA("Tool") then
      toolNow = t.Name
      local a = t:GetAttribute("EggUid") or t:GetAttribute("Uid") or t:GetAttribute("EggId")
      if a then toolUid = tostring(a) end
    end
  end end
  addLog("Tool in hands: " .. tostring(toolNow) .. " uid=" .. tostring(toolUid and toolUid:sub(1, 8)), toolNow ~= nil)
  if toolUid then uid = toolUid end
  local pa = findKid(plot, "PetArea")
  local busy = {}
  local freshSet = {}
  pcall(function()
    local okR, resR = pcall(function() return EggWorld.AskLiveSnapshot:InvokeServer() end)
    if okR and type(resR) == "table" then
      for _, t in pairs(resR) do
        if type(t) == "table" and t.OwnerUserId == LP.UserId then
          for u, r in pairs(t.Records or {}) do
            if r.Placement == nil then freshSet[u] = true end
            if r.Placement and r.Placement.LocalCFrame then
              local cf = r.Placement.LocalCFrame
              local lp = (typeof(cf) == "CFrame") and cf.Position or Vector3.new(cf[1] or 0, 0, cf[3] or 0)
              table.insert(busy, (cp.CFrame * CFrame.new(lp)).Position)
            end
          end
        end
      end
    end
  end)
  if not freshSet[uid] then
    local alt = nil
    for u, _ in pairs(freshSet) do alt = u break end
    if alt then addLog("uid stale, taking " .. alt:sub(1, 8), nil) uid = alt
    else setPlace("inventory empty", false) return false end
  end
  local h = hrp()
  local meP = h and h.Position or cp.Position
  local bestCF, bestD = nil, nil
  if pa then
    local rel = cp.CFrame:ToObjectSpace(pa.CFrame)
    local hx, hz = pa.Size.X / 2 - 4, pa.Size.Z / 2 - 4
    for gx = -hx, hx, 12 do
      for gz = -hz, hz, 12 do
        local wp = (cp.CFrame * CFrame.new(rel.Position + Vector3.new(gx, 0, gz))).Position
        local free = true
        for _, b in ipairs(busy) do if (Vector3.new(wp.X, 0, wp.Z) - Vector3.new(b.X, 0, b.Z)).Magnitude < 10 then free = false break end end
        if free then
          local d = (Vector3.new(wp.X, 0, wp.Z) - Vector3.new(meP.X, 0, meP.Z)).Magnitude
          if bestD == nil or d < bestD then bestD, bestCF = d, cp.CFrame:ToObjectSpace(CFrame.new(wp + Vector3.new(0, 1.5, 0))) end
        end
      end
    end
  end
  if not bestCF then setPlace("base full", false) return false end
  local targetW = (cp.CFrame * bestCF).Position
  if (Vector3.new(meP.X, 0, meP.Z) - Vector3.new(targetW.X, 0, targetW.Z)).Magnitude > 12 then
    walkSmart(Vector3.new(targetW.X, meP.Y, targetW.Z), 30)
  end
  local localCF = bestCF
  local done, resA, resB = false, nil, nil
  task.spawn(function()
    local EggState = require(RS.Client.EggState)
    local ok, a, b = pcall(function() return EggState.PlantEgg(uid, localCF) end)
    done, resA, resB = true, ok and a, b
  end)
  local t0 = os.clock()
  while not done and os.clock() - t0 < 5 do task.wait(0.2) end
  if not done then setPlace("server timeout", false) return false end
  if resA == true then setPlace("ok", true) return true end
  setPlace(tostring(resA) .. " " .. tostring(resB):sub(1, 60), false)
  return false
end

local function autoHatch()
  local ok, res = pcall(function() return EggWorld.AskLiveSnapshot:InvokeServer() end)
  if not ok or type(res) ~= "table" then return end
  for _, t in pairs(res) do
    if type(t) == "table" and t.OwnerUserId == LP.UserId then
      for uid, r in pairs(t.Records or {}) do
        if r.Placement ~= nil then
          local okH = pcall(function() return EggWorld.AskHatch:InvokeServer(uid) end)
          task.wait(0.2)
          local okF, aF, bF = pcall(function() return EggWorld.AskFinishHatch:InvokeServer(uid) end)
          if okF and aF == true then addLog("Hatch popped " .. uid:sub(1, 6), true) end
        end
      end
    end
  end
  if cfg.wearBest then pcall(function() Remotes.Haul.WearBest:InvokeServer() end) end
end

local function myUnplaced()
  local set = {}
  local ok, res = pcall(function() return EggWorld.AskLiveSnapshot:InvokeServer() end)
  if ok and type(res) == "table" then
    for _, t in pairs(res) do
      if type(t) == "table" and t.OwnerUserId == LP.UserId then
        for uid, r in pairs(t.Records or {}) do
          if r.Placement == nil then set[uid] = true end
        end
      end
    end
  end
  return set
end

local function findPrompt(eggPos)
  local best, bestD = nil, 12
  for _, p in ipairs(workspace:GetDescendants()) do
    if p:IsA("ProximityPrompt") and p.Name == "CarryAreaEgg" then
      local part = p.Parent
      if part and part:IsA("BasePart") then
        local d = (part.Position - eggPos).Magnitude
        if d < bestD then best, bestD = p, d end
      end
    end
  end
  return best
end

task.spawn(function()
  addLog("v4 ready S=" .. mySpeed(), nil)
  local loopN = 0
  while alive() do
    loopN = loopN + 1
    if loopN % 20 == 0 then refreshZones() end
    if cfg.farm and cfg.treadBreak and loopN % 3 == 0 then
      local plot = myPlot()
      local tb = plot and findKid(plot, "TreadmillBottom")
      if tb then walkSmart(tb.Position + Vector3.new(0, 2, 0), 60) end
      addLog("Break: a minute on treadmill", nil)
      for i = 1, 6 do
        task.wait(10)
        if not alive() or not cfg.farm then break end
        pcall(function() Remotes.Telemetry.SubmitIdleState:FireServer(false) end)
      end
      addLog("Break over S=" .. mySpeed(), true)
    end
    pcall(function() Remotes.Telemetry.SubmitIdleState:FireServer(false) end)
    if cfg.farm and cfg.autoHatch then pcall(function() autoHatch() end) end
    if cfg.farm and cfg.upTrails then pcall(function() autoTrail() end) end
    if cfg.farm and cfg.upTread then pcall(function() autoUpgrade() end) end
    if cfg.farm then
      dismount()
      local beforeSet = myUnplaced()
      local ok, snap = pcall(function() return EggWorld.AskFieldEggSnapshot:InvokeServer() end)
      local me = hrp() and hrp().Position
      local plot = myPlot()
      local cands = {}
      if ok and type(snap) == "table" and me then
        local safeReq = {}
        for _, z in ipairs(safeZones()) do safeReq[z.n] = z.req end
        for _, r in ipairs(snap.Records or {}) do
          if safeReq[r.AreaId] and r.State == "Slot" and r.BoundsCFrame then
            local bp = Vector3.new(r.BoundsCFrame.X, r.BoundsCFrame.Y, r.BoundsCFrame.Z)
            local d = (bp - me).Magnitude
            if d <= maxWalk() then table.insert(cands, { r = r, bp = bp, d = d, req = safeReq[r.AreaId] }) end
          end
        end
        table.sort(cands, function(a, b) if a.req ~= b.req then return a.req > b.req end return a.d < b.d end)
      end
      if #cands == 0 then
        local sl = {}
        for _, z in ipairs(safeZones()) do table.insert(sl, z.n) end
        -- top zone distance check
        local topD, topN = nil, nil
        if ok and type(snap) == "table" and me then
          local safeReq = {}
          for _, z in ipairs(safeZones()) do safeReq[z.n] = z.req end
          local bestReq = -1
          for _, z in ipairs(safeZones()) do if z.req > bestReq then bestReq = z.req end end
          for _, r in ipairs(snap.Records or {}) do
            if safeReq[r.AreaId] and r.State == "Slot" and r.BoundsCFrame then
              local bp = Vector3.new(r.BoundsCFrame.X, r.BoundsCFrame.Y, r.BoundsCFrame.Z)
              local d = math.floor((bp - me).Magnitude)
              if topD == nil or d < topD then topD, topN = d, r.AreaId end
            end
          end
        end
        addLog("no eggs S=" .. mySpeed() .. " limit=" .. math.floor(maxWalk()) .. " nearest=" .. tostring(topN) .. ":" .. tostring(topD) .. " safe:" .. table.concat(sl, ","), nil)
        if plot then local tb = findKid(plot, "TreadmillBottom") local h = hrp() if tb and h and (h.Position - tb.Position).Magnitude > 25 then walkSmart(tb.Position, 60) end end
        task.wait(12)
      else
        local c = cands[1]
        addLog("Going " .. math.floor(c.d) .. "st " .. c.r.AreaId .. " " .. c.r.Uid:sub(1, 6) .. " home=" .. (plot and plot.Name or "?"), nil)
        if walkSmart(c.bp + Vector3.new(0, 0, 4), 100) then
          -- instant steal, run at once
          local pr = findPrompt(c.bp)
          if pr then pcall(function() fireproximityprompt(pr) end) end
          task.spawn(function()
            local ok, a, b = pcall(function() return EggWorld.AskFieldEggCarry:InvokeServer({ Uid = c.r.Uid }) end)
            addLog("Carry response: " .. tostring(a) .. " " .. tostring(b):sub(1, 60), a == true)
          end)
          local home = plot and findKid(plot, "CenterPoint")
          local h2 = hum()
          if h2 and home then h2:MoveTo(home.Position) end
          addLog("Running home!", nil)
          if home then walkSmart(home.Position, 120) end
          -- hands check, wear any unplaced if empty
          local ch = LP.Character
          local hands = false
          if ch then for _, t in ipairs(ch:GetChildren()) do if t:IsA("Tool") and t.Name:lower():find("egg") then hands = true end end end
          if not hands then
            local after0 = myUnplaced()
            for uid, _ in pairs(after0) do
              pcall(function() require(RS.Client.EggState).WearEggTool(uid) end)
              task.wait(0.4)
              equipEgg()
              if ch then for _, t in ipairs(ch:GetChildren()) do if t:IsA("Tool") and t.Name:lower():find("egg") then hands = true end end end
              if hands then addLog("Took from inventory " .. uid:sub(1, 8), true) break end
            end
          end
          if not hands then
            setPlace("empty hands - carry denied, skip", false)
          else
            -- fresh server uid
            local placeUid, afterSet = c.r.Uid, myUnplaced()
            for uid, _ in pairs(afterSet) do
              if not beforeSet[uid] then placeUid = uid break end
            end
            addLog("Placing uid=" .. placeUid:sub(1, 8) .. (placeUid ~= c.r.Uid and " (new!)" or " (field)"), nil)
            if cfg.placeEgg then
              local placed = tryPlace(plot, placeUid)
          if placed then
            pcall(function() return EggWorld.AskHatch:InvokeServer(placeUid) end)
            task.wait(0.3)
            pcall(function() return EggWorld.AskFinishHatch:InvokeServer(placeUid) end)
            if cfg.wearBest then pcall(function() Remotes.Haul.WearBest:InvokeServer() end) end
          end
            else addLog("Place skipped (toggle off)", nil) end
          end
          pcall(function() Remotes.Codex.AskRedeemAll:InvokeServer() end)
          if plot then local tb = findKid(plot, "TreadmillBottom") if tb then walkSmart(tb.Position + Vector3.new(0, 2, 0), 60) end end
          addLog("Circle done S=" .. mySpeed(), true)
        else addLog("Didn't reach - skip", false) end
      end
    end
    task.wait(3)
  end
end)
