--// Overgeared Universal - Rayfield
--// Auto Farm + quest pickup (max 3) + Auto Block + Skill Dodge

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Monsters = workspace:WaitForChild("Monsters")
local DebrisFolder = workspace:WaitForChild("Debris")

local SwordAttack = ReplicatedStorage:WaitForChild("SwordAttack")
local UseSkill = ReplicatedStorage:WaitForChild("UseSkill")
local UsePotion = ReplicatedStorage:WaitForChild("UsePotion")
local SetBlocking = ReplicatedStorage:WaitForChild("SetBlocking")
local SaveSettings = ReplicatedStorage:WaitForChild("SaveSettings")
local RedeemCode = ReplicatedStorage:WaitForChild("RedeemCode")

local MonsterData, QuestData, CodesData, PotionData = {}, {}, {}, {}
do
    local zen = ReplicatedStorage:FindFirstChild("ZenFolder")
    if zen then
        local monsterModule = zen:FindFirstChild("MonsterData")
        local questModule = zen:FindFirstChild("QuestData")
        local codesModule = zen:FindFirstChild("CodesData")
        local potionModule = zen:FindFirstChild("PotionData")
        if monsterModule then
            local ok, result = pcall(require, monsterModule)
            if ok and type(result) == "table" then MonsterData = result end
        end
        if questModule then
            local ok, result = pcall(require, questModule)
            if ok and type(result) == "table" then QuestData = result end
        end
        if codesModule then
            local ok, result = pcall(require, codesModule)
            if ok and type(result) == "table" then CodesData = result end
        end
        if potionModule then
            local ok, result = pcall(require, potionModule)
            if ok and type(result) == "table" then PotionData = result end
        end
    end
end

local fallbackCodes = {
    "BETA", "OVERGEARED", "15KVISIT", "RELEASED", "UPDATE1", "UPDATE2",
    "UPDATE3", "LGREED", "LIMITEDITEM1", "MAGNUS", "100KVISIT", "BETAPHASE",
    "ABSOLUTEONE", "UPDATE4", "LIMITED2", "200KVISIT", "UPDATE5",
}

_G.Overgeared = _G.Overgeared or {}
local G = _G.Overgeared

local defaults = {
    FarmEnabled = false,
    AttackEnabled = true,
    SkillsEnabled = false,
    SelectedMobs = {},
    AttackDelay = 0.45,
    SkillDelay = 1,
    OrbitSpeed = 0.30, -- legado; órbita não é mais usada
    OrbitRadius = 5, -- distância fixa do mob
    HoverHeight = 0,
    FarmPositionTolerance = 0.75,
    FarmPositionInterval = 0.10,
    NoClip = true,
    AntiAFK = true,
    AntiVoid = true,
    MenuKeybind = "RightShift",

    QuestEnabled = true,
    SelectedQuests = {},
    QuestTeleportDelay = 0.50,
    QuestInteractDelay = 0.75,
    QuestBusy = false,

    NativeAutoQuest = false,
    AutoPotionEnabled = false,
    SelectedPotions = {MediumHealthPotion = true},
    PotionThreshold = 90,
    PotionCooldown = 1,
    PotionBurstDelay = 0.05,
    RedeemCodeDelay = 0.20,
    RedeemCodesBusy = false,

    AutoBlockEnabled = true,
    AutoBlockDelay = 0.10,
    AutoBlockHoldTime = 0.20,
    AutoBlockRange = 22,
    AutoBlockFacing = 0.10,

    SkillDodgeEnabled = true,
    DodgeBehindDistance = 7,
    DodgeCasterRange = 40,
    DodgeAreaMargin = 5,
    DodgeCooldown = 0.35,
    EnemySliceMinLength = 15,
    EnemyAreaMinDiameter = 20,
    SlicePauseTime = 0.60,
    HazardRecoveryDelay = 0.25,
    AreaAwarenessRange = 120,
    AreaSafeSearchRadius = 80,
    AreaSafeSearchStep = 5,
    AreaSafeDirections = 24,
}

for key, value in pairs(defaults) do
    if G[key] == nil then G[key] = value end
end

if G.RuntimeSchema ~= 2 then
    G.RuntimeSchema = 2
    G.HoverHeight = 0
    G.FarmPositionInterval = 0.10
    G.FarmPositionTolerance = 0.75
    G.FarmFreezeCharacter = nil
end

local function getCharacterData()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
    if not character or not humanoid or humanoid.Health <= 0 or not root then return nil end
    return character, humanoid, root
end

local function getModelRoot(model)
    return model and (model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart)
end

local function isAlive(model)
    if not model or not model.Parent then return false end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid then return humanoid.Health > 0 end
    local health = model:GetAttribute("Health")
    return health == nil or health > 0
end

local function isMobModel(instance)
    return instance:IsA("Model")
        and instance:FindFirstChildOfClass("Humanoid") ~= nil
        and getModelRoot(instance) ~= nil
end

local function collectMobModels()
    local result = {}
    for _, child in ipairs(Monsters:GetChildren()) do
        if isMobModel(child) then
            table.insert(result, child)
        elseif child:IsA("Folder") or child:IsA("Model") then
            for _, descendant in ipairs(child:GetChildren()) do
                if isMobModel(descendant) then table.insert(result, descendant) end
            end
        end
    end
    return result
end

