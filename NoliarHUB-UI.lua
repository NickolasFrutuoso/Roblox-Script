--[[
╔══════════════════════════════════════════════════════════╗
║              ForgeLib — UI Library for Roblox            ║
║              Style: Seisen / Rayfield                    ║
║              v2.3.0 — Layout & Keybind Fix               ║
║                                                          ║
║  FIXES v2.3:                                             ║
║  • Grid buttons: layout absoluto, texto/ícone sem vazar  ║
║  • Keybind funcional em TODOS os elementos:              ║
║    Toggle → liga/desliga, Button → executa callback      ║
║    Slider → nenhuma ação (keybind visual apenas)         ║
║  • Notificações: respeitam _NotifsEnabled corretamente   ║
║  • Animação de fechar: slide lateral suave (sem resize)  ║
║  • MakeBlock: padding absoluto, texto nunca vaza borda   ║
║  • ButtonStyles.secondary.bg: Color3 resolvido           ║
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
-- ÍCONES
-- ============================================================
local Icons = {
    Play       = "▶",  Pause      = "⏸",  Stop       = "⏹",
    Refresh    = "↺",  Search     = "⌕",  Settings   = "⚙",
    Close      = "✕",  Check      = "✓",  Plus       = "+",
    Minus      = "−",  Edit       = "✎",  Delete     = "🗑",
    Copy       = "⎘",  Download   = "↓",  Upload     = "↑",
    Link       = "⛓",  Star       = "★",  Heart      = "♥",
    Flag       = "⚑",  Lock       = "🔒", Unlock     = "🔓",
    Eye        = "👁",  EyeOff     = "🙈",
    Sword      = "⚔",  Shield     = "🛡", Farm       = "🌾",
    Speed      = "⚡",  Aim        = "🎯", Map        = "🗺",
    Bag        = "🎒",  Gem        = "💎", Fire       = "🔥",
    Ghost      = "👻",  Robot      = "🤖", Skull      = "💀",
    Crown      = "👑",  Key        = "🔑",
    Arrow      = "→",  ArrowLeft  = "←",  ArrowUp    = "↑",
    ArrowDown  = "↓",  Chevron    = "›",  ChevronDown= "▾",
    Dot        = "•",  Circle     = "○",  CircleFill = "●",
    Square     = "□",  SquareFill = "■",  Diamond    = "◆",
    Triangle   = "▲",
    Info       = "i",
    Warning    = "!",  Error      = "x",  Success    = "ok",
    Bell       = "🔔",  BellOff    = "🔕",
    User       = "👤",  Users      = "👥", Person     = "🧑",
}

-- ============================================================
-- TEMA
-- ============================================================
local Theme = {
    Background   = Color3.fromRGB(12, 12, 16),
    Surface      = Color3.fromRGB(18, 18, 24),
    Surface2     = Color3.fromRGB(24, 24, 32),
    Surface3     = Color3.fromRGB(30, 30, 40),
    Border       = Color3.fromRGB(36, 36, 48),
    BorderHover  = Color3.fromRGB(60, 60, 80),
    Accent       = Color3.fromRGB(124, 106, 247),
    AccentDim    = Color3.fromRGB(60, 48, 140),
    AccentGlow   = Color3.fromRGB(90, 72, 200),
    AccentGreen  = Color3.fromRGB(34, 197, 94),
    AccentGreenDim = Color3.fromRGB(20, 80, 45),
    AccentRed    = Color3.fromRGB(239, 68, 68),
    AccentRedDim = Color3.fromRGB(90, 26, 26),
    AccentYellow = Color3.fromRGB(234, 179, 8),
    TextPrimary  = Color3.fromRGB(210, 210, 218),
    TextSecondary= Color3.fromRGB(140, 140, 155),
    TextMuted    = Color3.fromRGB(80, 80, 95),
    TextHint     = Color3.fromRGB(44, 44, 58),
    InputBg      = Color3.fromRGB(20, 20, 28),
    ToggleOff    = Color3.fromRGB(36, 36, 50),
    White        = Color3.fromRGB(255, 255, 255),
    NavActive    = Color3.fromRGB(22, 20, 40),
    NavHover     = Color3.fromRGB(20, 20, 30),
}

-- ButtonStyles declarados após Theme para que referências a Theme sejam válidas
local ButtonStyles = {
    primary   = {
        bg     = Color3.fromRGB(36, 24, 100),
        text   = Color3.fromRGB(167, 139, 250),
        border = Color3.fromRGB(80, 60, 180),
        hover  = Color3.fromRGB(48, 34, 120),
    },
    success   = {
        bg     = Color3.fromRGB(16, 64, 36),
        text   = Color3.fromRGB(74, 222, 128),
        border = Color3.fromRGB(34, 140, 70),
        hover  = Color3.fromRGB(22, 80, 46),
    },
    danger    = {
        bg     = Color3.fromRGB(60, 20, 20),
        text   = Color3.fromRGB(248, 113, 113),
        border = Color3.fromRGB(160, 40, 40),
        hover  = Color3.fromRGB(76, 28, 28),
    },
    secondary = {
        bg     = Color3.fromRGB(20, 20, 28),  -- mesmo que Theme.InputBg mas sem referência tardia
        text   = Color3.fromRGB(140, 140, 155),
        border = Color3.fromRGB(36, 36, 48),
        hover  = Color3.fromRGB(24, 24, 32),
    },
    ghost     = {
        bg     = Color3.fromRGB(16, 16, 22),
        text   = Color3.fromRGB(80, 80, 95),
        border = Color3.fromRGB(36, 36, 48),
        hover  = Color3.fromRGB(18, 18, 24),
    },
}

-- ============================================================
-- UTILITÁRIOS
-- ============================================================
local function Tween(obj, props, t, style, dir)
    TweenService:Create(obj, TweenInfo.new(
        t or 0.15,
        style or Enum.EasingStyle.Quad,
        dir or Enum.EasingDirection.Out
    ), props):Play()
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

local function Stroke(color, thick, p, transp)
    return New("UIStroke", {
        Color = color or Theme.Border,
        Thickness = thick or 0.5,
        Transparency = transp or 0,
    }, p)
end

local function Padding(t, b, l, r, p)
    return New("UIPadding", {
        PaddingTop    = UDim.new(0, t or 0),
        PaddingBottom = UDim.new(0, b or 0),
        PaddingLeft   = UDim.new(0, l or 0),
        PaddingRight  = UDim.new(0, r or 0),
    }, p)
end

local function List(spacing, p, dir)
    return New("UIListLayout", {
        SortOrder           = Enum.SortOrder.LayoutOrder,
        Padding             = UDim.new(0, spacing or 0),
        FillDirection       = dir or Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
    }, p)
end

local function AddHover(btn, normalBg, hoverBg)
    btn.MouseEnter:Connect(function()
        Tween(btn, { BackgroundColor3 = hoverBg }, 0.1)
    end)
    btn.MouseLeave:Connect(function()
        Tween(btn, { BackgroundColor3 = normalBg }, 0.1)
    end)
end

-- FIX #2: Sanitiza texto removendo unicode problemático mas mantendo RichText
local function SanitizeRich(text)
    -- Remove caracteres que quebram RichText mas mantém tags HTML
    return tostring(text or "")
end

-- ============================================================
-- FIX #3: Keybind inline universal — retorna badge e getter
-- ============================================================
local function MakeInlineKeybind(parent, defaultKey, onChanged, rightOffset)
    local key       = defaultKey
    local listening = false
    rightOffset = rightOffset or 0

    local kName = key and key.Name or "..."
    local kBadge = New("TextButton", {
        AnchorPoint    = Vector2.new(1, 0.5),
        Position       = UDim2.new(1, -(rightOffset), 0.5, 0),
        Size           = UDim2.new(0, 46, 0, 22),
        BackgroundColor3 = Theme.InputBg,
        Text           = kName,
        Font           = Enum.Font.GothamMedium,
        TextSize       = 9,
        TextColor3     = Theme.Accent,
        AutoButtonColor = false,
        ZIndex         = 5,
        TextTruncate   = Enum.TextTruncate.AtEnd,
    }, parent)
    Corner(5, kBadge)
    Stroke(Theme.Accent, 0.5, kBadge, 0.5)

    kBadge.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        kBadge.Text = "..."
        kBadge.TextColor3 = Theme.TextMuted
        Tween(kBadge, { BackgroundColor3 = Theme.Surface2 }, 0.1)
    end)

    UserInputService.InputBegan:Connect(function(inp, gp)
        if not listening or gp then return end
        if inp.KeyCode == Enum.KeyCode.Escape then
            listening = false
            kBadge.Text = key and key.Name or "..."
            kBadge.TextColor3 = Theme.Accent
            Tween(kBadge, { BackgroundColor3 = Theme.InputBg }, 0.1)
            return
        end
        if inp.UserInputType == Enum.UserInputType.Keyboard then
            listening = false
            key = inp.KeyCode
            kBadge.Text = key.Name
            kBadge.TextColor3 = Theme.Accent
            Tween(kBadge, { BackgroundColor3 = Theme.InputBg }, 0.1)
            if onChanged then onChanged(key) end
        end
    end)

    return kBadge, function() return key end
end

-- ============================================================
-- AVATAR
-- ============================================================
local function GetAvatarThumb(userId)
    local ok, url = pcall(function()
        return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
    end)
    return ok and url or nil
end

-- ============================================================
-- SAVE / LOAD CONFIG
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
-- FIX #6: NOTIFICAÇÕES — fade simples sem animação bugada
-- ============================================================
local NotifHolder

local function EnsureNotifHolder()
    if NotifHolder and NotifHolder.Parent then return end
    local sg = New("ScreenGui", {
        Name = "ForgeLib_Notifs", ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, PlayerGui)
    NotifHolder = New("Frame", {
        Name = "Holder", AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -16, 1, -16),
        Size = UDim2.new(0, 300, 1, 0), BackgroundTransparency = 1,
    }, sg)
    local l = List(8, NotifHolder)
    l.VerticalAlignment = Enum.VerticalAlignment.Bottom
end

-- ============================================================
-- FORGELIB
-- ============================================================
local ForgeLib = {}
ForgeLib.__index = ForgeLib
ForgeLib.Icons = Icons

-- FIX v2.3: Notificação respeita _NotifsEnabled
function ForgeLib:Notify(opts)
    -- FIX: verificar flag ANTES de criar qualquer frame
    if ForgeLib._NotifsEnabled == false then return end
    opts = opts or {}
    EnsureNotifHolder()
    local title    = opts.Title or "Aviso"
    local content  = opts.Content or ""
    local duration = opts.Duration or 4
    local color    = opts.Color or Theme.Accent
    local icon     = opts.Icon or "i"

    -- Wrapper com altura fixa para não bugar layout
    local wrapper = New("Frame", {
        Size = UDim2.new(1, 0, 0, 68),
        BackgroundTransparency = 1,
        ClipsDescendants = false,
    }, NotifHolder)

    local card = New("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Theme.Surface,
        BackgroundTransparency = 1,
    }, wrapper)
    Corner(10, card)
    Stroke(Theme.Border, 0.5, card)
    Padding(10, 10, 14, 14, card)

    -- Barra lateral colorida
    local bar = New("Frame", {
        Size = UDim2.new(0, 3, 0.7, 0), AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, -14, 0.5, 0),
        BackgroundColor3 = color, BorderSizePixel = 0,
    }, card)
    Corner(2, bar)

    -- Ícone
    local iconFrame = New("Frame", {
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(0, 0, 0.5, -14),
        BackgroundColor3 = Color3.fromRGB(
            math.clamp(math.floor(color.R*255*0.18), 0, 255),
            math.clamp(math.floor(color.G*255*0.18), 0, 255),
            math.clamp(math.floor(color.B*255*0.18), 0, 255)
        ),
    }, card)
    Corner(8, iconFrame)
    New("TextLabel", {
        Size = UDim2.new(1,0,1,0), BackgroundTransparency=1,
        Text = icon, TextSize = 13,
        TextColor3 = color, Font = Enum.Font.GothamBold,
        RichText = false,
        TextXAlignment = Enum.TextXAlignment.Center,
    }, iconFrame)

    -- Título
    New("TextLabel", {
        Size = UDim2.new(1, -38, 0, 18),
        Position = UDim2.new(0, 36, 0, 4),
        BackgroundTransparency = 1, Text = title,
        TextColor3 = Theme.TextPrimary, TextSize = 13,
        Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
        RichText = false,
    }, card)

    -- Conteúdo
    New("TextLabel", {
        Size = UDim2.new(1, -38, 0, 16),
        Position = UDim2.new(0, 36, 0, 24),
        BackgroundTransparency = 1, Text = content,
        TextColor3 = Theme.TextMuted, TextSize = 11,
        Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        RichText = false,
    }, card)

    -- Barra de progresso
    local progTrack = New("Frame", {
        AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
    }, card)
    Corner(1, progTrack)
    local progFill = New("Frame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = color, BorderSizePixel = 0,
    }, progTrack)
    Corner(1, progFill)

    -- FIX v2.3: Fade in simples
    Tween(card, { BackgroundTransparency = 0 }, 0.2)
    Tween(bar,  { BackgroundTransparency = 0 }, 0.2)
    Tween(progFill, { Size = UDim2.new(0, 0, 1, 0) }, duration, Enum.EasingStyle.Linear)

    -- FIX v2.3: Animação de fechar = slide para a direita + fade, sem resize de altura
    task.delay(duration, function()
        if not wrapper or not wrapper.Parent then return end
        -- Slide para a direita + fade simultâneo
        Tween(wrapper, { Position = UDim2.new(1, 20, wrapper.Position.Y.Scale, wrapper.Position.Y.Offset) }, 0.28)
        Tween(card, { BackgroundTransparency = 1 }, 0.22)
        -- Após slide, encolhe altura silenciosamente para o layout ajustar
        task.wait(0.3)
        if not wrapper or not wrapper.Parent then return end
        Tween(wrapper, { Size = UDim2.new(1, 0, 0, 0) }, 0.14)
        task.wait(0.16)
        if wrapper and wrapper.Parent then wrapper:Destroy() end
    end)
