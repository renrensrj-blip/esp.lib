local MathFloor = math.floor;
local MathMax = math.max;
local MathHuge = math.huge;
local MathClamp = math.clamp;
local MathSqrt = math.sqrt;
local MathTan = math.tan;
local MathRad = math.rad;

local NewVector3 = Vector3.new;
local NewVector2 = Vector2.new;
local NewUDim2 = UDim2.new;
local NewColor = Color3.new;
local NewRgb = Color3.fromRGB;
local NewCFrame = CFrame.new;
local NewInstance = Instance.new;
local ToString = tostring;

local Ref = cloneref or function(X) return X end;
local ServicePlayers = Ref(game:GetService("Players"));
local ServiceRunService = Ref(game:GetService("RunService"));
local ServiceHttpService = Ref(game:GetService("HttpService"));
local Camera = workspace.CurrentCamera;
local LocalPlayer = ServicePlayers.LocalPlayer;

local ColorWhite = NewColor(1, 1, 1);
local ColorBlack = NewColor(0, 0, 0);
local ColorBarBackground = NewRgb(5, 10, 25);
local GlowPadding = 21;
local GlowPadding2 = GlowPadding * 2;
local GlowSliceRect = Rect.new(NewVector2(21, 21), NewVector2(79, 79));

local ScreenMinX, ScreenMinY, ScreenMaxX, ScreenMaxY = 0, 0, 0, 0;
local CameraRightX, CameraRightY, CameraRightZ = 0, 0, 0;
local CameraUpX, CameraUpY, CameraUpZ = 0, 0, 0;
local CameraLookX, CameraLookY, CameraLookZ = 0, 0, 0;
local CameraPositionX, CameraPositionY, CameraPositionZ = 0, 0, 0;
local FocalLength, HalfViewportX, HalfViewportY = 1, 0, 0;

local FontSmall = Font.new("rbxasset://fonts/families/RobotoMono.json");
local FontTahoma = Font.new("rbxasset://fonts/families/RobotoMono.json");

pcall(function()
    local function LoadFont(FontName, FontWeight, FontStyle, AssetFile, FontData)
        if isfile(AssetFile) then delfile(AssetFile) end;
        writefile(AssetFile, FontData);
        task.wait(0.1);
        local FontFile = FontName .. ".font";
        if isfile(FontFile) then delfile(FontFile) end;
        writefile(FontFile, ServiceHttpService:JSONEncode({
            name = FontName;
            faces = {{ name = "Regular"; weight = FontWeight; style = FontStyle; assetId = getcustomasset(AssetFile) }};
        }));
        task.wait(0.1);
        return getcustomasset(FontFile);
    end;

    FontSmall = Font.new(LoadFont("SmallestPixel.ttf", 100, "normal", "SmallestPixelAsset.ttf",
        crypt.base64.decode(game:HttpGet("https://gist.githubusercontent.com/index987745/cbe1120f297fc9e7a31568f290a36c30/raw/6dbbb378feffbebb2af51cc8b0125b837f590f7a/SmallestPixel.tff"))
    ));
    FontTahoma = Font.new(LoadFont("Tahoma.ttf", 400, "normal", "TahomaAsset.ttf",
        game:HttpGet("https://github.com/f1nobe7650/Nebula/raw/refs/heads/main/fs-tahoma-8px.ttf")
    ));
end);

local Esp = { Cache = {}, List = {}, Connections = {}, LocalRoot = nil };

Esp.Settings = {
    Enabled = false, LocalPlayer = true, Font = "Tahoma",
    FontSize = 12, FontType = "lowercase", MaxDistance = 9e9, RefreshRate = 60,

    Highlight = {
        Enabled = true, FillColor = NewRgb(216, 126, 157), OutlineColor = NewRgb(0, 0, 0),
        FillTransparency = 0.5, OutlineTransparency = 0, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
    },

    Box = {
        Enabled = false, Rotation = 90,
        Color = { NewRgb(216, 126, 157), NewRgb(216, 126, 157) },
        Transparency = { 0, 0 },
        Glow = {
            Enabled = true, Rotation = 90,
            Color = { NewRgb(216, 126, 157), NewRgb(216, 126, 157) },
            Transparency = { 0.75, 0.75 },
        },
        Fill = {
            Enabled = true, Rotation = 90,
            Color = { NewRgb(216, 126, 157), NewRgb(216, 126, 157) },
            Transparency = { 1, 0.5 },
        },
    },

    Bars = {
        HealthBar = {
            Enabled = true, Position = "Left",
            Color = { NewRgb(252, 71, 77), NewRgb(255, 255, 0), NewRgb(131, 245, 78) },
            Text = { Enabled = true, FollowBar = false, Ending = "HP", Position = "Left", Color = NewRgb(255, 255, 255), Transparency = 0 },
        },
        ArmorBar = {
            Enabled = true, Position = "Bottom",
            Color = { NewRgb(52, 131, 235), NewRgb(52, 131, 235), NewRgb(52, 131, 235) },
            Type = function() return 100, 100 end,
        },
    },

    Name = { Enabled = true, UseDisplay = true, Position = "Top", Color = NewRgb(255, 255, 255), Transparency = 0 },
    Distance = { Enabled = true, Ending = "st", Position = "Bottom", Color = NewRgb(255, 255, 255), Transparency = 0 },
    Weapon = { Enabled = true, ShowNone = true, Position = "Bottom", Color = NewRgb(255, 255, 255), Transparency = 0 },
    Flags = {
        Enabled = true, Position = "Right", Color = NewRgb(255, 255, 255), Transparency = 0,
        Type = function(Speed, IsJumping)
            if IsJumping then return { "jumping" } elseif Speed > 0 then return { "moving" } end;
            return { "standing" };
        end,
    },
};

local Settings = Esp.Settings;

local function GetActiveFont() return Settings.Font == "Tahoma" and FontTahoma or FontSmall end;
local function GetFontSize() return Settings.FontSize or 12 end;

local function FormatText(Text)
    if Settings.FontType == "uppercase" then return string.upper(Text) end;
    if Settings.FontType == "lowercase" then return string.lower(Text) end;
    return Text;
end;

local BarWidth, BarGap, BarPadding = 1, 4, 1;
local BarWidthOutline = BarWidth + 2;
local BarPadding2 = BarPadding * 2;
local BarGapWidth = BarGap + BarWidth;
local ArmorBarHeight, ArmorBarHeightOutline, ArmorBarGap, ArmorBarPadding = 1, 3, 4, 1;

local function BuildGradient2(A, B) return ColorSequence.new({ ColorSequenceKeypoint.new(0, A), ColorSequenceKeypoint.new(1, B) }) end;
local function BuildGradient3(A, B, C) return ColorSequence.new({ ColorSequenceKeypoint.new(0, A), ColorSequenceKeypoint.new(0.5, B), ColorSequenceKeypoint.new(1, C) }) end;

