local Floor   = math.floor
local Max     = math.max
local Huge    = math.huge
local Clamp   = math.clamp
local Sqrt    = math.sqrt
local Tan     = math.tan
local Rad     = math.rad

local Vector2New  = Vector2.new
local UDim2New    = UDim2.new
local Color3New   = Color3.new
local Rgb         = Color3.fromRGB
local NewInstance = Instance.new
local ToString    = tostring

local CloneRef       = cloneref or function(x) return x end
local PlayersService = CloneRef(game:GetService("Players"))
local RunService     = CloneRef(game:GetService("RunService"))
local HttpService    = CloneRef(game:GetService("HttpService"))
local CurrentCamera  = workspace.CurrentCamera
local LocalPlayer    = PlayersService.LocalPlayer

local White              = Color3New(1, 1, 1)
local Black              = Color3New(0, 0, 0)
local BarBackgroundColor = Rgb(5, 10, 25)

local GlowPad   = 21
local GlowPad2  = GlowPad * 2
local GlowSlice = Rect.new(Vector2New(21, 21), Vector2New(79, 79))

local ScreenMinX, ScreenMinY, ScreenMaxX, ScreenMaxY = 0, 0, 0, 0
local CameraRightX, CameraRightY, CameraRightZ       = 0, 0, 0
local CameraUpX, CameraUpY, CameraUpZ                = 0, 0, 0
local CameraLookX, CameraLookY, CameraLookZ          = 0, 0, 0
local CameraPosX, CameraPosY, CameraPosZ             = 0, 0, 0
local FocalLength, HalfViewportX, HalfViewportY      = 1, 0, 0

local _Fallback       = Font.new("rbxasset://fonts/families/RobotoMono.json")
local FontSmall       = _Fallback
local FontTahoma      = _Fallback
local FontProggyClean = _Fallback
local FontProggyTiny  = _Fallback

pcall(function()
    local function LoadFont(Name, Weight, Style, AssetFile, Data)
        if isfile(AssetFile) then delfile(AssetFile) end
        writefile(AssetFile, Data)
        task.wait(0.1)
        local FontFile = Name .. ".font"
        if isfile(FontFile) then delfile(FontFile) end
        writefile(FontFile, HttpService:JSONEncode({
            name  = Name,
            faces = {{ name = "Regular", weight = Weight, style = Style, assetId = getcustomasset(AssetFile) }},
        }))
        task.wait(0.1)
        return getcustomasset(FontFile)
    end

    pcall(function()
        FontSmall = Font.new(LoadFont(
            "SmallestPixel.ttf", 100, "normal", "SmallestPixelAsset.ttf",
            crypt.base64.decode(game:HttpGet("https://gist.githubusercontent.com/index987745/cbe1120f297fc9e7a31568f290a36c30/raw/6dbbb378feffbebb2af51cc8b0125b837f590f7a/SmallestPixel.tff"))
        ))
    end)

    pcall(function()
        FontTahoma = Font.new(LoadFont(
            "Tahoma.ttf", 400, "normal", "TahomaAsset.ttf",
            game:HttpGet("https://github.com/f1nobe7650/Nebula/raw/refs/heads/main/fs-tahoma-8px.ttf")
        ))
    end)

    pcall(function()
        FontProggyClean = Font.new(LoadFont(
            "ProggyClean.ttf", 400, "normal", "ProggyCleanAsset.ttf",
            game:HttpGet("https://raw.githubusercontent.com/renrensrj-blip/fonts/main/proggyclean%20(1).ttf")
        ))
    end)

    pcall(function()
        FontProggyTiny = Font.new(LoadFont(
            "ProggyTiny.ttf", 400, "normal", "ProggyTinyAsset.ttf",
            game:HttpGet("https://raw.githubusercontent.com/renrensrj-blip/fonts/main/ProggyTiny%20(1).ttf")
        ))
    end)
end)

local Esp = { Cache = {}, List = {}, Connections = {}, LocalRoot = nil }

Esp.Settings = {
    Enabled = true, LocalPlayer = true, Font = "Tahoma",
    FontSize = 12, FontType = "lowercase", MaxDistance = 9e9, RefreshRate = 60,

    Highlight = {
        Enabled = false,
        FillColor = Rgb(216, 126, 157),
        OutlineColor = Rgb(0, 0, 0),
        FillTransparency = 0.5,
        OutlineTransparency = 0,
        DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
    },

    Box = {
        Enabled = true, Rotation = 90,
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
                Enabled = false, FollowBar = false, Ending = "HP",
                Position = "Left", Color = Rgb(255, 255, 255), Transparency = 0,
            },
        },
        ArmorBar = {
            Enabled = true, Position = "Bottom",
            Color = { Rgb(52, 131, 235), Rgb(52, 131, 235), Rgb(52, 131, 235) },
            Type = function() return 100, 100 end,
        },
    },

    Name     = { Enabled = true, UseDisplay = true, Position = "Top",    Color = Rgb(255,255,255), Transparency = 0 },
    Distance = { Enabled = true, Ending = "st",     Position = "Bottom", Color = Rgb(255,255,255), Transparency = 0 },
    Weapon   = { Enabled = true, ShowNone = true,   Position = "Bottom", Color = Rgb(255,255,255), Transparency = 0 },
    Flags    = {
        Enabled = true, Position = "Right", Color = Rgb(255,255,255), Transparency = 0,
        Type = function(Speed, Jumping)
            if Jumping   then return { "jumping" }  end
            if Speed > 0 then return { "moving" }   end
            return { "standing" }
        end,
    },
}

