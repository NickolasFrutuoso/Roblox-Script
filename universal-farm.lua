--// Overgeared Complete - Rayfield
--// Três modos de farm + quests + defesa + esquiva + poções

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
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

local POTION_PRIORITY = {
    "HealthPotion",
    "DefencePotion",
    "MediumHealthPotion",
    "LargeHealthPotion",
    "BigHealthPotion",
}
local POTION_PRIORITY_INDEX = {}
for index, potionId in ipairs(POTION_PRIORITY) do
    POTION_PRIORITY_INDEX[potionId] = index
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
    FarmMode = "Farm fixo",
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
    StationaryRange = 14,
    WalkAreaRadius = 65,
    WalkCombatDistance = 5,
    WalkActionRange = 11,
    WalkReturnTolerance = 3,
    WalkFollowInterval = 0.12,
    FaceTarget = true,
    FacingResponsiveness = 30,
    AttackFacingDot = 0.70,
    AttackAnimationEnabled = true,
    AttackAnimationFolder = "SwordAnims",
    AttackAnimationSpeed = 1,
    AttackAnimationFade = 0.05,
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
    PotionMediumThreshold = 60,
    PotionCriticalThreshold = 30,
    PotionCooldown = 1,
    PotionInterval = 1,
    RedeemCodeDelay = 0.20,
    RedeemCodesBusy = false,

    AutoBlockEnabled = true,
    AutoBlockChance = 50,
    AutoBlockDelay = 0.10,
    AutoBlockHoldTime = 0.20,
    AutoBlockRange = 22,
    AutoBlockFacing = 0.10,
    AreaBlockEnabled = true,
    AreaGrowingTrigger = 28,
    AreaShrinkingTrigger = 42,
    AreaBlockHoldTime = 0.45,
    AreaInsideMargin = 1.5,

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

local function findNearestMob(maxDistance, requireSelected, center, centerRadius, requiredName)
    local _, _, root = getCharacterData()
    if not root then return nil end
    local best, bestDistance
    bestDistance = math.huge
    for _, mob in ipairs(collectMobModels()) do
        if (not requireSelected or G.SelectedMobs[mob.Name])
            and (not requiredName or mob.Name == requiredName)
            and isAlive(mob) then
            local mobRoot = getModelRoot(mob)
            local distance = (mobRoot.Position - root.Position).Magnitude
            local insideCenter = not center or not centerRadius
                or (Vector3.new(mobRoot.Position.X, 0, mobRoot.Position.Z)
                    - Vector3.new(center.X, 0, center.Z)).Magnitude <= centerRadius
            if insideCenter and distance <= (maxDistance or math.huge) and distance < bestDistance then
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
local walkHomePosition
local lockedWalkMobName
local facingAttachment
local facingAlign
local facingHumanoid
local attackTrack
local attackAnimator
local attackTrackCache = {}
local comboIndex = 1

local function hasActiveEnemyArea()
    for area in pairs(activeEnemyAreas) do
        if area.Parent then return true end
        activeEnemyAreas[area] = nil
    end
    return false
end

local function farmIsPaused()
    return G.QuestBusy
        or (G.FarmMode == "Farm fixo"
            and (hasActiveEnemyArea() or os.clock() < movementPausedUntil))
end

local function stopFacing()
    if facingAlign then facingAlign:Destroy() end
    if facingAttachment then facingAttachment:Destroy() end
    if facingHumanoid and facingHumanoid.Parent then facingHumanoid.AutoRotate = true end
    facingAttachment, facingAlign, facingHumanoid = nil, nil, nil
end

