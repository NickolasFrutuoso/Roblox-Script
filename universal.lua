--// Merchant + Crafting + Player Stats - MacUI

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local MerchantRequest = ReplicatedStorage:WaitForChild("MerchantRequest")
local MerchantStockUpdate = ReplicatedStorage:WaitForChild("MerchantStockUpdate")
local MerchantBuy = ReplicatedStorage:WaitForChild("MerchantBuy")
local AllocateAttribute = ReplicatedStorage:WaitForChild("AllocateAttribute")
local SwordAttack = ReplicatedStorage:WaitForChild("SwordAttack")
local UseSkill = ReplicatedStorage:WaitForChild("UseSkill")
local SetBlocking = ReplicatedStorage:WaitForChild("SetBlocking")
local UsePotion = ReplicatedStorage:WaitForChild("UsePotion")
local SaveSettings = ReplicatedStorage:WaitForChild("SaveSettings")

local MerchantData = {}
local CraftingData = {}
local MonsterData = {}
local MonsterSpawnData = {}
local QuestData = {}
local PotionData = {}
do
    local zen = ReplicatedStorage:FindFirstChild("ZenFolder")
    local module = zen and zen:FindFirstChild("MerchantData")
    if module then
        local ok, result = pcall(require, module)
        if ok and type(result) == "table" then MerchantData = result end
    end
    local craftingModule = zen and zen:FindFirstChild("CraftingData")
    if craftingModule then
        local ok, result = pcall(require, craftingModule)
        if ok and type(result) == "table" then CraftingData = result end
    end
    local monsterModule = zen and zen:FindFirstChild("MonsterData")
    if monsterModule then
        local ok, result = pcall(require, monsterModule)
        if ok and type(result) == "table" then MonsterData = result end
    end
    local spawnModule = zen and zen:FindFirstChild("MonsterSpawnConfig")
    if spawnModule then
        local ok, result = pcall(require, spawnModule)
        if ok and type(result) == "table" then MonsterSpawnData = result end
    end
    local questModule = zen and zen:FindFirstChild("QuestData")
    if questModule then
        local ok, result = pcall(require, questModule)
        if ok and type(result) == "table" then QuestData = result end
    end
    local potionModule = zen and zen:FindFirstChild("PotionData")
    if potionModule then
        local ok, result = pcall(require, potionModule)
        if ok and type(result) == "table" then PotionData = result end
    end
end

if _G.SimpleMerchantAutoBuyRuntime and _G.SimpleMerchantAutoBuyRuntime.Stop then
    _G.SimpleMerchantAutoBuyRuntime.Stop()
end

_G.SimpleMerchantAutoBuy = _G.SimpleMerchantAutoBuy or {}
local G = _G.SimpleMerchantAutoBuy
if G.Enabled == nil then G.Enabled = false end
if G.SelectedItems == nil then G.SelectedItems = {} end
if G.BuyMode == nil then G.BuyMode = "Quantidade" end
if G.Quantity == nil then G.Quantity = 1 end
if G.AutoAttribute == nil then G.AutoAttribute = false end
if G.AttributeTarget == nil then G.AttributeTarget = "Damage" end
if G.SelectedCraft == nil then G.SelectedCraft = "Nenhum" end
if G.FarmEnabled == nil then G.FarmEnabled = false end
if G.SelectedMobs == nil then G.SelectedMobs = {} end
if G.FarmDistance == nil then G.FarmDistance = 6 end
if G.AttackDelay == nil then G.AttackDelay = 0.45 end
if G.BlockEnabled == nil then G.BlockEnabled = false end
if G.BlockDelay == nil then G.BlockDelay = 0.10 end
if G.BlockHold == nil then G.BlockHold = 0.20 end
if G.BlockRange == nil then G.BlockRange = 24 end
if G.DodgeEnabled == nil then G.DodgeEnabled = false end
if G.DodgeDistance == nil then G.DodgeDistance = 8 end
if G.DodgeMargin == nil then G.DodgeMargin = 5 end
if G.QuestEnabled == nil then G.QuestEnabled = true end
if G.SelectedQuests == nil then G.SelectedQuests = {} end
if G.QuestTeleportDelay == nil then G.QuestTeleportDelay = 0.5 end
if G.QuestInteractDelay == nil then G.QuestInteractDelay = 0.75 end
if G.NativeAutoQuest == nil then G.NativeAutoQuest = false end
if G.AutoPotionEnabled == nil then G.AutoPotionEnabled = false end
if G.SelectedPotions == nil then G.SelectedPotions = {MediumHealthPotion = true} end
if G.PotionThreshold == nil then G.PotionThreshold = 90 end
if G.PotionCooldown == nil then G.PotionCooldown = 1 end
if G.NoClip == nil then G.NoClip = true end
if G.AntiAFK == nil then G.AntiAFK = false end
if G.AntiVoid == nil then G.AntiVoid = true end
if G.MenuKeybind == nil then G.MenuKeybind = "F12" end
if G.LegitFarmEnabled == nil then G.LegitFarmEnabled = false end
if G.LegitFarmMode == nil then G.LegitFarmMode = "Parado" end
if G.LegitFarmRadius == nil then G.LegitFarmRadius = 25 end
if G.LegitActionRange == nil then G.LegitActionRange = 12 end

local Runtime = {
    Running = true,
    Connections = {},
    Stock = {},
    Catalog = {},
    LabelToId = {},
    IdToLabel = {},
    UpdatingDropdown = false,
    ReceivedInitialStock = false,
    Remaining = 0,
    Deadline = nil,
    LastStockSignature = nil,
    RestockGeneration = 0,
    Buying = false,
    RequestedAtZero = false,
    AllocatingAttribute = false,
    CappedAttributes = {},
    BuyRequested = false,
    LastBuyStatus = "Aguardando Auto Buy.",
    FarmTarget = nil,
    MovementPausedUntil = 0,
    ActiveAreas = {},
    Defending = false,
    DefenseGeneration = 0,
    WatchedMobs = {},
    LastDodge = 0,
    LastFarmMove = 0,
    LastFarmStatusTarget = nil,
    QuestBusy = false,
    PotionBusy = false,
    LastPotionUse = 0,
    NoClipParts = {},
    LastSafeCFrame = nil,
    LegitTarget = nil,
    LegitTargetId = nil,
    LegitOrigin = nil,
    LegitDetectedAt = 0,
    LegitLastMove = 0,
    AttackTrack = nil,
    AttackAnimator = nil,
    AttackTrackCache = {},
    ComboIndex = 1,
    LegitLastStatus = 0,
}
_G.SimpleMerchantAutoBuyRuntime = Runtime

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(Runtime.Connections, connection)
    return connection
end

for id, data in pairs(MerchantData.Resources or {}) do
    if data.Stockable ~= false then
        Runtime.Catalog[tostring(id)] = {
            id = tostring(id),
            price = tonumber(data.Price) or 0,
        }
    end
end

local function normalizeStock(payload)
    local result = {}
    if type(payload) ~= "table" then return result end
    for key, entry in pairs(payload) do
        if type(entry) == "table" and entry.id then
            local id = tostring(entry.id)
            result[id] = {
                id = id,
                price = tonumber(entry.price)
                    or (Runtime.Catalog[id] and Runtime.Catalog[id].price)
                    or 0,
                stock = math.max(0, math.floor(tonumber(entry.stock) or 0)),
            }
        elseif type(key) == "string" and type(entry) == "number" then
            result[key] = {
                id = key,
                price = Runtime.Catalog[key] and Runtime.Catalog[key].price or 0,
                stock = math.max(0, math.floor(entry)),
            }
        end
    end
    return result
end

local MacLib = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/NickolasFrutuoso/MacUI/refs/heads/main/UI"
))()
pcall(function() MacLib:SetFolder("OvergearedMacUI") end)

local camera = Workspace.CurrentCamera
local viewport = camera and camera.ViewportSize or Vector2.new(868, 650)
local compactUI = UserInputService.TouchEnabled or viewport.X < 900
local function mobileWindowSize(size)
    local width = math.min(math.clamp(size.X - 24, 280, 680), math.max(220, size.X - 8))
    local height = math.min(math.clamp(size.Y - 70, 340, 600), math.max(300, size.Y - 8))
    return UDim2.fromOffset(width, height)
end
local windowSize = compactUI and mobileWindowSize(viewport) or UDim2.fromOffset(868, 650)

local MacWindow = MacLib:Window({
    Title = "Merchant + Player Stats",
    Subtitle = "Auto Buy · Crafting · Progressão",
    Size = windowSize,
    DragStyle = 1,
    AcrylicBlur = false,
    Keybind = Enum.KeyCode[G.MenuKeybind] or Enum.KeyCode.F12,
    ShowUserInfo = not compactUI,
    DisabledWindowControls = {},
})

if compactUI and camera then
    connect(camera:GetPropertyChangedSignal("ViewportSize"), function()
        pcall(function() MacWindow:SetSize(mobileWindowSize(camera.ViewportSize)) end)
    end)
end

-- O keybind da biblioteca não atende celulares. Este botão fica fora da
-- janela da MacUI e usa os métodos oficiais SetState/GetState para alterná-la.
if compactUI then
    local mobileGui = Instance.new("ScreenGui")
    mobileGui.Name = "MerchantMobileToggle"
    mobileGui.ResetOnSpawn = false
    mobileGui.IgnoreGuiInset = true
    mobileGui.DisplayOrder = 999999
    mobileGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local button = Instance.new("TextButton")
    button.Name = "Toggle"
    button.AnchorPoint = Vector2.new(1, 1)
    button.Position = UDim2.new(1, -16, 1, -90)
    button.Size = UDim2.fromOffset(54, 54)
    button.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
    button.BackgroundTransparency = 0.08
    button.Text = "−"
    button.TextColor3 = Color3.fromRGB(245, 245, 247)
    button.TextSize = 28
    button.Font = Enum.Font.GothamMedium
    button.AutoButtonColor = true
    button.ZIndex = 100
    button.Parent = mobileGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = button

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(90, 90, 96)
    stroke.Transparency = 0.25
    stroke.Thickness = 1
    stroke.Parent = button

    Runtime.MobileGui = mobileGui
    connect(button.Activated, function()
        local visible = MacWindow:GetState()
        MacWindow:SetState(not visible)
        button.Text = visible and "☰" or "−"
    end)
    task.spawn(function()
        while Runtime.Running and mobileGui.Parent do
            task.wait(0.25)
            pcall(function()
                button.Text = MacWindow:GetState() and "−" or "☰"
            end)
        end
    end)
end

-- Adaptador pequeno para manter a lógica separada da biblioteca visual.
local MacTabGroup = MacWindow:TabGroup()
local firstMacTab
local Window = {}

