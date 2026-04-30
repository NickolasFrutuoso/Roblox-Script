-- ══════════════════════════════════════════════════════════════════════
-- // AUTO DUNGEON — CORE (Rayfield-ready)
-- // GUI e JSON removidos. Conecte seus callbacks Rayfield às _G vars.
-- ══════════════════════════════════════════════════════════════════════

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace        = game:GetService("Workspace")

local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")
local RemoteAtaque = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PlayerActionRE")
local GameRoundRE  = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("GameRoundRE")

-- ══════════════════════════════════════════════════════════════════════
-- // VARIÁVEIS GLOBAIS
-- // Elo de comunicação entre o Core e os callbacks da UI Rayfield.
-- // Escreva nelas diretamente dentro dos callbacks de Toggle/Dropdown.
-- ══════════════════════════════════════════════════════════════════════

_G.LoopAtivo        = true   -- false encerra todos os loops permanentemente
_G.AutoDungeonBot   = false  -- Toggle "Farm" do Rayfield
_G.AutoReplay       = true   -- Toggle "Auto Replay" do Rayfield
_G.KillAura         = false  -- Toggle "Kill Aura" do Rayfield
_G.MapaSelecionado  = "X"    -- Dropdown "Mapa": "X" = Florest | "Y" = Snow
_G.SkillsAtivas     = {      -- Toggles individuais de skill do Rayfield
    Skill1 = true,
    Skill2 = true,
    SkillU = false,
}

-- Estado interno do bot (não expor na UI, apenas leitura informativa)
_G.RoundAtual       = 1
_G.PortaisUsados    = {}
_G.VictoryDetectado = false
_G.UltimoInimigo    = tick()
_G.AntiStuckAtivo   = false
_G.QuebrandoBau     = false

-- ══════════════════════════════════════════════════════════════════════
-- // UTILITÁRIOS
-- ══════════════════════════════════════════════════════════════════════

--- Registra mensagens no output do executor.
--- Substitua o corpo por Window:Log() do Rayfield se quiser exibir na UI.
local function log(msg)
    print("[AutoDungeon] " .. msg)
end

--- Teleporta o HumanoidRootPart para um CFrame alvo com offset vertical.
local function realizarTeleporte(alvoCFrame)
    local hrp = LocalPlayer.Character
        and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame  = alvoCFrame * CFrame.new(0, 3, 0)
        hrp.Velocity = Vector3.new(0, 0, 0)
    end
end

--- Retorna true se existir pelo menos um inimigo vivo na pasta EnemyNpc.
local function temInimigos()
    local pasta = Workspace:FindFirstChild("EnemyNpc")
    if not pasta then return false end
    for _, m in ipairs(pasta:GetChildren()) do
        if m:IsA("Model")
            and m:FindFirstChild("Humanoid")
            and m.Humanoid.Health > 0
        then
            return true
        end
    end
    return false
end

-- ══════════════════════════════════════════════════════════════════════
-- // COMBATE
-- ══════════════════════════════════════════════════════════════════════

--- Dispara as skills habilitadas em _G.SkillsAtivas via RemoteAtaque.
--- SkillU usa uma sequência especial de 4 chamadas com delays.
local function usarSkillsAtivas()
    task.spawn(function()
        for skillName, ativa in pairs(_G.SkillsAtivas) do
            if ativa then
                pcall(function()
                    if skillName == "SkillU" then
                        RemoteAtaque:FireServer("SkillAction", "SkillU", 1)
                        task.wait(0.08)
                        RemoteAtaque:FireServer("SkillAction", "SkillU", 2)
                        task.wait(0.08)
                        RemoteAtaque:FireServer("SkillAction", "SkillU", 3)
                        task.wait(0.08)
                        RemoteAtaque:FireServer("SkillAction", "SkillU")
                    else
                        RemoteAtaque:FireServer("SkillAction", skillName)
                        task.wait(0.08)
                        RemoteAtaque:FireServer("SkillAction", skillName, 1)
                    end
                end)
            end
        end
    end)
