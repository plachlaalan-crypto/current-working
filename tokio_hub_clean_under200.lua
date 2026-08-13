function TOKYO_LAUNCH_MAIN()
pcall(function() setfpscap(999) end)
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")
local SoundService   = game:GetService("SoundService")
local Lighting       = game:GetService("Lighting")
local HttpService    = game:GetService("HttpService")
local LocalPlayer    = Players.LocalPlayer
local VisualSetters = {}
local mobileButtonContainer
local apMain
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local NORMAL_SPEED = 60
local CARRY_SPEED  = 30
local LAGGER_SPEED = 15
local FOV_VALUE    = 70
local UI_SCALE     = isMobile and 0.65 or 1.0
local function getMobileOptimized(pcValue, mobileValue)
    return isMobile and mobileValue or pcValue
end
local speedToggled       = false
local fastestStealEnabled = false
local laggerToggled      = false
local autoBatToggled     = false
local hittingCooldown    = false
local fullAutoPlayEnabled = false
local fullAutoPlayConn = nil
local fullAutoPlayLeftEnabled = false
local fullAutoPlayRightEnabled = false
local fullAutoPlayLeftConn = nil
local fullAutoPlayRightConn = nil
local fullAutoLeftSetter = nil
local fullAutoRightSetter = nil
local brainrotReturnLeftEnabled  = false
local brainrotReturnRightEnabled = false
local brainrotReturnCooldown     = false
local lastKnownHealth            = 100
local G_myPlotSide               = nil
local G_myPlotName               = nil
local G_tpAutoEnabled            = false
local G_autoPlayAfterTP          = false
local G_countdownActive          = false
local ultraModeEnabled           = false
local autoSwingEnabled           = false
local batCounterEnabled          = false
local batCounterConn             = nil
local noCamCollisionEnabled      = false
local noCamCollisionConn         = nil
local noCamParts                 = {}
local _antiLagDescConn           = nil
local lastBatSwing               = 0
local BAT_SWING_COOLDOWN         = 0.12
local SPAWN_DETECT_RADIUS        = 40
local COUNTDOWN_TARGET           = 4.9
local SPAWN_Z_RIGHT_THRESHOLD    = 60
local SPAWN_LEFT                 = Vector3.new(-466.429901, 0, 113.553757)
local SPAWN_RIGHT                = Vector3.new(-466.42984,  0, 6.55357218)
local AP_Offsets  = {{x=0,y=0,z=0},{x=0,y=0,z=0},{x=0,y=0,z=0},{x=0,y=0,z=0}}
local APR_Offsets = {{x=0,y=0,z=0},{x=0,y=0,z=0},{x=0,y=0,z=0},{x=0,y=0,z=0}}
local BR_L2 = Vector3.new(-475.5, -3.75, 100.5)
local BR_L3 = Vector3.new(-486.5, -3.75, 100.5)
local BR_R2 = Vector3.new(-475.50, -3.95, 17.55)
local BR_R3 = Vector3.new(-486.76, -3.95, 17.55)
local lastNoclipUpdate = 0
RunService.Stepped:Connect(function()
    local now = tick()
    if now - lastNoclipUpdate < 0.1 then return end
    lastNoclipUpdate = now
    local batTarget = nil
    if autoBatToggled and type(getClosestPlayer) == "function" then
        local ok, t = pcall(getClosestPlayer)
        if ok and t then batTarget = t end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            if autoBatToggled and p == batTarget then continue end
            for _, part in ipairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end
end)
local Keybinds = {
    AutoBat        = Enum.KeyCode.E,
    SpeedToggle    = Enum.KeyCode.Q,
    LaggerToggle   = Enum.KeyCode.R,
    InfiniteJump   = Enum.KeyCode.M,
    UIToggle       = Enum.KeyCode.U,
    DropBrainrot   = Enum.KeyCode.X,
    FloatToggle    = Enum.KeyCode.J,
    FullAutoLeft   = Enum.KeyCode.G,
    FullAutoRight  = Enum.KeyCode.H,
    TPDown         = Enum.KeyCode.F,
    AutoLeft       = Enum.KeyCode.Z,
    AutoRight      = Enum.KeyCode.C,
}
local isStealing     = false
local stealStartTime = nil
local StealData      = {}
local lastStealTick  = 0
local plotCache      = {}
local plotCacheTime  = {}
local cachedPrompts  = {}
local promptCacheTime= 0
local Settings = {
    AutoStealEnabled = false,
    StealRadius      = 8,
    StealDuration    = 0.2,
}
local Values = {
    STEAL_RADIUS         = 8,
    STEAL_DURATION       = 0.2,
    STEAL_COOLDOWN       = 0.1,
    PLOT_CACHE_DURATION  = 2,
    PROMPT_CACHE_REFRESH = 0.15,
    DEFAULT_GRAVITY      = 196.2,
    GalaxyGravityPercent = 70,
    HOP_POWER            = 35,
    HOP_COOLDOWN         = 0.08,
}
local function detectMyPlot()
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil, nil end
    local myName = LocalPlayer.DisplayName or LocalPlayer.Name
    for _, plot in ipairs(plots:GetChildren()) do
        local ok, result = pcall(function()
            local sign = plot:FindFirstChild("PlotSign"); if not sign then return nil end
            local sg = sign:FindFirstChild("SurfaceGui"); if not sg then return nil end
            local fr = sg:FindFirstChild("Frame"); if not fr then return nil end
            local tl = fr:FindFirstChild("TextLabel"); if not tl then return nil end
            if tl.Text:find(myName, 1, true) then
                local spawnObj = plot:FindFirstChild("Spawn")
                if spawnObj then
                    local z = spawnObj.CFrame.Position.Z
                    return z < SPAWN_Z_RIGHT_THRESHOLD and "left" or "right"
                end
            end
            return nil
        end)
        if ok and result then return result, plot.Name end
    end
    return nil, nil
end
local function refreshMyPlotSide()
    local side, plotName = detectMyPlot()
    G_myPlotSide = side; G_myPlotName = plotName
    return side
end
task.spawn(function()
    while true do
        task.wait(2)
        if G_tpAutoEnabled then refreshMyPlotSide() end
    end
end)
task.spawn(function()
    local plots = workspace:WaitForChild("Plots", 30); if not plots then return end
    local myName = LocalPlayer.DisplayName or LocalPlayer.Name
    local function watchPlot(plot)
        pcall(function()
            local tl = plot:WaitForChild("PlotSign",5):WaitForChild("SurfaceGui",5):WaitForChild("Frame",5):WaitForChild("TextLabel",5)
            if not tl then return end
            tl:GetPropertyChangedSignal("Text"):Connect(function() refreshMyPlotSide() end)
            if tl.Text:find(myName, 1, true) then refreshMyPlotSide() end
        end)
    end
    for _, plot in ipairs(plots:GetChildren()) do task.spawn(watchPlot, plot) end
    plots.ChildAdded:Connect(function(plot) task.spawn(watchPlot, plot) end)
end)
local function calculateFastestStealSpeed()
    local char = LocalPlayer.Character; if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return nil end
    local targetPos = nil
    if fullAutoPlayLeftEnabled then
        local pts = {FAP_L1, FAP_L2, FAP_L3, FAP_L4, FAP_L5}
        local phase = FAP_LeftPhase
        if type(phase) ~= "number" or phase < 1 then phase = 1 end
        if phase > 5 then phase = 5 end
        targetPos = pts[phase]
    elseif fullAutoPlayRightEnabled then
        local pts = {FAP_R1, FAP_R2, FAP_R3, FAP_R4, FAP_R5}
        local phase = FAP_RightPhase
        if type(phase) ~= "number" or phase < 1 then phase = 1 end
        if phase > 5 then phase = 5 end
        targetPos = pts[phase]
    else
        return nil
    end
    if not targetPos then return end
    local dist = Vector3.new(targetPos.X - hrp.Position.X, 0, targetPos.Z - hrp.Position.Z).Magnitude
    if dist < 0.1 then return end
    local TARGET_TIME = 1.65
    local requiredSpeed = dist / TARGET_TIME
    requiredSpeed = math.clamp(requiredSpeed, 1, 9999)
    return requiredSpeed
end
RunService.Heartbeat:Connect(function()
    if not fastestStealEnabled then return end
    if not (fullAutoPlayLeftEnabled or fullAutoPlayRightEnabled) then return end
    local char = LocalPlayer.Character; if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    local md = hum.MoveDirection; if md.Magnitude == 0 then return end
    local spd = calculateFastestStealSpeed()
    if spd then hrp.AssemblyLinearVelocity = Vector3.new(md.X * spd, hrp.AssemblyLinearVelocity.Y, md.Z * spd) end
end)
local function syncStealSettings()
    Values.STEAL_RADIUS   = Settings.StealRadius
    Values.STEAL_DURATION = Settings.StealDuration
    Settings.StealRadius  = Values.STEAL_RADIUS
    Settings.StealDuration= Values.STEAL_DURATION
end
local STEAL_COOLDOWN       = Values.STEAL_COOLDOWN
local PLOT_CACHE_DURATION  = Values.PLOT_CACHE_DURATION
local PROMPT_CACHE_REFRESH = Values.PROMPT_CACHE_REFRESH
local Enabled = {
    AntiRagdoll  = false,
    AutoSteal    = false,
    InfiniteJump = false,
    ShinyGraphics= false,
    Optimizer    = false,
    Unwalk       = false,
    RemoveAccessories = false,
}
local Connections          = {}
local originalTransparency = {}
local savedAnimations      = {}
local xrayEnabled = false
local h, hrp, speedLbl
local progressConnection = nil
local gui, main
local speedSwBg, speedSwCircle
local laggerSwBg, laggerSwCircle
local batSwBg, batSwCircle
local waitingForKey = nil
local sideSetters = {}
local dropMobileSetter = nil
local function getHRP()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end
local function isMyPlotByName(plotName)
    local currentTime = tick()
    if plotCache[plotName] and (currentTime - (plotCacheTime[plotName] or 0)) < PLOT_CACHE_DURATION then
        return plotCache[plotName]
    end
    local plots = workspace:FindFirstChild("Plots")
    if not plots then plotCache[plotName]=false; plotCacheTime[plotName]=currentTime; return false end
    local plot = plots:FindFirstChild(plotName)
    if not plot then plotCache[plotName]=false; plotCacheTime[plotName]=currentTime; return false end
    local sign = plot:FindFirstChild("PlotSign")
    if sign then
        local yourBase = sign:FindFirstChild("YourBase")
        if yourBase and yourBase:IsA("BillboardGui") then
            local result = yourBase.Enabled == true
            plotCache[plotName]=result; plotCacheTime[plotName]=currentTime
            return result
        end
    end
    plotCache[plotName]=false; plotCacheTime[plotName]=currentTime
    return false
end
local function findNearestPrompt()
    local char = LocalPlayer.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local currentTime = tick()
    if currentTime - promptCacheTime < PROMPT_CACHE_REFRESH and #cachedPrompts > 0 then
        local nearestPrompt, nearestDist, nearestName = nil, math.huge, nil
        for _, data in ipairs(cachedPrompts) do
            if data.spawn then
                local dist = (data.spawn.Position - root.Position).Magnitude
                if dist <= Settings.StealRadius and dist < nearestDist then
                    nearestPrompt = data.prompt; nearestDist = dist; nearestName = data.name
                end
            end
        end
        if nearestPrompt then return nearestPrompt, nearestDist, nearestName end
    end
    cachedPrompts = {}; promptCacheTime = currentTime
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    local nearestPrompt, nearestDist, nearestName = nil, math.huge, nil
    for _, plot in ipairs(plots:GetChildren()) do
        if isMyPlotByName(plot.Name) then continue end
        local podiums = plot:FindFirstChild("AnimalPodiums")
        if not podiums then continue end
        for _, podium in ipairs(podiums:GetChildren()) do
            pcall(function()
                local base  = podium:FindFirstChild("Base")
                local spawn = base and base:FindFirstChild("Spawn")
                if spawn then
                    local dist = (spawn.Position - root.Position).Magnitude
                    local att = spawn:FindFirstChild("PromptAttachment")
                    if att then
                        for _, ch in ipairs(att:GetChildren()) do
                            if ch:IsA("ProximityPrompt") then
                                table.insert(cachedPrompts, {prompt=ch, spawn=spawn, name=podium.Name})
                                if dist <= Settings.StealRadius and dist < nearestDist then
                                    nearestPrompt=ch; nearestDist=dist; nearestName=podium.Name
                                end
                                break
                            end
                        end
                    end
                end
            end)
        end
    end
    return nearestPrompt, nearestDist, nearestName
end
local ProgressLabel, ProgressPercentLabel, ProgressBarFill, RadiusInput, DurationInput
local pbRadiusLabel, pbDurationLabel
local function ResetProgressBar()
    if ProgressLabel        then ProgressLabel.Text = "READY" end
    if ProgressPercentLabel then ProgressPercentLabel.Text = "" end
    if ProgressBarFill      then ProgressBarFill.Size = UDim2.new(0,0,1,0) end
end
local function executeSteal(prompt, name)
    local currentTime = tick()
    if currentTime - lastStealTick < STEAL_COOLDOWN then return end
    if isStealing then return end
    if not StealData[prompt] then
        StealData[prompt] = {hold={}, trigger={}, ready=true}
        pcall(function()
            if getconnections then
                for _, c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do
                    if c.Function then table.insert(StealData[prompt].hold, c.Function) end
                end
                for _, c in ipairs(getconnections(prompt.Triggered)) do
                    if c.Function then table.insert(StealData[prompt].trigger, c.Function) end
                end
            else StealData[prompt].useFallback = true end
        end)
    end
    local data = StealData[prompt]
    if not data.ready then return end
    data.ready=false; isStealing=true; stealStartTime=currentTime; lastStealTick=currentTime
    if ProgressLabel then ProgressLabel.Text = name or "STEALING..." end
    if progressConnection then progressConnection:Disconnect() end
    progressConnection = RunService.Heartbeat:Connect(function()
        if not isStealing then progressConnection:Disconnect(); return end
        local prog = math.clamp((tick()-stealStartTime)/Settings.StealDuration, 0, 1)
        if ProgressBarFill      then ProgressBarFill.Size = UDim2.new(prog,0,1,0) end
        if ProgressPercentLabel then ProgressPercentLabel.Text = math.floor(prog*100).."%" end
    end)
    task.spawn(function()
        local ok = false
        pcall(function()
            if not data.useFallback then
                for _, f in ipairs(data.hold) do task.spawn(f) end
                task.wait(Settings.StealDuration)
                for _, f in ipairs(data.trigger) do task.spawn(f) end
                ok=true
            end
        end)
        if not ok and fireproximityprompt then
            pcall(function() fireproximityprompt(prompt); ok=true end)
        end
        if not ok then
            pcall(function()
                prompt:InputHoldBegin(); task.wait(Settings.StealDuration); prompt:InputHoldEnd(); ok=true
            end)
        end
        task.wait(Settings.StealDuration * 0.3)
        if progressConnection then progressConnection:Disconnect() end
        ResetProgressBar()
        task.wait(0.05)
        data.ready=true; isStealing=false
    end)
end
local function startAutoSteal()
    if Connections.autoSteal then return end
    Connections.autoSteal = RunService.Heartbeat:Connect(function()
        if not Enabled.AutoSteal or isStealing then return end
        local p,_,n = findNearestPrompt()
        if p then
            local char = LocalPlayer.Character
            local hrpLocal = char and char:FindFirstChild("HumanoidRootPart")
            if hrpLocal then hrpLocal.AssemblyLinearVelocity = Vector3.new(0, hrpLocal.AssemblyLinearVelocity.Y, 0) end
            executeSteal(p,n)
        end
    end)
end
local function stopAutoSteal()
    if Connections.autoSteal then Connections.autoSteal:Disconnect(); Connections.autoSteal=nil end
    isStealing=false; lastStealTick=0
    plotCache={}; plotCacheTime={}; cachedPrompts={}
    ResetProgressBar()
end
local function startAntiRagdoll()
    if Connections.antiRagdoll then return end
    Connections.antiRagdoll = RunService.Heartbeat:Connect(function()
        if not Enabled.AntiRagdoll then return end
        local char = LocalPlayer.Character; if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum  = char:FindFirstChildOfClass("Humanoid")
        if hum then
            local st = hum:GetState()
            if st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown then
                hum:ChangeState(Enum.HumanoidStateType.Running)
                workspace.CurrentCamera.CameraSubject = hum
                pcall(function()
                    local pm = LocalPlayer.PlayerScripts:FindFirstChild("PlayerModule")
                    if pm then require(pm:FindFirstChild("ControlModule")):Enable() end
                end)
                if root then root.Velocity=Vector3.new(0,0,0); root.RotVelocity=Vector3.new(0,0,0) end
            end
        end
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("Motor6D") and not obj.Enabled then obj.Enabled=true end
        end
    end)
end
local function stopAntiRagdoll()
    if Connections.antiRagdoll then Connections.antiRagdoll:Disconnect(); Connections.antiRagdoll=nil end
end
local IJ_JumpConn = nil
local IJ_FallConn = nil
local function startInfiniteJump()
    if IJ_JumpConn then IJ_JumpConn:Disconnect() end
    if IJ_FallConn then IJ_FallConn:Disconnect() end
    IJ_JumpConn = UserInputService.JumpRequest:Connect(function()
        if not Enabled.InfiniteJump then return end
        local char = LocalPlayer.Character; if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then root.Velocity = Vector3.new(root.Velocity.X, 55, root.Velocity.Z) end
    end)
    IJ_FallConn = RunService.Heartbeat:Connect(function()
        if not Enabled.InfiniteJump then return end
        local char = LocalPlayer.Character; if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if root and root.Velocity.Y < -120 then
            root.Velocity = Vector3.new(root.Velocity.X, -120, root.Velocity.Z)
        end
    end)
