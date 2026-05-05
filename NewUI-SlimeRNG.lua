-- ══════════════════════════════════════════════════════
-- // SLIME FUN GUI - MacLib Interface
-- ══════════════════════════════════════════════════════

local MacLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/NickolasFrutuoso/MacUI/refs/heads/main/UI"))()

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
local BoostRemote     = getRemote("BoostService")

local USC         = require(RS.Source.Features.Upgrades.UpgradeServiceClient)
local UpgradeTree = require(RS.Source.Features.Upgrades.UpgradeTree)

-- ══════════════════════════════════════════════════════
-- // CONSTANTS
-- ══════════════════════════════════════════════════════

local FRUITS = {
    "apple", "carrot", "cherries", "grapes", "banana",
    "watermelon", "pizza", "chicken", "drumstick"
}

local ALL_BOOSTS = {
    { id = "luck",         label = "Lucky Boost"       },
    { id = "ultraLuck",    label = "Ultra Lucky Boost" },
    { id = "currency",     label = "Currency Boost"    },
    { id = "rollSpeed",    label = "Roll Speed Boost"  },
    { id = "jackpotSpin",  label = "Jackpot Spin"      },
    { id = "bigDice",      label = "Big Dice"          },
    { id = "hugeDice",     label = "Huge Dice"         },
    { id = "shinyDice",    label = "Shiny Dice"        },
    { id = "invertedDice", label = "Inverted Dice"     },
}

-- ══════════════════════════════════════════════════════
-- // UPGRADE REGISTRY
-- ══════════════════════════════════════════════════════

local UPGRADE_REGISTRY = {
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
    {key="lootChain",        tree="lootTree",   label="Loot: Food Chain",         max=9,  ids={"lootApple","lootCarrot","lootCherries","lootGrapes","lootBanana","lootWatermelon","lootPizza","lootChicken","lootDrumstick"}},
    {key="coinIncome",       tree="lootTree",   label="Loot: Coin Income",        max=13, ids={"coinIncome1","coinIncome2","coinIncome3","coinIncome4","coinIncome5","coinIncome6","coinIncome7","coinIncome8","coinIncome9","coinIncome10","coinIncome11","coinIncome12","coinIncome13"}},
    {key="offlineLoot",      tree="lootTree",   label="Loot: Offline Loot",       max=5,  ids={"offlineLootAmount1","offlineLootAmount2","offlineLootAmount3","offlineLootAmount4","offlineLootAmount5"}},
    {key="lootLuck",         tree="lootTree",   label="Loot: Luck",               max=1,  ids={"lootLuck"}},
    {key="lootCurrency",     tree="lootTree",   label="Loot: Currency",           max=1,  ids={"lootCurrency"}},
    {key="lootRollSpeed",    tree="lootTree",   label="Loot: Roll Speed",         max=1,  ids={"lootRollSpeed"}},
    {key="lootUltraLuck",    tree="lootTree",   label="Loot: Ultra Luck",         max=1,  ids={"lootUltraLuck"}},
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
    autoRoll        = false,
    autoEquip       = false,
    autoCollect     = false,
    autoZone        = false,
    autoUpgrade     = false,
    farmEnabled     = false,
    autoMob         = false,
    autoIndexReward = false,
    autoRebirth     = false,
    autoFeed        = false,
    autoBoost       = false,

    -- { [slimeId] = true }
    selectedSlimes  = {},
    -- { [boostId] = true }
    selectedBoosts  = {},

    rollDelay       = 0.05,
    farmPriority    = "upgrade",
    upgradePriority = "all",
    upgradeOrder    = "cost",
    mobMode         = "fly",
    flySpeed        = 80,
    mobCooldown     = 0.3,

    farmSlots = {
        {key = "none", maxLevel = 0},
        {key = "none", maxLevel = 0},
        {key = "none", maxLevel = 0},
        {key = "none", maxLevel = 0},
        {key = "none", maxLevel = 0},
        {key = "none", maxLevel = 0},
    },

    rollCount      = 0,
    upgradeCount   = 0,
    collectCount   = 0,
    zoneCount      = 0,
    mobCount       = 0,
    currentMobName = "None",

    zoneRunning    = false,
    upgradeRunning = false,
}

-- ══════════════════════════════════════════════════════
-- // BASE HELPERS
-- ══════════════════════════════════════════════════════

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
    if success then State.upgradeCount += 1 end
    return success
end

-- ══════════════════════════════════════════════════════
-- // AUTO FEED HELPERS
-- ══════════════════════════════════════════════════════