local LocalSettings = Esp.Settings

-- ── gradient / sequence cache ─────────────────────────────────────────────────
local CachedBoxGradient    = nil
local CachedFillGradient   = nil
local CachedHealthGradient = nil
local CachedArmorGradient  = nil
local CachedGlowFadeTop    = nil
local CachedGlowFadeBot    = nil

local PrevBoxColor1, PrevBoxColor2                         = nil, nil
local PrevFillColor1, PrevFillColor2                       = nil, nil
local PrevHealthColor1, PrevHealthColor2, PrevHealthColor3 = nil, nil, nil
local PrevArmorColor1, PrevArmorColor2, PrevArmorColor3    = nil, nil, nil
local PrevGlowTransp1, PrevGlowTransp2                     = nil, nil
local PrevFont                                             = nil

local function RebuildGradientCache()
    local S = LocalSettings

    local BC1, BC2 = S.Box.Color[1], S.Box.Color[2]
    if BC1 ~= PrevBoxColor1 or BC2 ~= PrevBoxColor2 then
        PrevBoxColor1, PrevBoxColor2 = BC1, BC2
        CachedBoxGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, BC1),
            ColorSequenceKeypoint.new(1, BC2),
        })
    end

    local FC1, FC2 = S.Box.Fill.Color[1], S.Box.Fill.Color[2]
    if FC1 ~= PrevFillColor1 or FC2 ~= PrevFillColor2 then
        PrevFillColor1, PrevFillColor2 = FC1, FC2
        CachedFillGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, FC1),
            ColorSequenceKeypoint.new(1, FC2),
        })
    end

    local HC1, HC2, HC3 = S.Bars.HealthBar.Color[1], S.Bars.HealthBar.Color[2], S.Bars.HealthBar.Color[3]
    if HC1 ~= PrevHealthColor1 or HC2 ~= PrevHealthColor2 or HC3 ~= PrevHealthColor3 then
        PrevHealthColor1, PrevHealthColor2, PrevHealthColor3 = HC1, HC2, HC3
        CachedHealthGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   HC1),
            ColorSequenceKeypoint.new(0.5, HC2),
            ColorSequenceKeypoint.new(1,   HC3),
        })
    end

    local AC1, AC2, AC3 = S.Bars.ArmorBar.Color[1], S.Bars.ArmorBar.Color[2], S.Bars.ArmorBar.Color[3]
    if AC1 ~= PrevArmorColor1 or AC2 ~= PrevArmorColor2 or AC3 ~= PrevArmorColor3 then
        PrevArmorColor1, PrevArmorColor2, PrevArmorColor3 = AC1, AC2, AC3
        CachedArmorGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   AC1),
            ColorSequenceKeypoint.new(0.5, AC2),
            ColorSequenceKeypoint.new(1,   AC3),
        })
    end

    local GT1, GT2 = S.Box.Glow.Transparency[1], S.Box.Glow.Transparency[2]
    if GT1 ~= PrevGlowTransp1 or GT2 ~= PrevGlowTransp2 then
        PrevGlowTransp1, PrevGlowTransp2 = GT1, GT2
        CachedGlowFadeTop = NumberSequence.new({
            NumberSequenceKeypoint.new(0,   0),
            NumberSequenceKeypoint.new(0.5, GT1),
            NumberSequenceKeypoint.new(1,   1),
        })
        CachedGlowFadeBot = NumberSequence.new({
            NumberSequenceKeypoint.new(0,   1),
            NumberSequenceKeypoint.new(0.5, GT2),
            NumberSequenceKeypoint.new(1,   0),
        })
    end
end

local function GetFont()
    local f = LocalSettings.Font
    if f == "Tahoma"      then return FontTahoma      end
    if f == "Small"       then return FontSmall        end
    if f == "ProggyClean" then return FontProggyClean  end
    if f == "ProggyTiny"  then return FontProggyTiny   end
    return FontTahoma
end

local function GetFontSize() return LocalSettings.FontSize or 12 end

local function FormatText(Text)
    local ft = LocalSettings.FontType
    if ft == "uppercase" then return string.upper(Text) end
    if ft == "lowercase" then return string.lower(Text) end
    return Text
end