local function faceTarget(humanoid, root, position)
    if not G.FaceTarget then stopFacing() return end
    if facingHumanoid ~= humanoid or not facingAlign or not facingAlign.Parent then
        stopFacing()
        facingAttachment = Instance.new("Attachment")
        facingAttachment.Name = "CompleteFarmFacingAttachment"
        facingAttachment.Parent = root
        facingAlign = Instance.new("AlignOrientation")
        facingAlign.Name = "CompleteFarmFacing"
        facingAlign.Mode = Enum.OrientationAlignmentMode.OneAttachment
        facingAlign.Attachment0 = facingAttachment
        facingAlign.RigidityEnabled = false
        facingAlign.MaxTorque = 1000000000
        facingAlign.Parent = root
        facingHumanoid = humanoid
        humanoid.AutoRotate = false
    end
    local direction = Vector3.new(position.X - root.Position.X, 0, position.Z - root.Position.Z)
    if direction.Magnitude > 0.05 then
        facingAlign.Responsiveness = math.max(G.FacingResponsiveness, 1)
        facingAlign.CFrame = CFrame.lookAt(Vector3.zero, direction.Unit)
    end
end

local function stopAttackAnimation()
    if attackTrack then pcall(function() attackTrack:Stop(G.AttackAnimationFade) end) end
    attackTrack = nil
end

local function resetAttackAnimations()
    stopAttackAnimation()
    attackAnimator, attackTrackCache, comboIndex = nil, {}, 1
end

local function playAttackAnimation()
    if not G.AttackAnimationEnabled then return end
    local _, humanoid = getCharacterData()
    local animator = humanoid and (humanoid:FindFirstChildOfClass("Animator")
        or humanoid:WaitForChild("Animator", 1))
    if not animator then return end
    if attackAnimator ~= animator then
        resetAttackAnimations()
        attackAnimator = animator
    end
    local anims = ReplicatedStorage:FindFirstChild("Anims")
    local folder = anims and anims:FindFirstChild(G.AttackAnimationFolder)
    if not folder then return end
    local choices = {}
    for index = 1, 10 do
        local animation = folder:FindFirstChild("S" .. index)
        if animation and animation:IsA("Animation") then table.insert(choices, animation) end
    end
    if #choices == 0 then return end
    if comboIndex > #choices then comboIndex = 1 end
    local animation = choices[comboIndex]
    comboIndex = comboIndex % #choices + 1
    local track = attackTrackCache[animation]
    if not track then
        local ok, loaded = pcall(function() return animator:LoadAnimation(animation) end)
        if not ok or not loaded then return end
        track = loaded
        track.Priority = Enum.AnimationPriority.Action
        track.Looped = false
        attackTrackCache[animation] = track
    end
    stopAttackAnimation()
    attackTrack = track
    pcall(function()
        track:Play(math.max(G.AttackAnimationFade, 0), 1, math.max(G.AttackAnimationSpeed, 0.05))
    end)
end

local function targetFacingOkay(root, targetRoot)
    if not G.FaceTarget or G.FarmMode == "Farm fixo" then return true end
    local direction = Vector3.new(
        targetRoot.Position.X - root.Position.X, 0, targetRoot.Position.Z - root.Position.Z)
    if direction.Magnitude < 0.05 then return true end
    local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
    return look.Magnitude > 0.05 and look.Unit:Dot(direction.Unit) >= G.AttackFacingDot
end

local function canActOnTarget()
    if not G.FarmEnabled or farmIsPaused() or not currentTarget or not isAlive(currentTarget) then
        return false
    end
    local _, _, root = getCharacterData()
    local targetRoot = getModelRoot(currentTarget)
    if not root or not targetRoot then return false end
    if G.FarmMode == "Farm fixo" then return true end
    local range = G.FarmMode == "Farm parado" and G.StationaryRange or G.WalkActionRange
    return (root.Position - targetRoot.Position).Magnitude <= range
        and targetFacingOkay(root, targetRoot)
end

task.spawn(function()
    while task.wait(G.FarmEnabled and math.max(G.AttackDelay, 0.05) or 0.15) do
        if G.AttackEnabled and canActOnTarget() then
            playAttackAnimation()
            pcall(function() SwordAttack:FireServer() end)
        end
    end
end)