end

-- ============================================================
-- CRIAR JANELA
-- ============================================================
function ForgeLib:CreateWindow(opts)
    opts = opts or {}
    local titleText = opts.Title     or "FORGE HUB"
    local subtitle  = opts.Subtitle  or "v2.2.0"

    -- FIX #4: Nome do jogo com truncagem
    local gameName = opts.GameName or "Unknown Game"
    if not opts.GameName then
        pcall(function()
            gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
        end)
    end

    local toggleKey = opts.ToggleKey or Enum.KeyCode.LeftAlt
    local width     = opts.Width     or 740
    local height    = opts.Height    or 490

    local ScreenGui = New("ScreenGui", {
        Name = "ForgeLib_UI", ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 10,
    }, PlayerGui)

    local Shadow = New("Frame", {
        Name = "Shadow", AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 3, 0.5, 4),
        Size = UDim2.new(0, width + 8, 0, height + 8),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5, ZIndex = 1,
    }, ScreenGui)
    Corner(14, Shadow)

    local Shadow2 = New("Frame", {
        Name = "Shadow2", AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 5, 0.5, 7),
        Size = UDim2.new(0, width + 20, 0, height + 20),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.78, ZIndex = 0,
    }, ScreenGui)
    Corner(16, Shadow2)

    local Main = New("Frame", {
        Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, width, 0, height),
        BackgroundColor3 = Theme.Background,
        ClipsDescendants = true, ZIndex = 2,
    }, ScreenGui)
    Corner(12, Main)
    Stroke(Theme.Border, 1, Main)

    -- ── FIX #5: Bolinha "N" arrastável ao minimizar
    local BallGui = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.08, 0, 0.5, 0),
        Size = UDim2.new(0, 40, 0, 40),
        BackgroundColor3 = Color3.fromRGB(6, 6, 10),
        Visible = false, ZIndex = 20,
        Active = true,
    }, ScreenGui)
    Corner(20, BallGui)
    Stroke(Theme.Accent, 1.5, BallGui, 0.3)
    New("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        Text = "N", Font = Enum.Font.GothamBold, TextSize = 18,
        TextColor3 = Theme.Accent, ZIndex = 21,
    }, BallGui)

    -- Sombra da bolinha
    local BallShadow = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 2, 0.5, 3),
        Size = UDim2.new(1, 8, 1, 8),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.6, ZIndex = 19,
        Visible = false,
    }, ScreenGui)
    Corner(24, BallShadow)

    -- Arrastar bolinha
    local ballDragging, ballDragStart, ballStartPos = false, nil, nil
    local ballBtn = New("TextButton", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        Text = "", ZIndex = 22,
    }, BallGui)

    ballBtn.MouseButton1Down:Connect(function()
        ballDragging = true
        ballDragStart = UserInputService:GetMouseLocation()
        ballStartPos = BallGui.Position
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            ballDragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if ballDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local cur = UserInputService:GetMouseLocation()
            local dx = cur.X - ballDragStart.X
            local dy = cur.Y - ballDragStart.Y
            BallGui.Position = UDim2.new(
                ballStartPos.X.Scale, ballStartPos.X.Offset + dx,
                ballStartPos.Y.Scale, ballStartPos.Y.Offset + dy
            )
            BallShadow.Position = UDim2.new(
                ballStartPos.X.Scale, ballStartPos.X.Offset + dx + 2,
                ballStartPos.Y.Scale, ballStartPos.Y.Offset + dy + 3
            )
        end
    end)

    -- Clique na bolinha → abre menu
    local ballClickThreshold = 5
    local ballPressPos
    ballBtn.MouseButton1Down:Connect(function()
        ballPressPos = UserInputService:GetMouseLocation()
    end)
    ballBtn.MouseButton1Up:Connect(function()
        if not ballPressPos then return end
        local cur = UserInputService:GetMouseLocation()
        local dist = (cur - ballPressPos).Magnitude
        if dist < ballClickThreshold then
            -- Abrir menu
            BallGui.Visible    = false
            BallShadow.Visible = false
            Main.Visible    = true
            Shadow.Visible  = true
            Shadow2.Visible = true
            Tween(Main, { Size = UDim2.new(0, width, 0, height) }, 0.2)
        end
    end)

    local function SyncShadows()
        local px = Main.Position.X.Offset
        local py = Main.Position.Y.Offset
        local ps = Main.Position.X.Scale
        local psy= Main.Position.Y.Scale
        Shadow.Position  = UDim2.new(ps, px+3,  psy, py+4)
        Shadow2.Position = UDim2.new(ps, px+5,  psy, py+7)
    end

    local function SyncVisible(v)
        Main.Visible    = v
        Shadow.Visible  = v
        Shadow2.Visible = v
    end

    -- ── Topbar
    local Topbar = New("Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = Theme.Surface, ZIndex = 3,
    }, Main)
    New("Frame", {
        AnchorPoint = Vector2.new(0,1), Position = UDim2.new(0,0,1,0),
        Size = UDim2.new(1,0,0,1), BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
    }, Topbar)

    -- Traffic lights
    local wbColors = {
        { c=Color3.fromRGB(255,95,87),  h=Color3.fromRGB(220,60,50)  },
        { c=Color3.fromRGB(255,189,68), h=Color3.fromRGB(220,155,40) },
        { c=Color3.fromRGB(40,200,64),  h=Color3.fromRGB(20,160,45)  },
    }
    for i, info in ipairs(wbColors) do
        local btn = New("Frame", {
            Size = UDim2.new(0,13,0,13),
            Position = UDim2.new(0, 12+(i-1)*20, 0.5, -6),
            BackgroundColor3 = info.c, ZIndex = 4,
        }, Topbar)
        Corner(7, btn)
        local hitbox = New("TextButton", {
            Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
            Text = "", ZIndex = 5,
        }, btn)
        hitbox.MouseEnter:Connect(function() Tween(btn,{BackgroundColor3=info.h},0.08) end)
        hitbox.MouseLeave:Connect(function() Tween(btn,{BackgroundColor3=info.c},0.08) end)
        if i == 1 then
            -- Fechar
            hitbox.MouseButton1Click:Connect(function()
                Tween(Main,    { Size = UDim2.new(0,0,0,0), BackgroundTransparency=1 }, 0.18)
                Tween(Shadow,  { BackgroundTransparency=1 }, 0.18)
                Tween(Shadow2, { BackgroundTransparency=1 }, 0.18)
                task.wait(0.22)
                ScreenGui:Destroy()
            end)
        elseif i == 2 then
            -- FIX #5: Minimizar → bolinha "N"
            hitbox.MouseButton1Click:Connect(function()
                -- Esconde main com animação
                Tween(Main, { Size = UDim2.new(0, width, 0, 0) }, 0.18)
                Tween(Shadow,  { BackgroundTransparency=1 }, 0.15)
                Tween(Shadow2, { BackgroundTransparency=1 }, 0.15)
                task.wait(0.2)
                Main.Visible    = false
                Shadow.Visible  = false
                Shadow2.Visible = false
                Main.Size = UDim2.new(0, width, 0, height) -- reset para quando abrir

                -- Mostra bolinha
                BallGui.Visible    = true
                BallShadow.Visible = true
                Tween(BallGui, { BackgroundTransparency = 0 }, 0.15)
            end)
        end
    end

    -- Título da topbar
    local words = titleText:split(" ")
    local w1 = words[1] or titleText
    local w2 = words[2] or ""
    local rich = string.format(
        '<font color="rgb(215,215,220)">%s</font><font color="rgb(124,106,247)"> %s</font>',
        w1, w2
    )
    New("TextLabel", {
        Size = UDim2.new(0, 220, 1, 0), Position = UDim2.new(0, 80, 0, 0),
        BackgroundTransparency = 1, RichText = true, Text = rich,
        Font = Enum.Font.GothamBold, TextSize = 14,
        TextColor3 = Theme.TextPrimary, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3,
    }, Topbar)

    -- Separador
    New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -175, 0.5, 0),
        Size = UDim2.new(0, 1, 0, 20),
        BackgroundColor3 = Theme.Border, BorderSizePixel = 0,
    }, Topbar)

    -- FIX #4: gameName truncado + subtitle — container com largura limitada
    local infoContainer = New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -18, 0.5, 0),
        Size = UDim2.new(0, 152, 0, 28),
        BackgroundTransparency = 1,
        ZIndex = 3,
        ClipsDescendants = true,
    }, Topbar)

    -- gameName (primeira linha) — truncado
    New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 14),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = gameName,
        Font = Enum.Font.GothamMedium, TextSize = 10,
        TextColor3 = Theme.TextMuted,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 3,
    }, infoContainer)

    -- subtitle (segunda linha)
    New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 13),
        Position = UDim2.new(0, 0, 0, 15),
        BackgroundTransparency = 1,
        Text = subtitle,
        Font = Enum.Font.GothamMedium, TextSize = 10,
        TextColor3 = Theme.AccentDim,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 3,
    }, infoContainer)

    -- Drag
    local dragging, dragStart, startMainPos
    Topbar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = inp.Position
            startMainPos = Main.Position
        end
    end)
    Topbar.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d = inp.Position - dragStart
            Main.Position = UDim2.new(
                startMainPos.X.Scale, startMainPos.X.Offset + d.X,
                startMainPos.Y.Scale, startMainPos.Y.Offset + d.Y
            )
            SyncShadows()
        end
    end)

    -- Toggle key
    UserInputService.InputBegan:Connect(function(inp, gp)
        if not gp and inp.KeyCode == toggleKey then
            SyncVisible(not Main.Visible)
        end
    end)

    -- Resize handle
    local ResizeHandle = New("TextButton", {
        Size = UDim2.new(0,18,0,18), AnchorPoint = Vector2.new(1,1),
        Position = UDim2.new(1,-1,1,-1), BackgroundTransparency = 1,
        Text = "", ZIndex = 10,
    }, Main)
    New("TextLabel", {
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        Text="⌟", TextSize=14, TextColor3=Theme.TextHint,
        Font=Enum.Font.Gotham, ZIndex=10,
    }, ResizeHandle)

    local resizing, resizeStart, startSize = false, nil, nil
    ResizeHandle.MouseButton1Down:Connect(function()
        resizing    = true
        resizeStart = UserInputService:GetMouseLocation()
        startSize   = Main.AbsoluteSize
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = false
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if resizing and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local cur = UserInputService:GetMouseLocation()
            local nw = math.clamp(startSize.X + (cur.X - resizeStart.X), 520, 1200)
            local nh = math.clamp(startSize.Y + (cur.Y - resizeStart.Y), 360, 800)
            Main.Size    = UDim2.new(0, nw, 0, nh)
            Shadow.Size  = UDim2.new(0, nw+8,  0, nh+8)
            Shadow2.Size = UDim2.new(0, nw+20, 0, nh+20)
            SyncShadows()
        end
    end)

    -- ── Sidebar
    local Sidebar = New("Frame", {
        Name = "Sidebar", Position = UDim2.new(0,0,0,44),
        Size = UDim2.new(0,168,1,-44),
        BackgroundColor3 = Theme.Surface,
    }, Main)
    New("Frame", {
        AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,0,0,0),
        Size=UDim2.new(0,1,1,0), BackgroundColor3=Theme.Border,
        BorderSizePixel=0,
    }, Sidebar)

    local SearchFrame = New("Frame", {
        Size = UDim2.new(1,-16,0,30), Position = UDim2.new(0,8,0,10),
        BackgroundColor3 = Theme.InputBg,
    }, Sidebar)
    Corner(8, SearchFrame)
    local searchStroke = Stroke(Theme.Border, 0.5, SearchFrame)

    New("TextLabel", {
        Size=UDim2.new(0,18,1,0), Position=UDim2.new(0,8,0,0),
        BackgroundTransparency=1, Text=Icons.Search,
        TextColor3=Theme.TextMuted, TextSize=14, Font=Enum.Font.Gotham,
        RichText=false,
    }, SearchFrame)

    local SearchBox = New("TextBox", {
        Size=UDim2.new(1,-28,1,0), Position=UDim2.new(0,26,0,0),
        BackgroundTransparency=1, PlaceholderText="Search...",
        PlaceholderColor3=Theme.TextHint,
        Text="", TextColor3=Theme.TextPrimary,
        Font=Enum.Font.Gotham, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left,
        ClearTextOnFocus=false,
    }, SearchFrame)

    SearchBox.Focused:Connect(function()
        Tween(searchStroke, {Color=Theme.Accent, Thickness=1}, 0.15)
    end)
    SearchBox.FocusLost:Connect(function()
        Tween(searchStroke, {Color=Theme.Border, Thickness=0.5}, 0.15)
    end)

    local NavScroll = New("ScrollingFrame", {
        Position=UDim2.new(0,0,0,50), Size=UDim2.new(1,0,1,-100),
        BackgroundTransparency=1, ScrollBarThickness=0,
        CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
        BorderSizePixel=0,
    }, Sidebar)
    List(0, NavScroll)

    -- Footer sidebar
    local SideFooter = New("Frame", {
        AnchorPoint=Vector2.new(0,1), Position=UDim2.new(0,0,1,0),
        Size=UDim2.new(1,0,0,58),
        BackgroundColor3=Theme.Surface,
    }, Sidebar)
    New("Frame", {
        Size=UDim2.new(1,0,0,1), BackgroundColor3=Theme.Border, BorderSizePixel=0,
    }, SideFooter)
    Padding(0,0,10,10, SideFooter)

    local AvatarFrame = New("Frame", {
        Size=UDim2.new(0,38,0,38), Position=UDim2.new(0,0,0.5,-19),
        BackgroundColor3=Theme.InputBg,
    }, SideFooter)
    Corner(19, AvatarFrame)
    Stroke(Theme.Accent, 1, AvatarFrame, 0.5)

    local AvatarImg = New("ImageLabel", {
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        Image="", ScaleType=Enum.ScaleType.Crop,
    }, AvatarFrame)
    Corner(19, AvatarImg)

    task.spawn(function()
        local thumb = GetAvatarThumb(LocalPlayer.UserId)
        if thumb then AvatarImg.Image = thumb end
    end)

    New("TextLabel", {
        Size=UDim2.new(1,-50,0,18), Position=UDim2.new(0,48,0,8),
        BackgroundTransparency=1, Text=LocalPlayer.DisplayName,
        Font=Enum.Font.GothamMedium, TextSize=12,
        TextColor3=Theme.TextPrimary, TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd,
    }, SideFooter)
    New("TextLabel", {
        Size=UDim2.new(1,-50,0,14), Position=UDim2.new(0,48,0,28),
        BackgroundTransparency=1, Text="@"..LocalPlayer.Name,
        Font=Enum.Font.Gotham, TextSize=10,
        TextColor3=Theme.TextMuted, TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd,
    }, SideFooter)

    -- ── ContentArea
    local ContentArea = New("Frame", {
        Position=UDim2.new(0,168,0,44), Size=UDim2.new(1,-168,1,-44),
        BackgroundColor3=Theme.Background, ClipsDescendants=true,
    }, Main)

    local AllTabs   = {}
    local ActiveTab = nil

    local function SetActiveTab(tabData)
        for _, td in pairs(AllTabs) do
            td.frame.Visible = false
            Tween(td.navBtn,   { BackgroundColor3=Color3.fromRGB(0,0,0), BackgroundTransparency=1 }, 0.12)
            Tween(td.navLabel, { TextColor3=Theme.TextMuted }, 0.12)
            if td.navIcon  then Tween(td.navIcon,  { TextColor3=Theme.TextMuted }, 0.12) end
            if td.accentBar then td.accentBar.Visible = false end
            if td.activeBg  then td.activeBg.Visible  = false end
        end
        tabData.frame.Visible = true
        Tween(tabData.navBtn,   { BackgroundColor3=Theme.NavActive, BackgroundTransparency=0 }, 0.15)
        Tween(tabData.navLabel, { TextColor3=Theme.TextPrimary }, 0.15)
        if tabData.navIcon  then Tween(tabData.navIcon, { TextColor3=Theme.Accent }, 0.15) end
        if tabData.accentBar then tabData.accentBar.Visible = true end
        if tabData.activeBg  then tabData.activeBg.Visible  = true end
        ActiveTab = tabData
    end

    local function MakeNavSectionLabel(text, layoutOrder)
        local lbl = New("TextLabel", {
            Size=UDim2.new(1,0,0,28), BackgroundTransparency=1,
            Text=text, Font=Enum.Font.GothamMedium,
            TextSize=9, TextColor3=Theme.TextHint,
            TextXAlignment=Enum.TextXAlignment.Left,
            LayoutOrder=layoutOrder,
        }, NavScroll)
        Padding(8,0,14,0, lbl)
        return lbl
    end

    local function MakeNavBtn(tabName, icon, sectionName, layoutOrder)
        local btn = New("TextButton", {
            Size=UDim2.new(1,0,0,36), BackgroundTransparency=1,
            BackgroundColor3=Theme.NavActive,
            Text="", AutoButtonColor=false,
            LayoutOrder=layoutOrder,
        }, NavScroll)
        Corner(8, btn)
        New("UIPadding", {
            PaddingLeft=UDim.new(0,6), PaddingRight=UDim.new(0,6),
            PaddingTop=UDim.new(0,2),  PaddingBottom=UDim.new(0,2),
        }, btn)

        local accentBar = New("Frame", {
            Size=UDim2.new(0,3,0.7,0), AnchorPoint=Vector2.new(0,0.5),
            Position=UDim2.new(0,-6,0.5,0),
            BackgroundColor3=Theme.Accent, Visible=false,
        }, btn)
        Corner(2, accentBar)

        local activeBg = New("Frame", {
            Size=UDim2.new(1,0,1,0), BackgroundColor3=Theme.NavActive,
            BackgroundTransparency=0, Visible=false,
        }, btn)
        Corner(8, activeBg)

        local iconLbl = nil
        if icon and icon ~= "" then
            iconLbl = New("TextLabel", {
                Size=UDim2.new(0,20,1,0), Position=UDim2.new(0,6,0,0),
                BackgroundTransparency=1, Text=icon,
                TextColor3=Theme.TextMuted, TextSize=14,
                Font=Enum.Font.Gotham, ZIndex=3,
                RichText=false,
            }, btn)
        end

        local lbl = New("TextLabel", {
            Size=UDim2.new(1,-(icon and 30 or 8),1,0),
            Position=UDim2.new(0,icon and 28 or 8,0,0),
            BackgroundTransparency=1, Text=tabName,
            Font=Enum.Font.GothamMedium, TextSize=12,
            TextColor3=Theme.TextMuted, TextXAlignment=Enum.TextXAlignment.Left,
            ZIndex=3,
        }, btn)

        btn.MouseEnter:Connect(function()
            if not (ActiveTab and ActiveTab.navBtn == btn) then
                Tween(btn, {BackgroundTransparency=0, BackgroundColor3=Theme.NavHover}, 0.1)
            end
        end)
        btn.MouseLeave:Connect(function()
            if not (ActiveTab and ActiveTab.navBtn == btn) then
                Tween(btn, {BackgroundTransparency=1}, 0.1)
            end
        end)

        return btn, lbl, accentBar, activeBg, iconLbl
    end

    -- Busca global
    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local q = SearchBox.Text:lower():gsub("^%s+",""):gsub("%s+$","")
        if q == "" then
            for _, td in pairs(AllTabs) do
                td.navBtn.Visible = true
                for _, si in pairs(td.searchItems or {}) do
                    si.frame.Visible = true
                end
            end
            for _, c in pairs(NavScroll:GetChildren()) do
                if c:IsA("TextLabel") then c.Visible = true end
            end
            return
        end
        local anyTabMatch = false
        for _, td in pairs(AllTabs) do
            local tabMatch  = td.name:lower():find(q, 1, true) ~= nil
            local itemMatch = false
            for _, si in pairs(td.searchItems or {}) do
                local match = si.name:lower():find(q, 1, true) ~= nil
                si.frame.Visible = match
                if match then itemMatch = true end
            end
            td.navBtn.Visible = tabMatch or itemMatch
            if tabMatch or itemMatch then anyTabMatch = true end
        end
        for _, c in pairs(NavScroll:GetChildren()) do
            if c:IsA("TextLabel") then c.Visible = anyTabMatch end
        end
    end)

    -- ============================================================
    -- SETTINGS TAB
    -- ============================================================
    local function BuildSettingsTab()
        local navLO = 900
        MakeNavSectionLabel("SETTINGS", navLO - 1)
        local navBtn, navLbl, accentBar, activeBg, navIcon = MakeNavBtn(
            "Settings", Icons.Settings, "settings", navLO
        )

        local TabFrame = New("ScrollingFrame", {
            Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
            Visible=false, ScrollBarThickness=3,
            ScrollBarImageColor3=Theme.Border,
            CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
            BorderSizePixel=0,
        }, ContentArea)
        Padding(16,16,16,16, TabFrame)
        List(12, TabFrame)

        local tabData = {
            frame=TabFrame, navBtn=navBtn, navLabel=navLbl,
            navIcon=navIcon, accentBar=accentBar, activeBg=activeBg,
            name="Settings", section="settings", searchItems={},
        }
        table.insert(AllTabs, tabData)
        navBtn.MouseButton1Click:Connect(function() SetActiveTab(tabData) end)

        local function SecTitle(txt)
            local f = New("Frame", { Size=UDim2.new(1,0,0,26), BackgroundTransparency=1 }, TabFrame)
            New("TextLabel", {
                Size=UDim2.new(1,0,0,16), Position=UDim2.new(0,0,0,8),
                BackgroundTransparency=1, Text=txt:upper(),
                Font=Enum.Font.GothamMedium, TextSize=9,
                TextColor3=Theme.TextHint, TextXAlignment=Enum.TextXAlignment.Left,
            }, f)
            New("Frame", {
                AnchorPoint=Vector2.new(0,1), Position=UDim2.new(0,0,1,0),
                Size=UDim2.new(1,0,0,1), BackgroundColor3=Theme.Border,
            }, f)
        end

        local function Card(h, parent)
            local c = New("Frame", {
                Size=UDim2.new(1,0,0,h),
                BackgroundColor3=Theme.Surface,
            }, parent or TabFrame)
            Corner(10, c)
            Stroke(Theme.Border, 0.5, c)
            Padding(8,8,14,14, c)
            return c
        end

        local function SRow(parent, label, h)
            local r = New("Frame", {
                Size=UDim2.new(1,0,0,h or 34), BackgroundTransparency=1,
            }, parent)
            New("TextLabel", {
                Size=UDim2.new(0.6,0,1,0), BackgroundTransparency=1,
                Text=label, Font=Enum.Font.Gotham,
                TextSize=12, TextColor3=Theme.TextPrimary,
                TextXAlignment=Enum.TextXAlignment.Left,
            }, r)
            return r
        end

        local function SToggle(parent, label, default, cb)
            local state = default or false
            local row   = SRow(parent, label)
            local track = New("Frame", {
                AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,0,0.5,0),
                Size=UDim2.new(0,40,0,22),
                BackgroundColor3=state and Theme.AccentGreen or Theme.ToggleOff,
            }, row)
            Corner(11, track)
            Stroke(Theme.Border, 0.5, track)
            local knob = New("Frame", {
                Position=UDim2.new(0,state and 20 or 3,0.5,-7),
                Size=UDim2.new(0,16,0,16), BackgroundColor3=Theme.White,
            }, track)
            Corner(8, knob)
            local hitbox = New("TextButton", {
                Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="",
            }, row)
            hitbox.MouseButton1Click:Connect(function()
                state = not state
                Tween(track, {BackgroundColor3=state and Theme.AccentGreen or Theme.ToggleOff})
                Tween(knob,  {Position=UDim2.new(0,state and 20 or 3,0.5,-7)})
                if cb then cb(state) end
            end)
        end

        -- FIX #1: FlatBtn com cores corretas e texto/ícone sem sair do layout
        local function FlatBtn(parent, label, icon, cb, style)
            local sty = ButtonStyles[style or "secondary"] or ButtonStyles.secondary
            local btn = New("TextButton", {
                Size=UDim2.new(1,0,0,36),
                BackgroundColor3=sty.bg,
                Text="", AutoButtonColor=false,
            }, parent)
            Corner(8, btn)
            Stroke(sty.border, 0.5, btn)

            -- Layout interno: ícone fixo à esquerda, texto ocupa resto
            local iconW = icon and 32 or 0
            if icon then
                New("TextLabel", {
                    Size=UDim2.new(0, iconW, 1, 0),
                    Position=UDim2.new(0, 8, 0, 0),
                    BackgroundTransparency=1, Text=icon,
                    TextColor3=sty.text, TextSize=13,
                    Font=Enum.Font.Gotham, RichText=false,
                    TextXAlignment=Enum.TextXAlignment.Left,
                }, btn)
            end
            New("TextLabel", {
                Size=UDim2.new(1, -(iconW + 16), 1, 0),
                Position=UDim2.new(0, iconW + 12, 0, 0),
                BackgroundTransparency=1, Text=label,
                Font=Enum.Font.GothamMedium, TextSize=12,
                TextColor3=sty.text, TextXAlignment=Enum.TextXAlignment.Left,
                TextTruncate=Enum.TextTruncate.AtEnd,
            }, btn)

            AddHover(btn, sty.bg, sty.hover or sty.bg)
            btn.MouseButton1Click:Connect(function()
                Tween(btn,{BackgroundTransparency=0.4},0.06)
                task.delay(0.12, function() Tween(btn,{BackgroundTransparency=0},0.1) end)
                if cb then cb() end
            end)
            return btn
        end

        -- Interface
        SecTitle("Interface")
        local uiCard = Card(90)
        List(0, uiCard)

        local uiScale = New("UIScale", { Scale = 1 }, ScreenGui)

        local scaleRow = New("Frame", { Size=UDim2.new(1,0,0,52), BackgroundTransparency=1 }, uiCard)
        New("TextLabel", {
            Size=UDim2.new(0.6,0,0,18), BackgroundTransparency=1,
            Text="UI Scale", Font=Enum.Font.Gotham,
            TextSize=12, TextColor3=Theme.TextPrimary,
            TextXAlignment=Enum.TextXAlignment.Left,
        }, scaleRow)
        local scaleValLbl = New("TextLabel", {
            AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,0,0,0),
            Size=UDim2.new(0,40,0,18), BackgroundTransparency=1,
            Text="100%", Font=Enum.Font.GothamMedium,
            TextSize=12, TextColor3=Theme.Accent,
            TextXAlignment=Enum.TextXAlignment.Right,
        }, scaleRow)

        local sTrackFrame = New("Frame", {
            Position=UDim2.new(0,0,0,28), Size=UDim2.new(1,-4,0,6),
            BackgroundColor3=Theme.ToggleOff,
        }, scaleRow)
        Corner(3, sTrackFrame)
        local sFill = New("Frame", {
            Size=UDim2.new(0.5,0,1,0), BackgroundColor3=Theme.AccentGreen,
        }, sTrackFrame)
        Corner(3, sFill)
        local sThumb = New("Frame", {
            AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,0.5,0),
            Size=UDim2.new(0,16,0,16), BackgroundColor3=Theme.White,
        }, sTrackFrame)
        Corner(8, sThumb)
        Stroke(Theme.Border, 0.5, sThumb)
        local sDragBtn = New("TextButton", {
            Size=UDim2.new(1,0,5,0), Position=UDim2.new(0,0,-2,0),
            BackgroundTransparency=1, Text="", ZIndex=5,
        }, sTrackFrame)

        local sDragging = false
        sDragBtn.MouseButton1Down:Connect(function() sDragging = true end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then sDragging = false end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if sDragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                local rel = math.clamp(
                    (i.Position.X - sTrackFrame.AbsolutePosition.X) / sTrackFrame.AbsoluteSize.X,
                    0, 1
                )
                local pct = math.floor(50 + 100 * rel)
                sFill.Size           = UDim2.new(rel, 0, 1, 0)
                sThumb.Position      = UDim2.new(rel, 0, 0.5, 0)
                scaleValLbl.Text     = pct .. "%"
                uiScale.Scale        = pct / 100
            end
        end)

        SToggle(uiCard, "Ativar Notificacoes", true, function(v)
            ForgeLib._NotifsEnabled = v
        end)
        uiCard.Size = UDim2.new(1, 0, 0, 52 + 34 + 12)

        -- Configurações
        SecTitle("Configuracoes")

        local cfgNameFrame = New("Frame", {
            Size=UDim2.new(1,0,0,32), BackgroundColor3=Theme.InputBg,
        }, TabFrame)
        Corner(8, cfgNameFrame)
        Stroke(Theme.Border, 0.5, cfgNameFrame)
        local cfgNameBox = New("TextBox", {
            Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
            PlaceholderText="Nome da config...",
            PlaceholderColor3=Theme.TextMuted, Text="",
            TextColor3=Theme.TextPrimary, Font=Enum.Font.Gotham,
            TextSize=12, TextXAlignment=Enum.TextXAlignment.Left,
            ClearTextOnFocus=false,
        }, cfgNameFrame)
        Padding(0,0,12,12, cfgNameFrame)

        local cfgCard = Card(80)
        List(0, cfgCard)
        SToggle(cfgCard, "Account Exclusive", false)
        SToggle(cfgCard, "Account Autoload",  false)

        FlatBtn(TabFrame, "Create Config", Icons.Plus, function()
            local name = cfgNameBox.Text
            if name == "" then
                ForgeLib:Notify({Title="Erro",Content="Digite um nome.",Color=Theme.AccentRed,Icon=Icons.Error})
                return
            end
            SaveConfig(name, {_name=name, _created=os.time()})
            ForgeLib:Notify({Title="Config criada",Content=name,Color=Theme.AccentGreen,Icon=Icons.Check})
            cfgNameBox.Text = ""
        end, "primary")

        SecTitle("Lista de Configs")

        local cfgSelected = "nil"
        local cfgDropBtn = New("TextButton", {
            Size=UDim2.new(1,0,0,32), BackgroundColor3=Theme.InputBg,
            Text="", AutoButtonColor=false,
        }, TabFrame)
        Corner(8, cfgDropBtn)
        Stroke(Theme.Border, 0.5, cfgDropBtn)
        Padding(0,0,12,12, cfgDropBtn)
        local cfgDropLabel = New("TextLabel", {
            Size=UDim2.new(1,-24,1,0), BackgroundTransparency=1,
            Text=cfgSelected, Font=Enum.Font.Gotham, TextSize=12,
            TextColor3=Theme.TextPrimary, TextXAlignment=Enum.TextXAlignment.Left,
            TextTruncate=Enum.TextTruncate.AtEnd,
        }, cfgDropBtn)
        New("TextLabel", {
            AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-10,0.5,0),
            Size=UDim2.new(0,14,0,14), BackgroundTransparency=1,
            Text=Icons.ChevronDown, Font=Enum.Font.Gotham,
            TextSize=12, TextColor3=Theme.TextMuted,
        }, cfgDropBtn)
        AddHover(cfgDropBtn, Theme.InputBg, Theme.Surface2)

        -- FIX #7 (dropdown de configs): container com altura dinâmica
        local cfgListFrame = New("Frame", {
            Size=UDim2.new(1,0,0,0), BackgroundColor3=Theme.InputBg,
            ClipsDescendants=true, Visible=false,
        }, TabFrame)
        Corner(8, cfgListFrame)
        Stroke(Theme.Border, 0.5, cfgListFrame)
        List(0, cfgListFrame)

        local function RefreshCfgList()
            cfgListFrame:ClearAllChildren()
            List(0, cfgListFrame)
            local configs = ListConfigs()
            table.insert(configs, 1, "nil")
            for _, name in ipairs(configs) do
                local ib = New("TextButton", {
                    Size=UDim2.new(1,0,0,30),
                    BackgroundColor3=name==cfgSelected and Theme.Surface2 or Theme.InputBg,
                    Text="", AutoButtonColor=false,
                }, cfgListFrame)
                Padding(0,0,12,0, ib)
                New("TextLabel", {
                    Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
                    Text=name, Font=Enum.Font.Gotham, TextSize=12,
                    TextColor3=name==cfgSelected and Theme.Accent or Theme.TextPrimary,
                    TextXAlignment=Enum.TextXAlignment.Left,
                    TextTruncate=Enum.TextTruncate.AtEnd,
                }, ib)
                AddHover(ib, name==cfgSelected and Theme.Surface2 or Theme.InputBg, Theme.Surface3)
                ib.MouseButton1Click:Connect(function()
                    cfgSelected       = name
                    cfgDropLabel.Text = name
                    cfgListFrame.Visible = false
                    Tween(cfgListFrame, {Size=UDim2.new(1,0,0,0)}, 0.12)
                end)
            end
            local h = #configs * 30
            Tween(cfgListFrame, {Size=UDim2.new(1,0,0,h)}, 0.14)
        end

        cfgDropBtn.MouseButton1Click:Connect(function()
            local open = not cfgListFrame.Visible
            if open then
                cfgListFrame.Size    = UDim2.new(1,0,0,0)
                cfgListFrame.Visible = true
                RefreshCfgList()
            else
                Tween(cfgListFrame, {Size=UDim2.new(1,0,0,0)}, 0.12)
                task.delay(0.14, function() cfgListFrame.Visible = false end)
            end
        end)

        local actionCard = Card(168)
        List(6, actionCard)
        FlatBtn(actionCard, "Load Config",      Icons.Download, function()
            if cfgSelected == "nil" then
                ForgeLib:Notify({Title="Erro",Content="Selecione uma config.",Color=Theme.AccentRed,Icon=Icons.Error})
                return
            end
            LoadConfig(cfgSelected)
            ForgeLib:Notify({Title="Config carregada",Content=cfgSelected,Icon=Icons.Check})
        end, "success")
        FlatBtn(actionCard, "Overwrite Config", Icons.Edit, function()
            if cfgSelected == "nil" then return end
            SaveConfig(cfgSelected, {_name=cfgSelected, _updated=os.time()})
            ForgeLib:Notify({Title="Config sobrescrita",Content=cfgSelected,Icon=Icons.Check})
        end, "secondary")
        FlatBtn(actionCard, "Delete Config",    Icons.Delete, function()
            if cfgSelected == "nil" then return end
            ConfigStore[cfgSelected] = nil
            cfgSelected = "nil"; cfgDropLabel.Text = "nil"
            ForgeLib:Notify({Title="Config deletada",Color=Theme.AccentRed,Icon=Icons.Error})
        end, "danger")
        FlatBtn(actionCard, "Refresh List",     Icons.Refresh, function()
            if cfgListFrame.Visible then RefreshCfgList() end
            ForgeLib:Notify({Title="Lista atualizada",Icon=Icons.Check})
        end, "ghost")

        local autoCard = Card(114)
        List(6, autoCard)
        FlatBtn(autoCard, "Set as Normal Autoload",  Icons.Star, function()
            ForgeLib._NormalAutoload = cfgSelected
            ForgeLib:Notify({Title="Autoload definido",Content=cfgSelected,Icon=Icons.Star})
        end, "primary")
        FlatBtn(autoCard, "Set as Account Autoload", Icons.User, function()
            ForgeLib._AccountAutoload = cfgSelected
            ForgeLib:Notify({Title="Account Autoload",Content=cfgSelected,Icon=Icons.User})
        end, "primary")
        FlatBtn(autoCard, "Reset Autoloads", Icons.Refresh, function()
            ForgeLib._NormalAutoload  = nil
            ForgeLib._AccountAutoload = nil
            ForgeLib:Notify({Title="Autoloads resetados",Color=Theme.AccentRed,Icon=Icons.Error})
        end, "danger")

        local autoInfoLbl = New("TextLabel", {
            Size=UDim2.new(1,0,0,18), BackgroundTransparency=1,
            Text="Autoload: none (None)", Font=Enum.Font.Gotham,
            TextSize=10, TextColor3=Theme.TextHint,
            TextXAlignment=Enum.TextXAlignment.Left,
        }, TabFrame)
        RunService.Heartbeat:Connect(function()
            autoInfoLbl.Text = ("Autoload: %s (%s)"):format(
                ForgeLib._NormalAutoload  or "none",
                ForgeLib._AccountAutoload or "None"
            )
        end)
    end

    BuildSettingsTab()

    -- ══════════════════════════════════════════════════════
    -- WINDOW OBJECT
    -- ══════════════════════════════════════════════════════
    local WindowObj            = {}
    local mainLabelAdded       = false
    local sectionLabelAdded    = {}
    local mainLabelOrder       = -100
    local ButtonHotkeys        = {}

    UserInputService.InputBegan:Connect(function(inp, gp)
        if gp then return end
        for _, bh in pairs(ButtonHotkeys) do
            if inp.KeyCode == bh.key then pcall(bh.cb) end
        end
    end)

    function WindowObj:CreateTab(tabName, tabOpts)
        tabOpts = tabOpts or {}
        local section = (tabOpts.Section or "main"):lower()
        local icon    = tabOpts.Icon or ""

        if not mainLabelAdded and section == "main" then
            MakeNavSectionLabel("MAIN", mainLabelOrder)
            mainLabelAdded = true
        end
        if section ~= "main" and section ~= "settings" and not sectionLabelAdded[section] then
            MakeNavSectionLabel(section:upper(), #AllTabs*10+50-1)
            sectionLabelAdded[section] = true
        end

        local layoutOrder = (#AllTabs + 1) * 10
        if section == "main" then layoutOrder = layoutOrder - 500 end

        local navBtn, navLbl, accentBar, activeBg, navIcon = MakeNavBtn(tabName, icon, section, layoutOrder)

        local TabFrame = New("ScrollingFrame", {
            Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
            Visible=false, ScrollBarThickness=3,
            ScrollBarImageColor3=Theme.Border,
            CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
            BorderSizePixel=0,
        }, ContentArea)
        Padding(14,14,14,14, TabFrame)
        List(10, TabFrame)

        local tabData = {
            frame=TabFrame, navBtn=navBtn, navLabel=navLbl,
            navIcon=navIcon, accentBar=accentBar, activeBg=activeBg,
            name=tabName, section=section, searchItems={},
        }
        table.insert(AllTabs, tabData)

        local mainTabs = 0
        for _, td in pairs(AllTabs) do
            if td.section == "main" then mainTabs = mainTabs + 1 end
        end
        if mainTabs == 1 and section == "main" then SetActiveTab(tabData) end

        navBtn.MouseButton1Click:Connect(function() SetActiveTab(tabData) end)

        -- ─────────────────────────────────────────────────
        -- TAB OBJECT
        -- ─────────────────────────────────────────────────
        local TabObj = {}

        local function RegisterSearch(name, frame)
            table.insert(tabData.searchItems, { name=name, frame=frame })
        end

        -- FIX v2.3: MakeBlock — padding absoluto, ClipsDescendants=false para keybind badge
        -- Conteúdo interno começa em X=12 (PaddingLeft) e vai até width-12 (PaddingRight)
        local function MakeBlock(h, parent)
            local b = New("Frame", {
                Size = UDim2.new(1, 0, 0, h or 38),
                BackgroundColor3 = Theme.Surface,
                ClipsDescendants = false,
            }, parent or TabFrame)
            Corner(10, b)
            Stroke(Theme.Border, 0.5, b)
            Padding(0, 0, 12, 12, b)
            return b
        end

        -- FIX v2.3: MakeLabel com posições absolutas para garantir sem sobreposição
        -- Layout: [ícone 18px][gap 4px][texto até 55% - offset]
        -- Lado direito reservado para keybind (52px) + controle (toggle=46px, etc.)
        local ICON_W = 22

        local function MakeLabel(parent, text, iconStr)
            local offset = iconStr and ICON_W or 0
            if iconStr and iconStr ~= "" then
                New("TextLabel", {
                    Size               = UDim2.new(0, 18, 1, 0),
                    Position           = UDim2.new(0, 0, 0, 0),
                    BackgroundTransparency = 1,
                    Text               = iconStr,
                    TextColor3         = Theme.Accent,
                    TextSize           = 13,
                    Font               = Enum.Font.Gotham,
                    RichText           = false,
                    TextXAlignment     = Enum.TextXAlignment.Left,
                    TextYAlignment     = Enum.TextYAlignment.Center,
                }, parent)
            end
            return New("TextLabel", {
                -- Texto vai de offset até 56% da largura (deixa ~44% p/ controles)
                Size               = UDim2.new(0.56, -offset, 1, 0),
                Position           = UDim2.new(0, offset, 0, 0),
                BackgroundTransparency = 1,
                Text               = text,
                Font               = Enum.Font.Gotham,
                TextSize           = 12,
                TextColor3         = Theme.TextPrimary,
                TextXAlignment     = Enum.TextXAlignment.Left,
                TextYAlignment     = Enum.TextYAlignment.Center,
                TextTruncate       = Enum.TextTruncate.AtEnd,
            }, parent)
        end

        -- CreateSection
        function TabObj:CreateSection(text)
            local sec = New("Frame", { Size=UDim2.new(1,0,0,26), BackgroundTransparency=1 }, TabFrame)
            New("TextLabel", {
                Size=UDim2.new(1,0,0,16), Position=UDim2.new(0,0,0,8),
                BackgroundTransparency=1, Text=text:upper(),
                Font=Enum.Font.GothamMedium, TextSize=9,
                TextColor3=Theme.TextHint, TextXAlignment=Enum.TextXAlignment.Left,
            }, sec)
            New("Frame", {
                AnchorPoint=Vector2.new(0,1), Position=UDim2.new(0,0,1,0),
                Size=UDim2.new(1,0,0,1), BackgroundColor3=Theme.Border,
            }, sec)
        end

        -- CreateGrid
        function TabObj:CreateGrid(callback, cellHeight)
            local ch = cellHeight or 38
            local gridContainer = New("Frame", {
                Size=UDim2.new(1,0,0,10),
                BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.Y,
            }, TabFrame)

            New("UIGridLayout", {
                CellSize=UDim2.new(0.5,-5,0,ch),
                CellPadding=UDim2.new(0,8,0,8),
                SortOrder=Enum.SortOrder.LayoutOrder,
            }, gridContainer)

            local function MakeColProxy()
                local proxy = {}

                local function MakeBlockInGrid(h)
                    local b = New("Frame", {
                        Size=UDim2.new(0,1,0,h or ch),
                        BackgroundColor3=Theme.Surface,
                    }, gridContainer)
                    Corner(10, b)
                    Stroke(Theme.Border, 0.5, b)
                    Padding(0,0,10,10, b)
                    return b
                end

                -- FIX #1: Toggle no grid com cores corretas
                function proxy:CreateToggle(opts2)
                    opts2 = opts2 or {}
                    local state = opts2.Default or false
                    local blk = MakeBlockInGrid(ch)
                    MakeLabel(blk, opts2.Name or "Toggle", opts2.Icon)
                    local track = New("Frame", {
                        AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,0,0.5,0),
                        Size=UDim2.new(0,38,0,21),
                        BackgroundColor3=state and Theme.AccentGreen or Theme.ToggleOff,
                    }, blk)
                    Corner(11, track)
                    local knob = New("Frame", {
                        Position=UDim2.new(0,state and 19 or 3,0.5,-7),
                        Size=UDim2.new(0,15,0,15), BackgroundColor3=Theme.White,
                    }, track)
                    Corner(8, knob)
                    local hitbox = New("TextButton", {Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=""}, blk)
                    local function SetState(v)
                        state=v
                        Tween(track,{BackgroundColor3=v and Theme.AccentGreen or Theme.ToggleOff})
                        Tween(knob,{Position=UDim2.new(0,v and 19 or 3,0.5,-7)})
                        if opts2.Callback then opts2.Callback(v) end
                    end
                    hitbox.MouseButton1Click:Connect(function() SetState(not state) end)
                    RegisterSearch(opts2.Name or "Toggle", blk)
                    return { SetState=SetState, GetState=function() return state end }
                end

                -- FIX #1: Button no grid — texto/ícone não saem do layout
                function proxy:CreateButton(opts2)
                    opts2 = opts2 or {}
                    local c = ButtonStyles[opts2.Style or "primary"] or ButtonStyles.primary
                    local blk = MakeBlockInGrid(ch)
                    local btn = New("TextButton", {
                        Size=UDim2.new(1,0,1,0), BackgroundColor3=c.bg,
                        Text="", AutoButtonColor=false,
                    }, blk)
                    Corner(8, btn)
                    Stroke(c.border, 0.5, btn)

                    local iconW = opts2.Icon and 28 or 0
                    if opts2.Icon then
                        New("TextLabel", {
                            Size=UDim2.new(0, iconW, 1, 0),
                            Position=UDim2.new(0, 6, 0, 0),
                            BackgroundTransparency=1, Text=opts2.Icon,
                            TextColor3=c.text, TextSize=14,
                            Font=Enum.Font.Gotham, RichText=false,
                            TextXAlignment=Enum.TextXAlignment.Left,
                        }, btn)
                    end
                    New("TextLabel", {
                        Size=UDim2.new(1, -(iconW + 8), 1, 0),
                        Position=UDim2.new(0, iconW + 4, 0, 0),
                        BackgroundTransparency=1, Text=opts2.Name or "Button",
                        Font=Enum.Font.GothamMedium, TextSize=12,
                        TextColor3=c.text, TextXAlignment=Enum.TextXAlignment.Center,
                        TextTruncate=Enum.TextTruncate.AtEnd,
                    }, btn)

                    AddHover(btn, c.bg, c.hover or c.bg)
                    local function DoClick()
                        Tween(btn,{BackgroundTransparency=0.35},0.06)
                        task.delay(0.14, function() Tween(btn,{BackgroundTransparency=0},0.1) end)
                        if opts2.Callback then opts2.Callback() end
                    end
                    btn.MouseButton1Click:Connect(DoClick)
                    if opts2.Keybind then
                        table.insert(ButtonHotkeys, {key=opts2.Keybind, cb=DoClick})
                    end
                    RegisterSearch(opts2.Name or "Button", blk)
                    return { SetText=function(t)
                        for _, c2 in pairs(btn:GetChildren()) do
                            if c2:IsA("TextLabel") then c2.Text=t end
                        end
                    end }
                end

                function proxy:CreateLabel(opts2)
                    opts2 = opts2 or {}
                    local blk = MakeBlockInGrid(ch)
                    New("TextLabel", {
                        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
                        Text=opts2.Text or "", Font=Enum.Font.Gotham, TextSize=12,
                        TextColor3=opts2.Color or Theme.TextMuted,
                        TextXAlignment=Enum.TextXAlignment.Left,
                        RichText=false, TextTruncate=Enum.TextTruncate.AtEnd,
                    }, blk)
                end

                return proxy
            end

            local col1 = MakeColProxy()
            local col2 = MakeColProxy()
            if callback then callback(col1, col2) end
            task.defer(function()
                local gl2 = gridContainer:FindFirstChildOfClass("UIGridLayout")
                if gl2 then
                    gridContainer.Size = UDim2.new(1,0,0,gl2.AbsoluteContentSize.Y+4)
                end
            end)
            return col1, col2
        end

        -- ─── CreateToggle (FIX #3: keybind "..." universal)
        function TabObj:CreateToggle(opts)
            opts = opts or {}
            local state = opts.Default or false
            local blk = MakeBlock(38)
            MakeLabel(blk, opts.Name or "Toggle", opts.Icon)

            -- Toggle (direita)
            local track = New("Frame", {
                AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,0,0.5,0),
                Size=UDim2.new(0,40,0,22),
                BackgroundColor3=state and Theme.AccentGreen or Theme.ToggleOff,
            }, blk)
            Corner(11, track)
            Stroke(Theme.Border, 0.5, track)
            local knob = New("Frame", {
                Position=UDim2.new(0,state and 20 or 3,0.5,-7),
                Size=UDim2.new(0,16,0,16), BackgroundColor3=Theme.White,
            }, track)
            Corner(8, knob)

            -- FIX #3: keybind badge antes do toggle
            local kbKey = nil
            if opts.Keybind ~= nil then
                local defaultKey = type(opts.Keybind) ~= "string" and opts.Keybind or nil
                MakeInlineKeybind(blk, defaultKey, function(newKey)
                    kbKey = newKey
                    if opts.KeybindCallback then opts.KeybindCallback(newKey) end
                end, 46) -- offset para não sobrepor o toggle
                kbKey = defaultKey
            end

            local hitbox = New("TextButton", {
                Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="",
            }, blk)

            local function SetState(v)
                state = v
                Tween(track,{BackgroundColor3=v and Theme.AccentGreen or Theme.ToggleOff})
                Tween(knob,{Position=UDim2.new(0,v and 20 or 3,0.5,-7)})
                if opts.Callback then opts.Callback(v) end
                if opts.Flag then _G["FL_"..opts.Flag] = v end
            end
            hitbox.MouseButton1Click:Connect(function() SetState(not state) end)

            RegisterSearch(opts.Name or "Toggle", blk)
            return { SetState=SetState, GetState=function() return state end }
        end

        -- ─── CreateSlider (FIX #3: keybind universal)
        function TabObj:CreateSlider(opts)
            opts = opts or {}
            local min     = opts.Min or 0
            local max     = opts.Max or 100
            local dec     = opts.Decimals
            local current = opts.Default or min

            local blk = MakeBlock(54)

            -- Linha do topo: ícone + nome + keybind badge + valor
            local topRow = New("Frame", {
                Size=UDim2.new(1,0,0,20), BackgroundTransparency=1,
            }, blk)

            if opts.Icon then
                New("TextLabel", {
                    Position=UDim2.new(0,0,0,0), Size=UDim2.new(0,18,1,0),
                    BackgroundTransparency=1, Text=opts.Icon,
                    TextColor3=Theme.Accent, TextSize=13, Font=Enum.Font.Gotham,
                    RichText=false,
                }, topRow)
            end

            local iconOff = opts.Icon and 22 or 0
            New("TextLabel", {
                Size=UDim2.new(0.5, -iconOff, 1, 0),
                Position=UDim2.new(0, iconOff, 0, 0),
                BackgroundTransparency=1, Text=opts.Name or "Slider",
                Font=Enum.Font.Gotham, TextSize=12,
                TextColor3=Theme.TextPrimary, TextXAlignment=Enum.TextXAlignment.Left,
                TextTruncate=Enum.TextTruncate.AtEnd,
            }, topRow)

            -- Valor à direita da linha do topo
            local valLbl = New("TextLabel", {
                AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,0,0.5,0),
                Size=UDim2.new(0,40,1,0), BackgroundTransparency=1,
                Text=tostring(current), Font=Enum.Font.GothamMedium,
                TextSize=12, TextColor3=Theme.Accent,
                TextXAlignment=Enum.TextXAlignment.Right,
            }, topRow)

            -- FIX #3: keybind badge entre nome e valor
            if opts.Keybind ~= nil then
                local defaultKey = type(opts.Keybind) ~= "string" and opts.Keybind or nil
                MakeInlineKeybind(topRow, defaultKey, function(newKey)
                    if opts.KeybindCallback then opts.KeybindCallback(newKey) end
                end, 46) -- offset para não cobrir o valLbl
            end

            -- Track do slider
            local track = New("Frame", {
                Position=UDim2.new(0,0,0,28), Size=UDim2.new(1,0,0,6),
                BackgroundColor3=Theme.ToggleOff,
            }, blk)
            Corner(3, track)
            local fill = New("Frame", {
                Size=UDim2.new((current-min)/(max-min),0,1,0),
                BackgroundColor3=Theme.AccentGreen,
            }, track)
            Corner(3, fill)
            local thumb = New("Frame", {
                AnchorPoint=Vector2.new(0.5,0.5),
                Position=UDim2.new((current-min)/(max-min),0,0.5,0),
                Size=UDim2.new(0,16,0,16), BackgroundColor3=Theme.White,
            }, track)
            Corner(8, thumb)
            Stroke(Theme.Border, 0.5, thumb)
            local sliderBtn = New("TextButton", {
                Size=UDim2.new(1,0,4,0), Position=UDim2.new(0,0,-1.5,0),
                BackgroundTransparency=1, Text="", ZIndex=5,
            }, track)

            local sdrag = false
            local function Update(inp)
                local rel = math.clamp((inp.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
                local val = dec
                    and tonumber(("%."..(dec).."f"):format(min+(max-min)*rel))
                    or  math.floor(min+(max-min)*rel)
                current = val
                fill.Size       = UDim2.new(rel,0,1,0)
                thumb.Position  = UDim2.new(rel,0,0.5,0)
                valLbl.Text     = tostring(val)
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
                current=v
                local rel=math.clamp((v-min)/(max-min),0,1)
                fill.Size      = UDim2.new(rel,0,1,0)
                thumb.Position = UDim2.new(rel,0,0.5,0)
                valLbl.Text    = tostring(v)
            end
            RegisterSearch(opts.Name or "Slider", blk)
            return { SetValue=SetValue, GetValue=function() return current end }
        end

        -- ─── CreateDropdown (FIX #3 + #7)
        function TabObj:CreateDropdown(opts)
            opts = opts or {}
            local items    = opts.Items or {}
            local selected = opts.Default or (items[1] or "")
            local open     = false
            local BASE_H   = 70

            local container = New("Frame", {
                Size=UDim2.new(1,0,0,BASE_H), BackgroundTransparency=1,
            }, TabFrame)
            List(4, container)

            local headerRow = New("Frame", {
                Size=UDim2.new(1,0,0,20), BackgroundTransparency=1,
            }, container)

            -- Ícone + nome
            local iconOff = opts.Icon and 22 or 0
            if opts.Icon then
                New("TextLabel", {
                    Size=UDim2.new(0,20,1,0), BackgroundTransparency=1,
                    Text=opts.Icon, TextColor3=Theme.Accent, TextSize=13,
                    Font=Enum.Font.Gotham, RichText=false,
                }, headerRow)
            end
            New("TextLabel", {
                Size=UDim2.new(0.55,-iconOff,1,0),
                Position=UDim2.new(0,iconOff,0,0),
                BackgroundTransparency=1, Text=opts.Name or "Dropdown",
                Font=Enum.Font.Gotham, TextSize=12,
                TextColor3=Theme.TextPrimary, TextXAlignment=Enum.TextXAlignment.Left,
                TextTruncate=Enum.TextTruncate.AtEnd,
            }, headerRow)

            -- FIX #3: keybind no dropdown
            if opts.Keybind ~= nil then
                local defaultKey = type(opts.Keybind) ~= "string" and opts.Keybind or nil
                MakeInlineKeybind(headerRow, defaultKey, function(newKey)
                    if opts.KeybindCallback then opts.KeybindCallback(newKey) end
                end)
            end

            local dropBtn = New("TextButton", {
                Size=UDim2.new(1,0,0,32), BackgroundColor3=Theme.InputBg,
                Text="", AutoButtonColor=false,
            }, container)
            Corner(8, dropBtn)
            Stroke(Theme.Border, 0.5, dropBtn)
            Padding(0,0,12,12, dropBtn)

            local selLbl = New("TextLabel", {
                Size=UDim2.new(1,-24,1,0), BackgroundTransparency=1,
                Text=selected, Font=Enum.Font.Gotham, TextSize=12,
                TextColor3=Theme.TextPrimary, TextXAlignment=Enum.TextXAlignment.Left,
                TextTruncate=Enum.TextTruncate.AtEnd,
            }, dropBtn)
            local chevron = New("TextLabel", {
                AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-10,0.5,0),
                Size=UDim2.new(0,14,0,14), BackgroundTransparency=1,
                Text=Icons.ChevronDown, Font=Enum.Font.Gotham,
                TextSize=12, TextColor3=Theme.TextMuted,
            }, dropBtn)
            AddHover(dropBtn, Theme.InputBg, Theme.Surface2)

            local listFrame = New("Frame", {
                Size=UDim2.new(1,0,0,0), BackgroundColor3=Theme.Surface2,
                ClipsDescendants=true, Visible=false,
            }, container)
            Corner(8, listFrame)
            Stroke(Theme.Border, 0.5, listFrame)
            List(0, listFrame)

            local function CloseList()
                open = false
                Tween(listFrame, { Size=UDim2.new(1,0,0,0) }, 0.12)
                task.delay(0.14, function() listFrame.Visible = false end)
                Tween(container, { Size=UDim2.new(1,0,0,BASE_H) }, 0.12)
                Tween(chevron, { Rotation=0 }, 0.12)
            end

            local function Build()
                for _, item in ipairs(items) do
                    local ib = New("TextButton", {
                        Size=UDim2.new(1,0,0,30),
                        BackgroundColor3=item==selected and Theme.Surface3 or Theme.Surface2,
                        Text="", AutoButtonColor=false,
                    }, listFrame)
                    Padding(0,0,12,0, ib)
                    New("TextLabel", {
                        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
                        Text=item, Font=Enum.Font.Gotham, TextSize=12,
                        TextColor3=item==selected and Theme.Accent or Theme.TextPrimary,
                        TextXAlignment=Enum.TextXAlignment.Left,
                        TextTruncate=Enum.TextTruncate.AtEnd,
                    }, ib)
                    AddHover(ib,
                        item==selected and Theme.Surface3 or Theme.Surface2,
                        Theme.Surface3
                    )
                    ib.MouseButton1Click:Connect(function()
                        selected = item; selLbl.Text = item
                        CloseList()
                        if opts.Callback then opts.Callback(item) end
                        if opts.Flag then _G["FL_"..opts.Flag] = item end
                        listFrame:ClearAllChildren(); List(0,listFrame); Build()
                    end)
                end
            end

            dropBtn.MouseButton1Click:Connect(function()
                if open then
                    CloseList()
                else
                    open = true
                    listFrame:ClearAllChildren(); List(0,listFrame); Build()
                    local h = math.min(#items * 30, 180)
                    listFrame.Size    = UDim2.new(1,0,0,0)
                    listFrame.Visible = true
                    Tween(listFrame, { Size=UDim2.new(1,0,0,h) }, 0.14)
                    Tween(container, { Size=UDim2.new(1,0,0,BASE_H+h+4) }, 0.14)
                    Tween(chevron, { Rotation=180 }, 0.14)
                end
            end)

            RegisterSearch(opts.Name or "Dropdown", container)
            return {
                GetSelected = function() return selected end,
                SetItems    = function(t)
                    items = t; selected = t[1] or ""; selLbl.Text = selected
                    if open then listFrame:ClearAllChildren(); List(0,listFrame); Build() end
                end,
            }
        end

        -- ─── CreateButton (FIX #1 + #3: cores corretas + keybind)
        function TabObj:CreateButton(opts)
            opts = opts or {}
            local c = ButtonStyles[opts.Style or "primary"] or ButtonStyles.primary
            local blk = MakeBlock(38)

            local btn = New("TextButton", {
                Size=UDim2.new(1,0,1,0), BackgroundColor3=c.bg,
                Text="", AutoButtonColor=false,
            }, blk)
            Corner(8, btn)
            Stroke(c.border, 0.5, btn)

            -- FIX #1: ícone fixo à esquerda, texto no centro, sem sobreposição
            local iconW = opts.Icon and 28 or 0
            if opts.Icon then
                New("TextLabel", {
                    Size=UDim2.new(0, iconW, 1, 0),
                    Position=UDim2.new(0, 8, 0, 0),
                    BackgroundTransparency=1, Text=opts.Icon,
                    TextColor3=c.text, TextSize=14,
                    Font=Enum.Font.Gotham, RichText=false,
                    TextXAlignment=Enum.TextXAlignment.Left,
                }, btn)
            end

            -- FIX #3: keybind badge no bloco (fora do btn para não conflitar)
            local kbW = opts.Keybind ~= nil and 52 or 0
            local kbBadge = nil
            if opts.Keybind ~= nil then
                local defaultKey = type(opts.Keybind) ~= "string" and opts.Keybind or nil
                kbBadge = MakeInlineKeybind(blk, defaultKey, function(newKey)
                    -- Atualiza hotkey
                    for i, bh in ipairs(ButtonHotkeys) do
                        if bh._ref == btn then
                            table.remove(ButtonHotkeys, i); break
                        end
                    end
                    table.insert(ButtonHotkeys, {key=newKey, cb=function() pcall(opts.Callback) end, _ref=btn})
                end)
            end

            -- Texto centrado no espaço disponível
            New("TextLabel", {
                Size=UDim2.new(1, -(iconW + 8), 1, 0),
                Position=UDim2.new(0, iconW + 4, 0, 0),
                BackgroundTransparency=1, Text=opts.Name or "Button",
                Font=Enum.Font.GothamMedium, TextSize=12,
                TextColor3=c.text, TextXAlignment=Enum.TextXAlignment.Center,
                TextTruncate=Enum.TextTruncate.AtEnd,
            }, btn)

            AddHover(btn, c.bg, c.hover or c.bg)

            local function DoClick()
                Tween(btn,{BackgroundTransparency=0.35},0.06)
                task.delay(0.14, function() Tween(btn,{BackgroundTransparency=0},0.1) end)
                if opts.Callback then opts.Callback() end
            end
            btn.MouseButton1Click:Connect(DoClick)

            if opts.Keybind ~= nil and type(opts.Keybind) ~= "string" then
                table.insert(ButtonHotkeys, {key=opts.Keybind, cb=DoClick, _ref=btn})
            end

            RegisterSearch(opts.Name or "Button", blk)
            return {
                SetText = function(t)
                    for _, child in pairs(btn:GetChildren()) do
                        if child:IsA("TextLabel") and child.TextXAlignment==Enum.TextXAlignment.Center then
                            child.Text = t
                        end
                    end
                end
            }
        end

        -- ─── CreateInput (FIX #3: keybind universal)
        function TabObj:CreateInput(opts)
            opts = opts or {}
            local cont = New("Frame", {
                Size=UDim2.new(1,0,0,60), BackgroundTransparency=1,
            }, TabFrame)
            List(4, cont)

            local headerRow = New("Frame", {Size=UDim2.new(1,0,0,18),BackgroundTransparency=1}, cont)

            local iconOff = opts.Icon and 22 or 0
            if opts.Icon then
                New("TextLabel", {
                    Size=UDim2.new(0,18,1,0), BackgroundTransparency=1,
                    Text=opts.Icon, TextColor3=Theme.Accent, TextSize=13,
                    Font=Enum.Font.Gotham, RichText=false,
                }, headerRow)
            end
            New("TextLabel", {
                Size=UDim2.new(0.55,-iconOff,1,0),
                Position=UDim2.new(0,iconOff,0,0),
                BackgroundTransparency=1, Text=opts.Name or "Input",
                Font=Enum.Font.Gotham, TextSize=12,
                TextColor3=Theme.TextPrimary, TextXAlignment=Enum.TextXAlignment.Left,
                TextTruncate=Enum.TextTruncate.AtEnd,
            }, headerRow)

            -- FIX #3: keybind no input
            if opts.Keybind ~= nil then
                local defaultKey = type(opts.Keybind) ~= "string" and opts.Keybind or nil
                MakeInlineKeybind(headerRow, defaultKey, function(newKey)
                    if opts.KeybindCallback then opts.KeybindCallback(newKey) end
                end)
            end

            local inp = New("Frame", {
                Size=UDim2.new(1,0,0,32), BackgroundColor3=Theme.InputBg,
            }, cont)
            Corner(8, inp)
            local inpStroke = Stroke(Theme.Border, 0.5, inp)
            Padding(0,0,12,12, inp)

            local tb = New("TextBox", {
                Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
                PlaceholderText=opts.Placeholder or "Digite aqui...",
                PlaceholderColor3=Theme.TextMuted, Text=opts.Default or "",
                TextColor3=Theme.TextPrimary, Font=Enum.Font.Gotham,
                TextSize=12, TextXAlignment=Enum.TextXAlignment.Left,
                ClearTextOnFocus=false,
            }, inp)

            tb.Focused:Connect(function()
                Tween(inpStroke,{Color=Theme.Accent,Thickness=1},0.15)
            end)
            tb.FocusLost:Connect(function(enter)
                Tween(inpStroke,{Color=Theme.Border,Thickness=0.5},0.15)
                if enter and opts.Callback then opts.Callback(tb.Text) end
                if opts.Flag then _G["FL_"..opts.Flag] = tb.Text end
            end)

            RegisterSearch(opts.Name or "Input", cont)
            return {
                GetValue = function() return tb.Text end,
                SetValue = function(v) tb.Text = v end,
            }
        end

        -- ─── CreateKeybind standalone (FIX #3)
        function TabObj:CreateKeybind(opts)
            opts = opts or {}
            local key      = opts.Default or Enum.KeyCode.Unknown
            local listening = false
            local blk = MakeBlock(38)
            MakeLabel(blk, opts.Name or "Keybind", opts.Icon)

            local kBtn = New("TextButton", {
                AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,0,0.5,0),
                Size=UDim2.new(0,82,0,26), BackgroundColor3=Theme.InputBg,
                Text=key.Name or "NONE", Font=Enum.Font.GothamMedium,
                TextSize=11, TextColor3=Theme.Accent, AutoButtonColor=false,
                TextTruncate=Enum.TextTruncate.AtEnd,
            }, blk)
            Corner(6, kBtn)
            Stroke(Theme.Accent, 0.5, kBtn, 0.6)

            kBtn.MouseButton1Click:Connect(function()
                listening=true; kBtn.Text="..."; kBtn.TextColor3=Theme.TextMuted
                Tween(kBtn,{BackgroundColor3=Theme.Surface2},0.1)
            end)
            UserInputService.InputBegan:Connect(function(inp, gp)
                if listening and not gp then
                    if inp.KeyCode == Enum.KeyCode.Escape then
                        listening=false; kBtn.Text=key.Name; kBtn.TextColor3=Theme.Accent
                        Tween(kBtn,{BackgroundColor3=Theme.InputBg},0.1)
                        return
                    end
                    listening=false; key=inp.KeyCode
                    kBtn.Text=key.Name; kBtn.TextColor3=Theme.Accent
                    Tween(kBtn,{BackgroundColor3=Theme.InputBg},0.1)
                    if opts.Callback then opts.Callback(key) end
                    if opts.Flag then _G["FL_"..opts.Flag]=key end
                end
            end)

            RegisterSearch(opts.Name or "Keybind", blk)
            return { GetKey=function() return key end }
        end

        -- ─── CreateLabel (FIX #2 + #7: RichText=true com sanitização, sem sobreposição)
        function TabObj:CreateLabel(opts)
            opts = opts or {}
            local useRich = opts.RichText ~= false  -- FIX #2: padrão true

            if opts.Icon and opts.Icon ~= "" then
                local row = New("Frame", {
                    Size=UDim2.new(1,0,0,24), BackgroundTransparency=1,
                }, TabFrame)
                -- Ícone à esquerda
                New("TextLabel", {
                    Size=UDim2.new(0,18,1,0),
                    Position=UDim2.new(0,0,0,0),
                    BackgroundTransparency=1,
                    Text=opts.Icon, TextColor3=Theme.Accent, TextSize=13,
                    Font=Enum.Font.Gotham, RichText=false,
                    TextXAlignment=Enum.TextXAlignment.Left,
                }, row)
                -- Texto começa depois do ícone (sem sobreposição)
                local lbl = New("TextLabel", {
                    Size=UDim2.new(1,-22,1,0),
                    Position=UDim2.new(0,22,0,0),
                    BackgroundTransparency=1,
                    Text=SanitizeRich(opts.Text or ""),
                    Font=Enum.Font.Gotham, TextSize=12,
                    TextColor3=opts.Color or Theme.TextMuted,
                    TextXAlignment=Enum.TextXAlignment.Left,
                    RichText=useRich,
                    TextTruncate=Enum.TextTruncate.AtEnd,
                }, row)
                RegisterSearch(opts.Text or "Label", row)
                return { SetText=function(t) lbl.Text=SanitizeRich(t) end }
            else
                local lbl = New("TextLabel", {
                    Size=UDim2.new(1,0,0,24), BackgroundTransparency=1,
                    Text=SanitizeRich(opts.Text or ""),
                    Font=Enum.Font.Gotham, TextSize=12,
                    TextColor3=opts.Color or Theme.TextMuted,
                    TextXAlignment=Enum.TextXAlignment.Left,
                    RichText=useRich,
                    TextTruncate=Enum.TextTruncate.AtEnd,
                }, TabFrame)
                RegisterSearch(opts.Text or "Label", lbl)
                return { SetText=function(t) lbl.Text=SanitizeRich(t) end }
            end
        end

        -- ─── CreateInfo (FIX #2 + #7: RichText=true, ícone separado, sem sobreposição)
        function TabObj:CreateInfo(opts)
            opts = opts or {}
            local lines   = opts.Lines or {}
            local useRich = opts.RichText ~= false  -- FIX #2: padrão true

            local boxH = 16 + math.max(#lines, 1) * 20 + 8
            local box = New("Frame", {
                Size=UDim2.new(1,0,0,boxH),
                BackgroundColor3=Theme.Surface,
            }, TabFrame)
            Corner(10, box)
            Stroke(Theme.Border, 0.5, box)

            -- FIX #7: padding direito maior para acomodar badge "i" sem sobrepor texto
            Padding(10, 10, 14, 32, box)
            List(3, box)

            -- Badge "i" no canto superior direito
            local iconBadge = New("Frame", {
                AnchorPoint=Vector2.new(1,0),
                Position=UDim2.new(1,-8,0,8),
                Size=UDim2.new(0,18,0,18),
                BackgroundColor3=Theme.AccentDim,
            }, box)
            Corner(9, iconBadge)
            New("TextLabel", {
                Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
                Text="i", Font=Enum.Font.GothamBold, TextSize=11,
                TextColor3=Theme.Accent,
                TextXAlignment=Enum.TextXAlignment.Center,
                RichText=false,
            }, iconBadge)

            -- FIX #2: linhas com RichText=true para <b>, <i>, etc.
            for _, line in ipairs(lines) do
                New("TextLabel", {
                    Size=UDim2.new(1,0,0,18), BackgroundTransparency=1,
                    Text=SanitizeRich(line),
                    Font=Enum.Font.Gotham, TextSize=11,
                    TextColor3=Theme.TextSecondary,
                    TextXAlignment=Enum.TextXAlignment.Left,
                    RichText=useRich,  -- FIX #2
                    TextTruncate=Enum.TextTruncate.AtEnd,
                }, box)
            end
        end

        return TabObj
    end

    function WindowObj:Notify(opts)  ForgeLib:Notify(opts) end
    function WindowObj:Destroy()     ScreenGui:Destroy()   end
    function WindowObj:SetVisible(v) SyncVisible(v)        end

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