local BarWidth          = 1
local BarGap            = 4
local BarPad            = 1
local BarWidthOutline   = BarWidth + 2
local BarPad2           = BarPad * 2
local BarGapWidth       = BarGap + BarWidth
local ArmorHeight       = 1
local ArmorHeightOutline = 3
local ArmorGap          = 4
local ArmorPad          = 1

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
    for Key, Value in next, Properties do Object[Key] = Value end
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
        Color    = CachedBoxGradient or ColorSequence.new(White),
        Rotation = LocalSettings.Box.Rotation,
        Parent   = Stroke,
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
        Color = CachedFillGradient or ColorSequence.new(White),
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
    local H = NewInstance("Highlight")
    H.FillColor           = LocalSettings.Highlight.FillColor
    H.OutlineColor        = LocalSettings.Highlight.OutlineColor
    H.FillTransparency    = LocalSettings.Highlight.FillTransparency
    H.OutlineTransparency = LocalSettings.Highlight.OutlineTransparency
    H.DepthMode           = LocalSettings.Highlight.DepthMode
    H.Adornee             = Model
    H.Parent              = Gui
    H.Enabled             = true
    return H
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
    local DX  = PosX-CameraPosX; local DY = PosY-CameraPosY; local DZ = PosZ-CameraPosZ
    local DotD = CameraLookX*DX  + CameraLookY*DY  + CameraLookZ*DZ
    local DotR = CameraRightX*DX + CameraRightY*DY + CameraRightZ*DZ
    local DotU = CameraUpX*DX    + CameraUpY*DY    + CameraUpZ*DZ
    local DA = CameraLookX*AAX  + CameraLookY*AAY  + CameraLookZ*AAZ
    local RA = CameraRightX*AAX + CameraRightY*AAY + CameraRightZ*AAZ
    local UA = CameraUpX*AAX    + CameraUpY*AAY    + CameraUpZ*AAZ
    local DB = CameraLookX*ABX  + CameraLookY*ABY  + CameraLookZ*ABZ
    local RB = CameraRightX*ABX + CameraRightY*ABY + CameraRightZ*ABZ
    local UB = CameraUpX*ABX    + CameraUpY*ABY    + CameraUpZ*ABZ
    local DC = CameraLookX*ACX  + CameraLookY*ACY  + CameraLookZ*ACZ
    local RC = CameraRightX*ACX + CameraRightY*ACY + CameraRightZ*ACZ
    local UC = CameraUpX*ACX    + CameraUpY*ACY    + CameraUpZ*ACZ
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

local function HideFill(Entry)      Entry.BoxFill.Visible       = false end
local function HideGlow(Entry)      Entry.GlowTop.Visible = false; Entry.GlowBot.Visible = false end

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
    Entry.PrevFillHeight=-1;      Entry.PrevArmorFillWidth=-1
    Entry.PrevHealthLabelX=-1;    Entry.PrevHealthLabelY=-1
    Entry.PrevNameLabelX=-1;      Entry.PrevNameLabelY=-1
    Entry.PrevWeaponLabelX=-1;    Entry.PrevWeaponLabelY=-1
    Entry.PrevDistanceLabelX=-1;  Entry.PrevDistanceLabelY=-1
    Entry.PrevDistanceValue=-1
    Entry.PrevFlagsLabelX=-1;     Entry.PrevFlagsLabelY=-1
end

local function ResetAllCache(Entry)
    Entry.PrevBoxX=-1; Entry.PrevBoxY=-1; Entry.PrevBoxW=-1; Entry.PrevBoxH=-1
    ResetPositionCache(Entry)
    Entry.PrevHealthString="";    Entry.PrevNameString=""
    Entry.PrevWeaponString="__unset__"
    Entry.PrevDistanceString="";  Entry.PrevFlagsString=""
    Entry.PrevFormattedName="";   Entry.PrevFormattedWeapon=""
    Entry.PrevFormattedFlags=""
end

function Esp:HideEntry(Entry)
    if not Entry.IsVisible then return end
    HideBox(Entry); HideFill(Entry); HideGlow(Entry)
    HideHealthBar(Entry); HideArmorBar(Entry)
    HideLabels(Entry); HideHighlight(Entry)
    Entry.IsVisible = false
    ResetAllCache(Entry)
end

function Esp:NewEntry(Player)
    local Container = NewInstance("Frame")
    Container.Name                   = ToString(Player) .. "_esp"
    Container.BackgroundTransparency = 1
    Container.BorderSizePixel        = 0
    Container.Size                   = UDim2New(1,0,1,0)
    Container.ZIndex                 = 1
    Container.Parent                 = Gui

    local FontSize = GetFontSize()

    local BoxFillFrame, BoxFillGrad       = MakeFillFrame(Container, 8)
    local GlowTopFrame, GlowTopGrad       = MakeGlowImage(Container, CachedGlowFadeTop or NumberSequence.new(0), 2)
    local GlowBotFrame, GlowBotGrad       = MakeGlowImage(Container, CachedGlowFadeBot or NumberSequence.new(0), 2)
    local BorderStrokeFrame, BorderGrad   = MakeGradientStrokeFrame(Container, 5)
    local BarFillFrame, BarFillGrad       = MakeBarFill(Container, CachedHealthGradient or ColorSequence.new(White), 270)
    local ArmorFillFrame, ArmorFillGrad   = MakeBarFill(Container, CachedArmorGradient  or ColorSequence.new(White), 0)

    local Entry = {
        Player = Player, PlayerName = Player.Name, Container = Container,

        OuterStroke  = MakeStrokeFrame(Container, Black, 4),
        BorderStroke = BorderStrokeFrame,
        BorderGrad   = BorderGrad,
        InnerCover   = MakeInstance("Frame", {
            BackgroundColor3 = Black, BackgroundTransparency = 1,
            BorderSizePixel = 0, ZIndex = 6, Visible = false,
            Size = UDim2New(0,0,0,0), Parent = Container,
        }),
        InnerStroke  = MakeStrokeFrame(Container, Black, 7),
        BoxFill      = BoxFillFrame,
        BoxFillGrad  = BoxFillGrad,

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
        GlowBot     = GlowBotFrame,
        GlowBotGrad = GlowBotGrad,

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
        PrevFormattedName="", PrevFormattedWeapon="", PrevFormattedFlags="",
        PlayerConnections={}, CharacterConnections={},
    }

    ResetAllCache(Entry)
    return Entry
