-- Utils-HUB.lua

-- ══════════════════════════════════════════════════════
-- // IMPORTS
-- ══════════════════════════════════════════════════════

local Script_Iron = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/NickolasFrutuoso/Roblox-Script/refs/heads/main/Script_Iron.lua"
))()

local IronSoulLib = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/NickolasFrutuoso/Roblox-Script/refs/heads/main/HubLogic.lua"
))()

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- Atalhos
local getOresDisponiveis    = IronSoulLib.getOresDisponiveis
local venderMinerio         = IronSoulLib.venderMinerio
local venderTodosOres       = IronSoulLib.venderTodosOres
local getListaEquipamentos  = IronSoulLib.getListaEquipamentos
local venderEquipamento     = IronSoulLib.venderEquipamento
local venderTodosEquipamentos = IronSoulLib.venderTodosEquipamentos
local getEquipamentoAtual   = IronSoulLib.getEquipamentoAtual
local getStatsSnapshot      = IronSoulLib.getStatsSnapshot
local getDailyQuestStatus   = IronSoulLib.getDailyQuestStatus
local getSevenDailyStatus   = IronSoulLib.getSevenDailyStatus
local extrairNome           = IronSoulLib.extrairNome

-- ══════════════════════════════════════════════════════
-- // UI — WINDOW
-- ══════════════════════════════════════════════════════
local Window = Rayfield:CreateWindow({
    Name            = "Iron Soul Hub",
    LoadingTitle    = "Iron Soul: Dungeon",
    LoadingSubtitle = "by Noliar",
    ShowText        = "2.0",
    Theme           = "Default",
    ToggleUIKeybind = "L",

    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = false,

    ConfigurationSaving = {
        Enabled    = true,
        FolderName = nil,
        FileName   = "IronSoulHub",
    },

    KeySystem = false,
})

-- ══════════════════════════════════════════════════════
-- // TAB: FARM
-- ══════════════════════════════════════════════════════
local TabFarm = Window:CreateTab("⚔ Farm")

TabFarm:CreateSection("Automação")

TabFarm:CreateToggle({
    Name         = "Modo Farm",
    CurrentValue = false,
    Flag         = "ToggleFarm",
    Callback     = function(v) _G.AutoDungeonBot = v end,
})

TabFarm:CreateToggle({
    Name         = "Auto-Rerun",
    CurrentValue = false,
    Flag         = "ToggleRerun",
    Callback     = function(v) _G.AutoReplay = v end,
})

TabFarm:CreateDivider()
TabFarm:CreateSection("Mapa")

TabFarm:CreateDropdown({
    Name            = "Selecionar Mapa",
    Options         = {"Floresta Sem Estrela", "Vale Congelante"},
    CurrentOption   = {"Floresta Sem Estrela"},
    MultipleOptions = false,
    Flag            = "DropdownMapa",
    Callback = function(opcoes)
        if type(opcoes) == "table" then opcoes = opcoes[1] or "" end
        _G.MapaSelecionado = (opcoes == "Floresta Sem Estrela") and "X" or "Y"
        _G.PortaisUsados   = {}
    end,
})

-- ══════════════════════════════════════════════════════
-- // TAB: KILL AURA
-- ══════════════════════════════════════════════════════
local TabAura = Window:CreateTab("💀 Kill Aura")

TabAura:CreateSection("Controle")

TabAura:CreateToggle({
    Name         = "Kill Aura",
    CurrentValue = false,
    Flag         = "ToggleKillAura",
    Callback     = function(v) _G.KillAura = v end,
})

TabAura:CreateDivider()
TabAura:CreateSection("Modo de Movimento")

TabAura:CreateDropdown({
    Name            = "Modo",
    Options         = {"tp", "fly"},
    CurrentOption   = {"fly"},
    MultipleOptions = false,
    Flag            = "DropdownKAMode",
    Callback = function(v)
        if type(v) == "table" then v = v[1] end
        _G.KillAura_Mode = v
    end,
})

TabAura:CreateToggle({
    Name         = "Modo Órbita",
    CurrentValue = false,
    Flag         = "ToggleOrbit",
    Callback     = function(v) _G.KillAura_Orbit = v end,
})

TabAura:CreateSlider({
    Name         = "Raio Horizontal (Órbita)",
    Range        = {1, 20},
    Increment    = 1,
    CurrentValue = 6,
    Flag         = "SliderOrbitH",
    Callback     = function(v) _G.KillAura_OrbitRadiusH = v end,
})

