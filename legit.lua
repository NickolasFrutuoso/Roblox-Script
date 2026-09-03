--// Legit Boss Farm - Rayfield
--// Caminhada normal, combate local e defesa probabilística.
--// Sem teleporte, noclip, autoquest ou esquiva de habilidades.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Monsters = workspace:WaitForChild("Monsters")
local DebrisFolder = workspace:WaitForChild("Debris")
local VirtualUser = game:GetService("VirtualUser")
local SwordAttack = ReplicatedStorage:WaitForChild("SwordAttack")
local UseSkill = ReplicatedStorage:WaitForChild("UseSkill")
local UsePotion = ReplicatedStorage:WaitForChild("UsePotion")
local SetBlocking = ReplicatedStorage:WaitForChild("SetBlocking")

local PotionData = {}
do
    local zen = ReplicatedStorage:FindFirstChild("ZenFolder")
    local module = zen and zen:FindFirstChild("PotionData")
    if module then
        local ok, result = pcall(require, module)
        if ok and type(result) == "table" then PotionData = result end
    end
end

-- Encerra apenas uma execução anterior deste mesmo script.
if _G.LegitBossFarmRuntime and _G.LegitBossFarmRuntime.Stop then
    _G.LegitBossFarmRuntime.Stop()
end

_G.LegitBossFarm = _G.LegitBossFarm or {}
local G = _G.LegitBossFarm
local defaults = {
    Enabled = false,
    SelectedBoss = "Mais próximo",
    AttackEnabled = true,
    SkillsEnabled = true,
    BlockEnabled = true,

    BossAreaRadius = 65,
    CombatDistance = 5,
    ActionRange = 11,
    FollowInterval = 0.12,
    ReturnTolerance = 3,
    FaceTarget = true,
    FacingResponsiveness = 30,
    AttackFacingDot = 0.70,

    AttackDelay = 0.48,
    AttackAnimationEnabled = true,
    AttackAnimationFolder = "SwordAnims",
    AttackAnimationSpeed = 1,
    AttackAnimationFade = 0.05,
    SkillDelay = 1.25,
    Skill1 = true,
    Skill2 = true,
    Skill3 = true,
    SkillGap = 0.04,

    AutoPotionEnabled = false,
    SelectedPotions = {MediumHealthPotion = true},
    PotionThreshold = 50,
    PotionCooldown = 1,
    PotionBurstDelay = 0.05,

    BlockChance = 50,
    BlockDelay = 0.10,
    BlockHoldTime = 0.20,
    BlockRange = 22,
    BlockFacing = 0.05,
    AnimationDebounce = 0.08,

    AreaBlockEnabled = true,
    AreaMinimumDiameter = 18,
    AreaMaximumThickness = 2,
    AreaGrowingTrigger = 28,
    AreaShrinkingTrigger = 42,
    AreaBlockHoldTime = 0.45,
    AreaInsideMargin = 1.5,
    AreaDecisionCooldown = 0.20,

    MenuKey = "RightShift",
    AntiAFK = true,
}
for key, value in pairs(defaults) do
    if G[key] == nil then G[key] = value end
end

local Runtime = {
    Alive = true,
    Connections = {},
    Watched = {},
    LastAnimations = {},
    Target = nil,
    LockedBossName = nil,
    StartPosition = nil,
    Defending = false,
    ManualDefense = false,
    DefenseGeneration = 0,
    ComboIndex = 1,
    AttackTrack = nil,
    AttackAnimator = nil,
    AttackTrackCache = {},
    AreaCandidates = {},
    LastAreaDecision = 0,
    FacingAttachment = nil,
    FacingAlign = nil,
    FacingHumanoid = nil,
}
_G.LegitBossFarmRuntime = Runtime

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(Runtime.Connections, connection)
    return connection
end

connect(LocalPlayer.Idled, function()
    if G.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.zero)
    end
end)

local function characterData()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
    if not character or not humanoid or humanoid.Health <= 0 or not root then return nil end
    return character, humanoid, root
end

local function modelRoot(model)
    return model and (model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart)
end

local function alive(model)
    if not model or not model.Parent then return false end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid then return humanoid.Health > 0 end
    local health = model:GetAttribute("Health")
    return health == nil or health > 0
end

local function mobModel(instance)
    return instance:IsA("Model")
        and instance:FindFirstChildOfClass("Humanoid") ~= nil
        and modelRoot(instance) ~= nil
end

local function allMobs()
    local result, seen = {}, {}
    for _, instance in ipairs(Monsters:GetDescendants()) do
        if mobModel(instance) and not seen[instance] then
            seen[instance] = true
            table.insert(result, instance)
        end
    end
    for _, instance in ipairs(Monsters:GetChildren()) do
        if mobModel(instance) and not seen[instance] then
            seen[instance] = true
            table.insert(result, instance)
        end
    end
    return result