local function findNearestSelectedMob()
    local _, _, root = getCharacterData()
    if not root then return nil end
    local best, bestDistance
    bestDistance = math.huge
    for _, mob in ipairs(collectMobModels()) do
        if G.SelectedMobs[mob.Name] and isAlive(mob) then
            local mobRoot = getModelRoot(mob)
            local distance = (mobRoot.Position - root.Position).Magnitude
            if distance < bestDistance then
                best, bestDistance = mob, distance
            end
        end
    end
    return best
end

-- Auto Farm
local currentTarget
local fixedFarmCFrame
local movementPausedUntil = 0
local activeEnemyAreas = {}
local lastFarmPositionUpdate = 0

local function hasActiveEnemyArea()
    for area in pairs(activeEnemyAreas) do
        if area.Parent then return true end
        activeEnemyAreas[area] = nil
    end
    return false
end

local function farmIsPaused()
    return G.QuestBusy or hasActiveEnemyArea() or os.clock() < movementPausedUntil
end

task.spawn(function()
    while task.wait(G.FarmEnabled and math.max(G.AttackDelay, 0.05) or 0.15) do
        if G.FarmEnabled and G.AttackEnabled and not farmIsPaused() then
            pcall(function() SwordAttack:FireServer() end)
        end
    end
end)

task.spawn(function()
    while task.wait(G.FarmEnabled and math.max(G.SkillDelay, 0.10) or 0.15) do
        if G.FarmEnabled and G.SkillsEnabled and not farmIsPaused() then
            pcall(function()
                UseSkill:FireServer(1)
                UseSkill:FireServer(2)
                UseSkill:FireServer(3)
            end)
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if not G.FarmEnabled or farmIsPaused() then return end
    if currentTarget and not isAlive(currentTarget) then
        currentTarget = nil
        fixedFarmCFrame = nil
    end
    if not currentTarget or not G.SelectedMobs[currentTarget.Name] then
        currentTarget = findNearestSelectedMob()
        fixedFarmCFrame = nil
    end
    if not currentTarget then return end

    local character, _, root = getCharacterData()
    local mobRoot = getModelRoot(currentTarget)
    if not character or not mobRoot then
        currentTarget = nil
        fixedFarmCFrame = nil
        return
    end

    if not fixedFarmCFrame then
        local away = Vector3.new(
            root.Position.X - mobRoot.Position.X,
            0,
            root.Position.Z - mobRoot.Position.Z
        )
        if away.Magnitude < 0.1 then
            away = -Vector3.new(mobRoot.CFrame.LookVector.X, 0, mobRoot.CFrame.LookVector.Z)
        end
        if away.Magnitude < 0.1 then away = Vector3.zAxis end
        away = away.Unit
        local fixedPosition = mobRoot.Position
            + away * G.OrbitRadius
            + Vector3.new(0, G.HoverHeight, 0)
        fixedFarmCFrame = CFrame.lookAt(fixedPosition, mobRoot.Position)
    end

    local now = os.clock()
    if now - lastFarmPositionUpdate < G.FarmPositionInterval then return end
    lastFarmPositionUpdate = now

    if (root.Position - fixedFarmCFrame.Position).Magnitude > G.FarmPositionTolerance then
        root.CFrame = fixedFarmCFrame
    end
end)

-- NoClip / Anti Void / Anti AFK
RunService.Stepped:Connect(function()
    if not (G.FarmEnabled and G.NoClip) then return end
    local character = LocalPlayer.Character
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
    end
end)

local lastSafeCFrame
task.spawn(function()
    while task.wait(0.5) do
        local _, _, root = getCharacterData()
        if root and root.Position.Y > -50 then lastSafeCFrame = root.CFrame end
    end
end)

RunService.Heartbeat:Connect(function()
    if not G.AntiVoid then return end
    local _, _, root = getCharacterData()
    if root and root.Position.Y < -100 and lastSafeCFrame then
        root.CFrame = lastSafeCFrame + Vector3.new(0, 5, 0)
    end
end)

LocalPlayer.Idled:Connect(function()
    if G.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.zero)
    end
end)

-- Local Auto Potion (legacy behavior, independent from native SaveSettings).
local lastPotionUse = 0
local potionBusy = false
RunService.Heartbeat:Connect(function()
    if not G.AutoPotionEnabled or potionBusy then return end
    if os.clock() - lastPotionUse < G.PotionCooldown then return end

    local _, humanoid = getCharacterData()
    if not humanoid or humanoid.MaxHealth <= 0 then return end

    local healthPercent = humanoid.Health / humanoid.MaxHealth * 100
    if healthPercent >= G.PotionThreshold then return end

    lastPotionUse = os.clock()
    potionBusy = true
    task.spawn(function()
        local selected = {}
        for potionId, enabled in pairs(G.SelectedPotions) do
            if enabled then table.insert(selected, potionId) end
        end
        table.sort(selected)
        for _, potionId in ipairs(selected) do
            if not G.AutoPotionEnabled then break end
            pcall(function() UsePotion:FireServer(potionId) end)
            task.wait(math.max(G.PotionBurstDelay, 0))
        end
        potionBusy = false
    end)
end)

-- Quest pickup: one pass only, maximum of three selected NPCs.
local function firePrompt(prompt)
    if fireproximityprompt then
        pcall(fireproximityprompt, prompt, prompt.HoldDuration or 0)
    else
        pcall(function()
            prompt:InputHoldBegin()
            task.wait((prompt.HoldDuration or 0) + 0.1)
            prompt:InputHoldEnd()
        end)
    end
