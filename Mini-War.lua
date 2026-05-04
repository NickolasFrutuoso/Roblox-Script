-- ============================================
--          AUTO FARM - INTEGRATED SCRIPT
--       Collect + Sell + Buy em um único loop
-- ============================================

-- ============================================
-- CONFIGURAÇÕES GLOBAIS (use para a UI)
-- ============================================

-- [ COLLECT ]
_G.COLLECT          = true
_G.DELAY_COLLECT    = 0.1

-- [ SELL ]
_G.SELL             = true
_G.DELAY_SELL       = 6

-- [ BUY ]
_G.AUTO_BUY         = true
_G.DELAY_BUY        = 0.5
_G.RESTOCK_WAIT     = 310

-- [ RECURSOS COLETÁVEIS ]
-- Preenchido automaticamente pelo scan do plot.
-- { [resourceName] = true/false }
-- true  = coleta | false = ignora
_G.RECURSOS = {}

-- [ LISTA DE COMPRA ] true = compra, false = ignora
_G.BUY_LIST = {
    -- House
    ["SmallHouse"]          = false,
    ["FarmHouse"]           = false,
    ["House"]               = false,
    ["ModernBlock"]         = false,
    ["ApartmentBuilding"]   = false,
    ["Villa"]               = false,
    ["Skyscraper"]          = false,
    ["HelixTower"]          = false,
    ["TheManor"]            = false,
    ["Hotel"]               = false,
    ["Giant Skyscraper"]    = false,
    -- Military
    ["BigHangar"]           = false,
    ["Hangar"]              = false,
    ["MissleLauncher"]      = false,
    ["MissleHangar"]        = false,
    ["BigTankBase"]         = false,
    ["TankBase"]            = false,
    ["GeneralsBase"]        = false,
    ["SpecialForce"]        = false,
    ["HeliPad"]             = false,
    ["Barracks"]            = false,
    ["Barracks2"]           = false,
    ["BorderTower"]         = false,
    ["SniperTower"]         = false,
    ["Air Base"]            = false,
    ["Artillery Depot"]     = false,
    ["Rocket Bunker"]       = false,
    ["MilitaryHospital"]    = false,
    -- Decor
    ["Storage Center"]      = false,
    ["Worker Statue"]       = false,
    ["Soldier Statue"]      = false,
    ["Workshop"]            = false,
    ["Grass"]               = false,
    ["Road2"]               = false,
    ["Rocks"]               = false,
    ["Road1"]               = false,
    ["StreetLamp"]          = false,
    ["PineTree"]            = false,
    ["Lamp"]                = false,
    ["Tree"]                = false,
    ["Flowers"]             = false,
    ["Bench"]               = false,
    ["Fountain"]            = false,
    ["SalutingStatue"]      = false,
    ["Statue"]              = false,
    -- Farm
    ["Bank"]                = false,
    ["CaveCoal"]            = false,
    ["CaveDiamond"]         = false,
    ["CaveUran"]            = false,
    ["CaveGold"]            = false,
    ["CaveIron"]            = false,
    ["CementPlant"]         = false,
    ["FarmCorn"]            = false,
    ["FarmCarrots"]         = false,
    ["FarmWheat"]           = false,
    ["Labs"]                = false,
    ["Library"]             = false,
    ["NuclearReactor"]      = false,
    ["OilAmerica"]          = false,
    ["Windmill"]            = false,
    ["WoodPlant"]           = false,
    ["Data Center"]         = false,
    ["Blackhole Generator"] = false,
}

-- ============================================
-- STATS GLOBAIS — leia na UI via _G.STATS
-- ============================================
--[[
    _G.STATS = {
        startTime  : number   tick() de quando o script iniciou
        uptime     : number   segundos rodando (atualizado a cada ciclo)

        collect = {
            totalItems    : number              total de unidades coletadas (acumulado)
            totalRuns     : number              quantas rodadas de coleta aconteceram
            byResource    : { [name] = number } total por nome de recurso
            lastRun       : number              tick() da última coleta
            lastRunItems  : number              unidades coletadas na última rodada
        },

        sell = {
            totalRuns : number   quantas vezes a venda disparou com sucesso
            lastRun   : number   tick() da última venda
        },

        buy = {
            totalItems    : number              total de unidades compradas (acumulado)
            totalRuns     : number              quantas rodadas de compra aconteceram
            byItem        : { [name] = number } total por nome de item
            lastRun       : number              tick() da última compra
            lastRunItems  : number              unidades compradas na última rodada
        },
    }

    Para resetar: _G.RESET_STATS()
]]

_G.STATS = {
    startTime = tick(),
    uptime    = 0,

    collect = {
        totalItems   = 0,
        totalRuns    = 0,
        byResource   = {},
        lastRun      = 0,
        lastRunItems = 0,
    },

    sell = {
        totalRuns = 0,
        lastRun   = 0,
    },

    buy = {
        totalItems   = 0,
        totalRuns    = 0,
        byItem       = {},
        lastRun      = 0,
        lastRunItems = 0,
    },
}

