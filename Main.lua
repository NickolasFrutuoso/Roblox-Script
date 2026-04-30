local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name             = "Iron Soul | Script Updated!",
    LoadingTitle     = "Iron Soul: Dungeon",
    LoadingSubtitle  = "by Noliar",
    Theme            = "Default",
    DisableRayfieldPrompts = true,
    DisableBuildWarnings   = true,
    ConfigurationSaving = { Enabled = false },
    Discord   = { Enabled = false },
    KeySystem = false,
})

local Tab = Window:CreateTab("Update", nil)

Tab:CreateSection("🆕  New Update Available")

Tab:CreateLabel("The script has been updated with new features and bug fixes.")
Tab:CreateLabel("Copy the new loader below or visit the script page to get it.")

Tab:CreateSection("🔗  Script Page")

Tab:CreateButton({
    Name     = "Open Script Page  (rscripts.net)",
    Callback = function()
        setclipboard("https://rscripts.net/script/op-iron-soul-or-auto-farm-auto-rerun-sell-gui-and-more-1pGJ")
        Rayfield:Notify({
            Title   = "Link Copied!",
            Content = "Script page URL copied to clipboard. Paste it in your browser.",
            Duration = 5,
        })
    end,
})

Tab:CreateSection("📋  Quick Loader")

Tab:CreateLabel("Click the button below to copy the loader and paste it in your executor.")

Tab:CreateButton({
    Name     = "Copy Loader to Clipboard",
    Callback = function()
        setclipboard('loadstring(game:HttpGet("https://pastefy.app/u731MA8m/raw"))()')
        Rayfield:Notify({
            Title   = "Loader Copied!",
            Content = 'Paste it in your executor and run it.',
            Duration = 5,
        })
    end,
})

Rayfield:Notify({
    Title   = "Script Updated!",
    Content = "A new version is available. Copy the loader or visit the script page.",
    Duration = 6,
})