end

local function selectedQuestIds()
    local result = {}
    for questId, enabled in pairs(G.SelectedQuests) do
        if enabled then table.insert(result, questId) end
    end
    table.sort(result, function(a, b)
        return (tonumber(a:match("%d+")) or 999999) < (tonumber(b:match("%d+")) or 999999)
    end)
    while #result > 3 do table.remove(result) end
    return result
end

local function pickupSelectedQuests()
    if G.QuestBusy or not G.QuestEnabled then return end
    local questIds = selectedQuestIds()
    if #questIds == 0 then return end
    G.QuestBusy = true
    task.spawn(function()
        pcall(function()
            local folder = workspace:FindFirstChild("QuestNPC")
            if not folder then return end
            for _, questId in ipairs(questIds) do
                if not G.QuestEnabled then break end
                local npc = folder:FindFirstChild(questId)
                local character, _, root = getCharacterData()
                if npc and character and root then
                    local npcPosition = npc:GetPivot().Position
                    root.CFrame = CFrame.lookAt(
                        npcPosition + Vector3.new(0, 2, 3),
                        npcPosition + Vector3.new(0, 2, 0)
                    )
                    task.wait(math.max(G.QuestTeleportDelay, 0))
                    local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt then firePrompt(prompt) end
                    task.wait(math.max(G.QuestInteractDelay, 0))
                end
            end
        end)
        G.QuestBusy = false
    end)
end

-- Native game settings and code redemption.
local function setNativeSetting(name, value)
    pcall(function()
        SaveSettings:FireServer(name, value)
    end)
end

local function getRedeemableCodes()
    local codes = {}
    for code, data in pairs(CodesData) do
        if type(code) == "string" and (type(data) ~= "table" or data.Active ~= false) then
            table.insert(codes, code)
        end
    end
    if #codes == 0 then
        for _, code in ipairs(fallbackCodes) do table.insert(codes, code) end
    end
    table.sort(codes)
    return codes
end

local function redeemAllCodes()
    if G.RedeemCodesBusy then return end
    G.RedeemCodesBusy = true
    task.spawn(function()
        for _, code in ipairs(getRedeemableCodes()) do
            pcall(function() RedeemCode:FireServer(code) end)
            task.wait(math.max(G.RedeemCodeDelay, 0.05))
        end
        G.RedeemCodesBusy = false
    end)
end

-- Auto Block (known-good logic)
local defending = false
local manualDefense = false
local defenseGeneration = 0
local watchedMobs = {}
local lastAnimationActivation = {}

local function setDefending(value)
    if defending == value then return end
    defending = value
    SetBlocking:FireServer(value)
end

local function defendFor(duration)
    defenseGeneration += 1
    local generation = defenseGeneration
    setDefending(true)
    task.delay(duration, function()
        if generation == defenseGeneration and not manualDefense then setDefending(false) end
    end)
end

local function mobThreatensPlayer(mobRoot, playerRoot)
    local offset = playerRoot.Position - mobRoot.Position
    if offset.Magnitude == 0 or offset.Magnitude > G.AutoBlockRange then return false end
    return mobRoot.CFrame.LookVector:Dot(offset.Unit) >= G.AutoBlockFacing
end

local function processMobAnimation(mob, humanoid, mobRoot, track)
    if not G.AutoBlockEnabled or not mob.Parent or humanoid.Health <= 0 then return end
    if not track.Animation or track.Animation.AnimationId == "" or track.Looped then return end
    local _, _, playerRoot = getCharacterData()
    if not playerRoot or not mobThreatensPlayer(mobRoot, playerRoot) then return end

    local animationId = track.Animation.AnimationId
    local now = os.clock()
    lastAnimationActivation[mob] = lastAnimationActivation[mob] or {}
    if now - (lastAnimationActivation[mob][animationId] or 0) < 0.05 then return end
    lastAnimationActivation[mob][animationId] = now

    task.delay(math.max(G.AutoBlockDelay, 0), function()
        local _, _, currentRoot = getCharacterData()
        local currentMobRoot = getModelRoot(mob)
        if G.AutoBlockEnabled and currentRoot and currentMobRoot
            and mob.Parent and humanoid.Health > 0
            and mobThreatensPlayer(currentMobRoot, currentRoot) then
            defendFor(math.max(G.AutoBlockHoldTime, 0.01))
        end
    end)
end

