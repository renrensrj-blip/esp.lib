local Floor   = math.floor
local Max     = math.max
local Huge    = math.huge
local Clamp   = math.clamp
local Sqrt    = math.sqrt
local Tan     = math.tan
local Rad     = math.rad

local Vector3New = Vector3.new
local Vector2New = Vector2.new
local UDim2New   = UDim2.new
local Color3New  = Color3.new
local Rgb        = Color3.fromRGB
local CFrameNew  = CFrame.new
local NewInstance = Instance.new
local ToString   = tostring

local CloneRef = cloneref or function(x) return x end
local PlayersService    = CloneRef(game:GetService("Players"))
local RunService        = CloneRef(game:GetService("RunService"))
local HttpService       = CloneRef(game:GetService("HttpService"))
local CurrentCamera     = workspace.CurrentCamera
local LocalPlayer       = PlayersService.LocalPlayer

local White = Color3New(1, 1, 1)
local Black = Color3New(0, 0, 0)
local BarBackgroundColor = Rgb(5, 10, 25)

local GlowPad    = 21
local GlowPad2   = GlowPad * 2
local GlowSlice  = Rect.new(Vector2New(21, 21), Vector2New(79, 79))

local ScreenMinX, ScreenMinY, ScreenMaxX, ScreenMaxY = 0, 0, 0, 0
local CameraRightX, CameraRightY, CameraRightZ = 0, 0, 0
local CameraUpX, CameraUpY, CameraUpZ = 0, 0, 0
local CameraLookX, CameraLookY, CameraLookZ = 0, 0, 0
local CameraPosX, CameraPosY, CameraPosZ = 0, 0, 0
local FocalLength, HalfViewportX, HalfViewportY = 1, 0, 0

local FontSmall  = Font.new("rbxasset://fonts/families/RobotoMono.json")
local FontTahoma = Font.new("rbxasset://fonts/families/RobotoMono.json")

pcall(function()
    local function LoadFont(Name, Weight, Style, AssetFile, Data)
        if isfile(AssetFile) then delfile(AssetFile) end
        writefile(AssetFile, Data)
        task.wait(0.1)
        local FontFile = Name .. ".font"
        if isfile(FontFile) then delfile(FontFile) end
        writefile(FontFile, HttpService:JSONEncode({
            name = Name,
            faces = {{ name = "Regular", weight = Weight, style = Style, assetId = getcustomasset(AssetFile) }},
        }))
        task.wait(0.1)
        return getcustomasset(FontFile)
    end

    FontSmall = Font.new(LoadFont(
        "SmallestPixel.ttf", 100, "normal", "SmallestPixelAsset.ttf",
        crypt.base64.decode(game:HttpGet("https://gist.githubusercontent.com/index987745/cbe1120f297fc9e7a31568f290a36c30/raw/6dbbb378feffbebb2af51cc8b0125b837f590f7a/SmallestPixel.tff"))
    ))
    FontTahoma = Font.new(LoadFont(
        "Tahoma.ttf", 400, "normal", "TahomaAsset.ttf",
        game:HttpGet("https://github.com/f1nobe7650/Nebula/raw/refs/heads/main/fs-tahoma-8px.ttf")
    ))
end)

local Esp = { Cache = {}, List = {}, Connections = {}, LocalRoot = nil }

Esp.Settings = {
    Enabled = false, LocalPlayer = true, Font = "Tahoma",
    FontSize = 12, FontType = "lowercase", MaxDistance = 9e9, RefreshRate = 60,

    Highlight = {
        Enabled = true,
        FillColor = Rgb(216, 126, 157),
        OutlineColor = Rgb(0, 0, 0),
        FillTransparency = 0.5,
        OutlineTransparency = 0,
        DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
    },

    Box = {
        Enabled = false, Rotation = 90,
        Color = { Rgb(216, 126, 157), Rgb(216, 126, 157) },
        Transparency = { 0, 0 },
        Glow = {
            Enabled = true, Rotation = 90,
            Color = { Rgb(216, 126, 157), Rgb(216, 126, 157) },
            Transparency = { 0.75, 0.75 },
        },
        Fill = {
            Enabled = true, Rotation = 90,
            Color = { Rgb(216, 126, 157), Rgb(216, 126, 157) },
            Transparency = { 1, 0.5 },
        },
    },

    Bars = {
        HealthBar = {
            Enabled = true, Position = "Left",
            Color = { Rgb(252, 71, 77), Rgb(255, 255, 0), Rgb(131, 245, 78) },
            Text = {
                Enabled = true, FollowBar = false, Ending = "HP",
                Position = "Left", Color = Rgb(255, 255, 255), Transparency = 0,
            },
        },
        ArmorBar = {
            Enabled = true, Position = "Bottom",
            Color = { Rgb(52, 131, 235), Rgb(52, 131, 235), Rgb(52, 131, 235) },
            Type = function() return 100, 100 end,
        },
    },

    Name     = { Enabled = true,  UseDisplay = true, Position = "Top",    Color = Rgb(255,255,255), Transparency = 0 },
    Distance = { Enabled = true,  Ending = "st",     Position = "Bottom", Color = Rgb(255,255,255), Transparency = 0 },
    Weapon   = { Enabled = true,  ShowNone = true,   Position = "Bottom", Color = Rgb(255,255,255), Transparency = 0 },
    Flags    = {
        Enabled = true, Position = "Right", Color = Rgb(255,255,255), Transparency = 0,
        Type = function(Speed, Jumping)
            if Jumping    then return { "jumping" }  end
            if Speed > 0  then return { "moving" }   end
            return { "standing" }
        end,
    },
}

local LocalSettings = Esp.Settings

local function GetFont()   return LocalSettings.Font == "Tahoma" and FontTahoma or FontSmall end
local function GetFontSize() return LocalSettings.FontSize or 12 end

local function FormatText(Text)
    if LocalSettings.FontType == "uppercase" then return string.upper(Text) end
    if LocalSettings.FontType == "lowercase" then return string.lower(Text) end
    return Text
end

local BarWidth         = 1
local BarGap           = 4
local BarPad           = 1
local BarWidthOutline  = BarWidth + 2
local BarPad2          = BarPad * 2
local BarGapWidth      = BarGap + BarWidth
local ArmorHeight       = 1
local ArmorHeightOutline = 3
local ArmorGap          = 4
local ArmorPad          = 1

local function Gradient2(A, B)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0, A),
        ColorSequenceKeypoint.new(1, B),
    })
end

local function Gradient3(A, B, C)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0,   A),
        ColorSequenceKeypoint.new(0.5, B),
        ColorSequenceKeypoint.new(1,   C),
    })
end

local function GlowFadeTop()
    return NumberSequence.new({
        NumberSequenceKeypoint.new(0,   0),
        NumberSequenceKeypoint.new(0.5, LocalSettings.Box.Glow.Transparency[1]),
        NumberSequenceKeypoint.new(1,   1),
    })
end

