-- ╔══════════════════════════════════════════════════════════════╗
-- ║                 Iron Soul Hub  —  Main.lua                  ║
-- ║   Apenas UI: janela, abas, toggles, dropdowns e botões.     ║
-- ║   Toda a lógica vive no HubLogic.lua (IronSoulLib).         ║
-- ╚══════════════════════════════════════════════════════════════╝

-- ══════════════════════════════════════════════════════
-- // IMPORTS
-- ══════════════════════════════════════════════════════

-- Script de bot/mecânicas externas (mantido igual ao original)
local script_iron = loadstring(game:HttpGet(
    'https://raw.githubusercontent.com/NickolasFrutuoso/Roblox-Script/refs/heads/main/Script_Iron.lua'
))()

-- Lógica centralizada
-- ATENÇÃO: substitua a URL abaixo pela URL raw do seu HubLogic.lua hospedado
local IronSoulLib = loadstring(game:HttpGet(
    'https://raw.githubusercontent.com/NickolasFrutuoso/Roblox-Script/refs/heads/main/Logica.lua'
))()

-- Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Atalhos locais para as funções da lib
local getOresDisponiveis   = IronSoulLib.getOresDisponiveis
local venderMinerio        = IronSoulLib.venderMinerio
local getListaEquipamentos = IronSoulLib.getListaEquipamentos
local venderEquipamento    = IronSoulLib.venderEquipamento
local getStatsSnapshot     = IronSoulLib.getStatsSnapshot
local extrairNome          = IronSoulLib.extrairNome

-- ══════════════════════════════════════════════════════
-- // UI — WINDOW
-- ══════════════════════════════════════════════════════
local Window = Rayfield:CreateWindow({
    Name             = "Iron Soul",
    LoadingTitle     = "Iron Soul: Dungeon [BETA]",
    LoadingSubtitle  = "by Noliar",
    ShowText         = "1.0",
    Theme            = "Default",
    ToggleUIKeybind  = "L",

    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = false,

    ConfigurationSaving = {
        Enabled    = true,
        FolderName = nil,
        FileName   = "Iron Soul",
    },

    Discord = {
        Enabled      = false,
        Invite       = "noinvitelink",
        RememberJoins = true,
    },

    KeySystem = false,
    KeySettings = {
        Title = "Noliar Hub",
        Subtitle = "Sistema de Chave",
        Note = "Clique no botão abaixo para pegar a chave!",
        FileName = "NoliarKey",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"Hello"}
    }
})

-- ══════════════════════════════════════════════════════
-- // UI — TAB: FARME
-- ══════════════════════════════════════════════════════
local TabFarme = Window:CreateTab("Farm")
TabFarme:CreateSection("Last Script Update - 29/04")

TabFarme:CreateToggle({
    Name         = "Modo Farm",
    CurrentValue = false,
    Flag         = "ToggleFarm",
    Callback = function(value)
        _G.AutoDungeonBot = value
    end,
})

TabFarme:CreateToggle({
    Name         = "Auto-Rerun",
    CurrentValue = false,
    Flag         = "ToggleRerun",
    Callback = function(value)
        _G.AutoReplay = value
        print("Auto-Rerun foi alterado para:", value)
    end,
})

TabFarme:CreateDivider()

TabFarme:CreateDropdown({
    Name           = "Selecionar Mapa",
    Options        = {"Floresta Sem Estrela", "Vale Congelante"},
    CurrentOption  = {"Floresta Sem Estrela"},
    MultipleOptions = false,
    Flag           = "DropdownMapa",
    Callback = function(opcoes)
        _G.MapaSelecionado = (opcoes[1] == "Floresta Sem Estrela") and "X" or "Y"
        _G.PortaisUsados   = {}  -- limpa portais ao trocar de mapa
        print("Mapa alterado para:", _G.MapaSelecionado)
    end,
})

-- ══════════════════════════════════════════════════════
-- // UI — TAB: HABILIDADES
-- ══════════════════════════════════════════════════════
local TabSkills = Window:CreateTab("Habilidades")

