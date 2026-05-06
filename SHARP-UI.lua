--[[ This wont affect the script
100+ KEYLESS SCRIPTS https://discord.gg/WQKnsmpkAD
]]--

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Carregar MacLib
local MacLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/NickolasFrutuoso/MacUI/refs/heads/main/UI"))()
-- Settings
local settings = {
    silentAim = false,
    triggerBot = false,
    autoShoot = false,
    maxCharge = false,
    fov = 200,
    instantFireRate = false,
    infiniteAmmo = false,
    espEnabled = false,
    espEnemyOnly = false,
    espTeamOnly = false,
    espBoxes = true,
    espNames = true,
    espDistance = true,
    espHealth = true,
    espTracers = false,
    espMaxDistance = 1000,
    espEnemyColor = Color3.fromRGB(255, 50, 50),
    espTeamColor = Color3.fromRGB(50, 255, 50),
    fovCircle = true,
    targetHighlight = false,
    knifeTracers = false,
    knifeTracerColor = Color3.fromRGB(255, 200, 0),
    fovColor = Color3.fromRGB(255, 255, 255),
}

-- Require dos módulos do jogo
local m_GameCharacterController = require(ReplicatedStorage.Client.Controllers.GameCharacterController)
local m_CombatClient = require(ReplicatedStorage.Client.Madwork.CombatClient)
local m_BackpackClient = require(ReplicatedStorage.Client.Madwork.BackpackClient)
local m_ToolUsageClient = require(ReplicatedStorage.Client.Madwork.ToolUsageClient)
local m_MadFSM = require(ReplicatedStorage.Shared.Madwork.MadFSM)
local m_MadworkCaster = require(ReplicatedStorage.Shared.Madwork.MadworkCaster)

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

-- Utilitários
local function IsVisible(head)
    local localChar = LocalPlayer.Character
    if not localChar then return false end
    local rootPart = localChar:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    rayParams.FilterDescendantsInstances = {localChar}
    local result = workspace:Raycast(rootPart.Position, head.Position - rootPart.Position, rayParams)
    if result then
        return result.Instance:IsDescendantOf(head.Parent)
    end
    return false
end

local function GetClosestHead()
    local mousePos = UserInputService:GetMouseLocation()
    local closest = nil
    local closestDist = settings.fov
    local closestPlayer = nil
    local closestGameChar = nil

    for _, gameChar in ipairs(m_GameCharacterController.GetGameCharacters()) do
        if gameChar.Player == LocalPlayer then continue end
        if gameChar.GamePlayer:GetLocalRelationship() ~= "Enemy" then continue end
        local char = gameChar.Character
        if not char or not char.IsAlive then continue end
        local model = char.Model
        local head = model:FindFirstChild("Head")
        local humanoid = model:FindFirstChild("Humanoid")
        if head and humanoid and humanoid.Health > 0 then
            local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = head
                    closestPlayer = gameChar.Player
                    closestGameChar = gameChar
                end
            end
        end
    end
    return closest, closestPlayer, closestGameChar
end

-- Silent Aim
m_CombatClient.OnLocalEvent:Connect(function(combatEvent)
    if not settings.silentAim then return end
    local head = GetClosestHead()
    if not head then return end
    local throwPos = combatEvent.GameAction.Position
    combatEvent.GameAction.Direction = (head.Position - throwPos).Unit
    if settings.maxCharge then
        combatEvent.GameAction.Charge = 1
    end
end)

-- Infinite Ammo
local useClipHooked = false
local function HookUseClip()
    if useClipHooked then return end
    local upvalues = getupvalues(m_ToolUsageClient.NewToolUsage)
    for i, v in pairs(upvalues) do
        if type(v) == "table" and v.UseClip ~= nil then
            local original_UseClip = v.UseClip
            v.UseClip = function(self)
                if settings.infiniteAmmo then
                    self.Clip = self.Clip + 1
                end
                return original_UseClip(self)
            end
            useClipHooked = true
            break
        end
    end
end
HookUseClip()

-- FSM
local patched = {}

local function PatchFSM(fsm)
    if not fsm or not fsm._states then return end
    for name, state in pairs(fsm._states) do
        if name == "Fire" or name == "Throw" or name == "Reload" then
            state.Duration = 0
            state.Leaving = nil
            state.Entering = nil
        end
    end
