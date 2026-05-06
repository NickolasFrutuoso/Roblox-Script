-- =============================================================
--  Noliar Hub - ONE TAP CHEAT
--  Complete with Silent Aim, Aimbot, Triggerbot & ESP
--  UI powered by MacLib
-- =============================================================

-- Load MacLib UI Library
local MacLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/NickolasFrutuoso/MacUI/refs/heads/main/UI"))()

-- ============== SERVICES ==============
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Camera = Workspace.CurrentCamera
local VirtualInputManager = game:GetService("VirtualInputManager")
local Teams = game:GetService("Teams")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer
local Common = ReplicatedStorage and ReplicatedStorage:FindFirstChild("Common")

-- ============== CONFIG TABLE (holds all runtime state) ==============
local Settings = {
    -- Aimbot
    Aimbot = false,
    AimbotKey = "MouseButton2",
    AimbotSmoothness = 0.18,
    AimbotFOV = 200,
    AimbotHitbox = "Head",
    AimbotVisibleCheck = false,
    AimbotWallCheck = false,        -- NEW: wall check for silent aim
    
    -- Silent Aim
    SilentAim = false,
    SilentAimSmooth = false,        -- NEW: smooth snap for silent aim
    SilentAimSmoothness = 0.15,
    
    -- ESP
    ESP = false,
    ESPColor = Color3.fromRGB(255, 50, 50),
    ESPShowHealth = true,
    ESPShowDistance = true,
    ESPShowName = true,
    ESPBox = true,
    
    -- Triggerbot
    TriggerBot = false,
    TriggerKey = "MouseButton1",
    TriggerDelay = 0.001,
    
    -- Weapon Mods
    InfiniteAmmo = false,
    FastFireRate = false,
    InfiniteDamage = false,
    BulletSpeedMultiplier = 3,
    MaxDistance = 9999,
}

local aimbotActive = false
local triggerActive = false
local ESPObjects = {}

-- ============== GET ALL TARGETS (Players + Bots) ==============
local function GetAllTargets()
    local targets = {}
    
    -- Players
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end
        local hum = char:FindFirstChild("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        table.insert(targets, {
            Type = "Player",
            Player = player,
            Character = char,
            Humanoid = hum
        })
    end
    
    -- Bots / NPCs
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= LocalPlayer.Character then
            local isPlayer = Players:GetPlayerFromCharacter(obj)
            if isPlayer then continue end
            
            local hum = obj:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local name = obj.Name or ""
                local isBot = name:match("[Nn][Pp][Cc]")
                    or name:match("[Bb][Oo][Tt]")
                    or name:match("Dummy")
                    or name:match("Target")
                    or name:match("Enemy")
                    or name:match("Zombie")
                    or obj:FindFirstChild("Head") ~= nil
                
                if isBot or hum.MaxHealth > 100 or hum.MaxHealth < 100 then
                    local alreadyAdded = false
                    for _, t in ipairs(targets) do
                        if t.Character == obj then alreadyAdded = true break end
                    end
                    if not alreadyAdded then
                        table.insert(targets, {
                            Type = "Bot",
                            Player = nil,
                            Character = obj,
                            Humanoid = hum
                        })
                    end
                end
            end
        end
    end
    
    -- NPC folders
    local npcFolder = Workspace:FindFirstChild("NPCs") or Workspace:FindFirstChild("Bots")
        or Workspace:FindFirstChild("Enemies")
    if npcFolder then
        for _, npc in ipairs(npcFolder:GetDescendants()) do
            if npc:IsA("Model") then
                local hum = npc:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    local alreadyAdded = false
                    for _, t in ipairs(targets) do
                        if t.Character == npc then alreadyAdded = true break end
                    end
                    if not alreadyAdded then
                        table.insert(targets, {
                            Type = "Bot",
                            Player = nil,
                            Character = npc,
                            Humanoid = hum
                        })
                    end
                end
            end
        end
    end
    
    return targets
end

-- ============== TARGET PART RESOLVER ==============
local function GetTargetPart(target)
    local char = target.Character
    return char:FindFirstChild(Settings.AimbotHitbox)
        or char:FindFirstChild("Head")
        or char:FindFirstChild("HumanoidRootPart")
        or char:FindFirstChild("Torso")
        or char:FindFirstChild("UpperTorso")
