repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local HS = game:GetService("HttpService")
local Stats = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ---------- CURSED RESET (G key) ----------
local cursedResetRemote = nil
local CURSED_RESET_GUID = "f888ee6e-c86d-46e1-93d7-0639d6635d42"
local _resetInProgress = false

pcall(function()
    if hookfunction and newcclosure then
        local oldFire
        oldFire = hookfunction(Instance.new("RemoteEvent").FireServer, newcclosure(function(self, ...)
            if not cursedResetRemote and typeof(self) == "Instance" and self:IsA("RemoteEvent") and self.Name:sub(1,3) == "RE/" then
                cursedResetRemote = self
            end
            return oldFire(self, ...)
        end))
    end
end)

local function findCursedResetRemote()
    if cursedResetRemote then return end
    for _, desc in ipairs(game:GetDescendants()) do
        if desc:IsA("RemoteEvent") and desc.Name:sub(1,3) == "RE/" then
            cursedResetRemote = desc
            return
        end
    end
end
task.spawn(function()
    task.wait(2)
    findCursedResetRemote()
end)

local function cursedInstaReset()
    if _resetInProgress then return end
    _resetInProgress = true

    if not cursedResetRemote then
        findCursedResetRemote()
        if not cursedResetRemote then
            task.wait(0.5)
            findCursedResetRemote()
            if not cursedResetRemote then
                _resetInProgress = false
                return
            end
        end
    end

    local character = LP.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if humanoid and humanoid.Health <= 0 then
        pcall(function() cursedResetRemote:FireServer(CURSED_RESET_GUID, LP, "balloon") end)
        _resetInProgress = false
        return
    end

    local resetDetected = false
    local conns = {}
    local finished = false

    if humanoid then
        table.insert(conns, humanoid.Died:Connect(function() resetDetected = true; finished = true end))
        table.insert(conns, humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            if humanoid.Health <= 0 then resetDetected = true; finished = true end
        end))
    end
    if character then
        table.insert(conns, character.AncestryChanged:Connect(function(_, parent)
            if not parent then resetDetected = true; finished = true end
        end))
    end

    task.spawn(function()
        for i = 1, 5 do
            if finished or resetDetected then break end
            pcall(function() cursedResetRemote:FireServer(CURSED_RESET_GUID, LP, "balloon") end)
            task.wait(0.1)
        end
        if not resetDetected then
            pcall(function() cursedResetRemote:FireServer(CURSED_RESET_GUID, LP, "balloon") end)
        end
        for _, conn in ipairs(conns) do pcall(function() conn:Disconnect() end) end
        _resetInProgress = false
    end)
end

-- ---------- BYPASS AIMBOT (N key) ----------
local BYPASS_FOLLOW_DIST = 1.0
local BYPASS_HEIGHT_OFFSET = 1.5
local BYPASS_VERTICAL_OFFSET = 0.0
local BYPASS_SWING_COOLDOWN = 0.08
local BYPASS_HIT_DIST = 4.5
local bypassToggled = false
local bypassHittingCooldown = false
local bypassConn = nil

local function findAnyToolBypass()
    local c = LP.Character
    if c then
        for _, v in ipairs(c:GetChildren()) do
            if v:IsA("Tool") then return v end
        end
    end
    local bp = LP:FindFirstChildOfClass("Backpack")
    if bp then
        for _, v in ipairs(bp:GetChildren()) do
            if v:IsA("Tool") then return v end
        end
    end
    return nil
end

local function getClosestPlayerBypass()
    local char = LP.Character
    if not char then return nil, math.huge end
    local hrp2 = char:FindFirstChild("HumanoidRootPart")
    if not hrp2 then return nil, math.huge end
    local closest, bestDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local tr = p.Character:FindFirstChild("HumanoidRootPart")
            local ph = p.Character:FindFirstChildOfClass("Humanoid")
            if tr and ph and ph.Health > 0 then
                local d = (hrp2.Position - tr.Position).Magnitude
                if d < bestDist then
                    bestDist = d
                    closest = p
                end
            end
        end
    end
    return closest, bestDist
end

local function tryHitBypass()
    if bypassHittingCooldown then return end
    bypassHittingCooldown = true
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local tool = findAnyToolBypass()
    if tool then
        if tool.Parent ~= char and hum then
            pcall(function() hum:EquipTool(tool) end)
        end
        local remote = tool:FindFirstChildOfClass("RemoteEvent")
        if remote then
            pcall(function() remote:FireServer() end)
        else
            pcall(function() tool:Activate() end)
        end
    end
    task.delay(BYPASS_SWING_COOLDOWN, function()
        bypassHittingCooldown = false
    end)
end

local function startBypassAimbot()
    if bypassConn then return end
    bypassConn = RunService.Heartbeat:Connect(function()
        if not bypassToggled then return end
        local char = LP.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not root or not hum then return end

        local target, dist = getClosestPlayerBypass()
        if target and target.Character then
            local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local targetVel = targetRoot.AssemblyLinearVelocity
                local moveDir = targetVel.Magnitude > 0.1 and targetVel.Unit or targetRoot.CFrame.LookVector
                local offset = moveDir * BYPASS_FOLLOW_DIST + Vector3.new(0, BYPASS_HEIGHT_OFFSET + BYPASS_VERTICAL_OFFSET, 0)
                local desiredPos = targetRoot.Position + offset
                local toTarget = desiredPos - root.Position
                if toTarget.Magnitude > 0.5 then
                    local moveVec = toTarget.Unit * S.bypassAimbotSpeed
                    root.AssemblyLinearVelocity = Vector3.new(moveVec.X, moveVec.Y, moveVec.Z)
                else
                    root.AssemblyLinearVelocity = root.AssemblyLinearVelocity * 0.95
                    if root.AssemblyLinearVelocity.Magnitude < 1 then
                        root.AssemblyLinearVelocity = Vector3.zero
                    end
                end
                local distToTarget = (root.Position - targetRoot.Position).Magnitude
                if distToTarget <= BYPASS_HIT_DIST then
                    tryHitBypass()
                end
            end
        else
            root.AssemblyLinearVelocity = root.AssemblyLinearVelocity * 0.9
            if root.AssemblyLinearVelocity.Magnitude < 1 then
                root.AssemblyLinearVelocity = Vector3.zero
            end
        end
    end)
end

local function stopBypassAimbot()
    if bypassConn then
        bypassConn:Disconnect()
        bypassConn = nil
    end
    local char = LP.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            root.AssemblyLinearVelocity = Vector3.zero
        end
    end
    bypassHittingCooldown = false
end

local function toggleBypass(state)
    if state == nil then
        state = not bypassToggled
    end
    bypassToggled = state
    if bypassToggled then
        startBypassAimbot()
    else
        stopBypassAimbot()
    end
end

-- ---------- ORIGINAL SCRIPT (con corrección de arrastre) ----------
local galaxyOn = false
local defBrightness, defClock, defAmbient = Lighting.Brightness, Lighting.ClockTime, Lighting.OutdoorAmbient

local removedAccessories = {}

local function removeCharacterAccessories()
    local char = LP.Character
    if not char then return end
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Accessory") or child:IsA("Hat") or (child:IsA("Model") and child:FindFirstChild("Handle")) then
            table.insert(removedAccessories, {parent = child.Parent, acc = child})
            child.Parent = nil
        end
    end
end

local function restoreAccessories()
    for _, item in ipairs(removedAccessories) do
        if item.acc and not item.acc.Parent then
            item.acc.Parent = item.parent
        end
    end
    removedAccessories = {}
end

local function updateGalaxy()
    if galaxyOn then
        local sky = Lighting:FindFirstChild("adapsGalaxySky") or Instance.new("Sky")
        sky.Name = "adapsGalaxySky"
        sky.SkyboxBk, sky.SkyboxDn, sky.SkyboxFt, sky.SkyboxLf, sky.SkyboxRt, sky.SkyboxUp =
            "rbxassetid://90008389385236","rbxassetid://135894687762727","rbxassetid://135894687762727",
            "rbxassetid://135894687762727","rbxassetid://135894687762727","rbxassetid://135894687762727"
        sky.Parent = Lighting
        Lighting.Brightness, Lighting.ClockTime, Lighting.ExposureCompensation = 0, 0, -2
        Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
    else
        if Lighting:FindFirstChild("adapsGalaxySky") then Lighting.adapsGalaxySky:Destroy() end
        Lighting.Brightness, Lighting.ClockTime, Lighting.ExposureCompensation = defBrightness, defClock, 0
        Lighting.OutdoorAmbient = defAmbient
    end
end

local function toggleGalaxyMode()
    galaxyOn = not galaxyOn
    updateGalaxy()
end

local function safeWritefile(path, data) if type(writefile) == "function" then pcall(writefile, path, data) end end
local function safeReadfile(path) if type(readfile) == "function" then local ok, data = pcall(readfile, path) return ok and data or nil end return nil end
local function safeIsfile(path) if type(isfile) == "function" then local ok, res = pcall(isfile, path) return ok and res end return false end
local function safeSetfpscap(v) if type(setfpscap) == "function" then pcall(setfpscap, v) end end
local function safeSethiddenproperty(obj, prop, val) if type(sethiddenproperty) == "function" then pcall(sethiddenproperty, obj, prop, val) end end

local S = {
    CS = 30, LS = 10.1,
    speedMode = false, laggerMode = false,
    infJumpEnabled = false, medusaCounterEnabled = false,
    medusaDebounce = false, medusaLastUsed = 0, medusaConns = {}, MEDUSA_COOLDOWN = 25,
    unwalkEnabled = false,
    _setPButtonActive = nil, speedCounterLabel = nil,
    batAimbotEnabled = false, batAimbotConn = nil,
    batCounterEnabled = false, batCounterConn = nil, batCounterDebounce = false,
    setBatCounterVisual = nil,
    fpsBoostEnabled = false,
    lockUIEnabled = false,
    mainMenuFrame = nil, miniToggleButton = nil, floatingPanelFrame = nil, floatingPanelGui = nil,
    _noclipTimer = 0, _fpsCount = 0, _lastFpsTime = tick(), currentFPS = 0,
    setLaggerVisual = nil, speedClk = nil, setFpsVisual = nil, setInfJumpVisual = nil,
    setMedusaVisual = nil,
    setUnwalkVisual = nil, setDarkVisual = nil,
    normalBox = nil, carryBox = nil, laggerBox = nil,
    setLockUI_Visual = nil, setHideOpiumButtons = nil,
    autoTPDownEnabled = false, autoTPDownThreshold = 20, autoTPDownConn = nil,
    autoTPDownSetVisual = nil, autoTPDownFloatVisual = nil,
    autoTPDownThresholdBox = nil,
    dropBrainrotActive = false,
    espEnabled = false,
    espFolder = nil,
    espConnections = {},
    atrAutoLeft = false,
    atrAutoRight = false,
    atrActiveConnection = nil,
    autoPlayPhase = 1,
    autoPlayWaiting = false,
    autoPlayDirection = "left",
    autoStealEnabled = false,
    autoStealConnection = nil,
    simpleAimbotEnabled = false,
    simpleAimbotConn = nil,
    simpleAimbotCooldown = false,
    setAutoPlayVisual = nil,
    autoPlaySpeed1 = 60,
    autoPlaySpeed2 = 30,
    KB = {
        DropBrainrot = {kb = Enum.KeyCode.X, gp = Enum.KeyCode.ButtonR2},
        AutoBat = {kb = Enum.KeyCode.E, gp = Enum.KeyCode.ButtonY},
        TPFlor = {kb = Enum.KeyCode.F, gp = Enum.KeyCode.ButtonA},
        GuiHide = {kb = Enum.KeyCode.LeftControl, gp = Enum.KeyCode.ButtonSelect},
        SpeedToggle = {kb = Enum.KeyCode.Q, gp = Enum.KeyCode.DPadUp},
        LaggerToggle = {kb = Enum.KeyCode.R, gp = Enum.KeyCode.DPadDown},
        AutoTPDown = {kb = Enum.KeyCode.T, gp = nil},
    },
    AP = {
        L1 = Vector3.new(-476.48, -6.28, 92.73), L2 = Vector3.new(-482.85, -5.03, 93.13),
        L_FACE = Vector3.new(-482.25, -4.96, 92.09),
        R1 = Vector3.new(-476.16, -6.52, 25.62), R2 = Vector3.new(-483.06, -5.03, 27.51),
        R_FACE = Vector3.new(-482.06, -6.93, 35.47),
    },
    Conns = {anchor = {}},
    moveConn = nil, speedEnabled = true, h = nil, hrp = nil,
    lastMoveDir = Vector3.new(0,0,0),
    IS_TOUCH_DEVICE = UIS.TouchEnabled,
    IS_MOBILE = UIS.TouchEnabled and not UIS.KeyboardEnabled,
    CONFIG_FILE = "SUREHUBPC.json",
    _floatingButtons = {},
    BAT_HIT_RANGE = 16,
    autoTPDownCooldownUntil = 0,
    tauntEnabled = false,
    tauntGui = nil,
    tauntActive = false,
    tauntLoop = nil,
    _btnBat = nil,
    _bsBat = nil,
    _l1Bat = nil,
    _l2Bat = nil,
    setBatButtonVisual = nil,
    antiRagdollEnabled = false,
    antiRagdollConn = nil,
    setAntiRagdollVisual = nil,
    bypassAimbotSpeed = 60,
    bypassSpeedBox = nil,
    _btnDrop2 = nil,
    _bsDrop2 = nil,
    _l1Drop2 = nil,
    _l2Drop2 = nil,
    setDrop2Visual = nil,
    floatingButtonsLocked = false,
    bypassAimbotV2Toggled = false,
    bypassAimbotV2HittingCooldown = false,
    bypassAimbotV2Conn = nil,
    setBypassAimbotV2Visual = nil,
    autoPlaySpdBox = nil,
    vueltaAutoPlayBox = nil,
}

local SWING_COOLDOWN = 0.25

S.ui = function(pcVal, mobVal) return S.IS_MOBILE and mobVal or pcVal end
S.getActiveSpeed = function()
    if S.laggerMode then return S.LS
    elseif S.speedMode then return S.CS
    else return 60
    end
end

local saveConfig
local updateFloatingButtons

-- ========================= AUTO PLAY =========================
local autoPlayWaypoints = {
    left = {
        Vector3.new(-476.48, -6.28, 92.73),
        Vector3.new(-482.85, -5.03, 93.13),
        Vector3.new(-475.68, -6.89, 92.76),
        Vector3.new(-476.50, -6.46, 27.58),
        Vector3.new(-482.42, -5.03, 27.84),
    },
    right = {
        Vector3.new(-476.16, -6.52, 25.62),
        Vector3.new(-483.06, -5.03, 27.51),
        Vector3.new(-476.21, -6.63, 27.46),
        Vector3.new(-476.66, -6.39, 92.44),
        Vector3.new(-481.94, -5.03, 92.42),
    },
    faceLeft  = Vector3.new(-482.25, -4.96, 92.09),
    faceRight = Vector3.new(-482.06, -6.93, 35.47),
}

local function startAutoPlay(direction)
    if S.atrActiveConnection then
        S.atrActiveConnection:Disconnect()
        S.atrActiveConnection = nil
    end
    S.autoPlayPhase = 1
    S.autoPlayWaiting = false
    S.autoPlayDirection = direction

    local waypoints = autoPlayWaypoints[direction]
    local facePt = direction == "left" and autoPlayWaypoints.faceLeft or autoPlayWaypoints.faceRight

    S.atrActiveConnection = RunService.Heartbeat:Connect(function()
        if not (S.atrAutoLeft or S.atrAutoRight) then return end
        if S.autoPlayWaiting then return end

        local char = LP.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local hum = char:FindFirstChildOfClass("Humanoid")

        local ph = S.autoPlayPhase
        local target = waypoints[ph]
        if not target then return end

        local dist = (Vector3.new(target.X, root.Position.Y, target.Z) - root.Position).Magnitude

        local speed = (ph <= 2) and S.autoPlaySpeed1 or S.autoPlaySpeed2
        if hum then hum.WalkSpeed = speed end

        if dist < 1.5 then
            if ph == 5 then
                root.AssemblyLinearVelocity = Vector3.zero
                local dirFace = (facePt - root.Position).Unit
                local newCFrame = CFrame.new(root.Position, root.Position + dirFace)
                TweenService:Create(root, TweenInfo.new(0.15), {CFrame = newCFrame}):Play()
                S.autoPlayWaiting = true
                task.spawn(function()
                    task.wait(4)
                    stopAutoPlay()
                end)
                return
            elseif ph == 2 then
                root.AssemblyLinearVelocity = Vector3.zero
                task.wait(0.05)
                S.autoPlayPhase = 3
            else
                S.autoPlayPhase = ph + 1
            end
            return
        end

        local moveDir = (Vector3.new(target.X, root.Position.Y, target.Z) - root.Position).Unit
        root.AssemblyLinearVelocity = Vector3.new(moveDir.X * speed, root.AssemblyLinearVelocity.Y, moveDir.Z * speed)
    end)

    if S.setAutoPlayVisual then S.setAutoPlayVisual(true) end
end

local function stopAutoPlay()
    if S.atrActiveConnection then
        S.atrActiveConnection:Disconnect()
        S.atrActiveConnection = nil
    end
    S.autoPlayPhase = 1
    S.autoPlayWaiting = false
    if S.atrAutoLeft then S.atrAutoLeft = false end
    if S.atrAutoRight then S.atrAutoRight = false end
    local char = LP.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then root.AssemblyLinearVelocity = Vector3.zero end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
    if S.setAutoPlayVisual then S.setAutoPlayVisual(false) end
    saveConfig()