end

function Esp:DestroyEntry(Entry)
    self:HideEntry(Entry)
    for i = 1, #Entry.PlayerConnections    do pcall(Entry.PlayerConnections[i].Disconnect,    Entry.PlayerConnections[i])    end
    for i = 1, #Entry.CharacterConnections do pcall(Entry.CharacterConnections[i].Disconnect, Entry.CharacterConnections[i]) end
    if Entry.Highlight then pcall(Entry.Highlight.Destroy, Entry.Highlight) end
    pcall(Entry.Container.Destroy, Entry.Container)
end

function Esp:BuildParts(Entry)
    local Character = Entry.Character
    if not Character then return end

    local PartNames  = Entry.IsR6 and R6Parts  or R15Parts
    local PaddingMap = Entry.IsR6 and R6Padding or R15Padding
    local RootY      = Entry.RootPart.Position.Y
    local LowestY, HighestY = Huge, -Huge
    local Parts, HalfWidths, HalfHeights, HalfDepths = {}, {}, {}, {}
    local Count = 0

    for i = 1, #PartNames do
        local Part = Character:FindFirstChild(PartNames[i])
        if not Part or not Part:IsA("BasePart") then continue end
        local Pad   = PaddingMap[PartNames[i]] or 0.04
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

    Entry.TopOffset    = HighestY == -Huge and 3.0 or HighestY + 0.02
    Entry.BottomOffset = LowestY  ==  Huge and 3.0 or -LowestY + 0.02
    Entry.Parts        = Parts
    Entry.PartHalfWidth = HalfWidths; Entry.PartHalfHeight = HalfHeights; Entry.PartHalfDepth = HalfDepths
    Entry.PartCount    = Count
end