local HealthGradient = BuildGradient3(Settings.Bars.HealthBar.Color[1], Settings.Bars.HealthBar.Color[2], Settings.Bars.HealthBar.Color[3]);
local ArmorGradient = BuildGradient3(Settings.Bars.ArmorBar.Color[1], Settings.Bars.ArmorBar.Color[2], Settings.Bars.ArmorBar.Color[3]);
local FillGradient = BuildGradient2(Settings.Box.Fill.Color[1], Settings.Box.Fill.Color[2]);
local BoxGradient = BuildGradient2(Settings.Box.Color[1], Settings.Box.Color[2]);

local GlowFadeTop = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, Settings.Box.Glow.Transparency[1]), NumberSequenceKeypoint.new(1, 1) });
local GlowFadeBottom = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, Settings.Box.Glow.Transparency[2]), NumberSequenceKeypoint.new(1, 0) });

local R15PartNames = { "Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot" };
local R6PartNames = { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" };
local R15PaddingMap = { Head = 0.05, LeftHand = 0.02, RightHand = 0.02, LeftFoot = 0.04, RightFoot = 0.04 };
local R6PaddingMap = { Head = 0.05, ["Left Leg"] = 0.03, ["Right Leg"] = 0.03 };
local BodyPartLookup = { Head = true, LeftHand = true, RightHand = true, LeftFoot = true, RightFoot = true, ["Left Arm"] = true, ["Right Arm"] = true, Torso = true, ["Left Leg"] = true, ["Right Leg"] = true };

local function MakeInstance(ClassName, Properties)
    local Object = NewInstance(ClassName);
    for Key, Value in pairs(Properties) do Object[Key] = Value end;
    return Object;
end;

local ScreenGui = NewInstance("ScreenGui");
ScreenGui.Name = "\0";
ScreenGui.ResetOnSpawn = false;
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
ScreenGui.IgnoreGuiInset = true;
ScreenGui.Parent = gethui();
Esp.ScreenGui = ScreenGui;

local function CreateStrokeFrame(Parent, StrokeColor, ZIndex)
    local Frame = MakeInstance("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = ZIndex, Visible = false, Size = NewUDim2(0,0,0,0), Parent = Parent });
    MakeInstance("UIStroke", { Color = StrokeColor, Thickness = 1, LineJoinMode = Enum.LineJoinMode.Miter, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = Frame });
    return Frame;
end;

local function CreateGradientStrokeFrame(Parent, ZIndex)
    local Frame = MakeInstance("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = ZIndex, Visible = false, Size = NewUDim2(0,0,0,0), Parent = Parent });
    local Stroke = MakeInstance("UIStroke", { Color = ColorWhite, Thickness = 1, LineJoinMode = Enum.LineJoinMode.Miter, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = Frame });
    MakeInstance("UIGradient", { Color = BoxGradient, Rotation = Settings.Box.Rotation, Parent = Stroke });
    return Frame;
end;

local function CreateSolidFrame(Parent, FillColor, ZIndex)
    return MakeInstance("Frame", { BackgroundColor3 = FillColor, BackgroundTransparency = 0, BorderSizePixel = 0, ZIndex = ZIndex, Visible = false, Size = NewUDim2(0,0,0,0), Parent = Parent });
end;

local function CreateTextLabel(Parent, ZIndex, TextColor, FontSize, Alignment)
    local IsLeft = Alignment == "Left";
    local Label = MakeInstance("TextLabel", {
        BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = false,
        ZIndex = ZIndex, Visible = false, Size = NewUDim2(0, 300, 0, FontSize + 4),
        AnchorPoint = IsLeft and NewVector2(0, 0) or NewVector2(0.5, 0),
        FontFace = GetActiveFont(), TextSize = FontSize, TextColor3 = TextColor,
        TextStrokeTransparency = 1,
        TextXAlignment = IsLeft and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextTruncate = Enum.TextTruncate.None, TextScaled = false, RichText = false,
        Text = "", Parent = Parent,
    });
    MakeInstance("UIStroke", { Color = ColorBlack, Thickness = 1, LineJoinMode = Enum.LineJoinMode.Miter, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, Parent = Label });
    return Label;
end;

local function CreateFillFrame(Parent, ZIndex)
    local Frame = MakeInstance("Frame", { BackgroundColor3 = ColorWhite, BorderSizePixel = 0, ZIndex = ZIndex, Visible = false, Size = NewUDim2(0,0,0,0), Parent = Parent });
    MakeInstance("UIGradient", {
        Color = FillGradient, Rotation = Settings.Box.Fill.Rotation,
        Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, Settings.Box.Fill.Transparency[1]), NumberSequenceKeypoint.new(1, Settings.Box.Fill.Transparency[2]) }),
        Parent = Frame,
    });
    return Frame;
end;

local function CreateGlowImage(Parent, GlowColor, FadeSequence)
    local Image = MakeInstance("ImageLabel", {
        Image = "rbxassetid://18245826428", ImageColor3 = GlowColor,
        ImageTransparency = Settings.Box.Glow.Transparency[1],
        ScaleType = Enum.ScaleType.Slice, SliceCenter = GlowSliceRect,
        BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2,
        Visible = false, Size = NewUDim2(0,0,0,0), Parent = Parent,
    });
    MakeInstance("UIGradient", { Transparency = FadeSequence, Rotation = Settings.Box.Glow.Rotation, Parent = Image });
    return Image;
end;

local function CreateBarFillFrame(Parent, GradientColor, GradientRotation)
    local Frame = MakeInstance("Frame", { BackgroundColor3 = ColorWhite, BorderSizePixel = 0, ZIndex = 11, Visible = false, Size = NewUDim2(0,0,0,0), Parent = Parent });
    MakeInstance("UIGradient", { Color = GradientColor, Rotation = GradientRotation, Parent = Frame });
    return Frame;
end;

local function CreateHighlight(TargetModel)
    if not Settings.Highlight.Enabled then return nil end;
    local Highlight = NewInstance("Highlight");
    Highlight.FillColor = Settings.Highlight.FillColor;
    Highlight.OutlineColor = Settings.Highlight.OutlineColor;
    Highlight.FillTransparency = Settings.Highlight.FillTransparency;
    Highlight.OutlineTransparency = Settings.Highlight.OutlineTransparency;
    Highlight.DepthMode = Settings.Highlight.DepthMode;
    Highlight.Adornee = TargetModel;
    Highlight.Parent = ScreenGui;
    Highlight.Enabled = true;
    return Highlight;
end;

local function ExpandScreenBounds(Depth, RightOffset, UpOffset)
    if Depth <= 0 then return end;
    local Inverse = FocalLength / Depth;
    local ScreenX = HalfViewportX + RightOffset * Inverse;
    local ScreenY = HalfViewportY - UpOffset * Inverse;
    if ScreenX < ScreenMinX then ScreenMinX = ScreenX end;
    if ScreenX > ScreenMaxX then ScreenMaxX = ScreenX end;
    if ScreenY < ScreenMinY then ScreenMinY = ScreenY end;
    if ScreenY > ScreenMaxY then ScreenMaxY = ScreenY end;
