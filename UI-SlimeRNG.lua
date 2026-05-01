-- ══════════════════════════════════════════════════════
-- // SLIME FUN GUI - Rayfield Interface
-- // Auto Roll | Auto Upgrade | Farm | Auto Mob | Auto Collect | Auto Zone
-- ══════════════════════════════════════════════════════

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local RS         = game:GetService("ReplicatedStorage")
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local player     = Players.LocalPlayer

-- ══════════════════════════════════════════════════════
-- // REMOTES
-- ══════════════════════════════════════════════════════

local function getRemote(serviceName)
    return RS
        :WaitForChild("Packages")
        :WaitForChild("_Index")
        :WaitForChild("leifstout_networker@0.3.1")
        :WaitForChild("networker")
        :WaitForChild("_remotes")
        :WaitForChild(serviceName)
        :WaitForChild("RemoteFunction")
end

local RollRemote      = getRemote("RollService")
local InventoryRemote = getRemote("InventoryService")
local UpgradeRemote   = getRemote("UpgradeService")
local LootRemote      = getRemote("LootService")
local ZoneRemote      = getRemote("ZonesService")
local IndexRemote     = getRemote("IndexService")
local RebirthRemote   = getRemote("RebirthService")

local USC         = require(RS.Source.Features.Upgrades.UpgradeServiceClient)
local UpgradeTree = require(RS.Source.Features.Upgrades.UpgradeTree)

-- ══════════════════════════════════════════════════════
-- // UPGRADE REGISTRY
-- ══════════════════════════════════════════════════════

local UPGRADE_REGISTRY = {
    -- ── Main Tree ──────────────────────────────────────
    {key="rollSpeed",        tree="main",       label="Main: Roll Speed",         max=6,  ids={"rollSpeed1","rollSpeed2","rollSpeed3","rollSpeed4","rollSpeed5","rollSpeed6"}},
    {key="luck",             tree="main",       label="Main: Luck",               max=15, ids={"luck1","luck2","luck3","luck4","luck5","luck6","luck7","luck8","luck9","luck10","luck11","luck12","luck13","luck14","luck15"}},
    {key="slots",            tree="main",       label="Main: Slots",              max=7,  ids={"slots2","slots3","slots4","slots5","slots6","slots7","slots8"}},
    {key="enemyCount",       tree="main",       label="Main: Enemy Count",        max=6,  ids={"enemyCount2","enemyCount3","enemyCount4","enemyCount5","enemyCount6","enemyCount7"}},
    {key="enemySpawnSpeed",  tree="main",       label="Main: Enemy Spawn Speed",  max=3,  ids={"enemySpawnSpeed1","enemySpawnSpeed2","enemySpawnSpeed3"}},
    {key="goldenRolls",      tree="main",       label="Main: Golden Rolls",       max=2,  ids={"goldenRolls","goldenRolls2"}},
    {key="diamondRolls",     tree="main",       label="Main: Diamond Rolls",      max=4,  ids={"diamondRolls","diamondRolls2","diamondRolls3","diamondRolls4"}},
    {key="voidRolls",        tree="main",       label="Main: Void Rolls",         max=4,  ids={"voidRolls","voidRolls2","voidRolls3","voidRolls4"}},
    {key="bonusRolls",       tree="main",       label="Main: Bonus Rolls",        max=3,  ids={"bonusRolls1","bonusRolls2","bonusRolls3"}},
    {key="cloverRolls",      tree="main",       label="Main: Clover Rolls",       max=5,  ids={"cloverRolls1","cloverRolls2","cloverRolls3","cloverRolls4","cloverRolls5"}},
    {key="friendLuck",       tree="main",       label="Main: Friend Luck",        max=9,  ids={"friendLuck1","friendLuck2","friendLuck3","friendLuck4","friendLuck5","friendLuck6","friendLuck7","friendLuck8","friendLuck9"}},
    {key="friendLuckBoost",  tree="main",       label="Main: Friend Luck Boost",  max=4,  ids={"friendLuckBoost1","friendLuckBoost2","friendLuckBoost3","friendLuckBoost4"}},
    {key="extraRollChance",  tree="main",       label="Main: Extra Roll Chance",  max=3,  ids={"extraRollChance1","extraRollChance2","extraRollChance3"}},
    {key="slimeTargetRange", tree="main",       label="Main: Slime Target Range", max=3,  ids={"slimeTargetRange1","slimeTargetRange2","slimeTargetRange3"}},
    {key="goopDropRate",     tree="main",       label="Main: Goop Drop Rate",     max=6,  ids={"goopDropRate1","goopDropRate2","goopDropRate3","goopDropRate4","goopDropRate5","goopDropRate6"}},
    {key="overkill",         tree="main",       label="Main: Overkill",           max=8,  ids={"overkill1","overkill2","overkill3","overkill4","overkill5","overkill6","overkill7","overkill8"}},
    {key="walkSpeed",        tree="main",       label="Main: Walk Speed",         max=3,  ids={"walkSpeed1","walkSpeed2","walkSpeed3"}},
    {key="autoRoll",         tree="main",       label="Main: Auto Roll",          max=1,  ids={"autoRoll"}},
    {key="backpack",         tree="main",       label="Main: Backpack",           max=1,  ids={"backpack"}},
    {key="goop",             tree="main",       label="Main: Goop",               max=1,  ids={"goop"}},
    {key="bigSlimes",        tree="main",       label="Main: Big Slimes",         max=1,  ids={"bigSlimes"}},
    {key="shinySlimes",      tree="main",       label="Main: Shiny Slimes",       max=1,  ids={"shinySlimes"}},
    {key="hugeSlimes",       tree="main",       label="Main: Huge Slimes",        max=1,  ids={"hugeSlimes"}},
    {key="invertedSlimes",   tree="main",       label="Main: Inverted Slimes",    max=1,  ids={"invertedSlimes"}},
    {key="bossChance",       tree="main",       label="Main: Boss Chance",        max=1,  ids={"bossChance"}},
    -- ── Loot Tree ─────────────────────────────────────
    {key="lootChain",        tree="lootTree",   label="Loot: Food Chain",         max=9,  ids={"lootApple","lootCarrot","lootCherries","lootGrapes","lootBanana","lootWatermelon","lootPizza","lootChicken","lootDrumstick"}},
    {key="coinIncome",       tree="lootTree",   label="Loot: Coin Income",        max=13, ids={"coinIncome1","coinIncome2","coinIncome3","coinIncome4","coinIncome5","coinIncome6","coinIncome7","coinIncome8","coinIncome9","coinIncome10","coinIncome11","coinIncome12","coinIncome13"}},
    {key="offlineLoot",      tree="lootTree",   label="Loot: Offline Loot",       max=5,  ids={"offlineLootAmount1","offlineLootAmount2","offlineLootAmount3","offlineLootAmount4","offlineLootAmount5"}},
    {key="lootLuck",         tree="lootTree",   label="Loot: Luck",               max=1,  ids={"lootLuck"}},
    {key="lootCurrency",     tree="lootTree",   label="Loot: Currency",           max=1,  ids={"lootCurrency"}},
    {key="lootRollSpeed",    tree="lootTree",   label="Loot: Roll Speed",         max=1,  ids={"lootRollSpeed"}},
    {key="lootUltraLuck",    tree="lootTree",   label="Loot: Ultra Luck",         max=1,  ids={"lootUltraLuck"}},
    -- ── Player Tree ───────────────────────────────────
    {key="playerOverkill",   tree="playerTree", label="Player: Overkill",         max=8,  ids={"overkill1","overkill2","overkill3","overkill4","overkill5","overkill6","overkill7","overkill8"}},
    {key="playerWalkSpeed",  tree="playerTree", label="Player: Walk Speed",       max=3,  ids={"walkSpeed1","walkSpeed2","walkSpeed3"}},
    {key="playerBigSlimes",  tree="playerTree", label="Player: Big Slimes",       max=1,  ids={"bigSlimes"}},
    {key="playerShiny",      tree="playerTree", label="Player: Shiny Slimes",     max=1,  ids={"shinySlimes"}},
    {key="playerHuge",       tree="playerTree", label="Player: Huge Slimes",      max=1,  ids={"hugeSlimes"}},
    {key="playerInverted",   tree="playerTree", label="Player: Inverted Slimes",  max=1,  ids={"invertedSlimes"}},
    {key="playerBackpack",   tree="playerTree", label="Player: Backpack",         max=1,  ids={"backpack"}},
}