local function watchMob(mob)
    if watchedMobs[mob] or not isMobModel(mob) then return end
    local humanoid = mob:FindFirstChildOfClass("Humanoid")
    local mobRoot = getModelRoot(mob)
    local animator = humanoid and (humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator", 5))
    if not humanoid or not mobRoot or not animator then return end
    watchedMobs[mob] = animator.AnimationPlayed:Connect(function(track)
        processMobAnimation(mob, humanoid, mobRoot, track)
    end)
    mob.Destroying:Connect(function()
        if watchedMobs[mob] then watchedMobs[mob]:Disconnect() end
        watchedMobs[mob], lastAnimationActivation[mob] = nil, nil
    end)
end

local function scanMobsForBlock()
    for _, mob in ipairs(collectMobModels()) do task.spawn(watchMob, mob) end
end
scanMobsForBlock()
Monsters.DescendantAdded:Connect(function(instance)
    if instance:IsA("Model") then task.defer(watchMob, instance) end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.F then
        manualDefense = true
        defenseGeneration += 1
        setDefending(true)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F then
        manualDefense = false
        setDefending(false)
    end
end)

-- Skill Dodge
local lastDodge = 0
local recentAreas = {}

local function horizontalUnit(vector, fallback)
    local horizontal = Vector3.new(vector.X, 0, vector.Z)
    return horizontal.Magnitude < 0.001 and fallback or horizontal.Unit
end

local function isEnemySlice(instance)
    return instance:IsA("BasePart")
        and instance.Name:lower() == "slice"
        and math.max(instance.Size.X, instance.Size.Y, instance.Size.Z) >= G.EnemySliceMinLength
end

local function isEnemyArea(instance)
    if not instance:IsA("Part") or instance.Shape ~= Enum.PartType.Cylinder or not instance.Anchored then return false end
    local red = instance.Color.R >= 0.60
        and instance.Color.R > instance.Color.G * 1.5
        and instance.Color.R > instance.Color.B * 1.5
    return red and math.max(instance.Size.Y, instance.Size.Z) >= G.EnemyAreaMinDiameter
end

local function safeHorizontalDistance(origin, direction, distance, character)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character, DebrisFolder, Monsters}
    params.IgnoreWater = true
    local hit = workspace:Raycast(origin, direction * distance, params)
    return hit and math.max(hit.Distance - 2, 0) or distance
end

local function teleportHorizontal(character, root, direction, distance)
    direction = horizontalUnit(direction, Vector3.xAxis)
    local safeDistance = safeHorizontalDistance(root.Position, direction, distance, character)
    if safeDistance < 3 then return false end
    local destination = Vector3.new(
        root.Position.X + direction.X * safeDistance,
        root.Position.Y,
        root.Position.Z + direction.Z * safeDistance
    )
    local look = horizontalUnit(root.CFrame.LookVector, -Vector3.zAxis)
    character:PivotTo(CFrame.lookAt(destination, destination + look))
    lastDodge = os.clock()
    return true
end

local function findSliceCaster(slice)
    local nearest, nearestRoot, nearestDistance = nil, nil, G.DodgeCasterRange
    for _, mob in ipairs(collectMobModels()) do
        local root = getModelRoot(mob)
        if root and isAlive(mob) then
            local distance = (slice.Position - root.Position).Magnitude
            if distance < nearestDistance then
                nearest, nearestRoot, nearestDistance = mob, root, distance
            end
        end
    end
    return nearest, nearestRoot
end

local function dodgeSlice(slice)
    if not G.SkillDodgeEnabled or os.clock() - lastDodge < G.DodgeCooldown then return end
    local character, _, playerRoot = getCharacterData()
    local _, casterRoot = findSliceCaster(slice)
    if not character or not casterRoot then return end
    movementPausedUntil = math.max(movementPausedUntil, os.clock() + G.SlicePauseTime)
    local forward = horizontalUnit(casterRoot.CFrame.LookVector, -Vector3.zAxis)
    local behind = casterRoot.Position - forward * G.DodgeBehindDistance
    behind = Vector3.new(behind.X, playerRoot.Position.Y, behind.Z)
    local offset = Vector3.new(behind.X - playerRoot.Position.X, 0, behind.Z - playerRoot.Position.Z)
    if offset.Magnitude >= 0.5 then teleportHorizontal(character, playerRoot, offset.Unit, offset.Magnitude) end
end

local function collectEnemyAreas()
    local areas = {}
    for _, instance in ipairs(DebrisFolder:GetDescendants()) do
        if isEnemyArea(instance) then table.insert(areas, instance) end
    end
    return areas
end

local function pointInsideArea(point, area, margin)
    if not area.Parent then return false end
    local localPoint = area.CFrame:PointToObjectSpace(point)
    local radialDistance = Vector2.new(localPoint.Y, localPoint.Z).Magnitude
    local radius = math.max(area.Size.Y, area.Size.Z) / 2 + margin
    return radialDistance <= radius and math.abs(localPoint.X) <= 12
end

local function registerActiveArea(area)
    if activeEnemyAreas[area] then return end
    activeEnemyAreas[area] = true
    area.AncestryChanged:Connect(function(_, parent)
        if parent then return end
        activeEnemyAreas[area] = nil
        movementPausedUntil = math.max(
            movementPausedUntil,
            os.clock() + G.HazardRecoveryDelay
        )
    end)
end

local function findSafeAreaDestination(root, character, triggeringArea, areas)
    local origin = root.Position
    local preferred = horizontalUnit(origin - triggeringArea.Position, root.CFrame.RightVector)
    local baseAngle = math.atan2(preferred.Z, preferred.X)
    local directions = math.max(math.floor(G.AreaSafeDirections), 8)
    local step = math.max(G.AreaSafeSearchStep, 1)

    for distance = step, G.AreaSafeSearchRadius, step do
        local bestPoint, bestScore
        for index = 0, directions - 1 do
            local angle = baseAngle + index / directions * math.pi * 2
            local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
            local candidate = Vector3.new(
                origin.X + direction.X * distance,
                origin.Y,
                origin.Z + direction.Z * distance
            )

            local pathDistance = safeHorizontalDistance(origin, direction, distance, character)
            if pathDistance + 0.5 < distance then continue end

            local safe = true
            local minimumClearance = math.huge
            for _, otherArea in ipairs(areas) do
                if pointInsideArea(candidate, otherArea, G.DodgeAreaMargin) then
                    safe = false
                    break
                end
                local localPoint = otherArea.CFrame:PointToObjectSpace(candidate)
                local radial = Vector2.new(localPoint.Y, localPoint.Z).Magnitude
                local radius = math.max(otherArea.Size.Y, otherArea.Size.Z) / 2
                minimumClearance = math.min(minimumClearance, radial - radius)
            end

            if safe then
                local score = minimumClearance + direction:Dot(preferred) * 2
                if not bestScore or score > bestScore then
                    bestPoint, bestScore = candidate, score
                end
            end
        end
        if bestPoint then return bestPoint end
    end

    return nil
