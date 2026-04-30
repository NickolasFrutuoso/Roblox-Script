-- Farm-HUB.lua

-- ══════════════════════════════════════════════════════
-- // SERVIÇOS
-- ══════════════════════════════════════════════════════
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS         = game:GetService("ReplicatedStorage")
local Workspace  = game:GetService("Workspace")

local lp        = Players.LocalPlayer
local PlayerGui = lp:WaitForChild("PlayerGui")

local RemoteAtaque = RS:WaitForChild("Remotes"):WaitForChild("PlayerActionRE")
local GameRoundRE  = RS:WaitForChild("Remotes"):WaitForChild("GameRoundRE")

-- ══════════════════════════════════════════════════════
-- // VARIÁVEIS GLOBAIS
-- // Todas expostas para o Main.lua (Rayfield) controlar
-- ══════════════════════════════════════════════════════

-- Controle geral
_G.LoopAtivo        = true   -- false encerra todos os loops permanentemente

-- Kill Aura - Rotate


-- Farm
_G.AutoDungeonBot   = false  -- Toggle "Modo Farm"
_G.AutoReplay       = false  -- Toggle "Auto-Rerun"

-- Skills
_G.SkillsAtivas = _G.SkillsAtivas or {
    Skill1 = false,
    Skill2 = false,
    SkillU = false,
}

-- Kill Aura
_G.KillAura             = _G.KillAura          ~= nil and _G.KillAura          or false
_G.KillAura_Mode        = _G.KillAura_Mode     or "fly"       -- "tp" | "fly"
_G.KillAura_FlySpeed    = _G.KillAura_FlySpeed or 150
_G.KillAura_APS         = _G.KillAura_APS      or 30          -- 1-30 ataques/s
_G.KillAura_Priority    = _G.KillAura_Priority or "lowestHP"  -- "closest" | "lowestHP" | "boss"
_G.KillAura_OffsetY     = _G.KillAura_OffsetY  or 4
_G.KillAura_Noclip      = _G.KillAura_Noclip   ~= nil and _G.KillAura_Noclip or true
_G.KillAura_Orbit       = _G.KillAura_Orbit or false  -- true = orbita | false = fica parado em cima
_G.KillAura_OrbitRadius = _G.KillAura_OrbitRadius or 6      -- distância do centro do mob (studs)
_G.KillAura_OrbitSpeed  = _G.KillAura_OrbitSpeed or 2      -- velocidade da órbita (radianos/s)

-- Estado interno (leitura informativa para a UI)
_G.RoundAtual       = 1
_G.PortaisUsados    = {}
_G.VictoryDetectado = false
_G.UltimoInimigo    = tick()
_G.AntiStuckAtivo   = false
_G.QuebrandoBau     = false

_G.BotOcupado = false  -- adicione junto das outras _G no topo do script

-- ══════════════════════════════════════════════════════
-- // KILL AURA — Estado interno
-- ══════════════════════════════════════════════════════
local alvoAtual      = nil
local posConn        = nil
local atkConn        = nil
local noclipConn     = nil
local waveConn       = nil
local killConn       = nil
local bodyPos        = nil
local bodyGyro       = nil
local kaEstadoAnterior = false
local orbitAngulo = 0  -- ângulo atual da órbita em radianos

-- Sessão Kill Aura (métricas públicas)
local KASessao = {
    kills       = 0,
    killsBuffer = {},
}
_G.KillAura_Sessao = KASessao

-- ══════════════════════════════════════════════════════
-- // UTILITÁRIOS GERAIS
-- ══════════════════════════════════════════════════════

local function getPasta()
    return Workspace:FindFirstChild("EnemyNpc")
end

local function getHRP()
    local char = lp.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local char = lp.Character
    return char and char:FindFirstChild("Humanoid")
end

local function realizarTeleporte(alvoCFrame)
    local hrp = getHRP()
    if not hrp then return end

    _G.BotOcupado = true
    if bodyPos then bodyPos.MaxForce = Vector3.new(0,0,0) end

    hrp.CFrame   = alvoCFrame * CFrame.new(0, 3, 0)
    hrp.Velocity = Vector3.new(0, 0, 0)

    task.wait(0.3) -- dá tempo do servidor processar

    if bodyPos then bodyPos.MaxForce = Vector3.new(1e5, 1e5, 1e5) end
    _G.BotOcupado = false