local CATEGORY_MAP     = {}
local CATEGORY_OPTIONS = {"── None ──"}
for _, reg in pairs(UPGRADE_REGISTRY) do
    CATEGORY_MAP[reg.label] = reg
    CATEGORY_MAP[reg.key]   = reg
    table.insert(CATEGORY_OPTIONS, reg.label)
end

local KNOWN_TREES = {"main", "lootTree", "playerTree"}

-- ══════════════════════════════════════════════════════
-- // STATE
-- ══════════════════════════════════════════════════════

local State = {
    -- Automation toggles
    autoRoll        = false,
    autoEquip       = false,
    autoCollect     = false,
    autoZone        = false,
    autoUpgrade     = false,
    farmEnabled     = false,
    autoMob         = false,
    autoIndexReward = false,
    autoRebirth     = false,

    -- Settings
    rollDelay       = 0.05,
    farmPriority    = "upgrade",
    upgradePriority = "all",
    upgradeOrder    = "cost",
    mobMode         = "fly",
    flySpeed        = 80,
    mobCooldown     = 0.3,

    -- Farm priority slots
    farmSlots = {
        {key = "none", maxLevel = 0},
        {key = "none", maxLevel = 0},
        {key = "none", maxLevel = 0},
        {key = "none", maxLevel = 0},
        {key = "none", maxLevel = 0},
        {key = "none", maxLevel = 0},
    },

    -- Session counters
    rollCount      = 0,
    upgradeCount   = 0,
    collectCount   = 0,
    zoneCount      = 0,
    mobCount       = 0,
    currentMobName = "None",

    -- Mutexes — FIX: evita chamadas simultâneas
    zoneRunning    = false,
    upgradeRunning = false,
}

-- ══════════════════════════════════════════════════════
-- // BASE HELPERS
-- ══════════════════════════════════════════════════════

-- FIX: helper para extrair valor de dropdown (pode vir como string ou table)
local function resolveDropdown(s)
    return type(s) == "table" and (s[1] or "") or tostring(s)
end

local function doRoll()
    local ok = pcall(function() RollRemote:InvokeServer("requestRoll") end)
    if ok then State.rollCount += 1 end
    return ok
end

local function doEquipBest()
    pcall(function() InventoryRemote:InvokeServer("requestEquipBest") end)
end

local function doUnlock(id)
    local ok, result = pcall(function()
        return UpgradeRemote:InvokeServer("requestUnlock", id)
    end)
    local success = ok and result == true
    if success then
        State.upgradeCount += 1
    end
    return success
end

-- ══════════════════════════════════════════════════════
-- // ZONE SYSTEM  —  FIX TELEPORTE CORRETO
-- ══════════════════════════════════════════════════════

local function getZoneByNumber(num)
    for _, zone in pairs(workspace.Zones:GetChildren()) do
        if tonumber(zone.Name) == num then
            return zone
        end
    end
    return nil
end

local function getCurrentHighestZoneNumber()
    local highest = 0
    for _, zone in pairs(workspace.Zones:GetChildren()) do
        local num = tonumber(zone.Name)
        if num then
            local gate    = zone:FindFirstChild("Gate")
            local blocker = gate and gate:FindFirstChildWhichIsA("Part")
            -- conta zona sem gate (zona inicial) OU zona com gate desbloqueado
            if not gate or (blocker and not blocker.CanCollide) then
                if num > highest then highest = num end
            end
        end
    end
    return highest
end