end

local function dodgeArea(area)
    local position = area.Position
    local key = string.format("%d:%d:%d", math.round(position.X), math.round(position.Y), math.round(position.Z))
    local now = os.clock()
    local duplicateArea = recentAreas[key] and now - recentAreas[key] < 1
    if not G.SkillDodgeEnabled then return end

    local character, _, root = getCharacterData()
    if not character then return end
    local localPosition = area.CFrame:PointToObjectSpace(root.Position)
    local radialDistance = Vector2.new(localPosition.Y, localPosition.Z).Magnitude
    local requiredRadius = math.max(area.Size.Y, area.Size.Z) / 2 + G.DodgeAreaMargin
    local wasAlreadyAvoidingAreas = hasActiveEnemyArea()
    local allAreas = collectEnemyAreas()

    if radialDistance > requiredRadius then
        if wasAlreadyAvoidingAreas or duplicateArea then
            for _, otherArea in ipairs(allAreas) do
                local horizontalDistance = Vector2.new(
                    otherArea.Position.X - root.Position.X,
                    otherArea.Position.Z - root.Position.Z
                ).Magnitude
                if horizontalDistance <= G.AreaAwarenessRange then
                    registerActiveArea(otherArea)
                end
            end
        end
        return
    end

    if not duplicateArea then
        recentAreas[key] = now
        task.delay(1.5, function() if recentAreas[key] == now then recentAreas[key] = nil end end)
    end

    for _, otherArea in ipairs(allAreas) do
        local horizontalDistance = Vector2.new(
            otherArea.Position.X - root.Position.X,
            otherArea.Position.Z - root.Position.Z
        ).Magnitude
        if horizontalDistance <= G.AreaAwarenessRange then
            registerActiveArea(otherArea)
        end
    end

    if duplicateArea then return end

    local destination = findSafeAreaDestination(root, character, area, allAreas)
    if not destination then return end
    local offset = Vector3.new(destination.X - root.Position.X, 0, destination.Z - root.Position.Z)
    if offset.Magnitude >= 0.5 then
        teleportHorizontal(character, root, offset.Unit, offset.Magnitude)
    end
end

DebrisFolder.DescendantAdded:Connect(function(instance)
    task.defer(function()
        if isEnemySlice(instance) then
            dodgeSlice(instance)
        elseif isEnemyArea(instance) then
            dodgeArea(instance)
        end
    end)
end)

-- Rayfield UI
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window = Rayfield:CreateWindow({
    Name = "Overgeared Universal",
    Icon = "swords",
    LoadingTitle = "Overgeared Universal",
    LoadingSubtitle = "Farm, defesa e esquiva",
    ShowText = "Overgeared",
    Theme = "Default",
    -- A troca de visibilidade é controlada pelo keybind configurável abaixo.
    -- Nunca use Unknown aqui: cliques do mouse também possuem KeyCode.Unknown.
    -- F12 fica apenas como fallback interno; o atalho configurável é tratado abaixo.
    ToggleUIKeybind = Enum.KeyCode.F12,
    DisableRayfieldPrompts = true,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "OvergearedUniversal",
        FileName = "SettingsV5",
    },
    Discord = {Enabled = false, Invite = "", RememberJoins = false},
    KeySystem = false,
})

local FarmTab = Window:CreateTab("Farm", "swords")
local QuestTab = Window:CreateTab("Quests", "scroll-text")
local DefenseTab = Window:CreateTab("Defesa", "shield")
local DodgeTab = Window:CreateTab("Esquiva", "move")
local NativeTab = Window:CreateTab("Nativo", "gamepad-2")
local ExtraTab = Window:CreateTab("Extras", "settings")

local mobNameByLabel = {}
local mobLabelByName = {}

local function buildMobLabels()
    local found, names = {}, {}
    for _, mob in ipairs(collectMobModels()) do
        if not found[mob.Name] then found[mob.Name] = true table.insert(names, mob.Name) end
    end
    table.sort(names, function(a, b)
        local levelA = MonsterData[a] and MonsterData[a].Level or math.huge
        local levelB = MonsterData[b] and MonsterData[b].Level or math.huge
        return levelA == levelB and a < b or levelA < levelB
    end)
    table.clear(mobNameByLabel)
    table.clear(mobLabelByName)
    local labels = {}
    for _, name in ipairs(names) do
        local data = MonsterData[name]
        local displayName = data and data.Name or name
        local level = data and data.Level
        local label = level
            and string.format("%s [Lv.%d]", displayName, level)
            or displayName
        mobNameByLabel[label] = name
        mobLabelByName[name] = label
        table.insert(labels, label)
    end
    return labels
