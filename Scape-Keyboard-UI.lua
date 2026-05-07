local MacLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/NickolasFrutuoso/MacUI/refs/heads/main/UI"))()

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local RepStorage   = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp       = character:WaitForChild("HumanoidRootPart")
local humanoid  = character:WaitForChild("Humanoid")

player.CharacterAdded:Connect(function(char)
    character = char
    hrp       = char:WaitForChild("HumanoidRootPart")
    humanoid  = char:WaitForChild("Humanoid")
end)

-- ══════════════════════════════════════
--  CONFIG
-- ══════════════════════════════════════

local CFG = {
    -- Farm Win (positions are fixed)
    farmEnabled   = false,
    teleportSpeed = 8,
    spawnPos      = Vector3.new(2.1690, 10.3981, 3.7223),
    winPos        = Vector3.new(-13999.0518, 776.0323, 3067.8577),

    -- Walking Remote
    walkingEnabled = false,
    walkingRate    = 0.1,

    -- Rebirth Remote
    rebirthEnabled = false,
    rebirthRate    = 0.1,
}

-- ══════════════════════════════════════
--  UTILITIES
-- ══════════════════════════════════════

local function enableNoclip()
    if character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end

local noclipConnection

local function startNoclip()
    noclipConnection = RunService.Stepped:Connect(enableNoclip)
end

local function stopNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
end

-- Returns false if farm was disabled mid-travel (caller should abort)
-- Recalculates each iteration so speed changes apply immediately
local function moveTo(destPos)
    while true do
        if not CFG.farmEnabled then
            return false
        end

        local remaining = (destPos - hrp.Position).Magnitude
        if remaining <= CFG.teleportSpeed then
            enableNoclip()
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.CFrame = CFrame.new(destPos)
            break
        end

        local dir     = (destPos - hrp.Position).Unit
        local nextPos = hrp.Position + dir * CFG.teleportSpeed
        enableNoclip()
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.CFrame = CFrame.new(nextPos)
        task.wait(0.05)
    end
    return true
end

local function isNearSpawn()
    return (hrp.Position - CFG.spawnPos).Magnitude <= 100
end

local function jump()
    if humanoid then
        humanoid.Jump = true
    end
end

-- ══════════════════════════════════════
--  PARALLEL LOOPS
-- ══════════════════════════════════════

-- Walking loop
task.spawn(function()
    local remote = RepStorage:WaitForChild("Remotes"):WaitForChild("UpdateSpeed")
    while true do
        task.wait(CFG.walkingRate)
        if CFG.walkingEnabled then
            remote:FireServer("Walking")
        end
    end
end)

-- Rebirth loop
task.spawn(function()
    local remote = RepStorage:WaitForChild("Remotes"):WaitForChild("Rebirth")
    while true do
        task.wait(CFG.rebirthRate)
        if CFG.rebirthEnabled then
            remote:FireServer()
        end
    end
end)

-- Farm Win loop
task.spawn(function()
    while true do
        task.wait(0.2)

        if not CFG.farmEnabled then
            continue
        end

        if isNearSpawn() then
            startNoclip()
            hrp.AssemblyLinearVelocity = Vector3.zero

            local completed = moveTo(CFG.winPos)

            stopNoclip()

            if completed then
                hrp.AssemblyLinearVelocity = Vector3.zero
            end
        else
            jump()
            task.wait(1.2)
        end
    end
end)

-- ══════════════════════════════════════
--  UI
-- ══════════════════════════════════════

local HUB = MacLib:CreateHUB({
    Title    = "Noliar Hub",
    Subtitle = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name,
    OnTabGroup = function(TabGroup, Window)

        -- ── TAB: FARM ──────────────────────────────
        local FarmTab = TabGroup:Tab({ Name = "Farm", Image = "rbxassetid://10734950309" })

        local FarmLeft  = FarmTab:Section({ Side = "Left" })
        local FarmRight = FarmTab:Section({ Side = "Right" })

        -- ── LEFT: Farm Win ──
        FarmLeft:Header({ Name = "Farm Win" })

        FarmLeft:Toggle({
            Name     = "Enable Farm Win",
            Default  = false,
            Callback = function(state)
                CFG.farmEnabled = state
            end,
        }, "FarmEnabled")

        FarmLeft:Divider()
        FarmLeft:Header({ Name = "Teleport Settings" })

        FarmLeft:Input({
            Name               = "Teleport Speed",
            Default            = "8",
            Placeholder        = "Recommended: 8",
            AcceptedCharacters = "Numeric",
            Callback = function(text)
                local n = tonumber(text)
                if n and n > 0 then
                    CFG.teleportSpeed = n
                end
            end,
        }, "FarmTeleportSpeed")

        FarmLeft:Label({
            Text = "Recommended value: 8 studs/step",
        })

        -- ── RIGHT: Walking Remote ──
        FarmRight:Header({ Name = "Walking Speed" })

        FarmRight:Toggle({
            Name     = "Enable Walking Remote",
            Default  = false,
            Callback = function(state)
                CFG.walkingEnabled = state
            end,
        }, "WalkingEnabled")

        FarmRight:Slider({
            Name      = "Fire Rate",
            Minimum   = 0.01,
            Maximum   = 2,
            Default   = 0.1,
            Precision = 2,
            Suffix    = "s",
            Callback  = function(value)
                CFG.walkingRate = value
            end,
        }, "WalkingRate")

        FarmRight:Divider()

        -- ── RIGHT: Rebirth Remote ──
        FarmRight:Header({ Name = "Rebirth" })

        FarmRight:Toggle({
            Name     = "Enable Rebirth Remote",
            Default  = false,
            Callback = function(state)
                CFG.rebirthEnabled = state
            end,
        }, "RebirthEnabled")

        FarmRight:Slider({
            Name      = "Fire Rate",
            Minimum   = 0.01,
            Maximum   = 2,
            Default   = 0.1,
            Precision = 2,
            Suffix    = "s",
            Callback  = function(value)
                CFG.rebirthRate = value
            end,
        }, "RebirthRate")

    end,
})

local Window = HUB.Window

Window:Notify({
    Title       = "Noliar HUB Loaded",
    Description = "All features are OFF by default. Enable them in the tabs.",
    Lifetime    = 4,
})