TabAura:CreateSlider({
    Name         = "Altura (Órbita)",
    Range        = {0, 15},
    Increment    = 1,
    CurrentValue = 4,
    Flag         = "SliderOrbitV",
    Callback     = function(v) _G.KillAura_OrbitRadiusV = v end,
})

TabAura:CreateSlider({
    Name         = "Velocidade de Órbita",
    Range        = {1, 10},
    Increment    = 1,
    CurrentValue = 2,
    Flag         = "SliderOrbitSpeed",
    Callback     = function(v) _G.KillAura_OrbitSpeed = v end,
})

TabAura:CreateDivider()
TabAura:CreateSection("Ataque")

TabAura:CreateSlider({
    Name         = "Ataques por Segundo",
    Range        = {1, 30},
    Increment    = 1,
    CurrentValue = 30,
    Flag         = "SliderAPS",
    Callback     = function(v) _G.KillAura_APS = v end,
})

TabAura:CreateDropdown({
    Name            = "Prioridade de Alvo",
    Options         = {"closest", "lowestHP", "boss"},
    CurrentOption   = {"lowestHP"},
    MultipleOptions = false,
    Flag            = "DropdownPriority",
    Callback = function(v)
        if type(v) == "table" then v = v[1] end
        _G.KillAura_Priority = v
    end,
})

TabAura:CreateSlider({
    Name         = "Velocidade Fly (studs/s)",
    Range        = {50, 500},
    Increment    = 10,
    CurrentValue = 150,
    Flag         = "SliderFlySpeed",
    Callback     = function(v) _G.KillAura_FlySpeed = v end,
})

TabAura:CreateSlider({
    Name         = "Offset Y (Altura sobre alvo)",
    Range        = {0, 15},
    Increment    = 1,
    CurrentValue = 4,
    Flag         = "SliderOffsetY",
    Callback     = function(v) _G.KillAura_OffsetY = v end,
})

TabAura:CreateToggle({
    Name         = "Noclip",
    CurrentValue = true,
    Flag         = "ToggleNoclip",
    Callback     = function(v) _G.KillAura_Noclip = v end,
})

-- ══════════════════════════════════════════════════════
-- // TAB: HABILIDADES
-- ══════════════════════════════════════════════════════
local TabSkills = Window:CreateTab("✨ Skills")

TabSkills:CreateSection("Auto Skill")

TabSkills:CreateToggle({
    Name         = "[Q] Skill 1",
    CurrentValue = false,
    Flag         = "ToggleSkill1",
    Callback     = function(v) _G.SkillsAtivas.Skill1 = v end,
})

TabSkills:CreateToggle({
    Name         = "[E] Skill 2",
    CurrentValue = false,
    Flag         = "ToggleSkill2",
    Callback     = function(v) _G.SkillsAtivas.Skill2 = v end,
})

TabSkills:CreateToggle({
    Name         = "[R] Skill U",
    CurrentValue = false,
    Flag         = "ToggleSkillU",
    Callback     = function(v) _G.SkillsAtivas.SkillU = v end,
})

-- ══════════════════════════════════════════════════════
-- // TAB: VENDAS
-- ══════════════════════════════════════════════════════
local TabVendas = Window:CreateTab("💰 Vendas")

-- ── AUTO-SELL ─────────────────────────────────────────
TabVendas:CreateSection("Auto-Sell (ao fim de cada round)")

TabVendas:CreateToggle({
    Name         = "Auto-Sell Minérios",
    CurrentValue = false,
    Flag         = "ToggleAutoSellOres",
    Callback     = function(v) _G.AutoSellOres = v end,
})

TabVendas:CreateToggle({
    Name         = "Auto-Sell Armas",
    CurrentValue = false,
    Flag         = "ToggleAutoSellWeapons",
    Callback     = function(v) _G.AutoSellWeapons = v end,
})

TabVendas:CreateToggle({
    Name         = "Auto-Sell Armaduras",
    CurrentValue = false,
    Flag         = "ToggleAutoSellArmors",
    Callback     = function(v) _G.AutoSellArmors = v end,
})

TabVendas:CreateSlider({
    Name         = "Raridade Máxima para Auto-Sell (0 = todos)",
    Range        = {0, 5},
    Increment    = 1,
    CurrentValue = 0,
    Flag         = "SliderMinRarity",
    Callback     = function(v) _G.AutoSellMinRarity = v end,
})