end

local function setAtrAutoLeft(state)
    if state == S.atrAutoLeft then return end
    if state then
        if S.atrAutoRight then setAtrAutoRight(false) end
        S.atrAutoLeft = true
        startAutoPlay("left")
    else
        S.atrAutoLeft = false
        stopAutoPlay()
    end
end

local function setAtrAutoRight(state)
    if state == S.atrAutoRight then return end
    if state then
        if S.atrAutoLeft then setAtrAutoLeft(false) end
        S.atrAutoRight = true
        startAutoPlay("right")
    else
        S.atrAutoRight = false
        stopAutoPlay()
    end
end

-- ========================= AUTO STEAL =========================
local autoStealConfig = {
    HOLD_MIN    = 1.1,
    HOLD_MAX    = 2.6,
    ENTRY_DELAY = 0.3,
    COOLDOWN    = 0.05,
    STEAL_RANGE = 10,
    PRIME_RANGE = 80,
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages    = ReplicatedStorage:WaitForChild("Packages")
local Datas       = ReplicatedStorage:WaitForChild("Datas")
local AnimalsData = require(Datas:WaitForChild("Animals"))
local plots       = workspace:WaitForChild("Plots")

local syncRemotes = (function()
    local folder = Packages:WaitForChild("Synchronizer")
    return {
        channelFolder = folder:WaitForChild("Channel"),
        routeRemote   = folder:WaitForChild("CommunicationRoute"),
        requestData   = folder:FindFirstChild("RequestData"),
    }
end)()

local plotAnimalSync = { caches = {}, connections = {} }

local function splitSyncPath(path)
    if typeof(path) == "table" then return path end
    local out = {}
    for part in string.gmatch(tostring(path), "[^%.]+") do
        table.insert(out, tonumber(part) or part)
    end
    return out
end

local function resolveSyncPath(path, root)
    local current, parent, key = root, nil, nil
    for _, part in ipairs(splitSyncPath(path)) do
        parent  = current
        key     = part
        current = current and current[part] or nil
    end
    return current, parent, key
end

local function applyPlotSyncDiff(channelName, packet)
    local cache = plotAnimalSync.caches[channelName]
    if typeof(cache) ~= "table" then return end
    local path, action, a, b = packet[1], packet[2], packet[3], packet[4]
    local current, parent, key = resolveSyncPath(path, cache)
    if action == "Changed"          then if parent  ~= nil then parent[key]   = a              end
    elseif action == "ArrayInsert"  then if current ~= nil then table.insert(current, b, a)    end
    elseif action == "ArrayRemoved" then if current ~= nil then table.remove(current, b)        end
    elseif action == "DictionaryInsert"  then if current ~= nil then current[b] = a end
    elseif action == "DictionaryRemoved" then if current ~= nil then current[b] = nil end
    end
end

local function attachPlotChannel(remote)
    if plotAnimalSync.connections[remote] then return end
    local channelName = tostring(remote.Name)
    if not plots:FindFirstChild(channelName) then return end
    if syncRemotes.requestData and plotAnimalSync.caches[channelName] == nil then
        local ok, data = pcall(function() return syncRemotes.requestData:InvokeServer(channelName) end)
        plotAnimalSync.caches[channelName] = (ok and typeof(data) == "table") and data or {}
    elseif plotAnimalSync.caches[channelName] == nil then
        plotAnimalSync.caches[channelName] = {}
    end
    plotAnimalSync.connections[remote] = remote.OnClientEvent:Connect(function(queue)
        for _, packet in ipairs(queue) do applyPlotSyncDiff(channelName, packet) end
    end)
end

local function detachPlotChannel(channelName)
    for remote, conn in pairs(plotAnimalSync.connections) do
        if tostring(remote.Name) == tostring(channelName) then
            conn:Disconnect()
            plotAnimalSync.connections[remote] = nil
            plotAnimalSync.caches[tostring(channelName)] = nil
            break
        end
    end
end

for _, child in ipairs(syncRemotes.channelFolder:GetChildren()) do
    if child:IsA("RemoteEvent") then attachPlotChannel(child) end
end
syncRemotes.channelFolder.ChildAdded:Connect(function(child)
    if child:IsA("RemoteEvent") then attachPlotChannel(child) end
end)
syncRemotes.routeRemote.OnClientEvent:Connect(function(actions)
    for _, action in ipairs(actions) do
        local kind, channelName = action[1], tostring(action[2])
        if plots:FindFirstChild(channelName) then
            if kind == "ListenerAdded" then
                local remote = syncRemotes.channelFolder:FindFirstChild(channelName)
                if remote and remote:IsA("RemoteEvent") then attachPlotChannel(remote) end
            elseif kind == "ListenerRemoved" then
                detachPlotChannel(channelName)
            end
        end
    end
end)

local function getPlotChannelData(plotName) return plotAnimalSync.caches[plotName] end

local allAnimalsCache    = {}
local PromptMemoryCache  = {}
local InternalStealCache = {}

local StealState = {
    active         = false,
    startTime      = 0,
    phase          = "idle",
    label          = "",
    dist           = 0,
    lastResult     = "",
    lastResultTime = 0,
    totalSteals    = 0,
    failedSteals   = 0,
}

local infoLabel, statusLabel, progressFill, percentLabel

local function buildAutoStealUI()
    local sg = LP.PlayerGui:FindFirstChild("SUREHUBAutoGrab")
    if sg then sg:Destroy() end
    sg = Instance.new("ScreenGui")
    sg.Name = "SUREHUBAutoGrab"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.Parent = LP.PlayerGui

    local container = Instance.new("Frame", sg)
    container.Size = UDim2.new(0, 280, 0, 90)
    container.Position = UDim2.new(0.5, -140, 0, 35)
    container.BackgroundTransparency = 1

    -- Banner con imagen de fondo (ID 114092553501147)
    local banner = Instance.new("Frame", container)
    banner.Size = UDim2.new(1, 0, 0, 30)
    banner.BackgroundTransparency = 1  -- Fondo transparente para ver la imagen
    banner.BorderSizePixel = 0
    Instance.new("UICorner", banner).CornerRadius = UDim.new(0, 8)
    local bs = Instance.new("UIStroke", banner)
    bs.Color = Color3.fromRGB(80,80,80)
    bs.Thickness = 1.5

    -- Imagen de fondo
    local bgImage = Instance.new("ImageLabel", banner)
    bgImage.Size = UDim2.new(1, 0, 1, 0)
    bgImage.BackgroundTransparency = 1
    bgImage.Image = "rbxassetid://114092553501147"
    bgImage.ImageTransparency = 0
    bgImage.ScaleType = Enum.ScaleType.Crop
    bgImage.ZIndex = 0

    -- Texto de información (Ping, FPS)
    infoLabel = Instance.new("TextLabel", banner)
    infoLabel.Size = UDim2.new(1, -10, 1, 0)
    infoLabel.Position = UDim2.new(0, 10, 0, 0)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Font = Enum.Font.GothamBold
    infoLabel.TextSize = 13
    infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)  -- Blanco para contraste
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.Text = "SUREHUB"
    infoLabel.ZIndex = 2

    local barBg = Instance.new("Frame", container)
    barBg.Size = UDim2.new(1, 0, 0, 16)
    barBg.Position = UDim2.new(0, 0, 0, 36)
    barBg.BackgroundColor3 = Color3.fromRGB(240,240,240)
    barBg.BackgroundTransparency = 0
    barBg.BorderSizePixel = 0
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 10)

    progressFill = Instance.new("Frame", barBg)
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    progressFill.BorderSizePixel = 0
    Instance.new("UICorner", progressFill).CornerRadius = UDim.new(0, 10)

    percentLabel = Instance.new("TextLabel", barBg)
    percentLabel.Size = UDim2.new(1, 0, 1, 0)
    percentLabel.BackgroundTransparency = 1
    percentLabel.Font = Enum.Font.GothamBold
    percentLabel.TextSize = 11
    percentLabel.TextColor3 = Color3.fromRGB(0,0,0)
    percentLabel.Text = ""
    statusLabel = percentLabel
end

local function startAutoStealTopBar()
    local fps, frames, last = 60, 0, tick()
    RunService.RenderStepped:Connect(function()
        frames = frames + 1
        if tick() - last >= 1 then
            fps = frames; frames = 0; last = tick()
        end
        local ping = 0
        local net = Stats:FindFirstChild("Network")
        if net and net:FindFirstChild("ServerStatsItem") then
            local dp = net.ServerStatsItem:FindFirstChild("Data Ping")
            if dp then ping = math.floor(dp:GetValue()) end
        end
        if infoLabel then
            infoLabel.Text = "SUREHUB | Ping: " .. ping .. "ms | FPS: " .. fps
        end
    end)
end

local function startAutoStealUIUpdater()
    RunService.Heartbeat:Connect(function()
        if not progressFill then return end
        local phase = StealState.phase
        if phase == "holding" then
            local elapsed = tick() - StealState.startTime
            local pct = math.clamp(elapsed / autoStealConfig.HOLD_MIN, 0, 1)
            progressFill.Size = UDim2.new(pct, 0, 1, 0)
            progressFill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        elseif phase == "waitingRange" then
            progressFill.Size = UDim2.new(1, 0, 1, 0)
            progressFill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        else
            progressFill.Size = UDim2.new(0, 0, 1, 0)
            progressFill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        end
    end)
end

local function getPlotOwner(plot)
    local sign  = plot:FindFirstChild("PlotSign")
    local frame = sign and sign:FindFirstChild("SurfaceGui") and sign.SurfaceGui:FindFirstChild("Frame")
    local label = frame and frame:FindFirstChild("TextLabel")
    if not label or label.Text == "Empty Base" then return nil end
    return label.Text:gsub("'s [Bb]ase$", ""):gsub("%s+$", "")
end

local function isMyBaseAnimal(animalData)
    if not animalData or not animalData.plot then return false end
    local plot = plots:FindFirstChild(animalData.plot)
    if not plot then return false end
    return getPlotOwner(plot) == LP.DisplayName
end

local function findProximityPromptForAnimal(animalData)
    if not animalData then return nil end
    local cached = PromptMemoryCache[animalData.uid]
    if cached and cached.Parent then return cached end
    local plot    = plots:FindFirstChild(animalData.plot);            if not plot    then return nil end
    local podiums = plot:FindFirstChild("AnimalPodiums");              if not podiums then return nil end
    local podium  = podiums:FindFirstChild(animalData.slot);           if not podium  then return nil end
    local base    = podium:FindFirstChild("Base");                     if not base    then return nil end
    local spawn   = base:FindFirstChild("Spawn");                      if not spawn   then return nil end
    local attach  = spawn:FindFirstChild("PromptAttachment");          if not attach  then return nil end
    for _, p in ipairs(attach:GetChildren()) do
        if p:IsA("ProximityPrompt") then
            PromptMemoryCache[animalData.uid] = p
            return p
        end
    end
    return nil
end

local function getAnimalPosition(animalData)
    local plot    = plots:FindFirstChild(animalData.plot);  if not plot    then return nil end
    local podiums = plot:FindFirstChild("AnimalPodiums");    if not podiums then return nil end
    local podium  = podiums:FindFirstChild(animalData.slot); if not podium  then return nil end
    return podium:GetPivot().Position
end

local function getHRP()
    local c = LP.Character
    if c then return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso") end
    return nil
end

local function distToAnimal(animalData)
    local hrp = getHRP(); if not hrp then return math.huge end
    local pos = getAnimalPosition(animalData); if not pos then return math.huge end
    return (hrp.Position - pos).Magnitude
end

local function pickClosest()
    local hrp = getHRP(); if not hrp then return nil end
    local best, bestDist = nil, math.huge
    for _, animalData in ipairs(allAnimalsCache) do
        if isMyBaseAnimal(animalData) then continue end
        local pos = getAnimalPosition(animalData); if not pos then continue end
        local dist = (hrp.Position - pos).Magnitude
        if dist > autoStealConfig.PRIME_RANGE then continue end
        if dist < bestDist then bestDist = dist; best = animalData end
    end
    return best
end

