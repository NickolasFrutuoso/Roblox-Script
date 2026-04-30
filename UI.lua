-- ══════════════════════════════════════════════════════
-- // GUI-HUB.lua
-- ══════════════════════════════════════════════════════

local farmSource, rayfieldSource

local t1 = task.spawn(function()
    for i = 1, 3 do
        local ok, result = pcall(function()
            return game:HttpGet("https://raw.githubusercontent.com/NickolasFrutuoso/Roblox-Script/refs/heads/main/Farm-HUB.lua")
        end)
        if ok and result and not result:find("404") and not result:find("Not Found") then
            farmSource = result
            break
        end
        warn("[GUI-HUB] Farm-HUB attempt " .. i .. " failed, retrying...")
        task.wait(1)
    end
end)

local t2 = task.spawn(function()
    for i = 1, 3 do
        local ok, result = pcall(function()
            return game:HttpGet("https://sirius.menu/rayfield")
        end)
        if ok and result and not result:find("404") and not result:find("Not Found") then
            rayfieldSource = result
            break
        end
        warn("[GUI-HUB] Rayfield attempt " .. i .. " failed, retrying...")
        task.wait(1)
    end
end)

local timeout = tick()
repeat task.wait(0.1) until (farmSource and rayfieldSource) or (tick() - timeout > 30)

if not farmSource     then error("[GUI-HUB] Farm-HUB failed to load after 3 attempts!") end
if not rayfieldSource then error("[GUI-HUB] Rayfield failed to load after 3 attempts!")  end

local farmFn, farmErr = loadstring(farmSource)
if not farmFn then error("[GUI-HUB] Farm-HUB failed: " .. tostring(farmErr)) end
farmFn()

-- ══════════════════════════════════════════════════════
-- // CONFIG SAVE/LOAD SYSTEM
-- ══════════════════════════════════════════════════════

local HttpService    = game:GetService("HttpService")
local CONFIG_FILE    = "FarmHUB_Configs.json"
local autoSaveAtivo  = true
local autoLoadAtivo  = true

local function salvarConfigs()
    if not autoSaveAtivo then return end
    pcall(function()
        local configs = {
            AutoDungeonBot       = _G.AutoDungeonBot                              or false,
            AutoReplay           = _G.AutoReplay                                  or false,
            KillAura             = _G.KillAura                                    or false,
            KillAura_Noclip      = (_G.KillAura_Noclip ~= nil) and _G.KillAura_Noclip or true,
            KillAura_Priority    = _G.KillAura_Priority                           or "lowestHP",
            KillAura_FlySpeed    = _G.KillAura_FlySpeed                           or 150,
            KillAura_APS         = _G.KillAura_APS                                or 30,
            KillAura_OffsetY     = _G.KillAura_OffsetY                            or 4,
            KillAura_Orbit       = _G.KillAura_Orbit                              or false,
            KillAura_OrbitRadius = _G.KillAura_OrbitRadius                        or 6,
            KillAura_OrbitSpeed  = _G.KillAura_OrbitSpeed                         or 2,
            Skill1               = (_G.SkillsAtivas and _G.SkillsAtivas.Skill1)   or false,
            Skill2               = (_G.SkillsAtivas and _G.SkillsAtivas.Skill2)   or false,
            SkillU               = (_G.SkillsAtivas and _G.SkillsAtivas.SkillU)   or false,
            LoopAtivo            = (_G.LoopAtivo ~= nil) and _G.LoopAtivo         or true,
        }
        writefile(CONFIG_FILE, HttpService:JSONEncode(configs))
    end)
end

local function carregarConfigs()
    local configs = {}
    if not autoLoadAtivo then return configs end
    pcall(function()
        if isfile(CONFIG_FILE) then
            configs = HttpService:JSONDecode(readfile(CONFIG_FILE))
        end
    end)
    return configs
end

-- Carrega configs antes de criar a UI
local CFG = carregarConfigs()

-- Aplica _G imediatamente com os valores carregados
_G.AutoDungeonBot       = CFG.AutoDungeonBot       or false
_G.AutoReplay           = CFG.AutoReplay           or false
_G.KillAura             = CFG.KillAura             or false
_G.KillAura_Noclip      = (CFG.KillAura_Noclip ~= nil) and CFG.KillAura_Noclip or true
_G.KillAura_Mode        = "fly"
_G.KillAura_Priority    = CFG.KillAura_Priority    or "lowestHP"
_G.KillAura_FlySpeed    = CFG.KillAura_FlySpeed    or 150
_G.KillAura_APS         = CFG.KillAura_APS         or 30
_G.KillAura_OffsetY     = CFG.KillAura_OffsetY     or 4
_G.KillAura_Orbit       = CFG.KillAura_Orbit       or false
_G.KillAura_OrbitRadius = CFG.KillAura_OrbitRadius or 6
_G.KillAura_OrbitSpeed  = CFG.KillAura_OrbitSpeed  or 2
_G.LoopAtivo            = (CFG.LoopAtivo ~= nil) and CFG.LoopAtivo or true
if not _G.SkillsAtivas then _G.SkillsAtivas = {} end
_G.SkillsAtivas.Skill1  = CFG.Skill1 or false
_G.SkillsAtivas.Skill2  = CFG.Skill2 or false
_G.SkillsAtivas.SkillU  = CFG.SkillU or false