end;

local function ProjectOrientedBoundingBox(Px, Py, Pz, R00, R01, R02, R10, R11, R12, R20, R21, R22, HalfW, HalfH, HalfD)
    local AxisAX, AxisAY, AxisAZ = R00 * HalfW, R01 * HalfW, R02 * HalfW;
    local AxisBX, AxisBY, AxisBZ = R10 * HalfH, R11 * HalfH, R12 * HalfH;
    local AxisCX, AxisCY, AxisCZ = R20 * HalfD, R21 * HalfD, R22 * HalfD;
    local DeltaX, DeltaY, DeltaZ = Px - CameraPositionX, Py - CameraPositionY, Pz - CameraPositionZ;
    local OriginDepth = CameraLookX * DeltaX + CameraLookY * DeltaY + CameraLookZ * DeltaZ;
    local OriginRight = CameraRightX * DeltaX + CameraRightY * DeltaY + CameraRightZ * DeltaZ;
    local OriginUp = CameraUpX * DeltaX + CameraUpY * DeltaY + CameraUpZ * DeltaZ;
    local DepthA = CameraLookX * AxisAX + CameraLookY * AxisAY + CameraLookZ * AxisAZ;
    local RightA = CameraRightX * AxisAX + CameraRightY * AxisAY + CameraRightZ * AxisAZ;
    local UpA = CameraUpX * AxisAX + CameraUpY * AxisAY + CameraUpZ * AxisAZ;
    local DepthB = CameraLookX * AxisBX + CameraLookY * AxisBY + CameraLookZ * AxisBZ;
    local RightB = CameraRightX * AxisBX + CameraRightY * AxisBY + CameraRightZ * AxisBZ;
    local UpB = CameraUpX * AxisBX + CameraUpY * AxisBY + CameraUpZ * AxisBZ;
    local DepthC = CameraLookX * AxisCX + CameraLookY * AxisCY + CameraLookZ * AxisCZ;
    local RightC = CameraRightX * AxisCX + CameraRightY * AxisCY + CameraRightZ * AxisCZ;
    local UpC = CameraUpX * AxisCX + CameraUpY * AxisCY + CameraUpZ * AxisCZ;
    ExpandScreenBounds(OriginDepth + DepthA + DepthB + DepthC, OriginRight + RightA + RightB + RightC, OriginUp + UpA + UpB + UpC);
    ExpandScreenBounds(OriginDepth + DepthA + DepthB - DepthC, OriginRight + RightA + RightB - RightC, OriginUp + UpA + UpB - UpC);
    ExpandScreenBounds(OriginDepth + DepthA - DepthB + DepthC, OriginRight + RightA - RightB + RightC, OriginUp + UpA - UpB + UpC);
    ExpandScreenBounds(OriginDepth + DepthA - DepthB - DepthC, OriginRight + RightA - RightB - RightC, OriginUp + UpA - UpB - UpC);
    ExpandScreenBounds(OriginDepth - DepthA + DepthB + DepthC, OriginRight - RightA + RightB + RightC, OriginUp - UpA + UpB + UpC);
    ExpandScreenBounds(OriginDepth - DepthA + DepthB - DepthC, OriginRight - RightA + RightB - RightC, OriginUp - UpA + UpB - UpC);
    ExpandScreenBounds(OriginDepth - DepthA - DepthB + DepthC, OriginRight - RightA - RightB + RightC, OriginUp - UpA - UpB + UpC);
    ExpandScreenBounds(OriginDepth - DepthA - DepthB - DepthC, OriginRight - RightA - RightB - RightC, OriginUp - UpA - UpB - UpC);
end;

local function HideBoxFrames(Entry)
    Entry.OuterStroke.Visible  = false;
    Entry.BorderStroke.Visible = false;
    Entry.InnerCover.Visible   = false;
    Entry.InnerStroke.Visible  = false;
end;

local function HideFillFrame(Entry)
    Entry.BoxFill.Visible = false;
end;

local function HideGlowFrames(Entry)
    Entry.GlowTop.Visible = false;
    Entry.GlowBot.Visible = false;
end;

local function HideHealthBar(Entry)
    Entry.BarOutline.Visible    = false;
    Entry.BarBackground.Visible = false;
    Entry.BarFill.Visible       = false;
    Entry.LabelHealth.Visible   = false;
end;

local function HideArmorBar(Entry)
    Entry.ArmorOutline.Visible    = false;
    Entry.ArmorBackground.Visible = false;
    Entry.ArmorFill.Visible       = false;
end;

local function HideLabels(Entry)
    Entry.LabelName.Visible     = false;
    Entry.LabelWeapon.Visible   = false;
    Entry.LabelDistance.Visible = false;
    Entry.LabelFlags.Visible    = false;
end;

local function HideHighlight(Entry)
    if Entry.Highlight then Entry.Highlight.Enabled = false end;
end;

local function ResetPositionCache(Entry)
    Entry.PrevBoxX = -1; Entry.PrevBoxY = -1; Entry.PrevBoxW = -1; Entry.PrevBoxH = -1;
    Entry.PrevFillHeight = -1; Entry.PrevArmorFillWidth = -1;
    Entry.PrevHealthLabelX = -1; Entry.PrevHealthLabelY = -1;
    Entry.PrevNameLabelX = -1; Entry.PrevNameLabelY = -1;
    Entry.PrevWeaponLabelX = -1; Entry.PrevWeaponLabelY = -1;
    Entry.PrevDistanceLabelX = -1; Entry.PrevDistanceLabelY = -1;
    Entry.PrevDistanceValue = -1;
    Entry.PrevFlagsLabelX = -1; Entry.PrevFlagsLabelY = -1;
end;

local function ResetAllCache(Entry)
    ResetPositionCache(Entry);
    Entry.PrevHealthString = ""; Entry.PrevNameString = "";
    Entry.PrevWeaponString = "__unset__";
    Entry.PrevDistanceString = ""; Entry.PrevFlagsString = "";
end;

local function EntryHide(Entry)
    HideBoxFrames(Entry);
    HideFillFrame(Entry);
    HideGlowFrames(Entry);
    HideHealthBar(Entry);
    HideArmorBar(Entry);
    HideLabels(Entry);
    HideHighlight(Entry);
    Entry.IsVisible = false;
    ResetAllCache(Entry);
end;