end
local function stopInfiniteJump()
    if IJ_JumpConn then IJ_JumpConn:Disconnect(); IJ_JumpConn = nil end
    if IJ_FallConn then IJ_FallConn:Disconnect(); IJ_FallConn = nil end
end
local function startUnwalk()
    local c = LocalPlayer.Character; if not c then return end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hum then for _,t in ipairs(hum:GetPlayingAnimationTracks()) do t:Stop() end end
    local anim = c:FindFirstChild("Animate")
    if anim then savedAnimations.Animate=anim:Clone(); anim:Destroy() end
end
local function stopUnwalk()
    local c = LocalPlayer.Character
    if c and savedAnimations.Animate then savedAnimations.Animate:Clone().Parent=c; savedAnimations.Animate=nil end
end
local xrayDescendantConn = nil
local function isXrayTarget(obj)
    if not obj:IsA("BasePart") then return false end
    if not obj.Anchored then return false end
    local n = obj.Name:lower(); local pn = (obj.Parent and obj.Parent.Name:lower()) or ""
    return n:find("base") ~= nil or pn:find("base") ~= nil
end
local function applyXrayToPart(obj)
    pcall(function()
        if isXrayTarget(obj) and originalTransparency[obj] == nil then
            originalTransparency[obj] = obj.LocalTransparencyModifier
            obj.LocalTransparencyModifier = 0.85
        end
    end)
end
local function applyXrayToAll()
    pcall(function() for _, obj in ipairs(workspace:GetDescendants()) do applyXrayToPart(obj) end end)
end
local function startXrayWatcher()
    if xrayDescendantConn then return end
    xrayDescendantConn = workspace.DescendantAdded:Connect(function(obj)
        if not xrayEnabled then return end
        task.defer(function() if xrayEnabled then applyXrayToPart(obj) end end)
    end)
end
local function stopXrayWatcher()
    if xrayDescendantConn then xrayDescendantConn:Disconnect(); xrayDescendantConn=nil end
end
local _antiLagDescConn = nil
local ultraModeEnabled = false
local function applyAntiLag(ultra)
    Lighting.GlobalShadows = false; Lighting.FogEnd = 1e10; Lighting.Brightness = 1
    Lighting.EnvironmentDiffuseScale = 0; Lighting.EnvironmentSpecularScale = 0
    for _, e in pairs(Lighting:GetChildren()) do
        if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect")
            or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then e.Enabled = false end
    end
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.Material = Enum.Material.Plastic; obj.Reflectance = 0
            if ultra then obj.CastShadow = false end
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            if ultra then obj:Destroy() else obj.Transparency = 1 end
        elseif ultra and (obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Fire")) then
            obj.Enabled = false
        end
    end
    if ultra then pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end) end
end
local function enableOptimizer()
    Enabled.Optimizer = true; applyAntiLag(false)
    if _antiLagDescConn then _antiLagDescConn:Disconnect() end
    _antiLagDescConn = workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("BasePart") then obj.Material = Enum.Material.Plastic; obj.Reflectance = 0
        elseif obj:IsA("Decal") or obj:IsA("Texture") then obj.Transparency = 1 end
    end)
end
local function disableOptimizer()
    Enabled.Optimizer = false
    if _antiLagDescConn then _antiLagDescConn:Disconnect(); _antiLagDescConn = nil end
end
local function enableUltraMode() ultraModeEnabled = true; applyAntiLag(true) end
local function disableUltraMode() ultraModeEnabled = false end
local removedAccessories = {}
local function removeAccessories()
    if Enabled.RemoveAccessories then
        local char = LocalPlayer.Character; if not char then return end
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("Accessory") or obj:IsA("Hat") then
                if not removedAccessories[obj] then removedAccessories[obj] = true; obj:Destroy() end
            end
        end
    end
end
local function startRemoveAccessories()
    Enabled.RemoveAccessories = true; removeAccessories()
    if not Connections.removeAccessories then
        Connections.removeAccessories = LocalPlayer.CharacterAdded:Connect(function()
            task.wait(0.5); if Enabled.RemoveAccessories then removeAccessories() end
        end)
    end
end
local function stopRemoveAccessories()
    Enabled.RemoveAccessories = false
    if Connections.removeAccessories then Connections.removeAccessories:Disconnect(); Connections.removeAccessories = nil end
    removedAccessories = {}
end
local dropBrainrotActive = false
local DROP_ASCEND_DURATION = 0.2
local DROP_ASCEND_SPEED = 150
local setDropBrainrotVisual = nil
local function runDropBrainrot()
    if dropBrainrotActive then return end
    local char = LocalPlayer.Character; if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
    dropBrainrotActive = true
    local t0 = tick()
    local dc
    dc = RunService.Heartbeat:Connect(function()
        local r = char and char:FindFirstChild("HumanoidRootPart")
        if not r then
            dc:Disconnect(); dropBrainrotActive = false
            if setDropBrainrotVisual then setDropBrainrotVisual(false) end
            if dropMobileSetter then dropMobileSetter(false) end
            return
        end
        if tick() - t0 >= DROP_ASCEND_DURATION then
            dc:Disconnect()
            local rp = RaycastParams.new(); rp.FilterDescendantsInstances = {char}; rp.FilterType = Enum.RaycastFilterType.Exclude
            local rr = workspace:Raycast(r.Position, Vector3.new(0,-2000,0), rp)
            if rr then
                local hum2 = char:FindFirstChildOfClass("Humanoid")
                local off = (hum2 and hum2.HipHeight or 2) + (r.Size.Y/2)
                r.CFrame = CFrame.new(r.Position.X, rr.Position.Y+off, r.Position.Z)
                r.AssemblyLinearVelocity = Vector3.new(0,0,0)
            end
            dropBrainrotActive = false
            if setDropBrainrotVisual then setDropBrainrotVisual(false) end
            if dropMobileSetter then dropMobileSetter(false) end
            return
        end
        r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, DROP_ASCEND_SPEED, r.AssemblyLinearVelocity.Z)
    end)
end
local floatEnabled = false
local floatHeight  = 9.5
local function enableNoCameraCollision()
    noCamCollisionEnabled = true
    if noCamCollisionConn then noCamCollisionConn:Disconnect() end
    noCamCollisionConn = RunService.RenderStepped:Connect(function()
        if not noCamCollisionEnabled then return end
        local ch = LocalPlayer.Character; if not ch then return end
        local cam = workspace.CurrentCamera; if not cam then return end
        local hrp = ch:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        local camPos  = cam.CFrame.Position
        local charPos = hrp.Position + Vector3.new(0, 1.5, 0)
        local toChar  = charPos - camPos
        local dist    = toChar.Magnitude
        if dist < 0.3 then return end
        local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {ch}; params.IgnoreWater = true
        local hit = {}; local origin = camPos; local remaining = toChar
        for _ = 1, 12 do
            if remaining.Magnitude < 0.2 then break end
            local res = workspace:Raycast(origin, remaining, params); if not res then break end
            local p = res.Instance
            if p and p:IsA("BasePart") and not p:IsDescendantOf(ch) then
                hit[p] = true
                if noCamParts[p] == nil then noCamParts[p] = p.LocalTransparencyModifier end
                p.LocalTransparencyModifier = 1
            end
            origin = res.Position + remaining.Unit * 0.02; remaining = charPos - origin
        end
        for p, orig in pairs(noCamParts) do
            if not hit[p] then
                pcall(function() if p and p.Parent then p.LocalTransparencyModifier = orig end end)
                noCamParts[p] = nil
            end
        end
    end)
end
local function disableNoCameraCollision()
    noCamCollisionEnabled = false
    if noCamCollisionConn then noCamCollisionConn:Disconnect(); noCamCollisionConn = nil end
    for p, orig in pairs(noCamParts) do
        pcall(function() if p and p.Parent then p.LocalTransparencyModifier = orig end end)
    end
    noCamParts = {}
end
local function startFloat()
    if Connections.float then Connections.float:Disconnect() end
    Connections.float = RunService.Heartbeat:Connect(function()
        if not floatEnabled then return end
        local char = LocalPlayer.Character; if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
        local rp = RaycastParams.new(); rp.FilterDescendantsInstances = {char}; rp.FilterType = Enum.RaycastFilterType.Exclude
        local rr = workspace:Raycast(root.Position, Vector3.new(0,-200,0), rp)
        if rr then
            local diff = (rr.Position.Y + floatHeight) - root.Position.Y
            if math.abs(diff) > 0.3 then
                root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, diff*15, root.AssemblyLinearVelocity.Z)
            else
                root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
            end
        end
    end)
end
local function stopFloat()
    if Connections.float then Connections.float:Disconnect(); Connections.float = nil end
    local char = LocalPlayer.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z) end
    end
end
local animHeartbeatConn = nil
local originalAnims = nil
local harderHitAnimEnabled = false
local Anims = {
    idle1="rbxassetid://133806214992291", idle2="rbxassetid://94970088341563",
    walk="rbxassetid://707897309", run="rbxassetid://707861613",
    jump="rbxassetid://116936326516985", fall="rbxassetid://116936326516985",
    climb="rbxassetid://116936326516985", swim="rbxassetid://116936326516985",
    swimidle="rbxassetid://116936326516985",
}
local function saveOriginalAnims(char)
    local animate = char:FindFirstChild("Animate"); if not animate then return end
    local function g(obj) return obj and obj.AnimationId or nil end
    originalAnims = {
        idle1=g(animate.idle and animate.idle.Animation1), idle2=g(animate.idle and animate.idle.Animation2),
        walk=g(animate.walk and animate.walk.WalkAnim), run=g(animate.run and animate.run.RunAnim),
        jump=g(animate.jump and animate.jump.JumpAnim), fall=g(animate.fall and animate.fall.FallAnim),
        climb=g(animate.climb and animate.climb.ClimbAnim), swim=g(animate.swim and animate.swim.Swim),
        swimidle=g(animate.swimidle and animate.swimidle.SwimIdle),
    }
end
local function applyAnimPack(char)
    local animate = char:FindFirstChild("Animate"); if not animate then return end
    local function s(obj, id) if obj then obj.AnimationId = id end end
    s(animate.idle and animate.idle.Animation1, Anims.idle1); s(animate.idle and animate.idle.Animation2, Anims.idle2)
    s(animate.walk and animate.walk.WalkAnim, Anims.walk); s(animate.run and animate.run.RunAnim, Anims.run)
    s(animate.jump and animate.jump.JumpAnim, Anims.jump); s(animate.fall and animate.fall.FallAnim, Anims.fall)
    s(animate.climb and animate.climb.ClimbAnim, Anims.climb); s(animate.swim and animate.swim.Swim, Anims.swim)
    s(animate.swimidle and animate.swimidle.SwimIdle, Anims.swimidle)
end
local function restoreOriginalAnims(char)
    if not originalAnims then return end
    local animate = char:FindFirstChild("Animate"); if not animate then return end
    local function s(obj, id) if obj and id then obj.AnimationId = id end end
    s(animate.idle and animate.idle.Animation1, originalAnims.idle1); s(animate.idle and animate.idle.Animation2, originalAnims.idle2)
    s(animate.walk and animate.walk.WalkAnim, originalAnims.walk); s(animate.run and animate.run.RunAnim, originalAnims.run)
    s(animate.jump and animate.jump.JumpAnim, originalAnims.jump); s(animate.fall and animate.fall.FallAnim, originalAnims.fall)
    s(animate.climb and animate.climb.ClimbAnim, originalAnims.climb); s(animate.swim and animate.swim.Swim, originalAnims.swim)
    s(animate.swimidle and animate.swimidle.SwimIdle, originalAnims.swimidle)
    local hum2 = char:FindFirstChildOfClass("Humanoid")
    if hum2 then for _, t in ipairs(hum2:GetPlayingAnimationTracks()) do t:Stop(0) end end
end
local function startHarderHitAnim()
    if animHeartbeatConn then animHeartbeatConn:Disconnect(); animHeartbeatConn = nil end
    local char = LocalPlayer.Character
    if char then
        saveOriginalAnims(char); applyAnimPack(char)
        local hum2 = char:FindFirstChildOfClass("Humanoid")
        if hum2 then for _, t in ipairs(hum2:GetPlayingAnimationTracks()) do t:Stop(0) end end
    end
    animHeartbeatConn = RunService.Heartbeat:Connect(function()
        if not harderHitAnimEnabled then return end
        local c = LocalPlayer.Character; if c then applyAnimPack(c) end
    end)
end
local function stopHarderHitAnim()
    if animHeartbeatConn then animHeartbeatConn:Disconnect(); animHeartbeatConn = nil end
    local char = LocalPlayer.Character; if char then restoreOriginalAnims(char) end
end
local MEDUSA_COOLDOWN = 25
local medusaLastUsed = 0
local medusaDebounce = false
local medusaCounterEnabled = false
local medusaAnchorConns = {}
local function findMedusa()
    local char = LocalPlayer.Character; if not char then return nil end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local tn = tool.Name:lower()
            if tn:find("medusa") or tn:find("head") or tn:find("stone") then return tool end
        end
    end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") then
                local tn = tool.Name:lower()
                if tn:find("medusa") or tn:find("head") or tn:find("stone") then return tool end
            end
        end
    end
    return nil
end
local function useMedusaCounter()
    if medusaDebounce then return end
    if tick() - medusaLastUsed < MEDUSA_COOLDOWN then return end
    local char = LocalPlayer.Character; if not char then return end
    medusaDebounce = true
    local med = findMedusa(); if not med then medusaDebounce = false; return end
    if med.Parent ~= char then
        local hum2 = char:FindFirstChildOfClass("Humanoid"); if hum2 then hum2:EquipTool(med) end
    end
    pcall(function() med:Activate() end)
    medusaLastUsed = tick(); medusaDebounce = false
end
local function stopMedusaCounter()
    for _, c in pairs(medusaAnchorConns) do pcall(function() c:Disconnect() end) end
    medusaAnchorConns = {}
end
local function setupMedusaCounter(char)
    stopMedusaCounter(); if not char then return end
    local function onAnchorChanged(part)
        return part:GetPropertyChangedSignal("Anchored"):Connect(function()
            if medusaCounterEnabled and part.Anchored and part.Transparency == 1 then useMedusaCounter() end
        end)
    end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then table.insert(medusaAnchorConns, onAnchorChanged(part)) end
    end
    table.insert(medusaAnchorConns, char.DescendantAdded:Connect(function(part)
        if part:IsA("BasePart") then table.insert(medusaAnchorConns, onAnchorChanged(part)) end
    end))
end
local function doReturnTeleport(side)
    if brainrotReturnCooldown then return end
    brainrotReturnCooldown = true
    task.spawn(function()
        pcall(function()
            local c = LocalPlayer.Character; if not c then return end
            local root = c:FindFirstChild("HumanoidRootPart"); local hum = c:FindFirstChildOfClass("Humanoid"); if not root then return end
            local rotation = (side == "right") and math.rad(180) or 0
            local step2 = (side == "right") and BR_R2 or BR_L2
            local step3 = (side == "right") and BR_R3 or BR_L3
            local function tp(pos)
                root.AssemblyLinearVelocity = Vector3.zero; root.AssemblyAngularVelocity = Vector3.zero
                root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) * CFrame.Angles(0, rotation, 0)
                if hum then hum:ChangeState(Enum.HumanoidStateType.Running); hum:Move(Vector3.zero, false) end
                for _, obj in ipairs(c:GetDescendants()) do if obj:IsA("Motor6D") and not obj.Enabled then obj.Enabled = true end end
            end
            tp(step2); task.wait(0.1); tp(step3)
        end)
        local _c = LocalPlayer.Character; local _hum = _c and _c:FindFirstChildOfClass("Humanoid")
        if _hum then lastKnownHealth = _hum.Health end
        brainrotReturnCooldown = false
        if G_autoPlayAfterTP and G_myPlotSide then
            task.wait(0.3); local side = G_myPlotSide
            if fullAutoPlayLeftEnabled then stopFullAutoLeft(); fullAutoPlayLeftEnabled = false; if fullAutoLeftSetter then fullAutoLeftSetter(false) end end
            if fullAutoPlayRightEnabled then stopFullAutoRight(); fullAutoPlayRightEnabled = false; if fullAutoRightSetter then fullAutoRightSetter(false) end end
            task.wait(0.1)
            if side == "left" then
                fullAutoPlayLeftEnabled = true; if fullAutoLeftSetter then fullAutoLeftSetter(true) end; startFullAutoLeft()
                if VisualSetters.FullAuto then VisualSetters.FullAuto(true) end
            elseif side == "right" then
                fullAutoPlayRightEnabled = true; if fullAutoRightSetter then fullAutoRightSetter(true) end; startFullAutoRight()
                if VisualSetters.FullAuto then VisualSetters.FullAuto(true) end
            end
        end
    end)