end

-- ============== WEAPON HOOOKS ==============
local function ApplyWeaponHooks()
    if not Common then return end
    
    local WeaponManager = Common:FindFirstChild("Managers") and require(Common.Managers.WeaponManager)
    if not WeaponManager then
        local mgr = Common:FindFirstChild("WeaponManager") or Common:FindFirstChild("GunManager")
        if mgr then
            WeaponManager = require(mgr)
        end
    end
    
    if WeaponManager then
        local WeaponsData = rawget(WeaponManager, "_Weapons") or rawget(WeaponManager, "Weapons")
        local Constants = rawget(WeaponManager, "Constants")
        
        if Constants then
            if Settings.InfiniteAmmo then Constants.DEFAULT_MAGAZINE = 9999 end
            if Settings.FastFireRate then Constants.DEFAULT_FIRERATE = 100 end
            if Settings.InfiniteDamage then Constants.DEFAULT_DAMAGE = 1000 end
            Constants.DEFAULT_MAX_DISTANCE = Settings.MaxDistance
            
            if Settings.BulletSpeedMultiplier > 1 then
                Constants.DEFAULT_SPEED = (Constants.DEFAULT_SPEED or 500) * Settings.BulletSpeedMultiplier
            end
        end
        
        if WeaponsData then
            for _, weaponData in pairs(WeaponsData) do
                if type(weaponData) == "table" then
                    if Settings.InfiniteAmmo then weaponData.magazine = 9999 end
                    if Settings.FastFireRate then weaponData.firerate = 100 end
                    if Settings.InfiniteDamage then weaponData.damage = 1000 end
                end
            end
        end
        
        local oldGet = WeaponManager.getWeaponData
        if oldGet then
            WeaponManager.getWeaponData = function(self, weaponName)
                local data = oldGet(self, weaponName)
                if data then
                    if Settings.InfiniteAmmo then data.magazine = 9999 end
                    if Settings.FastFireRate then data.firerate = 100 end
                    if Settings.InfiniteDamage then data.damage = 1000 end
                end
                return data
            end
        end
    end
    
    -- FastCastRedux hook
    local FastCast = Common:FindFirstChild("Components") and Common.Components:FindFirstChild("FastCastRedux")
        or Common:FindFirstChild("FastCastRedux")
    if FastCast then
        local FastCastModule = require(FastCast)
        local oldNewBehavior = FastCastModule.newBehavior
        if oldNewBehavior then
            FastCastModule.newBehavior = function()
                local behavior = oldNewBehavior()
                if behavior then
                    behavior.MaxDistance = Settings.MaxDistance
                end
                return behavior
            end
        end
        
        local oldFire = FastCastModule.Fire
        if oldFire then
            FastCastModule.Fire = function(self, origin, direction, velocity, behavior, ...)
                if not behavior then
                    behavior = FastCastModule.newBehavior()
                end
                if Settings.BulletSpeedMultiplier > 1 then
                    velocity = velocity * Settings.BulletSpeedMultiplier
                end
                return oldFire(self, origin, direction, velocity, behavior, ...)
            end
        end
    end
end

