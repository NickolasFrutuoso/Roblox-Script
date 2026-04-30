-- Utils-HUB
 
local RS        = game:GetService("ReplicatedStorage")
local Players   = game:GetService("Players")
local lp        = Players.LocalPlayer
 
-- ══════════════════════════════════════════════════════
-- // REFERÊNCIAS DO JOGO
-- ══════════════════════════════════════════════════════
 
local Remotes       = RS:WaitForChild("Remotes")
local SellRE        = Remotes:WaitForChild("SellRE",        10)
local InventoryRE   = Remotes:WaitForChild("InventoryRE",   10)
local PlayerDataRE  = Remotes:WaitForChild("PlayerDataRE",  10)
local QuestRE       = Remotes:WaitForChild("QuestRE",       10)
 
-- ══════════════════════════════════════════════════════
-- // ESTADO INTERNO DE SESSÃO
-- // Atualizado externamente via _G (Farm-HUB.lua)
-- ══════════════════════════════════════════════════════
 
local sessaoInicio = tick()
 
local Sessao = {
    kills       = 0,
    vendasOres  = 0,
    vendasItens = 0,
    roundsFarm  = 0,
    xpInicio    = nil,   -- preenchido no primeiro getStatsSnapshot
    lvlInicio   = nil,
    moedasInicio = nil,
    killsBuffer  = {},   -- timestamps p/ calcular KPM
}
 
-- Exposto publicamente para o Farm-HUB incrementar
_G.HubLogic_Sessao = Sessao
 
-- ══════════════════════════════════════════════════════
-- // UTILITÁRIOS INTERNOS
-- ══════════════════════════════════════════════════════
 
local function segundosParaHMS(s)
    s = math.floor(s)
    local h = math.floor(s / 3600)
    local m = math.floor((s % 3600) / 60)
    local sg = s % 60
    if h > 0 then
        return string.format("%dh %02dm %02ds", h, m, sg)
    else
        return string.format("%dm %02ds", m, sg)
    end
end
 
local function formatNum(n)
    -- separa milhar: 1234567 → "1,234,567"
    local s = tostring(math.floor(n or 0))
    return s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end
 
-- lê um valor de PlayerData via RemoteFunction (ajuste conforme o jogo)
local function getPlayerData()
    if not PlayerDataRE then return nil end
    local ok, data = pcall(function()
        return PlayerDataRE:InvokeServer("GetData")
    end)
    return ok and data or nil
end
 
-- ══════════════════════════════════════════════════════
-- // MINÉRIOS
-- ══════════════════════════════════════════════════════
 
--[[
    getOresDisponiveis()
    Retorna lista de strings no formato "NomeOre (qtd)"
    para popular um Dropdown de UI.
]]
local function getOresDisponiveis()
    local lista = {}
    local ok, inv = pcall(function()
        return InventoryRE:InvokeServer("GetOres")
    end)
    if not ok or not inv then return lista end
 
    for nome, qtd in pairs(inv) do
        if type(qtd) == "number" and qtd > 0 then
            table.insert(lista, nome .. " (" .. qtd .. ")")
        end
    end
    table.sort(lista)
    return lista
end
 
--[[
    extrairNome(opcao)
    Remove o sufixo " (qtd)" que getOresDisponiveis adiciona.
    Exemplo: "Iron Ore (12)" → "Iron Ore"
]]
local function extrairNome(opcao)
    if not opcao then return "" end
    return (opcao:gsub("%s*%(%d+%)%s*$", ""))
end
 
--[[
    venderMinerio(nome, callback)
    Vende todos os itens do tipo `nome`.
    callback(sucesso: bool, mensagem: string)
]]
local function venderMinerio(nome, callback)
    if not nome or nome == "" then
        if callback then callback(false, "Nenhum minério selecionado.") end
        return
    end
    task.spawn(function()
        local ok, res = pcall(function()
            return SellRE:InvokeServer("SellOre", nome)
        end)
        if ok and res then
            Sessao.vendasOres += 1
            if callback then callback(true, "Vendido: " .. nome) end
        else
            if callback then callback(false, "Falha ao vender " .. nome) end
        end
    end)