end
RunService.Heartbeat:Connect(function()
    if not G_tpAutoEnabled then return end
    if brainrotReturnCooldown then return end
    if G_countdownActive then return end
    local char = LocalPlayer.Character; if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp and hrp.Anchored then lastKnownHealth = hum.Health; return end
    local hp = hum.Health; local st = hum:GetState()
    local rag = st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown
    local wasHit = hp < lastKnownHealth - 1; lastKnownHealth = hp
    if not (wasHit or rag) then return end
    if fullAutoPlayLeftEnabled then stopFullAutoLeft(); fullAutoPlayLeftEnabled = false; if fullAutoLeftSetter then fullAutoLeftSetter(false) end end
    if fullAutoPlayRightEnabled then stopFullAutoRight(); fullAutoPlayRightEnabled = false; if fullAutoRightSetter then fullAutoRightSetter(false) end end
    local side = G_myPlotSide
    if side == "left" then doReturnTeleport("left")
    elseif side == "right" then doReturnTeleport("right") end
end)
local function monitorCountdown(snd)
    if snd.Name ~= "Countdown" or not snd:IsA("Sound") then return end
    local triggered, conn = false, nil
    G_countdownActive = true
    conn = RunService.Heartbeat:Connect(function()
        if not snd or not snd.Parent or not snd.Playing then
            G_countdownActive = false; if conn then conn:Disconnect(); conn = nil end; return
        end
        local ct = snd.TimePosition
        if ct >= COUNTDOWN_TARGET and not triggered then
            triggered = true; G_countdownActive = false; if conn then conn:Disconnect(); conn = nil end
            if not G_tpAutoEnabled then return end
            local side = G_myPlotSide; if not side then return end
            if fullAutoPlayLeftEnabled then stopFullAutoLeft(); fullAutoPlayLeftEnabled = false; if fullAutoLeftSetter then fullAutoLeftSetter(false) end end
            if fullAutoPlayRightEnabled then stopFullAutoRight(); fullAutoPlayRightEnabled = false; if fullAutoRightSetter then fullAutoRightSetter(false) end end
            task.wait(0.1)
            if side == "left" then
                fullAutoPlayRightEnabled = true; if fullAutoRightSetter then fullAutoRightSetter(true) end; startFullAutoRight()
                if VisualSetters.FullAuto then VisualSetters.FullAuto(true) end
            elseif side == "right" then
                fullAutoPlayLeftEnabled = true; if fullAutoLeftSetter then fullAutoLeftSetter(true) end; startFullAutoLeft()
                if VisualSetters.FullAuto then VisualSetters.FullAuto(true) end
            end
        end
        if ct > COUNTDOWN_TARGET + 2 then G_countdownActive = false; if conn then conn:Disconnect(); conn = nil end end
    end)
end
workspace.ChildAdded:Connect(function(child)
    if child.Name == "Countdown" and child:IsA("Sound") then monitorCountdown(child) end
end)
do local ex = workspace:FindFirstChild("Countdown"); if ex and ex:IsA("Sound") then monitorCountdown(ex) end end
local FAP_L1 = Vector3.new(-476.48, -6.28, 92.73)
local FAP_L2 = Vector3.new(-482.85, -5.03, 93.13)
local FAP_L3 = Vector3.new(-475.68, -6.89, 92.76)
local FAP_L4 = Vector3.new(-476.50, -6.46, 27.58)
local FAP_L5 = Vector3.new(-482.42, -5.03, 27.84)
local FAP_R1 = Vector3.new(-476.16, -6.52, 25.62)
local FAP_R2 = Vector3.new(-483.06, -5.03, 27.51)
local FAP_R3 = Vector3.new(-476.21, -6.63, 27.46)
local FAP_R4 = Vector3.new(-476.66, -6.39, 92.44)
local FAP_R5 = Vector3.new(-481.94, -5.03, 92.42)
local FACE_FAP_L = Vector3.new(-482.25, -4.96, 92.09)
local FACE_FAP_R = Vector3.new(-482.06, -6.93, 35.47)
local FAP_LeftPhase  = 1
local FAP_RightPhase = 1
local function makeFullAutoPlay(getEnabled, setEnabled, getPhase, setPhase, getConn, setConn, getVisual, getMobSetter, p1, p2, p3, p4, p5, faceTgt)
    local pts = {p1, p2, p3, p4, p5}
    local function stop()
        local c = getConn(); if c then c:Disconnect(); setConn(nil) end
        setPhase(1)
        local char = LocalPlayer.Character
        if char then local hum2 = char:FindFirstChildOfClass("Humanoid"); if hum2 then hum2:Move(Vector3.zero, false) end end
    end
    local function start()
        stop(); setPhase(1)
        setConn(RunService.Heartbeat:Connect(function()
            if not getEnabled() then return end
            local char = LocalPlayer.Character; if not char then return end
            local rp = char:FindFirstChild("HumanoidRootPart"); local hum2 = char:FindFirstChildOfClass("Humanoid")
            if not rp or not hum2 then return end
            local ph = getPhase(); local tgt = pts[ph]; local spd
            if fastestStealEnabled and ph >= 4 then
                local dist = Vector3.new(tgt.X - rp.Position.X, 0, tgt.Z - rp.Position.Z).Magnitude
                if dist > 0.1 then spd = math.clamp(dist / 1.653, 28, 29) else spd = CARRY_SPEED end
            else spd = ph >= 3 and CARRY_SPEED or NORMAL_SPEED end
            if (Vector3.new(tgt.X, rp.Position.Y, tgt.Z) - rp.Position).Magnitude < 1 then
                if ph == 5 then
                    hum2:Move(Vector3.zero, false); rp.AssemblyLinearVelocity = Vector3.zero
                    setEnabled(false); stop()
                    local v = getVisual(); if v then v(false) end
                    local mv = getMobSetter(); if mv then mv(false) end
                    if faceTgt then
                        local dir = Vector3.new(faceTgt.X, rp.Position.Y, faceTgt.Z) - rp.Position
                        if dir.Magnitude > 0.01 then rp.CFrame = CFrame.new(rp.Position, rp.Position + dir.Unit) end
                    end
                    return
                elseif ph == 2 then
                    hum2:Move(Vector3.zero, false); rp.AssemblyLinearVelocity = Vector3.zero
                    task.wait(0.05); setPhase(3); return
                else setPhase(ph + 1); return end
            end
            local d = tgt - rp.Position; local mv = Vector3.new(d.X, 0, d.Z).Unit
            hum2:Move(mv, false); rp.AssemblyLinearVelocity = Vector3.new(mv.X * spd, rp.AssemblyLinearVelocity.Y, mv.Z * spd)
        end))
    end
    return start, stop
end
local startFullAutoLeft, stopFullAutoLeft = makeFullAutoPlay(
    function() return fullAutoPlayLeftEnabled end, function(v) fullAutoPlayLeftEnabled = v end,
    function() return FAP_LeftPhase end, function(v) FAP_LeftPhase = v end,
    function() return fullAutoPlayLeftConn end, function(v) fullAutoPlayLeftConn = v end,
    function() return fullAutoLeftSetter end, function() return nil end,
    FAP_L1, FAP_L2, FAP_L3, FAP_L4, FAP_L5, FACE_FAP_L)
local startFullAutoRight, stopFullAutoRight = makeFullAutoPlay(
    function() return fullAutoPlayRightEnabled end, function(v) fullAutoPlayRightEnabled = v end,
    function() return FAP_RightPhase end, function(v) FAP_RightPhase = v end,
    function() return fullAutoPlayRightConn end, function(v) fullAutoPlayRightConn = v end,
    function() return fullAutoRightSetter end, function() return nil end,
    FAP_R1, FAP_R2, FAP_R3, FAP_R4, FAP_R5, FACE_FAP_R)
local function startFullAutoPlay() end
local function stopFullAutoPlay() end
local autoLeftEnabled  = false
local autoRightEnabled = false
local autoLeftConn     = nil
local autoRightConn    = nil
local autoLeftPhase    = 1
local autoRightPhase   = 1
local autoLeftSetter   = nil
local autoRightSetter  = nil
local SAL_P1 = Vector3.new(-476.48, -6.28, 92.73)
local SAL_P2 = Vector3.new(-482.85, -5.03, 93.13)
local SAR_P1 = Vector3.new(-476.16, -6.52, 25.62)
local SAR_P2 = Vector3.new(-483.06, -5.03, 27.51)
local autoSavedWalkSpeed = nil
local autoInputLockConn  = nil
local autoControlModule  = nil
local function lockPlayerInput()
    local c = LocalPlayer.Character; if not c then return end
    local hum2 = c:FindFirstChildOfClass("Humanoid"); if not hum2 then return end
    if autoSavedWalkSpeed == nil then autoSavedWalkSpeed = hum2.WalkSpeed end
    hum2.WalkSpeed = 0
    if autoInputLockConn then autoInputLockConn:Disconnect(); autoInputLockConn = nil end
end
local function unlockPlayerInput()
    if autoInputLockConn then autoInputLockConn:Disconnect(); autoInputLockConn = nil end
    local c = LocalPlayer.Character
    if c then local hum2 = c:FindFirstChildOfClass("Humanoid"); if hum2 then hum2.WalkSpeed = autoSavedWalkSpeed or NORMAL_SPEED end end
    autoSavedWalkSpeed = nil
end
local function stopAutoLeft()
    if autoLeftConn then autoLeftConn:Disconnect(); autoLeftConn = nil end
    autoLeftPhase = 1; autoLeftEnabled = false
    local c = LocalPlayer.Character
    if c then local hum2 = c:FindFirstChildOfClass("Humanoid"); if hum2 then hum2:Move(Vector3.zero, false) end end
    if not autoRightEnabled then unlockPlayerInput() end
    if autoLeftSetter then autoLeftSetter(false) end
    -- pill setter not called here to avoid recursive loop
end
local function stopAutoRight()
    if autoRightConn then autoRightConn:Disconnect(); autoRightConn = nil end
    autoRightPhase = 1; autoRightEnabled = false
    local c = LocalPlayer.Character
    if c then local hum2 = c:FindFirstChildOfClass("Humanoid"); if hum2 then hum2:Move(Vector3.zero, false) end end
    if not autoLeftEnabled then unlockPlayerInput() end
    if autoRightSetter then autoRightSetter(false) end
    -- pill setter not called here to avoid recursive loop
end
local function startAutoLeft()
    stopAutoLeft(); autoLeftEnabled = true; autoLeftPhase = 1; lockPlayerInput()
    local watchdogId = tick()
    local myId = watchdogId
    autoLeftConn = RunService.Heartbeat:Connect(function()
        if not autoLeftEnabled then return end
        local c = LocalPlayer.Character; if not c then return end
        local rp = c:FindFirstChild("HumanoidRootPart"); local hum2 = c:FindFirstChildOfClass("Humanoid")
        if not rp or not hum2 then return end
        local tgt = autoLeftPhase == 1 and SAL_P1 or SAL_P2
        local d = Vector3.new(tgt.X - rp.Position.X, 0, tgt.Z - rp.Position.Z)
        if d.Magnitude < 1.2 then
            if autoLeftPhase == 1 then autoLeftPhase = 2
            else rp.AssemblyLinearVelocity = Vector3.new(0, rp.AssemblyLinearVelocity.Y, 0); stopAutoLeft(); if autoLeftSetter then autoLeftSetter(false) end end
            return
        end
        local mv = d.Unit
        rp.AssemblyLinearVelocity = Vector3.new(mv.X * NORMAL_SPEED, rp.AssemblyLinearVelocity.Y, mv.Z * NORMAL_SPEED)
    end)
    -- Watchdog: if character gets stuck (velocity killed externally), re-kick it
    task.spawn(function()
        while autoLeftEnabled and myId == watchdogId do
            task.wait(0.6)
            if not autoLeftEnabled or myId ~= watchdogId then break end
            local c = LocalPlayer.Character
            local rp = c and c:FindFirstChild("HumanoidRootPart")
            if rp then
                local spd = Vector3.new(rp.AssemblyLinearVelocity.X, 0, rp.AssemblyLinearVelocity.Z).Magnitude
                if spd < 2 then
                    local tgt = autoLeftPhase == 1 and SAL_P1 or SAL_P2
                    local d = Vector3.new(tgt.X - rp.Position.X, 0, tgt.Z - rp.Position.Z)
                    if d.Magnitude > 1.2 then
                        rp.AssemblyLinearVelocity = Vector3.new(d.Unit.X * NORMAL_SPEED, rp.AssemblyLinearVelocity.Y, d.Unit.Z * NORMAL_SPEED)
                    end
                end
            end
        end
    end)
end
local function startAutoRight()
    stopAutoRight(); autoRightEnabled = true; autoRightPhase = 1; lockPlayerInput()
    local myId = tick()
    local watchdogId = myId
    autoRightConn = RunService.Heartbeat:Connect(function()
        if not autoRightEnabled then return end
        local c = LocalPlayer.Character; if not c then return end
        local rp = c:FindFirstChild("HumanoidRootPart"); local hum2 = c:FindFirstChildOfClass("Humanoid")
        if not rp or not hum2 then return end
        local tgt = autoRightPhase == 1 and SAR_P1 or SAR_P2
        local d = Vector3.new(tgt.X - rp.Position.X, 0, tgt.Z - rp.Position.Z)
        if d.Magnitude < 1.2 then
            if autoRightPhase == 1 then autoRightPhase = 2
            else rp.AssemblyLinearVelocity = Vector3.new(0, rp.AssemblyLinearVelocity.Y, 0); stopAutoRight(); if autoRightSetter then autoRightSetter(false) end end
            return
        end
        local mv = d.Unit
        rp.AssemblyLinearVelocity = Vector3.new(mv.X * NORMAL_SPEED, rp.AssemblyLinearVelocity.Y, mv.Z * NORMAL_SPEED)
    end)
    -- Watchdog: if character gets stuck (velocity killed externally), re-kick it
    task.spawn(function()
        while autoRightEnabled and myId == watchdogId do
            task.wait(0.6)
            if not autoRightEnabled or myId ~= watchdogId then break end
            local c = LocalPlayer.Character
            local rp = c and c:FindFirstChild("HumanoidRootPart")
            if rp then
                local spd = Vector3.new(rp.AssemblyLinearVelocity.X, 0, rp.AssemblyLinearVelocity.Z).Magnitude
                if spd < 2 then
                    local tgt = autoRightPhase == 1 and SAR_P1 or SAR_P2
                    local d = Vector3.new(tgt.X - rp.Position.X, 0, tgt.Z - rp.Position.Z)
                    if d.Magnitude > 1.2 then
                        rp.AssemblyLinearVelocity = Vector3.new(d.Unit.X * NORMAL_SPEED, rp.AssemblyLinearVelocity.Y, d.Unit.Z * NORMAL_SPEED)
                    end
                end
            end
        end
    end)
end
local SAFE_DELAY = 0.08
local function getBat()
    local char = LocalPlayer.Character; if not char then return nil end
    local tool = char:FindFirstChild("Bat"); if tool then return tool end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then tool=bp:FindFirstChild("Bat"); if tool then tool.Parent=char; return tool end end
    return nil
end
local function getClosestPlayer()
    local c = LocalPlayer.Character; if not c then return nil end
    local hrp = c:FindFirstChild("HumanoidRootPart"); if not hrp then return nil end
    local cp, cd = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local tr = p.Character:FindFirstChild("HumanoidRootPart")
            if tr then local d = (hrp.Position - tr.Position).Magnitude; if d < cd then cd = d; cp = p end end
        end
    end
    return cp