end

local function GetAllTools()
    local tools = {}
    local upvals = getupvalues(m_BackpackClient.GetToolById)
    for i, v in pairs(upvals) do
        if type(v) == "table" then
            for id, tool in pairs(v) do
                if type(tool) == "table" and tool.Store then
                    table.insert(tools, tool)
                end
            end
        end
    end
    return tools
end

local function IsKnifeTool(tool)
    return tool.Setup and tool.Setup.ToolBehaviour == "Knife"
end

-- Hook FSM creation
local orig = m_MadFSM.NewMadFSM
m_MadFSM.NewMadFSM = function()
    local fsm = orig()
    local origDef = fsm.DefineStates
    fsm.DefineStates = function(self, states)
        for _, name in ipairs({"Fire", "Throw", "Reload"}) do
            if states[name] and settings.instantFireRate then
                states[name].Duration = 0
                states[name].Leaving = nil
                states[name].Entering = nil
            end
        end
        return origDef(self, states)
    end
    return fsm
end

task.spawn(function()
    while true do
        task.wait(0.1)
        for _, tool in ipairs(GetAllTools()) do
            local fsm = tool.Store.FSM
            if fsm then
                if not patched[fsm] then
                    patched[fsm] = true
                    PatchFSM(fsm)
                end
                if settings.instantFireRate then
                    if fsm.State == "Fire" or fsm.State == "Throw" or fsm.State == "Reload" then
                        fsm.Progress = 1
                        fsm.Duration = 0
                        fsm.StartTime = 0
                    end
                end
            end
        end
    end
end)

local function TryFire()
    for _, tool in ipairs(GetAllTools()) do
        if tool.Equipped and tool.Store.FSM and IsKnifeTool(tool) then
            local fsm = tool.Store.FSM
            if fsm.State == "Idle" or fsm.State == "Throw" or fsm.State == "Fire" then
                fsm:Set("Throw")
            end
        end
    end
end

task.spawn(function()
    while true do
        task.wait(0.05)
        if settings.triggerBot then
            local head = GetClosestHead()
            if head and IsVisible(head) then
                TryFire()
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.05)
        if settings.autoShoot then
            local head = GetClosestHead()
            if head then
                TryFire()
            end
        end
    end
end)

-- Drawing objects
local espObjects = {}
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1
fovCircle.Color = Color3.fromRGB(255, 255, 255)
fovCircle.Filled = false
fovCircle.Transparency = 0.8
fovCircle.NumSides = 64
fovCircle.Visible = false

local currentHighlight = nil
local lastTarget = nil

local function ClearHighlight()
    if currentHighlight then
        currentHighlight:Destroy()
        currentHighlight = nil
    end
    lastTarget = nil
end

local function ApplyHighlight(model)
    if lastTarget == model then return end
    ClearHighlight()
    local h = Instance.new("Highlight")
    h.FillColor = Color3.fromRGB(255, 50, 50)
    h.OutlineColor = Color3.fromRGB(255, 255, 255)
    h.FillTransparency = 0.5
    h.OutlineTransparency = 0
    h.Adornee = model
    h.Parent = model
    currentHighlight = h
    lastTarget = model
end

local function NewDrawing(type, props)
    local d = Drawing.new(type)
    for k, v in pairs(props) do
        d[k] = v
    end
    return d
end

local function CreateESPForChar(gameChar)
    if gameChar.Player == LocalPlayer then return end
    if espObjects[gameChar] then return end
    local box = NewDrawing("Square", {Thickness = 1, Filled = false, Visible = false})
    local boxOutline = NewDrawing("Square", {Thickness = 3, Color = Color3.fromRGB(0,0,0), Filled = false, Visible = false})
    local healthBarBg = NewDrawing("Square", {Thickness = 0, Color = Color3.fromRGB(0,0,0), Filled = true, Visible = false})
    local healthBar = NewDrawing("Square", {Thickness = 0, Filled = true, Visible = false})
    local label = NewDrawing("Text", {Size = 13, Center = true, Outline = true, Font = Drawing.Fonts.GothamBold, Visible = false})
    local tracer = NewDrawing("Line", {Thickness = 1, Visible = false})
    espObjects[gameChar] = {box = box, boxOutline = boxOutline, healthBarBg = healthBarBg, healthBar = healthBar, label = label, tracer = tracer}