local function teleportToZone(zone)
    if not zone then return end
    local poi = zone:FindFirstChild("POI")
    if not poi then return end
    local spawn = poi:FindFirstChild("PlayerSpawn")
    if not spawn then return end
    local char = player.Character
    if not char then return end
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    rootPart.CFrame = CFrame.new(spawn.Position + Vector3.new(0, 4, 0))
end

local function getPlayerCurrentZone()
    local char = player.Character
    local rp   = char and char:FindFirstChild("HumanoidRootPart")
    if not rp then return 1 end

    local closest    = 1
    local closestDist = math.huge

    for _, zone in pairs(workspace.Zones:GetChildren()) do
        local num = tonumber(zone.Name)
        if num then
            local poi   = zone:FindFirstChild("POI")
            local spawn = poi and poi:FindFirstChild("PlayerSpawn")
            if spawn then
                local dist = (spawn.Position - rp.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest     = num
                end
            end
        end
    end
    return closest
end

local function doPurchaseZone()
    if State.zoneRunning then return false end
    State.zoneRunning = true

    -- Zona atual baseada na posição do player
    local zoneBefore = getPlayerCurrentZone()

    local ok, result = pcall(function()
        return ZoneRemote:InvokeServer("requestPurchaseZone")
    end)
    local success = ok and result == true

    if success then
        State.zoneCount += 1

        local newZoneNum = zoneBefore + 1

        task.wait(1.0)

        local zone = getZoneByNumber(newZoneNum)

        if not zone then
            Rayfield:Notify({ Title = "Zone", Content = "Zone " .. newZoneNum .. " not found!", Duration = 3, Image = 4483362458 })
            State.zoneRunning = false
            return false
        end

        teleportToZone(zone)

        Rayfield:Notify({
            Title    = "🗺️ New Zone!",
            Content  = "Zone " .. newZoneNum .. " unlocked! Teleporting...",
            Duration = 4,
            Image    = 4483362458,
        })
    end

    State.zoneRunning = false
    return success
end

-- ══════════════════════════════════════════════════════
-- // LOOT
-- ══════════════════════════════════════════════════════

local function collectAllLoot()
    local LootFolder = workspace:FindFirstChild("Loot")
    if not LootFolder then return 0 end
    local collected = 0
    for _, item in pairs(LootFolder:GetChildren()) do
        local ok, result = pcall(function()
            return LootRemote:InvokeServer("requestCollect", item.Name)
        end)
        if ok and result == true then
            collected      += 1
            State.collectCount += 1
        end
        task.wait(0.05)
    end
    return collected
end

-- ══════════════════════════════════════════════════════
-- // UPGRADE SYSTEM
-- ══════════════════════════════════════════════════════

local function buyCategoryUpTo(key, maxLevel)
    local reg = CATEGORY_MAP[key]
    if not reg then return 0 end
    local maxIdx = math.min(maxLevel, #reg.ids)
    local bought = 0
    for idx = 1, maxIdx do
        local id   = reg.ids[idx]
        local owns = false
        pcall(function() owns = USC.ownsUpgrade(player, id) end)
        if not owns then
            if doUnlock(id) then bought += 1 end
            task.wait(0.15)
        end
    end
    return bought
end

local function getNextInCategory(key, maxLevel)
    local reg = CATEGORY_MAP[key]
    if not reg then return nil end
    local maxIdx = math.min(maxLevel, #reg.ids)
    for idx = 1, maxIdx do
        local id   = reg.ids[idx]
        local owns = false
        pcall(function() owns = USC.ownsUpgrade(player, id) end)
        if not owns then return id end
    end
    return nil
end

-- FIX: mutex upgradeRunning para evitar conflito entre farmStep e autoUpgrade
local function farmStep()
    if State.upgradeRunning then return false end
    State.upgradeRunning = true

    local bought = false
    for i = 1, 6 do
        local slot = State.farmSlots[i]
        if slot.key ~= "none" and slot.maxLevel > 0 then
            local nextId = getNextInCategory(slot.key, slot.maxLevel)
            if nextId then
                doUnlock(nextId)
                bought = true
                break
            end
        end
    end

    State.upgradeRunning = false
    return bought
end

local function getTreeUpgrades(treeName)
    local tree = UpgradeTree[treeName]
    if type(tree) ~= "table" then return {} end
    local available = {}
    for id, data in pairs(tree) do
        if type(data) == "table" and data.id then
            local owns = false
            pcall(function() owns = USC.ownsUpgrade(player, id) end)
            if not owns then
                local depOk = true
                if data.dependency then
                    local depOwns = false
                    pcall(function() depOwns = USC.ownsUpgrade(player, data.dependency) end)
                    depOk = depOwns
                end
                if depOk then
                    local numCost = 0
                    if type(data.cost) == "number" then
                        numCost = data.cost
                    elseif type(data.cost) == "table" then
                        numCost = data.cost.amount or 0
                        if numCost == 0 then
                            for _, v in pairs(data.cost) do
                                if type(v) == "number" then numCost = v break end
                            end
                        end
                    end
                    table.insert(available, {id = id, tree = treeName, cost = numCost})
                end
            end
        end
    end
    return available
end

local function getUpgradesToBuy()
    local trees = State.upgradePriority == "all" and KNOWN_TREES or {State.upgradePriority}
    local all   = {}
    for _, treeName in pairs(trees) do
        for _, entry in pairs(getTreeUpgrades(treeName)) do
            table.insert(all, entry)
        end
    end
    if State.upgradeOrder == "cost" then
        table.sort(all, function(a, b) return a.cost < b.cost end)
    end
    return all
end

-- FIX: mutex upgradeRunning aplicado aqui também
local function buyAllPasses(treeOverride)
    if State.upgradeRunning then return 0 end
    State.upgradeRunning = true

    local totalBought = 0
    for _ = 1, 10 do
        local available = treeOverride and getTreeUpgrades(treeOverride) or getUpgradesToBuy()
        if #available == 0 then break end
        local bought = 0
        for _, entry in pairs(available) do
            if doUnlock(entry.id) then
                bought += 1
                task.wait(0.15)
            else
                task.wait(0.05)
            end
        end
        totalBought += bought
        if bought == 0 then break end
    end

    State.upgradeRunning = false
    return totalBought
end

-- ══════════════════════════════════════════════════════
-- // AUTO MOB SYSTEM
-- ══════════════════════════════════════════════════════

local mobFlyConn = nil

local function getEnemiesFolder()
    local folder = workspace:FindFirstChild("Gameplay16")
    if folder then
        local enemies = folder:FindFirstChild("Enemies")
        if enemies then return enemies end
    end
    for _, child in pairs(workspace:GetChildren()) do
        if child.Name:match("^Gameplay") then
            local enemies = child:FindFirstChild("Enemies")
            if enemies then return enemies end
        end
    end
    return nil
end

local function getMobRoot(mob)
    return mob:FindFirstChild("HumanoidRootPart")
        or mob.PrimaryPart
        or mob:FindFirstChildWhichIsA("BasePart")
end

local function isMobAlive(mob)
    if not mob or not mob.Parent then return false end
    local hum = mob:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return false end
    return true
end

local function getClosestMob()
    local Enemies = getEnemiesFolder()
    if not Enemies then return nil end
    local char = player.Character
    if not char then return nil end
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end
    local closest, closestDist = nil, math.huge
    for _, mob in pairs(Enemies:GetChildren()) do
        if mob:IsA("Model") and isMobAlive(mob) then
            local root = getMobRoot(mob)
            if root then
                local dist = (root.Position - rootPart.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest     = mob
                end
            end
        end
    end
    return closest
end

local function teleportToMob(mob)
    local char = player.Character
    if not char then return end
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    local root     = getMobRoot(mob)
    if not rootPart or not root then return end
    rootPart.CFrame = CFrame.new(root.Position + Vector3.new(3, 2, 3))
end

local function stopFly()
    if mobFlyConn then
        mobFlyConn:Disconnect()
        mobFlyConn = nil
    end
    local char = player.Character
    if char then
        local hum      = char:FindFirstChildOfClass("Humanoid")
        local rootPart = char:FindFirstChild("HumanoidRootPart")
        if hum      then hum.PlatformStand = false end
        if rootPart then rootPart.AssemblyLinearVelocity = Vector3.zero end
    end
end

local function flyToMob(mob, onArrived)
    stopFly()
    local char = player.Character
    if not char then return end
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    local hum      = char:FindFirstChildOfClass("Humanoid")
    if not rootPart or not hum then return end
    hum.PlatformStand = true

    local arrived      = false
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    mobFlyConn = RunService.Heartbeat:Connect(function()
        if arrived then return end
        if not isMobAlive(mob) then
            arrived = true
            stopFly()
            if onArrived then onArrived(true) end
            return
        end
        local target = getMobRoot(mob)
        if not target then
            arrived = true
            stopFly()
            if onArrived then onArrived(false) end
            return
        end
        local charPos   = rootPart.Position
        local targetPos = target.Position + Vector3.new(0, 2, 0)
        local dir       = targetPos - charPos
        local dist      = dir.Magnitude
        if dist < 4 then
            arrived = true
            stopFly()
            if onArrived then onArrived(true) end
            return
        end
        local unitDir = dir.Unit
        raycastParams.FilterDescendantsInstances = {char, mob}
        local hit     = workspace:Raycast(charPos, unitDir * math.min(dist, 8), raycastParams)
        local moveDir = unitDir
        if hit then
            local alts = {
                Vector3.new(unitDir.X,  0.8,  unitDir.Z).Unit,
                Vector3.new(-unitDir.Z, 0.3,  unitDir.X).Unit,
                Vector3.new( unitDir.Z, 0.3, -unitDir.X).Unit,
            }
            local found = false
            for _, alt in pairs(alts) do
                if not workspace:Raycast(charPos, alt * 8, raycastParams) then
                    moveDir = alt
                    found   = true
                    break
                end
            end
            if not found then
                moveDir = Vector3.new(unitDir.X, 1, unitDir.Z).Unit
            end
        end
        rootPart.AssemblyLinearVelocity = moveDir * State.flySpeed
    end)
end

local function autoMobStep()
    if not State.autoMob then return end
    local mob = getClosestMob()
    if not mob then
        State.currentMobName = "None"
        task.wait(0.5)
        if State.autoMob then autoMobStep() end  -- ← só recursiona se ainda ativo
        return
    end
    State.currentMobName = mob.Name

    if State.mobMode == "teleport" then
        teleportToMob(mob)
        local elapsed = 0
        repeat task.wait(0.1) elapsed += 0.1
        until not isMobAlive(mob) or elapsed >= 10 or not State.autoMob
        State.mobCount += 1
        task.wait(State.mobCooldown)
        if State.autoMob then autoMobStep() end

    elseif State.mobMode == "fly" then
        local done = false
        flyToMob(mob, function() done = true end)
        local elapsed = 0
        repeat task.wait(0.1) elapsed += 0.1
        until done or not isMobAlive(mob) or elapsed >= 15 or not State.autoMob
        stopFly()
        if isMobAlive(mob) then
            elapsed = 0
            repeat
                task.wait(0.1)
                elapsed += 0.1
                local root = getMobRoot(mob)
                local char = player.Character
                local rp   = char and char:FindFirstChild("HumanoidRootPart")
                if root and rp and (root.Position - rp.Position).Magnitude > 10 then
                    teleportToMob(mob)
                end
            until not isMobAlive(mob) or elapsed >= 8 or not State.autoMob
        end
        State.mobCount += 1
        task.wait(State.mobCooldown)
        if State.autoMob then autoMobStep() end
    end
end

-- ══════════════════════════════════════════════════════
-- // WINDOW
-- ══════════════════════════════════════════════════════

local Window = Rayfield:CreateWindow({
    Name             = "Slime RNG | UPDT 04/30",
    LoadingTitle     = "Slime RNG",
    LoadingSubtitle  = "by Noliar",
    ShowText         = "v1.0",
    Theme            = "Default",
    ToggleUIKeybind  = "L",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = false,
    ConfigurationSaving = {
        Enabled    = true, 
        FolderName = "SlimeRNG",
        FileName   = "Noliar-HUB",
    },
    Discord   = { Enabled = false },
    KeySystem = false,
})

-- ══════════════════════════════════════════════════════
-- // TAB: MAIN
-- ══════════════════════════════════════════════════════

local MainTab = Window:CreateTab("🏠 Main", nil)

-- ── Auto Roll ─────────────────────────────────────────

MainTab:CreateSection("Auto Roll")

MainTab:CreateToggle({
    Name         = "Enable Auto Roll",
    CurrentValue = false,
    Flag         = "AutoRoll",
    Callback     = function(v) State.autoRoll = v end,
})

MainTab:CreateSlider({
    Name         = "Roll Delay",
    Range        = {5, 500},
    Increment    = 5,
    Suffix       = "ms",
    CurrentValue = 50,
    Flag         = "RollDelay",
    Callback     = function(v) State.rollDelay = v / 1000 end,
})

MainTab:CreateToggle({
    Name         = "Auto Equip Best Slimes",
    CurrentValue = false,
    Flag         = "AutoEquip",
    Callback     = function(v) State.autoEquip = v end,
})

-- ── Auto Collect ──────────────────────────────────────

MainTab:CreateSection("Auto Collect")

MainTab:CreateToggle({
    Name         = "Enable Auto Collect",
    CurrentValue = false,
    Flag         = "AutoCollect",
    Callback     = function(v) State.autoCollect = v end,
})

-- ── Auto Mob ──────────────────────────────────────────

MainTab:CreateSection("Auto Mob")

MainTab:CreateToggle({
    Name         = "Enable Auto Mob",
    CurrentValue = false,
    Flag         = "AutoMob",
    Callback     = function(v)
        State.autoMob = v
        if v then
            Rayfield:Notify({ Title = "Auto Mob", Content = "Enabled! Mode: " .. State.mobMode, Duration = 3, Image = 4483362458 })
            task.spawn(autoMobStep)
        else
            stopFly()
            State.currentMobName = "None"
            Rayfield:Notify({ Title = "Auto Mob", Content = "Disabled.", Duration = 2, Image = 4483362458 })
        end
    end,
})

-- FIX: resolveDropdown aplicado no callback
MainTab:CreateDropdown({
    Name          = "Mob Mode",
    Options       = {"Fly", "Teleport"},
    CurrentOption = {"Fly"},
    Flag          = "MobMode",
    Callback      = function(s)
        local opt     = resolveDropdown(s)
        State.mobMode = opt == "Fly" and "fly" or "teleport"
    end,
})

MainTab:CreateSlider({
    Name         = "Fly Speed",
    Range        = {20, 300},
    Increment    = 10,
    Suffix       = " studs/s",
    CurrentValue = 80,
    Flag         = "FlySpeed",
    Callback     = function(v) State.flySpeed = v end,
})

MainTab:CreateSlider({
    Name         = "Mob Cooldown",
    Range        = {0, 200},
    Increment    = 10,
    Suffix       = "ms",
    CurrentValue = 300,
    Flag         = "MobCooldown",
    Callback     = function(v) State.mobCooldown = v / 1000 end,
})

-- ── Auto Zone ─────────────────────────────────────────

MainTab:CreateSection("Auto Zone")

MainTab:CreateToggle({
    Name         = "Enable Auto Zone",
    CurrentValue = false,
    Flag         = "AutoZone",
    Callback     = function(v) State.autoZone = v end,
})

-- FIX: resolveDropdown aplicado no callback
MainTab:CreateDropdown({
    Name          = "Farm Priority",
    Options       = {"Upgrade First", "Zone First"},
    CurrentOption = {"Upgrade First"},
    Flag          = "FarmPriority",
    Callback      = function(s)
        local opt           = resolveDropdown(s)
        State.farmPriority  = opt == "Zone First" and "zone" or "upgrade"
    end,
})

-- ── Manual ────────────────────────────────────────────

MainTab:CreateSection("Manual")

MainTab:CreateButton({
    Name     = "Roll Once",
    Callback = function()
        Rayfield:Notify({ Title = "Roll", Content = doRoll() and "Rolled!" or "Failed.", Duration = 2, Image = 4483362458 })
    end,
})

MainTab:CreateButton({
    Name     = "Equip Best Now",
    Callback = function()
        doEquipBest()
        Rayfield:Notify({ Title = "Equipped", Content = "Best slimes equipped!", Duration = 2, Image = 4483362458 })
    end,
})

MainTab:CreateButton({
    Name     = "Collect All Now",
    Callback = function()
        task.spawn(function()
            local n = collectAllLoot()
            Rayfield:Notify({ Title = "Collect", Content = "Collected " .. n .. " item(s)!", Duration = 3, Image = 4483362458 })
        end)
    end,
})

MainTab:CreateButton({
    Name     = "Buy Next Zone",
    Callback = function()
        task.spawn(function()
            if not doPurchaseZone() then
                Rayfield:Notify({ Title = "Zone", Content = "Not enough money or already running.", Duration = 3, Image = 4483362458 })
            end
        end)
    end,
})

-- ── Index Rewards ─────────────────────────────────────

MainTab:CreateSection("Index Rewards")

MainTab:CreateToggle({
    Name         = "Auto Claim Index Rewards",
    CurrentValue = false,
    Flag         = "AutoIndexReward",
    Callback     = function(v)
        State.autoIndexReward = v
        Rayfield:Notify({
            Title    = "Index Rewards",
            Content  = v and "Auto claiming enabled!" or "Auto claiming disabled.",
            Duration = 2,
            Image    = 4483362458,
        })
    end,
})

MainTab:CreateButton({
    Name     = "Claim All Index Rewards Now",
    Callback = function()
        task.spawn(function()
            local types   = {"basic","big", "huge", "shiny", "inverted"}
            local claimed = 0
            for _, t in pairs(types) do
                local ok, result = pcall(function()
                    return IndexRemote:InvokeServer("requestClaimReward", t)
                end)
                if ok and result then
                    claimed += 1
                end
                task.wait(0.2)
            end
            Rayfield:Notify({
                Title    = "Index Rewards",
                Content  = claimed > 0 and "Claimed " .. claimed .. " reward(s)!" or "No rewards available.",
                Duration = 3,
                Image    = 4483362458,
            })
        end)
    end,
})

-- ── Rebirth ───────────────────────────────────────────

MainTab:CreateSection("Rebirth")

MainTab:CreateToggle({
    Name         = "Auto Rebirth",
    CurrentValue = false,
    Flag         = "AutoRebirth",
    Callback     = function(v)
        State.autoRebirth = v
        Rayfield:Notify({
            Title    = "Auto Rebirth",
            Content  = v and "Auto Rebirth enabled!" or "Auto Rebirth disabled.",
            Duration = 2,
            Image    = 4483362458,
        })
    end,
})

MainTab:CreateButton({
    Name     = "Rebirth Now",
    Callback = function()
        task.spawn(function()
            local ok, result = pcall(function()
                return RebirthRemote:InvokeServer("requestRebirth")
            end)
            if ok and result then
                Rayfield:Notify({ Title = "Rebirth", Content = "Rebirth successful!", Duration = 3, Image = 4483362458 })
            else
                Rayfield:Notify({ Title = "Rebirth", Content = "Requirements not met yet.", Duration = 3, Image = 4483362458 })
            end
        end)
    end,
})

-- ══════════════════════════════════════════════════════
-- // TAB: AUTO UPGRADE
-- ══════════════════════════════════════════════════════

local UpgradeTab = Window:CreateTab("🔼 Auto Upgrade", nil)

UpgradeTab:CreateSection("Settings")

UpgradeTab:CreateParagraph({
    Title   = "Auto Upgrade",
    Content = "Automatically purchases all available upgrades. Configure the tree and purchase order below.",
})

UpgradeTab:CreateToggle({
    Name         = "Enable Auto Upgrade",
    CurrentValue = false,
    Flag         = "AutoUpgrade",
    Callback     = function(v) State.autoUpgrade = v end,
})

-- FIX: resolveDropdown aplicado
UpgradeTab:CreateDropdown({
    Name          = "Tree",
    Options       = {"All", "Main", "Loot", "Player"},
    CurrentOption = {"All"},
    Flag          = "UpgradePriority",
    Callback      = function(s)
        local opt = resolveDropdown(s)
        local map = {["All"]="all", ["Main"]="main", ["Loot"]="lootTree", ["Player"]="playerTree"}
        State.upgradePriority = map[opt] or "all"
    end,
})

-- FIX: resolveDropdown aplicado
UpgradeTab:CreateDropdown({
    Name          = "Purchase Order",
    Options       = {"Cheapest First", "Dependency Order"},
    CurrentOption = {"Cheapest First"},
    Flag          = "UpgradeOrder",
    Callback      = function(s)
        local opt          = resolveDropdown(s)
        State.upgradeOrder = opt == "Cheapest First" and "cost" or "dependency"
    end,
})

UpgradeTab:CreateSection("Buy by Category")

UpgradeTab:CreateParagraph({
    Title   = "How to use",
    Content = "Select a category (e.g. Main: Roll Speed) and set the max level to purchase up to. The script buys in order: rollSpeed1 → rollSpeed2 → ...",
})

local selCategoryKey = "none"
local selMaxLevel    = 1

-- FIX: resolveDropdown aplicado
UpgradeTab:CreateDropdown({
    Name          = "Category",
    Options       = CATEGORY_OPTIONS,
    CurrentOption = {"── None ──"},
    Flag          = "BuyCategorySelect",
    Callback      = function(s)
        local opt = resolveDropdown(s)
        if opt == "── None ──" then
            selCategoryKey = "none"
        else
            local reg = CATEGORY_MAP[opt]
            if reg then
                selCategoryKey = reg.key
                selMaxLevel    = reg.max
            end
        end
    end,
})

UpgradeTab:CreateInput({
    Name                     = "Up to Level (leave blank = max)",
    PlaceholderText          = "e.g. 3",
    RemoveTextAfterFocusLost = false,
    Flag                     = "BuyCategoryLevel",
    Callback                 = function(text)
        local n = tonumber(text)
        if n then selMaxLevel = math.floor(math.max(1, n)) end
    end,
})

UpgradeTab:CreateButton({
    Name     = "Buy Selected Category",
    Callback = function()
        if selCategoryKey == "none" then
            Rayfield:Notify({ Title = "Error", Content = "Select a category first.", Duration = 3, Image = 4483362458 })
            return
        end
        task.spawn(function()
            local reg = CATEGORY_MAP[selCategoryKey]
            if not reg then return end
            Rayfield:Notify({ Title = "Buying...", Content = reg.label .. " up to level " .. selMaxLevel, Duration = 2, Image = 4483362458 })
            local n = buyCategoryUpTo(selCategoryKey, selMaxLevel)
            Rayfield:Notify({ Title = "Done", Content = "Bought " .. n .. " upgrade(s) from " .. reg.label, Duration = 4, Image = 4483362458 })
        end)
    end,
})

UpgradeTab:CreateSection("Bulk Buy")

UpgradeTab:CreateButton({
    Name     = "Buy All Available",
    Callback = function()
        task.spawn(function()
            Rayfield:Notify({ Title = "Buying...", Content = "Running passes. Please wait.", Duration = 3, Image = 4483362458 })
            local n = buyAllPasses()
            Rayfield:Notify({ Title = "Done!", Content = "Bought " .. n .. " upgrade(s)!", Duration = 5, Image = 4483362458 })
        end)
    end,
})

UpgradeTab:CreateButton({
    Name     = "Buy Main Only",
    Callback = function()
        task.spawn(function()
            local n = buyAllPasses("main")
            Rayfield:Notify({ Title = "Main", Content = n .. " upgrade(s) purchased.", Duration = 3, Image = 4483362458 })
        end)
    end,
})

UpgradeTab:CreateButton({
    Name     = "Buy Loot Tree Only",
    Callback = function()
        task.spawn(function()
            local n = buyAllPasses("lootTree")
            Rayfield:Notify({ Title = "Loot", Content = n .. " upgrade(s) purchased.", Duration = 3, Image = 4483362458 })
        end)
    end,
})

UpgradeTab:CreateButton({
    Name     = "Buy Player Tree Only",
    Callback = function()
        task.spawn(function()
            local n = buyAllPasses("playerTree")
            Rayfield:Notify({ Title = "Player", Content = n .. " upgrade(s) purchased.", Duration = 3, Image = 4483362458 })
        end)
    end,
})

-- ══════════════════════════════════════════════════════
-- // TAB: FARM
-- ══════════════════════════════════════════════════════

local FarmTab = Window:CreateTab("🌾 Farm", nil)

FarmTab:CreateSection("Control")

FarmTab:CreateParagraph({
    Title   = "How Farm Works",
    Content = "Set up to 6 priority slots. Farm always focuses on Priority 1 first. It only moves to Priority 2 when Priority 1 is complete (up to the defined level).",
})

FarmTab:CreateToggle({
    Name         = "🌾 Enable Farm",
    CurrentValue = false,
    Flag         = "FarmEnabled",
    Callback     = function(v)
        State.farmEnabled = v
        Rayfield:Notify({
            Title    = "Farm",
            Content  = v and "Farm enabled! Following priorities." or "Farm disabled.",
            Duration = 3,
            Image    = 4483362458,
        })
    end,
})

FarmTab:CreateButton({
    Name     = "Check Priority Status (F9)",
    Callback = function()
        for i, slot in pairs(State.farmSlots) do
            if slot.key ~= "none" then
                local reg    = CATEGORY_MAP[slot.key]
                local label  = reg and reg.label or slot.key
                local nextId = getNextInCategory(slot.key, slot.maxLevel)
            end
        end
        Rayfield:Notify({ Title = "Farm Status", Content = "Check F9 for details.", Duration = 3, Image = 4483362458 })
    end,
})

-- FIX: resolveDropdown aplicado em todos os slots
for slotNum = 1, 6 do
    local idx = slotNum

    FarmTab:CreateSection("Priority " .. idx)

    FarmTab:CreateDropdown({
        Name          = "P" .. idx .. " — Category",
        Options       = CATEGORY_OPTIONS,
        CurrentOption = {"── None ──"},
        Flag          = "FarmSlot" .. idx .. "Cat",
        Callback      = function(s)
            local opt = resolveDropdown(s)
            if opt == "── None ──" then
                State.farmSlots[idx].key      = "none"
                State.farmSlots[idx].maxLevel = 0
            else
                local reg = CATEGORY_MAP[opt]
                if reg then
                    State.farmSlots[idx].key = reg.key
                    if State.farmSlots[idx].maxLevel == 0 then
                        State.farmSlots[idx].maxLevel = reg.max
                    end
                end
            end
        end,
    })

    FarmTab:CreateInput({
        Name                     = "P" .. idx .. " — Up to Level (blank = max)",
        PlaceholderText          = "e.g. 3 (see Upgrade Info for limits)",
        RemoveTextAfterFocusLost = false,
        Flag                     = "FarmSlot" .. idx .. "Level",
        Callback                 = function(text)
            local n = tonumber(text)
            if n then
                State.farmSlots[idx].maxLevel = math.floor(math.max(1, n))
            else
                local reg = CATEGORY_MAP[State.farmSlots[idx].key]
                if reg then State.farmSlots[idx].maxLevel = reg.max end
            end
        end,
    })
end

-- ══════════════════════════════════════════════════════
-- // TAB: UPGRADE INFO
-- ══════════════════════════════════════════════════════

local InfoTab = Window:CreateTab("📖 Upgrade Info", nil)

InfoTab:CreateSection("🟡 Main Tree")
InfoTab:CreateParagraph({ Title = "Roll Speed",         Content = "rollSpeed1 → rollSpeed6           | Level 1 to 6"   })
InfoTab:CreateParagraph({ Title = "Luck",               Content = "luck1 → luck15                    | Level 1 to 15"  })
InfoTab:CreateParagraph({ Title = "Slots",              Content = "slots2 → slots8                   | Level 2 to 8"   })
InfoTab:CreateParagraph({ Title = "Enemy Count",        Content = "enemyCount2 → enemyCount7         | Level 2 to 7"   })
InfoTab:CreateParagraph({ Title = "Enemy Spawn Speed",  Content = "enemySpawnSpeed1 → 3              | Level 1 to 3"   })
InfoTab:CreateParagraph({ Title = "Golden Rolls",       Content = "goldenRolls → goldenRolls2        | Level 1 to 2"   })
InfoTab:CreateParagraph({ Title = "Diamond Rolls",      Content = "diamondRolls → diamondRolls4      | Level 1 to 4"   })
InfoTab:CreateParagraph({ Title = "Void Rolls",         Content = "voidRolls → voidRolls4            | Level 1 to 4"   })
InfoTab:CreateParagraph({ Title = "Bonus Rolls",        Content = "bonusRolls1 → bonusRolls3         | Level 1 to 3"   })
InfoTab:CreateParagraph({ Title = "Clover Rolls",       Content = "cloverRolls1 → cloverRolls5       | Level 1 to 5"   })
InfoTab:CreateParagraph({ Title = "Friend Luck",        Content = "friendLuck1 → friendLuck9         | Level 1 to 9"   })
InfoTab:CreateParagraph({ Title = "Friend Luck Boost",  Content = "friendLuckBoost1 → 4              | Level 1 to 4"   })
InfoTab:CreateParagraph({ Title = "Extra Roll Chance",  Content = "extraRollChance1 → 3              | Level 1 to 3"   })
InfoTab:CreateParagraph({ Title = "Slime Target Range", Content = "slimeTargetRange1 → 3             | Level 1 to 3"   })
InfoTab:CreateParagraph({ Title = "Goop Drop Rate",     Content = "goopDropRate1 → goopDropRate6     | Level 1 to 6"   })
InfoTab:CreateParagraph({ Title = "Overkill",           Content = "overkill1 → overkill8             | Level 1 to 8"   })
InfoTab:CreateParagraph({ Title = "Walk Speed",         Content = "walkSpeed1 → walkSpeed3           | Level 1 to 3"   })
InfoTab:CreateParagraph({ Title = "Unique Upgrades",    Content = "autoRoll | backpack | goop | bigSlimes | shinySlimes | hugeSlimes | invertedSlimes | bossChance  |  Level 1 (unique)" })

InfoTab:CreateSection("🟢 Loot Tree")
InfoTab:CreateParagraph({ Title = "Food Chain",   Content = "lootApple → lootCarrot → lootCherries → lootGrapes → lootBanana → lootWatermelon → lootPizza → lootChicken → lootDrumstick  |  9 chained upgrades" })
InfoTab:CreateParagraph({ Title = "Coin Income",  Content = "coinIncome1 → coinIncome13              | Level 1 to 13"  })
InfoTab:CreateParagraph({ Title = "Offline Loot", Content = "offlineLootAmount1 → 5                 | Level 1 to 5"   })
InfoTab:CreateParagraph({ Title = "Unique",       Content = "lootLuck | lootCurrency | lootRollSpeed | lootUltraLuck  |  Level 1 (unique)" })

InfoTab:CreateSection("🔵 Player Tree")
InfoTab:CreateParagraph({ Title = "Overkill",   Content = "overkill1 → overkill8                    | Level 1 to 8"   })
InfoTab:CreateParagraph({ Title = "Walk Speed", Content = "walkSpeed1 → walkSpeed3                  | Level 1 to 3"   })
InfoTab:CreateParagraph({ Title = "Unique",     Content = "bigSlimes | shinySlimes | hugeSlimes | invertedSlimes | backpack  |  Level 1 (unique)" })

InfoTab:CreateSection("💡 Farm Tip")
InfoTab:CreateParagraph({
    Title   = "Recommended Farm Order",
    Content = "P1: Main: Roll Speed ×6 → P2: Main: Luck ×15 → P3: Main: Enemy Count ×6 → P4: Loot: Food Chain ×9 → P5: Loot: Coin Income ×13 → P6: Main: Slots ×7",
})

-- ══════════════════════════════════════════════════════
-- // MAIN LOOP
-- ══════════════════════════════════════════════════════

task.spawn(function()
    local rollTick    = 0
    local upgradeTick = 0
    local collectTick = 0
    local zoneTick    = 0
    local farmTick    = 0
    local indexTick   = 0
    local rebirthTick = 0

    local UPGRADE_INTERVAL_PRIMARY   = 3
    local UPGRADE_INTERVAL_SECONDARY = 15
    local ZONE_INTERVAL_PRIMARY      = 2
    local ZONE_INTERVAL_SECONDARY    = 10

    while true do
        local now = tick()

        -- AUTO ROLL
        if State.autoRoll and (now - rollTick) >= State.rollDelay then
            rollTick = now
            doRoll()
            if State.autoEquip then doEquipBest() end
        end

        -- FARM
        if State.farmEnabled and (now - farmTick) >= 0.5 then
            farmTick = now
            task.spawn(farmStep)
        end

        -- AUTO UPGRADE — FIX: só roda se farmStep não estiver ocupado
        if State.autoUpgrade and not State.upgradeRunning then
            local interval = State.farmPriority == "upgrade"
                and UPGRADE_INTERVAL_PRIMARY or UPGRADE_INTERVAL_SECONDARY
            if (now - upgradeTick) >= interval then
                upgradeTick = now
                task.spawn(buyAllPasses)  -- ← buyAllPasses já tem mutex interno
            end
        end

        -- AUTO COLLECT
        if State.autoCollect and (now - collectTick) >= 0.5 then
            collectTick = now
            task.spawn(collectAllLoot)
        end

        -- AUTO ZONE — FIX: mutex zoneRunning já garante que não dispara 2x
        if State.autoZone and not State.zoneRunning then
            local interval = State.farmPriority == "zone"
                and ZONE_INTERVAL_PRIMARY or ZONE_INTERVAL_SECONDARY
            if (now - zoneTick) >= interval then
                zoneTick = now
                task.spawn(doPurchaseZone)
            end
        end

        -- AUTO INDEX REWARDS
        if State.autoIndexReward and (now - indexTick) >= 30 then
            indexTick = now
            task.spawn(function()
                local types = {"big", "huge", "shiny", "inverted"}
                for _, t in pairs(types) do
                    pcall(function() IndexRemote:InvokeServer("requestClaimReward", t) end)
                    task.wait(0.2)
                end
            end)
        end

        -- AUTO REBIRTH
        if State.autoRebirth and (now - rebirthTick) >= 5 then
            rebirthTick = now
            task.spawn(function()
                local ok, result = pcall(function()
                    return RebirthRemote:InvokeServer("requestRebirth")
                end)
                if ok and result then
                    Rayfield:Notify({ Title = "♻️ Rebirth!", Content = "Rebirth successful!", Duration = 4, Image = 4483362458 })
                end
            end)
        end

        task.wait(0.01)
    end
end)

-- ══════════════════════════════════════════════════════
-- // READY
-- ══════════════════════════════════════════════════════

Rayfield:Notify({
    Title    = "✅ Slime Fun Hub Ready!",
    Content  = "Roll · Farm · Collect · Zone · Mob — all loaded!",
    Duration = 5,
    Image    = 4483362458,
})