end
local function findBat()
    local c = LocalPlayer.Character; if not c then return nil end
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    local SlapList = {"Bat","Slap","Iron Slap","Gold Slap","Diamond Slap","Emerald Slap","Ruby Slap","Dark Matter Slap","Flame Slap","Nuclear Slap","Galaxy Slap","Glitched Slap"}
    for _, name in ipairs(SlapList) do
        local t = c:FindFirstChild(name) or (bp and bp:FindFirstChild(name)); if t then return t end
    end
    for _, ch in ipairs(c:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end
    if bp then for _, ch in ipairs(bp:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end end
    return nil
end
local _aimbotConn = nil
local _aimbotLockedTarget = nil
local BAT_ENGAGE_RANGE    = 2      -- swing when this close (studs)
local AIMBOT_SPEED        = 120    -- base horizontal chase speed
local AIMBOT_SPEED_MAX    = 300    -- cap on scaled chase speed
local MELEE_OFFSET        = 0      -- stand exactly on the target
local VERTICAL_SNAP_VEL   = -200   -- downward Y velocity to apply when target drops fast
local VERTICAL_SNAP_THRESHOLD = -60 -- target Y velocity below this triggers snap
local aimbotHighlight = Instance.new("Highlight")
aimbotHighlight.Name = "BatAimbotESP"
aimbotHighlight.FillColor = Color3.fromRGB(255, 182, 210)
aimbotHighlight.OutlineColor = Color3.fromRGB(255, 220, 235)
aimbotHighlight.FillTransparency = 0.5
aimbotHighlight.OutlineTransparency = 0
pcall(function() aimbotHighlight.Parent = LocalPlayer:WaitForChild("PlayerGui") end)
local function isTargetValid(targetChar)
    if not targetChar then return false end
    local hum2 = targetChar:FindFirstChildOfClass("Humanoid")
    local hrp2 = targetChar:FindFirstChild("HumanoidRootPart")
    local ff = targetChar:FindFirstChildOfClass("ForceField")
    return hum2 and hrp2 and hum2.Health > 0 and not ff
end
local function getBestAimbotTarget(myHRP)
    if _aimbotLockedTarget and isTargetValid(_aimbotLockedTarget) then
        return _aimbotLockedTarget:FindFirstChild("HumanoidRootPart"), _aimbotLockedTarget
    end
    local shortestDist, newTargetChar, newTargetHRP = math.huge, nil, nil
    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        if targetPlayer ~= LocalPlayer and isTargetValid(targetPlayer.Character) then
            local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            local distance = (targetHRP.Position - myHRP.Position).Magnitude
            if distance < shortestDist then
                shortestDist = distance; newTargetHRP = targetHRP; newTargetChar = targetPlayer.Character
            end
        end
    end
    _aimbotLockedTarget = newTargetChar
    return newTargetHRP, newTargetChar
end
local function startBatAimbotInternal()
    if _aimbotConn then return end
    local c = LocalPlayer.Character; if not c then return end
    local h = c:FindFirstChild("HumanoidRootPart")
    local hm = c:FindFirstChildOfClass("Humanoid")
    if not h or not hm then return end
    pcall(function() hm.AutoRotate = false end)
    local attachment = h:FindFirstChild("AimbotAttachment") or Instance.new("Attachment", h)
    attachment.Name = "AimbotAttachment"
    local align = h:FindFirstChild("AimbotAlign") or Instance.new("AlignOrientation", h)
    align.Name = "AimbotAlign"
    align.Mode = Enum.OrientationAlignmentMode.OneAttachment
    align.Attachment0 = attachment
    align.MaxTorque = math.huge
    align.Responsiveness = 200
    _aimbotConn = RunService.Heartbeat:Connect(function()
        if not autoBatToggled then return end
        local c2 = LocalPlayer.Character; if not c2 then return end
        local h2 = c2:FindFirstChild("HumanoidRootPart"); if not h2 then return end
        local hm2 = c2:FindFirstChildOfClass("Humanoid")
        local bat = findBat()
        if bat and bat.Parent ~= c2 then pcall(function() hm2:EquipTool(bat) end) end
        local targetHRP, targetChar = getBestAimbotTarget(h2)
        if targetHRP and targetChar then
            aimbotHighlight.Adornee = targetChar
            local targetVel = targetHRP.AssemblyLinearVelocity
            -- Predict where target will be a tiny moment ahead
            local hSpeed = Vector3.new(targetVel.X, 0, targetVel.Z).Magnitude
            local predictTime = math.clamp(hSpeed / 200, 0.02, 0.12)
            local predictedPos = targetHRP.Position + (targetVel * predictTime)
            -- Direction and distance in 3D (including vertical)
            local dir3D = predictedPos - h2.Position
            local dist3D = dir3D.Magnitude
            -- Stand right on top of the target (MELEE_OFFSET = 0)
            local standPos = predictedPos
            if dist3D > 0.01 then standPos = predictedPos - (dir3D.Unit * MELEE_OFFSET) end
            -- Face the target
            align.CFrame = CFrame.lookAt(h2.Position, predictedPos)
            -- ── HORIZONTAL chase ──────────────────────────────────
            local hDelta = standPos - h2.Position
            local hDist  = Vector3.new(hDelta.X, 0, hDelta.Z).Magnitude
            -- Scale speed up when far, but always aggressive
            local chaseSpeed = math.clamp(AIMBOT_SPEED + hDist * 4, AIMBOT_SPEED, AIMBOT_SPEED_MAX)
            local hDir = Vector3.new(hDelta.X, 0, hDelta.Z)
            -- ── VERTICAL tracking ─────────────────────────────────
            local targetYVel = targetVel.Y
            local myYVel
            if targetYVel <= VERTICAL_SNAP_THRESHOLD then
                -- Target is dropping super fast (TP down / big fall) — snap down instantly
                -- Match their downward speed plus extra to stay on them
                myYVel = math.min(targetYVel * 1.4, VERTICAL_SNAP_VEL)
            else
                -- Normal vertical: mirror target Y so we rise/fall with them
                local yDiff = predictedPos.Y - h2.Position.Y
                if math.abs(yDiff) > 1 then
                    -- Proportional vertical push to close vertical gap quickly
                    myYVel = math.clamp(yDiff * 12 + targetYVel, -350, 350)
                else
                    myYVel = targetYVel
                end
            end
            -- Apply final velocity
            if hDist > 0.5 then
                local hUnit = hDir.Unit
                h2.AssemblyLinearVelocity = Vector3.new(hUnit.X * chaseSpeed, myYVel, hUnit.Z * chaseSpeed)
            else
                -- Already on top horizontally — just match their full velocity
                h2.AssemblyLinearVelocity = Vector3.new(targetVel.X, myYVel, targetVel.Z)
            end
            -- Swing when in melee range (3D distance)
            if dist3D <= BAT_ENGAGE_RANGE then
                if bat and bat.Parent == c2 then
                    if autoSwingEnabled then pcall(function() bat:Activate() end) end
                end
            end
        else
            _aimbotLockedTarget = nil
            h2.AssemblyLinearVelocity = Vector3.new(0, h2.AssemblyLinearVelocity.Y, 0)
            aimbotHighlight.Adornee = nil
        end
    end)
end
local function stopBatAimbotInternal()
    if _aimbotConn then _aimbotConn:Disconnect(); _aimbotConn = nil end
    local c = LocalPlayer.Character
    local h = c and c:FindFirstChild("HumanoidRootPart")
    local hm = c and c:FindFirstChildOfClass("Humanoid")
    if h then
        local att = h:FindFirstChild("AimbotAttachment"); if att then att:Destroy() end
        local al = h:FindFirstChild("AimbotAlign"); if al then al:Destroy() end
        h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0)
    end
    if hm then pcall(function() hm.AutoRotate = true end) end
    _aimbotLockedTarget = nil
    aimbotHighlight.Adornee = nil
end
local function startBatCounter()
    if batCounterConn then return end
    batCounterConn = RunService.Heartbeat:Connect(function()
        if not batCounterEnabled then return end
        local char = LocalPlayer.Character; if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
        local st = hum:GetState()
        local isRagdolled = st == Enum.HumanoidStateType.Physics
            or st == Enum.HumanoidStateType.Ragdoll
            or st == Enum.HumanoidStateType.FallingDown
        if isRagdolled then
            task.spawn(function()
                local bat = findBat(); if not bat then return end
                if bat.Parent ~= char then
                    local hum2 = char:FindFirstChildOfClass("Humanoid")
                    if hum2 then pcall(function() hum2:EquipTool(bat) end) end
                end
                pcall(function() bat:Activate() end)
                task.wait(0.15)
                pcall(function() bat:Activate() end)
            end)
            task.wait(0.5) -- cooldown so it doesn't fire every frame
        end
    end)
end
local function stopBatCounter()
    if batCounterConn then batCounterConn:Disconnect(); batCounterConn = nil end
end
RunService.Heartbeat:Connect(function()
    if autoBatToggled and not _aimbotConn then
        startBatAimbotInternal()
    elseif not autoBatToggled and _aimbotConn then
        stopBatAimbotInternal()
    end
end)
local function runTPDown()
    local wasFloating = floatEnabled
    if wasFloating then stopFloat() end
    task.spawn(function()
        pcall(function()
            local c = LocalPlayer.Character; if not c then return end
            local hrp = c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
            local hum = c:FindFirstChildOfClass("Humanoid"); if not hum then return end
            local rp = RaycastParams.new(); rp.FilterDescendantsInstances = {c}; rp.FilterType = Enum.RaycastFilterType.Exclude
            local hit = workspace:Raycast(hrp.Position, Vector3.new(0,-500,0), rp)
            if hit then
                hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero
                local hh = hum.HipHeight or 2; local hy = hrp.Size.Y / 2
                hrp.CFrame = CFrame.new(hit.Position.X, hit.Position.Y + hh + hy + 0.1, hit.Position.Z)
                hrp.AssemblyLinearVelocity = Vector3.zero
            end
        end)
        task.wait(0.1)
        if wasFloating then startFloat() end
        if VisualSetters and VisualSetters.TPDownReset then VisualSetters.TPDownReset() end
    end)
end
;(function()
local ESP_Enabled    = false
local Tracer_Enabled = false
local ESP_Color      = Color3.fromRGB(255, 182, 210)
local Tracer_Color   = Color3.fromRGB(255, 182, 210)
local ESPObjects     = {}
local ESPReady       = false
local function GetHealthColor(pct)
    pct = math.clamp(pct, 0, 1)
    return Color3.fromRGB(math.floor(255*(1-pct)), math.floor(255*pct), 0)
end
local function CreateESP(player)
    local data = {}; local lines = {}
    for i = 1, 4 do
        local l = Drawing.new("Line"); l.Color = ESP_Color; l.Thickness = 1.5; l.Transparency = 1; l.Visible = false; lines[i] = l
    end
    local healthBG = Drawing.new("Line"); healthBG.Color = Color3.fromRGB(18, 18, 18); healthBG.Thickness = 4; healthBG.Transparency = 1; healthBG.Visible = false
    local healthFG = Drawing.new("Line"); healthFG.Color = Color3.fromRGB(0,255,0); healthFG.Thickness = 2.5; healthFG.Transparency = 1; healthFG.Visible = false
    local distText = Drawing.new("Text"); distText.Color = ESP_Color; distText.Size = 11; distText.Center = false
    distText.Outline = true; distText.Font = Drawing.Fonts.Plex; distText.Visible = false
    local tracer = Drawing.new("Line"); tracer.Color = Tracer_Color; tracer.Thickness = 1.5; tracer.Transparency = 1; tracer.Visible = false
    -- Outline-only box (no fill quad — we use 4 Line segments only)
    data.Lines = lines; data.HealthBG = healthBG; data.HealthFG = healthFG; data.DistText = distText; data.TracerLine = tracer; data.Player = player
    return data
end
local function RemoveESP(player)
    if not ESPObjects[player] then return end
    local d = ESPObjects[player]; if type(d) ~= "table" then ESPObjects[player] = nil; return end
    for _, l in pairs(d.Lines) do pcall(function() l:Remove() end) end
    pcall(function() d.HealthBG:Remove() end); pcall(function() d.HealthFG:Remove() end)
    pcall(function() d.DistText:Remove() end); pcall(function() d.TracerLine:Remove() end)
    ESPObjects[player] = nil
end
local function AddPlayer(player)
    if player == LocalPlayer then return end
    if ESPReady then
        if not ESPObjects[player] or type(ESPObjects[player]) ~= "table" then ESPObjects[player] = CreateESP(player) end
    else ESPObjects[player] = true end
end
_G.EmsaSetESP = function(state)
    ESP_Enabled = state; _G.EmsaESPEnabled = state
    if not state then
        for _, data in pairs(ESPObjects) do
            if type(data) == "table" then
                for _, l in pairs(data.Lines) do l.Visible = false end
                data.HealthBG.Visible = false; data.HealthFG.Visible = false; data.DistText.Visible = false
            end
        end
    end
end
_G.EmsaSetTracer = function(state)
    Tracer_Enabled = state; _G.EmsaTracerEnabled = state
    if not state then for _, data in pairs(ESPObjects) do if type(data) == "table" then data.TracerLine.Visible = false end end end
end
_G.EmsaAddESPPlayer = AddPlayer
for _, p in pairs(Players:GetPlayers()) do AddPlayer(p) end
Players.PlayerAdded:Connect(AddPlayer); Players.PlayerRemoving:Connect(RemoveESP)
Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function() task.wait(0.5); AddPlayer(p) end) end)
for _, p in pairs(Players:GetPlayers()) do p.CharacterAdded:Connect(function() task.wait(0.5); AddPlayer(p) end) end
task.spawn(function()
    local timeout = tick() + 10
    repeat task.wait(0.1)
    until pcall(function() local t = Drawing.new("Line"); t:Remove() end) or tick() > timeout
    if tick() > timeout then warn("ESP: Drawing API not available"); return end
    ESPReady = true
    for player, val in pairs(ESPObjects) do
        if player ~= LocalPlayer and (val == true or type(val) ~= "table") then ESPObjects[player] = CreateESP(player) end
    end
    local function GetBoundingBox(character)
        local root = character:FindFirstChild("HumanoidRootPart"); local head = character:FindFirstChild("Head")
        if not root or not head then return nil end
        local Camera = workspace.CurrentCamera
        local topWorld = Vector3.new(root.Position.X, head.Position.Y + 0.5, root.Position.Z)
        local bottomWorld = Vector3.new(root.Position.X, root.Position.Y - 3, root.Position.Z)
        local topScreen, topOn = Camera:WorldToViewportPoint(topWorld)
        local bottomScreen, bottomOn = Camera:WorldToViewportPoint(bottomWorld)
        if not topOn and not bottomOn then return nil end
        local height = math.abs(topScreen.Y - bottomScreen.Y); local width = height * 0.5; local cx = topScreen.X
        local top = topScreen.Y; local bottom = bottomScreen.Y; local left = cx - width / 2; local right = cx + width / 2
        return {topLeft=Vector2.new(left,top), topRight=Vector2.new(right,top),
            bottomLeft=Vector2.new(left,bottom), bottomRight=Vector2.new(right,bottom),
            cx=cx, top=top, bottom=bottom, left=left, right=right, height=height}
    end
    RunService.RenderStepped:Connect(function()
        local cam = workspace.CurrentCamera; if not cam then return end
        local vp = cam.ViewportSize
        for player, data in pairs(ESPObjects) do
            if type(data) ~= "table" then continue end
            local char = player.Character; local root = char and char:FindFirstChild("HumanoidRootPart")
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            local alive = root and humanoid and humanoid.Health > 0
            if alive then
                local box = GetBoundingBox(char); local _, onScreen = cam:WorldToViewportPoint(root.Position)
                if ESP_Enabled and box and onScreen then
                    local L = data.Lines
                    L[1].From=box.topLeft; L[1].To=box.topRight; L[1].Visible=true; L[1].Color=ESP_Color
                    L[2].From=box.bottomLeft; L[2].To=box.bottomRight; L[2].Visible=true; L[2].Color=ESP_Color
                    L[3].From=box.topLeft; L[3].To=box.bottomLeft; L[3].Visible=true; L[3].Color=ESP_Color
                    L[4].From=box.topRight; L[4].To=box.bottomRight; L[4].Visible=true; L[4].Color=ESP_Color
                    local hpPct = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                    local barX = box.left - 6
                    data.HealthBG.From=Vector2.new(barX,box.top); data.HealthBG.To=Vector2.new(barX,box.bottom); data.HealthBG.Visible=true
                    local filledY = box.bottom - (box.height * hpPct)
                    data.HealthFG.From=Vector2.new(barX,filledY); data.HealthFG.To=Vector2.new(barX,box.bottom)
                    data.HealthFG.Color=GetHealthColor(hpPct); data.HealthFG.Visible=true
                    local dist = math.floor((cam.CFrame.Position - root.Position).Magnitude)
                    local midY = box.top + (box.height / 2) - 6
                    data.DistText.Position=Vector2.new(box.right+5, midY); data.DistText.Text=dist.."m"
                    data.DistText.Color=ESP_Color; data.DistText.Visible=true
                else
                    for _, l in pairs(data.Lines) do l.Visible=false end
                    data.HealthBG.Visible=false; data.HealthFG.Visible=false; data.DistText.Visible=false
                end
                if Tracer_Enabled and onScreen then
                    local sp, _ = cam:WorldToViewportPoint(root.Position)
                    data.TracerLine.From=Vector2.new(vp.X/2, vp.Y); data.TracerLine.To=Vector2.new(sp.X, sp.Y)
                    data.TracerLine.Color=Tracer_Color; data.TracerLine.Visible=true
                else data.TracerLine.Visible=false end
            else
                for _, l in pairs(data.Lines or {}) do l.Visible=false end
                if data.HealthBG then data.HealthBG.Visible=false end
                if data.HealthFG then data.HealthFG.Visible=false end
                if data.DistText then data.DistText.Visible=false end
                if data.TracerLine then data.TracerLine.Visible=false end
            end
        end
    end)
end)
end)()
;(function()
task.spawn(function()
repeat task.wait(0.05) until LocalPlayer:FindFirstChildOfClass("PlayerGui")
local tweenCache = {}
local function getTween(obj, info, props)
    local key = tostring(obj)
    if tweenCache[key] then tweenCache[key]:Cancel() end
    tweenCache[key] = TweenService:Create(obj, info, props)
    return tweenCache[key]
end
local CONFIG_FILE = "tokyo_config.json"
local function saveConfig()
    local config = {
        -- Speeds & values
        NORMAL_SPEED        = NORMAL_SPEED,
        CARRY_SPEED         = CARRY_SPEED,
        LAGGER_SPEED        = LAGGER_SPEED,
        FOV_VALUE           = FOV_VALUE,
        floatHeight         = floatHeight,
        StealRadius         = Settings.StealRadius,
        StealDuration       = Settings.StealDuration,
        -- Window positions
        mainPosX            = main and main.Position.X.Offset or 10,
        mainPosY            = main and main.Position.Y.Offset or 10,
        radiusPosX          = progressBar and progressBar.Position.X.Offset or nil,
        radiusPosY          = progressBar and progressBar.Position.Y.Offset or nil,
        -- Gameplay toggles
        speedToggled        = speedToggled,
        laggerToggled       = laggerToggled,
        autoBatToggled      = autoBatToggled,
        ultraModeEnabled    = ultraModeEnabled,
        fastestStealEnabled = fastestStealEnabled,
        autoSwingEnabled    = autoSwingEnabled,
        medusaCounterEnabled= medusaCounterEnabled,
        floatEnabled        = floatEnabled,
        noCamCollisionEnabled = noCamCollisionEnabled,
        xrayEnabled         = xrayEnabled,
        ESPEnabled          = _G.EmsaESPEnabled or false,
        TracerEnabled       = _G.EmsaTracerEnabled or false,
        -- Enabled table (Anti Ragdoll, Auto Steal, Infinite Jump, etc.)
        Enabled = {
            AntiRagdoll       = Enabled.AntiRagdoll,
            AutoSteal         = Enabled.AutoSteal,
            InfiniteJump      = Enabled.InfiniteJump,
            ShinyGraphics     = Enabled.ShinyGraphics,
            Optimizer         = Enabled.Optimizer,
            Unwalk            = Enabled.Unwalk,
            RemoveAccessories = Enabled.RemoveAccessories,
        },
        -- Keybinds
        Keybinds = {
            AutoBat      = Keybinds.AutoBat.Name,
            SpeedToggle  = Keybinds.SpeedToggle.Name,
            LaggerToggle = Keybinds.LaggerToggle.Name,
            InfiniteJump = Keybinds.InfiniteJump.Name,
            UIToggle     = Keybinds.UIToggle.Name,
            DropBrainrot = Keybinds.DropBrainrot.Name,
            FloatToggle  = Keybinds.FloatToggle.Name,
            FullAutoLeft = Keybinds.FullAutoLeft.Name,
            FullAutoRight= Keybinds.FullAutoRight.Name,
            TPDown       = Keybinds.TPDown.Name,
            AutoLeft     = Keybinds.AutoLeft.Name,
            AutoRight    = Keybinds.AutoRight.Name,
        },
    }
    local ok = pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(config))
    end)
    return ok