local function GlowFadeBottom()
    return NumberSequence.new({
        NumberSequenceKeypoint.new(0,   1),
        NumberSequenceKeypoint.new(0.5, LocalSettings.Box.Glow.Transparency[2]),
        NumberSequenceKeypoint.new(1,   0),
    })
end

local R15Parts = {
    "Head","UpperTorso","LowerTorso",
    "LeftUpperArm","LeftLowerArm","LeftHand",
    "RightUpperArm","RightLowerArm","RightHand",
    "LeftUpperLeg","LeftLowerLeg","LeftFoot",
    "RightUpperLeg","RightLowerLeg","RightFoot",
}
local R6Parts = { "Head","Torso","Left Arm","Right Arm","Left Leg","Right Leg" }

local R15Padding = { Head=0.05, LeftHand=0.02, RightHand=0.02, LeftFoot=0.04, RightFoot=0.04 }
local R6Padding  = { Head=0.05, ["Left Leg"]=0.03, ["Right Leg"]=0.03 }

local BodyPartSet = {
    Head=true, LeftHand=true, RightHand=true, LeftFoot=true, RightFoot=true,
    ["Left Arm"]=true, ["Right Arm"]=true, Torso=true,
    ["Left Leg"]=true, ["Right Leg"]=true,
}

local function MakeInstance(Class, Properties)
    local Object = NewInstance(Class)
    for Key, Value in pairs(Properties) do Object[Key] = Value end
    return Object
end

local Gui = NewInstance("ScreenGui")
Gui.Name             = "\0"
Gui.ResetOnSpawn     = false
Gui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
Gui.IgnoreGuiInset   = true
Gui.Parent           = gethui()
Esp.ScreenGui        = Gui

local function MakeStrokeFrame(Parent, StrokeColor, ZIndex)
    local Frame = MakeInstance("Frame", {
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ZIndex = ZIndex, Visible = false, Size = UDim2New(0,0,0,0), Parent = Parent,
    })
    MakeInstance("UIStroke", {
        Color = StrokeColor, Thickness = 1,
        LineJoinMode = Enum.LineJoinMode.Miter,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = Frame,
    })
    return Frame
end

local function MakeGradientStrokeFrame(Parent, ZIndex)
    local Frame = MakeInstance("Frame", {
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ZIndex = ZIndex, Visible = false, Size = UDim2New(0,0,0,0), Parent = Parent,
    })
    local Stroke = MakeInstance("UIStroke", {
        Color = White, Thickness = 1,
        LineJoinMode = Enum.LineJoinMode.Miter,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = Frame,
    })
    local Grad = MakeInstance("UIGradient", {
        Color = Gradient2(LocalSettings.Box.Color[1], LocalSettings.Box.Color[2]),
        Rotation = LocalSettings.Box.Rotation,
        Parent = Stroke,
    })
    return Frame, Grad
end

local function MakeSolidFrame(Parent, FillColor, ZIndex)
    return MakeInstance("Frame", {
        BackgroundColor3 = FillColor, BackgroundTransparency = 0,
        BorderSizePixel = 0, ZIndex = ZIndex,
        Visible = false, Size = UDim2New(0,0,0,0), Parent = Parent,
    })
end

local function MakeTextLabel(Parent, ZIndex, TextColor, FontSize, Alignment)
    local IsLeft = Alignment == "Left"
    local Label = MakeInstance("TextLabel", {
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ClipsDescendants = false, ZIndex = ZIndex, Visible = false,
        Size = UDim2New(0, 300, 0, FontSize + 4),
        AnchorPoint = IsLeft and Vector2New(0, 0) or Vector2New(0.5, 0),
        FontFace = GetFont(), TextSize = FontSize,
        TextColor3 = TextColor, TextStrokeTransparency = 1,
        TextXAlignment = IsLeft and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextTruncate = Enum.TextTruncate.None,
        TextScaled = false, RichText = false,
        Text = "", Parent = Parent,
    })
    MakeInstance("UIStroke", {
        Color = Black, Thickness = 1,
        LineJoinMode = Enum.LineJoinMode.Miter,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
        Parent = Label,
    })
    return Label
end

local function MakeFillFrame(Parent, ZIndex)
    local Frame = MakeInstance("Frame", {
        BackgroundColor3 = White, BorderSizePixel = 0,
        ZIndex = ZIndex, Visible = false, Size = UDim2New(0,0,0,0), Parent = Parent,
    })
    local Grad = MakeInstance("UIGradient", {
        Color = Gradient2(LocalSettings.Box.Fill.Color[1], LocalSettings.Box.Fill.Color[2]),
        Rotation = LocalSettings.Box.Fill.Rotation,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, LocalSettings.Box.Fill.Transparency[1]),
            NumberSequenceKeypoint.new(1, LocalSettings.Box.Fill.Transparency[2]),
        }),
        Parent = Frame,
    })
    return Frame, Grad
end

local function MakeGlowImage(Parent, FadeSequence, ZIndex)
    local Image = MakeInstance("ImageLabel", {
        Image = "rbxassetid://18245826428",
        ImageColor3 = LocalSettings.Box.Glow.Color[1],
        ImageTransparency = LocalSettings.Box.Glow.Transparency[1],
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = GlowSlice,
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ZIndex = ZIndex, Visible = false, Size = UDim2New(0,0,0,0), Parent = Parent,
    })
    local Grad = MakeInstance("UIGradient", {
        Transparency = FadeSequence,
        Rotation = LocalSettings.Box.Glow.Rotation,
        Parent = Image,
    })
    return Image, Grad
end

local function MakeBarFill(Parent, GradientColor, GradientRotation)
    local Frame = MakeInstance("Frame", {
        BackgroundColor3 = White, BorderSizePixel = 0,
        ZIndex = 11, Visible = false, Size = UDim2New(0,0,0,0), Parent = Parent,
    })
    local Grad = MakeInstance("UIGradient", {
        Color = GradientColor, Rotation = GradientRotation, Parent = Frame,
    })
    return Frame, Grad
end

local function MakeHighlight(Model)
    if not LocalSettings.Highlight.Enabled then return nil end
    local Highlight = NewInstance("Highlight")
    Highlight.FillColor           = LocalSettings.Highlight.FillColor
    Highlight.OutlineColor        = LocalSettings.Highlight.OutlineColor
    Highlight.FillTransparency    = LocalSettings.Highlight.FillTransparency
    Highlight.OutlineTransparency = LocalSettings.Highlight.OutlineTransparency
    Highlight.DepthMode           = LocalSettings.Highlight.DepthMode
    Highlight.Adornee             = Model
    Highlight.Parent              = Gui
    Highlight.Enabled             = true
    return Highlight
end

local function ExpandBounds(Depth, RightOffset, UpOffset)
    if Depth <= 0 then return end
    local Inv = FocalLength / Depth
    local SX  = HalfViewportX + RightOffset * Inv
    local SY  = HalfViewportY - UpOffset * Inv
    if SX < ScreenMinX then ScreenMinX = SX end
    if SX > ScreenMaxX then ScreenMaxX = SX end
    if SY < ScreenMinY then ScreenMinY = SY end
    if SY > ScreenMaxY then ScreenMaxY = SY end