end


local function temInimigos()
    local pasta = getPasta()
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

-- ══════════════════════════════════════════════════════
-- // KILL AURA — Seleção de alvo
-- ══════════════════════════════════════════════════════

local function getAlvo(hrp)
    local pasta = getPasta()
    if not pasta then return nil end

    local filhos = pasta:GetChildren()
    if #filhos == 0 then return nil end

    local melhor, melhorVal = nil, math.huge

    for _, m in ipairs(filhos) do
        local hum  = m:FindFirstChild("Humanoid")
        local mHrp = m:FindFirstChild("HumanoidRootPart")
        if not hum or not mHrp or hum.Health <= 0 then continue end

        local prioridade = _G.KillAura_Priority

        if prioridade == "closest" then
            local dist = (hrp.Position - mHrp.Position).Magnitude
            if dist < melhorVal then
                melhorVal = dist
                melhor    = m
            end
        elseif prioridade == "lowestHP" then
            if hum.Health < melhorVal then
                melhorVal = hum.Health
                melhor    = m
            end
        elseif prioridade == "boss" then
            -- Boss primeiro: prioriza modelos com "Boss" no nome
            local ehBoss = m.Name:lower():find("boss") ~= nil
            local dist   = (hrp.Position - mHrp.Position).Magnitude
            local peso   = ehBoss and 0 or 1e6
            if (peso + dist) < melhorVal then
                melhorVal = peso + dist
                melhor    = m
            end
        end
    end

    return melhor
end

-- ══════════════════════════════════════════════════════
-- // KILL AURA — Noclip
-- ══════════════════════════════════════════════════════

local function setNoclip(enabled)
    if noclipConn then
        noclipConn:Disconnect()
        noclipConn = nil
    end
    if not enabled then return end

    noclipConn = RunService.Stepped:Connect(function()
        local char = lp.Character
        if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = false
            end
        end
    end)
end

-- ══════════════════════════════════════════════════════
-- // KILL AURA — Body Movers (modo fly)
-- ══════════════════════════════════════════════════════

local function criarBodyMovers(hrp)
    if hrp:FindFirstChild("KA_BodyPos")  then hrp.KA_BodyPos:Destroy()  end
    if hrp:FindFirstChild("KA_BodyGyro") then hrp.KA_BodyGyro:Destroy() end

    bodyPos          = Instance.new("BodyPosition")
    bodyPos.Name     = "KA_BodyPos"
    bodyPos.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bodyPos.D        = 500
    bodyPos.P        = _G.KillAura_FlySpeed * 100
    bodyPos.Position = hrp.Position
    bodyPos.Parent   = hrp

    bodyGyro           = Instance.new("BodyGyro")
    bodyGyro.Name      = "KA_BodyGyro"
    bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    bodyGyro.D         = 100
    bodyGyro.P         = 1e4
    bodyGyro.CFrame    = hrp.CFrame
    bodyGyro.Parent    = hrp
end

local function removerBodyMovers()
    local hrp = getHRP()
    if hrp then
        if hrp:FindFirstChild("KA_BodyPos")  then hrp.KA_BodyPos:Destroy()  end
        if hrp:FindFirstChild("KA_BodyGyro") then hrp.KA_BodyGyro:Destroy() end
    end
    bodyPos  = nil
    bodyGyro = nil
end

-- ══════════════════════════════════════════════════════
-- // KILL AURA — Movimento
-- ══════════════════════════════════════════════════════

local function moverTP(hrp, destino)
    hrp.CFrame   = CFrame.new(destino + Vector3.new(0, _G.KillAura_OffsetY, 0))
    hrp.Velocity = Vector3.new(0, 0, 0)
end

local function moverFly(destino)
    if not bodyPos or not bodyGyro then return end
    bodyPos.P        = _G.KillAura_FlySpeed * 100
    bodyPos.Position = destino + Vector3.new(0, _G.KillAura_OffsetY, 0)
end

-- ══════════════════════════════════════════════════════
-- // KILL AURA — Ataque
-- ══════════════════════════════════════════════════════

local attackSeq = {1, 2, 3, 4}
local seqIdx    = 1