end
local function loadConfig()
    local ok, data = pcall(function()
        if not isfile(CONFIG_FILE) then return nil end
        return HttpService:JSONDecode(readfile(CONFIG_FILE))
    end)
    if not ok or not data then return end
    -- Speeds & values
    if data.NORMAL_SPEED         then NORMAL_SPEED         = data.NORMAL_SPEED         end
    if data.CARRY_SPEED          then CARRY_SPEED          = data.CARRY_SPEED          end
    if data.LAGGER_SPEED         then LAGGER_SPEED         = data.LAGGER_SPEED         end
    if data.FOV_VALUE            then FOV_VALUE            = data.FOV_VALUE            end
    if data.floatHeight          then floatHeight          = data.floatHeight          end
    if data.StealRadius          then Settings.StealRadius   = data.StealRadius;  Values.STEAL_RADIUS   = data.StealRadius   end
    if data.StealDuration        then Settings.StealDuration = data.StealDuration; Values.STEAL_DURATION = data.StealDuration end
    -- Window positions stored for application after GUI frames are created
    if data.mainPosX ~= nil and data.mainPosY ~= nil then
        _savedMainPos = {x = data.mainPosX, y = data.mainPosY}
    end
    if data.radiusPosX ~= nil and data.radiusPosY ~= nil then
        _savedRadiusPos = {x = data.radiusPosX, y = data.radiusPosY}
    end
    -- Gameplay toggles
    if data.speedToggled         ~= nil then speedToggled         = data.speedToggled         end
    if data.laggerToggled        ~= nil then laggerToggled        = data.laggerToggled        end
    if data.autoBatToggled       ~= nil then autoBatToggled       = data.autoBatToggled       end
    if data.ultraModeEnabled     ~= nil then ultraModeEnabled     = data.ultraModeEnabled     end
    if data.fastestStealEnabled  ~= nil then fastestStealEnabled  = data.fastestStealEnabled  end
    if data.autoSwingEnabled     ~= nil then autoSwingEnabled     = data.autoSwingEnabled     end
    if data.medusaCounterEnabled ~= nil then medusaCounterEnabled = data.medusaCounterEnabled end
    if data.floatEnabled         ~= nil then floatEnabled         = data.floatEnabled         end
    if data.noCamCollisionEnabled~= nil then noCamCollisionEnabled= data.noCamCollisionEnabled end
    if data.xrayEnabled          ~= nil then xrayEnabled          = data.xrayEnabled          end
    if data.ESPEnabled           ~= nil then _G.EmsaESPEnabled    = data.ESPEnabled            end
    if data.TracerEnabled        ~= nil then _G.EmsaTracerEnabled = data.TracerEnabled         end
    -- Enabled table
    if data.Enabled then
        for k, v in pairs(data.Enabled) do
            if Enabled[k] ~= nil then Enabled[k] = v end
        end
    end
    -- Keybinds
    if data.Keybinds then
        for k, v in pairs(data.Keybinds) do
            if Keybinds[k] ~= nil then
                local kc = Enum.KeyCode[v]
                if kc then Keybinds[k] = kc end
            end
        end
    end
end
local _savedMainPos = nil
local _savedRadiusPos = nil
pcall(loadConfig)
local C_BG      = Color3.fromRGB(0, 0, 0)
local C_SIDEBAR = Color3.fromRGB(0, 0, 0)
local C_CARD    = Color3.fromRGB(0, 0, 0)
local C_PURPLE  = Color3.fromRGB(255, 255, 255)
local C_PURPLE2 = Color3.fromRGB(220, 220, 220)
local C_RED     = Color3.fromRGB(180, 30, 50)
local C_DIM     = Color3.fromRGB(130, 130, 130)
local C_SW_OFF  = Color3.fromRGB(50, 50, 50)
local C_WHITE   = Color3.fromRGB(255, 255, 255)
local C_KEYBIND = Color3.fromRGB(45, 45, 45)
local lastTickTime = 0
local tickSound = Instance.new("Sound")
tickSound.SoundId = ""; tickSound.Volume = 0.12
tickSound.RollOffMaxDistance = 0; tickSound.Parent = SoundService
local function playTick()
    local now = tick()
    if now - lastTickTime < 0.08 then return end
    lastTickTime = now; tickSound.TimePosition = 0; tickSound:Play()
end
gui = Instance.new("ScreenGui")
gui.Name = "TokyoHubGUI"; gui.ResetOnSpawn = false; gui.DisplayOrder = 50
gui.IgnoreGuiInset = true; gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.Parent = LocalPlayer:FindFirstChildOfClass("PlayerGui")
local _guiOpen = false
local progressBar
do
    local introGui = Instance.new("ScreenGui")
    introGui.Name = "TokyoIntro"; introGui.ResetOnSpawn = false
    introGui.DisplayOrder = 999; introGui.IgnoreGuiInset = true
    introGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    introGui.Parent = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    -- Intro sound
    local introSound = Instance.new("Sound")
    introSound.SoundId = "rbxassetid://103445348511856"
    introSound.Volume = 1
    introSound.RollOffMaxDistance = 0
    introSound.Parent = workspace -- workspace parenting works more reliably
    -- Preload so it plays immediately
    game:GetService("ContentProvider"):PreloadAsync({introSound})
    -- Blurred dark overlay
    local blur = Instance.new("BlurEffect")
    blur.Size = 0; blur.Parent = game:GetService("Lighting")
    local overlay = Instance.new("Frame", introGui)
    overlay.Size = UDim2.new(1, 0, 1, 0); overlay.Position = UDim2.new(0,0,0,0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0; overlay.BorderSizePixel = 0; overlay.ZIndex = 10
    -- Subtle pink/blue gradient shimmer bar
    local shimmer = Instance.new("Frame", overlay)
    shimmer.Size = UDim2.new(1, 0, 0, 2); shimmer.Position = UDim2.new(0, 0, 0.5, 20)
    shimmer.BackgroundColor3 = Color3.fromRGB(0, 0, 0); shimmer.BorderSizePixel = 0
    shimmer.BackgroundTransparency = 1; shimmer.ZIndex = 11
    local shimGrad = Instance.new("UIGradient", shimmer)
    shimGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
    })
    -- Main title label (types in)
    local titleIntro = Instance.new("TextLabel", overlay)
    titleIntro.Size = UDim2.new(1, 0, 0, 60); titleIntro.Position = UDim2.new(0, 0, 0.5, -50)
    titleIntro.BackgroundTransparency = 1; titleIntro.Text = ""
    titleIntro.TextColor3 = Color3.fromRGB(0, 0, 0)
    titleIntro.Font = Enum.Font.GothamBlack; titleIntro.TextSize = 42
    titleIntro.TextXAlignment = Enum.TextXAlignment.Center; titleIntro.ZIndex = 12
    -- Pink/blue gradient on title
    local titleGrad = Instance.new("UIGradient", titleIntro)
    titleGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
    })
    -- Subtitle
    local subIntro = Instance.new("TextLabel", overlay)
    subIntro.Size = UDim2.new(1, 0, 0, 20); subIntro.Position = UDim2.new(0, 0, 0.5, 18)
    subIntro.BackgroundTransparency = 1; subIntro.Text = ""
    subIntro.TextColor3 = Color3.fromRGB(0, 0, 0)
    subIntro.TextTransparency = 0
    subIntro.Font = Enum.Font.GothamBold; subIntro.TextSize = 16
    subIntro.TextXAlignment = Enum.TextXAlignment.Center; subIntro.ZIndex = 12
    -- Sub cursor blink label
    local subCursor = Instance.new("TextLabel", overlay)
    subCursor.Size = UDim2.new(0, 20, 0, 20); subCursor.AnchorPoint = Vector2.new(0, 0)
    subCursor.BackgroundTransparency = 1; subCursor.Text = "|"
    subCursor.TextColor3 = Color3.fromRGB(0, 0, 0)
    subCursor.Font = Enum.Font.GothamBold; subCursor.TextSize = 16; subCursor.ZIndex = 12
    -- Cursor blink label
    local cursor = Instance.new("TextLabel", overlay)
    cursor.Size = UDim2.new(0, 30, 0, 60); cursor.AnchorPoint = Vector2.new(0, 0)
    cursor.BackgroundTransparency = 1; cursor.Text = "|"
    cursor.TextColor3 = Color3.fromRGB(0, 0, 0)
    cursor.Font = Enum.Font.GothamBlack; cursor.TextSize = 42; cursor.ZIndex = 12
    -- Play intro sequence
    task.spawn(function()
        -- Fade in blur
        task.wait(0.1) -- tiny buffer after preload
        introSound:Play()
        TweenService:Create(blur, TweenInfo.new(0.4), {Size = 24}):Play()
        TweenService:Create(overlay, TweenInfo.new(0.4), {BackgroundTransparency = 0.15}):Play()
        task.wait(0.5)
        -- Type out "Tokyo"
        local fullText = "Tokyo Hub"
        local charDelay = 0.10
        for i = 1, #fullText do
            titleIntro.Text = string.sub(fullText, 1, i)
            -- Position cursor after text (approximate)
            local charW = 24
            local totalW = i * charW
            local startX = (workspace.CurrentCamera.ViewportSize.X / 2) - (totalW / 2) + totalW
            cursor.Position = UDim2.new(0, startX, 0.5, -50)
            task.wait(charDelay)
        end
        -- Blink title cursor then hide
        for _ = 1, 2 do
            cursor.TextTransparency = 1; task.wait(0.2)
            cursor.TextTransparency = 0; task.wait(0.2)
        end
        cursor.TextTransparency = 1
        -- Type out subtitle "whatwecouldbe"
        task.wait(0.15)
        local subText = "whatwecouldbe"
        local subCharW = 9
        local vpX = workspace.CurrentCamera.ViewportSize.X
        subCursor.TextTransparency = 0
        for i = 1, #subText do
            subIntro.Text = string.sub(subText, 1, i)
            local tw = i * subCharW
            local sx = (vpX / 2) + (tw / 2) + 2
            subCursor.Position = UDim2.new(0, sx, 0.5, 18)
            task.wait(0.07)
        end
        -- Blink sub cursor then hide
        for _ = 1, 3 do
            subCursor.TextTransparency = 1; task.wait(0.25)
            subCursor.TextTransparency = 0; task.wait(0.25)
        end
        subCursor.TextTransparency = 1
        -- Hold for a moment
        task.wait(3.2)
        -- Fade out everything + cut sound immediately
        introSound:Stop()
        introSound:Destroy()
        TweenService:Create(overlay, TweenInfo.new(0.6), {BackgroundTransparency = 1}):Play()
        TweenService:Create(titleIntro, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
        TweenService:Create(subIntro, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
        TweenService:Create(subCursor, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        TweenService:Create(shimmer, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
        TweenService:Create(blur, TweenInfo.new(0.6), {Size = 0}):Play()
        task.wait(0.7)
        introGui:Destroy()
        -- Reveal main GUI with pop-in
        -- BASE_W/BASE_H are declared after this intro block, use literals
        main.Size = UDim2.new(0,0,0,0)
        main.Visible = true
        _guiOpen = true
        progressBar.Visible = true
        TweenService:Create(main, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size=UDim2.new(0,190,0,520)}):Play()
    end)
end
local bannerAnimIndex = 0
local BASE_W = 190; local BASE_H = 520; local SIDEBAR_W = 0; local CONTENT_W = BASE_W; local TABBAR_H = 26
main = Instance.new("Frame"); main.Name = "Main"
main.Size = UDim2.new(0, BASE_W, 0, BASE_H)
main.Position = (_savedMainPos and UDim2.new(0, _savedMainPos.x, 0, _savedMainPos.y)) or UDim2.new(0, 10, 0, 10)
main.BackgroundColor3 = Color3.fromRGB(0, 0, 0); main.BackgroundTransparency = 0; main.BorderSizePixel = 0; main.Active = true
main.ClipsDescendants = false; main.Parent = gui
main.Visible = false
local bgImage = Instance.new("ImageLabel", main)
bgImage.Size = UDim2.new(1, 0, 1, 0); bgImage.Position = UDim2.new(0, 0, 0, 0)
bgImage.BackgroundTransparency = 1
bgImage.Image = "rbxassetid://106297709263361"
bgImage.ImageTransparency = 0
bgImage.ScaleType = Enum.ScaleType.Crop
bgImage.BorderSizePixel = 0; bgImage.ZIndex = 1; bgImage.Name = "Background"
Instance.new("UICorner", bgImage).CornerRadius = UDim.new(0, 6)
local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color = Color3.fromRGB(30, 30, 30); mainStroke.Thickness = 1; mainStroke.Transparency = 0
do
    local drag, ds, sp, dragConn = false
    main.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            drag = true; ds = inp.Position; sp = main.Position
            if dragConn then dragConn:Disconnect() end
            dragConn = inp.Changed:Connect(function() if inp.UserInputState == Enum.UserInputState.End then drag = false; if dragConn then dragConn:Disconnect(); dragConn = nil end end end)
        end
    end)
    local lastDragUpdate = 0
    UserInputService.InputChanged:Connect(function(inp)
        if drag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local now = tick(); if now - lastDragUpdate < 0.016 then return end; lastDragUpdate = now
            local d = inp.Position - ds; main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end)
end
local header = Instance.new("Frame", main)
header.Size = UDim2.new(1, 0, 0, 24); header.BackgroundColor3 = Color3.fromRGB(18, 18, 18); header.BackgroundTransparency = 1; header.BorderSizePixel = 0; header.ZIndex = 3
local headerBgImg = Instance.new("Frame", header)
headerBgImg.Size = UDim2.new(1,0,1,0); headerBgImg.Position = UDim2.new(0,0,0,0)
headerBgImg.BackgroundColor3 = Color3.fromRGB(0, 0, 0); headerBgImg.BackgroundTransparency = 1
headerBgImg.BorderSizePixel = 0; headerBgImg.ZIndex = 2; headerBgImg.Name = "HeaderBG"
local headerFix = Instance.new("Frame", header)
headerFix.Size = UDim2.new(1, 0, 0, 10); headerFix.Position = UDim2.new(0, 0, 1, -10)
headerFix.BackgroundColor3 = Color3.fromRGB(18, 18, 18); headerFix.BackgroundTransparency = 1; headerFix.BorderSizePixel = 0; headerFix.ZIndex = 3
local titleLabel = Instance.new("TextLabel", header)
titleLabel.Size = UDim2.new(0, 90, 1, 0); titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1; titleLabel.Text = "tokyo"; titleLabel.TextColor3 = C_WHITE
titleLabel.Font = Enum.Font.GothamBlack; titleLabel.TextSize = 12; titleLabel.TextXAlignment = Enum.TextXAlignment.Left; titleLabel.ZIndex = 4
local discordLabel = Instance.new("TextLabel", header)
discordLabel.Size = UDim2.new(0, 160, 1, 0); discordLabel.Position = UDim2.new(0.5, -80, 0, 0)
discordLabel.BackgroundTransparency = 1; discordLabel.Text = ""; discordLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
discordLabel.Font = Enum.Font.Gotham; discordLabel.TextSize = 9; discordLabel.ZIndex = 4
local closeBtn = Instance.new("TextButton", header)
closeBtn.Size = UDim2.new(0, 18, 0, 18); closeBtn.Position = UDim2.new(1, -24, 0.5, -9)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255); closeBtn.BorderSizePixel = 0
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)
closeBtn.Text = "–"; closeBtn.TextColor3 = Color3.fromRGB(0, 0, 0); closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 13; closeBtn.ZIndex = 8
local reopenBtn = Instance.new("TextButton", gui)
reopenBtn.Size = UDim2.new(0, 120, 0, 32); reopenBtn.Position = UDim2.new(0.5, -60, 0, 5)
reopenBtn.AnchorPoint = Vector2.new(0, 0)
reopenBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 18); reopenBtn.BorderSizePixel = 0; reopenBtn.Text = ""; reopenBtn.ZIndex = 20; reopenBtn.Visible = false
local reopenStroke = Instance.new("UIStroke", reopenBtn)
reopenStroke.Color = Color3.fromRGB(255, 255, 255); reopenStroke.Thickness = 2; reopenStroke.Transparency = 0
local reopenDotL = Instance.new("Frame", reopenBtn)
reopenDotL.Size = UDim2.new(0, 6, 0, 6); reopenDotL.Position = UDim2.new(0, 10, 0.5, -3)
reopenDotL.BackgroundColor3 = Color3.fromRGB(180, 210, 255); reopenDotL.BorderSizePixel = 0; reopenDotL.ZIndex = 21
Instance.new("UICorner", reopenDotL).CornerRadius = UDim.new(1, 0)
local reopenDotR = Instance.new("Frame", reopenBtn)
reopenDotR.Size = UDim2.new(0, 6, 0, 6); reopenDotR.Position = UDim2.new(1, -16, 0.5, -3)
reopenDotR.BackgroundColor3 = Color3.fromRGB(180, 210, 255); reopenDotR.BorderSizePixel = 0; reopenDotR.ZIndex = 21
Instance.new("UICorner", reopenDotR).CornerRadius = UDim.new(1, 0)
local reopenLabel = Instance.new("TextLabel", reopenBtn)
reopenLabel.Size = UDim2.new(1, -32, 1, 0); reopenLabel.Position = UDim2.new(0, 16, 0, 0)
reopenLabel.BackgroundTransparency = 1; reopenLabel.Text = "MENU [U]"; reopenLabel.TextColor3 = Color3.fromRGB(220, 235, 255)
reopenLabel.Font = Enum.Font.GothamBold; reopenLabel.TextSize = 13; reopenLabel.ZIndex = 21; reopenLabel.TextXAlignment = Enum.TextXAlignment.Center
do
    local drag, ds, sp = false
    reopenBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            drag = true; ds = inp.Position; sp = reopenBtn.Position
            inp.Changed:Connect(function() if inp.UserInputState == Enum.UserInputState.End then drag = false end end)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if drag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local d = inp.Position - ds; if d.Magnitude > 5 then reopenBtn.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y) end
        end
    end)
