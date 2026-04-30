-- ══════════════════════════════════════════════════════
-- // SCOPED GUI - Rayfield Interface
-- ══════════════════════════════════════════════════════

-- Load the base script first (defines all _G functions)
loadstring(game:HttpGet("https://raw.githubusercontent.com/NickolasFrutuoso/Roblox-Script/refs/heads/main/Scoped.lua"))()

-- Load Rayfield
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- ══════════════════════════════════════════════════════
-- // MAIN WINDOW
-- ══════════════════════════════════════════════════════

local Window = Rayfield:CreateWindow({
    Name             = "Scoped | UPDT 04/30",
    LoadingTitle     = "[FPS]🎯Scoped [BETA]",
    LoadingSubtitle  = "by Noliar",
    ShowText         = "v1.0",
    Theme            = "Default",
    ToggleUIKeybind  = "L",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = false,
    ConfigurationSaving = {
        Enabled    = true, 
        FolderName = "Scoped",
        FileName   = "Noliar-HUB",
    },
    Discord   = { Enabled = false },
    KeySystem = false,
})

-- ══════════════════════════════════════════════════════
-- // TAB: AIMBOT
-- ══════════════════════════════════════════════════════

local AimbotTab = Window:CreateTab("🎯 Aimbot", nil)

AimbotTab:CreateSection("General")

AimbotTab:CreateParagraph({
    Title = "Silent Aimbot",
    Content = "If it doesn't work, please check your ping or switch to a different server."
})

AimbotTab:CreateToggle({
    Name = "Enable Silent Aimbot",
    CurrentValue = _G.AimbotAtivo or false,
    Flag = "AimbotAtivo",
    Callback = function(value)
        _G.AimbotAtivo = value
    end,
})

AimbotTab:CreateParagraph({
    Title = "Wall Penetration",
    Content = "When ON, the aimbot will lock onto targets even through walls. When OFF, only visible targets are tracked."
})

AimbotTab:CreateToggle({
    Name = "Wall Penetration",
    CurrentValue = _G.AtravestParede or false,
    Flag = "AtravestParede",
    Callback = function(value)
        _G.AtravestParede = value
    end,
})

AimbotTab:CreateSection("Smoothness & FOV")

AimbotTab:CreateParagraph({
    Title = "FOV Radius",
    Content = "The radius (in pixels) around your crosshair where enemies are detected. Lower = tighter cone. Higher = wider detection area."
})

AimbotTab:CreateSlider({
    Name = "FOV Radius",
    Range = {10, 500},
    Increment = 5,
    Suffix = "px",
    CurrentValue = _G.FovRaio or 130,
    Flag = "FovRaio",
    Callback = function(value)
        _G.FovRaio = value
    end,
})

AimbotTab:CreateParagraph({
    Title = "Smoothness",
    Content = "Controls how fast the aimbot snaps to the target. Lower = slower and smoother. Higher = instant snap."
})

AimbotTab:CreateSlider({
    Name = "Smoothness",
    Range = {1, 100},
    Increment = 1,
    Suffix = "%",
    CurrentValue = math.floor((_G.SuavidadeBase or 0.12) * 100),
    Flag = "SuavidadeBase",
    Callback = function(value)
        _G.SuavidadeBase = value / 100
    end,
})

AimbotTab:CreateParagraph({
    Title = "Humanization",
    Content = "Adds a random pixel offset to mouse movement to simulate human imperfection. 0 = perfect aim. Higher = more natural-looking movement."
})

AimbotTab:CreateSlider({
    Name = "Humanization (noise)",
    Range = {0, 20},
    Increment = 1,
    Suffix = "px",
    CurrentValue = _G.Humanizacao or 2,
    Flag = "Humanizacao",
    Callback = function(value)
        _G.Humanizacao = value
    end,
})

AimbotTab:CreateSection("Target Part")

AimbotTab:CreateDropdown({
    Name = "Target Part",
    Options = _G.PartesDisponiveis or {
        "Head", "HumanoidRootPart", "UpperTorso",
        "LowerTorso", "RightArm", "LeftArm", "RightLeg", "LeftLeg"
    },
    CurrentOption = {_G.ParteAlvo or "Head"},
    MultipleOptions = false,
    Flag = "ParteAlvo",
    Callback = function(option)
        _G.ParteAlvo = option[1]
    end,
})

AimbotTab:CreateParagraph({
    Title = "Random Part Mode",
    Content = "When ON, ignores the Target Part setting and randomly picks between Head and HumanoidRootPart each shot. Use the slider below to set the Head probability."
})

AimbotTab:CreateToggle({
    Name = "Random Part Mode",
    CurrentValue = _G.ModoAleatorio or false,
    Flag = "ModoAleatorio",
    Callback = function(value)
        _G.ModoAleatorio = value
    end,
})

