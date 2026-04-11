local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local HttpService = cloneref(game:GetService("HttpService"))
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local MathFloor = math.floor
local MathMax = math.max
local MathMin = math.min
local MathHuge = math.huge
local MathClamp = math.clamp
local MathSqrt = math.sqrt
local MathTan = math.tan
local MathRad = math.rad

local Vector3New = Vector3.new
local UDim2New = UDim2.new
local Color3New = Color3.new
local Color3FromRGB = Color3.fromRGB
local InstanceNew = Instance.new
local Vector2New = Vector2.new
local CFrameNew = CFrame.new
local ToString = tostring

local ColorWhite = Color3New(1,1,1)
local ColorBlack = Color3New(0,0,0)

local TargetFrametime = 1/60
local BoxMinSize = 0
local CullDistanceSq = 9e9
local LodDistanceSq = 300*300
local GlowPad = 21
local GlowPad2 = GlowPad*2

local ScreenMinX, ScreenMinY, ScreenMaxX, ScreenMaxY = 0,0,0,0
local CamRightX, CamRightY, CamRightZ = 0,0,0
local CamUpX, CamUpY, CamUpZ = 0,0,0
local CamLookX, CamLookY, CamLookZ = 0,0,0
local CamPosX, CamPosY, CamPosZ = 0,0,0
local FocalLength = 1
local HalfViewportX, HalfViewportY = 0,0
local GlowSliceRect = Rect.new(Vector2New(21,21), Vector2New(79,79))

local FontFace = Font.new("rbxasset://fonts/families/RobotoMono.json")
local TahomaFontFace = Font.new("rbxasset://fonts/families/RobotoMono.json")

do
    pcall(function()
        local function LoadFont(FontName, FontWeight, FontStyle, AssetId, FontData)
            if isfile(AssetId) then delfile(AssetId) end
            writefile(AssetId, FontData)
            task.wait(0.1)
            local FontFile = FontName..".font"
            if isfile(FontFile) then delfile(FontFile) end
            writefile(FontFile, HttpService:JSONEncode({
                name = FontName,
                faces = {{
                    name = "Regular",
                    weight = FontWeight,
                    style = FontStyle,
                    assetId = getcustomasset(AssetId),
                }},
            }))
            task.wait(0.1)
            return getcustomasset(FontFile)
        end
        local Base64Data = game:HttpGet("https://gist.githubusercontent.com/index987745/cbe1120f297fc9e7a31568f290a36c30/raw/6dbbb378feffbebb2af51cc8b0125b837f590f7a/SmallestPixel.tff")
        FontFace = Font.new(LoadFont("SmallestPixel.ttf", 100, "normal", "SmallestPixelAsset.ttf", crypt.base64.decode(Base64Data)))
        local TahomaData = game:HttpGet("https://github.com/f1nobe7650/Nebula/raw/refs/heads/main/fs-tahoma-8px.ttf")
        TahomaFontFace = Font.new(LoadFont("Tahoma.ttf", 400, "normal", "TahomaAsset.ttf", TahomaData))
    end)
end

local DefaultSettings = {
    Enabled = true,
    LocalPlayer = true,
    Font = "Tahoma",
    FontSize = 12,
    FontType = "lowercase",
    MaxDistance = 9e9,
    RefreshRate = 60,
    Highlight = {
        Enabled = true,
        FillColor = Color3FromRGB(216,126,157),
        OutlineColor = Color3FromRGB(0,0,0),
        FillTransparency = 0.5,
        OutlineTransparency = 0,
        DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
    },
    Box = {
        Enabled = true,
        Rotation = 90,
        Color = { Color3FromRGB(216,126,157), Color3FromRGB(216,126,157) },
        Transparency = { 0,0 },
        Glow = {
            Enabled = true,
            Rotation = 90,
            Color = { Color3FromRGB(216,126,157), Color3FromRGB(216,126,157) },
            Transparency = { 0.75,0.75 },
        },
        Fill = {
            Enabled = true,
            Rotation = 90,
            Color = { Color3FromRGB(216,126,157), Color3FromRGB(216,126,157) },
            Transparency = { 1,0.5 },
        },
    },
    Bars = {
        HealthBar = {
            Enabled = true,
            Position = "Left",
            Color = { Color3FromRGB(252,71,77), Color3FromRGB(255,255,0), Color3FromRGB(131,245,78) },
            Text = {
                Enabled = true,
                FollowBar = false,
                Ending = "HP",
                Position = "Left",
                Color = Color3FromRGB(255,255,255),
                Transparency = 0,
            },
        },
        ArmorBar = {
            Enabled = true,
            Position = "Bottom",
            Color = { Color3FromRGB(52,131,235), Color3FromRGB(52,131,235), Color3FromRGB(52,131,235) },
            Type = function(Character) return 100, 100 end,
        },
    },
    Name = {
        Enabled = true,
        UseDisplay = true,
        Position = "Top",
        Color = Color3FromRGB(255,255,255),
        Transparency = 0,
    },
    Distance = {
        Enabled = true,
        Ending = "st",
        Position = "Bottom",
        Color = Color3FromRGB(255,255,255),
        Transparency = 0,
    },
    Weapon = {
        Enabled = true,
        ShowNone = true,
        Position = "Bottom",
        Color = Color3FromRGB(255,255,255),
        Transparency = 0,
    },
    Flags = {
        Enabled = true,
        Position = "Right",
        Color = Color3FromRGB(255,255,255),
        Transparency = 0,
        Type = function(Speed, IsJumping)
            local Flags = {}
            if IsJumping then
                table.insert(Flags, "jumping")
            elseif Speed > 0 then
                table.insert(Flags, "moving")
            else
                table.insert(Flags, "standing")
            end
            return Flags
        end,
    },
}

local Settings = {}
local Esp = { Cache = {}, List = {}, Connections = {}, Object = {} }
local ScreenGui = nil

local function GetActiveFont()
    return Settings.Font == "Tahoma" and TahomaFontFace or FontFace
end

local function GetFontSize()
    return Settings.FontSize or 12
end

local function FormatText(Text)
    if Settings.FontType == "uppercase" then return string.upper(Text) end
    if Settings.FontType == "lowercase" then return string.lower(Text) end
    return Text
end

local function MakeInstance(ClassName, Properties)
    local Object = InstanceNew(ClassName)
    for Key, Value in pairs(Properties) do Object[Key] = Value end
    return Object
end

function Esp.Object.StrokeSolid(Parent, Color, ZIndex)
    local Frame = MakeInstance("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = ZIndex,
        Visible = false,
        Size = UDim2New(0,0,0,0),
        Parent = Parent,
    })
    MakeInstance("UIStroke", {
        Color = Color,
        Thickness = 1,
        LineJoinMode = Enum.LineJoinMode.Miter,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Transparency = 0,
        Parent = Frame,
    })
    return Frame