end

local function ProjectOBB(PosX, PosY, PosZ, R00, R01, R02, R10, R11, R12, R20, R21, R22, HalfW, HalfH, HalfD)
    local AAX, AAY, AAZ = R00*HalfW, R01*HalfW, R02*HalfW
    local ABX, ABY, ABZ = R10*HalfH, R11*HalfH, R12*HalfH
    local ACX, ACY, ACZ = R20*HalfD, R21*HalfD, R22*HalfD
    local DX, DY, DZ    = PosX-CameraPosX, PosY-CameraPosY, PosZ-CameraPosZ
    local DotD = CameraLookX*DX + CameraLookY*DY + CameraLookZ*DZ
    local DotR = CameraRightX*DX + CameraRightY*DY + CameraRightZ*DZ
    local DotU = CameraUpX*DX + CameraUpY*DY + CameraUpZ*DZ
    local DA  = CameraLookX*AAX + CameraLookY*AAY + CameraLookZ*AAZ
    local RA  = CameraRightX*AAX + CameraRightY*AAY + CameraRightZ*AAZ
    local UA  = CameraUpX*AAX + CameraUpY*AAY + CameraUpZ*AAZ
    local DB  = CameraLookX*ABX + CameraLookY*ABY + CameraLookZ*ABZ
    local RB  = CameraRightX*ABX + CameraRightY*ABY + CameraRightZ*ABZ
    local UB  = CameraUpX*ABX + CameraUpY*ABY + CameraUpZ*ABZ
    local DC  = CameraLookX*ACX + CameraLookY*ACY + CameraLookZ*ACZ
    local RC  = CameraRightX*ACX + CameraRightY*ACY + CameraRightZ*ACZ
    local UC  = CameraUpX*ACX + CameraUpY*ACY + CameraUpZ*ACZ
    ExpandBounds(DotD+DA+DB+DC, DotR+RA+RB+RC, DotU+UA+UB+UC)
    ExpandBounds(DotD+DA+DB-DC, DotR+RA+RB-RC, DotU+UA+UB-UC)
    ExpandBounds(DotD+DA-DB+DC, DotR+RA-RB+RC, DotU+UA-UB+UC)
    ExpandBounds(DotD+DA-DB-DC, DotR+RA-RB-RC, DotU+UA-UB-UC)
    ExpandBounds(DotD-DA+DB+DC, DotR-RA+RB+RC, DotU-UA+UB+UC)
    ExpandBounds(DotD-DA+DB-DC, DotR-RA+RB-RC, DotU-UA+UB-UC)
    ExpandBounds(DotD-DA-DB+DC, DotR-RA-RB+RC, DotU-UA-UB+UC)
    ExpandBounds(DotD-DA-DB-DC, DotR-RA-RB-RC, DotU-UA-UB-UC)
end

local function HideBox(Entry)
    Entry.OuterStroke.Visible  = false
    Entry.BorderStroke.Visible = false
    Entry.InnerCover.Visible   = false
    Entry.InnerStroke.Visible  = false
end

local function HideFill(Entry)   Entry.BoxFill.Visible      = false end
local function HideGlow(Entry)   Entry.GlowTop.Visible = false; Entry.GlowBot.Visible = false end

local function HideHealthBar(Entry)
    Entry.BarOutline.Visible    = false
    Entry.BarBackground.Visible = false
    Entry.BarFill.Visible       = false
    Entry.LabelHealth.Visible   = false
end

local function HideArmorBar(Entry)
    Entry.ArmorOutline.Visible    = false
    Entry.ArmorBackground.Visible = false
    Entry.ArmorFill.Visible       = false
end

local function HideLabels(Entry)
    Entry.LabelName.Visible     = false
    Entry.LabelWeapon.Visible   = false
    Entry.LabelDistance.Visible = false
    Entry.LabelFlags.Visible    = false
end

local function HideHighlight(Entry)
    if Entry.Highlight then Entry.Highlight.Enabled = false end
end

local function ResetPositionCache(Entry)
    Entry.PrevBoxX=-1; Entry.PrevBoxY=-1; Entry.PrevBoxW=-1; Entry.PrevBoxH=-1
    Entry.PrevFillHeight=-1; Entry.PrevArmorFillWidth=-1
    Entry.PrevHealthLabelX=-1; Entry.PrevHealthLabelY=-1
    Entry.PrevNameLabelX=-1; Entry.PrevNameLabelY=-1
    Entry.PrevWeaponLabelX=-1; Entry.PrevWeaponLabelY=-1
    Entry.PrevDistanceLabelX=-1; Entry.PrevDistanceLabelY=-1
    Entry.PrevDistanceValue=-1
    Entry.PrevFlagsLabelX=-1; Entry.PrevFlagsLabelY=-1
end

local function ResetAllCache(Entry)
    ResetPositionCache(Entry)
    Entry.PrevHealthString=""; Entry.PrevNameString=""
    Entry.PrevWeaponString="__unset__"
    Entry.PrevDistanceString=""; Entry.PrevFlagsString=""
end

function Esp:HideEntry(Entry)
    HideBox(Entry); HideFill(Entry); HideGlow(Entry)
    HideHealthBar(Entry); HideArmorBar(Entry)
    HideLabels(Entry); HideHighlight(Entry)
    Entry.IsVisible = false
    ResetAllCache(Entry)
end