end
 
--[[
    venderTodosOres(callback)
    Vende todos os minérios disponíveis.
    callback(quantidade: number)
]]
local function venderTodosOres(callback)
    task.spawn(function()
        local lista = getOresDisponiveis()
        local count = 0
        for _, opcao in ipairs(lista) do
            local nome = extrairNome(opcao)
            local ok = pcall(function()
                SellRE:InvokeServer("SellOre", nome)
            end)
            if ok then
                count += 1
                Sessao.vendasOres += 1
                task.wait(0.1)
            end
        end
        if callback then callback(count) end
    end)
end
 
-- ══════════════════════════════════════════════════════
-- // EQUIPAMENTOS (Armas / Armaduras)
-- ══════════════════════════════════════════════════════
 
--[[
    getListaEquipamentos(tipo)
    tipo = "Weapon" | "Armor"
    Retorna:
      lista  : { string }   — nomes formatados para Dropdown
      mapa   : { [nome] = { uuid, rarity, ... } }
]]
local function getListaEquipamentos(tipo)
    local lista = {}
    local mapa  = {}
 
    local ok, inv = pcall(function()
        return InventoryRE:InvokeServer("GetEquipment", tipo)
    end)
    if not ok or not inv then return lista, mapa end
 
    for _, item in ipairs(inv) do
        -- item esperado: { uuid, name, rarity, level, ... }
        local label = string.format("[%s] %s lv%s",
            item.rarity or "?",
            item.name   or "Item",
            item.level  or "?"
        )
        table.insert(lista, label)
        mapa[label] = item
    end
 
    return lista, mapa
end
 
--[[
    venderEquipamento(uuid, callback)
    Vende um item específico pelo UUID.
    callback(sucesso, mensagem)
]]
local function venderEquipamento(uuid, callback)
    if not uuid then
        if callback then callback(false, "Nenhum item selecionado.") end
        return
    end
    task.spawn(function()
        local ok, res = pcall(function()
            return SellRE:InvokeServer("SellItem", uuid)
        end)
        if ok and res then
            Sessao.vendasItens += 1
            if callback then callback(true, "Item vendido com sucesso!") end
        else
            if callback then callback(false, "Falha ao vender item.") end
        end
    end)
end
 
--[[
    venderTodosEquipamentos(tipo, callback)
    Vende todos os equipamentos do tipo informado.
    callback(quantidade)
]]
local function venderTodosEquipamentos(tipo, callback)
    task.spawn(function()
        local lista, mapa = getListaEquipamentos(tipo)
        local count = 0
        for _, label in ipairs(lista) do
            local item = mapa[label]
            if item and item.uuid then
                local ok = pcall(function()
                    SellRE:InvokeServer("SellItem", item.uuid)
                end)
                if ok then
                    count += 1
                    Sessao.vendasItens += 1
                    task.wait(0.1)
                end
            end
        end
        if callback then callback(count) end
    end)
end
 
-- ══════════════════════════════════════════════════════
-- // EQUIPAMENTO ATUAL
-- ══════════════════════════════════════════════════════
 
--[[
    getEquipamentoAtual()
    Retorna lista de slots equipados:
    { { slot, id, maxOre, factor }, ... }
]]
local function getEquipamentoAtual()
    local resultado = {}
    local ok, data = pcall(function()
        return InventoryRE:InvokeServer("GetEquipped")
    end)
    if not ok or not data then return resultado end
 
    for slot, item in pairs(data) do
        table.insert(resultado, {
            slot   = tostring(slot),
            id     = item.name   or item.id or "?",
            maxOre = item.maxOre or 0,
            factor = item.factor or 1,
        })
    end
    return resultado
end
 
-- ══════════════════════════════════════════════════════
-- // SNAPSHOT DE STATS
-- // Retorna tabela com TODOS os campos usados pela UI
-- ══════════════════════════════════════════════════════
 