end

local mobLabels = buildMobLabels()
local initialMobs = {}
for name, enabled in pairs(G.SelectedMobs) do
    if enabled and mobLabelByName[name] then table.insert(initialMobs, mobLabelByName[name]) end
end

FarmTab:CreateSection("Alvos")
local MobDropdown = FarmTab:CreateDropdown({
    Name = "Mobs selecionados",
    Options = mobLabels,
    CurrentOption = initialMobs,
    MultipleOptions = true,
    Flag = "SelectedMobsV2",
    Callback = function(options)
        table.clear(G.SelectedMobs)
        for _, label in ipairs(options) do
            local name = mobNameByLabel[label] or label
            G.SelectedMobs[name] = true
        end
        currentTarget = nil
        fixedFarmCFrame = nil
    end,
})
FarmTab:CreateButton({Name = "Atualizar lista de mobs", Callback = function()
    mobLabels = buildMobLabels()
    MobDropdown:Refresh(mobLabels)
    scanMobsForBlock()
end})

FarmTab:CreateSection("Farm")
FarmTab:CreateToggle({Name = "Auto Farm", CurrentValue = G.FarmEnabled, Flag = "FarmEnabled", Callback = function(v) G.FarmEnabled = v end})
FarmTab:CreateToggle({Name = "Auto Ataque", CurrentValue = G.AttackEnabled, Flag = "AttackEnabled", Callback = function(v) G.AttackEnabled = v end})
FarmTab:CreateToggle({Name = "Auto Skills 1, 2 e 3", CurrentValue = G.SkillsEnabled, Flag = "SkillsEnabled", Callback = function(v) G.SkillsEnabled = v end})
FarmTab:CreateSlider({Name = "Delay do ataque", Range = {0.05, 2}, Increment = 0.05, Suffix = "s", CurrentValue = G.AttackDelay, Flag = "AttackDelay", Callback = function(v) G.AttackDelay = v end})
FarmTab:CreateSlider({Name = "Delay das skills", Range = {0.1, 10}, Increment = 0.1, Suffix = "s", CurrentValue = G.SkillDelay, Flag = "SkillDelay", Callback = function(v) G.SkillDelay = v end})
FarmTab:CreateSlider({Name = "Distância fixa do mob", Range = {2, 15}, Increment = 0.5, CurrentValue = G.OrbitRadius, Flag = "OrbitRadius", Callback = function(v) G.OrbitRadius = v fixedFarmCFrame = nil end})
FarmTab:CreateSlider({Name = "Altura fixa", Range = {0, 25}, Increment = 0.5, CurrentValue = G.HoverHeight, Flag = "HoverHeight", Callback = function(v) G.HoverHeight = v fixedFarmCFrame = nil end})
FarmTab:CreateSlider({Name = "Tolerância da posição", Range = {0.1, 5}, Increment = 0.05, Suffix = " studs", CurrentValue = G.FarmPositionTolerance, Flag = "FarmPositionTolerance", Callback = function(v) G.FarmPositionTolerance = v end})
FarmTab:CreateSlider({Name = "Intervalo de correção da posição", Range = {0.05, 1}, Increment = 0.05, Suffix = "s", CurrentValue = G.FarmPositionInterval, Flag = "FarmPositionInterval", Callback = function(v) G.FarmPositionInterval = v end})

local questLabels, questIdByLabel = {}, {}
for questId, data in pairs(QuestData) do
    local label = string.format(
        "%s [Lv.%d+]",
        data.Title or data.MonsterId or "Quest",
        data.MinLevel or 0
    )
    table.insert(questLabels, label)
    questIdByLabel[label] = questId
end
table.sort(questLabels, function(a, b)
    local idA, idB = questIdByLabel[a], questIdByLabel[b]
    local dataA, dataB = QuestData[idA] or {}, QuestData[idB] or {}
    local levelA, levelB = dataA.MinLevel or math.huge, dataB.MinLevel or math.huge
    if levelA == levelB then return a < b end
    return levelA < levelB
end)

local initialQuests = {}
for _, label in ipairs(questLabels) do
    if G.SelectedQuests[questIdByLabel[label]] then table.insert(initialQuests, label) end
end
while #initialQuests > 3 do table.remove(initialQuests) end
table.clear(G.SelectedQuests)
for _, label in ipairs(initialQuests) do
    G.SelectedQuests[questIdByLabel[label]] = true
end
local questDropdown
local questGuard = false
local lastValidQuestLabels = table.clone(initialQuests)

QuestTab:CreateSection("Selecione no máximo 3")
questDropdown = QuestTab:CreateDropdown({
    Name = "Quests",
    Options = questLabels,
    CurrentOption = initialQuests,
    MultipleOptions = true,
    Flag = "SelectedQuestsV2",
    Callback = function(options)
        if questGuard then return end
        if #options > 3 then
            questGuard = true
            questDropdown:Set(lastValidQuestLabels)
            questGuard = false
            return
        end
        lastValidQuestLabels = table.clone(options)
        table.clear(G.SelectedQuests)
        for _, label in ipairs(options) do
            local id = questIdByLabel[label]
            if id then G.SelectedQuests[id] = true end
        end
    end,
})
QuestTab:CreateToggle({Name = "Permitir pegar quests", CurrentValue = G.QuestEnabled, Flag = "QuestEnabled", Callback = function(v) G.QuestEnabled = v end})
QuestTab:CreateSlider({Name = "Espera após teleportar", Range = {0, 3}, Increment = 0.05, Suffix = "s", CurrentValue = G.QuestTeleportDelay, Flag = "QuestTeleportDelay", Callback = function(v) G.QuestTeleportDelay = v end})
QuestTab:CreateSlider({Name = "Espera entre quests", Range = {0, 3}, Increment = 0.05, Suffix = "s", CurrentValue = G.QuestInteractDelay, Flag = "QuestInteractDelay", Callback = function(v) G.QuestInteractDelay = v end})
QuestTab:CreateButton({Name = "Teleportar e pegar quests", Callback = pickupSelectedQuests})