task.spawn(function()
    while task.wait(G.FarmEnabled and math.max(G.SkillDelay, 0.10) or 0.15) do
        if G.SkillsEnabled and canActOnTarget() then
            pcall(function()
                UseSkill:FireServer(1)
                UseSkill:FireServer(2)
                UseSkill:FireServer(3)
            end)
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if not G.FarmEnabled or farmIsPaused() then
        if not G.FarmEnabled then stopFacing() end
        return
    end
    if currentTarget and not isAlive(currentTarget) then
        if G.FarmMode == "Farm caminhada" and not lockedWalkMobName then
            lockedWalkMobName = currentTarget.Name
        end
        currentTarget = nil
        fixedFarmCFrame = nil
    end

    local character, humanoid, root = getCharacterData()
    if not character then return end
    if G.FarmMode == "Farm caminhada" and not walkHomePosition then walkHomePosition = root.Position end

    if currentTarget and G.FarmMode == "Farm parado" then
        local targetRoot = getModelRoot(currentTarget)
        if not targetRoot or (targetRoot.Position - root.Position).Magnitude > G.StationaryRange then
            currentTarget = nil
        end
    elseif currentTarget and G.FarmMode == "Farm caminhada" and walkHomePosition then
        local targetRoot = getModelRoot(currentTarget)
        local flatDistance = targetRoot and
            (Vector3.new(targetRoot.Position.X, 0, targetRoot.Position.Z)
                - Vector3.new(walkHomePosition.X, 0, walkHomePosition.Z)).Magnitude
        if not flatDistance or flatDistance > G.WalkAreaRadius then currentTarget = nil end
    end

    if not currentTarget then
        if G.FarmMode == "Farm parado" then
            currentTarget = findNearestMob(G.StationaryRange, false)
        elseif G.FarmMode == "Farm caminhada" then
            currentTarget = findNearestMob(
                math.huge,
                true,
                walkHomePosition,
                G.WalkAreaRadius,
                lockedWalkMobName
            )
            if currentTarget and not lockedWalkMobName then
                lockedWalkMobName = currentTarget.Name
            end
        else
            currentTarget = findNearestMob(math.huge, true)
        end
        fixedFarmCFrame = nil
    end
    if not currentTarget then
        stopFacing()
        if G.FarmMode == "Farm caminhada" and walkHomePosition then
            local flatDistance = (Vector3.new(root.Position.X, 0, root.Position.Z)
                - Vector3.new(walkHomePosition.X, 0, walkHomePosition.Z)).Magnitude
            humanoid:MoveTo(flatDistance > G.WalkReturnTolerance and walkHomePosition or root.Position)
        end
        return
    end

    local mobRoot = getModelRoot(currentTarget)
    if not character or not mobRoot then
        currentTarget = nil
        fixedFarmCFrame = nil
        return
    end

    if G.FarmMode == "Farm parado" then
        faceTarget(humanoid, root, mobRoot.Position)
        humanoid:MoveTo(root.Position)
        return
    end

    if G.FarmMode == "Farm caminhada" then
        faceTarget(humanoid, root, mobRoot.Position)
        local away = Vector3.new(
            root.Position.X - mobRoot.Position.X, 0, root.Position.Z - mobRoot.Position.Z)
        if away.Magnitude < 0.1 then
            away = -Vector3.new(mobRoot.CFrame.LookVector.X, 0, mobRoot.CFrame.LookVector.Z)
        end
        if away.Magnitude < 0.1 then away = Vector3.zAxis end
        local desired = mobRoot.Position + away.Unit * G.WalkCombatDistance
        desired = Vector3.new(desired.X, root.Position.Y, desired.Z)
        humanoid:MoveTo((root.Position - desired).Magnitude > 0.8 and desired or root.Position)
        return
    end

    stopFacing()

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
    if not (G.FarmEnabled and G.NoClip and G.FarmMode == "Farm fixo") then return end
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
        -- Intencionalmente vazio: lógica futura.
    end
end)

-- Auto Potion inteligente, com reavaliação a cada uso.
local lastPotionUse = 0
local potionBusy = false
local fallbackPotionHealth = {
    HealthPotion = 50,
    DefencePotion = 50,
    MediumHealthPotion = 225,
    LargeHealthPotion = 800,
    BigHealthPotion = 1500,
}
local function potionPower(potionId)
    local data = PotionData[potionId]
    return data and tonumber(data.Health) or fallbackPotionHealth[potionId] or 0