end
closeBtn.MouseButton1Click:Connect(function()
    TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size=UDim2.new(0,0,0,0)}):Play()
    task.wait(0.25); main.Visible = false; reopenBtn.Visible = true
end)
reopenBtn.MouseButton1Click:Connect(function()
    _guiOpen = true
    reopenBtn.Visible = false; main.Size = UDim2.new(0,0,0,0); main.Visible = true
    TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size=UDim2.new(0,BASE_W,0,BASE_H)}):Play()
end)
local function openGUI()
    if _guiOpen then return end
    _guiOpen = true
    reopenBtn.Visible = false; main.Size = UDim2.new(0,0,0,0); main.Visible = true
    TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size=UDim2.new(0,BASE_W,0,BASE_H)}):Play()
end
local function closeGUI()
    if not _guiOpen then return end
    _guiOpen = false
    TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size=UDim2.new(0,0,0,0)}):Play()
    task.delay(0.25, function() main.Visible = false; reopenBtn.Visible = true end)
end
closeBtn.MouseEnter:Connect(function() getTween(closeBtn, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(200, 200, 200), TextColor3=Color3.fromRGB(0,0,0)}):Play() end)
closeBtn.MouseLeave:Connect(function() TweenService:Create(closeBtn, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(255, 255, 255), TextColor3=Color3.fromRGB(0,0,0)}):Play() end)
local body = Instance.new("Frame", main)
body.Size = UDim2.new(1, 0, 1, -24); body.Position = UDim2.new(0, 0, 0, 24)
body.BackgroundTransparency = 1; body.BorderSizePixel = 0; body.ZIndex = 2; body.ClipsDescendants = false
local singleScroll = Instance.new("ScrollingFrame", body)
singleScroll.Size = UDim2.new(1, -6, 1, -8)
singleScroll.Position = UDim2.new(0, 0, 0, 4)
singleScroll.BackgroundTransparency = 1; singleScroll.BorderSizePixel = 0
singleScroll.ScrollBarThickness = 3; singleScroll.ScrollBarImageColor3 = Color3.fromRGB(255,255,255)
singleScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; singleScroll.CanvasSize = UDim2.new(0,0,0,0)
singleScroll.ZIndex = 2
local singleLayout = Instance.new("UIListLayout", singleScroll)
singleLayout.Padding = UDim.new(0, 6); singleLayout.SortOrder = Enum.SortOrder.LayoutOrder
local singlePad = Instance.new("UIPadding", singleScroll)
singlePad.PaddingLeft = UDim.new(0, 8); singlePad.PaddingRight = UDim.new(0, 12); singlePad.PaddingTop = UDim.new(0, 4)
local gameplayPage  = singleScroll
local movementPage2 = singleScroll
local visualPage2   = singleScroll
local settingsScrollPage = singleScroll
local tabPages = {}
local tabButtons = {}
local VisualSetters = {}
local KeybindDisplayLabels = {}
local waitingForKey = nil
local function createSection(parent, text, order)
    local section = Instance.new("Frame", parent)
    section.Size = UDim2.new(1, 0, 0, 15); section.BackgroundTransparency = 1; section.LayoutOrder = order; section.ZIndex = 3
    local label = Instance.new("TextLabel", section)
    label.Size = UDim2.new(1, 0, 1, 0); label.BackgroundTransparency = 1; label.Text = text:upper()
    label.TextColor3 = Color3.fromRGB(255, 255, 255); label.Font = Enum.Font.GothamBold; label.TextSize = 8
    label.TextXAlignment = Enum.TextXAlignment.Left; label.ZIndex = 4
    local line = Instance.new("Frame", section)
    line.Size = UDim2.new(1, 0, 0, 1); line.Position = UDim2.new(0, 0, 1, -1)
    line.BackgroundColor3 = Color3.fromRGB(35, 35, 35); line.BackgroundTransparency = 0; line.BorderSizePixel = 0; line.ZIndex = 3
end
local function createToggle(parent, labelText, keybindName, enabledKey, defaultOn, order, onToggle, desc)
    local hasDesc = desc and desc ~= ""
    local cardH = hasDesc and 32 or 20
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, 0, 0, cardH); container.BackgroundColor3 = C_CARD
    container.BorderSizePixel = 0; container.LayoutOrder = order; container.ZIndex = 3
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 4)
    local containerStroke = Instance.new("UIStroke", container)
    containerStroke.Color = Color3.fromRGB(30, 30, 30); containerStroke.Thickness = 1; containerStroke.Transparency = 0
    local xOffset = 7
    local badge, badgeText
    if keybindName and keybindName ~= "" then
        badge = Instance.new("Frame", container)
        badge.Size = UDim2.new(0, 18, 0, 12); badge.Position = UDim2.new(0, 6, 0, 4)
        badge.BackgroundColor3 = Color3.fromRGB(40, 40, 40); badge.BackgroundTransparency = 0; badge.BorderSizePixel = 0; badge.ZIndex = 5
        Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 4)
        badgeText = Instance.new("TextLabel", badge)
        badgeText.Size = UDim2.new(1, 0, 1, 0); badgeText.BackgroundTransparency = 1
        badgeText.Text = Keybinds[keybindName] and Keybinds[keybindName].Name or (keybindName or "")
        badgeText.TextColor3 = C_WHITE; badgeText.Font = Enum.Font.GothamBold; badgeText.TextSize = 7; badgeText.ZIndex = 6
        KeybindDisplayLabels[keybindName] = badgeText; xOffset = 30
    end
    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(1, -80, 0, 12); label.Position = UDim2.new(0, xOffset, 0, 4)
    label.BackgroundTransparency = 1; label.Text = labelText; label.TextColor3 = C_WHITE
    label.Font = Enum.Font.GothamBold; label.TextSize = 9; label.TextXAlignment = Enum.TextXAlignment.Left; label.ZIndex = 5
    if hasDesc then
        local descLabel = Instance.new("TextLabel", container)
        descLabel.Size = UDim2.new(1, -14, 0, 11); descLabel.Position = UDim2.new(0, xOffset, 0, 17)
        descLabel.BackgroundTransparency = 1; descLabel.Text = desc
        descLabel.TextColor3 = Color3.fromRGB(100, 100, 100); descLabel.Font = Enum.Font.Gotham
        descLabel.TextSize = 7; descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.TextTruncate = Enum.TextTruncate.AtEnd; descLabel.ZIndex = 5
    end
    local switchBg = Instance.new("Frame", container)
    switchBg.Size = UDim2.new(0, 26, 0, 14); switchBg.Position = UDim2.new(1, -30, 0, 3)
    switchBg.BackgroundColor3 = defaultOn and C_PURPLE or C_SW_OFF; switchBg.BorderSizePixel = 0; switchBg.ZIndex = 5
    Instance.new("UICorner", switchBg).CornerRadius = UDim.new(1, 0)
    local switchCircle = Instance.new("Frame", switchBg)
    switchCircle.Size = UDim2.new(0, 10, 0, 10)
    switchCircle.Position = defaultOn and UDim2.new(1,-12,0.5,-5) or UDim2.new(0,2,0.5,-5)
    switchCircle.BackgroundColor3 = defaultOn and Color3.fromRGB(18, 18, 18) or C_WHITE; switchCircle.BorderSizePixel = 0; switchCircle.ZIndex = 6
    Instance.new("UICorner", switchCircle).CornerRadius = UDim.new(1, 0)
    local isOn = defaultOn
    local isHoldingForKeybind = false; local holdStartTime = 0
    local function setVisual(state)
        isOn = state
        TweenService:Create(switchBg, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {BackgroundColor3=isOn and C_PURPLE or C_SW_OFF}):Play()
        TweenService:Create(switchCircle, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Position=isOn and UDim2.new(1,-12,0.5,-5) or UDim2.new(0,2,0.5,-5)}):Play()
        TweenService:Create(switchCircle, TweenInfo.new(0.15), {BackgroundColor3=isOn and Color3.fromRGB(18, 18, 18) or C_WHITE}):Play()
    end
    if enabledKey then VisualSetters[enabledKey] = setVisual end
    local function startKeybindChange()
        if not keybindName or keybindName == "" or not badgeText then return end
        waitingForKey = keybindName; badgeText.Text = "..."
        TweenService:Create(badge, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(255,180,100)}):Play()
        local conn
        conn = UserInputService.InputBegan:Connect(function(input, gpe)
            if waitingForKey ~= keybindName then conn:Disconnect(); return end
            if not (input.UserInputType == Enum.UserInputType.Keyboard) then return end
            local kc = input.KeyCode
            if kc == Enum.KeyCode.Escape then
                badgeText.Text = Keybinds[keybindName].Name
                TweenService:Create(badge, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(40, 40, 40), BackgroundTransparency=0}):Play()
                waitingForKey = nil; conn:Disconnect(); return
            end
            if kc == Enum.KeyCode.Unknown then return end
            Keybinds[keybindName] = kc; badgeText.Text = kc.Name
            TweenService:Create(badge, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(40, 40, 40), BackgroundTransparency=0}):Play()
            waitingForKey = nil; conn:Disconnect()
        end)
    end
    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(1, 0, 1, 0); btn.BackgroundTransparency = 1; btn.Text = ""; btn.ZIndex = 7
    btn.MouseButton1Click:Connect(function()
        if not isHoldingForKeybind then
            playTick(); isOn = not isOn; setVisual(isOn)
            if enabledKey then Enabled[enabledKey] = isOn end
            if onToggle then onToggle(isOn) end
        end
        isHoldingForKeybind = false; holdStartTime = 0
    end)
    btn.MouseButton2Click:Connect(function() playTick(); startKeybindChange() end)
    btn.MouseButton1Down:Connect(function()
        isHoldingForKeybind = false; holdStartTime = tick()
        task.delay(0.6, function()
            if holdStartTime > 0 and (tick()-holdStartTime) >= 0.6 then isHoldingForKeybind = true; playTick(); startKeybindChange() end
        end)
    end)
    btn.MouseButton1Up:Connect(function() if (tick()-holdStartTime) < 0.6 then holdStartTime = 0 end end)
    btn.MouseEnter:Connect(function()
        TweenService:Create(containerStroke, TweenInfo.new(0.15), {Transparency=0}):Play()
        TweenService:Create(container, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(10,10,10)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(containerStroke, TweenInfo.new(0.15), {Transparency=0}):Play()
        TweenService:Create(container, TweenInfo.new(0.15), {BackgroundColor3=C_CARD}):Play()
    end)
    return setVisual, switchBg, switchCircle
end
local order = 0
local function O() order = order + 1; return order end
createSection(gameplayPage, "Combat", O())
createToggle(gameplayPage, "Anti Ragdoll", "", "AntiRagdoll", Enabled.AntiRagdoll, O(), function(s) if s then startAntiRagdoll() else stopAntiRagdoll() end end, "Prevents your character from ragdolling when hit")
local speedClk, _speedSwBg, _speedSwCircle = createToggle(gameplayPage, "Carry Mode", "SpeedToggle", nil, speedToggled, O(), function(on)
    if on and laggerToggled then
        laggerToggled = false
        if laggerSwBg and laggerSwCircle then TweenService:Create(laggerSwBg,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{BackgroundColor3=C_SW_OFF}):Play(); TweenService:Create(laggerSwCircle,TweenInfo.new(0.2,Enum.EasingStyle.Back),{Position=UDim2.new(0,2,0.5,-6)}):Play() end
        if laggerClk then laggerClk(false) end
        if sideSetters and sideSetters.laggerSetter then sideSetters.laggerSetter(false) end
    end
    speedToggled = on; if sideSetters and sideSetters.carrySetter then sideSetters.carrySetter(on) end
end, "Boosts your speed to carry speed")
speedSwBg = _speedSwBg; speedSwCircle = _speedSwCircle
local laggerClk, _laggerSwBg, _laggerSwCircle = createToggle(gameplayPage, "Lagger Mode", "LaggerToggle", nil, laggerToggled, O(), function(on)
    if on and speedToggled then
        speedToggled = false
        if speedSwBg and speedSwCircle then TweenService:Create(speedSwBg,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{BackgroundColor3=C_SW_OFF}):Play(); TweenService:Create(speedSwCircle,TweenInfo.new(0.2,Enum.EasingStyle.Back),{Position=UDim2.new(0,2,0.5,-6)}):Play() end
        if speedClk then speedClk(false) end
        if sideSetters and sideSetters.carrySetter then sideSetters.carrySetter(false) end
    end
    laggerToggled = on; if sideSetters and sideSetters.laggerSetter then sideSetters.laggerSetter(on) end
end, "Slows you to lagger speed to appear laggy")
laggerSwBg = _laggerSwBg; laggerSwCircle = _laggerSwCircle
local batClk, _batSwBg, _batSwCircle = createToggle(gameplayPage, "Auto Bat", "AutoBat", nil, autoBatToggled, O(), function(on)
    autoBatToggled = on
    if sideSetters and sideSetters.batSetter then sideSetters.batSetter(on) end
end, "Automatically moves you toward the nearest player to hit")
batSwBg = _batSwBg; batSwCircle = _batSwCircle
local setMedusaVisual, _, _ = createToggle(gameplayPage, "Medusa Counter", "", nil, medusaCounterEnabled, O(), function(on) medusaCounterEnabled = on; if on then setupMedusaCounter(LocalPlayer.Character) else stopMedusaCounter() end end, "Auto-activates Medusa head when you get stoned")
VisualSetters.MedusaCounter = setMedusaVisual
local setAutoSwingVisual, _, _ = createToggle(gameplayPage, "Auto Swing", "", nil, false, O(), function(on) autoSwingEnabled = on end, "Automatically swings your bat at nearby players")
VisualSetters.AutoSwing = setAutoSwingVisual
local setBatCounterVisual, _, _ = createToggle(gameplayPage, "Bat Counter", "", nil, false, O(), function(on)
    batCounterEnabled = on; if on then startBatCounter() else stopBatCounter() end
end, "When you get ragdolled, automatically swings your bat 2 times")
VisualSetters.BatCounter = setBatCounterVisual
createSection(gameplayPage, "Steal", O())
local stealVisual, _, _ = createToggle(gameplayPage, "Auto Steal", "", nil, Enabled.AutoSteal, O(), function(on)
    Enabled.AutoSteal = on; Settings.AutoStealEnabled = on; if on then startAutoSteal() else stopAutoSteal() end
end, "Automatically steals animals from nearby podiums")
createSection(gameplayPage, "Speed Settings", O())
local function createSpeedInput(parent, labelText, defaultValue, variableName, order2)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, 0, 0, 24); container.BackgroundColor3 = C_CARD
    container.BorderSizePixel = 0; container.LayoutOrder = order2; container.ZIndex = 3
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 5)
    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(0.6, -10, 1, 0); label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1; label.Text = labelText; label.TextColor3 = C_WHITE
    label.Font = Enum.Font.GothamBold; label.TextSize = 9; label.TextXAlignment = Enum.TextXAlignment.Left; label.ZIndex = 4
    local input = Instance.new("TextBox", container)
    input.Size = UDim2.new(0, 52, 0, 18); input.Position = UDim2.new(1, -58, 0.5, -9)
    input.BackgroundColor3 = Color3.fromRGB(0, 0, 0); input.BorderSizePixel = 0; input.Text = tostring(defaultValue)
    input.TextColor3 = Color3.fromRGB(255, 255, 255); input.Font = Enum.Font.GothamBold; input.TextSize = 9; input.ZIndex = 4
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 4)
    local iStroke = Instance.new("UIStroke", input); iStroke.Color = Color3.fromRGB(40, 40, 40); iStroke.Thickness = 1; iStroke.Transparency = 0
    input.FocusLost:Connect(function()
        local n = tonumber(input.Text)
        if n then
            n = math.clamp(math.floor(n*10)/10, 1, 9999)
            if variableName == "NORMAL" then NORMAL_SPEED = n
            elseif variableName == "CARRY" then CARRY_SPEED = n
            elseif variableName == "LAGGER" then LAGGER_SPEED = n end
            input.Text = string.format("%.1f", n)
        else
            if variableName == "NORMAL" then input.Text = tostring(NORMAL_SPEED)
            elseif variableName == "CARRY" then input.Text = tostring(CARRY_SPEED)
            elseif variableName == "LAGGER" then input.Text = tostring(LAGGER_SPEED) end
        end
    end)
end
createSpeedInput(gameplayPage, "Normal Speed", NORMAL_SPEED, "NORMAL", O())
createSpeedInput(gameplayPage, "Carry Speed", CARRY_SPEED, "CARRY", O())
createSpeedInput(gameplayPage, "Lagger Speed", LAGGER_SPEED, "LAGGER", O())
createSection(movementPage2, "Movement", O())
createToggle(movementPage2, "Infinite Jump", "", "InfiniteJump", Enabled.InfiniteJump, O(), function(s) if s then startInfiniteJump() else stopInfiniteJump() end end, "Jump unlimited times in the air")
createToggle(movementPage2, "Unwalk", "", "Unwalk", Enabled.Unwalk, O(), function(s) if s then startUnwalk() else stopUnwalk() end end, "Removes walk animation so you appear still to others")
local setFloatVisual, _, _ = createToggle(movementPage2, "Float", "FloatToggle", nil, false, O(), function(on)
    floatEnabled = on; if on then startFloat() else stopFloat() end
end, "Hovers you above the ground at a set height")
local _dropVis, _, _ = createToggle(movementPage2, "Drop Brainrot", "DropBrainrot", nil, false, O(), function(on)
    if on then task.spawn(runDropBrainrot) end
end, "Launches you up then drops you to the ground instantly")
setDropBrainrotVisual = _dropVis
local setTPDownVisual, tpDownSwBg, tpDownSwCircle = createToggle(movementPage2, "TP Down", "TPDown", nil, false, O(), function(on)
    if on then runTPDown() end
end, "Teleports you straight down to the floor below")
VisualSetters.TPDown = setTPDownVisual
VisualSetters.TPDownReset = function()
    TweenService:Create(tpDownSwBg, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {BackgroundColor3=C_SW_OFF}):Play()
    TweenService:Create(tpDownSwCircle, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Position=UDim2.new(0,2,0.5,-6)}):Play()
    setTPDownVisual(false)
