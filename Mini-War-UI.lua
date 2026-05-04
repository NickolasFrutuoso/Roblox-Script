local MacLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/NickolasFrutuoso/MacUI/refs/heads/main/UI"))()

-- ============================================
-- DEFAULTS — tudo desligado
-- ============================================
_G.COLLECT       = false
_G.SELL          = false
_G.AUTO_BUY      = false
_G.DELAY_COLLECT = 0.5
_G.DELAY_SELL    = 10
_G.DELAY_BUY     = 0.5
_G.RESTOCK_WAIT  = 120
_G.RECURSOS      = {}
_G.BUY_LIST      = {}

-- ============================================
-- CARREGAMENTO LAZY DO FARM
-- ============================================

local farmLoaded = false
_G.FARM_READY = false  -- o farm vai setar isso como true quando terminar de inicializar

local function ensureFarmLoaded(cb)
    if farmLoaded then
        if cb then task.spawn(cb) end
        return
    end

    task.spawn(function()
        -- Carrega o farm numa thread separada (ele vai travar lá com o while true)
        task.spawn(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/NickolasFrutuoso/Roblox-Script/refs/heads/main/Mini-War.lua"))()
        end)

        -- Aguarda o farm sinalizar que está pronto
        local timeout = 0
        repeat
            task.wait(0.5)
            timeout = timeout + 0.5
        until _G.SCAN_RECURSOS ~= nil or timeout >= 30

        if _G.SCAN_RECURSOS then
            farmLoaded = true
            print("[UI] Farm carregado e pronto!")
            if cb then task.spawn(cb) end
        else
            warn("[UI] Farm não respondeu após 30s!")
        end
    end)
end

-- ============================================
-- MAPA ID -> NOME AMIGÁVEL
-- ============================================
local itemNames = {
    -- House
    SmallHouse              = "Small House",
    FarmHouse               = "Farm House",
    House                   = "House",
    ModernBlock             = "Modern Block",
    ApartmentBuilding       = "Apartment Building",
    Villa                   = "Villa",
    Skyscraper              = "Skyscraper",
    HelixTower              = "Helix Tower",
    TheManor                = "The Manor",
    Hotel                   = "Hotel",
    ["Giant Skyscraper"]    = "Giant Skyscraper",
    -- Military
    BigHangar               = "Big Hangar",
    Hangar                  = "Hangar",
    MissleLauncher          = "Missile Launcher",
    MissleHangar            = "Missile Hangar",
    BigTankBase             = "Big Tank Base",
    TankBase                = "Tank Base",
    GeneralsBase            = "General's Base",
    SpecialForce            = "Special Force",
    HeliPad                 = "Heli Pad",
    Barracks                = "Barracks",
    Barracks2               = "Barracks II",
    BorderTower             = "Border Tower",
    SniperTower             = "Sniper Tower",
    ["Air Base"]            = "Air Base",
    ["Artillery Depot"]     = "Artillery Depot",
    ["Rocket Bunker"]       = "Rocket Bunker",
    MilitaryHospital        = "Military Hospital",
    -- Farm
    Bank                    = "Bank",
    CaveCoal                = "Coal Cave",
    CaveDiamond             = "Diamond Cave",
    CaveUran                = "Uranium Cave",
    CaveGold                = "Gold Cave",
    CaveIron                = "Iron Cave",
    CementPlant             = "Cement Plant",
    FarmCorn                = "Corn Farm",
    FarmCarrots             = "Carrot Farm",
    FarmWheat               = "Wheat Farm",
    Labs                    = "Laboratory",
    Library                 = "Library",
    NuclearReactor          = "Nuclear Reactor",
    OilAmerica              = "Oil Rig",
    Windmill                = "Windmill",
    WoodPlant               = "Wood Plant",
    ["Data Center"]         = "Data Center",
    ["Blackhole Generator"] = "Blackhole Generator",
    -- Decor
    ["Storage Center"]      = "Storage Center",
    ["Worker Statue"]       = "Worker Statue",
    ["Soldier Statue"]      = "Soldier Statue",
    Workshop                = "Workshop",
    Grass                   = "Grass",
    Road2                   = "Road (Type 2)",
    Rocks                   = "Rocks",
    Road1                   = "Road (Type 1)",
    StreetLamp              = "Street Lamp",
    PineTree                = "Pine Tree",
    Lamp                    = "Lamp",
    Tree                    = "Tree",
    Flowers                 = "Flowers",
    Bench                   = "Bench",
    Fountain                = "Fountain",
    SalutingStatue          = "Saluting Statue",
    Statue                  = "Statue",
}