local function dispararAtaque()
    local seq = attackSeq[seqIdx]
    seqIdx    = (seqIdx % #attackSeq) + 1
    pcall(function()
        RemoteAtaque:FireServer("SkillAction", "BaseAttack", seq)
    end)
end

-- ══════════════════════════════════════════════════════
-- // SKILLS AUTOMÁTICAS
-- ══════════════════════════════════════════════════════

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

-- ══════════════════════════════════════════════════════
-- // KILL AURA — Loop de posição
-- ══════════════════════════════════════════════════════

local function iniciarLoopPosicao()
    if posConn then posConn:Disconnect() posConn = nil end

    local ultimoTick = tick()

    posConn = RunService.RenderStepped:Connect(function()
        if not _G.KillAura then return end
        if _G.BotOcupado   then return end

        local hrp = getHRP()
        local hum = getHum()
        if not hrp or not hum or hum.Health <= 0 then return end

        local alvHum = alvoAtual and alvoAtual:FindFirstChild("Humanoid")
        local alvHrp = alvoAtual and alvoAtual:FindFirstChild("HumanoidRootPart")

        if not alvoAtual or not alvHum or alvHum.Health <= 0 or not alvHrp then
            alvoAtual = getAlvo(hrp)
            return
        end

        local centro  = alvHrp.Position
        local agora   = tick()
        local delta   = agora - ultimoTick
        ultimoTick    = agora

        local destino

        if _G.KillAura_Orbit then
            -- Avança o ângulo com base no speed e delta de tempo
            orbitAngulo = orbitAngulo + (_G.KillAura_OrbitSpeed * delta)

            local r = _G.KillAura_OrbitRadius
            local offsetX = math.cos(orbitAngulo) * r
            local offsetZ = math.sin(orbitAngulo) * r

            destino = Vector3.new(
                centro.X + offsetX,
                centro.Y + _G.KillAura_OffsetY,
                centro.Z + offsetZ
            )

            if _G.KillAura_Mode == "tp" then
                hrp.CFrame   = CFrame.lookAt(destino, centro)
                hrp.Velocity = Vector3.new(0, 0, 0)

            elseif _G.KillAura_Mode == "fly" then
                if bodyPos then
                    bodyPos.P        = _G.KillAura_FlySpeed * 100
                    bodyPos.Position = destino
                end
                -- Gira personagem para sempre olhar para o mob
                if bodyGyro then
                    bodyGyro.CFrame = CFrame.lookAt(hrp.Position, centro)
                end
            end
        else
            -- Modo estático: fica em cima do mob
            destino = centro

            if _G.KillAura_Mode == "tp" then
                moverTP(hrp, destino)
            elseif _G.KillAura_Mode == "fly" then
                moverFly(destino)
            end

            if bodyGyro then
                bodyGyro.CFrame = CFrame.lookAt(
                    hrp.Position,
                    Vector3.new(centro.X, hrp.Position.Y, centro.Z)
                )
            end
        end
    end)
end

-- ══════════════════════════════════════════════════════
-- // KILL AURA — Loop de ataque
-- ══════════════════════════════════════════════════════

local function iniciarLoopAtaque()
    if atkConn then atkConn:Disconnect() atkConn = nil end

    local ultimo = 0

    atkConn = RunService.Heartbeat:Connect(function()
        if not _G.KillAura then return end
        if _G.BotOcupado   then return end  -- ← farm tem prioridade

        local agora     = tick()
        local intervalo = 1 / math.clamp(_G.KillAura_APS, 1, 30)
        if agora - ultimo < intervalo then return end
        ultimo = agora

        local hrp = getHRP()
        local hum = getHum()
        if not hrp or not hum or hum.Health <= 0 then return end

        local alvHum = alvoAtual and alvoAtual:FindFirstChild("Humanoid")

        if alvoAtual and alvHum and alvHum.Health > 0 then
            dispararAtaque()
            usarSkillsAtivas()
        else
            alvoAtual = getAlvo(hrp)
        end
    end)
end

-- ══════════════════════════════════════════════════════
-- // KILL AURA — Wave watcher
-- ══════════════════════════════════════════════════════

local function conectarWave()
    if waveConn then waveConn:Disconnect() waveConn = nil end

    local pasta = getPasta()
    if not pasta then return end

    waveConn = pasta.ChildAdded:Connect(function()
        task.wait(0.1)
        if not _G.KillAura then return end

        local alvHum = alvoAtual and alvoAtual:FindFirstChild("Humanoid")
        if not alvoAtual or not alvHum or alvHum.Health <= 0 then
            local hrp = getHRP()
            if hrp then alvoAtual = getAlvo(hrp) end
        end
    end)
end

-- ══════════════════════════════════════════════════════
-- // KILL AURA — Kill counter
-- ══════════════════════════════════════════════════════

local function conectarKillCounter()
    if killConn then killConn:Disconnect() killConn = nil end

    local pasta = getPasta()
    if not pasta then return end

    killConn = pasta.ChildRemoved:Connect(function(child)
        if child:IsA("Model") and child:FindFirstChild("Humanoid") then
            KASessao.kills += 1
            table.insert(KASessao.killsBuffer, tick())
            if alvoAtual == child then
                alvoAtual = nil
            end
        end
    end)
end

-- Reconecta listeners se EnemyNpc for recriada entre rounds
Workspace.ChildAdded:Connect(function(child)
    if child.Name == "EnemyNpc" then
        task.wait(0.1)
        conectarWave()
        conectarKillCounter()
    end
end)

-- Conecta na inicialização
task.spawn(function()
    local pasta = getPasta() or Workspace:WaitForChild("EnemyNpc", 30)
    if pasta then
        conectarWave()
        conectarKillCounter()
    end
end)

-- ══════════════════════════════════════════════════════
-- // KILL AURA — Ligar / Desligar
-- ══════════════════════════════════════════════════════

local function kaLigar()
    local hrp = getHRP()
    local hum = getHum()
    if not hrp or not hum then
        warn("[KillAura] ❌ Personagem não encontrado ao tentar ligar!")
        return
    end

    hum.PlatformStand = true
    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)

    if _G.KillAura_Mode == "fly" then
        criarBodyMovers(hrp)
    end

    if _G.KillAura_Noclip then
        setNoclip(true)
    end

    alvoAtual = getAlvo(hrp)
    iniciarLoopPosicao()
    iniciarLoopAtaque()
