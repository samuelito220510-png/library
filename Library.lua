local InputService = game:GetService('UserInputService')
local TextService = game:GetService('TextService')
local CoreGui = game:GetService('CoreGui')
local Teams = game:GetService('Teams')
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
local RenderStepped = RunService.RenderStepped
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end)

local ScreenGui = Instance.new('ScreenGui')
ProtectGui(ScreenGui)
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.Parent = CoreGui

local Toggles = {}
local Options = {}
getgenv().Toggles = Toggles
getgenv().Options = Options

-- ================================================================
--  THEME SYSTEM — Modern Minimalist Dark
-- ================================================================
local Theme = {
    Background   = Color3.fromRGB(13, 13, 15),
    Surface      = Color3.fromRGB(22, 22, 26),
    Elevated     = Color3.fromRGB(30, 30, 36),
    Primary      = Color3.fromRGB(99, 102, 241),
    PrimaryHover = Color3.fromRGB(129, 140, 248),
    PrimaryMuted = Color3.fromRGB(67, 56, 202),
    TextPrimary   = Color3.fromRGB(243, 244, 246),
    TextSecondary = Color3.fromRGB(156, 163, 175),
    TextMuted     = Color3.fromRGB(107, 114, 128),
    Border       = Color3.fromRGB(39, 39, 46),
    BorderHover  = Color3.fromRGB(63, 63, 70),
    BorderActive = Color3.fromRGB(99, 102, 241),
    Success = Color3.fromRGB(34, 197, 94),
    Warning = Color3.fromRGB(251, 191, 36),
    Error   = Color3.fromRGB(239, 68, 68),
    Shadow = Color3.fromRGB(0, 0, 0),
}

-- ================================================================
--  ANIMATION SYSTEM
-- ================================================================
local Anim = {
    Fast   = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Normal = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Smooth = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Bounce = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
}

local function Tween(Instance, Properties, Info)
    Info = Info or Anim.Normal
    TweenService:Create(Instance, Info, Properties):Play()
end

local function SetCorner(Instance, Radius)
    Radius = Radius or UDim.new(0, 6)
    local Corner = Instance:FindFirstChildOfClass('UICorner')
    if not Corner then
        Corner = Instance.new('UICorner')
        Corner.Parent = Instance
    end
    Corner.CornerRadius = Radius
end

local function SetStroke(Instance, Color, Thickness)
    Thickness = Thickness or 1
    local Stroke = Instance:FindFirstChildOfClass('UIStroke')
    if not Stroke then
        Stroke = Instance.new('UIStroke')
        Stroke.Parent = Instance
    end
    Stroke.Color = Color or Theme.Border
    Stroke.Thickness = Thickness
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
end

local function SetShadow(Instance, Offset, Size, Transparency)
    local Shadow = Instance:FindFirstChild('__Shadow')
    if Shadow then Shadow:Destroy() end

    Shadow = Instance.new('ImageLabel')
    Shadow.Name = '__Shadow'
    Shadow.BackgroundTransparency = 1
    Shadow.Image = 'rbxassetid://1316045217'
    Shadow.ImageColor3 = Theme.Shadow
    Shadow.ImageTransparency = Transparency or 0.6
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    Shadow.Size = UDim2.new(1, Size or 20, 1, Size or 20)
    Shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    Shadow.ZIndex = Instance.ZIndex - 1
    Shadow.Parent = Instance
end

-- ================================================================
--  CORE LIBRARY
-- ================================================================
local Library = {
    Registry = {};
    RegistryMap = {};
    HudRegistry = {};
    OpenedFrames = {};
    DependencyBoxes = {};
    Signals = {};
    ScreenGui = ScreenGui;
    Theme = Theme;
    Anim = Anim;
    Font = Enum.Font.Gotham;
    FontBold = Enum.Font.GothamBold;
    FontMedium = Enum.Font.GothamMedium;
    FontMono = Enum.Font.Code;
}

-- Rainbow
local RainbowStep = 0
local Hue = 0
table.insert(Library.Signals, RenderStepped:Connect(function(Delta)
    RainbowStep = RainbowStep + Delta
    if RainbowStep >= (1 / 60) then
        RainbowStep = 0
        Hue = Hue + (1 / 400)
        if Hue > 1 then Hue = 0 end
        Library.CurrentRainbowHue = Hue
        Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1)
    end
end))

-- ================================================================
--  UTILITIES
-- ================================================================
function Library:SafeCallback(f, ...)
    if not f then return end
    if not Library.NotifyOnError then return f(...) end
    local success, event = pcall(f, ...)
    if not success then
        local _, i = event:find(':%d+: ')
        if not i then return Library:Notify(event) end
        return Library:Notify(event:sub(i + 1), 3)
    end
end

function Library:AttemptSave()
    if Library.SaveManager then
        Library.SaveManager:Save()
    end
end

function Library:Create(Class, Properties)
    local _Instance = Class
    if type(Class) == 'string' then
        _Instance = Instance.new(Class)
    end
    for Property, Value in next, Properties do
        _Instance[Property] = Value
    end
    return _Instance
end

function Library:CreateLabel(Properties, IsHud)
    local Label = Library:Create('TextLabel', {
        BackgroundTransparency = 1;
        Font = Library.Font;
        TextColor3 = Theme.TextPrimary;
        TextSize = 14;
        RichText = true;
    })
    Library:AddToRegistry(Label, { TextColor3 = 'TextPrimary' }, IsHud)
    return Library:Create(Label, Properties)
end

function Library:GetTextBounds(Text, Font, Size, Resolution)
    local Bounds = TextService:GetTextSize(Text, Size, Font, Resolution or Vector2.new(1920, 1080))
    return Bounds.X, Bounds.Y
end

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
    return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB
end

function Library:AddToRegistry(Instance, Properties, IsHud)
    local Idx = #Library.Registry + 1
    local Data = { Instance = Instance; Properties = Properties; Idx = Idx }
    table.insert(Library.Registry, Data)
    Library.RegistryMap[Instance] = Data
    if IsHud then table.insert(Library.HudRegistry, Data) end
end

function Library:RemoveFromRegistry(Instance)
    local Data = Library.RegistryMap[Instance]
    if Data then
        for Idx = #Library.Registry, 1, -1 do
            if Library.Registry[Idx] == Data then table.remove(Library.Registry, Idx) end
        end
        for Idx = #Library.HudRegistry, 1, -1 do
            if Library.HudRegistry[Idx] == Data then table.remove(Library.HudRegistry, Idx) end
        end
        Library.RegistryMap[Instance] = nil
    end
end

function Library:UpdateColorsUsingRegistry()
    for _, Object in next, Library.Registry do
        for Property, ColorIdx in next, Object.Properties do
            if type(ColorIdx) == 'string' then
                Object.Instance[Property] = Theme[ColorIdx] or ColorIdx
            elseif type(ColorIdx) == 'function' then
                Object.Instance[Property] = ColorIdx()
            end
        end
    end
end

function Library:GiveSignal(Signal)
    table.insert(Library.Signals, Signal)
end

function Library:Unload()
    for Idx = #Library.Signals, 1, -1 do
        local Connection = table.remove(Library.Signals, Idx)
        Connection:Disconnect()
    end
    if Library.OnUnload then Library.OnUnload() end
    ScreenGui:Destroy()
end

function Library:OnUnload(Callback)
    Library.OnUnload = Callback
end

Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(Instance)
    if Library.RegistryMap[Instance] then
        Library:RemoveFromRegistry(Instance)
    end
end))

-- ================================================================
--  DRAGGING — Smooth, modern
-- ================================================================
function Library:MakeDraggable(Instance, Cutoff)
    Instance.Active = true
    local Dragging = false
    local DragStart, StartPos

    Instance.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            local ObjPos = Vector2.new(
                Mouse.X - Instance.AbsolutePosition.X,
                Mouse.Y - Instance.AbsolutePosition.Y
            )
            if ObjPos.Y > (Cutoff or 40) then return end
            Dragging = true
            DragStart = Input.Position
            StartPos = Instance.Position
            Input.Changed:Connect(function()
                if Input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                end
            end)
        end
    end)

    Instance.InputChanged:Connect(function(Input)
        if Dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
            local Delta = Input.Position - DragStart
            Instance.Position = UDim2.new(
                StartPos.X.Scale, StartPos.X.Offset + Delta.X,
                StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y
            )
        end
    end)
end

-- ================================================================
--  TOOLTIP — Modern floating tooltip
-- ================================================================
function Library:AddToolTip(InfoStr, HoverInstance)
    local X, Y = Library:GetTextBounds(InfoStr, Library.Font, 13)

    local Tooltip = Library:Create('Frame', {
        BackgroundColor3 = Theme.Elevated,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(X + 16, Y + 12),
        ZIndex = 200,
        Parent = Library.ScreenGui,
        Visible = false,
        ClipsDescendants = true,
    })
    SetCorner(Tooltip, UDim.new(0, 6))
    SetShadow(Tooltip, 0, 12, 0.7)

    local Label = Library:CreateLabel({
        Position = UDim2.fromOffset(8, 6),
        Size = UDim2.fromOffset(X, Y),
        TextSize = 13,
        Text = InfoStr,
        TextColor3 = Theme.TextSecondary,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 201,
        Parent = Tooltip,
    })

    Library:AddToRegistry(Tooltip, { BackgroundColor3 = 'Elevated' })
    Library:AddToRegistry(Label, { TextColor3 = 'TextSecondary' })

    local IsHovering = false

    HoverInstance.MouseEnter:Connect(function()
        if Library:MouseIsOverOpenedFrame() then return end
        IsHovering = true
        Tooltip.Position = UDim2.fromOffset(Mouse.X + 18, Mouse.Y + 14)
        Tooltip.Size = UDim2.fromOffset(X + 16, 0)
        Tooltip.Visible = true
        Tween(Tooltip, {Size = UDim2.fromOffset(X + 16, Y + 12)}, Anim.Fast)
        while IsHovering do
            RunService.Heartbeat:Wait()
            Tooltip.Position = UDim2.fromOffset(Mouse.X + 18, Mouse.Y + 14)
        end
    end)

    HoverInstance.MouseLeave:Connect(function()
        IsHovering = false
        Tween(Tooltip, {Size = UDim2.fromOffset(X + 16, 0)}, Anim.Fast)
        task.delay(0.15, function()
            if not IsHovering then Tooltip.Visible = false end
        end)
    end)
end

-- ================================================================
--  HIGHLIGHT SYSTEM
-- ================================================================
function Library:OnHighlight(HighlightInstance, Instance, Properties, PropertiesDefault)
    HighlightInstance.MouseEnter:Connect(function()
        local Reg = Library.RegistryMap[Instance]
        for Property, ColorIdx in next, Properties do
            Tween(Instance, {[Property] = Theme[ColorIdx] or ColorIdx}, Anim.Fast)
            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx
            end
        end
    end)

    HighlightInstance.MouseLeave:Connect(function()
        local Reg = Library.RegistryMap[Instance]
        for Property, ColorIdx in next, PropertiesDefault do
            Tween(Instance, {[Property] = Theme[ColorIdx] or ColorIdx}, Anim.Fast)
            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx
            end
        end
    end)
end

-- ================================================================
--  MOUSE UTILS
-- ================================================================
function Library:MouseIsOverOpenedFrame()
    for Frame, _ in next, Library.OpenedFrames do
        local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize
        if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
            and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then
            return true
        end
    end
    return false
end

function Library:IsMouseOverFrame(Frame)
    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize
    return Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
        and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y
end

function Library:UpdateDependencyBoxes()
    for _, Depbox in next, Library.DependencyBoxes do
        Depbox:Update()
    end
end

-- ================================================================
--  PLAYER/TEAM HELPERS
-- ================================================================
local function GetPlayersString()
    local PlayerList = Players:GetPlayers()
    for i = 1, #PlayerList do PlayerList[i] = PlayerList[i].Name end
    table.sort(PlayerList, function(a, b) return a < b end)
    return PlayerList
end

local function GetTeamsString()
    local TeamList = Teams:GetTeams()
    for i = 1, #TeamList do TeamList[i] = TeamList[i].Name end
    table.sort(TeamList, function(a, b) return a < b end)
    return TeamList
end

-- ================================================================
--  NOTIFICATION SYSTEM — Modern toast notifications
-- ================================================================
Library.NotificationArea = Library:Create('Frame', {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 20, 0, 20),
    Size = UDim2.new(0, 320, 1, -40),
    ZIndex = 100,
    Parent = ScreenGui,
})

Library:Create('UIListLayout', {
    Padding = UDim.new(0, 8),
    FillDirection = Enum.FillDirection.Vertical,
    SortOrder = Enum.SortOrder.LayoutOrder,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    Parent = Library.NotificationArea,
})