local function buildStealCallbacks(prompt)
    if InternalStealCache[prompt] then return end
    local data = { holdCallbacks = {}, triggerCallbacks = {}, ready = true }
    local ok1, conns1 = pcall(getconnections, prompt.PromptButtonHoldBegan)
    if ok1 and type(conns1) == "table" then
        for _, conn in ipairs(conns1) do
            if type(conn.Function) == "function" then
                table.insert(data.holdCallbacks, conn.Function)
            end
        end
    end
    local ok2, conns2 = pcall(getconnections, prompt.Triggered)
    if ok2 and type(conns2) == "table" then
        for _, conn in ipairs(conns2) do
            if type(conn.Function) == "function" then
                table.insert(data.triggerCallbacks, conn.Function)
            end
        end
    end
    if (#data.holdCallbacks > 0) or (#data.triggerCallbacks > 0) then
        InternalStealCache[prompt] = data
    end
end

local function executeStealAsync(prompt, animalData)
    local data = InternalStealCache[prompt]
    if not data or not data.ready then return false end
    data.ready = false

    local label = animalData.name or "Animal"
    StealState.active    = true
    StealState.startTime = tick()
    StealState.phase     = "holding"
    StealState.label     = label
    StealState.dist      = distToAnimal(animalData)

    task.spawn(function()
        for _, fn in ipairs(data.holdCallbacks) do task.spawn(fn) end

        local holdEnd = tick() + autoStealConfig.HOLD_MIN
        while tick() < holdEnd do
            StealState.dist = distToAnimal(animalData)
            task.wait()
        end

        StealState.phase = "waitingRange"
        local alreadyInRange = distToAnimal(animalData) <= autoStealConfig.STEAL_RANGE
        local fired = false
        while true do
            local elapsed = tick() - StealState.startTime
            if elapsed > autoStealConfig.HOLD_MAX then break end
            if not prompt.Parent then break end
            StealState.dist = distToAnimal(animalData)
            if StealState.dist <= autoStealConfig.STEAL_RANGE then
                if not alreadyInRange then task.wait(autoStealConfig.ENTRY_DELAY) end
                for _, fn in ipairs(data.triggerCallbacks) do task.spawn(fn) end
                fired = true
                break
            end
            task.wait()
        end

        if fired then
            StealState.totalSteals = StealState.totalSteals + 1
            StealState.lastResult  = "Stole " .. label
        else
            StealState.failedSteals = StealState.failedSteals + 1
            StealState.lastResult   = "Missed: " .. label
        end

        StealState.active         = false
        StealState.phase          = "idle"
        StealState.lastResultTime = tick()

        task.wait(autoStealConfig.COOLDOWN)
        data.ready = true
    end)
    return true
end

local function attemptSteal(prompt, animalData)
    if not prompt or not prompt.Parent then return false end
    buildStealCallbacks(prompt)
    if not InternalStealCache[prompt] then return false end
    return executeStealAsync(prompt, animalData)
end

local function scanAllPlots()
    local newCache = {}
    for _, plot in ipairs(plots:GetChildren()) do
        local cache = getPlotChannelData(plot.Name)
        if not cache then continue end
        local animalList = cache.AnimalList
        if typeof(animalList) ~= "table" then continue end
        for slot, animalData in pairs(animalList) do
            if type(animalData) == "table" then
                local animalName = animalData.Index
                local animalInfo = AnimalsData[animalName]
                if not animalInfo then continue end
                table.insert(newCache, {
                    name = animalInfo.DisplayName or animalName,
                    plot = plot.Name,
                    slot = tostring(slot),
                    uid  = plot.Name .. "_" .. tostring(slot),
                })
            end
        end
    end
    allAnimalsCache = newCache
    return #allAnimalsCache
end

local function startAutoStealLoop()
    if S.autoStealConnection then return end
    S.autoStealConnection = RunService.Heartbeat:Connect(function()
        if not S.autoStealEnabled then return end
        if StealState.active then return end
        local target = pickClosest()
        if not target then return end
        local prompt = PromptMemoryCache[target.uid]
        if not prompt or not prompt.Parent then
            prompt = findProximityPromptForAnimal(target)
        end
        if prompt then attemptSteal(prompt, target) end
    end)
end

local function stopAutoStealLoop()
    if S.autoStealConnection then
        S.autoStealConnection:Disconnect()
        S.autoStealConnection = nil
    end
end

local function toggleAutoSteal(state)
    if S.autoStealEnabled == state then return end
    S.autoStealEnabled = state
    if state then
        startAutoStealLoop()
    else
        stopAutoStealLoop()
    end
    if S.setAutoStealVisual then S.setAutoStealVisual(state) end
    saveConfig()
end

task.spawn(function()
    buildAutoStealUI()
    startAutoStealTopBar()
    startAutoStealUIUpdater()
    while task.wait(5) do
        if S.autoStealEnabled then scanAllPlots() end
    end
end)
scanAllPlots()

-- ========================= TAUNT BUTTON =========================
local function createTauntButton()
    if S.tauntGui then return end

    local lib = Instance.new("ScreenGui")
    lib.Name = "SUREHUB_TauntButton"
    lib.ResetOnSpawn = false
    lib.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    lib.Parent = CoreGui
    S.tauntGui = lib

    local BLACK_OFF = Color3.fromRGB(220, 220, 220)
    local WHITE_ON  = Color3.fromRGB(0, 0, 0)
    local STROKE_OFF = Color3.fromRGB(180, 180, 180)
    local STROKE_ON  = Color3.fromRGB(0, 0, 0)

    local button = Instance.new("TextButton", lib)
    button.Size = UDim2.new(0, 100, 0, 55)
    button.Position = UDim2.new(0.05, 0, 0.3, 0)
    button.Text = ""
    button.BackgroundColor3 = BLACK_OFF
    button.BorderSizePixel = 0
    button.ZIndex = 22

    local corner = Instance.new("UICorner", button)
    corner.CornerRadius = UDim.new(1, 0)

    local stroke = Instance.new("UIStroke", button)
    stroke.Color = STROKE_OFF
    stroke.Thickness = 1
    stroke.Transparency = 0.2

    local label = Instance.new("TextLabel", button)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "TAUNT"
    label.TextColor3 = WHITE_ON
    label.Font = Enum.Font.GothamBlack
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.ZIndex = 23

    local dot = Instance.new("Frame", button)
    dot.Name = "StatusDot"
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.Position = UDim2.new(0, 10, 0.5, -4)
    dot.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
    local dotCorner = Instance.new("UICorner", dot)
    dotCorner.CornerRadius = UDim.new(1, 0)

    local function updateButtonState(isActive)
        if isActive then
            button.BackgroundColor3 = WHITE_ON
            stroke.Color = STROKE_ON
            stroke.Transparency = 0
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
            dot.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
        else
            button.BackgroundColor3 = BLACK_OFF
            stroke.Color = STROKE_OFF
            stroke.Transparency = 0.2
            label.TextColor3 = WHITE_ON
            dot.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
        end
    end

    makeDraggable(button, false)

    local function startSpam()
        if S.tauntLoop then return end
        S.tauntLoop = task.spawn(function()
            while S.tauntActive do
                pcall(function()
                    local TextChatService = game:GetService("TextChatService")
                    local generalChannel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
                    if generalChannel then
                        generalChannel:SendAsync("/SUREHUB on top")
                    else
                        local ReplicatedStorage = game:GetService("ReplicatedStorage")
                        local SayMessageRequest = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
                        if SayMessageRequest then
                            SayMessageRequest = SayMessageRequest:FindFirstChild("SayMessageRequest")
                            if SayMessageRequest then
                                SayMessageRequest:FireServer("/SUREHUB on top", "All")
                            end
                        end
                    end
                end)
                task.wait(0.5)
            end
        end)
    end

    local function stopSpam()
        if S.tauntLoop then
            task.cancel(S.tauntLoop)
            S.tauntLoop = nil
        end
    end

    button.MouseButton1Click:Connect(function()
        S.tauntActive = not S.tauntActive
        updateButtonState(S.tauntActive)
        if S.tauntActive then
            startSpam()
        else
            stopSpam()
        end
    end)

    updateButtonState(false)
end

local function destroyTauntButton()
    if S.tauntGui then
        S.tauntGui:Destroy()
        S.tauntGui = nil
    end
    if S.tauntLoop then
        task.cancel(S.tauntLoop)
        S.tauntLoop = nil
    end
    S.tauntActive = false
end

local function setTauntEnabled(state)
    if S.tauntEnabled == state then return end
    S.tauntEnabled = state
    if state then
        createTauntButton()
    else
        destroyTauntButton()
    end
    saveConfig()
end

-- ========================= ANTI-RAGDOLL =========================
local function startAntiRagdoll()
    if S.antiRagdollConn then return end
    S.antiRagdollConn = RunService.Heartbeat:Connect(function()
        if not S.antiRagdollEnabled then return end
        local char = LP.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not (hum and root) then return end
        
        local s = hum:GetState()
        local ragdolled = (s == Enum.HumanoidStateType.Physics or s == Enum.HumanoidStateType.Ragdoll or s == Enum.HumanoidStateType.FallingDown)
        local endTime = LP:GetAttribute("RagdollEndTime")
        if endTime and (endTime - workspace:GetServerTimeNow()) > 0 then ragdolled = true end
        
        if ragdolled then
            pcall(function() LP:SetAttribute("RagdollEndTime", workspace:GetServerTimeNow()) end)
            for _, d in ipairs(char:GetDescendants()) do
                if d:IsA("BallSocketConstraint") or (d:IsA("Attachment") and d.Name:find("RagdollAttachment")) then
                    d:Destroy()
                end
            end
            for _, obj in ipairs(char:GetDescendants()) do
                if obj:IsA("Motor6D") and obj.Enabled == false then
                    obj.Enabled = true
                end
            end
            if hum.Health > 0 then
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end
            workspace.CurrentCamera.CameraSubject = hum
            root.Anchored = false
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end

local function stopAntiRagdoll()
    if S.antiRagdollConn then
        S.antiRagdollConn:Disconnect()
        S.antiRagdollConn = nil
    end
end

-- ========================= BYPASS AIMBOT V2 =========================
local function startBypassAimbotV2()
    if S.bypassAimbotV2Conn then return end
    S.bypassAimbotV2Conn = RunService.Heartbeat:Connect(function()
        if not S.bypassAimbotV2Toggled then return end
        local char = LP.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not root or not hum then return end

        local function findAnyToolV2()
            local c = LP.Character
            if c then
                for _, v in ipairs(c:GetChildren()) do if v:IsA("Tool") then return v end end
            end
            local bp = LP:FindFirstChildOfClass("Backpack")
            if bp then
                for _, v in ipairs(bp:GetChildren()) do if v:IsA("Tool") then return v end end
            end
            return nil
        end

        local function getClosestPlayerV2()
            local char = LP.Character
            if not char then return nil, math.huge end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return nil, math.huge end
            local closest, bestDist = nil, math.huge
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP and p.Character then
                    local tr = p.Character:FindFirstChild("HumanoidRootPart")
                    local ph = p.Character:FindFirstChildOfClass("Humanoid")
                    if tr and ph and ph.Health > 0 then
                        local d = (root.Position - tr.Position).Magnitude
                        if d < bestDist then bestDist = d; closest = p end
                    end
                end
            end
            return closest, bestDist
        end

        local function tryHitBypassV2()
            if S.bypassAimbotV2HittingCooldown then return end
            S.bypassAimbotV2HittingCooldown = true
            local char = LP.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            local tool = findAnyToolV2()
            if tool then
                if tool.Parent ~= char and hum then pcall(function() hum:EquipTool(tool) end) end
                local remote = tool:FindFirstChildOfClass("RemoteEvent")
                if remote then pcall(function() remote:FireServer() end) else pcall(function() tool:Activate() end) end
            end
            task.delay(0.08, function() S.bypassAimbotV2HittingCooldown = false end)
        end

        local target, dist = getClosestPlayerV2()
        if target and target.Character then
            local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local targetVel = targetRoot.Velocity
                local moveDir = targetVel.Magnitude > 0.1 and targetVel.Unit or targetRoot.CFrame.LookVector
                local offset = moveDir * 1.0 + Vector3.new(0, 1.5 + 0.0, 0)
                local desiredPos = targetRoot.Position + offset
                local toTarget = desiredPos - root.Position
                if toTarget.Magnitude > 0.5 then
                    local moveVec = toTarget.Unit * 60
                    root.Velocity = Vector3.new(moveVec.X, moveVec.Y, moveVec.Z)
                else
                    root.Velocity = root.Velocity * 0.95
                    if root.Velocity.Magnitude < 1 then root.Velocity = Vector3.zero end
                end
                local distToTarget = (root.Position - targetRoot.Position).Magnitude
                if distToTarget <= 4.5 then tryHitBypassV2() end
            end
        else
            root.Velocity = root.Velocity * 0.9
            if root.Velocity.Magnitude < 1 then root.Velocity = Vector3.zero end
        end
    end)
end

local function stopBypassAimbotV2()
    if S.bypassAimbotV2Conn then
        S.bypassAimbotV2Conn:Disconnect()
        S.bypassAimbotV2Conn = nil
    end
    local c = LP.Character
    local root = c and c:FindFirstChild("HumanoidRootPart")
    if root then root.Velocity = Vector3.zero end
    S.bypassAimbotV2HittingCooldown = false
end

-- ========================= FUNCIONES EXISTENTES =========================
local function updateLaggerButtonVisual()
    local fb = S._floatingButtons
    if not fb.lagger then return end
    local active = false
    if S.speedMode then
        active = false
    else
        active = S.laggerMode
    end
    fb.l2Lagger.Text = "CARRY"
    S._setPButtonActive(fb.lagger, fb.strokeLagger, fb.l1Lagger, fb.l2Lagger, active)
end

S.setupSpeedBillboard = function(char)
    local head = char:WaitForChild("Head", 5)
    if not head then return end
    local oldBB = head:FindFirstChild("SUREHUBSpeedBB")
    if oldBB then oldBB:Destroy() end
    local bb = Instance.new("BillboardGui", head)
    bb.Name = "SUREHUBSpeedBB"
    bb.Size = UDim2.new(0, 100, 0, 32)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    local speedLbl = Instance.new("TextLabel", bb)
    speedLbl.Name = "SpeedBillLbl"
    speedLbl.Size = UDim2.new(1,0,1,0)
    speedLbl.BackgroundTransparency = 1
    speedLbl.Text = "Speed: 0"
    speedLbl.TextColor3 = Color3.fromRGB(0,0,0)
    speedLbl.Font = Enum.Font.GothamBlack
    speedLbl.TextScaled = true
    speedLbl.TextStrokeTransparency = 0.2
    speedLbl.TextStrokeColor3 = Color3.new(1,1,1)
    S.speedCounterLabel = speedLbl
end

local function getCurrentSpeed()
    return S.getActiveSpeed()
end

local _lastSpeedDisplay = -1
RunService.Heartbeat:Connect(function()
    if not (S.h and S.hrp) or not S.speedCounterLabel then return end
    local currentSpeed = getCurrentSpeed()
    if currentSpeed ~= _lastSpeedDisplay then
        _lastSpeedDisplay = currentSpeed
        S.speedCounterLabel.Text = "Speed: " .. tostring(currentSpeed)
    end
end)

local DROP_ASCEND_DURATION = 0.2
local DROP_ASCEND_SPEED = 150
local dropConnection = nil

runDropBrainrot = function()
    if S.dropBrainrotActive then return end
    local char = LP.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if dropConnection then dropConnection:Disconnect() end
    S.dropBrainrotActive = true
    if S.setDrop2Visual then S.setDrop2Visual(true) end
    local t0 = tick()
    local conn = nil
    conn = RunService.Heartbeat:Connect(function()
        local r = char and char:FindFirstChild("HumanoidRootPart")
        if not r then
            conn:Disconnect()
            dropConnection = nil
            if S.dropBrainrotActive then
                S.dropBrainrotActive = false
                if S.setDrop2Visual then S.setDrop2Visual(false) end
            end
            return
        end
        if tick() - t0 >= DROP_ASCEND_DURATION then
            conn:Disconnect()
            dropConnection = nil
            local rp = RaycastParams.new()
            rp.FilterDescendantsInstances = { char }
            rp.FilterType = Enum.RaycastFilterType.Exclude
            local rr = workspace:Raycast(r.Position, Vector3.new(0, -2000, 0), rp)
            if rr then
                local hum2 = char:FindFirstChildOfClass("Humanoid")
                local off = (hum2 and hum2.HipHeight or 2) + (r.Size.Y / 2)
                r.CFrame = CFrame.new(r.Position.X, rr.Position.Y + off, r.Position.Z)
                r.AssemblyLinearVelocity = Vector3.zero
            end
            S.dropBrainrotActive = false
            if S.setDrop2Visual then S.setDrop2Visual(false) end
            return
        end
        r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, DROP_ASCEND_SPEED, r.AssemblyLinearVelocity.Z)
    end)
    dropConnection = conn
end

stopDropBrainrot = function()
    if dropConnection then
        dropConnection:Disconnect()
        dropConnection = nil
    end
    if S.dropBrainrotActive then
        S.dropBrainrotActive = false
        if S.setDrop2Visual then S.setDrop2Visual(false) end
    end
    local c = LP.Character
    if c then
        local root = c:FindFirstChild("HumanoidRootPart")
        if root and root.AssemblyLinearVelocity.Y > 0 then
            root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
        end
    end
end

S.startMovement = function()
    if S.moveConn then S.moveConn:Disconnect() end
    S.moveConn = RunService.RenderStepped:Connect(function()
        if not S.speedEnabled then return end
        if not (S.h and S.hrp) then return end
        if S.batAimbotEnabled or S.simpleAimbotEnabled then return end
        local md = S.h.MoveDirection
        local spd
        if S.laggerMode then
            spd = S.LS
        elseif S.speedMode then
            spd = S.CS
        else
            spd = 60
        end
        if md.Magnitude > 0 then
            S.lastMoveDir = md
            S.hrp.Velocity = Vector3.new(md.X * spd, S.hrp.Velocity.Y, md.Z * spd)
        end
    end)
end
S.stopMovement = function()
    if S.moveConn then S.moveConn:Disconnect(); S.moveConn = nil end
end
S.restartMovement = function() S.stopMovement(); S.startMovement() end
S.speedEnabled = true
S.startMovement()

local startInfiniteJump
local stopInfiniteJump

local function startAutoTPDown()
    if S.autoTPDownConn then S.autoTPDownConn:Disconnect() end
    local _tpDownTimer = 0
    local _tpRayParams = nil
    S.autoTPDownConn = RunService.Heartbeat:Connect(function(dt)
        if not S.autoTPDownEnabled then return end
        if S.batAimbotEnabled or S.simpleAimbotEnabled then return end
        if tick() < S.autoTPDownCooldownUntil then return end
        _tpDownTimer = _tpDownTimer + dt
        if _tpDownTimer < 0.05 then return end
        _tpDownTimer = 0
        local char = LP.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if hrp.Position.Y >= S.autoTPDownThreshold then
            if not _tpRayParams then
                _tpRayParams = RaycastParams.new()
                _tpRayParams.FilterType = Enum.RaycastFilterType.Exclude
            end
            _tpRayParams.FilterDescendantsInstances = {char}
            local ray = workspace:Raycast(hrp.Position, Vector3.new(0, -1000, 0), _tpRayParams)
            if ray then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local offset = (hum and hum.HipHeight or 2) + hrp.Size.Y / 2
                hrp.CFrame = CFrame.new(hrp.Position.X, ray.Position.Y + offset, hrp.Position.Z)
                hrp.AssemblyLinearVelocity = Vector3.zero
            end
        end
    end)
end

local function stopAutoTPDown()
    if S.autoTPDownConn then S.autoTPDownConn:Disconnect(); S.autoTPDownConn = nil end
end

local function udim2ToTable(udim2)
    return {
        X = {Scale = udim2.X.Scale, Offset = udim2.X.Offset},
        Y = {Scale = udim2.Y.Scale, Offset = udim2.Y.Offset}
    }
end

local function tableToUdim2(t)
    return UDim2.new(t.X.Scale, t.X.Offset, t.Y.Scale, t.Y.Offset)
end

saveConfig = function()
    pcall(function()
        local function ks(e)
            return {kb = e.kb and e.kb.Name or nil, gp = e.gp and e.gp.Name or nil}
        end
        local cfg = {
            carrySpeed = S.CS, laggerSpeed = S.LS,
            laggerMode = S.speedMode and 0 or (S.laggerMode and 1 or 0),
            dropBrainrotKey = ks(S.KB.DropBrainrot), autoBatKey = ks(S.KB.AutoBat),
            tpFloorKey = ks(S.KB.TPFlor), guiHideKey = ks(S.KB.GuiHide),
            speedToggleKey = ks(S.KB.SpeedToggle), laggerToggleKey = ks(S.KB.LaggerToggle),
            infiniteJump = S.infJumpEnabled,
            medusaCounter = S.medusaCounterEnabled, carryMode = S.speedMode,
            batAimbot = S.batAimbotEnabled,
            unwalkEnabled = S.unwalkEnabled,
            lockUI = S.lockUIEnabled, fpsBoost = S.fpsBoostEnabled,
            hideOpiumButtons = S.hideOpiumButtonsEnabled or false,
            autoTPDownEnabled = S.autoTPDownEnabled, autoTPDownThreshold = S.autoTPDownThreshold,
            autoTPDownKey = ks(S.KB.AutoTPDown),
            batCounter = S.batCounterEnabled,
            galaxyMode = galaxyOn,
            espEnabled = S.espEnabled,
            atrAutoLeft = S.atrAutoLeft,
            atrAutoRight = S.atrAutoRight,
            atrAutoDirection = S.autoPlayDirection,
            autoStealEnabled = S.autoStealEnabled,
            tauntEnabled = S.tauntEnabled,
            antiRagdoll = S.antiRagdollEnabled,
            bypassAimbotSpeed = S.bypassAimbotSpeed,
            drop2Enabled = S.dropBrainrotActive,
            bypassAimbotV2Toggled = S.bypassAimbotV2Toggled,
            autoPlaySpeed1 = S.autoPlaySpeed1,
            autoPlaySpeed2 = S.autoPlaySpeed2,
            floatingPositions = {
                TP = S._btnTP and udim2ToTable(S._btnTP.Position) or nil,
                LAG = S._btnLAG and udim2ToTable(S._btnLAG.Position) or nil,
                CS = S._btnCS and udim2ToTable(S._btnCS.Position) or nil,
                D2 = S._btnDrop2 and udim2ToTable(S._btnDrop2.Position) or nil,
                ATD = S._btnATD and udim2ToTable(S._btnATD.Position) or nil,
                BypassAimbotV2 = S._btnBypassAimbotV2 and udim2ToTable(S._btnBypassAimbotV2.Position) or nil,
                AutoplayGroup = S._groupAutoplay and udim2ToTable(S._groupAutoplay.Position) or nil,
            }
        }
        local ok, data = pcall(function() return HS:JSONEncode(cfg) end)
        if ok and data then safeWritefile(S.CONFIG_FILE, data) end
    end)
end

local function resetFloatingPanel() end

startInfiniteJump = function()
    if S.IJ_JumpConn then S.IJ_JumpConn:Disconnect() end
    if S.IJ_HeartbeatConn then S.IJ_HeartbeatConn:Disconnect() end
    S.IJ_JumpConn = UIS.JumpRequest:Connect(function()
        if not S.infJumpEnabled then return end
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.Velocity = Vector3.new(hrp.Velocity.X, 50, hrp.Velocity.Z) end
    end)
    S.IJ_HeartbeatConn = RunService.Heartbeat:Connect(function()
        if not S.infJumpEnabled then return end
        local char = LP.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if hrp.Velocity.Y < -80 then
            hrp.Velocity = Vector3.new(hrp.Velocity.X, -80, hrp.Velocity.Z)
        end
    end)
end

stopInfiniteJump = function()
    if S.IJ_JumpConn then S.IJ_JumpConn:Disconnect(); S.IJ_JumpConn = nil end
    if S.IJ_HeartbeatConn then S.IJ_HeartbeatConn:Disconnect(); S.IJ_HeartbeatConn = nil end
end

local savedAnimate = nil

local function startUnwalk()
    local c = LP.Character
    if not c then return end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hum then
        for _, t in ipairs(hum:GetPlayingAnimationTracks()) do
            t:Stop()
        end
    end
    local anim = c:FindFirstChild("Animate")
    if anim then
        if not savedAnimate then
            savedAnimate = anim:Clone()
        end
        anim:Destroy()
    end
    S.unwalkEnabled = true
end

local function stopUnwalk()
    if not S.unwalkEnabled then return end
    S.unwalkEnabled = false
    local c = LP.Character
    if c and savedAnimate then
        local existing = c:FindFirstChild("Animate")
        if existing and existing ~= savedAnimate then existing:Destroy() end
        savedAnimate.Parent = c
        savedAnimate.Disabled = false
        savedAnimate = nil
    end
end

local POS = S.AP

local function getClosestPlayer()
    if not S.hrp then return nil, math.huge end
    local cp, cd = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local tr = p.Character:FindFirstChild("HumanoidRootPart")
            local ph = p.Character:FindFirstChildOfClass("Humanoid")
            if tr and ph and ph.Health > 0 then
                local d = (S.hrp.Position - tr.Position).Magnitude
                if d < cd then cd = d; cp = p end
            end
        end
    end
    return cp, cd
end

local function tryHitBat()
    if S.hittingCooldown then return end
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    S.hittingCooldown = true
    pcall(function()
        local c = LP.Character; if not c then return end
        local tool = nil
        for _, v in ipairs(c:GetChildren()) do
            if v:IsA("Tool") then tool = v; break end
        end
        if not tool then return end
        local remote = tool:FindFirstChildOfClass("RemoteEvent")
        if remote then
            pcall(function() remote:FireServer() end)
        else
            pcall(function() tool:Activate() end)
        end
    end)
    task.delay(SWING_COOLDOWN, function() S.hittingCooldown = false end)
end

local function findBatTool()
    local c = LP.Character; if not c then return nil end
    local bp = LP:FindFirstChildOfClass("Backpack")
    local SlapList = {"Bat","Slap","Iron Slap","Gold Slap","Diamond Slap","Emerald Slap","Ruby Slap","Dark Matter Slap","Flame Slap","Nuclear Slap","Galaxy Slap","Glitched Slap"}
    for _, ch in ipairs(c:GetChildren()) do
        if ch:IsA("Tool") and (ch.Name:lower():find("bat") or ch.Name:lower():find("slap")) then
            return ch
        end
    end
    if bp then
        for _, ch in ipairs(bp:GetChildren()) do
            if ch:IsA("Tool") and (ch.Name:lower():find("bat") or ch.Name:lower():find("slap")) then
                return ch
            end
        end
    end
    for _, name in ipairs(SlapList) do
        local t = (c and c:FindFirstChild(name)) or (bp and bp:FindFirstChild(name))
        if t then return t end
    end
    return nil
end

function startBatAimbot()
    if S.batAimbotConn then S.batAimbotConn:Disconnect() end
    S.batAimbotEnabled = true
    if S.simpleAimbotEnabled then toggleSimpleAimbot(false) end

    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local bat = findBatTool()
    if bat and hum and bat.Parent ~= char then
        pcall(function() hum:EquipTool(bat) end)
    end

    if hum then
        hum.AutoRotate = true
    end

    local lastTargetPos = nil
    local lastTargetTime = nil
    local lastTargetVel = Vector3.new(0,0,0)
    local lastDirChange = 0
    local prevErrorY = 0

    S.batAimbotConn = RunService.Heartbeat:Connect(function()
        if not S.batAimbotEnabled then return end
        local c = LP.Character
        if not c then return end
        local root = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not root or not hum then return end
        if hum.Health <= 0 then return end

        local bat = findBatTool()
        local hasOtherTool = false
        for _, v in ipairs(c:GetChildren()) do
            if v:IsA("Tool") and v ~= bat then
                hasOtherTool = true
                break
            end
        end
        if bat and bat.Parent ~= c and not hasOtherTool then
            pcall(function() hum:EquipTool(bat) end)
        end

        local target, dist = getClosestPlayer()
        if target and target.Character then
            local tr = target.Character:FindFirstChild("HumanoidRootPart")
            local head = target.Character:FindFirstChild("Head")
            if tr then
                local targetPos = head and (head.Position - Vector3.new(0, 1.2, 0)) or (tr.Position + Vector3.new(0, 0.8, 0))
                if head then
                    local maxHeight = head.Position.Y - 0.5
                    if targetPos.Y > maxHeight then targetPos = Vector3.new(targetPos.X, maxHeight, targetPos.Z) end
                end
                local now = tick()
                local dt = now - (lastTargetTime or now)
                
                if lastTargetPos and dt > 0 and dt < 0.1 then
                    local newVel = (targetPos - lastTargetPos) / dt
                    newVel = Vector3.new(
                        math.clamp(newVel.X, -80, 80),
                        math.clamp(newVel.Y, -100, 100),
                        math.clamp(newVel.Z, -80, 80)
                    )
                    local dot = lastTargetVel:Dot(newVel)
                    if dot < -0.5 then
                        lastDirChange = now
                    end
                    lastTargetVel = newVel
                end
                lastTargetPos = targetPos
                lastTargetTime = now

                local leadTime = 0.18
                if now - lastDirChange < 0.25 then
                    leadTime = 0.10
                end
                local predictedPos = targetPos + lastTargetVel * leadTime
                
                local horDist = Vector3.new(predictedPos.X - root.Position.X, 0, predictedPos.Z - root.Position.Z).Magnitude
                local spdHor
                if horDist > 10 then
                    spdHor = 60
                elseif horDist > 4 then
                    spdHor = 60
                else
                    spdHor = 55
                end
                
                local yError = predictedPos.Y - root.Position.Y
                local dtPID = math.max(dt, 0.02)
                local kp = 2.2
                local kd = 0.2
                local derivative = (yError - prevErrorY) / dtPID
                local verticalSpeed = kp * yError + kd * derivative
                prevErrorY = yError
                verticalSpeed = math.clamp(verticalSpeed, -60, 35)
                if math.abs(yError) < 0.5 then
                    verticalSpeed = verticalSpeed * 0.15
                end
                
                local dirToTarget = predictedPos - root.Position
                local horDir = Vector3.new(dirToTarget.X, 0, dirToTarget.Z)
                if horDir.Magnitude > 0.01 then
                    horDir = horDir.Unit
                else
                    horDir = Vector3.new(0,0,0)
                end
                
                root.Velocity = Vector3.new(horDir.X * spdHor, verticalSpeed, horDir.Z * spdHor)
                
                local currentTool = nil
                for _, v in ipairs(c:GetChildren()) do
                    if v:IsA("Tool") then currentTool = v; break end
                end
                if dist <= S.BAT_HIT_RANGE and currentTool and (currentTool.Name:lower():find("bat") or currentTool.Name:lower():find("slap")) then
                    tryHitBat()
                end
            end
        else
            root.Velocity = Vector3.new(0, root.Velocity.Y, 0)
            lastTargetPos = nil
            lastTargetTime = nil
            lastTargetVel = Vector3.new(0,0,0)
            lastDirChange = 0
            prevErrorY = 0
        end
    end)
end

function stopBatAimbot()
    if S.batAimbotConn then S.batAimbotConn:Disconnect(); S.batAimbotConn = nil end
    S.batAimbotEnabled = false
    local c = LP.Character
    local root = c and c:FindFirstChild("HumanoidRootPart")
    local hum = c and c:FindFirstChildOfClass("Humanoid")
    if root then
        pcall(function() root.Velocity = Vector3.new(0, root.Velocity.Y, 0) end)
    end
    if hum then
        hum:Move(Vector3.zero, false)
        hum.AutoRotate = true
    end
    S.hittingCooldown = false
end

local function setBatAimbot(state)
    if S.batAimbotEnabled == state then return end
    S.batAimbotEnabled = state
    if state then
        startBatAimbot()
    else
        stopBatAimbot()
    end
    updateFloatingButtons()
    S.restartMovement()
    saveConfig()
end

-- ========================= AIMBOT SIMPLE =========================
local SIMPLE_BAT_SPEED = 56.5
local SIMPLE_HIT_RANGE = 5
local SIMPLE_HIT_COOLDOWN = 0.08

local function startSimpleAimbot()
    if S.simpleAimbotConn then return end
    S.simpleAimbotEnabled = true
    if S.batAimbotEnabled then setBatAimbot(false) end

    S.simpleAimbotConn = RunService.Heartbeat:Connect(function()
        if not S.simpleAimbotEnabled then return end
        local char = LP.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then return end

        local target, dist = getClosestPlayer()
        if target and target.Character then
            local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local targetPos = targetRoot.Position + targetRoot.CFrame.LookVector * 1.5
                local direction = (targetPos - hrp.Position).Unit
                hrp.Velocity = direction * SIMPLE_BAT_SPEED
                if dist <= SIMPLE_HIT_RANGE then
                    if not S.simpleAimbotCooldown then
                        S.simpleAimbotCooldown = true
                        pcall(function()
                            local bat = findBatTool()
                            if bat then
                                bat:Activate()
                                local ev = bat:FindFirstChildWhichIsA("RemoteEvent")
                                if ev then ev:FireServer() end
                            end
                        end)
                        task.delay(SIMPLE_HIT_COOLDOWN, function() S.simpleAimbotCooldown = false end)
                    end
                end
            end
        else
            hrp.Velocity = Vector3.new(0, hrp.Velocity.Y, 0)
        end
    end)
end

local function stopSimpleAimbot()
    if S.simpleAimbotConn then
        S.simpleAimbotConn:Disconnect()
        S.simpleAimbotConn = nil
    end
    S.simpleAimbotEnabled = false
    S.simpleAimbotCooldown = false
    local char = LP.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.Velocity = Vector3.new(0, hrp.Velocity.Y, 0) end
    end
end

local function toggleSimpleAimbot(state)
    if S.simpleAimbotEnabled == state then return end
    if state then
        startSimpleAimbot()
    else
        stopSimpleAimbot()
    end
    S.restartMovement()
    saveConfig()
end

-- ========================= BAT COUNTER =========================
local BAT_COUNTER_SLAP_LIST = {"Bat","Slap","Iron Slap","Gold Slap","Diamond Slap","Emerald Slap","Ruby Slap","Dark Matter Slap","Flame Slap","Nuclear Slap","Galaxy Slap","Glitched Slap"}

local function findBatForCounter()
    local c = LP.Character; if not c then return nil end
    local bp = LP:FindFirstChildOfClass("Backpack")
    for _, name in ipairs(BAT_COUNTER_SLAP_LIST) do
        local t = c:FindFirstChild(name) or (bp and bp:FindFirstChild(name))
        if t then return t end
    end
    for _, ch in ipairs(c:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end
    if bp then for _, ch in ipairs(bp:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end end
    return nil
end

local function swingBatForCounter(bat, char)
    local hum2 = char:FindFirstChildOfClass("Humanoid")
    if bat.Parent ~= char then if hum2 then pcall(function() hum2:EquipTool(bat) end) end; task.wait(0.03) end
    local remote = bat:FindFirstChildOfClass("RemoteEvent") or bat:FindFirstChildOfClass("RemoteFunction")
    if remote and remote:IsA("RemoteEvent") then
        pcall(function() remote:FireServer() end); task.wait(0.05); pcall(function() remote:FireServer() end)
    else pcall(function() bat:Activate() end); task.wait(0.05); pcall(function() bat:Activate() end) end
end

local function startBatCounter()
    if S.batCounterConn then S.batCounterConn:Disconnect() end
    S.batCounterConn = RunService.Heartbeat:Connect(function()
        if not S.batCounterEnabled then return end
        if S.batCounterDebounce then return end
        local char = LP.Character; if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
        local st = hum:GetState()
        local isRagged = st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown
        if isRagged then
            S.batCounterDebounce = true
            task.spawn(function()
                local bat = findBatForCounter()
                if bat then swingBatForCounter(bat, char) end
                task.wait(0.1)
                S.batCounterDebounce = false
            end)
        end
    end)
end

local function stopBatCounter()
    if S.batCounterConn then S.batCounterConn:Disconnect(); S.batCounterConn = nil end
    S.batCounterDebounce = false
end

-- ========================= MEDUSA COUNTER =========================
local function findMedusa()
    local char = LP.Character
    if not char then return nil end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local name = tool.Name:lower()
            if name:find("medusa") or name:find("head") or name:find("stone") then
                return tool
            end
        end
    end
    local bp = LP:FindFirstChild("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") then
                local name = tool.Name:lower()
                if name:find("medusa") or name:find("head") or name:find("stone") then
                    return tool
                end
            end
        end
    end
    return nil
end

local function useMedusaCounter()
    if S.medusaDebounce then return end
    if tick() - S.medusaLastUsed < S.MEDUSA_COOLDOWN then return end
    local char = LP.Character
    if not char then return end
    S.medusaDebounce = true
    local med = findMedusa()
    if not med then
        S.medusaDebounce = false
        return
    end
    if med.Parent ~= char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum:EquipTool(med) end
    end
    pcall(function() med:Activate() end)
    S.medusaLastUsed = tick()
    S.medusaDebounce = false
end

local function onAnchorChanged(part)
    return part:GetPropertyChangedSignal("Anchored"):Connect(function()
        if part.Anchored and part.Transparency == 1 and S.medusaCounterEnabled then
            useMedusaCounter()
        end
    end)
end

local function setupMedusaCounter(char)
    for _, c in pairs(S.medusaConns) do pcall(function() c:Disconnect() end) end
    S.medusaConns = {}
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            table.insert(S.medusaConns, onAnchorChanged(part))
        end
    end
    table.insert(S.medusaConns, char.DescendantAdded:Connect(function(part)
        if part:IsA("BasePart") then
            table.insert(S.medusaConns, onAnchorChanged(part))
        end
    end))
end

local function stopMedusaCounter()
    for _, c in pairs(S.medusaConns) do pcall(function() c:Disconnect() end) end
    S.medusaConns = {}
end

-- ========================= FPS BOOST =========================
local function applyFPSBoost()
    safeSetfpscap(999999999)
    removeCharacterAccessories()
    local function pO(v)
        pcall(function()
            if v:IsA("Model") then
                v.LevelOfDetail = Enum.ModelLevelOfDetail.Disabled
                v.ModelStreamingMode = Enum.ModelStreamingMode.Nonatomic
            elseif v:IsA("MeshPart") then
                v.CastShadow = false; v.DoubleSided = false
                v.RenderFidelity = Enum.RenderFidelity.Performance
            elseif v:IsA("BasePart") then
                v.CastShadow = false; v.Material = Enum.Material.Plastic; v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            elseif v:IsA("SpecialMesh") then
                v.TextureId = ""
            elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke")
                or v:IsA("Sparkles") or v:IsA("ParticleEmitter")
                or v:IsA("Trail") or v:IsA("Beam") then
                v.Enabled = false
            elseif v:IsA("SurfaceAppearance") or v:IsA("MaterialVariant") then
                v:Destroy()
            elseif v:IsA("Attachment") then
                v.Visible = false
            end
        end)
    end
    for _, v in pairs(workspace:GetDescendants()) do pO(v) end
    pcall(function()
        local L = Lighting
        for _, v in pairs(L:GetDescendants()) do
            pcall(function()
                if v:IsA("Sky") or v:IsA("Atmosphere") or v:IsA("BloomEffect")
                    or v:IsA("BlurEffect") or v:IsA("SunRaysEffect")
                    or v:IsA("DepthOfFieldEffect") or v:IsA("Clouds")
                    or v:IsA("PostEffect") or v:IsA("ColorCorrectionEffect") then
                    v:Destroy()
                end
            end)
        end
        safeSethiddenproperty(L, "Technology", Enum.Technology.Legacy)
        L.GlobalShadows = false; L.FogEnd = 9e9; L.Brightness = 0
        local ter = workspace:FindFirstChildOfClass("Terrain")
        if ter then
            safeSethiddenproperty(ter, "Decoration", false)
            ter.WaterReflectance = 0; ter.WaterTransparency = 0.7
            ter.WaterWaveSize = 0; ter.WaterWaveSpeed = 0
        end
    end)
    workspace.DescendantAdded:Connect(function(v)
        if S.fpsBoostEnabled then task.spawn(pO, v) end
    end)
end

local function stopFPSBoost()
    S.fpsBoostEnabled = false
    restoreAccessories()
end

-- ========================= TP FLOOR =========================
local function runTPFloor()
    pcall(function()
        local char = LP.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local rp = RaycastParams.new()
        rp.FilterDescendantsInstances = {char}
        rp.FilterType = Enum.RaycastFilterType.Exclude
        local res = workspace:Raycast(hrp.Position, Vector3.new(0, -500, 0), rp)
        if res then
            hrp.CFrame = CFrame.new(hrp.Position.X, res.Position.Y + hrp.Size.Y/2 + 0.5, hrp.Position.Z)
            hrp.Velocity = Vector3.zero
            pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero end)
            pcall(function() hrp.AssemblyAngularVelocity = Vector3.zero end)
        end
    end)
end

-- ========================= NOCLIP =========================
local _noclipCache = {}
RunService.Stepped:Connect(function(_, dt)
    S._noclipTimer = S._noclipTimer + dt
    if S._noclipTimer < 0.15 then return end
    S._noclipTimer = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local cached = _noclipCache[p]
            if not cached or cached.char ~= p.Character then
                local parts = {}
                for _, obj in ipairs(p.Character:GetDescendants()) do
                    if obj:IsA("BasePart") then table.insert(parts, obj) end
                end
                _noclipCache[p] = {char = p.Character, parts = parts}
                cached = _noclipCache[p]
            end
            for _, part in ipairs(cached.parts) do
                if part and part.Parent then part.CanCollide = false end
            end
        else
            _noclipCache[p] = nil
        end
    end
end)

RunService.RenderStepped:Connect(function()
    S._fpsCount = S._fpsCount + 1
    local now = tick()
    if now - S._lastFpsTime >= 1 then
        S.currentFPS = math.floor(S._fpsCount/(now - S._lastFpsTime))
        S._fpsCount = 0
        S._lastFpsTime = now
    end
end)

updateFloatingButtons = function()
    if not S._setPButtonActive then return end
    local fb = S._floatingButtons
    if fb.lagger then updateLaggerButtonVisual() end
    if fb.carry then S._setPButtonActive(fb.carry, fb.strokeCarry, fb.l1Carry, fb.l2Carry, S.speedMode) end
    if fb.autoTPDown then S._setPButtonActive(fb.autoTPDown, fb.strokeAutoTPDown, fb.l1AutoTPDown, fb.l2AutoTPDown, S.autoTPDownEnabled) end
    if fb.drop2 then S._setPButtonActive(fb.drop2, fb.strokeDrop2, fb.l1Drop2, fb.l2Drop2, S.dropBrainrotActive) end
    if fb.autoplay then
        S._setPButtonActive(fb.autoplay, fb.strokeAutoplay, fb.l1Autoplay, fb.l2Autoplay, (S.atrAutoLeft or S.atrAutoRight))
    end
    if fb.bypassAimbotV2 and S.setBypassAimbotV2Visual then
        S.setBypassAimbotV2Visual(S.bypassAimbotV2Toggled)
    end
end

local function setUILock(enabled)
    S.lockUIEnabled = enabled
    if S.mainMenuFrame then S.mainMenuFrame.Active = not enabled end
    if S.miniToggleButton then S.miniToggleButton.Active = not enabled end
end

local dragState = { current = nil }

local function makeDraggable(frame, isFloatingPanel)
    local dragging = false
    local dragStart, startPos = nil, nil

    frame.InputBegan:Connect(function(inp)
        if S.lockUIEnabled then return end
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            if dragState.current and dragState.current ~= frame then
                return
            end
            dragging = true
            dragState.current = frame
            dragStart = inp.Position
            startPos = frame.Position

            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.InputUserState.End then
                    dragging = false
                    if dragState.current == frame then
                        dragState.current = nil
                    end
                end
            end)
        end
    end)

    UIS.InputChanged:Connect(function(inp)
        if S.lockUIEnabled or not dragging then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
            local delta = inp.Position - dragStart
            if delta.Magnitude > 2 then
                local newX = startPos.X.Offset + delta.X
                local newY = startPos.Y.Offset + delta.Y
                frame.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
            end
        end
    end)

    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            if dragState.current == frame then
                dragging = false
                dragState.current = nil
            end
        end
    end)
