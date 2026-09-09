--// Merchant + Crafting + Player Stats - MacUI

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

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
if type(G.SelectedItems) ~= "table" then G.SelectedItems = {} end
if G.BuyMode == nil then G.BuyMode = "Quantity" end
if G.BuyMode == "Quantidade" then G.BuyMode = "Quantity" end
if G.BuyMode == "Todos" then G.BuyMode = "All" end
if G.Quantity == nil then G.Quantity = 1 end
if G.AutoAttribute == nil then G.AutoAttribute = false end
if G.AttributeTarget == nil then G.AttributeTarget = "Damage" end
if G.SelectedCraft == nil or G.SelectedCraft == "Nenhum" then G.SelectedCraft = "None" end
if G.FarmEnabled == nil then G.FarmEnabled = false end
if type(G.SelectedMobs) ~= "table" then G.SelectedMobs = {} end
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
if type(G.SelectedQuests) ~= "table" then G.SelectedQuests = {} end
if G.QuestTeleportDelay == nil then G.QuestTeleportDelay = 0.5 end
if G.QuestInteractDelay == nil then G.QuestInteractDelay = 0.75 end
if G.NativeAutoQuest == nil then G.NativeAutoQuest = false end
if G.AutoPotionEnabled == nil then G.AutoPotionEnabled = false end
if type(G.SelectedPotions) ~= "table" then G.SelectedPotions = {MediumHealthPotion = true} end
if G.PotionThreshold == nil then G.PotionThreshold = 90 end
if G.PotionCooldown == nil then G.PotionCooldown = 1 end
if G.NoClip == nil then G.NoClip = true end
if G.AntiAFK == nil then G.AntiAFK = false end
if G.AntiVoid == nil then G.AntiVoid = true end
if G.MenuKeybind == nil then G.MenuKeybind = "F12" end
if G.LegitFarmEnabled == nil then G.LegitFarmEnabled = false end
if G.LegitFarmMode == nil or G.LegitFarmMode == "Parado" then G.LegitFarmMode = "Stationary" end
if G.LegitFarmMode == "Aproximar" then G.LegitFarmMode = "Approach" end
if G.LegitFarmRadius == nil then G.LegitFarmRadius = 25 end
if G.LegitActionRange == nil then G.LegitActionRange = 12 end
if G.CraftModalEnabled == nil then G.CraftModalEnabled = false end
if G.LegitFaceTarget == nil then G.LegitFaceTarget = true end
if G.LegitAutoAttack == nil then G.LegitAutoAttack = true end
if G.LegitUseSkills == nil then G.LegitUseSkills = true end
if G.LegitActionDelay == nil then G.LegitActionDelay = 0.45 end
if G.AutoDisconnect == nil then G.AutoDisconnect = false end
if G.DiscordWebhookEnabled == nil then G.DiscordWebhookEnabled = false end
if G.CraftWebhookEnabled == nil then G.CraftWebhookEnabled = false end
if G.StatsWebhookEnabled == nil then G.StatsWebhookEnabled = false end
if G.WebhookIntervalMinutes == nil then G.WebhookIntervalMinutes = 30 end
G.WebhookIntervalMinutes = math.clamp(tonumber(G.WebhookIntervalMinutes) or 30, 10, 1440)

-- MacUI's current build no longer exposes the old SaveConfig/LoadConfig methods.
-- Keep persistence owned by this script so library updates cannot silently break it.
local CONFIG_FOLDER = "OvergearedMacUI"
local CONFIG_PATH = CONFIG_FOLDER .. "/Settings.json"
local CONFIG_KEYS = {
    "Enabled", "SelectedItems", "BuyMode", "Quantity",
    "AutoAttribute", "AttributeTarget", "SelectedCraft",
    "FarmEnabled", "SelectedMobs", "FarmDistance", "AttackDelay",
    "BlockEnabled", "BlockDelay", "BlockHold", "BlockRange",
    "DodgeEnabled", "DodgeDistance", "DodgeMargin",
    "QuestEnabled", "SelectedQuests", "QuestTeleportDelay", "QuestInteractDelay", "NativeAutoQuest",
    "AutoPotionEnabled", "SelectedPotions", "PotionThreshold", "PotionCooldown",
    "NoClip", "AntiAFK", "AntiVoid", "MenuKeybind",
    "LegitFarmEnabled", "LegitFarmMode", "LegitFarmRadius", "LegitActionRange",
    "LegitFaceTarget", "LegitAutoAttack", "LegitUseSkills", "LegitActionDelay",
    "CraftModalEnabled", "AutoDisconnect",
    "DiscordWebhookEnabled", "CraftWebhookEnabled", "StatsWebhookEnabled", "WebhookIntervalMinutes",
}

local function saveSettings()
    if type(writefile) ~= "function" then
        return false, "File saving is unavailable in this executor."
    end

    local ok, err = pcall(function()
        if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder(CONFIG_FOLDER) then
            makefolder(CONFIG_FOLDER)
        end

        local data = {Version = 1}
        for _, key in ipairs(CONFIG_KEYS) do
            local value = G[key]
            if type(value) == "boolean" or type(value) == "number" or type(value) == "string" or type(value) == "table" then
                data[key] = value
            end
        end
        -- The webhook URL is deliberately session-only and is never written to disk.
        writefile(CONFIG_PATH, HttpService:JSONEncode(data))
    end)
    return ok, ok and "Settings saved successfully." or ("Could not save settings: " .. tostring(err))
end

local function loadSettings()
    if type(readfile) ~= "function" or type(isfile) ~= "function" or not isfile(CONFIG_PATH) then
        return false, "No saved settings found."
    end

    local ok, result = pcall(function()
        return HttpService:JSONDecode(readfile(CONFIG_PATH))
    end)
    if not ok or type(result) ~= "table" then
        return false, "Saved settings are invalid and were ignored."
    end

    for _, key in ipairs(CONFIG_KEYS) do
        if result[key] ~= nil then G[key] = result[key] end
    end
    return true, "Saved settings loaded."
end

local settingsLoaded, settingsLoadMessage = loadSettings()

-- Normalize persisted values before controls are created.
if type(G.SelectedItems) ~= "table" then G.SelectedItems = {} end
if type(G.SelectedMobs) ~= "table" then G.SelectedMobs = {} end
if type(G.SelectedQuests) ~= "table" then G.SelectedQuests = {} end
if type(G.SelectedPotions) ~= "table" then G.SelectedPotions = {MediumHealthPotion = true} end
if G.BuyMode == "Quantidade" then G.BuyMode = "Quantity" end
if G.BuyMode == "Todos" then G.BuyMode = "All" end
if G.BuyMode ~= "All" then G.BuyMode = "Quantity" end
if G.SelectedCraft == "Nenhum" then G.SelectedCraft = "None" end
if G.LegitFarmMode == "Parado" then G.LegitFarmMode = "Stationary" end
if G.LegitFarmMode == "Aproximar" then G.LegitFarmMode = "Approach" end
if G.LegitFarmMode ~= "Approach" then G.LegitFarmMode = "Stationary" end
G.Quantity = math.max(1, math.floor(tonumber(G.Quantity) or 1))
G.WebhookIntervalMinutes = math.clamp(tonumber(G.WebhookIntervalMinutes) or 30, 10, 1440)

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
    LastBuyStatus = "Waiting for Auto Buy.",
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
    PendingPurchases = {},
    PurchaseHistory = {},
    PurchaseByItem = {},
    PurchaseTotalQuantity = 0,
    PurchaseTotalSpent = 0,
    CraftModalGui = nil,
    DiscordWebhookUrl = "",
    CraftWebhookUrl = "",
    DiscordWebhookBusy = false,
    DiscordWebhookLastSent = 0,
    DiscordWebhookBusyByUrl = {},
    DiscordWebhookLastSentByUrl = {},
    CraftWebhookMessageId = nil,
    CraftWebhookSignature = nil,
    CraftWebhookPending = false,
    CraftWebhookCraftId = nil,
    CraftWebhookLastAttempt = 0,
    StatsWebhookMessageId = nil,
    StatsWebhookPending = false,
    StatsWebhookLastUpdate = 0,
    StatsWebhookLastAttempt = 0,
    StatsPriorityQueued = false,
    SyncingCraftWebhook = false,
    AvatarThumbnailUrl = nil,
    AvatarThumbnailLastAttempt = 0,
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
    Subtitle = "Auto Buy · Crafting · Progression",
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

