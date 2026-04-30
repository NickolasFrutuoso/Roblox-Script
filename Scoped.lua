-- Scoped.lua

local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- ══════════════════════════════════════════════════════
-- // CONFIGURAÇÕES GLOBAIS (_G)
-- ══════════════════════════════════════════════════════

_G.AimbotAtivo       = true
_G.FovRaio           = 130
_G.SuavidadeBase     = 0.12
_G.Humanizacao       = 2
_G.AtravestParede    = false  -- false = só mira se visível | true = mira através de paredes

-- Parte do corpo alvo:
-- "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "RightArm", "LeftArm"
_G.ParteAlvo         = "Head"

-- Modo aleatório: ignora _G.ParteAlvo e sorteia entre as partes abaixo
_G.ModoAleatorio     = false
_G.ChanceCabeca      = 60  -- % de chance de Head no modo aleatório (resto vai pro HRP)



-- Lista de partes válidas (usada no GUI para montar o dropdown)
_G.PartesDisponiveis = {
    "Head",
    "HumanoidRootPart",
    "UpperTorso",
    "LowerTorso",
    "RightArm",
    "LeftArm",
    "RightLeg",
    "LeftLeg",
}

-- ══════════════════════════════════════════════════════
-- // VISIBILIDADE
-- ══════════════════════════════════════════════════════

local function estaVisivel(parte)
    -- Se atravessar paredes está ativo, sempre retorna true
    if _G.AtravestParede then return true end

    local origem    = Camera.CFrame.Position
    local direcao   = parte.Position - origem
    local parametros = RaycastParams.new()

    local listaIgnorar = {Players.LocalPlayer.Character}
    local pasta = workspace:FindFirstChild("PlayersCharacters")
    if pasta then
        for _, v in ipairs(pasta:GetChildren()) do
            table.insert(listaIgnorar, v)
        end
    end

    parametros.FilterDescendantsInstances = listaIgnorar
    parametros.FilterType = Enum.RaycastFilterType.Exclude

    local resultado = workspace:Raycast(origem, direcao, parametros)
    return resultado == nil
end

-- ══════════════════════════════════════════════════════
-- // SELEÇÃO DE PARTE
-- ══════════════════════════════════════════════════════

local function getParteAlvo()
    if _G.ModoAleatorio then
        local sorteio = math.random(1, 100)
        return (sorteio <= _G.ChanceCabeca) and "Head" or "HumanoidRootPart"
    end
    return _G.ParteAlvo or "Head"
end

-- ══════════════════════════════════════════════════════
-- // BUSCA DE ALVO
-- ══════════════════════════════════════════════════════

local function getAlvo()
    local alvo      = nil
    local menorDist = _G.FovRaio
    local centro    = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    local pasta = workspace:FindFirstChild("PlayersCharacters")
    if not pasta then return nil end

    local localChar = Players.LocalPlayer.Character

    for _, char in ipairs(pasta:GetChildren()) do
        if char:IsA("Model") and char ~= localChar then
            local nomeParte = getParteAlvo()
            local parte     = char:FindFirstChild(nomeParte)

            -- Fallback: se a parte não existir (ex: R6 não tem UpperTorso), tenta HRP
            if not parte then
                parte = char:FindFirstChild("HumanoidRootPart")
            end

            if parte then
                local pos, visivelNaTela = Camera:WorldToViewportPoint(parte.Position)
                if visivelNaTela then
                    local dist = (centro - Vector2.new(pos.X, pos.Y)).Magnitude
                    if dist < menorDist and estaVisivel(parte) then
                        menorDist = dist
                        alvo      = pos
                    end
                end
            end
        end
    end

    return alvo
end

-- ══════════════════════════════════════════════════════
-- // LOOP DE MOVIMENTO
-- ══════════════════════════════════════════════════════

