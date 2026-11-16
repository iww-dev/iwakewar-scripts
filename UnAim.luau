-- UnAim | Universal Aimbot
-- by iwakewar team
-- Camera aim with sticky lock, FOV / smoothness / speed, linear or exponential
-- interpolation, trigger bot, FOV circle, and read-only built-in configs
-- (you load ours, you cannot save your own; one can be set to autoload).
-- GUI: our own gui-lib/PrimordialUI.luau (flat dark "primordial" style).
--
-- How the game is wired (Scoped FPS):
--   shot direction comes from CameraController:GetAimRay() -> (origin, lookVector);
--   the client raycasts with it, picks the victim, then fires [C-S]FireEvent with
--   that same origin/direction. So the camera is the actual aim: turn it and the
--   shot follows.
--   Camera aim uses CameraController:LerpToTarget(point, alpha) - the same call the
--   game's own aim assist uses, so recoil/scope stay intact.
--   Team filter is layered (see the "team filter" block): the game's own
--   MatchQuery.CanDamage, then explicit team attributes, then the CombatPlayers
--   roster which marks who is actually in this match.
--   Firing = set LocalPlayer attribute "M1" + [C-S]SyncCombatAction:FireServer("M1", t)
--   guarded by the game's own "CanAttack" attribute.
--
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/iww-dev/iwakewar-scripts/refs/heads/main/UnAim.luau"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local plr = Players.LocalPlayer

-- ---------------------------------------------------------------- teardown ---
local genv = getgenv and getgenv() or _G
local old = genv.__unaim
if old and type(old.Destroy) == "function" then
    pcall(function() old:Destroy() end)
end

local Conn, GUI, Window, circleDraw, highlight

local S = {
    enabled = true,
    activation = "Always",
    aimKeys = {},
    -- aim cone and movement
    fov = 19.50,            -- full cone, degrees
    releaseFov = 0.00,      -- extra cone kept while a target is already locked
    smooth = 0.20,          -- 0 = raw speed, 100 = very slow
    speed = 90.00,          -- 0..100 -> how fast the camera turns
    snapAngle = 1.00,       -- remaining error below this snaps exactly onto the target
    camDamp = 40.00,        -- how much of your own mouse movement is ignored while locked, %
    curve = "Linear",       -- "Linear" | "Exponential"
    -- target selection
    part = "Head",
    priority = "Closest to crosshair",
    sticky = true,
    prediction = 0,
    visibleOnly = true,
    teamCheck = true,
    -- extras
    trigger = false,
    triggerFov = 1.00,
    triggerDelay = 42.60,
    drawFov = true,
    highlightTarget = true,
    notifications = true,
    unloaded = false,
    -- runtime
    lock = nil,
    target = nil,
    targetName = "-",
    shots = 0,
    lastShot = 0,
}

-- elements we have to poke when a preset is loaded
local UI = {}

local function log(...)
    if not S.notifications then return end
    local parts = table.pack(...)
    local text = table.concat(parts, " ", 1, parts.n)
    pcall(function()
        GUI:Notify({ Title = "UnAim", Content = text, Duration = 2 })
    end)
end

-- ---------------------------------------------------------------- GUI load ---
do
    local LIB_URL = "https://raw.githubusercontent.com/iww-dev/iwakewar-scripts/refs/heads/main/gui-lib/PrimordialUI.luau"
    local cached = genv.PrimordialUI
    if type(cached) == "table" and type(cached.CreateWindow) == "function" then
        GUI = cached
    end
    -- local copy first (Real workspace / scripts folder), then the network one
    if not GUI and typeof(readfile) == "function" and typeof(loadstring) == "function" then
        for _, p in ipairs({ "PrimordialUI.luau", "iwakewar-scripts/gui-lib/PrimordialUI.luau" }) do
            local okFile, src = pcall(readfile, p)
            if okFile and type(src) == "string" and #src > 100 then
                local okLoad, res = pcall(function() return loadstring(src)() end)
                if okLoad and type(res) == "table" and type(res.CreateWindow) == "function" then
                    GUI = res
                    break
                end
            end
        end
    end
    if not GUI then
        local ok, res = pcall(function()
            return loadstring(game:HttpGet(LIB_URL))()
        end)
        if ok and type(res) == "table" and type(res.CreateWindow) == "function" then
            GUI = res
        else
            warn("[UnAim] PrimordialUI failed to load: " .. tostring(res))
            return
        end
    end
end

Window = GUI:CreateWindow({
    Title = "iwakewar: UnAim",
    Subtitle = "by iwakewar team",
    Footer = "by iwakewar team",
    Version = "v1.3.0",
    Size = UDim2.fromOffset(760, 500),
    ToggleKey = Enum.KeyCode.RightShift,
})

local Tabs = {
    Info = Window:Tab({ Title = "Info", Subtitle = "About the script" }),
    Main = Window:Tab({ Title = "Aim", Subtitle = "Aimbot settings" }),
    Misc = Window:Tab({ Title = "Misc", Subtitle = "Trigger, visuals, misc" }),
}
pcall(function() Window:SelectTab(1) end)