local function EntryNew(Player)
    local Container = NewInstance("Frame");
    Container.Name = ToString(Player) .. "_esp";
    Container.BackgroundTransparency = 1;
    Container.BorderSizePixel = 0;
    Container.Size = NewUDim2(1, 0, 1, 0);
    Container.ZIndex = 1;
    Container.Parent = ScreenGui;

    local FontSize = GetFontSize();

    local Entry = {
        Player = Player, PlayerName = Player.Name, Container = Container,

        OuterStroke = CreateStrokeFrame(Container, ColorBlack, 4),
        BorderStroke = CreateGradientStrokeFrame(Container, 5),
        InnerCover = MakeInstance("Frame", { BackgroundColor3 = ColorBlack, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 6, Visible = false, Size = NewUDim2(0,0,0,0), Parent = Container }),
        InnerStroke = CreateStrokeFrame(Container, ColorBlack, 7),
        BoxFill = CreateFillFrame(Container, 8),

        BarOutline = CreateSolidFrame(Container, ColorBlack, 9),
        BarBackground = CreateSolidFrame(Container, ColorBarBackground, 10),
        BarFill = CreateBarFillFrame(Container, HealthGradient, 270),

        ArmorOutline = CreateSolidFrame(Container, ColorBlack, 9),
        ArmorBackground = CreateSolidFrame(Container, ColorBarBackground, 10),
        ArmorFill = CreateBarFillFrame(Container, ArmorGradient, 0),

        GlowTop = CreateGlowImage(Container, Settings.Box.Glow.Color[1], GlowFadeTop),
        GlowBot = CreateGlowImage(Container, Settings.Box.Glow.Color[2], GlowFadeBottom),

        LabelHealth = CreateTextLabel(Container, 12, Settings.Bars.HealthBar.Text.Color, FontSize, "Center"),
        LabelName = CreateTextLabel(Container, 12, Settings.Name.Color, FontSize, "Center"),
        LabelWeapon = CreateTextLabel(Container, 12, Settings.Weapon.Color, FontSize, "Center"),
        LabelDistance = CreateTextLabel(Container, 12, Settings.Distance.Color, FontSize, "Center"),
        LabelFlags = CreateTextLabel(Container, 12, Settings.Flags.Color, FontSize, "Left"),

        Highlight = nil, Character = nil, RootPart = nil, Humanoid = nil,
        IsDead = false, IsR6 = false, Health = 1, MaxHealth = 100,
        TopOffset = 3.0, BotOffset = 3.0,
        Parts = {}, PartHalfW = {}, PartHalfH = {}, PartHalfD = {}, PartCount = 0,
        CachedMoveSpeed = 0, CachedJumping = false, IsVisible = false,

        BarX = 0, BarY = 0, BarH = 0, BarLabelX = 0, BarLabelY = 0,
        ArmorBarX = 0, ArmorBarY = 0, ArmorBarW = 0,
        FlagsLabelX = 0, FlagsLabelY = 0,

        HealthString = "100", WeaponString = "none", FlagsString = "",
        PlayerConnections = {}, CharacterConnections = {},
    };

    ResetAllCache(Entry);
    return Entry;
end;

local function EntryDestroy(Entry)
    EntryHide(Entry);
    for _, Connection in ipairs(Entry.PlayerConnections) do pcall(Connection.Disconnect, Connection) end;
    for _, Connection in ipairs(Entry.CharacterConnections) do pcall(Connection.Disconnect, Connection) end;
    if Entry.Highlight then pcall(Entry.Highlight.Destroy, Entry.Highlight) end;
    pcall(Entry.Container.Destroy, Entry.Container);
end;

local function EntryBuildParts(Entry)
    local Character = Entry.Character;
    if not Character then return end;

    local PartNameList = Entry.IsR6 and R6PartNames or R15PartNames;
    local PaddingMap = Entry.IsR6 and R6PaddingMap or R15PaddingMap;
    local RootY = Entry.RootPart.Position.Y;
    local LowestY, HighestY = MathHuge, -MathHuge;
    local Parts, HalfWidths, HalfHeights, HalfDepths = {}, {}, {}, {};
    local Count = 0;

    for Index = 1, #PartNameList do
        local Part = Character:FindFirstChild(PartNameList[Index]);
        if not Part or not Part:IsA("BasePart") then continue end;
        local Padding = PaddingMap[PartNameList[Index]] or 0.04;
        local PartSize = Part.Size;
        local HalfW = PartSize.X * 0.5 + Padding;
        local HalfH = PartSize.Y * 0.5;
        local HalfD = PartSize.Z * 0.5 + Padding;
        local LocalY = Part.Position.Y - RootY;
        if LocalY + HalfH > HighestY then HighestY = LocalY + HalfH end;
        if LocalY - HalfH < LowestY then LowestY = LocalY - HalfH end;
        Count = Count + 1;
        Parts[Count] = Part; HalfWidths[Count] = HalfW; HalfHeights[Count] = HalfH; HalfDepths[Count] = HalfD;
    end;

    Entry.TopOffset = (HighestY == -MathHuge) and 3.0 or HighestY + 0.02;
    Entry.BotOffset = (LowestY == MathHuge) and 3.0 or -LowestY + 0.02;
    Entry.Parts = Parts; Entry.PartHalfW = HalfWidths; Entry.PartHalfH = HalfHeights; Entry.PartHalfD = HalfDepths; Entry.PartCount = Count;
end;

local function EntryClearCharacter(Entry)
    for _, Connection in ipairs(Entry.CharacterConnections) do pcall(Connection.Disconnect, Connection) end;
    Entry.CharacterConnections = {};
    Entry.Character = nil; Entry.RootPart = nil; Entry.Humanoid = nil; Entry.IsDead = false;
    Entry.Parts = {}; Entry.PartHalfW = {}; Entry.PartHalfH = {}; Entry.PartHalfD = {}; Entry.PartCount = 0;
    Entry.HealthString = "100"; Entry.WeaponString = "none"; Entry.FlagsString = "";
    Entry.CachedMoveSpeed = 0; Entry.CachedJumping = false;
    if Entry.Highlight then pcall(Entry.Highlight.Destroy, Entry.Highlight); Entry.Highlight = nil end;
end;

local function GetEquippedWeapon(Character)
    local Tool = Character:FindFirstChildOfClass("Tool");
    return Tool and Tool.Name or "none";
end;