function Library:Notify(Text, Time)
    Time = Time or 4
    local XSize, YSize = Library:GetTextBounds(Text, Library.Font, 13, Vector2.new(280, math.huge))
    YSize = math.max(YSize + 16, 44)

    local NotifyOuter = Library:Create('Frame', {
        BackgroundColor3 = Theme.Elevated,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 0, YSize),
        ClipsDescendants = true,
        ZIndex = 100,
        Parent = Library.NotificationArea,
    })
    SetCorner(NotifyOuter, UDim.new(0, 10))
    SetShadow(NotifyOuter, 0, 16, 0.75)

    local AccentBar = Library:Create('Frame', {
        BackgroundColor3 = Theme.Primary,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 3, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        ZIndex = 102,
        Parent = NotifyOuter,
    })
    SetCorner(AccentBar, UDim.new(0, 10))

    local Inner = Library:Create('Frame', {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -16, 1, 0),
        ZIndex = 101,
        Parent = NotifyOuter,
    })

    local NotifyLabel = Library:CreateLabel({
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        Text = Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextSize = 13,
        TextColor3 = Theme.TextPrimary,
        ZIndex = 103,
        Parent = Inner,
    })

    Library:AddToRegistry(NotifyOuter, { BackgroundColor3 = 'Elevated' })
    Library:AddToRegistry(AccentBar, { BackgroundColor3 = 'Primary' })

    -- Animate in
    NotifyOuter.Size = UDim2.new(0, 0, 0, YSize)
    Tween(NotifyOuter, {Size = UDim2.new(0, XSize + 28, 0, YSize)}, Anim.Bounce)

    -- Progress bar
    local ProgressBar = Library:Create('Frame', {
        BackgroundColor3 = Theme.PrimaryMuted,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, -2),
        ZIndex = 104,
        Parent = NotifyOuter,
    })

    local ProgressFill = Library:Create('Frame', {
        BackgroundColor3 = Theme.Primary,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 105,
        Parent = ProgressBar,
    })

    Tween(ProgressFill, {Size = UDim2.new(0, 0, 1, 0)}, TweenInfo.new(Time, Enum.EasingStyle.Linear))

    task.spawn(function()
        task.wait(Time)
        Tween(NotifyOuter, {Size = UDim2.new(0, 0, 0, YSize)}, Anim.Normal)
        task.wait(0.3)
        NotifyOuter:Destroy()
    end)
end

-- ================================================================
--  WATERMARK — Modern floating watermark
-- ================================================================
local WatermarkOuter = Library:Create('Frame', {
    BorderSizePixel = 0,
    Position = UDim2.new(0, 20, 0, 20),
    Size = UDim2.new(0, 200, 0, 32),
    ZIndex = 200,
    Visible = false,
    Parent = ScreenGui,
})
SetCorner(WatermarkOuter, UDim.new(0, 8))
SetShadow(WatermarkOuter, 0, 12, 0.6)

local WatermarkInner = Library:Create('Frame', {
    BackgroundColor3 = Theme.Surface,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 1, 0),
    ZIndex = 201,
    Parent = WatermarkOuter,
})
SetCorner(WatermarkInner, UDim.new(0, 8))

local WatermarkAccent = Library:Create('Frame', {
    BackgroundColor3 = Theme.Primary,
    BorderSizePixel = 0,
    Size = UDim2.new(0, 3, 1, 0),
    ZIndex = 202,
    Parent = WatermarkInner,
})
SetCorner(WatermarkAccent, UDim.new(0, 8))

local WatermarkLabel = Library:CreateLabel({
    Position = UDim2.new(0, 12, 0, 0),
    Size = UDim2.new(1, -16, 1, 0),
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
    Font = Library.FontMedium,
    ZIndex = 203,
    Parent = WatermarkInner,
})

Library:AddToRegistry(WatermarkInner, { BackgroundColor3 = 'Surface' })
Library:AddToRegistry(WatermarkAccent, { BackgroundColor3 = 'Primary' })

Library.Watermark = WatermarkOuter
Library.WatermarkText = WatermarkLabel
Library:MakeDraggable(WatermarkOuter, 32)

function Library:SetWatermarkVisibility(Bool)
    if Bool and not WatermarkOuter.Visible then
        WatermarkOuter.Visible = true
        WatermarkOuter.Size = UDim2.new(0, 200, 0, 0)
        Tween(WatermarkOuter, {Size = UDim2.new(0, 200, 0, 32)}, Anim.Bounce)
    elseif not Bool and WatermarkOuter.Visible then
        Tween(WatermarkOuter, {Size = UDim2.new(0, 200, 0, 0)}, Anim.Fast)
        task.delay(0.15, function() WatermarkOuter.Visible = false end)
    end
end

function Library:SetWatermark(Text)
    local X = Library:GetTextBounds(Text, Library.FontMedium, 13)
    WatermarkOuter.Size = UDim2.new(0, X + 28, 0, 32)
    WatermarkLabel.Text = Text
    Library:SetWatermarkVisibility(true)
end

-- ================================================================
--  KEYBIND DISPLAY — Modern keybind list
-- ================================================================
local KeybindOuter = Library:Create('Frame', {
    AnchorPoint = Vector2.new(0, 0.5),
    BorderSizePixel = 0,
    Position = UDim2.new(0, 20, 0.5, 0),
    Size = UDim2.new(0, 220, 0, 28),
    Visible = false,
    ZIndex = 100,
    Parent = ScreenGui,
})
SetCorner(KeybindOuter, UDim.new(0, 10))
SetShadow(KeybindOuter, 0, 14, 0.65)

local KeybindInner = Library:Create('Frame', {
    BackgroundColor3 = Theme.Surface,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 1, 0),
    ZIndex = 101,
    Parent = KeybindOuter,
})
SetCorner(KeybindInner, UDim.new(0, 10))

local KeybindAccent = Library:Create('Frame', {
    BackgroundColor3 = Theme.Primary,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 2),
    ZIndex = 102,
    Parent = KeybindInner,
})

local KeybindLabel = Library:CreateLabel({
    Size = UDim2.new(1, 0, 0, 26),
    Position = UDim2.new(0, 0, 0, 2),
    TextXAlignment = Enum.TextXAlignment.Center,
    TextYAlignment = Enum.TextYAlignment.Center,
    Font = Library.FontMedium,
    Text = 'Keybinds',
    TextSize = 13,
    ZIndex = 104,
    Parent = KeybindInner,
})

local KeybindContainer = Library:Create('Frame', {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 1, -28),
    Position = UDim2.new(0, 0, 0, 28),
    ZIndex = 1,
    Parent = KeybindInner,
})

Library:Create('UIListLayout', {
    Padding = UDim.new(0, 4),
    FillDirection = Enum.FillDirection.Vertical,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = KeybindContainer,
})

Library:Create('UIPadding', {
    PaddingLeft = UDim.new(0, 8),
    PaddingRight = UDim.new(0, 8),
    PaddingTop = UDim.new(0, 6),
    PaddingBottom = UDim.new(0, 8),
    Parent = KeybindContainer,
})

Library:AddToRegistry(KeybindInner, { BackgroundColor3 = 'Surface' }, true)
Library:AddToRegistry(KeybindAccent, { BackgroundColor3 = 'Primary' }, true)

Library.KeybindFrame = KeybindOuter
Library.KeybindContainer = KeybindContainer
Library:MakeDraggable(KeybindOuter, 28)