local function getEquippedSlimes()
    local slimes = {}
    for _, gameplay in pairs(workspace:GetChildren()) do
        if gameplay.Name:find("Gameplay") then
            local folder = gameplay:FindFirstChild("Slimes")
            if folder then
                for _, slime in pairs(folder:GetChildren()) do
                    local uniqueId = slime.Name:match("^(.-)#%d+$")
                    if uniqueId then
                        local displayName = uniqueId
                        local billboard = slime:FindFirstChild("SlimeInfoBillboard")
                        if billboard then
                            for _, v in pairs(billboard:GetDescendants()) do
                                if (v:IsA("TextLabel") or v:IsA("TextBox")) and v.Name == "Name" then
                                    displayName = v.Text
                                    break
                                end
                            end
                        end
                        table.insert(slimes, { id = uniqueId, name = displayName })
                    end
                end
            end
        end
    end
    return slimes
end

local function feedSlime(slimeId, foodId)
    local ok, r = pcall(function()
        return InventoryRemote:InvokeServer("requestUseFood", foodId, slimeId, 1)
    end)
    return ok and r == true
end

local function feedSelectedSlimes()
    for slimeId, enabled in pairs(State.selectedSlimes) do
        if enabled then
            for _, food in pairs(FRUITS) do
                feedSlime(slimeId, food)
                task.wait(0.05)
            end
        end
    end
end

-- ══════════════════════════════════════════════════════
-- // AUTO BOOST HELPERS
-- ══════════════════════════════════════════════════════

local function useBoost(boostId)
    local ok, r = pcall(function()
        return BoostRemote:InvokeServer("requestUseBoost", boostId)
    end)
    return ok and r == true
end

local function useSelectedBoosts()
    for boostId, enabled in pairs(State.selectedBoosts) do
        if enabled then
            useBoost(boostId)
            task.wait(0.1)
        end
    end
end

-- ══════════════════════════════════════════════════════
-- // ZONE SYSTEM
-- ══════════════════════════════════════════════════════

local function getZoneByNumber(num)
    for _, zone in pairs(workspace.Zones:GetChildren()) do
        if tonumber(zone.Name) == num then return zone end
    end
    return nil
end

local function teleportToZone(zone)
    if not zone then return end
    local poi   = zone:FindFirstChild("POI")
    if not poi  then return end
    local spawn = poi:FindFirstChild("PlayerSpawn")
    if not spawn then return end
    local char  = player.Character
    if not char  then return end
    local rp    = char:FindFirstChild("HumanoidRootPart")
    if not rp    then return end
    rp.CFrame = CFrame.new(spawn.Position + Vector3.new(0, 4, 0))
end

local function getPlayerCurrentZone()
    local char = player.Character
    local rp   = char and char:FindFirstChild("HumanoidRootPart")
    if not rp then return 1 end
    local closest, closestDist = 1, math.huge
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

local function doPurchaseZone(Window)
    if State.zoneRunning then return false end
    State.zoneRunning = true
    local zoneBefore  = getPlayerCurrentZone()
    local ok, result  = pcall(function() return ZoneRemote:InvokeServer("requestPurchaseZone") end)
    local success     = ok and result == true
    if success then
        State.zoneCount += 1
        local newZoneNum = zoneBefore + 1
        task.wait(1.0)
        local zone = getZoneByNumber(newZoneNum)
        if not zone then
            Window:Notify({ Title = "Zone", Description = "Zone " .. newZoneNum .. " not found!", Lifetime = 3 })
            State.zoneRunning = false
            return false
        end
        teleportToZone(zone)
        Window:Notify({ Title = "🗺️ New Zone!", Description = "Zone " .. newZoneNum .. " unlocked! Teleporting...", Lifetime = 4 })
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
        local ok, result = pcall(function() return LootRemote:InvokeServer("requestCollect", item.Name) end)
        if ok and result == true then
            collected          += 1
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
    local char    = player.Character
    if not char   then return nil end
    local rp      = char:FindFirstChild("HumanoidRootPart")
    if not rp     then return nil end
    local closest, closestDist = nil, math.huge
    for _, mob in pairs(Enemies:GetChildren()) do
        if mob:IsA("Model") and isMobAlive(mob) then
            local root = getMobRoot(mob)
            if root then
                local dist = (root.Position - rp.Position).Magnitude
                if dist < closestDist then closestDist = dist; closest = mob end
            end
        end
    end
    return closest
end

local function teleportToMob(mob)
    local char = player.Character
    if not char then return end
    local rp   = char:FindFirstChild("HumanoidRootPart")
    local root = getMobRoot(mob)
    if not rp or not root then return end
    rp.CFrame = CFrame.new(root.Position + Vector3.new(3, 2, 3))
end

local function stopFly()
    if mobFlyConn then mobFlyConn:Disconnect(); mobFlyConn = nil end
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local rp  = char:FindFirstChild("HumanoidRootPart")
        if hum then hum.PlatformStand = false end
        if rp  then rp.AssemblyLinearVelocity = Vector3.zero end
    end
end