local function RebuildFlagsString(Entry)
    if not Settings.Flags.Type then return end;
    local Result = Settings.Flags.Type(Entry.CachedMoveSpeed, Entry.CachedJumping);
    if type(Result) == "table" then
        Entry.FlagsString = (#Result > 0) and table.concat(Result, ", ") or "";
        Entry.PrevFlagsString = "";
    end;
end;

local function EntryLinkCharacter(Entry, Character)
    EntryClearCharacter(Entry);
    EntryHide(Entry);
    if not Character then return end;

    local RootPart = Character:WaitForChild("HumanoidRootPart", 10);
    local Humanoid = Character:WaitForChild("Humanoid", 10);
    if not RootPart or not Humanoid then return end;

    if not Character:FindFirstChild("UpperTorso") and not Character:FindFirstChild("Torso") then
        task.wait(0.5);
    end;

    Entry.IsR6 = Character:FindFirstChild("Torso") ~= nil;
    Entry.Character = Character; Entry.RootPart = RootPart; Entry.Humanoid = Humanoid;
    Entry.IsDead = false; Entry.MaxHealth = Humanoid.MaxHealth;
    Entry.Health = MathClamp(Humanoid.Health / Humanoid.MaxHealth, 0, 1);
    Entry.HealthString = ToString(MathFloor(Humanoid.Health));
    Entry.CachedMoveSpeed = Humanoid.MoveDirection.Magnitude;
    Entry.CachedJumping = Humanoid.Jump;
    Entry.WeaponString = GetEquippedWeapon(Character);
    RebuildFlagsString(Entry);

    if Settings.Highlight.Enabled then
        if Entry.Highlight then pcall(Entry.Highlight.Destroy, Entry.Highlight) end;
        Entry.Highlight = CreateHighlight(Character);
    end;

    local CharConnections = Entry.CharacterConnections;

    CharConnections[#CharConnections + 1] = Humanoid.HealthChanged:Connect(function(NewHealth)
        Entry.Health = MathClamp(NewHealth / Entry.MaxHealth, 0, 1);
        Entry.HealthString = ToString(MathFloor(NewHealth));
        Entry.PrevFillHeight = -1; Entry.PrevHealthString = "";
    end);

    CharConnections[#CharConnections + 1] = Humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
        Entry.MaxHealth = Humanoid.MaxHealth;
    end);

    CharConnections[#CharConnections + 1] = Humanoid.Died:Connect(function()
        Entry.IsDead = true;
        if Entry.Highlight then Entry.Highlight.Enabled = false end;
        EntryHide(Entry);
    end);

    CharConnections[#CharConnections + 1] = Humanoid.StateChanged:Connect(function(_, NewState)
        Entry.CachedJumping = NewState == Enum.HumanoidStateType.Jumping or NewState == Enum.HumanoidStateType.Freefall;
        RebuildFlagsString(Entry);
    end);

    CharConnections[#CharConnections + 1] = Humanoid.Running:Connect(function(Speed)
        Entry.CachedMoveSpeed = Speed; RebuildFlagsString(Entry);
    end);

    CharConnections[#CharConnections + 1] = Character.ChildAdded:Connect(function(Child)
        if Child:IsA("Tool") then Entry.WeaponString = Child.Name; Entry.PrevWeaponString = "__unset__" end;
    end);

    CharConnections[#CharConnections + 1] = Character.ChildRemoved:Connect(function(Child)
        if Child:IsA("Tool") then Entry.WeaponString = GetEquippedWeapon(Character); Entry.PrevWeaponString = "__unset__" end;
    end);

    CharConnections[#CharConnections + 1] = Character.DescendantAdded:Connect(function(Descendant)
        if not Descendant:IsA("BasePart") or not BodyPartLookup[Descendant.Name] then return end;
        local Parent = Descendant.Parent;
        while Parent and Parent ~= Character do
            if Parent:IsA("Tool") then return end;
            Parent = Parent.Parent;
        end;
        task.defer(EntryBuildParts, Entry);
    end);

    CharConnections[#CharConnections + 1] = Character.DescendantRemoving:Connect(function(Descendant)
        if Descendant:IsA("BasePart") and BodyPartLookup[Descendant.Name] then
            task.defer(EntryBuildParts, Entry);
        end;
    end);

    EntryBuildParts(Entry);
end;

function Esp:Add(Player)
    if Player == LocalPlayer then return end;
    if self.Cache[Player] then EntryDestroy(self.Cache[Player]) end;

    local Entry = EntryNew(Player);
    self.Cache[Player] = Entry;
    self.List[#self.List + 1] = Entry;

    local PlayerConnections = Entry.PlayerConnections;
    PlayerConnections[#PlayerConnections + 1] = Player.CharacterAdded:Connect(function(NewCharacter)
        task.spawn(EntryLinkCharacter, Entry, NewCharacter);
    end);
    PlayerConnections[#PlayerConnections + 1] = Player.CharacterRemoving:Connect(function()
        Entry.Character = nil; Entry.RootPart = nil;
        if Entry.Highlight then Entry.Highlight.Enabled = false end;
        EntryHide(Entry);
    end);

    if Player.Character then task.spawn(EntryLinkCharacter, Entry, Player.Character) end;
end;

function Esp:Remove(Player)
    local Entry = self.Cache[Player];
    if not Entry then return end;
    self.Cache[Player] = nil;
    local List = self.List;
    for Index = 1, #List do
        if List[Index] == Entry then List[Index] = List[#List]; List[#List] = nil; break end;
    end;
    EntryDestroy(Entry);
end;

local function OnLocalCharacterAdded(Character)
    Esp.LocalRoot = Character and Character:WaitForChild("HumanoidRootPart", 5) or nil;
end;
if LocalPlayer.Character then task.spawn(OnLocalCharacterAdded, LocalPlayer.Character) end;
Esp.Connections[#Esp.Connections + 1] = LocalPlayer.CharacterAdded:Connect(OnLocalCharacterAdded);
Esp.Connections[#Esp.Connections + 1] = LocalPlayer.CharacterRemoving:Connect(function() Esp.LocalRoot = nil end);

local NameOffset = -18;
local WeaponOffset = 19;
local DistanceOffset = 8;
local HealthOffset = -3;
local FlagsOffset = -2;
local CullDistanceSquared = 9e9;
local LodDistanceSquared = 300 * 300;
local DeltaAccumulator = 0;
local TargetFrameTime = 1 / 60;

local function UpdateBoxFrame(Entry, BoxX, BoxY, BoxW, BoxH)
    Entry.OuterStroke.Visible = true;
    Entry.OuterStroke.Position = NewUDim2(0, BoxX - 1, 0, BoxY - 1);
    Entry.OuterStroke.Size = NewUDim2(0, BoxW + 2, 0, BoxH + 2);
    Entry.BorderStroke.Visible = true;
    Entry.BorderStroke.Position = NewUDim2(0, BoxX, 0, BoxY);
    Entry.BorderStroke.Size = NewUDim2(0, BoxW, 0, BoxH);
    Entry.InnerCover.Visible = true;
    Entry.InnerCover.Position = NewUDim2(0, BoxX + 1, 0, BoxY + 1);
    Entry.InnerCover.Size = NewUDim2(0, BoxW - 2, 0, BoxH - 2);
    Entry.InnerStroke.Visible = true;
    Entry.InnerStroke.Position = NewUDim2(0, BoxX + 1, 0, BoxY + 1);
    Entry.InnerStroke.Size = NewUDim2(0, BoxW - 2, 0, BoxH - 2);
end;

local function UpdateFillFrame(Entry, BoxX, BoxY, BoxW, BoxH)
    Entry.BoxFill.Visible = true;
    Entry.BoxFill.Position = NewUDim2(0, BoxX + 1, 0, BoxY + 1);
    Entry.BoxFill.Size = NewUDim2(0, BoxW - 2, 0, BoxH - 2);
end;

local function UpdateGlowFrames(Entry, BoxX, BoxY, BoxW, BoxH)
    local GlowX, GlowY = BoxX - GlowPadding, BoxY - GlowPadding;
    local GlowW, GlowH = BoxW + GlowPadding2, BoxH + GlowPadding2;
    local Position = NewUDim2(0, GlowX, 0, GlowY);
    local Size = NewUDim2(0, GlowW, 0, GlowH);
    Entry.GlowTop.Visible = true; Entry.GlowTop.Position = Position; Entry.GlowTop.Size = Size;
    Entry.GlowBot.Visible = true; Entry.GlowBot.Position = Position; Entry.GlowBot.Size = Size;
end;

local function ProjectLodFallback(DepthDistance, RightDistance, UpDistance, EntryTop, EntryBot, BoxHalfWidth)
    local InverseFocal;
    local TopDepth = DepthDistance + CameraLookY * EntryTop;
    if TopDepth > 0 then
        InverseFocal = FocalLength / TopDepth;
        local SL = HalfViewportX + (RightDistance - BoxHalfWidth) * InverseFocal;
        local SR = HalfViewportX + (RightDistance + BoxHalfWidth) * InverseFocal;
        local SY = HalfViewportY - (UpDistance + EntryTop) * InverseFocal;
        if SL < ScreenMinX then ScreenMinX = SL end; if SR > ScreenMaxX then ScreenMaxX = SR end;
        if SY < ScreenMinY then ScreenMinY = SY end; if SY > ScreenMaxY then ScreenMaxY = SY end;
    end;
    local BottomDepth = DepthDistance - CameraLookY * EntryBot;
    if BottomDepth > 0 then
        InverseFocal = FocalLength / BottomDepth;
        local SL = HalfViewportX + (RightDistance - BoxHalfWidth) * InverseFocal;
        local SR = HalfViewportX + (RightDistance + BoxHalfWidth) * InverseFocal;
        local SY = HalfViewportY - (UpDistance - EntryBot) * InverseFocal;
        if SL < ScreenMinX then ScreenMinX = SL end; if SR > ScreenMaxX then ScreenMaxX = SR end;
        if SY < ScreenMinY then ScreenMinY = SY end; if SY > ScreenMaxY then ScreenMaxY = SY end;
    end;
    if DepthDistance > 0 then
        InverseFocal = FocalLength / DepthDistance;
        local SL = HalfViewportX + (RightDistance - BoxHalfWidth) * InverseFocal;
        local SR = HalfViewportX + (RightDistance + BoxHalfWidth) * InverseFocal;
        local SM = HalfViewportY - UpDistance * InverseFocal;
        if SL < ScreenMinX then ScreenMinX = SL end; if SR > ScreenMaxX then ScreenMaxX = SR end;
        if SM < ScreenMinY then ScreenMinY = SM end; if SM > ScreenMaxY then ScreenMaxY = SM end;
    end;
end;

Esp.Connections[#Esp.Connections + 1] = ServiceRunService.RenderStepped:Connect(function(DeltaTime)
    DeltaAccumulator = DeltaAccumulator + DeltaTime;
    if DeltaAccumulator < TargetFrameTime then return end;
    DeltaAccumulator = DeltaAccumulator - TargetFrameTime;

    local CameraFrame = Camera.CFrame;
    local ViewportSize = Camera.ViewportSize;
    local RightVector = CameraFrame.RightVector;
    local UpVector = CameraFrame.UpVector;
    local LookVector = CameraFrame.LookVector;
    local CameraPosition = CameraFrame.Position;

    CameraRightX = RightVector.X; CameraRightY = RightVector.Y; CameraRightZ = RightVector.Z;
    CameraUpX = UpVector.X; CameraUpY = UpVector.Y; CameraUpZ = UpVector.Z;
    CameraLookX = LookVector.X; CameraLookY = LookVector.Y; CameraLookZ = LookVector.Z;
    CameraPositionX = CameraPosition.X; CameraPositionY = CameraPosition.Y; CameraPositionZ = CameraPosition.Z;
    HalfViewportX = ViewportSize.X * 0.5;
    HalfViewportY = ViewportSize.Y * 0.5;
    FocalLength = HalfViewportY / MathTan(MathRad(Camera.FieldOfView * 0.5));

    local LocalPlayerRoot = Esp.LocalRoot;
    local LocalX, LocalY, LocalZ = 0, 0, 0;
    local HasLocalPlayer = LocalPlayerRoot ~= nil;
    if HasLocalPlayer then
        local LP = LocalPlayerRoot.Position;
        LocalX = LP.X; LocalY = LP.Y; LocalZ = LP.Z;
    end;

    local EspEnabled         = Settings.Enabled;
    local BoxEnabled         = Settings.Box.Enabled;
    local FillEnabled        = Settings.Box.Fill.Enabled;
    local GlowEnabled        = Settings.Box.Glow.Enabled;
    local HighlightEnabled   = Settings.Highlight.Enabled;
    local HealthBarEnabled   = Settings.Bars.HealthBar.Enabled;
    local HealthTextEnabled  = Settings.Bars.HealthBar.Text.Enabled;
    local ArmorBarEnabled    = Settings.Bars.ArmorBar.Enabled;
    local ArmorTypeFn        = Settings.Bars.ArmorBar.Type;
    local NameEnabled        = Settings.Name.Enabled;
    local WeaponEnabled      = Settings.Weapon.Enabled;
    local WeaponShowNone     = Settings.Weapon.ShowNone;
    local DistanceEnabled    = Settings.Distance.Enabled;
    local FlagsEnabled       = Settings.Flags.Enabled;

    local List = Esp.List;

    for ListIndex = 1, #List do
        local Entry = List[ListIndex];

        if not EspEnabled then
            EntryHide(Entry);
            continue;
        end;

        if Entry.IsDead or not Entry.RootPart or not Entry.Character then
            EntryHide(Entry); continue;
        end;

        local RootPosition = Entry.RootPart.Position;
        local RootX, RootY, RootZ = RootPosition.X, RootPosition.Y, RootPosition.Z;

        if HasLocalPlayer then
            local DeltaX, DeltaY, DeltaZ = RootX - LocalX, RootY - LocalY, RootZ - LocalZ;
            if DeltaX * DeltaX + DeltaY * DeltaY + DeltaZ * DeltaZ > CullDistanceSquared then
                EntryHide(Entry); continue;
            end;
        end;

        local FrontDot = (RootX - CameraPositionX) * CameraLookX + (RootY - CameraPositionY) * CameraLookY + (RootZ - CameraPositionZ) * CameraLookZ;
        if FrontDot < 0 then EntryHide(Entry); continue end;

        if Entry.Highlight then
            Entry.Highlight.Enabled = HighlightEnabled;
        elseif HighlightEnabled and Entry.Character then
            Entry.Highlight = CreateHighlight(Entry.Character);
        end;

        ScreenMinX = MathHuge; ScreenMinY = MathHuge; ScreenMaxX = -MathHuge; ScreenMaxY = -MathHuge;

        local CameraDeltaX = RootX - CameraPositionX;
        local CameraDeltaY = RootY - CameraPositionY;
        local CameraDeltaZ = RootZ - CameraPositionZ;
        local CameraDistSq = CameraDeltaX * CameraDeltaX + CameraDeltaY * CameraDeltaY + CameraDeltaZ * CameraDeltaZ;

        if Entry.PartCount == 0 or CameraDistSq > LodDistanceSquared then
            local DepthDist = CameraLookX * CameraDeltaX + CameraLookY * CameraDeltaY + CameraLookZ * CameraDeltaZ;
            local RightDist = CameraRightX * CameraDeltaX + CameraRightY * CameraDeltaY + CameraRightZ * CameraDeltaZ;
            local UpDist = CameraUpX * CameraDeltaX + CameraUpY * CameraDeltaY + CameraUpZ * CameraDeltaZ;
            local BoxHalf = MathClamp(MathSqrt(CameraDistSq) * 0.018, 1.2, 2.2);
            ProjectLodFallback(DepthDist, RightDist, UpDist, Entry.TopOffset, Entry.BotOffset, BoxHalf);
        else
            local EntryParts = Entry.Parts;
            local EntryHalfW = Entry.PartHalfW;
            local EntryHalfH = Entry.PartHalfH;
            local EntryHalfD = Entry.PartHalfD;
            for PartIndex = 1, Entry.PartCount do
                local Part = EntryParts[PartIndex];
                if not Part or not Part.Parent then continue end;
                local CX, CY, CZ, M00, M01, M02, M10, M11, M12, M20, M21, M22 = Part.CFrame:GetComponents();
                ProjectOrientedBoundingBox(CX, CY, CZ, M00, M01, M02, M10, M11, M12, M20, M21, M22, EntryHalfW[PartIndex], EntryHalfH[PartIndex], EntryHalfD[PartIndex]);
            end;
        end;

        if ScreenMinX == MathHuge then EntryHide(Entry); continue end;

        local BoxX = MathFloor(ScreenMinX);
        local BoxY = MathFloor(ScreenMinY);
        local BoxW = MathMax(MathFloor(ScreenMaxX - ScreenMinX), 0);
        local BoxH = MathMax(MathFloor(ScreenMaxY - ScreenMinY), 0);
        local BoxCenterX = BoxX + MathFloor(BoxW * 0.5);
        local BoxRight = BoxX + BoxW;
        local BoxBottom = BoxY + BoxH;
        Entry.IsVisible = true;

        local IsDirty = BoxX ~= Entry.PrevBoxX or BoxY ~= Entry.PrevBoxY or BoxW ~= Entry.PrevBoxW or BoxH ~= Entry.PrevBoxH;

        if IsDirty then
            Entry.PrevBoxX = BoxX; Entry.PrevBoxY = BoxY; Entry.PrevBoxW = BoxW; Entry.PrevBoxH = BoxH;
            ResetPositionCache(Entry);
            Entry.PrevBoxX = BoxX; Entry.PrevBoxY = BoxY; Entry.PrevBoxW = BoxW; Entry.PrevBoxH = BoxH;

            if BoxEnabled then
                UpdateBoxFrame(Entry, BoxX, BoxY, BoxW, BoxH);
            else
                HideBoxFrames(Entry);
            end;

            if BoxEnabled and FillEnabled then
                UpdateFillFrame(Entry, BoxX, BoxY, BoxW, BoxH);
            else
                HideFillFrame(Entry);
            end;

            if BoxEnabled and GlowEnabled then
                UpdateGlowFrames(Entry, BoxX, BoxY, BoxW, BoxH);
            else
                HideGlowFrames(Entry);
            end;

            if HealthBarEnabled then
                local HealthBarX = BoxX - BarGapWidth;
                local HealthBarY = BoxY - BarPadding;
                local HealthBarH = BoxH + BarPadding2;
                Entry.BarX = HealthBarX; Entry.BarY = HealthBarY; Entry.BarH = HealthBarH;
                Entry.BarLabelX = HealthBarX - 14; Entry.BarLabelY = HealthBarY;
                Entry.BarOutline.Visible = true;
                Entry.BarOutline.Position = NewUDim2(0, HealthBarX - 1, 0, HealthBarY - 1);
                Entry.BarOutline.Size = NewUDim2(0, BarWidthOutline, 0, HealthBarH + 2);
                Entry.BarBackground.Visible = true;
                Entry.BarBackground.Position = NewUDim2(0, HealthBarX, 0, HealthBarY);
                Entry.BarBackground.Size = NewUDim2(0, BarWidth, 0, HealthBarH);
            else
                HideHealthBar(Entry);
            end;

            if ArmorBarEnabled then
                local ArmorX = BoxX - ArmorBarPadding;
                local ArmorY = BoxBottom + ArmorBarGap;
                local ArmorW = BoxW + ArmorBarPadding * 2;
                Entry.ArmorBarX = ArmorX; Entry.ArmorBarY = ArmorY; Entry.ArmorBarW = ArmorW;
                Entry.ArmorOutline.Visible = true;
                Entry.ArmorOutline.Position = NewUDim2(0, ArmorX - 1, 0, ArmorY - 1);
                Entry.ArmorOutline.Size = NewUDim2(0, ArmorW + 2, 0, ArmorBarHeightOutline);
                Entry.ArmorBackground.Visible = true;
                Entry.ArmorBackground.Position = NewUDim2(0, ArmorX, 0, ArmorY);
                Entry.ArmorBackground.Size = NewUDim2(0, ArmorW, 0, ArmorBarHeight);
            else
                HideArmorBar(Entry);
            end;

            if FlagsEnabled then
                Entry.FlagsLabelX = BoxRight + BarGapWidth;
                Entry.FlagsLabelY = BoxY;
            end;
        else
            if not BoxEnabled then HideBoxFrames(Entry) end;
            if not BoxEnabled or not FillEnabled then HideFillFrame(Entry) end;
            if not BoxEnabled or not GlowEnabled then HideGlowFrames(Entry) end;
            if not HealthBarEnabled then HideHealthBar(Entry) end;
            if not ArmorBarEnabled then HideArmorBar(Entry) end;
        end;

        if HealthBarEnabled then
            local FillHeight = MathMax(MathFloor(Entry.BarH * Entry.Health), 1);
            if FillHeight ~= Entry.PrevFillHeight then
                Entry.PrevFillHeight = FillHeight;
                Entry.BarFill.Visible = true;
                Entry.BarFill.Position = NewUDim2(0, Entry.BarX, 0, Entry.BarY + (Entry.BarH - FillHeight));
                Entry.BarFill.Size = NewUDim2(0, BarWidth, 0, FillHeight);
            end;

            if HealthTextEnabled then
                local HealthStr = Entry.HealthString;
                local HLX, HLY = Entry.BarLabelX, Entry.BarLabelY;
                if HealthStr ~= Entry.PrevHealthString or HLX ~= Entry.PrevHealthLabelX or HLY ~= Entry.PrevHealthLabelY then
                    Entry.PrevHealthString = HealthStr; Entry.PrevHealthLabelX = HLX; Entry.PrevHealthLabelY = HLY;
                    Entry.LabelHealth.Visible = true;
                    Entry.LabelHealth.Text = HealthStr;
                    Entry.LabelHealth.Position = NewUDim2(0, HLX + 1, 0, HLY + HealthOffset);
                end;
            else
                Entry.LabelHealth.Visible = false;
            end;
        end;

        if ArmorBarEnabled and ArmorTypeFn then
            local CurrentArmor, MaxArmor = ArmorTypeFn(Entry.Character);
            local ArmorRatio = (MaxArmor and MaxArmor > 0) and MathClamp(CurrentArmor / MaxArmor, 0, 1) or 1;
            local ArmorFillW = MathMax(MathFloor(Entry.ArmorBarW * ArmorRatio), 1);
            if ArmorFillW ~= Entry.PrevArmorFillWidth then
                Entry.PrevArmorFillWidth = ArmorFillW;
                Entry.ArmorFill.Visible = true;
                Entry.ArmorFill.Position = NewUDim2(0, Entry.ArmorBarX, 0, Entry.ArmorBarY);
                Entry.ArmorFill.Size = NewUDim2(0, ArmorFillW, 0, ArmorBarHeight);
            end;
        end;

        if NameEnabled then
            local NX, NY = BoxCenterX, BoxY + NameOffset;
            local NameStr = Entry.PlayerName;
            if NameStr ~= Entry.PrevNameString or NX ~= Entry.PrevNameLabelX or NY ~= Entry.PrevNameLabelY then
                Entry.PrevNameString = NameStr; Entry.PrevNameLabelX = NX; Entry.PrevNameLabelY = NY;
                Entry.LabelName.Visible = true;
                Entry.LabelName.Text = FormatText(NameStr);
                Entry.LabelName.Position = NewUDim2(0, NX, 0, NY);
            end;
        else
            Entry.LabelName.Visible = false;
        end;

        if WeaponEnabled then
            local WX = BoxCenterX;
            local WY = ArmorBarEnabled and (BoxBottom + ArmorBarGap + ArmorBarHeight + 2 + WeaponOffset) or (BoxBottom + WeaponOffset);
            local WStr = Entry.WeaponString;
            if WStr ~= Entry.PrevWeaponString or WX ~= Entry.PrevWeaponLabelX or WY ~= Entry.PrevWeaponLabelY then
                Entry.PrevWeaponString = WStr; Entry.PrevWeaponLabelX = WX; Entry.PrevWeaponLabelY = WY;
                Entry.LabelWeapon.Visible = (WStr ~= "none") or WeaponShowNone;
                Entry.LabelWeapon.Text = FormatText(WStr);
                Entry.LabelWeapon.Position = NewUDim2(0, WX + 1, 0, WY - 6);
            end;
        else
            Entry.LabelWeapon.Visible = false;
        end;

        if DistanceEnabled and HasLocalPlayer then
            local DDX, DDY, DDZ = RootX - LocalX, RootY - LocalY, RootZ - LocalZ;
            local DistSq = DDX * DDX + DDY * DDY + DDZ * DDZ;
            local DLX, DLY = BoxCenterX, BoxBottom + DistanceOffset;
            local PrevDist = Entry.PrevDistanceValue;
            local CurDist;
            if PrevDist < 0 or DistSq < (PrevDist - 0.5) * (PrevDist - 0.5) or DistSq > (PrevDist + 0.5) * (PrevDist + 0.5) then
                CurDist = MathFloor(MathSqrt(DistSq));
            else
                CurDist = PrevDist;
            end;
            if CurDist ~= Entry.PrevDistanceValue or DLX ~= Entry.PrevDistanceLabelX or DLY ~= Entry.PrevDistanceLabelY then
                local DStr = (CurDist ~= Entry.PrevDistanceValue) and (ToString(CurDist) .. Settings.Distance.Ending) or Entry.PrevDistanceString;
                Entry.PrevDistanceValue = CurDist; Entry.PrevDistanceString = DStr;
                Entry.PrevDistanceLabelX = DLX; Entry.PrevDistanceLabelY = DLY;
                Entry.LabelDistance.Visible = true;
                Entry.LabelDistance.Text = DStr;
                Entry.LabelDistance.Position = NewUDim2(0, DLX, 0, DLY);
            end;
        else
            Entry.LabelDistance.Visible = false;
        end;

        if FlagsEnabled then
            local FStr = Entry.FlagsString;
            local FX, FY = Entry.FlagsLabelX, Entry.FlagsLabelY + FlagsOffset;
            if FStr ~= Entry.PrevFlagsString or FX ~= Entry.PrevFlagsLabelX or FY ~= Entry.PrevFlagsLabelY then
                Entry.PrevFlagsString = FStr; Entry.PrevFlagsLabelX = FX; Entry.PrevFlagsLabelY = FY;
                Entry.LabelFlags.Visible = FStr ~= "";
                Entry.LabelFlags.Text = FormatText(FStr);
                Entry.LabelFlags.Position = NewUDim2(0, FX + 2, 0, FY - 4);
            end;
        else
            Entry.LabelFlags.Visible = false;
        end;
    end;
end);

for _, Player in ipairs(ServicePlayers:GetPlayers()) do task.spawn(function() Esp:Add(Player) end) end;
Esp.Connections[#Esp.Connections + 1] = ServicePlayers.PlayerAdded:Connect(function(Player) Esp:Add(Player) end);
Esp.Connections[#Esp.Connections + 1] = ServicePlayers.PlayerRemoving:Connect(function(Player) task.delay(0.1, function() Esp:Remove(Player) end) end);

local BotFolder = workspace:FindFirstChild("Bots");
if BotFolder then
    local BotCache = {};

    local function AddBot(Model)
        if not Model:IsA("Model") or BotCache[Model] then return end;
        local Entry = EntryNew({ Name = Model.Name });
        Entry.PlayerName = Model.Name;
        BotCache[Model] = Entry;
        Esp.List[#Esp.List + 1] = Entry;
        task.spawn(EntryLinkCharacter, Entry, Model);
    end;

    local function RemoveBot(Model)
        local Entry = BotCache[Model];
        if not Entry then return end;
        BotCache[Model] = nil;
        local List = Esp.List;
        for Index = 1, #List do
            if List[Index] == Entry then List[Index] = List[#List]; List[#List] = nil; break end;
        end;
        EntryDestroy(Entry);
    end;

    for _, Bot in ipairs(BotFolder:GetChildren()) do task.spawn(AddBot, Bot) end;
    Esp.Connections[#Esp.Connections + 1] = BotFolder.ChildAdded:Connect(AddBot);
    Esp.Connections[#Esp.Connections + 1] = BotFolder.ChildRemoved:Connect(RemoveBot);
end;

return Esp;