end

local function horizontalDistance(a, b)
    local delta = Vector3.new(a.X - b.X, 0, a.Z - b.Z)
    return delta.Magnitude
end

local function validTarget(mob)
    if not alive(mob) then return false end
    local mobRoot = modelRoot(mob)
    if not mobRoot or not Runtime.StartPosition then return false end
    local requiredName = G.SelectedBoss ~= "Mais próximo"
        and G.SelectedBoss
        or Runtime.LockedBossName
    if requiredName and mob.Name ~= requiredName then return false end
    -- A área de farm é sempre centrada no ponto salvo ao ativar.
    return horizontalDistance(mobRoot.Position, Runtime.StartPosition) <= G.BossAreaRadius
end

local function nearestBoss()
    local _, _, root = characterData()
    if not root or not Runtime.StartPosition then return nil end
    local best, bestDistance
    for _, mob in ipairs(allMobs()) do
        if validTarget(mob) then
            local mobRoot = modelRoot(mob)
            local fromStart = horizontalDistance(mobRoot.Position, Runtime.StartPosition)
            local fromPlayer = horizontalDistance(mobRoot.Position, root.Position)
            if fromStart <= G.BossAreaRadius
                and (not bestDistance or fromPlayer < bestDistance) then
                best, bestDistance = mob, fromPlayer
            end
        end
    end
    if best and not Runtime.LockedBossName then
        Runtime.LockedBossName = best.Name
    end
    return best
end

local function setBlocking(value)
    if Runtime.Defending == value then return end
    Runtime.Defending = value
    pcall(function() SetBlocking:FireServer(value) end)
end

local function stopDefense()
    Runtime.DefenseGeneration += 1
    setBlocking(false)
end

local function defendFor(duration)
    Runtime.DefenseGeneration += 1
    local generation = Runtime.DefenseGeneration
    setBlocking(true)
    task.delay(math.max(duration, 0.01), function()
        if Runtime.Alive and generation == Runtime.DefenseGeneration
            and not Runtime.ManualDefense then
            setBlocking(false)
        end
    end)
end

local function stopMovement()
    local _, humanoid, root = characterData()
    if humanoid and root then humanoid:MoveTo(root.Position) end
end

local function stopFacing()
    if Runtime.FacingAlign then Runtime.FacingAlign:Destroy() end
    if Runtime.FacingAttachment then Runtime.FacingAttachment:Destroy() end
    if Runtime.FacingHumanoid and Runtime.FacingHumanoid.Parent then
        Runtime.FacingHumanoid.AutoRotate = true
    end
    Runtime.FacingAlign = nil
    Runtime.FacingAttachment = nil
    Runtime.FacingHumanoid = nil
end

local function facePosition(humanoid, root, worldPosition)
    if not G.FaceTarget then
        stopFacing()
        return
    end

    if Runtime.FacingHumanoid ~= humanoid
        or not Runtime.FacingAlign
        or not Runtime.FacingAlign.Parent then
        stopFacing()
        local attachment = Instance.new("Attachment")
        attachment.Name = "LegitBossFacingAttachment"
        attachment.Parent = root

        local align = Instance.new("AlignOrientation")
        align.Name = "LegitBossFacing"
        align.Mode = Enum.OrientationAlignmentMode.OneAttachment
        align.Attachment0 = attachment
        align.RigidityEnabled = false
        align.MaxTorque = 1000000000
        align.Parent = root

        Runtime.FacingAttachment = attachment
        Runtime.FacingAlign = align
        Runtime.FacingHumanoid = humanoid
        humanoid.AutoRotate = false
    end

    local direction = Vector3.new(
        worldPosition.X - root.Position.X,
        0,
        worldPosition.Z - root.Position.Z
    )
    if direction.Magnitude > 0.05 then
        Runtime.FacingAlign.Responsiveness = math.max(G.FacingResponsiveness, 1)
        Runtime.FacingAlign.CFrame = CFrame.lookAt(Vector3.zero, direction.Unit)
    end
end

local function stopAttackAnimation()
    if Runtime.AttackTrack then
        pcall(function() Runtime.AttackTrack:Stop(G.AttackAnimationFade) end)
    end
    Runtime.AttackTrack = nil
end

local function resetAttackAnimations()
    stopAttackAnimation()
    Runtime.ComboIndex = 1
    Runtime.AttackAnimator = nil
    Runtime.AttackTrackCache = {}
end