_G.RESET_STATS = function()
    _G.STATS.startTime            = tick()
    _G.STATS.uptime               = 0
    _G.STATS.collect.totalItems   = 0
    _G.STATS.collect.totalRuns    = 0
    _G.STATS.collect.byResource   = {}
    _G.STATS.collect.lastRun      = 0
    _G.STATS.collect.lastRunItems = 0
    _G.STATS.sell.totalRuns       = 0
    _G.STATS.sell.lastRun         = 0
    _G.STATS.buy.totalItems       = 0
    _G.STATS.buy.totalRuns        = 0
    _G.STATS.buy.byItem           = {}
    _G.STATS.buy.lastRun          = 0
    _G.STATS.buy.lastRunItems     = 0
    print("[STATS] Resetado!")
end

-- ============================================
-- SETUP
-- ============================================
local RS      = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player  = Players.LocalPlayer

local BridgeNet  = require(RS.package._Index["ncxyzero_bridgenet2-fork@1.1.5"]["bridgenet2-fork"])
local sellBridge = BridgeNet.ClientBridge("SellAll")

-- ============================================
-- FUNÇÕES AUXILIARES — PLOT
-- ============================================
local function getPlayerPlot()
    local playerPlots = workspace:FindFirstChild("MilitaryMap")
        and workspace.MilitaryMap:FindFirstChild("PlayerPlots")
    if not playerPlots then return nil end

    for _, plotFolder in ipairs(playerPlots:GetChildren()) do
        local plot = plotFolder:FindFirstChild("Plot")
        if plot then
            local buildings = plot:FindFirstChild("Buildings")
            if buildings then
                for _, obj in ipairs(buildings:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") and obj.ObjectText == "Collect!" then
                        return plot
                    end
                end
            end
        end
    end
    return nil
end

local function getResources(plot)
    local resources = {}
    local seen      = {}

    local buildings = plot:FindFirstChild("Buildings")
    if not buildings then return resources end

    for _, obj in ipairs(buildings:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.ObjectText == "Collect!" then
            local resourceName = obj.ActionText:match("x%d+ (.+)")
            if resourceName and not seen[obj] then
                seen[obj] = true
                table.insert(resources, {
                    prompt = obj,
                    name   = resourceName,
                    amount = tonumber(obj.ActionText:match("x(%d+)")) or 0,
                })
            end
        end
    end

    return resources
end

-- ============================================
-- SCAN DE RECURSOS DO PLOT
-- ============================================
local function scanResources()
    local plot = getPlayerPlot()
    if not plot then return false end

    local found    = {}
    local buildings = plot:FindFirstChild("Buildings")

    if buildings then
        for _, obj in ipairs(buildings:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.ObjectText == "Collect!" then
                local name = obj.ActionText:match("x%d+ (.+)")
                if name then found[name] = true end
            end
        end
    end

    -- Remove recursos que saíram do plot
    for name in pairs(_G.RECURSOS) do
        if not found[name] then _G.RECURSOS[name] = nil end
    end

    -- Adiciona novos (default: true)
    local newCount = 0
    for name in pairs(found) do
        if _G.RECURSOS[name] == nil then
            _G.RECURSOS[name] = true
            newCount = newCount + 1
        end
    end

    local total = 0
    for _ in pairs(_G.RECURSOS) do total = total + 1 end

    if newCount > 0 then
        print(string.format("[SCAN] %d recurso(s) | %d novo(s)", total, newCount))
    end

    return total > 0
end

-- Expõe rescan manual para a UI
_G.SCAN_RECURSOS = function()
    print("[SCAN] Rescaneando...")
    scanResources()
end

-- ============================================
-- FUNÇÕES AUXILIARES — BUY
-- ============================================
local function findShopPrompt()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.ActionText == "Talk!" then
            local part = obj.Parent
            if part:IsA("BasePart") then
                local model = part.Parent
                if model and model.Name == "HumanoidModel" then
                    return obj, part.Position
                end
            end
        end
    end
    return nil, nil
end

local function hasItemsToBuy()
    for _, v in pairs(_G.BUY_LIST) do
        if v then return true end
    end
    return false
end

local function hasStockAvailable(buyUI)
    local itemsGrid = buyUI:FindFirstChild("ItemsGrid")
    if not itemsGrid then return false end

    for _, itemFrame in ipairs(itemsGrid:GetChildren()) do
        if _G.BUY_LIST[itemFrame.Name] then
            local stockLabel = itemFrame:FindFirstChild("Stock")
            if stockLabel then
                local amount = tonumber(stockLabel.Text:match("Stock x(%d+)"))
                if amount and amount > 0 then return true end
            end
        end
    end
    return false
end

local function closeShopUI(buyUI)
    local closeBtn = buyUI:FindFirstChild("Topbar")
        and buyUI.Topbar:FindFirstChild("Close")
    if closeBtn then
        local conns = getconnections(closeBtn.MouseButton1Down)
        for _, conn in ipairs(conns) do pcall(conn.Function) end
    end
    task.wait(0.3)
end

-- ============================================
-- AÇÃO: COLLECT
-- ============================================
local function collectAll()
    if not _G.COLLECT then return end
    if not next(_G.RECURSOS) then return end

    local plot = getPlayerPlot()
    if not plot then return end

    local resources = getResources(plot)
    if #resources == 0 then return end

    local runTotal = 0

    for _, r in ipairs(resources) do
        if _G.RECURSOS[r.name] and r.amount > 0 then
            fireproximityprompt(r.prompt)

            local prev = _G.STATS.collect.byResource[r.name] or 0
            _G.STATS.collect.byResource[r.name] = prev + r.amount
            _G.STATS.collect.totalItems = _G.STATS.collect.totalItems + r.amount
            runTotal = runTotal + r.amount

            task.wait(_G.DELAY_COLLECT)
        end
    end

    if runTotal > 0 then
        _G.STATS.collect.totalRuns    = _G.STATS.collect.totalRuns + 1
        _G.STATS.collect.lastRun      = tick()
        _G.STATS.collect.lastRunItems = runTotal
    end
end

-- ============================================
-- AÇÃO: SELL
-- ============================================
local function sellAll()
    if not _G.SELL then return end

    local ok, err = pcall(function()
        sellBridge:Fire()
    end)

    if ok then
        _G.STATS.sell.totalRuns = _G.STATS.sell.totalRuns + 1
        _G.STATS.sell.lastRun   = tick()
    else
        warn("[SELL] Erro: " .. tostring(err))
    end
end

-- ============================================
-- AÇÃO: BUY
-- ============================================
local function buyAll()
    if not _G.AUTO_BUY then return end
    if not hasItemsToBuy() then return end

    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local savedCFrame = hrp.CFrame

    local prompt, shopPos = findShopPrompt()
    if not prompt then
        warn("[BUY] Shopkeeper não encontrado!")
        return
    end

    hrp.CFrame = CFrame.new(shopPos + Vector3.new(0, 0, 5))
    task.wait(0.8)
    fireproximityprompt(prompt)
    task.wait(1.5)

    local buyUI = player.PlayerGui.MainUI.Fullscreen.BuyUI
    if not buyUI.Visible then
        warn("[BUY] Loja não abriu!")
        hrp.CFrame = savedCFrame
        return
    end

    if not hasStockAvailable(buyUI) then
        closeShopUI(buyUI)
        hrp.CFrame = savedCFrame
        return
    end

    local itemsGrid = buyUI:FindFirstChild("ItemsGrid")
    local runTotal  = 0

    for _, itemFrame in ipairs(itemsGrid:GetChildren()) do
        if not _G.AUTO_BUY then break end

        local itemName = itemFrame.Name
        if _G.BUY_LIST[itemName] then
            local stockLabel = itemFrame:FindFirstChild("Stock")
            local buyBtn     = itemFrame:FindFirstChild("Buy")

            if stockLabel and buyBtn then
                local amount = tonumber(stockLabel.Text:match("Stock x(%d+)"))
                if amount and amount > 0 then
                    for _ = 1, amount do
                        local conns = getconnections(buyBtn.MouseButton1Down)
                        for _, conn in ipairs(conns) do pcall(conn.Function) end
                        task.wait(_G.DELAY_BUY)
                    end

                    local prev = _G.STATS.buy.byItem[itemName] or 0
                    _G.STATS.buy.byItem[itemName] = prev + amount
                    _G.STATS.buy.totalItems = _G.STATS.buy.totalItems + amount
                    runTotal = runTotal + amount
                end
            end
        end
    end

    if runTotal > 0 then
        print(string.format("[BUY] +%d comprado(s) | Total: %d", runTotal, _G.STATS.buy.totalItems))
    end

    _G.STATS.buy.totalRuns    = _G.STATS.buy.totalRuns + 1
    _G.STATS.buy.lastRun      = tick()
    _G.STATS.buy.lastRunItems = runTotal

    closeShopUI(buyUI)
    hrp.CFrame = savedCFrame
end

-- ============================================
-- SCAN INICIAL — aguarda o plot carregar
-- ============================================
print("[AUTO FARM] Aguardando plot...")

local scanOk = false
repeat
    task.wait(2)
    scanOk = scanResources()
until scanOk

print("[AUTO FARM] Rodando! | COLLECT:" .. tostring(_G.COLLECT) .. " SELL:" .. tostring(_G.SELL) .. " BUY:" .. tostring(_G.AUTO_BUY))

-- ============================================
-- LOOP PRINCIPAL
-- ============================================
local sellTimer  = 0
local buyTimer   = _G.RESTOCK_WAIT
local scanTimer  = 0
local SCAN_INTERVAL = 300

while true do
    _G.STATS.uptime = math.floor(tick() - _G.STATS.startTime)

    collectAll()

    task.wait(1)
    sellTimer = sellTimer + 1
    buyTimer  = buyTimer  + 1
    scanTimer = scanTimer + 1

    if sellTimer >= _G.DELAY_SELL then
        sellAll()
        sellTimer = 0
    end

    if buyTimer >= _G.RESTOCK_WAIT then
        buyAll()
        buyTimer = 0
    end

    if scanTimer >= SCAN_INTERVAL then
        scanResources()
        scanTimer = 0
    end
end