TabSkills:CreateSection("Auto Skill")
TabSkills:CreateToggle({
    Name         = "[Q] Skill1",
    CurrentValue = false,
    Flag         = "Skill1",
    Callback = function(value)
        _G.SkillsAtivas.Skill1 = value
        print("Skill 1 alterada para:", value)
    end,
})

TabSkills:CreateToggle({
    Name         = "[E] Skill2",
    CurrentValue = false,
    Flag         = "Skill2",
    Callback = function(value)
        _G.SkillsAtivas.Skill2 = value
        print("Skill 2 alterada para:", value)
    end,
})

TabSkills:CreateToggle({
    Name         = "[R] SkillU",
    CurrentValue = false,
    Flag         = "SkillU",
    Callback = function(value)
        _G.SkillsAtivas.SkillU = value
        print("Skill U alterada para:", value)
    end,
})

-- ══════════════════════════════════════════════════════
-- // UI — TAB: VENDAS (Minérios)
-- ══════════════════════════════════════════════════════
local TabVendas = Window:CreateTab("Vendas")
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
        Rayfield:Notify({
            Title   = "Minério Selecionado",
            Content = minerioSelecionado,
            Duration = 2,
        })
    end,
})

TabVendas:CreateButton({
    Name = "Vender Minério Selecionado",
    Callback = function()
        venderMinerio(minerioSelecionado, function(sucesso, msg)
            if sucesso then
                Rayfield:Notify({ Title = "✅ Vendido!",  Content = msg, Duration = 3 })
                task.wait(0.5)
                DropdownMinerio:Refresh(getOresDisponiveis(), true)
                minerioSelecionado = nil
            else
                Rayfield:Notify({ Title = "⚠ Atenção",  Content = msg, Duration = 3 })
            end
        end)
    end,
})

-- ── Equipamentos ──────────────────────────────────────
TabVendas:CreateSection("Armas")

local uuidSelecionadoArma     = nil
local uuidSelecionadoArmadura = nil
local mapaArmas, mapaArmaduras

-- Armas
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
        uuidSelecionadoArma = mapaArmas[opcao]
        Rayfield:Notify({ Title = "Arma Selecionada", Content = opcao, Duration = 2 })
    end,
})

TabVendas:CreateButton({
    Name = "Vender Arma Selecionada",
    Callback = function()
        venderEquipamento(uuidSelecionadoArma, function(sucesso, msg)
            if sucesso then
                Rayfield:Notify({ Title = "✅ Vendido!", Content = "Arma vendida com sucesso!", Duration = 3 })
                uuidSelecionadoArma = nil
                task.wait(0.5)
                local nova, novoMapa = getListaEquipamentos("Weapon")
                mapaArmas = novoMapa
                DropdownArmas:Refresh(#nova > 0 and nova or {"Sem armas guardadas"}, true)
            else
                Rayfield:Notify({ Title = "⚠ Atenção", Content = msg, Duration = 2 })
            end
        end)
    end,
})


TabVendas:CreateSection("Armaduras")
-- Armaduras
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
        uuidSelecionadoArmadura = mapaArmaduras[opcao]
        Rayfield:Notify({ Title = "Armadura Selecionada", Content = opcao, Duration = 2 })
    end,
})