function Window:CreateTab(name, image)
    local validImage = type(image) == "string"
        and image:find("^rbxassetid://") and image or nil
    local macTab = MacTabGroup:Tab({Name = name, Image = validImage})
    local sections = {}
    local function getSection(side, card)
        -- Em telas estreitas, empilha os cards em uma coluna.
        side = compactUI and "Left" or (side == "Right" and "Right" or "Left")
        local key = side .. "::" .. tostring(card or "Default")
        if not sections[key] then
            sections[key] = macTab:Section({Side = side})
        end
        return sections[key]
    end
    if not firstMacTab then firstMacTab = macTab end
    local tab = {}

    function tab:CreateParagraph(settings)
        local section = getSection(settings.Side, settings.Card)
        local control = section:Paragraph({
            Header = settings.Title or "",
            Body = settings.Content or "",
        })
        local wrapper = {}
        function wrapper:Set(value)
            if value.Title ~= nil then control:UpdateHeader(value.Title) end
            if value.Content ~= nil then control:UpdateBody(value.Content) end
        end
        return wrapper
    end

    function tab:CreateDropdown(settings)
        local section = getSection(settings.Side, settings.Card)
        local default = settings.CurrentOption
        if not settings.MultipleOptions and type(default) == "table" then
            default = default[1]
        end
        local control = section:Dropdown({
            Name = settings.Name,
            Options = settings.Options or {},
            Default = default,
            Multi = settings.MultipleOptions == true,
            Required = false,
            Search = true,
            Callback = function(value)
                if settings.MultipleOptions then
                    local normalized = {}
                    if type(value) == "table" then
                        for key, entry in pairs(value) do
                            if type(key) == "number" and type(entry) == "string" then
                                table.insert(normalized, entry)
                            elseif type(key) == "string" and entry == true then
                                table.insert(normalized, key)
                            elseif type(entry) == "table" and entry.Value and entry.Selected ~= false then
                                table.insert(normalized, tostring(entry.Value))
                            end
                        end
                    elseif type(value) == "string" then
                        table.insert(normalized, value)
                    end
                    settings.Callback(normalized)
                else
                    settings.Callback({value})
                end
            end,
        }, settings.Flag)
        local wrapper = {}
        function wrapper:Refresh(options)
            control:ClearOptions()
            control:InsertOptions(options)
        end
        function wrapper:Set(value)
            if not settings.MultipleOptions and type(value) == "table" then value = value[1] end
            if settings.MultipleOptions then
                -- A MacUI pode preservar seleções anteriores ao atualizar uma
                -- lista múltipla. Limpar primeiro garante substituição real.
                control:UpdateSelection({})
            end
            control:UpdateSelection(value)
        end
        return wrapper
    end

    function tab:CreateToggle(settings)
        local section = getSection(settings.Side, settings.Card)
        local control = section:Toggle({
            Name = settings.Name,
            Default = settings.CurrentValue == true,
            Callback = settings.Callback,
        }, settings.Flag)
        local wrapper = {}
        function wrapper:Set(value) control:UpdateState(value == true) end
        return wrapper
    end

    function tab:CreateInput(settings)
        local section = getSection(settings.Side, settings.Card)
        local control = section:Input({
            Name = settings.Name,
            Default = tostring(settings.CurrentValue or ""),
            Placeholder = settings.PlaceholderText or "",
            AcceptedCharacters = "All",
            Callback = settings.Callback,
        }, settings.Flag)
        local wrapper = {}
        function wrapper:Set(value) control:UpdateText(tostring(value or "")) end
        return wrapper
    end

    function tab:CreateSlider(settings)
        local section = getSection(settings.Side, settings.Card)
        local range = settings.Range or {0, 100}
        local control = section:Slider({
            Name = settings.Name,
            Minimum = range[1],
            Maximum = range[2],
            Default = settings.CurrentValue or range[1],
            Precision = settings.Increment and settings.Increment < 1 and 2 or 0,
            DisplayMethod = "Value",
            Suffix = settings.Suffix or "",
            Callback = settings.Callback,
        }, settings.Flag)
        local wrapper = {}
        function wrapper:Set(value) control:UpdateValue(value) end
        return wrapper
    end

    function tab:CreateButton(settings)
        local section = getSection(settings.Side, settings.Card)
        return section:Button({Name = settings.Name, Callback = settings.Callback}, settings.Flag)
    end

    return tab
end


local Rayfield = {}
function Rayfield:Destroy()
    MacWindow:Unload()
end

--// Auto Farm / Auto Block / Auto Dodge -------------------------------------

local MonstersFolder = Workspace:FindFirstChild("Monsters") or Workspace:WaitForChild("Monsters")
local DebrisFolder = Workspace:FindFirstChild("Debris") or Workspace:WaitForChild("Debris")

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

local function aliveMob(model)
    local humanoid = model and model:FindFirstChildOfClass("Humanoid")
    return model and model.Parent and humanoid and humanoid.Health > 0 and modelRoot(model) ~= nil
end

local function activeMobs()
    local result = {}
    for _, object in ipairs(MonstersFolder:GetDescendants()) do
        if object:IsA("Model") and aliveMob(object) then
            table.insert(result, object)
        end
    end
    return result
end

local mobIds = {}
local MobLabelToId, MobIdToLabel = {}, {}
for id, data in pairs(MonsterData) do
    table.insert(mobIds, id)
    local label = string.format("%s  ·  Lv.%d", data.Name or id, tonumber(data.Level) or 0)
    MobLabelToId[label], MobIdToLabel[id] = id, label
end
table.sort(mobIds, function(a, b)
    local levelA = tonumber(MonsterData[a] and MonsterData[a].Level) or 0
    local levelB = tonumber(MonsterData[b] and MonsterData[b].Level) or 0
    if levelA ~= levelB then return levelA < levelB end
    return a < b
end)
local mobOptions = {}
for _, id in ipairs(mobIds) do table.insert(mobOptions, MobIdToLabel[id]) end

local function mobDataId(name)
    if MonsterData[name] then return name end
    for id, data in pairs(MonsterData) do
        if data.Name == name then return id end
    end
    return name
end

local function findFarmTarget()
    local _, _, playerRoot = characterData()
    if not playerRoot then return nil end
    local mobsByName = {}
    for _, mob in ipairs(activeMobs()) do
        local id = mobDataId(mob.Name)
        mobsByName[id] = mobsByName[id] or {}
        table.insert(mobsByName[id], mob)
    end

    -- Prioridade fixa por nível/ID. Se não existe, tenta o próximo selecionado.
    local priority = Runtime.FarmPriority or mobIds
    for _, id in ipairs(priority) do
        if G.SelectedMobs[id] and mobsByName[id] then
            local nearest, nearestDistance
            for _, mob in ipairs(mobsByName[id]) do
                local root = modelRoot(mob)
                local distance = (root.Position - playerRoot.Position).Magnitude
                if not nearestDistance or distance < nearestDistance then
                    nearest, nearestDistance = mob, distance
                end
            end
            if nearest then return nearest end
        end
    end
    return nil
end

local function hasActiveArea()
    for area in pairs(Runtime.ActiveAreas) do
        if area.Parent then return true end
        Runtime.ActiveAreas[area] = nil
    end
    return false
end

local function farmPaused()
    return Runtime.QuestBusy or hasActiveArea() or os.clock() < Runtime.MovementPausedUntil
end

-- Mantém apenas a orientação estável usada no farm legítimo. O eixo Y é
-- ignorado para o personagem não inclinar quando o alvo estiver acima/abaixo.
local function stopFarmFacing()
    if Runtime.FacingAlign then Runtime.FacingAlign:Destroy() end
    if Runtime.FacingAttachment then Runtime.FacingAttachment:Destroy() end
    if Runtime.FacingHumanoid and Runtime.FacingHumanoid.Parent then
        Runtime.FacingHumanoid.AutoRotate = true
    end
    Runtime.FacingAlign = nil
    Runtime.FacingAttachment = nil
    Runtime.FacingHumanoid = nil
end

local function faceFarmTarget(humanoid, root, targetPosition)
    if Runtime.FacingHumanoid ~= humanoid
        or not Runtime.FacingAlign
        or not Runtime.FacingAlign.Parent then
        stopFarmFacing()

        local attachment = Instance.new("Attachment")
        attachment.Name = "SimpleFarmFacingAttachment"
        attachment.Parent = root

        local align = Instance.new("AlignOrientation")
        align.Name = "SimpleFarmFacing"
        align.Mode = Enum.OrientationAlignmentMode.OneAttachment
        align.Attachment0 = attachment
        align.RigidityEnabled = false
        align.Responsiveness = 100
        align.MaxTorque = 1000000000
        align.Parent = root

        Runtime.FacingAttachment = attachment
        Runtime.FacingAlign = align
        Runtime.FacingHumanoid = humanoid
        humanoid.AutoRotate = false
    end

    local direction = Vector3.new(
        targetPosition.X - root.Position.X,
        0,
        targetPosition.Z - root.Position.Z
    )
    if direction.Magnitude > 0.05 then
        Runtime.FacingAlign.CFrame = CFrame.lookAt(Vector3.zero, direction.Unit)
    end
end

local CombatTab = Window:CreateTab("Combat", nil)

local FarmStatus = CombatTab:CreateParagraph({
    Title = "Auto Farm parado",
    Content = "Selecione um ou mais monstros.",
    Side = "Left", Card = "Farm",
})

local MobDropdown
local FarmToggle
local LegitFarmToggle
MobDropdown = CombatTab:CreateDropdown({
    Name = "Monstros em ordem de prioridade",
    Options = mobOptions,
    CurrentOption = (function()
        local labels = {}
        for id, enabled in pairs(G.SelectedMobs) do
            if enabled and MobIdToLabel[id] then table.insert(labels, MobIdToLabel[id]) end
        end
        return labels
    end)(),
    MultipleOptions = true,
    Flag = "MacCombatSelectedMobs",
    Side = "Left", Card = "Farm",
    Callback = function(options)
        if Runtime.UpdatingMobDropdown then return end
        Runtime.FarmPriority = nil
        Runtime.CraftFarmSignature = nil
        table.clear(G.SelectedMobs)
        for _, label in ipairs(options) do
            local id = MobLabelToId[label]
            if id then G.SelectedMobs[id] = true end
        end
        Runtime.FarmTarget = nil
    end,
})

FarmToggle = CombatTab:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = G.FarmEnabled,
    Flag = "MacCombatFarm",
    Side = "Left", Card = "Farm",
    Callback = function(value)
        G.FarmEnabled = value
        if value and G.LegitFarmEnabled then
            G.LegitFarmEnabled = false
            if LegitFarmToggle then LegitFarmToggle:Set(false) end
        end
        if not value then Runtime.FarmTarget = nil end
    end,
})