--[[
    getStatsSnapshot()
    Retorna nil se os dados não estiverem disponíveis.
 
    Campos retornados:
      -- Perfil
      level, xp, xpFalta, xpPct, currency
      -- Cristais
      shards, flake, prism
      -- Minérios
      totalOres, oreLinhas   (table de strings)
      -- Atributos
      atkBonus, hpBonus, pontosDisponiveis
      -- Sessão
      tempoSessao, lvlGanho, xpGanho, moedas,
      roundsFarm, vendasOres, vendasItens, kills
      -- Métricas
      kpm, xpm, xph, moedasHora, tempoLvl, killsParaLevel
]]
local function getStatsSnapshot()
    local data = getPlayerData()
    if not data then return nil end
 
    -- ── Perfil ─────────────────────────────────────────
    local level   = data.level    or 0
    local xp      = data.xp       or 0
    local xpMax   = data.xpMax    or 1
    local xpFalta = math.max(0, xpMax - xp)
    local xpPct   = math.floor((xp / xpMax) * 100)
    local currency = data.currency or data.coins or 0
 
    -- inicializa referências de início de sessão
    if not Sessao.xpInicio   then Sessao.xpInicio    = xp       end
    if not Sessao.lvlInicio  then Sessao.lvlInicio   = level    end
    if not Sessao.moedasInicio then Sessao.moedasInicio = currency end
 
    -- ── Cristais ───────────────────────────────────────
    local cristais = data.crystals or {}
    local shards   = cristais.shards or data.crystalShards or 0
    local flake    = cristais.flake  or data.crystalFlake  or 0
    local prism    = cristais.prism  or data.crystalPrism  or 0
 
    -- ── Minérios ───────────────────────────────────────
    local ores       = data.ores or {}
    local totalOres  = 0
    local oreLinhas  = {}
    for nome, qtd in pairs(ores) do
        if type(qtd) == "number" and qtd > 0 then
            totalOres += qtd
            table.insert(oreLinhas, nome .. " x" .. qtd)
        end
    end
    table.sort(oreLinhas)
 
    -- ── Atributos ──────────────────────────────────────
    local attrs            = data.attributes or data.stats or {}
    local atkBonus         = attrs.atkBonus  or attrs.atk  or 0
    local hpBonus          = attrs.hpBonus   or attrs.hp   or 0
    local pontosDisponiveis = data.statPoints or data.attributePoints or 0
 
    -- ── Sessão ─────────────────────────────────────────
    local tempoSeg   = tick() - sessaoInicio
    local tempoSessao = segundosParaHMS(tempoSeg)
    local lvlGanho   = level    - Sessao.lvlInicio
    local xpGanho    = xp       - Sessao.xpInicio
    local moedasGanho = currency - Sessao.moedasInicio
    local kills       = (_G.KillAura_Sessao and _G.KillAura_Sessao.kills) or Sessao.kills
    local roundsFarm  = _G.RoundAtual and math.max(0, _G.RoundAtual - 1) or Sessao.roundsFarm
 
    -- ── Métricas ───────────────────────────────────────
    local minutos  = math.max(tempoSeg / 60, 0.01)
 
    -- KPM: usa killsBuffer (timestamps) dos últimos 60s
    local killsBuffer = (_G.KillAura_Sessao and _G.KillAura_Sessao.killsBuffer) or {}
    local agora       = tick()
    local killsRecentes = 0
    for _, t in ipairs(killsBuffer) do
        if agora - t <= 60 then killsRecentes += 1 end
    end
    local kpm        = formatNum(math.floor(killsRecentes))
    local xpm        = formatNum(math.floor(xpGanho  / minutos))
    local xph        = formatNum(math.floor(xpGanho  / minutos * 60))
    local moedasHora = formatNum(math.floor(moedasGanho / minutos * 60))
 
    -- Tempo estimado para próximo level
    local tempoLvl
    local killsParaLevel
    do
        local xpPorMin = xpGanho / minutos
        if xpPorMin > 0 then
            local segsParaLvl = (xpFalta / xpPorMin) * 60
            tempoLvl = segundosParaHMS(segsParaLvl)
        else
            tempoLvl = "—"
        end
 
        local kpmNum = killsRecentes
        if kpmNum > 0 and xpFalta > 0 then
            -- assume XP médio por kill = xpGanho / max(kills,1)
            local xpPorKill = xpGanho / math.max(kills, 1)
            killsParaLevel = formatNum(math.ceil(xpFalta / math.max(xpPorKill, 1)))
        else
            killsParaLevel = "—"
        end
    end
 
    return {
        -- Perfil
        level    = level,
        xp       = formatNum(xp),
        xpFalta  = formatNum(xpFalta),
        xpPct    = xpPct,
        currency = formatNum(currency),
        -- Cristais
        shards   = formatNum(shards),
        flake    = formatNum(flake),
        prism    = formatNum(prism),
        -- Minérios
        totalOres  = totalOres,
        oreLinhas  = oreLinhas,
        -- Atributos
        atkBonus          = atkBonus,
        hpBonus           = hpBonus,
        pontosDisponiveis = pontosDisponiveis,
        -- Sessão
        tempoSessao  = tempoSessao,
        lvlGanho     = lvlGanho,
        xpGanho      = formatNum(xpGanho),
        moedas       = formatNum(moedasGanho),
        roundsFarm   = roundsFarm,
        vendasOres   = Sessao.vendasOres,
        vendasItens  = Sessao.vendasItens,
        kills        = formatNum(kills),
        -- Métricas
        kpm            = kpm,
        xpm            = xpm,
        xph            = xph,
        moedasHora     = moedasHora,
        tempoLvl       = tempoLvl,
        killsParaLevel = killsParaLevel,
    }