end
local function choosePotion(selected, used, percent, lastPower)
    local available = {}
    for _, potionId in ipairs(selected) do
        if not used[potionId] then table.insert(available, potionId) end
    end
    table.sort(available, function(a, b)
        local powerA, powerB = potionPower(a), potionPower(b)
        if powerA == powerB then
            return (POTION_PRIORITY_INDEX[a] or 99) < (POTION_PRIORITY_INDEX[b] or 99)
        end
        return powerA < powerB
    end)
    if #available == 0 then return nil end
    local critical = math.min(G.PotionCriticalThreshold, G.PotionMediumThreshold)
    local medium = math.max(G.PotionCriticalThreshold, G.PotionMediumThreshold)
    if percent <= critical then return available[#available] end
    if percent <= medium then
        for _, potionId in ipairs(available) do
            if potionPower(potionId) >= 225 and potionPower(potionId) > lastPower then
                return potionId
            end
        end
        return available[#available]
    end
    for _, potionId in ipairs(available) do
        if potionPower(potionId) > lastPower then return potionId end
    end
    return nil
end
task.spawn(function()
    while task.wait(0.08) do
        if not G.AutoPotionEnabled or potionBusy
            or os.clock() - lastPotionUse < math.max(G.PotionCooldown, 1) then
            continue
        end
        local _, humanoid = getCharacterData()
        if not humanoid or humanoid.MaxHealth <= 0
            or humanoid.Health / humanoid.MaxHealth * 100 >= G.PotionThreshold then
            continue
        end
        local selected = {}
        for _, potionId in ipairs(POTION_PRIORITY) do
            if G.SelectedPotions[potionId] then table.insert(selected, potionId) end
        end
        if #selected == 0 then continue end
        lastPotionUse, potionBusy = os.clock(), true
        task.spawn(function()
            local used, lastPower = {}, -1
            while G.AutoPotionEnabled do
                local _, currentHumanoid = getCharacterData()
                if not currentHumanoid or currentHumanoid.MaxHealth <= 0 then break end
                local percent = currentHumanoid.Health / currentHumanoid.MaxHealth * 100
                if percent >= G.PotionThreshold then break end
                local potionId = choosePotion(selected, used, percent, lastPower)
                if not potionId then break end
                used[potionId], lastPower = true, potionPower(potionId)
                lastPotionUse = os.clock()
                pcall(function() UsePotion:FireServer(potionId) end)
                task.wait(math.max(G.PotionInterval, 1))
            end
            potionBusy = false
        end)
    end
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
local defenseRandom = Random.new()

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
    if defenseRandom:NextNumber(0, 100) >= G.AutoBlockChance then return end

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

-- Defesa adaptativa dentro dos círculos (usada nos modos caminhada/parado).
local areaBlockCandidates = {}
local lastAreaBlockDecision = 0

local function blockAreaDimensions(part)
    local dimensions = {
        {Axis = "X", Value = part.Size.X},
        {Axis = "Y", Value = part.Size.Y},
        {Axis = "Z", Value = part.Size.Z},
    }
    table.sort(dimensions, function(a, b) return a.Value < b.Value end)
    return dimensions[1], dimensions[2], dimensions[3]
end

local function isBlockArea(part)
    if not part:IsA("BasePart") then return false end
    local thin, wideA, wideB = blockAreaDimensions(part)
    if thin.Value > 2 or math.min(wideA.Value, wideB.Value) < 18 then return false end
    local round = math.abs(wideA.Value - wideB.Value) / math.max(wideA.Value, wideB.Value) <= 0.30
    local red = part.Color.R >= 0.60
        and part.Color.R > part.Color.G * 1.5
        and part.Color.R > part.Color.B * 1.5
    return round and red
end

local function insideBlockArea(part, root)
    local localPosition = part.CFrame:PointToObjectSpace(root.Position)
    local thin, wideA, wideB = blockAreaDimensions(part)
    local coordinates = {X = localPosition.X, Y = localPosition.Y, Z = localPosition.Z}
    local radiusA = wideA.Value * 0.5 + G.AreaInsideMargin
    local radiusB = wideB.Value * 0.5 + G.AreaInsideMargin
    return (coordinates[wideA.Axis] / radiusA) ^ 2
        + (coordinates[wideB.Axis] / radiusB) ^ 2 <= 1
        and math.abs(coordinates[thin.Axis]) <= 8
end

local function addAreaBlockCandidate(instance)
    if not instance:IsA("BasePart") then return end
    areaBlockCandidates[instance] = {
        CreatedAt = os.clock(),
        LastDiameter = nil,
        Direction = 0,
        Decided = false,
    }
end

for _, instance in ipairs(DebrisFolder:GetDescendants()) do addAreaBlockCandidate(instance) end
DebrisFolder.DescendantAdded:Connect(addAreaBlockCandidate)

local lastAreaBlockSample = 0
RunService.Heartbeat:Connect(function()
    if not G.FarmEnabled or G.FarmMode == "Farm fixo" or not G.AreaBlockEnabled then return end
    local now = os.clock()
    if now - lastAreaBlockSample < 0.02 then return end
    lastAreaBlockSample = now
    local _, _, root = getCharacterData()
    if not root then return end

    for part, state in pairs(areaBlockCandidates) do
        if not part.Parent or now - state.CreatedAt > 4 then
            areaBlockCandidates[part] = nil
        elseif not state.Decided and isBlockArea(part) then
            local _, wideA, wideB = blockAreaDimensions(part)
            local diameter = math.min(wideA.Value, wideB.Value)
            if state.LastDiameter then
                local delta = diameter - state.LastDiameter
                if delta >= 0.05 then state.Direction = 1 end
                if delta <= -0.05 then state.Direction = -1 end
            end
            state.LastDiameter = diameter
            local impactSoon = (state.Direction == 1 and diameter >= G.AreaGrowingTrigger)
                or (state.Direction == -1 and diameter <= G.AreaShrinkingTrigger)
            if impactSoon and insideBlockArea(part, root)
                and now - lastAreaBlockDecision >= 0.20 then
                lastAreaBlockDecision = now
                for otherPart, otherState in pairs(areaBlockCandidates) do
                    if otherPart.Parent
                        and (otherPart.Position - part.Position).Magnitude <= 4
                        and math.abs(otherState.CreatedAt - state.CreatedAt) <= 0.75 then
                        otherState.Decided = true
                    end
                end
                if defenseRandom:NextNumber(0, 100) < G.AutoBlockChance then
                    defendFor(G.AreaBlockHoldTime)
                end
            end
        end
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
    if G.FarmMode ~= "Farm fixo"
        or not G.SkillDodgeEnabled
        or os.clock() - lastDodge < G.DodgeCooldown then return end
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
    if G.FarmMode ~= "Farm fixo" or not G.SkillDodgeEnabled then return end

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
    Name = "Overgeared Complete",
    Icon = "swords",
    LoadingTitle = "Overgeared Complete",
    LoadingSubtitle = "Três farms, defesa, esquiva e utilidades",
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
        FileName = "SettingsCompleteV1",
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
FarmTab:CreateDropdown({
    Name = "Tipo de farm",
    Options = {"Farm fixo", "Farm caminhada", "Farm parado"},
    CurrentOption = {G.FarmMode},
    MultipleOptions = false,
    Flag = "FarmMode",
    Callback = function(options)
        G.FarmMode = options[1] or "Farm fixo"
        currentTarget, fixedFarmCFrame = nil, nil
        lockedWalkMobName = nil
        stopFacing()
        local _, _, root = getCharacterData()
        walkHomePosition = root and root.Position or nil
    end,
})
FarmTab:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = G.FarmEnabled,
    Flag = "FarmEnabled",
    Callback = function(value)
        G.FarmEnabled = value
        currentTarget, fixedFarmCFrame = nil, nil
        lockedWalkMobName = nil
        local _, _, root = getCharacterData()
        walkHomePosition = value and root and root.Position or nil
        if not value then stopFacing() end
    end,
})
FarmTab:CreateToggle({Name = "Auto Ataque", CurrentValue = G.AttackEnabled, Flag = "AttackEnabled", Callback = function(v) G.AttackEnabled = v end})
FarmTab:CreateToggle({Name = "Auto Skills 1, 2 e 3", CurrentValue = G.SkillsEnabled, Flag = "SkillsEnabled", Callback = function(v) G.SkillsEnabled = v end})
FarmTab:CreateToggle({Name = "Animação de ataque", CurrentValue = G.AttackAnimationEnabled, Flag = "AttackAnimationEnabled", Callback = function(v) G.AttackAnimationEnabled = v if not v then stopAttackAnimation() end end})
local attackAnimationFolders = {}
do
    local anims = ReplicatedStorage:FindFirstChild("Anims")
    for _, folderName in ipairs({
        "SwordAnims", "StraightSwordAnims", "GreatSwordAnims", "KatanaAnims",
        "DaggerAnims", "DaggerAnims1", "LanceSwordAnims", "ScytheAnims",
    }) do
        if anims and anims:FindFirstChild(folderName) then
            table.insert(attackAnimationFolders, folderName)
        end
    end
    if #attackAnimationFolders == 0 then table.insert(attackAnimationFolders, "SwordAnims") end
end
FarmTab:CreateDropdown({
    Name = "Conjunto de animações",
    Options = attackAnimationFolders,
    CurrentOption = {G.AttackAnimationFolder},
    MultipleOptions = false,
    Flag = "AttackAnimationFolder",
    Callback = function(options)
        G.AttackAnimationFolder = options[1] or "SwordAnims"
        resetAttackAnimations()
    end,
})
FarmTab:CreateSlider({Name = "Velocidade da animação", Range = {0.5, 2}, Increment = 0.05, Suffix = "x", CurrentValue = G.AttackAnimationSpeed, Flag = "AttackAnimationSpeed", Callback = function(v) G.AttackAnimationSpeed = v end})
FarmTab:CreateSlider({Name = "Delay do ataque", Range = {0.05, 2}, Increment = 0.05, Suffix = "s", CurrentValue = G.AttackDelay, Flag = "AttackDelay", Callback = function(v) G.AttackDelay = v end})
FarmTab:CreateSlider({Name = "Delay das skills", Range = {0.1, 10}, Increment = 0.1, Suffix = "s", CurrentValue = G.SkillDelay, Flag = "SkillDelay", Callback = function(v) G.SkillDelay = v end})
FarmTab:CreateSlider({Name = "Alcance do farm parado", Range = {5, 40}, Increment = 1, Suffix = " studs", CurrentValue = G.StationaryRange, Flag = "StationaryRange", Callback = function(v) G.StationaryRange = v currentTarget = nil end})
FarmTab:CreateSlider({Name = "Área do farm caminhada", Range = {15, 200}, Increment = 5, Suffix = " studs", CurrentValue = G.WalkAreaRadius, Flag = "WalkAreaRadius", Callback = function(v) G.WalkAreaRadius = v currentTarget = nil end})
FarmTab:CreateSlider({Name = "Distância no farm caminhada", Range = {3, 10}, Increment = 0.25, Suffix = " studs", CurrentValue = G.WalkCombatDistance, Flag = "WalkCombatDistance", Callback = function(v) G.WalkCombatDistance = v end})
FarmTab:CreateSlider({Name = "Alcance de ação caminhando", Range = {5, 18}, Increment = 0.5, Suffix = " studs", CurrentValue = G.WalkActionRange, Flag = "WalkActionRange", Callback = function(v) G.WalkActionRange = v end})
FarmTab:CreateToggle({Name = "Olhar para o inimigo", CurrentValue = G.FaceTarget, Flag = "FaceTarget", Callback = function(v) G.FaceTarget = v if not v then stopFacing() end end})
FarmTab:CreateSlider({Name = "Velocidade para virar", Range = {5, 100}, Increment = 5, CurrentValue = G.FacingResponsiveness, Flag = "FacingResponsiveness", Callback = function(v) G.FacingResponsiveness = v end})
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
DefenseTab:CreateSlider({Name = "Chance de defender", Range = {0, 100}, Increment = 1, Suffix = "%", CurrentValue = G.AutoBlockChance, Flag = "AutoBlockChance", Callback = function(v) G.AutoBlockChance = v end})
DefenseTab:CreateSlider({Name = "Delay para bloquear", Range = {0, 1}, Increment = 0.001, Suffix = "s", CurrentValue = G.AutoBlockDelay, Flag = "AutoBlockDelay", Callback = function(v) G.AutoBlockDelay = v end})
DefenseTab:CreateSlider({Name = "Tempo segurando defesa", Range = {0.01, 1}, Increment = 0.01, Suffix = "s", CurrentValue = G.AutoBlockHoldTime, Flag = "AutoBlockHoldTime", Callback = function(v) G.AutoBlockHoldTime = v end})
DefenseTab:CreateSlider({Name = "Alcance", Range = {5, 100}, Increment = 1, Suffix = " studs", CurrentValue = G.AutoBlockRange, Flag = "AutoBlockRange", Callback = function(v) G.AutoBlockRange = v end})
DefenseTab:CreateSlider({Name = "Limite de direção", Range = {-1, 1}, Increment = 0.05, CurrentValue = G.AutoBlockFacing, Flag = "AutoBlockFacing", Callback = function(v) G.AutoBlockFacing = v end})
DefenseTab:CreateSection("Círculos de dano")
DefenseTab:CreateToggle({Name = "Defender dentro de círculos", CurrentValue = G.AreaBlockEnabled, Flag = "AreaBlockEnabled", Callback = function(v) G.AreaBlockEnabled = v end})
DefenseTab:CreateSlider({Name = "Disco crescendo: defender em", Range = {20, 40}, Increment = 0.5, CurrentValue = G.AreaGrowingTrigger, Flag = "AreaGrowingTrigger", Callback = function(v) G.AreaGrowingTrigger = v end})
DefenseTab:CreateSlider({Name = "Disco encolhendo: defender em", Range = {30, 60}, Increment = 0.5, CurrentValue = G.AreaShrinkingTrigger, Flag = "AreaShrinkingTrigger", Callback = function(v) G.AreaShrinkingTrigger = v end})
DefenseTab:CreateSlider({Name = "Tempo de defesa da área", Range = {0.1, 1.2}, Increment = 0.01, Suffix = "s", CurrentValue = G.AreaBlockHoldTime, Flag = "AreaBlockHoldTime", Callback = function(v) G.AreaBlockHoldTime = v end})
DefenseTab:CreateSlider({Name = "Margem do círculo", Range = {0, 6}, Increment = 0.25, Suffix = " studs", CurrentValue = G.AreaInsideMargin, Flag = "AreaInsideMargin", Callback = function(v) G.AreaInsideMargin = v end})

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

local potionIds = POTION_PRIORITY
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
    Name = "Usar média abaixo de",
    Range = {10, 90},
    Increment = 1,
    Suffix = "% HP",
    CurrentValue = G.PotionMediumThreshold,
    Flag = "PotionMediumThreshold",
    Callback = function(value) G.PotionMediumThreshold = value end,
})
NativeTab:CreateSlider({
    Name = "Usar melhor abaixo de",
    Range = {1, 70},
    Increment = 1,
    Suffix = "% HP",
    CurrentValue = G.PotionCriticalThreshold,
    Flag = "PotionCriticalThreshold",
    Callback = function(value) G.PotionCriticalThreshold = value end,
})
NativeTab:CreateSlider({
    Name = "Cooldown da potion",
    Range = {1, 10},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = G.PotionCooldown,
    Flag = "PotionCooldown",
    Callback = function(value) G.PotionCooldown = value end,
})
NativeTab:CreateSlider({
    Name = "Intervalo entre potions",
    Range = {1, 10},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = G.PotionInterval,
    Flag = "PotionInterval",
    Callback = function(value) G.PotionInterval = value end,
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