function Runtime.Stop()
    Runtime.Alive = false
    G.Enabled = false
    stopDefense()
    resetAttackAnimations()
    stopFacing()
    stopMovement()
    for _, connection in ipairs(Runtime.Connections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(Runtime.Connections)
    for _, connection in pairs(Runtime.Watched) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(Runtime.Watched)
end

local rng = Random.new()

local function threatensPlayer(mobRoot, playerRoot)
    local offset = playerRoot.Position - mobRoot.Position
    if offset.Magnitude == 0 or offset.Magnitude > G.BlockRange then return false end
    return mobRoot.CFrame.LookVector:Dot(offset.Unit) >= G.BlockFacing
end

local function handleAnimation(mob, humanoid, track)
    if not Runtime.Alive or not G.Enabled or not G.BlockEnabled then return end
    if not alive(mob) then return end
    if not track.Animation or track.Animation.AnimationId == "" or track.Looped then return end

    local _, _, playerRoot = characterData()
    local mobRoot = modelRoot(mob)
    if not playerRoot or not mobRoot or not threatensPlayer(mobRoot, playerRoot) then return end

    local animationId = track.Animation.AnimationId
    local now = os.clock()
    Runtime.LastAnimations[mob] = Runtime.LastAnimations[mob] or {}
    if now - (Runtime.LastAnimations[mob][animationId] or 0) < 0.05 then return end
    Runtime.LastAnimations[mob][animationId] = now

    -- A rotina anterior permanece igual; somente a chance foi adicionada.
    if rng:NextNumber(0, 100) >= G.BlockChance then return end

    local delayTime = math.max(tonumber(G.BlockDelay) or 0, 0)
    local holdTime = math.max(tonumber(G.BlockHoldTime) or 0.20, 0.01)
    task.delay(delayTime, function()
        if not Runtime.Alive or not G.Enabled or not G.BlockEnabled then return end
        if not alive(mob) then return end
        local _, _, currentRoot = characterData()
        local currentMobRoot = modelRoot(mob)
        if not currentRoot or not currentMobRoot or not threatensPlayer(currentMobRoot, currentRoot) then return end

        defendFor(holdTime)
    end)
end

local function watchMob(mob)
    if Runtime.Watched[mob] or not mobModel(mob) then return end
    local humanoid = mob:FindFirstChildOfClass("Humanoid")
    local animator = humanoid and (humanoid:FindFirstChildOfClass("Animator")
        or humanoid:WaitForChild("Animator", 3))
    if not humanoid or not animator or not Runtime.Alive then return end

    Runtime.Watched[mob] = animator.AnimationPlayed:Connect(function(track)
        handleAnimation(mob, humanoid, track)
    end)
end

local function scanMobs()
    for _, mob in ipairs(allMobs()) do task.spawn(watchMob, mob) end
end
scanMobs()
connect(Monsters.DescendantAdded, function(instance)
    if instance:IsA("Model") then task.defer(watchMob, instance) end
end)

-- Defesa adaptativa contra círculos de dano.
local function areaDimensions(part)
    local dimensions = {
        {Axis = "X", Value = part.Size.X},
        {Axis = "Y", Value = part.Size.Y},
        {Axis = "Z", Value = part.Size.Z},
    }
    table.sort(dimensions, function(a, b) return a.Value < b.Value end)
    return dimensions[1], dimensions[2], dimensions[3]
end

local function areaShape(part)
    if not part:IsA("BasePart") then return false end
    local thin, wideA, wideB = areaDimensions(part)
    if thin.Value > G.AreaMaximumThickness then return false end
    if math.min(wideA.Value, wideB.Value) < G.AreaMinimumDiameter then return false end
    return math.abs(wideA.Value - wideB.Value) / math.max(wideA.Value, wideB.Value) <= 0.30
end

local function playerInsideArea(part, root)
    local localPosition = part.CFrame:PointToObjectSpace(root.Position)
    local thin, wideA, wideB = areaDimensions(part)
    local coordinates = {X = localPosition.X, Y = localPosition.Y, Z = localPosition.Z}
    local radiusA = wideA.Value * 0.5 + G.AreaInsideMargin
    local radiusB = wideB.Value * 0.5 + G.AreaInsideMargin
    local radial = (coordinates[wideA.Axis] / radiusA) ^ 2
        + (coordinates[wideB.Axis] / radiusB) ^ 2
    return radial <= 1 and math.abs(coordinates[thin.Axis]) <= 8
end

local function addAreaCandidate(instance)
    if not instance:IsA("BasePart") then return end
    Runtime.AreaCandidates[instance] = {
        CreatedAt = os.clock(),
        LastDiameter = nil,
        Direction = 0,
        Decided = false,
    }
end

for _, instance in ipairs(DebrisFolder:GetDescendants()) do addAreaCandidate(instance) end
connect(DebrisFolder.DescendantAdded, addAreaCandidate)

local lastAreaSample = 0
connect(RunService.Heartbeat, function()
    if not Runtime.Alive or not G.Enabled or not G.AreaBlockEnabled then return end
    local now = os.clock()
    if now - lastAreaSample < 0.02 then return end
    lastAreaSample = now

    local _, _, root = characterData()
    if not root then return end

    for part, state in pairs(Runtime.AreaCandidates) do
        if not part.Parent or now - state.CreatedAt > 4 then
            Runtime.AreaCandidates[part] = nil
        elseif not state.Decided and areaShape(part) then
            local _, wideA, wideB = areaDimensions(part)
            local diameter = math.min(wideA.Value, wideB.Value)
            if state.LastDiameter then
                local change = diameter - state.LastDiameter
                if change >= 0.05 then state.Direction = 1 end
                if change <= -0.05 then state.Direction = -1 end
            end
            state.LastDiameter = diameter

            local impactSoon = (state.Direction == 1 and diameter >= G.AreaGrowingTrigger)
                or (state.Direction == -1 and diameter <= G.AreaShrinkingTrigger)

            if impactSoon and playerInsideArea(part, root)
                and now - Runtime.LastAreaDecision >= G.AreaDecisionCooldown then
                Runtime.LastAreaDecision = now

                -- Partes sobrepostas da mesma área compartilham uma única decisão.
                for otherPart, otherState in pairs(Runtime.AreaCandidates) do
                    if otherPart.Parent
                        and (otherPart.Position - part.Position).Magnitude <= 4
                        and math.abs(otherState.CreatedAt - state.CreatedAt) <= 0.75 then
                        otherState.Decided = true
                    end
                end

                if rng:NextNumber(0, 100) < G.BlockChance then
                    defendFor(G.AreaBlockHoldTime)
                end
            end
        end
    end
end)

local function saveStartPosition()
    local _, _, root = characterData()
    if root then Runtime.StartPosition = root.Position end
end

local function setEnabled(value)
    G.Enabled = value
    if value then
        saveStartPosition()
        Runtime.Target = nil
        Runtime.LockedBossName = G.SelectedBoss ~= "Mais próximo" and G.SelectedBoss or nil
        scanMobs()
    else
        Runtime.Target = nil
        Runtime.LockedBossName = nil
        Runtime.ManualDefense = false
        stopDefense()
        stopFacing()
        stopMovement()
    end
end

-- Seguir o boss e retornar andando ao ponto onde o farm foi ligado.
task.spawn(function()
    while Runtime.Alive do
        task.wait(math.max(G.FollowInterval, 0.05))
        if not G.Enabled then continue end

        local _, humanoid, root = characterData()
        if not humanoid or not root then continue end
        if not Runtime.StartPosition then Runtime.StartPosition = root.Position end

        if not validTarget(Runtime.Target) then
            Runtime.Target = nearestBoss()
        end

        local target = Runtime.Target
        local targetRoot = modelRoot(target)
        if not target or not targetRoot then
            stopFacing()
            if horizontalDistance(root.Position, Runtime.StartPosition) > G.ReturnTolerance then
                humanoid:MoveTo(Runtime.StartPosition)
            else
                humanoid:MoveTo(root.Position)
            end
            continue
        end

        facePosition(humanoid, root, targetRoot.Position)

        local delta = Vector3.new(
            root.Position.X - targetRoot.Position.X,
            0,
            root.Position.Z - targetRoot.Position.Z
        )
        if delta.Magnitude < 0.1 then
            delta = -Vector3.new(targetRoot.CFrame.LookVector.X, 0, targetRoot.CFrame.LookVector.Z)
        end
        if delta.Magnitude < 0.1 then delta = Vector3.zAxis end

        local desired = targetRoot.Position + delta.Unit * G.CombatDistance
        desired = Vector3.new(desired.X, root.Position.Y, desired.Z)
        if horizontalDistance(root.Position, desired) > 0.8 then
            humanoid:MoveTo(desired)
        else
            humanoid:MoveTo(root.Position)
        end
    end
end)

-- Auto Potion independente: continua junto de movimento, ataque, skills e defesa.
local lastPotionUse = 0
local potionBusy = false
task.spawn(function()
    while Runtime.Alive do
        task.wait(0.08)
        if not G.AutoPotionEnabled or potionBusy then continue end
        if os.clock() - lastPotionUse < math.max(G.PotionCooldown, 0.1) then continue end

        local _, humanoid = characterData()
        if not humanoid or humanoid.MaxHealth <= 0 then continue end
        local healthPercent = humanoid.Health / humanoid.MaxHealth * 100
        if healthPercent >= G.PotionThreshold then continue end

        local selected = {}
        for potionId, enabled in pairs(G.SelectedPotions) do
            if enabled then table.insert(selected, potionId) end
        end
        table.sort(selected)
        if #selected == 0 then continue end

        lastPotionUse = os.clock()
        potionBusy = true
        task.spawn(function()
            for _, potionId in ipairs(selected) do
                if not Runtime.Alive or not G.AutoPotionEnabled then break end
                pcall(function() UsePotion:FireServer(potionId) end)
                task.wait(math.max(G.PotionBurstDelay, 0))
            end
            potionBusy = false
        end)
    end
end)

local function targetInActionRange()
    if not G.Enabled or not validTarget(Runtime.Target) then return false end
    local _, _, root = characterData()
    local targetRoot = modelRoot(Runtime.Target)
    if not root or not targetRoot
        or (root.Position - targetRoot.Position).Magnitude > G.ActionRange then
        return false
    end
    if not G.FaceTarget then return true end

    local direction = Vector3.new(
        targetRoot.Position.X - root.Position.X,
        0,
        targetRoot.Position.Z - root.Position.Z
    )
    if direction.Magnitude < 0.05 then return true end
    local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
    return look.Magnitude > 0.05 and look.Unit:Dot(direction.Unit) >= G.AttackFacingDot
end

local function attackAnimationObjects()
    local anims = ReplicatedStorage:FindFirstChild("Anims")
    local folder = anims and anims:FindFirstChild(G.AttackAnimationFolder)
    if not folder then return {} end

    local result = {}
    for index = 1, 10 do
        local animation = folder:FindFirstChild("S" .. index)
        if animation and animation:IsA("Animation") then
            table.insert(result, animation)
        end
    end
    return result
end

local function playAttackAnimation()
    if not G.AttackAnimationEnabled then return end
    local _, humanoid = characterData()
    if not humanoid then return end

    local animator = humanoid:FindFirstChildOfClass("Animator")
        or humanoid:WaitForChild("Animator", 1)
    if not animator then return end

    if Runtime.AttackAnimator ~= animator then
        resetAttackAnimations()
        Runtime.AttackAnimator = animator
    end

    local animations = attackAnimationObjects()
    if #animations == 0 then return end
    if Runtime.ComboIndex > #animations then Runtime.ComboIndex = 1 end

    local animation = animations[Runtime.ComboIndex]
    Runtime.ComboIndex = Runtime.ComboIndex % #animations + 1

    local track = Runtime.AttackTrackCache[animation]
    if not track then
        local ok, loaded = pcall(function() return animator:LoadAnimation(animation) end)
        if not ok or not loaded then return end
        track = loaded
        track.Priority = Enum.AnimationPriority.Action
        track.Looped = false
        Runtime.AttackTrackCache[animation] = track
    end

    stopAttackAnimation()
    Runtime.AttackTrack = track
    pcall(function()
        track:Play(math.max(G.AttackAnimationFade, 0), 1,
            math.max(G.AttackAnimationSpeed, 0.05))
    end)
end

-- Ataque, skills, movimento e defesa operam simultaneamente.
task.spawn(function()
    while Runtime.Alive do
        task.wait(math.max(G.AttackDelay, 0.1))
        if G.AttackEnabled and targetInActionRange() then
            playAttackAnimation()
            pcall(function() SwordAttack:FireServer() end)
        end
    end
end)

task.spawn(function()
    while Runtime.Alive do
        task.wait(math.max(G.SkillDelay, 0.15))
        if G.SkillsEnabled and targetInActionRange() then
            for skill = 1, 3 do
                if not Runtime.Alive or not G.Enabled or not targetInActionRange() then break end
                if G["Skill" .. skill] then
                    pcall(function() UseSkill:FireServer(skill) end)
                    if G.SkillGap > 0 then task.wait(G.SkillGap) end
                end
            end
        end
    end
end)

connect(LocalPlayer.CharacterAdded, function()
    Runtime.Target = nil
    stopDefense()
    resetAttackAnimations()
    if G.Enabled then
        task.delay(1, saveStartPosition)
    end
end)

connect(LocalPlayer.CharacterRemoving, function()
    Runtime.ManualDefense = false
    Runtime.DefenseGeneration += 1
    Runtime.Defending = false
    resetAttackAnimations()
    stopFacing()
end)

-- Mesma defesa manual da versão anterior.
connect(UserInputService.InputBegan, function(input, processed)
    if processed or input.KeyCode ~= Enum.KeyCode.F then return end
    Runtime.ManualDefense = true
    Runtime.DefenseGeneration += 1
    setBlocking(true)
end)

connect(UserInputService.InputEnded, function(input)
    if input.KeyCode ~= Enum.KeyCode.F then return end
    Runtime.ManualDefense = false
    setBlocking(false)
end)

-- Interface
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window = Rayfield:CreateWindow({
    Name = "Legit Boss Farm",
    Icon = "swords",
    LoadingTitle = "Legit Boss Farm",
    LoadingSubtitle = "Movimento normal e defesa probabilística",
    ShowText = "Boss Farm",
    Theme = "Default",
    ToggleUIKeybind = Enum.KeyCode.F12,
    DisableRayfieldPrompts = true,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "LegitBossFarm",
        FileName = "SettingsV9",
    },
    Discord = {Enabled = false},
    KeySystem = false,
})