end

function Esp.Object.StrokeGradient(Parent, ZIndex)
    local Frame = MakeInstance("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = ZIndex,
        Visible = false,
        Size = UDim2New(0,0,0,0),
        Parent = Parent,
    })
    local Stroke = MakeInstance("UIStroke", {
        Color = Color3New(1,1,1),
        Thickness = 1,
        LineJoinMode = Enum.LineJoinMode.Miter,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = Frame,
    })
    MakeInstance("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Settings.Box.Color[1]),
            ColorSequenceKeypoint.new(1, Settings.Box.Color[2]),
        }),
        Rotation = Settings.Box.Rotation,
        Parent = Stroke,
    })
    return Frame
end

function Esp.Object.InnerCover(Parent, ZIndex)
    return MakeInstance("Frame", {
        BackgroundColor3 = ColorBlack,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = ZIndex,
        Visible = false,
        Size = UDim2New(0,0,0,0),
        Parent = Parent,
    })
end

function Esp.Object.Frame(Parent, Color, ZIndex)
    return MakeInstance("Frame", {
        BackgroundColor3 = Color,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ZIndex = ZIndex,
        Visible = false,
        Size = UDim2New(0,0,0,0),
        Parent = Parent,
    })
end

function Esp.Object.Label(Parent, ZIndex, Color, Size)
    local Label = MakeInstance("TextLabel", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        ZIndex = ZIndex,
        Visible = false,
        Size = UDim2New(0,300,0,Size+4),
        AnchorPoint = Vector2New(0.5,0),
        Position = UDim2New(0,-9999,0,-9999),
        FontFace = GetActiveFont(),
        TextSize = Size,
        TextColor3 = Color,
        TextStrokeTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextTruncate = Enum.TextTruncate.None,
        TextScaled = false,
        RichText = false,
        Text = "",
        Parent = Parent,
    })
    MakeInstance("UIStroke", {
        Color = ColorBlack,
        Thickness = 1,
        LineJoinMode = Enum.LineJoinMode.Miter,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
        Transparency = 0,
        Parent = Label,
    })
    return Label
end

function Esp.Object.LabelLeft(Parent, ZIndex, Color, Size)
    local Label = MakeInstance("TextLabel", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        ZIndex = ZIndex,
        Visible = false,
        Size = UDim2New(0,300,0,Size+4),
        AnchorPoint = Vector2New(0,0),
        Position = UDim2New(0,-9999,0,-9999),
        FontFace = GetActiveFont(),
        TextSize = Size,
        TextColor3 = Color,
        TextStrokeTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextTruncate = Enum.TextTruncate.None,
        TextScaled = false,
        RichText = false,
        Text = "",
        Parent = Parent,
    })
    MakeInstance("UIStroke", {
        Color = ColorBlack,
        Thickness = 1,
        LineJoinMode = Enum.LineJoinMode.Miter,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
        Transparency = 0,
        Parent = Label,
    })
    return Label
end

function Esp.Object.Fill(Parent, ZIndex)
    local Frame = MakeInstance("Frame", {
        BackgroundColor3 = ColorWhite,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ZIndex = ZIndex,
        Visible = false,
        Size = UDim2New(0,0,0,0),
        AnchorPoint = Vector2New(0,0),
        Parent = Parent,
    })
    MakeInstance("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Settings.Box.Fill.Color[1]),
            ColorSequenceKeypoint.new(1, Settings.Box.Fill.Color[2]),
        }),
        Rotation = Settings.Box.Fill.Rotation,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, Settings.Box.Fill.Transparency[1]),
            NumberSequenceKeypoint.new(1, Settings.Box.Fill.Transparency[2]),
        }),
        Parent = Frame,
    })
    return Frame
end

function Esp.Object.Glow(Parent, Color, Fade)
    local Image = MakeInstance("ImageLabel", {
        Image = "rbxassetid://18245826428",
        ImageColor3 = Color,
        ImageTransparency = Settings.Box.Glow.Transparency[1],
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = GlowSliceRect,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 2,
        Visible = false,
        Size = UDim2New(0,0,0,0),
        Parent = Parent,
    })
    MakeInstance("UIGradient", {
        Transparency = Fade,
        Rotation = Settings.Box.Glow.Rotation,
        Parent = Image,
    })
    return Image
end

function Esp.Object.BarFill(Parent)
    local Frame = MakeInstance("Frame", {
        BackgroundColor3 = ColorWhite,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ZIndex = 11,
        Visible = false,
        Size = UDim2New(0,0,0,0),
        Parent = Parent,
    })
    MakeInstance("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Settings.Bars.HealthBar.Color[1]),
            ColorSequenceKeypoint.new(0.5, Settings.Bars.HealthBar.Color[2]),
            ColorSequenceKeypoint.new(1, Settings.Bars.HealthBar.Color[3]),
        }),
        Rotation = 270,
        Parent = Frame,
    })
    return Frame
end

function Esp.Object.ArmorBarFill(Parent)
    local Frame = MakeInstance("Frame", {
        BackgroundColor3 = ColorWhite,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ZIndex = 11,
        Visible = false,
        Size = UDim2New(0,0,0,0),
        Parent = Parent,
    })
    MakeInstance("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Settings.Bars.ArmorBar.Color[1]),
            ColorSequenceKeypoint.new(1, Settings.Bars.ArmorBar.Color[2]),
        }),
        Rotation = 0,
        Parent = Frame,
    })
    return Frame
end

function Esp.Object.Highlight(ParentModel)
    if not Settings.Highlight.Enabled then return nil end
    local Highlight = InstanceNew("Highlight")
    Highlight.FillColor = Settings.Highlight.FillColor
    Highlight.OutlineColor = Settings.Highlight.OutlineColor
    Highlight.FillTransparency = Settings.Highlight.FillTransparency
    Highlight.OutlineTransparency = Settings.Highlight.OutlineTransparency
    Highlight.DepthMode = Settings.Highlight.DepthMode
    Highlight.Adornee = ParentModel
    Highlight.Parent = ScreenGui
    return Highlight
end

function Esp.ExpandScreenBounds(Depth, Right, Up)
    if Depth <= 0 then return end
    local Inv = FocalLength / Depth
    local Sx = HalfViewportX + Right * Inv
    local Sy = HalfViewportY - Up * Inv
    if Sx < ScreenMinX then ScreenMinX = Sx end
    if Sx > ScreenMaxX then ScreenMaxX = Sx end
    if Sy < ScreenMinY then ScreenMinY = Sy end
    if Sy > ScreenMaxY then ScreenMaxY = Sy end
end