-- ============== SILENT AIM ==============
local function SetupSilentAim()
    if not Common then return end
    
    local ByteNetReliable = ReplicatedStorage:FindFirstChild("ByteNetReliable")
        or Common:FindFirstChild("ByteNetReliable")
    
    if not ByteNetReliable then
        -- Try to find the fire event in ReplicatedStorage
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteEvent") and (obj.Name:match("[Ss]hoot") or obj.Name:match("[Ff]ire") or obj.Name:match("[Rr]eplicate")) then
                ByteNetReliable = obj
                break
            end
        end
    end
    
    if ByteNetReliable and ByteNetReliable.IsA and ByteNetReliable:IsA("RemoteEvent") then
        local oldFireServer
        oldFireServer = hookfunction(ByteNetReliable.FireServer, function(self, ...)
            local args = {...}
            
            if Settings.SilentAim then
                local target = GetClosestTarget()
                
                if target then
                    local targetPart = GetTargetPart(target)
                    
                    if targetPart then
                        -- Wall check for silent aim
                        if not Settings.AimbotWallCheck then
                            local ray = Ray.new(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position).Unit * 1000)
                            local hit, pos = Workspace:FindPartOnRay(ray, LocalPlayer.Character)
                            if hit then
                                local hitModel = hit:FindFirstAncestorWhichIsA("Model")
                                if hitModel ~= target.Character then
                                    -- Wall blocking, skip silent aim modification
                                    return oldFireServer(self, ...)
                                end
                            end
                        end
                        
                        -- Apply smoothness to silent aim if enabled
                        if Settings.SilentAimSmooth then
                            -- Modify hit position with slight randomness for smoothness
                            local smoothFactor = Settings.SilentAimSmoothness
                            local offsetX = (math.random() - 0.5) * smoothFactor * 2
                            local offsetY = (math.random() - 0.5) * smoothFactor * 2
                            local offsetZ = (math.random() - 0.5) * smoothFactor * 2
                            local modifiedPos = targetPart.Position + Vector3.new(offsetX, offsetY, offsetZ)
                            
                            -- Try to modify the args if they contain position data
                            for i, arg in ipairs(args) do
                                if typeof(arg) == "Vector3" then
                                    args[i] = modifiedPos
                                end
                            end
                            
                            return oldFireServer(self, table.unpack(args))
                        else
                            -- Direct snap to target
                            for i, arg in ipairs(args) do
                                if typeof(arg) == "Vector3" then
                                    args[i] = targetPart.Position
                                end
                            end
                            
                            return oldFireServer(self, table.unpack(args))
                        end
                    end
                end
            end
            
            return oldFireServer(self, ...)
        end)
        
        print("[Noliar Hub] ✅ Silent Aim hook active!")
    else
        -- Try buffer-based ByteNet
        if ByteNetReliable and typeof(ByteNetReliable.FireServer) == "function" then
            local oldFireServer
            oldFireServer = hookfunction(ByteNetReliable.FireServer, function(self, buffer, refs, ...)
                if Settings.SilentAim and buffer and typeof(buffer) == "buffer" and buffer.len(buffer) > 5 then
                    local target = GetClosestTarget()
                    
                    if target then
                        local targetPart = GetTargetPart(target)
                        
                        if targetPart then
                            -- Wall check
                            if not Settings.AimbotWallCheck then
                                local ray = Ray.new(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position).Unit * 1000)
                                local hit, pos = Workspace:FindPartOnRay(ray, LocalPlayer.Character)
                                if hit then
                                    local hitModel = hit:FindFirstAncestorWhichIsA("Model")
                                    if hitModel ~= target.Character then
                                        return oldFireServer(self, buffer, refs, ...)
                                    end
                                end
                            end
                            
                            local bufLen = buffer.len(buffer)
                            local offset = 1  -- skip packetID
                            offset = offset + 1  -- skip shooter ref
                            
                            if bufLen > offset then
                                local hasInstance = buffer.readu8(buffer, offset)
                                offset = offset + 1
                                if hasInstance == 1 then
                                    offset = offset + 1
                                end
                            end
                            
                            if bufLen >= offset + 12 then
                                local targetPos = targetPart.Position
                                
                                if Settings.SilentAimSmooth then
                                    local smoothFactor = Settings.SilentAimSmoothness
                                    targetPos = targetPos + Vector3.new(
                                        (math.random() - 0.5) * smoothFactor * 2,
                                        (math.random() - 0.5) * smoothFactor * 2,
                                        (math.random() - 0.5) * smoothFactor * 2
                                    )
                                end
                                
                                buffer.writef32(buffer, offset, targetPos.X)
                                buffer.writef32(buffer, offset + 4, targetPos.Y)
                                buffer.writef32(buffer, offset + 8, targetPos.Z)
                            end
                        end
                    end
                end
                
                return oldFireServer(self, buffer, refs, ...)
            end)
            
            print("[Noliar Hub] ✅ Silent Aim (ByteNet) hook active!")
        end
    end
end