end

local function kaDesligar()
    if posConn then posConn:Disconnect() posConn = nil end
    if atkConn then atkConn:Disconnect() atkConn = nil end

    setNoclip(false)
    removerBodyMovers()

    alvoAtual = nil

    local hum = getHum()
    local hrp = getHRP()

    if hum then
        hum.PlatformStand = false
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
    end
    if hrp then
        hrp.Velocity = Vector3.new(0, 0, 0)
    end
end

-- ══════════════════════════════════════════════════════
-- // KILL AURA — Watcher de _G.KillAura
-- ══════════════════════════════════════════════════════

task.spawn(function()
    while task.wait(0.2) do
        if not _G.LoopAtivo then break end
        local ativo = _G.KillAura == true
        if ativo == kaEstadoAnterior then continue end
        kaEstadoAnterior = ativo

        if ativo then
            kaLigar()
        else
            kaDesligar()
        end
    end
end)

-- ══════════════════════════════════════════════════════
-- // KILL AURA — Respawn handler
-- ══════════════════════════════════════════════════════

lp.CharacterAdded:Connect(function()
    task.wait(1.5)
    if not _G.KillAura then return end
    removerBodyMovers()
    kaEstadoAnterior = false -- força o watcher a religar
end)

-- ══════════════════════════════════════════════════════
-- // BAÚS
-- ══════════════════════════════════════════════════════

local function quebrarBaus()
    local hrp = getHRP()
    if not hrp then return end

    local bausEncontrados = {}
    for _, obj in ipairs(Workspace:GetChildren()) do
        if string.match(obj.Name, "^Chest%d+$") then
            table.insert(bausEncontrados, obj)
        end
    end
    if #bausEncontrados == 0 then return end

    _G.QuebrandoBau = true
    _G.BotOcupado   = true  -- ← suspende Kill Aura

    -- Pausa o BodyPosition para o farm ter controle total do HRP
    if bodyPos then bodyPos.MaxForce = Vector3.new(0,0,0) end

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

        hrp.CFrame   = posBau * CFrame.new(0, 3, 0)
        hrp.Velocity = Vector3.new(0, 0, 0)
        task.wait(0.8)

        local tentativas = 0
        while bau.Parent and tentativas < 20 do
            tentativas += 1
            hrp.CFrame   = posBau * CFrame.new(0, 3, 0)
            hrp.Velocity = Vector3.new(0, 0, 0)
            pcall(function()
                RemoteAtaque:FireServer("SkillAction", "BaseAttack", 3)
                RemoteAtaque:FireServer("SkillAction", "BaseAttack", 1)
                RemoteAtaque:FireServer("SkillAction", "BaseAttack", 2)
                RemoteAtaque:FireServer("SkillAction", "BaseAttack", 4)
            end)
            task.wait(0.25)
        end
        task.wait(0.3)
    end

    -- Devolve controle ao Kill Aura
    if bodyPos then bodyPos.MaxForce = Vector3.new(1e5, 1e5, 1e5) end

    _G.QuebrandoBau = false
    _G.BotOcupado   = false  -- ← libera Kill Aura
    task.wait(0.4)