function Esp.ProjectObb(Px, Py, Pz, R00,R01,R02, R10,R11,R12, R20,R21,R22, HalfW, HalfH, HalfD)
    local Ax = R00*HalfW; local Ay = R01*HalfW; local Az = R02*HalfW
    local Bx = R10*HalfH; local By = R11*HalfH; local Bz = R12*HalfH
    local Cx = R20*HalfD; local Cy = R21*HalfD; local Cz = R22*HalfD
    local Dx = Px - CamPosX; local Dy = Py - CamPosY; local Dz = Pz - CamPosZ
    local Od = CamLookX*Dx + CamLookY*Dy + CamLookZ*Dz
    local Or_ = CamRightX*Dx + CamRightY*Dy + CamRightZ*Dz
    local Ou = CamUpX*Dx + CamUpY*Dy + CamUpZ*Dz
    local Ad = CamLookX*Ax + CamLookY*Ay + CamLookZ*Az
    local Ar = CamRightX*Ax + CamRightY*Ay + CamRightZ*Az
    local Au = CamUpX*Ax + CamUpY*Ay + CamUpZ*Az
    local Bd = CamLookX*Bx + CamLookY*By + CamLookZ*Bz
    local Br = CamRightX*Bx + CamRightY*By + CamRightZ*Bz
    local Bu = CamUpX*Bx + CamUpY*By + CamUpZ*Bz
    local Cd = CamLookX*Cx + CamLookY*Cy + CamLookZ*Cz
    local Cr = CamRightX*Cx + CamRightY*Cy + CamRightZ*Cz
    local Cu = CamUpX*Cx + CamUpY*Cy + CamUpZ*Cz
    Esp.ExpandScreenBounds(Od+Ad+Bd+Cd, Or_+Ar+Br+Cr, Ou+Au+Bu+Cu)
    Esp.ExpandScreenBounds(Od+Ad+Bd-Cd, Or_+Ar+Br-Cr, Ou+Au+Bu-Cu)
    Esp.ExpandScreenBounds(Od+Ad-Bd+Cd, Or_+Ar-Br+Cr, Ou+Au-Bu+Cu)
    Esp.ExpandScreenBounds(Od+Ad-Bd-Cd, Or_+Ar-Br-Cr, Ou+Au-Bu-Cu)
    Esp.ExpandScreenBounds(Od-Ad+Bd+Cd, Or_-Ar+Br+Cr, Ou-Au+Bu+Cu)
    Esp.ExpandScreenBounds(Od-Ad+Bd-Cd, Or_-Ar+Br-Cr, Ou-Au+Bu-Cu)
    Esp.ExpandScreenBounds(Od-Ad-Bd+Cd, Or_-Ar-Br+Cr, Ou-Au-Bu+Cu)
    Esp.ExpandScreenBounds(Od-Ad-Bd-Cd, Or_-Ar-Br-Cr, Ou-Au-Bu-Cu)
end

function Esp.EntryNew(Player)
    local Container = InstanceNew("Frame")
    Container.Name = ToString(Player).."_esp"
    Container.BackgroundTransparency = 1
    Container.BorderSizePixel = 0
    Container.Size = UDim2New(1,0,1,0)
    Container.ZIndex = 1
    Container.Parent = ScreenGui
    local FontSize = GetFontSize()
    return {
        Player = Player,
        PlayerName = Player.Name,
        Container = Container,
        OuterStroke = Esp.Object.StrokeSolid(Container, ColorBlack, 4),
        BorderStroke = Esp.Object.StrokeGradient(Container, 5),
        InnerCover = Esp.Object.InnerCover(Container, 6),
        InnerStroke = Esp.Object.StrokeSolid(Container, ColorBlack, 7),
        BoxFill = Esp.Object.Fill(Container, 8),
        BarOutline = Esp.Object.Frame(Container, ColorBlack, 9),
        BarBackground = Esp.Object.Frame(Container, Color3FromRGB(5,10,25), 10),
        BarFill = Esp.Object.BarFill(Container),
        ArmorOutline = Esp.Object.Frame(Container, ColorBlack, 9),
        ArmorBackground = Esp.Object.Frame(Container, Color3FromRGB(5,10,25), 10),
        ArmorFill = Esp.Object.ArmorBarFill(Container),
        GlowTop = Esp.Object.Glow(Container, Settings.Box.Glow.Color[1], NumberSequence.new({
            NumberSequenceKeypoint.new(0,0),
            NumberSequenceKeypoint.new(0.5, Settings.Box.Glow.Transparency[1]),
            NumberSequenceKeypoint.new(1,1),
        })),
        GlowBot = Esp.Object.Glow(Container, Settings.Box.Glow.Color[2], NumberSequence.new({
            NumberSequenceKeypoint.new(0,1),
            NumberSequenceKeypoint.new(0.5, Settings.Box.Glow.Transparency[2]),
            NumberSequenceKeypoint.new(1,0),
        })),
        LabelHp = Esp.Object.Label(Container, 12, Settings.Bars.HealthBar.Text.Color, FontSize),
        LabelName = Esp.Object.Label(Container, 12, Settings.Name.Color, FontSize),
        LabelWeapon = Esp.Object.Label(Container, 12, Settings.Weapon.Color, FontSize),
        LabelDist = Esp.Object.Label(Container, 12, Settings.Distance.Color, FontSize),
        LabelFlags = Esp.Object.LabelLeft(Container, 12, Settings.Flags.Color, FontSize),
        Highlight = nil,
        Character = nil, RootPart = nil, Humanoid = nil,
        IsDead = false, IsR6 = false,
        Health = 1, MaxHealth = 100,
        Armor = 1, MaxArmor = 100,
        TopOffset = 3.0, BotOffset = 3.0,
        Parts = {}, PartHalfW = {}, PartHalfH = {}, PartHalfD = {}, PartCount = 0,
        CachedMoveSpeed = 0, CachedJumping = false,
        IsVisible = false,
        BoxX = 0, BoxY = 0, BoxW = 0, BoxH = 0,
        PrevBoxX = -1, PrevBoxY = -1, PrevBoxW = -1, PrevBoxH = -1,
        PrevFillH = -1, PrevArmorFillW = -1,
        PrevHpStr = "", PrevNameStr = "", PrevWeaponStr = "__unset__",
        PrevDistStr = "", PrevFlagsStr = "",
        PrevHpLabelX = -1, PrevHpLabelY = -1,
        PrevNmLabelX = -1, PrevNmLabelY = -1,
        PrevWpLabelX = -1, PrevWpLabelY = -1,
        PrevDtLabelX = -1, PrevDtLabelY = -1,
        PrevDistance = -1,
        PrevFlLabelX = -1, PrevFlLabelY = -1,
        BarX = 0, BarY = 0, BarH = 0,
        BarLabelX = 0, BarLabelY = 0,
        ArmorBarX = 0, ArmorBarY = 0, ArmorBarW = 0,
        FlagsLabelX = 0, FlagsLabelY = 0,
        HpString = "100",
        WeaponString = "none",
        FlagsString = "",
        PlayerConnections = {},
        CharacterConnections = {},
    }