function Esp:NewEntry(Player)
    local Container = NewInstance("Frame")
    Container.Name                = ToString(Player) .. "_esp"
    Container.BackgroundTransparency = 1
    Container.BorderSizePixel     = 0
    Container.Size                = UDim2New(1,0,1,0)
    Container.ZIndex              = 1
    Container.Parent              = Gui

    local FontSize = GetFontSize()

    local BoxFillFrame, BoxFillGrad         = MakeFillFrame(Container, 8)
    local GlowTopFrame, GlowTopGrad         = MakeGlowImage(Container, GlowFadeTop(), 2)
    local GlowBottomFrame, GlowBottomGrad   = MakeGlowImage(Container, GlowFadeBottom(), 2)
    local BorderStrokeFrame, BorderGrad     = MakeGradientStrokeFrame(Container, 5)
    local BarFillFrame, BarFillGrad         = MakeBarFill(Container, Gradient3(LocalSettings.Bars.HealthBar.Color[1], LocalSettings.Bars.HealthBar.Color[2], LocalSettings.Bars.HealthBar.Color[3]), 270)
    local ArmorFillFrame, ArmorFillGrad     = MakeBarFill(Container, Gradient3(LocalSettings.Bars.ArmorBar.Color[1], LocalSettings.Bars.ArmorBar.Color[2], LocalSettings.Bars.ArmorBar.Color[3]), 0)

    local Entry = {
        Player = Player, PlayerName = Player.Name, Container = Container,

        OuterStroke   = MakeStrokeFrame(Container, Black, 4),
        BorderStroke  = BorderStrokeFrame,
        BorderGrad    = BorderGrad,
        InnerCover    = MakeInstance("Frame", {
            BackgroundColor3 = Black, BackgroundTransparency = 1,
            BorderSizePixel = 0, ZIndex = 6, Visible = false,
            Size = UDim2New(0,0,0,0), Parent = Container,
        }),
        InnerStroke   = MakeStrokeFrame(Container, Black, 7),
        BoxFill       = BoxFillFrame,
        BoxFillGrad   = BoxFillGrad,

        BarOutline    = MakeSolidFrame(Container, Black, 9),
        BarBackground = MakeSolidFrame(Container, BarBackgroundColor, 10),
        BarFill       = BarFillFrame,
        BarFillGrad   = BarFillGrad,

        ArmorOutline    = MakeSolidFrame(Container, Black, 9),
        ArmorBackground = MakeSolidFrame(Container, BarBackgroundColor, 10),
        ArmorFill       = ArmorFillFrame,
        ArmorFillGrad   = ArmorFillGrad,

        GlowTop     = GlowTopFrame,
        GlowTopGrad = GlowTopGrad,
        GlowBot     = GlowBottomFrame,
        GlowBotGrad = GlowBottomGrad,

        LabelHealth   = MakeTextLabel(Container, 12, LocalSettings.Bars.HealthBar.Text.Color, FontSize, "Center"),
        LabelName     = MakeTextLabel(Container, 12, LocalSettings.Name.Color,     FontSize, "Center"),
        LabelWeapon   = MakeTextLabel(Container, 12, LocalSettings.Weapon.Color,   FontSize, "Center"),
        LabelDistance = MakeTextLabel(Container, 12, LocalSettings.Distance.Color, FontSize, "Center"),
        LabelFlags    = MakeTextLabel(Container, 12, LocalSettings.Flags.Color,    FontSize, "Left"),

        Highlight = nil, Character = nil, RootPart = nil, Humanoid = nil,
        IsDead = false, IsR6 = false, Health = 1, MaxHealth = 100,
        TopOffset = 3.0, BottomOffset = 3.0,
        Parts = {}, PartHalfWidth = {}, PartHalfHeight = {}, PartHalfDepth = {}, PartCount = 0,
        CachedMoveSpeed = 0, CachedJumping = false, IsVisible = false,

        BarX=0, BarY=0, BarHeight=0, BarLabelX=0, BarLabelY=0,
        ArmorBarX=0, ArmorBarY=0, ArmorBarWidth=0,
        FlagsLabelX=0, FlagsLabelY=0,

        HealthString="100", WeaponString="none", FlagsString="",
        PlayerConnections={}, CharacterConnections={},
    }

    ResetAllCache(Entry)
    return Entry
end

function Esp:DestroyEntry(Entry)
    self:HideEntry(Entry)
    for _, Connection in ipairs(Entry.PlayerConnections)   do pcall(Connection.Disconnect, Connection) end
    for _, Connection in ipairs(Entry.CharacterConnections) do pcall(Connection.Disconnect, Connection) end
    if Entry.Highlight then pcall(Entry.Highlight.Destroy, Entry.Highlight) end
    pcall(Entry.Container.Destroy, Entry.Container)
end

function Esp:BuildParts(Entry)
    local Character = Entry.Character
    if not Character then return end

    local PartNames  = Entry.IsR6 and R6Parts or R15Parts
    local PaddingMap = Entry.IsR6 and R6Padding   or R15Padding
    local RootY      = Entry.RootPart.Position.Y
    local LowestY, HighestY = Huge, -Huge
    local Parts, HalfWidths, HalfHeights, HalfDepths = {}, {}, {}, {}
    local Count = 0

    for Index = 1, #PartNames do
        local Part = Character:FindFirstChild(PartNames[Index])
        if not Part or not Part:IsA("BasePart") then continue end
        local Pad = PaddingMap[PartNames[Index]] or 0.04
        local Size  = Part.Size
        local HalfW = Size.X * 0.5 + Pad
        local HalfH = Size.Y * 0.5
        local HalfD = Size.Z * 0.5 + Pad
        local LocalY = Part.Position.Y - RootY
        if LocalY + HalfH > HighestY then HighestY = LocalY + HalfH end
        if LocalY - HalfH < LowestY  then LowestY  = LocalY - HalfH end
        Count += 1
        Parts[Count] = Part
        HalfWidths[Count] = HalfW; HalfHeights[Count] = HalfH; HalfDepths[Count] = HalfD
    end

    Entry.TopOffset  = HighestY == -Huge and 3.0 or HighestY + 0.02
    Entry.BottomOffset  = LowestY  ==  Huge and 3.0 or -LowestY + 0.02
    Entry.Parts      = Parts
    Entry.PartHalfWidth  = HalfWidths; Entry.PartHalfHeight = HalfHeights; Entry.PartHalfDepth = HalfDepths
    Entry.PartCount  = Count
end

function Esp:ClearCharacter(Entry)
    for _, Connection in ipairs(Entry.CharacterConnections) do pcall(Connection.Disconnect, Connection) end
    Entry.CharacterConnections = {}
    Entry.Character=nil; Entry.RootPart=nil; Entry.Humanoid=nil; Entry.IsDead=false
    Entry.Parts={}; Entry.PartHalfWidth={}; Entry.PartHalfHeight={}; Entry.PartHalfDepth={}; Entry.PartCount=0
    Entry.HealthString="100"; Entry.WeaponString="none"; Entry.FlagsString=""
    Entry.CachedMoveSpeed=0; Entry.CachedJumping=false
    if Entry.Highlight then pcall(Entry.Highlight.Destroy, Entry.Highlight); Entry.Highlight=nil end
end

local function GetWeapon(Character)
    local Tool = Character:FindFirstChildOfClass("Tool")
    return Tool and Tool.Name or "none"
end

local function RebuildFlags(Entry)
    if not LocalSettings.Flags.Type then return end
    local Result = LocalSettings.Flags.Type(Entry.CachedMoveSpeed, Entry.CachedJumping)
    if type(Result) == "table" then
        Entry.FlagsString = #Result > 0 and table.concat(Result, ", ") or ""
        Entry.PrevFlagsString = ""
    end
end