-- ============== AIMBOT LOGIC ==============
local function GetClosestTarget()
    local closest = nil
    local closestDist = Settings.AimbotFOV
    local mousePos = UserInputService:GetMouseLocation()
    
    local allTargets = GetAllTargets()
    
    for _, target in ipairs(allTargets) do
        local part = GetTargetPart(target)
        if not part then continue end
        
        -- Visibility check
        if Settings.AimbotVisibleCheck then
            local ray = Ray.new(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 1000)
            local hit, pos = Workspace:FindPartOnRay(ray, LocalPlayer.Character)
            if hit then
                local hitModel = hit:FindFirstAncestorWhichIsA("Model")
                if hitModel ~= target.Character then
                    if not Settings.AimbotWallCheck then
                        continue
                    end
                end
            end
        end
        
        local sp, onScr = Camera:WorldToViewportPoint(part.Position)
        if not onScr then continue end
        
        local dist = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
        if dist < closestDist then
            closestDist = dist
            closest = target
        end
    end
    
    return closest
end

-- ============== AIMBOT KEYBINDS ==============
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        if Settings.AimbotKey == "MouseButton2" and Settings.Aimbot then
            aimbotActive = true
        end
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        if Settings.AimbotKey == "MouseButton1" and Settings.Aimbot then
            aimbotActive = true
        end
        if Settings.TriggerBot and Settings.TriggerKey == "MouseButton1" then
            triggerActive = true
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aimbotActive = false
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        aimbotActive = false
        triggerActive = false
    end
end)