end
 
-- ══════════════════════════════════════════════════════
-- // DAILY QUEST
-- ══════════════════════════════════════════════════════
 
--[[
    getDailyQuestStatus()
    Retorna:
      { completas, pendentes, rewardsPending }
]]
local function getDailyQuestStatus()
    local resultado = { completas = 0, pendentes = 0, rewardsPending = 0 }
    if not QuestRE then return resultado end
 
    local ok, quests = pcall(function()
        return QuestRE:InvokeServer("GetDailyQuests")
    end)
    if not ok or not quests then return resultado end
 
    for _, q in ipairs(quests) do
        if q.completed then
            resultado.completas += 1
            if not q.rewardClaimed then
                resultado.rewardsPending += 1
            end
        else
            resultado.pendentes += 1
        end
    end
    return resultado
end
 
-- ══════════════════════════════════════════════════════
-- // SEVEN DAILY
-- ══════════════════════════════════════════════════════
 
--[[
    getSevenDailyStatus()
    Retorna:
      { unlockDay, totalDisponivel }
]]
local function getSevenDailyStatus()
    local resultado = { unlockDay = 0, totalDisponivel = 0 }
    if not QuestRE then return resultado end
 
    local ok, data = pcall(function()
        return QuestRE:InvokeServer("GetSevenDaily")
    end)
    if not ok or not data then return resultado end
 
    resultado.unlockDay      = data.currentDay    or 0
    resultado.totalDisponivel = data.totalAvailable or 0
    return resultado
end
 
-- ══════════════════════════════════════════════════════
-- // EXPORT
-- ══════════════════════════════════════════════════════
 
return {
    -- Minérios
    getOresDisponiveis      = getOresDisponiveis,
    extrairNome             = extrairNome,
    venderMinerio           = venderMinerio,
    venderTodosOres         = venderTodosOres,
    -- Equipamentos
    getListaEquipamentos    = getListaEquipamentos,
    venderEquipamento       = venderEquipamento,
    venderTodosEquipamentos = venderTodosEquipamentos,
    getEquipamentoAtual     = getEquipamentoAtual,
    -- Stats / Sessão
    getStatsSnapshot        = getStatsSnapshot,
    getDailyQuestStatus     = getDailyQuestStatus,
    getSevenDailyStatus     = getSevenDailyStatus,
    -- Sessão (acesso direto para o Farm-HUB incrementar)
    Sessao                  = Sessao,
}