end

local function RemoveESPForChar(gameChar)
    local esp = espObjects[gameChar]
    if not esp then return end
    for _, d in pairs(esp) do d:Remove() end
    espObjects[gameChar] = nil
end

local function GetCharColor(gameChar)
    local rel = gameChar.GamePlayer:GetLocalRelationship()
    return rel == "Enemy" and settings.espEnemyColor or settings.espTeamColor
end

local function ShouldShowESP(gameChar)
    if not settings.espEnabled then return false end
    local rel = gameChar.GamePlayer:GetLocalRelationship()
    if settings.espEnemyOnly and rel ~= "Enemy" then return false end
    if settings.espTeamOnly and rel ~= "Friendly" then return false end
    local localChar = LocalPlayer.Character
    if localChar and localChar:FindFirstChild("HumanoidRootPart") then
        local rootPart = gameChar.Character and gameChar.Character.RootPart
        if rootPart then
            local dist = (rootPart.Position - localChar.HumanoidRootPart.Position).Magnitude
            if dist > settings.espMaxDistance then return false end
        end
    end
    return true
end

for _, gameChar in ipairs(m_GameCharacterController.GetGameCharacters()) do CreateESPForChar(gameChar) end
m_GameCharacterController.GameCharacterAdded:Connect(CreateESPForChar)

-- Knife Tracers
local original_NewCaster = m_MadworkCaster.NewCaster
m_MadworkCaster.NewCaster = function(params)
    local caster = original_NewCaster(params)
    if settings.knifeTracers then
        local line = Drawing.new("Line")
        line.Thickness = 2
        line.Color = settings.knifeTracerColor
        line.Transparency = 0.3
        line.Visible = false
        local startPos = params.Position
        caster:OnUpdate(function()
            if not settings.knifeTracers then line.Visible = false return end
            local s, on1 = Camera:WorldToViewportPoint(startPos)
            local e, on2 = Camera:WorldToViewportPoint(caster.Position)
            line.From = Vector2.new(s.X, s.Y)
            line.To = Vector2.new(e.X, e.Y)
            line.Visible = on1 and on2
        end)
        caster:OnSolve(function() line:Remove() end)
    end
    return caster
end