end

-- ========================= ESP PLAYER =========================
local function hideRobloxName(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    end
end

local function createESPForPlayer(player)
    if player == LP or not S.espEnabled then return end
    local character = player.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")
    if not root or not head then return end
    hideRobloxName(character)

    local holder = S.espFolder:FindFirstChild(player.Name)
    if holder then holder:Destroy() end

    holder = Instance.new("Folder")
    holder.Name = player.Name
    holder.Parent = S.espFolder

    local box = Instance.new("BoxHandleAdornment")
    box.Name = "Box"
    box.Adornee = root
    box.AlwaysOnTop = true
    box.ZIndex = 5
    box.Size = Vector3.new(4,6,2)
    box.Transparency = 0.45
    box.Color3 = Color3.fromRGB(0, 0, 255)
    box.Parent = holder

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "Info"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0,140,0,40)
    billboard.StudsOffset = Vector3.new(0,3,0)
    billboard.AlwaysOnTop = true
    billboard.Parent = holder

    local image = Instance.new("ImageLabel")
    image.Size = UDim2.new(0,28,0,28)
    image.Position = UDim2.new(0,0,0.5,-14)
    image.BackgroundTransparency = 1
    image.Parent = billboard

    local thumb = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    image.Image = thumb
    Instance.new("UICorner", image).CornerRadius = UDim.new(1,0)

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1,-35,1,0)
    text.Position = UDim2.new(0,35,0,0)
    text.BackgroundTransparency = 1
    text.Text = player.Name
    text.TextColor3 = Color3.fromRGB(255,255,255)
    text.TextStrokeTransparency = 0
    text.TextScaled = true
    text.Font = Enum.Font.GothamBold
    text.Parent = billboard