local function makeDraggable(handle, target, onTap)
    handle.Active = true
    local dragging, dragInput, dragStart, startPosition, moved = false, nil, nil, nil, false

    connect(handle.InputBegan, function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging = true
        dragInput = input
        dragStart = input.Position
        startPosition = target.Position
        moved = false
        local ended
        ended = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                if not moved and onTap then pcall(onTap) end
                if ended then ended:Disconnect() end
            end
        end)
    end)

    connect(UserInputService.InputChanged, function(input)
        if not dragging then return end
        if input ~= dragInput and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local delta = input.Position - dragStart
        if delta.Magnitude >= 6 then moved = true end
        target.Position = UDim2.new(
            startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
        )
        local view = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize
        if view then
            local absolute, size = target.AbsolutePosition, target.AbsoluteSize
            local correctionX = absolute.X < 6 and (6 - absolute.X)
                or (absolute.X + size.X > view.X - 6 and (view.X - 6 - absolute.X - size.X) or 0)
            local correctionY = absolute.Y < 6 and (6 - absolute.Y)
                or (absolute.Y + size.Y > view.Y - 6 and (view.Y - 6 - absolute.Y - size.Y) or 0)
            target.Position += UDim2.fromOffset(correctionX, correctionY)
        end
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
    button.Text = "UI"
    button.TextColor3 = Color3.fromRGB(245, 245, 247)
    button.TextSize = 16
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
    makeDraggable(button, button, function()
        local visible = MacWindow:GetState()
        MacWindow:SetState(not visible)
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
        side = side == "Right" and "Right" or "Left"
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

local function releaseFarmFacing()
    stopFarmFacing()
    local character, humanoid, root = characterData()
    if humanoid then humanoid.AutoRotate = true end
    if root then
        for _, name in ipairs({
            "SimpleFarmFacing", "SimpleFarmFacingAttachment",
            "LegitBossFacing", "LegitBossFacingAttachment",
        }) do
            local object = root:FindFirstChild(name)
            if object then pcall(function() object:Destroy() end) end
        end
    end
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
    Title = "Stationary Auto Farm",
    Content = "Select one or more enemies.",
    Side = "Left", Card = "Farm",
})

local MobDropdown
local FarmToggle
local LegitFarmToggle
MobDropdown = CombatTab:CreateDropdown({
    Name = "Enemies in priority order",
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
        if not value then
            Runtime.FarmTarget = nil
            if not G.LegitFarmEnabled then task.defer(releaseFarmFacing) end
        end
    end,
})

CombatTab:CreateSlider({
    Name = "Distance from enemy", Range = {3, 15}, Increment = 0.5,
    CurrentValue = G.FarmDistance, Suffix = " studs",
    Side = "Left", Card = "Farm", Flag = "MacCombatDistance",
    Callback = function(value) G.FarmDistance = value end,
})

local LegitStatus = CombatTab:CreateParagraph({
    Title = "Legit Farm",
    Content = "Movement and facing use the target; attacks can run without one.",
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
            if not G.FarmEnabled then task.defer(releaseFarmFacing) end
        end
    end,
})

local LegitModeDropdown = CombatTab:CreateDropdown({
    Name = "Mode", Options = {"Stationary", "Approach"},
    CurrentOption = {G.LegitFarmMode}, MultipleOptions = false,
    Flag = "MacLegitFarmMode", Side = "Left", Card = "LegitFarm",
    Callback = function(options)
        local mode = options[1]
        if mode == "Parado" then mode = "Stationary" end
        if mode == "Aproximar" then mode = "Approach" end
        G.LegitFarmMode = mode == "Approach" and "Approach" or "Stationary"
        if G.LegitFarmMode == "Stationary" then
            local _, humanoid, root = characterData()
            if humanoid and root then humanoid:MoveTo(root.Position) end
        end
    end,
})

CombatTab:CreateToggle({
    Name = "Face the enemy", CurrentValue = G.LegitFaceTarget,
    Flag = "MacLegitFaceTarget", Side = "Left", Card = "LegitFarm",
    Callback = function(value)
        G.LegitFaceTarget = value
        if not value and not G.FarmEnabled then task.defer(releaseFarmFacing) end
    end,
})

CombatTab:CreateSlider({
    Name = "Action interval", Range = {0.1, 2}, Increment = 0.05, Suffix = "s",
    CurrentValue = G.LegitActionDelay, Flag = "MacLegitActionDelay",
    Side = "Left", Card = "LegitFarm",
    Callback = function(value) G.LegitActionDelay = value end,
})

CombatTab:CreateToggle({
    Name = "Auto Attack", CurrentValue = G.LegitAutoAttack,
    Flag = "MacLegitAutoAttack", Side = "Left", Card = "LegitFarm",
    Callback = function(value) G.LegitAutoAttack = value end,
})

CombatTab:CreateToggle({
    Name = "Auto Skills 1, 2 and 3", CurrentValue = G.LegitUseSkills,
    Flag = "MacLegitUseSkills", Side = "Left", Card = "LegitFarm",
    Callback = function(value) G.LegitUseSkills = value end,
})

CombatTab:CreateSlider({
    Name = "Search radius", Range = {5, 60}, Increment = 1, Suffix = " studs",
    CurrentValue = G.LegitFarmRadius, Flag = "MacLegitFarmRadius",
    Side = "Left", Card = "LegitFarm",
    Callback = function(value) G.LegitFarmRadius = value end,
})

CombatTab:CreateSlider({
    Name = "Attack interval", Range = {0.1, 1.5}, Increment = 0.05,
    CurrentValue = G.AttackDelay, Suffix = "s",
    Side = "Left", Card = "Farm", Flag = "MacCombatAttackDelay",
    Callback = function(value) G.AttackDelay = value end,
})

local BlockStatus = CombatTab:CreateParagraph({
    Title = "Auto Block",
    Content = "Blocks when a nearby hostile animation starts.",
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
    Name = "Block delay", Range = {0, 0.5}, Increment = 0.01,
    CurrentValue = G.BlockDelay, Suffix = "s",
    Side = "Right", Card = "Block", Flag = "MacCombatBlockDelay",
    Callback = function(value) G.BlockDelay = value end,
})

CombatTab:CreateSlider({
    Name = "Block duration", Range = {0.05, 1}, Increment = 0.01,
    CurrentValue = G.BlockHold, Suffix = "s",
    Side = "Right", Card = "Block", Flag = "MacCombatBlockHold",
    Callback = function(value) G.BlockHold = value end,
})

local DodgeStatus = CombatTab:CreateParagraph({
    Title = "Auto Dodge",
    Content = "Blasts: behind the caster · Areas: nearest safe horizontal point.",
    Side = "Right", Card = "Dodge",
})

CombatTab:CreateToggle({
    Name = "Auto Dodge", CurrentValue = G.DodgeEnabled,
    Side = "Right", Card = "Dodge", Flag = "MacCombatDodge",
    Callback = function(value) G.DodgeEnabled = value end,
})

CombatTab:CreateSlider({
    Name = "Dodge distance", Range = {4, 20}, Increment = 0.5,
    CurrentValue = G.DodgeDistance, Suffix = " studs",
    Side = "Right", Card = "Dodge", Flag = "MacCombatDodgeDistance",
    Callback = function(value) G.DodgeDistance = value end,
})

CombatTab:CreateSlider({
    Name = "Area safety margin", Range = {1, 12}, Increment = 0.5,
    CurrentValue = G.DodgeMargin, Suffix = " studs",
    Side = "Right", Card = "Dodge", Flag = "MacCombatDodgeMargin",
    Callback = function(value) G.DodgeMargin = value end,
})

local AutoDisconnectStatus = CombatTab:CreateParagraph({
    Title = "Auto Disconnect",
    Content = "Fully unloads the script when another player joins.",
    Side = "Right", Card = "Safety",
})

CombatTab:CreateToggle({
    Name = "Stop when a player joins", CurrentValue = G.AutoDisconnect,
    Side = "Right", Card = "Safety", Flag = "MacCombatAutoDisconnect",
    Callback = function(value)
        G.AutoDisconnect = value
        AutoDisconnectStatus:Set({
            Title = "Auto Disconnect",
            Content = value and "Enabled · waiting for another player to join."
                or "Disabled.",
        })
    end,
})