end

-- ══════════════════════════════════════════════════════════════════════
-- // BAÚS
-- ══════════════════════════════════════════════════════════════════════

--- Localiza todos os objetos "Chest%d+" no Workspace, teleporta até cada
--- um e envia ataques base até destruí-lo (máx 20 tentativas por baú).
--- Seta _G.QuebrandoBau durante a execução para pausar o loop principal.
local function quebrarBaus()
    local hrp = LocalPlayer.Character
        and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local bausEncontrados = {}
    for _, obj in ipairs(Workspace:GetChildren()) do
        if string.match(obj.Name, "^Chest%d+$") then
            table.insert(bausEncontrados, obj)
        end
    end
    if #bausEncontrados == 0 then return end

    _G.QuebrandoBau = true
    log("📦 " .. #bausEncontrados .. " baú(s) encontrado(s)!")

    for _, bau in ipairs(bausEncontrados) do
        if not bau.Parent then continue end

        local posBau
        if bau:IsA("Model") and bau.PrimaryPart then
            posBau = bau.PrimaryPart.CFrame
        elseif bau:IsA("Model") then
            for _, p in ipairs(bau:GetDescendants()) do
                if p:IsA("BasePart") then posBau = p.CFrame break end
            end
        elseif bau:IsA("BasePart") then
            posBau = bau.CFrame
        end
        if not posBau then continue end

        hrp.CFrame  = posBau * CFrame.new(0, 3, 0)
        hrp.Velocity = Vector3.new(0, 0, 0)
        task.wait(0.8)

        local tentativas = 0
        while bau.Parent and tentativas < 20 do
            tentativas += 1
            hrp.CFrame  = posBau * CFrame.new(0, 3, 0)
            hrp.Velocity = Vector3.new(0, 0, 0)
            pcall(function()
                RemoteAtaque:FireServer("SkillAction", "BaseAttack", 3)
                RemoteAtaque:FireServer("SkillAction", "BaseAttack", 1)
                RemoteAtaque:FireServer("SkillAction", "BaseAttack", 2)
                RemoteAtaque:FireServer("SkillAction", "BaseAttack", 4)
            end)
            task.wait(0.25)
        end

        log(bau.Parent
            and ("⚠ Baú '" .. bau.Name .. "' resistiu.")
            or  ("✅ Baú '" .. bau.Name .. "' destruído!"))
        task.wait(0.3)
    end

    _G.QuebrandoBau = false
    task.wait(0.4)
end

-- ══════════════════════════════════════════════════════════════════════
-- // PORTAIS
-- ══════════════════════════════════════════════════════════════════════

--- Retorna a lista de nomes de portais válidos para o mapa atual.
--- Mapa "X" (Florest) → {"Portal"}
--- Mapa "Y" (Snow)    → {"PortalD", "Portal"}
local function getNomesPortal()
    if _G.MapaSelecionado == "Y" then
        return {"PortalD", "Portal"}
    else
        return {"Portal"}
    end
end

--- Busca na pasta RoundDoor o portal mais próximo ainda não utilizado.
--- Retorna o objeto do portal ou nil caso nenhum seja encontrado.
local function encontrarPortalProximo()
    local hrp = LocalPlayer.Character
        and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local portalFolder = Workspace:FindFirstChild("RoundDoor")
    if not portalFolder then
        log("❌ 'RoundDoor' não encontrada!")
        return nil
    end

    local nomesAlvo          = getNomesPortal()
    local melhor, menorDist  = nil, math.huge

    for _, obj in ipairs(portalFolder:GetChildren()) do
        local nomeValido = false
        for _, nome in ipairs(nomesAlvo) do
            if obj.Name == nome then nomeValido = true break end
        end

        if nomeValido and not _G.PortaisUsados[obj] then
            local parte = obj:FindFirstChild("Root")
                       or obj:FindFirstChild("door")
                       or obj:FindFirstChildWhichIsA("BasePart")
            if parte then
                local dist = (hrp.Position - parte.Position).Magnitude
                if dist < menorDist then
                    menorDist = dist
                    melhor    = obj
                end
            end
        end
    end

    if melhor then
        log(string.format("🌀 %s encontrado (%.1fst)", melhor.Name, menorDist))
    else
        log("❌ Nenhum portal disponível!")
    end
    return melhor
end

--- Teleporta o HRP até o portal e usa firetouchinterest em todas as suas
--- BaseParts para simular a entrada. Marca o portal em _G.PortaisUsados.
local function simularToqueNoPortal(portal)
    local hrp = LocalPlayer.Character
        and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local parte = portal:FindFirstChild("Root")
               or portal:FindFirstChild("door")
               or portal:FindFirstChildWhichIsA("BasePart")

    if parte then
        hrp.CFrame  = parte.CFrame * CFrame.new(0, 3, 0)
        hrp.Velocity = Vector3.new(0, 0, 0)
    end
    task.wait(0.2)

    for _, p in ipairs(portal:GetDescendants()) do
        if p:IsA("BasePart") then
            pcall(function()
                firetouchinterest(hrp, p, 0)
                task.wait(0.05)
                firetouchinterest(hrp, p, 1)
            end)
        end
    end

    _G.PortaisUsados[portal] = true
    log("✅ Portal '" .. portal.Name .. "' usado.")
end

-- ══════════════════════════════════════════════════════════════════════
-- // ANTI-STUCK
-- ══════════════════════════════════════════════════════════════════════

--- Rotina de recuperação disparada quando nenhum inimigo é detectado por
--- ≥5 segundos. Tenta avançar para o próximo round via PlayerRespawn ou,
--- se ele não existir, usa um portal disponível. Executa até 20 ciclos.
--- Protegida por _G.AntiStuckAtivo para não rodar em paralelo.
local function antiStuck()
    if _G.AntiStuckAtivo then return end
    _G.AntiStuckAtivo = true
    log("🚨 Anti-stuck! Procurando round...")

    local playerRespawn = Workspace:FindFirstChild("PlayerRespawn")

    for _ = 1, 20 do
        if not _G.LoopAtivo or not _G.AutoDungeonBot then break end

        local proximoRound = _G.RoundAtual + 1
        local hrp = LocalPlayer.Character
            and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then task.wait(1) continue end

        local partePart = playerRespawn
            and playerRespawn:FindFirstChild("Round" .. proximoRound)

        if partePart and partePart:IsA("BasePart") then
            log("🔍 Testando Round " .. proximoRound .. "...")
            hrp.CFrame  = partePart.CFrame * CFrame.new(0, 3, 0)
            hrp.Velocity = Vector3.new(0, 0, 0)
            _G.RoundAtual = proximoRound
            task.wait(1.5)

            if temInimigos() then
                log("✅ Inimigos no Round " .. proximoRound .. "!")
                _G.UltimoInimigo  = tick()
                _G.AntiStuckAtivo = false
                return
            end
        else
            log("🌀 Sem rounds. Buscando portal...")
            quebrarBaus()
            local portal = encontrarPortalProximo()
            if portal then
                simularToqueNoPortal(portal)
                task.wait(2)
                if temInimigos() then
                    log("✅ Inimigos após portal!")
                    _G.UltimoInimigo  = tick()
                    _G.AntiStuckAtivo = false
                    return
                end
            else
                log("❌ Sem rounds e sem portal disponível!")
                break
            end
        end
    end

    log("⚠ Anti-stuck encerrado.")
    _G.AntiStuckAtivo = false
end

-- ══════════════════════════════════════════════════════════════════════
-- // PROGRESSÃO DE DUNGEON
-- ══════════════════════════════════════════════════════════════════════

--- Orquestrador de avanço de round: quebra baús → tenta teleportar para
--- Round+1 via PlayerRespawn → se ausente, usa portal → atualiza
--- _G.RoundAtual. Disparada automaticamente pelo gatilho RoundCompleted.
local function avancarDungeon()
    _G.QuebrandoBau = true
    quebrarBaus()
    _G.QuebrandoBau = false

    local playerRespawn  = Workspace:FindFirstChild("PlayerRespawn")
    local roundEncontrado = false

    for nextRound = _G.RoundAtual + 1, _G.RoundAtual + 10 do
        local proxParte = playerRespawn
            and playerRespawn:FindFirstChild("Round" .. nextRound)

        if proxParte and proxParte:IsA("BasePart") then
            log("📍 Round " .. _G.RoundAtual .. " → " .. nextRound)
            realizarTeleporte(proxParte.CFrame)
            _G.RoundAtual  = nextRound
            roundEncontrado = true
            break
        else
            log("🌀 Round" .. nextRound .. " ausente. Buscando portal...")
            local portal = encontrarPortalProximo()
            if portal then
                simularToqueNoPortal(portal)
                task.wait(1.5)
                local parteApos = playerRespawn
                    and playerRespawn:FindFirstChild("Round" .. nextRound)
                if parteApos and parteApos:IsA("BasePart") then
                    log("📍 Round " .. _G.RoundAtual .. " → " .. nextRound .. " (pós-portal)")
                    realizarTeleporte(parteApos.CFrame)
                else
                    log("📍 Round " .. _G.RoundAtual .. " → " .. nextRound .. " (sala adjacente)")
                end
                _G.RoundAtual  = nextRound
                roundEncontrado = true
                break
            else
                log("❌ Sem portal para Round" .. nextRound .. "!")
                break
            end
        end
    end

    if not roundEncontrado then
        _G.RoundAtual += 1
        log("⚠ Round não encontrado, incrementando para " .. _G.RoundAtual)
    end
end

-- ══════════════════════════════════════════════════════════════════════
-- // AUTO REPLAY
-- ══════════════════════════════════════════════════════════════════════

--- Vota replay ao detectar fim da dungeon via Victory GUI.
--- Reseta _G.RoundAtual e _G.PortaisUsados para o próximo ciclo.
--- Protegida por _G.VictoryDetectado para não votar em duplicidade.
local function executarReplay()
    if not _G.AutoDungeonBot or not _G.AutoReplay then return end
    if _G.VictoryDetectado then return end
    _G.VictoryDetectado = true

    log("🏆 Dungeon concluída! Votando replay...")
    task.wait(1.5)
    pcall(function() GameRoundRE:FireServer("VotePlayAgain") end)

    _G.RoundAtual    = 1
    _G.PortaisUsados = {}
    _G.UltimoInimigo = tick()

    log("🔁 Voto enviado!")
    task.delay(5, function() _G.VictoryDetectado = false end)
end

-- ══════════════════════════════════════════════════════════════════════
-- // GATILHO: ROUND COMPLETED (HUD)
-- // Monitora a visibilidade do elemento RoundCompleted no BattleHUD.
-- // Quando fica visível e o bot está ativo → chama avancarDungeon().
-- ══════════════════════════════════════════════════════════════════════
task.spawn(function()
    local ok, hud = pcall(function()
        return PlayerGui
            :WaitForChild("BattleHUD")
            :WaitForChild("InformFrame")
    end)
    if not ok then log("❌ BattleHUD não encontrado") return end

    local msg = hud:WaitForChild("RoundCompleted")
    msg:GetPropertyChangedSignal("Visible"):Connect(function()
        if msg.Visible and _G.AutoDungeonBot then
            log("✅ Round completo! Avançando...")
            _G.UltimoInimigo = tick()
            avancarDungeon()
            task.wait(2)
            msg.Visible = false
        end
    end)
end)

-- ══════════════════════════════════════════════════════════════════════
-- // DETECÇÃO VICTORY — M1 (sinal de propriedade)
-- // Método primário: conecta ao sinal Visible do Victory GUI.
-- ══════════════════════════════════════════════════════════════════════
task.spawn(function()
    local ok, victoryGui = pcall(function()
        return PlayerGui
            :WaitForChild("ResultGui", 30)
            :WaitForChild("ScreenSettlement", 30)
            :WaitForChild("Victory", 30)
    end)
    if not ok or not victoryGui then
        log("⚠ Victory GUI não encontrado (M1)")
        return
    end
    log("✅ Victory GUI monitorado!")
    victoryGui:GetPropertyChangedSignal("Visible"):Connect(function()
        if victoryGui.Visible then executarReplay() end
    end)
end)

-- ══════════════════════════════════════════════════════════════════════
-- // DETECÇÃO VICTORY — M2 (polling backup)
-- // Método de fallback via polling a cada 0.5s caso o M1 falhe.
-- ══════════════════════════════════════════════════════════════════════
task.spawn(function()
    while task.wait(0.5) do
        if not _G.LoopAtivo then break end
        if not _G.AutoDungeonBot or not _G.AutoReplay then continue end
        pcall(function()
            local v = PlayerGui:FindFirstChild("ResultGui")
                and PlayerGui.ResultGui:FindFirstChild("ScreenSettlement")
                and PlayerGui.ResultGui.ScreenSettlement:FindFirstChild("Victory")
            if v and v.Visible then executarReplay() end
        end)
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- // LOOP PRINCIPAL
-- // Tick de 0.1s. A cada ciclo:
-- //   1. Se _G.QuebrandoBau → pula (baús têm prioridade)
-- //   2. Busca inimigo vivo na pasta EnemyNpc
-- //   3. Se encontrou → teleporta em cima, dispara BaseAttack + skills
-- //   4. Se não encontrou há ≥5s e Farm ativo → chama antiStuck()
-- ══════════════════════════════════════════════════════════════════════
task.spawn(function()
    while task.wait(0.1) do
        if not _G.LoopAtivo then break end
        if _G.QuebrandoBau then continue end

        local farmAtivo = _G.AutoDungeonBot
        local auraAtiva = _G.KillAura
        if not farmAtivo and not auraAtiva then continue end

        local pasta = Workspace:FindFirstChild("EnemyNpc")
        local hrp   = LocalPlayer.Character
            and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local inimigo = nil
        if pasta then
            for _, m in ipairs(pasta:GetChildren()) do
                if m:IsA("Model")
                    and m:FindFirstChild("Humanoid")
                    and m.Humanoid.Health > 0
                    and m:FindFirstChild("HumanoidRootPart")
                then
                    inimigo = m
                    break
                end
            end
        end

        if inimigo then
            _G.UltimoInimigo = tick()
            hrp.CFrame       = inimigo.HumanoidRootPart.CFrame * CFrame.new(0, 7, 0)
            hrp.Velocity      = Vector3.new(0, 0, 0)
            pcall(function()
                RemoteAtaque:FireServer("SkillAction", "BaseAttack", 3)
                RemoteAtaque:FireServer("SkillAction", "BaseAttack", 1)
                RemoteAtaque:FireServer("SkillAction", "BaseAttack", 2)
                RemoteAtaque:FireServer("SkillAction", "BaseAttack", 4)
            end)
            usarSkillsAtivas()
        else
            if farmAtivo and not _G.AntiStuckAtivo then
                if tick() - _G.UltimoInimigo >= 5 then
                    task.spawn(antiStuck)
                end
            end
        end
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- // INIT
-- ══════════════════════════════════════════════════════════════════════
log("🎯 Auto Dungeon Core carregado! Aguardando Rayfield...")
log("💡 Mapa atual: " .. _G.MapaSelecionado)