function Esp:LinkCharacter(Entry, Character)
    self:ClearCharacter(Entry)
    self:HideEntry(Entry)
    if not Character then return end

    local Root = Character:WaitForChild("HumanoidRootPart", 10)
    local Humanoid  = Character:WaitForChild("Humanoid", 10)
    if not Root or not Humanoid then return end

    if not Character:FindFirstChild("UpperTorso") and not Character:FindFirstChild("Torso") then
        task.wait(0.5)
    end

    Entry.IsR6         = Character:FindFirstChild("Torso") ~= nil
    Entry.Character    = Character
    Entry.RootPart     = Root
    Entry.Humanoid     = Humanoid
    Entry.IsDead       = false
    Entry.MaxHealth    = Humanoid.MaxHealth
    Entry.Health       = Clamp(Humanoid.Health / Humanoid.MaxHealth, 0, 1)
    Entry.HealthString = ToString(Floor(Humanoid.Health))
    Entry.CachedMoveSpeed  = Humanoid.MoveDirection.Magnitude
    Entry.CachedJumping    = Humanoid.Jump
    Entry.WeaponString     = GetWeapon(Character)
    RebuildFlags(Entry)

    if LocalSettings.Highlight.Enabled then
        if Entry.Highlight then pcall(Entry.Highlight.Destroy, Entry.Highlight) end
        Entry.Highlight = MakeHighlight(Character)
    end

    local Connections = Entry.CharacterConnections

    Connections[#Connections+1] = Humanoid.HealthChanged:Connect(function(Health)
        Entry.Health = Clamp(Health / Entry.MaxHealth, 0, 1)
        Entry.HealthString = ToString(Floor(Health))
        Entry.PrevFillHeight = -1; Entry.PrevHealthString = ""
    end)

    Connections[#Connections+1] = Humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
        Entry.MaxHealth = Humanoid.MaxHealth
    end)

    Connections[#Connections+1] = Humanoid.Died:Connect(function()
        Entry.IsDead = true
        if Entry.Highlight then Entry.Highlight.Enabled = false end
        self:HideEntry(Entry)
    end)

    Connections[#Connections+1] = Humanoid.StateChanged:Connect(function(_, NewState)
        Entry.CachedJumping = NewState == Enum.HumanoidStateType.Jumping or NewState == Enum.HumanoidStateType.Freefall
        RebuildFlags(Entry)
    end)

    Connections[#Connections+1] = Humanoid.Running:Connect(function(Speed)
        Entry.CachedMoveSpeed = Speed; RebuildFlags(Entry)
    end)

    Connections[#Connections+1] = Character.ChildAdded:Connect(function(Child)
        if Child:IsA("Tool") then
            Entry.WeaponString = Child.Name; Entry.PrevWeaponString = "__unset__"
        end
    end)

    Connections[#Connections+1] = Character.ChildRemoved:Connect(function(Child)
        if Child:IsA("Tool") then
            Entry.WeaponString = GetWeapon(Character); Entry.PrevWeaponString = "__unset__"
        end
    end)

    Connections[#Connections+1] = Character.DescendantAdded:Connect(function(Descendant)
        if not Descendant:IsA("BasePart") or not BodyPartSet[Descendant.Name] then return end
        local Parent = Descendant.Parent
        while Parent and Parent ~= Character do
            if Parent:IsA("Tool") then return end
            Parent = Parent.Parent
        end
        task.defer(function() self:BuildParts(Entry) end)
    end)

    Connections[#Connections+1] = Character.DescendantRemoving:Connect(function(Descendant)
        if Descendant:IsA("BasePart") and BodyPartSet[Descendant.Name] then
            task.defer(function() self:BuildParts(Entry) end)
        end
    end)

    self:BuildParts(Entry)
end