local function flyToMob(mob, onArrived)
    stopFly()
    local char = player.Character
    if not char then return end
    local rp  = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not rp or not hum then return end
    hum.PlatformStand = true
    local arrived       = false
    local rcParams      = RaycastParams.new()
    rcParams.FilterType = Enum.RaycastFilterType.Exclude
    mobFlyConn = RunService.Heartbeat:Connect(function()
        if arrived then return end
        if not isMobAlive(mob) then
            arrived = true; stopFly()
            if onArrived then onArrived(true) end
            return
        end
        local target = getMobRoot(mob)
        if not target then
            arrived = true; stopFly()
            if onArrived then onArrived(false) end
            return
        end
        local charPos   = rp.Position
        local targetPos = target.Position + Vector3.new(0, 2, 0)
        local dir       = targetPos - charPos
        local dist      = dir.Magnitude
        if dist < 4 then
            arrived = true; stopFly()
            if onArrived then onArrived(true) end
            return
        end
        local unitDir = dir.Unit
        rcParams.FilterDescendantsInstances = {char, mob}
        local hit     = workspace:Raycast(charPos, unitDir * math.min(dist, 8), rcParams)
        local moveDir = unitDir
        if hit then
            local alts = {
                Vector3.new(unitDir.X,  0.8,  unitDir.Z).Unit,
                Vector3.new(-unitDir.Z, 0.3,  unitDir.X).Unit,
                Vector3.new( unitDir.Z, 0.3, -unitDir.X).Unit,
            }
            local found = false
            for _, alt in pairs(alts) do
                if not workspace:Raycast(charPos, alt * 8, rcParams) then
                    moveDir = alt; found = true; break
                end
            end
            if not found then moveDir = Vector3.new(unitDir.X, 1, unitDir.Z).Unit end
        end
        rp.AssemblyLinearVelocity = moveDir * State.flySpeed
    end)
end

local function autoMobStep()
    if not State.autoMob then return end
    local mob = getClosestMob()
    if not mob then
        State.currentMobName = "None"
        task.wait(0.5)
        if State.autoMob then autoMobStep() end
        return
    end
    State.currentMobName = mob.Name
    if State.mobMode == "teleport" then
        teleportToMob(mob)
        local elapsed = 0
        repeat task.wait(0.1); elapsed += 0.1
        until not isMobAlive(mob) or elapsed >= 10 or not State.autoMob
        State.mobCount += 1
        task.wait(State.mobCooldown)
        if State.autoMob then autoMobStep() end
    elseif State.mobMode == "fly" then
        local done = false
        flyToMob(mob, function() done = true end)
        local elapsed = 0
        repeat task.wait(0.1); elapsed += 0.1
        until done or not isMobAlive(mob) or elapsed >= 15 or not State.autoMob
        stopFly()
        if isMobAlive(mob) then
            elapsed = 0
            repeat
                task.wait(0.1); elapsed += 0.1
                local root = getMobRoot(mob)
                local char = player.Character
                local crp  = char and char:FindFirstChild("HumanoidRootPart")
                if root and crp and (root.Position - crp.Position).Magnitude > 10 then
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
-- // HUB
-- ══════════════════════════════════════════════════════