-- ══════════════════════════════════════════════════════
-- // LOGICA.LUA — IronSoulLib embutido
-- ══════════════════════════════════════════════════════

local IronSoulLib = (function()

    local RS      = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")

    local DataController = require(
        RS:WaitForChild("Framework")
          :WaitForChild("Systems")
          :WaitForChild("DataSystem")
          :WaitForChild("Client")
          :WaitForChild("DataController")
    )

    local EquipmentRE = RS:WaitForChild("Framework")
        :WaitForChild("Gameplay")
        :WaitForChild("EquipmentSystem")
        :WaitForChild("EquipmentRE")

    local ForgeRF = RS:WaitForChild("Framework")
        :WaitForChild("Features")
        :WaitForChild("ForgeSystem")
        :WaitForChild("ForgeRF")

    local RedPointRE = RS:WaitForChild("Framework")
        :WaitForChild("Systems")
        :WaitForChild("RedPointSystem")
        :WaitForChild("RedPointUtil")
        :WaitForChild("RemoteEvent")

    local ok1, ResWeapon = pcall(require, RS:WaitForChild("Configs"):WaitForChild("ResWeapon"))
    local ok2, ResArmor  = pcall(require, RS:WaitForChild("Configs"):WaitForChild("ResArmor"))

    -- ══════════════════════════════════════════════════
    -- // SESSION PERSISTENCE
    -- ══════════════════════════════════════════════════

    local SESSION_FILE = "FarmHUB_Session.json"

    local function salvarSessao(sessao)
        pcall(function()
            local dados = {
                kills        = sessao.kills,
                xpInicial    = sessao.xpInicial,
                levelInicial = sessao.levelInicial,
                inicio       = sessao.inicio,
            }
            writefile(SESSION_FILE, HttpService:JSONEncode(dados))
        end)
    end

    local function carregarSessao()
        local resultado = {
            kills        = 0,
            xpInicial    = 0,
            levelInicial = 0,
            inicio       = tick(),
        }
        pcall(function()
            if isfile(SESSION_FILE) then
                local raw  = readfile(SESSION_FILE)
                local data = HttpService:JSONDecode(raw)
                resultado.kills        = data.kills        or 0
                resultado.levelInicial = data.levelInicial or 0
                resultado.xpInicial    = data.xpInicial    or 0
                resultado.inicio       = data.inicio       or tick()
            end
        end)
        return resultado
    end

    local salvo = carregarSessao()
    local Sessao = {
        inicio       = salvo.inicio,
        xpInicial    = salvo.xpInicial,
        levelInicial = salvo.levelInicial,
        kills        = salvo.kills,
        killsBuffer  = {},
        xpBuffer     = {},
    }

    task.spawn(function()
        task.wait(1)
        local data = DataController.Data
        if data and data.LevelData then
            if Sessao.xpInicial == 0 then
                Sessao.xpInicial    = data.LevelData.XP    or 0
            end
            if Sessao.levelInicial == 0 then
                Sessao.levelInicial = data.LevelData.Level or 0
            end
        end
    end)

    -- ══════════════════════════════════════════════════
    -- // KILL COUNTER
    -- ══════════════════════════════════════════════════

    local conexoesAtivas = {}

    local function conectarKillCounter(pasta)
        if conexoesAtivas[pasta] then return end

        local conn = pasta.ChildRemoved:Connect(function(child)
            if child:IsA("Model") then
                local hum = child:FindFirstChildOfClass("Humanoid")
                    or child:FindFirstChild("Humanoid")
                if hum then
                    Sessao.kills += 1
                    table.insert(Sessao.killsBuffer, tick())
                    salvarSessao(Sessao)
                end
            end
        end)

        conexoesAtivas[pasta] = conn

        pasta.AncestryChanged:Connect(function()
            if not pasta:IsDescendantOf(game) then
                if conexoesAtivas[pasta] then
                    conexoesAtivas[pasta]:Disconnect()
                    conexoesAtivas[pasta] = nil
                end
            end
        end)
    end

    task.spawn(function()
        local function tentarConectar()
            local pasta = game.Workspace:FindFirstChild("EnemyNpc")
            if pasta then conectarKillCounter(pasta) end
        end

        tentarConectar()

        game.Workspace.ChildAdded:Connect(function(child)
            if child.Name == "EnemyNpc" then
                task.wait(0.1)
                conectarKillCounter(child)
            end
        end)

        while task.wait(5) do
            tentarConectar()
        end
    end)

    -- Snapshot de XP a cada 10s
    task.spawn(function()
        while task.wait(10) do
            local data = DataController.Data
            if data and data.LevelData then
                table.insert(Sessao.xpBuffer, {
                    t  = tick(),
                    xp = data.LevelData.XP or 0,
                })
                if #Sessao.xpBuffer > 6 then
                    table.remove(Sessao.xpBuffer, 1)
                end
                salvarSessao(Sessao)
            end
        end
    end)

    -- ── Helpers ────────────────────────────────────────

    local function formatarTempo(segundos)
        segundos = math.floor(segundos)
        if segundos < 60 then
            return segundos .. "s"
        elseif segundos < 3600 then
            return math.floor(segundos / 60) .. "m " .. (segundos % 60) .. "s"
        else
            local h = math.floor(segundos / 3600)
            local m = math.floor((segundos % 3600) / 60)
            return h .. "h " .. m .. "m"
        end
    end

    local function formatarNumero(n)
        n = tonumber(n) or 0
        if n >= 1000000 then
            return string.format("%.1fM", n / 1000000)
        elseif n >= 1000 then
            return string.format("%.1fK", n / 1000)
        end
        return tostring(math.floor(n))
    end

    local function calcularKillsMinuto()
        local agora = tick()
        local i = 1
        while i <= #Sessao.killsBuffer do
            if agora - Sessao.killsBuffer[i] > 60 then
                table.remove(Sessao.killsBuffer, i)
            else
                i += 1
            end
        end
        return #Sessao.killsBuffer
    end

    local function calcularXpMinuto()
        if #Sessao.xpBuffer < 2 then return 0 end
        local primeiro = Sessao.xpBuffer[1]
        local ultimo   = Sessao.xpBuffer[#Sessao.xpBuffer]
        local deltaXP  = ultimo.xp - primeiro.xp
        local deltaSeg = ultimo.t  - primeiro.t
        if deltaSeg <= 0 then return 0 end
        return (deltaXP / deltaSeg) * 60
    end

    local function xpParaProximoLevel(level, xpAtual)
        local xpNecessario = math.floor(100 * (level ^ 1.5))
        if xpNecessario <= 0 then xpNecessario = 1 end
        local falta = xpNecessario - (xpAtual % xpNecessario)
        return falta, xpNecessario
    end

    local function calcularTempoParaLevel(xpPorMinuto, xpFaltando)
        if xpPorMinuto <= 0 then return "∞" end
        return formatarTempo((xpFaltando / xpPorMinuto) * 60)
    end

    local function extrairNome(opcao)
        if type(opcao) == "table" then opcao = opcao[1] or "" end
        return opcao:match("^(.-)%s*%(") or opcao
    end

    -- ── Inventário ─────────────────────────────────────

    local function getOresDisponiveis()
        local ores  = (DataController.Data and DataController.Data.Ores) or {}
        local lista = {}
        for minerio, quantidade in pairs(ores) do
            if quantidade and quantidade > 0 then
                table.insert(lista, minerio .. " (" .. quantidade .. ")")
            end
        end
        if #lista == 0 then table.insert(lista, "No ores") end
        return lista
    end

    local function venderMinerio(minerioSelecionado, callback)
        if not minerioSelecionado or minerioSelecionado == "No ores" then
            if callback then callback(false, "Select an ore first!") end
            return
        end
        local quantidade = (DataController.Data.Ores and DataController.Data.Ores[minerioSelecionado]) or 0
        if quantidade <= 0 then
            if callback then callback(false, minerioSelecionado .. " is empty!") end
            return
        end
        pcall(function() ForgeRF:InvokeServer("Sell", {minerioSelecionado}) end)
        pcall(function() RedPointRE:FireServer("Clear", "Ores", minerioSelecionado) end)
        if callback then callback(true, quantidade .. "x " .. minerioSelecionado .. " sold!") end
    end

    local function getListaEquipamentos(tipo)
        local equipment = (DataController.Data and DataController.Data.Equipment) or {}
        local owned     = equipment.Owned    or {}
        local equipped  = equipment.Equipped or {}
        local lista     = {}
        local mapaUUID  = {}
        for uuid, dados in pairs(owned) do
            if type(dados) == "table" and dados.Type == tipo and not equipped[uuid] then
                local itemData = (tipo == "Weapon")
                    and (ok1 and ResWeapon[dados.ID] or nil)
                    or  (ok2 and ResArmor[dados.ID]  or nil)
                local rarity = itemData and itemData.Rarity or "?"
                local price  = itemData and itemData.Price  or "?"
                local label  = dados.ID .. " | R:" .. tostring(rarity) .. " | $" .. tostring(price)
                table.insert(lista, label)
                mapaUUID[label] = uuid
            end
        end
        if #lista == 0 then table.insert(lista, "No items") end
        return lista, mapaUUID
    end

    local function venderEquipamento(uuid, callback)
        if not uuid then
            if callback then callback(false, "No item selected!") end
            return
        end
        pcall(function() EquipmentRE:FireServer("Sell", {uuid}) end)
        if callback then callback(true, "Item sold successfully!") end
    end

    -- ── Stats Snapshot ─────────────────────────────────

    local function getStatsSnapshot()
        local ok, data = pcall(function() return DataController.Data end)
        if not ok or not data then return nil end

        local levelData = data.LevelData        or {}
        local currency  = data.Currency         or {}
        local crystals  = data.Crystals         or {}
        local ores      = data.Ores             or {}
        local attrs     = data.AttributeUpgrade or {}
        local attrLvs   = attrs.AttributeLvs   or {}

        local level = levelData.Level or 0
        local xp    = levelData.XP    or 0
        local curr  = currency.Currency1 or 0

        local xpFalta, xpTotal = xpParaProximoLevel(level, xp)
        local xpPct = math.floor(((xpTotal - xpFalta) / math.max(xpTotal, 1)) * 100)

        local totalOres = 0
        local oreStr    = ""
        for minerio, qtd in pairs(ores) do
            if qtd and qtd > 0 then
                totalOres += qtd
                oreStr = oreStr .. minerio .. ": " .. qtd .. "  |  "
            end
        end

        local tempoSessao = tick() - Sessao.inicio
        local xpGanho     = xp - Sessao.xpInicial
        local lvlGanho    = level - Sessao.levelInicial
        local kpm         = calcularKillsMinuto()
        local xpm         = calcularXpMinuto()
        local xph         = xpm * 60
        local tempoLvl    = calcularTempoParaLevel(xpm, xpFalta)

        return {
            level      = level,
            xp         = formatarNumero(xp),
            xpFalta    = formatarNumero(xpFalta),
            xpPct      = xpPct,
            currency   = formatarNumero(curr),
            shards     = crystals.CrystalShards or 0,
            flake      = crystals.CrystalFlake  or 0,
            prism      = crystals.CrystalPrism  or 0,
            totalOres  = totalOres,
            oreStr     = totalOres > 0
                and ("Total: " .. totalOres .. "  →  " .. oreStr:sub(1, -5))
                or "No ores in inventory",
            atkBonus          = attrLvs.AtkBonusValue or 0,
            hpBonus           = attrLvs.HpBonus       or 0,
            pontosDisponiveis = attrs.RemainingPoint   or 0,
            tempoSessao = formatarTempo(tempoSessao),
            lvlGanho    = lvlGanho,
            xpGanho     = formatarNumero(math.max(0, xpGanho)),
            kills       = Sessao.kills,
            kpm         = kpm,
            xpm         = formatarNumero(xpm),
            xph         = formatarNumero(xph),
            tempoLvl    = tempoLvl,
        }
    end

    local function resetarSessao()
        local data = DataController.Data
        Sessao.kills        = 0
        Sessao.killsBuffer  = {}
        Sessao.xpBuffer     = {}
        Sessao.inicio       = tick()
        Sessao.xpInicial    = (data and data.LevelData and data.LevelData.XP)    or 0
        Sessao.levelInicial = (data and data.LevelData and data.LevelData.Level) or 0
        salvarSessao(Sessao)
    end

    return {
        formatarTempo         = formatarTempo,
        formatarNumero        = formatarNumero,
        extrairNome           = extrairNome,
        getOresDisponiveis    = getOresDisponiveis,
        venderMinerio         = venderMinerio,
        getListaEquipamentos  = getListaEquipamentos,
        venderEquipamento     = venderEquipamento,
        getStatsSnapshot      = getStatsSnapshot,
        resetarSessao         = resetarSessao,
        Sessao                = Sessao,
        DataController        = DataController,
    }
end)()

-- [3] Executa Rayfield
local rayfieldFn, rayfieldErr = loadstring(rayfieldSource)
if not rayfieldFn then error("[GUI-HUB] Rayfield failed: " .. tostring(rayfieldErr)) end
local Rayfield = rayfieldFn()

-- ══════════════════════════════════════════════════════
-- // WINDOW
-- ══════════════════════════════════════════════════════

local Window = Rayfield:CreateWindow({
    Name             = "Iron Soul | UPDT 04/30",
    LoadingTitle     = "Iron Soul: Dungeon [BETA]",
    LoadingSubtitle  = "by Noliar",
    ShowText         = "v1.2",
    Theme            = "Default",
    ToggleUIKeybind  = "L",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = false,
    ConfigurationSaving = {
        Enabled    = false, -- desativado, usamos nosso próprio sistema
        FolderName = nil,
        FileName   = "Noliar-HUB",
    },
    Discord   = { Enabled = false },
    KeySystem = false,
})

-- ══════════════════════════════════════════════════════
-- // TAB 1 — FARM
-- ══════════════════════════════════════════════════════

local FarmTab = Window:CreateTab("Farm", nil)

FarmTab:CreateSection("Dungeon Automation - Only enable these if you are inside a Dungeon   ")

local KillAuraToggleRef

local AutoDungeonToggle
AutoDungeonToggle = FarmTab:CreateToggle({
    Name         = "Auto Dungeon Bot",
    CurrentValue = _G.AutoDungeonBot,
    Flag         = "AutoDungeonBot",
    Callback     = function(Value)
        _G.AutoDungeonBot = Value
        if Value then
            _G.KillAura = true
            if KillAuraToggleRef then KillAuraToggleRef:Set(true) end
        else
            _G.BotOcupado     = false
            _G.AntiStuckAtivo = false
            _G.QuebrandoBau   = false
        end
        salvarConfigs()
    end,
})

FarmTab:CreateToggle({
    Name         = "Auto Replay  (Auto-Rerun after Victory)",
    CurrentValue = _G.AutoReplay,
    Flag         = "AutoReplay",
    Callback     = function(Value)
        _G.AutoReplay = Value
        salvarConfigs()
    end,
})

FarmTab:CreateSection("Auto Skills")

FarmTab:CreateToggle({
    Name         = "Skill 1",
    CurrentValue = _G.SkillsAtivas.Skill1,
    Flag         = "Skill1",
    Callback     = function(Value)
        _G.SkillsAtivas.Skill1 = Value
        salvarConfigs()
    end,
})

FarmTab:CreateToggle({
    Name         = "Skill 2",
    CurrentValue = _G.SkillsAtivas.Skill2,
    Flag         = "Skill2",
    Callback     = function(Value)
        _G.SkillsAtivas.Skill2 = Value
        salvarConfigs()
    end,
})

FarmTab:CreateToggle({
    Name         = "Skill U  (Ultimate)",
    CurrentValue = _G.SkillsAtivas.SkillU,
    Flag         = "SkillU",
    Callback     = function(Value)
        _G.SkillsAtivas.SkillU = Value
        salvarConfigs()
    end,
})

FarmTab:CreateSection("Live Status")

local RoundLabel = FarmTab:CreateLabel("Current Round:  1")
local BotLabel   = FarmTab:CreateLabel("Bot Busy:  WORKING")
local StuckLabel = FarmTab:CreateLabel("Anti-Stuck:  Active")
local ChestLabel = FarmTab:CreateLabel("Breaking Chest:  Breaking")

task.spawn(function()
    while task.wait(0.8) do
        pcall(function()
            local botAtivo  = _G.AutoDungeonBot or false
            local botBusy   = botAtivo and (_G.BotOcupado     ~= false)
            local antiStuck = botAtivo and (_G.AntiStuckAtivo ~= false)
            local chest     = _G.QuebrandoBau or false

            RoundLabel:Set("Current Round:  " .. tostring(_G.RoundAtual or 1))
            BotLabel:Set("Bot Busy:  "         .. (botBusy   and "WORKING ⚙️" or "ON"))
            StuckLabel:Set("Anti-Stuck:  "     .. (antiStuck and "Active 🔄" or "ON"))
            ChestLabel:Set("Breaking Chest:  " .. (chest     and "Breaking 📦" or "ON"))
        end)
    end
end)

-- ══════════════════════════════════════════════════════
-- // TAB 2 — KILL AURA
-- ══════════════════════════════════════════════════════

local KATab = Window:CreateTab("Kill Aura", nil)

KATab:CreateSection("Kill Aura Control")

KillAuraToggleRef = KATab:CreateToggle({
    Name         = "Enable Kill Aura",
    CurrentValue = _G.KillAura,
    Flag         = "KillAura",
    Callback     = function(Value)
        _G.KillAura = Value
        salvarConfigs()
    end,
})

KATab:CreateToggle({
    Name         = "Noclip",
    CurrentValue = _G.KillAura_Noclip,
    Flag         = "KillAuraNoclip",
    Callback     = function(Value)
        _G.KillAura_Noclip = Value
        salvarConfigs()
    end,
})

-- Movement Mode fixado em fly
_G.KillAura_Mode = "fly"

KATab:CreateDropdown({
    Name          = "Target Priority",
    Options       = { "closest", "lowestHP", "boss" },
    CurrentOption = { _G.KillAura_Priority },
    Flag          = "KillAuraPriority",
    Callback      = function(Option)
        _G.KillAura_Priority = (type(Option) == "table") and Option[1] or Option
        salvarConfigs()
    end,
})

KATab:CreateSection("Fly & Attack Settings")

KATab:CreateSlider({
    Name         = "Fly Speed",
    Range        = { 10, 500 },
    Increment    = 10,
    Suffix       = " spd",
    CurrentValue = _G.KillAura_FlySpeed,
    Flag         = "KillAuraFlySpeed",
    Callback     = function(Value)
        _G.KillAura_FlySpeed = Value
        salvarConfigs()
    end,
})

KATab:CreateSlider({
    Name         = "Attacks Per Second (APS)",
    Range        = { 1, 30 },
    Increment    = 1,
    Suffix       = " atk/s",
    CurrentValue = _G.KillAura_APS,
    Flag         = "KillAuraAPS",
    Callback     = function(Value)
        _G.KillAura_APS = Value
        salvarConfigs()
    end,
})

KATab:CreateSlider({
    Name         = "Y Offset  (Height above enemy)",
    Range        = { 0, 13 },
    Increment    = 1,
    Suffix       = " studs",
    CurrentValue = math.min(_G.KillAura_OffsetY, 13),
    Flag         = "KillAuraOffsetY",
    Callback     = function(Value)
        _G.KillAura_OffsetY = Value
        salvarConfigs()
    end,
})

KATab:CreateSection("Orbit Settings")

KATab:CreateToggle({
    Name         = "Enable Orbit Mode",
    CurrentValue = _G.KillAura_Orbit,
    Flag         = "KillAuraOrbit",
    Callback     = function(Value)
        _G.KillAura_Orbit = Value
        salvarConfigs()
    end,
})

KATab:CreateSlider({
    Name         = "Orbit Radius",
    Range        = { 1, 15 },
    Increment    = 1,
    Suffix       = " studs",
    CurrentValue = math.min(_G.KillAura_OrbitRadius, 15),
    Flag         = "KillAuraOrbitRadius",
    Callback     = function(Value)
        _G.KillAura_OrbitRadius = Value
        salvarConfigs()
    end,
})

KATab:CreateSlider({
    Name         = "Orbit Speed",
    Range        = { 1, 20 },
    Increment    = 1,
    Suffix       = " rad/s",
    CurrentValue = math.min(_G.KillAura_OrbitSpeed, 20),
    Flag         = "KillAuraOrbitSpeed",
    Callback     = function(Value)
        _G.KillAura_OrbitSpeed = Value
        salvarConfigs()
    end,
})

-- ══════════════════════════════════════════════════════
-- // TAB 3 — SELL
-- ══════════════════════════════════════════════════════

local SellTab = Window:CreateTab("Sell", nil)

SellTab:CreateSection("Ores")

local oreOptions     = IronSoulLib.getOresDisponiveis()  -- declarada ANTES
local oreSelecionado = oreOptions[1]                     -- agora é seguro
local OreDropdown = SellTab:CreateDropdown({
    Name          = "Select Ore to Sell",
    Options       = oreOptions,
    CurrentOption = { oreOptions[1] },
    Flag          = "OreDropdown",
    Callback      = function(Option)
        oreSelecionado = (type(Option) == "table") and Option[1] or Option
    end,
})

SellTab:CreateButton({
    Name     = "Sell Selected Ore",
    Callback = function()
        local name = IronSoulLib.extrairNome(oreSelecionado)
        IronSoulLib.venderMinerio(name, function(ok, msg)
            Rayfield:Notify({ Title = ok and "Ore Sold!" or "Error", Content = msg, Duration = 3 })
        end)
    end,
})

SellTab:CreateSection("Weapons")

local weaponOptions, weaponMap = IronSoulLib.getListaEquipamentos("Weapon")
local weaponSelecionado = weaponOptions[1]
local WeaponDropdown = SellTab:CreateDropdown({
    Name          = "Select Weapon to Sell",
    Options       = weaponOptions,
    CurrentOption = { weaponOptions[1] },
    Flag          = "WeaponDropdown",
    Callback      = function(Option)
        weaponSelecionado = (type(Option) == "table") and Option[1] or Option
    end,
})

SellTab:CreateButton({
    Name     = "Sell Selected Weapon",
    Callback = function()
        local uuid = weaponMap[weaponSelecionado]
        IronSoulLib.venderEquipamento(uuid, function(ok, msg)
            Rayfield:Notify({ Title = ok and "Weapon Sold!" or "Error", Content = msg, Duration = 3 })
        end)
    end,
})

SellTab:CreateSection("Armor")

local armorOptions, armorMap = IronSoulLib.getListaEquipamentos("Armor")
local armorSelecionado = armorOptions[1]
local ArmorDropdown = SellTab:CreateDropdown({
    Name          = "Select Armor to Sell",
    Options       = armorOptions,
    CurrentOption = { armorOptions[1] },
    Flag          = "ArmorDropdown",
    Callback      = function(Option)
        armorSelecionado = (type(Option) == "table") and Option[1] or Option
    end,
})

SellTab:CreateButton({
    Name     = "Sell Selected Armor",
    Callback = function()
        local uuid = armorMap[armorSelecionado]
        IronSoulLib.venderEquipamento(uuid, function(ok, msg)
            Rayfield:Notify({ Title = ok and "Armor Sold!" or "Error", Content = msg, Duration = 3 })
        end)
    end,
})

SellTab:CreateSection("Refresh")

SellTab:CreateButton({
    Name     = "Refresh All Lists",
    Callback = function()
        pcall(function()
            local oreList = IronSoulLib.getOresDisponiveis()
            oreSelecionado = oreList[1]
            OreDropdown:Refresh(oreList, { oreList[1] })

            local wList, wMap = IronSoulLib.getListaEquipamentos("Weapon")
            weaponOptions = wList; weaponMap = wMap
            weaponSelecionado = wList[1]
            WeaponDropdown:Refresh(wList, { wList[1] })

            local aList, aMap = IronSoulLib.getListaEquipamentos("Armor")
            armorOptions = aList; armorMap = aMap
            armorSelecionado = aList[1]
            ArmorDropdown:Refresh(aList, { aList[1] })
        end)
        Rayfield:Notify({ Title = "Refreshed", Content = "All lists updated.", Duration = 2 })
    end,
})

-- ══════════════════════════════════════════════════════
-- // TAB 4 — STATS
-- ══════════════════════════════════════════════════════

local StatsTab = Window:CreateTab("Stats", nil)

StatsTab:CreateSection("Player Profile")
local LevelLabel    = StatsTab:CreateLabel("Level:  —")
local XPLabel       = StatsTab:CreateLabel("XP:  —  |  Missing: —  (—%)")
local CurrencyLabel = StatsTab:CreateLabel("Currency:  —")

StatsTab:CreateSection("Crystals")
local ShardsLabel = StatsTab:CreateLabel("Shards:  —")
local FlakeLabel  = StatsTab:CreateLabel("Flake:  —")
local PrismLabel  = StatsTab:CreateLabel("Prism:  —")

StatsTab:CreateSection("Attributes")
local AtkLabel = StatsTab:CreateLabel("ATK Bonus:  —")
local HpLabel  = StatsTab:CreateLabel("HP Bonus:  —")
local PtsLabel = StatsTab:CreateLabel("Stat Points Available:  —")

StatsTab:CreateSection("Ores in Inventory")
local OreStrLabel = StatsTab:CreateLabel("—")

local oreWarningAtivo = false

StatsTab:CreateSection("Session")
local SessionTimeLabel = StatsTab:CreateLabel("Session Time:  —")
local LvlGainLabel     = StatsTab:CreateLabel("Levels Gained:  —")
local XpGainLabel      = StatsTab:CreateLabel("XP Gained:  —")
local KillsStatLabel   = StatsTab:CreateLabel("Kills:  —")

StatsTab:CreateSection("Metrics")
local KPMLabel     = StatsTab:CreateLabel("Kills/min (last 60s):  —")
local XPMLabel     = StatsTab:CreateLabel("XP/min:  —")
local XPHLabel     = StatsTab:CreateLabel("XP/hour:  —")
local TimeLvlLabel = StatsTab:CreateLabel("Est. Time to Next Level:  —")

task.spawn(function()
    while task.wait(2) do
        pcall(function()
            local s = IronSoulLib.getStatsSnapshot()
            if not s then return end

            LevelLabel:Set("Level:  " .. tostring(s.level))
            XPLabel:Set("XP:  " .. s.xp .. "  |  Missing: " .. s.xpFalta .. "  (" .. s.xpPct .. "%)")
            CurrencyLabel:Set("Currency:  " .. s.currency)
            ShardsLabel:Set("Shards:  " .. tostring(s.shards))
            FlakeLabel:Set("Flake:  "   .. tostring(s.flake))
            PrismLabel:Set("Prism:  "   .. tostring(s.prism))
            AtkLabel:Set("ATK Bonus:  " .. tostring(s.atkBonus))
            HpLabel:Set("HP Bonus:  "   .. tostring(s.hpBonus))
            PtsLabel:Set("Stat Points Available:  " .. tostring(s.pontosDisponiveis))
            OreStrLabel:Set(s.oreStr)

            if s.totalOres >= 100 and not oreWarningAtivo then
                oreWarningAtivo = true
                Rayfield:Notify({
                    Title    = "⚠️ Ore Inventory Almost Full!",
                    Content  = "You have " .. s.totalOres .. " ores! Sell them before reaching the limit!",
                    Duration = 15,
                })
                task.delay(60, function() oreWarningAtivo = false end)
            end

            SessionTimeLabel:Set("Session Time:  " .. s.tempoSessao)
            LvlGainLabel:Set("Levels Gained:  "    .. tostring(s.lvlGanho))
            XpGainLabel:Set("XP Gained:  "         .. s.xpGanho)
            KillsStatLabel:Set("Kills:  "           .. tostring(s.kills))
            KPMLabel:Set("Kills/min (last 60s):  " .. tostring(s.kpm))
            XPMLabel:Set("XP/min:  "               .. s.xpm)
            XPHLabel:Set("XP/hour:  "              .. s.xph)
            TimeLvlLabel:Set("Est. Time to Next Level:  " .. s.tempoLvl)
        end)
    end
end)

-- ══════════════════════════════════════════════════════
-- // TAB 5 — SETTINGS
-- ══════════════════════════════════════════════════════

local SettingsTab = Window:CreateTab("Settings", nil)

-- ── Config Save/Load ───────────────────────────────────
SettingsTab:CreateSection("Config  —  Controls auto-save and auto-load of all toggle/slider settings.")

SettingsTab:CreateToggle({
    Name         = "Auto Save",
    CurrentValue = autoSaveAtivo,
    Flag         = "AutoSave",
    Callback     = function(Value)
        autoSaveAtivo = Value
        Rayfield:Notify({
            Title   = Value and "Auto Save ON" or "Auto Save OFF",
            Content = Value and "Settings will be saved automatically on every change." or "Settings will NOT be saved automatically. Use the Save button manually.",
            Duration = 4,
        })
    end,
})

SettingsTab:CreateToggle({
    Name         = "Auto Load Save",
    CurrentValue = autoLoadAtivo,
    Flag         = "AutoLoad",
    Callback     = function(Value)
        autoLoadAtivo = Value
        Rayfield:Notify({
            Title   = Value and "Auto Load ON" or "Auto Load OFF",
            Content = Value and "Settings will be restored automatically next time you run the script." or "Settings will NOT be loaded on next start. Script will use default values.",
            Duration = 4,
        })
    end,
})

SettingsTab:CreateButton({
    Name     = "Save Config Now",
    Callback = function()
        local prev = autoSaveAtivo
        autoSaveAtivo = true
        salvarConfigs()
        autoSaveAtivo = prev
        Rayfield:Notify({
            Title   = "Config Saved!",
            Content = "All current settings have been saved",
            Duration = 4,
        })
    end,
})

SettingsTab:CreateButton({
    Name     = "Load Savee Config Now",
    Callback = function()
        local ok = pcall(function()
            if isfile(CONFIG_FILE) then
                local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
                Rayfield:Notify({
                    Title   = "Config Loaded!",
                    Content = "Settings file found. Values will be fully applied on next script start.",
                    Duration = 5,
                })
            else
                Rayfield:Notify({
                    Title   = "No Config Found",
                    Content = "No saved config file found. Save your settings first.",
                    Duration = 4,
                })
            end
        end)
        if not ok then
            Rayfield:Notify({ Title = "Error", Content = "Failed to read config file.", Duration = 3 })
        end
    end,
})

-- ── Reset Stats ────────────────────────────────────────
SettingsTab:CreateSection("Reset Stats  —  Clears session data: kills, XP gained, levels gained and session time.")

SettingsTab:CreateButton({
    Name     = "Reset Session Stats",
    Callback = function()
        IronSoulLib.resetarSessao()
        _G.RoundAtual    = 1
        _G.PortaisUsados = {}
        Rayfield:Notify({
            Title   = "Session Reset",
            Content = "Kills, XP gained, levels and session time have been cleared.",
            Duration = 4,
        })
    end,
})


-- ── General ────────────────────────────────────────────
SettingsTab:CreateSection("General  —  Disabling loops stops Farm, Kill Aura and Skills. Restart to resume.")

SettingsTab:CreateToggle({
    Name         = "Master Loop Active  (Disabling stops all automation)",
    CurrentValue = _G.LoopAtivo,
    Flag         = "LoopAtivo",
    Callback     = function(Value)
        _G.LoopAtivo = Value
        salvarConfigs()
        Rayfield:Notify({
            Title   = Value and "Loops Enabled" or "Loops Disabled",
            Content = Value and "Farm, Kill Aura and Skills are running." or "All loops stopped. Restart the script to resume.",
            Duration = 4,
        })
    end,
})

-- ══════════════════════════════════════════════════════
-- // READY
-- ══════════════════════════════════════════════════════

Rayfield:Notify({
    Title   = "Farm HUB Loaded!",
    Content = "Session data restored. All systems ready." .. (isfile(CONFIG_FILE) and " Config loaded ✅" or " No config found, using defaults."),
    Duration = 5,
})