end

function Esp.EntryHide(Entry)
    Entry.OuterStroke.Visible = false
    Entry.BorderStroke.Visible = false
    Entry.InnerCover.Visible = false
    Entry.InnerStroke.Visible = false
    Entry.BoxFill.Visible = false
    Entry.BarOutline.Visible = false
    Entry.BarBackground.Visible = false
    Entry.BarFill.Visible = false
    Entry.ArmorOutline.Visible = false
    Entry.ArmorBackground.Visible = false
    Entry.ArmorFill.Visible = false
    Entry.GlowTop.Visible = false
    Entry.GlowBot.Visible = false
    Entry.LabelHp.Visible = false
    Entry.LabelName.Visible = false
    Entry.LabelWeapon.Visible = false
    Entry.LabelDist.Visible = false
    Entry.LabelFlags.Visible = false
    Entry.IsVisible = false
    if Entry.Highlight then Entry.Highlight.Enabled = false end
    Entry.PrevBoxX = -1; Entry.PrevBoxY = -1; Entry.PrevBoxW = -1; Entry.PrevBoxH = -1
    Entry.PrevFillH = -1
    Entry.PrevArmorFillW = -1
    Entry.PrevHpStr = ""; Entry.PrevNameStr = ""; Entry.PrevWeaponStr = "__unset__"
    Entry.PrevDistStr = ""; Entry.PrevFlagsStr = ""
    Entry.PrevHpLabelX = -1; Entry.PrevHpLabelY = -1
    Entry.PrevNmLabelX = -1; Entry.PrevNmLabelY = -1
    Entry.PrevWpLabelX = -1; Entry.PrevWpLabelY = -1
    Entry.PrevDtLabelX = -1; Entry.PrevDtLabelY = -1
    Entry.PrevDistance = -1
    Entry.PrevFlLabelX = -1; Entry.PrevFlLabelY = -1
end

function Esp.EntryDestroy(Entry)
    Esp.EntryHide(Entry)
    for _, C in ipairs(Entry.PlayerConnections) do pcall(C.Disconnect, C) end
    for _, C in ipairs(Entry.CharacterConnections) do pcall(C.Disconnect, C) end
    if Entry.Highlight then pcall(Entry.Highlight.Destroy, Entry.Highlight) end
    pcall(Entry.Container.Destroy, Entry.Container)
end

local R15Parts = {"Head","UpperTorso","LowerTorso","LeftUpperArm","LeftLowerArm","LeftHand","RightUpperArm","RightLowerArm","RightHand","LeftUpperLeg","LeftLowerLeg","LeftFoot","RightUpperLeg","RightLowerLeg","RightFoot"}
local R6Parts = {"Head","Torso","Left Arm","Right Arm","Left Leg","Right Leg"}
local R15Padding = {Head=0.05,LeftHand=0.02,RightHand=0.02,LeftFoot=0.04,RightFoot=0.04}
local R6Padding = {Head=0.05,Torso=0,["Left Arm"]=0,["Right Arm"]=0,["Left Leg"]=0.03,["Right Leg"]=0.03}
local BodyPartNames = {Head=true,LeftHand=true,RightHand=true,LeftFoot=true,RightFoot=true,["Left Arm"]=true,["Right Arm"]=true,Torso=true,["Left Leg"]=true,["Right Leg"]=true}

function Esp.EntryBuild(Entry)
    local Character = Entry.Character
    if not Character then return end
    local PartList = Entry.IsR6 and R6Parts or R15Parts
    local PaddingMap = Entry.IsR6 and R6Padding or R15Padding
    local RootY = Entry.RootPart.Position.Y
    local LowestY = MathHuge
    local HighestY = -MathHuge
    local Parts = {}
    local HalfWList = {}
    local HalfHList = {}
    local HalfDList = {}
    local Count = 0
    for i=1,#PartList do
        local Part = Character:FindFirstChild(PartList[i])
        if Part and Part:IsA("BasePart") then
            local Padding = PaddingMap[PartList[i]] or 0.04
            local PartSize = Part.Size
            local HalfW = PartSize.X*0.5 + Padding
            local HalfH = PartSize.Y*0.5
            local HalfD = PartSize.Z*0.5 + Padding
            local LocalY = Part.Position.Y - RootY
            if LocalY + HalfH > HighestY then HighestY = LocalY + HalfH end
            if LocalY - HalfH < LowestY then LowestY = LocalY - HalfH end
            Count = Count + 1
            Parts[Count] = Part
            HalfWList[Count] = HalfW
            HalfHList[Count] = HalfH
            HalfDList[Count] = HalfD
        end
    end
    Entry.TopOffset = (HighestY == -MathHuge) and 3.0 or HighestY + 0.02
    Entry.BotOffset = (LowestY == MathHuge) and 3.0 or -LowestY + 0.02
    Entry.Parts = Parts
    Entry.PartHalfW = HalfWList
    Entry.PartHalfH = HalfHList
    Entry.PartHalfD = HalfDList
    Entry.PartCount = Count
end

function Esp.EntryClear(Entry)
    for _, C in ipairs(Entry.CharacterConnections) do pcall(C.Disconnect, C) end
    Entry.CharacterConnections = {}
    Entry.Character = nil
    Entry.RootPart = nil
    Entry.Humanoid = nil
    Entry.IsDead = false
    Entry.Parts = {}
    Entry.PartHalfW = {}
    Entry.PartHalfH = {}
    Entry.PartHalfD = {}
    Entry.PartCount = 0
    Entry.HpString = "100"
    Entry.WeaponString = "none"
    Entry.FlagsString = ""
    Entry.CachedMoveSpeed = 0
    Entry.CachedJumping = false
    if Entry.Highlight then
        pcall(Entry.Highlight.Destroy, Entry.Highlight)
        Entry.Highlight = nil
    end
end

function Esp.GetEquippedWeapon(Character)
    local Tool = Character:FindFirstChildOfClass("Tool")
    return Tool and Tool.Name or "none"
end

