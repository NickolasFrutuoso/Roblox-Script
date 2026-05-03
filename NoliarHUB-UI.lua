--[[
╔══════════════════════════════════════════════════════════╗
║              ForgeLib — UI Library for Roblox            ║
║              Estilo: Seisen / Rayfield                   ║
║                                                          ║
║  USO BÁSICO:                                             ║
║                                                          ║
║  local ForgeLib = loadstring(game:HttpGet("URL"))()      ║
║                                                          ║
║  local Window = ForgeLib:CreateWindow({                  ║
║      Title    = "NOLIAR HUB",                            ║
║      Subtitle = "v1.0.0",                                ║
║      ToggleKey = Enum.KeyCode.LeftAlt,                   ║
║  })                                                      ║
║                                                          ║
║  local Tab = Window:CreateTab("Lobby")                   ║
║                                                          ║
║  Tab:CreateToggle({                                      ║
║      Name     = "Auto Farm",                             ║
║      Default  = false,                                   ║
║      Keybind  = "F",                                     ║
║      Callback = function(v) print(v) end,                ║
║  })                                                      ║
║                                                          ║
║  Tab:CreateSlider({                                      ║
║      Name = "Walk Speed", Min=16, Max=100, Default=16,   ║
║      Callback = function(v) ... end,                     ║
║  })                                                      ║
║                                                          ║
║  Tab:CreateDropdown({                                    ║
║      Name  = "Target",                                   ║
║      Items = {"Closest","Lowest HP"},                    ║
║      Default = "Closest",                                ║
║      Callback = function(v) ... end,                     ║
║  })                                                      ║
║                                                          ║
║  Tab:CreateButton({                                      ║
║      Name  = "Execute",                                  ║
║      Style = "primary",  -- primary|success|danger       ║
║      Callback = function() ... end,                      ║
║  })                                                      ║
║                                                          ║
║  Tab:CreateInput({                                       ║
║      Name = "Webhook URL",                               ║
║      Placeholder = "https://...",                        ║
║      Callback = function(v) ... end,                     ║
║  })                                                      ║
║                                                          ║
║  Tab:CreateKeybind({                                     ║
║      Name = "Toggle ESP",                                ║
║      Default = Enum.KeyCode.E,                           ║
║      Callback = function(k) ... end,                     ║
║  })                                                      ║
║                                                          ║
║  Tab:CreateLabel({ Text = "Versão 1.0", Color = nil })   ║
║  Tab:CreateSection("Seção")                              ║
║  Tab:CreateInfo({ Lines = {"Linha 1","Linha 2"} })       ║
║                                                          ║
║  ForgeLib:Notify({                                       ║
║      Title   = "Sucesso",                                ║
║      Content = "Feito!",                                 ║
║      Duration = 4,                                       ║
║  })                                                      ║
╚══════════════════════════════════════════════════════════╝
]]

-- ============================================================
-- SERVIÇOS
-- ============================================================
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================
-- TEMA (Dark / Seisen)
-- ============================================================
local Theme = {
    Background  = Color3.fromRGB(14, 14, 17),
    Surface     = Color3.fromRGB(20, 20, 24),
    Surface2    = Color3.fromRGB(28, 28, 34),
    Border      = Color3.fromRGB(38, 38, 46),
    Accent      = Color3.fromRGB(124, 106, 247),
    AccentGreen = Color3.fromRGB(34, 197, 94),
    AccentRed   = Color3.fromRGB(239, 68, 68),
    TextPrimary = Color3.fromRGB(200, 200, 204),
    TextMuted   = Color3.fromRGB(80, 80, 90),
    TextHint    = Color3.fromRGB(48, 48, 56),
    InputBg     = Color3.fromRGB(22, 22, 28),
    ToggleOff   = Color3.fromRGB(38, 38, 46),
    White       = Color3.fromRGB(255, 255, 255),
}

-- ============================================================
-- UTILITÁRIOS INTERNOS
-- ============================================================
local function Tween(obj, props, t)
    TweenService:Create(obj, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad), props):Play()
end

local function New(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        pcall(function() inst[k] = v end)
    end
    if parent then inst.Parent = parent end
    return inst
end

local function Corner(r, p)
    return New("UICorner", { CornerRadius = UDim.new(0, r) }, p)
end

local function Stroke(color, thick, p)
    return New("UIStroke", { Color = color or Theme.Border, Thickness = thick or 0.5 }, p)
end

local function Padding(t, b, l, r, p)
    return New("UIPadding", {
        PaddingTop    = UDim.new(0, t or 0), PaddingBottom = UDim.new(0, b or 0),
        PaddingLeft   = UDim.new(0, l or 0), PaddingRight  = UDim.new(0, r or 0),
    }, p)
end

local function List(spacing, p)
    return New("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, spacing or 0),
    }, p)
end

local function AutoSize(frame)
    local layout = frame:FindFirstChildOfClass("UIListLayout")
    if not layout then return end
    local function update()
        frame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 28)
    end
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
    update()
end

-- ============================================================
-- AVATAR DO PERSONAGEM (thumbnail via Players API)
-- ============================================================
local function GetAvatarThumb(userId)
    local ok, url = pcall(function()
        return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
    end)
    return ok and url or nil
end

-- ============================================================
-- SAVE / LOAD CONFIG (JSON via datafolder simulado em _G)
-- ============================================================
local ConfigStore = {}

local function SaveConfig(name, data)
    ConfigStore[name] = HttpService:JSONEncode(data)
end

local function LoadConfig(name)
    if ConfigStore[name] then
        return HttpService:JSONDecode(ConfigStore[name])
    end
    return nil
end

local function ListConfigs()
    local list = {}
    for k in pairs(ConfigStore) do table.insert(list, k) end
    return list
end

-- ============================================================
-- NOTIFICAÇÕES
-- ============================================================
local NotifHolder

local function EnsureNotifHolder()
    if NotifHolder and NotifHolder.Parent then return end
    local sg = New("ScreenGui", { Name = "ForgeLib_Notifs", ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, PlayerGui)
    NotifHolder = New("Frame", {
        Name = "Holder", AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -16, 1, -16),
        Size = UDim2.new(0, 290, 1, 0), BackgroundTransparency = 1,
    }, sg)
    local l = List(8, NotifHolder)
    l.VerticalAlignment = Enum.VerticalAlignment.Bottom
end

local ForgeLib = {}
ForgeLib.__index = ForgeLib