-- ── MINÉRIOS ──────────────────────────────────────────
TabVendas:CreateDivider()
TabVendas:CreateSection("Minérios")

local minerioSelecionado = nil

local DropdownMinerio = TabVendas:CreateDropdown({
    Name            = "Selecionar Minério",
    Options         = getOresDisponiveis(),
    CurrentOption   = {""},
    MultipleOptions = false,
    Flag            = "DropdownMinerio",
    Callback = function(opcao)
        minerioSelecionado = extrairNome(opcao)
        Rayfield:Notify({ Title = "Minério", Content = minerioSelecionado, Duration = 2 })
    end,
})

TabVendas:CreateButton({
    Name = "💰 Vender Selecionado",
    Callback = function()
        venderMinerio(minerioSelecionado, function(ok, msg)
            Rayfield:Notify({ Title = ok and "✅ Vendido!" or "⚠ Atenção", Content = msg, Duration = 3 })
            if ok then
                task.wait(0.3)
                DropdownMinerio:Refresh(getOresDisponiveis(), true)
                minerioSelecionado = nil
            end
        end)
    end,
})

TabVendas:CreateButton({
    Name = "💸 Vender Todos os Minérios",
    Callback = function()
        venderTodosOres(function(n)
            Rayfield:Notify({
                Title   = "✅ Concluído",
                Content = n .. " tipo(s) de minério vendido(s)!",
                Duration = 3,
            })
            task.wait(0.3)
            DropdownMinerio:Refresh(getOresDisponiveis(), true)
            minerioSelecionado = nil
        end)
    end,
})

-- ── ARMAS ─────────────────────────────────────────────
TabVendas:CreateDivider()
TabVendas:CreateSection("Armas")

local uuidArma = nil
local mapaArmas

local listaArmas, _mapaArmas = getListaEquipamentos("Weapon")
mapaArmas = _mapaArmas

local DropdownArmas = TabVendas:CreateDropdown({
    Name            = "Selecionar Arma",
    Options         = #listaArmas > 0 and listaArmas or {"Sem armas guardadas"},
    CurrentOption   = {""},
    MultipleOptions = false,
    Flag            = "DropdownArmas",
    Callback = function(opcao)
        if type(opcao) == "table" then opcao = opcao[1] or "" end
        local entry = mapaArmas[opcao]
        uuidArma = entry and entry.uuid or nil
        Rayfield:Notify({ Title = "Arma", Content = opcao, Duration = 2 })
    end,
})