local function RebuildFlags(Entry)
    if Settings.Flags.Type then
        local Result = Settings.Flags.Type(Entry.CachedMoveSpeed, Entry.CachedJumping)
        if type(Result) == "table" then
            Entry.FlagsString = (#Result > 0) and table.concat(Result, ", ") or ""
            Entry.PrevFlagsStr = ""
        end
    end
end

function Esp.EntryLink(Entry, Character)
    Esp.EntryClear(Entry)
    Esp.EntryHide(Entry)
    if not Character then return end
    local RootPart = Character:WaitForChild("HumanoidRootPart", 10)
    local Humanoid = Character:WaitForChild("Humanoid", 10)
    if not RootPart or not Humanoid then return end
    if not Character:FindFirstChild("UpperTorso") and not Character:FindFirstChild("Torso") then
        task.wait(0.5)
    end
    Entry.IsR6 = Character:FindFirstChild("Torso") ~= nil
    Entry.Character = Character
    Entry.RootPart = RootPart
    Entry.Humanoid = Humanoid
    Entry.IsDead = false
    Entry.MaxHealth = Humanoid.MaxHealth
    Entry.Health = MathClamp(Humanoid.Health / Humanoid.MaxHealth, 0, 1)
    Entry.HpString = ToString(MathFloor(Humanoid.Health))
    Entry.CachedMoveSpeed = Humanoid.MoveDirection.Magnitude
    Entry.CachedJumping = Humanoid.Jump
    Entry.WeaponString = Esp.GetEquippedWeapon(Character)
    RebuildFlags(Entry)
    if Settings.Highlight.Enabled then
        if Entry.Highlight then pcall(Entry.Highlight.Destroy, Entry.Highlight) end
        Entry.Highlight = Esp.Object.Highlight(Character)
        if Entry.Highlight then Entry.Highlight.Enabled = true end
    end
    local CharConns = Entry.CharacterConnections
    CharConns[#CharConns+1] = Humanoid.HealthChanged:Connect(function(NewHp)
        Entry.Health = MathClamp(NewHp / Entry.MaxHealth, 0, 1)
        Entry.HpString = ToString(MathFloor(NewHp))
        Entry.PrevFillH = -1
        Entry.PrevHpStr = ""
    end)
    CharConns[#CharConns+1] = Humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
        Entry.MaxHealth = Humanoid.MaxHealth
    end)
    CharConns[#CharConns+1] = Humanoid.Died:Connect(function()
        Entry.IsDead = true
        if Entry.Highlight then Entry.Highlight.Enabled = false end
        Esp.EntryHide(Entry)
    end)
    CharConns[#CharConns+1] = Humanoid.StateChanged:Connect(function(_, NewState)
        Entry.CachedJumping = (NewState == Enum.HumanoidStateType.Jumping or NewState == Enum.HumanoidStateType.Freefall)
        RebuildFlags(Entry)
    end)
    CharConns[#CharConns+1] = Humanoid.Running:Connect(function(Speed)
        Entry.CachedMoveSpeed = Speed
        RebuildFlags(Entry)
    end)
    CharConns[#CharConns+1] = Character.ChildAdded:Connect(function(Child)
        if Child:IsA("Tool") then
            Entry.WeaponString = Child.Name
            Entry.PrevWeaponStr = "__unset__"
        end
    end)
    CharConns[#CharConns+1] = Character.ChildRemoved:Connect(function(Child)
        if Child:IsA("Tool") then
            Entry.WeaponString = Esp.GetEquippedWeapon(Character)
            Entry.PrevWeaponStr = "__unset__"
        end
    end)
    CharConns[#CharConns+1] = Character.DescendantAdded:Connect(function(Desc)
        if not Desc:IsA("BasePart") or not BodyPartNames[Desc.Name] then return end
        local Parent = Desc.Parent
        while Parent and Parent ~= Character do
            if Parent:IsA("Tool") then return end
            Parent = Parent.Parent
        end
        task.defer(Esp.EntryBuild, Entry)
    end)
    CharConns[#CharConns+1] = Character.DescendantRemoving:Connect(function(Desc)
        if Desc:IsA("BasePart") and BodyPartNames[Desc.Name] then
            task.defer(Esp.EntryBuild, Entry)
        end
    end)
    Esp.EntryBuild(Entry)
end

function Esp.Add(Player)
    if Player == LocalPlayer then return end
    if Esp.Cache[Player] then Esp.EntryDestroy(Esp.Cache[Player]) end
    local Entry = Esp.EntryNew(Player)
    Esp.Cache[Player] = Entry
    local List = Esp.List
    List[#List+1] = Entry
    local PlayerConns = Entry.PlayerConnections
    PlayerConns[#PlayerConns+1] = Player.CharacterAdded:Connect(function(NewCharacter)
        task.spawn(Esp.EntryLink, Entry, NewCharacter)
    end)
    PlayerConns[#PlayerConns+1] = Player.CharacterRemoving:Connect(function()
        Entry.Character = nil
        Entry.RootPart = nil
        if Entry.Highlight then Entry.Highlight.Enabled = false end
        Esp.EntryHide(Entry)
    end)
    if Player.Character then
        task.spawn(Esp.EntryLink, Entry, Player.Character)
    end
end

function Esp.Remove(Player)
    local Entry = Esp.Cache[Player]
    if not Entry then return end
    Esp.Cache[Player] = nil
    local List = Esp.List
    for i=1,#List do
        if List[i] == Entry then
            List[i] = List[#List]
            List[#List] = nil
            break
        end
    end
    Esp.EntryDestroy(Entry)
end

local ESPLibrary = {}

function ESPLibrary.Start(overrideSettings)
    if overrideSettings then
        for k,v in pairs(overrideSettings) do Settings[k] = v end
    else
        for k,v in pairs(DefaultSettings) do Settings[k] = v end
    end
    if ScreenGui then return end
    ScreenGui = InstanceNew("ScreenGui")
    ScreenGui.Name = "\0"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Parent = gethui()
    for _, Player in ipairs(Players:GetPlayers()) do
        task.spawn(Esp.Add, Player)
    end
    Esp.Connections[#Esp.Connections+1] = Players.PlayerAdded:Connect(function(Player)
        task.spawn(Esp.Add, Player)
    end)
    Esp.Connections[#Esp.Connections+1] = Players.PlayerRemoving:Connect(function(Player)
        task.delay(0.1, Esp.Remove, Player)
    end)
    local BotFolder = workspace:FindFirstChild("Bots")
    if BotFolder then
        local BotCache = {}
        local function BotAdd(Model)
            if not Model:IsA("Model") or BotCache[Model] then return end
            local Entry = Esp.EntryNew({ Name = Model.Name })
            Entry.PlayerName = Model.Name
            BotCache[Model] = Entry
            local List = Esp.List
            List[#List+1] = Entry
            task.spawn(Esp.EntryLink, Entry, Model)
        end
        local function BotRemove(Model)
            local Entry = BotCache[Model]
            if not Entry then return end
            BotCache[Model] = nil
            local List = Esp.List
            for i=1,#List do
                if List[i] == Entry then
                    List[i] = List[#List]
                    List[#List] = nil
                    break
                end
            end
            Esp.EntryDestroy(Entry)
        end
        for _, Bot in ipairs(BotFolder:GetChildren()) do
            task.spawn(BotAdd, Bot)
        end
        Esp.Connections[#Esp.Connections+1] = BotFolder.ChildAdded:Connect(BotAdd)
        Esp.Connections[#Esp.Connections+1] = BotFolder.ChildRemoved:Connect(BotRemove)
    end
    local LocalPlayerRoot = nil
    local function OnLocalCharacter(Character)
        LocalPlayerRoot = Character and Character:WaitForChild("HumanoidRootPart",5) or nil
    end
    if LocalPlayer.Character then task.spawn(OnLocalCharacter, LocalPlayer.Character) end
    Esp.Connections[#Esp.Connections+1] = LocalPlayer.CharacterAdded:Connect(OnLocalCharacter)
    Esp.Connections[#Esp.Connections+1] = LocalPlayer.CharacterRemoving:Connect(function()
        LocalPlayerRoot = nil
    end)
    local TextOffsets = {Name = -18, Weapon = 19, Distance = 8, Health = -3, Flags = -2}
    local BoxEnabled = Settings.Box.Enabled
    local FillEnabled = Settings.Box.Fill.Enabled
    local GlowEnabled = Settings.Box.Glow.Enabled
    local BarEnabled = Settings.Bars.HealthBar.Enabled
    local ArmorEnabled = Settings.Bars.ArmorBar.Enabled
    local ArmorTypeFn = Settings.Bars.ArmorBar.Type
    local HpTextEnabled = Settings.Bars.HealthBar.Text.Enabled
    local NameEnabled = Settings.Name.Enabled
    local WeaponEnabled = Settings.Weapon.Enabled
    local WeaponShowNone = Settings.Weapon.ShowNone
    local DistEnabled = Settings.Distance.Enabled
    local FlagsEnabled = Settings.Flags.Enabled
    local FontSize = GetFontSize()
    local NameOffset = TextOffsets.Name
    local WeaponOffset = TextOffsets.Weapon
    local DistOffset = TextOffsets.Distance
    local HpOffset = TextOffsets.Health
    local FlagsOffset = TextOffsets.Flags
    local DeltaAccum = 0
    local renderConnection = RunService.RenderStepped:Connect(function(DeltaTime)
        DeltaAccum = DeltaAccum + DeltaTime
        if DeltaAccum < TargetFrametime then return end
        DeltaAccum = DeltaAccum - TargetFrametime
        local CamCframe = Camera.CFrame
        local ViewportSize = Camera.ViewportSize
        local RightVector = CamCframe.RightVector
        CamRightX = RightVector.X; CamRightY = RightVector.Y; CamRightZ = RightVector.Z
        local UpVector = CamCframe.UpVector
        CamUpX = UpVector.X; CamUpY = UpVector.Y; CamUpZ = UpVector.Z
        local LookVector = CamCframe.LookVector
        CamLookX = LookVector.X; CamLookY = LookVector.Y; CamLookZ = LookVector.Z
        local CameraPos = CamCframe.Position
        CamPosX = CameraPos.X; CamPosY = CameraPos.Y; CamPosZ = CameraPos.Z
        HalfViewportX = ViewportSize.X * 0.5
        HalfViewportY = ViewportSize.Y * 0.5
        FocalLength = HalfViewportY / MathTan(MathRad(Camera.FieldOfView * 0.5))
        local LpX, LpY, LpZ = 0,0,0
        local HasLocalPlayer = LocalPlayerRoot ~= nil
        if HasLocalPlayer then
            local LpPos = LocalPlayerRoot.Position
            LpX = LpPos.X; LpY = LpPos.Y; LpZ = LpPos.Z
        end
        local List = Esp.List
        for i=1,#List do
            local Entry = List[i]
            if Entry.IsDead or not Entry.RootPart or not Entry.Character then
                Esp.EntryHide(Entry)
                goto continue
            end
            local RootPos = Entry.RootPart.Position
            local Rx, Ry, Rz = RootPos.X, RootPos.Y, RootPos.Z
            if HasLocalPlayer then
                local Dx = Rx - LpX; local Dy = Ry - LpY; local Dz = Rz - LpZ
                if Dx*Dx + Dy*Dy + Dz*Dz > CullDistanceSq then
                    Esp.EntryHide(Entry)
                    goto continue
                end
            end
            local FrontDot = (Rx - CamPosX)*CamLookX + (Ry - CamPosY)*CamLookY + (Rz - CamPosZ)*CamLookZ
            if FrontDot < 0 then
                Esp.EntryHide(Entry)
                goto continue
            end
            if Entry.Highlight and not Entry.Highlight.Enabled then
                Entry.Highlight.Enabled = true
            end
            ScreenMinX = MathHuge; ScreenMinY = MathHuge
            ScreenMaxX = -MathHuge; ScreenMaxY = -MathHuge
            local CamDx = Rx - CamPosX; local CamDy = Ry - CamPosY; local CamDz = Rz - CamPosZ
            local CamDist2 = CamDx*CamDx + CamDy*CamDy + CamDz*CamDz
            if Entry.PartCount == 0 or CamDist2 > LodDistanceSq then
                local DepthD = CamLookX*CamDx + CamLookY*CamDy + CamLookZ*CamDz
                local RightD = CamRightX*CamDx + CamRightY*CamDy + CamRightZ*CamDz
                local UpD = CamUpX*CamDx + CamUpY*CamDy + CamUpZ*CamDz
                local EntryTop = Entry.TopOffset
                local EntryBot = Entry.BotOffset
                local CamDist = MathSqrt(CamDist2)
                local BoxHalfW = MathClamp(CamDist * 0.018, 1.2, 2.2)
                local Inv
                local TopDepth = DepthD + CamLookY * EntryTop
                if TopDepth > 0 then
                    Inv = FocalLength / TopDepth
                    local SxL = HalfViewportX + (RightD - BoxHalfW) * Inv
                    local SxR = HalfViewportX + (RightD + BoxHalfW) * Inv
                    local Sy = HalfViewportY - (UpD + EntryTop) * Inv
                    if SxL < ScreenMinX then ScreenMinX = SxL end
                    if SxR > ScreenMaxX then ScreenMaxX = SxR end
                    if Sy < ScreenMinY then ScreenMinY = Sy end
                    if Sy > ScreenMaxY then ScreenMaxY = Sy end
                end
                local BotDepth = DepthD - CamLookY * EntryBot
                if BotDepth > 0 then
                    Inv = FocalLength / BotDepth
                    local SxL = HalfViewportX + (RightD - BoxHalfW) * Inv
                    local SxR = HalfViewportX + (RightD + BoxHalfW) * Inv
                    local Sy = HalfViewportY - (UpD - EntryBot) * Inv
                    if SxL < ScreenMinX then ScreenMinX = SxL end
                    if SxR > ScreenMaxX then ScreenMaxX = SxR end
                    if Sy < ScreenMinY then ScreenMinY = Sy end
                    if Sy > ScreenMaxY then ScreenMaxY = Sy end
                end
                if DepthD > 0 then
                    Inv = FocalLength / DepthD
                    local SxL = HalfViewportX + (RightD - BoxHalfW) * Inv
                    local SxR = HalfViewportX + (RightD + BoxHalfW) * Inv
                    local SyMid = HalfViewportY - UpD * Inv
                    if SxL < ScreenMinX then ScreenMinX = SxL end
                    if SxR > ScreenMaxX then ScreenMaxX = SxR end
                    if SyMid < ScreenMinY then ScreenMinY = SyMid end
                    if SyMid > ScreenMaxY then ScreenMaxY = SyMid end
                end
            else
                local Parts = Entry.Parts
                local HalfWList = Entry.PartHalfW
                local HalfHList = Entry.PartHalfH
                local HalfDList = Entry.PartHalfD
                for PartIndex=1,Entry.PartCount do
                    local Part = Parts[PartIndex]
                    if Part and Part.Parent then
                        local Cx,Cy,Cz, M00,M01,M02, M10,M11,M12, M20,M21,M22 = Part.CFrame:GetComponents()
                        Esp.ProjectObb(Cx,Cy,Cz, M00,M01,M02, M10,M11,M12, M20,M21,M22, HalfWList[PartIndex], HalfHList[PartIndex], HalfDList[PartIndex])
                    end
                end
            end
            if ScreenMinX == MathHuge then
                Esp.EntryHide(Entry)
                goto continue
            end
            local BoxX = MathFloor(ScreenMinX)
            local BoxY = MathFloor(ScreenMinY)
            local BoxW = MathMax(MathFloor(ScreenMaxX - ScreenMinX), BoxMinSize)
            local BoxH = MathMax(MathFloor(ScreenMaxY - ScreenMinY), BoxMinSize)
            local BoxCx = BoxX + MathFloor(BoxW * 0.5)
            local BoxRight = BoxX + BoxW
            local BoxBot = BoxY + BoxH
            Entry.IsVisible = true
            local IsDirty = BoxX ~= Entry.PrevBoxX or BoxY ~= Entry.PrevBoxY or BoxW ~= Entry.PrevBoxW or BoxH ~= Entry.PrevBoxH
            if IsDirty then
                Entry.PrevBoxX = BoxX; Entry.PrevBoxY = BoxY; Entry.PrevBoxW = BoxW; Entry.PrevBoxH = BoxH
                Entry.PrevFillH = -1; Entry.PrevArmorFillW = -1
                Entry.PrevHpStr = ""; Entry.PrevNameStr = ""; Entry.PrevWeaponStr = "__unset__"
                Entry.PrevDistStr = ""; Entry.PrevFlagsStr = ""
                Entry.PrevHpLabelX = -1; Entry.PrevHpLabelY = -1
                Entry.PrevNmLabelX = -1; Entry.PrevNmLabelY = -1
                Entry.PrevWpLabelX = -1; Entry.PrevWpLabelY = -1
                Entry.PrevDtLabelX = -1; Entry.PrevDtLabelY = -1
                Entry.PrevDistance = -1
                Entry.PrevFlLabelX = -1; Entry.PrevFlLabelY = -1
                if BoxEnabled then
                    Entry.OuterStroke.Visible = true
                    Entry.OuterStroke.Position = UDim2New(0,BoxX-1,0,BoxY-1)
                    Entry.OuterStroke.Size = UDim2New(0,BoxW+2,0,BoxH+2)
                    Entry.BorderStroke.Visible = true
                    Entry.BorderStroke.Position = UDim2New(0,BoxX,0,BoxY)
                    Entry.BorderStroke.Size = UDim2New(0,BoxW,0,BoxH)
                    Entry.InnerCover.Visible = true
                    Entry.InnerCover.Position = UDim2New(0,BoxX+1,0,BoxY+1)
                    Entry.InnerCover.Size = UDim2New(0,BoxW-2,0,BoxH-2)
                    Entry.InnerStroke.Visible = true
                    Entry.InnerStroke.Position = UDim2New(0,BoxX+1,0,BoxY+1)
                    Entry.InnerStroke.Size = UDim2New(0,BoxW-2,0,BoxH-2)
                    if FillEnabled then
                        Entry.BoxFill.Visible = true
                        Entry.BoxFill.Position = UDim2New(0,BoxX+1,0,BoxY+1)
                        Entry.BoxFill.Size = UDim2New(0,BoxW-2,0,BoxH-2)
                    end
                    if GlowEnabled then
                        local Gx = BoxX - GlowPad
                        local Gy = BoxY - GlowPad
                        local Gw = BoxW + GlowPad2
                        local Gh = BoxH + GlowPad2
                        Entry.GlowTop.Visible = true
                        Entry.GlowTop.Position = UDim2New(0,Gx,0,Gy)
                        Entry.GlowTop.Size = UDim2New(0,Gw,0,Gh)
                        Entry.GlowBot.Visible = true
                        Entry.GlowBot.Position = UDim2New(0,Gx,0,Gy)
                        Entry.GlowBot.Size = UDim2New(0,Gw,0,Gh)
                    end
                end
                if BarEnabled then
                    local Bx = BoxX - (1+4+1)
                    local By = BoxY - 1
                    local Bh = BoxH + 2
                    Entry.BarX = Bx; Entry.BarY = By; Entry.BarH = Bh
                    Entry.BarLabelX = Bx - 14
                    Entry.BarLabelY = By
                    Entry.BarOutline.Visible = true
                    Entry.BarOutline.Position = UDim2New(0,Bx-1,0,By-1)
                    Entry.BarOutline.Size = UDim2New(0,1+2,0,Bh+2)
                    Entry.BarBackground.Visible = true
                    Entry.BarBackground.Position = UDim2New(0,Bx,0,By)
                    Entry.BarBackground.Size = UDim2New(0,1,0,Bh)
                end
                if ArmorEnabled then
                    local Ax = BoxX - 1
                    local Ay = BoxBot + 4
                    local Aw = BoxW + 2
                    Entry.ArmorBarX = Ax
                    Entry.ArmorBarY = Ay
                    Entry.ArmorBarW = Aw
                    Entry.ArmorOutline.Visible = true
                    Entry.ArmorOutline.Position = UDim2New(0,Ax-1,0,Ay-1)
                    Entry.ArmorOutline.Size = UDim2New(0,Aw+2,0,1+2)
                    Entry.ArmorBackground.Visible = true
                    Entry.ArmorBackground.Position = UDim2New(0,Ax,0,Ay)
                    Entry.ArmorBackground.Size = UDim2New(0,Aw,0,1)
                end
                if FlagsEnabled then
                    Entry.FlagsLabelX = BoxRight + 4+1
                    Entry.FlagsLabelY = BoxY
                end
            end
            if BarEnabled then
                local FillH = MathMax(MathFloor(Entry.BarH * Entry.Health), 1)
                if FillH ~= Entry.PrevFillH then
                    Entry.PrevFillH = FillH
                    Entry.BarFill.Visible = true
                    Entry.BarFill.Position = UDim2New(0,Entry.BarX,0,Entry.BarY + (Entry.BarH - FillH))
                    Entry.BarFill.Size = UDim2New(0,1,0,FillH)
                end
                if HpTextEnabled then
                    local HpStr = Entry.HpString
                    local HpLblX = Entry.BarLabelX
                    local HpLblY = Entry.BarLabelY
                    if HpStr ~= Entry.PrevHpStr or HpLblX ~= Entry.PrevHpLabelX or HpLblY ~= Entry.PrevHpLabelY then
                        Entry.PrevHpStr = HpStr
                        Entry.PrevHpLabelX = HpLblX
                        Entry.PrevHpLabelY = HpLblY
                        Entry.LabelHp.Visible = true
                        Entry.LabelHp.Text = HpStr
                        Entry.LabelHp.Position = UDim2New(0,HpLblX+1,0,HpLblY + HpOffset)
                    end
                end
            end
            if ArmorEnabled and ArmorTypeFn then
                local CurrentArmor, MaxArmor = ArmorTypeFn(Entry.Character)
                local ArmorRatio = (MaxArmor and MaxArmor > 0) and MathClamp(CurrentArmor / MaxArmor, 0, 1) or 1
                local FillW = MathMax(MathFloor(Entry.ArmorBarW * ArmorRatio), 1)
                if FillW ~= Entry.PrevArmorFillW then
                    Entry.PrevArmorFillW = FillW
                    Entry.ArmorFill.Visible = true
                    Entry.ArmorFill.Position = UDim2New(0,Entry.ArmorBarX,0,Entry.ArmorBarY)
                    Entry.ArmorFill.Size = UDim2New(0,FillW,0,1)
                end
            end
            if NameEnabled then
                local NmX = BoxCx
                local NmY = BoxY + NameOffset
                local NmStr = Entry.PlayerName
                if NmStr ~= Entry.PrevNameStr or NmX ~= Entry.PrevNmLabelX or NmY ~= Entry.PrevNmLabelY then
                    Entry.PrevNameStr = NmStr
                    Entry.PrevNmLabelX = NmX
                    Entry.PrevNmLabelY = NmY
                    Entry.LabelName.Visible = true
                    Entry.LabelName.Text = FormatText(NmStr)
                    Entry.LabelName.Position = UDim2New(0,NmX,0,NmY)
                end
            end
            if WeaponEnabled then
                local WpX = BoxCx
                local WpY = ArmorEnabled and (BoxBot + 1+4+2 + WeaponOffset) or (BoxBot + WeaponOffset)
                local WpStr = Entry.WeaponString
                if WpStr ~= Entry.PrevWeaponStr or WpX ~= Entry.PrevWpLabelX or WpY ~= Entry.PrevWpLabelY then
                    Entry.PrevWeaponStr = WpStr
                    Entry.PrevWpLabelX = WpX
                    Entry.PrevWpLabelY = WpY
                    local Show = (WpStr ~= "none") or WeaponShowNone
                    Entry.LabelWeapon.Visible = Show
                    Entry.LabelWeapon.Text = FormatText(WpStr)
                    Entry.LabelWeapon.Position = UDim2New(0,WpX+1,0,WpY-6)
                end
            end
            if DistEnabled and HasLocalPlayer then
                local Dx = Rx - LpX; local Dy = Ry - LpY; local Dz = Rz - LpZ
                local Dist2 = Dx*Dx + Dy*Dy + Dz*Dz
                local DtLblX = BoxCx
                local DtLblY = BoxBot + DistOffset
                local PrevDist = Entry.PrevDistance
                local CurrentDist
                if PrevDist < 0 or Dist2 < (PrevDist-0.5)*(PrevDist-0.5) or Dist2 > (PrevDist+0.5)*(PrevDist+0.5) then
                    CurrentDist = MathFloor(MathSqrt(Dist2))
                else
                    CurrentDist = PrevDist
                end
                if CurrentDist ~= Entry.PrevDistance or DtLblX ~= Entry.PrevDtLabelX or DtLblY ~= Entry.PrevDtLabelY then
                    local DistStr = (CurrentDist ~= Entry.PrevDistance) and (ToString(CurrentDist)..Settings.Distance.Ending) or Entry.PrevDistStr
                    Entry.PrevDistance = CurrentDist
                    Entry.PrevDistStr = DistStr
                    Entry.PrevDtLabelX = DtLblX
                    Entry.PrevDtLabelY = DtLblY
                    Entry.LabelDist.Visible = true
                    Entry.LabelDist.Text = DistStr
                    Entry.LabelDist.Position = UDim2New(0,DtLblX,0,DtLblY)
                end
            end
            if FlagsEnabled then
                local FlagsStr = Entry.FlagsString
                local FlagsX = Entry.FlagsLabelX
                local FlagsY = Entry.FlagsLabelY + FlagsOffset
                if FlagsStr ~= Entry.PrevFlagsStr or FlagsX ~= Entry.PrevFlLabelX or FlagsY ~= Entry.PrevFlLabelY then
                    Entry.PrevFlagsStr = FlagsStr
                    Entry.PrevFlLabelX = FlagsX
                    Entry.PrevFlLabelY = FlagsY
                    Entry.LabelFlags.Visible = FlagsStr ~= ""
                    Entry.LabelFlags.Text = FormatText(FlagsStr)
                    Entry.LabelFlags.Position = UDim2New(0,FlagsX+2,0,FlagsY-4)
                end
            end
            ::continue::
        end
    end)
    ESPLibrary._renderConnection = renderConnection
end

function ESPLibrary.Stop()
    if ESPLibrary._renderConnection then
        ESPLibrary._renderConnection:Disconnect()
        ESPLibrary._renderConnection = nil
    end
    for _, C in ipairs(Esp.Connections) do pcall(C.Disconnect, C) end
    Esp.Connections = {}
    for _, Entry in pairs(Esp.Cache) do
        Esp.EntryDestroy(Entry)
    end
    Esp.Cache = {}
    Esp.List = {}
    if ScreenGui then ScreenGui:Destroy() ScreenGui = nil end
end

function ESPLibrary.SetSettings(newSettings)
    for k,v in pairs(newSettings) do Settings[k] = v end
end