function ForgeLib:Notify(opts)
    opts = opts or {}
    EnsureNotifHolder()
    local title    = opts.Title or "Aviso"
    local content  = opts.Content or ""
    local duration = opts.Duration or 4
    local color    = opts.Color or Theme.Accent

    local card = New("Frame", {
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundColor3 = Theme.Surface,
        BackgroundTransparency = 1,
    }, NotifHolder)
    Corner(9, card)
    Stroke(Theme.Border, 0.5, card)
    Padding(10, 10, 14, 12, card)

    New("Frame", { Size = UDim2.new(0, 3, 1, -20),
        Position = UDim2.new(0, -14, 0, 10),
        BackgroundColor3 = color }, card)

    New("Frame", { Size = UDim2.new(0, 8, 0, 8),
        Position = UDim2.new(0, 0, 0, 4),
        BackgroundColor3 = color }, card)
    Corner(4, card:FindFirstChild("Frame"))

    New("TextLabel", {
        Size = UDim2.new(1, -16, 0, 17), Position = UDim2.new(0, 16, 0, 0),
        BackgroundTransparency = 1, Text = title,
        TextColor3 = Theme.TextPrimary, TextSize = 13,
        Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left,
    }, card)
    New("TextLabel", {
        Size = UDim2.new(1, -16, 0, 14), Position = UDim2.new(0, 16, 0, 22),
        BackgroundTransparency = 1, Text = content,
        TextColor3 = Theme.TextMuted, TextSize = 11,
        Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, card)

    Tween(card, { BackgroundTransparency = 0 }, 0.2)
    task.delay(duration, function()
        Tween(card, { BackgroundTransparency = 1 }, 0.3)
        task.wait(0.35)
        card:Destroy()
    end)
end

-- ============================================================
-- CRIAR JANELA
-- ============================================================
function ForgeLib:CreateWindow(opts)
    opts = opts or {}
    local titleText = opts.Title    or "NOLIAR HUB"
    local subtitle  = opts.Subtitle or "v1.0.0"
    local toggleKey = opts.ToggleKey or Enum.KeyCode.LeftAlt

    -- ScreenGui principal
    local ScreenGui = New("ScreenGui", {
        Name = "ForgeLib_UI", ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, PlayerGui)

    -- ── Sombra (frame levemente maior atrás)
    local Shadow = New("Frame", {
        Name = "Shadow", AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 2, 0.5, 2),
        Size = UDim2.new(0, 726, 0, 486),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.6,
    }, ScreenGui)
    Corner(12, Shadow)

    -- ── Janela principal
    local Main = New("Frame", {
        Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 720, 0, 480),
        BackgroundColor3 = Theme.Background,
        ClipsDescendants = true,
    }, ScreenGui)
    Corner(10, Main)
    Stroke(Theme.Border, 0.5, Main)

    -- ── Topbar
    local Topbar = New("Frame", {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = Theme.Surface,
    }, Main)
    Stroke(Theme.Border, 0.5, Topbar)

    -- Botões macOS decorativos
    local wbColors = {
        Color3.fromRGB(255,95,87),
        Color3.fromRGB(255,189,68),
        Color3.fromRGB(40,200,64)
    }
    for i, c in ipairs(wbColors) do
        local btn = New("Frame", {
            Size = UDim2.new(0,12,0,12),
            Position = UDim2.new(0, 10+(i-1)*18, 0.5, -6),
            BackgroundColor3 = c,
        }, Topbar)
        Corner(6, btn)

        -- Fechar (vermelho)
        if i == 1 then
            New("TextButton", {
                Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
                Text = "", ZIndex = 5,
            }, btn).MouseButton1Click:Connect(function()
                Tween(Main, { Size = UDim2.new(0,0,0,0), Position = UDim2.new(0.5,0,0.5,0) }, 0.2)
                task.wait(0.22)
                ScreenGui:Destroy()
            end)
        end
        -- Minimizar (amarelo)
        if i == 2 then
            local minimized = false
            New("TextButton", {
                Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
                Text = "", ZIndex = 5,
            }, btn).MouseButton1Click:Connect(function()
                minimized = not minimized
                if minimized then
                    Tween(Main, { Size = UDim2.new(0,720,0,42) }, 0.18)
                else
                    Tween(Main, { Size = UDim2.new(0,720,0,480) }, 0.18)
                end
            end)
        end
    end

    -- Título (duas cores: palavra1 branca / palavra2 roxa)
    local words = titleText:split(" ")
    local rich = string.format(
        '<font color="rgb(210,210,215)">%s</font> <font color="rgb(124,106,247)">%s</font>',
        words[1] or titleText, words[2] or ""
    )
    local TitleLabel = New("TextLabel", {
        Size = UDim2.new(0,260,1,0), Position = UDim2.new(0,74,0,0),
        BackgroundTransparency = 1, RichText = true, Text = rich,
        Font = Enum.Font.GothamBold, TextSize = 14,
        TextColor3 = Theme.TextPrimary, TextXAlignment = Enum.TextXAlignment.Left,
    }, Topbar)

    -- Badge versão
    local VerBadge = New("TextLabel", {
        Size = UDim2.new(0,52,0,22), AnchorPoint = Vector2.new(1,0.5),
        Position = UDim2.new(1,-14,0.5,0),
        BackgroundColor3 = Theme.AccentGreen,
        Text = subtitle, Font = Enum.Font.GothamMedium,
        TextSize = 11, TextColor3 = Theme.White,
    }, Topbar)
    Corner(11, VerBadge)

    -- ── Arraste
    local dragging, dragStart, startPos
    Topbar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = inp.Position; startPos = Main.Position
        end
    end)
    Topbar.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d = inp.Position - dragStart
            Main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)

    -- ── Toggle visibilidade
    UserInputService.InputBegan:Connect(function(inp, gp)
        if not gp and inp.KeyCode == toggleKey then
            Main.Visible = not Main.Visible
        end
    end)

    -- ── Resize (canto inferior direito)
    local ResizeHandle = New("TextButton", {
        Size = UDim2.new(0,14,0,14), AnchorPoint = Vector2.new(1,1),
        Position = UDim2.new(1,-2,1,-2), BackgroundTransparency = 1,
        Text = "", ZIndex = 10,
    }, Main)
    -- triângulo decorativo
    New("Frame", {
        Size = UDim2.new(0,8,0,1), Position = UDim2.new(0,2,0,10),
        BackgroundColor3 = Theme.TextHint, BorderSizePixel = 0,
    }, ResizeHandle)
    New("Frame", {
        Size = UDim2.new(0,4,0,1), Position = UDim2.new(0,6,0,7),
        BackgroundColor3 = Theme.TextHint, BorderSizePixel = 0,
    }, ResizeHandle)

    local resizing = false
    local resizeStart, startSize
    ResizeHandle.MouseButton1Down:Connect(function()
        resizing = true
        resizeStart = UserInputService:GetMouseLocation()
        startSize   = Main.AbsoluteSize
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then resizing = false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if resizing and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local cur = UserInputService:GetMouseLocation()
            local dx  = cur.X - resizeStart.X
            local dy  = cur.Y - resizeStart.Y
            local nw  = math.clamp(startSize.X + dx, 520, 1200)
            local nh  = math.clamp(startSize.Y + dy, 360, 800)
            Main.Size = UDim2.new(0, nw, 0, nh)
            Shadow.Size = UDim2.new(0, nw+6, 0, nh+6)
        end
    end)

    -- ── Sidebar
    local Sidebar = New("Frame", {
        Name = "Sidebar", Position = UDim2.new(0,0,0,42),
        Size = UDim2.new(0,160,1,-42),
        BackgroundColor3 = Theme.Surface,
    }, Main)
    Stroke(Theme.Border, 0.5, Sidebar)

    -- Search
    local SearchFrame = New("Frame", {
        Size = UDim2.new(1,-18,0,30), Position = UDim2.new(0,9,0,10),
        BackgroundColor3 = Theme.InputBg,
    }, Sidebar)
    Corner(8, SearchFrame)
    Stroke(Theme.Border, 0.5, SearchFrame)

    -- ícone lupa
    local SearchIcon = New("TextLabel", {
        Size = UDim2.new(0,20,1,0), Position = UDim2.new(0,8,0,0),
        BackgroundTransparency = 1, Text = "⌕",
        TextColor3 = Theme.TextMuted, TextSize = 16,
        Font = Enum.Font.Gotham,
    }, SearchFrame)

    local SearchBox = New("TextBox", {
        Size = UDim2.new(1,-32,1,0), Position = UDim2.new(0,30,0,0),
        BackgroundTransparency = 1, PlaceholderText = "Search",
        PlaceholderColor3 = Theme.TextMuted,
        Text = "", TextColor3 = Theme.TextPrimary,
        Font = Enum.Font.Gotham, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
    }, SearchFrame)

    -- Container nav
    local NavScroll = New("ScrollingFrame", {
        Position = UDim2.new(0,0,0,50), Size = UDim2.new(1,0,1,-90),
        BackgroundTransparency = 1, ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
    }, Sidebar)
    List(0, NavScroll)

    -- Footer sidebar — personagem
    local SideFooter = New("Frame", {
        AnchorPoint = Vector2.new(0,1), Position = UDim2.new(0,0,1,0),
        Size = UDim2.new(1,0,0,52),
        BackgroundColor3 = Theme.Surface,
    }, Sidebar)
    New("Frame", {
        Size = UDim2.new(1,0,0,0.5), BackgroundColor3 = Theme.Border,
    }, SideFooter)
    Padding(0,0,10,10, SideFooter)

    -- Avatar frame (placeholder redondo)
    local AvatarFrame = New("Frame", {
        Size = UDim2.new(0,36,0,36), Position = UDim2.new(0,0,0.5,-18),
        BackgroundColor3 = Theme.InputBg,
    }, SideFooter)
    Corner(18, AvatarFrame)
    Stroke(Theme.Border, 0.5, AvatarFrame)

    -- Imagem do avatar
    local AvatarImg = New("ImageLabel", {
        Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
        Image = "", ScaleType = Enum.ScaleType.Crop,
    }, AvatarFrame)
    Corner(18, AvatarImg)

    -- Puxar thumbnail do personagem
    task.spawn(function()
        local thumb = GetAvatarThumb(LocalPlayer.UserId)
        if thumb then AvatarImg.Image = thumb end
    end)

    -- Nome + @
    New("TextLabel", {
        Size = UDim2.new(1,-46,0,18), Position = UDim2.new(0,44,0,6),
        BackgroundTransparency = 1, Text = LocalPlayer.DisplayName,
        Font = Enum.Font.GothamMedium, TextSize = 12,
        TextColor3 = Theme.TextPrimary, TextXAlignment = Enum.TextXAlignment.Left,
    }, SideFooter)
    New("TextLabel", {
        Size = UDim2.new(1,-46,0,14), Position = UDim2.new(0,44,0,26),
        BackgroundTransparency = 1, Text = "@"..LocalPlayer.Name,
        Font = Enum.Font.Gotham, TextSize = 10,
        TextColor3 = Theme.TextMuted, TextXAlignment = Enum.TextXAlignment.Left,
    }, SideFooter)

    -- ── Área de conteúdo
    local ContentArea = New("Frame", {
        Position = UDim2.new(0,160,0,42), Size = UDim2.new(1,-160,1,-42),
        BackgroundColor3 = Theme.Background, ClipsDescendants = true,
    }, Main)

    -- ── Estado de abas
    local AllTabs   = {}
    local AllNavBtns = {}
    local ActiveTab = nil

    local function AddNavSectionLabel(name)
        local lbl = New("TextLabel", {
            Size = UDim2.new(1,0,0,22), BackgroundTransparency = 1,
            Text = name:upper(), Font = Enum.Font.GothamMedium,
            TextSize = 9, TextColor3 = Theme.TextHint,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, NavScroll)
        Padding(0,0,12,0, lbl)
    end

    local function SetActiveTab(frame, btn)
        -- Esconde tudo
        for _, f in pairs(AllTabs) do f.Visible = false end
        for _, b in pairs(AllNavBtns) do
            b.BackgroundTransparency = 1
            b.TextColor3 = Theme.TextMuted
            local bar = b:FindFirstChild("_AccentBar")
            if bar then bar:Destroy() end
        end
        -- Ativa
        frame.Visible = true
        btn.BackgroundColor3 = Theme.InputBg
        btn.BackgroundTransparency = 0
        btn.TextColor3 = Theme.TextPrimary
        local bar = New("Frame", {
            Name = "_AccentBar", Size = UDim2.new(0,2,1,0),
            Position = UDim2.new(0,0,0,0),
            BackgroundColor3 = Theme.Accent,
        }, btn)
        ActiveTab = frame
    end

    -- Filtro de search
    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local q = SearchBox.Text:lower()
        for _, btn in pairs(AllNavBtns) do
            btn.Visible = q == "" or btn.Text:lower():find(q, 1, true) ~= nil
        end
    end)

    -- ╔══════════════════════════════════════════════════════╗
    -- ║  ABA DE SETTINGS FIXA (sempre presente)             ║
    -- ╚══════════════════════════════════════════════════════╝
    local function BuildSettingsTab()
        -- nav label
        AddNavSectionLabel("Settings")

        local navBtn = New("TextButton", {
            Size = UDim2.new(1,0,0,34), BackgroundTransparency = 1,
            Text = "   Settings", Font = Enum.Font.Gotham,
            TextSize = 12, TextColor3 = Theme.TextMuted,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, NavScroll)

        local TabFrame = New("ScrollingFrame", {
            Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
            Visible = false, ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Border,
            CanvasSize = UDim2.new(0,0,0,0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            BorderSizePixel = 0,
        }, ContentArea)
        Padding(14,14,14,14, TabFrame)
        local lay = List(10, TabFrame)

        table.insert(AllNavBtns, navBtn)
        table.insert(AllTabs, TabFrame)
        navBtn.MouseButton1Click:Connect(function() SetActiveTab(TabFrame, navBtn) end)

        -- ── Helpers locais
        local function SecLabel(txt)
            local f = New("Frame", { Size = UDim2.new(1,0,0,20), BackgroundTransparency = 1 }, TabFrame)
            New("TextLabel", {
                Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
                Text = txt:upper(), Font = Enum.Font.GothamMedium,
                TextSize = 9, TextColor3 = Theme.TextHint,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, f)
        end

        local function Card(h)
            local c = New("Frame", {
                Size = UDim2.new(1,0,0,h), BackgroundColor3 = Theme.Surface,
            }, TabFrame)
            Corner(8, c)
            Stroke(Theme.Border, 0.5, c)
            Padding(0,0,12,12, c)
            return c
        end

        local function Row(parent, label)
            local r = New("Frame", {
                Size = UDim2.new(1,0,0,34), BackgroundTransparency = 1,
            }, parent)
            New("TextLabel", {
                Size = UDim2.new(0.6,0,1,0), BackgroundTransparency = 1,
                Text = label, Font = Enum.Font.Gotham,
                TextSize = 12, TextColor3 = Theme.TextPrimary,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, r)
            return r
        end

        local function Toggle(parent, label, default, cb)
            local state = default or false
            local row = Row(parent, label)
            local track = New("Frame", {
                AnchorPoint = Vector2.new(1,0.5), Position = UDim2.new(1,0,0.5,0),
                Size = UDim2.new(0,38,0,21),
                BackgroundColor3 = state and Theme.AccentGreen or Theme.ToggleOff,
            }, row)
            Corner(11, track)
            local knob = New("Frame", {
                Position = UDim2.new(0, state and 19 or 3, 0.5,-7),
                Size = UDim2.new(0,15,0,15), BackgroundColor3 = Theme.White,
            }, track)
            Corner(8, knob)
            local btn = New("TextButton", {
                Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "",
            }, row)
            btn.MouseButton1Click:Connect(function()
                state = not state
                Tween(track, { BackgroundColor3 = state and Theme.AccentGreen or Theme.ToggleOff })
                Tween(knob, { Position = UDim2.new(0, state and 19 or 3, 0.5,-7) })
                if cb then cb(state) end
            end)
            return function(v)
                state = v
                Tween(track, { BackgroundColor3 = v and Theme.AccentGreen or Theme.ToggleOff })
                Tween(knob, { Position = UDim2.new(0, v and 19 or 3, 0.5,-7) })
                if cb then cb(v) end
            end
        end

        local function FlatBtn(parent, label, cb)
            local btn = New("TextButton", {
                Size = UDim2.new(1,0,0,32),
                BackgroundColor3 = Theme.InputBg,
                Text = label, Font = Enum.Font.GothamMedium,
                TextSize = 12, TextColor3 = Theme.TextPrimary,
                AutoButtonColor = false,
            }, parent)
            Corner(7, btn)
            Stroke(Theme.Border, 0.5, btn)
            btn.MouseButton1Click:Connect(function()
                Tween(btn, { BackgroundColor3 = Theme.Surface }, 0.08)
                task.delay(0.15, function() Tween(btn, { BackgroundColor3 = Theme.InputBg }, 0.1) end)
                if cb then cb() end
            end)
            return btn
        end

        -- ──────────────────────────────────────────────────
        -- SEÇÃO: Interface
        -- ──────────────────────────────────────────────────
        SecLabel("Interface")

        local uiCard = Card(120)
        local uiLayout = List(0, uiCard)

        -- UI Scale
        local scaleRow = New("Frame", { Size = UDim2.new(1,0,0,52), BackgroundTransparency = 1 }, uiCard)
        New("TextLabel", {
            Size = UDim2.new(0.6,0,0,18), BackgroundTransparency = 1,
            Text = "UI Scale", Font = Enum.Font.Gotham,
            TextSize = 12, TextColor3 = Theme.TextPrimary,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, scaleRow)
        local scaleVal = New("TextLabel", {
            AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,0,0,0),
            Size = UDim2.new(0,40,0,18), BackgroundTransparency = 1,
            Text = "100", Font = Enum.Font.GothamMedium,
            TextSize = 12, TextColor3 = Theme.Accent,
            TextXAlignment = Enum.TextXAlignment.Right,
        }, scaleRow)
        local sTrack = New("Frame", {
            Position = UDim2.new(0,0,0,28), Size = UDim2.new(1,0,0,4),
            BackgroundColor3 = Theme.ToggleOff,
        }, scaleRow)
        Corner(2, sTrack)
        local sFill = New("Frame", { Size = UDim2.new(0.5,0,1,0), BackgroundColor3 = Theme.AccentGreen }, sTrack)
        Corner(2, sFill)
        local sThumb = New("Frame", {
            AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0.5,0,0.5,0),
            Size = UDim2.new(0,14,0,14), BackgroundColor3 = Theme.White,
        }, sTrack)
        Corner(7, sThumb)
        local sDrag = New("TextButton", {
            Size = UDim2.new(1,0,4,0), Position = UDim2.new(0,0,-1.5,0),
            BackgroundTransparency = 1, Text = "", ZIndex = 5,
        }, sTrack)
        local sDragging = false
        sDrag.MouseButton1Down:Connect(function() sDragging = true end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then sDragging = false end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if sDragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                local rel = math.clamp((i.Position.X - sTrack.AbsolutePosition.X)/sTrack.AbsoluteSize.X, 0, 1)
                local val = math.floor(50 + (150-50)*rel)
                sFill.Size = UDim2.new(rel,0,1,0)
                sThumb.Position = UDim2.new(rel,0,0.5,0)
                scaleVal.Text = tostring(val)
                -- Aqui você aplicaria a escala real no Main se quiser
            end
        end)

        -- Notificações
        Toggle(uiCard, "Ativar Notificações", true, function(v)
            ForgeLib._NotifsEnabled = v
        end)
        -- Sons de alerta
        Toggle(uiCard, "Sons de Alerta", false, function(v)
            ForgeLib._SoundsEnabled = v
        end)
        uiCard.Size = UDim2.new(1,0,0, 52 + 34 + 34 + 8)

        -- ──────────────────────────────────────────────────
        -- SEÇÃO: Configurações
        -- ──────────────────────────────────────────────────
        SecLabel("Configurações")

        -- Config Name input
        local cfgNameFrame = New("Frame", {
            Size = UDim2.new(1,0,0,30), BackgroundColor3 = Theme.InputBg,
        }, TabFrame)
        Corner(7, cfgNameFrame)
        Stroke(Theme.Border, 0.5, cfgNameFrame)
        local cfgNameBox = New("TextBox", {
            Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
            PlaceholderText = "Nome da config...",
            PlaceholderColor3 = Theme.TextMuted,
            Text = "", TextColor3 = Theme.TextPrimary,
            Font = Enum.Font.Gotham, TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false,
        }, cfgNameFrame)
        Padding(0,0,10,10, cfgNameFrame)

        -- Checkboxes account
        local cfgCard = Card(76)
        local cfgLayout = List(0, cfgCard)
        Toggle(cfgCard, "Account Exclusive", false)
        Toggle(cfgCard, "Account Autoload",  false)

        FlatBtn(TabFrame, "Create Config", function()
            local name = cfgNameBox.Text
            if name == "" then
                ForgeLib:Notify({ Title="Erro", Content="Digite um nome para a config.", Color=Theme.AccentRed })
                return
            end
            SaveConfig(name, { _name = name, _created = os.time() })
            ForgeLib:Notify({ Title="Config criada", Content=name, Color=Theme.AccentGreen })
            cfgNameBox.Text = ""
        end)

        -- Seção config list
        SecLabel("Lista de Configs")

        -- Dropdown config list
        local cfgSelected = "nil"
        local cfgDropBtn = New("TextButton", {
            Size = UDim2.new(1,0,0,30), BackgroundColor3 = Theme.InputBg,
            Text = "", AutoButtonColor = false,
        }, TabFrame)
        Corner(7, cfgDropBtn)
        Stroke(Theme.Border, 0.5, cfgDropBtn)
        Padding(0,0,10,10, cfgDropBtn)
        local cfgDropLabel = New("TextLabel", {
            Size = UDim2.new(1,-20,1,0), BackgroundTransparency = 1,
            Text = cfgSelected, Font = Enum.Font.Gotham,
            TextSize = 12, TextColor3 = Theme.TextPrimary,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, cfgDropBtn)
        New("TextLabel", {
            AnchorPoint = Vector2.new(1,0.5), Position = UDim2.new(1,-10,0.5,0),
            Size = UDim2.new(0,12,0,12), BackgroundTransparency = 1,
            Text = "▾", Font = Enum.Font.Gotham,
            TextSize = 12, TextColor3 = Theme.TextMuted,
        }, cfgDropBtn)

        local cfgListFrame = New("Frame", {
            Size = UDim2.new(1,0,0,0), BackgroundColor3 = Theme.InputBg,
            ClipsDescendants = true, Visible = false,
        }, TabFrame)
        Corner(7, cfgListFrame)
        Stroke(Theme.Border, 0.5, cfgListFrame)
        local cfgListLayout = List(0, cfgListFrame)

        local function RefreshCfgList()
            cfgListFrame:ClearAllChildren()
            List(0, cfgListFrame)
            local configs = ListConfigs()
            table.insert(configs, 1, "nil")
            for _, name in ipairs(configs) do
                local item = New("TextButton", {
                    Size = UDim2.new(1,0,0,28),
                    BackgroundColor3 = name == cfgSelected and Theme.Surface or Theme.InputBg,
                    Text = "", AutoButtonColor = false,
                }, cfgListFrame)
                Padding(0,0,10,0, item)
                New("TextLabel", {
                    Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
                    Text = name, Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextColor3 = name == cfgSelected and Theme.Accent or Theme.TextPrimary,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }, item)
                item.MouseButton1Click:Connect(function()
                    cfgSelected = name
                    cfgDropLabel.Text = name
                    cfgListFrame.Visible = false
                end)
            end
            cfgListFrame.Size = UDim2.new(1,0,0,#configs*28)
        end

        cfgDropBtn.MouseButton1Click:Connect(function()
            cfgListFrame.Visible = not cfgListFrame.Visible
            if cfgListFrame.Visible then RefreshCfgList() end
        end)

        -- Botões de ação de config
        local btnCfgCard = Card(168)
        local btnCfgLayout = List(6, btnCfgCard)

        FlatBtn(btnCfgCard, "Load Config", function()
            if cfgSelected == "nil" then
                ForgeLib:Notify({ Title="Erro", Content="Selecione uma config.", Color=Theme.AccentRed })
                return
            end
            local data = LoadConfig(cfgSelected)
            ForgeLib:Notify({ Title="Config carregada", Content=cfgSelected })
        end)
        FlatBtn(btnCfgCard, "Overwrite Config", function()
            if cfgSelected == "nil" then return end
            SaveConfig(cfgSelected, { _name=cfgSelected, _updated=os.time() })
            ForgeLib:Notify({ Title="Config sobrescrita", Content=cfgSelected })
        end)
        FlatBtn(btnCfgCard, "Delete Config", function()
            if cfgSelected == "nil" then return end
            ConfigStore[cfgSelected] = nil
            cfgSelected = "nil"
            cfgDropLabel.Text = "nil"
            ForgeLib:Notify({ Title="Config deletada", Color=Theme.AccentRed })
        end)
        FlatBtn(btnCfgCard, "Refresh List", function()
            RefreshCfgList()
            ForgeLib:Notify({ Title="Lista atualizada" })
        end)

        local autoCard = Card(108)
        local autoLayout = List(6, autoCard)

        FlatBtn(autoCard, "Set as Normal Autoload", function()
            ForgeLib._NormalAutoload = cfgSelected
            ForgeLib:Notify({ Title="Autoload definido", Content=cfgSelected })
        end)
        FlatBtn(autoCard, "Set as Account Autoload", function()
            ForgeLib._AccountAutoload = cfgSelected
            ForgeLib:Notify({ Title="Account Autoload definido", Content=cfgSelected })
        end)
        FlatBtn(autoCard, "Reset Autoloads", function()
            ForgeLib._NormalAutoload  = nil
            ForgeLib._AccountAutoload = nil
            ForgeLib:Notify({ Title="Autoloads resetados", Color=Theme.AccentRed })
        end)

        -- Info autoload
        local autoInfoLabel = New("TextLabel", {
            Size = UDim2.new(1,0,0,20), BackgroundTransparency = 1,
            Text = "Autoload: none (None)", Font = Enum.Font.Gotham,
            TextSize = 10, TextColor3 = Theme.TextHint,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, TabFrame)

        RunService.Heartbeat:Connect(function()
            local n = ForgeLib._NormalAutoload  or "none"
            local a = ForgeLib._AccountAutoload or "None"
            autoInfoLabel.Text = ("Autoload: %s (%s)"):format(n, a)
        end)
    end

    -- Constrói a aba settings fixa
    BuildSettingsTab()

    -- ══════════════════════════════════════════════════════
    -- OBJETO WINDOW retornado ao script do jogo
    -- ══════════════════════════════════════════════════════
    local WindowObj  = {}
    local tabSection = nil
    local sectionAdded = false

    -- Label "Main" antes da primeira aba do usuário
    local mainLabelAdded = false

    function WindowObj:CreateTab(name, section)
        -- Insere a label de seção antes das abas do usuário
        if not mainLabelAdded then
            -- Insere antes da label "Settings"
            -- (recria a ordem: injeta label Main no topo do NavScroll)
            local lbl = New("TextLabel", {
                Size = UDim2.new(1,0,0,22), BackgroundTransparency = 1,
                Text = "MAIN", Font = Enum.Font.GothamMedium,
                TextSize = 9, TextColor3 = Theme.TextHint,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = -100,
            }, NavScroll)
            Padding(0,0,12,0, lbl)
            mainLabelAdded = true
        end

        -- Seção customizada opcional
        if section and section ~= tabSection then
            tabSection = section
            local lbl2 = New("TextLabel", {
                Size = UDim2.new(1,0,0,22), BackgroundTransparency = 1,
                Text = section:upper(), Font = Enum.Font.GothamMedium,
                TextSize = 9, TextColor3 = Theme.TextHint,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = #AllNavBtns,
            }, NavScroll)
            Padding(0,0,12,0, lbl2)
        end

        local navBtn = New("TextButton", {
            Size = UDim2.new(1,0,0,34), BackgroundTransparency = 1,
            Text = "   "..name, Font = Enum.Font.Gotham,
            TextSize = 12, TextColor3 = Theme.TextMuted,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = #AllNavBtns + 1,
        }, NavScroll)

        local TabFrame = New("ScrollingFrame", {
            Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
            Visible = false, ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Border,
            CanvasSize = UDim2.new(0,0,0,0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            BorderSizePixel = 0,
        }, ContentArea)
        Padding(14,14,14,14, TabFrame)
        List(10, TabFrame)

        table.insert(AllNavBtns, navBtn)
        table.insert(AllTabs, TabFrame)

        -- Primeira aba criada fica ativa por padrão
        if #AllTabs == 2 then -- 1 = settings, 2 = primeira do user
            SetActiveTab(TabFrame, navBtn)
        end

        navBtn.MouseButton1Click:Connect(function()
            SetActiveTab(TabFrame, navBtn)
        end)

        -- ─────────────────────────────────────────────────
        -- OBJETO TAB (componentes disponíveis ao dev)
        -- ─────────────────────────────────────────────────
        local TabObj = {}

        local function MakeRow(h)
            local r = New("Frame", {
                Size = UDim2.new(1,0,0,h or 36),
                BackgroundColor3 = Theme.Surface,
            }, TabFrame)
            Corner(8, r)
            Stroke(Theme.Border, 0.5, r)
            Padding(0,0,12,12, r)
            return r
        end

        local function MakeLabel(parent, text)
            return New("TextLabel", {
                Size = UDim2.new(0.65,0,1,0), BackgroundTransparency = 1,
                Text = text, Font = Enum.Font.Gotham, TextSize = 12,
                TextColor3 = Theme.TextPrimary, TextXAlignment = Enum.TextXAlignment.Left,
            }, parent)
        end

        -- CreateSection
        function TabObj:CreateSection(text)
            local sec = New("Frame", { Size = UDim2.new(1,0,0,20), BackgroundTransparency = 1 }, TabFrame)
            New("TextLabel", {
                Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
                Text = text:upper(), Font = Enum.Font.GothamMedium,
                TextSize = 9, TextColor3 = Theme.TextHint,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, sec)
            New("Frame", {
                AnchorPoint = Vector2.new(0,0.5), Position = UDim2.new(0,0,1,0),
                Size = UDim2.new(1,0,0,0.5), BackgroundColor3 = Theme.Border,
            }, sec)
        end

        -- CreateToggle
        function TabObj:CreateToggle(opts)
            opts = opts or {}
            local state = opts.Default or false
            local row = MakeRow(36)
            MakeLabel(row, opts.Name or "Toggle")

            if opts.Keybind then
                local kb = New("TextLabel", {
                    AnchorPoint = Vector2.new(1,0.5), Position = UDim2.new(1,-48,0.5,0),
                    Size = UDim2.new(0,44,0,18), BackgroundColor3 = Theme.InputBg,
                    Text = opts.Keybind, Font = Enum.Font.GothamMedium,
                    TextSize = 10, TextColor3 = Theme.TextMuted,
                }, row)
                Corner(4, kb)
                Stroke(Theme.Border, 0.5, kb)
            end

            local track = New("Frame", {
                AnchorPoint = Vector2.new(1,0.5), Position = UDim2.new(1,0,0.5,0),
                Size = UDim2.new(0,38,0,21),
                BackgroundColor3 = state and Theme.AccentGreen or Theme.ToggleOff,
            }, row)
            Corner(11, track)
            local knob = New("Frame", {
                Position = UDim2.new(0, state and 19 or 3, 0.5,-7),
                Size = UDim2.new(0,15,0,15), BackgroundColor3 = Theme.White,
            }, track)
            Corner(8, knob)
            local btn = New("TextButton", { Size = UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="" }, row)

            local function SetState(v)
                state = v
                Tween(track, { BackgroundColor3 = v and Theme.AccentGreen or Theme.ToggleOff })
                Tween(knob,  { Position = UDim2.new(0, v and 19 or 3, 0.5,-7) })
                if opts.Callback then opts.Callback(v) end
                if opts.Flag then _G["FL_"..opts.Flag] = v end
            end
            btn.MouseButton1Click:Connect(function() SetState(not state) end)
            return { SetState=SetState, GetState=function() return state end }
        end

        -- CreateSlider
        function TabObj:CreateSlider(opts)
            opts = opts or {}
            local min = opts.Min or 0
            local max = opts.Max or 100
            local dec = opts.Decimals
            local current = opts.Default or min

            local row = MakeRow(52)
            New("TextLabel", {
                Size = UDim2.new(0.7,0,0,18), BackgroundTransparency=1,
                Text = opts.Name or "Slider", Font=Enum.Font.Gotham,
                TextSize=12, TextColor3=Theme.TextPrimary,
                TextXAlignment=Enum.TextXAlignment.Left,
            }, row)
            local valLbl = New("TextLabel", {
                AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,0,0,0),
                Size=UDim2.new(0,50,0,18), BackgroundTransparency=1,
                Text=tostring(current), Font=Enum.Font.GothamMedium,
                TextSize=12, TextColor3=Theme.Accent,
                TextXAlignment=Enum.TextXAlignment.Right,
            }, row)
            local track = New("Frame", {
                Position=UDim2.new(0,0,0,28), Size=UDim2.new(1,0,0,4),
                BackgroundColor3=Theme.ToggleOff,
            }, row)
            Corner(2,track)
            local fill = New("Frame", {
                Size=UDim2.new((current-min)/(max-min),0,1,0),
                BackgroundColor3=Theme.AccentGreen,
            }, track)
            Corner(2,fill)
            local thumb = New("Frame", {
                AnchorPoint=Vector2.new(0.5,0.5),
                Position=UDim2.new((current-min)/(max-min),0,0.5,0),
                Size=UDim2.new(0,14,0,14), BackgroundColor3=Theme.White,
            }, track)
            Corner(7,thumb)
            local sliderBtn = New("TextButton", {
                Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", ZIndex=5,
            }, track)

            local sdrag = false
            local function Update(inp)
                local rel = math.clamp((inp.Position.X - track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
                local val = dec
                    and tonumber(("%."..(dec).."f"):format(min+(max-min)*rel))
                    or math.floor(min+(max-min)*rel)
                current = val
                fill.Size = UDim2.new(rel,0,1,0)
                thumb.Position = UDim2.new(rel,0,0.5,0)
                valLbl.Text = tostring(val)
                if opts.Callback then opts.Callback(val) end
                if opts.Flag then _G["FL_"..opts.Flag] = val end
            end
            sliderBtn.MouseButton1Down:Connect(function() sdrag=true end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 then sdrag=false end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if sdrag and i.UserInputType==Enum.UserInputType.MouseMovement then Update(i) end
            end)

            local function SetValue(v)
                current = v
                local rel = math.clamp((v-min)/(max-min),0,1)
                fill.Size = UDim2.new(rel,0,1,0)
                thumb.Position = UDim2.new(rel,0,0.5,0)
                valLbl.Text = tostring(v)
            end
            return { SetValue=SetValue, GetValue=function() return current end }
        end

        -- CreateDropdown
        function TabObj:CreateDropdown(opts)
            opts = opts or {}
            local items    = opts.Items or {}
            local selected = opts.Default or (items[1] or "")
            local open     = false

            local container = New("Frame", { Size=UDim2.new(1,0,0,62), BackgroundTransparency=1 }, TabFrame)
            List(4, container)
            New("TextLabel", {
                Size=UDim2.new(1,0,0,16), BackgroundTransparency=1,
                Text=opts.Name or "Dropdown", Font=Enum.Font.Gotham,
                TextSize=12, TextColor3=Theme.TextPrimary,
                TextXAlignment=Enum.TextXAlignment.Left,
            }, container)
            local dropBtn = New("TextButton", {
                Size=UDim2.new(1,0,0,30), BackgroundColor3=Theme.InputBg,
                Text="", AutoButtonColor=false,
            }, container)
            Corner(7,dropBtn); Stroke(Theme.Border,0.5,dropBtn); Padding(0,0,10,10,dropBtn)
            local selLbl = New("TextLabel", {
                Size=UDim2.new(1,-20,1,0), BackgroundTransparency=1,
                Text=selected, Font=Enum.Font.Gotham, TextSize=12,
                TextColor3=Theme.TextPrimary, TextXAlignment=Enum.TextXAlignment.Left,
            }, dropBtn)
            New("TextLabel", {
                AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-10,0.5,0),
                Size=UDim2.new(0,12,0,12), BackgroundTransparency=1,
                Text="▾", Font=Enum.Font.Gotham, TextSize=12, TextColor3=Theme.TextMuted,
            }, dropBtn)
            local listFrame = New("Frame", {
                Size=UDim2.new(1,0,0,0), BackgroundColor3=Theme.InputBg,
                ClipsDescendants=true, Visible=false,
            }, container)
            Corner(7,listFrame); Stroke(Theme.Border,0.5,listFrame); List(0,listFrame)

            local function Build()
                for _,item in ipairs(items) do
                    local ib = New("TextButton", {
                        Size=UDim2.new(1,0,0,28),
                        BackgroundColor3=item==selected and Theme.Surface or Theme.InputBg,
                        Text="", AutoButtonColor=false,
                    }, listFrame)
                    Padding(0,0,10,0,ib)
                    New("TextLabel", {
                        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
                        Text=item, Font=Enum.Font.Gotham, TextSize=12,
                        TextColor3=item==selected and Theme.Accent or Theme.TextPrimary,
                        TextXAlignment=Enum.TextXAlignment.Left,
                    }, ib)
                    ib.MouseButton1Click:Connect(function()
                        selected=item; selLbl.Text=item
                        open=false; listFrame.Visible=false
                        container.Size=UDim2.new(1,0,0,62)
                        if opts.Callback then opts.Callback(item) end
                        if opts.Flag then _G["FL_"..opts.Flag]=item end
                        listFrame:ClearAllChildren(); List(0,listFrame); Build()
                    end)
                end
                local h=#items*28
                listFrame.Size=UDim2.new(1,0,0,h)
                container.Size=UDim2.new(1,0,0,62+h+4)
            end
            dropBtn.MouseButton1Click:Connect(function()
                open=not open; listFrame.Visible=open
                if open then listFrame:ClearAllChildren(); List(0,listFrame); Build()
                else container.Size=UDim2.new(1,0,0,62) end
            end)
            return { GetSelected=function() return selected end,
                     SetItems=function(t) items=t; selected=t[1] or ""; selLbl.Text=selected end }
        end

        -- CreateButton
        function TabObj:CreateButton(opts)
            opts = opts or {}
            local styles = {
                primary   = { bg=Color3.fromRGB(46,26,110),  text=Color3.fromRGB(167,139,250) },
                success   = { bg=Color3.fromRGB(20,83,45),   text=Color3.fromRGB(74,222,128)  },
                danger    = { bg=Color3.fromRGB(69,26,26),   text=Color3.fromRGB(248,113,113) },
                secondary = { bg=Theme.InputBg,              text=Theme.TextMuted             },
            }
            local c = styles[opts.Style or "primary"] or styles.primary
            local row = MakeRow(36)
            local btn = New("TextButton", {
                Size=UDim2.new(1,0,1,0), BackgroundColor3=c.bg,
                Text=opts.Name or "Button", Font=Enum.Font.GothamMedium,
                TextSize=12, TextColor3=c.text, AutoButtonColor=false,
            }, row)
            Corner(7,btn)
            btn.MouseButton1Click:Connect(function()
                Tween(btn,{BackgroundTransparency=0.3},0.07)
                task.delay(0.15,function() Tween(btn,{BackgroundTransparency=0},0.1) end)
                if opts.Callback then opts.Callback() end
            end)
            return { SetText=function(t) btn.Text=t end }
        end

        -- CreateInput
        function TabObj:CreateInput(opts)
            opts = opts or {}
            local cont = New("Frame", { Size=UDim2.new(1,0,0,56), BackgroundTransparency=1 }, TabFrame)
            List(4,cont)
            New("TextLabel", {
                Size=UDim2.new(1,0,0,16), BackgroundTransparency=1,
                Text=opts.Name or "Input", Font=Enum.Font.Gotham,
                TextSize=12, TextColor3=Theme.TextPrimary,
                TextXAlignment=Enum.TextXAlignment.Left,
            }, cont)
            local inp = New("Frame", { Size=UDim2.new(1,0,0,30), BackgroundColor3=Theme.InputBg }, cont)
            Corner(7,inp); Stroke(Theme.Border,0.5,inp); Padding(0,0,10,10,inp)
            local tb = New("TextBox", {
                Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
                PlaceholderText=opts.Placeholder or "Digite aqui...",
                PlaceholderColor3=Theme.TextMuted, Text=opts.Default or "",
                TextColor3=Theme.TextPrimary, Font=Enum.Font.Gotham,
                TextSize=12, TextXAlignment=Enum.TextXAlignment.Left,
                ClearTextOnFocus=false,
            }, inp)
            tb.FocusLost:Connect(function(enter)
                if enter and opts.Callback then opts.Callback(tb.Text) end
                if opts.Flag then _G["FL_"..opts.Flag]=tb.Text end
            end)
            return { GetValue=function() return tb.Text end, SetValue=function(v) tb.Text=v end }
        end

        -- CreateKeybind
        function TabObj:CreateKeybind(opts)
            opts = opts or {}
            local key = opts.Default or Enum.KeyCode.Unknown
            local listening = false
            local row = MakeRow(36)
            MakeLabel(row, opts.Name or "Keybind")
            local kBtn = New("TextButton", {
                AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,0,0.5,0),
                Size=UDim2.new(0,80,0,24), BackgroundColor3=Theme.InputBg,
                Text=key.Name or "NONE", Font=Enum.Font.GothamMedium,
                TextSize=11, TextColor3=Theme.Accent, AutoButtonColor=false,
            }, row)
            Corner(5,kBtn); Stroke(Theme.Border,0.5,kBtn)
            kBtn.MouseButton1Click:Connect(function()
                listening=true; kBtn.Text="..."; kBtn.TextColor3=Theme.TextMuted
            end)
            UserInputService.InputBegan:Connect(function(inp,gp)
                if listening and not gp then
                    listening=false; key=inp.KeyCode
                    kBtn.Text=key.Name; kBtn.TextColor3=Theme.Accent
                    if opts.Callback then opts.Callback(key) end
                    if opts.Flag then _G["FL_"..opts.Flag]=key end
                end
            end)
            return { GetKey=function() return key end }
        end

        -- CreateLabel
        function TabObj:CreateLabel(opts)
            opts = opts or {}
            local lbl = New("TextLabel", {
                Size=UDim2.new(1,0,0,24), BackgroundTransparency=1,
                Text=opts.Text or "", Font=Enum.Font.Gotham, TextSize=12,
                TextColor3=opts.Color or Theme.TextMuted,
                TextXAlignment=Enum.TextXAlignment.Left, RichText=true,
            }, TabFrame)
            return { SetText=function(t) lbl.Text=t end }
        end

        -- CreateInfo
        function TabObj:CreateInfo(opts)
            opts = opts or {}
            local lines = opts.Lines or {}
            local box = New("Frame", {
                Size=UDim2.new(1,0,0,14+#lines*18),
                BackgroundColor3=Color3.fromRGB(16,16,24),
            }, TabFrame)
            Corner(8,box); Stroke(Color3.fromRGB(36,36,56),0.5,box)
            Padding(8,8,12,12,box); List(2,box)
            for _,line in ipairs(lines) do
                New("TextLabel", {
                    Size=UDim2.new(1,0,0,16), BackgroundTransparency=1,
                    Text=line, Font=Enum.Font.Gotham, TextSize=11,
                    TextColor3=Theme.TextMuted,
                    TextXAlignment=Enum.TextXAlignment.Left, RichText=true,
                }, box)
            end
        end

        return TabObj
    end

    function WindowObj:Destroy()
        ScreenGui:Destroy()
    end

    return WindowObj
end

-- ============================================================
-- FLAGS GLOBAIS
-- ============================================================
ForgeLib._NotifsEnabled   = true
ForgeLib._SoundsEnabled   = false
ForgeLib._NormalAutoload  = nil
ForgeLib._AccountAutoload = nil

return ForgeLib