local HUB = MacLib:CreateHUB({
    Title    = "Noliar HUB",
    Subtitle = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name,

    OnTabGroup = function(TabGroup, Window)

        -- ════════════════════════════════════════════
        -- TAB: MAIN
        -- ════════════════════════════════════════════

        local MainTab = TabGroup:Tab({ Name = "Main" })

        -- ── Coluna Left ──────────────────────────────

        local RollSection = MainTab:Section({ Side = "Left" })

        RollSection:Header({ Name = "Auto Roll" })

        RollSection:Toggle({
            Name     = "Enable Auto Roll",
            Default  = false,
            Callback = function(v) State.autoRoll = v end,
        }, "AutoRoll")

        RollSection:Toggle({
            Name     = "Auto Equip Best Slimes",
            Default  = false,
            Callback = function(v) State.autoEquip = v end,
        }, "AutoEquip")

        RollSection:Slider({
            Name     = "Roll Delay",
            Minimum  = 5,
            Maximum  = 500,
            Default  = 50,
            Suffix   = "ms",
            Callback = function(v) State.rollDelay = v / 1000 end,
        }, "RollDelay")

        -- ── AUTO FEED ────────────────────────────────

        RollSection:Divider()
        RollSection:Header({ Name = "Auto Feed" })

        RollSection:Toggle({
            Name     = "Enable Auto Feed",
            Default  = false,
            Callback = function(v)
                State.autoFeed = v
                Window:Notify({
                    Title       = "Auto Feed",
                    Description = v and "Alimentando slimes selecionados a cada 2s." or "Desativado.",
                    Lifetime    = 3,
                })
            end,
        }, "AutoFeed")

        -- Dropdown multi-select de slimes — preenchido dinamicamente
        local slimeLabelToId = {}  -- label -> uniqueId

        local function buildSlimeOptions()
            slimeLabelToId = {}
            local opts = {}
            for _, s in pairs(getEquippedSlimes()) do
                local label = s.name .. " (" .. s.id:sub(1, 6) .. ")"
                slimeLabelToId[label] = s.id
                table.insert(opts, label)
            end
            if #opts == 0 then
                table.insert(opts, "Nenhum slime equipado")
            end
            return opts
        end

        local slimeDropdown = RollSection:Dropdown({
            Name     = "Slimes — Selecionar (multi)",
            Options  = buildSlimeOptions(),
            Default  = {},
            Multi    = true,
            Callback = function(selected)
                -- selected = { ["label"] = true/false, ... }
                State.selectedSlimes = {}
                for label, active in pairs(selected) do
                    if active then
                        local id = slimeLabelToId[label]
                        if id then
                            State.selectedSlimes[id] = true
                        end
                    end
                end
            end,
        }, "FeedSlimeDropdown")

        -- ── AUTO BOOST ───────────────────────────────

        RollSection:Divider()
        RollSection:Header({ Name = "Auto Boost" })

        RollSection:Toggle({
            Name     = "Enable Auto Boost",
            Default  = false,
            Callback = function(v)
                State.autoBoost = v
                Window:Notify({
                    Title       = "Auto Boost",
                    Description = v and "Usando boosts selecionados a cada 30s." or "Desativado.",
                    Lifetime    = 3,
                })
            end,
        }, "AutoBoost")

        -- Monta labels dos boosts para o dropdown
        local boostLabelToId = {}
        local function buildBoostOptions()
            boostLabelToId = {}
            local opts = {}
            for _, boost in pairs(ALL_BOOSTS) do
                boostLabelToId[boost.label] = boost.id
                table.insert(opts, boost.label)
            end
            return opts
        end

        local boostDropdown = RollSection:Dropdown({
            Name     = "Boosts — Selecionar (multi)",
            Options  = buildBoostOptions(),
            Default  = {},
            Multi    = true,
            Callback = function(selected)
                -- selected = { ["label"] = true/false, ... }
                State.selectedBoosts = {}
                for label, active in pairs(selected) do
                    if active then
                        local id = boostLabelToId[label]
                        if id then
                            State.selectedBoosts[id] = true
                        end
                    end
                end
            end,
        }, "BoostDropdown")

        -- ── REFRESH ──────────────────────────────────

        RollSection:Divider()

        RollSection:Button({
            Name     = "🔄 Refresh Slimes & Boosts",
            Callback = function()
                -- Reconstrói as opções de slimes
                local newSlimeOpts = buildSlimeOptions()
                slimeDropdown:ClearOptions()
                slimeDropdown:InsertOptions(newSlimeOpts)
                -- Limpa seleção anterior (IDs podem ter mudado)
                State.selectedSlimes = {}

                -- Reconstrói as opções de boosts (lista fixa, mas reseta seleção)
                local newBoostOpts = buildBoostOptions()
                boostDropdown:ClearOptions()
                boostDropdown:InsertOptions(newBoostOpts)
                State.selectedBoosts = {}

                Window:Notify({
                    Title       = "🔄 Atualizado!",
                    Description = #newSlimeOpts .. " slime(s) encontrado(s). Selecione novamente.",
                    Lifetime    = 4,
                })
            end,
        })

        -- ── Auto Collect ──────────────────────────────

        RollSection:Divider()
        RollSection:Header({ Name = "Auto Collect" })

        RollSection:Toggle({
            Name     = "Enable Auto Collect",
            Default  = false,
            Callback = function(v) State.autoCollect = v end,
        }, "AutoCollect")

        RollSection:Divider()
        RollSection:Header({ Name = "Manual Actions" })

        RollSection:Button({
            Name     = "Roll Once",
            Callback = function()
                Window:Notify({ Title = "Roll", Description = doRoll() and "Rolled!" or "Failed.", Lifetime = 2 })
            end,
        })

        RollSection:Button({
            Name     = "Equip Best Now",
            Callback = function()
                doEquipBest()
                Window:Notify({ Title = "Equipped", Description = "Best slimes equipped!", Lifetime = 2 })
            end,
        })

        RollSection:Button({
            Name     = "Collect All Now",
            Callback = function()
                task.spawn(function()
                    local n = collectAllLoot()
                    Window:Notify({ Title = "Collect", Description = "Collected " .. n .. " item(s)!", Lifetime = 3 })
                end)
            end,
        })

        RollSection:Button({
            Name     = "Buy Next Zone",
            Callback = function()
                task.spawn(function()
                    if not doPurchaseZone(Window) then
                        Window:Notify({ Title = "Zone", Description = "Not enough money or already running.", Lifetime = 3 })
                    end
                end)
            end,
        })

        -- ── Coluna Right ─────────────────────────────

        local MobSection = MainTab:Section({ Side = "Right" })

        MobSection:Header({ Name = "Auto Mob" })

        MobSection:Toggle({
            Name     = "Enable Auto Mob",
            Default  = false,
            Callback = function(v)
                State.autoMob = v
                if v then
                    Window:Notify({ Title = "Auto Mob", Description = "Enabled! Mode: " .. State.mobMode, Lifetime = 3 })
                    task.spawn(autoMobStep)
                else
                    stopFly()
                    State.currentMobName = "None"
                    Window:Notify({ Title = "Auto Mob", Description = "Disabled.", Lifetime = 2 })
                end
            end,
        }, "AutoMob")

        MobSection:Dropdown({
            Name     = "Mob Mode",
            Options  = {"Fly", "Teleport"},
            Default  = 1,
            Callback = function(v)
                State.mobMode = v == "Fly" and "fly" or "teleport"
            end,
        }, "MobMode")

        MobSection:Slider({
            Name     = "Fly Speed",
            Minimum  = 20,
            Maximum  = 300,
            Default  = 80,
            Suffix   = " studs/s",
            Callback = function(v) State.flySpeed = v end,
        }, "FlySpeed")

        MobSection:Slider({
            Name     = "Mob Cooldown",
            Minimum  = 0,
            Maximum  = 200,
            Default  = 300,
            Suffix   = "ms",
            Callback = function(v) State.mobCooldown = v / 1000 end,
        }, "MobCooldown")

        MobSection:Divider()
        MobSection:Header({ Name = "Auto Zone" })

        MobSection:Toggle({
            Name     = "Enable Auto Zone",
            Default  = false,
            Callback = function(v) State.autoZone = v end,
        }, "AutoZone")

        MobSection:Dropdown({
            Name     = "Farm Priority",
            Options  = {"Upgrade First", "Zone First"},
            Default  = 1,
            Callback = function(v)
                State.farmPriority = v == "Zone First" and "zone" or "upgrade"
            end,
        }, "FarmPriority")

        MobSection:Divider()
        MobSection:Header({ Name = "Index Rewards" })

        MobSection:Toggle({
            Name     = "Auto Claim Index Rewards",
            Default  = false,
            Callback = function(v)
                State.autoIndexReward = v
                Window:Notify({ Title = "Index Rewards", Description = v and "Auto claiming enabled!" or "Disabled.", Lifetime = 2 })
            end,
        }, "AutoIndexReward")

        MobSection:Button({
            Name     = "Claim All Index Rewards Now",
            Callback = function()
                task.spawn(function()
                    local types   = {"basic","big","huge","shiny","inverted"}
                    local claimed = 0
                    for _, t in pairs(types) do
                        local ok, result = pcall(function() return IndexRemote:InvokeServer("requestClaimReward", t) end)
                        if ok and result then claimed += 1 end
                        task.wait(0.2)
                    end
                    Window:Notify({ Title = "Index Rewards", Description = claimed > 0 and "Claimed " .. claimed .. " reward(s)!" or "No rewards available.", Lifetime = 3 })
                end)
            end,
        })

        MobSection:Divider()
        MobSection:Header({ Name = "Rebirth" })

        MobSection:Toggle({
            Name     = "Auto Rebirth",
            Default  = false,
            Callback = function(v)
                State.autoRebirth = v
                Window:Notify({ Title = "Auto Rebirth", Description = v and "Enabled!" or "Disabled.", Lifetime = 2 })
            end,
        }, "AutoRebirth")

        MobSection:Button({
            Name     = "Rebirth Now",
            Callback = function()
                task.spawn(function()
                    local ok, result = pcall(function() return RebirthRemote:InvokeServer("requestRebirth") end)
                    if ok and result then
                        Window:Notify({ Title = "Rebirth", Description = "Rebirth successful!", Lifetime = 3 })
                    else
                        Window:Notify({ Title = "Rebirth", Description = "Requirements not met yet.", Lifetime = 3 })
                    end
                end)
            end,
        })

        -- ════════════════════════════════════════════
        -- TAB: UPGRADES
        -- ════════════════════════════════════════════

        local UpgradeTab = TabGroup:Tab({ Name = "Upgrades" })

        local UpgSettingsSection = UpgradeTab:Section({ Side = "Left" })

        UpgSettingsSection:Header({ Name = "Auto Upgrade" })

        UpgSettingsSection:Paragraph({
            Header = "How it works",
            Body   = "Automatically purchases all available upgrades. Configure the tree and purchase order below.",
        })

        UpgSettingsSection:Toggle({
            Name     = "Enable Auto Upgrade",
            Default  = false,
            Callback = function(v) State.autoUpgrade = v end,
        }, "AutoUpgrade")

        UpgSettingsSection:Dropdown({
            Name     = "Tree",
            Options  = {"All", "Main", "Loot", "Player"},
            Default  = 1,
            Callback = function(v)
                local map = {["All"]="all", ["Main"]="main", ["Loot"]="lootTree", ["Player"]="playerTree"}
                State.upgradePriority = map[v] or "all"
            end,
        }, "UpgradePriority")

        UpgSettingsSection:Dropdown({
            Name     = "Purchase Order",
            Options  = {"Cheapest First", "Dependency Order"},
            Default  = 1,
            Callback = function(v)
                State.upgradeOrder = v == "Cheapest First" and "cost" or "dependency"
            end,
        }, "UpgradeOrder")

        UpgSettingsSection:Divider()
        UpgSettingsSection:Header({ Name = "Bulk Buy" })

        UpgSettingsSection:Button({
            Name     = "Buy All Available",
            Callback = function()
                task.spawn(function()
                    Window:Notify({ Title = "Buying...", Description = "Running passes. Please wait.", Lifetime = 3 })
                    local n = buyAllPasses()
                    Window:Notify({ Title = "Done!", Description = "Bought " .. n .. " upgrade(s)!", Lifetime = 5 })
                end)
            end,
        })

        UpgSettingsSection:Button({
            Name     = "Buy Main Only",
            Callback = function()
                task.spawn(function()
                    local n = buyAllPasses("main")
                    Window:Notify({ Title = "Main", Description = n .. " upgrade(s) purchased.", Lifetime = 3 })
                end)
            end,
        })

        UpgSettingsSection:Button({
            Name     = "Buy Loot Tree Only",
            Callback = function()
                task.spawn(function()
                    local n = buyAllPasses("lootTree")
                    Window:Notify({ Title = "Loot", Description = n .. " upgrade(s) purchased.", Lifetime = 3 })
                end)
            end,
        })

        UpgSettingsSection:Button({
            Name     = "Buy Player Tree Only",
            Callback = function()
                task.spawn(function()
                    local n = buyAllPasses("playerTree")
                    Window:Notify({ Title = "Player", Description = n .. " upgrade(s) purchased.", Lifetime = 3 })
                end)
            end,
        })

        local CatSection = UpgradeTab:Section({ Side = "Right" })

        CatSection:Header({ Name = "Buy by Category" })

        CatSection:Paragraph({
            Header = "How to use",
            Body   = "Select a category and set the max level. Upgrades are bought in order: e.g. rollSpeed1 → rollSpeed2 → ...",
        })

        local selCategoryKey = "none"
        local selMaxLevel    = 1

        CatSection:Dropdown({
            Name     = "Category",
            Options  = CATEGORY_OPTIONS,
            Default  = 1,
            Search   = true,
            Callback = function(v)
                if v == "── None ──" then
                    selCategoryKey = "none"
                else
                    local reg = CATEGORY_MAP[v]
                    if reg then
                        selCategoryKey = reg.key
                        selMaxLevel    = reg.max
                    end
                end
            end,
        }, "BuyCategorySelect")

        CatSection:Input({
            Name               = "Up to Level (blank = max)",
            Placeholder        = "e.g. 3",
            AcceptedCharacters = "Numeric",
            Callback           = function(text)
                local n = tonumber(text)
                if n then selMaxLevel = math.floor(math.max(1, n)) end
            end,
        }, "BuyCategoryLevel")

        CatSection:Button({
            Name     = "Buy Selected Category",
            Callback = function()
                if selCategoryKey == "none" then
                    Window:Notify({ Title = "Error", Description = "Select a category first.", Lifetime = 3 })
                    return
                end
                task.spawn(function()
                    local reg = CATEGORY_MAP[selCategoryKey]
                    if not reg then return end
                    Window:Notify({ Title = "Buying...", Description = reg.label .. " up to level " .. selMaxLevel, Lifetime = 2 })
                    local n = buyCategoryUpTo(selCategoryKey, selMaxLevel)
                    Window:Notify({ Title = "Done", Description = "Bought " .. n .. " upgrade(s) from " .. reg.label, Lifetime = 4 })
                end)
            end,
        })

        -- ════════════════════════════════════════════
        -- TAB: FARM
        -- ════════════════════════════════════════════

        local FarmTab = TabGroup:Tab({ Name = "Farm" })

        local FarmInfoSection = FarmTab:Section({ Side = "Left" })

        FarmInfoSection:Header({ Name = "Farm Control" })

        FarmInfoSection:Paragraph({
            Header = "How Farm Works",
            Body   = "Set up to 6 priority slots. Farm always focuses on Priority 1 first and only moves to the next when complete.",
        })

        FarmInfoSection:Toggle({
            Name     = "Enable Farm",
            Default  = false,
            Callback = function(v)
                State.farmEnabled = v
                Window:Notify({ Title = "Farm", Description = v and "Farm enabled! Following priorities." or "Farm disabled.", Lifetime = 3 })
            end,
        }, "FarmEnabled")

        FarmInfoSection:Divider()
        FarmInfoSection:Header({ Name = "Recommended Order" })

        FarmInfoSection:Paragraph({
            Header = "Tip",
            Body   = "P1: Roll Speed ×6 → P2: Luck ×15 → P3: Enemy Count ×6 → P4: Loot Food Chain ×9 → P5: Coin Income ×13 → P6: Slots ×7",
        })

        local farmSections = {
            FarmTab:Section({ Side = "Left" }),
            FarmTab:Section({ Side = "Left" }),
            FarmTab:Section({ Side = "Left" }),
            FarmTab:Section({ Side = "Right" }),
            FarmTab:Section({ Side = "Right" }),
            FarmTab:Section({ Side = "Right" }),
        }

        for slotNum = 1, 6 do
            local idx = slotNum
            local sec = farmSections[idx]

            sec:Header({ Name = "Priority " .. idx })

            sec:Dropdown({
                Name     = "P" .. idx .. " — Category",
                Options  = CATEGORY_OPTIONS,
                Default  = 1,
                Search   = true,
                Callback = function(v)
                    if v == "── None ──" then
                        State.farmSlots[idx].key      = "none"
                        State.farmSlots[idx].maxLevel = 0
                    else
                        local reg = CATEGORY_MAP[v]
                        if reg then
                            State.farmSlots[idx].key = reg.key
                            if State.farmSlots[idx].maxLevel == 0 then
                                State.farmSlots[idx].maxLevel = reg.max
                            end
                        end
                    end
                end,
            }, "FarmSlot" .. idx .. "Cat")

            sec:Input({
                Name               = "P" .. idx .. " — Up to Level (blank = max)",
                Placeholder        = "e.g. 3",
                AcceptedCharacters = "Numeric",
                Callback           = function(text)
                    local n = tonumber(text)
                    if n then
                        State.farmSlots[idx].maxLevel = math.floor(math.max(1, n))
                    else
                        local reg = CATEGORY_MAP[State.farmSlots[idx].key]
                        if reg then State.farmSlots[idx].maxLevel = reg.max end
                    end
                end,
            }, "FarmSlot" .. idx .. "Level")
        end

        -- ════════════════════════════════════════════
        -- TAB: INFO
        -- ════════════════════════════════════════════

        local InfoTab = TabGroup:Tab({ Name = "Info" })

        local InfoLeft  = InfoTab:Section({ Side = "Left" })
        local InfoRight = InfoTab:Section({ Side = "Right" })

        InfoLeft:Header({ Name = "🟡 Main Tree" })
        InfoLeft:Paragraph({ Header = "Roll Speed",         Body = "rollSpeed1 → rollSpeed6  |  Levels 1–6"   })
        InfoLeft:Paragraph({ Header = "Luck",               Body = "luck1 → luck15  |  Levels 1–15"           })
        InfoLeft:Paragraph({ Header = "Slots",              Body = "slots2 → slots8  |  Levels 2–8"           })
        InfoLeft:Paragraph({ Header = "Enemy Count",        Body = "enemyCount2 → enemyCount7  |  Levels 2–7" })
        InfoLeft:Paragraph({ Header = "Enemy Spawn Speed",  Body = "enemySpawnSpeed1 → 3  |  Levels 1–3"      })
        InfoLeft:Paragraph({ Header = "Golden Rolls",       Body = "goldenRolls → goldenRolls2  |  Levels 1–2"})
        InfoLeft:Paragraph({ Header = "Diamond Rolls",      Body = "diamondRolls → diamondRolls4  |  Lvl 1–4" })
        InfoLeft:Paragraph({ Header = "Void Rolls",         Body = "voidRolls → voidRolls4  |  Levels 1–4"    })
        InfoLeft:Paragraph({ Header = "Bonus Rolls",        Body = "bonusRolls1 → bonusRolls3  |  Levels 1–3" })
        InfoLeft:Paragraph({ Header = "Clover Rolls",       Body = "cloverRolls1 → cloverRolls5  |  Lvl 1–5"  })
        InfoLeft:Paragraph({ Header = "Friend Luck",        Body = "friendLuck1 → friendLuck9  |  Levels 1–9" })
        InfoLeft:Paragraph({ Header = "Friend Luck Boost",  Body = "friendLuckBoost1 → 4  |  Levels 1–4"      })
        InfoLeft:Paragraph({ Header = "Extra Roll Chance",  Body = "extraRollChance1 → 3  |  Levels 1–3"      })
        InfoLeft:Paragraph({ Header = "Slime Target Range", Body = "slimeTargetRange1 → 3  |  Levels 1–3"      })
        InfoLeft:Paragraph({ Header = "Goop Drop Rate",     Body = "goopDropRate1 → goopDropRate6  |  Lvl 1–6" })
        InfoLeft:Paragraph({ Header = "Overkill",           Body = "overkill1 → overkill8  |  Levels 1–8"     })
        InfoLeft:Paragraph({ Header = "Walk Speed",         Body = "walkSpeed1 → walkSpeed3  |  Levels 1–3"   })
        InfoLeft:Paragraph({ Header = "Unique (×1 each)",   Body = "autoRoll | backpack | goop | bigSlimes | shinySlimes | hugeSlimes | invertedSlimes | bossChance" })

        InfoRight:Header({ Name = "🟢 Loot Tree" })
        InfoRight:Paragraph({ Header = "Food Chain",   Body = "lootApple → lootCarrot → lootCherries → lootGrapes → lootBanana → lootWatermelon → lootPizza → lootChicken → lootDrumstick  |  9 upgrades" })
        InfoRight:Paragraph({ Header = "Coin Income",  Body = "coinIncome1 → coinIncome13  |  Levels 1–13" })
        InfoRight:Paragraph({ Header = "Offline Loot", Body = "offlineLootAmount1 → 5  |  Levels 1–5"     })
        InfoRight:Paragraph({ Header = "Unique (×1)",  Body = "lootLuck | lootCurrency | lootRollSpeed | lootUltraLuck" })
        InfoRight:Divider()
        InfoRight:Header({ Name = "🔵 Player Tree" })
        InfoRight:Paragraph({ Header = "Overkill",         Body = "overkill1 → overkill8  |  Levels 1–8"  })
        InfoRight:Paragraph({ Header = "Walk Speed",       Body = "walkSpeed1 → walkSpeed3  |  Levels 1–3"})
        InfoRight:Paragraph({ Header = "Unique (×1 each)", Body = "bigSlimes | shinySlimes | hugeSlimes | invertedSlimes | backpack" })

    end,
})

