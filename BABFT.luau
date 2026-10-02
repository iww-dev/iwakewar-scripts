-- BABFT autofarm by iwakewar team
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local isPhone = UIS.TouchEnabled and not UIS.KeyboardEnabled

local cfg = { farm = false, speed = 60 }

local genv0 = getgenv()
if genv0.__babftFluent and type(genv0.__babftFluent.Destroy) == "function" then
  pcall(function() genv0.__babftFluent:Destroy() end)
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
genv0.__babftFluent = GUI
local Window = GUI:CreateWindow({
  Title = "BABFT Farm",
  SubTitle = "by iwakewar team",
  TabWidth = 150,
  Size = UDim2.fromOffset(640, 460),
  ToggleKey = Enum.KeyCode.RightAlt,
})
GUI._selfUrl = "https://raw.githubusercontent.com/iww-dev/iwakewar-scripts/refs/heads/main/iwakewar-scripts/BABFT.luau"
local Tabs = {
  Info = Window:AddTab({ Title = "Info", Icon = "badge-check" }),
  Main = Window:AddTab({ Title = "Main", Icon = "" }),
}
Window:SelectTab(1)
Tabs.Info:AddParagraph({
  Title = "BABFT Farm",
  Content = "Autofarm for Build A Boat For Treasure\nby iwakewar team\n\n- Launch via button handler (no boat needed)\n- Smooth flight base -> center -> stages -> chest\n- 0.3s at chest, reset, next circle",
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
    GUI:Notify({ Title = "BABFT Farm", Content = ok and "Discord link copied" or "No clipboard API", Duration = 3 })
  end,
})
-- mobile floating toggle is built into iwakewar-gui, nothing to do here

local farmTog = Tabs.Main:AddToggle("FarmTog", { Title = "Farm", Description = "Launch -> fly -> chest -> reset", Default = false })
farmTog:OnChanged(function() cfg.farm = farmTog.Value end)
local ratePara = Tabs.Main:AddParagraph({ Title = "Gold per 15 minutes", Content = "-" })
local speedSld = Tabs.Main:AddSlider("SpeedSld", {
  Title = "Fly speed", Description = "Studs per second",
  Default = 60, Min = 20, Max = 406, Rounding = 0,
})
speedSld:OnChanged(function(v) cfg.speed = v end)

local genv = getgenv()
genv.__babftGen = (genv.__babftGen or 0) + 1
local myGen = genv.__babftGen
STATE = STATE or {}
local running = true
if STATE.onCleanup then STATE.onCleanup(function() running = false end) end
local function alive()
  if genv.__babftGen ~= myGen then return false end
  if not running then return false end
  if STATE.alive then return STATE.alive() end
  return true
end

local WAYPOINTS = {
  Vector3.new(-54, 27, 1108),
  Vector3.new(-54, 27, 1368),
  Vector3.new(-54, 27, 2138),
  Vector3.new(-54, 27, 2908),
  Vector3.new(-54, 27, 3678),
  Vector3.new(-54, 27, 4448),
  Vector3.new(-54, 27, 5218),
  Vector3.new(-54, 27, 5988),
  Vector3.new(-54, 27, 6758),
  Vector3.new(-54, 27, 7528),
  Vector3.new(-54, 27, 8298),
  Vector3.new(-54, 9, 8447),
}
local CHEST = Vector3.new(-55.7, -356, 9492)

local function hrp() local c = LP.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function noclipOn()
  local c = LP.Character
  if c then for _, v in ipairs(c:GetDescendants()) do
    if v:IsA("BasePart") then v.CanCollide = false end
  end end