-- ================================================================
--  BASE ADDONS (ColorPicker, KeyPicker)
-- ================================================================
local BaseAddons = {}
do
    local Funcs = {}

    function Funcs:AddColorPicker(Idx, Info)
        local ToggleLabel = self.TextLabel
        assert(Info.Default, 'AddColorPicker: Missing default value.')

        local ColorPicker = {
            Value = Info.Default;
            Transparency = Info.Transparency or 0;
            Type = 'ColorPicker';
            Title = type(Info.Title) == 'string' and Info.Title or 'Color picker';
            Callback = Info.Callback or function(Color) end;
        }

        function ColorPicker:SetHSVFromRGB(Color)
            local H, S, V = Color3.toHSV(Color)
            ColorPicker.Hue = H; ColorPicker.Sat = S; ColorPicker.Vib = V
        end
        ColorPicker:SetHSVFromRGB(ColorPicker.Value)

        -- Display swatch
        local DisplayFrame = Library:Create('Frame', {
            BackgroundColor3 = ColorPicker.Value;
            BorderSizePixel = 0;
            Size = UDim2.new(0, 22, 0, 14);
            ZIndex = 6;
            Parent = ToggleLabel;
        })
        SetCorner(DisplayFrame, UDim.new(0, 4))

        if Info.Transparency then
            Library:Create('ImageLabel', {
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 5;
                Image = 'http://www.roblox.com/asset/?id=12977615774';
                Parent = DisplayFrame;
            })
        end

        -- Picker Frame
        local PickerFrameOuter = Library:Create('Frame', {
            Name = 'Color';
            BackgroundColor3 = Theme.Elevated;
            BorderSizePixel = 0;
            Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18);
            Size = UDim2.fromOffset(240, Info.Transparency and 295 or 275);
            Visible = false;
            ZIndex = 50;
            Parent = ScreenGui;
        })
        SetCorner(PickerFrameOuter, UDim.new(0, 12))
        SetShadow(PickerFrameOuter, 0, 20, 0.5)

        DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            PickerFrameOuter.Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18)
        end)

        local PickerFrameInner = Library:Create('Frame', {
            BackgroundColor3 = Theme.Surface;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 51;
            Parent = PickerFrameOuter;
        })
        SetCorner(PickerFrameInner, UDim.new(0, 12))

        local AccentBar = Library:Create('Frame', {
            BackgroundColor3 = Theme.Primary;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 0, 2);
            ZIndex = 52;
            Parent = PickerFrameInner;
        })

        -- Saturation/Value Map
        local SatVibMapOuter = Library:Create('Frame', {
            BorderSizePixel = 0;
            Position = UDim2.new(0, 12, 0, 28);
            Size = UDim2.new(0, 180, 0, 180);
            ZIndex = 53;
            Parent = PickerFrameInner;
        })
        SetCorner(SatVibMapOuter, UDim.new(0, 8))

        local SatVibMap = Library:Create('ImageLabel', {
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 54;
            Image = 'rbxassetid://4155801252';
            Parent = SatVibMapOuter;
        })
        SetCorner(SatVibMap, UDim.new(0, 8))

        local CursorOuter = Library:Create('Frame', {
            AnchorPoint = Vector2.new(0.5, 0.5);
            Size = UDim2.new(0, 10, 0, 10);
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            ZIndex = 55;
            Parent = SatVibMap;
        })
        Library:Create('UIStroke', { Color = Color3.new(1, 1, 1); Thickness = 2; Parent = CursorOuter })

        -- Hue Slider
        local HueSelectorOuter = Library:Create('Frame', {
            BorderSizePixel = 0;
            Position = UDim2.new(0, 200, 0, 28);
            Size = UDim2.new(0, 16, 0, 180);
            ZIndex = 53;
            Parent = PickerFrameInner;
        })
        SetCorner(HueSelectorOuter, UDim.new(0, 8))

        local HueSelectorInner = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 54;
            Parent = HueSelectorOuter;
        })
        SetCorner(HueSelectorInner, UDim.new(0, 8))

        local HueCursor = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1, 1, 1);
            AnchorPoint = Vector2.new(0, 0.5);
            BorderSizePixel = 0;
            Size = UDim2.new(1, 4, 0, 3);
            Position = UDim2.new(0, -2, 0, 0);
            ZIndex = 56;
            Parent = HueSelectorInner;
        })
        SetCorner(HueCursor, UDim.new(0, 2))
        Library:Create('UIStroke', { Color = Color3.new(0, 0, 0); Thickness = 1; Parent = HueCursor })

        local SequenceTable = {}
        for HueVal = 0, 1, 0.05 do
            table.insert(SequenceTable, ColorSequenceKeypoint.new(HueVal, Color3.fromHSV(HueVal, 1, 1)))
        end
        Library:Create('UIGradient', { Color = ColorSequence.new(SequenceTable); Rotation = 90; Parent = HueSelectorInner })

        -- Input Fields
        local HueBoxOuter = Library:Create('Frame', {
            BorderSizePixel = 0;
            BackgroundColor3 = Theme.Background;
            Position = UDim2.fromOffset(12, 218);
            Size = UDim2.new(0.5, -16, 0, 28);
            ZIndex = 54;
            Parent = PickerFrameInner;
        })
        SetCorner(HueBoxOuter, UDim.new(0, 6))
        SetStroke(HueBoxOuter, Theme.Border)

        local HueBox = Library:Create('TextBox', {
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 8, 0, 0);
            Size = UDim2.new(1, -16, 1, 0);
            Font = Library.FontMono;
            PlaceholderColor3 = Theme.TextMuted;
            PlaceholderText = 'Hex';
            Text = '#FFFFFF';
            TextColor3 = Theme.TextPrimary;
            TextSize = 12;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 55;
            Parent = HueBoxOuter;
        })

        local RgbBoxOuter = Library:Create('Frame', {
            BorderSizePixel = 0;
            BackgroundColor3 = Theme.Background;
            Position = UDim2.new(0.5, 4, 0, 218);
            Size = UDim2.new(0.5, -16, 0, 28);
            ZIndex = 54;
            Parent = PickerFrameInner;
        })
        SetCorner(RgbBoxOuter, UDim.new(0, 6))
        SetStroke(RgbBoxOuter, Theme.Border)

        local RgbBox = Library:Create('TextBox', {
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 8, 0, 0);
            Size = UDim2.new(1, -16, 1, 0);
            Font = Library.FontMono;
            PlaceholderColor3 = Theme.TextMuted;
            PlaceholderText = 'RGB';
            Text = '255, 255, 255';
            TextColor3 = Theme.TextPrimary;
            TextSize = 12;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 55;
            Parent = RgbBoxOuter;
        })

        -- Transparency
        local TransparencyBoxOuter, TransparencyBoxInner, TransparencyCursor
        if Info.Transparency then
            TransparencyBoxOuter = Library:Create('Frame', {
                BorderSizePixel = 0;
                BackgroundColor3 = Theme.Background;
                Position = UDim2.fromOffset(12, 254);
                Size = UDim2.new(1, -24, 0, 20);
                ZIndex = 54;
                Parent = PickerFrameInner;
            })
            SetCorner(TransparencyBoxOuter, UDim.new(0, 6))
            SetStroke(TransparencyBoxOuter, Theme.Border)

            TransparencyBoxInner = Library:Create('Frame', {
                BackgroundColor3 = ColorPicker.Value;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 55;
                Parent = TransparencyBoxOuter;
            })
            SetCorner(TransparencyBoxInner, UDim.new(0, 6))

            Library:Create('ImageLabel', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 1, 0);
                Image = 'http://www.roblox.com/asset/?id=12978095818';
                ZIndex = 56;
                Parent = TransparencyBoxInner;
            })

            TransparencyCursor = Library:Create('Frame', {
                BackgroundColor3 = Color3.new(1, 1, 1);
                AnchorPoint = Vector2.new(0.5, 0);
                BorderSizePixel = 0;
                Size = UDim2.new(0, 2, 1, 0);
                ZIndex = 57;
                Parent = TransparencyBoxInner;
            })
            SetCorner(TransparencyCursor, UDim.new(0, 1))
        end

        -- Title
        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 16);
            Position = UDim2.fromOffset(12, 8);
            TextXAlignment = Enum.TextXAlignment.Left;
            TextSize = 13;
            Text = ColorPicker.Title;
            Font = Library.FontMedium;
            ZIndex = 52;
            Parent = PickerFrameInner;
        })

        -- Context Menu
        local ContextMenu = {}
        do
            ContextMenu.Options = {}
            ContextMenu.Container = Library:Create('Frame', {
                BorderSizePixel = 0;
                BackgroundColor3 = Theme.Elevated;
                ZIndex = 60;
                Visible = false;
                Parent = ScreenGui;
            })
            SetCorner(ContextMenu.Container, UDim.new(0, 8))
            SetShadow(ContextMenu.Container, 0, 12, 0.6)

            ContextMenu.Inner = Library:Create('Frame', {
                BackgroundColor3 = Theme.Surface;
                BorderSizePixel = 0;
                Size = UDim2.fromScale(1, 1);
                ZIndex = 61;
                Parent = ContextMenu.Container;
            })
            SetCorner(ContextMenu.Inner, UDim.new(0, 8))

            Library:Create('UIListLayout', {
                Name = 'Layout';
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Padding = UDim.new(0, 2);
                Parent = ContextMenu.Inner;
            })

            Library:Create('UIPadding', {
                Name = 'Padding';
                PaddingLeft = UDim.new(0, 4);
                PaddingRight = UDim.new(0, 4);
                PaddingTop = UDim.new(0, 4);
                PaddingBottom = UDim.new(0, 4);
                Parent = ContextMenu.Inner;
            })

            local function updateMenuPosition()
                ContextMenu.Container.Position = UDim2.fromOffset(
                    (DisplayFrame.AbsolutePosition.X + DisplayFrame.AbsoluteSize.X) + 6,
                    DisplayFrame.AbsolutePosition.Y
                )
            end

            local function updateMenuSize()
                local menuWidth = 80
                for _, label in next, ContextMenu.Inner:GetChildren() do
                    if label:IsA('TextLabel') then
                        menuWidth = math.max(menuWidth, label.TextBounds.X)
                    end
                end
                ContextMenu.Container.Size = UDim2.fromOffset(menuWidth + 16, ContextMenu.Inner.Layout.AbsoluteContentSize.Y + 8)
            end

            DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(updateMenuPosition)
            ContextMenu.Inner.Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(updateMenuSize)
            task.spawn(updateMenuPosition); task.spawn(updateMenuSize)

            Library:AddToRegistry(ContextMenu.Inner, { BackgroundColor3 = 'Surface' })

            function ContextMenu:Show()
                self.Container.Visible = true
                self.Container.Size = UDim2.fromOffset(self.Container.Size.X.Offset, 0)
                Tween(self.Container, {Size = UDim2.fromOffset(self.Container.Size.X.Offset, ContextMenu.Inner.Layout.AbsoluteContentSize.Y + 8)}, Anim.Fast)
            end

            function ContextMenu:Hide()
                Tween(self.Container, {Size = UDim2.fromOffset(self.Container.Size.X.Offset, 0)}, Anim.Fast)
                task.delay(0.12, function() if not ContextMenu.Container.Visible then return end self.Container.Visible = false end)
            end

            function ContextMenu:AddOption(Str, Callback)
                if type(Callback) ~= 'function' then Callback = function() end end

                local Button = Library:CreateLabel({
                    Active = false;
                    Size = UDim2.new(1, 0, 0, 22);
                    TextSize = 12;
                    Text = Str;
                    ZIndex = 62;
                    Parent = self.Inner;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    BackgroundTransparency = 1;
                })
                SetCorner(Button, UDim.new(0, 4))

                local ButtonBg = Library:Create('Frame', {
                    BackgroundTransparency = 1;
                    Size = UDim2.new(1, 0, 1, 0);
                    ZIndex = 61;
                    Parent = Button;
                })
                SetCorner(ButtonBg, UDim.new(0, 4))

                Button.MouseEnter:Connect(function()
                    Tween(ButtonBg, {BackgroundTransparency = 0.9, BackgroundColor3 = Theme.Primary}, Anim.Fast)
                    Tween(Button, {TextColor3 = Theme.Primary}, Anim.Fast)
                end)

                Button.MouseLeave:Connect(function()
                    Tween(ButtonBg, {BackgroundTransparency = 1}, Anim.Fast)
                    Tween(Button, {TextColor3 = Theme.TextPrimary}, Anim.Fast)
                end)

                Button.InputBegan:Connect(function(Input)
                    if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                    Callback()
                end)
            end

            ContextMenu:AddOption('Copy color', function()
                Library.ColorClipboard = ColorPicker.Value
                Library:Notify('Color copied!', 2)
            end)

            ContextMenu:AddOption('Paste color', function()
                if not Library.ColorClipboard then return Library:Notify('Clipboard empty!', 2) end
                ColorPicker:SetValueRGB(Library.ColorClipboard)
            end)

            ContextMenu:AddOption('Copy HEX', function()
                pcall(setclipboard, ColorPicker.Value:ToHex())
                Library:Notify('HEX copied!', 2)
            end)

            ContextMenu:AddOption('Copy RGB', function()
                pcall(setclipboard, table.concat({
                    math.floor(ColorPicker.Value.R * 255),
                    math.floor(ColorPicker.Value.G * 255),
                    math.floor(ColorPicker.Value.B * 255)
                }, ', '))
                Library:Notify('RGB copied!', 2)
            end)
        end

        -- Registry
        Library:AddToRegistry(PickerFrameInner, { BackgroundColor3 = 'Surface' })
        Library:AddToRegistry(AccentBar, { BackgroundColor3 = 'Primary' })
        Library:AddToRegistry(HueBoxOuter, { BackgroundColor3 = 'Background' })
        Library:AddToRegistry(RgbBoxOuter, { BackgroundColor3 = 'Background' })
        Library:AddToRegistry(HueBox, { TextColor3 = 'TextPrimary' })
        Library:AddToRegistry(RgbBox, { TextColor3 = 'TextPrimary' })

        -- Input handlers
        HueBox.FocusLost:Connect(function(enter)
            if enter then
                local success, result = pcall(Color3.fromHex, HueBox.Text)
                if success and typeof(result) == 'Color3' then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(result)
                end
            end
            ColorPicker:Display()
        end)

        RgbBox.FocusLost:Connect(function(enter)
            if enter then
                local r, g, b = RgbBox.Text:match('(%d+),%s*(%d+),%s*(%d+)')
                if r and g and b then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(Color3.fromRGB(r, g, b))
                end
            end
            ColorPicker:Display()
        end)

        function ColorPicker:Display()
            ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib)
            SatVibMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1)

            Tween(DisplayFrame, { BackgroundColor3 = ColorPicker.Value; BackgroundTransparency = ColorPicker.Transparency }, Anim.Fast)

            if TransparencyBoxInner then
                Tween(TransparencyBoxInner, {BackgroundColor3 = ColorPicker.Value}, Anim.Fast)
                TransparencyCursor.Position = UDim2.new(1 - ColorPicker.Transparency, 0, 0, 0)
            end

            CursorOuter.Position = UDim2.new(ColorPicker.Sat, 0, 1 - ColorPicker.Vib, 0)
            HueCursor.Position = UDim2.new(0, 0, ColorPicker.Hue, 0)

            HueBox.Text = '#' .. ColorPicker.Value:ToHex()
            RgbBox.Text = table.concat({
                math.floor(ColorPicker.Value.R * 255),
                math.floor(ColorPicker.Value.G * 255),
                math.floor(ColorPicker.Value.B * 255)
            }, ', ')

            Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value)
            Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value)
        end

        function ColorPicker:OnChanged(Func)
            ColorPicker.Changed = Func
            Func(ColorPicker.Value)
        end

        function ColorPicker:Show()
            for Frame, Val in next, Library.OpenedFrames do
                if Frame.Name == 'Color' then
                    Frame.Visible = false
                    Library.OpenedFrames[Frame] = nil
                end
            end
            PickerFrameOuter.Visible = true
            Library.OpenedFrames[PickerFrameOuter] = true
            Tween(PickerFrameOuter, {Size = UDim2.fromOffset(240, Info.Transparency and 295 or 275)}, Anim.Bounce)
        end

        function ColorPicker:Hide()
            Tween(PickerFrameOuter, {Size = UDim2.fromOffset(240, 0)}, Anim.Fast)
            task.delay(0.15, function()
                PickerFrameOuter.Visible = false
                Library.OpenedFrames[PickerFrameOuter] = nil
            end)
        end

        function ColorPicker:SetValue(HSV, Transparency)
            local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3])
            ColorPicker.Transparency = Transparency or 0
            ColorPicker:SetHSVFromRGB(Color)
            ColorPicker:Display()
        end

        function ColorPicker:SetValueRGB(Color, Transparency)
            ColorPicker.Transparency = Transparency or 0
            ColorPicker:SetHSVFromRGB(Color)
            ColorPicker:Display()
        end

        -- Interactions
        SatVibMap.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local MinX = SatVibMap.AbsolutePosition.X
                    local MaxX = MinX + SatVibMap.AbsoluteSize.X
                    local MouseX = math.clamp(Mouse.X, MinX, MaxX)
                    local MinY = SatVibMap.AbsolutePosition.Y
                    local MaxY = MinY + SatVibMap.AbsoluteSize.Y
                    local MouseY = math.clamp(Mouse.Y, MinY, MaxY)
                    ColorPicker.Sat = (MouseX - MinX) / (MaxX - MinX)
                    ColorPicker.Vib = 1 - ((MouseY - MinY) / (MaxY - MinY))
                    ColorPicker:Display()
                    RenderStepped:Wait()
                end
                Library:AttemptSave()
            end
        end)

        HueSelectorInner.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local MinY = HueSelectorInner.AbsolutePosition.Y
                    local MaxY = MinY + HueSelectorInner.AbsoluteSize.Y
                    local MouseY = math.clamp(Mouse.Y, MinY, MaxY)
                    ColorPicker.Hue = ((MouseY - MinY) / (MaxY - MinY))
                    ColorPicker:Display()
                    RenderStepped:Wait()
                end
                Library:AttemptSave()
            end
        end)

        DisplayFrame.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                if PickerFrameOuter.Visible then ColorPicker:Hide() else ContextMenu:Hide(); ColorPicker:Show() end
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
                ContextMenu:Show(); ColorPicker:Hide()
            end
        end)

        if TransparencyBoxInner then
            TransparencyBoxInner.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                        local MinX = TransparencyBoxInner.AbsolutePosition.X
                        local MaxX = MinX + TransparencyBoxInner.AbsoluteSize.X
                        local MouseX = math.clamp(Mouse.X, MinX, MaxX)
                        ColorPicker.Transparency = 1 - ((MouseX - MinX) / (MaxX - MinX))
                        ColorPicker:Display()
                        RenderStepped:Wait()
                    end
                    Library:AttemptSave()
                end
            end)
        end

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                local AbsPos, AbsSize = PickerFrameOuter.AbsolutePosition, PickerFrameOuter.AbsoluteSize
                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20) or Mouse.Y > AbsPos.Y + AbsSize.Y then
                    ColorPicker:Hide()
                end
                if not Library:IsMouseOverFrame(ContextMenu.Container) then ContextMenu:Hide() end
            end
            if Input.UserInputType == Enum.UserInputType.MouseButton2 and ContextMenu.Container.Visible then
                if not Library:IsMouseOverFrame(ContextMenu.Container) and not Library:IsMouseOverFrame(DisplayFrame) then
                    ContextMenu:Hide()
                end
            end
        end))

        ColorPicker:Display()
        ColorPicker.DisplayFrame = DisplayFrame
        Options[Idx] = ColorPicker
        return self
    end

    function Funcs:AddKeyPicker(Idx, Info)
        local ParentObj = self
        local ToggleLabel = self.TextLabel
        local Container = self.Container

        assert(Info.Default, 'AddKeyPicker: Missing default value.')

        local KeyPicker = {
            Value = Info.Default;
            Toggled = false;
            Mode = Info.Mode or 'Toggle';
            Type = 'KeyPicker';
            Callback = Info.Callback or function(Value) end;
            ChangedCallback = Info.ChangedCallback or function(New) end;
            SyncToggleState = Info.SyncToggleState or false;
        }

        if KeyPicker.SyncToggleState then
            Info.Modes = { 'Toggle' }
            Info.Mode = 'Toggle'
        end

        -- Key display
        local PickOuter = Library:Create('Frame', {
            BackgroundColor3 = Theme.Background;
            BorderSizePixel = 0;
            Size = UDim2.new(0, 32, 0, 18);
            ZIndex = 6;
            Parent = ToggleLabel;
        })
        SetCorner(PickOuter, UDim.new(0, 4))
        SetStroke(PickOuter, Theme.Border)

        local PickInner = Library:Create('Frame', {
            BackgroundColor3 = Theme.Surface;
            BorderSizePixel = 0;
            Size = UDim2.new(1, -2, 1, -2);
            Position = UDim2.new(0, 1, 0, 1);
            ZIndex = 7;
            Parent = PickOuter;
        })
        SetCorner(PickInner, UDim.new(0, 3))

        Library:AddToRegistry(PickInner, { BackgroundColor3 = 'Surface' })

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = 11;
            Text = Info.Default;
            TextWrapped = true;
            Font = Library.FontMono;
            TextColor3 = Theme.TextSecondary;
            ZIndex = 8;
            Parent = PickInner;
        })

        -- Mode selector
        local ModeSelectOuter = Library:Create('Frame', {
            BorderSizePixel = 0;
            BackgroundColor3 = Theme.Elevated;
            Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 6, ToggleLabel.AbsolutePosition.Y);
            Size = UDim2.new(0, 72, 0, 0);
            Visible = false;
            ZIndex = 50;
            Parent = ScreenGui;
        })
        SetCorner(ModeSelectOuter, UDim.new(0, 10))
        SetShadow(ModeSelectOuter, 0, 14, 0.55)

        ToggleLabel:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            ModeSelectOuter.Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 6, ToggleLabel.AbsolutePosition.Y)
        end)

        local ModeSelectInner = Library:Create('Frame', {
            BackgroundColor3 = Theme.Surface;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 51;
            Parent = ModeSelectOuter;
        })
        SetCorner(ModeSelectInner, UDim.new(0, 10))

        Library:AddToRegistry(ModeSelectInner, { BackgroundColor3 = 'Surface' })

        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Padding = UDim.new(0, 1);
            Parent = ModeSelectInner;
        })

        Library:Create('UIPadding', {
            PaddingLeft = UDim.new(0, 4);
            PaddingRight = UDim.new(0, 4);
            PaddingTop = UDim.new(0, 4);
            PaddingBottom = UDim.new(0, 4);
            Parent = ModeSelectInner;
        })

        -- Keybind display in list
        local ContainerLabel = Library:CreateLabel({
            TextXAlignment = Enum.TextXAlignment.Left;
            Size = UDim2.new(1, 0, 0, 20);
            TextSize = 12;
            Visible = false;
            ZIndex = 110;
            Parent = Library.KeybindContainer;
        }, true)

        local Modes = Info.Modes or { 'Always', 'Toggle', 'Hold' }
        local ModeButtons = {}

        for _, Mode in next, Modes do
            local ModeButton = {}

            local Label = Library:CreateLabel({
                Active = false;
                Size = UDim2.new(1, 0, 0, 22);
                TextSize = 12;
                Text = Mode;
                ZIndex = 52;
                Parent = ModeSelectInner;
                TextXAlignment = Enum.TextXAlignment.Left;
                BackgroundTransparency = 1;
            })
            SetCorner(Label, UDim.new(0, 4))

            local LabelBg = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 51;
                Parent = Label;
            })
            SetCorner(LabelBg, UDim.new(0, 4))

            Label.MouseEnter:Connect(function()
                Tween(LabelBg, {BackgroundTransparency = 0.9, BackgroundColor3 = Theme.Primary}, Anim.Fast)
            end)

            Label.MouseLeave:Connect(function()
                Tween(LabelBg, {BackgroundTransparency = 1}, Anim.Fast)
            end)

            function ModeButton:Select()
                for _, Button in next, ModeButtons do Button:Deselect() end
                KeyPicker.Mode = Mode
                Tween(Label, {TextColor3 = Theme.Primary}, Anim.Fast)
                Library.RegistryMap[Label].Properties.TextColor3 = 'Primary'
                ModeSelectOuter.Visible = false
            end

            function ModeButton:Deselect()
                KeyPicker.Mode = nil
                Tween(Label, {TextColor3 = Theme.TextPrimary}, Anim.Fast)
                Library.RegistryMap[Label].Properties.TextColor3 = 'TextPrimary'
            end

            Label.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    ModeButton:Select()
                    Library:AttemptSave()
                end
            end)

            if Mode == KeyPicker.Mode then ModeButton:Select() end
            ModeButtons[Mode] = ModeButton
        end

        function KeyPicker:Update()
            if Info.NoUI then return end
            local State = KeyPicker:GetState()
            ContainerLabel.Text = string.format('[%s] %s (%s)', KeyPicker.Value, Info.Text, KeyPicker.Mode)
            ContainerLabel.Visible = true

            if State then
                Tween(ContainerLabel, {TextColor3 = Theme.Primary}, Anim.Fast)
                Library.RegistryMap[ContainerLabel].Properties.TextColor3 = 'Primary'
            else
                Tween(ContainerLabel, {TextColor3 = Theme.TextSecondary}, Anim.Fast)
                Library.RegistryMap[ContainerLabel].Properties.TextColor3 = 'TextSecondary'
            end

            local YSize = 0
            local XSize = 0
            for _, Label in next, Library.KeybindContainer:GetChildren() do
                if Label:IsA('TextLabel') and Label.Visible then
                    YSize = YSize + 20
                    if Label.TextBounds.X > XSize then XSize = Label.TextBounds.X end
                end
            end
            Library.KeybindFrame.Size = UDim2.new(0, math.max(XSize + 20, 220), 0, YSize + 36)
        end

        function KeyPicker:GetState()
            if KeyPicker.Mode == 'Always' then return true
            elseif KeyPicker.Mode == 'Hold' then
                if KeyPicker.Value == 'None' then return false end
                local Key = KeyPicker.Value
                if Key == 'MB1' or Key == 'MB2' then
                    return Key == 'MB1' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                        or Key == 'MB2' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
                else
                    return InputService:IsKeyDown(Enum.KeyCode[KeyPicker.Value])
                end
            else return KeyPicker.Toggled end
        end

        function KeyPicker:SetValue(Data)
            local Key, Mode = Data[1], Data[2]
            DisplayLabel.Text = Key
            KeyPicker.Value = Key
            ModeButtons[Mode]:Select()
            KeyPicker:Update()
        end

        function KeyPicker:OnClick(Callback) KeyPicker.Clicked = Callback end

        function KeyPicker:OnChanged(Callback)
            KeyPicker.Changed = Callback
            Callback(KeyPicker.Value)
        end

        if ParentObj.Addons then table.insert(ParentObj.Addons, KeyPicker) end

        function KeyPicker:DoClick()
            if ParentObj.Type == 'Toggle' and KeyPicker.SyncToggleState then
                ParentObj:SetValue(not ParentObj.Value)
            end
            Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
            Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled)
        end

        local Picking = false

        PickOuter.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                Picking = true
                DisplayLabel.Text = ''
                Tween(PickOuter, {BackgroundColor3 = Theme.PrimaryMuted}, Anim.Fast)

                local Break
                local Text = ''
                task.spawn(function()
                    while not Break do
                        if Text == '...' then Text = '' end
                        Text = Text .. '.'
                        DisplayLabel.Text = Text
                        wait(0.4)
                    end
                end)

                wait(0.2)

                local Event
                Event = InputService.InputBegan:Connect(function(Input)
                    local Key
                    if Input.UserInputType == Enum.UserInputType.Keyboard then
                        Key = Input.KeyCode.Name
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Key = 'MB1'
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                        Key = 'MB2'
                    end

                    Break = true
                    Picking = false
                    DisplayLabel.Text = Key
                    KeyPicker.Value = Key
                    Tween(PickOuter, {BackgroundColor3 = Theme.Background}, Anim.Fast)

                    Library:SafeCallback(KeyPicker.ChangedCallback, Input.KeyCode or Input.UserInputType)
                    Library:SafeCallback(KeyPicker.Changed, Input.KeyCode or Input.UserInputType)
                    Library:AttemptSave()
                    Event:Disconnect()
                end)

            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
                ModeSelectOuter.Visible = true
                ModeSelectOuter.Size = UDim2.new(0, 72, 0, 0)
                Tween(ModeSelectOuter, {Size = UDim2.new(0, 72, 0, #Modes * 22 + 10)}, Anim.Bounce)
            end
        end)

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if not Picking then
                if KeyPicker.Mode == 'Toggle' then
                    local Key = KeyPicker.Value
                    if Key == 'MB1' or Key == 'MB2' then
                        if Key == 'MB1' and Input.UserInputType == Enum.UserInputType.MouseButton1
                        or Key == 'MB2' and Input.UserInputType == Enum.UserInputType.MouseButton2 then
                            KeyPicker.Toggled = not KeyPicker.Toggled
                            KeyPicker:DoClick()
                        end
                    elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                        if Input.KeyCode.Name == Key then
                            KeyPicker.Toggled = not KeyPicker.Toggled
                            KeyPicker:DoClick()
                        end
                    end
                end
                KeyPicker:Update()
            end

            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                local AbsPos, AbsSize = ModeSelectOuter.AbsolutePosition, ModeSelectOuter.AbsoluteSize
                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20) or Mouse.Y > AbsPos.Y + AbsSize.Y then
                    if ModeSelectOuter.Visible then
                        Tween(ModeSelectOuter, {Size = UDim2.new(0, 72, 0, 0)}, Anim.Fast)
                        task.delay(0.12, function() ModeSelectOuter.Visible = false end)
                    end
                end
            end
        end))

        Library:GiveSignal(InputService.InputEnded:Connect(function(Input)
            if not Picking then KeyPicker:Update() end
        end))

        KeyPicker:Update()
        Options[Idx] = KeyPicker
        return self
    end

    BaseAddons.__index = Funcs
    BaseAddons.__namecall = function(Table, Key, ...)
        return Funcs[Key](...)
    end