function Esp:Add(Player)
    if Player == LocalPlayer then return end
    if self.Cache[Player] then self:DestroyEntry(self.Cache[Player]) end

    local Entry = self:NewEntry(Player)
    self.Cache[Player]    = Entry
    self.List[#self.List+1] = Entry

    local Connections = Entry.PlayerConnections

    Connections[#Connections+1] = Player.CharacterAdded:Connect(function(Character)
        task.spawn(function() self:LinkCharacter(Entry, Character) end)
    end)

    Connections[#Connections+1] = Player.CharacterRemoving:Connect(function()
        Entry.Character = nil; Entry.RootPart = nil
        if Entry.Highlight then Entry.Highlight.Enabled = false end
        self:HideEntry(Entry)
    end)

    if Player.Character then
        task.spawn(function() self:LinkCharacter(Entry, Player.Character) end)
    end
end

function Esp:Remove(Player)
    local Entry = self.Cache[Player]
    if not Entry then return end
    self.Cache[Player] = nil
    local List = self.List
    for Index = 1, #List do
        if List[Index] == Entry then List[Index] = List[#List]; List[#List] = nil; break end
    end
    self:DestroyEntry(Entry)
end

local function OnLocalCharacterAdded(Character)
    Esp.LocalRoot = Character and Character:WaitForChild("HumanoidRootPart", 5) or nil
end

if LocalPlayer.Character then task.spawn(OnLocalCharacterAdded, LocalPlayer.Character) end
Esp.Connections[#Esp.Connections+1] = LocalPlayer.CharacterAdded:Connect(OnLocalCharacterAdded)
Esp.Connections[#Esp.Connections+1] = LocalPlayer.CharacterRemoving:Connect(function() Esp.LocalRoot = nil end)

local NameOffset      = -18
local WeaponOffset    = 19
local DistanceOffset  = 8
local HealthOffset    = -3
local FlagsOffset     = -2
local CullDistanceSq  = 9e9
local LodDistanceSq   = 300 * 300
local DeltaTimeAccumulator = 0
local FrameTime       = 1 / 60

local function LodFallback(Depth, Right, Up, TopOffset, BottomOffset, HalfWidth)
    local Inv
    local TopDepth = Depth + CameraLookY * TopOffset
    if TopDepth > 0 then
        Inv = FocalLength / TopDepth
        local LeftX   = HalfViewportX + (Right - HalfWidth) * Inv
        local RightX  = HalfViewportX + (Right + HalfWidth) * Inv
        local ScreenY = HalfViewportY - (Up + TopOffset) * Inv
        if LeftX   < ScreenMinX then ScreenMinX = LeftX end
        if RightX  > ScreenMaxX then ScreenMaxX = RightX end
        if ScreenY < ScreenMinY then ScreenMinY = ScreenY end
        if ScreenY > ScreenMaxY then ScreenMaxY = ScreenY end
    end
    local BottomDepth = Depth - CameraLookY * BottomOffset
    if BottomDepth > 0 then
        Inv = FocalLength / BottomDepth
        local LeftX   = HalfViewportX + (Right - HalfWidth) * Inv
        local RightX  = HalfViewportX + (Right + HalfWidth) * Inv
        local ScreenY = HalfViewportY - (Up - BottomOffset) * Inv
        if LeftX   < ScreenMinX then ScreenMinX = LeftX end
        if RightX  > ScreenMaxX then ScreenMaxX = RightX end
        if ScreenY < ScreenMinY then ScreenMinY = ScreenY end
        if ScreenY > ScreenMaxY then ScreenMaxY = ScreenY end
    end
    if Depth > 0 then
        Inv = FocalLength / Depth
        local LeftX   = HalfViewportX + (Right - HalfWidth) * Inv
        local RightX  = HalfViewportX + (Right + HalfWidth) * Inv
        local MidY    = HalfViewportY - Up * Inv
        if LeftX   < ScreenMinX then ScreenMinX = LeftX end
        if RightX  > ScreenMaxX then ScreenMaxX = RightX end
        if MidY    < ScreenMinY then ScreenMinY = MidY end
        if MidY    > ScreenMaxY then ScreenMaxY = MidY end
    end
end

Esp.Connections[#Esp.Connections+1] = RunService.RenderStepped:Connect(function(DeltaTime)
    DeltaTimeAccumulator = DeltaTimeAccumulator + DeltaTime
    if DeltaTimeAccumulator < FrameTime then return end
    DeltaTimeAccumulator = DeltaTimeAccumulator - FrameTime

    local CameraCF  = CurrentCamera.CFrame
    local ViewportSize = CurrentCamera.ViewportSize
    local RightVector     = CameraCF.RightVector
    local UpVector        = CameraCF.UpVector
    local LookVector      = CameraCF.LookVector
    local CameraPosition  = CameraCF.Position

    CameraRightX=RightVector.X; CameraRightY=RightVector.Y; CameraRightZ=RightVector.Z
    CameraUpX=UpVector.X; CameraUpY=UpVector.Y; CameraUpZ=UpVector.Z
    CameraLookX=LookVector.X; CameraLookY=LookVector.Y; CameraLookZ=LookVector.Z
    CameraPosX=CameraPosition.X; CameraPosY=CameraPosition.Y; CameraPosZ=CameraPosition.Z
    HalfViewportX   = ViewportSize.X * 0.5
    HalfViewportY   = ViewportSize.Y * 0.5
    FocalLength = HalfViewportY / Tan(Rad(CurrentCamera.FieldOfView * 0.5))

    local LocalRoot  = Esp.LocalRoot
    local LocalX, LocalY, LocalZ = 0, 0, 0
    local HasLocal   = LocalRoot ~= nil
    if HasLocal then
        local LocalPos = LocalRoot.Position
        LocalX=LocalPos.X; LocalY=LocalPos.Y; LocalZ=LocalPos.Z
    end

    local EspOn       = LocalSettings.Enabled
    local BoxOn       = LocalSettings.Box.Enabled
    local FillOn      = LocalSettings.Box.Fill.Enabled
    local GlowOn      = LocalSettings.Box.Glow.Enabled
    local HighlightOn = LocalSettings.Highlight.Enabled
    local HealthBarOn     = LocalSettings.Bars.HealthBar.Enabled
    local HealthTextOn    = LocalSettings.Bars.HealthBar.Text.Enabled
    local ArmorBarOn      = LocalSettings.Bars.ArmorBar.Enabled
    local ArmorTypeFunction = LocalSettings.Bars.ArmorBar.Type
    local NameOn      = LocalSettings.Name.Enabled
    local WeaponOn    = LocalSettings.Weapon.Enabled
    local WeaponNone  = LocalSettings.Weapon.ShowNone
    local DistanceOn  = LocalSettings.Distance.Enabled
    local FlagsOn     = LocalSettings.Flags.Enabled

    local BoxGradient      = Gradient2(LocalSettings.Box.Color[1],        LocalSettings.Box.Color[2])
    local FillGradient     = Gradient2(LocalSettings.Box.Fill.Color[1],   LocalSettings.Box.Fill.Color[2])
    local HealthGradient   = Gradient3(LocalSettings.Bars.HealthBar.Color[1], LocalSettings.Bars.HealthBar.Color[2], LocalSettings.Bars.HealthBar.Color[3])
    local ArmorGradient    = Gradient3(LocalSettings.Bars.ArmorBar.Color[1],  LocalSettings.Bars.ArmorBar.Color[2],  LocalSettings.Bars.ArmorBar.Color[3])
    local GlowColorTop = LocalSettings.Box.Glow.Color[1]
    local GlowColorBottom = LocalSettings.Box.Glow.Color[2]

    local EntryList = Esp.List

    for Index = 1, #EntryList do
        local Entry = EntryList[Index]

        if not EspOn then Esp:HideEntry(Entry); continue end
        if Entry.IsDead or not Entry.RootPart or not Entry.Character then Esp:HideEntry(Entry); continue end

        local RootPos = Entry.RootPart.Position
        local RootX, RootY, RootZ = RootPos.X, RootPos.Y, RootPos.Z

        if HasLocal then
            local DeltaX, DeltaY, DeltaZ = RootX-LocalX, RootY-LocalY, RootZ-LocalZ
            if DeltaX*DeltaX + DeltaY*DeltaY + DeltaZ*DeltaZ > CullDistanceSq then
                Esp:HideEntry(Entry); continue
            end
        end

        local ForwardDot = (RootX-CameraPosX)*CameraLookX + (RootY-CameraPosY)*CameraLookY + (RootZ-CameraPosZ)*CameraLookZ
        if ForwardDot < 0 then Esp:HideEntry(Entry); continue end

        if Entry.Highlight then
            Entry.Highlight.Enabled        = HighlightOn
            Entry.Highlight.FillColor      = LocalSettings.Highlight.FillColor
            Entry.Highlight.OutlineColor   = LocalSettings.Highlight.OutlineColor
        elseif HighlightOn and Entry.Character then
            Entry.Highlight = MakeHighlight(Entry.Character)
        end

        Entry.BorderGrad.Color      = BoxGradient
        Entry.BoxFillGrad.Color     = FillGradient
        Entry.BarFillGrad.Color     = HealthGradient
        Entry.ArmorFillGrad.Color   = ArmorGradient
        Entry.GlowTop.ImageColor3   = GlowColorTop
        Entry.GlowBot.ImageColor3   = GlowColorBottom
        Entry.GlowTopGrad.Transparency = GlowFadeTop()
        Entry.GlowBotGrad.Transparency = GlowFadeBottom()

        ScreenMinX=Huge; ScreenMinY=Huge; ScreenMaxX=-Huge; ScreenMaxY=-Huge

        local DeltaX = RootX-CameraPosX; local DeltaY = RootY-CameraPosY; local DeltaZ = RootZ-CameraPosZ
        local DistanceSq = DeltaX*DeltaX + DeltaY*DeltaY + DeltaZ*DeltaZ

        if Entry.PartCount == 0 or DistanceSq > LodDistanceSq then
            local Depth = CameraLookX*DeltaX + CameraLookY*DeltaY + CameraLookZ*DeltaZ
            local Right = CameraRightX*DeltaX + CameraRightY*DeltaY + CameraRightZ*DeltaZ
            local Up    = CameraUpX*DeltaX + CameraUpY*DeltaY + CameraUpZ*DeltaZ
            local BoxHeight = Clamp(Sqrt(DistanceSq)*0.018, 1.2, 2.2)
            LodFallback(Depth, Right, Up, Entry.TopOffset, Entry.BottomOffset, BoxHeight)
        else
            local Parts = Entry.Parts; local HalfW = Entry.PartHalfWidth; local HalfH = Entry.PartHalfHeight; local HalfD = Entry.PartHalfDepth
            for PartIndex = 1, Entry.PartCount do
                local Part = Parts[PartIndex]
                if not Part or not Part.Parent then continue end
                local PosX,PosY,PosZ, M00,M01,M02,M10,M11,M12,M20,M21,M22 = Part.CFrame:GetComponents()
                ProjectOBB(PosX,PosY,PosZ, M00,M01,M02, M10,M11,M12, M20,M21,M22, HalfW[PartIndex], HalfH[PartIndex], HalfD[PartIndex])
            end
        end

        if ScreenMinX == Huge then Esp:HideEntry(Entry); continue end

        local BoxX = Floor(ScreenMinX)
        local BoxY = Floor(ScreenMinY)
        local BoxWidth = Max(Floor(ScreenMaxX - ScreenMinX), 0)
        local BoxHeight = Max(Floor(ScreenMaxY - ScreenMinY), 0)
        local BoxCenterX = BoxX + Floor(BoxWidth * 0.5)
        local BoxRight   = BoxX + BoxWidth
        local BoxBottom  = BoxY + BoxHeight
        Entry.IsVisible  = true

        local Dirty = BoxX~=Entry.PrevBoxX or BoxY~=Entry.PrevBoxY or BoxWidth~=Entry.PrevBoxW or BoxHeight~=Entry.PrevBoxH

        if Dirty then
            Entry.PrevBoxX=BoxX; Entry.PrevBoxY=BoxY; Entry.PrevBoxW=BoxWidth; Entry.PrevBoxH=BoxHeight
            ResetPositionCache(Entry)
            Entry.PrevBoxX=BoxX; Entry.PrevBoxY=BoxY; Entry.PrevBoxW=BoxWidth; Entry.PrevBoxH=BoxHeight

            if BoxOn then
                Entry.OuterStroke.Visible  = true
                Entry.OuterStroke.Position = UDim2New(0,BoxX-1,0,BoxY-1)
                Entry.OuterStroke.Size     = UDim2New(0,BoxWidth+2,0,BoxHeight+2)
                Entry.BorderStroke.Visible = true
                Entry.BorderStroke.Position = UDim2New(0,BoxX,0,BoxY)
                Entry.BorderStroke.Size     = UDim2New(0,BoxWidth,0,BoxHeight)
                Entry.InnerCover.Visible   = true
                Entry.InnerCover.Position  = UDim2New(0,BoxX+1,0,BoxY+1)
                Entry.InnerCover.Size      = UDim2New(0,BoxWidth-2,0,BoxHeight-2)
                Entry.InnerStroke.Visible  = true
                Entry.InnerStroke.Position = UDim2New(0,BoxX+1,0,BoxY+1)
                Entry.InnerStroke.Size     = UDim2New(0,BoxWidth-2,0,BoxHeight-2)
            else HideBox(Entry) end

            if BoxOn and FillOn then
                Entry.BoxFill.Visible   = true
                Entry.BoxFill.Position  = UDim2New(0,BoxX+1,0,BoxY+1)
                Entry.BoxFill.Size      = UDim2New(0,BoxWidth-2,0,BoxHeight-2)
            else HideFill(Entry) end

            if BoxOn and GlowOn then
                local GlowX,GlowY = BoxX-GlowPad, BoxY-GlowPad
                local GlowWidth,GlowHeight = BoxWidth+GlowPad2, BoxHeight+GlowPad2
                local GlowPos  = UDim2New(0,GlowX,0,GlowY)
                local GlowSize = UDim2New(0,GlowWidth,0,GlowHeight)
                Entry.GlowTop.Visible=true; Entry.GlowTop.Position=GlowPos; Entry.GlowTop.Size=GlowSize
                Entry.GlowBot.Visible=true; Entry.GlowBot.Position=GlowPos; Entry.GlowBot.Size=GlowSize
            else HideGlow(Entry) end

            if HealthBarOn then
                local BarX = BoxX - BarGapWidth
                local BarY = BoxY - BarPad
                local BarH = BoxHeight + BarPad2
                Entry.BarX=BarX; Entry.BarY=BarY; Entry.BarHeight=BarH
                Entry.BarLabelX=BarX-14; Entry.BarLabelY=BarY
                Entry.BarOutline.Visible    = true
                Entry.BarOutline.Position   = UDim2New(0,BarX-1,0,BarY-1)
                Entry.BarOutline.Size       = UDim2New(0,BarWidthOutline,0,BarH+2)
                Entry.BarBackground.Visible = true
                Entry.BarBackground.Position = UDim2New(0,BarX,0,BarY)
                Entry.BarBackground.Size     = UDim2New(0,BarWidth,0,BarH)
            else HideHealthBar(Entry) end

            if ArmorBarOn then
                local ArmorX = BoxX - ArmorPad
                local ArmorY = BoxBottom + ArmorGap
                local ArmorW = BoxWidth + ArmorPad*2
                Entry.ArmorBarX=ArmorX; Entry.ArmorBarY=ArmorY; Entry.ArmorBarWidth=ArmorW
                Entry.ArmorOutline.Visible    = true
                Entry.ArmorOutline.Position   = UDim2New(0,ArmorX-1,0,ArmorY-1)
                Entry.ArmorOutline.Size       = UDim2New(0,ArmorW+2,0,ArmorHeightOutline)
                Entry.ArmorBackground.Visible = true
                Entry.ArmorBackground.Position = UDim2New(0,ArmorX,0,ArmorY)
                Entry.ArmorBackground.Size     = UDim2New(0,ArmorW,0,ArmorHeight)
            else HideArmorBar(Entry) end

            if FlagsOn then
                Entry.FlagsLabelX = BoxRight + BarGapWidth
                Entry.FlagsLabelY = BoxY
            end
        else
            if not BoxOn                     then HideBox(Entry)       end
            if not BoxOn or not FillOn       then HideFill(Entry)      end
            if not BoxOn or not GlowOn       then HideGlow(Entry)      end
            if not HealthBarOn                   then HideHealthBar(Entry) end
            if not ArmorBarOn                  then HideArmorBar(Entry)  end
        end

        if HealthBarOn then
            local FillHeight = Max(Floor(Entry.BarHeight * Entry.Health), 1)
            if FillHeight ~= Entry.PrevFillHeight then
                Entry.PrevFillHeight = FillHeight
                Entry.BarFill.Visible   = true
                Entry.BarFill.Position  = UDim2New(0,Entry.BarX, 0,Entry.BarY+(Entry.BarHeight-FillHeight))
                Entry.BarFill.Size      = UDim2New(0,BarWidth,0,FillHeight)
            end
            if HealthTextOn then
                local HealthString = Entry.HealthString
                local LabelX, LabelY = Entry.BarLabelX, Entry.BarLabelY
                if HealthString~=Entry.PrevHealthString or LabelX~=Entry.PrevHealthLabelX or LabelY~=Entry.PrevHealthLabelY then
                    Entry.PrevHealthString=HealthString; Entry.PrevHealthLabelX=LabelX; Entry.PrevHealthLabelY=LabelY
                    Entry.LabelHealth.Visible   = true
                    Entry.LabelHealth.Text      = HealthString
                    Entry.LabelHealth.Position  = UDim2New(0,LabelX+1,0,LabelY+HealthOffset)
                end
            else
                Entry.LabelHealth.Visible = false
            end
        end

        if ArmorBarOn and ArmorTypeFunction then
            local Current, MaxValue = ArmorTypeFunction(Entry.Character)
            local Ratio   = (MaxValue and MaxValue>0) and Clamp(Current/MaxValue,0,1) or 1
            local ArmorFillWidth = Max(Floor(Entry.ArmorBarWidth*Ratio),1)
            if ArmorFillWidth ~= Entry.PrevArmorFillWidth then
                Entry.PrevArmorFillWidth = ArmorFillWidth
                Entry.ArmorFill.Visible  = true
                Entry.ArmorFill.Position = UDim2New(0,Entry.ArmorBarX,0,Entry.ArmorBarY)
                Entry.ArmorFill.Size     = UDim2New(0,ArmorFillWidth,0,ArmorHeight)
            end
        end

        if NameOn then
            local NameX, NameY = BoxCenterX, BoxY+NameOffset
            local NameString = Entry.PlayerName
            if NameString~=Entry.PrevNameString or NameX~=Entry.PrevNameLabelX or NameY~=Entry.PrevNameLabelY then
                Entry.PrevNameString=NameString; Entry.PrevNameLabelX=NameX; Entry.PrevNameLabelY=NameY
                Entry.LabelName.Visible  = true
                Entry.LabelName.Text     = FormatText(NameString)
                Entry.LabelName.Position = UDim2New(0,NameX,0,NameY)
            end
        else
            Entry.LabelName.Visible = false
        end

        if WeaponOn then
            local WeaponX = BoxCenterX
            local WeaponY = ArmorBarOn and (BoxBottom+ArmorGap+ArmorHeight+2+WeaponOffset) or (BoxBottom+WeaponOffset)
            local WeaponString = Entry.WeaponString
            if WeaponString~=Entry.PrevWeaponString or WeaponX~=Entry.PrevWeaponLabelX or WeaponY~=Entry.PrevWeaponLabelY then
                Entry.PrevWeaponString=WeaponString; Entry.PrevWeaponLabelX=WeaponX; Entry.PrevWeaponLabelY=WeaponY
                Entry.LabelWeapon.Visible  = WeaponString~="none" or WeaponNone
                Entry.LabelWeapon.Text     = FormatText(WeaponString)
                Entry.LabelWeapon.Position = UDim2New(0,WeaponX+1,0,WeaponY-6)
            end
        else
            Entry.LabelWeapon.Visible = false
        end

        if DistanceOn and HasLocal then
            local DeltaX,DeltaY,DeltaZ = RootX-LocalX, RootY-LocalY, RootZ-LocalZ
            local DistSq = DeltaX*DeltaX + DeltaY*DeltaY + DeltaZ*DeltaZ
            local DistX, DistY = BoxCenterX, BoxBottom+DistanceOffset
            local PreviousDist = Entry.PrevDistanceValue
            local CurrentDist
            if PreviousDist<0 or DistSq<(PreviousDist-0.5)*(PreviousDist-0.5) or DistSq>(PreviousDist+0.5)*(PreviousDist+0.5) then
                CurrentDist = Floor(Sqrt(DistSq))
            else
                CurrentDist = PreviousDist
            end
            if CurrentDist~=Entry.PrevDistanceValue or DistX~=Entry.PrevDistanceLabelX or DistY~=Entry.PrevDistanceLabelY then
                local DistanceString = CurrentDist~=Entry.PrevDistanceValue and (ToString(CurrentDist)..LocalSettings.Distance.Ending) or Entry.PrevDistanceString
                Entry.PrevDistanceValue=CurrentDist; Entry.PrevDistanceString=DistanceString
                Entry.PrevDistanceLabelX=DistX; Entry.PrevDistanceLabelY=DistY
                Entry.LabelDistance.Visible  = true
                Entry.LabelDistance.Text     = DistanceString
                Entry.LabelDistance.Position = UDim2New(0,DistX,0,DistY)
            end
        else
            Entry.LabelDistance.Visible = false
        end

        if FlagsOn then
            local FlagsString = Entry.FlagsString
            local FlagsX = Entry.FlagsLabelX
            local FlagsY = Entry.FlagsLabelY + FlagsOffset
            if FlagsString~=Entry.PrevFlagsString or FlagsX~=Entry.PrevFlagsLabelX or FlagsY~=Entry.PrevFlagsLabelY then
                Entry.PrevFlagsString=FlagsString; Entry.PrevFlagsLabelX=FlagsX; Entry.PrevFlagsLabelY=FlagsY
                Entry.LabelFlags.Visible  = FlagsString~=""
                Entry.LabelFlags.Text     = FormatText(FlagsString)
                Entry.LabelFlags.Position = UDim2New(0,FlagsX+2,0,FlagsY-4)
            end
        else
            Entry.LabelFlags.Visible = false
        end
    end
end)

for _, Player in ipairs(PlayersService:GetPlayers()) do
    task.spawn(function() Esp:Add(Player) end)
end
Esp.Connections[#Esp.Connections+1] = PlayersService.PlayerAdded:Connect(function(Player) Esp:Add(Player) end)
Esp.Connections[#Esp.Connections+1] = PlayersService.PlayerRemoving:Connect(function(Player)
    task.delay(0.1, function() Esp:Remove(Player) end)
end)

local BotFolder = workspace:FindFirstChild("Bots")
if BotFolder then
    local BotCache = {}

    local function AddBot(Model)
        if not Model:IsA("Model") or BotCache[Model] then return end
        local Entry = Esp:NewEntry({ Name = Model.Name })
        Entry.PlayerName = Model.Name
        BotCache[Model] = Entry
        Esp.List[#Esp.List+1] = Entry
        task.spawn(function() Esp:LinkCharacter(Entry, Model) end)
    end

    local function RemoveBot(Model)
        local Entry = BotCache[Model]
        if not Entry then return end
        BotCache[Model] = nil
        local List = Esp.List
        for Index = 1, #List do
            if List[Index] == Entry then List[Index] = List[#List]; List[#List] = nil; break end
        end
        Esp:DestroyEntry(Entry)
    end

    for _, Bot in ipairs(BotFolder:GetChildren()) do task.spawn(AddBot, Bot) end
    Esp.Connections[#Esp.Connections+1] = BotFolder.ChildAdded:Connect(AddBot)
    Esp.Connections[#Esp.Connections+1] = BotFolder.ChildRemoved:Connect(RemoveBot)
end

return Esp