end


-- ══════════════════════════════════════════════════════
-- // PORTAIS — busca Portal e PortalD pelo mais próximo
-- ══════════════════════════════════════════════════════

local function encontrarPortalProximo()
    local hrp = getHRP()
    if not hrp then return nil end

    local portalFolder = Workspace:FindFirstChild("RoundDoor")
    if not portalFolder then
        warn("[AutoDungeon] ❌ 'RoundDoor' não encontrada no Workspace!")
        return nil
    end

    local nomesAlvo        = {"Portal", "PortalD"}
    local melhor, menorDist = nil, math.huge

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

    return melhor
end

local function simularToqueNoPortal(portal)
    local hrp = getHRP()
    if not hrp then return end

    _G.BotOcupado = true
    if bodyPos then bodyPos.MaxForce = Vector3.new(0,0,0) end

    local parte = portal:FindFirstChild("Root")
               or portal:FindFirstChild("door")
               or portal:FindFirstChildWhichIsA("BasePart")

    if parte then
        hrp.CFrame   = parte.CFrame * CFrame.new(0, 3, 0)
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

    if bodyPos then bodyPos.MaxForce = Vector3.new(1e5, 1e5, 1e5) end
    _G.BotOcupado = false
end


-- ══════════════════════════════════════════════════════
-- // ANTI-STUCK
-- ══════════════════════════════════════════════════════

local function antiStuck()
    if _G.AntiStuckAtivo then return end
    _G.AntiStuckAtivo = true

    local playerRespawn = Workspace:FindFirstChild("PlayerRespawn")

    for _ = 1, 20 do
        if not _G.LoopAtivo or not _G.AutoDungeonBot then break end

        local proximoRound = _G.RoundAtual + 1
        local hrp = getHRP()
        if not hrp then task.wait(1) continue end

        local partePart = playerRespawn
            and playerRespawn:FindFirstChild("Round" .. proximoRound)

        if partePart and partePart:IsA("BasePart") then
            hrp.CFrame   = partePart.CFrame * CFrame.new(0, 3, 0)
            hrp.Velocity = Vector3.new(0, 0, 0)
            _G.RoundAtual = proximoRound
            task.wait(1.5)

            if temInimigos() then
                _G.UltimoInimigo  = tick()
                _G.AntiStuckAtivo = false
                return
            end
        else
            quebrarBaus()
            local portal = encontrarPortalProximo()
            if portal then
                simularToqueNoPortal(portal)
                task.wait(2)
                if temInimigos() then
                    _G.UltimoInimigo  = tick()
                    _G.AntiStuckAtivo = false
                    return
                end
            else
                warn("[AutoDungeon] ❌ Anti-stuck: sem rounds e sem portal disponível!")
                break
            end
        end
    end

    _G.AntiStuckAtivo = false
end

-- ══════════════════════════════════════════════════════
-- // PROGRESSÃO DE DUNGEON
-- ══════════════════════════════════════════════════════