end

-- ================================================================
--  BASE GROUPBOX — All interactive elements
-- ================================================================
local BaseGroupbox = {}
do
    local Funcs = {}

    function Funcs:AddBlank(Size)
        local Groupbox = self
        local Container = Groupbox.Container
        Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, Size);
            ZIndex = 1;
            Parent = Container;
        })
    end

    function Funcs:AddLabel(Text, DoesWrap)
        local Label = {}
        local Groupbox = self
        local Container = Groupbox.Container

        local TextLabel = Library:CreateLabel({
            Size = UDim2.new(1, -8, 0, 16);
            TextSize = 13;
            Text = Text;
            TextWrapped = DoesWrap or false;
            TextXAlignment = Enum.TextXAlignment.Left;
            TextColor3 = Theme.TextSecondary;
            ZIndex = 5;
            Parent = Container;
        })

        if DoesWrap then
            local Y = select(2, Library:GetTextBounds(Text, Library.Font, 13, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
            TextLabel.Size = UDim2.new(1, -8, 0, Y)
        else
            Library:Create('UIListLayout', {
                Padding = UDim.new(0, 4);
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Right;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = TextLabel;
            })
        end

        Label.TextLabel = TextLabel
        Label.Container = Container

        function Label:SetText(Text)
            TextLabel.Text = Text
            if DoesWrap then
                local Y = select(2, Library:GetTextBounds(Text, Library.Font, 13, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
                TextLabel.Size = UDim2.new(1, -8, 0, Y)
            end
            Groupbox:Resize()
        end

        if not DoesWrap then setmetatable(Label, BaseAddons) end
        Groupbox:AddBlank(4)
        Groupbox:Resize()
        return Label
    end

    function Funcs:AddButton(...)
        local Button = {}
        local function ProcessButtonParams(Class, Obj, ...)
            local Props = select(1, ...)
            if type(Props) == 'table' then
                Obj.Text = Props.Text
                Obj.Func = Props.Func
                Obj.DoubleClick = Props.DoubleClick
                Obj.Tooltip = Props.Tooltip
            else
                Obj.Text = select(1, ...)
                Obj.Func = select(2, ...)
            end
            assert(type(Obj.Func) == 'function', 'AddButton: `Func` callback is missing.')
        end

        ProcessButtonParams('Button', Button, ...)

        local Groupbox = self
        local Container = Groupbox.Container

        local function CreateBaseButton(Button)
            local Outer = Library:Create('Frame', {
                BackgroundColor3 = Theme.Primary;
                BorderSizePixel = 0;
                Size = UDim2.new(1, -4, 0, 32);
                ZIndex = 5;
            })
            SetCorner(Outer, UDim.new(0, 8))

            local Inner = Library:Create('Frame', {
                BackgroundColor3 = Theme.Primary;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 6;
                Parent = Outer;
            })
            SetCorner(Inner, UDim.new(0, 8))

            local Label = Library:CreateLabel({
                Size = UDim2.new(1, 0, 1, 0);
                TextSize = 13;
                Text = Button.Text;
                Font = Library.FontMedium;
                ZIndex = 7;
                Parent = Inner;
            })

            Library:AddToRegistry(Outer, { BackgroundColor3 = 'Primary' })
            Library:AddToRegistry(Inner, { BackgroundColor3 = 'Primary' })

            Outer.MouseEnter:Connect(function()
                Tween(Outer, {BackgroundColor3 = Theme.PrimaryHover}, Anim.Fast)
                Tween(Inner, {BackgroundColor3 = Theme.PrimaryHover}, Anim.Fast)
            end)

            Outer.MouseLeave:Connect(function()
                Tween(Outer, {BackgroundColor3 = Theme.Primary}, Anim.Fast)
                Tween(Inner, {BackgroundColor3 = Theme.Primary}, Anim.Fast)
            end)

            return Outer, Inner, Label
        end

        local function InitEvents(Button)
            local function WaitForEvent(event, timeout, validator)
                local bindable = Instance.new('BindableEvent')
                local connection = event:Once(function(...)
                    if type(validator) == 'function' and validator(...) then
                        bindable:Fire(true)
                    else
                        bindable:Fire(false)
                    end
                end)
                task.delay(timeout, function()
                    connection:disconnect()
                    bindable:Fire(false)
                end)
                return bindable.Event:Wait()
            end

            local function ValidateClick(Input)
                if Library:MouseIsOverOpenedFrame() then return false end
                if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then return false end
                return true
            end

            Button.Outer.InputBegan:Connect(function(Input)
                if not ValidateClick(Input) then return end
                if Button.Locked then return end

                if Button.DoubleClick then
                    Tween(Button.Outer, {BackgroundColor3 = Theme.PrimaryMuted}, Anim.Fast)
                    Tween(Button.Inner, {BackgroundColor3 = Theme.PrimaryMuted}, Anim.Fast)
                    Button.Label.Text = 'Are you sure?'
                    Button.Locked = true

                    local clicked = WaitForEvent(Button.Outer.InputBegan, 0.5, ValidateClick)

                    Tween(Button.Outer, {BackgroundColor3 = Theme.Primary}, Anim.Fast)
                    Tween(Button.Inner, {BackgroundColor3 = Theme.Primary}, Anim.Fast)
                    Button.Label.Text = Button.Text
                    task.defer(rawset, Button, 'Locked', false)

                    if clicked then Library:SafeCallback(Button.Func) end
                    return
                end

                Library:SafeCallback(Button.Func)
            end)
        end

        Button.Outer, Button.Inner, Button.Label = CreateBaseButton(Button)
        Button.Outer.Parent = Container
        InitEvents(Button)

        function Button:AddTooltip(tooltip)
            if type(tooltip) == 'string' then Library:AddToolTip(tooltip, self.Outer) end
            return self
        end

        function Button:AddButton(...)
            local SubButton = {}
            ProcessButtonParams('SubButton', SubButton, ...)

            self.Outer.Size = UDim2.new(0.5, -2, 0, 32)
            SubButton.Outer, SubButton.Inner, SubButton.Label = CreateBaseButton(SubButton)
            SubButton.Outer.Position = UDim2.new(1, 3, 0, 0)
            SubButton.Outer.Size = UDim2.fromOffset(self.Outer.AbsoluteSize.X - 2, self.Outer.AbsoluteSize.Y)
            SubButton.Outer.Parent = self.Outer

            function SubButton:AddTooltip(tooltip)
                if type(tooltip) == 'string' then Library:AddToolTip(tooltip, self.Outer) end
                return SubButton
            end

            if type(SubButton.Tooltip) == 'string' then SubButton:AddTooltip(SubButton.Tooltip) end
            InitEvents(SubButton)
            return SubButton
        end

        if type(Button.Tooltip) == 'string' then Button:AddTooltip(Button.Tooltip) end
        Groupbox:AddBlank(4)
        Groupbox:Resize()
        return Button
    end

    function Funcs:AddDivider()
        local Groupbox = self
        local Container = self.Container

        local Divider = { Type = 'Divider' }
        Groupbox:AddBlank(6)

        local DividerOuter = Library:Create('Frame', {
            BackgroundColor3 = Theme.Border;
            BorderSizePixel = 0;
            Size = UDim2.new(1, -8, 0, 1);
            ZIndex = 5;
            Parent = Container;
        })
        SetCorner(DividerOuter, UDim.new(0, 1))

        Groupbox:AddBlank(10)
        Groupbox:Resize()
    end

    function Funcs:AddInput(Idx, Info)
        assert(Info.Text, 'AddInput: Missing `Text` string.')

        local Textbox = {
            Value = Info.Default or '';
            Numeric = Info.Numeric or false;
            Finished = Info.Finished or false;
            Type = 'Input';
            Callback = Info.Callback or function(Value) end;
        }

        local Groupbox = self
        local Container = Groupbox.Container

        local InputLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 16);
            TextSize = 13;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            TextColor3 = Theme.TextSecondary;
            ZIndex = 5;
            Parent = Container;
        })

        Groupbox:AddBlank(2)

        local TextBoxOuter = Library:Create('Frame', {
            BackgroundColor3 = Theme.Background;
            BorderSizePixel = 0;
            Size = UDim2.new(1, -4, 0, 32);
            ZIndex = 5;
            Parent = Container;
        })
        SetCorner(TextBoxOuter, UDim.new(0, 8))
        SetStroke(TextBoxOuter, Theme.Border)

        Library:OnHighlight(TextBoxOuter, TextBoxOuter,
            { BorderColor3 = Theme.BorderHover },
            { BorderColor3 = Theme.Border }
        )

        if type(Info.Tooltip) == 'string' then Library:AddToolTip(Info.Tooltip, TextBoxOuter) end

        local ContainerFrame = Library:Create('Frame', {
            BackgroundTransparency = 1;
            ClipsDescendants = true;
            Position = UDim2.new(0, 10, 0, 0);
            Size = UDim2.new(1, -20, 1, 0);
            ZIndex = 7;
            Parent = TextBoxOuter;
        })

        local Box = Library:Create('TextBox', {
            BackgroundTransparency = 1;
            Position = UDim2.fromOffset(0, 0);
            Size = UDim2.fromScale(5, 1);
            Font = Library.Font;
            PlaceholderColor3 = Theme.TextMuted;
            PlaceholderText = Info.Placeholder or '';
            Text = Info.Default or '';
            TextColor3 = Theme.TextPrimary;
            TextSize = 13;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 7;
            Parent = ContainerFrame;
        })

        function Textbox:SetValue(Text)
            if Info.MaxLength and #Text > Info.MaxLength then
                Text = Text:sub(1, Info.MaxLength)
            end
            if Textbox.Numeric then
                if (not tonumber(Text)) and Text:len() > 0 then Text = Textbox.Value end
            end
            Textbox.Value = Text
            Box.Text = Text
            Library:SafeCallback(Textbox.Callback, Textbox.Value)
            Library:SafeCallback(Textbox.Changed, Textbox.Value)
        end

        if Textbox.Finished then
            Box.FocusLost:Connect(function(enter)
                if not enter then return end
                Textbox:SetValue(Box.Text)
                Library:AttemptSave()
            end)
        else
            Box:GetPropertyChangedSignal('Text'):Connect(function()
                Textbox:SetValue(Box.Text)
                Library:AttemptSave()
            end)
        end

        Box.Focused:Connect(function()
            Tween(TextBoxOuter, {BorderColor3 = Theme.BorderActive}, Anim.Fast)
        end)

        Box.FocusLost:Connect(function()
            Tween(TextBoxOuter, {BorderColor3 = Theme.Border}, Anim.Fast)
        end)

        -- Cursor follow
        local function Update()
            local PADDING = 2
            local reveal = ContainerFrame.AbsoluteSize.X
            if not Box:IsFocused() or Box.TextBounds.X <= reveal - 2 * PADDING then
                Box.Position = UDim2.new(0, PADDING, 0, 0)
            else
                local cursor = Box.CursorPosition
                if cursor ~= -1 then
                    local subtext = string.sub(Box.Text, 1, cursor-1)
                    local width = TextService:GetTextSize(subtext, Box.TextSize, Box.Font, Vector2.new(math.huge, math.huge)).X
                    local currentCursorPos = Box.Position.X.Offset + width
                    if currentCursorPos < PADDING then
                        Box.Position = UDim2.fromOffset(PADDING - width, 0)
                    elseif currentCursorPos > reveal - PADDING - 1 then
                        Box.Position = UDim2.fromOffset(reveal - width - PADDING - 1, 0)
                    end
                end
            end
        end

        task.spawn(Update)
        Box:GetPropertyChangedSignal('Text'):Connect(Update)
        Box:GetPropertyChangedSignal('CursorPosition'):Connect(Update)
        Box.FocusLost:Connect(Update)
        Box.Focused:Connect(Update)

        Library:AddToRegistry(Box, { TextColor3 = 'TextPrimary' })

        function Textbox:OnChanged(Func)
            Textbox.Changed = Func
            Func(Textbox.Value)
        end

        Groupbox:AddBlank(4)
        Groupbox:Resize()
        Options[Idx] = Textbox
        return Textbox
    end

    function Funcs:AddToggle(Idx, Info)
        assert(Info.Text, 'AddToggle: Missing `Text` string.')

        local Toggle = {
            Value = Info.Default or false;
            Type = 'Toggle';
            Callback = Info.Callback or function(Value) end;
            Addons = {};
            Risky = Info.Risky;
        }

        local Groupbox = self
        local Container = Groupbox.Container

        local ToggleOuter = Library:Create('Frame', {
            BackgroundColor3 = Theme.Background;
            BorderSizePixel = 0;
            Size = UDim2.new(0, 36, 0, 20);
            ZIndex = 5;
            Parent = Container;
        })
        SetCorner(ToggleOuter, UDim.new(0, 10))
        SetStroke(ToggleOuter, Theme.Border)

        local ToggleInner = Library:Create('Frame', {
            BackgroundColor3 = Theme.Surface;
            BorderSizePixel = 0;
            Size = UDim2.new(1, -4, 1, -4);
            Position = UDim2.new(0, 2, 0, 2);
            ZIndex = 6;
            Parent = ToggleOuter;
        })
        SetCorner(ToggleInner, UDim.new(0, 8))

        local ToggleKnob = Library:Create('Frame', {
            BackgroundColor3 = Theme.TextMuted;
            BorderSizePixel = 0;
            Size = UDim2.new(0, 14, 0, 14);
            Position = UDim2.new(0, 2, 0.5, -7);
            ZIndex = 7;
            Parent = ToggleInner;
        })
        SetCorner(ToggleKnob, UDim.new(0, 7))

        local ToggleLabel = Library:CreateLabel({
            Size = UDim2.new(0, 200, 1, 0);
            Position = UDim2.new(1, 10, 0, 0);
            TextSize = 13;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            TextColor3 = Theme.TextPrimary;
            ZIndex = 6;
            Parent = ToggleInner;
        })

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 4);
            FillDirection = Enum.FillDirection.Horizontal;
            HorizontalAlignment = Enum.HorizontalAlignment.Right;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ToggleLabel;
        })

        local ToggleRegion = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(0, 240, 1, 0);
            ZIndex = 8;
            Parent = ToggleOuter;
        })

        Library:OnHighlight(ToggleRegion, ToggleOuter,
            { BorderColor3 = Theme.BorderHover },
            { BorderColor3 = Theme.Border }
        )

        function Toggle:UpdateColors() Toggle:Display() end

        if type(Info.Tooltip) == 'string' then Library:AddToolTip(Info.Tooltip, ToggleRegion) end

        function Toggle:Display()
            if Toggle.Value then
                Tween(ToggleOuter, {BackgroundColor3 = Theme.Primary}, Anim.Fast)
                Tween(ToggleInner, {BackgroundColor3 = Theme.PrimaryMuted}, Anim.Fast)
                Tween(ToggleKnob, {BackgroundColor3 = Color3.new(1,1,1), Position = UDim2.new(1, -16, 0.5, -7)}, Anim.Fast)
            else
                Tween(ToggleOuter, {BackgroundColor3 = Theme.Background}, Anim.Fast)
                Tween(ToggleInner, {BackgroundColor3 = Theme.Surface}, Anim.Fast)
                Tween(ToggleKnob, {BackgroundColor3 = Theme.TextMuted, Position = UDim2.new(0, 2, 0.5, -7)}, Anim.Fast)
            end
        end

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func
            Func(Toggle.Value)
        end

        function Toggle:SetValue(Bool)
            Bool = (not not Bool)
            Toggle.Value = Bool
            Toggle:Display()

            for _, Addon in next, Toggle.Addons do
                if Addon.Type == 'KeyPicker' and Addon.SyncToggleState then
                    Addon.Toggled = Bool
                    Addon:Update()
                end
            end

            Library:SafeCallback(Toggle.Callback, Toggle.Value)
            Library:SafeCallback(Toggle.Changed, Toggle.Value)
            Library:UpdateDependencyBoxes()
        end

        ToggleRegion.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                Toggle:SetValue(not Toggle.Value)
                Library:AttemptSave()
            end
        end)

        if Toggle.Risky then
            Library:RemoveFromRegistry(ToggleLabel)
            ToggleLabel.TextColor3 = Theme.Error
            Library:AddToRegistry(ToggleLabel, { TextColor3 = 'Error' })
        end

        Toggle:Display()
        Groupbox:AddBlank(Info.BlankSize or 6)
        Groupbox:Resize()

        Toggle.TextLabel = ToggleLabel
        Toggle.Container = Container
        setmetatable(Toggle, BaseAddons)

        Toggles[Idx] = Toggle
        Library:UpdateDependencyBoxes()
        return Toggle
    end

    function Funcs:AddSlider(Idx, Info)
        assert(Info.Default, 'AddSlider: Missing default value.')
        assert(Info.Text, 'AddSlider: Missing slider text.')
        assert(Info.Min, 'AddSlider: Missing minimum value.')
        assert(Info.Max, 'AddSlider: Missing maximum value.')
        assert(Info.Rounding, 'AddSlider: Missing rounding value.')

        local Slider = {
            Value = Info.Default;
            Min = Info.Min;
            Max = Info.Max;
            Rounding = Info.Rounding;
            MaxSize = 232;
            Type = 'Slider';
            Callback = Info.Callback or function(Value) end;
        }

        local Groupbox = self
        local Container = Groupbox.Container

        if not Info.Compact then
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 16);
                TextSize = 13;
                Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Bottom;
                TextColor3 = Theme.TextSecondary;
                ZIndex = 5;
                Parent = Container;
            })
            Groupbox:AddBlank(2)
        end

        local SliderOuter = Library:Create('Frame', {
            BackgroundColor3 = Theme.Background;
            BorderSizePixel = 0;
            Size = UDim2.new(1, -4, 0, 6);
            ZIndex = 5;
            Parent = Container;
        })
        SetCorner(SliderOuter, UDim.new(0, 3))

        local Fill = Library:Create('Frame', {
            BackgroundColor3 = Theme.Primary;
            BorderSizePixel = 0;
            Size = UDim2.new(0, 0, 1, 0);
            ZIndex = 7;
            Parent = SliderOuter;
        })
        SetCorner(Fill, UDim.new(0, 3))

        local Knob = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderSizePixel = 0;
            Size = UDim2.new(0, 14, 0, 14);
            AnchorPoint = Vector2.new(0.5, 0.5);
            Position = UDim2.new(0, 0, 0.5, 0);
            ZIndex = 8;
            Parent = SliderOuter;
        })
        SetCorner(Knob, UDim.new(0, 7))
        SetShadow(Knob, 0, 6, 0.5)

        local ValueLabel = Library:CreateLabel({
            Size = UDim2.new(0, 50, 0, 16);
            Position = UDim2.new(1, -50, 0, -18);
            TextSize = 12;
            Text = tostring(Info.Default);
            TextColor3 = Theme.TextSecondary;
            TextXAlignment = Enum.TextXAlignment.Right;
            ZIndex = 9;
            Parent = SliderOuter;
        })

        Library:AddToRegistry(Fill, { BackgroundColor3 = 'Primary' })

        if type(Info.Tooltip) == 'string' then Library:AddToolTip(Info.Tooltip, SliderOuter) end

        function Slider:UpdateColors()
            Fill.BackgroundColor3 = Theme.Primary
        end

        function Slider:Display()
            local Suffix = Info.Suffix or ''
            if Info.Compact then
                ValueLabel.Text = Info.Text .. ': ' .. Slider.Value .. Suffix
            elseif Info.HideMax then
                ValueLabel.Text = tostring(Slider.Value .. Suffix)
            else
                ValueLabel.Text = string.format('%s/%s', Slider.Value .. Suffix, Slider.Max .. Suffix)
            end

            local X = math.ceil(Library:MapValue(Slider.Value, Slider.Min, Slider.Max, 0, Slider.MaxSize))
            Fill.Size = UDim2.new(0, X, 1, 0)
            Knob.Position = UDim2.new(0, X, 0.5, 0)
        end

        function Slider:OnChanged(Func)
            Slider.Changed = Func
            Func(Slider.Value)
        end

        local function Round(Value)
            if Slider.Rounding == 0 then return math.floor(Value) end
            return tonumber(string.format('%.' .. Slider.Rounding .. 'f', Value))
        end

        function Slider:GetValueFromXOffset(X)
            return Round(Library:MapValue(X, 0, Slider.MaxSize, Slider.Min, Slider.Max))
        end

        function Slider:SetValue(Str)
            local Num = tonumber(Str)
            if not Num then return end
            Num = math.clamp(Num, Slider.Min, Slider.Max)
            Slider.Value = Num
            Slider:Display()
            Library:SafeCallback(Slider.Callback, Slider.Value)
            Library:SafeCallback(Slider.Changed, Slider.Value)
        end

        SliderOuter.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                local mPos = Mouse.X
                local gPos = Fill.Size.X.Offset
                local Diff = mPos - (Fill.AbsolutePosition.X + gPos)

                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local nMPos = Mouse.X
                    local nX = math.clamp(gPos + (nMPos - mPos) + Diff, 0, Slider.MaxSize)
                    local nValue = Slider:GetValueFromXOffset(nX)
                    local OldValue = Slider.Value
                    Slider.Value = nValue
                    Slider:Display()

                    if nValue ~= OldValue then
                        Library:SafeCallback(Slider.Callback, Slider.Value)
                        Library:SafeCallback(Slider.Changed, Slider.Value)
                    end
                    RenderStepped:Wait()
                end
                Library:AttemptSave()
            end
        end)

        Slider:Display()
        Groupbox:AddBlank(Info.BlankSize or 8)
        Groupbox:Resize()
        Options[Idx] = Slider
        return Slider
    end

    function Funcs:AddDropdown(Idx, Info)
        if Info.SpecialType == 'Player' then
            Info.Values = GetPlayersString()
            Info.AllowNull = true
        elseif Info.SpecialType == 'Team' then
            Info.Values = GetTeamsString()
            Info.AllowNull = true
        end

        assert(Info.Values, 'AddDropdown: Missing dropdown value list.')
        assert(Info.AllowNull or Info.Default, 'AddDropdown: Missing default value. Pass `AllowNull` as true if this was intentional.')

        if not Info.Text then Info.Compact = true end

        local Dropdown = {
            Values = Info.Values;
            Value = Info.Multi and {};
            Multi = Info.Multi;
            Type = 'Dropdown';
            SpecialType = Info.SpecialType;
            Callback = Info.Callback or function(Value) end;
        }

        local Groupbox = self
        local Container = Groupbox.Container
        local RelativeOffset = 0

        if not Info.Compact then
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 16);
                TextSize = 13;
                Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Bottom;
                TextColor3 = Theme.TextSecondary;
                ZIndex = 5;
                Parent = Container;
            })
            Groupbox:AddBlank(2)
        end

        for _, Element in next, Container:GetChildren() do
            if not Element:IsA('UIListLayout') then
                RelativeOffset = RelativeOffset + Element.Size.Y.Offset
            end
        end

        local DropdownOuter = Library:Create('Frame', {
            BackgroundColor3 = Theme.Background;
            BorderSizePixel = 0;
            Size = UDim2.new(1, -4, 0, 32);
            ZIndex = 5;
            Parent = Container;
        })
        SetCorner(DropdownOuter, UDim.new(0, 8))
        SetStroke(DropdownOuter, Theme.Border)

        Library:OnHighlight(DropdownOuter, DropdownOuter,
            { BorderColor3 = Theme.BorderHover },
            { BorderColor3 = Theme.Border }
        )

        local DropdownArrow = Library:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0, 0.5);
            BackgroundTransparency = 1;
            Position = UDim2.new(1, -24, 0.5, 0);
            Size = UDim2.new(0, 14, 0, 14);
            Image = 'http://www.roblox.com/asset/?id=6282522798';
            ImageColor3 = Theme.TextMuted;
            ZIndex = 8;
            Parent = DropdownOuter;
        })

        local ItemList = Library:CreateLabel({
            Position = UDim2.new(0, 10, 0, 0);
            Size = UDim2.new(1, -40, 1, 0);
            TextSize = 13;
            Text = '--';
            TextXAlignment = Enum.TextXAlignment.Left;
            TextYAlignment = Enum.TextYAlignment.Center;
            TextColor3 = Theme.TextSecondary;
            TextWrapped = true;
            ZIndex = 7;
            Parent = DropdownOuter;
        })

        if type(Info.Tooltip) == 'string' then Library:AddToolTip(Info.Tooltip, DropdownOuter) end

        local MAX_DROPDOWN_ITEMS = 8

        local ListOuter = Library:Create('Frame', {
            BackgroundColor3 = Theme.Elevated;
            BorderSizePixel = 0;
            ZIndex = 50;
            Visible = false;
            Parent = ScreenGui;
        })
        SetCorner(ListOuter, UDim.new(0, 10))
        SetShadow(ListOuter, 0, 16, 0.5)

        local function RecalculateListPosition()
            ListOuter.Position = UDim2.fromOffset(DropdownOuter.AbsolutePosition.X, DropdownOuter.AbsolutePosition.Y + DropdownOuter.Size.Y.Offset + 4)
        end

        local function RecalculateListSize(YSize)
            ListOuter.Size = UDim2.fromOffset(DropdownOuter.AbsoluteSize.X, YSize or (MAX_DROPDOWN_ITEMS * 32 + 8))
        end

        RecalculateListPosition()
        RecalculateListSize()
        DropdownOuter:GetPropertyChangedSignal('AbsolutePosition'):Connect(RecalculateListPosition)

        local ListInner = Library:Create('Frame', {
            BackgroundColor3 = Theme.Surface;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 51;
            Parent = ListOuter;
        })
        SetCorner(ListInner, UDim.new(0, 10))

        Library:AddToRegistry(ListInner, { BackgroundColor3 = 'Surface' })

        local Scrolling = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            CanvasSize = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 51;
            Parent = ListInner;
            TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png';
            BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png';
            ScrollBarThickness = 3;
            ScrollBarImageColor3 = Theme.Primary;
        })

        Library:AddToRegistry(Scrolling, { ScrollBarImageColor3 = 'Primary' })

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 2);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Scrolling;
        })

        Library:Create('UIPadding', {
            PaddingLeft = UDim.new(0, 4);
            PaddingRight = UDim.new(0, 4);
            PaddingTop = UDim.new(0, 4);
            PaddingBottom = UDim.new(0, 4);
            Parent = Scrolling;
        })

        function Dropdown:Display()
            local Values = Dropdown.Values
            local Str = ''
            if Info.Multi then
                for _, Value in next, Values do
                    if Dropdown.Value[Value] then Str = Str .. Value .. ', ' end
                end
                Str = Str:sub(1, #Str - 2)
            else
                Str = Dropdown.Value or ''
            end
            ItemList.Text = (Str == '' and '--' or Str)
        end

        function Dropdown:GetActiveValues()
            if Info.Multi then
                local T = {}
                for Value, Bool in next, Dropdown.Value do table.insert(T, Value) end
                return T
            else
                return Dropdown.Value and 1 or 0
            end
        end

        function Dropdown:BuildDropdownList()
            local Values = Dropdown.Values
            local Buttons = {}

            for _, Element in next, Scrolling:GetChildren() do
                if not Element:IsA('UIListLayout') and not Element:IsA('UIPadding') then Element:Destroy() end
            end

            local Count = 0
            for _, Value in next, Values do
                local Table = {}
                Count = Count + 1

                local Button = Library:Create('Frame', {
                    BackgroundColor3 = Theme.Surface;
                    BorderSizePixel = 0;
                    Size = UDim2.new(1, 0, 0, 28);
                    ZIndex = 53;
                    Active = true;
                    Parent = Scrolling;
                })
                SetCorner(Button, UDim.new(0, 6))

                local ButtonLabel = Library:CreateLabel({
                    Active = false;
                    Size = UDim2.new(1, -12, 1, 0);
                    Position = UDim2.new(0, 10, 0, 0);
                    TextSize = 13;
                    Text = Value;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    TextYAlignment = Enum.TextYAlignment.Center;
                    TextColor3 = Theme.TextPrimary;
                    ZIndex = 55;
                    Parent = Button;
                })

                local Selected
                if Info.Multi then Selected = Dropdown.Value[Value]
                else Selected = Dropdown.Value == Value end

                function Table:UpdateButton()
                    if Info.Multi then Selected = Dropdown.Value[Value]
                    else Selected = Dropdown.Value == Value end

                    if Selected then
                        Tween(Button, {BackgroundColor3 = Theme.PrimaryMuted}, Anim.Fast)
                        Tween(ButtonLabel, {TextColor3 = Theme.Primary}, Anim.Fast)
                    else
                        Tween(Button, {BackgroundColor3 = Theme.Surface}, Anim.Fast)
                        Tween(ButtonLabel, {TextColor3 = Theme.TextPrimary}, Anim.Fast)
                    end
                end

                Button.MouseEnter:Connect(function()
                    if not Selected then
                        Tween(Button, {BackgroundColor3 = Theme.Elevated}, Anim.Fast)
                    end
                end)

                Button.MouseLeave:Connect(function()
                    if not Selected then
                        Tween(Button, {BackgroundColor3 = Theme.Surface}, Anim.Fast)
                    end
                end)

                ButtonLabel.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        local Try = not Selected
                        if Dropdown:GetActiveValues() == 1 and (not Try) and (not Info.AllowNull) then
                        else
                            if Info.Multi then
                                Selected = Try
                                if Selected then Dropdown.Value[Value] = true else Dropdown.Value[Value] = nil end
                            else
                                Selected = Try
                                if Selected then Dropdown.Value = Value else Dropdown.Value = nil end
                                for _, OtherButton in next, Buttons do OtherButton:UpdateButton() end
                            end
                            Table:UpdateButton()
                            Dropdown:Display()
                            Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                            Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
                            Library:AttemptSave()
                        end
                    end
                end)

                Table:UpdateButton()
                Dropdown:Display()
                Buttons[Button] = Table
            end

            Scrolling.CanvasSize = UDim2.fromOffset(0, (Count * 30) + 8)
            local Y = math.clamp(Count * 30, 0, MAX_DROPDOWN_ITEMS * 30) + 8
            RecalculateListSize(Y)
        end

        function Dropdown:SetValues(NewValues)
            if NewValues then Dropdown.Values = NewValues end
            Dropdown:BuildDropdownList()
        end

        function Dropdown:OpenDropdown()
            ListOuter.Visible = true
            Library.OpenedFrames[ListOuter] = true
            Tween(DropdownArrow, {Rotation = 180}, Anim.Fast)
            ListOuter.Size = UDim2.fromOffset(ListOuter.Size.X.Offset, 0)
            Tween(ListOuter, {Size = UDim2.fromOffset(ListOuter.Size.X.Offset, ListOuter.Size.Y.Offset)}, Anim.Bounce)
        end

        function Dropdown:CloseDropdown()
            Tween(DropdownArrow, {Rotation = 0}, Anim.Fast)
            Tween(ListOuter, {Size = UDim2.fromOffset(ListOuter.Size.X.Offset, 0)}, Anim.Fast)
            task.delay(0.15, function()
                ListOuter.Visible = false
                Library.OpenedFrames[ListOuter] = nil
            end)
        end

        function Dropdown:OnChanged(Func)
            Dropdown.Changed = Func
            Func(Dropdown.Value)
        end

        function Dropdown:SetValue(Val)
            if Dropdown.Multi then
                local nTable = {}
                for Value, Bool in next, Val do
                    if table.find(Dropdown.Values, Value) then nTable[Value] = true end
                end
                Dropdown.Value = nTable
            else
                if not Val then Dropdown.Value = nil
                elseif table.find(Dropdown.Values, Val) then Dropdown.Value = Val end
            end
            Dropdown:BuildDropdownList()
            Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
            Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
        end

        DropdownOuter.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                if ListOuter.Visible then Dropdown:CloseDropdown() else Dropdown:OpenDropdown() end
            end
        end)

        InputService.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                local AbsPos, AbsSize = ListOuter.AbsolutePosition, ListOuter.AbsoluteSize
                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20) or Mouse.Y > AbsPos.Y + AbsSize.Y then
                    Dropdown:CloseDropdown()
                end
            end
        end)

        Dropdown:BuildDropdownList()
        Dropdown:Display()

        local Defaults = {}
        if type(Info.Default) == 'string' then
            local Idx = table.find(Dropdown.Values, Info.Default)
            if Idx then table.insert(Defaults, Idx) end
        elseif type(Info.Default) == 'table' then
            for _, Value in next, Info.Default do
                local Idx = table.find(Dropdown.Values, Value)
                if Idx then table.insert(Defaults, Idx) end
            end
        elseif type(Info.Default) == 'number' and Dropdown.Values[Info.Default] ~= nil then
            table.insert(Defaults, Info.Default)
        end

        if next(Defaults) then
            for i = 1, #Defaults do
                local Index = Defaults[i]
                if Info.Multi then Dropdown.Value[Dropdown.Values[Index]] = true
                else Dropdown.Value = Dropdown.Values[Index] end
                if not Info.Multi then break end
            end
            Dropdown:BuildDropdownList()
            Dropdown:Display()
        end

        Groupbox:AddBlank(Info.BlankSize or 4)
        Groupbox:Resize()
        Options[Idx] = Dropdown
        return Dropdown
    end

    function Funcs:AddDependencyBox()
        local Depbox = { Dependencies = {} }
        local Groupbox = self
        local Container = Groupbox.Container

        local Holder = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, 0);
            Visible = false;
            Parent = Container;
        })

        local Frame = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 1, 0);
            Visible = true;
            Parent = Holder;
        })

        local Layout = Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Frame;
        })

        function Depbox:Resize()
            Holder.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y)
            Groupbox:Resize()
        end

        Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function() Depbox:Resize() end)
        Holder:GetPropertyChangedSignal('Visible'):Connect(function() Depbox:Resize() end)

        function Depbox:Update()
            for _, Dependency in next, Depbox.Dependencies do
                local Elem = Dependency[1]
                local Value = Dependency[2]
                if Elem.Type == 'Toggle' and Elem.Value ~= Value then
                    Holder.Visible = false
                    Depbox:Resize()
                    return
                end
            end
            Holder.Visible = true
            Depbox:Resize()
        end

        function Depbox:SetupDependencies(Dependencies)
            for _, Dependency in next, Dependencies do
                assert(type(Dependency) == 'table', 'SetupDependencies: Dependency is not of type `table`.')
                assert(Dependency[1], 'SetupDependencies: Dependency is missing element argument.')
                assert(Dependency[2] ~= nil, 'SetupDependencies: Dependency is missing value argument.')
            end
            Depbox.Dependencies = Dependencies
            Depbox:Update()
        end

        Depbox.Container = Frame
        setmetatable(Depbox, BaseGroupbox)
        table.insert(Library.DependencyBoxes, Depbox)
        return Depbox
    end

    BaseGroupbox.__index = Funcs
    BaseGroupbox.__namecall = function(Table, Key, ...)
        return Funcs[Key](...)
    end