QuestTab:CreateSection("Sistema nativo")
QuestTab:CreateToggle({
    Name = "Repetir quest automaticamente",
    CurrentValue = G.NativeAutoQuest,
    Flag = "NativeAutoQuest",
    Callback = function(value)
        G.NativeAutoQuest = value
        setNativeSetting("AutoQuestRepeat", value)
    end,
})

DefenseTab:CreateSection("Auto Block")
DefenseTab:CreateToggle({Name = "Auto Block", CurrentValue = G.AutoBlockEnabled, Flag = "AutoBlockEnabled", Callback = function(v) G.AutoBlockEnabled = v if not v and not manualDefense then setDefending(false) end end})
DefenseTab:CreateSlider({Name = "Delay para bloquear", Range = {0, 1}, Increment = 0.001, Suffix = "s", CurrentValue = G.AutoBlockDelay, Flag = "AutoBlockDelay", Callback = function(v) G.AutoBlockDelay = v end})
DefenseTab:CreateSlider({Name = "Tempo segurando defesa", Range = {0.01, 1}, Increment = 0.01, Suffix = "s", CurrentValue = G.AutoBlockHoldTime, Flag = "AutoBlockHoldTime", Callback = function(v) G.AutoBlockHoldTime = v end})
DefenseTab:CreateSlider({Name = "Alcance", Range = {5, 100}, Increment = 1, Suffix = " studs", CurrentValue = G.AutoBlockRange, Flag = "AutoBlockRange", Callback = function(v) G.AutoBlockRange = v end})
DefenseTab:CreateSlider({Name = "Limite de direção", Range = {-1, 1}, Increment = 0.05, CurrentValue = G.AutoBlockFacing, Flag = "AutoBlockFacing", Callback = function(v) G.AutoBlockFacing = v end})

DodgeTab:CreateSection("Desvio de habilidades")
DodgeTab:CreateToggle({Name = "Desviar habilidades", CurrentValue = G.SkillDodgeEnabled, Flag = "SkillDodgeEnabled", Callback = function(v) G.SkillDodgeEnabled = v end})
DodgeTab:CreateSlider({Name = "Distância atrás do mob", Range = {3, 20}, Increment = 0.5, Suffix = " studs", CurrentValue = G.DodgeBehindDistance, Flag = "DodgeBehindDistance", Callback = function(v) G.DodgeBehindDistance = v end})
DodgeTab:CreateSlider({Name = "Busca do lançador", Range = {10, 100}, Increment = 1, Suffix = " studs", CurrentValue = G.DodgeCasterRange, Flag = "DodgeCasterRange", Callback = function(v) G.DodgeCasterRange = v end})
DodgeTab:CreateSlider({Name = "Margem do círculo", Range = {1, 20}, Increment = 0.5, Suffix = " studs", CurrentValue = G.DodgeAreaMargin, Flag = "DodgeAreaMargin", Callback = function(v) G.DodgeAreaMargin = v end})
DodgeTab:CreateSlider({Name = "Cooldown da esquiva", Range = {0, 2}, Increment = 0.05, Suffix = "s", CurrentValue = G.DodgeCooldown, Flag = "DodgeCooldown", Callback = function(v) G.DodgeCooldown = v end})
DodgeTab:CreateSlider({Name = "Pausa após rajada", Range = {0, 3}, Increment = 0.05, Suffix = "s", CurrentValue = G.SlicePauseTime, Flag = "SlicePauseTime", Callback = function(v) G.SlicePauseTime = v end})
DodgeTab:CreateSlider({Name = "Espera após acabar o círculo", Range = {0, 3}, Increment = 0.05, Suffix = "s", CurrentValue = G.HazardRecoveryDelay, Flag = "HazardRecoveryDelay", Callback = function(v) G.HazardRecoveryDelay = v end})
DodgeTab:CreateSlider({Name = "Tamanho mínimo da rajada", Range = {5, 30}, Increment = 0.5, CurrentValue = G.EnemySliceMinLength, Flag = "EnemySliceMinLength", Callback = function(v) G.EnemySliceMinLength = v end})
DodgeTab:CreateSlider({Name = "Diâmetro mínimo do círculo", Range = {5, 50}, Increment = 0.5, CurrentValue = G.EnemyAreaMinDiameter, Flag = "EnemyAreaMinDiameter", Callback = function(v) G.EnemyAreaMinDiameter = v end})
DodgeTab:CreateSlider({Name = "Alcance para observar círculos", Range = {30, 250}, Increment = 5, Suffix = " studs", CurrentValue = G.AreaAwarenessRange, Flag = "AreaAwarenessRange", Callback = function(v) G.AreaAwarenessRange = v end})
DodgeTab:CreateSlider({Name = "Raio para procurar saída segura", Range = {20, 150}, Increment = 5, Suffix = " studs", CurrentValue = G.AreaSafeSearchRadius, Flag = "AreaSafeSearchRadius", Callback = function(v) G.AreaSafeSearchRadius = v end})
DodgeTab:CreateSlider({Name = "Precisão da busca de saída", Range = {8, 36}, Increment = 2, Suffix = " direções", CurrentValue = G.AreaSafeDirections, Flag = "AreaSafeDirections", Callback = function(v) G.AreaSafeDirections = v end})