-- Render loop
RunService.Heartbeat:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()
    local viewportSize = Camera.ViewportSize
    local localChar = LocalPlayer.Character
    local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")

    -- FOV Circle
    fovCircle.Position = mousePos
    fovCircle.Radius = settings.fov
    fovCircle.Visible = settings.fovCircle

    -- Target Highlight
    if settings.targetHighlight then
        local head, _, gameChar = GetClosestHead()
        if gameChar and gameChar.Character and gameChar.Character.IsAlive then
            ApplyHighlight(gameChar.Character.Model)
        else
            ClearHighlight()
        end
    else
        ClearHighlight()
    end

    -- ESP
    for gameChar, esp in pairs(espObjects) do
        local show = ShouldShowESP(gameChar)
        local char = gameChar.Character
        local alive = char and char.IsAlive
        if not show or not alive then
            for _, d in pairs(esp) do d.Visible = false end
            continue
        end
        local model = char.Model
        local rootPart = model:FindFirstChild("HumanoidRootPart")
        local headPart = model:FindFirstChild("Head")
        local humanoid = model:FindFirstChild("Humanoid")
        if not rootPart or not headPart then
            for _, d in pairs(esp) do d.Visible = false end
            continue
        end
        local topWorld = headPart.Position + Vector3.new(0, headPart.Size.Y / 2, 0)
        local botWorld = rootPart.Position - Vector3.new(0, 3.5, 0)
        local topScreen, onScreen1 = Camera:WorldToViewportPoint(topWorld)
        local botScreen, onScreen2 = Camera:WorldToViewportPoint(botWorld)
        if not onScreen1 or not onScreen2 then
            for _, d in pairs(esp) do d.Visible = false end
            continue
        end
        local color = GetCharColor(gameChar)
        local hp = gameChar.DamageReceiver and gameChar.DamageReceiver.Health or 0
        local maxHp = gameChar.DamageReceiver and gameChar.DamageReceiver.MaxHealth or 100
        local hpFrac = math.clamp(hp / maxHp, 0, 1)
        local hpColor = Color3.fromRGB(255 * (1 - hpFrac), 255 * hpFrac, 0)
        local height = math.abs(topScreen.Y - botScreen.Y)
        local width = height * 0.5
        local boxX = topScreen.X - width / 2
        local boxY = topScreen.Y
        local dist = localRoot and math.floor((rootPart.Position - localRoot.Position).Magnitude) or 0
        local labelParts = {}
        if settings.espNames then table.insert(labelParts, gameChar.Player.Name) end
        if settings.espDistance then table.insert(labelParts, dist .. "m") end
        if settings.espHealth then table.insert(labelParts, math.floor(hp) .. "hp") end
        esp.label.Text = table.concat(labelParts, " | ")
        esp.label.Position = Vector2.new(topScreen.X, boxY - 18)
        esp.label.Color = color
        esp.label.Visible = #labelParts > 0
        if settings.espBoxes then
            esp.boxOutline.Size = Vector2.new(width + 2, height + 2)
            esp.boxOutline.Position = Vector2.new(boxX - 1, boxY - 1)
            esp.boxOutline.Visible = true
            esp.box.Size = Vector2.new(width, height)
            esp.box.Position = Vector2.new(boxX, boxY)
            esp.box.Color = color
            esp.box.Visible = true
        else
            esp.box.Visible = false
            esp.boxOutline.Visible = false
        end
        local barX = boxX - 6
        esp.healthBarBg.Size = Vector2.new(4, height)
        esp.healthBarBg.Position = Vector2.new(barX, boxY)
        esp.healthBarBg.Visible = settings.espHealth
        local barH = height * hpFrac
        esp.healthBar.Size = Vector2.new(4, barH)
        esp.healthBar.Position = Vector2.new(barX, boxY + (height - barH))
        esp.healthBar.Color = hpColor
        esp.healthBar.Visible = settings.espHealth
        if settings.espTracers then
            esp.tracer.From = Vector2.new(viewportSize.X / 2, viewportSize.Y)
            esp.tracer.To = Vector2.new(botScreen.X, botScreen.Y)
            esp.tracer.Color = color
            esp.tracer.Visible = true
        else
            esp.tracer.Visible = false
        end
    end
end)