function Esp:ClearCharacter(Entry)
    for i = 1, #Entry.CharacterConnections do pcall(Entry.CharacterConnections[i].Disconnect, Entry.CharacterConnections[i]) end
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

    local Root     = Character:WaitForChild("HumanoidRootPart", 10)
    local Humanoid = Character:WaitForChild("Humanoid", 10)
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
    Entry.CachedMoveSpeed = Humanoid.MoveDirection.Magnitude
    Entry.CachedJumping   = Humanoid.Jump
    Entry.WeaponString    = GetWeapon(Character)
    RebuildFlags(Entry)

    if LocalSettings.Highlight.Enabled then
        if Entry.Highlight then pcall(Entry.Highlight.Destroy, Entry.Highlight) end
        Entry.Highlight = MakeHighlight(Character)
    end

    local Connections = Entry.CharacterConnections

    Connections[#Connections+1] = Humanoid.HealthChanged:Connect(function(Health)
        Entry.Health       = Clamp(Health / Entry.MaxHealth, 0, 1)
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
    local IsLocal = Player == LocalPlayer
    if IsLocal and not LocalSettings.LocalPlayer then return end
    if self.Cache[Player] then self:DestroyEntry(self.Cache[Player]) end

    local Entry = self:NewEntry(Player)
    self.Cache[Player]      = Entry
    self.List[#self.List+1] = Entry

    if IsLocal then
        if Player.Character then
            task.spawn(function() self:LinkCharacter(Entry, Player.Character) end)
        end
        self.Connections[#self.Connections+1] = Player.CharacterAdded:Connect(function(Character)
            task.spawn(function() self:LinkCharacter(Entry, Character) end)
        end)
        self.Connections[#self.Connections+1] = Player.CharacterRemoving:Connect(function()
            Entry.Character = nil; Entry.RootPart = nil
            if Entry.Highlight then Entry.Highlight.Enabled = false end
            self:HideEntry(Entry)
        end)
        return
    end

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
    for i = 1, #List do
        if List[i] == Entry then List[i] = List[#List]; List[#List] = nil; break end
    end
    self:DestroyEntry(Entry)
end

local function OnLocalCharacterAdded(Character)
    Esp.LocalRoot = Character and Character:WaitForChild("HumanoidRootPart", 5) or nil
end

if LocalPlayer.Character then task.spawn(OnLocalCharacterAdded, LocalPlayer.Character) end
Esp.Connections[#Esp.Connections+1] = LocalPlayer.CharacterAdded:Connect(OnLocalCharacterAdded)
Esp.Connections[#Esp.Connections+1] = LocalPlayer.CharacterRemoving:Connect(function() Esp.LocalRoot = nil end)

local NameOffset     = -18
local WeaponOffset   = 19
local DistanceOffset = 8
local HealthOffset   = -3
local FlagsOffset    = -2
local CullDistanceSq = 9e9
local LodDistanceSq  = 200 * 200
local DeltaTimeAccumulator = 0
local FrameTime      = 1 / 60

local function LodFallback(Depth, Right, Up, TopOffset, BottomOffset, HalfWidth)
    local Inv
    local TopDepth = Depth + CameraLookY * TopOffset
    if TopDepth > 0 then
        Inv = FocalLength / TopDepth
        local LeftX   = HalfViewportX + (Right - HalfWidth) * Inv
        local RightX  = HalfViewportX + (Right + HalfWidth) * Inv
        local ScreenY = HalfViewportY - (Up + TopOffset) * Inv
        if LeftX  < ScreenMinX then ScreenMinX = LeftX  end
        if RightX > ScreenMaxX then ScreenMaxX = RightX end
        if ScreenY < ScreenMinY then ScreenMinY = ScreenY end
        if ScreenY > ScreenMaxY then ScreenMaxY = ScreenY end
    end
    local BottomDepth = Depth - CameraLookY * BottomOffset
    if BottomDepth > 0 then
        Inv = FocalLength / BottomDepth
        local LeftX   = HalfViewportX + (Right - HalfWidth) * Inv
        local RightX  = HalfViewportX + (Right + HalfWidth) * Inv
        local ScreenY = HalfViewportY - (Up - BottomOffset) * Inv
        if LeftX  < ScreenMinX then ScreenMinX = LeftX  end
        if RightX > ScreenMaxX then ScreenMaxX = RightX end
        if ScreenY < ScreenMinY then ScreenMinY = ScreenY end
        if ScreenY > ScreenMaxY then ScreenMaxY = ScreenY end
    end
    if Depth > 0 then
        Inv = FocalLength / Depth
        local LeftX   = HalfViewportX + (Right - HalfWidth) * Inv
        local RightX  = HalfViewportX + (Right + HalfWidth) * Inv
        local MidY    = HalfViewportY - Up * Inv
        if LeftX  < ScreenMinX then ScreenMinX = LeftX  end
        if RightX > ScreenMaxX then ScreenMaxX = RightX end
        if MidY   < ScreenMinY then ScreenMinY = MidY   end
        if MidY   > ScreenMaxY then ScreenMaxY = MidY   end
    end
end

Esp.Connections[#Esp.Connections+1] = RunService.RenderStepped:Connect(function(DeltaTime)
    DeltaTimeAccumulator = DeltaTimeAccumulator + DeltaTime
    if DeltaTimeAccumulator < FrameTime then return end
    DeltaTimeAccumulator = DeltaTimeAccumulator - FrameTime

    RebuildGradientCache()

    local CameraCF       = CurrentCamera.CFrame
    local ViewportSize   = CurrentCamera.ViewportSize
    local RightVector    = CameraCF.RightVector
    local UpVector       = CameraCF.UpVector
    local LookVector     = CameraCF.LookVector
    local CameraPosition = CameraCF.Position

    CameraRightX=RightVector.X; CameraRightY=RightVector.Y; CameraRightZ=RightVector.Z
    CameraUpX=UpVector.X;       CameraUpY=UpVector.Y;       CameraUpZ=UpVector.Z
    CameraLookX=LookVector.X;   CameraLookY=LookVector.Y;   CameraLookZ=LookVector.Z
    CameraPosX=CameraPosition.X; CameraPosY=CameraPosition.Y; CameraPosZ=CameraPosition.Z
    HalfViewportX = ViewportSize.X * 0.5
    HalfViewportY = ViewportSize.Y * 0.5
    FocalLength   = HalfViewportY / Tan(Rad(CurrentCamera.FieldOfView * 0.5))

    local LocalRoot = Esp.LocalRoot
    local LocalX, LocalY, LocalZ = 0, 0, 0
    local HasLocal = LocalRoot ~= nil
    if HasLocal then
        local LP = LocalRoot.Position
        LocalX=LP.X; LocalY=LP.Y; LocalZ=LP.Z
    end

    local EspOn         = LocalSettings.Enabled
    local BoxOn         = LocalSettings.Box.Enabled
    local FillOn        = LocalSettings.Box.Fill.Enabled
    local GlowOn        = LocalSettings.Box.Glow.Enabled
    local HighlightOn   = LocalSettings.Highlight.Enabled
    local HealthBarOn   = LocalSettings.Bars.HealthBar.Enabled
    local HealthTextOn  = LocalSettings.Bars.HealthBar.Text.Enabled
    local ArmorBarOn    = LocalSettings.Bars.ArmorBar.Enabled
    local ArmorTypeFn   = LocalSettings.Bars.ArmorBar.Type
    local NameOn        = LocalSettings.Name.Enabled
    local WeaponOn      = LocalSettings.Weapon.Enabled
    local WeaponNone    = LocalSettings.Weapon.ShowNone
    local DistanceOn    = LocalSettings.Distance.Enabled
    local FlagsOn       = LocalSettings.Flags.Enabled
    local LocalPlayerOn = LocalSettings.LocalPlayer

    local GlowColorTop    = LocalSettings.Box.Glow.Color[1]
    local GlowColorBottom = LocalSettings.Box.Glow.Color[2]

    local CurrentFont = GetFont()
    local FontChanged = CurrentFont ~= PrevFont
    if FontChanged then PrevFont = CurrentFont end

    local EntryList = Esp.List

    for i = 1, #EntryList do
        local Entry = EntryList[i]

        if not EspOn then Esp:HideEntry(Entry); continue end

        local IsLocalEntry = Entry.Player == LocalPlayer
        if IsLocalEntry and not LocalPlayerOn then Esp:HideEntry(Entry); continue end

        if Entry.IsDead or not Entry.RootPart or not Entry.Character then Esp:HideEntry(Entry); continue end

        local RootPos = Entry.RootPart.Position
        local RootX, RootY, RootZ = RootPos.X, RootPos.Y, RootPos.Z

        if HasLocal and not IsLocalEntry then
            local DX, DY, DZ = RootX-LocalX, RootY-LocalY, RootZ-LocalZ
            if DX*DX + DY*DY + DZ*DZ > CullDistanceSq then Esp:HideEntry(Entry); continue end
        end

        local FwdDot = (RootX-CameraPosX)*CameraLookX + (RootY-CameraPosY)*CameraLookY + (RootZ-CameraPosZ)*CameraLookZ
        if FwdDot < 0 then Esp:HideEntry(Entry); continue end

        if Entry.Highlight then
            Entry.Highlight.Enabled      = HighlightOn
            Entry.Highlight.FillColor    = LocalSettings.Highlight.FillColor
            Entry.Highlight.OutlineColor = LocalSettings.Highlight.OutlineColor
        elseif HighlightOn and Entry.Character then
            Entry.Highlight = MakeHighlight(Entry.Character)
        end

        Entry.BorderGrad.Color         = CachedBoxGradient
        Entry.BoxFillGrad.Color        = CachedFillGradient
        Entry.BarFillGrad.Color        = CachedHealthGradient
        Entry.ArmorFillGrad.Color      = CachedArmorGradient
        Entry.GlowTop.ImageColor3      = GlowColorTop
        Entry.GlowBot.ImageColor3      = GlowColorBottom
        Entry.GlowTopGrad.Transparency = CachedGlowFadeTop
        Entry.GlowBotGrad.Transparency = CachedGlowFadeBot

        if FontChanged then
            Entry.LabelName.FontFace     = CurrentFont
            Entry.LabelWeapon.FontFace   = CurrentFont
            Entry.LabelDistance.FontFace = CurrentFont
            Entry.LabelFlags.FontFace    = CurrentFont
            Entry.LabelHealth.FontFace   = CurrentFont
        end

        ScreenMinX=Huge; ScreenMinY=Huge; ScreenMaxX=-Huge; ScreenMaxY=-Huge

        local DX = RootX-CameraPosX; local DY = RootY-CameraPosY; local DZ = RootZ-CameraPosZ
        local DistanceSq = DX*DX + DY*DY + DZ*DZ

        if Entry.PartCount == 0 or DistanceSq > LodDistanceSq then
            local Depth = CameraLookX*DX  + CameraLookY*DY  + CameraLookZ*DZ
            local Right = CameraRightX*DX + CameraRightY*DY + CameraRightZ*DZ
            local Up    = CameraUpX*DX    + CameraUpY*DY    + CameraUpZ*DZ
            local BoxH  = Clamp(Sqrt(DistanceSq)*0.018, 1.2, 2.2)
            LodFallback(Depth, Right, Up, Entry.TopOffset, Entry.BottomOffset, BoxH)
        else
            local Parts = Entry.Parts
            local HalfW = Entry.PartHalfWidth
            local HalfH = Entry.PartHalfHeight
            local HalfD = Entry.PartHalfDepth
            for p = 1, Entry.PartCount do
                local Part = Parts[p]
                if not Part or not Part.Parent then continue end
                local PX,PY,PZ,M00,M01,M02,M10,M11,M12,M20,M21,M22 = Part.CFrame:GetComponents()
                ProjectOBB(PX,PY,PZ, M00,M01,M02, M10,M11,M12, M20,M21,M22, HalfW[p], HalfH[p], HalfD[p])
            end
        end

        if ScreenMinX == Huge then Esp:HideEntry(Entry); continue end

        local BoxX      = Floor(ScreenMinX)
        local BoxY      = Floor(ScreenMinY)
        local BoxWidth  = Max(Floor(ScreenMaxX - ScreenMinX), 0)
        local BoxHeight = Max(Floor(ScreenMaxY - ScreenMinY), 0)
        local BoxCenterX = BoxX + Floor(BoxWidth * 0.5)
        local BoxRight   = BoxX + BoxWidth
        local BoxBottom  = BoxY + BoxHeight
        Entry.IsVisible  = true

        local Dirty = BoxX~=Entry.PrevBoxX or BoxY~=Entry.PrevBoxY or BoxWidth~=Entry.PrevBoxW or BoxHeight~=Entry.PrevBoxH

        if Dirty then
            Entry.PrevBoxX=BoxX; Entry.PrevBoxY=BoxY; Entry.PrevBoxW=BoxWidth; Entry.PrevBoxH=BoxHeight
            ResetPositionCache(Entry)

            if BoxOn then
                Entry.OuterStroke.Visible   = true
                Entry.OuterStroke.Position  = UDim2New(0,BoxX-1,0,BoxY-1)
                Entry.OuterStroke.Size      = UDim2New(0,BoxWidth+2,0,BoxHeight+2)
                Entry.BorderStroke.Visible  = true
                Entry.BorderStroke.Position = UDim2New(0,BoxX,0,BoxY)
                Entry.BorderStroke.Size     = UDim2New(0,BoxWidth,0,BoxHeight)
                Entry.InnerCover.Visible    = true
                Entry.InnerCover.Position   = UDim2New(0,BoxX+1,0,BoxY+1)
                Entry.InnerCover.Size       = UDim2New(0,BoxWidth-2,0,BoxHeight-2)
                Entry.InnerStroke.Visible   = true
                Entry.InnerStroke.Position  = UDim2New(0,BoxX+1,0,BoxY+1)
                Entry.InnerStroke.Size      = UDim2New(0,BoxWidth-2,0,BoxHeight-2)
            else HideBox(Entry) end

            if BoxOn and FillOn then
                Entry.BoxFill.Visible  = true
                Entry.BoxFill.Position = UDim2New(0,BoxX+1,0,BoxY+1)
                Entry.BoxFill.Size     = UDim2New(0,BoxWidth-2,0,BoxHeight-2)
            else HideFill(Entry) end

            if BoxOn and GlowOn then
                local GX,GY = BoxX-GlowPad, BoxY-GlowPad
                local GW,GH = BoxWidth+GlowPad2, BoxHeight+GlowPad2
                local GP = UDim2New(0,GX,0,GY)
                local GS = UDim2New(0,GW,0,GH)
                Entry.GlowTop.Visible=true; Entry.GlowTop.Position=GP; Entry.GlowTop.Size=GS
                Entry.GlowBot.Visible=true; Entry.GlowBot.Position=GP; Entry.GlowBot.Size=GS
            else HideGlow(Entry) end

            if HealthBarOn then
                local BX = BoxX - BarGapWidth
                local BY = BoxY - BarPad
                local BH = BoxHeight + BarPad2
                Entry.BarX=BX; Entry.BarY=BY; Entry.BarHeight=BH
                Entry.BarLabelX=BX-14; Entry.BarLabelY=BY
                Entry.BarOutline.Visible     = true
                Entry.BarOutline.Position    = UDim2New(0,BX-1,0,BY-1)
                Entry.BarOutline.Size        = UDim2New(0,BarWidthOutline,0,BH+2)
                Entry.BarBackground.Visible  = true
                Entry.BarBackground.Position = UDim2New(0,BX,0,BY)
                Entry.BarBackground.Size     = UDim2New(0,BarWidth,0,BH)
            else HideHealthBar(Entry) end

            if ArmorBarOn then
                local AX = BoxX - ArmorPad
                local AY = BoxBottom + ArmorGap
                local AW = BoxWidth + ArmorPad*2
                Entry.ArmorBarX=AX; Entry.ArmorBarY=AY; Entry.ArmorBarWidth=AW
                Entry.ArmorOutline.Visible     = true
                Entry.ArmorOutline.Position    = UDim2New(0,AX-1,0,AY-1)
                Entry.ArmorOutline.Size        = UDim2New(0,AW+2,0,ArmorHeightOutline)
                Entry.ArmorBackground.Visible  = true
                Entry.ArmorBackground.Position = UDim2New(0,AX,0,AY)
                Entry.ArmorBackground.Size     = UDim2New(0,AW,0,ArmorHeight)
            else HideArmorBar(Entry) end

            if FlagsOn then
                Entry.FlagsLabelX = BoxRight + BarGapWidth
                Entry.FlagsLabelY = BoxY
            end
        else
            if not BoxOn                 then HideBox(Entry)       end
            if not BoxOn or not FillOn   then HideFill(Entry)      end
            if not BoxOn or not GlowOn   then HideGlow(Entry)      end
            if not HealthBarOn           then HideHealthBar(Entry) end
            if not ArmorBarOn            then HideArmorBar(Entry)  end
        end

        if HealthBarOn then
            local FillH = Max(Floor(Entry.BarHeight * Entry.Health), 1)
            if FillH ~= Entry.PrevFillHeight then
                Entry.PrevFillHeight    = FillH
                Entry.BarFill.Visible   = true
                Entry.BarFill.Position  = UDim2New(0,Entry.BarX, 0,Entry.BarY+(Entry.BarHeight-FillH))
                Entry.BarFill.Size      = UDim2New(0,BarWidth,0,FillH)
            end
            if HealthTextOn then
                local HS = Entry.HealthString
                local LX, LY = Entry.BarLabelX, Entry.BarLabelY
                if HS~=Entry.PrevHealthString or LX~=Entry.PrevHealthLabelX or LY~=Entry.PrevHealthLabelY then
                    Entry.PrevHealthString=HS; Entry.PrevHealthLabelX=LX; Entry.PrevHealthLabelY=LY
                    Entry.LabelHealth.Visible  = true
                    Entry.LabelHealth.Text     = HS
                    Entry.LabelHealth.Position = UDim2New(0,LX+1,0,LY+HealthOffset)
                end
            else
                Entry.LabelHealth.Visible = false
            end
        end

        if ArmorBarOn and ArmorTypeFn then
            local Current, MaxVal = ArmorTypeFn(Entry.Character)
            local Ratio = (MaxVal and MaxVal>0) and Clamp(Current/MaxVal,0,1) or 1
            local AFW   = Max(Floor(Entry.ArmorBarWidth*Ratio),1)
            if AFW ~= Entry.PrevArmorFillWidth then
                Entry.PrevArmorFillWidth = AFW
                Entry.ArmorFill.Visible  = true
                Entry.ArmorFill.Position = UDim2New(0,Entry.ArmorBarX,0,Entry.ArmorBarY)
                Entry.ArmorFill.Size     = UDim2New(0,AFW,0,ArmorHeight)
            end
        end

        if NameOn then
            local NX, NY  = BoxCenterX, BoxY+NameOffset
            local Raw     = Entry.PlayerName
            if Raw~=Entry.PrevNameString or NX~=Entry.PrevNameLabelX or NY~=Entry.PrevNameLabelY then
                local Fmt = FormatText(Raw)
                Entry.PrevNameString=Raw; Entry.PrevNameLabelX=NX; Entry.PrevNameLabelY=NY
                Entry.PrevFormattedName=Fmt
                Entry.LabelName.Visible  = true
                Entry.LabelName.Text     = Fmt
                Entry.LabelName.Position = UDim2New(0,NX,0,NY)
            end
        else
            Entry.LabelName.Visible = false
        end

        if WeaponOn then
            local WX  = BoxCenterX
            local WY  = ArmorBarOn and (BoxBottom+ArmorGap+ArmorHeight+2+WeaponOffset) or (BoxBottom+WeaponOffset)
            local Raw = Entry.WeaponString
            if Raw~=Entry.PrevWeaponString or WX~=Entry.PrevWeaponLabelX or WY~=Entry.PrevWeaponLabelY then
                local Fmt = FormatText(Raw)
                Entry.PrevWeaponString=Raw; Entry.PrevWeaponLabelX=WX; Entry.PrevWeaponLabelY=WY
                Entry.PrevFormattedWeapon=Fmt
                Entry.LabelWeapon.Visible  = Raw~="none" or WeaponNone
                Entry.LabelWeapon.Text     = Fmt
                Entry.LabelWeapon.Position = UDim2New(0,WX+1,0,WY-6)
            end
        else
            Entry.LabelWeapon.Visible = false
        end

        if DistanceOn and HasLocal then
            local DX2,DY2,DZ2 = RootX-LocalX, RootY-LocalY, RootZ-LocalZ
            local DSq = DX2*DX2 + DY2*DY2 + DZ2*DZ2
            local DDistX, DDistY = BoxCenterX, BoxBottom+DistanceOffset
            local Prev = Entry.PrevDistanceValue
            local Cur
            if Prev<0 or DSq<(Prev-0.5)*(Prev-0.5) or DSq>(Prev+0.5)*(Prev+0.5) then
                Cur = Floor(Sqrt(DSq))
            else
                Cur = Prev
            end
            if Cur~=Entry.PrevDistanceValue or DDistX~=Entry.PrevDistanceLabelX or DDistY~=Entry.PrevDistanceLabelY then
                local DS = Cur~=Entry.PrevDistanceValue and (ToString(Cur)..LocalSettings.Distance.Ending) or Entry.PrevDistanceString
                Entry.PrevDistanceValue=Cur; Entry.PrevDistanceString=DS
                Entry.PrevDistanceLabelX=DDistX; Entry.PrevDistanceLabelY=DDistY
                Entry.LabelDistance.Visible  = true
                Entry.LabelDistance.Text     = DS
                Entry.LabelDistance.Position = UDim2New(0,DDistX,0,DDistY)
            end
        else
            Entry.LabelDistance.Visible = false
        end

        if FlagsOn then
            local Raw = Entry.FlagsString
            local FX  = Entry.FlagsLabelX
            local FY  = Entry.FlagsLabelY + FlagsOffset
            if Raw~=Entry.PrevFlagsString or FX~=Entry.PrevFlagsLabelX or FY~=Entry.PrevFlagsLabelY then
                local Fmt = FormatText(Raw)
                Entry.PrevFlagsString=Raw; Entry.PrevFlagsLabelX=FX; Entry.PrevFlagsLabelY=FY
                Entry.PrevFormattedFlags=Fmt
                Entry.LabelFlags.Visible  = Raw~=""
                Entry.LabelFlags.Text     = Fmt
                Entry.LabelFlags.Position = UDim2New(0,FX+2,0,FY-4)
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
        for i = 1, #List do
            if List[i] == Entry then List[i] = List[#List]; List[#List] = nil; break end
        end
        Esp:DestroyEntry(Entry)
    end

    for _, Bot in ipairs(BotFolder:GetChildren()) do task.spawn(AddBot, Bot) end
    Esp.Connections[#Esp.Connections+1] = BotFolder.ChildAdded:Connect(AddBot)
    Esp.Connections[#Esp.Connections+1] = BotFolder.ChildRemoved:Connect(RemoveBot)
end

return Esp