local FarmTab = Window:CreateTab("Combate", "swords")
local DefenseTab = Window:CreateTab("Defesa", "shield")
local PotionTab = Window:CreateTab("Poções", "heart-pulse")
local SettingsTab = Window:CreateTab("Ajustes", "settings")

local function bossNames()
    local names, found = {"Mais próximo"}, {}
    for _, mob in ipairs(allMobs()) do
        if not found[mob.Name] then
            found[mob.Name] = true
            table.insert(names, mob.Name)
        end
    end
    table.sort(names, function(a, b)
        if a == b then return false end
        if a == "Mais próximo" then return true end
        if b == "Mais próximo" then return false end
        return a < b
    end)
    return names
end

local BossDropdown
BossDropdown = FarmTab:CreateDropdown({
    Name = "Boss",
    Options = bossNames(),
    CurrentOption = {G.SelectedBoss},
    MultipleOptions = false,
    Flag = "SelectedBoss",
    Callback = function(options)
        G.SelectedBoss = options[1] or "Mais próximo"
        Runtime.Target = nil
        Runtime.LockedBossName = G.SelectedBoss ~= "Mais próximo" and G.SelectedBoss or nil
    end,
})
FarmTab:CreateButton({
    Name = "Atualizar lista de bosses",
    Callback = function()
        scanMobs()
        BossDropdown:Refresh(bossNames())
    end,
})
FarmTab:CreateToggle({
    Name = "Ativar farm próximo",
    CurrentValue = G.Enabled,
    Flag = "Enabled",
    Callback = setEnabled,
})
FarmTab:CreateToggle({Name = "Ataque básico", CurrentValue = G.AttackEnabled, Flag = "AttackEnabled",
    Callback = function(value) G.AttackEnabled = value end})