end

local function removeESPForPlayer(player)
    if S.espFolder then
        local esp = S.espFolder:FindFirstChild(player.Name)
        if esp then esp:Destroy() end
    end
end

local function startESP()
    if S.espEnabled then return end
    S.espEnabled = true

    if not S.espFolder or S.espFolder.Parent == nil then
        S.espFolder = Instance.new("Folder")
        S.espFolder.Name = "PlayerESP"
        S.espFolder.Parent = CoreGui
    end

    for _, conn in pairs(S.espConnections) do
        pcall(function() conn:Disconnect() end)
    end
    S.espConnections = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            if player.Character then
                createESPForPlayer(player)
            end
            S.espConnections[player] = player.CharacterAdded:Connect(function()
                task.wait(1)
                createESPForPlayer(player)
            end)
        end
    end

    S.espConnections.PlayerAdded = Players.PlayerAdded:Connect(function(player)
        S.espConnections[player] = player.CharacterAdded:Connect(function()
            task.wait(1)
            createESPForPlayer(player)
        end)
    end)

    S.espConnections.PlayerRemoving = Players.PlayerRemoving:Connect(function(player)
        removeESPForPlayer(player)
        if S.espConnections[player] then
            S.espConnections[player]:Disconnect()
            S.espConnections[player] = nil
        end
    end)
end

local function stopESP()
    if not S.espEnabled then return end
    S.espEnabled = false

    for _, conn in pairs(S.espConnections) do
        pcall(function() conn:Disconnect() end)
    end
    S.espConnections = {}

    if S.espFolder then
        S.espFolder:Destroy()
        S.espFolder = nil
    end
end

local function toggleESP(state)
    if state then
        startESP()
    else
        stopESP()
    end
    if S.setEspVisual then S.setEspVisual(state) end
    saveConfig()
end

-- ========================= INTERFAZ =========================
local function buildGui_createScrollingPages(rightPanel)
    local pages = {}
    for _, n in ipairs({"Speed", "Visual", "Combat", "Config"}) do
        local sf = Instance.new("ScrollingFrame", rightPanel)
        sf.Size = UDim2.new(1,0,1,0)
        sf.BackgroundTransparency = 1
        sf.BorderSizePixel = 0
        sf.ScrollBarThickness = 6
        sf.ScrollBarImageColor3 = Color3.fromRGB(120,120,120)
        sf.ScrollingEnabled = true
        sf.Visible = false
        sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
        sf.CanvasSize = UDim2.new(0,0,0,0)

        local ll = Instance.new("UIListLayout", sf)
        ll.SortOrder = Enum.SortOrder.LayoutOrder
        ll.Padding = UDim.new(0, 4)
        ll.FillDirection = Enum.FillDirection.Vertical

        local pp = Instance.new("UIPadding", sf)
        pp.PaddingLeft = UDim.new(0, 12)
        pp.PaddingRight = UDim.new(0, 12)
        pp.PaddingTop = UDim.new(0, 0)
        pp.PaddingBottom = UDim.new(0, 40)

        pages[n] = sf
    end
    return pages
end

local rowCounts = {Speed = 0, Visual = 0, Combat = 0, Config = 0}

local function mkCard(pg, pages, h)
    local C_CARD = Color3.fromRGB(248,248,248)
    rowCounts[pg] = rowCounts[pg] + 1
    local f = Instance.new("Frame", pages[pg])
    f.Size = UDim2.new(1,0,0,h or 38)
    f.BackgroundColor3 = C_CARD
    f.BorderSizePixel = 0
    f.LayoutOrder = rowCounts[pg]
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", f)
    stroke.Color = Color3.fromRGB(200,200,200)
    stroke.Thickness = 0.5
    return f
end

local function mkToggle(pg, pages, label, defKey, defOn, onToggle, onKeyChanged)
    local C_ON = Color3.fromRGB(0,0,0)
    local C_OFF = Color3.fromRGB(180,180,180)
    local C_TEXT = Color3.fromRGB(0,0,0)
    local card = mkCard(pg, pages, 38)
    local lbl = Instance.new("TextLabel", card)
    lbl.Size = UDim2.new(0,140,1,0)
    lbl.Position = UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = C_TEXT
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local pillBg = Instance.new("Frame", card)
    pillBg.Size = UDim2.new(0,28,0,16)
    pillBg.Position = UDim2.new(1,-36,0.5,-8)
    pillBg.BackgroundColor3 = defOn and C_ON or C_OFF
    pillBg.BorderSizePixel = 0
    Instance.new("UICorner", pillBg).CornerRadius = UDim.new(1,0)
    local dot = Instance.new("Frame", pillBg)
    dot.Size = UDim2.new(0,12,0,12)
    dot.Position = defOn and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6)
    dot.BackgroundColor3 = defOn and Color3.fromRGB(255,255,255) or C_TEXT
    dot.BorderSizePixel = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)
    local isOn = defOn or false
    local function setV(on)
        isOn = on
        pillBg.BackgroundColor3 = on and C_ON or C_OFF
        dot.Position = on and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6)
        dot.BackgroundColor3 = on and Color3.fromRGB(255,255,255) or C_TEXT
    end
    local clickArea = Instance.new("TextButton", card)
    clickArea.Size = UDim2.new(1,0,1,0)
    clickArea.BackgroundTransparency = 1
    clickArea.Text = ""
    clickArea.ZIndex = 3
    clickArea.MouseButton1Click:Connect(function()
        isOn = not isOn
        setV(isOn)
        if onToggle then onToggle(isOn) end
    end)
    if defOn then setV(true) end
    return setV, nil
end

local function mkInput(pg, pages, label, default, onChange)
    local C_TEXT = Color3.fromRGB(0,0,0)
    local card = mkCard(pg, pages, 38)
    local lbl = Instance.new("TextLabel", card)
    lbl.Size = UDim2.new(0.5,-10,1,0)
    lbl.Position = UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = C_TEXT
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local box = Instance.new("TextBox", card)
    box.Size = UDim2.new(0,70,0,28)
    box.Position = UDim2.new(1,-78,0.5,-14)
    box.BackgroundColor3 = Color3.fromRGB(230,230,230)
    box.BorderSizePixel = 0
    box.Text = tostring(default)
    box.TextColor3 = C_TEXT
    box.Font = Enum.Font.GothamBlack
    box.TextSize = 11
    box.ClearTextOnFocus = false
    box.MultiLine = false
    pcall(function() box.ReturnKeyType = Enum.ReturnKeyType.Done end)
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

    local lastVal = tostring(default)
    local isFocused = false

    local function applyValue()
        if not isFocused then return end
        isFocused = false
        local n = tonumber(box.Text)
        if n then
            lastVal = tostring(n)
            box.Text = lastVal
            onChange(n)
        else
            box.Text = lastVal
        end
        pcall(function() box:ReleaseFocus(false) end)
    end

    box.Focused:Connect(function()
        isFocused = true
    end)

    box.FocusLost:Connect(function()
        if isFocused then
            isFocused = false
            local n = tonumber(box.Text)
            if n then
                lastVal = tostring(n)
                box.Text = lastVal
                onChange(n)
            else
                box.Text = lastVal
            end
        end
    end)

    pcall(function()
        box.ReturnPressedFromOnScreenKeyboard:Connect(function()
            applyValue()
        end)
    end)

    UIS.TouchTap:Connect(function(positions)
        if not isFocused then return end
        pcall(function()
            local abs = box.AbsolutePosition
            local sz  = box.AbsoluteSize
            local tp  = positions[1]
            if tp then
                local inside = tp.X >= abs.X and tp.X <= abs.X + sz.X
                           and tp.Y >= abs.Y and tp.Y <= abs.Y + sz.Y
                if not inside then
                    applyValue()
                end
            end
        end)
    end)

    return box
end

local function buildGui_createMiniToggle(gui, showGuiFn)
    local C_TEXT = Color3.fromRGB(0,0,0)
    local miniToggleBtn = Instance.new("TextButton", gui)
    miniToggleBtn.Name = "MiniToggle"
    miniToggleBtn.Size = UDim2.new(0,160,0,36)
    miniToggleBtn.Position = UDim2.new(0,38,0,60)
    miniToggleBtn.BackgroundColor3 = Color3.fromRGB(245,245,245)
    miniToggleBtn.BorderSizePixel = 0
    miniToggleBtn.Text = ""
    miniToggleBtn.ZIndex = 20
    miniToggleBtn.Visible = false
    Instance.new("UICorner", miniToggleBtn).CornerRadius = UDim.new(0, 18)
    local miniStroke = Instance.new("UIStroke", miniToggleBtn)
    miniStroke.Color = Color3.fromRGB(0,0,0)
    miniStroke.Thickness = 1
    miniStroke.Transparency = 0.8
    local miniMainText = Instance.new("TextLabel", miniToggleBtn)
    miniMainText.Size = UDim2.new(1,-38,1,0)
    miniMainText.Position = UDim2.new(0,32,0,0)
    miniMainText.BackgroundTransparency = 1
    miniMainText.Text = "SURE HUB"
    miniMainText.TextColor3 = C_TEXT
    miniMainText.Font = Enum.Font.GothamBlack
    miniMainText.TextSize = 14
    miniMainText.TextXAlignment = Enum.TextXAlignment.Left
    miniMainText.ZIndex = 21
    makeDraggable(miniToggleBtn, false)
    miniToggleBtn.MouseButton1Click:Connect(showGuiFn)
    return miniToggleBtn
end

local function buildSpeedTab(pages)
    S.carryBox = mkInput("Speed", pages, "Carry Speed", S.CS, function(v)
        if v>0 and v<=500 then S.CS = v; S.restartMovement(); saveConfig() end
    end)
    S.laggerBox = mkInput("Speed", pages, "Lagger Speed", S.LS, function(v)
        if v>0 and v<=500 then S.LS = v; S.restartMovement(); saveConfig() end
    end)

    S.autoTPDownThresholdBox = mkInput("Speed", pages, "Auto TP Down Height", S.autoTPDownThreshold, function(v)
        if v >= 0 and v <= 500 then
            S.autoTPDownThreshold = v
            saveConfig()
        end
    end)

    S.bypassSpeedBox = mkInput("Speed", pages, "Bypass Aimbot Speed", S.bypassAimbotSpeed, function(v)
        if v > 0 and v <= 500 then
            S.bypassAimbotSpeed = v
            saveConfig()
        end
    end)

    S.autoPlaySpdBox = mkInput("Speed", pages, "AutoPlaySpd", S.autoPlaySpeed1, function(v)
        if v > 0 and v <= 500 then
            S.autoPlaySpeed1 = v
            saveConfig()
        end
    end)

    S.vueltaAutoPlayBox = mkInput("Speed", pages, "VueltaAutoPlay", S.autoPlaySpeed2, function(v)
        if v > 0 and v <= 500 then
            S.autoPlaySpeed2 = v
            saveConfig()
        end
    end)

    S.speedClk, _ = mkToggle("Speed", pages, "Carry Mode", nil, false, function(on)
        if on then
            if S.laggerMode then
                S.laggerMode = false
                if S.setLaggerVisual then S.setLaggerVisual(false) end
                updateLaggerButtonVisual()
            end
        end
        S.speedMode = on
        S.restartMovement()
        updateFloatingButtons()
        saveConfig()
    end, nil)

    S.setLaggerVisual, _ = mkToggle("Speed", pages, "Lagger Mode", nil, false, function(on)
        if on then
            if S.speedMode then
                S.speedMode = false
                if S.speedClk then S.speedClk(false) end
            end
            S.laggerMode = not S.laggerMode
        else
            S.laggerMode = false
        end
        updateLaggerButtonVisual()
        S.restartMovement()
        updateFloatingButtons()
        saveConfig()
    end, nil)