-- ============================================
-- INTERFACE MACLIB
-- ============================================
local HUB = MacLib:CreateHUB({
    Title    = "SHARP",
    Subtitle = "Knife Skill",
    OnTabGroup = function(TabGroup, Window)
        -- Aba Combat
        local CombatTab = TabGroup:Tab({ Name = "Combat" })
        local AimbotSection = CombatTab:Section({ Side = "Left" })
        local CombatSection = CombatTab:Section({ Side = "Right" })

        AimbotSection:Header({ Name = "Aimbot" })
        AimbotSection:Toggle({
            Name = "Silent Aim",
            Default = settings.silentAim,
            Callback = function(v) settings.silentAim = v end
        }, "SilentAim")
        AimbotSection:Toggle({
            Name = "Triggerbot (Knife)",
            Default = settings.triggerBot,
            Callback = function(v) settings.triggerBot = v end
        }, "TriggerBot")
        AimbotSection:Toggle({
            Name = "Auto Shoot (Knife)",
            Default = settings.autoShoot,
            Callback = function(v) settings.autoShoot = v end
        }, "AutoShoot")
        AimbotSection:Toggle({
            Name = "Max Charge",
            Default = settings.maxCharge,
            Callback = function(v) settings.maxCharge = v end
        }, "MaxCharge")
        AimbotSection:Slider({
            Name = "FOV",
            Minimum = 50,
            Maximum = 600,
            Default = settings.fov,
            Callback = function(v) settings.fov = v end
        }, "FOV")

        CombatSection:Header({ Name = "Combat" })
        CombatSection:Toggle({
            Name = "Instant Fire Rate",
            Default = settings.instantFireRate,
            Callback = function(v)
                settings.instantFireRate = v
                if v then patched = {} end
            end
        }, "InstantFireRate")
        CombatSection:Toggle({
            Name = "Infinite Ammo",
            Default = settings.infiniteAmmo,
            Callback = function(v) settings.infiniteAmmo = v end
        }, "InfiniteAmmo")
        CombatSection:Button({
            Name = "Throw At Target",
            Callback = TryFire
        })

        -- Aba Visuals
        local VisualTab = TabGroup:Tab({ Name = "Visuals" })
        local EspMain = VisualTab:Section({ Side = "Left" })
        local EspToggles = VisualTab:Section({ Side = "Right" })
        local EspColors = VisualTab:Section({ Side = "Left" })
        local World = VisualTab:Section({ Side = "Right" })

        EspMain:Header({ Name = "ESP" })
        EspMain:Toggle({
            Name = "Enable ESP",
            Default = settings.espEnabled,
            Callback = function(v) settings.espEnabled = v end
        }, "EspEnabled")
        EspMain:Toggle({
            Name = "Enemy Only",
            Default = settings.espEnemyOnly,
            Callback = function(v)
                settings.espEnemyOnly = v
                if v then settings.espTeamOnly = false end
            end
        }, "EspEnemyOnly")
        EspMain:Toggle({
            Name = "Team Only",
            Default = settings.espTeamOnly,
            Callback = function(v)
                settings.espTeamOnly = v
                if v then settings.espEnemyOnly = false end
            end
        }, "EspTeamOnly")
        EspMain:Slider({
            Name = "Max Distance",
            Minimum = 50,
            Maximum = 2000,
            Default = settings.espMaxDistance,
            Callback = function(v) settings.espMaxDistance = v end
        }, "EspMaxDistance")

        EspToggles:Header({ Name = "Elements" })
        EspToggles:Toggle({
            Name = "Boxes",
            Default = settings.espBoxes,
            Callback = function(v) settings.espBoxes = v end
        }, "EspBoxes")
        EspToggles:Toggle({
            Name = "Names",
            Default = settings.espNames,
            Callback = function(v) settings.espNames = v end
        }, "EspNames")
        EspToggles:Toggle({
            Name = "Distance",
            Default = settings.espDistance,
            Callback = function(v) settings.espDistance = v end
        }, "EspDistance")
        EspToggles:Toggle({
            Name = "Health",
            Default = settings.espHealth,
            Callback = function(v) settings.espHealth = v end
        }, "EspHealth")
        EspToggles:Toggle({
            Name = "Tracers",
            Default = settings.espTracers,
            Callback = function(v) settings.espTracers = v end
        }, "EspTracers")

        EspColors:Header({ Name = "Colors" })
        EspColors:Colorpicker({
            Name = "Enemy Color",
            Default = settings.espEnemyColor,
            Callback = function(v) settings.espEnemyColor = v end
        }, "EspEnemyColor")
        EspColors:Colorpicker({
            Name = "Team Color",
            Default = settings.espTeamColor,
            Callback = function(v) settings.espTeamColor = v end
        }, "EspTeamColor")

        World:Header({ Name = "World" })
        World:Toggle({
            Name = "FOV Circle",
            Default = settings.fovCircle,
            Callback = function(v) settings.fovCircle = v end
        }, "FovCircle")
        World:Colorpicker({
            Name = "FOV Color",
            Default = settings.fovColor,
            Callback = function(v)
                settings.fovColor = v
                fovCircle.Color = v
            end
        }, "FovColor")
        World:Toggle({
            Name = "Target Highlight",
            Default = settings.targetHighlight,
            Callback = function(v)
                settings.targetHighlight = v
                if not v then ClearHighlight() end
            end
        }, "TargetHighlight")
        World:Toggle({
            Name = "Knife Tracers",
            Default = settings.knifeTracers,
            Callback = function(v) settings.knifeTracers = v end
        }, "KnifeTracers")
        World:Colorpicker({
            Name = "Tracer Color",
            Default = settings.knifeTracerColor,
            Callback = function(v) settings.knifeTracerColor = v end
        }, "KnifeTracerColor")
    end,
})