FarmTab:CreateToggle({Name = "Animação de ataque", CurrentValue = G.AttackAnimationEnabled,
    Flag = "AttackAnimationEnabled", Callback = function(value)
        G.AttackAnimationEnabled = value
        if not value then stopAttackAnimation() end
    end})
FarmTab:CreateToggle({Name = "Skills", CurrentValue = G.SkillsEnabled, Flag = "SkillsEnabled",
    Callback = function(value) G.SkillsEnabled = value end})
FarmTab:CreateToggle({Name = "Skill 1", CurrentValue = G.Skill1, Flag = "Skill1",
    Callback = function(value) G.Skill1 = value end})
FarmTab:CreateToggle({Name = "Skill 2", CurrentValue = G.Skill2, Flag = "Skill2",
    Callback = function(value) G.Skill2 = value end})
FarmTab:CreateToggle({Name = "Skill 3", CurrentValue = G.Skill3, Flag = "Skill3",
    Callback = function(value) G.Skill3 = value end})
FarmTab:CreateSlider({Name = "Intervalo do ataque", Range = {0.3, 2}, Increment = 0.01,
    Suffix = "s", CurrentValue = G.AttackDelay, Flag = "AttackDelay",
    Callback = function(value) G.AttackDelay = value end})
local animationFolderOptions = {}
do
    local anims = ReplicatedStorage:FindFirstChild("Anims")
    for _, folderName in ipairs({
        "SwordAnims", "StraightSwordAnims", "GreatSwordAnims", "KatanaAnims",
        "DaggerAnims", "DaggerAnims1", "LanceSwordAnims", "ScytheAnims",
    }) do
        if anims and anims:FindFirstChild(folderName) then
            table.insert(animationFolderOptions, folderName)
        end
    end
    if #animationFolderOptions == 0 then table.insert(animationFolderOptions, "SwordAnims") end