end
local setNoCamVisual, _, _ = createToggle(movementPage2, "No Cam Collision", "", nil, false, O(), function(on)
    noCamCollisionEnabled = on; if on then enableNoCameraCollision() else disableNoCameraCollision() end
end, "Camera passes through walls so you always see your character")
VisualSetters.NoCam = setNoCamVisual
createSection(movementPage2, "Float Settings", O())
local function createFloatInput(parent, order2)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1,0,0,26); container.BackgroundColor3 = C_CARD
    container.BorderSizePixel = 0; container.LayoutOrder = order2; container.ZIndex = 3
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 5)
    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(0.6,-10,1,0); label.Position = UDim2.new(0,8,0,0)
    label.BackgroundTransparency = 1; label.Text = "Float Height"; label.TextColor3 = C_WHITE
    label.Font = Enum.Font.GothamBold; label.TextSize = 9; label.TextXAlignment = Enum.TextXAlignment.Left; label.ZIndex = 4
    local input = Instance.new("TextBox", container)
    input.Size = UDim2.new(0,52,0,18); input.Position = UDim2.new(1,-58,0.5,-9)
    input.BackgroundColor3 = Color3.fromRGB(0, 0, 0); input.BorderSizePixel = 0; input.Text = tostring(floatHeight)
    input.TextColor3 = Color3.fromRGB(255, 255, 255); input.Font = Enum.Font.GothamBold; input.TextSize = 9; input.ZIndex = 4
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 4)
    local iStroke2 = Instance.new("UIStroke", input); iStroke2.Color = Color3.fromRGB(40, 40, 40); iStroke2.Thickness = 1; iStroke2.Transparency = 0
    input.FocusLost:Connect(function()
        local n = tonumber(input.Text)
        if n then floatHeight = math.clamp(n,1,100); input.Text = tostring(floatHeight)
        else input.Text = tostring(floatHeight) end
    end)
end
createFloatInput(movementPage2, O())
createSection(movementPage2, "Auto Walk", O())
local setAutoSimpleLeftVisual, _, _ = createToggle(movementPage2, "Auto Left", "AutoLeft", nil, false, O(), function(on)
    if on then autoRightEnabled=false; stopAutoRight(); if autoRightSetter then autoRightSetter(false) end; startAutoLeft()
    else stopAutoLeft() end; autoLeftEnabled = on
end, "Auto-walks to the left side podium position")
autoLeftSetter = setAutoSimpleLeftVisual
local setAutoSimpleRightVisual, _, _ = createToggle(movementPage2, "Auto Right", "AutoRight", nil, false, O(), function(on)
    if on then autoLeftEnabled=false; stopAutoLeft(); if autoLeftSetter then autoLeftSetter(false) end; startAutoRight()
    else stopAutoRight() end; autoRightEnabled = on
end, "Auto-walks to the right side podium position")
autoRightSetter = setAutoSimpleRightVisual
createSection(visualPage2, "ESP & Tracers", O())
local setESPVisual, _, _ = createToggle(visualPage2, "ESP (Pink Outline)", "", nil, _G.EmsaESPEnabled or false, O(), function(on)
    if _G.EmsaSetESP then _G.EmsaSetESP(on) end
    if _G.EmsaAddESPPlayer then for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then _G.EmsaAddESPPlayer(p) end end end
end, "Shows boxes and health bars around all players")
local setTracerVisual, _, _ = createToggle(visualPage2, "Tracer Lines", "", nil, _G.EmsaTracerEnabled or false, O(), function(on)
    if _G.EmsaSetTracer then _G.EmsaSetTracer(on) end
end, "Draws a line from your screen to every player")
createSection(visualPage2, "Performance", O())
createToggle(visualPage2, "Anti Lag", "", "Optimizer", Enabled.Optimizer, O(), function(s) if s then enableOptimizer() else disableOptimizer() end end, "Removes textures and effects to boost FPS")
local setUltraVisual, _, _ = createToggle(visualPage2, "Ultra Mode", "", nil, false, O(), function(s) ultraModeEnabled = s; if s then enableUltraMode() else disableUltraMode() end end, "Max performance mode — destroys shadows, particles and decals")
VisualSetters.UltraMode = setUltraVisual
createToggle(visualPage2, "Remove Accessories", "", "RemoveAccessories", Enabled.RemoveAccessories, O(), function(s) if s then startRemoveAccessories() else stopRemoveAccessories() end end, "Hides all hats and accessories on your character")
createSection(singleScroll, "Steal Settings", O())
local function createStealInput2(labelText, getVal, setVal, formatFn, order2)
    local container = Instance.new("Frame", singleScroll)
    container.Size = UDim2.new(1,0,0,28); container.BackgroundColor3 = C_CARD
    container.BorderSizePixel = 0; container.LayoutOrder = order2; container.ZIndex = 3
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 5)
    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(0.55,-10,1,0); label.Position = UDim2.new(0,8,0,0)
    label.BackgroundTransparency = 1; label.Text = labelText; label.TextColor3 = C_WHITE
    label.Font = Enum.Font.GothamBold; label.TextSize = 9; label.TextXAlignment = Enum.TextXAlignment.Left; label.ZIndex = 4
    local input = Instance.new("TextBox", container)
    input.Size = UDim2.new(0,58,0,20); input.Position = UDim2.new(1,-64,0.5,-10)
    input.BackgroundColor3 = Color3.fromRGB(0, 0, 0); input.BorderSizePixel = 0
    input.Text = formatFn(getVal()); input.TextColor3 = Color3.fromRGB(255, 255, 255)
    input.Font = Enum.Font.GothamBold; input.TextSize = 9; input.TextXAlignment = Enum.TextXAlignment.Center; input.ZIndex = 5
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 4)
    local iStroke = Instance.new("UIStroke", input); iStroke.Color = Color3.fromRGB(40, 40, 40); iStroke.Thickness = 1; iStroke.Transparency = 0
    input.FocusLost:Connect(function()
        local n = tonumber(input.Text)
        if n then setVal(n); input.Text = formatFn(getVal()) else input.Text = formatFn(getVal()) end
    end)
    return input
end
createStealInput2("Steal Radius",
    function() return Settings.StealRadius end,
    function(n) Settings.StealRadius = math.clamp(math.floor(n*10)/10, 0.1, 500); Values.STEAL_RADIUS = Settings.StealRadius; cachedPrompts={}; promptCacheTime=0 end,
    function(v) return string.format("%.1f", v) end, O())
createStealInput2("Steal Duration",
    function() return Settings.StealDuration end,
    function(n) Settings.StealDuration = math.clamp(n,0.2,5); Values.STEAL_DURATION = Settings.StealDuration end,
    function(v) return string.format("%.2f", v) end, O())
createSection(singleScroll, "Keybinds", O())
do
    local keybindList2 = {
        {"Carry Mode","SpeedToggle"},{"Lagger Mode","LaggerToggle"},{"Auto Bat","AutoBat"},
        {"Infinite Jump","InfiniteJump"},{"UI Toggle","UIToggle"},{"Drop Brainrot","DropBrainrot"},
        {"Float Toggle","FloatToggle"},{"Full Auto Left","FullAutoLeft"},{"Full Auto Right","FullAutoRight"},
        {"TP Down","TPDown"},{"Auto Left","AutoLeft"},{"Auto Right","AutoRight"},
    }
    for _, entry in ipairs(keybindList2) do
        local labelText, keybindName = entry[1], entry[2]
        local container = Instance.new("Frame", singleScroll)
        container.Size = UDim2.new(1,0,0,26); container.BackgroundColor3 = C_CARD
        container.BorderSizePixel = 0; container.LayoutOrder = O(); container.ZIndex = 3
        Instance.new("UICorner", container).CornerRadius = UDim.new(0, 5)
        local cStroke = Instance.new("UIStroke", container); cStroke.Color = Color3.fromRGB(18, 18, 18); cStroke.Thickness = 1; cStroke.Transparency = 0.5
        local nameLabel = Instance.new("TextLabel", container)
        nameLabel.Size = UDim2.new(1,-80,1,0); nameLabel.Position = UDim2.new(0,8,0,0)
        nameLabel.BackgroundTransparency = 1; nameLabel.Text = labelText; nameLabel.TextColor3 = C_WHITE
        nameLabel.Font = Enum.Font.GothamBold; nameLabel.TextSize = 9; nameLabel.TextXAlignment = Enum.TextXAlignment.Left; nameLabel.ZIndex = 4
        local badge = Instance.new("Frame", container)
        badge.Size = UDim2.new(0,48,0,18); badge.Position = UDim2.new(1,-54,0.5,-9)
        badge.BackgroundColor3 = Color3.fromRGB(40, 40, 40); badge.BackgroundTransparency = 0; badge.BorderSizePixel = 0; badge.ZIndex = 5
        Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 4)
        local badgeText = Instance.new("TextLabel", badge)
        badgeText.Size = UDim2.new(1,0,1,0); badgeText.BackgroundTransparency = 1
        badgeText.Text = Keybinds[keybindName] and Keybinds[keybindName].Name or keybindName
        badgeText.TextColor3 = C_WHITE; badgeText.Font = Enum.Font.GothamBold; badgeText.TextSize = 8; badgeText.ZIndex = 6
        if KeybindDisplayLabels[keybindName] == nil then KeybindDisplayLabels[keybindName] = badgeText end
        local btn = Instance.new("TextButton", container)
        btn.Size = UDim2.new(1,0,1,0); btn.BackgroundTransparency = 1; btn.Text = ""; btn.ZIndex = 7
        btn.MouseButton1Click:Connect(function()
            playTick(); waitingForKey = keybindName; badgeText.Text = "..."
            TweenService:Create(badge, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(255,180,100)}):Play()
            local conn
            conn = UserInputService.InputBegan:Connect(function(input, _)
                if waitingForKey ~= keybindName then conn:Disconnect(); return end
                if not (input.UserInputType == Enum.UserInputType.Keyboard) then return end
                local kc = input.KeyCode
                if kc == Enum.KeyCode.Escape then
                    badgeText.Text = Keybinds[keybindName].Name
                    TweenService:Create(badge, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(40, 40, 40), BackgroundTransparency=0}):Play()
                    waitingForKey = nil; conn:Disconnect(); return
                end
                if kc == Enum.KeyCode.Unknown then return end
                Keybinds[keybindName] = kc; badgeText.Text = kc.Name
                if KeybindDisplayLabels[keybindName] then KeybindDisplayLabels[keybindName].Text = kc.Name end
                TweenService:Create(badge, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(40, 40, 40), BackgroundTransparency=0}):Play()
                waitingForKey = nil; conn:Disconnect()
            end)
        end)
        btn.MouseEnter:Connect(function()
            TweenService:Create(cStroke, TweenInfo.new(0.15), {Transparency=0.3}):Play()
            TweenService:Create(container, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(10,10,10)}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(cStroke, TweenInfo.new(0.15), {Transparency=0.85}):Play()
            TweenService:Create(container, TweenInfo.new(0.15), {BackgroundColor3=C_CARD}):Play()
        end)
    end
end
task.spawn(function()
    while true do
        task.wait(2)
        pcall(saveConfig)
    end
end)
progressBar = Instance.new("Frame", main)
progressBar.Size = UDim2.new(0, 200, 0, 46)
progressBar.Position = UDim2.new(0, 0, 1, 6)
progressBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0); progressBar.BackgroundTransparency = 0; progressBar.BorderSizePixel = 0; progressBar.Active = true; progressBar.ZIndex = 50
progressBar.Visible = false -- hidden until after intro
Instance.new("UICorner", progressBar).CornerRadius = UDim.new(0, 10)
local pbStroke2 = Instance.new("UIStroke", progressBar); pbStroke2.Color = Color3.fromRGB(255, 255, 255); pbStroke2.Thickness = 1.2; pbStroke2.Transparency = 0
ProgressLabel = Instance.new("TextLabel", progressBar)
ProgressLabel.Size = UDim2.new(0.5,0,0,13); ProgressLabel.Position = UDim2.new(0,8,0,4)
ProgressLabel.BackgroundTransparency = 1; ProgressLabel.Text = "READY"; ProgressLabel.TextColor3 = Color3.fromRGB(255,255,255)
ProgressLabel.Font = Enum.Font.GothamBlack; ProgressLabel.TextSize = 8; ProgressLabel.TextXAlignment = Enum.TextXAlignment.Left; ProgressLabel.ZIndex = 51
ProgressPercentLabel = Instance.new("TextLabel", progressBar)
ProgressPercentLabel.Size = UDim2.new(1,-8,0,13); ProgressPercentLabel.Position = UDim2.new(0,0,0,4)
ProgressPercentLabel.BackgroundTransparency = 1; ProgressPercentLabel.Text = ""; ProgressPercentLabel.TextColor3 = C_WHITE
ProgressPercentLabel.Font = Enum.Font.GothamBlack; ProgressPercentLabel.TextSize = 8; ProgressPercentLabel.TextXAlignment = Enum.TextXAlignment.Right; ProgressPercentLabel.ZIndex = 51
local pTrack2 = Instance.new("Frame", progressBar)
pTrack2.Size = UDim2.new(1,-14,0,10); pTrack2.Position = UDim2.new(0,7,0,20)
pTrack2.BackgroundColor3 = Color3.fromRGB(30, 30, 30); pTrack2.BorderSizePixel = 0; pTrack2.ZIndex = 50
Instance.new("UICorner", pTrack2).CornerRadius = UDim.new(0, 4)
ProgressBarFill = Instance.new("Frame", pTrack2)
ProgressBarFill.Size = UDim2.new(0,0,1,0); ProgressBarFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ProgressBarFill.BorderSizePixel = 0; ProgressBarFill.ZIndex = 51
Instance.new("UICorner", ProgressBarFill).CornerRadius = UDim.new(0, 4)
local pbRadiusLabel = Instance.new("TextLabel", progressBar)
pbRadiusLabel.Size = UDim2.new(0.5,-4,0,10); pbRadiusLabel.Position = UDim2.new(0,8,0,33)
pbRadiusLabel.BackgroundTransparency = 1; pbRadiusLabel.TextColor3 = Color3.fromRGB(255, 255, 255); pbRadiusLabel.Font = Enum.Font.GothamBold
pbRadiusLabel.TextSize = 7; pbRadiusLabel.TextXAlignment = Enum.TextXAlignment.Left; pbRadiusLabel.ZIndex = 52
pbRadiusLabel.Text = "Radius: " .. tostring(Settings.StealRadius)
local pbDurationLabel = Instance.new("TextLabel", progressBar)
pbDurationLabel.Size = UDim2.new(0.5,-4,0,10); pbDurationLabel.Position = UDim2.new(0.5,0,0,33)
pbDurationLabel.BackgroundTransparency = 1; pbDurationLabel.TextColor3 = Color3.fromRGB(255, 255, 255); pbDurationLabel.Font = Enum.Font.GothamBold
pbDurationLabel.TextSize = 7; pbDurationLabel.TextXAlignment = Enum.TextXAlignment.Right; pbDurationLabel.ZIndex = 52
pbDurationLabel.Text = "Dur: " .. string.format("%.2f", Settings.StealDuration)
RadiusInput = Instance.new("TextBox", progressBar); RadiusInput.Visible = false
DurationInput = Instance.new("TextBox", progressBar); DurationInput.Visible = false
RadiusInput.Text = tostring(Settings.StealRadius); DurationInput.Text = tostring(Settings.StealDuration)
local function handleKeybindAction(kc)
    if waitingForKey then return end
    if kc == Keybinds.UIToggle then
        if _guiOpen then closeGUI() else openGUI() end
    end
    if kc == Keybinds.LaggerToggle then
        laggerToggled = not laggerToggled
        if laggerToggled and speedToggled then speedToggled=false
            if speedSwBg and speedSwCircle then TweenService:Create(speedSwBg,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{BackgroundColor3=C_SW_OFF}):Play(); TweenService:Create(speedSwCircle,TweenInfo.new(0.2,Enum.EasingStyle.Back),{Position=UDim2.new(0,2,0.5,-6)}):Play() end
            if sideSetters and sideSetters.carrySetter then sideSetters.carrySetter(false) end
        end
        if not laggerToggled then
            speedToggled = true
            if speedSwBg and speedSwCircle then TweenService:Create(speedSwBg,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{BackgroundColor3=C_PURPLE}):Play(); TweenService:Create(speedSwCircle,TweenInfo.new(0.2,Enum.EasingStyle.Back),{Position=UDim2.new(1,-14,0.5,-6)}):Play() end
            if sideSetters and sideSetters.carrySetter then sideSetters.carrySetter(true) end
        end
        if laggerSwBg and laggerSwCircle then TweenService:Create(laggerSwBg,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{BackgroundColor3=laggerToggled and C_PURPLE or C_SW_OFF}):Play(); TweenService:Create(laggerSwCircle,TweenInfo.new(0.2,Enum.EasingStyle.Back),{Position=laggerToggled and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6)}):Play() end
        if sideSetters and sideSetters.laggerSetter then sideSetters.laggerSetter(laggerToggled) end
    end
    if kc == Keybinds.SpeedToggle then
        speedToggled = not speedToggled
        if speedToggled and laggerToggled then laggerToggled=false
            if laggerSwBg and laggerSwCircle then TweenService:Create(laggerSwBg,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{BackgroundColor3=C_SW_OFF}):Play(); TweenService:Create(laggerSwCircle,TweenInfo.new(0.2,Enum.EasingStyle.Back),{Position=UDim2.new(0,2,0.5,-6)}):Play() end
            if sideSetters and sideSetters.laggerSetter then sideSetters.laggerSetter(false) end
        end
        if speedSwBg and speedSwCircle then TweenService:Create(speedSwBg,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{BackgroundColor3=speedToggled and C_PURPLE or C_SW_OFF}):Play(); TweenService:Create(speedSwCircle,TweenInfo.new(0.2,Enum.EasingStyle.Back),{Position=speedToggled and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6)}):Play() end
        if sideSetters and sideSetters.carrySetter then sideSetters.carrySetter(speedToggled) end
    end
    if kc == Keybinds.AutoBat then autoBatToggled = not autoBatToggled
        if batSwBg and batSwCircle then TweenService:Create(batSwBg,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{BackgroundColor3=autoBatToggled and C_PURPLE or C_SW_OFF}):Play(); TweenService:Create(batSwCircle,TweenInfo.new(0.2,Enum.EasingStyle.Back),{Position=autoBatToggled and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6)}):Play() end
        if sideSetters and sideSetters.batSetter then sideSetters.batSetter(autoBatToggled) end
    end
    if kc == Keybinds.InfiniteJump then Enabled.InfiniteJump = not Enabled.InfiniteJump; if VisualSetters.InfiniteJump then VisualSetters.InfiniteJump(Enabled.InfiniteJump) end; if Enabled.InfiniteJump then startInfiniteJump() else stopInfiniteJump() end end
    if kc == Keybinds.DropBrainrot then if setDropBrainrotVisual then setDropBrainrotVisual(true) end; if dropMobileSetter then dropMobileSetter(true) end; task.spawn(runDropBrainrot) end
    if kc == Keybinds.FloatToggle then floatEnabled = not floatEnabled; if setFloatVisual then setFloatVisual(floatEnabled) end; if floatEnabled then startFloat() else stopFloat() end end
    if kc == Keybinds.FullAutoLeft then fullAutoPlayLeftEnabled = not fullAutoPlayLeftEnabled; if fullAutoLeftSetter then fullAutoLeftSetter(fullAutoPlayLeftEnabled) end; if fullAutoPlayLeftEnabled then startFullAutoLeft() else stopFullAutoLeft() end end
    if kc == Keybinds.TPDown then runTPDown() end
    if kc == Keybinds.AutoLeft then
        autoLeftEnabled = not autoLeftEnabled
        if autoLeftEnabled then autoRightEnabled=false; stopAutoRight(); if autoRightSetter then autoRightSetter(false) end; startAutoLeft() else stopAutoLeft() end
        if autoLeftSetter then autoLeftSetter(autoLeftEnabled) end; if sideSetters and sideSetters.autoLeftMobile then sideSetters.autoLeftMobile(autoLeftEnabled) end
    end
    if kc == Keybinds.AutoRight then
        autoRightEnabled = not autoRightEnabled
        if autoRightEnabled then autoLeftEnabled=false; stopAutoLeft(); if autoLeftSetter then autoLeftSetter(false) end; startAutoRight() else stopAutoRight() end
        if autoRightSetter then autoRightSetter(autoRightEnabled) end; if sideSetters and sideSetters.autoRightMobile then sideSetters.autoRightMobile(autoRightEnabled) end
    end