connect(Players.PlayerAdded, function(player)
    if not Runtime.Running or not G.AutoDisconnect or player == LocalPlayer then return end
    pcall(function()
        AutoDisconnectStatus:Set({
            Title = "Player detected",
            Content = "Stopping all features...",
        })
    end)
    task.spawn(function()
        while Runtime.Running and not Runtime.Stop do task.wait() end
        if Runtime.Running then Runtime.Stop() end
    end)
end)

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
    connect(mob.AncestryChanged, function(_, parent)
        if parent then return end
        local animationConnection = Runtime.WatchedMobs[mob]
        if animationConnection then
            animationConnection:Disconnect()
            Runtime.WatchedMobs[mob] = nil
        end
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
        if Runtime.ActiveAreas[object] then return end
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

-- Algumas áreas começam pequenas e só atingem o diâmetro perigoso depois dos
-- atrasos acima. Esta varredura leve cobre todo o período de crescimento.
task.spawn(function()
    while Runtime.Running do
        task.wait(0.1)
        if G.DodgeEnabled then
            for _, area in ipairs(allEnemyAreas()) do
                dodgeObject(area)
            end
        end
    end
end)

connect(RunService.Heartbeat, function()
    if not G.FarmEnabled or farmPaused() then
        if not G.LegitFarmEnabled then
            local _, humanoid, root = characterData()
            local hasResidual = Runtime.FacingAlign ~= nil
                or (humanoid and humanoid.AutoRotate == false)
                or (root and (root:FindFirstChild("SimpleFarmFacing")
                    or root:FindFirstChild("LegitBossFacing")))
            if hasResidual then releaseFarmFacing() end
        end
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
            FarmStatus:Set({Title = "Waiting for enemy", Content = "No selected enemy is alive; trying the next one."})
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
        FarmStatus:Set({Title = "Auto Farm enabled", Content = string.format("Target: %s · Lv.%d",
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
    if farmPaused() then
        humanoid:MoveTo(root.Position)
        stopFarmFacing()
        return
    end
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
        humanoid:MoveTo(root.Position)
        stopFarmFacing()
        if os.clock() - Runtime.LegitLastStatus >= 0.5 then
            Runtime.LegitLastStatus = os.clock()
            LegitStatus:Set({Title = "Legit Farm", Content = Runtime.LegitTargetId and "Waiting for respawn." or "No enemy within range."})
        end
        return
    end

    if G.LegitFaceTarget then
        faceFarmTarget(humanoid, root, targetRoot.Position)
    else
        releaseFarmFacing()
    end
    local distance = (root.Position - targetRoot.Position).Magnitude
    if G.LegitFarmMode == "Approach"
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
        task.wait(math.max(0.1, G.LegitActionDelay))
        if G.LegitFarmEnabled and not farmPaused() then
            if G.LegitAutoAttack then
                playLegitAttackAnimation()
                pcall(function() SwordAttack:FireServer() end)
            end
            if G.LegitUseSkills then
                pcall(function()
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
        if QuestStatus then QuestStatus:Set({Title = "No quest selected", Content = "Select up to three quests."}) end
        return
    end

    Runtime.QuestBusy = true
    stopFarmFacing()
    task.spawn(function()
        local picked = 0
        local ok = pcall(function()
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
        end)
        Runtime.QuestBusy = false
        Runtime.FarmTarget = nil
        if QuestStatus then
            QuestStatus:Set({
                Title = ok and "Quest pickup completed" or "Quest pickup failed",
                Content = ok and string.format("%d of %d NPCs found.", picked, #ids)
                    or "Quest pickup is ready for another attempt.",
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

local function consumeSelectedPotions(humanoid)
    if Runtime.PotionBusy then return end
    Runtime.PotionBusy = true

    task.spawn(function()
        pcall(function()
            for _, potionId in ipairs(potionIds) do
                if not Runtime.Running or not G.AutoPotionEnabled then break end
                if not humanoid.Parent or humanoid.Health <= 0 or humanoid.Health >= humanoid.MaxHealth then break end

                if G.SelectedPotions[potionId] and potionCount(potionId) > 0 then
                    Runtime.LastPotionUse = os.clock()
                    pcall(function() UsePotion:FireServer(potionId) end)
                    task.wait(math.max(1, tonumber(G.PotionCooldown) or 1))
                end
            end
        end)
        Runtime.PotionBusy = false
    end)
end

task.spawn(function()
    while Runtime.Running do
        task.wait(0.1)
        if G.AutoPotionEnabled and not Runtime.PotionBusy then
            local _, humanoid = characterData()
            local hasSelectedPotion = false
            for _, potionId in ipairs(potionIds) do
                if G.SelectedPotions[potionId] then
                    hasSelectedPotion = true
                    break
                end
            end
            if humanoid and humanoid.MaxHealth > 0
                and hasSelectedPotion
                and humanoid.Health / humanoid.MaxHealth * 100 < (tonumber(G.PotionThreshold) or 90) then
                consumeSelectedPotions(humanoid)
            end
        end
    end
end)

local UtilityTab = Window:CreateTab("Quests + Potion", nil)

QuestStatus = UtilityTab:CreateParagraph({
    Title = "Auto Quest",
    Content = "Select up to three quests and run the initial pickup.",
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
    Name = "Quests (maximum 3)", Options = questLabels, CurrentOption = initialQuestLabels,
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
    Name = "Enable quest pickup", CurrentValue = G.QuestEnabled,
    Flag = "MacQuestEnabled", Side = "Left", Card = "Quests",
    Callback = function(value) G.QuestEnabled = value end,
})
UtilityTab:CreateToggle({
    Name = "Automatically repeat quests", CurrentValue = G.NativeAutoQuest,
    Flag = "MacNativeAutoQuest", Side = "Left", Card = "Quests",
    Callback = function(value)
        G.NativeAutoQuest = value
        pcall(function() SaveSettings:FireServer("AutoQuestRepeat", value) end)
    end,
})
UtilityTab:CreateSlider({
    Name = "Wait after teleporting", Range = {0, 3}, Increment = 0.05, Suffix = "s",
    CurrentValue = G.QuestTeleportDelay, Flag = "MacQuestTeleportDelay", Side = "Left", Card = "Quests",
    Callback = function(value) G.QuestTeleportDelay = value end,
})
UtilityTab:CreateSlider({
    Name = "Wait between quests", Range = {0, 3}, Increment = 0.05, Suffix = "s",
    CurrentValue = G.QuestInteractDelay, Flag = "MacQuestInteractDelay", Side = "Left", Card = "Quests",
    Callback = function(value) G.QuestInteractDelay = value end,
})
UtilityTab:CreateButton({
    Name = "Teleport and pick up quests", Side = "Left", Card = "Quests",
    Callback = pickupSelectedQuests,
})

local PotionStatus = UtilityTab:CreateParagraph({
    Title = "Auto Potion",
    Content = "Below the threshold, uses selected potions in order and stops at full health.",
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
    Name = "Available potions", Options = potionLabels, CurrentOption = initialPotionLabels,
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
    Name = "Use below", Range = {1, 100}, Increment = 1, Suffix = "% HP",
    CurrentValue = G.PotionThreshold, Flag = "MacPotionThreshold", Side = "Right", Card = "Potions",
    Callback = function(value) G.PotionThreshold = value end,
})
UtilityTab:CreateSlider({
    Name = "Interval", Range = {1, 10}, Increment = 0.1, Suffix = "s",
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
                Title = "Auto Potion",
                Content = #rows > 0 and table.concat(rows, " · ") or "No potion selected.",
            })
        end)
    end
end)

local Tab = Window:CreateTab("Auto Buy", "shopping-bag")

local Status = Tab:CreateParagraph({
    Title = "Waiting for stock",
    Content = "The first update does not trigger purchases.",
    Side = "Left", Card = "BuyControls",
})

local ItemDropdown
ItemDropdown = Tab:CreateDropdown({
    Name = "Items",
    Options = {"Loading catalog..."},
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "SimpleMerchantItems",
    Side = "Left", Card = "BuyControls",
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
    Title = "Current stock",
    Content = "Waiting for server response...",
    Side = "Right", Card = "CurrentStock",
})

local PurchaseHistoryStatus = Tab:CreateParagraph({
    Title = "Purchase history",
    Content = "0 items · 0 Gold",
    Side = "Right", Card = "PurchaseHistory",
})

Tab:CreateToggle({
    Name = "Auto Buy selected items",
    CurrentValue = G.Enabled,
    Flag = "SimpleMerchantEnabled",
    Side = "Left", Card = "BuyControls",
    Callback = function(value)
        G.Enabled = value
        if value then
            Runtime.BuyRequested = true
            MerchantRequest:FireServer()
        end
    end,
})

local BuyModeDropdown = Tab:CreateDropdown({
    Name = "Purchase mode",
    Options = {"Quantity", "All"},
    CurrentOption = {G.BuyMode},
    MultipleOptions = false,
    Flag = "SimpleMerchantMode",
    Side = "Left", Card = "BuyControls",
    Callback = function(options)
        local mode = options[1]
        if mode == "Quantidade" then mode = "Quantity" end
        if mode == "Todos" then mode = "All" end
        G.BuyMode = mode == "All" and "All" or "Quantity"
    end,
})

local QuantityInput
QuantityInput = Tab:CreateInput({
    Name = "Quantity per item",
    CurrentValue = tostring(G.Quantity),
    PlaceholderText = "Example: 10",
    RemoveTextAfterFocusLost = false,
    Flag = "SimpleMerchantQuantity",
    Side = "Left", Card = "BuyControls",
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

    if #options == 0 then options = {"No items found"} end
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
            Title = string.format("Next restock: %02d:%02d", minutes, seconds),
            Content = string.format("%d available · %d selected\n%s",
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
            Title = "Current stock",
            Content = #rows > 0 and table.concat(rows, "\n") or "No items available.",
        })
    end)
end

local function updatePurchaseHistory()
    local lines = {
        string.format("%d items · %d Gold", Runtime.PurchaseTotalQuantity, Runtime.PurchaseTotalSpent),
    }

    local itemIds = {}
    for id in pairs(Runtime.PurchaseByItem) do table.insert(itemIds, id) end
    table.sort(itemIds, function(a, b)
        local itemA = Runtime.PurchaseByItem[a]
        local itemB = Runtime.PurchaseByItem[b]
        if itemA.spent ~= itemB.spent then return itemA.spent > itemB.spent end
        return a < b
    end)

    for index, id in ipairs(itemIds) do
        if index > 8 then break end
        local item = Runtime.PurchaseByItem[id]
        table.insert(lines, string.format("%s x%d | %d Gold",
            id, item.quantity, item.spent))
    end
    pcall(function()
        PurchaseHistoryStatus:Set({
            Title = "Purchase history",
            Content = table.concat(lines, "\n"),
        })
    end)
end

local function recordPurchase(id, quantity, price)
    if quantity <= 0 then return end
    local spent = quantity * math.max(0, tonumber(price) or 0)
    Runtime.PurchaseTotalQuantity += quantity
    Runtime.PurchaseTotalSpent += spent
    local item = Runtime.PurchaseByItem[id] or {quantity = 0, spent = 0}
    item.quantity += quantity
    item.spent += spent
    Runtime.PurchaseByItem[id] = item
    table.insert(Runtime.PurchaseHistory, 1, {
        time = os.date("%H:%M:%S"), id = id, quantity = quantity, spent = spent,
    })
    while #Runtime.PurchaseHistory > 20 do table.remove(Runtime.PurchaseHistory) end
    updatePurchaseHistory()
end

local function reconcilePurchases(newStock)
    for id, pending in pairs(Runtime.PendingPurchases) do
        local oldItem = Runtime.Stock[id]
        local newItem = newStock[id]
        if pending > 0 and oldItem then
            local newAmount = newItem and newItem.stock or 0
            local confirmed = math.min(pending, math.max(0, oldItem.stock - newAmount))
            if confirmed > 0 then
                recordPurchase(id, confirmed, oldItem.price)
                pending -= confirmed
            end
        end
        Runtime.PendingPurchases[id] = pending > 0 and pending or nil
    end
end

--// Crafting -----------------------------------------------------------------

local sendDiscordWebhook
local sendStatsWebhook
local StatsCraftWebhookToggle
local CraftWebhookToggle
local CraftTab = Window:CreateTab("Crafting", "hammer")

CraftTab:CreateParagraph({
    Title = "Recipe",
    Content = "Choose an item.",
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
    Title = "Materials",
    Content = "—",
    Side = "Right",
    Card = "CraftMaterials",
})

local CraftSources = CraftTab:CreateParagraph({
    Title = "Sources",
    Content = "—",
    Side = "Right",
    Card = "CraftSources",
})

local CraftWebhookStatus = CraftTab:CreateParagraph({
    Title = "Craft Webhook",
    Content = "Disabled.",
    Side = "Left",
    Card = "CraftSelection",
})

local function friendlyName(text)
    return tostring(text)
        :gsub("(%l)(%u)", "%1 %2")
        :gsub("(%a)(%d)", "%1 %2")
end

local craftModalGui = Instance.new("ScreenGui")
craftModalGui.Name = "CraftProgressModal"
craftModalGui.ResetOnSpawn = false
craftModalGui.IgnoreGuiInset = true
craftModalGui.DisplayOrder = 999998
craftModalGui.Enabled = G.CraftModalEnabled
craftModalGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local craftModal = Instance.new("Frame")
craftModal.Name = "Panel"
craftModal.AnchorPoint = Vector2.new(1, 0)
craftModal.Position = UDim2.new(1, -18, 0, 70)
craftModal.Size = UDim2.fromOffset(compactUI and 270 or 310, 130)
craftModal.BackgroundColor3 = Color3.fromRGB(24, 24, 26)
craftModal.BackgroundTransparency = 0.06
craftModal.BorderSizePixel = 0
craftModal.Parent = craftModalGui

local modalCorner = Instance.new("UICorner")
modalCorner.CornerRadius = UDim.new(0, 12)
modalCorner.Parent = craftModal
local modalStroke = Instance.new("UIStroke")
modalStroke.Color = Color3.fromRGB(72, 72, 78)
modalStroke.Transparency = 0.35
modalStroke.Thickness = 1
modalStroke.Parent = craftModal

local modalHeader = Instance.new("TextLabel")
modalHeader.Name = "Header"
modalHeader.BackgroundTransparency = 1
modalHeader.Position = UDim2.fromOffset(14, 8)
modalHeader.Size = UDim2.new(1, -28, 0, 24)
modalHeader.Font = Enum.Font.GothamSemibold
modalHeader.TextColor3 = Color3.fromRGB(245, 245, 247)
modalHeader.TextSize = 15
modalHeader.TextXAlignment = Enum.TextXAlignment.Left
modalHeader.TextTruncate = Enum.TextTruncate.AtEnd
modalHeader.Text = "Craft"
modalHeader.Parent = craftModal

local modalSummary = Instance.new("TextLabel")
modalSummary.BackgroundTransparency = 1
modalSummary.Position = UDim2.fromOffset(14, 33)
modalSummary.Size = UDim2.new(1, -28, 0, 20)
modalSummary.Font = Enum.Font.GothamMedium
modalSummary.TextColor3 = Color3.fromRGB(170, 170, 178)
modalSummary.TextSize = 13
modalSummary.TextXAlignment = Enum.TextXAlignment.Left
modalSummary.Text = "0/0"
modalSummary.Parent = craftModal

local modalBody = Instance.new("TextLabel")
modalBody.BackgroundTransparency = 1
modalBody.Position = UDim2.fromOffset(14, 58)
modalBody.Size = UDim2.new(1, -28, 1, -68)
modalBody.Font = Enum.Font.Code
modalBody.TextColor3 = Color3.fromRGB(220, 220, 225)
modalBody.TextSize = compactUI and 12 or 13
modalBody.TextXAlignment = Enum.TextXAlignment.Left
modalBody.TextYAlignment = Enum.TextYAlignment.Top
modalBody.TextWrapped = false
modalBody.Text = "Select a recipe."
modalBody.Parent = craftModal

makeDraggable(modalHeader, craftModal)
Runtime.CraftModalGui = craftModalGui

CraftTab:CreateToggle({
    Name = "Show floating progress",
    CurrentValue = G.CraftModalEnabled,
    Flag = "MacCraftProgressModal",
    Side = "Left", Card = "CraftSelection",
    Callback = function(value)
        G.CraftModalEnabled = value
        craftModalGui.Enabled = value
    end,
})

local function updateCraftModal(craftId, completed, total, overall, missingLines)
    modalHeader.Text = friendlyName(craftId)
    modalSummary.Text = string.format("%d/%d completed · %d%%", completed, total, overall)
    modalBody.Text = #missingLines > 0 and table.concat(missingLines, "\n") or "Ready to craft."
    local visibleLines = math.max(1, math.min(#missingLines, 9))
    craftModal.Size = UDim2.fromOffset(compactUI and 270 or 310, 72 + visibleLines * 19)
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

local craftOptions = {"None"}
local CraftLabelToId = {None = "None"}
local CraftIdToLabel = {None = "None"}
for craftId, recipe in pairs(CraftingData) do
    local label = string.format("%s  ·  %s", friendlyName(craftId), tostring(recipe.Type or "Craft"))
    CraftLabelToId[label] = craftId
    CraftIdToLabel[craftId] = label
    table.insert(craftOptions, label)
end
table.sort(craftOptions, function(a, b)
    if a == b then return false end
    if a == "None" then return true end
    if b == "None" then return false end
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

    G.BuyMode = "All"
    Runtime.UpdatingDropdown = true
    pcall(function()
        ItemDropdown:Set(selectedLabels())
        BuyModeDropdown:Set({"All"})
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

local function resetCraftWebhook(craftId)
    Runtime.CraftWebhookMessageId = nil
    Runtime.CraftWebhookSignature = nil
    Runtime.CraftWebhookPending = false
    Runtime.CraftWebhookCraftId = craftId
    Runtime.CraftWebhookLastAttempt = 0
end

local function updateCraftWebhook(craftId, recipe, complete, completed, total, overall, fields, signature)
    if not G.CraftWebhookEnabled then return end
    if Runtime.CraftWebhookCraftId ~= craftId then resetCraftWebhook(craftId) end
    if Runtime.CraftWebhookPending then return end
    local intervalSeconds = math.clamp(tonumber(G.WebhookIntervalMinutes) or 30, 10, 1440) * 60
    if Runtime.CraftWebhookLastAttempt > 0
        and os.clock() - Runtime.CraftWebhookLastAttempt < intervalSeconds then return end
    if type(sendDiscordWebhook) ~= "function" then return end

    Runtime.CraftWebhookPending = true
    local stateText = complete and "COMPLETED" or "IN PROGRESS"
    local started, reason = sendDiscordWebhook(
        friendlyName(craftId) .. " | Craft Tracker",
        string.format("%s **%s**\n%d of %d requirements complete · **%d%%**",
            complete and "✅" or "🛠️", stateText, completed, total, overall),
        {
            fields = fields,
            webhookUrl = Runtime.CraftWebhookUrl,
            messageId = Runtime.CraftWebhookMessageId,
            footer = string.format("Overgeared Crafting · Updates every %d minute(s)",
                math.clamp(tonumber(G.WebhookIntervalMinutes) or 30, 10, 1440)),
            authorName = "OVERGEARED · CRAFTING",
            color = complete and 5763719 or 16753920,
            silentStatus = true,
            callback = function(success, messageId, errorMessage)
                if not G.CraftWebhookEnabled or Runtime.CraftWebhookCraftId ~= craftId then return end
                Runtime.CraftWebhookPending = false
                if success then
                    Runtime.CraftWebhookMessageId = messageId or Runtime.CraftWebhookMessageId
                    Runtime.CraftWebhookSignature = signature
                    CraftWebhookStatus:Set({
                        Title = "Craft Webhook",
                        Content = complete and "Craft completed | tracker updated."
                            or string.format("Tracking %s | %d%%", friendlyName(craftId), overall),
                    })
                else
                    CraftWebhookStatus:Set({
                        Title = "Craft Webhook",
                        Content = errorMessage or "Failed to update the tracker.",
                    })
                end
            end,
        }
    )
    if not started then
        Runtime.CraftWebhookPending = false
        CraftWebhookStatus:Set({Title = "Craft Webhook", Content = reason})
    else
        Runtime.CraftWebhookLastAttempt = os.clock()
    end
end


local function renderCraftProgress()
    local craftId = G.SelectedCraft
    local recipe = CraftingData[craftId]
    if not recipe then
        pcall(function()
            CraftSummary:Set({Title = "Craft", Content = "Select a recipe."})
            CraftProgress:Set({Title = "Materials", Content = "—"})
            CraftSources:Set({Title = "Sources", Content = "—"})
            modalHeader.Text = "Craft"
            modalSummary.Text = "0/0"
            modalBody.Text = "Select a recipe."
            craftModal.Size = UDim2.fromOffset(compactUI and 270 or 310, 110)
        end)
        return
    end

    local lines = {}
    local sourceLines = {}
    local modalLines = {}
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
    if goldMissing > 0 then
        table.insert(modalLines, string.format("Gold  %d/%d", goldHave, goldNeed))
    end

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
            table.insert(modalLines, string.format("%s  %d/%d",
                friendlyName(id), have, needed))
        end

        if missing > 0 then
            local acquisition = {}
            if Runtime.Catalog[id] then table.insert(acquisition, "Merchant") end
            local source = (DropSources[id] or {})[1]
            if source then
                table.insert(acquisition, string.format("%s Lv.%d · %.0f%% ×%d",
                    friendlyName(source.name), source.level, source.chance * 100, source.amount))
            elseif not Runtime.Catalog[id] then
                table.insert(acquisition, "Unknown source")
            end
            table.insert(sourceLines, string.format("%s → %s",
                friendlyName(id), table.concat(acquisition, " + ")))
        end
    end

    local overall = totalRequirements > 0 and math.floor(progressSum / totalRequirements * 100 + 0.5) or 100
    updateCraftModal(craftId, completedRequirements, totalRequirements, overall, modalLines)

    pcall(function()
        CraftSummary:Set({
            Title = friendlyName(craftId),
            Content = string.format("%s · %d/%d · %d%%",
                complete and "Ready" or tostring(recipe.Type or "Craft"),
                completedRequirements, totalRequirements, overall),
        })
        CraftProgress:Set({
            Title = "Materials",
            Content = table.concat(lines, "\n"),
        })
        CraftSources:Set({
            Title = "Sources for missing items",
            Content = #sourceLines > 0 and table.concat(sourceLines, "\n\n")
                or "Complete.",
        })
    end)
end

local renderCraftProgressBase = renderCraftProgress
renderCraftProgress = function()
    renderCraftProgressBase()

    local craftId = G.SelectedCraft
    local recipe = CraftingData[craftId]
    if not recipe or not G.CraftWebhookEnabled then return end

    local missingLines = {}
    local completedLines = {}
    local signatureParts = {craftId}
    local completed = 0
    local total = 1 + #(recipe.Materials or {})
    local progressSum = 0
    local complete = true
    local goldHave = currentGold()
    local goldNeed = tonumber(recipe.GoldCost) or 0
    local goldDone = goldHave >= goldNeed
    local goldProgress = math.min(goldHave, goldNeed)
    if goldDone then completed += 1 else complete = false end
    progressSum += goldNeed > 0 and math.clamp(goldHave / goldNeed, 0, 1) or 1
    local goldLine = string.format("**Gold** — `%d / %d`", goldProgress, goldNeed)
    if goldDone then
        table.insert(completedLines, goldLine)
    else
        table.insert(missingLines, goldLine .. string.format("  _(missing %d)_", goldNeed - goldProgress))
    end
    table.insert(signatureParts, string.format("Gold:%d/%d", goldProgress, goldNeed))

    local materials = table.clone(recipe.Materials or {})
    table.sort(materials, function(a, b) return tostring(a.Id) < tostring(b.Id) end)
    for _, material in ipairs(materials) do
        local id = tostring(material.Id)
        local needed = tonumber(material.Amount) or 0
        local have = ownedResourceAmount(id)
        local shownHave = math.min(have, needed)
        local done = have >= needed
        if done then completed += 1 else complete = false end
        progressSum += needed > 0 and math.clamp(have / needed, 0, 1) or 1

        local sources = {}
        if Runtime.Catalog[id] then table.insert(sources, "Merchant") end
        local source = (DropSources[id] or {})[1]
        if source then
            table.insert(sources, string.format("%s Lv.%d | %.0f%% x%d",
                friendlyName(source.name), source.level, source.chance * 100, source.amount))
        elseif not Runtime.Catalog[id] then
            table.insert(sources, "Unknown source")
        end
        local materialLine = string.format("**%s** — `%d / %d`",
            friendlyName(id), shownHave, needed)
        if done then
            table.insert(completedLines, materialLine)
        else
            table.insert(missingLines, materialLine
                .. string.format("  _(missing %d)_\n↳ %s", needed - shownHave, table.concat(sources, " + ")))
        end
        table.insert(signatureParts, string.format("%s:%d/%d", id, shownHave, needed))
    end

    local overall = total > 0 and math.floor(progressSum / total * 100 + 0.5) or 100
    table.insert(signatureParts, complete and "complete" or "progress")
    local fields = {
        {name = "Progress", value = string.format("**%d / %d**", completed, total), inline = true},
        {name = "Completion", value = string.format("**%d%%**", overall), inline = true},
        {name = "Type", value = tostring(recipe.Type or "Craft"), inline = true},
        {
            name = complete and "Requirements" or "Missing requirements",
            value = (#missingLines > 0 and table.concat(missingLines, "\n\n") or "Nothing missing."):sub(1, 1024),
            inline = false,
        },
        {
            name = "Completed requirements",
            value = (#completedLines > 0 and table.concat(completedLines, "\n") or "None yet."):sub(1, 1024),
            inline = false,
        },
    }
    updateCraftWebhook(craftId, recipe, complete, completed, total, overall,
        fields, table.concat(signatureParts, "|"))
end

CraftTab:CreateDropdown({
    Name = "Selected craft",
    Options = craftOptions,
    CurrentOption = {CraftingData[G.SelectedCraft] and CraftIdToLabel[G.SelectedCraft] or "None"},
    MultipleOptions = false,
    Flag = "MerchantSelectedCraft",
    Side = "Left",
    Card = "CraftSelection",
    Callback = function(options)
        local craftId = CraftLabelToId[options[1]] or "None"
        G.SelectedCraft = craftId
        resetCraftWebhook(craftId)
        if CraftingData[craftId] then
            applyCraftAutomation(craftId)
        elseif G.CraftWebhookEnabled then
            CraftWebhookStatus:Set({Title = "Craft Webhook", Content = "Select a craft."})
        end
        renderCraftProgress()
    end,
})

CraftWebhookToggle = CraftTab:CreateToggle({
    Name = "Craft Webhook",
    CurrentValue = G.CraftWebhookEnabled,
    Flag = "MacCraftWebhookEnabled",
    Side = "Left",
    Card = "CraftSelection",
    Callback = function(value)
        G.CraftWebhookEnabled = value
        if not Runtime.SyncingCraftWebhook and StatsCraftWebhookToggle then
            Runtime.SyncingCraftWebhook = true
            StatsCraftWebhookToggle:Set(value)
            Runtime.SyncingCraftWebhook = false
        end
        resetCraftWebhook(G.SelectedCraft)
        if not value then
            CraftWebhookStatus:Set({Title = "Craft Webhook", Content = "Disabled."})
        elseif not CraftingData[G.SelectedCraft] then
            CraftWebhookStatus:Set({Title = "Craft Webhook", Content = "Select a craft."})
        else
            CraftWebhookStatus:Set({Title = "Craft Webhook", Content = "Preparing tracker..."})
            renderCraftProgress()
        end
    end,
})

CraftTab:CreateButton({
    Name = "Sync Merchant + Auto Farm",
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
        Runtime.LastBuyStatus = "No selected item is currently in stock."
        Runtime.Buying = false
        updateStatus()
        return
    end

    local requestsSent = 0
    Runtime.LastBuyStatus = "Buying selected items..."
    updateStatus()

    for _, id in ipairs(ids) do
        if not Runtime.Running or not G.Enabled then break end
        local item = Runtime.Stock[id]
        local amount = G.BuyMode == "All"
            and item.stock
            or math.min(G.Quantity, item.stock)

        for _ = 1, amount do
            if not Runtime.Running or not G.Enabled then break end
            MerchantBuy:FireServer(id)
            Runtime.PendingPurchases[id] = (Runtime.PendingPurchases[id] or 0) + 1
            requestsSent += 1
            -- Apenas cede um ciclo para não congelar o cliente; não existe
            -- configuração de intervalo na interface.
            task.wait()
        end
    end

    Runtime.Buying = false
    Runtime.LastBuyStatus = string.format("Last run: %d purchase request(s) sent.", requestsSent)
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

    if next(newStock) ~= nil and not isRestock then
        reconcilePurchases(newStock)
    elseif isRestock then
        table.clear(Runtime.PendingPurchases)
    end

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
                Title = "New restock detected",
                Content = "Selected items will be purchased in 5 seconds.",
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

connect(LocalPlayer.Idled, function()
    if G.AntiAFK then
        pcall(function()
            local cameraCFrame = Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame or CFrame.new()
            VirtualUser:CaptureController()
            VirtualUser:Button2Down(Vector2.zero, cameraCFrame)
            task.wait()
            VirtualUser:Button2Up(Vector2.zero, cameraCFrame)
        end)
    end
end)

local StatsTab = Window:CreateTab("Player Stats", "user")

local StatsRuntime = {
    Baseline = {},
    StartedAt = os.time(),
}

local function getHttpRequest()
    local environment = getgenv and getgenv() or _G
    return environment.request
        or environment.http_request
        or (environment.syn and environment.syn.request)
        or (environment.http and environment.http.request)
        or (environment.fluxus and environment.fluxus.request)
end

local function getAvatarThumbnailUrl()
    if type(Runtime.AvatarThumbnailUrl) == "string" and Runtime.AvatarThumbnailUrl:match("^https://") then
        return Runtime.AvatarThumbnailUrl
    end
    if Runtime.AvatarThumbnailLastAttempt > 0
        and os.clock() - Runtime.AvatarThumbnailLastAttempt < 60 then return nil end
    Runtime.AvatarThumbnailLastAttempt = os.clock()

    local endpoint = string.format(
        "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=%d&size=420x420&format=Png&isCircular=false",
        LocalPlayer.UserId
    )
    local ok, body = pcall(function()
        local request = getHttpRequest()
        if type(request) == "function" then
            local response = request({Url = endpoint, Method = "GET"})
            if type(response) == "table" then
                return response.Body or response.body
            end
        end
        return game:HttpGet(endpoint)
    end)
    if not ok then return nil end

    local decodedOk, decoded = pcall(function()
        if type(body) == "table" then return body end
        return HttpService:JSONDecode(tostring(body or ""))
    end)
    local entry = decodedOk and type(decoded) == "table" and type(decoded.data) == "table" and decoded.data[1]
    local imageUrl = type(entry) == "table" and entry.imageUrl
    if type(imageUrl) == "string" and imageUrl:match("^https://") then
        Runtime.AvatarThumbnailUrl = imageUrl
        return imageUrl
    end
    return nil
end

local function normalizeDiscordWebhook(url)
    url = tostring(url or ""):match("^%s*(.-)%s*$")
    url = url:gsub("^https://discordapp%.com/", "https://discord.com/")
    url = url:gsub("^https://canary%.discord%.com/", "https://discord.com/")
    url = url:gsub("^https://ptb%.discord%.com/", "https://discord.com/")
    url = url:gsub("%?.*$", "")
    url = url:gsub("/+$", "")
    return url
end

local function validDiscordWebhook(url)
    if type(url) ~= "string" then return false end
    return url:match("^https://discord%.com/api/webhooks/%d+/[%w_-]+$") ~= nil
end

local DiscordWebhookStatus = StatsTab:CreateParagraph({
    Title = "Player Stats Webhook",
    Content = "Paste the player-status webhook URL. It is kept only in memory.",
    Side = "Left",
    Card = "DiscordWebhook",
})

StatsTab:CreateInput({
    Name = "Player Stats webhook URL",
    CurrentValue = "",
    PlaceholderText = "https://discord.com/api/webhooks/...",
    Side = "Left",
    Card = "DiscordWebhook",
    -- No Flag: the credential is never written to the configuration file.
    Callback = function(value)
        Runtime.DiscordWebhookUrl = normalizeDiscordWebhook(value)
        DiscordWebhookStatus:Set({
            Title = "Discord Webhook",
            Content = Runtime.DiscordWebhookUrl == ""
                and "Empty URL | nothing will be sent."
                or (validDiscordWebhook(Runtime.DiscordWebhookUrl)
                    and "URL recognized | ready to test."
                    or "Invalid URL | use a Discord webhook URL."),
        })
    end,
})

StatsTab:CreateInput({
    Name = "Craft webhook URL",
    CurrentValue = "",
    PlaceholderText = "https://discord.com/api/webhooks/...",
    Side = "Left",
    Card = "DiscordWebhook",
    -- No Flag: webhook credentials remain session-only.
    Callback = function(value)
        local previousUrl = Runtime.CraftWebhookUrl
        Runtime.CraftWebhookUrl = normalizeDiscordWebhook(value)
        if previousUrl ~= Runtime.CraftWebhookUrl then
            resetCraftWebhook(G.SelectedCraft)
        end
        CraftWebhookStatus:Set({
            Title = "Craft Webhook",
            Content = Runtime.CraftWebhookUrl == ""
                and "Empty URL | craft updates will not be sent."
                or (validDiscordWebhook(Runtime.CraftWebhookUrl)
                    and "URL recognized | craft tracker ready."
                    or "Invalid URL | use a Discord webhook URL."),
        })
    end,
})

StatsTab:CreateToggle({
    Name = "Enable notifications",
    CurrentValue = G.DiscordWebhookEnabled,
    Flag = "MacDiscordWebhookEnabled",
    Side = "Left",
    Card = "DiscordWebhook",
    Callback = function(value)
        if not value and G.StatsWebhookEnabled and sendStatsWebhook then
            sendStatsWebhook(false, "Discord notifications disabled.", true)
        end
        G.DiscordWebhookEnabled = value
    end,
})

sendDiscordWebhook = function(title, description, options)
    options = options or {}
    if not Runtime.Running and not options.allowWhenStopped then return false, "Script stopped." end
    if not G.DiscordWebhookEnabled then return false, "Enable notifications first." end
    local destinationUrl = normalizeDiscordWebhook(options.webhookUrl or Runtime.DiscordWebhookUrl)
    if not validDiscordWebhook(destinationUrl) then
        return false, options.webhookUrl ~= nil
            and "Enter a valid Craft webhook URL."
            or "Enter a valid Player Stats webhook URL."
    end
    if Runtime.DiscordWebhookBusyByUrl[destinationUrl] and not options.bypassBusy then
        return false, "A request for this webhook is already in progress."
    end
    local destinationLastSent = Runtime.DiscordWebhookLastSentByUrl[destinationUrl] or 0
    if not options.bypassCooldown and os.clock() - destinationLastSent < 2 then
        return false, "Wait two seconds before trying again."
    end

    local request = getHttpRequest()
    if type(request) ~= "function" then
        return false, "This environment does not support HTTP requests."
    end

    Runtime.DiscordWebhookBusy = true
    Runtime.DiscordWebhookLastSent = os.clock()
    Runtime.DiscordWebhookBusyByUrl[destinationUrl] = true
    Runtime.DiscordWebhookLastSentByUrl[destinationUrl] = os.clock()
    local thumbnailUrl = options.thumbnailUrl or getAvatarThumbnailUrl()
    local requestUrl = destinationUrl
    local requestMethod = "POST"
    if options.messageId then
        requestUrl = requestUrl .. "/messages/" .. tostring(options.messageId)
        requestMethod = "PATCH"
    else
        requestUrl = requestUrl .. "?wait=true"
    end
    task.spawn(function()
        local ok, response = pcall(function()
            local body = HttpService:JSONEncode({
                username = "Overgeared Tracker",
                allowed_mentions = { parse = {} },
                embeds = {{
                    title = tostring(title or "Overgeared"),
                    description = tostring(description or ""),
                    color = tonumber(options.color) or 16777215,
                    fields = options.fields or {},
                    timestamp = options.timestamp or os.date("!%Y-%m-%dT%H:%M:%SZ"),
                    author = options.authorName and {
                        name = tostring(options.authorName):sub(1, 256),
                    } or nil,
                    thumbnail = thumbnailUrl and { url = thumbnailUrl } or nil,
                    footer = { text = tostring(options.footer or "MacUI notification") },
                }},
            })
            return request({
                Url = requestUrl,
                Method = requestMethod,
                Headers = { ["Content-Type"] = "application/json" },
                Body = body,
            })
        end)

        Runtime.DiscordWebhookBusyByUrl[destinationUrl] = nil
        Runtime.DiscordWebhookBusy = next(Runtime.DiscordWebhookBusyByUrl) ~= nil
        local responseTable = type(response) == "table" and response or nil
        local statusCode = ok and tonumber(responseTable and (
            responseTable.StatusCode or responseTable.Status
                or responseTable.status_code or responseTable.status
        )) or 0
        local responseBody = responseTable and (responseTable.Body or responseTable.body)
        local requestSucceeded = ok and (
            (statusCode >= 200 and statusCode < 300)
            or (statusCode == 0 and responseTable
                and (responseTable.Success == true or responseTable.success == true))
        )
        if requestSucceeded then
            local messageId = options.messageId
            if not messageId and type(responseBody) == "string" then
                local decodedOk, decoded = pcall(HttpService.JSONDecode, HttpService, responseBody)
                if decodedOk and type(decoded) == "table" then messageId = decoded.id end
            elseif not messageId and type(responseBody) == "table" then
                messageId = responseBody.id
            end
            if not options.silentStatus then
                DiscordWebhookStatus:Set({
                    Title = "Discord Webhook",
                    Content = "Test sent successfully.",
                })
            end
            if options.callback then options.callback(true, messageId) end
        else
            local errorMessage = ok and ("Discord returned HTTP " .. tostring(statusCode) .. ".")
                or "The request failed before reaching Discord."
            if not options.silentStatus then
                DiscordWebhookStatus:Set({
                    Title = "Webhook failed",
                    Content = errorMessage,
                })
            end
            if options.callback then options.callback(false, nil, errorMessage) end
        end
    end)
    return true
end

StatsTab:CreateButton({
    Name = "Test webhook",
    Side = "Left",
    Card = "DiscordWebhook",
    Callback = function()
        local started, reason = sendDiscordWebhook(
            "Webhook connected",
            "The Overgeared MacUI notification test was successful."
        )
        if not started then
            DiscordWebhookStatus:Set({Title = "Discord Webhook", Content = reason})
        else
            DiscordWebhookStatus:Set({Title = "Discord Webhook", Content = "Sending test..."})
        end
    end,
})

local StatsSummary = StatsTab:CreateParagraph({
    Title = "Session summary",
    Content = "Waiting for replicated player data...",
    Side = "Left",
    Card = "SessionSummary",
})

local StatsResources = StatsTab:CreateParagraph({
    Title = "Inventory and gains",
    Content = "Waiting for resources...",
    Side = "Left",
    Card = "InventoryGains",
})

local StatsCombat = StatsTab:CreateParagraph({
    Title = "Combat stats",
    Content = "Waiting for stats...",
    Side = "Right",
    Card = "CombatStats",
})

local AttributeStatus = StatsTab:CreateParagraph({
    Title = "Auto Attributes",
    Content = "Choose an attribute and enable automatic point allocation.",
    Side = "Right",
    Card = "AutoAttributes",
})

local attributeOptions = {
    "Health", "Def", "Damage", "CritChance", "CritMultiplier", "Evasion",
}

StatsTab:CreateDropdown({
    Name = "Attribute to receive points",
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
    Name = "Auto allocate points",
    CurrentValue = G.AutoAttribute,
    Flag = "MerchantStatsAutoAttribute",
    Side = "Right",
    Card = "AutoAttributes",
    Callback = function(value)
        G.AutoAttribute = value
    end,
})

local SettingsSaveStatus = StatsTab:CreateParagraph({
    Title = "Player options",
    Content = settingsLoaded and settingsLoadMessage or "Settings are ready to be saved.",
    Side = "Right",
    Card = "PlayerOptions",
})

StatsTab:CreateToggle({
    Name = "NoClip while farming", CurrentValue = G.NoClip,
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
    Name = "Anti-AFK", CurrentValue = G.AntiAFK,
    Flag = "MacPlayerAntiAFK", Side = "Right", Card = "PlayerOptions",
    Callback = function(value) G.AntiAFK = value end,
})

local keybindOptions = {"F12", "RightShift", "RightControl", "LeftAlt"}
StatsTab:CreateDropdown({
    Name = "Interface keybind", Options = keybindOptions,
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
    Name = "Save settings now", Side = "Right", Card = "PlayerOptions",
    Callback = function()
        local ok, message = saveSettings()
        SettingsSaveStatus:Set({
            Title = ok and "Settings saved" or "Settings not saved",
            Content = message,
        })
    end,
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
        setAttributeStatus("Auto Attributes waiting", "Could not read the available points.")
        return
    end
    if availableBefore <= 0 then
        setAttributeStatus("Auto Attributes enabled", "No points available · target: " .. target)
        return
    end
    if Runtime.CappedAttributes[target] or (rule.cap and allocated and allocated >= rule.cap) then
        Runtime.CappedAttributes[target] = true
        setAttributeStatus("Attribute capped", target .. " will not receive further attempts.")
        return
    end

    Runtime.AllocatingAttribute = true
    AllocateAttribute:FireServer(target, 1)

    task.delay(0.8, function()
        if not Runtime.Running then return end
        local availableAfter = availableAttributePoints()
        if availableAfter ~= nil and availableAfter < availableBefore then
            Runtime.CappedAttributes[target] = nil
            setAttributeStatus("Point allocated", string.format(
                "%s · available: %d", target, availableAfter))
        elseif G.AttributeTarget == target then
            Runtime.CappedAttributes[target] = true
            setAttributeStatus("No change", target .. " was treated as capped or rejected by the server.")
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

    local summaryLines = {
        "Session  " .. timeText,
        string.format("Level  %s (%s)", fmt(current.Level), gainText(current.Level, StatsRuntime.Baseline.Level)),
    }
    if expGoal then
        table.insert(summaryLines, string.format("EXP  %s/%s", fmt(expNow), fmt(expGoal)))
    else
        table.insert(summaryLines, string.format("EXP  %s (%s)", fmt(current.Exp), gainText(current.Exp, StatsRuntime.Baseline.Exp)))
    end

    for _, entry in ipairs({
        {"Gold", "Gold"}, {"Gem", "Gems"}, {"MonsterKills", "Enemies defeated"},
        {"GuildPoints", "Guild Points"}, {"AttributePoints", "Available points"},
    }) do
        local key, label = entry[1], entry[2]
        table.insert(summaryLines, string.format("%s  %s (%s)", label, fmt(current[key]),
            gainText(current[key], StatsRuntime.Baseline[key])))
    end

    local combatLines = {}
    for _, entry in ipairs({
        {"Damage", "Damage", "AttrDamage", ""},
        {"Def", "Defense", "AttrDef", ""},
        {"Health", "Health", "AttrHealth", ""},
        {"Evasion", "Evasion", "AttrEvasion", ""},
        {"CritChance", "Critical chance", "AttrCritChance", "%"},
        {"CritMultiplier", "Critical multiplier", "AttrCritMultiplier", "x"},
    }) do
        local ruleName, label, key, suffix = entry[1], entry[2], entry[3], entry[4]
        local value = current[key]
        local points = allocatedPoints(ruleName)
        local cap = pointRules[ruleName] and pointRules[ruleName].cap
        local displayValue = value
        if ruleName == "CritChance" and value then displayValue = value * 100 end
        local pointText = cap and string.format("%s/%d", fmt(points), cap) or fmt(points)
        table.insert(combatLines, string.format("%s  %s%s · %s pts",
            label, fmt(displayValue), suffix, pointText))
    end

    pcall(function()
        StatsSummary:Set({Title = "Session summary", Content = table.concat(summaryLines, "\n")})
        StatsCombat:Set({Title = "Combat stats", Content = table.concat(combatLines, "\n\n")})
    end)

    local resourceLines = {}
    for key, value in pairs(current) do
        local name = key:match("^Resource:(.+)$")
        if name then
            local delta = deltaValue(value, StatsRuntime.Baseline[key])
            local marker = delta > 0 and "+" or delta < 0 and "−" or "·"
            table.insert(resourceLines, string.format("%s %s  %s (%s)",
                marker, friendlyName(name), fmt(value), gainText(value, StatsRuntime.Baseline[key])))
        end
    end
    table.sort(resourceLines)
    pcall(function()
        StatsResources:Set({
            Title = "Inventory and gains",
            Content = #resourceLines > 0 and table.concat(resourceLines, "\n") or "—",
        })
    end)
end

local function resetStatsBaseline()
    StatsRuntime.Baseline = statsSnapshot()
    StatsRuntime.StartedAt = os.time()
    renderStats()
end

StatsTab:CreateButton({
    Name = "Reset comparison baseline",
    Side = "Left",
    Card = "SessionSummary",
    Callback = resetStatsBaseline,
})

local StatsWebhookStatus = StatsTab:CreateParagraph({
    Title = "Stats Webhook",
    Content = "Disabled.",
    Side = "Left",
    Card = "DiscordWebhook",
})

local WebhookIntervalInput
WebhookIntervalInput = StatsTab:CreateInput({
    Name = "Update interval (minutes)",
    CurrentValue = tostring(G.WebhookIntervalMinutes),
    PlaceholderText = "10 - 1440",
    Flag = "MacWebhookIntervalMinutes",
    Side = "Left",
    Card = "DiscordWebhook",
    Callback = function(text)
        local value = tonumber(text)
        if not value then return end
        value = math.clamp(math.floor(value), 10, 1440)
        G.WebhookIntervalMinutes = value
        if tostring(value) ~= tostring(text) then
            WebhookIntervalInput:Set(tostring(value))
        end
        StatsWebhookStatus:Set({
            Title = "Global webhook interval",
            Content = string.format("Craft and player status update every %d minute(s).", value),
        })
    end,
})

StatsCraftWebhookToggle = StatsTab:CreateToggle({
    Name = "Craft Webhook",
    CurrentValue = G.CraftWebhookEnabled,
    Side = "Left",
    Card = "DiscordWebhook",
    Callback = function(value)
        if Runtime.SyncingCraftWebhook then return end
        Runtime.SyncingCraftWebhook = true
        G.CraftWebhookEnabled = value
        CraftWebhookToggle:Set(value)
        Runtime.SyncingCraftWebhook = false
        resetCraftWebhook(G.SelectedCraft)
        if value and CraftingData[G.SelectedCraft] then
            CraftWebhookStatus:Set({Title = "Craft Webhook", Content = "Preparing tracker..."})
            renderCraftProgress()
        elseif value then
            CraftWebhookStatus:Set({Title = "Craft Webhook", Content = "Select a craft."})
        else
            CraftWebhookStatus:Set({Title = "Craft Webhook", Content = "Disabled."})
        end
    end,
})

sendStatsWebhook = function(isOnline, reason, urgent)
    if urgent and (Runtime.DiscordWebhookBusy or Runtime.StatsWebhookPending) then
        if Runtime.StatsPriorityQueued then return true end
        Runtime.StatsPriorityQueued = true
        task.spawn(function()
            local deadline = os.clock() + 15
            while (Runtime.DiscordWebhookBusy or Runtime.StatsWebhookPending)
                and os.clock() < deadline do
                task.wait(0.1)
            end
            Runtime.StatsPriorityQueued = false
            if not Runtime.DiscordWebhookBusy and not Runtime.StatsWebhookPending then
                sendStatsWebhook(isOnline, reason, true)
            end
        end)
        return true
    end
    if Runtime.StatsWebhookPending and not urgent then return false, "A stats update is already in progress." end

    local snapshotOk, snapshot = pcall(statsSnapshot)
    local dataValid = snapshotOk and type(snapshot) == "table"
        and snapshot.Level ~= nil and snapshot.Gold ~= nil
        and snapshot.Gem ~= nil and snapshot.MonsterKills ~= nil
    if isOnline and not dataValid then
        isOnline = false
        reason = reason or "Player data could not be read."
    end
    snapshot = type(snapshot) == "table" and snapshot or {}

    local elapsed = math.max(0, os.time() - StatsRuntime.StartedAt)
    local sessionTime = string.format("%02d:%02d:%02d",
        math.floor(elapsed / 3600), math.floor(elapsed % 3600 / 60), elapsed % 60)
    local displayName = tostring(LocalPlayer.DisplayName or LocalPlayer.Name):gsub("[`*_~|>]", "")
    local username = tostring(LocalPlayer.Name):gsub("[`*_~|>]", "")
    local baseline = StatsRuntime.Baseline or {}
    local sessionGains = table.concat({
        string.format("Level `%s`", gainText(snapshot.Level, baseline.Level)),
        string.format("Gold `%s`", gainText(snapshot.Gold, baseline.Gold)),
        string.format("Gems `%s`", gainText(snapshot.Gem, baseline.Gem)),
        string.format("Kills `%s`", gainText(snapshot.MonsterKills, baseline.MonsterKills)),
    }, " · ")
    local fields = {
        {
            name = "Player",
            value = string.format("**%s** (@%s)\nUser ID: `%s`", displayName, username, tostring(LocalPlayer.UserId)),
            inline = false,
        },
        {name = "Level", value = "**" .. fmt(snapshot.Level) .. "**", inline = true},
        {name = "Experience", value = "**" .. fmt(snapshot.Exp) .. "**", inline = true},
        {name = "Session", value = "`" .. sessionTime .. "`", inline = true},
        {name = "Gold", value = "**" .. fmt(snapshot.Gold) .. "**", inline = true},
        {name = "Gems", value = "**" .. fmt(snapshot.Gem) .. "**", inline = true},
        {name = "Kills", value = "**" .. fmt(snapshot.MonsterKills) .. "**", inline = true},
        {name = "Guild Points", value = fmt(snapshot.GuildPoints), inline = true},
        {name = "Attribute Points", value = fmt(snapshot.AttributePoints), inline = true},
        {name = "Players in server", value = tostring(#Players:GetPlayers()), inline = true},
        {name = "Session gains", value = sessionGains, inline = false},
    }

    Runtime.StatsWebhookPending = true
    local stateText = isOnline and "ONLINE" or "OFFLINE"
    local started, startReason = sendDiscordWebhook(
        "Overgeared | Player Status",
        isOnline and ("🟢 **ONLINE**\nLive session overview for **" .. displayName .. "**.")
            or ("🔴 **OFFLINE**\n" .. (reason or "The player tracker is no longer running.")),
        {
            fields = fields,
            messageId = Runtime.StatsWebhookMessageId,
            footer = string.format("Overgeared Tracker · Updates every %d minute(s)",
                math.clamp(tonumber(G.WebhookIntervalMinutes) or 30, 10, 1440)),
            authorName = "OVERGEARED · LIVE SESSION",
            color = isOnline and 5763719 or 15548997,
            silentStatus = true,
            allowWhenStopped = urgent == true,
            bypassCooldown = urgent == true,
            callback = function(success, messageId, errorMessage)
                Runtime.StatsWebhookPending = false
                if success then
                    Runtime.StatsWebhookMessageId = messageId or Runtime.StatsWebhookMessageId
                    Runtime.StatsWebhookLastUpdate = os.clock()
                    StatsWebhookStatus:Set({
                        Title = "Stats Webhook | " .. stateText,
                        Content = isOnline and "Live status updated."
                            or "Offline status sent.",
                    })
                else
                    StatsWebhookStatus:Set({
                        Title = "Stats Webhook | OFFLINE",
                        Content = errorMessage or "Status update failed.",
                    })
                end
            end,
        }
    )
    if not started then
        Runtime.StatsWebhookPending = false
        StatsWebhookStatus:Set({Title = "Stats Webhook | OFFLINE", Content = startReason})
    else
        Runtime.StatsWebhookLastAttempt = os.clock()
    end
    return started, startReason
end

StatsTab:CreateToggle({
    Name = "Stats Webhook",
    CurrentValue = G.StatsWebhookEnabled,
    Flag = "MacStatsWebhookEnabled",
    Side = "Left",
    Card = "DiscordWebhook",
    Callback = function(value)
        if not value and G.StatsWebhookEnabled then
            sendStatsWebhook(false, "Stats Webhook disabled.", true)
        end
        G.StatsWebhookEnabled = value
        if value then
            StatsWebhookStatus:Set({Title = "Stats Webhook", Content = "Starting live status..."})
            task.defer(sendStatsWebhook, true)
        end
    end,
})

StatsTab:CreateButton({
    Name = "Send full status now",
    Side = "Left",
    Card = "DiscordWebhook",
    Callback = function()
        if not G.StatsWebhookEnabled then
            StatsWebhookStatus:Set({
                Title = "Stats Webhook | OFFLINE",
                Content = "Enable Stats Webhook first.",
            })
            return
        end
        StatsWebhookStatus:Set({Title = "Stats Webhook", Content = "Sending full status..."})
        sendStatsWebhook(true)
    end,
})

resetStatsBaseline()

task.spawn(function()
    while Runtime.Running do
        task.wait(5)
        local intervalSeconds = math.clamp(tonumber(G.WebhookIntervalMinutes) or 30, 10, 1440) * 60
        if Runtime.Running and G.StatsWebhookEnabled
            and (Runtime.StatsWebhookLastAttempt == 0
                or os.clock() - Runtime.StatsWebhookLastAttempt >= intervalSeconds) then
            sendStatsWebhook(true)
        end
    end
end)

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
    saveSettings()
    if G.StatsWebhookEnabled and sendStatsWebhook then
        sendStatsWebhook(false, "Script unloaded or safety shutdown triggered.", true)
    end
    Runtime.Running = false
    G.Enabled = false
    G.FarmEnabled = false
    G.BlockEnabled = false
    G.DodgeEnabled = false
    G.LegitFarmEnabled = false
    Runtime.RestockGeneration += 1
    releaseFarmFacing()
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
    if Runtime.CraftModalGui then
        Runtime.CraftModalGui:Destroy()
        Runtime.CraftModalGui = nil
    end
    pcall(function() Rayfield:Destroy() end)
end

if G.BuyMode == "Quantidade" then G.BuyMode = "Quantity" end
if G.BuyMode == "Todos" then G.BuyMode = "All" end
if G.BuyMode ~= "All" then G.BuyMode = "Quantity" end
if G.LegitFarmMode == "Parado" then G.LegitFarmMode = "Stationary" end
if G.LegitFarmMode == "Aproximar" then G.LegitFarmMode = "Approach" end
if G.LegitFarmMode ~= "Approach" then G.LegitFarmMode = "Stationary" end
pcall(function()
    BuyModeDropdown:Set({G.BuyMode})
    LegitModeDropdown:Set({G.LegitFarmMode})
end)
if G.LegitFarmEnabled and G.FarmEnabled then
    G.FarmEnabled = false
    pcall(function() FarmToggle:Set(false) end)
end

task.spawn(function()
    while Runtime.Running do
        task.wait(5)
        if Runtime.Running then saveSettings() end
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