end
FarmTab:CreateDropdown({
    Name = "Conjunto de animações",
    Options = animationFolderOptions,
    CurrentOption = {G.AttackAnimationFolder},
    MultipleOptions = false,
    Flag = "AttackAnimationFolder",
    Callback = function(options)
        G.AttackAnimationFolder = options[1] or "SwordAnims"
        resetAttackAnimations()
    end,
})
FarmTab:CreateSlider({Name = "Velocidade da animação", Range = {0.5, 2}, Increment = 0.05,
    Suffix = "x", CurrentValue = G.AttackAnimationSpeed, Flag = "AttackAnimationSpeed",
    Callback = function(value) G.AttackAnimationSpeed = value end})
FarmTab:CreateSlider({Name = "Intervalo das skills", Range = {0.3, 8}, Increment = 0.05,
    Suffix = "s", CurrentValue = G.SkillDelay, Flag = "SkillDelay",
    Callback = function(value) G.SkillDelay = value end})
FarmTab:CreateSlider({Name = "Distância de combate", Range = {3, 10}, Increment = 0.25,
    Suffix = " studs", CurrentValue = G.CombatDistance, Flag = "CombatDistance",
    Callback = function(value) G.CombatDistance = value end})
FarmTab:CreateSlider({Name = "Alcance para agir", Range = {5, 18}, Increment = 0.5,
    Suffix = " studs", CurrentValue = G.ActionRange, Flag = "ActionRange",
    Callback = function(value) G.ActionRange = value end})