-- ============== TRIGGERBOT ==============
local function GetTargetUnderCrosshair()
    local mp = UserInputService:GetMouseLocation()
    local ray = Camera:ScreenPointToRay(mp.X, mp.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {LocalPlayer.Character or {}}
    
    local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
    if result then
        local hitModel = result.Instance:FindFirstAncestorWhichIsA("Model")
        if hitModel then
            local hitPlayer = Players:GetPlayerFromCharacter(hitModel)
            if hitPlayer and hitPlayer ~= LocalPlayer then
                return hitPlayer.Character
            end
            local hum = hitModel:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 and hitModel ~= LocalPlayer.Character then
                return hitModel
            end
        end
    end
    return nil
end

-- ============== ESP ==============
local function NewESP(target)
    local labelText = Drawing.new("Text")
    labelText.Visible = false
    labelText.Center = true
    labelText.Size = 16
    labelText.Outline = true
    labelText.OutlineColor = Color3.fromRGB(0, 0, 0)
    labelText.Color = Settings.ESPColor
    
    local box = Drawing.new("Square")
    box.Visible = false
    box.Thickness = 1
    box.Color = Settings.ESPColor
    box.Transparency = 0.8
    
    local healthBar = Drawing.new("Square")
    healthBar.Visible = false
    healthBar.Thickness = 1
    healthBar.Color = Color3.fromRGB(0, 255, 0)
    healthBar.Filled = true
    healthBar.Transparency = 0.5
    
    ESPObjects[target.Character] = { Text = labelText, Box = box, Health = healthBar, Target = target }
end

local function RemoveESP(char)
    if ESPObjects[char] then
        pcall(function()
            ESPObjects[char].Text:Remove()
            ESPObjects[char].Box:Remove()
            ESPObjects[char].Health:Remove()
        end)
        ESPObjects[char] = nil
    end
end

local function RefreshESP()
    for char, _ in pairs(ESPObjects) do
        local stillExists = false
        for _, target in ipairs(GetAllTargets()) do
            if target.Character == char then
                stillExists = true
                ESPObjects[char].Target = target
                break
            end
        end
        if not stillExists then
            RemoveESP(char)
        end
    end
    
    for _, target in ipairs(GetAllTargets()) do
        if not ESPObjects[target.Character] then
            NewESP(target)
        end
    end
end

task.spawn(function()
    while task.wait(1) do
        RefreshESP()
    end
end)

Players.PlayerRemoving:Connect(function(p)
    if p.Character then
        RemoveESP(p.Character)
    end
end)

-- ============== UI SETUP ==============
local HUB = MacLib:CreateHUB({
    Title = "Noliar Hub",
    Subtitle = "One Tap Cheat",
    OnTabGroup = function(TabGroup, Window)
        
        -- ====== AIMBOT TAB ======
        local AimbotTab = TabGroup:Tab({ Name = "Aimbot", Image = "rbxassetid://10734950309" })
        
        -- Main Aimbot Section
        local aimSection = AimbotTab:Section({ Side = "Left" })
        aimSection:Header({ Name = "Aimbot Settings" })
        
        aimSection:Toggle({
            Name = "Aimbot",
            Default = false,
            Callback = function(state)
                Settings.Aimbot = state
            end,
        }, "AimbotEnabled")
        
        aimSection:Dropdown({
            Name = "Activation Key",
            Options = {"MouseButton2", "MouseButton1"},
            Default = 1,
            Callback = function(value)
                Settings.AimbotKey = value
            end,
        }, "AimbotKey")
        
        aimSection:Dropdown({
            Name = "Hitbox",
            Options = {"Head", "HumanoidRootPart", "Torso", "UpperTorso"},
            Default = 1,
            Callback = function(value)
                Settings.AimbotHitbox = value
            end,
        }, "AimbotHitbox")
        
        aimSection:Slider({
            Name = "Smoothness",
            Minimum = 0.01,
            Maximum = 1,
            Default = 0.18,
            Precision = 2,
            DisplayMethod = "Hundredths",
            Callback = function(value)
                Settings.AimbotSmoothness = value
            end,
        }, "AimbotSmoothness")
        
        aimSection:Slider({
            Name = "FOV",
            Minimum = 10,
            Maximum = 1000,
            Default = 200,
            DisplayMethod = "Value",
            Suffix = "px",
            Callback = function(value)
                Settings.AimbotFOV = value
            end,
        }, "AimbotFOV")
        
        -- Checks Section
        local checkSection = AimbotTab:Section({ Side = "Right" })
        checkSection:Header({ Name = "Visibility & Checks" })
        
        checkSection:Toggle({
            Name = "Line of Sight Check",
            Default = false,
            Callback = function(state)
                Settings.AimbotVisibleCheck = state
            end,
        }, "AimbotVisibleCheck")
        
        checkSection:Toggle({
            Name = "Wall Check (Silent Aim)",
            Default = false,
            Callback = function(state)
                Settings.AimbotWallCheck = state
            end,
        }, "AimbotWallCheck")
        
        -- Silent Aim Section
        local silentSection = AimbotTab:Section({ Side = "Right" })
        silentSection:Header({ Name = "Silent Aim" })
        
        silentSection:Toggle({
            Name = "Silent Aim",
            Default = false,
            Callback = function(state)
                Settings.SilentAim = state
            end,
        }, "SilentAimEnabled")
        
        silentSection:Toggle({
            Name = "Silent Aim Smoothing",
            Default = false,
            Callback = function(state)
                Settings.SilentAimSmooth = state
                if state then
                    silentSmoothSlider:SetVisibility(true)
                else
                    silentSmoothSlider:SetVisibility(false)
                end
            end,
        }, "SilentAimSmooth")
        
        local silentSmoothSlider = silentSection:Slider({
            Name = "Smooth Factor",
            Minimum = 0.01,
            Maximum = 1,
            Default = 0.15,
            Precision = 2,
            DisplayMethod = "Hundredths",
            Visible = false,
            Callback = function(value)
                Settings.SilentAimSmoothness = value
            end,
        }, "SilentAimSmoothness")
        
        -- Triggerbot Section
        local triggerSection = AimbotTab:Section({ Side = "Left" })
        triggerSection:Header({ Name = "Trigger Bot" })
        
        triggerSection:Toggle({
            Name = "Trigger Bot",
            Default = false,
            Callback = function(state)
                Settings.TriggerBot = state
            end,
        }, "TriggerBotEnabled")
        
        triggerSection:Dropdown({
            Name = "Trigger Key",
            Options = {"MouseButton1", "MouseButton2"},
            Default = 1,
            Callback = function(value)
                Settings.TriggerKey = value
            end,
        }, "TriggerBotKey")
        
        triggerSection:Slider({
            Name = "Trigger Delay (s)",
            Minimum = 0.001,
            Maximum = 0.5,
            Default = 0.001,
            Precision = 3,
            DisplayMethod = "Thousandths",
            Suffix = "s",
            Callback = function(value)
                Settings.TriggerDelay = value
            end,
        }, "TriggerBotDelay")
        
        -- ====== ESP TAB ======
        local ESPTab = TabGroup:Tab({ Name = "ESP", Image = "rbxassetid://10734950309" })
        
        local espMain = ESPTab:Section({ Side = "Left" })
        espMain:Header({ Name = "ESP Settings" })
        
        espMain:Toggle({
            Name = "ESP",
            Default = false,
            Callback = function(state)
                Settings.ESP = state
            end,
        }, "ESPEnabled")
        
        espMain:Toggle({
            Name = "Show Name",
            Default = true,
            Callback = function(state)
                Settings.ESPShowName = state
            end,
        }, "ESPShowName")
        
        espMain:Toggle({
            Name = "Show Health",
            Default = true,
            Callback = function(state)
                Settings.ESPShowHealth = state
            end,
        }, "ESPShowHealth")
        
        espMain:Toggle({
            Name = "Show Distance",
            Default = true,
            Callback = function(state)
                Settings.ESPShowDistance = state
            end,
        }, "ESPShowDistance")
        
        espMain:Toggle({
            Name = "2D Box",
            Default = true,
            Callback = function(state)
                Settings.ESPBox = state
            end,
        }, "ESPBox")
        
        local espColors = ESPTab:Section({ Side = "Right" })
        espColors:Header({ Name = "Colors" })
        
        espColors:Colorpicker({
            Name = "ESP Color",
            Default = Color3.fromRGB(255, 50, 50),
            Callback = function(color)
                Settings.ESPColor = color
            end,
        }, "ESPColor")
        
        -- ====== WEAPON MODS TAB ======
        local WeaponTab = TabGroup:Tab({ Name = "Weapon Mods", Image = "rbxassetid://10734950309" })
        
        local wpnMain = WeaponTab:Section({ Side = "Left" })
        wpnMain:Header({ Name = "Weapon Modifications" })
        
        wpnMain:Toggle({
            Name = "Infinite Ammo",
            Default = false,
            Callback = function(state)
                Settings.InfiniteAmmo = state
                ApplyWeaponHooks()
            end,
        }, "InfiniteAmmo")
        
        wpnMain:Toggle({
            Name = "Fast Fire Rate",
            Default = false,
            Callback = function(state)
                Settings.FastFireRate = state
                ApplyWeaponHooks()
            end,
        }, "FastFireRate")
        
        wpnMain:Toggle({
            Name = "Infinite Damage",
            Default = false,
            Callback = function(state)
                Settings.InfiniteDamage = state
                ApplyWeaponHooks()
            end,
        }, "InfiniteDamage")
        
        local wpnAdv = WeaponTab:Section({ Side = "Right" })
        wpnAdv:Header({ Name = "Advanced" })
        
        wpnAdv:Slider({
            Name = "Bullet Speed Multiplier",
            Minimum = 1,
            Maximum = 10,
            Default = 3,
            Precision = 1,
            DisplayMethod = "Tenths",
            Suffix = "x",
            Callback = function(value)
                Settings.BulletSpeedMultiplier = value
                ApplyWeaponHooks()
            end,
        }, "BulletSpeedMultiplier")
        
        wpnAdv:Slider({
            Name = "Max Distance",
            Minimum = 1000,
            Maximum = 50000,
            Default = 9999,
            DisplayMethod = "Value",
            Callback = function(value)
                Settings.MaxDistance = value
                ApplyWeaponHooks()
            end,
        }, "MaxDistance")
        
    end,
})

local Window = HUB.Window
local SettingsTab = HUB.SettingsTab
local PlayerTab = HUB.PlayerTab

-- ============== MAIN RENDER LOOP ==============
RunService.RenderStepped:Connect(function()
    -- ESP Rendering
    if Settings.ESP then
        for char, objs in pairs(ESPObjects) do
            local target = objs.Target
            local root = char:FindFirstChild("HumanoidRootPart")
                or char:FindFirstChild("Torso")
                or char:FindFirstChild("UpperTorso")
            local hum = target and target.Humanoid
            
            if hum and hum.Health > 0 and root then
                local sp, onScr = Camera:WorldToViewportPoint(root.Position)
                if onScr then
                    local dist = (Camera.CFrame.Position - root.Position).Magnitude
                    local scale = math.clamp(dist / 80, 0.3, 15)
                    
                    local label = ""
                    if Settings.ESPShowName then
                        label = target.Type == "Bot" and (char.Name or "Bot")
                            or (target.Player and target.Player.Name or char.Name)
                    end
                    if Settings.ESPShowHealth then
                        label = label .. " [" .. math.floor(hum.Health) .. "HP]"
                    end
                    if Settings.ESPShowDistance then
                        label = label .. " " .. math.floor(dist) .. "m"
                    end
                    
                    objs.Text.Position = Vector2.new(sp.X, sp.Y - 35)
                    objs.Text.Text = label
                    objs.Text.Visible = #label > 0
                    objs.Text.Color = Settings.ESPColor
                    
                    if Settings.ESPBox then
                        local sz = Vector3.new(4, 6, 0) * scale
                        objs.Box.Size = Vector2.new(sz.X, sz.Y)
                        objs.Box.Position = Vector2.new(sp.X - sz.X / 2, sp.Y - sz.Y / 2)
                        objs.Box.Visible = true
                        objs.Box.Color = Settings.ESPColor
                    else
                        objs.Box.Visible = false
                    end
                    
                    if Settings.ESPShowHealth then
                        local hpPct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                        local barHeight = (Settings.ESPBox and Vector3.new(4, 6, 0) * scale or Vector3.new(4, 6, 0) * scale).Y
                        local barWidth = 4
                        objs.Health.Size = Vector2.new(barWidth, math.max(barHeight * hpPct, 1))
                        objs.Health.Position = Vector2.new(
                            sp.X + (Settings.ESPBox and (Vector3.new(4, 6, 0) * scale).X / 2 or 4) + 2,
                            sp.Y + barHeight / 2 - objs.Health.Size.Y
                        )
                        objs.Health.Color = Color3.fromRGB(
                            math.floor(255 * (1 - hpPct)),
                            math.floor(255 * hpPct),
                            0
                        )
                        objs.Health.Visible = true
                    else
                        objs.Health.Visible = false
                    end
                    
                    continue
                end
            end
            objs.Text.Visible = false
            objs.Box.Visible = false
            objs.Health.Visible = false
        end
    else
        for _, objs in pairs(ESPObjects) do
            objs.Text.Visible = false
            objs.Box.Visible = false
            objs.Health.Visible = false
        end
    end
    
    -- Aimbot
    if Settings.Aimbot and aimbotActive then
        local target = GetClosestTarget()
        if target then
            local part = GetTargetPart(target)
            if part then
                local tCF = CFrame.lookAt(Camera.CFrame.Position, part.Position)
                Camera.CFrame = Camera.CFrame:Lerp(tCF, Settings.AimbotSmoothness)
            end
        end
    end
end)

-- ============== TRIGGER BOT LOOP ==============
task.spawn(function()
    while task.wait(Settings.TriggerDelay) do
        if Settings.TriggerBot and triggerActive then
            local targetChar = GetTargetUnderCrosshair()
            if targetChar then
                local mousePos = UserInputService:GetMouseLocation()
                VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, true, game, 0)
                task.wait(0.005)
                VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, false, game, 0)
            end
        end
    end
end)

-- ============== INITIALIZATION ==============
task.spawn(function()
    task.wait(2)
    ApplyWeaponHooks()
    
    if Common then
        SetupSilentAim()
    end
    
    Window:Notify({
        Title = "Noliar Hub Loaded",
        Description = "All modules ready. Everything starts disabled — configure via the menu.",
        Lifetime = 4,
        Style = "Confirm",
    })
    
    print("✅ Noliar Hub - One Tap Cheat loaded!")
    print("   All features disabled by default")
    print("   Press RightControl to toggle the menu")
end)
