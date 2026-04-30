-- ╔══════════════════════════════════════════════════════════════╗
-- ║              IronSoulLib  —  HubLogic.lua                   ║
-- ║   Lógica pura: serviços, sessão, helpers e inventário.      ║
-- ║   Retorna a tabela  IronSoulLib  para o Main.lua usar.      ║
-- ╚══════════════════════════════════════════════════════════════╝

-- ══════════════════════════════════════════════════════
-- // GLOBALS
-- ══════════════════════════════════════════════════════
_G.AutoDungeonBot  = false
_G.AutoReplay      = false
_G.KillAura        = false
_G.MapaSelecionado = "X"
_G.PortaisUsados   = {}
_G.SkillsAtivas    = {
    Skill1 = false,
    Skill2 = false,
    SkillU = false,
}

-- ══════════════════════════════════════════════════════
-- // SERVICES
-- ══════════════════════════════════════════════════════
local RS      = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local lp      = Players.LocalPlayer

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

-- Configs de equipamentos (falha silenciosa se não existirem)
local ok1, ResWeapon = pcall(require, RS:WaitForChild("Configs"):WaitForChild("ResWeapon"))
local ok2, ResArmor  = pcall(require, RS:WaitForChild("Configs"):WaitForChild("ResArmor"))

-- ══════════════════════════════════════════════════════
-- // SESSION  —  rastreamento de XP, Kills e Tempo
-- ══════════════════════════════════════════════════════
local Sessao = {
    inicio       = tick(),
    xpInicial    = 0,
    levelInicial = 0,
    kills        = 0,
    killsBuffer  = {},  -- timestamps para kills/min
    xpBuffer     = {},  -- snapshots para xp/min
}

-- Captura XP inicial assim que o dado carregar
task.spawn(function()
    task.wait(1)
    local data = DataController.Data
    if data and data.LevelData then
        Sessao.xpInicial    = data.LevelData.XP    or 0
        Sessao.levelInicial = data.LevelData.Level or 0
    end
end)

-- Listener de kills (aguarda a pasta existir)
task.spawn(function()
    while task.wait(0.1) do
        local pasta = game.Workspace:FindFirstChild("EnemyNpc")
        if pasta then
            pasta.ChildRemoved:Connect(function(child)
                if child:IsA("Model") and child:FindFirstChild("Humanoid") then
                    Sessao.kills += 1
                    table.insert(Sessao.killsBuffer, tick())
                end
            end)
            break
        end
    end
end)

-- Snapshot de XP a cada 10s (para calcular xp/min)
task.spawn(function()
    while task.wait(10) do
        local data = DataController.Data
        if data and data.LevelData then
            table.insert(Sessao.xpBuffer, {
                t  = tick(),
                xp = data.LevelData.XP or 0,
            })
            if #Sessao.xpBuffer > 6 then   -- mantém ~1 min de histórico
                table.remove(Sessao.xpBuffer, 1)
            end
        end
    end
end)

-- ══════════════════════════════════════════════════════
-- // HELPERS
-- ══════════════════════════════════════════════════════

-- Formata segundos → "1h 2m" / "3m 5s" / "45s"
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

-- Formata número grande → "1.2M" / "3.4K" / "999"
local function formatarNumero(n)
    if n >= 1_000_000 then
        return string.format("%.1fM", n / 1_000_000)
    elseif n >= 1_000 then
        return string.format("%.1fK", n / 1_000)
    end
    return tostring(math.floor(n))
end

-- Kills nos últimos 60s (limpa buffer automaticamente)
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