AimbotTab:CreateSlider({
    Name = "Head Chance (Random Mode)",
    Range = {0, 100},
    Increment = 5,
    Suffix = "%",
    CurrentValue = _G.ChanceCabeca or 60,
    Flag = "ChanceCabeca",
    Callback = function(value)
        _G.ChanceCabeca = value
    end,
})

-- ══════════════════════════════════════════════════════
-- // TAB: REWARDS
-- ══════════════════════════════════════════════════════

local RewardsTab = Window:CreateTab("🎁 Rewards", nil)

RewardsTab:CreateSection("Collect All Rewards")

RewardsTab:CreateParagraph({
    Title = "Collect All Rewards",
    Content = "Claims all daily rewards (slots 1–8) AND all level milestone rewards (every 5 levels from 5 to 100) in a single click. Wait a few seconds for it to finish."
})

RewardsTab:CreateButton({
    Name = "⚡ Collect All Rewards",
    Callback = function()
        Rayfield:Notify({
            Title = "Rewards",
            Content = "Collecting all rewards... Please wait.",
            Duration = 4,
            Image = 4483362458,
        })
        task.spawn(function()
            if _G.GetAllRewards then
                _G.GetAllRewards()
            end
            task.wait(0.5)
            if _G.ClaimAllLevelRewards then
                _G.ClaimAllLevelRewards()
            end
            Rayfield:Notify({
                Title = "Rewards",
                Content = "All rewards collected successfully!",
                Duration = 4,
                Image = 4483362458,
            })
        end)
    end,
})

-- ══════════════════════════════════════════════════════
-- // TAB: CHEST
-- ══════════════════════════════════════════════════════

local ChestTab = Window:CreateTab("📦 Chest", nil)

local chestNomes = {}
for nome, _ in pairs(_G.ChestList or {
    ["Origin Case"] = "S1",
    ["Fracture Case"] = "S3",
    ["Technical Case"] = "S4",
}) do
    table.insert(chestNomes, nome)
end

ChestTab:CreateSection("Configuration")

ChestTab:CreateDropdown({
    Name = "Selected Chest",
    Options = chestNomes,
    CurrentOption = {_G.ChestSelecionado or "Technical Case"},
    MultipleOptions = false,
    Flag = "ChestSelecionado",
    Callback = function(option)
        _G.ChestSelecionado = option[1]
    end,
})

ChestTab:CreateInput({
    Name = "Buy Quantity",
    PlaceholderText = "Default: 10",
    RemoveTextAfterFocusLost = false,
    Flag = "ChestQuantComprar",
    Callback = function(text)
        local num = tonumber(text)
        if num and num > 0 then
            _G.ChestQuantComprar = math.floor(num)
        end
    end,
})

ChestTab:CreateInput({
    Name = "Open Quantity",
    PlaceholderText = "Default: 10",
    RemoveTextAfterFocusLost = false,
    Flag = "ChestQuantAbrir",
    Callback = function(text)
        local num = tonumber(text)
        if num and num > 0 then
            _G.ChestQuantAbrir = math.floor(num)
        end
    end,
})

ChestTab:CreateSection("Actions")

ChestTab:CreateParagraph({
    Title = "Buy & Open",
    Content = "⚠️ Warning: If you try to open a chest you don't have in your inventory, the game will automatically purchase it for you using your coins. Make sure you have enough coins before clicking Open."    
})

ChestTab:CreateButton({
    Name = "Buy Chest",
    Callback = function()
        local nome = customBuyName or _G.ChestSelecionado or "Technical Case"
        local qtd  = _G.ChestQuantComprar or 10
        Rayfield:Notify({
            Title = "Chest",
            Content = "Buying " .. qtd .. "x " .. nome .. "...",
            Duration = 3,
            Image = 4483362458,
        })
        task.spawn(function()
            _G.ComprarChest(nome, qtd)
        end)
    end,
})

ChestTab:CreateButton({
    Name = "Open Chest",
    Callback = function()
        local nome = _G.ChestSelecionado or "Technical Case"
        local qtd  = _G.ChestQuantAbrir or 10
        Rayfield:Notify({
            Title = "Chest",
            Content = "Opening " .. qtd .. "x " .. nome .. "...",
            Duration = 3,
            Image = 4483362458,
        })
        task.spawn(function()
            _G.AbrirChest(nome, qtd)
        end)
    end,
})

-- ══════════════════════════════════════════════════════
-- // READY NOTIFICATION
-- ══════════════════════════════════════════════════════

Rayfield:Notify({
    Title = "Scoped Ready!",
    Content = "All modules loaded. GUI is ready to use.",
    Duration = 5,
    Image = 4483362458,
})