CombatTab:CreateSlider({
    Name = "Distância do monstro", Range = {3, 15}, Increment = 0.5,
    CurrentValue = G.FarmDistance, Suffix = " studs",
    Side = "Left", Card = "Farm", Flag = "MacCombatDistance",
    Callback = function(value) G.FarmDistance = value end,
})

local LegitStatus = CombatTab:CreateParagraph({
    Title = "Legit Farm",
    Content = "Procura o mob mais próximo dentro do raio.",
    Side = "Left", Card = "LegitFarm",
})

LegitFarmToggle = CombatTab:CreateToggle({
    Name = "Legit Farm", CurrentValue = G.LegitFarmEnabled,
    Flag = "MacLegitFarm", Side = "Left", Card = "LegitFarm",
    Callback = function(value)
        G.LegitFarmEnabled = value
        if value then
            G.FarmEnabled = false
            FarmToggle:Set(false)
            local _, _, root = characterData()
            Runtime.LegitOrigin = root and root.Position or nil
        end
        Runtime.LegitTarget = nil
        Runtime.LegitTargetId = nil
        Runtime.LegitDetectedAt = 0
        if not value then
            local _, humanoid, root = characterData()
            if humanoid and root then humanoid:MoveTo(root.Position) end
        end
    end,
})

CombatTab:CreateDropdown({
    Name = "Modo", Options = {"Parado", "Aproximar"},
    CurrentOption = {G.LegitFarmMode}, MultipleOptions = false,
    Flag = "MacLegitFarmMode", Side = "Left", Card = "LegitFarm",
    Callback = function(options)
        G.LegitFarmMode = options[1] or "Parado"
        if G.LegitFarmMode == "Parado" then
            local _, humanoid, root = characterData()
            if humanoid and root then humanoid:MoveTo(root.Position) end
        end
    end,
})

CombatTab:CreateSlider({
    Name = "Raio de busca", Range = {5, 60}, Increment = 1, Suffix = " studs",
    CurrentValue = G.LegitFarmRadius, Flag = "MacLegitFarmRadius",
    Side = "Left", Card = "LegitFarm",
    Callback = function(value) G.LegitFarmRadius = value end,
})

CombatTab:CreateSlider({
    Name = "Intervalo de ataque", Range = {0.1, 1.5}, Increment = 0.05,
    CurrentValue = G.AttackDelay, Suffix = "s",
    Side = "Left", Card = "Farm", Flag = "MacCombatAttackDelay",
    Callback = function(value) G.AttackDelay = value end,
})

local BlockStatus = CombatTab:CreateParagraph({
    Title = "Auto Block",
    Content = "Defende ao iniciar uma animação hostil próxima.",
    Side = "Right", Card = "Block",
})

CombatTab:CreateToggle({
    Name = "Auto Block", CurrentValue = G.BlockEnabled,
    Side = "Right", Card = "Block", Flag = "MacCombatBlock",
    Callback = function(value)
        G.BlockEnabled = value
        if not value and Runtime.Defending then
            Runtime.Defending = false
            SetBlocking:FireServer(false)
        end
    end,
})

CombatTab:CreateSlider({
    Name = "Atraso da defesa", Range = {0, 0.5}, Increment = 0.01,
    CurrentValue = G.BlockDelay, Suffix = "s",
    Side = "Right", Card = "Block", Flag = "MacCombatBlockDelay",
    Callback = function(value) G.BlockDelay = value end,
})

CombatTab:CreateSlider({
    Name = "Duração da defesa", Range = {0.05, 1}, Increment = 0.01,
    CurrentValue = G.BlockHold, Suffix = "s",
    Side = "Right", Card = "Block", Flag = "MacCombatBlockHold",
    Callback = function(value) G.BlockHold = value end,
})

local DodgeStatus = CombatTab:CreateParagraph({
    Title = "Auto Dodge",
    Content = "Rajadas: atrás do lançador · Áreas: ponto horizontal seguro.",
    Side = "Right", Card = "Dodge",
})

CombatTab:CreateToggle({
    Name = "Auto Dodge", CurrentValue = G.DodgeEnabled,
    Side = "Right", Card = "Dodge", Flag = "MacCombatDodge",
    Callback = function(value) G.DodgeEnabled = value end,
})

CombatTab:CreateSlider({
    Name = "Distância da esquiva", Range = {4, 20}, Increment = 0.5,
    CurrentValue = G.DodgeDistance, Suffix = " studs",
    Side = "Right", Card = "Dodge", Flag = "MacCombatDodgeDistance",
    Callback = function(value) G.DodgeDistance = value end,
})

CombatTab:CreateSlider({
    Name = "Margem das áreas", Range = {1, 12}, Increment = 0.5,
    CurrentValue = G.DodgeMargin, Suffix = " studs",
    Side = "Right", Card = "Dodge", Flag = "MacCombatDodgeMargin",
    Callback = function(value) G.DodgeMargin = value end,
})

local function setDefending(value)
    if Runtime.Defending == value then return end
    Runtime.Defending = value
    SetBlocking:FireServer(value)
end

local function defendFor(duration)
    Runtime.DefenseGeneration += 1
    local generation = Runtime.DefenseGeneration
    setDefending(true)
    task.delay(duration, function()
        if Runtime.Running and generation == Runtime.DefenseGeneration then setDefending(false) end
    end)
end