-- ------------------------------------------------------- game integration ---
local CameraController, MatchQuery, syncCombatAction
do
    local ok, m = pcall(require, ReplicatedStorage:WaitForChild("Utils"):WaitForChild("CameraController"))
    if ok and type(m) == "table" then CameraController = m end
    local ok2, m2 = pcall(require, ReplicatedStorage:WaitForChild("GameMode"):WaitForChild("MatchQuery"))
    if ok2 and type(m2) == "table" then MatchQuery = m2 end
    local remote = ReplicatedStorage:FindFirstChild("Remote")
    local gameEvent = remote and remote:FindFirstChild("Event") and remote.Event:FindFirstChild("Game")
    if gameEvent then
        syncCombatAction = gameEvent:FindFirstChild("[C-S]SyncCombatAction")
    end
end

-- ------------------------------------------------------------- team filter ---
-- Scoped FPS has its own match model, exposed through MatchQuery:
--   ReplicatedStorage.MatchState.Participants.<name> carries InMatch + TeamId,
--   MatchState.IsTeamMode says whether teams are even in play.
--   MatchQuery.GetRelation(me, target) -> "Self" | "Friendly" | "Enemy" | "Neutral".
-- So the filter asks the game directly instead of guessing from Player.Team
-- (which only holds the queue you sit in).
--
-- MatchQuery is a plain table of dot-call functions: GetRelation(me, target),
-- GetTeamId(name). Passing the module as `self` shifted every argument by one,
-- which is exactly why every relation used to come back "Neutral".
local function mq(method, ...)
    if not MatchQuery then return nil end
    local fn = MatchQuery[method]
    if type(fn) ~= "function" then return nil end

    local args = table.pack(...)
    local ok, res = pcall(fn, table.unpack(args, 1, args.n))
    if ok then return res end
    -- a build that defines them as colon methods instead
    local ok2, res2 = pcall(fn, MatchQuery, table.unpack(args, 1, args.n))
    if ok2 then return res2 end
    return nil
end

local function canDamage(name)
    if not S.teamCheck then
        return true
    end
    if not MatchQuery then
        return true
    end

    local rel = mq("GetRelation", plr.Name, name)
    if type(rel) == "string" and rel ~= "Neutral" then
        return not (rel == "Self" or rel == "Friendly")
    end

    -- Neutral means one of us is not in a match right now: ask the other two
    if mq("AreTeammates", plr.Name, name) == true then
        return false
    end
    if mq("CanDamage", plr.Name, name) == false then
        return false
    end

    return true
end

