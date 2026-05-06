-- ============================================
-- VaenHub - "Kick a Lucky Block" Script
-- By Dalkoski - MacLib Version
-- ============================================

-- Carrega a MacLib
local MacLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/NickolasFrutuoso/MacUI/refs/heads/main/UI"))()

-- Serviços do Roblox
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Referências úteis
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Packages"):WaitForChild("Network")

-- Cria o HUB usando CreateHUB (já vem com Settings e Player tabs)
local HUB = MacLib:CreateHUB({
    Title    = "Kick a Lucky Block",
    Subtitle = "by Noliar",
    OnTabGroup = function(TabGroup, Window)
        
        -- ============================================
        -- TAB MAIN
        -- ============================================
        local MainTab = TabGroup:Tab({ 
            Name = "Main", 
            Image = "rbxassetid://10734950309" 
        })

        -- Seção Game Specific
        local GameSection = MainTab:Section({ Side = "Left" })
        GameSection:Header({ Name = "FARM MODE" })

        -- Auto Kick + Get Brainrots
        GameSection:Toggle({
            Name     = "Auto Kick (OP POWER)",
            Default  = false,
            Callback = function(state) end
        }, "AutoKickFlag")

        -- Auto Click Bonus
        GameSection:Toggle({
            Name     = "Auto Click Bonus (With Weights)",
            Default  = false,
            Callback = function(state) end
        }, "AutoBonusFlag")

        -- Auto Sell All Brainrots
        GameSection:Toggle({
            Name     = "Auto Sell All Brainrots",
            Default  = false,
            Callback = function(state) end
        }, "AutoSell")

        -- Auto Speed Upgrade
        GameSection:Toggle({
            Name     = "Auto Speed Upgrade",
            Default  = false,
            Callback = function(state) end
        }, "AutoSpeed")

        -- Auto Collect Cash
        GameSection:Toggle({
            Name     = "Auto Collect Cash",
            Default  = false,
            Callback = function(state) end
        }, "AutoCollect")

        -- Auto Upgrade Brainrots
        GameSection:Toggle({
            Name     = "Auto Upgrade Brainrots",
            Default  = false,
            Callback = function(state) end
        }, "AutoUpgrade")

        -- Auto Rebirth
        GameSection:Toggle({
            Name     = "Auto Rebirth",
            Default  = false,
            Callback = function(state) end
        }, "AutoRebirth")
    end
})

-- Referências
local Window = HUB.Window

-- ============================================
-- SISTEMA DE LOOPS (executa independente dos callbacks dos toggles)
-- ============================================

-- Função auxiliar para criar loops que verificam as flags
local function createToggleLoop(flagName, loopFunction, interval)
    task.spawn(function()
        while task.wait(interval or 1) do
            local option = MacLib.Options[flagName]
            if option and option:GetState() then
                local success, err = pcall(loopFunction)
                if not success then
                    warn("Error in loop [" .. flagName .. "]: " .. err)
                end
            end
        end
    end)
end

-- Auto Kick Loop
createToggleLoop("AutoKickFlag", function()
    local kickEvent = Network:FindFirstChild("rev_KickEvent")
    local speedUpgrade = Network:FindFirstChild("rev_SPEED_UPGRADE")
    
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local kickReady = workspace:FindFirstChild("Areas") and workspace.Areas:FindFirstChild("KickReady")
    
    if kickReady and humanoid and kickEvent then
        kickEvent:FireServer()
    end
    
    if humanoid and humanoid.WalkSpeed < 16 and speedUpgrade then
        speedUpgrade:FireServer(1)
    end
end, 1)

-- Auto Bonus Loop
createToggleLoop("AutoBonusFlag", function()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local kickUpgrades = playerGui:FindFirstChild("KickUpgrades")
    
    if kickUpgrades then
        for _, child in ipairs(kickUpgrades:GetChildren()) do
            if child:IsA("ImageButton") or child:IsA("TextButton") then
                local x = child.AbsolutePosition.X + child.AbsoluteSize.X / 2
                local y = child.AbsolutePosition.Y + child.AbsoluteSize.Y / 2
                
                VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
                task.wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
                task.wait(0.1)
            end
        end
    end
end, 0.3)

-- Auto Sell Loop
createToggleLoop("AutoSell", function()
    local sellAll = Network:FindFirstChild("ref_B_SellAll")
    if sellAll then
        sellAll:InvokeServer()
    end
end, 1)

-- Auto Speed Loop
createToggleLoop("AutoSpeed", function()
    local speedUpgrade = Network:FindFirstChild("rev_SPEED_UPGRADE")
    if speedUpgrade then
        speedUpgrade:FireServer(1)
    end
end, 0.5)

-- Auto Collect Loop
createToggleLoop("AutoCollect", function()
    local collect = Network:FindFirstChild("rev_B_Collect")
    if collect then
        for slot = 1, 10 do
            collect:FireServer(slot)
            task.wait(0.2)
        end
    end
end, 3)

-- Auto Upgrade Loop
createToggleLoop("AutoUpgrade", function()
    local upgrade = Network:FindFirstChild("rev_B_Upgrade")
    if upgrade then
        for slot = 1, 10 do
            upgrade:FireServer(slot)
            task.wait(0.01)
        end
    end
end, 0.5)

-- Auto Rebirth Loop
createToggleLoop("AutoRebirth", function()
    local rebirth = Network:FindFirstChild("rev_RebirthRequest")
    if rebirth then
        rebirth:FireServer()
    end
end, 2)

-- ============================================
-- NOTIFICAÇÃO INICIAL
-- ============================================
task.wait(1)  -- Aguarda a UI carregar completamente
Window:Notify({
    Title = "Noliar HUB Loaded",
    Description = "by Noliar • Kick a Lucky Block",
    Lifetime = 5,
    Style = "Confirm"
})