end
local function flyTo(target, speed)
  local h = hrp()
  if not h then return false end
  local t0 = os.clock()
  local conn
  local done = false
  conn = game:GetService("RunService").Heartbeat:Connect(function(dt)
    if not alive() or not cfg.farm then done = true return end
    local hh = hrp()
    if not hh then done = true return end
    noclipOn()
    local d = target - hh.Position
    if d.Magnitude < 8 then done = true return end
    hh.AssemblyLinearVelocity = Vector3.zero
    hh.AssemblyAngularVelocity = Vector3.zero
    local step = d.Unit * math.min(speed * math.min(dt, 0.05), d.Magnitude)
    hh.CFrame = CFrame.lookAt(hh.Position + step, hh.Position + step + d.Unit)
    if os.clock() - t0 > 180 then done = true end
  end)
  while not done and alive() and cfg.farm do task.wait(0.1) end
  pcall(function() conn:Disconnect() end)
  return done
end
local function doLaunch()
  local btn = LP.PlayerGui:FindFirstChild("LaunchBoatGui")
  btn = btn and btn:FindFirstChild("PromptLaunch")
  btn = btn and btn:FindFirstChild("Yes")
  if not btn then return false end
  local ok = false
  for _, c in ipairs(getconnections(btn.MouseButton1Click)) do
    local s = pcall(function() c.Function() end)
    if s then ok = true end
  end
  return ok
end

local function gold()
  local g = LP.PlayerGui:FindFirstChild("GoldGui")
  g = g and g:FindFirstChild("Frame")
  g = g and g:FindFirstChild("Amount")
  return tonumber(g and g.Text) or nil
end
local function log(m) print("[BABFT] " .. m) end
task.spawn(function()
  local lastG = gold()
  local lastP = nil
  local hist = {}
  while alive() do
    task.wait(2)
    local now = os.clock()
    local g = gold()
    if g ~= nil and lastG ~= nil and g ~= lastG then
      log("GOLD " .. lastG .. " -> " .. g .. " (+" .. (g - lastG) .. ")")
    end
    if g ~= nil then
      if lastG ~= nil and g > lastG then
        table.insert(hist, { t = now, v = g - lastG })
      end
      lastG = g
      local cut = now - 900
      local sum = 0
      local fresh = {}
      for _, e in ipairs(hist) do
        if e.t >= cut then sum = sum + e.v table.insert(fresh, e) end
      end
      hist = fresh
      pcall(function()
        ratePara:SetContent(tostring(sum) .. " gold / 15 min (now: " .. g .. ")")
      end)
    end
    local h = hrp()
    local p = h and h.Position or nil
    if p and lastP and (p - lastP).Magnitude > 500 then
      log("TELEPORT " .. tostring(lastP) .. " -> " .. tostring(p))
    end
    if p then lastP = p end
  end
end)
  game:GetService("RunService").Heartbeat:Connect(function()
    if genv.__babftGen ~= myGen then return end
    if cfg.farm then
      local h = hrp()
      if h then
        h.AssemblyLinearVelocity = Vector3.zero
        h.AssemblyAngularVelocity = Vector3.zero
        local c = LP.Character
        if c then for _, v in ipairs(c:GetDescendants()) do
          if v:IsA("BasePart") then v.CanCollide = false end
        end end
      end
      pcall(function()
        for _, d in ipairs(LP.PlayerGui:GetDescendants()) do
          if (d:IsA("TextButton") or d:IsA("ImageButton")) and d.Visible then
            local hit = d.Name:lower():find("claim") ~= nil
            if not hit then
              for _, ch in ipairs(d:GetDescendants()) do
                if (ch:IsA("TextLabel") or ch:IsA("TextButton"))
                  and tostring(ch.Text or ""):lower():find("claim") then
                  hit = true break
                end
              end
            end
            if hit then
              for _, cn in ipairs(getconnections(d.MouseButton1Click)) do
                pcall(function() cn.Function() end)
              end
              for _, cn in ipairs(getconnections(d.Activated)) do
                pcall(function() cn.Function() end)
              end
            end
          end
        end
      end)
    end
  end)