TabVendas:CreateButton({
    Name = "Vender Armadura Selecionada",
    Callback = function()
        venderEquipamento(uuidSelecionadoArmadura, function(sucesso, msg)
            if sucesso then
                Rayfield:Notify({ Title = "✅ Vendido!", Content = "Armadura vendida com sucesso!", Duration = 3 })
                uuidSelecionadoArmadura = nil
                task.wait(0.5)
                local nova, novoMapa = getListaEquipamentos("Armor")
                mapaArmaduras = novoMapa
                DropdownArmaduras:Refresh(#nova > 0 and nova or {"Sem armaduras guardadas"}, true)
            else
                Rayfield:Notify({ Title = "⚠ Atenção", Content = msg, Duration = 2 })
            end
        end)
    end,
})

-- ── Atualizar tudo de uma vez ─────────────────────────
TabVendas:CreateButton({
    Name = "Atualizar Todas as Listas",
    Callback = function()
        -- Minérios
        local novaLista = getOresDisponiveis()
        DropdownMinerio:Refresh(getOresDisponiveis(), true)
        minerioSelecionado = nil

        -- Armas
        local novaArmas, novoMapaArmas = getListaEquipamentos("Weapon")
        mapaArmas = novoMapaArmas
        DropdownArmas:Refresh(#novaArmas > 0 and novaArmas or {"Sem armas guardadas"}, true)

        -- Armaduras
        local novaArmaduras, novoMapaArmaduras = getListaEquipamentos("Armor")
        mapaArmaduras = novoMapaArmaduras
        DropdownArmaduras:Refresh(#novaArmaduras > 0 and novaArmaduras or {"Sem armaduras guardadas"}, true)

        uuidSelecionadoArma     = nil
        uuidSelecionadoArmadura = nil

        Rayfield:Notify({ Title = "🔄 Atualizado", Content = "Todas as listas atualizadas!", Duration = 2 })
    end,
})

-- ══════════════════════════════════════════════════════
-- // UI — TAB: STATS
-- ══════════════════════════════════════════════════════
local TabStats = Window:CreateTab("Stats")

-- ── Perfil ────────────────────────────────────────────
TabStats:CreateSection("Perfil")
local LabelLevel    = TabStats:CreateLabel("Level: carregando...")
local LabelXP       = TabStats:CreateLabel("XP: carregando...")
local LabelCurrency = TabStats:CreateLabel("Currency: carregando...")

-- ── Minérios ──────────────────────────────────────────
TabStats:CreateSection("Minérios Total")
local LabelOres = TabStats:CreateLabel("Carregando...")

-- ── Atributos ─────────────────────────────────────────
TabStats:CreateSection("Atributos")
local LabelAtk    = TabStats:CreateLabel("ATK Bonus: carregando...")
local LabelHp     = TabStats:CreateLabel("HP Bonus: carregando...")
local LabelPontos = TabStats:CreateLabel("Pontos disponíveis: carregando...")

-- ── Sessão ────────────────────────────────────────────
TabStats:CreateSection("Sessão Atual")
local LabelTempo   = TabStats:CreateLabel("Tempo de sessão: 0s")
local LabelLevels  = TabStats:CreateLabel("Levels ganhos: 0")
local LabelXPTotal = TabStats:CreateLabel("XP ganho na sessão: 0")

-- ── Métricas em Tempo Real ────────────────────────────
TabStats:CreateSection("Métricas em Tempo Real")
local LabelXPM      = TabStats:CreateLabel("XP/min: aguardando...")
local LabelXPH      = TabStats:CreateLabel("XP/hora estimado: aguardando...")
local LabelTempoLvl = TabStats:CreateLabel("Tempo p/ próx. level: aguardando...")

-- ══════════════════════════════════════════════════════
-- // LOOP DE ATUALIZAÇÃO DA UI — Stats
-- Chama IronSoulLib.getStatsSnapshot() e aplica nas Labels.
-- ══════════════════════════════════════════════════════
task.spawn(function()
    while task.wait(2) do
        local s = getStatsSnapshot()
        if not s then continue end

        -- Perfil
        LabelLevel:Set("Level: " .. s.level .. "  |  XP: " .. s.xp)
        LabelXP:Set("Próx. Level: " .. s.xpFalta .. " XP faltando  (" .. s.xpPct .. "%)")
        LabelCurrency:Set("Currency: " .. s.currency)

        -- Minérios
        LabelOres:Set(s.oreStr)

        -- Atributos
        LabelAtk:Set("ATK Bonus: "              .. s.atkBonus)
        LabelHp:Set("HP Bonus: "                .. s.hpBonus)
        LabelPontos:Set("Pontos disponíveis: " .. s.pontosDisponiveis)

        -- Sessão
        LabelTempo:Set("Sessão: "     .. s.tempoSessao)
        LabelLevels:Set("Levels ganhos: " .. s.lvlGanho)
        LabelXPTotal:Set("XP ganho: " .. s.xpGanho)

        -- Métricas
        LabelXPM:Set("XP/min: "    .. s.xpm)
        LabelXPH:Set("XP/hora: "   .. s.xph)
        LabelTempoLvl:Set("Tempo p/ level: " .. s.tempoLvl)
    end
end)