end
local CONTROLLER_MAP = {
    [Enum.KeyCode.ButtonA]=Keybinds.DropBrainrot,[Enum.KeyCode.ButtonB]=Keybinds.FloatToggle,
    [Enum.KeyCode.ButtonX]=Keybinds.FullAutoLeft,[Enum.KeyCode.ButtonY]=Keybinds.AutoBat,
    [Enum.KeyCode.ButtonL1]=Keybinds.SpeedToggle,[Enum.KeyCode.ButtonR1]=Keybinds.LaggerToggle,
    [Enum.KeyCode.ButtonL2]=Keybinds.TPDown,[Enum.KeyCode.ButtonR2]=Keybinds.InfiniteJump,
    [Enum.KeyCode.ButtonStart]=Keybinds.UIToggle,
    [Enum.KeyCode.DPadUp]=Keybinds.FullAutoLeft,[Enum.KeyCode.DPadDown]=Keybinds.TPDown,
    [Enum.KeyCode.DPadLeft]=Keybinds.AutoBat,[Enum.KeyCode.DPadRight]=Keybinds.SpeedToggle,
}
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        handleKeybindAction(input.KeyCode)
    elseif input.UserInputType == Enum.UserInputType.Gamepad1 or input.UserInputType == Enum.UserInputType.Gamepad2 then
        local mapped = CONTROLLER_MAP[input.KeyCode]
        if mapped then handleKeybindAction(mapped) else handleKeybindAction(input.KeyCode) end
    end
end)
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character; if not char then return end
    local localH = char:FindFirstChildOfClass("Humanoid"); local localHRP = char:FindFirstChild("HumanoidRootPart")
    if not localH or not localHRP then return end
    h = localH; hrp = localHRP
    -- Skip speed override while auto left/right is controlling movement
    if autoLeftEnabled or autoRightEnabled then
        if speedLbl then speedLbl.Text = "Speed: " .. string.format("%.1f", Vector3.new(localHRP.AssemblyLinearVelocity.X, 0, localHRP.AssemblyLinearVelocity.Z).Magnitude) end
        return
    end
    local md = localH.MoveDirection
    local spd = laggerToggled and LAGGER_SPEED or (speedToggled and CARRY_SPEED or NORMAL_SPEED)
    if md.Magnitude > 0 then localHRP.AssemblyLinearVelocity = Vector3.new(md.X*spd, localHRP.AssemblyLinearVelocity.Y, md.Z*spd) end
    if speedLbl then speedLbl.Text = "Speed: " .. string.format("%.1f", Vector3.new(localHRP.AssemblyLinearVelocity.X, 0, localHRP.AssemblyLinearVelocity.Z).Magnitude) end
end)
task.spawn(function()
    task.wait(2)
    if Enabled.AutoSteal then startAutoSteal() end
    if Enabled.AntiRagdoll then startAntiRagdoll() end
    if Enabled.InfiniteJump then if VisualSetters.InfiniteJump then VisualSetters.InfiniteJump(true) end; startInfiniteJump() end
    if Enabled.Unwalk then startUnwalk() end
    if Enabled.Optimizer then enableOptimizer() end
    if ultraModeEnabled then enableUltraMode() end
    if Enabled.RemoveAccessories then startRemoveAccessories() end
    local cam = workspace.CurrentCamera; if cam then cam.FieldOfView = FOV_VALUE end
    if _G.EmsaESPEnabled then if _G.EmsaSetESP then _G.EmsaSetESP(true) end; if setESPVisual then setESPVisual(true) end end
    if _G.EmsaTracerEnabled then if _G.EmsaSetTracer then _G.EmsaSetTracer(true) end; if setTracerVisual then setTracerVisual(true) end end
    task.defer(function()
        if VisualSetters.UltraMode then VisualSetters.UltraMode(ultraModeEnabled) end
        if VisualSetters.FastestSteal then VisualSetters.FastestSteal(fastestStealEnabled) end
        if VisualSetters.NoCam then VisualSetters.NoCam(noCamCollisionEnabled) end
        if VisualSetters.MedusaCounter then VisualSetters.MedusaCounter(medusaCounterEnabled) end
        if medusaCounterEnabled and LocalPlayer.Character then setupMedusaCounter(LocalPlayer.Character) end
        if _G.EmsaESPEnabled then if setESPVisual then setESPVisual(true) end; if _G.EmsaSetESP then _G.EmsaSetESP(true) end end
        if _G.EmsaTracerEnabled then if setTracerVisual then setTracerVisual(true) end; if _G.EmsaSetTracer then _G.EmsaSetTracer(true) end end
    end)
end)
local function setupChar(char)
    h = char:WaitForChild("Humanoid"); hrp = char:WaitForChild("HumanoidRootPart")
    lastKnownHealth = h and h.Health or 100
    if medusaCounterEnabled then setupMedusaCounter(char) end
    if harderHitAnimEnabled then task.wait(0.3); saveOriginalAnims(char); applyAnimPack(char) end
    local head = char:FindFirstChild("Head")
    if head then
        local bb = Instance.new("BillboardGui", head)
        bb.Size = UDim2.new(0,160,0,28); bb.StudsOffset = Vector3.new(0,3,0); bb.AlwaysOnTop = true
        speedLbl = Instance.new("TextLabel", bb)
        speedLbl.Size = UDim2.new(1,0,1,0); speedLbl.BackgroundTransparency = 1
        speedLbl.TextColor3 = Color3.fromRGB(18, 18, 18); speedLbl.Font = Enum.Font.GothamBold; speedLbl.TextScaled = true
    end
end
LocalPlayer.CharacterAdded:Connect(setupChar)
LocalPlayer.CharacterAdded:Connect(function()
    if autoLeftEnabled  then stopAutoLeft();  autoLeftEnabled  = false; if autoLeftSetter  then autoLeftSetter(false)  end end
    if autoRightEnabled then stopAutoRight(); autoRightEnabled = false; if autoRightSetter then autoRightSetter(false) end end
    autoSavedWalkSpeed = nil
    if autoInputLockConn then autoInputLockConn:Disconnect(); autoInputLockConn = nil end
end)
if LocalPlayer.Character then setupChar(LocalPlayer.Character) end
local TOKYO_OWNER = "mimifaye1235" -- Set your Roblox username here as owner
local tokyoUserTag = "tokyo user"
local tokyoOwnerTag = "tokyo owner"
local tokyoBannerColor = Color3.fromRGB(255, 255, 255)
local tokyoTaggedPlayers = {}
local function addTokyoBanner(player, isOwner)
    if tokyoTaggedPlayers[player] then return end
    tokyoTaggedPlayers[player] = true
    local function applyBanner(char)
        if not char then return end
        local head = char:FindFirstChild("Head"); if not head then return end
        -- Remove old banner if exists
        local old = head:FindFirstChild("TokyoBannerGui"); if old then old:Destroy() end
        local bb = Instance.new("BillboardGui", head)
        bb.Name = "TokyoBannerGui"
        bb.Size = UDim2.new(0, 120, 0, 22); bb.StudsOffset = Vector3.new(0, 2.5, 0)
        bb.AlwaysOnTop = true; bb.ZIndexBehavior = Enum.ZIndexBehavior.Global
        local bg = Instance.new("Frame", bb)
        bg.Size = UDim2.new(1, 0, 1, 0); bg.BackgroundColor3 = tokyoBannerColor
        bg.BackgroundTransparency = 0.15; bg.BorderSizePixel = 0
        Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 6)
        local stroke = Instance.new("UIStroke", bg); stroke.Color = Color3.fromRGB(200, 200, 200); stroke.Thickness = 1
        local lbl = Instance.new("TextLabel", bg)
        lbl.Size = UDim2.new(1, 0, 1, 0); lbl.BackgroundTransparency = 1
        lbl.Text = isOwner and tokyoOwnerTag or tokyoUserTag
        lbl.TextColor3 = Color3.fromRGB(0, 0, 0); lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 10; lbl.TextXAlignment = Enum.TextXAlignment.Center
    end
    if player.Character then applyBanner(player.Character) end
    player.CharacterAdded:Connect(function(char) task.wait(0.5); applyBanner(char) end)
end
pcall(function()
    LocalPlayer:SetAttribute("TokyoHubUser", true)
    if LocalPlayer.Name == TOKYO_OWNER or LocalPlayer.DisplayName == TOKYO_OWNER then
        LocalPlayer:SetAttribute("TokyoHubOwner", true)
    end
end)
local function checkPlayer(p)
    if p == LocalPlayer then return end
    local function watch()
        -- Poll for the attribute (set when they load the hub)
        for _ = 1, 30 do
            task.wait(1)
            local ok, isUser = pcall(function() return p:GetAttribute("TokyoHubUser") end)
            if ok and isUser then
                local _, isOwner = pcall(function() return p:GetAttribute("TokyoHubOwner") end)
                addTokyoBanner(p, isOwner)
                return
            end
        end
    end
    task.spawn(watch)
end
for _, p in ipairs(Players:GetPlayers()) do checkPlayer(p) end
Players.PlayerAdded:Connect(checkPlayer)
createSection(singleScroll, "Config", O())
do
    local saveBtnContainer = Instance.new("Frame", singleScroll)
    saveBtnContainer.Size = UDim2.new(1,0,0,26); saveBtnContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    saveBtnContainer.BorderSizePixel = 0; saveBtnContainer.LayoutOrder = O(); saveBtnContainer.ZIndex = 3
    Instance.new("UICorner", saveBtnContainer).CornerRadius = UDim.new(0, 5)
    local scStroke = Instance.new("UIStroke", saveBtnContainer); scStroke.Color = Color3.fromRGB(40, 40, 40); scStroke.Thickness = 1; scStroke.Transparency = 0
    local saveNameLabel = Instance.new("TextLabel", saveBtnContainer)
    saveNameLabel.Size = UDim2.new(0.5,-8,1,0); saveNameLabel.Position = UDim2.new(0,8,0,0)
    saveNameLabel.BackgroundTransparency = 1; saveNameLabel.Text = "Save Config"
    saveNameLabel.TextColor3 = Color3.fromRGB(255,255,255); saveNameLabel.Font = Enum.Font.GothamBold
    saveNameLabel.TextSize = 9; saveNameLabel.TextXAlignment = Enum.TextXAlignment.Left; saveNameLabel.ZIndex = 4
    local saveStatusLabel = Instance.new("TextLabel", saveBtnContainer)
    saveStatusLabel.Size = UDim2.new(0.3,0,1,0); saveStatusLabel.Position = UDim2.new(0.45,0,0,0)
    saveStatusLabel.BackgroundTransparency = 1; saveStatusLabel.Text = ""
    saveStatusLabel.TextColor3 = Color3.fromRGB(100,255,100); saveStatusLabel.Font = Enum.Font.Gotham
    saveStatusLabel.TextSize = 8; saveStatusLabel.TextXAlignment = Enum.TextXAlignment.Right; saveStatusLabel.ZIndex = 4
    local saveBadge = Instance.new("Frame", saveBtnContainer)
    saveBadge.Size = UDim2.new(0,42,0,18); saveBadge.Position = UDim2.new(1,-47,0.5,-9)
    saveBadge.BackgroundColor3 = Color3.fromRGB(0, 0, 0); saveBadge.BorderSizePixel = 0; saveBadge.ZIndex = 5
    Instance.new("UICorner", saveBadge).CornerRadius = UDim.new(0, 4)
    local saveBadgeStroke = Instance.new("UIStroke", saveBadge); saveBadgeStroke.Color = Color3.fromRGB(80,80,80); saveBadgeStroke.Thickness = 1; saveBadgeStroke.Transparency = 0
    local saveBadgeText = Instance.new("TextLabel", saveBadge)
    saveBadgeText.Size = UDim2.new(1,0,1,0); saveBadgeText.BackgroundTransparency = 1
    saveBadgeText.Text = "💾 Save"; saveBadgeText.TextColor3 = Color3.fromRGB(255,255,255)
    saveBadgeText.Font = Enum.Font.GothamBold; saveBadgeText.TextSize = 8; saveBadgeText.ZIndex = 6
    local saveClickBtn = Instance.new("TextButton", saveBtnContainer)
    saveClickBtn.Size = UDim2.new(1,0,1,0); saveClickBtn.BackgroundTransparency = 1; saveClickBtn.Text = ""; saveClickBtn.ZIndex = 7
    saveClickBtn.MouseButton1Click:Connect(function()
        local ok = saveConfig()
        saveStatusLabel.Text = ok and "✓ Saved!" or "✗ Failed"
        saveStatusLabel.TextColor3 = ok and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,80,80)
        saveBadgeText.Text = ok and "✓ Done" or "✗ Error"
        TweenService:Create(saveBadge, TweenInfo.new(0.1), {BackgroundColor3 = ok and Color3.fromRGB(20,60,20) or Color3.fromRGB(60,20,20)}):Play()
        task.delay(1.8, function()
            saveStatusLabel.Text = ""
            saveBadgeText.Text = "💾 Save"
            TweenService:Create(saveBadge, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30,30,30)}):Play()
        end)
    end)
    saveClickBtn.MouseEnter:Connect(function()
        TweenService:Create(saveBtnContainer, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(15,15,15)}):Play()
        TweenService:Create(scStroke, TweenInfo.new(0.15), {Transparency=0.3}):Play()
    end)
    saveClickBtn.MouseLeave:Connect(function()
        TweenService:Create(saveBtnContainer, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(18, 18, 18)}):Play()
        TweenService:Create(scStroke, TweenInfo.new(0.15), {Transparency=0}):Play()
    end)
end
local creditsLabel = Instance.new("TextLabel", main)
creditsLabel.Size = UDim2.new(0, 130, 0, 14)
creditsLabel.Position = UDim2.new(0, 6, 1, -16)
creditsLabel.AnchorPoint = Vector2.new(0, 0)
creditsLabel.BackgroundTransparency = 1
creditsLabel.Text = "credits to @thesparkwehad FOR INTRO"
creditsLabel.TextColor3 = Color3.fromRGB(55, 55, 70)
creditsLabel.Font = Enum.Font.Gotham
creditsLabel.TextSize = 8
creditsLabel.TextXAlignment = Enum.TextXAlignment.Left
creditsLabel.ZIndex = 10
print("tokyo loaded")
end) 
end)()
end
TOKYO_LAUNCH_MAIN()