TabVendas:CreateButton({
    Name = "💰 Vender Arma Selecionada",
    Callback = function()
        venderEquipamento(uuidArma, function(ok, msg)
            Rayfield:Notify({ Title = ok and "✅ Vendido!" or "⚠ Atenção", Content = msg, Duration = 3 })
            if ok then
                uuidArma = nil
                task.wait(0.3)
                local nova, nm = getListaEquipamentos("Weapon")
                mapaArmas = nm
                DropdownArmas:Refresh(#nova > 0 and nova or {"Sem armas guardadas"}, true)
            end
        end)
    end,
})

TabVendas:CreateButton({
    Name = "💸 Vender Todas as Armas",
    Callback = function()
        venderTodosEquipamentos("Weapon", function(n)
            Rayfield:Notify({ Title = "✅ Concluído", Content = n .. " arma(s) vendida(s)!", Duration = 3 })
            uuidArma = nil
            task.wait(0.3)
            local nova, nm = getListaEquipamentos("Weapon")
            mapaArmas = nm
            DropdownArmas:Refresh(#nova > 0 and nova or {"Sem armas guardadas"}, true)
        end)
    end,
})

-- ── ARMADURAS ─────────────────────────────────────────
TabVendas:CreateDivider()
TabVendas:CreateSection("Armaduras")

local uuidArmadura = nil
local mapaArmaduras

local listaArmaduras, _mapaArmaduras = getListaEquipamentos("Armor")
mapaArmaduras = _mapaArmaduras

local DropdownArmaduras = TabVendas:CreateDropdown({
    Name            = "Selecionar Armadura",
    Options         = #listaArmaduras > 0 and listaArmaduras or {"Sem armaduras guardadas"},
    CurrentOption   = {""},
    MultipleOptions = false,
    Flag            = "DropdownArmaduras",
    Callback = function(opcao)
        if type(opcao) == "table" then opcao = opcao[1] or "" end
        local entry = mapaArmaduras[opcao]
        uuidArmadura = entry and entry.uuid or nil
        Rayfield:Notify({ Title = "Armadura", Content = opcao, Duration = 2 })
    end,
})

TabVendas:CreateButton({
    Name = "💰 Vender Armadura Selecionada",
    Callback = function()
        venderEquipamento(uuidArmadura, function(ok, msg)
            Rayfield:Notify({ Title = ok and "✅ Vendido!" or "⚠ Atenção", Content = msg, Duration = 3 })
            if ok then
                uuidArmadura = nil
                task.wait(0.3)
                local nova, nm = getListaEquipamentos("Armor")
                mapaArmaduras = nm
                DropdownArmaduras:Refresh(#nova > 0 and nova or {"Sem armaduras guardadas"}, true)
            end
        end)
    end,
})

TabVendas:CreateButton({
    Name = "💸 Vender Todas as Armaduras",
    Callback = function()
        venderTodosEquipamentos("Armor", function(n)
            Rayfield:Notify({ Title = "✅ Concluído", Content = n .. " armadura(s) vendida(s)!", Duration = 3 })
            uuidArmadura = nil
            task.wait(0.3)
            local nova, nm = getListaEquipamentos("Armor")
            mapaArmaduras = nm
            DropdownArmaduras:Refresh(#nova > 0 and nova or {"Sem armaduras guardadas"}, true)
        end)
    end,
})

-- ── ATUALIZAR LISTAS ──────────────────────────────────
TabVendas:CreateDivider()
TabVendas:CreateButton({
    Name = "🔄 Atualizar Todas as Listas",
    Callback = function()
        DropdownMinerio:Refresh(getOresDisponiveis(), true)

        local na, nma = getListaEquipamentos("Weapon")
        mapaArmas = nma
        DropdownArmas:Refresh(#na > 0 and na or {"Sem armas guardadas"}, true)

        local nb, nmb = getListaEquipamentos("Armor")
        mapaArmaduras = nmb
        DropdownArmaduras:Refresh(#nb > 0 and nb or {"Sem armaduras guardadas"}, true)

        minerioSelecionado = nil
        uuidArma           = nil
        uuidArmadura       = nil

        Rayfield:Notify({ Title = "🔄 Atualizado", Content = "Listas atualizadas!", Duration = 2 })
    end,
})

-- ══════════════════════════════════════════════════════
-- // TAB: STATS
-- ══════════════════════════════════════════════════════
local TabStats = Window:CreateTab("📊 Stats")

-- ── Perfil ────────────────────────────────────────────
TabStats:CreateSection("👤 Perfil")
local LabelLevel    = TabStats:CreateLabel("Level: ...")
local LabelXP       = TabStats:CreateLabel("XP: ...")
local LabelCurrency = TabStats:CreateLabel("Moedas: ...")

-- ── Cristais ──────────────────────────────────────────
TabStats:CreateSection("💎 Cristais")
local LabelShards = TabStats:CreateLabel("Shards: ...")
local LabelFlake  = TabStats:CreateLabel("Flake: ...")
local LabelPrism  = TabStats:CreateLabel("Prism: ...")

-- ── Minérios ──────────────────────────────────────────
TabStats:CreateSection("🪨 Minérios")
local LabelOres = TabStats:CreateLabel("...")

-- ── Atributos ─────────────────────────────────────────
TabStats:CreateSection("⚔ Atributos")
local LabelAtk    = TabStats:CreateLabel("ATK Bonus: ...")
local LabelHp     = TabStats:CreateLabel("HP Bonus: ...")
local LabelPontos = TabStats:CreateLabel("Pontos disponíveis: ...")

-- ── Equipado Agora ────────────────────────────────────
TabStats:CreateSection("🛡 Equipamento Atual")
local LabelEquip = TabStats:CreateLabel("Carregando...")

-- ── Sessão ────────────────────────────────────────────
TabStats:CreateSection("⏱ Sessão")
local LabelTempo    = TabStats:CreateLabel("Tempo: ...")
local LabelLvlGanho = TabStats:CreateLabel("Levels ganhos: ...")
local LabelXPGanho  = TabStats:CreateLabel("XP ganho: ...")
local LabelMoedas   = TabStats:CreateLabel("Moedas ganhas: ...")
local LabelRounds   = TabStats:CreateLabel("Rounds farmados: ...")
local LabelVendas   = TabStats:CreateLabel("Vendas realizadas: ...")
local LabelKillsT   = TabStats:CreateLabel("Kills totais: ...")

-- ── Métricas ──────────────────────────────────────────
TabStats:CreateSection("📈 Métricas em Tempo Real")
local LabelKPM       = TabStats:CreateLabel("Kills/min: ...")
local LabelXPM       = TabStats:CreateLabel("XP/min: ...")
local LabelXPH       = TabStats:CreateLabel("XP/hora: ...")
local LabelMoedasH   = TabStats:CreateLabel("Moedas/hora: ...")
local LabelTempoLvl  = TabStats:CreateLabel("Tempo p/ level: ...")
local LabelKillsLvl  = TabStats:CreateLabel("Kills p/ level: ...")

-- ── Daily ─────────────────────────────────────────────
TabStats:CreateSection("📅 Daily / Seven Daily")
local LabelDaily  = TabStats:CreateLabel("Daily Quest: ...")
local LabelSeven  = TabStats:CreateLabel("Seven Daily: ...")

-- ── Loop de Atualização ───────────────────────────────
task.spawn(function()
    while task.wait(2) do
        local s = getStatsSnapshot()
        if not s then continue end

        -- Perfil
        LabelLevel:Set("Level: " .. s.level .. "  |  XP: " .. s.xp)
        LabelXP:Set("Próx. Level: " .. s.xpFalta .. " XP  (" .. s.xpPct .. "%)")
        LabelCurrency:Set("💰 Moedas: " .. s.currency)

        -- Cristais
        LabelShards:Set("Crystal Shards: " .. s.shards)
        LabelFlake:Set("Crystal Flake: "   .. s.flake)
        LabelPrism:Set("Crystal Prism: "   .. s.prism)

        -- Minérios
        LabelOres:Set(s.totalOres > 0
            and ("Total: " .. s.totalOres .. "  —  " .. table.concat(s.oreLinhas, " | "))
            or "Sem minérios no bolso")

        -- Atributos
        LabelAtk:Set("ATK Bonus: "           .. s.atkBonus)
        LabelHp:Set("HP Bonus: "             .. s.hpBonus)
        LabelPontos:Set("⚡ Pontos livres: " .. s.pontosDisponiveis)

        -- Equipamento atual
        local equip = getEquipamentoAtual()
        if #equip > 0 then
            local linhas = {}
            for _, e in ipairs(equip) do
                table.insert(linhas, e.slot .. ": " .. e.id .. " | Ore: " .. e.maxOre .. " | Fator: " .. e.factor)
            end
            LabelEquip:Set(table.concat(linhas, "\n"))
        else
            LabelEquip:Set("Nenhum equipamento equipado")
        end

        -- Sessão
        LabelTempo:Set("⏱ Sessão: "         .. s.tempoSessao)
        LabelLvlGanho:Set("📈 Levels: +"    .. s.lvlGanho)
        LabelXPGanho:Set("✨ XP: +"         .. s.xpGanho)
        LabelMoedas:Set("💰 Moedas: +"      .. s.moedas)
        LabelRounds:Set("🏰 Rounds: "       .. s.roundsFarm)
        LabelVendas:Set("🛒 Vendas: "       .. (s.vendasOres + s.vendasItens))
        LabelKillsT:Set("💀 Kills: "        .. s.kills)

        -- Métricas
        LabelKPM:Set("⚔ Kills/min: "        .. s.kpm)
        LabelXPM:Set("✨ XP/min: "          .. s.xpm)
        LabelXPH:Set("🚀 XP/hora: "         .. s.xph)
        LabelMoedasH:Set("💰 Moedas/hora: " .. s.moedasHora)
        LabelTempoLvl:Set("⏳ Tempo p/ level: " .. s.tempoLvl)
        LabelKillsLvl:Set("🎯 Kills p/ level: " .. s.killsParaLevel)

        -- Daily Quest
        local dq = getDailyQuestStatus()
        LabelDaily:Set(
            "Completas: " .. dq.completas ..
            "  |  Pendentes: " .. dq.pendentes ..
            "  |  Recompensas: " .. dq.rewardsPending
        )

        -- Seven Daily
        local sd = getSevenDailyStatus()
        LabelSeven:Set(
            "Dia desbloqueado: " .. sd.unlockDay ..
            "  |  Disponíveis: " .. sd.totalDisponivel
        )
    end
end)