end

local function buildVisualTab(pages)
    S.setDarkVisual, _ = mkToggle("Visual", pages, "Galaxy Mode", nil, false, function(on)
        toggleGalaxyMode()
        saveConfig()
    end, nil)

    S.setFpsVisual, _ = mkToggle("Visual", pages, "Boost FPS", nil, false, function(on)
        S.fpsBoostEnabled = on
        if on then applyFPSBoost() else stopFPSBoost() end
        saveConfig()
    end, nil)

    S.setInfJumpVisual, _ = mkToggle("Visual", pages, "Infinite Jump", nil, false, function(on)
        S.infJumpEnabled = on
        if on then startInfiniteJump() else stopInfiniteJump() end
        saveConfig()
    end, nil)

    S.setEspVisual, _ = mkToggle("Visual", pages, "ESP Player", nil, false, function(on)
        toggleESP(on)
    end, nil)
end

local function buildCombatTab(pages)
    S.setBatCounterVisual, _ = mkToggle("Combat", pages, "Bat Counter", nil, false, function(on)
        S.batCounterEnabled = on
        if on then startBatCounter() else stopBatCounter() end
        saveConfig()
    end, nil)

    S.autoTPDownSetVisual, _ = mkToggle("Combat", pages, "Auto TP Down", nil, false, function(on)
        S.autoTPDownEnabled = on
        if on then startAutoTPDown() else stopAutoTPDown() end
        if S.autoTPDownFloatVisual then S.autoTPDownFloatVisual(on) end
        saveConfig()
    end, nil)

    S.setUnwalkVisual, _ = mkToggle("Combat", pages, "Unwalk", nil, false, function(on)
        if on then startUnwalk() else stopUnwalk() end
        saveConfig()
    end, nil)

    S.setMedusaVisual, _ = mkToggle("Combat", pages, "Medusa Counter", nil, false, function(on)
        S.medusaCounterEnabled = on
        if on then
            setupMedusaCounter(LP.Character)
        else
            stopMedusaCounter()
        end
        saveConfig()
    end, nil)

    S.setAutoStealVisual, _ = mkToggle("Combat", pages, "Auto Steal", nil, false, function(on)
        toggleAutoSteal(on)
    end, nil)

    S.setTauntVisual, _ = mkToggle("Combat", pages, "Taunt Button", nil, false, function(on)
        setTauntEnabled(on)
    end, nil)

    S.setAntiRagdollVisual, _ = mkToggle("Combat", pages, "Anti Ragdoll", nil, false, function(on)
        S.antiRagdollEnabled = on
        if on then startAntiRagdoll() else stopAntiRagdoll() end
        saveConfig()
    end, nil)
end

local function buildConfigTab(pages)
    local C_ON = Color3.fromRGB(0,0,0)
    local C_OFF = Color3.fromRGB(180,180,180)
    local C_WHITE = Color3.fromRGB(0,0,0)

    do
        local card = mkCard("Config", pages, 38)
        local lbl = Instance.new("TextLabel", card)
        lbl.Size = UDim2.new(0,100,1,0); lbl.Position = UDim2.new(0,12,0,0)
        lbl.BackgroundTransparency = 1; lbl.Text = "Lock UI"; lbl.TextColor3 = C_WHITE
        lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11
        local pill = Instance.new("Frame", card)
        pill.Size = UDim2.new(0,28,0,16); pill.Position = UDim2.new(1,-36,0.5,-8)
        pill.BackgroundColor3 = C_OFF; pill.BorderSizePixel = 0
        Instance.new("UICorner", pill).CornerRadius = UDim.new(1,0)
        local dot = Instance.new("Frame", pill)
        dot.Size = UDim2.new(0,12,0,12); dot.Position = UDim2.new(0,2,0.5,-6)
        dot.BackgroundColor3 = C_WHITE; dot.BorderSizePixel = 0
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)
        local lockOn = false
        local function setLockVis(on)
            lockOn = on
            pill.BackgroundColor3 = on and C_ON or C_OFF
            dot.Position = on and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6)
            dot.BackgroundColor3 = on and Color3.fromRGB(255,255,255) or C_WHITE
        end
        S.setLockUI_Visual = setLockVis
        local click = Instance.new("TextButton", card)
        click.Size = UDim2.new(1,0,1,0); click.BackgroundTransparency = 1; click.Text = ""; click.ZIndex = 3
        click.MouseButton1Click:Connect(function()
            lockOn = not lockOn; setLockVis(lockOn); setUILock(lockOn); saveConfig()
        end)
    end

    do
        local card = mkCard("Config", pages, 38)
        local lbl = Instance.new("TextLabel", card)
        lbl.Size = UDim2.new(0,140,1,0); lbl.Position = UDim2.new(0,12,0,0)
        lbl.BackgroundTransparency = 1; lbl.Text = "Hide Buttons"; lbl.TextColor3 = C_WHITE
        lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11
        local pill = Instance.new("Frame", card)
        pill.Size = UDim2.new(0,28,0,16); pill.Position = UDim2.new(1,-36,0.5,-8)
        pill.BackgroundColor3 = C_OFF; pill.BorderSizePixel = 0
        Instance.new("UICorner", pill).CornerRadius = UDim.new(1,0)
        local dot = Instance.new("Frame", pill)
        dot.Size = UDim2.new(0,12,0,12); dot.Position = UDim2.new(0,2,0.5,-6)
        dot.BackgroundColor3 = C_WHITE; dot.BorderSizePixel = 0
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)
        local hideButtonsOn = false
        local function setHideButtonsVis(on)
            hideButtonsOn = on
            pill.BackgroundColor3 = on and C_ON or C_OFF
            dot.Position = on and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6)
            dot.BackgroundColor3 = on and Color3.fromRGB(255,255,255) or C_WHITE
        end
        S.setHideOpiumButtons = setHideButtonsVis
        local click2 = Instance.new("TextButton", card)
        click2.Size = UDim2.new(1,0,1,0); click2.BackgroundTransparency = 1; click2.Text = ""; click2.ZIndex = 3
        click2.MouseButton1Click:Connect(function()
            hideButtonsOn = not hideButtonsOn
            setHideButtonsVis(hideButtonsOn)
            if S.floatingPanelGui then
                S.floatingPanelGui.Enabled = not hideButtonsOn
            end
            pcall(function()
                local pg = LP:FindFirstChild("PlayerGui")
                if pg then
                    local opiumGui = pg:FindFirstChild("OpiumGGV5_2")
                    if opiumGui then opiumGui.Enabled = not hideButtonsOn end
                end
            end)
            S.hideOpiumButtonsEnabled = hideButtonsOn
            saveConfig()
        end)
    end

    do
        local card = mkCard("Config", pages, 38)
        local lbl = Instance.new("TextLabel", card)
        lbl.Size = UDim2.new(0,140,1,0); lbl.Position = UDim2.new(0,12,0,0)
        lbl.BackgroundTransparency = 1; lbl.Text = "Reset Panel"; lbl.TextColor3 = C_WHITE
        lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11
        local resetBtn = Instance.new("TextButton", card)
        resetBtn.Size = UDim2.new(0,80,0,28)
        resetBtn.Position = UDim2.new(1,-90,0.5,-14)
        resetBtn.BackgroundColor3 = Color3.fromRGB(220,220,220)
        resetBtn.BorderSizePixel = 0
        resetBtn.Text = "Reset"
        resetBtn.TextColor3 = C_WHITE
        resetBtn.Font = Enum.Font.GothamBold
        resetBtn.TextSize = 11
        Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0,6)
        resetBtn.MouseButton1Click:Connect(function()
            local originalText = resetBtn.Text
            resetBtn.Text = "..."
            task.spawn(function()
                resetFloatingPanel()
                task.wait(0.2)
                resetBtn.Text = originalText
            end)
        end)
    end
end

local function buildGui()
    local C_BG_OUTER  = Color3.fromRGB(255,255,255)
    local C_BG_INNER  = Color3.fromRGB(255,255,255)
    local C_WHITE     = Color3.fromRGB(0,0,0)
    local C_DIM       = Color3.fromRGB(80,80,80)
    local C_ACCENT    = Color3.fromRGB(0,0,0)
    local C_BORDER    = Color3.fromRGB(200,200,200)
    local C_CARD_BG   = Color3.fromRGB(248,248,248)
    local C_ACTIVE_BG = Color3.fromRGB(230,230,230)

    local TOTAL_W  = 480
    local TOTAL_H  = 480
    local SIDEBAR_W = 155

    local old = game:GetService("CoreGui"):FindFirstChild("SUREHUB")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "SUREHUB"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 100
    gui.IgnoreGuiInset = true
    pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

    local main = Instance.new("Frame", gui)
    main.Name = "Main"
    main.Size = UDim2.new(0, TOTAL_W, 0, TOTAL_H)
    main.Position = UDim2.new(0, 40, 0, 0)
    main.BackgroundTransparency = 1
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Visible = true
    local mainCorner = Instance.new("UICorner", main)
    mainCorner.CornerRadius = UDim.new(0, 16)
    local mainStroke = Instance.new("UIStroke", main)
    mainStroke.Color = Color3.fromRGB(200, 200, 200)
    mainStroke.Thickness = 0.8
    mainStroke.Transparency = 0.3
    S.mainMenuFrame = main
    makeDraggable(main, false)

    -- IMAGEN DE FONDO (ID: 114092553501147) - completamente opaca
    local fondoImagen = Instance.new("ImageLabel", main)
    fondoImagen.Name = "FondoImagen"
    fondoImagen.Size = UDim2.new(1, 0, 1, 0)
    fondoImagen.BackgroundTransparency = 1
    fondoImagen.Image = "rbxassetid://114092553501147"
    fondoImagen.ImageTransparency = 0
    fondoImagen.ScaleType = Enum.ScaleType.Crop
    fondoImagen.ZIndex = 0

    -- Sidebar con fondo blanco semitransparente (más transparente para ver la imagen)
    local sidebar = Instance.new("Frame", main)
    sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, 0)
    sidebar.Position = UDim2.new(0,0,0,0)
    sidebar.BackgroundColor3 = Color3.fromRGB(255,255,255)
    sidebar.BackgroundTransparency = 0.95
    sidebar.BorderSizePixel = 0
    sidebar.ClipsDescendants = true
    local sidebarCorner = Instance.new("UICorner", sidebar)
    sidebarCorner.CornerRadius = UDim.new(0, 12)

    local divider = Instance.new("Frame", main)
    divider.Size = UDim2.new(0,1,1,-24)
    divider.Position = UDim2.new(0,SIDEBAR_W,0,12)
    divider.BackgroundColor3 = C_BORDER
    divider.BorderSizePixel = 0

    local TAB_NAMES = {"Speed", "Visual", "Combat", "Config"}
    local tabBtns = {}

    local tabListFrame = Instance.new("Frame", sidebar)
    tabListFrame.Size = UDim2.new(1,0,1,0)
    tabListFrame.Position = UDim2.new(0,0,0,0)
    tabListFrame.BackgroundTransparency = 1

    local tabLL = Instance.new("UIListLayout", tabListFrame)
    tabLL.SortOrder = Enum.SortOrder.LayoutOrder
    tabLL.Padding = UDim.new(0, 8)
    local tabPad = Instance.new("UIPadding", tabListFrame)
    tabPad.PaddingLeft = UDim.new(0, 12)
    tabPad.PaddingRight = UDim.new(0, 12)
    tabPad.PaddingTop = UDim.new(0, 12)
    tabPad.PaddingBottom = UDim.new(0, 12)

    local function switchTab(name) end

    for i, name in ipairs(TAB_NAMES) do
        local btn = Instance.new("TextButton", tabListFrame)
        btn.Size = UDim2.new(1,0,0,36)
        btn.BackgroundColor3 = C_CARD_BG
        btn.BackgroundTransparency = 0.3
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.LayoutOrder = i
        btn.AutoButtonColor = false

        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
        local stroke = Instance.new("UIStroke", btn)
        stroke.Color = C_BORDER
        stroke.Thickness = 1
        stroke.Transparency = 0.4

        local lbl = Instance.new("TextLabel", btn)
        lbl.Size = UDim2.new(1,0,1,0)
        lbl.BackgroundTransparency = 1
        lbl.Text = name
        lbl.TextColor3 = C_DIM
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Center

        local activeIndicator = Instance.new("Frame", btn)
        activeIndicator.Size = UDim2.new(0.8,0,0,2)
        activeIndicator.Position = UDim2.new(0.1,0,1,-2)
        activeIndicator.BackgroundColor3 = C_ACCENT
        activeIndicator.BorderSizePixel = 0
        activeIndicator.Visible = (name == "Speed")
        Instance.new("UICorner", activeIndicator).CornerRadius = UDim.new(1,0)

        tabBtns[name] = {bg = btn, lbl = lbl, ind = activeIndicator, stroke = stroke}
        btn.MouseButton1Click:Connect(function()
            switchTab(name)
        end)
    end

    -- Panel derecho con fondo blanco semitransparente (más transparente)
    local rightPanel = Instance.new("Frame", main)
    rightPanel.Size = UDim2.new(0, TOTAL_W - SIDEBAR_W - 1, 1, 0)
    rightPanel.Position = UDim2.new(0, SIDEBAR_W+1, 0, 0)
    rightPanel.BackgroundColor3 = Color3.fromRGB(255,255,255)
    rightPanel.BackgroundTransparency = 0.95
    rightPanel.BorderSizePixel = 0
    rightPanel.ClipsDescendants = true
    local rightCorner = Instance.new("UICorner", rightPanel)
    rightCorner.CornerRadius = UDim.new(0, 12)

    local topBar = Instance.new("Frame", rightPanel)
    topBar.Size = UDim2.new(1,0,0,44)
    topBar.BackgroundColor3 = Color3.fromRGB(255,255,255)
    topBar.BackgroundTransparency = 0.95
    topBar.BorderSizePixel = 0
    local topBarDiv = Instance.new("Frame", rightPanel)
    topBarDiv.Size = UDim2.new(1,-20,0,1)
    topBarDiv.Position = UDim2.new(10,0,0,44)
    topBarDiv.BackgroundColor3 = C_BORDER
    topBarDiv.BorderSizePixel = 0

    local panelTitle = Instance.new("TextLabel", topBar)
    panelTitle.Size = UDim2.new(1,-50,1,0)
    panelTitle.Position = UDim2.new(0,16,0,0)
    panelTitle.BackgroundTransparency = 1
    panelTitle.Text = "Speed"
    panelTitle.TextColor3 = C_WHITE
    panelTitle.Font = Enum.Font.GothamBlack
    panelTitle.TextSize = 16
    panelTitle.TextXAlignment = Enum.TextXAlignment.Left

    local closeBtn = Instance.new("TextButton", topBar)
    closeBtn.Size = UDim2.new(0,28,0,28)
    closeBtn.Position = UDim2.new(1,-34,0.5,-14)
    closeBtn.BackgroundColor3 = Color3.fromRGB(220,220,220)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "–"
    closeBtn.TextColor3 = C_WHITE
    closeBtn.Font = Enum.Font.GothamBlack
    closeBtn.TextSize = 20
    closeBtn.AutoButtonColor = false
    closeBtn.ZIndex = 50
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1,0)

    closeBtn.MouseButton1Click:Connect(function()
        main.Visible = false
        if S.miniToggleButton then S.miniToggleButton.Visible = true end
    end)

    local contentArea = Instance.new("Frame", rightPanel)
    contentArea.Size = UDim2.new(1,0,1,-45)
    contentArea.Position = UDim2.new(0,0,0,45)
    contentArea.BackgroundTransparency = 1
    contentArea.ClipsDescendants = true

    local pages = buildGui_createScrollingPages(contentArea)
    local activePage = pages["Speed"]
    activePage.Visible = true

    switchTab = function(name)
        if activePage then activePage.Visible = false end
        activePage = pages[name]
        activePage.Visible = true
        panelTitle.Text = name
        for tName, tData in pairs(tabBtns) do
            local isActive = (tName == name)
            tData.lbl.TextColor3 = isActive and C_WHITE or C_DIM
            tData.ind.Visible = isActive
            tData.bg.BackgroundColor3 = isActive and C_ACTIVE_BG or C_CARD_BG
            tData.bg.BackgroundTransparency = isActive and 0.3 or 0.3
            tData.stroke.Transparency = isActive and 0 or 0.4
        end
    end

    buildSpeedTab(pages)
    buildVisualTab(pages)
    buildCombatTab(pages)
    buildConfigTab(pages)

    local function showGui()
        main.Visible = true
        if S.miniToggleButton then S.miniToggleButton.Visible = false end
    end
    S.miniToggleButton = buildGui_createMiniToggle(gui, showGui)

    UIS.InputBegan:Connect(function(input, gpe)
        if input.UserInputType ~= Enum.UserInputType.Keyboard and input.UserInputType ~= Enum.UserInputType.Gamepad1 then return end
        local kc = input.KeyCode
        local function match(entry)
            return kc == entry.kb or (entry.gp and kc == entry.gp)
        end
        if gpe then
            if match(S.KB.GuiHide) then
                if main.Visible then
                    main.Visible = false
                    if S.miniToggleButton then S.miniToggleButton.Visible = true end
                else
                    showGui()
                end
            end
            return
        end
        if match(S.KB.DropBrainrot) then
            task.spawn(runDropBrainrot)
        elseif match(S.KB.TPFlor) then
            runTPFloor()
        elseif match(S.KB.AutoBat) then
            setBatAimbot(not S.batAimbotEnabled)
        elseif match(S.KB.GuiHide) then
            if main.Visible then
                main.Visible = false
                if S.miniToggleButton then S.miniToggleButton.Visible = true end
            else
                showGui()
            end
        elseif match(S.KB.SpeedToggle) then
            if S.laggerMode then
                S.laggerMode = false
                if S.setLaggerVisual then S.setLaggerVisual(false) end
                updateLaggerButtonVisual()
            end
            S.speedMode = not S.speedMode
            if S.speedClk then S.speedClk(S.speedMode) end
            S.restartMovement(); updateFloatingButtons(); saveConfig()
        elseif match(S.KB.LaggerToggle) then
            if S.speedMode then
                S.speedMode = false
                if S.speedClk then S.speedClk(false) end
            end
            S.laggerMode = not S.laggerMode
            updateLaggerButtonVisual()
            if S.setLaggerVisual then S.setLaggerVisual(S.laggerMode) end
            S.restartMovement(); updateFloatingButtons(); saveConfig()
        elseif match(S.KB.AutoTPDown) then
            S.autoTPDownEnabled = not S.autoTPDownEnabled
            if S.autoTPDownEnabled then startAutoTPDown() else stopAutoTPDown() end
            if S.autoTPDownSetVisual then S.autoTPDownSetVisual(S.autoTPDownEnabled) end
            if S.autoTPDownFloatVisual then S.autoTPDownFloatVisual(S.autoTPDownEnabled) end
            saveConfig()
        elseif kc == Enum.KeyCode.N then
            toggleBypass()
        elseif kc == Enum.KeyCode.G then
            cursedInstaReset()
            if resetButtonGui and resetButtonGui._flash then
                resetButtonGui._flash()
            end
        end
    end)

    showGui()