RunService.RenderStepped:Connect(function()
    if _G.AimbotAtivo and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local alvoPos = getAlvo()

        if alvoPos then
            local centro = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

            local diffX = alvoPos.X - centro.X
            local diffY = alvoPos.Y - centro.Y

            if _G.Humanizacao > 0 then
                diffX += math.random(-_G.Humanizacao, _G.Humanizacao)
                diffY += math.random(-_G.Humanizacao, _G.Humanizacao)
            end

            pcall(function()
                mousemoverel(diffX * _G.SuavidadeBase, diffY * _G.SuavidadeBase)
            end)
        end
    end
end)

-- ══════════════════════════════════════════════════════
-- // REWARDS
-- ══════════════════════════════════════════════════════

_G.GetAllRewards = function()
    for i = 1, 8 do
        pcall(function()
            game:GetService("ReplicatedStorage")
                :WaitForChild("Remote")
                :WaitForChild("Event")
                :WaitForChild("Reward")
                :WaitForChild("[C-S]TryGetReward")
                :FireServer(tostring(i))
        end)
        task.wait(0.3)
    end
end

_G.ClaimAllLevelRewards = function()
    for i = 5, 100, 5 do
        pcall(function()
            game:GetService("ReplicatedStorage")
                :WaitForChild("Remote")
                :WaitForChild("Event")
                :WaitForChild("Reward")
                :WaitForChild("[C-S]ClaimLevelReward")
                :FireServer("R" .. tostring(i))
        end)
        task.wait(0.3)
    end
end

-- Para usar:
-- _G.ClaimAllLevelRewards()

-- Coletar todas as recompensas
-- _G.GetAllRewards()

-- ══════════════════════════════════════════════════════
-- // CHEST SYSTEM
-- ══════════════════════════════════════════════════════

-- Lista de caixas disponíveis
_G.ChestList = {
    ["Origin Case"]    = "S1",
    ["Fracture Case"]  = "S3",
    ["Technical Case"] = "S4",
}

-- Configurações
_G.ChestSelecionado  = "Technical Case"  -- nome da caixa
_G.ChestQuantComprar = 10                -- quantas comprar
_G.ChestQuantAbrir   = 10                -- quantas abrir

-- ── Comprar ────────────────────────────────────────────
_G.ComprarChest = function(nome, quantidade)
    nome      = nome      or _G.ChestSelecionado
    quantidade = quantidade or _G.ChestQuantComprar

    local id = _G.ChestList[nome]
    if not id then
        warn("[Chest] Caixa não encontrada: " .. tostring(nome))
        return
    end

    local remote = game:GetService("ReplicatedStorage")
        :WaitForChild("Remote")
        :WaitForChild("Event")
        :WaitForChild("Shop")
        :WaitForChild("[C-S]TryBuyChestCoin")

    for i = 1, quantidade do
        pcall(function()
            remote:FireServer(id)
        end)
        task.wait(0.3)
    end

    print("[Chest] Comprou " .. quantidade .. "x " .. nome .. " (" .. id .. ")")
end

-- ── Abrir ──────────────────────────────────────────────
_G.AbrirChest = function(nome, quantidade)
    nome      = nome      or _G.ChestSelecionado
    quantidade = quantidade or _G.ChestQuantAbrir

    local id = _G.ChestList[nome]
    if not id then
        warn("[Chest] Caixa não encontrada: " .. tostring(nome))
        return
    end

    local remote = game:GetService("ReplicatedStorage")
        :WaitForChild("Remote")
        :WaitForChild("Function")
        :WaitForChild("Chest")
        :WaitForChild("[C-S]OpenChest")

    for i = 1, quantidade do
        pcall(function()
            remote:InvokeServer(id, 1)
        end)
        task.wait(0.5)
    end

    print("[Chest] Abriu " .. quantidade .. "x " .. nome .. " (" .. id .. ")")
end

-- ── Comprar e Abrir junto ──────────────────────────────
_G.ComprarEAbrirChest = function(nome, quantidade)
    nome      = nome      or _G.ChestSelecionado
    quantidade = quantidade or _G.ChestQuantComprar

    _G.ComprarChest(nome, quantidade)
    task.wait(1)
    _G.AbrirChest(nome, quantidade)
end