NativeTab:CreateSection("Auto Potion")
NativeTab:CreateToggle({
    Name = "Auto Potion",
    CurrentValue = G.AutoPotionEnabled,
    Flag = "AutoPotionEnabled",
    Callback = function(value)
        G.AutoPotionEnabled = value
    end,
})

local potionIds = {
    "HealthPotion",
    "MediumHealthPotion",
    "LargeHealthPotion",
    "BigHealthPotion",
    "DefencePotion",
}
local potionLabels = {}
local potionIdByLabel = {}
local potionLabelById = {}
for _, potionId in ipairs(potionIds) do
    local data = PotionData[potionId] or {}
    local name = data.Name or potionId
    local label = data.Health
        and string.format("%s (+%d HP)", name, data.Health)
        or name
    potionIdByLabel[label] = potionId
    potionLabelById[potionId] = label
    table.insert(potionLabels, label)
end

local initialPotionLabels = {}
for _, potionId in ipairs(potionIds) do
    if G.SelectedPotions[potionId] then
        table.insert(initialPotionLabels, potionLabelById[potionId])
    end
end

NativeTab:CreateDropdown({
    Name = "Potions para usar",
    Options = potionLabels,
    CurrentOption = initialPotionLabels,
    MultipleOptions = true,
    Flag = "SelectedPotionsV1",
    Callback = function(options)
        table.clear(G.SelectedPotions)
        for _, label in ipairs(options) do
            local potionId = potionIdByLabel[label]
            if potionId then G.SelectedPotions[potionId] = true end
        end
    end,
})
NativeTab:CreateSlider({
    Name = "Usar potion abaixo de",
    Range = {1, 100},
    Increment = 1,
    Suffix = "% HP",
    CurrentValue = G.PotionThreshold,
    Flag = "PotionThreshold",
    Callback = function(value)
        G.PotionThreshold = value
    end,
})
NativeTab:CreateSlider({
    Name = "Cooldown da potion",
    Range = {0.1, 10},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = G.PotionCooldown,
    Flag = "PotionCooldown",
    Callback = function(value) G.PotionCooldown = value end,
})
NativeTab:CreateSlider({
    Name = "Intervalo entre potions",
    Range = {0, 1},
    Increment = 0.01,
    Suffix = "s",
    CurrentValue = G.PotionBurstDelay,
    Flag = "PotionBurstDelay",
    Callback = function(value) G.PotionBurstDelay = value end,
})

NativeTab:CreateSection("Códigos")
NativeTab:CreateSlider({
    Name = "Intervalo entre códigos",
    Range = {0.05, 2},
    Increment = 0.05,
    Suffix = "s",
    CurrentValue = G.RedeemCodeDelay,
    Flag = "RedeemCodeDelay",
    Callback = function(value) G.RedeemCodeDelay = value end,
})
NativeTab:CreateButton({
    Name = "Resgatar todos os códigos ativos",
    Callback = redeemAllCodes,
})

ExtraTab:CreateSection("Extras")
local MenuKeybindControl
MenuKeybindControl = ExtraTab:CreateKeybind({
    Name = "Tecla para abrir/fechar interface",
    CurrentKeybind = G.MenuKeybind,
    HoldToInteract = false,
    Flag = "MenuKeybind",
    -- O Callback do Rayfield também pode disparar ao concluir a edição.
    -- A alternância real é tratada pelo UserInputService abaixo.
    Callback = function() end,
})

local function getConfiguredMenuKey()
    local selected = MenuKeybindControl
        and MenuKeybindControl.CurrentKeybind
        or G.MenuKeybind

    if typeof(selected) == "EnumItem"
        and selected.EnumType == Enum.KeyCode
    then
        return selected
    end

    if type(selected) == "string" then
        return Enum.KeyCode[selected]
    end

    return Enum.KeyCode.RightShift
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed or input.UserInputType ~= Enum.UserInputType.Keyboard then
        return
    end

    local configuredKey = getConfiguredMenuKey()
    if configuredKey and input.KeyCode == configuredKey then
        G.MenuKeybind = configuredKey.Name
        Rayfield:SetVisibility(not Rayfield:IsVisible())
    end
end)
ExtraTab:CreateToggle({Name = "NoClip durante farm", CurrentValue = G.NoClip, Flag = "NoClip", Callback = function(v) G.NoClip = v end})
ExtraTab:CreateToggle({Name = "Anti-AFK", CurrentValue = G.AntiAFK, Flag = "AntiAFK", Callback = function(v) G.AntiAFK = v end})
ExtraTab:CreateToggle({Name = "Anti-Void", CurrentValue = G.AntiVoid, Flag = "AntiVoid", Callback = function(v) G.AntiVoid = v end})

Rayfield:LoadConfiguration()