-- XP/min baseado nos snapshots do buffer
local function calcularXpMinuto()
    if #Sessao.xpBuffer < 2 then return 0 end
    local primeiro = Sessao.xpBuffer[1]
    local ultimo   = Sessao.xpBuffer[#Sessao.xpBuffer]
    local deltaXP  = ultimo.xp - primeiro.xp
    local deltaSeg = ultimo.t  - primeiro.t
    if deltaSeg <= 0 then return 0 end
    return (deltaXP / deltaSeg) * 60
end

-- XP necessário para o próximo level (ajuste a fórmula se souber a real)
local function xpParaProximoLevel(level, xpAtual)
    local xpNecessario = math.floor(100 * (level ^ 1.5))
    local falta = xpNecessario - (xpAtual % xpNecessario)
    return falta, xpNecessario
end

-- Tempo estimado para o próximo level em formato legível
local function calcularTempoParaLevel(xpPorMinuto, xpFaltando)
    if xpPorMinuto <= 0 then return "∞" end
    local minutos = xpFaltando / xpPorMinuto
    return formatarTempo(minutos * 60)
end

-- Extrai "NomeMinerio" de "NomeMinerio (42)"
local function extrairNome(opcao)
    if type(opcao) == "table" then
        opcao = opcao[1] or ""
    end
    return opcao:match("^(.-)%s*%(") or opcao
end

-- ══════════════════════════════════════════════════════
-- // INVENTORY  —  ores e equipamentos
-- ══════════════════════════════════════════════════════

-- Retorna lista de minérios com quantidade > 0
local function getOresDisponiveis()
    local ores  = DataController.Data.Ores
    local lista = {}
    for minerio, quantidade in pairs(ores) do
        if quantidade and quantidade > 0 then
            table.insert(lista, minerio .. " (" .. quantidade .. ")")
        end
    end
    if #lista == 0 then
        table.insert(lista, "Sem minérios")
    end
    return lista
end

-- Vende um minério via ForgeRF e limpa o RedPoint
local function venderMinerio(minerioSelecionado, callback)
    if not minerioSelecionado or minerioSelecionado == "Sem minérios" then
        if callback then callback(false, "Selecione um minério primeiro!") end
        return
    end
    local quantidade = DataController.Data.Ores[minerioSelecionado] or 0
    if quantidade <= 0 then
        if callback then callback(false, minerioSelecionado .. " está vazio!") end
        return
    end
    pcall(function() ForgeRF:InvokeServer("Sell", {minerioSelecionado}) end)
    pcall(function() RedPointRE:FireServer("Clear", "Ores", minerioSelecionado) end)
    if callback then callback(true, quantidade .. "x " .. minerioSelecionado .. " vendido!") end
end

-- Retorna lista de equipamentos não equipados e mapa label→uuid
local function getListaEquipamentos(tipo)
    local equipment = DataController.Data.Equipment
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
    return lista, mapaUUID
end

-- Vende equipamento pelo UUID via EquipmentRE
local function venderEquipamento(uuid, callback)
    if not uuid then
        if callback then callback(false, "Nenhum item selecionado!") end
        return
    end
    pcall(function() EquipmentRE:FireServer("Sell", {uuid}) end)
    if callback then callback(true, "Item vendido com sucesso!") end
end

-- ══════════════════════════════════════════════════════
-- // STATS SNAPSHOT  —  snapshot completo para a UI
-- ══════════════════════════════════════════════════════

-- Retorna uma tabela com todos os dados processados de uma vez.
-- O Main.lua só precisa chamar essa função no loop de atualização.
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
    local xpPct = math.floor(((xpTotal - xpFalta) / xpTotal) * 100)

    -- Minérios em texto
    local totalOres = 0
    local oreStr    = ""
    for minerio, qtd in pairs(ores) do
        if qtd and qtd > 0 then
            totalOres += qtd
            oreStr = oreStr .. minerio .. ": " .. qtd .. "  |  "
        end
    end

    -- Sessão
    local tempoSessao = tick() - Sessao.inicio
    local xpGanho     = xp - Sessao.xpInicial
    local lvlGanho    = level - Sessao.levelInicial

    -- Métricas
    local kpm = calcularKillsMinuto()
    local xpm = calcularXpMinuto()
    local xph = xpm * 60
    local tempoLvl = calcularTempoParaLevel(xpm, xpFalta)

    return {
        -- Perfil
        level      = level,
        xp         = formatarNumero(xp),
        xpFalta    = formatarNumero(xpFalta),
        xpPct      = xpPct,
        currency   = formatarNumero(curr),

        -- Cristais
        shards = crystals.CrystalShards or 0,
        flake  = crystals.CrystalFlake  or 0,
        prism  = crystals.CrystalPrism  or 0,

        -- Minérios
        totalOres = totalOres,
        oreStr    = totalOres > 0
            and ("Total: " .. totalOres .. "  →  " .. oreStr:sub(1, -5))
            or "Nenhum minério no bolso",

        -- Atributos
        atkBonus        = attrLvs.AtkBonusValue or 0,
        hpBonus         = attrLvs.HpBonus       or 0,
        pontosDisponiveis = attrs.RemainingPoint or 0,

        -- Sessão
        tempoSessao = formatarTempo(tempoSessao),
        lvlGanho    = lvlGanho,
        xpGanho     = formatarNumero(math.max(0, xpGanho)),

        -- Métricas
        kpm        = kpm,
        xpm        = formatarNumero(xpm),
        xph        = formatarNumero(xph),
        tempoLvl   = tempoLvl,
    }
end

-- ══════════════════════════════════════════════════════
-- // EXPORT  —  tabela pública IronSoulLib
-- ══════════════════════════════════════════════════════
local IronSoulLib = {
    -- Helpers expostos (úteis para o Main.lua pontualmente)
    formatarTempo    = formatarTempo,
    formatarNumero   = formatarNumero,
    extrairNome      = extrairNome,

    -- Inventário
    getOresDisponiveis    = getOresDisponiveis,
    venderMinerio         = venderMinerio,
    getListaEquipamentos  = getListaEquipamentos,
    venderEquipamento     = venderEquipamento,

    -- Stats
    getStatsSnapshot = getStatsSnapshot,

    -- Sessão (leitura direta se necessário)
    Sessao = Sessao,

    -- Serviços (evita re-require no Main.lua)
    DataController = DataController,
    EquipmentRE    = EquipmentRE,
    ForgeRF        = ForgeRF,
    RedPointRE     = RedPointRE,
}

return IronSoulLib