local function watchMobForBlock(mob)
    if Runtime.WatchedMobs[mob] or not aliveMob(mob) then return end
    local humanoid, root = mob:FindFirstChildOfClass("Humanoid"), modelRoot(mob)
    local animator = humanoid and (humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator", 3))
    if not animator or not root then return end
    Runtime.WatchedMobs[mob] = connect(animator.AnimationPlayed, function(track)
        if not G.BlockEnabled or track.Looped or not track.Animation then return end
        local _, _, playerRoot = characterData()
        if not playerRoot or (playerRoot.Position - root.Position).Magnitude > G.BlockRange then return end
        task.delay(G.BlockDelay, function()
            if Runtime.Running and G.BlockEnabled and aliveMob(mob) then defendFor(G.BlockHold) end
        end)
    end)
end

for _, mob in ipairs(activeMobs()) do task.spawn(watchMobForBlock, mob) end
connect(MonstersFolder.DescendantAdded, function(object)
    if object:IsA("Model") then
        task.defer(watchMobForBlock, object)
        task.delay(0.25, watchMobForBlock, object)
        task.delay(1, watchMobForBlock, object)
    end
end)

-- Alguns spawns chegam como Model antes de Humanoid/Animator serem replicados.
task.spawn(function()
    while Runtime.Running do
        task.wait(2)
        if G.BlockEnabled then
            for _, mob in ipairs(activeMobs()) do task.spawn(watchMobForBlock, mob) end
        end
    end
end)

local function isEnemySlice(object)
    return object:IsA("BasePart") and object.Name:lower() == "slice"
        and math.max(object.Size.X, object.Size.Y, object.Size.Z) >= 15
end

local function isEnemyArea(object)
    if not object:IsA("Part") or object.Shape ~= Enum.PartType.Cylinder or not object.Anchored then return false end
    return object.Color.R >= 0.6 and object.Color.R > object.Color.G * 1.5
        and object.Color.R > object.Color.B * 1.5
        and math.max(object.Size.Y, object.Size.Z) >= 20
end

local function horizontalUnit(vector, fallback)
    local flat = Vector3.new(vector.X, 0, vector.Z)
    return flat.Magnitude > 0.01 and flat.Unit or fallback
end

local function pointInsideArea(point, area)
    local localPoint = area.CFrame:PointToObjectSpace(point)
    return Vector2.new(localPoint.Y, localPoint.Z).Magnitude
        <= math.max(area.Size.Y, area.Size.Z) / 2 + G.DodgeMargin
end

local function allEnemyAreas()
    local result = {}
    for _, object in ipairs(DebrisFolder:GetDescendants()) do
        if isEnemyArea(object) then table.insert(result, object) end
    end
    return result
end

local function safeAreaPoint(root, area)
    local origin = root.Position
    local preferred = horizontalUnit(origin - area.Position, root.CFrame.RightVector)
    local areas = allEnemyAreas()
    for distance = 5, 80, 5 do
        for index = 0, 23 do
            local angle = math.atan2(preferred.Z, preferred.X) + index / 24 * math.pi * 2
            local point = origin + Vector3.new(math.cos(angle), 0, math.sin(angle)) * distance
            local safe = true
            for _, other in ipairs(areas) do
                if pointInsideArea(point, other) then safe = false break end
            end
            if safe then return point end
        end
    end
end

local function dodgeObject(object)
    if not G.DodgeEnabled or os.clock() - Runtime.LastDodge < 0.3 then return end
    local character, _, root = characterData()
    if not character then return end

    if isEnemySlice(object) then
        local caster, casterDistance
        for _, mob in ipairs(activeMobs()) do
            local mobRoot = modelRoot(mob)
            local distance = (mobRoot.Position - object.Position).Magnitude
            if distance <= 50 and (not casterDistance or distance < casterDistance) then
                caster, casterDistance = mobRoot, distance
            end
        end
        if caster then
            local forward = horizontalUnit(caster.CFrame.LookVector, -Vector3.zAxis)
            local point = caster.Position - forward * G.DodgeDistance
            character:PivotTo(CFrame.lookAt(Vector3.new(point.X, root.Position.Y, point.Z), caster.Position))
            Runtime.MovementPausedUntil = os.clock() + 0.6
            Runtime.LastDodge = os.clock()
        end
    elseif isEnemyArea(object) and pointInsideArea(root.Position, object) then
        Runtime.ActiveAreas[object] = true
        local point = safeAreaPoint(root, object)
        if point then
            character:PivotTo(CFrame.lookAt(point, point + root.CFrame.LookVector))
            Runtime.LastDodge = os.clock()
        end
        connect(object.AncestryChanged, function(_, parent)
            if not parent then
                Runtime.ActiveAreas[object] = nil
                Runtime.MovementPausedUntil = os.clock() + 0.25
            end
        end)
    end
end

connect(DebrisFolder.DescendantAdded, function(object)
    task.defer(dodgeObject, object)
    task.delay(0.08, dodgeObject, object)
    task.delay(0.25, dodgeObject, object)
end)

connect(RunService.Heartbeat, function()
    if not G.FarmEnabled or farmPaused() then
        if not G.LegitFarmEnabled then stopFarmFacing() end
        return
    end
    if not aliveMob(Runtime.FarmTarget)
        or not G.SelectedMobs[mobDataId(Runtime.FarmTarget.Name)] then
        Runtime.FarmTarget = findFarmTarget()
    end
    local character, humanoid, root = characterData()
    local mobRoot = modelRoot(Runtime.FarmTarget)
    if not character or not humanoid or not mobRoot then
        stopFarmFacing()
        if Runtime.LastFarmStatusTarget ~= false then
            Runtime.LastFarmStatusTarget = false
            FarmStatus:Set({Title = "Aguardando monstro", Content = "Nenhum selecionado está vivo; tentando o próximo."})
        end
        return
    end
    faceFarmTarget(humanoid, root, mobRoot.Position)
    if os.clock() - Runtime.LastFarmMove < 0.08 then return end
    Runtime.LastFarmMove = os.clock()
    local behind = horizontalUnit(-mobRoot.CFrame.LookVector, Vector3.zAxis)
    local position = mobRoot.Position + behind * G.FarmDistance
    local flatTarget = Vector3.new(mobRoot.Position.X, position.Y, mobRoot.Position.Z)
    character:PivotTo(CFrame.lookAt(position, flatTarget))
    if Runtime.LastFarmStatusTarget ~= Runtime.FarmTarget then
        Runtime.LastFarmStatusTarget = Runtime.FarmTarget
        local id = mobDataId(Runtime.FarmTarget.Name)
        FarmStatus:Set({Title = "Auto Farm ativo", Content = string.format("Alvo: %s · Lv.%d",
            MonsterData[id] and (MonsterData[id].Name or id) or id,
            MonsterData[id] and (MonsterData[id].Level or 0) or 0)})
    end
end)

task.spawn(function()
    while Runtime.Running do
        task.wait(math.max(0.1, G.AttackDelay))
        if G.FarmEnabled and aliveMob(Runtime.FarmTarget) and not farmPaused() then
            pcall(function()
                SwordAttack:FireServer()
                UseSkill:FireServer(1)
                UseSkill:FireServer(2)
                UseSkill:FireServer(3)
            end)
        end
    end
end)

local function resetLegitAnimation()
    if Runtime.AttackTrack then pcall(function() Runtime.AttackTrack:Stop(0.05) end) end
    Runtime.AttackTrack = nil
    Runtime.AttackAnimator = nil
    Runtime.AttackTrackCache = {}
    Runtime.ComboIndex = 1
end

local function legitAnimations()
    local anims = ReplicatedStorage:FindFirstChild("Anims")
    if not anims then return {} end
    local folder = anims:FindFirstChild("SwordAnims")
    local result = {}
    if folder then
        for index = 1, 10 do
            local animation = folder:FindFirstChild("S" .. index)
            if animation and animation:IsA("Animation") then table.insert(result, animation) end
        end
    end
    if #result == 0 then
        for _, animation in ipairs(anims:GetDescendants()) do
            if animation:IsA("Animation") and animation.Name:match("^S%d+$") then
                table.insert(result, animation)
            end
        end
    end
    return result
end

local function playLegitAttackAnimation()
    local _, humanoid = characterData()
    if not humanoid then return end
    local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator", 1)
    if not animator then return end
    if Runtime.AttackAnimator ~= animator then
        resetLegitAnimation()
        Runtime.AttackAnimator = animator
    end
    local animations = legitAnimations()
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
    if Runtime.AttackTrack and Runtime.AttackTrack ~= track then
        pcall(function() Runtime.AttackTrack:Stop(0.05) end)
    end
    Runtime.AttackTrack = track
    pcall(function() track:Play(0.05, 1, 1) end)
end

local function findLegitTarget()
    local origin = Runtime.LegitOrigin
    if not origin then return nil end
    local nearest, nearestDistance
    for _, mob in ipairs(activeMobs()) do
        local id = mobDataId(mob.Name)
        if not Runtime.LegitTargetId or id == Runtime.LegitTargetId then
            local root = modelRoot(mob)
            local fromOrigin = (root.Position - origin).Magnitude
            if fromOrigin <= G.LegitFarmRadius then
                local distance = fromOrigin
                if not nearestDistance or distance < nearestDistance then
                    nearest, nearestDistance = mob, distance
                end
            end
        end
    end
    return nearest
end

connect(RunService.Heartbeat, function()
    if not G.LegitFarmEnabled then return end
    local character, humanoid, root = characterData()
    if not character then return end
    if not Runtime.LegitOrigin then Runtime.LegitOrigin = root.Position end

    if not aliveMob(Runtime.LegitTarget) then
        Runtime.LegitTarget = findLegitTarget()
        Runtime.LegitDetectedAt = Runtime.LegitTarget and os.clock() or 0
        if Runtime.LegitTarget and not Runtime.LegitTargetId then
            Runtime.LegitTargetId = mobDataId(Runtime.LegitTarget.Name)
        end
    end

    local targetRoot = modelRoot(Runtime.LegitTarget)
    if not targetRoot then
        stopFarmFacing()
        if os.clock() - Runtime.LegitLastStatus >= 0.5 then
            Runtime.LegitLastStatus = os.clock()
            LegitStatus:Set({Title = "Legit Farm", Content = Runtime.LegitTargetId and "Aguardando respawn." or "Nenhum mob no raio."})
        end
        return
    end

    faceFarmTarget(humanoid, root, targetRoot.Position)
    local distance = (root.Position - targetRoot.Position).Magnitude
    if G.LegitFarmMode == "Aproximar"
        and os.clock() - Runtime.LegitDetectedAt >= 1
        and os.clock() - Runtime.LegitLastMove >= 0.2 then
        Runtime.LegitLastMove = os.clock()
        local direction = Vector3.new(root.Position.X - targetRoot.Position.X, 0, root.Position.Z - targetRoot.Position.Z)
        if direction.Magnitude < 0.1 then direction = Vector3.zAxis end
        humanoid:MoveTo(targetRoot.Position + direction.Unit * math.min(5, G.LegitActionRange - 1))
    end
    if os.clock() - Runtime.LegitLastStatus >= 0.5 then
        Runtime.LegitLastStatus = os.clock()
        LegitStatus:Set({Title = "Legit Farm", Content = string.format("%s · %.0f studs", Runtime.LegitTarget.Name, distance)})
    end
end)

task.spawn(function()
    while Runtime.Running do
        task.wait(math.max(0.1, G.AttackDelay))
        if G.LegitFarmEnabled and aliveMob(Runtime.LegitTarget) and not farmPaused() then
            local _, _, root = characterData()
            local targetRoot = modelRoot(Runtime.LegitTarget)
            local reactionReady = G.LegitFarmMode ~= "Aproximar"
                or os.clock() - Runtime.LegitDetectedAt >= 1
            if reactionReady and root and targetRoot
                and (root.Position - targetRoot.Position).Magnitude <= G.LegitActionRange then
                playLegitAttackAnimation()
                pcall(function()
                    SwordAttack:FireServer()
                    UseSkill:FireServer(1)
                    UseSkill:FireServer(2)
                    UseSkill:FireServer(3)
                end)
            end
        end
    end
end)

--// Quests + Auto Potion -----------------------------------------------------

local function fireQuestPrompt(prompt)
    if not prompt then return end
    if type(fireproximityprompt) == "function" then
        pcall(fireproximityprompt, prompt, prompt.HoldDuration or 0)
        return
    end
    pcall(function()
        prompt:InputHoldBegin()
        task.wait((prompt.HoldDuration or 0) + 0.1)
        prompt:InputHoldEnd()
    end)
end

local function selectedQuestIds()
    local ids = {}
    for id, selected in pairs(G.SelectedQuests) do
        if selected and QuestData[id] then table.insert(ids, id) end
    end
    table.sort(ids, function(a, b)
        local levelA = tonumber(QuestData[a] and QuestData[a].MinLevel) or math.huge
        local levelB = tonumber(QuestData[b] and QuestData[b].MinLevel) or math.huge
        if levelA ~= levelB then return levelA < levelB end
        return a < b
    end)
    while #ids > 3 do table.remove(ids) end
    return ids
end

local QuestStatus
local function pickupSelectedQuests()
    if Runtime.QuestBusy or not G.QuestEnabled then return end
    local ids = selectedQuestIds()
    if #ids == 0 then
        if QuestStatus then QuestStatus:Set({Title = "Nenhuma quest selecionada", Content = "Selecione até três quests."}) end
        return
    end

    Runtime.QuestBusy = true
    stopFarmFacing()
    task.spawn(function()
        local picked = 0
        for _, questId in ipairs(ids) do
            if not Runtime.Running or not G.QuestEnabled then break end
            local folder = Workspace:FindFirstChild("QuestNPC")
            local npc = folder and folder:FindFirstChild(questId, true)
            local character = characterData()
            if npc and character then
                local npcPosition = npc:GetPivot().Position
                character:PivotTo(CFrame.lookAt(
                    npcPosition + Vector3.new(0, 2, 3),
                    npcPosition + Vector3.new(0, 2, 0)
                ))
                task.wait(math.max(0, G.QuestTeleportDelay))
                fireQuestPrompt(npc:FindFirstChildWhichIsA("ProximityPrompt", true))
                picked += 1
                task.wait(math.max(0, G.QuestInteractDelay))
            end
        end
        Runtime.QuestBusy = false
        Runtime.FarmTarget = nil
        if QuestStatus then
            QuestStatus:Set({
                Title = "Coleta de quests concluída",
                Content = string.format("%d de %d NPCs encontrados.", picked, #ids),
            })
        end
    end)
end

local potionIds = {
    "HealthPotion",
    "MediumHealthPotion",
    "LargeHealthPotion",
    "BigHealthPotion",
    "DefencePotion",
}

local function potionCount(id)
    local resources = LocalPlayer:FindFirstChild("OwnedResources")
    local value = resources and resources:FindFirstChild(id)
    return value and value:IsA("ValueBase") and math.max(0, tonumber(value.Value) or 0) or 0
end

local function choosePotion(missingHealth)
    local available = {}
    for order, id in ipairs(potionIds) do
        if G.SelectedPotions[id] and potionCount(id) > 0 then
            table.insert(available, {
                id = id,
                heal = tonumber(PotionData[id] and PotionData[id].Health) or 0,
                order = order,
            })
        end
    end
    table.sort(available, function(a, b)
        if a.heal ~= b.heal then return a.heal < b.heal end
        return a.order < b.order
    end)
    for _, potion in ipairs(available) do
        if potion.heal >= missingHealth then return potion.id end
    end
    return available[#available] and available[#available].id or nil
end

task.spawn(function()
    while Runtime.Running do
        task.wait(0.1)
        if G.AutoPotionEnabled and not Runtime.PotionBusy
            and os.clock() - Runtime.LastPotionUse >= math.max(1, G.PotionCooldown) then
            local _, humanoid = characterData()
            if humanoid and humanoid.MaxHealth > 0
                and humanoid.Health / humanoid.MaxHealth * 100 < G.PotionThreshold then
                local potionId = choosePotion(humanoid.MaxHealth - humanoid.Health)
                if potionId then
                    Runtime.PotionBusy = true
                    Runtime.LastPotionUse = os.clock()
                    pcall(function() UsePotion:FireServer(potionId) end)
                    Runtime.PotionBusy = false
                end
            end
        end
    end
end)

local UtilityTab = Window:CreateTab("Quests + Potion", nil)

QuestStatus = UtilityTab:CreateParagraph({
    Title = "Auto Quest",
    Content = "Selecione até três quests e faça uma coleta inicial.",
    Side = "Left", Card = "Quests",
})

local questLabels, QuestLabelToId, QuestIdToLabel = {}, {}, {}
for id, data in pairs(QuestData) do
    local label = string.format("%s · Lv.%d+", data.Title or data.MonsterId or id, tonumber(data.MinLevel) or 0)
    QuestLabelToId[label], QuestIdToLabel[id] = id, label
    table.insert(questLabels, label)
end
table.sort(questLabels, function(a, b)
    local dataA, dataB = QuestData[QuestLabelToId[a]] or {}, QuestData[QuestLabelToId[b]] or {}
    local levelA, levelB = tonumber(dataA.MinLevel) or math.huge, tonumber(dataB.MinLevel) or math.huge
    if levelA ~= levelB then return levelA < levelB end
    return a < b
end)

local initialQuestLabels = {}
for _, id in ipairs(selectedQuestIds()) do
    if QuestIdToLabel[id] then table.insert(initialQuestLabels, QuestIdToLabel[id]) end
end
local QuestDropdown
local updatingQuests = false
local lastQuestLabels = table.clone(initialQuestLabels)
QuestDropdown = UtilityTab:CreateDropdown({
    Name = "Quests (máximo 3)", Options = questLabels, CurrentOption = initialQuestLabels,
    MultipleOptions = true, Flag = "MacSelectedQuests", Side = "Left", Card = "Quests",
    Callback = function(labels)
        if updatingQuests then return end
        if #labels > 3 then
            updatingQuests = true
            QuestDropdown:Set(lastQuestLabels)
            updatingQuests = false
            return
        end
        lastQuestLabels = table.clone(labels)
        table.clear(G.SelectedQuests)
        for _, label in ipairs(labels) do
            local id = QuestLabelToId[label]
            if id then G.SelectedQuests[id] = true end
        end
    end,
})
UtilityTab:CreateToggle({
    Name = "Permitir coleta de quests", CurrentValue = G.QuestEnabled,
    Flag = "MacQuestEnabled", Side = "Left", Card = "Quests",
    Callback = function(value) G.QuestEnabled = value end,
})
UtilityTab:CreateToggle({
    Name = "Repetir quest automaticamente", CurrentValue = G.NativeAutoQuest,
    Flag = "MacNativeAutoQuest", Side = "Left", Card = "Quests",
    Callback = function(value)
        G.NativeAutoQuest = value
        pcall(function() SaveSettings:FireServer("AutoQuestRepeat", value) end)
    end,
})
UtilityTab:CreateSlider({
    Name = "Espera após teleportar", Range = {0, 3}, Increment = 0.05, Suffix = "s",
    CurrentValue = G.QuestTeleportDelay, Flag = "MacQuestTeleportDelay", Side = "Left", Card = "Quests",
    Callback = function(value) G.QuestTeleportDelay = value end,
})
UtilityTab:CreateSlider({
    Name = "Espera entre quests", Range = {0, 3}, Increment = 0.05, Suffix = "s",
    CurrentValue = G.QuestInteractDelay, Flag = "MacQuestInteractDelay", Side = "Left", Card = "Quests",
    Callback = function(value) G.QuestInteractDelay = value end,
})
UtilityTab:CreateButton({
    Name = "Teleportar e pegar quests", Side = "Left", Card = "Quests",
    Callback = pickupSelectedQuests,
})

local PotionStatus = UtilityTab:CreateParagraph({
    Title = "Auto Potion inteligente",
    Content = "Usa uma poção por ciclo e escolhe a menor capaz de recuperar a vida perdida.",
    Side = "Right", Card = "Potions",
})
local potionLabels, PotionLabelToId, PotionIdToLabel = {}, {}, {}
for _, id in ipairs(potionIds) do
    local data = PotionData[id] or {}
    local label = data.Health and string.format("%s (+%d HP)", data.Name or id, data.Health) or (data.Name or id)
    PotionLabelToId[label], PotionIdToLabel[id] = id, label
    table.insert(potionLabels, label)
end
local initialPotionLabels = {}
for _, id in ipairs(potionIds) do
    if G.SelectedPotions[id] and PotionIdToLabel[id] then table.insert(initialPotionLabels, PotionIdToLabel[id]) end
end
UtilityTab:CreateToggle({
    Name = "Auto Potion", CurrentValue = G.AutoPotionEnabled,
    Flag = "MacAutoPotion", Side = "Right", Card = "Potions",
    Callback = function(value) G.AutoPotionEnabled = value end,
})
UtilityTab:CreateDropdown({
    Name = "Poções disponíveis", Options = potionLabels, CurrentOption = initialPotionLabels,
    MultipleOptions = true, Flag = "MacSelectedPotions", Side = "Right", Card = "Potions",
    Callback = function(labels)
        table.clear(G.SelectedPotions)
        for _, label in ipairs(labels) do
            local id = PotionLabelToId[label]
            if id then G.SelectedPotions[id] = true end
        end
    end,
})
UtilityTab:CreateSlider({
    Name = "Usar abaixo de", Range = {1, 100}, Increment = 1, Suffix = "% HP",
    CurrentValue = G.PotionThreshold, Flag = "MacPotionThreshold", Side = "Right", Card = "Potions",
    Callback = function(value) G.PotionThreshold = value end,
})
UtilityTab:CreateSlider({
    Name = "Intervalo", Range = {1, 10}, Increment = 0.1, Suffix = "s",
    CurrentValue = math.max(1, G.PotionCooldown), Flag = "MacPotionCooldown", Side = "Right", Card = "Potions",
    Callback = function(value) G.PotionCooldown = math.max(1, value) end,
})

task.spawn(function()
    while Runtime.Running do
        task.wait(1)
        local rows = {}
        for _, id in ipairs(potionIds) do
            if G.SelectedPotions[id] then
                table.insert(rows, string.format("%s: %d", PotionData[id] and PotionData[id].Name or id, potionCount(id)))
            end
        end
        pcall(function()
            PotionStatus:Set({
                Title = "Auto Potion inteligente",
                Content = #rows > 0 and table.concat(rows, " · ") or "Nenhuma poção selecionada.",
            })
        end)
    end
end)

local Tab = Window:CreateTab("Auto Buy", "shopping-bag")

local Status = Tab:CreateParagraph({
    Title = "Aguardando estoque",
    Content = "A primeira atualização não realiza compras.",
})

local ItemDropdown
ItemDropdown = Tab:CreateDropdown({
    Name = "Itens",
    Options = {"Carregando catálogo..."},
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "SimpleMerchantItems",
    Callback = function(options)
        if Runtime.UpdatingDropdown then return end
        table.clear(G.SelectedItems)
        for _, label in ipairs(options) do
            local id = Runtime.LabelToId[label]
            if id then G.SelectedItems[id] = true end
        end
        if G.Enabled then Runtime.BuyRequested = true end
    end,
})

local StockStatus = Tab:CreateParagraph({
    Title = "Estoque atual",
    Content = "Aguardando resposta do servidor...",
})

Tab:CreateToggle({
    Name = "Auto Buy selecionados",
    CurrentValue = G.Enabled,
    Flag = "SimpleMerchantEnabled",
    Callback = function(value)
        G.Enabled = value
        if value then
            Runtime.BuyRequested = true
            MerchantRequest:FireServer()
        end
    end,
})

local BuyModeDropdown = Tab:CreateDropdown({
    Name = "Modo de compra",
    Options = {"Quantidade", "Todos"},
    CurrentOption = {G.BuyMode},
    MultipleOptions = false,
    Flag = "SimpleMerchantMode",
    Callback = function(options)
        G.BuyMode = options[1] or "Quantidade"
    end,
})

local QuantityInput
QuantityInput = Tab:CreateInput({
    Name = "Quantidade por item",
    CurrentValue = tostring(G.Quantity),
    PlaceholderText = "Exemplo: 10",
    RemoveTextAfterFocusLost = false,
    Flag = "SimpleMerchantQuantity",
    Callback = function(text)
        local value = tonumber(text)
        if value then
            G.Quantity = math.clamp(math.floor(value), 1, 10000)
            if tostring(G.Quantity) ~= tostring(text) then
                QuantityInput:Set(tostring(G.Quantity))
            end
        end
    end,
})

local function selectedLabels()
    local result = {}
    for id, enabled in pairs(G.SelectedItems) do
        local label = enabled and Runtime.IdToLabel[id]
        if label then table.insert(result, label) end
    end
    table.sort(result)
    return result
end

local function buildCatalogDropdown()
    local ids = {}
    for id in pairs(Runtime.Catalog) do table.insert(ids, id) end
    table.sort(ids)

    table.clear(Runtime.LabelToId)
    table.clear(Runtime.IdToLabel)
    local options = {}

    for _, id in ipairs(ids) do
        local catalogItem = Runtime.Catalog[id]
        local price = catalogItem and catalogItem.price or 0
        local label = string.format("%s | %d", id, price)
        Runtime.LabelToId[label] = id
        Runtime.IdToLabel[id] = label
        table.insert(options, label)
    end

    if #options == 0 then options = {"Nenhum item identificado"} end
    Runtime.UpdatingDropdown = true
    ItemDropdown:Refresh(options)
    ItemDropdown:Set(selectedLabels())
    Runtime.UpdatingDropdown = false
end

local function currentRemaining()
    if Runtime.Deadline then
        return math.max(0, math.ceil(Runtime.Deadline - os.clock()))
    end
    return math.max(0, Runtime.Remaining)
end

local function updateStatus()
    Runtime.Remaining = currentRemaining()

    local available, selected = 0, 0
    for _, item in pairs(Runtime.Stock) do
        if item.stock > 0 then available += 1 end
    end
    for _, enabled in pairs(G.SelectedItems) do
        if enabled then selected += 1 end
    end
    local minutes = math.floor(Runtime.Remaining / 60)
    local seconds = Runtime.Remaining % 60
    pcall(function()
        Status:Set({
            Title = string.format("Próxima reposição: %02d:%02d", minutes, seconds),
            Content = string.format("%d disponíveis · %d selecionados\n%s",
                available, selected, Runtime.LastBuyStatus),
        })
    end)
end


local function stockSignature(stock)
    local parts = {}
    for id, item in pairs(stock) do
        table.insert(parts, string.format("%s=%d", id, item.stock))
    end
    table.sort(parts)
    return table.concat(parts, ";")
end

local function updateStockDisplay()
    local rows = {}
    for id, item in pairs(Runtime.Stock) do
        if item.stock > 0 then
            table.insert(rows, string.format("%s — x%d", id, item.stock))
        end
    end
    table.sort(rows)
    pcall(function()
        StockStatus:Set({
            Title = "Estoque atual",
            Content = #rows > 0 and table.concat(rows, "\n") or "Nenhum item disponível.",
        })
    end)
end

--// Crafting -----------------------------------------------------------------

local CraftTab = Window:CreateTab("Crafting", "hammer")

CraftTab:CreateParagraph({
    Title = "Receita",
    Content = "Escolha um item.",
    Side = "Left",
    Card = "CraftSelection",
})

local CraftSummary = CraftTab:CreateParagraph({
    Title = "Craft",
    Content = "—",
    Side = "Left",
    Card = "CraftOverview",
})

local CraftProgress = CraftTab:CreateParagraph({
    Title = "Materiais",
    Content = "—",
    Side = "Right",
    Card = "CraftMaterials",
})

local CraftSources = CraftTab:CreateParagraph({
    Title = "Fontes",
    Content = "—",
    Side = "Right",
    Card = "CraftSources",
})

local function friendlyName(text)
    return tostring(text)
        :gsub("(%l)(%u)", "%1 %2")
        :gsub("(%a)(%d)", "%1 %2")
end

local DropSources = {}
for monsterId, monster in pairs(MonsterData) do
    for _, drop in ipairs(monster.Drops or {}) do
        if drop.Type == "Resource" and drop.Id then
            local id = tostring(drop.Id)
            DropSources[id] = DropSources[id] or {}
            local spawn = MonsterSpawnData[monsterId] or {}
            table.insert(DropSources[id], {
                id = monsterId,
                name = monster.Name or monsterId,
                level = tonumber(monster.Level) or 0,
                chance = tonumber(drop.Chance) or 0,
                amount = tonumber(drop.Amount) or 1,
                respawn = tonumber(spawn.respawnTime),
                boss = spawn.isBoss == true,
            })
        end
    end
end
for _, sources in pairs(DropSources) do
    table.sort(sources, function(a, b)
        local expectedA = a.chance * a.amount
        local expectedB = b.chance * b.amount
        if expectedA ~= expectedB then return expectedA > expectedB end
        return a.level > b.level
    end)
end

local function dropSourceText(resourceId)
    local sources = DropSources[resourceId]
    if not sources or #sources == 0 then return nil end
    local parts = {}
    for index, source in ipairs(sources) do
        if index > 3 then break end
        local respawn = source.respawn and source.respawn > 0
            and string.format(" · respawn %ds", source.respawn) or ""
        table.insert(parts, string.format("      ↳ %s [Lv.%d]%s · %.0f%% x%d%s",
            friendlyName(source.name), source.level, source.boss and " · Boss" or "",
            source.chance * 100, source.amount, respawn))
    end
    return table.concat(parts, "\n")
end

local craftOptions = {"Nenhum"}
local CraftLabelToId = {Nenhum = "Nenhum"}
local CraftIdToLabel = {Nenhum = "Nenhum"}
for craftId, recipe in pairs(CraftingData) do
    local label = string.format("%s  ·  %s", friendlyName(craftId), tostring(recipe.Type or "Craft"))
    CraftLabelToId[label] = craftId
    CraftIdToLabel[craftId] = label
    table.insert(craftOptions, label)
end
table.sort(craftOptions, function(a, b)
    if a == b then return false end
    if a == "Nenhum" then return true end
    if b == "Nenhum" then return false end
    return a < b
end)

local function ownedResourceAmount(id)
    local resources = LocalPlayer:FindFirstChild("OwnedResources")
    local value = resources and resources:FindFirstChild(id)
    return value and value:IsA("ValueBase") and tonumber(value.Value) or 0
end

local function currentGold()
    local privateStats = LocalPlayer:FindFirstChild("PrivateStats")
    local value = privateStats and privateStats:FindFirstChild("Gold")
    return value and value:IsA("ValueBase") and tonumber(value.Value) or 0
end

local function applyCraftToAutoBuy(craftId)
    local recipe = CraftingData[craftId]
    if not recipe then return end

    table.clear(G.SelectedItems)
    for _, material in ipairs(recipe.Materials or {}) do
        local id = tostring(material.Id)
        -- Só adiciona ao Auto Buy o que realmente pode aparecer no Merchant.
        if Runtime.Catalog[id] then
            G.SelectedItems[id] = true
        end
    end

    G.BuyMode = "Todos"
    Runtime.UpdatingDropdown = true
    pcall(function()
        ItemDropdown:Set(selectedLabels())
        BuyModeDropdown:Set({"Todos"})
    end)
    Runtime.UpdatingDropdown = false
end

local function applyCraftToFarm(craftId)
    local recipe = CraftingData[craftId]
    if not recipe then return end

    local wantedMobs, ids = {}, {}
    for _, material in ipairs(recipe.Materials or {}) do
        local resourceId = tostring(material.Id)
        local needed = tonumber(material.Amount) or 0
        if ownedResourceAmount(resourceId) < needed then
            -- DropSources já está ordenado por rendimento esperado. Selecionar
            -- apenas a melhor fonte evita marcar todas as alternativas do item.
            local source = (DropSources[resourceId] or {})[1]
            if source and MonsterData[source.id] and not wantedMobs[source.id] then
                wantedMobs[source.id] = true
                table.insert(ids, source.id)
            end
        end
    end

    local signature = table.concat(ids, "|")
    if Runtime.CraftFarmSignature == signature then return end
    Runtime.CraftFarmSignature = signature
    Runtime.FarmPriority = ids

    table.clear(G.SelectedMobs)
    local labels = {}
    for _, id in ipairs(ids) do
        G.SelectedMobs[id] = true
        if MobIdToLabel[id] then table.insert(labels, MobIdToLabel[id]) end
    end
    Runtime.FarmTarget = nil
    Runtime.UpdatingMobDropdown = true
    pcall(function() MobDropdown:Set(labels) end)
    Runtime.UpdatingMobDropdown = false
end

local function applyCraftAutomation(craftId)
    applyCraftToAutoBuy(craftId)
    applyCraftToFarm(craftId)
end


local function renderCraftProgress()
    local craftId = G.SelectedCraft
    local recipe = CraftingData[craftId]
    if not recipe then
        pcall(function()
            CraftSummary:Set({Title = "Craft", Content = "Selecione uma receita."})
            CraftProgress:Set({Title = "Materiais", Content = "—"})
            CraftSources:Set({Title = "Fontes", Content = "—"})
        end)
        return
    end

    local lines = {}
    local sourceLines = {}
    local complete = true
    local completedRequirements = 0
    local totalRequirements = 1 + #(recipe.Materials or {})
    local progressSum = 0
    local goldHave = currentGold()
    local goldNeed = tonumber(recipe.GoldCost) or 0
    local goldMissing = math.max(0, goldNeed - goldHave)
    if goldMissing > 0 then complete = false end
    if goldMissing == 0 then completedRequirements += 1 end
    progressSum += goldNeed > 0 and math.clamp(goldHave / goldNeed, 0, 1) or 1
    table.insert(lines, string.format("%s Gold  %d/%d",
        goldMissing == 0 and "✓" or "○", goldHave, goldNeed))

    local materials = table.clone(recipe.Materials or {})
    table.sort(materials, function(a, b) return tostring(a.Id) < tostring(b.Id) end)
    for _, material in ipairs(materials) do
        local id = tostring(material.Id)
        local needed = tonumber(material.Amount) or 0
        local have = ownedResourceAmount(id)
        local missing = math.max(0, needed - have)
        if missing > 0 then complete = false end
        if missing == 0 then completedRequirements += 1 end
        local ratio = needed > 0 and math.clamp(have / needed, 0, 1) or 1
        progressSum += ratio
        table.insert(lines, string.format("%s %s  %d/%d",
            missing == 0 and "✓" or "○", friendlyName(id), have, needed))

        if missing > 0 then
            local acquisition = {}
            if Runtime.Catalog[id] then table.insert(acquisition, "Merchant") end
            local source = (DropSources[id] or {})[1]
            if source then
                table.insert(acquisition, string.format("%s Lv.%d · %.0f%% ×%d",
                    friendlyName(source.name), source.level, source.chance * 100, source.amount))
            elseif not Runtime.Catalog[id] then
                table.insert(acquisition, "Fonte desconhecida")
            end
            table.insert(sourceLines, string.format("%s → %s",
                friendlyName(id), table.concat(acquisition, " + ")))
        end
    end

    local overall = totalRequirements > 0 and math.floor(progressSum / totalRequirements * 100 + 0.5) or 100

    pcall(function()
        CraftSummary:Set({
            Title = friendlyName(craftId),
            Content = string.format("%s · %d/%d · %d%%",
                complete and "Pronto" or tostring(recipe.Type or "Craft"),
                completedRequirements, totalRequirements, overall),
        })
        CraftProgress:Set({
            Title = "Materiais",
            Content = table.concat(lines, "\n"),
        })
        CraftSources:Set({
            Title = "Fontes do que falta",
            Content = #sourceLines > 0 and table.concat(sourceLines, "\n\n")
                or "Completo.",
        })
    end)
end

CraftTab:CreateDropdown({
    Name = "Craft selecionado",
    Options = craftOptions,
    CurrentOption = {CraftingData[G.SelectedCraft] and CraftIdToLabel[G.SelectedCraft] or "Nenhum"},
    MultipleOptions = false,
    Flag = "MerchantSelectedCraft",
    Side = "Left",
    Card = "CraftSelection",
    Callback = function(options)
        local craftId = CraftLabelToId[options[1]] or "Nenhum"
        G.SelectedCraft = craftId
        if CraftingData[craftId] then
            applyCraftAutomation(craftId)
        end
        renderCraftProgress()
    end,
})

CraftTab:CreateButton({
    Name = "Sincronizar Merchant + Auto Farm",
    Side = "Left",
    Card = "CraftSelection",
    Callback = function()
        if CraftingData[G.SelectedCraft] then
            applyCraftAutomation(G.SelectedCraft)
            renderCraftProgress()
        end
    end,
})

local function buySelectedStock()
    if Runtime.Buying or not G.Enabled then return end
    Runtime.Buying = true

    local ids = {}
    for id, enabled in pairs(G.SelectedItems) do
        local item = Runtime.Stock[id]
        if enabled and item and item.stock > 0 then table.insert(ids, id) end
    end
    table.sort(ids)

    if #ids == 0 then
        Runtime.LastBuyStatus = "Nenhum item selecionado está disponível no estoque."
        Runtime.Buying = false
        updateStatus()
        return
    end

    local requestsSent = 0
    Runtime.LastBuyStatus = "Comprando itens selecionados..."
    updateStatus()

    for _, id in ipairs(ids) do
        if not Runtime.Running or not G.Enabled then break end
        local item = Runtime.Stock[id]
        local amount = G.BuyMode == "Todos"
            and item.stock
            or math.min(G.Quantity, item.stock)

        for _ = 1, amount do
            if not Runtime.Running or not G.Enabled then break end
            MerchantBuy:FireServer(id)
            requestsSent += 1
            -- Apenas cede um ciclo para não congelar o cliente; não existe
            -- configuração de intervalo na interface.
            task.wait()
        end
    end

    Runtime.Buying = false
    Runtime.LastBuyStatus = string.format("Última execução: %d solicitação(ões) enviada(s).", requestsSent)
    updateStatus()
end

local function scheduleRestockPurchase()
    Runtime.RestockGeneration += 1
    local generation = Runtime.RestockGeneration
    task.delay(5, function()
        if not Runtime.Running or not G.Enabled
            or generation ~= Runtime.RestockGeneration then
            return
        end
        buySelectedStock()
    end)
end

connect(MerchantStockUpdate.OnClientEvent, function(payload, secondsRemaining)
    local newRemaining = math.max(0, math.floor(tonumber(secondsRemaining) or 0))
    local previousRemaining = currentRemaining()
    local isRestock = Runtime.ReceivedInitialStock
        and newRemaining > previousRemaining + 30

    local newStock = normalizeStock(payload)
    local newSignature = stockSignature(newStock)

    -- Durante a reposição o servidor pode emitir momentaneamente uma tabela vazia.
    -- Preserve o último snapshot válido para a interface não desaparecer.
    if next(newStock) ~= nil then
        Runtime.Stock = newStock
        if newSignature ~= Runtime.LastStockSignature then
            Runtime.LastStockSignature = newSignature
            updateStockDisplay()
        end
    end

    if tonumber(secondsRemaining) then
        Runtime.Remaining = newRemaining
        Runtime.Deadline = os.clock() + newRemaining
        if newRemaining > 0 then
            Runtime.RequestedAtZero = false
        end
    end
    updateStatus()

    if not Runtime.ReceivedInitialStock then
        Runtime.ReceivedInitialStock = true
    elseif isRestock then
        pcall(function()
            Status:Set({
                Title = "Nova reposição detectada",
                Content = "Compra dos selecionados em 5 segundos.",
            })
        end)
        scheduleRestockPurchase()
    end
end)

task.spawn(function()
    while Runtime.Running do
        task.wait(1)
        updateStatus()
        if Runtime.BuyRequested and next(Runtime.Stock) ~= nil then
            Runtime.BuyRequested = false
            task.spawn(buySelectedStock)
        end
        -- O jogo pode não transmitir a reposição até o cliente solicitá-la.
        -- Uma única consulta ao chegar em zero obtém o novo estoque e contador.
        if Runtime.Remaining <= 0 and Runtime.ReceivedInitialStock
            and not Runtime.RequestedAtZero then
            Runtime.RequestedAtZero = true
            MerchantRequest:FireServer()
        end
    end
end)

--// Comparador de stats -------------------------------------------------------

local function restoreNoClip()
    for part, original in pairs(Runtime.NoClipParts) do
        if part and part.Parent then pcall(function() part.CanCollide = original end) end
        Runtime.NoClipParts[part] = nil
    end
end

connect(RunService.Stepped, function()
    if not (G.FarmEnabled and G.NoClip) then
        if next(Runtime.NoClipParts) then restoreNoClip() end
        return
    end
    local character = LocalPlayer.Character
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            if Runtime.NoClipParts[part] == nil then Runtime.NoClipParts[part] = true end
            part.CanCollide = false
        end
    end
end)

task.spawn(function()
    while Runtime.Running do
        task.wait(0.5)
        local _, _, root = characterData()
        if root then
            if root.Position.Y > -50 then Runtime.LastSafeCFrame = root.CFrame end
            if G.AntiVoid and root.Position.Y < -100 and Runtime.LastSafeCFrame then
                root.CFrame = Runtime.LastSafeCFrame + Vector3.new(0, 5, 0)
            end
        end
    end
end)

-- Reservado para uma estratégia futura que não interfira nas ações do jogador.
connect(LocalPlayer.Idled, function()
    if G.AntiAFK then
		VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.zero)
    end
end)

local StatsTab = Window:CreateTab("Player Stats", "user")

local StatsRuntime = {
    Baseline = {},
    StartedAt = os.time(),
}

local StatsSummary = StatsTab:CreateParagraph({
    Title = "Resumo da sessão",
    Content = "Aguardando os dados replicados do jogador...",
    Side = "Left",
    Card = "SessionSummary",
})

local StatsResources = StatsTab:CreateParagraph({
    Title = "Inventário e ganhos",
    Content = "Aguardando recursos...",
    Side = "Left",
    Card = "InventoryGains",
})

local StatsCombat = StatsTab:CreateParagraph({
    Title = "Atributos de combate",
    Content = "Aguardando atributos...",
    Side = "Right",
    Card = "CombatStats",
})

local AttributeStatus = StatsTab:CreateParagraph({
    Title = "Auto atributos",
    Content = "Escolha um atributo e ative a distribuição automática.",
    Side = "Right",
    Card = "AutoAttributes",
})

local attributeOptions = {
    "Health", "Def", "Damage", "CritChance", "CritMultiplier", "Evasion",
}

StatsTab:CreateDropdown({
    Name = "Atributo para receber os pontos",
    Options = attributeOptions,
    CurrentOption = {G.AttributeTarget},
    MultipleOptions = false,
    Flag = "MerchantStatsAttributeTarget",
    Side = "Right",
    Card = "AutoAttributes",
    Callback = function(options)
        G.AttributeTarget = options[1] or "Damage"
        Runtime.CappedAttributes[G.AttributeTarget] = nil
    end,
})

StatsTab:CreateToggle({
    Name = "Auto distribuir pontos",
    CurrentValue = G.AutoAttribute,
    Flag = "MerchantStatsAutoAttribute",
    Side = "Right",
    Card = "AutoAttributes",
    Callback = function(value)
        G.AutoAttribute = value
    end,
})

StatsTab:CreateParagraph({
    Title = "Opções do jogador",
    Content = "Recursos auxiliares do farm.",
    Side = "Right",
    Card = "PlayerOptions",
})

StatsTab:CreateToggle({
    Name = "NoClip durante o farm", CurrentValue = G.NoClip,
    Flag = "MacPlayerNoClip", Side = "Right", Card = "PlayerOptions",
    Callback = function(value)
        G.NoClip = value
        if not value then restoreNoClip() end
    end,
})

StatsTab:CreateToggle({
    Name = "Anti-Void", CurrentValue = G.AntiVoid,
    Flag = "MacPlayerAntiVoid", Side = "Right", Card = "PlayerOptions",
    Callback = function(value) G.AntiVoid = value end,
})

StatsTab:CreateToggle({
    Name = "Anti-AFK (reservado)", CurrentValue = G.AntiAFK,
    Flag = "MacPlayerAntiAFK", Side = "Right", Card = "PlayerOptions",
    Callback = function(value) G.AntiAFK = value end,
})

local keybindOptions = {"F12", "RightShift", "RightControl", "LeftAlt"}
StatsTab:CreateDropdown({
    Name = "Tecla da interface", Options = keybindOptions,
    CurrentOption = {table.find(keybindOptions, G.MenuKeybind) and G.MenuKeybind or "F12"},
    MultipleOptions = false, Flag = "MacMenuKeybind", Side = "Right", Card = "PlayerOptions",
    Callback = function(options)
        local name = options[1] or "F12"
        local key = Enum.KeyCode[name]
        if key then
            G.MenuKeybind = name
            MacWindow:SetKeybind(key)
        end
    end,
})

StatsTab:CreateButton({
    Name = "Salvar opções agora", Side = "Right", Card = "PlayerOptions",
    Callback = function() pcall(function() MacLib:SaveConfig("Settings") end) end,
})

local function readNumber(parent, name)
    local object = parent and parent:FindFirstChild(name)
    return object and object:IsA("ValueBase") and tonumber(object.Value) or nil
end

local availableAttributePoints

local function statsSnapshot()
    local result = {}
    local privateStats = LocalPlayer:FindFirstChild("PrivateStats")
    local publicStats = LocalPlayer:FindFirstChild("PublicStats")
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    local levelStats = LocalPlayer:FindFirstChild("LevelStats")
    local resources = LocalPlayer:FindFirstChild("OwnedResources")

    result.Level = readNumber(publicStats, "Level") or readNumber(leaderstats, "Level")
    result.Exp = readNumber(levelStats, "Exp")
    result.Gold = readNumber(privateStats, "Gold")
    result.Gem = readNumber(privateStats, "Gem")
    result.MonsterKills = readNumber(privateStats, "MonsterKills")
    result.GuildPoints = readNumber(privateStats, "GuildPoints")
    result.AttributePoints = availableAttributePoints and availableAttributePoints() or nil

    for _, name in ipairs({
        "AttrDamage", "AttrDef", "AttrHealth", "AttrEvasion",
        "AttrCritChance", "AttrCritMultiplier", "PotionHealth", "PotionDef",
    }) do
        result[name] = tonumber(LocalPlayer:GetAttribute(name))
    end

    if resources then
        for _, object in ipairs(resources:GetChildren()) do
            if object:IsA("ValueBase") and tonumber(object.Value) ~= nil then
                result["Resource:" .. object.Name] = tonumber(object.Value)
            end
        end
    end
    return result
end

availableAttributePoints = function()
    -- Prefere um ValueBase, caso o jogo passe a replicar o saldo diretamente.
    for _, object in ipairs(LocalPlayer:GetDescendants()) do
        if object:IsA("ValueBase")
            and (object.Name == "AttributePoints" or object.Name == "StatPoints") then
            return tonumber(object.Value)
        end
    end

    local zenUI = LocalPlayer:FindFirstChild("PlayerGui")
    zenUI = zenUI and zenUI:FindFirstChild("ZenUI")
    local frames = zenUI and zenUI:FindFirstChild("Frames")
    local profile = frames and frames:FindFirstChild("Profile")
    local label = profile and profile:FindFirstChild("PointsValue")
    if label and label:IsA("TextLabel") then
        local numberText = label.Text:match("(%d[%d,%.]*)")
        return numberText and tonumber((numberText:gsub("[,%.]", ""))) or nil
    end
    return nil
end

local pointRules = {
    Health = {attribute = "AttrHealth", perPoint = 15},
    Def = {attribute = "AttrDef", perPoint = 2.5},
    Damage = {attribute = "AttrDamage", perPoint = 3.5},
    CritChance = {attribute = "AttrCritChance", perPoint = 0.005, cap = 20},
    CritMultiplier = {attribute = "AttrCritMultiplier", perPoint = 0.05, cap = 10},
    Evasion = {attribute = "AttrEvasion", perPoint = 1, cap = 10},
}

local function allocatedPoints(attributeName)
    local rule = pointRules[attributeName]
    local bonus = rule and tonumber(LocalPlayer:GetAttribute(rule.attribute))
    if not rule or bonus == nil then return nil end
    return math.floor((bonus / rule.perPoint) + 0.5)
end

local function setAttributeStatus(titleText, contentText)
    pcall(function()
        AttributeStatus:Set({Title = titleText, Content = contentText})
    end)
end

local function tryAllocateAttribute()
    if Runtime.AllocatingAttribute or not G.AutoAttribute then return end

    local target = G.AttributeTarget
    local rule = pointRules[target]
    local availableBefore = availableAttributePoints()
    local allocated = allocatedPoints(target)
    if not rule or availableBefore == nil then
        setAttributeStatus("Auto atributos aguardando", "Não foi possível ler os pontos disponíveis.")
        return
    end
    if availableBefore <= 0 then
        setAttributeStatus("Auto atributos ativo", "Sem pontos disponíveis · alvo: " .. target)
        return
    end
    if Runtime.CappedAttributes[target] or (rule.cap and allocated and allocated >= rule.cap) then
        Runtime.CappedAttributes[target] = true
        setAttributeStatus("Atributo no máximo", target .. " não receberá novas tentativas.")
        return
    end

    Runtime.AllocatingAttribute = true
    AllocateAttribute:FireServer(target, 1)

    task.delay(0.8, function()
        if not Runtime.Running then return end
        local availableAfter = availableAttributePoints()
        if availableAfter ~= nil and availableAfter < availableBefore then
            Runtime.CappedAttributes[target] = nil
            setAttributeStatus("Ponto distribuído", string.format(
                "%s · disponíveis: %d", target, availableAfter))
        elseif G.AttributeTarget == target then
            Runtime.CappedAttributes[target] = true
            setAttributeStatus("Sem alteração", target .. " foi tratado como máximo ou recusado pelo servidor.")
        end
        Runtime.AllocatingAttribute = false
    end)
end

local function fmt(value)
    if value == nil then return "—" end
    if value == math.floor(value) then
        local sign = value < 0 and "-" or ""
        local digits = tostring(math.abs(math.floor(value)))
        digits = digits:reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
        return sign .. digits
    end
    return string.format("%.3f", value):gsub("0+$", ""):gsub("%.$", "")
end

local function gainText(current, initial)
    if current == nil then return "—" end
    local delta = current - (initial or current)
    return (delta >= 0 and "+" or "") .. fmt(delta)
end

local function deltaValue(current, initial)
    if current == nil then return 0 end
    return current - (initial or current)
end

local function hourlyText(delta, elapsed)
    if elapsed < 5 or delta == 0 then return nil end
    return fmt(delta / elapsed * 3600) .. "/h"
end

local function experienceGoal()
    local guiRoot = LocalPlayer:FindFirstChild("PlayerGui")
    local zen = guiRoot and guiRoot:FindFirstChild("ZenUI")
    local frames = zen and zen:FindFirstChild("Frames")
    local levelFrame = frames and frames:FindFirstChild("Level")
    local label = levelFrame and levelFrame:FindFirstChild("Level")
    if label and label:IsA("TextLabel") then
        local currentText, goalText = label.Text:match("%(([%d,%.]+)%s*/%s*([%d,%.]+)%)")
        if currentText and goalText then
            return tonumber((currentText:gsub("[,%.]", ""))),
                tonumber((goalText:gsub("[,%.]", "")))
        end
    end
    return nil, nil
end

local function renderStats()
    local current = statsSnapshot()
    local elapsed = math.max(0, os.time() - StatsRuntime.StartedAt)
    local timeText = string.format("%02d:%02d:%02d", math.floor(elapsed / 3600), math.floor(elapsed % 3600 / 60), elapsed % 60)
    local expNow, expGoal = experienceGoal()
    expNow = expNow or current.Exp
    local expPercent = expGoal and expGoal > 0 and math.clamp(expNow / expGoal * 100, 0, 100) or nil
    local filled = expPercent and math.clamp(math.floor(expPercent / 10 + 0.5), 0, 10) or 0
    local expBar = string.rep("■", filled) .. string.rep("□", 10 - filled)

    local summaryLines = {
        "Tempo acompanhado: " .. timeText,
        "",
        string.format("Nível: %s  (%s)", fmt(current.Level), gainText(current.Level, StatsRuntime.Baseline.Level)),
    }
    if expGoal then
        table.insert(summaryLines, string.format("EXP: %s / %s", fmt(expNow), fmt(expGoal)))
        table.insert(summaryLines, string.format("%s  %d%%", expBar, math.floor(expPercent + 0.5)))
    else
        table.insert(summaryLines, string.format("EXP: %s  (%s)", fmt(current.Exp), gainText(current.Exp, StatsRuntime.Baseline.Exp)))
    end

    for _, entry in ipairs({
        {"Gold", "Gold"}, {"Gem", "Gemas"}, {"MonsterKills", "Monstros eliminados"},
        {"GuildPoints", "Guild Points"}, {"AttributePoints", "Pontos disponíveis"},
    }) do
        local key, label = entry[1], entry[2]
        local delta = deltaValue(current[key], StatsRuntime.Baseline[key])
        local rate = hourlyText(delta, elapsed)
        table.insert(summaryLines, string.format("%s: %s  (%s)%s", label, fmt(current[key]),
            gainText(current[key], StatsRuntime.Baseline[key]), rate and ("  ·  " .. rate) or ""))
    end

    local combatLines = {}
    for _, entry in ipairs({
        {"Damage", "Dano", "AttrDamage", ""},
        {"Def", "Defesa", "AttrDef", ""},
        {"Health", "Vida", "AttrHealth", ""},
        {"Evasion", "Evasão", "AttrEvasion", ""},
        {"CritChance", "Chance crítica", "AttrCritChance", "%"},
        {"CritMultiplier", "Multiplicador crítico", "AttrCritMultiplier", "x"},
    }) do
        local ruleName, label, key, suffix = entry[1], entry[2], entry[3], entry[4]
        local value = current[key]
        local points = allocatedPoints(ruleName)
        local cap = pointRules[ruleName] and pointRules[ruleName].cap
        local displayValue = value
        if ruleName == "CritChance" and value then displayValue = value * 100 end
        local capText = cap and string.format(" / %d máx.", cap) or ""
        table.insert(combatLines, string.format("%s\n    Bônus: %s%s  ·  Pontos: %s%s",
            label, fmt(displayValue), suffix, fmt(points), capText))
    end

    pcall(function()
        StatsSummary:Set({Title = "Resumo da sessão", Content = table.concat(summaryLines, "\n")})
        StatsCombat:Set({Title = "Atributos de combate", Content = table.concat(combatLines, "\n\n")})
    end)

    local resourceLines = {}
    for key, value in pairs(current) do
        local name = key:match("^Resource:(.+)$")
        if name then
            local delta = deltaValue(value, StatsRuntime.Baseline[key])
            local marker = delta > 0 and "▲" or delta < 0 and "▼" or "•"
            table.insert(resourceLines, string.format("%s  %s\n    Atual: %s  ·  Sessão: %s",
                marker, friendlyName(name), fmt(value), gainText(value, StatsRuntime.Baseline[key])))
        end
    end
    table.sort(resourceLines)
    pcall(function()
        StatsResources:Set({
            Title = "Inventário e ganhos",
            Content = #resourceLines > 0 and table.concat(resourceLines, "\n\n") or "Nenhum recurso replicado.",
        })
    end)
end

local function resetStatsBaseline()
    StatsRuntime.Baseline = statsSnapshot()
    StatsRuntime.StartedAt = os.time()
    renderStats()
end

StatsTab:CreateButton({
    Name = "Redefinir início da comparação",
    Side = "Left",
    Card = "SessionSummary",
    Callback = resetStatsBaseline,
})

resetStatsBaseline()

task.spawn(function()
    while Runtime.Running do
        task.wait(2)
        if Runtime.Running then
            pcall(renderStats)
            pcall(renderCraftProgress)
            pcall(tryAllocateAttribute)
        end
    end
end)

function Runtime.Stop()
    pcall(function() MacLib:SaveConfig("Settings") end)
    Runtime.Running = false
    G.Enabled = false
    G.FarmEnabled = false
    G.BlockEnabled = false
    G.DodgeEnabled = false
    G.LegitFarmEnabled = false
    Runtime.RestockGeneration += 1
    stopFarmFacing()
    resetLegitAnimation()
    restoreNoClip()
    if Runtime.Defending then
        Runtime.Defending = false
        pcall(function() SetBlocking:FireServer(false) end)
    end
    for _, connection in ipairs(Runtime.Connections) do
        pcall(function() connection:Disconnect() end)
    end
    if Runtime.MobileGui then
        Runtime.MobileGui:Destroy()
        Runtime.MobileGui = nil
    end
    pcall(function() Rayfield:Destroy() end)
end

pcall(function() MacLib:LoadConfig("Settings") end)
if G.LegitFarmEnabled and G.FarmEnabled then
    G.FarmEnabled = false
    pcall(function() FarmToggle:Set(false) end)
end

task.spawn(function()
    while Runtime.Running do
        task.wait(5)
        if Runtime.Running then pcall(function() MacLib:SaveConfig("Settings") end) end
    end
end)

buildCatalogDropdown()
updateStatus()
if CraftingData[G.SelectedCraft] then
    applyCraftAutomation(G.SelectedCraft)
end
renderCraftProgress()
if firstMacTab then firstMacTab:Select() end

task.defer(function()
    MerchantRequest:FireServer()
end)