local function toDisplayNames(idList)
    local names = {}
    for _, id in ipairs(idList) do
        table.insert(names, itemNames[id] or id)
    end
    return names
end

local function toID(displayName)
    for id, name in pairs(itemNames) do
        if name == displayName then return id end
    end
    return displayName
end

local function getActiveBuyItems(list)
    local defaults = {}
    for _, id in ipairs(list) do
        if _G.BUY_LIST[id] then
            table.insert(defaults, itemNames[id] or id)
        end
    end
    return defaults
end

local function makeBuyCallback(list)
    return function(selected)
        for _, id in ipairs(list) do
            _G.BUY_LIST[id] = false
        end
        for displayName, state in pairs(selected) do
            if state then
                _G.BUY_LIST[toID(displayName)] = true
            end
        end
    end
end

-- ============================================
-- HUB
-- ============================================
local HUB = MacLib:CreateHUB({
    Title    = "Mini War",
    Subtitle = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name,

    OnTabGroup = function(TabGroup, Window)

        -- ============================================================
        -- TAB: FARM
        -- ============================================================
        local FarmTab   = TabGroup:Tab({ Name = "Farm",  Image = "rbxassetid://10734950309" })
        local FarmLeft  = FarmTab:Section({ Side = "Left"  })
        local FarmRight = FarmTab:Section({ Side = "Right" })

        FarmLeft:Header({ Name = "Collect" })

        FarmLeft:Toggle({
            Name     = "Auto Collect",
            Default  = _G.COLLECT,
            Callback = function(state)
                _G.COLLECT = state
                if state then ensureFarmLoaded() end
            end,
        }, "FarmCollectToggle")

        FarmLeft:Slider({
            Name      = "Collect Delay",
            Minimum   = 0,
            Maximum   = 2,
            Default   = _G.DELAY_COLLECT,
            Precision = 1,
            Suffix    = "s",
            Callback  = function(value) _G.DELAY_COLLECT = value end,
        }, "FarmCollectDelay")

        FarmLeft:Divider()
        FarmLeft:Header({ Name = "Sell" })

        FarmLeft:Toggle({
            Name     = "Auto Sell",
            Default  = _G.SELL,
            Callback = function(state)
                _G.SELL = state
                if state then ensureFarmLoaded() end
            end,
        }, "FarmSellToggle")

        FarmLeft:Slider({
            Name      = "Sell Interval",
            Minimum   = 1,
            Maximum   = 60,
            Default   = _G.DELAY_SELL,
            Precision = 0,
            Suffix    = "s",
            Callback  = function(value) _G.DELAY_SELL = value end,
        }, "FarmSellDelay")

        -- Plot Resources
        FarmRight:Header({ Name = "Plot Resources" })

        local resourceDropdown = FarmRight:Dropdown({
            Name     = "Select Resources",
            Options  = {},
            Default  = {},
            Multi    = true,
            Search   = true,
            Callback = function(selected)
                for name, _ in pairs(_G.RECURSOS) do
                    _G.RECURSOS[name] = false
                end
                for name, state in pairs(selected) do
                    if state then _G.RECURSOS[name] = true end
                end
            end,
        }, "FarmResourceDropdown")

        FarmRight:Divider()

        FarmRight:Button({
            Name     = "Rescan Resources",
            Callback = function()
                task.spawn(function()
                    ensureFarmLoaded(function()
                        task.wait(1) -- garante que o farm terminou de inicializar

                        _G.SCAN_RECURSOS()
                        task.wait(3) -- aguarda scan popular _G.RECURSOS

                        local newNames = {}
                        for name, _ in pairs(_G.RECURSOS) do
                            table.insert(newNames, name)
                        end
                        table.sort(newNames)
                        print("[RESCAN] Total encontrado:", #newNames)
                        for _, n in ipairs(newNames) do print(" -", n) end

                        if #newNames == 0 then
                            Window:Notify({ Title = "Vazio", Description = "Nenhum recurso encontrado.", Lifetime = 4, Style = "None" })
                            return
                        end

                        resourceDropdown:ClearOptions()
                        resourceDropdown:InsertOptions(newNames)

                        Window:Notify({
                            Title       = "Scan completo!",
                            Description = #newNames .. " recurso(s) encontrado(s).",
                            Lifetime    = 4,
                            Style       = "None",
                        })
                    end)
                end)
            end,
        }, "FarmRescan")

        FarmRight:SubLabel({
            Text = "After scanning, wait a few seconds.",
        })

        -- ============================================================
        -- TAB: BUY
        -- ============================================================
        local BuyTab   = TabGroup:Tab({ Name = "Buy",   Image = "rbxassetid://10734950309" })
        local BuyLeft  = BuyTab:Section({ Side = "Left"  })
        local BuyRight = BuyTab:Section({ Side = "Right" })

        BuyLeft:Header({ Name = "Settings" })

        BuyLeft:Toggle({
            Name     = "Auto Buy",
            Default  = _G.AUTO_BUY,
            Callback = function(state)
                _G.AUTO_BUY = state
                if state then ensureFarmLoaded() end
            end,
        }, "BuyToggle")

        BuyLeft:Slider({
            Name      = "Buy Delay",
            Minimum   = 0.1,
            Maximum   = 2,
            Default   = _G.DELAY_BUY,
            Precision = 1,
            Suffix    = "s",
            Callback  = function(value) _G.DELAY_BUY = value end,
        }, "BuyDelay")

        BuyLeft:Slider({
            Name      = "Restock Wait",
            Minimum   = 60,
            Maximum   = 600,
            Default   = _G.RESTOCK_WAIT,
            Precision = 0,
            Suffix    = "s",
            Callback  = function(value) _G.RESTOCK_WAIT = value end,
        }, "BuyRestockWait")

        local houseItems = {
            "SmallHouse","FarmHouse","House","ModernBlock",
            "ApartmentBuilding","Villa","Skyscraper","HelixTower",
            "TheManor","Hotel","Giant Skyscraper",
        }

        local militaryItems = {
            "BigHangar","Hangar","MissleLauncher","MissleHangar",
            "BigTankBase","TankBase","GeneralsBase","SpecialForce",
            "HeliPad","Barracks","Barracks2","BorderTower","SniperTower",
            "Air Base","Artillery Depot","Rocket Bunker","MilitaryHospital",
        }

        local farmBuildItems = {
            "Bank","CaveCoal","CaveDiamond","CaveUran","CaveGold","CaveIron",
            "CementPlant","FarmCorn","FarmCarrots","FarmWheat","Labs","Library",
            "NuclearReactor","OilAmerica","Windmill","WoodPlant",
            "Data Center","Blackhole Generator",
        }

        local decorItems = {
            "Storage Center","Worker Statue","Soldier Statue","Workshop",
            "Grass","Road2","Rocks","Road1","StreetLamp","PineTree",
            "Lamp","Tree","Flowers","Bench","Fountain",
            "SalutingStatue","Statue",
        }

        BuyRight:Header({ Name = "House" })
        BuyRight:Dropdown({
            Name     = "Select House Items",
            Options  = toDisplayNames(houseItems),
            Default  = getActiveBuyItems(houseItems),
            Multi    = true,
            Search   = true,
            Callback = makeBuyCallback(houseItems),
        }, "BuyHouseDropdown")

        BuyRight:Divider()
        BuyRight:Header({ Name = "Military" })
        BuyRight:Dropdown({
            Name     = "Select Military Items",
            Options  = toDisplayNames(militaryItems),
            Default  = getActiveBuyItems(militaryItems),
            Multi    = true,
            Search   = true,
            Callback = makeBuyCallback(militaryItems),
        }, "BuyMilitaryDropdown")

        BuyRight:Divider()
        BuyRight:Header({ Name = "Farm" })
        BuyRight:Dropdown({
            Name     = "Select Farm Items",
            Options  = toDisplayNames(farmBuildItems),
            Default  = getActiveBuyItems(farmBuildItems),
            Multi    = true,
            Search   = true,
            Callback = makeBuyCallback(farmBuildItems),
        }, "BuyFarmDropdown")

        BuyRight:Divider()
        BuyRight:Header({ Name = "Decor" })
        BuyRight:Dropdown({
            Name     = "Select Decor Items",
            Options  = toDisplayNames(decorItems),
            Default  = getActiveBuyItems(decorItems),
            Multi    = true,
            Search   = true,
            Callback = makeBuyCallback(decorItems),
        }, "BuyDecorDropdown")

        -- ============================================================
        -- TAB: STATS
        -- ============================================================
        local StatsTab   = TabGroup:Tab({ Name = "Stats", Image = "rbxassetid://10734950309" })
        local StatsLeft  = StatsTab:Section({ Side = "Left"  })
        local StatsRight = StatsTab:Section({ Side = "Right" })

        StatsLeft:Header({ Name = "General" })
        local lUptime       = StatsLeft:Label({ Text = "Uptime: --"         })
        local lCollectTotal = StatsLeft:Label({ Text = "Total Collected: 0" })
        local lCollectRuns  = StatsLeft:Label({ Text = "Collect Runs: 0"    })
        local lSellRuns     = StatsLeft:Label({ Text = "Sell Runs: 0"       })
        local lBuyTotal     = StatsLeft:Label({ Text = "Total Bought: 0"    })
        local lBuyRuns      = StatsLeft:Label({ Text = "Buy Runs: 0"        })

        StatsLeft:Divider()
        StatsLeft:Header({ Name = "Last Action" })
        local lLastCollect  = StatsLeft:Label({ Text = "Collect: --"        })
        local lLastSell     = StatsLeft:Label({ Text = "Sell: --"           })
        local lLastBuy      = StatsLeft:Label({ Text = "Buy: --"            })

        StatsLeft:Divider()
        StatsLeft:Button({
            Name     = "Reset Stats",
            Callback = function()
                if _G.RESET_STATS then _G.RESET_STATS() end
                Window:Notify({
                    Title       = "Stats",
                    Description = "Counters reset!",
                    Lifetime    = 3,
                    Style       = "None",
                })
            end,
        }, "StatsReset")

        StatsRight:Header({ Name = "By Resource (Collect)" })
        local pByResource = StatsRight:Paragraph({ Header = "Resources", Body = "Waiting for data..." })

        StatsRight:Divider()
        StatsRight:Header({ Name = "By Item (Buy)" })
        local pByItem = StatsRight:Paragraph({ Header = "Items", Body = "Waiting for data..." })

        local function formatTime(secs)
            local h = math.floor(secs / 3600)
            local m = math.floor((secs % 3600) / 60)
            local s = secs % 60
            return string.format("%02d:%02d:%02d", h, m, s)
        end

        local function timeSince(t)
            if t == 0 then return "never" end
            local diff = math.floor(tick() - t)
            if diff < 60       then return diff .. "s ago"
            elseif diff < 3600 then return math.floor(diff / 60) .. "m ago"
            else                    return math.floor(diff / 3600) .. "h ago"
            end
        end

        task.spawn(function()
            while true do
                task.wait(1)
                if not _G.STATS then continue end
                local s = _G.STATS

                lUptime:UpdateName("Uptime: "            .. formatTime(s.uptime))
                lCollectTotal:UpdateName("Total Collected: " .. s.collect.totalItems)
                lCollectRuns:UpdateName("Collect Runs: "     .. s.collect.totalRuns)
                lSellRuns:UpdateName("Sell Runs: "           .. s.sell.totalRuns)
                lBuyTotal:UpdateName("Total Bought: "        .. s.buy.totalItems)
                lBuyRuns:UpdateName("Buy Runs: "             .. s.buy.totalRuns)

                lLastCollect:UpdateName("Collect: " .. timeSince(s.collect.lastRun)
                    .. " (+" .. s.collect.lastRunItems .. ")")
                lLastSell:UpdateName("Sell: "   .. timeSince(s.sell.lastRun))
                lLastBuy:UpdateName("Buy: "     .. timeSince(s.buy.lastRun)
                    .. " (+" .. s.buy.lastRunItems .. ")")

                local resLines = {}
                for name, amount in pairs(s.collect.byResource) do
                    if amount > 0 then table.insert(resLines, name .. ": " .. amount) end
                end
                table.sort(resLines)
                pByResource:UpdateBody(#resLines > 0 and table.concat(resLines, "\n") or "None yet.")

                local buyLines = {}
                for name, amount in pairs(s.buy.byItem) do
                    if amount > 0 then table.insert(buyLines, name .. ": " .. amount) end
                end
                table.sort(buyLines)
                pByItem:UpdateBody(#buyLines > 0 and table.concat(buyLines, "\n") or "None yet.")
            end
        end)

    end,
})

HUB.Window:Notify({
    Title       = "Mini War Hub",
    Description = "Loaded! Press RightCtrl to open.",
    Lifetime    = 5,
    Style       = "None",
})