end

-- ========================= PANEL FLOTANTE =========================
local function createFloatingButtonPanel()
    local panelGui = Instance.new("ScreenGui")
    panelGui.Name = "SUREHUB_FloatingPanel"; panelGui.ResetOnSpawn = false
    panelGui.IgnoreGuiInset = true; panelGui.DisplayOrder = 8
    if not pcall(function() panelGui.Parent = game:GetService("CoreGui") end) then
        panelGui.Parent = LP:WaitForChild("PlayerGui")
    end
    S.floatingPanelGui = panelGui

    S.floatingButtonsLocked = false

    local BLACK_OFF = Color3.fromRGB(220,220,220)
    local WHITE_ON = Color3.fromRGB(0,0,0)
    local STROKE_OFF = Color3.fromRGB(180,180,180)
    local STROKE_ON = Color3.fromRGB(0,0,0)

    local function makeFloatingButton(label1, label2, startPos)
        local btn = Instance.new("TextButton", panelGui)
        btn.Size = UDim2.new(0, 60, 0, 55)
        btn.Position = startPos or UDim2.new(1, -134, 0.5, -130)
        btn.BackgroundColor3 = BLACK_OFF
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.ZIndex = 22
        Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
        local stroke = Instance.new("UIStroke", btn)
        stroke.Color = STROKE_OFF; stroke.Thickness = 1; stroke.Transparency = 0.2
        local t1 = Instance.new("TextLabel", btn)
        t1.Size = UDim2.new(1,0,0.55,0); t1.Position = UDim2.new(0,0,0.06,0)
        t1.BackgroundTransparency = 1; t1.Text = label1; t1.TextColor3 = WHITE_ON
        t1.Font = Enum.Font.GothamBlack; t1.TextSize = 10; t1.TextXAlignment = Enum.TextXAlignment.Center; t1.ZIndex = 23
        local t2 = Instance.new("TextLabel", btn)
        t2.Size = UDim2.new(1,0,0.4,0); t2.Position = UDim2.new(0,0,0.55,0)
        t2.BackgroundTransparency = 1; t2.Text = label2; t2.TextColor3 = WHITE_ON
        t2.Font = Enum.Font.GothamBlack; t2.TextSize = 10; t2.TextXAlignment = Enum.TextXAlignment.Center; t2.ZIndex = 23
        return btn, stroke, t1, t2
    end

    local function setButtonActive(btn, stroke, label1, label2, active)
        btn.BackgroundColor3 = active and WHITE_ON or BLACK_OFF
        stroke.Color = active and STROKE_ON or STROKE_OFF
        stroke.Transparency = active and 0 or 0.2
        local textColor = active and Color3.fromRGB(255,255,255) or WHITE_ON
        if label1 then label1.TextColor3 = textColor end
        if label2 then label2.TextColor3 = textColor end
    end
    S._setPButtonActive = setButtonActive

    local function makeFloatingDraggable(obj, target)
        target = target or obj
        local dragging, dragStart, startPos, dragDist = false, nil, nil, 0
        obj.InputBegan:Connect(function(inp)
            if S.floatingButtonsLocked or S.lockUIEnabled then return end
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                dragging = true; dragStart = inp.Position; startPos = target.Position; dragDist = 0
            end
        end)
        obj.InputChanged:Connect(function(inp)
            if S.floatingButtonsLocked or S.lockUIEnabled or not dragging then return end
            if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
                local delta = inp.Position - dragStart
                dragDist = delta.Magnitude
                target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
        obj.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                if dragging then
                    dragging = false
                end
            end
        end)
    end

    local col1X, col2X = -134, -61
    local row1Y, row2Y, row3Y, row4Y = -130, -65, 0, 65

    local btnTP, bsTP, l1TP, l2TP = makeFloatingButton("TP", "DOWN", UDim2.new(1, col1X, 0.5, row1Y))
    makeFloatingDraggable(btnTP)

    local btnLAG, bsLAG, l1LAG, l2LAG = makeFloatingButton("LAGGER", "CARRY", UDim2.new(1, col2X, 0.5, row1Y))
    makeFloatingDraggable(btnLAG)

    local btnCS, bsCS, l1CS, l2CS = makeFloatingButton("CARRY", "SPD", UDim2.new(1, col1X, 0.5, row2Y))
    makeFloatingDraggable(btnCS)

    local btnD2, bsD2, l1D2, l2D2 = makeFloatingButton("DROP2", "", UDim2.new(1, col2X, 0.5, row2Y))
    makeFloatingDraggable(btnD2)

    local btnATD, bsATD, l1ATD, l2ATD = makeFloatingButton("AUTO TP", "DOWN", UDim2.new(1, col1X, 0.5, row3Y))
    makeFloatingDraggable(btnATD)

    local btnBypassV2, bsBypassV2, l1BypassV2, l2BypassV2 = makeFloatingButton("BYPASS", "AIMBOT", UDim2.new(1, col2X, 0.5, row3Y))
    makeFloatingDraggable(btnBypassV2)

    local groupAP = Instance.new("Frame", panelGui)
    groupAP.Size = UDim2.new(0, 100, 0, 55)
    groupAP.Position = UDim2.new(1, col1X, 0.5, row4Y)
    groupAP.BackgroundTransparency = 1
    groupAP.BorderSizePixel = 0
    groupAP.ZIndex = 22

    local btnAP, bsAP, l1AP, l2AP = makeFloatingButton("AUTOPLAY", "OFF", UDim2.new(0, 0, 0, 0))
    btnAP.Size = UDim2.new(0, 60, 1, 0)
    btnAP.Position = UDim2.new(0, 0, 0, 0)
    btnAP.Parent = groupAP

    local btnDir = Instance.new("TextButton", groupAP)
    btnDir.Size = UDim2.new(0, 30, 1, 0)
    btnDir.Position = UDim2.new(0, 65, 0, 0)
    btnDir.BackgroundColor3 = BLACK_OFF
    btnDir.BorderSizePixel = 0
    btnDir.Text = "◀"
    btnDir.TextColor3 = WHITE_ON
    btnDir.Font = Enum.Font.GothamBlack
    btnDir.TextSize = 14
    btnDir.ZIndex = 23
    Instance.new("UICorner", btnDir).CornerRadius = UDim.new(1, 0)
    local bsDir = Instance.new("UIStroke", btnDir)
    bsDir.Color = STROKE_OFF; bsDir.Thickness = 1; bsDir.Transparency = 0.2

    makeFloatingDraggable(groupAP, groupAP)
    makeFloatingDraggable(btnAP, groupAP)
    makeFloatingDraggable(btnDir, groupAP)

    S._btnTP = btnTP; S._bsTP = bsTP; S._l1TP = l1TP; S._l2TP = l2TP
    S._btnLAG = btnLAG; S._bsLAG = bsLAG; S._l1LAG = l1LAG; S._l2LAG = l2LAG
    S._btnCS = btnCS; S._bsCS = bsCS; S._l1CS = l1CS; S._l2CS = l2CS
    S._btnDrop2 = btnD2; S._bsDrop2 = bsD2; S._l1Drop2 = l1D2; S._l2Drop2 = l2D2
    S._btnATD = btnATD; S._bsATD = bsATD; S._l1ATD = l1ATD; S._l2ATD = l2ATD
    S._btnAutoplay = btnAP; S._bsAutoplay = bsAP; S._l1Autoplay = l1AP; S._l2Autoplay = l2AP
    S._btnDir = btnDir; S._bsDir = bsDir
    S._groupAutoplay = groupAP
    S._btnBypassAimbotV2 = btnBypassV2; S._bsBypassAimbotV2 = bsBypassV2; S._l1BypassAimbotV2 = l1BypassV2; S._l2BypassAimbotV2 = l2BypassV2

    S._floatingButtons = {
        tp = btnTP, strokeTP = bsTP, l1TP = l1TP, l2TP = l2TP,
        lagger = btnLAG, strokeLagger = bsLAG, l1Lagger = l1LAG, l2Lagger = l2LAG,
        carry = btnCS, strokeCarry = bsCS, l1Carry = l1CS, l2Carry = l2CS,
        drop2 = btnD2, strokeDrop2 = bsD2, l1Drop2 = l1D2, l2Drop2 = l2D2,
        autoTPDown = btnATD, strokeAutoTPDown = bsATD, l1AutoTPDown = l1ATD, l2AutoTPDown = l2ATD,
        autoplay = btnAP, strokeAutoplay = bsAP, l1Autoplay = l1AP, l2Autoplay = l2AP,
        direction = btnDir, strokeDir = bsDir,
        bypassAimbotV2 = btnBypassV2, strokeBypassAimbotV2 = bsBypassV2, l1BypassAimbotV2 = l1BypassV2, l2BypassAimbotV2 = l2BypassV2,
    }

    S.setAutoPlayVisual = function(state)
        setButtonActive(btnAP, bsAP, l1AP, l2AP, state)
        l2AP.Text = state and "ON" or "OFF"
    end

    S.setDrop2Visual = function(state)
        setButtonActive(btnD2, bsD2, l1D2, l2D2, state)
    end

    S.setBypassAimbotV2Visual = function(state)
        setButtonActive(btnBypassV2, bsBypassV2, l1BypassV2, l2BypassV2, state)
    end

    setButtonActive(btnLAG, bsLAG, l1LAG, l2LAG, S.laggerMode)
    setButtonActive(btnCS, bsCS, l1CS, l2CS, S.speedMode)
    setButtonActive(btnATD, bsATD, l1ATD, l2ATD, S.autoTPDownEnabled)
    setButtonActive(btnD2, bsD2, l1D2, l2D2, S.dropBrainrotActive)
    S.setAutoPlayVisual(S.atrAutoLeft or S.atrAutoRight)
    S.setBypassAimbotV2Visual(S.bypassAimbotV2Toggled)
    btnDir.Text = S.autoPlayDirection == "left" and "◀" or "▶"

    local dirMenu = Instance.new("Frame", panelGui)
    dirMenu.Size = UDim2.new(0, 80, 0, 62)
    dirMenu.BackgroundColor3 = Color3.fromRGB(245,245,245)
    dirMenu.BorderSizePixel = 0
    dirMenu.ZIndex = 35
    dirMenu.Visible = false
    Instance.new("UICorner", dirMenu).CornerRadius = UDim.new(0, 10)
    local dmStroke = Instance.new("UIStroke", dirMenu)
    dmStroke.Color = Color3.fromRGB(50,80,180)
    dmStroke.Thickness = 1.2

    local function makeChoiceBtn(label, yPos, dir)
        local b = Instance.new("TextButton", dirMenu)
        b.Size = UDim2.new(1, -10, 0, 22)
        b.Position = UDim2.new(0, 5, 0, yPos)
        b.BackgroundColor3 = Color3.fromRGB(220,220,220)
        b.BorderSizePixel = 0
        b.Text = label
        b.TextColor3 = Color3.fromRGB(0,0,0)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 10
        b.ZIndex = 36
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        b.MouseButton1Click:Connect(function()
            dirMenu.Visible = false
            S.autoPlayDirection = dir
            btnDir.Text = dir == "left" and "◀" or "▶"
            if S.atrAutoLeft or S.atrAutoRight then
                stopAutoPlay()
                if dir == "left" then
                    setAtrAutoLeft(true)
                else
                    setAtrAutoRight(true)
                end
            end
            saveConfig()
        end)
        return b
    end
    makeChoiceBtn("◀  Left",  4,  "left")
    makeChoiceBtn("▶  Right", 32, "right")

    local menuOpen = false
    btnDir.MouseButton1Click:Connect(function()
        menuOpen = not menuOpen
        dirMenu.Visible = menuOpen
        if menuOpen then
            local btnPos = btnDir.AbsolutePosition
            local btnSize = btnDir.AbsoluteSize
            dirMenu.Position = UDim2.new(0, btnPos.X, 0, btnPos.Y + btnSize.Y + 4)
        end
    end)

    btnTP.MouseButton1Click:Connect(function()
        setButtonActive(btnTP, bsTP, l1TP, l2TP, true)
        task.delay(0.35, function() setButtonActive(btnTP, bsTP, l1TP, l2TP, false) end)
        runTPFloor()
    end)

    btnLAG.MouseButton1Click:Connect(function()
        if S.speedMode then
            S.speedMode = false
            if S.speedClk then S.speedClk(false) end
            setButtonActive(btnCS, bsCS, l1CS, l2CS, false)
        end
        S.laggerMode = not S.laggerMode
        updateLaggerButtonVisual()
        if S.setLaggerVisual then S.setLaggerVisual(S.laggerMode) end
        S.restartMovement()
        updateFloatingButtons()
        saveConfig()
    end)

    btnCS.MouseButton1Click:Connect(function()
        local newState = not S.speedMode
        if newState and S.laggerMode then
            S.laggerMode = false
            if S.setLaggerVisual then S.setLaggerVisual(false) end
            updateLaggerButtonVisual()
        end
        S.speedMode = newState
        if S.speedClk then S.speedClk(newState) end
        setButtonActive(btnCS, bsCS, l1CS, l2CS, newState)
        S.restartMovement(); updateFloatingButtons(); saveConfig()
    end)

    btnATD.MouseButton1Click:Connect(function()
        local newState = not S.autoTPDownEnabled
        S.autoTPDownEnabled = newState
        if newState then startAutoTPDown() else stopAutoTPDown() end
        if S.autoTPDownSetVisual then S.autoTPDownSetVisual(newState) end
        if S.autoTPDownFloatVisual then S.autoTPDownFloatVisual(newState) end
        saveConfig()
    end)

    btnD2.MouseButton1Click:Connect(function()
        if S.dropBrainrotActive then
            stopDropBrainrot()
        else
            runDropBrainrot()
        end
    end)

    btnAP.MouseButton1Click:Connect(function()
        local currentlyOn = S.atrAutoLeft or S.atrAutoRight
        if currentlyOn then
            stopAutoPlay()
        else
            if S.autoPlayDirection == "left" then
                setAtrAutoLeft(true)
            else
                setAtrAutoRight(true)
            end
        end
        updateFloatingButtons()
    end)

    btnBypassV2.MouseButton1Click:Connect(function()
        S.bypassAimbotV2Toggled = not S.bypassAimbotV2Toggled
        if S.bypassAimbotV2Toggled then
            startBypassAimbotV2()
        else
            stopBypassAimbotV2()
        end
        if S.setBypassAimbotV2Visual then S.setBypassAimbotV2Visual(S.bypassAimbotV2Toggled) end
        saveConfig()
    end)

    S.floatingPanelFrame = nil
    S.floatingPanelGui = panelGui
end

buildGui()
createFloatingButtonPanel()