end

-- ================================================================
--  WINDOW CREATION — Modern, rounded, professional
-- ================================================================
function Library:CreateWindow(...)
    local Arguments = { ... }
    local Config = { AnchorPoint = Vector2.zero }

    if type(...) == 'table' then
        Config = ...
    else
        Config.Title = Arguments[1]
        Config.AutoShow = Arguments[2] or false
    end

    if type(Config.Title) ~= 'string' then Config.Title = 'No title' end
    if type(Config.TabPadding) ~= 'number' then Config.TabPadding = 0 end
    if type(Config.MenuFadeTime) ~= 'number' then Config.MenuFadeTime = 0.2 end
    if typeof(Config.Position) ~= 'UDim2' then Config.Position = UDim2.fromOffset(175, 50) end
    if typeof(Config.Size) ~= 'UDim2' then Config.Size = UDim2.fromOffset(580, 620) end
    if Config.Center then
        Config.AnchorPoint = Vector2.new(0.5, 0.5)
        Config.Position = UDim2.fromScale(0.5, 0.5)
    end

    local Window = { Tabs = {} }

    -- Main window frame
    local Outer = Library:Create('Frame', {
        AnchorPoint = Config.AnchorPoint;
        BackgroundColor3 = Theme.Background;
        BorderSizePixel = 0;
        Position = Config.Position;
        Size = Config.Size;
        Visible = false;
        ZIndex = 1;
        Parent = ScreenGui;
    })
    SetCorner(Outer, UDim.new(0, 14))
    SetShadow(Outer, 0, 24, 0.4)

    Library:MakeDraggable(Outer, 40)

    local Inner = Library:Create('Frame', {
        BackgroundColor3 = Theme.Surface;
        BorderSizePixel = 0;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 1;
        Parent = Outer;
    })
    SetCorner(Inner, UDim.new(0, 13))

    Library:AddToRegistry(Inner, { BackgroundColor3 = 'Surface' })

    -- Title bar
    local TitleBar = Library:Create('Frame', {
        BackgroundColor3 = Theme.Surface;
        BorderSizePixel = 0;
        Size = UDim2.new(1, 0, 0, 44);
        ZIndex = 2;
        Parent = Inner;
    })
    SetCorner(TitleBar, UDim.new(0, 13))

    local TitleAccent = Library:Create('Frame', {
        BackgroundColor3 = Theme.Primary;
        BorderSizePixel = 0;
        Size = UDim2.new(0, 4, 0, 20);
        Position = UDim2.new(0, 16, 0, 12);
        ZIndex = 3;
        Parent = TitleBar;
    })
    SetCorner(TitleAccent, UDim.new(0, 2))

    local WindowLabel = Library:CreateLabel({
        Position = UDim2.new(0, 28, 0, 0);
        Size = UDim2.new(0, 0, 1, 0);
        Text = Config.Title or '';
        Font = Library.FontBold;
        TextSize = 15;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 3;
        Parent = TitleBar;
    })

    -- Close button
    local CloseButton = Library:Create('TextButton', {
        BackgroundTransparency = 1;
        Size = UDim2.new(0, 32, 0, 32);
        Position = UDim2.new(1, -40, 0, 6);
        Text = 'x';
        Font = Library.FontBold;
        TextSize = 16;
        TextColor3 = Theme.TextMuted;
        ZIndex = 3;
        Parent = TitleBar;
    })

    CloseButton.MouseEnter:Connect(function()
        Tween(CloseButton, {TextColor3 = Theme.Error}, Anim.Fast)
    end)
    CloseButton.MouseLeave:Connect(function()
        Tween(CloseButton, {TextColor3 = Theme.TextMuted}, Anim.Fast)
    end)
    CloseButton.MouseButton1Click:Connect(function()
        Library:Toggle()
    end)

    -- Main content area
    local MainSectionOuter = Library:Create('Frame', {
        BackgroundColor3 = Theme.Background;
        BorderSizePixel = 0;
        Position = UDim2.new(0, 12, 0, 48);
        Size = UDim2.new(1, -24, 1, -56);
        ZIndex = 1;
        Parent = Inner;
    })
    SetCorner(MainSectionOuter, UDim.new(0, 10))

    Library:AddToRegistry(MainSectionOuter, { BackgroundColor3 = 'Background' })

    local MainSectionInner = Library:Create('Frame', {
        BackgroundColor3 = Theme.Background;
        BorderSizePixel = 0;
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 1;
        Parent = MainSectionOuter;
    })
    SetCorner(MainSectionInner, UDim.new(0, 10))

    Library:AddToRegistry(MainSectionInner, { BackgroundColor3 = 'Background' })

    -- Tab area
    local TabArea = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 12, 0, 10);
        Size = UDim2.new(1, -24, 0, 32);
        ZIndex = 1;
        Parent = MainSectionInner;
    })

    local TabListLayout = Library:Create('UIListLayout', {
        Padding = UDim.new(0, Config.TabPadding);
        FillDirection = Enum.FillDirection.Horizontal;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = TabArea;
    })

    -- Tab container
    local TabContainer = Library:Create('Frame', {
        BackgroundColor3 = Theme.Surface;
        BorderSizePixel = 0;
        Position = UDim2.new(0, 12, 0, 48);
        Size = UDim2.new(1, -24, 1, -56);
        ZIndex = 2;
        Parent = MainSectionInner;
    })
    SetCorner(TabContainer, UDim.new(0, 10))

    Library:AddToRegistry(TabContainer, { BackgroundColor3 = 'Surface' })

    function Window:SetWindowTitle(Title)
        WindowLabel.Text = Title
    end

    function Window:AddTab(Name)
        local Tab = { Groupboxes = {}; Tabboxes = {} }

        local TabButtonWidth = Library:GetTextBounds(Name, Library.Font, 14)

        local TabButton = Library:Create('TextButton', {
            BackgroundColor3 = Theme.Background;
            BorderSizePixel = 0;
            Size = UDim2.new(0, TabButtonWidth + 24, 1, 0);
            ZIndex = 1;
            Text = '';
            Parent = TabArea;
        })
        SetCorner(TabButton, UDim.new(0, 8))

        local TabButtonLabel = Library:CreateLabel({
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, -2);
            Text = Name;
            TextSize = 13;
            TextColor3 = Theme.TextMuted;
            ZIndex = 2;
            Parent = TabButton;
        })

        local TabIndicator = Library:Create('Frame', {
            BackgroundColor3 = Theme.Primary;
            BorderSizePixel = 0;
            Position = UDim2.new(0.5, 0, 1, -2);
            AnchorPoint = Vector2.new(0.5, 0);
            Size = UDim2.new(0, 0, 0, 2);
            ZIndex = 3;
            Parent = TabButton;
        })
        SetCorner(TabIndicator, UDim.new(0, 1))

        local TabFrame = Library:Create('Frame', {
            Name = 'TabFrame';
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            Visible = false;
            ZIndex = 2;
            Parent = TabContainer;
        })

        local LeftSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 8, 0, 8);
            Size = UDim2.new(0.5, -12, 0, 520);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            BottomImage = '';
            TopImage = '';
            ScrollBarThickness = 0;
            ZIndex = 2;
            Parent = TabFrame;
        })

        local RightSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0.5, 4, 0, 8);
            Size = UDim2.new(0.5, -12, 0, 520);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            BottomImage = '';
            TopImage = '';
            ScrollBarThickness = 0;
            ZIndex = 2;
            Parent = TabFrame;
        })

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 10);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
            Parent = LeftSide;
        })

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 10);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
            Parent = RightSide;
        })

        for _, Side in next, { LeftSide, RightSide } do
            Side:WaitForChild('UIListLayout'):GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                Side.CanvasSize = UDim2.fromOffset(0, Side.UIListLayout.AbsoluteContentSize.Y)
            end)
        end

        function Tab:ShowTab()
            for _, Tab in next, Window.Tabs do
                Tab:HideTab()
            end
            Tween(TabButtonLabel, {TextColor3 = Theme.TextPrimary}, Anim.Fast)
            Tween(TabIndicator, {Size = UDim2.new(0.6, 0, 0, 2)}, Anim.Bounce)
            TabFrame.Visible = true
        end

        function Tab:HideTab()
            Tween(TabButtonLabel, {TextColor3 = Theme.TextMuted}, Anim.Fast)
            Tween(TabIndicator, {Size = UDim2.new(0, 0, 0, 2)}, Anim.Fast)
            TabFrame.Visible = false
        end

        function Tab:SetLayoutOrder(Position)
            TabButton.LayoutOrder = Position
            TabListLayout:ApplyLayout()
        end

        function Tab:AddGroupbox(Info)
            local Groupbox = {}

            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Theme.Elevated;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 520);
                ZIndex = 2;
                Parent = Info.Side == 1 and LeftSide or RightSide;
            })
            SetCorner(BoxOuter, UDim.new(0, 10))

            Library:AddToRegistry(BoxOuter, { BackgroundColor3 = 'Elevated' })

            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Theme.Elevated;
                BorderSizePixel = 0;
                Size = UDim2.new(1, -2, 1, -2);
                Position = UDim2.new(0, 1, 0, 1);
                ZIndex = 4;
                Parent = BoxOuter;
            })
            SetCorner(BoxInner, UDim.new(0, 10))

            Library:AddToRegistry(BoxInner, { BackgroundColor3 = 'Elevated' })

            local Highlight = Library:Create('Frame', {
                BackgroundColor3 = Theme.Primary;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 2);
                ZIndex = 5;
                Parent = BoxInner;
            })
            SetCorner(Highlight, UDim.new(0, 10))

            Library:AddToRegistry(Highlight, { BackgroundColor3 = 'Primary' })

            local GroupboxLabel = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 18);
                Position = UDim2.new(0, 12, 0, 10);
                TextSize = 13;
                Text = Info.Name;
                Font = Library.FontMedium;
                TextXAlignment = Enum.TextXAlignment.Left;
                ZIndex = 5;
                Parent = BoxInner;
            })

            local Container = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 8, 0, 32);
                Size = UDim2.new(1, -16, 1, -36);
                ZIndex = 1;
                Parent = BoxInner;
            })

            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = Container;
            })

            function Groupbox:Resize()
                local Size = 0
                for _, Element in next, Groupbox.Container:GetChildren() do
                    if not Element:IsA('UIListLayout') and Element.Visible then
                        Size = Size + Element.Size.Y.Offset
                    end
                end
                BoxOuter.Size = UDim2.new(1, 0, 0, 36 + Size + 8)
            end

            Groupbox.Container = Container
            setmetatable(Groupbox, BaseGroupbox)
            Groupbox:AddBlank(4)
            Groupbox:Resize()

            Tab.Groupboxes[Info.Name] = Groupbox
            return Groupbox
        end

        function Tab:AddLeftGroupbox(Name)
            return Tab:AddGroupbox({ Side = 1; Name = Name; })
        end

        function Tab:AddRightGroupbox(Name)
            return Tab:AddGroupbox({ Side = 2; Name = Name; })
        end

        function Tab:AddTabbox(Info)
            local Tabbox = { Tabs = {} }

            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Theme.Elevated;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 0);
                ZIndex = 2;
                Parent = Info.Side == 1 and LeftSide or RightSide;
            })
            SetCorner(BoxOuter, UDim.new(0, 10))

            Library:AddToRegistry(BoxOuter, { BackgroundColor3 = 'Elevated' })

            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Theme.Elevated;
                BorderSizePixel = 0;
                Size = UDim2.new(1, -2, 1, -2);
                Position = UDim2.new(0, 1, 0, 1);
                ZIndex = 4;
                Parent = BoxOuter;
            })
            SetCorner(BoxInner, UDim.new(0, 10))

            Library:AddToRegistry(BoxInner, { BackgroundColor3 = 'Elevated' })

            local Highlight = Library:Create('Frame', {
                BackgroundColor3 = Theme.Primary;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 2);
                ZIndex = 10;
                Parent = BoxInner;
            })
            SetCorner(Highlight, UDim.new(0, 10))

            Library:AddToRegistry(Highlight, { BackgroundColor3 = 'Primary' })

            local TabboxButtons = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 0, 0, 1);
                Size = UDim2.new(1, 0, 0, 32);
                ZIndex = 5;
                Parent = BoxInner;
            })

            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Left;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = TabboxButtons;
            })

            function Tabbox:AddTab(Name)
                local Tab = {}

                local Button = Library:Create('TextButton', {
                    BackgroundColor3 = Theme.Surface;
                    BorderSizePixel = 0;
                    Size = UDim2.new(0.5, 0, 1, 0);
                    Text = '';
                    ZIndex = 6;
                    Parent = TabboxButtons;
                })
                SetCorner(Button, UDim.new(0, 6))

                Library:AddToRegistry(Button, { BackgroundColor3 = 'Surface' })

                local ButtonLabel = Library:CreateLabel({
                    Size = UDim2.new(1, 0, 1, 0);
                    TextSize = 12;
                    Text = Name;
                    TextColor3 = Theme.TextMuted;
                    TextXAlignment = Enum.TextXAlignment.Center;
                    ZIndex = 7;
                    Parent = Button;
                })

                local Indicator = Library:Create('Frame', {
                    BackgroundColor3 = Theme.Primary;
                    BorderSizePixel = 0;
                    Position = UDim2.new(0.5, 0, 1, -2);
                    AnchorPoint = Vector2.new(0.5, 0);
                    Size = UDim2.new(0, 0, 0, 2);
                    Visible = false;
                    ZIndex = 9;
                    Parent = Button;
                })
                SetCorner(Indicator, UDim.new(0, 1))

                local Container = Library:Create('Frame', {
                    BackgroundTransparency = 1;
                    Position = UDim2.new(0, 8, 0, 36);
                    Size = UDim2.new(1, -16, 1, -40);
                    ZIndex = 1;
                    Visible = false;
                    Parent = BoxInner;
                })

                Library:Create('UIListLayout', {
                    FillDirection = Enum.FillDirection.Vertical;
                    SortOrder = Enum.SortOrder.LayoutOrder;
                    Parent = Container;
                })

                function Tab:Show()
                    for _, Tab in next, Tabbox.Tabs do
                        Tab:Hide()
                    end
                    Container.Visible = true
                    Indicator.Visible = true
                    Tween(Indicator, {Size = UDim2.new(0.5, 0, 0, 2)}, Anim.Bounce)
                    Tween(ButtonLabel, {TextColor3 = Theme.TextPrimary}, Anim.Fast)
                    Button.BackgroundColor3 = Theme.Elevated
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = 'Elevated'
                    Tab:Resize()
                end

                function Tab:Hide()
                    Container.Visible = false
                    Indicator.Visible = false
                    Indicator.Size = UDim2.new(0, 0, 0, 2)
                    Tween(ButtonLabel, {TextColor3 = Theme.TextMuted}, Anim.Fast)
                    Button.BackgroundColor3 = Theme.Surface
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = 'Surface'
                end

                function Tab:Resize()
                    local TabCount = 0
                    for _ in next, Tabbox.Tabs do TabCount = TabCount + 1 end
                    for _, Btn in next, TabboxButtons:GetChildren() do
                        if not Btn:IsA('UIListLayout') then
                            Btn.Size = UDim2.new(1 / TabCount, 0, 1, 0)
                        end
                    end
                    if not Container.Visible then return end
                    local Size = 0
                    for _, Element in next, Tab.Container:GetChildren() do
                        if not Element:IsA('UIListLayout') and Element.Visible then
                            Size = Size + Element.Size.Y.Offset
                        end
                    end
                    BoxOuter.Size = UDim2.new(1, 0, 0, 40 + Size + 8)
                end

                Button.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                        Tab:Show()
                        Tab:Resize()
                    end
                end)

                Tab.Container = Container
                Tabbox.Tabs[Name] = Tab
                setmetatable(Tab, BaseGroupbox)
                Tab:AddBlank(4)
                Tab:Resize()

                if #TabboxButtons:GetChildren() == 2 then
                    Tab:Show()
                end

                return Tab
            end

            Tab.Tabboxes[Info.Name or ''] = Tabbox
            return Tabbox
        end

        function Tab:AddLeftTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 1; })
        end

        function Tab:AddRightTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 2; })
        end

        TabButton.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                Tab:ShowTab()
            end
        end)

        if #TabContainer:GetChildren() == 1 then
            Tab:ShowTab()
        end

        Window.Tabs[Name] = Tab
        return Tab
    end

    -- Toggle system
    local ModalElement = Library:Create('TextButton', {
        BackgroundTransparency = 1;
        Size = UDim2.new(0, 0, 0, 0);
        Visible = true;
        Text = '';
        Modal = false;
        Parent = ScreenGui;
    })

    local TransparencyCache = {}
    local Toggled = false
    local Fading = false

    function Library:Toggle()
        if Fading then return end
        local FadeTime = Config.MenuFadeTime
        Fading = true
        Toggled = (not Toggled)
        ModalElement.Modal = Toggled

        if Toggled then
            Outer.Visible = true
            Outer.Size = UDim2.new(0, Config.Size.X.Offset * 0.95, 0, Config.Size.Y.Offset * 0.95)
            Tween(Outer, {Size = Config.Size}, Anim.Bounce)

            task.spawn(function()
                local State = InputService.MouseIconEnabled
                local Cursor = Drawing.new('Triangle')
                Cursor.Thickness = 1
                Cursor.Filled = true
                Cursor.Visible = true

                local CursorOutline = Drawing.new('Triangle')
                CursorOutline.Thickness = 1
                CursorOutline.Filled = false
                CursorOutline.Color = Color3.new(0, 0, 0)
                CursorOutline.Visible = true

                while Toggled and ScreenGui.Parent do
                    InputService.MouseIconEnabled = false
                    local mPos = InputService:GetMouseLocation()
                    Cursor.Color = Theme.Primary
                    Cursor.PointA = Vector2.new(mPos.X, mPos.Y)
                    Cursor.PointB = Vector2.new(mPos.X + 16, mPos.Y + 6)
                    Cursor.PointC = Vector2.new(mPos.X + 6, mPos.Y + 16)
                    CursorOutline.PointA = Cursor.PointA
                    CursorOutline.PointB = Cursor.PointB
                    CursorOutline.PointC = Cursor.PointC
                    RenderStepped:Wait()
                end

                InputService.MouseIconEnabled = State
                Cursor:Remove()
                CursorOutline:Remove()
            end)
        else
            Tween(Outer, {Size = UDim2.new(0, Config.Size.X.Offset * 0.95, 0, Config.Size.Y.Offset * 0.95)}, Anim.Smooth)
            task.delay(FadeTime, function()
                Outer.Visible = false
            end)
        end

        for _, Desc in next, Outer:GetDescendants() do
            local Properties = {}
            if Desc:IsA('ImageLabel') then
                table.insert(Properties, 'ImageTransparency')
                table.insert(Properties, 'BackgroundTransparency')
            elseif Desc:IsA('TextLabel') or Desc:IsA('TextBox') then
                table.insert(Properties, 'TextTransparency')
            elseif Desc:IsA('Frame') or Desc:IsA('ScrollingFrame') then
                table.insert(Properties, 'BackgroundTransparency')
            elseif Desc:IsA('UIStroke') then
                table.insert(Properties, 'Transparency')
            end

            local Cache = TransparencyCache[Desc]
            if not Cache then
                Cache = {}
                TransparencyCache[Desc] = Cache
            end

            for _, Prop in next, Properties do
                if not Cache[Prop] then Cache[Prop] = Desc[Prop] end
                if Cache[Prop] == 1 then continue end
                TweenService:Create(Desc, TweenInfo.new(FadeTime, Enum.EasingStyle.Linear), { [Prop] = Toggled and Cache[Prop] or 1 }):Play()
            end
        end

        task.wait(FadeTime)
        Fading = false
    end

    Library:GiveSignal(InputService.InputBegan:Connect(function(Input, Processed)
        if type(Library.ToggleKeybind) == 'table' and Library.ToggleKeybind.Type == 'KeyPicker' then
            if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Library.ToggleKeybind.Value then
                task.spawn(Library.Toggle)
            end
        elseif Input.KeyCode == Enum.KeyCode.RightControl or (Input.KeyCode == Enum.KeyCode.RightShift and not Processed) then
            task.spawn(Library.Toggle)
        end
    end))

    if Config.AutoShow then task.spawn(Library.Toggle) end

    Window.Holder = Outer
    return Window
end

-- ================================================================
--  PLAYER/TEAM LISTENERS
-- ================================================================
local function OnPlayerChange()
    local PlayerList = GetPlayersString()
    for _, Value in next, Options do
        if Value.Type == 'Dropdown' and Value.SpecialType == 'Player' then
            Value:SetValues(PlayerList)
        end
    end
end

Players.PlayerAdded:Connect(OnPlayerChange)
Players.PlayerRemoving:Connect(OnPlayerChange)

getgenv().Library = Library
return Library