task.spawn(function()
  print("[BABFT] ready")
  while alive() do
    if cfg.farm then
      log("circle start, gold=" .. tostring(gold()))
      local wt0 = os.clock()
      while alive() and cfg.farm and hrp() == nil and os.clock() - wt0 < 15 do
        task.wait(0.5)
      end
      if hrp() == nil then
        log("no character, skip circle")
      else
      local z = nil
      pcall(function()
        for _, zz in ipairs(workspace:GetChildren()) do
          if zz.Name:find("Zone") then
            local tc = zz:FindFirstChild("TeamColor")
            if tc and LP.Team and tostring(tc.Value) == tostring(LP.Team.TeamColor) then
              z = zz break
            end
          end
        end
      end)
      log("zone=" .. (z and z.Name or "nil"))
      for _ = 1, 3 do
        if not alive() or not cfg.farm then break end
        if z and z.Launched.Value then break end
        local okL = doLaunch()
        log("launch press ok=" .. tostring(okL) .. " launched=" .. tostring(z and z.Launched.Value))
        task.wait(0.2)
      end
      local h0 = hrp()
      log("fly start at " .. tostring(h0 and h0.Position))
      flyTo(Vector3.new(-54, 27, 300), cfg.speed)
      for i, wp in ipairs(WAYPOINTS) do
        if not alive() or not cfg.farm then break end
        local okW = flyTo(wp, cfg.speed)
        local hw = hrp()
        log("wp " .. i .. "/" .. #WAYPOINTS .. " ok=" .. tostring(okW) .. " at " .. tostring(hw and hw.Position))
      end
      if alive() and cfg.farm then
        flyTo(Vector3.new(-55.7, 9, 9492), cfg.speed)
        flyTo(CHEST, cfg.speed * 1.5)
        local g0 = gold()
        local t1 = os.clock()
        while alive() and cfg.farm and os.clock() - t1 < 8 do
          local hh = hrp()
          if hh then
            hh.CFrame = CFrame.new(CHEST + Vector3.new(0, math.sin(os.clock() * 6) * 2, 0))
          end
          local g1 = gold()
          if g0 ~= nil and g1 ~= nil and g1 > g0 then
            log("gold tick, resetting now")
            break
          end
          task.wait(0.1)
        end
        local hend = hrp()
        local chestPos = Vector3.new(-55.7, -358.7, 9492)
        local cdist = hend and (hend.Position - chestPos).Magnitude or -1
        log("chest hover done, dist=" .. math.floor(cdist) .. " hp=" .. tostring(LP.Character and LP.Character:FindFirstChildOfClass("Humanoid").Health))
        if hend and cdist < 40 then
          log("resetting")
          local h2 = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
          if h2 then pcall(function() h2.Health = 0 end) end
          local wt = os.clock()
          while alive() and cfg.farm and hrp() ~= nil and os.clock() - wt < 3 do
            task.wait(0.2)
          end
          wt = os.clock()
          while alive() and cfg.farm and hrp() == nil and os.clock() - wt < 15 do
            task.wait(0.5)
          end
          task.wait(1.7)
          local hn = hrp()
          log("respawned at " .. tostring(hn and hn.Position))
          local spawn = Vector3.new(470, -10, -25)
          pcall(function()
            local tm = LP.Team and game.Workspace.Teams:FindFirstChild(LP.Team.Name .. "Team")
            local sp = tm and tm:FindFirstChild("Spawns", true)
            sp = sp and (sp:FindFirstChildOfClass("SpawnLocation") or sp:FindFirstChildWhichIsA("BasePart", true))
            if sp then spawn = sp.Position + Vector3.new(0, 3, 0) end
          end)
          hn = hrp()
          if hn and (hn.Position - spawn).Magnitude > 200 then
            hn.CFrame = CFrame.new(spawn)
            task.wait(1)
          end
        end
      end
    end
    else
      task.wait(0.5)
    end
  end
end)