FarmTab:CreateToggle({Name = "Olhar para o boss", CurrentValue = G.FaceTarget, Flag = "FaceTarget",
    Callback = function(value)
        G.FaceTarget = value
        if not value then stopFacing() end
    end})
FarmTab:CreateSlider({Name = "Velocidade para virar", Range = {5, 100}, Increment = 5,
    CurrentValue = G.FacingResponsiveness, Flag = "FacingResponsiveness",
    Callback = function(value) G.FacingResponsiveness = value end})

DefenseTab:CreateToggle({Name = "Defesa automática", CurrentValue = G.BlockEnabled, Flag = "BlockEnabled",
    Callback = function(value) G.BlockEnabled = value if not value then stopDefense() end end})
DefenseTab:CreateSlider({Name = "Chance de defender", Range = {0, 100}, Increment = 1,
    Suffix = "%", CurrentValue = G.BlockChance, Flag = "BlockChance",
    Callback = function(value) G.BlockChance = value end})
DefenseTab:CreateSlider({Name = "Atraso da defesa", Range = {0, 0.8}, Increment = 0.001,
    Suffix = "s", CurrentValue = G.BlockDelay, Flag = "BlockDelay",
    Callback = function(value) G.BlockDelay = value end})
DefenseTab:CreateSlider({Name = "Tempo defendendo", Range = {0.01, 1.5}, Increment = 0.01,
    Suffix = "s", CurrentValue = G.BlockHoldTime, Flag = "BlockHoldTime",
    Callback = function(value) G.BlockHoldTime = value end})
DefenseTab:CreateSlider({Name = "Alcance da defesa", Range = {5, 40}, Increment = 1,
    Suffix = " studs", CurrentValue = G.BlockRange, Flag = "BlockRange",
    Callback = function(value) G.BlockRange = value end})

DefenseTab:CreateSection("Círculos de dano")
DefenseTab:CreateToggle({
    Name = "Defender dentro de círculos",
    CurrentValue = G.AreaBlockEnabled,
    Flag = "AreaBlockEnabled",
    Callback = function(value) G.AreaBlockEnabled = value end,
})
DefenseTab:CreateSlider({
    Name = "Disco crescendo: defender em",
    Range = {20, 40},
    Increment = 0.5,
    Suffix = " diâmetro",
    CurrentValue = G.AreaGrowingTrigger,
    Flag = "AreaGrowingTrigger",
    Callback = function(value) G.AreaGrowingTrigger = value end,
})
DefenseTab:CreateSlider({
    Name = "Disco encolhendo: defender em",
    Range = {30, 60},
    Increment = 0.5,
    Suffix = " diâmetro",
    CurrentValue = G.AreaShrinkingTrigger,
    Flag = "AreaShrinkingTrigger",
    Callback = function(value) G.AreaShrinkingTrigger = value end,
})
DefenseTab:CreateSlider({
    Name = "Tempo de defesa da área",
    Range = {0.1, 1.2},
    Increment = 0.01,
    Suffix = "s",
    CurrentValue = G.AreaBlockHoldTime,
    Flag = "AreaBlockHoldTime",
    Callback = function(value) G.AreaBlockHoldTime = value end,
})
DefenseTab:CreateSlider({
    Name = "Margem do círculo",
    Range = {0, 6},
    Increment = 0.25,
    Suffix = " studs",
    CurrentValue = G.AreaInsideMargin,
    Flag = "AreaInsideMargin",
    Callback = function(value) G.AreaInsideMargin = value end,
})