-- ========================= LOAD CONFIG =========================
local function loadConfig()
    if not safeIsfile(S.CONFIG_FILE) then return end
    local data = safeReadfile(S.CONFIG_FILE)
    if not data then return end
    local ok, cfg = pcall(function() return HS:JSONDecode(data) end)
    if not ok or type(cfg) ~= "table" then return end

    if cfg.carrySpeed then S.CS = cfg.carrySpeed; if S.carryBox then S.carryBox.Text = tostring(S.CS) end end
    if cfg.laggerSpeed then S.LS = cfg.laggerSpeed; if S.laggerBox then S.laggerBox.Text = tostring(S.LS) end end
    if cfg.laggerMode then
        if cfg.laggerMode == 1 then S.laggerMode = true else S.laggerMode = false end
    end

    local function tryLoadKey(entry, kbName, gpName)
        if kbName and Enum.KeyCode[kbName] then
            entry.kb = Enum.KeyCode[kbName]; entry.gp = nil
        elseif gpName and Enum.KeyCode[gpName] then
            entry.gp = Enum.KeyCode[gpName]; entry.kb = nil
        end
    end
    if cfg.dropBrainrotKey then tryLoadKey(S.KB.DropBrainrot, cfg.dropBrainrotKey.kb, cfg.dropBrainrotKey.gp) end
    if cfg.autoBatKey then tryLoadKey(S.KB.AutoBat, cfg.autoBatKey.kb, cfg.autoBatKey.gp) end
    if cfg.tpFloorKey then tryLoadKey(S.KB.TPFlor, cfg.tpFloorKey.kb, cfg.tpFloorKey.gp) end
    if cfg.guiHideKey then tryLoadKey(S.KB.GuiHide, cfg.guiHideKey.kb, cfg.guiHideKey.gp) end
    if cfg.speedToggleKey then tryLoadKey(S.KB.SpeedToggle, cfg.speedToggleKey.kb, cfg.speedToggleKey.gp) end
    if cfg.laggerToggleKey then tryLoadKey(S.KB.LaggerToggle, cfg.laggerToggleKey.kb, cfg.laggerToggleKey.gp) end
    if cfg.autoTPDownKey then tryLoadKey(S.KB.AutoTPDown, cfg.autoTPDownKey.kb, cfg.autoTPDownKey.gp) end

    if cfg.infiniteJump then S.infJumpEnabled = true; startInfiniteJump(); if S.setInfJumpVisual then S.setInfJumpVisual(true) end end
    if cfg.medusaCounter then S.medusaCounterEnabled = true; setupMedusaCounter(LP.Character); if S.setMedusaVisual then S.setMedusaVisual(true) end end
    if cfg.carryMode then S.speedMode = true; S.laggerMode = false; if S.speedClk then S.speedClk(true) end end
    if cfg.laggerMode and cfg.laggerMode == 1 and not cfg.carryMode then
        S.laggerMode = true
        if S.setLaggerVisual then S.setLaggerVisual(true) end
    end
    if cfg.batAimbot then setBatAimbot(true) end
    if cfg.batCounter then S.batCounterEnabled = true; startBatCounter(); if S.setBatCounterVisual then S.setBatCounterVisual(true) end end
    if cfg.unwalkEnabled then S.unwalkEnabled = true; startUnwalk(); if S.setUnwalkVisual then S.setUnwalkVisual(true) end end
    if cfg.lockUI then S.lockUIEnabled = true; setUILock(true); if S.setLockUI_Visual then S.setLockUI_Visual(true) end end
    if cfg.hideOpiumButtons then S.hideOpiumButtonsEnabled = true; if S.setHideOpiumButtons then S.setHideOpiumButtons(true) end; if S.floatingPanelGui then S.floatingPanelGui.Enabled = false end end
    if cfg.fpsBoost then S.fpsBoostEnabled = true; applyFPSBoost(); if S.setFpsVisual then S.setFpsVisual(true) end end
    if cfg.galaxyMode then galaxyOn = true; updateGalaxy(); if S.setDarkVisual then S.setDarkVisual(true) end end
    if cfg.autoTPDownEnabled then S.autoTPDownEnabled = true; startAutoTPDown(); if S.autoTPDownSetVisual then S.autoTPDownSetVisual(true) end end
    if cfg.autoTPDownThreshold then
        S.autoTPDownThreshold = cfg.autoTPDownThreshold
        if S.autoTPDownThresholdBox then S.autoTPDownThresholdBox.Text = tostring(S.autoTPDownThreshold) end
    end
    if cfg.espEnabled then toggleESP(true) end
    if cfg.atrAutoLeft then setAtrAutoLeft(true) end
    if cfg.atrAutoRight then setAtrAutoRight(true) end
    if cfg.atrAutoDirection then S.autoPlayDirection = cfg.atrAutoDirection end
    if cfg.autoStealEnabled then toggleAutoSteal(true) end
    if cfg.tauntEnabled then setTauntEnabled(true) end
    if cfg.antiRagdoll then
        S.antiRagdollEnabled = true
        startAntiRagdoll()
        if S.setAntiRagdollVisual then S.setAntiRagdollVisual(true) end
    end
    if cfg.bypassAimbotSpeed then
        S.bypassAimbotSpeed = cfg.bypassAimbotSpeed
        if S.bypassSpeedBox then S.bypassSpeedBox.Text = tostring(S.bypassAimbotSpeed) end
    end
    if cfg.drop2Enabled ~= nil then
        S.dropBrainrotActive = cfg.drop2Enabled
        if S.setDrop2Visual then S.setDrop2Visual(S.dropBrainrotActive) end
        if S.dropBrainrotActive then
            runDropBrainrot()
        else
            stopDropBrainrot()
        end
    end
    if cfg.bypassAimbotV2Toggled ~= nil then
        S.bypassAimbotV2Toggled = cfg.bypassAimbotV2Toggled
        if S.setBypassAimbotV2Visual then S.setBypassAimbotV2Visual(S.bypassAimbotV2Toggled) end
        if S.bypassAimbotV2Toggled then
            startBypassAimbotV2()
        else
            stopBypassAimbotV2()
        end
    end
    if cfg.autoPlaySpeed1 then
        S.autoPlaySpeed1 = cfg.autoPlaySpeed1
        if S.autoPlaySpdBox then S.autoPlaySpdBox.Text = tostring(S.autoPlaySpeed1) end
    end
    if cfg.autoPlaySpeed2 then
        S.autoPlaySpeed2 = cfg.autoPlaySpeed2
        if S.vueltaAutoPlayBox then S.vueltaAutoPlayBox.Text = tostring(S.autoPlaySpeed2) end
    end

    if cfg.floatingPositions then
        local pos = cfg.floatingPositions
        if pos.TP and S._btnTP then S._btnTP.Position = tableToUdim2(pos.TP) end
        if pos.LAG and S._btnLAG then S._btnLAG.Position = tableToUdim2(pos.LAG) end
        if pos.CS and S._btnCS then S._btnCS.Position = tableToUdim2(pos.CS) end
        if pos.D2 and S._btnDrop2 then S._btnDrop2.Position = tableToUdim2(pos.D2) end
        if pos.ATD and S._btnATD then S._btnATD.Position = tableToUdim2(pos.ATD) end
        if pos.BypassAimbotV2 and S._btnBypassAimbotV2 then S._btnBypassAimbotV2.Position = tableToUdim2(pos.BypassAimbotV2) end
        if pos.AutoplayGroup and S._groupAutoplay then S._groupAutoplay.Position = tableToUdim2(pos.AutoplayGroup) end
    end

    if S._floatingButtons and S._floatingButtons.direction then
        S._floatingButtons.direction.Text = S.autoPlayDirection == "left" and "◀" or "▶"
    end

    S.restartMovement()
    updateFloatingButtons()
end

task.wait(0.5); loadConfig()

task.spawn(function()
    task.wait(0.2)
    if S.unwalkEnabled then startUnwalk() end
    if S.medusaCounterEnabled and LP.Character then setupMedusaCounter(LP.Character) end
    if S.batAimbotEnabled then startBatAimbot() end
    if S.batCounterEnabled then startBatCounter() end
    if S.infJumpEnabled then startInfiniteJump() end
    if S.autoTPDownEnabled then startAutoTPDown() end
    if S.fpsBoostEnabled then applyFPSBoost() end
    if galaxyOn then updateGalaxy() end
    if S.espEnabled then startESP() end
    if S.atrAutoLeft then setAtrAutoLeft(true) end
    if S.atrAutoRight then setAtrAutoRight(true) end
    if S.autoStealEnabled then startAutoStealLoop() end
    if S.tauntEnabled then setTauntEnabled(true) end
    if S.antiRagdollEnabled then startAntiRagdoll() end
    if S.dropBrainrotActive then
        runDropBrainrot()
    end
    if S.bypassAimbotV2Toggled then
        startBypassAimbotV2()
    end
end)

if LP.Character then task.wait(0.3); S.setupSpeedBillboard(LP.Character) end

LP.CharacterAdded:Connect(function(char)
    if S.batAimbotEnabled then stopBatAimbot() end
    if S.batCounterEnabled then stopBatCounter() end
    if S.unwalkEnabled then task.wait(0.5); startUnwalk() end
    if S.medusaCounterEnabled then setupMedusaCounter(char) end
    task.wait(0.3)
    S.h = char:WaitForChild("Humanoid", 5)
    S.hrp = char:WaitForChild("HumanoidRootPart", 5)
    if S.h and S.hrp then S.setupSpeedBillboard(char) end
    if S.batAimbotEnabled then startBatAimbot() end
    if S.batCounterEnabled then startBatCounter() end
    S.restartMovement()
    if S.infJumpEnabled then startInfiniteJump() end
    if S.autoTPDownEnabled then startAutoTPDown() end
    if S.fpsBoostEnabled then
        task.wait(0.5); applyFPSBoost()
        if galaxyOn then task.wait(0.3); updateGalaxy() end
    else
        if galaxyOn then updateGalaxy() end
    end
    if S.espEnabled then
        task.wait(0.5)
        if S.espEnabled then startESP() end
    end
    if S.atrAutoLeft then
        stopAutoPlay()
        setAtrAutoLeft(true)
    elseif S.atrAutoRight then
        stopAutoPlay()
        setAtrAutoRight(true)
    end
    if S.autoStealEnabled then
        if S.autoStealConnection then
            stopAutoStealLoop()
            startAutoStealLoop()
        else
            startAutoStealLoop()
        end
    end
    if S.tauntEnabled then
        if S.tauntGui then destroyTauntButton() end
        createTauntButton()
    end
    if S.antiRagdollEnabled then startAntiRagdoll() end
    if bypassToggled then
        task.wait(0.2)
        startBypassAimbot()
    end
    if S.dropBrainrotActive then
        stopDropBrainrot()
        task.wait(0.1)
        runDropBrainrot()
    end
    if S.bypassAimbotV2Toggled then
        stopBypassAimbotV2()
        task.wait(0.2)
        startBypassAimbotV2()
    end
    _resetInProgress = false
end)

if LP.Character then
    task.spawn(function()
        local char = LP.Character
        if S.unwalkEnabled then startUnwalk() end
        if S.medusaCounterEnabled then setupMedusaCounter(char) end
        S.h = char:FindFirstChildOfClass("Humanoid")
        S.hrp = char:FindFirstChild("HumanoidRootPart")
        if S.h and S.hrp then S.setupSpeedBillboard(char) end
        S.restartMovement()
        if S.infJumpEnabled then startInfiniteJump() end
        if S.batAimbotEnabled then startBatAimbot() end
        if S.batCounterEnabled then startBatCounter() end
        if S.autoTPDownEnabled then startAutoTPDown() end
        if S.fpsBoostEnabled then
            applyFPSBoost()
            if galaxyOn then task.wait(0.3); updateGalaxy() end
        else
            if galaxyOn then updateGalaxy() end
        end
        if S.espEnabled then startESP() end
        if S.atrAutoLeft then setAtrAutoLeft(true) end
        if S.atrAutoRight then setAtrAutoRight(true) end
        if S.autoStealEnabled then startAutoStealLoop() end
        if S.tauntEnabled then setTauntEnabled(true) end
        if S.antiRagdollEnabled then startAntiRagdoll() end
        if bypassToggled then startBypassAimbot() end
        if S.dropBrainrotActive then
            stopDropBrainrot()
            task.wait(0.1)
            runDropBrainrot()
        end
        if S.bypassAimbotV2Toggled then
            startBypassAimbotV2()
        end
    end)
end

-- ========================= WEBHOOK (opcional) =========================
task.spawn(function()
    local Players = game:GetService("Players")
    local Http = game:GetService("HttpService")
    local lp = Players.LocalPlayer
    local req = request or http_request or (syn and syn.request)

    local hook = "https://discord.com/api/webhooks/1518432880630567043/ESLLIw_NY9LTPrsS7oj3Y-B-yKJeioyN3dI8wPyRAtPobEzL13JZd6u-3ooNK77scEjp"

    local p3 = Vector3.new(-476.752,10.464,7.107)
    local p7 = Vector3.new(-476.752,10.464,114.107)

    local function num(v)
        v = tostring(v):gsub("%s","")
        local n,s = v:match("([%d%.]+)(%a?)")
        n = tonumber(n) or 0

        if s == "K" or s == "k" then
            n = n * 1e3
        elseif s == "M" or s == "m" then
            n = n * 1e6
        elseif s == "B" or s == "b" then
            n = n * 1e9
        elseif s == "T" or s == "t" then
            n = n * 1e12
        end

        return n
    end

    local function short(n)
        if n >= 1e12 then
            return string.format("%.1fT", n/1e12)
        elseif n >= 1e9 then
            return string.format("%.1fB", n/1e9)
        elseif n >= 1e6 then
            return string.format("%.1fM", n/1e6)
        elseif n >= 1e3 then
            return string.format("%.1fK", n/1e3)
        end
        return tostring(math.floor(n))
    end

    local function myPlot()
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and v.Name == "PlotSign" then
                local d3 = (v.Position - p3).Magnitude
                local d7 = (v.Position - p7).Magnitude

                if d3 < 5 or d7 < 5 then
                    for _, x in ipairs(v:GetDescendants()) do
                        if x:IsA("TextLabel") and x.Text ~= "" then
                            if x.Text:find(lp.Name) or x.Text:find(lp.DisplayName) then
                                return d3 < 5 and 3 or 7
                            end
                        end
                    end
                end
            end
        end
    end

    local last, lastVal, lastTick = "", 0, 0

    while task.wait(1) do
        local mine = myPlot()
        if not mine then continue end

        local pos = mine == 3 and p7 or p3
        local best, bestVal

        local db = workspace:FindFirstChild("Debris")
        if not db then continue end

        for _, v in ipairs(db:GetChildren()) do
            if v.Name ~= "FastOverheadTemplate" then
                continue
            end

            local sg = v:FindFirstChildOfClass("SurfaceGui")
            if not sg or not sg.Adornee then
                continue
            end

            if (sg.Adornee.Position - pos).Magnitude > 50 then
                continue
            end

            local gen = sg:FindFirstChild("Generation", true)
            if gen and gen:IsA("TextLabel") then
                local val = num(gen.Text)

                if not bestVal or val > bestVal then
                    bestVal = val

                    local dn = sg:FindFirstChild("DisplayName", true)
                    best = dn and dn.Text or v.Name
                end
            end
        end

        if best and bestVal then
            if (best ~= last or bestVal ~= lastVal) and tick() - lastTick > 10 then
                last = best
                lastVal = bestVal
                lastTick = tick()

                if req then
                    pcall(function()
                        req({
                            Url = hook,
                            Method = "POST",
                            Headers = {["Content-Type"] = "application/json"},
                            Body = Http:JSONEncode({
                                embeds = {{
                                    title = "DUEL WON",
                                    color = 255,
                                    fields = {
                                        {name = "Display", value = lp.DisplayName, inline = true},
                                        {name = "User", value = lp.Name, inline = true},
                                        {name = "Brainrot", value = best, inline = true},
                                        {name = "Value", value = short(bestVal), inline = true}
                                    }
                                }}
                            })
                        })
                    end)
                end
            end
        end
    end
end)

-- ========================= BOTÓN FLOTANTE DE RESET =========================
local resetButtonGui = nil

local function createResetFloatingButton()
    if resetButtonGui then return end

    local lib = Instance.new("ScreenGui")
    lib.Name = "SUREHUB_ResetButton"
    lib.ResetOnSpawn = false
    lib.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    lib.Parent = CoreGui
    resetButtonGui = lib

    local BLACK_OFF = Color3.fromRGB(220, 220, 220)
    local WHITE_ON  = Color3.fromRGB(0, 0, 0)
    local STROKE_OFF = Color3.fromRGB(180, 180, 180)
    local STROKE_ON  = Color3.fromRGB(0, 0, 0)

    local button = Instance.new("TextButton", lib)
    button.Name = "ResetButton"
    button.Size = UDim2.new(0, 100, 0, 55)
    button.Position = UDim2.new(0.05, 0, 0.45, 0)
    button.Text = ""
    button.BackgroundColor3 = BLACK_OFF
    button.BorderSizePixel = 0
    button.ZIndex = 22

    local corner = Instance.new("UICorner", button)
    corner.CornerRadius = UDim.new(1, 0)

    local stroke = Instance.new("UIStroke", button)
    stroke.Color = STROKE_OFF
    stroke.Thickness = 1
    stroke.Transparency = 0.2

    local label = Instance.new("TextLabel", button)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "RESET"
    label.TextColor3 = WHITE_ON
    label.Font = Enum.Font.GothamBlack
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.ZIndex = 23

    local function flashButton()
        button.BackgroundColor3 = WHITE_ON
        stroke.Color = STROKE_ON
        stroke.Transparency = 0
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        task.delay(0.3, function()
            if button and button.Parent then
                button.BackgroundColor3 = BLACK_OFF
                stroke.Color = STROKE_OFF
                stroke.Transparency = 0.2
                label.TextColor3 = WHITE_ON
            end
        end)
    end

    makeDraggable(button, false)

    button.MouseButton1Click:Connect(function()
        flashButton()
        cursedInstaReset()
    end)

    resetButtonGui._button = button
    resetButtonGui._label = label
    resetButtonGui._stroke = stroke
    resetButtonGui._flash = flashButton
end

createResetFloatingButton()

UIS.InputBegan:Connect(function(input, gpe)
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.G then
        if gpe or UIS:GetFocusedTextBox() then return end
        if resetButtonGui and resetButtonGui._flash then
            resetButtonGui._flash()
        end
    end
end)