-- ══════════════════════════════════════════════════════
-- // MAIN LOOP
-- ══════════════════════════════════════════════════════

local Window = HUB.Window

task.spawn(function()
    local rollTick    = 0
    local upgradeTick = 0
    local collectTick = 0
    local zoneTick    = 0
    local farmTick    = 0
    local indexTick   = 0
    local rebirthTick = 0
    local feedTick    = 0
    local boostTick   = 0

    local UPGRADE_INTERVAL_PRIMARY   = 3
    local UPGRADE_INTERVAL_SECONDARY = 15
    local ZONE_INTERVAL_PRIMARY      = 2
    local ZONE_INTERVAL_SECONDARY    = 10

    while true do
        local now = tick()

        if State.autoRoll and (now - rollTick) >= State.rollDelay then
            rollTick = now
            doRoll()
            if State.autoEquip then doEquipBest() end
        end

        if State.farmEnabled and (now - farmTick) >= 0.5 then
            farmTick = now
            task.spawn(farmStep)
        end

        if State.autoUpgrade and not State.upgradeRunning then
            local interval = State.farmPriority == "upgrade"
                and UPGRADE_INTERVAL_PRIMARY or UPGRADE_INTERVAL_SECONDARY
            if (now - upgradeTick) >= interval then
                upgradeTick = now
                task.spawn(buyAllPasses)
            end
        end

        if State.autoCollect and (now - collectTick) >= 0.5 then
            collectTick = now
            task.spawn(collectAllLoot)
        end

        if State.autoZone and not State.zoneRunning then
            local interval = State.farmPriority == "zone"
                and ZONE_INTERVAL_PRIMARY or ZONE_INTERVAL_SECONDARY
            if (now - zoneTick) >= interval then
                zoneTick = now
                task.spawn(function() doPurchaseZone(Window) end)
            end
        end

        if State.autoIndexReward and (now - indexTick) >= 30 then
            indexTick = now
            task.spawn(function()
                local types = {"big","huge","shiny","inverted"}
                for _, t in pairs(types) do
                    pcall(function() IndexRemote:InvokeServer("requestClaimReward", t) end)
                    task.wait(0.2)
                end
            end)
        end

        if State.autoRebirth and (now - rebirthTick) >= 5 then
            rebirthTick = now
            task.spawn(function()
                local ok, result = pcall(function() return RebirthRemote:InvokeServer("requestRebirth") end)
                if ok and result then
                    Window:Notify({ Title = "♻️ Rebirth!", Description = "Rebirth successful!", Lifetime = 4 })
                end
            end)
        end

        if State.autoFeed and (now - feedTick) >= 2 then
            feedTick = now
            task.spawn(feedSelectedSlimes)
        end

        if State.autoBoost and (now - boostTick) >= 30 then
            boostTick = now
            task.spawn(useSelectedBoosts)
        end

        task.wait(0.01)
    end
end)

-- ══════════════════════════════════════════════════════
-- // READY
-- ══════════════════════════════════════════════════════

Window:Notify({
    Title       = "✅ Slime Fun Hub Ready!",
    Description = "Roll · Feed · Boost · Farm · Collect · Zone · Mob — all loaded!",
    Lifetime    = 5,
})