local potionIds = {
    "HealthPotion",
    "MediumHealthPotion",
    "LargeHealthPotion",
    "BigHealthPotion",
    "DefencePotion",
}
local potionLabels, potionIdByLabel, potionLabelById = {}, {}, {}
for _, potionId in ipairs(potionIds) do
    local data = PotionData[potionId] or {}
    local displayName = data.Name or potionId
    local potionLabel = data.Health
        and string.format("%s (+%d HP)", displayName, data.Health)
        or displayName
    potionIdByLabel[potionLabel] = potionId
    potionLabelById[potionId] = potionLabel
    table.insert(potionLabels, potionLabel)
end

local initialPotions = {}
for _, potionId in ipairs(potionIds) do
    if G.SelectedPotions[potionId] then
        table.insert(initialPotions, potionLabelById[potionId])
    end
end

PotionTab:CreateToggle({
    Name = "Auto Potion",
    CurrentValue = G.AutoPotionEnabled,
    Flag = "AutoPotionEnabled",
    Callback = function(value) G.AutoPotionEnabled = value end,
})
PotionTab:CreateDropdown({
    Name = "Poções para usar",
    Options = potionLabels,
    CurrentOption = initialPotions,
    MultipleOptions = true,
    Flag = "SelectedPotionsV2",
    Callback = function(options)
        table.clear(G.SelectedPotions)
        for _, potionLabel in ipairs(options) do
            local potionId = potionIdByLabel[potionLabel]
            if potionId then G.SelectedPotions[potionId] = true end
        end
    end,
})
PotionTab:CreateSlider({
    Name = "Usar abaixo de",
    Range = {1, 100},
    Increment = 1,
    Suffix = "% HP",
    CurrentValue = G.PotionThreshold,
    Flag = "PotionThreshold",
    Callback = function(value) G.PotionThreshold = value end,
})
PotionTab:CreateSlider({
    Name = "Cooldown das poções",
    Range = {0.1, 10},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = G.PotionCooldown,
    Flag = "PotionCooldown",
    Callback = function(value) G.PotionCooldown = value end,
})
PotionTab:CreateSlider({
    Name = "Intervalo entre poções",
    Range = {0, 1},
    Increment = 0.01,
    Suffix = "s",
    CurrentValue = G.PotionBurstDelay,
    Flag = "PotionBurstDelay",
    Callback = function(value) G.PotionBurstDelay = value end,
})

SettingsTab:CreateSlider({Name = "Limite da área do boss", Range = {15, 200}, Increment = 5,
    Suffix = " studs", CurrentValue = G.BossAreaRadius, Flag = "BossAreaRadius",
    Callback = function(value)
        G.BossAreaRadius = value
        if Runtime.Target and not validTarget(Runtime.Target) then Runtime.Target = nil end
    end})
SettingsTab:CreateSlider({Name = "Intervalo para acompanhar", Range = {0.05, 0.5}, Increment = 0.01,
    Suffix = "s", CurrentValue = G.FollowInterval, Flag = "FollowInterval",
    Callback = function(value) G.FollowInterval = value end})
SettingsTab:CreateButton({Name = "Redefinir posição inicial aqui", Callback = function()
    saveStartPosition()
    Runtime.Target = nil
end})

SettingsTab:CreateToggle({
    Name = "AntiAFK",
    CurrentValue = G.AntiAFK,
    Flag = "AntiAFK",
    Callback = function(value)
        G.AntiAFK = value
    end,
})

local MenuKeybindControl = SettingsTab:CreateKeybind({
    Name = "Tecla da interface",
    CurrentKeybind = G.MenuKey,
    HoldToInteract = false,
    Flag = "MenuKey",
    Callback = function(key)
        if typeof(key) == "EnumItem" then G.MenuKey = key.Name end
    end,
})

local function configuredMenuKey()
    local selected = MenuKeybindControl and MenuKeybindControl.CurrentKeybind or G.MenuKey
    if typeof(selected) == "EnumItem" and selected.EnumType == Enum.KeyCode then return selected end
    if type(selected) == "string" then return Enum.KeyCode[selected] end
    return Enum.KeyCode.RightShift
end

connect(UserInputService.InputBegan, function(input, processed)
    if processed or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local key = configuredMenuKey()
    if key and input.KeyCode == key then
        G.MenuKey = key.Name
        Rayfield:SetVisibility(not Rayfield:IsVisible())
    end
end)

Rayfield:LoadConfiguration()