-- what the game thinks we are, handy for the status line and for debugging
local function myTeamId()
    local id = mq("GetTeamId", plr.Name)
    if id then return id end
    return "-"
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local function exclusionList()
    local list = {}
    local ch = plr.Character
    if ch then list[#list + 1] = ch end
    for _, name in ipairs({ "HandModel", "ViewWeapon", "Camera" }) do
        local inst = workspace:FindFirstChild(name)
        if inst then list[#list + 1] = inst end
    end
    return list
end

local function eye()
    if CameraController then
        local okP, p = pcall(CameraController.GetCameraPosition, CameraController)
        local okL, l = pcall(CameraController.GetLookVector, CameraController)
        if okP and okL and p and l then return p, l end
    end
    local cam = workspace.CurrentCamera
    if cam then return cam.CFrame.Position, cam.CFrame.LookVector end
    return nil, nil
end

local function collectCharacters()
    local list, seen = {}, {}
    local function add(char)
        if not char or seen[char] or char == plr.Character then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return end
        if char:GetAttribute("FakeChar") then return end
        if not canDamage(char.Name) then return end
        seen[char] = true
        list[#list + 1] = char
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= plr then add(p.Character) end
    end
    for _, folderName in ipairs({ "PlayersCharacters", "LobbyBots", "Bots", "NPCs" }) do
        local folder = workspace:FindFirstChild(folderName)
        if folder then
            for _, m in ipairs(folder:GetChildren()) do
                if m:IsA("Model") then add(m) end
            end
        end
    end
    return list
end

local function aimParts(char)
    local torso = char:FindFirstChild("Torso")
        or char:FindFirstChild("UpperTorso")
        or char:FindFirstChild("HumanoidRootPart")
    return char:FindFirstChild("Head"), torso
end

local function visible(eyePos, part)
    local char = part and part.Parent and part:FindFirstAncestorOfClass("Model")
    if not char then return false end
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = exclusionList()
    local hit = workspace:Raycast(eyePos, (part.Position - eyePos), rayParams)
    if not hit then return false end
    -- hitting anything that belongs to the target counts as a clear line of sight
    return hit.Instance:IsDescendantOf(char)
end

local function angleTo(eyePos, look, pos)
    local d = pos - eyePos
    if d.Magnitude < 1e-4 then return 0 end
    return math.deg(math.acos(math.clamp(d.Unit:Dot(look), -1, 1)))
end

-- ------------------------------------------------------- target selection ---
local function partList(char)
    local head, torso = aimParts(char)
    if S.part == "Head" then
        return head and { head } or {}
    elseif S.part == "Torso" then
        return torso and { torso } or {}
    end
    local list = {}
    if head then list[#list + 1] = head end
    if torso then list[#list + 1] = torso end
    return list
end

local function makeCandidate(char, part, eyePos, look)
    local hum = char:FindFirstChildOfClass("Humanoid")
    return {
        char = char,
        part = part,
        partName = part.Name,
        pos = part.Position,
        velocity = part.AssemblyLinearVelocity,
        angle = angleTo(eyePos, look, part.Position),
        dist = (part.Position - eyePos).Magnitude,
        hp = hum and hum.Health or 0,
    }
end

local function refreshLocked(eyePos, look)
    local t = S.lock
    if not t then return nil end

    local char = t.char
    if not char or not char.Parent or not char:IsDescendantOf(workspace) then return nil end
    if char == plr.Character then return nil end
    if char:GetAttribute("FakeChar") then return nil end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return nil end
    if not canDamage(char.Name) then return nil end

    local part = t.part
    if not part or not part.Parent then
        part = char:FindFirstChild(t.partName or "Head")
        if not part then return nil end
        t.part = part
    end

    -- a locked target still has to be in sight; without this the lock happily
    -- kept chasing through walls for as long as the target stayed in the cone
    if S.visibleOnly and not visible(eyePos, part) then return nil end

    local cand = makeCandidate(char, part, eyePos, look)
    -- a held target is allowed to drift a bit further out than the entry FOV
    if cand.angle > (S.fov * 0.5 + S.releaseFov) then return nil end
    return cand
end

local function pickFrom(list)
    local best
    for _, cand in ipairs(list) do
        local better = false
        if not best then
            better = true
        elseif S.priority == "Lowest health" then
            if cand.hp < best.hp then
                better = true
            elseif cand.hp == best.hp and cand.angle < best.angle then
                better = true
            end
        elseif S.priority == "Closest distance" then
            if cand.dist < best.dist then
                better = true
            elseif cand.dist == best.dist and cand.angle < best.angle then
                better = true
            end
        else -- Closest to crosshair
            if cand.angle < best.angle then better = true end
        end
        if better then best = cand end
    end
    return best
end

local function selectTarget()
    local eyePos, look = eye()
    if not eyePos or not look then return nil end

    -- sticky lock: hold the current target until it dies / leaves the release cone
    if S.sticky then
        local held = refreshLocked(eyePos, look)
        if held then return held end
        S.lock = nil
    end

    local halfFov = S.fov * 0.5
    local pool = {}
    for _, char in ipairs(collectCharacters()) do
        for _, part in ipairs(partList(char)) do
            local cand = makeCandidate(char, part, eyePos, look)
            if cand.angle <= halfFov then
                if not S.visibleOnly or visible(eyePos, part) then
                    pool[#pool + 1] = cand
                end
            end
        end
    end

    local best = pickFrom(pool)
    if best then
        S.lock = { char = best.char, part = best.part, partName = best.partName }
    end
    return best
end

-- -------------------------------------------------------------- aim engine ---
local function predPos(t)
    if not t then return nil end
    -- only what the slider says: no hidden ping lead. Pressing "Prediction 0"
    -- has to mean "aim exactly where the head is", otherwise the camera sits
    -- ahead of the target in the direction it is running.
    local leadSec = S.prediction / 1000
    if leadSec <= 0 then
        return t.pos
    end
    return t.pos + t.velocity * leadSec
end

-- returns the fraction of the remaining error (degrees) we may close this frame
local function aimAlpha(errorDeg, dt)
    local step = math.clamp(dt or 0.016, 0.001, 0.1)
    if errorDeg <= 1e-6 then return 1 end

    local speedScale = math.clamp(S.speed / 100, 0, 1)
    local smoothScale = 1 - math.clamp(S.smooth / 100, 0, 1) * 0.95 -- 1 .. 0.05

    if S.curve == "Linear" then
        -- constant angular velocity: the camera covers the same degrees per second
        -- no matter how far it still has to travel
        local degPerSec = (2 + 178 * speedScale) * smoothScale
        local want = degPerSec * step
        if want >= errorDeg then return 1 end
        return math.clamp(want / errorDeg, 0, 1)
    else
        -- exponential: closes a fixed fraction of what is left, frame-rate independent
        local rate = (0.6 + 22 * speedScale) * smoothScale
        return math.clamp(1 - math.exp(-rate * step), 0, 1)
    end
end

-- Push the camera exactly where it has to look. CameraController keeps its own
-- yaw/pitch pair (CurrentAngles) and builds both the camera and GetAimRay from
-- it, so we set those angles directly instead of nudging the camera CFrame -
-- anything else leaves a permanent lag behind a moving target.
--
-- Mouse damping: CameraController.ApplyRotation adds the raw mouse delta to
-- CurrentAngles inside its own RenderStepped, which runs before ours. So by the
-- time we read GetAngles() the player's movement is already baked in. We keep
-- the angles we wrote last frame, measure that difference and keep only
-- (1 - camDamp/100) of it - the target stays glued instead of being dragged off
-- by every little hand twitch.
local aimState = { yaw = nil, pitch = nil }

local function applyCameraAim(pos, dt)
    if not pos then return end
    local eyePos, look = eye()
    if not eyePos or not look then return end
    local d = pos - eyePos
    if d.Magnitude < 0.05 then return end
    local u = d.Unit

    -- same convention CameraController itself uses in LerpToTarget
    local wantYaw = math.deg(math.atan2(-u.X, -u.Z))
    local wantPitch = math.deg(math.asin(math.clamp(u.Y, -1, 1)))

    if CameraController and type(CameraController.SetAngles) == "function" then
        local curYaw, curPitch = wantYaw, wantPitch
        if type(CameraController.GetAngles) == "function" then
            local ok, y, p = pcall(CameraController.GetAngles, CameraController)
            if ok and type(y) == "number" and type(p) == "number" then
                curYaw, curPitch = y, p
            end
        end

        -- let only a fraction of what the player did since our last write through
        if aimState.yaw and S.camDamp > 0 then
            local keep = 1 - math.clamp(S.camDamp, 0, 95) / 100
            local dYawIn = (curYaw - aimState.yaw + 180) % 360 - 180
            local dPitchIn = curPitch - aimState.pitch
            curYaw = aimState.yaw + dYawIn * keep
            curPitch = aimState.pitch + dPitchIn * keep
        end

        local dYaw = (wantYaw - curYaw + 180) % 360 - 180
        local dPitch = wantPitch - curPitch
        local error = math.sqrt(dYaw * dYaw + dPitch * dPitch)

        local alpha = aimAlpha(error, dt)
        -- once we are inside the snap window, land exactly on the target instead
        -- of easing asymptotically around it forever
        if error <= S.snapAngle then
            alpha = 1
        end

        local newYaw = curYaw + dYaw * alpha
        local newPitch = curPitch + dPitch * alpha
        pcall(CameraController.SetAngles, CameraController, newYaw, newPitch)
        aimState.yaw, aimState.pitch = newYaw, newPitch
        return
    end

    -- fallback for builds without SetAngles
    local current = math.acos(math.clamp(look:Dot(u), -1, 1))
    local alpha = math.deg(current) <= S.snapAngle and 1 or aimAlpha(math.deg(current), dt)
    if CameraController and type(CameraController.LerpToTarget) == "function" then
        pcall(CameraController.LerpToTarget, CameraController, pos, alpha)
    else
        local cam = workspace.CurrentCamera
        if cam then
            local targetCF = CFrame.lookAt(eyePos, eyePos + u)
            cam.CFrame = cam.CFrame:Lerp(targetCF, alpha)
        end
    end
end

local function shoot()
    local now = os.clock()
    if now - S.lastShot < math.max(0.02, S.triggerDelay / 1000) then return end
    if plr:GetAttribute("CanAttack") ~= true then return end
    S.lastShot = now
    local t = tick()
    pcall(function() plr:SetAttribute("M1", t) end)
    if syncCombatAction then
        pcall(function() syncCombatAction:FireServer("M1", t) end)
    end
    S.shots += 1
end

local function keyDown()
    if S.activation == "Always" then return true end
    if S.activation == "Hold RMB" then
        return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    end
    for _, k in ipairs(S.aimKeys) do
        if UIS:IsKeyDown(k) then return true end
    end
    return false
end

local function updateHighlight(target)
    if not S.highlightTarget then
        if highlight then highlight:Destroy() highlight = nil end
        return
    end
    local char = target and target.char
    if highlight and highlight.Parent == char then return end
    if highlight then
        pcall(function() highlight:Destroy() end)
        highlight = nil
    end
    if char then
        local h = Instance.new("Highlight")
        h.Name = "UnAimHighlight"
        h.FillColor = Color3.fromRGB(216, 132, 171)
        h.OutlineColor = Color3.fromRGB(255, 255, 255)
        h.FillTransparency = 0.65
        h.OutlineTransparency = 0.1
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = char
        highlight = h
    end
end

local function fovRadius()
    local cam = workspace.CurrentCamera
    if not cam then return 0 end
    local halfScreen = cam.ViewportSize.Y * 0.5
    local camHalf = math.tan(math.rad((cam.FieldOfView or 70) * 0.5))
    if camHalf <= 0 then return 0 end
    -- match the circle to the real angular cone
    return (math.tan(math.rad(S.fov * 0.5)) / camHalf) * halfScreen
end

-- --------------------------------------------------------------- main loop ---
local function step(dt)
    if S.unloaded then return end
    local aiming = S.enabled and keyDown()

    local target = nil
    if aiming then
        target = selectTarget()
    else
        S.lock = nil
    end
    if not target then
        -- nothing locked: stop rebasing, the next lock starts from wherever the
        -- camera actually is
        aimState.yaw, aimState.pitch = nil, nil
    end
    S.target = target
    S.targetName = target and target.char.Name or "-"

    if target then
        local aimPos = predPos(target)

        -- crosshair angle before the camera moves this frame
        local eyePos, look = eye()
        local current = 0
        if eyePos and look then current = angleTo(eyePos, look, aimPos) end

        applyCameraAim(aimPos, dt)

        if S.trigger and current <= S.triggerFov * 0.5 then
            shoot()
        end
    end

    updateHighlight(target)

    if circleDraw then
        local cam = workspace.CurrentCamera
        if S.drawFov and cam then
            circleDraw.Visible = true
            circleDraw.Position = cam.ViewportSize * 0.5
            circleDraw.Radius = fovRadius()
        else
            circleDraw.Visible = false
        end
    end
end

-- ------------------------------------------------------------------ drawing ---
if Drawing and Drawing.new then
    circleDraw = Drawing.new("Circle")
    circleDraw.Thickness = 1.5
    circleDraw.Filled = false
    circleDraw.Color = Color3.fromRGB(216, 132, 171)
    circleDraw.Transparency = 0.55
    circleDraw.Visible = false
end

-- --------------------------------------------------------------------- tab ---
Tabs.Main:Section({ Title = "Main Functions" })

local Status = Tabs.Main:Paragraph({
    Title = "Status",
    Content = "Idle",
})
local Live = Tabs.Main:Paragraph({
    Title = "Live",
    Content = "state: ON | target: - | mode: - | shots: 0",
})

UI.aim = Tabs.Main:Toggle({
    Title = "Aimbot",
    Description = "Master switch for the whole aimbot",
    Default = true,
    Callback = function(state)
        S.enabled = state
        if not state then S.lock = nil end
        log(state and "Aimbot enabled" or "Aimbot disabled")
    end,
})

UI.activation = Tabs.Main:Dropdown({
    Title = "Activation",
    Description = "How the aimbot turns on: hold a key, hold RMB, or always",
    Values = { "Hold key", "Hold RMB", "Always" },
    Value = "Always",
    Callback = function(value)
        S.activation = value
        if value ~= "Hold key" then S.lock = nil end
    end,
})

local aimKey = Tabs.Main:Keybind({
    Title = "Aim keybind",
    Description = "Hold this key to aim (used with Activation = Hold key)",
    Mode = "Hold",
    Default = "LeftAlt",
    Callback = function(keys)
        S.aimKeys = keys or {}
    end,
})
-- the keybind element fills its default keys without calling the callback
S.aimKeys = aimKey.Keys or {}

local fovSlider = Tabs.Main:Slider({
    Title = "FOV",
    Description = "Full cone in degrees - how far from the crosshair it may pick a target",
    Min = 5,
    Max = 180,
    Value = 19.50,
    Callback = function(v)
        S.fov = v
    end,
})
fovSlider:SetValue(S.fov)
UI.fov = fovSlider

Tabs.Main:Section({ Title = "Smoothing" })

local speedSlider = Tabs.Main:Slider({
    Title = "Speed",
    Description = "How fast the camera turns toward the target",
    Min = 1,
    Max = 100,
    Value = 90.00,
    Callback = function(v)
        S.speed = v
    end,
})
speedSlider:SetValue(S.speed)
UI.speed = speedSlider

local smoothSlider = Tabs.Main:Slider({
    Title = "Smoothness",
    Description = "0 = raw speed, 100 = very slow and buttery",
    Min = 0,
    Max = 100,
    Value = 0.20,
    Callback = function(v)
        S.smooth = v
    end,
})
smoothSlider:SetValue(S.smooth)
UI.smooth = smoothSlider

UI.curve = Tabs.Main:Dropdown({
    Title = "Curve",
    Description = "Linear = constant turn rate, Exponential = eases in and never overshoots",
    Values = { "Exponential", "Linear" },
    Value = "Linear",
    Callback = function(value)
        S.curve = value
    end,
})

local snapSlider = Tabs.Main:Slider({
    Title = "Snap",
    Description = "Once the crosshair is this many degrees from the target it locks on exactly",
    Min = 0,
    Max = 15,
    Value = 1.00,
    Callback = function(v)
        S.snapAngle = v
    end,
})
snapSlider:SetValue(S.snapAngle)
UI.snap = snapSlider

local dampSlider = Tabs.Main:Slider({
    Title = "Input damp",
    Description = "How much of your own mouse movement is ignored while a target is locked, %",
    Min = 0,
    Max = 95,
    Value = 40.00,
    Callback = function(v)
        S.camDamp = v
    end,
})
dampSlider:SetValue(S.camDamp)
UI.camDamp = dampSlider

local predSlider = Tabs.Main:Slider({
    Title = "Prediction",
    Description = "Lead the target, ms (plus your ping)",
    Min = 0,
    Max = 250,
    Value = 0,
    Callback = function(v)
        S.prediction = v
    end,
})
predSlider:SetValue(S.prediction)
UI.prediction = predSlider

Tabs.Main:Section({ Title = "Target" })

UI.part = Tabs.Main:Dropdown({
    Title = "Target part",
    Description = "Which bone the aimbot locks on",
    Values = { "Head", "Torso", "Nearest" },
    Value = "Head",
    Callback = function(value)
        S.part = value
        S.lock = nil
    end,
})

UI.priority = Tabs.Main:Dropdown({
    Title = "Priority",
    Description = "How it picks the next target once the old one is dead",
    Values = { "Closest to crosshair", "Closest distance", "Lowest health" },
    Value = "Closest to crosshair",
    Callback = function(value)
        S.priority = value
    end,
})

UI.sticky = Tabs.Main:Toggle({
    Title = "Sticky lock",
    Description = "Keeps the target locked and keeps chasing it until it dies",
    Default = true,
    Callback = function(state)
        S.sticky = state
        if not state then S.lock = nil end
    end,
})

local releaseSlider = Tabs.Main:Slider({
    Title = "Release FOV",
    Description = "Extra degrees the already-locked target may drift away before it is dropped",
    Min = 0,
    Max = 90,
    Value = 0.00,
    Callback = function(v)
        S.releaseFov = v
    end,
})
releaseSlider:SetValue(S.releaseFov)
UI.release = releaseSlider

UI.visibleOnly = Tabs.Main:Toggle({
    Title = "Visible only",
    Description = "Skip targets behind walls, and drop the lock as soon as it breaks line of sight",
    Default = true,
    Callback = function(state)
        S.visibleOnly = state
        if not state then S.lock = nil end
    end,
})

UI.teamCheck = Tabs.Main:Toggle({
    Title = "Team check",
    Description = "Skip friendlies and players not in the current match (layered filter)",
    Default = true,
    Callback = function(state)
        S.teamCheck = state
        S.lock = nil
    end,
})

-- ------------------------------------------------------------------- misc ---

Tabs.Misc:Section({ Title = "Trigger bot" })

UI.trigger = Tabs.Misc:Toggle({
    Title = "Trigger bot",
    Description = "Shoots automatically when the crosshair is on a target",
    Default = false,
    Callback = function(state)
        S.trigger = state
    end,
})

local trigFovSlider = Tabs.Misc:Slider({
    Title = "Trigger FOV",
    Description = "How close to the crosshair the target must be, degrees",
    Min = 1,
    Max = 60,
    Value = 1.00,
    Callback = function(v)
        S.triggerFov = v
    end,
})
trigFovSlider:SetValue(S.triggerFov)
UI.triggerFov = trigFovSlider

local trigDelaySlider = Tabs.Misc:Slider({
    Title = "Trigger delay",
    Description = "Minimum time between shots, ms",
    Min = 0,
    Max = 400,
    Value = 42.60,
    Callback = function(v)
        S.triggerDelay = v
    end,
})
trigDelaySlider:SetValue(S.triggerDelay)
UI.triggerDelay = trigDelaySlider

Tabs.Misc:Section({ Title = "Visuals" })

UI.drawFov = Tabs.Misc:Toggle({
    Title = "FOV circle",
    Description = "Draw the aim cone on screen",
    Default = true,
    Callback = function(state)
        S.drawFov = state
    end,
})

UI.highlightTarget = Tabs.Misc:Toggle({
    Title = "Highlight target",
    Description = "Outline the locked target",
    Default = true,
    Callback = function(state)
        S.highlightTarget = state
    end,
})

UI.noNotify = Tabs.Misc:Toggle({
    Title = "Do not send notifications",
    Description = "Hide all notifications",
    Default = false,
    Callback = function(state)
        S.notifications = not state
    end,
})

Tabs.Misc:Button({
    Title = "Unload UnAim",
    Description = "Remove the GUI and stop everything",
    Callback = function()
        if genv.__unaim then genv.__unaim:Destroy() end
    end,
})

-- ----------------------------------------------------------- read-only presets ---
-- We ship the configs, you only pick one. There is deliberately no "save my own
-- config" here: nothing is written to disk except the NAME of the preset you want
-- on the next launch, and that name has to exist in PRESETS to be accepted.
local CFG_DIR = "iwakewar-scripts/UnAim"
local CFG_FILE = CFG_DIR .. "/autoload.txt"

local PRESETS, PRESET_ORDER = {}, {}

local function addPreset(name, values)
    PRESETS[name] = values
    PRESET_ORDER[#PRESET_ORDER + 1] = name
end

-- Almost Full Rage: everything turned up to near-max, camera basically teleports
-- onto the nearest bone and the trigger does the clicking.
addPreset("Almost Full Rage (AFR)", {
    enabled = true,
    activation = "Always",
    fov = 115.00,
    speed = 98.44,
    smooth = 3.94,
    curve = "Exponential",
    snapAngle = 15.00,      -- max the slider allows: lands exactly from far out
    camDamp = 40.00,        -- hand movement barely drags the locked aim
    prediction = 6.90,
    part = "Nearest",
    priority = "Closest to crosshair",
    sticky = true,
    releaseFov = 0.00,
    visibleOnly = true,
    teamCheck = true,
    trigger = true,
    triggerFov = 1.12,
    triggerDelay = 84.42,
    drawFov = true,
    highlightTarget = true,
})

-- push the current S values back into the widgets (presets are applied by
-- writing S first, then mirroring it, so the GUI never disagrees with the aim)
local function syncUI()
    local function tog(el, v) if el then pcall(el.SetValue, el, v == true) end end
    local function slider(el, v) if el then pcall(el.SetValue, el, v) end end
    local function drop(el, v) if el and v ~= nil then pcall(el.SetValue, el, v) end end

    tog(UI.aim, S.enabled)
    drop(UI.activation, S.activation)
    slider(UI.fov, S.fov)
    slider(UI.speed, S.speed)
    slider(UI.smooth, S.smooth)
    drop(UI.curve, S.curve)
    slider(UI.snap, S.snapAngle)
    slider(UI.camDamp, S.camDamp)
    slider(UI.prediction, S.prediction)
    drop(UI.part, S.part)
    drop(UI.priority, S.priority)
    tog(UI.sticky, S.sticky)
    slider(UI.release, S.releaseFov)
    tog(UI.visibleOnly, S.visibleOnly)
    tog(UI.teamCheck, S.teamCheck)
    tog(UI.trigger, S.trigger)
    slider(UI.triggerFov, S.triggerFov)
    slider(UI.triggerDelay, S.triggerDelay)
    tog(UI.drawFov, S.drawFov)
    tog(UI.highlightTarget, S.highlightTarget)
end

local loadedPreset = nil

local function applyPreset(name)
    local preset = PRESETS[name]
    if not preset then return false end

    for key, value in pairs(preset) do
        S[key] = value
    end
    -- a new config must not keep the old lock
    S.lock, S.target, S.targetName = nil, nil, "-"
    loadedPreset = name
    syncUI()
    return true
end

-- what the sliders say right now vs the preset that was loaded: if they drifted,
-- the config is no longer "ours" and the label says so
local function currentPresetName()
    if not loadedPreset then return nil end
    local preset = PRESETS[loadedPreset]
    if not preset then return nil end
    for key, value in pairs(preset) do
        local now = S[key]
        if type(value) == "number" then
            if type(now) ~= "number" or math.abs(now - value) > 0.005 then
                return nil
            end
        elseif now ~= value then
            return nil
        end
    end
    return loadedPreset
end

local function fileApiReady()
    return type(writefile) == "function" and type(readfile) == "function"
end

local function saveAutoload(name)
    if not fileApiReady() then return false end
    return (pcall(function()
        if type(makefolder) == "function" then pcall(makefolder, CFG_DIR) end
        if type(name) == "string" and PRESETS[name] then
            writefile(CFG_FILE, name)
        elseif type(isfile) == "function" and isfile(CFG_FILE) then
            if type(delfile) == "function" then delfile(CFG_FILE) else writefile(CFG_FILE, "") end
        end
    end))
end

local function readAutoload()
    if not fileApiReady() then return nil end
    local ok, txt = pcall(readfile, CFG_FILE)
    if not ok or type(txt) ~= "string" then return nil end
    local name = txt:match("^%s*(.-)%s*$")
    if name and PRESETS[name] then return name end
    return nil
end

-- ------------------------------------------------------------------ configs tab ---
local CfgTab = Window:Tab({ Title = "Configs", Subtitle = "Read-only presets" })

CfgTab:Section({ Title = "Built-in configs" })

CfgTab:Paragraph({
    Title = "How it works",
    Content = "You cannot create or save your own config - only the ones we ship are here.\n"
        .. "Pick one, hit Load, and every slider moves to it.\n"
        .. "Turn on Autoload and the same preset is applied the next time UnAim loads.",
})

local cfgStatus = CfgTab:Paragraph({
    Title = "Active config",
    Content = "Custom (manual)",
})

local presetDropdown = CfgTab:Dropdown({
    Title = "Config",
    Description = "What we ship",
    Values = PRESET_ORDER,
    Value = PRESET_ORDER[1],
    Callback = function() end,
})

local autoloadOn = false
local autoloadToggle

local function refreshCfgStatus()
    pcall(function()
        cfgStatus:SetContent(string.format(
            "%s\nautoload: %s",
            currentPresetName() or "Custom (manual)",
            autoloadOn and "ON" or "OFF"
        ))
    end)
end

CfgTab:Button({
    Title = "Load config",
    Description = "Apply the selected config to every setting",
    Callback = function()
        local name = presetDropdown.Value
        if applyPreset(name) then
            if autoloadOn then saveAutoload(name) end
            refreshCfgStatus()
            log("Config loaded: " .. name, 3)
        else
            log("Unknown config")
        end
    end,
})

autoloadToggle = CfgTab:Toggle({
    Title = "Autoload on launch",
    Description = "Load this config automatically the next time UnAim starts",
    Default = false,
    Callback = function(state)
        autoloadOn = state == true
        local name = presetDropdown.Value
        if autoloadOn then
            if not currentPresetName() then
                applyPreset(name)
            end
            if saveAutoload(name) then
                log("Autoload on: " .. name, 3)
            else
                log("No file API on this executor - autoload will not persist")
            end
        else
            saveAutoload(nil)
            log("Autoload off", 3)
        end
        refreshCfgStatus()
    end,
})

refreshCfgStatus()

-- --------------------------------------------------------------------- info ---
Tabs.Info:Paragraph({
    Title = "UnAim",
    Content = "Universal aimbot\nby iwakewar team\n\n"
        .. "- Camera aim: turns the camera onto the target inside the FOV cone\n"
        .. "- Sticky lock: holds one target and keeps chasing it until it dies\n"
        .. "- Speed / Smoothness / Curve: linear or exponential camera movement\n"
        .. "- Target part: Head / Torso / Nearest, with priority sorting\n"
        .. "- Prediction with your own ping, visible-only and team check\n"
        .. "- Trigger bot, FOV circle and target highlight\n"
        .. "- Read-only configs: load ours, put one on autoload in the Configs tab\n\n"
        .. "Press RightShift to open / close the menu.\n"
        .. "Aim key is LeftAlt by default - change it in the Aim tab.",
})

Tabs.Info:Button({
    Title = "Our Discord Server",
    Description = "Copy invite link to clipboard",
    Callback = function()
        local ok = pcall(function()
            if typeof(setclipboard) == "function" then setclipboard("https://discord.gg/GgshjzxxFS") end
        end)
        log(ok and "Discord link copied" or "No clipboard API on this executor")
    end,
})

-- put the autoload preset back, if one was saved last time
do
    local saved = readAutoload()
    if saved and applyPreset(saved) then
        autoloadOn = true
        pcall(function() autoloadToggle:SetValue(true) end)
        pcall(function() presetDropdown:SetValue(saved) end)
        refreshCfgStatus()
        log("Autoloaded config: " .. saved, 3)
    end
end

-- ------------------------------------------------------------------ runtime ---
Conn = RunService.RenderStepped:Connect(function(dt)
    local ok, err = pcall(step, dt)
    if not ok and S.notifications then
        S.notifications = false
        warn("[UnAim] " .. tostring(err))
    end
end)

task.spawn(function()
    while not S.unloaded do
        task.wait(0.5)
        if GUI and GUI.Unloaded then break end
        local state = S.enabled and "ON" or "OFF"
        pcall(function()
            Status:SetContent(string.format(
                "state: %s | target: %s | shots: %d | team: %s | config: %s",
                state, S.targetName, S.shots, myTeamId(), currentPresetName() or "custom"
            ))
        end)
        pcall(function()
            Live:SetContent(string.format(
                "fov: %.2f | speed: %.2f | smooth: %.2f | snap: %.2f | damp: %.0f%% | %s | part: %s | trigger: %s",
                S.fov, S.speed, S.smooth, S.snapAngle, S.camDamp, S.curve, S.part, S.trigger and "ON" or "OFF"
            ))
        end)
        if loadedPreset then refreshCfgStatus() end
    end
end)

pcall(function() Window:SetToggleKey(Enum.KeyCode.RightShift) end)
log("Loaded. Toggle menu with RightShift.", 4)

-- ------------------------------------------------------------------ destroy ---
local api = {}
-- exposed for debugging / other scripts: live settings, the current target,
-- the team filter and what the game says about a given player
api.S = S
api.shoot = shoot
api.canDamage = canDamage
api.teamId = myTeamId
api.relation = function(name)
    return mq("GetRelation", plr.Name, name) or "?"
end
-- read-only configs: list them, load one by name, see which one is applied
api.presets = PRESET_ORDER
api.loadPreset = applyPreset
api.config = function() return currentPresetName() end
api.autoload = function() return readAutoload() end
api.setAutoload = function(name)
    if name == nil then
        autoloadOn = false
        saveAutoload(nil)
        pcall(function() autoloadToggle:SetValue(false) end)
        refreshCfgStatus()
        return true
    end
    if not PRESETS[name] then return false end
    applyPreset(name)
    autoloadOn = true
    pcall(function() autoloadToggle:SetValue(true) end)
    pcall(function() presetDropdown:SetValue(name) end)
    refreshCfgStatus()
    return saveAutoload(name)
end
function api:Destroy()
    if S.unloaded then return end
    S.unloaded = true
    pcall(function() if Conn then Conn:Disconnect() end end)
    pcall(function() if circleDraw then circleDraw:Remove() end end)
    circleDraw = nil
    pcall(function() if highlight then highlight:Destroy() end end)
    highlight = nil
    pcall(function() if Window then Window:Destroy() end end)
    pcall(function() if GUI and GUI.Destroy then GUI:Destroy() end end)
    S.lock = nil
    if genv.__unaim == api then genv.__unaim = nil end
end

genv.__unaim = api