local function avancarDungeon()
    _G.QuebrandoBau = true
    quebrarBaus()
    _G.QuebrandoBau = false

    local playerRespawn   = Workspace:FindFirstChild("PlayerRespawn")
    local roundEncontrado = false

    for nextRound = _G.RoundAtual + 1, _G.RoundAtual + 10 do
        local proxParte = playerRespawn
            and playerRespawn:FindFirstChild("Round" .. nextRound)

        if proxParte and proxParte:IsA("BasePart") then
            realizarTeleporte(proxParte.CFrame)
            _G.RoundAtual  = nextRound
            roundEncontrado = true
            break
        else
            local portal = encontrarPortalProximo()
            if portal then
                simularToqueNoPortal(portal)
                task.wait(1.5)
                local parteApos = playerRespawn
                    and playerRespawn:FindFirstChild("Round" .. nextRound)
                if parteApos and parteApos:IsA("BasePart") then
                    realizarTeleporte(parteApos.CFrame)
                end
                _G.RoundAtual  = nextRound
                roundEncontrado = true
                break
            else
                warn("[AutoDungeon] ❌ Sem portal para Round" .. nextRound .. "!")
                break
            end
        end
    end

    if not roundEncontrado then
        _G.RoundAtual += 1
    end
end

-- ══════════════════════════════════════════════════════
-- // AUTO REPLAY
-- ══════════════════════════════════════════════════════

local function executarReplay()
    if not _G.AutoDungeonBot or not _G.AutoReplay then return end
    if _G.VictoryDetectado then return end
    _G.VictoryDetectado = true

    task.wait(1.5)
    pcall(function() GameRoundRE:FireServer("VotePlayAgain") end)

    _G.RoundAtual    = 1
    _G.PortaisUsados = {}
    _G.UltimoInimigo = tick()

    task.delay(5, function() _G.VictoryDetectado = false end)
end

-- ══════════════════════════════════════════════════════
-- // GATILHO: ROUND COMPLETED (BattleHUD)
-- ══════════════════════════════════════════════════════

task.spawn(function()
    local ok, hud = pcall(function()
        return PlayerGui
            :WaitForChild("BattleHUD")
            :WaitForChild("InformFrame")
    end)
    if not ok then
        warn("[AutoDungeon] ❌ BattleHUD/InformFrame não encontrado!")
        return
    end

    local msg = hud:WaitForChild("RoundCompleted")
    msg:GetPropertyChangedSignal("Visible"):Connect(function()
        if msg.Visible and _G.AutoDungeonBot then
            _G.UltimoInimigo = tick()
            avancarDungeon()
            task.wait(2)
            msg.Visible = false
        end
    end)
end)

-- ══════════════════════════════════════════════════════
-- // DETECÇÃO VICTORY — M1 (sinal de propriedade)
-- ══════════════════════════════════════════════════════

task.spawn(function()
    local ok, victoryGui = pcall(function()
        return PlayerGui
            :WaitForChild("ResultGui", 30)
            :WaitForChild("ScreenSettlement", 30)
            :WaitForChild("Victory", 30)
    end)
    if not ok or not victoryGui then
        warn("[AutoDungeon] ❌ Victory GUI não encontrado (M1)!")
        return
    end
    victoryGui:GetPropertyChangedSignal("Visible"):Connect(function()
        if victoryGui.Visible then executarReplay() end
    end)
end)

-- ══════════════════════════════════════════════════════
-- // DETECÇÃO VICTORY — M2 (polling backup)
-- ══════════════════════════════════════════════════════

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

-- ══════════════════════════════════════════════════════
-- // LOOP PRINCIPAL — Farm
-- // Tick 0.1s. Kill Aura tem prioridade de movimento/ataque.
-- // Farm usa o mesmo alvo mas via teleporte simples quando
-- // Kill Aura estiver desligado.
-- ══════════════════════════════════════════════════════

task.spawn(function()
    while task.wait(0.1) do
        if not _G.LoopAtivo then break end
        if _G.QuebrandoBau  then continue end

        -- Se Kill Aura estiver ativo, ele já cuida do combate
        if _G.KillAura then continue end

        -- Farm sem Kill Aura
        if not _G.AutoDungeonBot then continue end

        local pasta = getPasta()
        local hrp   = getHRP()
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
            if not _G.AntiStuckAtivo then
                if tick() - _G.UltimoInimigo >= 5 then
                    task.spawn(antiStuck)
                end
            end
        end
    end
end)


-- _G.AutoDungeonBot = true
--_G.AutoReplay = true

--_G.SkillsAtivas = {
--    Skill1 = true,
--    Skill2 = true,
--    SkillU = true,
--}

--_G.KillAura = true
--_G.KillAura_Mode = "fly"
--_G.KillAura_Priority = "closest"
--_G.KillAura_OffsetY = 8
--_G.KillAura_Noclip = true
