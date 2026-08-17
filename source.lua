--[[
    Rayfield Ultimate - Custom UI Library
    Version: 1.0.0
    Author: justsadnyx
    Repository: https://gitlab.com/justsadnyx/Rayfield-Ultimate
    
    Features:
    - Script Hub with favorites
    - Theme Engine (presets + custom)
    - Key System
    - Console / Output
    - Notifications
    - Enhanced Window (draggable, minimizable, resizable)
    - Auto-update from GitLab
    - Session management + shutdown
--]]

local Rayfield = {}
Rayfield.__index = Rayfield

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

-- Config
local VERSION = "1.0.0"
local REPO_URL = "https://gitlab.com/justsadnyx/Rayfield-Ultimate"
local RAW_URL = REPO_URL .. "/-/raw/main"
local UPDATE_CHECK_INTERVAL = 300
local CONFIG_FOLDER = "RayfieldU_Config"

-- State
local ActiveWindow = nil
local Notifications = {}
local ConsoleLines = {}
local ScriptHubData = {}
local SessionActive = true
local LastUpdateCheck = 0

-- ============================================================
-- UTILITIES
-- ============================================================

local function Create(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" and k ~= "Children" then
            pcall(function() inst[k] = v end)
        end
    end
    if props.Children then
        for _, child in ipairs(props.Children) do
            child.Parent = inst
        end
    end
    if props.Parent then
        inst.Parent = props.Parent
    end
    return inst
end

local function Tween(obj, info, goals)
    return TweenService:Create(obj, TweenInfo.new(unpack(info)), goals):Play()
end

local function Round(num, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

local function GetConfigPath()
    return CONFIG_FOLDER
end

local function SaveConfig(name, data)
    pcall(function()
        if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
        writefile(CONFIG_FOLDER .. "/" .. name .. ".json", HttpService:JSONEncode(data))
    end)
end

local function LoadConfig(name)
    local success, result = pcall(function()
        if not isfolder(CONFIG_FOLDER) then return nil end
        if not isfile(CONFIG_FOLDER .. "/" .. name .. ".json") then return nil end
        return HttpService:JSONDecode(readfile(CONFIG_FOLDER .. "/" .. name .. ".json"))
    end)
    return success and result or nil
end

-- ============================================================
-- THEME ENGINE
-- ============================================================

local Themes = {}

Themes.Default = {
    Name = "Default",
    Background = Color3.fromRGB(25, 25, 35),
    TabBackground = Color3.fromRGB(30, 30, 45),
    TabActive = Color3.fromRGB(90, 70, 255),
    ElementBackground = Color3.fromRGB(35, 35, 50),
    ElementHover = Color3.fromRGB(45, 45, 65),
    Accent = Color3.fromRGB(90, 70, 255),
    AccentDark = Color3.fromRGB(60, 45, 200),
    Text = Color3.fromRGB(255, 255, 255),
    SubText = Color3.fromRGB(160, 160, 180),
    Outline = Color3.fromRGB(50, 50, 70),
    Success = Color3.fromRGB(80, 200, 120),
    Warning = Color3.fromRGB(255, 180, 60),
    Error = Color3.fromRGB(255, 80, 80),
    Info = Color3.fromRGB(80, 160, 255),
    Notification = {
        Background = Color3.fromRGB(30, 30, 45),
        Accent = Color3.fromRGB(90, 70, 255),
        Success = Color3.fromRGB(80, 200, 120),
        Warning = Color3.fromRGB(255, 180, 60),
        Error = Color3.fromRGB(255, 80, 80),
        Info = Color3.fromRGB(80, 160, 255),
    },
    Console = {
        Background = Color3.fromRGB(15, 15, 25),
        Text = Color3.fromRGB(180, 255, 180),
        Error = Color3.fromRGB(255, 100, 100),
        Warn = Color3.fromRGB(255, 255, 100),
    }
}

Themes.Dark = {
    Name = "Dark",
    Background = Color3.fromRGB(18, 18, 18),
    TabBackground = Color3.fromRGB(25, 25, 25),
    TabActive = Color3.fromRGB(200, 50, 50),
    ElementBackground = Color3.fromRGB(30, 30, 30),
    ElementHover = Color3.fromRGB(40, 40, 40),
    Accent = Color3.fromRGB(200, 50, 50),
    AccentDark = Color3.fromRGB(150, 30, 30),
    Text = Color3.fromRGB(240, 240, 240),
    SubText = Color3.fromRGB(140, 140, 140),
    Outline = Color3.fromRGB(45, 45, 45),
    Success = Color3.fromRGB(50, 180, 80),
    Warning = Color3.fromRGB(255, 160, 30),
    Error = Color3.fromRGB(255, 60, 60),
    Info = Color3.fromRGB(60, 140, 255),
    Notification = {
        Background = Color3.fromRGB(25, 25, 25),
        Accent = Color3.fromRGB(200, 50, 50),
        Success = Color3.fromRGB(50, 180, 80),
        Warning = Color3.fromRGB(255, 160, 30),
        Error = Color3.fromRGB(255, 60, 60),
        Info = Color3.fromRGB(60, 140, 255),
    },
    Console = {
        Background = Color3.fromRGB(10, 10, 10),
        Text = Color3.fromRGB(200, 200, 200),
        Error = Color3.fromRGB(255, 80, 80),
        Warn = Color3.fromRGB(255, 220, 80),
    }
}

Themes.Neon = {
    Name = "Neon",
    Background = Color3.fromRGB(15, 5, 30),
    TabBackground = Color3.fromRGB(25, 10, 45),
    TabActive = Color3.fromRGB(255, 0, 255),
    ElementBackground = Color3.fromRGB(30, 15, 50),
    ElementHover = Color3.fromRGB(45, 20, 70),
    Accent = Color3.fromRGB(255, 0, 255),
    AccentDark = Color3.fromRGB(180, 0, 180),
    Text = Color3.fromRGB(255, 200, 255),
    SubText = Color3.fromRGB(180, 130, 200),
    Outline = Color3.fromRGB(60, 20, 90),
    Success = Color3.fromRGB(0, 255, 150),
    Warning = Color3.fromRGB(255, 255, 0),
    Error = Color3.fromRGB(255, 0, 100),
    Info = Color3.fromRGB(0, 200, 255),
    Notification = {
        Background = Color3.fromRGB(25, 10, 45),
        Accent = Color3.fromRGB(255, 0, 255),
        Success = Color3.fromRGB(0, 255, 150),
        Warning = Color3.fromRGB(255, 255, 0),
        Error = Color3.fromRGB(255, 0, 100),
        Info = Color3.fromRGB(0, 200, 255),
    },
    Console = {
        Background = Color3.fromRGB(5, 0, 15),
        Text = Color3.fromRGB(0, 255, 150),
        Error = Color3.fromRGB(255, 50, 100),
        Warn = Color3.fromRGB(255, 255, 100),
    }
}

Themes.Ocean = {
    Name = "Ocean",
    Background = Color3.fromRGB(10, 20, 35),
    TabBackground = Color3.fromRGB(15, 30, 50),
    TabActive = Color3.fromRGB(30, 120, 200),
    ElementBackground = Color3.fromRGB(20, 40, 65),
    ElementHover = Color3.fromRGB(30, 55, 85),
    Accent = Color3.fromRGB(30, 140, 220),
    AccentDark = Color3.fromRGB(20, 100, 180),
    Text = Color3.fromRGB(200, 230, 255),
    SubText = Color3.fromRGB(120, 160, 200),
    Outline = Color3.fromRGB(30, 60, 90),
    Success = Color3.fromRGB(40, 200, 150),
    Warning = Color3.fromRGB(255, 200, 80),
    Error = Color3.fromRGB(255, 90, 90),
    Info = Color3.fromRGB(60, 180, 255),
    Notification = {
        Background = Color3.fromRGB(15, 30, 50),
        Accent = Color3.fromRGB(30, 140, 220),
        Success = Color3.fromRGB(40, 200, 150),
        Warning = Color3.fromRGB(255, 200, 80),
        Error = Color3.fromRGB(255, 90, 90),
        Info = Color3.fromRGB(60, 180, 255),
    },
    Console = {
        Background = Color3.fromRGB(5, 12, 25),
        Text = Color3.fromRGB(100, 220, 255),
        Error = Color3.fromRGB(255, 100, 100),
        Warn = Color3.fromRGB(255, 240, 100),
    }
}

Themes.Mint = {
    Name = "Mint",
    Background = Color3.fromRGB(15, 30, 25),
    TabBackground = Color3.fromRGB(20, 40, 35),
    TabActive = Color3.fromRGB(0, 210, 150),
    ElementBackground = Color3.fromRGB(25, 50, 42),
    ElementHover = Color3.fromRGB(35, 65, 55),
    Accent = Color3.fromRGB(0, 210, 150),
    AccentDark = Color3.fromRGB(0, 160, 110),
    Text = Color3.fromRGB(200, 255, 230),
    SubText = Color3.fromRGB(120, 180, 160),
    Outline = Color3.fromRGB(35, 65, 55),
    Success = Color3.fromRGB(0, 230, 130),
    Warning = Color3.fromRGB(255, 210, 70),
    Error = Color3.fromRGB(255, 85, 85),
    Info = Color3.fromRGB(70, 200, 255),
    Notification = {
        Background = Color3.fromRGB(20, 40, 35),
        Accent = Color3.fromRGB(0, 210, 150),
        Success = Color3.fromRGB(0, 230, 130),
        Warning = Color3.fromRGB(255, 210, 70),
        Error = Color3.fromRGB(255, 85, 85),
        Info = Color3.fromRGB(70, 200, 255),
    },
    Console = {
        Background = Color3.fromRGB(8, 18, 14),
        Text = Color3.fromRGB(120, 255, 200),
        Error = Color3.fromRGB(255, 90, 90),
        Warn = Color3.fromRGB(255, 250, 120),
    }
}

-- ============================================================
-- KEY SYSTEM
-- ============================================================

local KeySystem = {}
KeySystem.__index = KeySystem

function KeySystem.new(config)
    local self = setmetatable({}, KeySystem)
    self.Keys = config.Keys or {}
    self.MaxAttempts = config.MaxAttempts or 3
    self.OnSuccess = config.OnSuccess or function() end
    self.OnFail = config.OnFail or function() end
    self.KeyLink = config.KeyLink or ""
    self.Title = config.Title or "Key System"
    self.Attempts = 0
    self.Authenticated = false
    return self
end

function KeySystem:Validate(key)
    for _, validKey in ipairs(self.Keys) do
        if key == validKey then
            self.Authenticated = true
            self.OnSuccess()
            return true
        end
    end
    self.Attempts = self.Attempts + 1
    self.OnFail(self.Attempts, self.MaxAttempts)
    return false
end

function KeySystem:ShowPrompt(callback)
    local passed = false

    local screenGui = Create("ScreenGui", {
        Name = "Rayfield_KeySystem",
        Parent = CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })

    local overlay = Create("Frame", {
        Name = "Overlay",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        Parent = screenGui,
    })

    local theme = Themes[ActiveWindow and ActiveWindow._themeName or "Default"] or Themes.Default

    local frame = Create("Frame", {
        Name = "Frame",
        Size = UDim2.new(0, 380, 0, 260),
        Position = UDim2.new(0.5, -190, 0.5, -130),
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        Parent = overlay,
    })

    Create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = frame })
    Create("UIStroke", { Color = theme.Outline, Thickness = 1, Parent = frame })

    Create("Frame", {
        Name = "AccentBar",
        Size = UDim2.new(1, 0, 0, 3),
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Parent = frame,
    })

    Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -20, 0, 40),
        Position = UDim2.new(0, 10, 0, 15),
        BackgroundTransparency = 1,
        Text = self.Title,
        TextColor3 = theme.Text,
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
    })

    Create("TextLabel", {
        Name = "Subtitle",
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 10, 0, 50),
        BackgroundTransparency = 1,
        Text = "Enter your key to continue",
        TextColor3 = theme.SubText,
        TextSize = 13,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
    })

    local input = Create("TextBox", {
        Name = "Input",
        Size = UDim2.new(1, -40, 0, 40),
        Position = UDim2.new(0, 20, 0, 80),
        BackgroundColor3 = theme.ElementBackground,
        BorderSizePixel = 0,
        Text = "",
        PlaceholderText = "Paste your key here...",
        PlaceholderColor3 = theme.SubText,
        TextColor3 = theme.Text,
        TextSize = 14,
        Font = Enum.Font.Gotham,
        ClearTextOnFocus = false,
        Parent = frame,
    })

    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = input })

    local submitBtn = Create("TextButton", {
        Name = "Submit",
        Size = UDim2.new(1, -40, 0, 38),
        Position = UDim2.new(0, 20, 0, 135),
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Text = "Submit",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        Parent = frame,
    })

    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = submitBtn })

    local attemptsLabel = Create("TextLabel", {
        Name = "Attempts",
        Size = UDim2.new(1, -40, 0, 16),
        Position = UDim2.new(0, 20, 0, 182),
        BackgroundTransparency = 1,
        Text = "Attempts: 0/" .. self.MaxAttempts,
        TextColor3 = theme.SubText,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
    })

    if self.KeyLink ~= "" then
        local keyLinkBtn = Create("TextButton", {
            Name = "GetKey",
            Size = UDim2.new(1, -40, 0, 28),
            Position = UDim2.new(0, 20, 0, 210),
            BackgroundTransparency = 1,
            Text = "Get Key",
            TextColor3 = theme.Accent,
            TextSize = 13,
            Font = Enum.Font.GothamBold,
            Parent = frame,
        })
        keyLinkBtn.MouseButton1Click:Connect(function()
            setclipboard(self.KeyLink)
            Rayfield:Notify({
                Title = "Copied!",
                Content = "Key link copied to clipboard",
                Duration = 3,
                Type = "Info",
            })
        end)
    end

    submitBtn.MouseButton1Click:Connect(function()
        local key = input.Text
        if self:Validate(key) then
            passed = true
            screenGui:Destroy()
            if callback then callback(true) end
        else
            attemptsLabel.Text = "Attempts: " .. self.Attempts .. "/" .. self.MaxAttempts
            Tween(input, {0.2}, {BackgroundColor3 = theme.Error})
            task.delay(0.3, function()
                Tween(input, {0.2}, {BackgroundColor3 = theme.ElementBackground})
            end)
            if self.Attempts >= self.MaxAttempts then
                Rayfield:Notify({
                    Title = "Key System",
                    Content = "Max attempts reached. Please try again later.",
                    Duration = 5,
                    Type = "Error",
                })
                task.delay(1, function()
                    screenGui:Destroy()
                    if callback then callback(false) end
                end)
            end
        end
    end)

    return function()
        return passed
    end
end

-- ============================================================
-- CONSOLE
-- ============================================================

local Console = {}
Console.__index = Console

function Console.new(theme)
    local self = setmetatable({}, Console)
    self.Theme = theme or Themes.Default
    self.Visible = false
    self.Gui = nil
    self.Lines = {}
    self.MaxLines = 200
    return self
end

function Console:Create()
    self.Gui = Create("ScreenGui", {
        Name = "Rayfield_Console",
        Parent = CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })

    local frame = Create("Frame", {
        Name = "ConsoleFrame",
        Size = UDim2.new(0, 600, 0, 400),
        Position = UDim2.new(0.5, -300, 0.5, -200),
        BackgroundColor3 = self.Theme.Console.Background,
        BorderSizePixel = 0,
        Visible = false,
        Parent = self.Gui,
    })

    Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = frame })
    Create("UIStroke", { Color = self.Theme.Outline, Thickness = 1, Parent = frame })

    Create("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0,
        Parent = frame,
    })

    Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = "Console Output",
        TextColor3 = self.Theme.Text,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame.TitleBar,
    })

    local closeBtn = Create("TextButton", {
        Name = "Close",
        Size = UDim2.new(0, 60, 1, 0),
        Position = UDim2.new(1, -60, 0, 0),
        BackgroundTransparency = 1,
        Text = "X",
        TextColor3 = self.Theme.Error,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        Parent = frame.TitleBar,
    })

    closeBtn.MouseButton1Click:Connect(function()
        self:Toggle()
    end)

    local scrollFrame = Create("ScrollingFrame", {
        Name = "Output",
        Size = UDim2.new(1, -16, 1, -40),
        Position = UDim2.new(0, 8, 0, 36),
        BackgroundTransparency = 1,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = frame,
    })

    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        Parent = scrollFrame,
    })

    self.Frame = frame
    self.ScrollFrame = scrollFrame
    return self
end

function Console:Log(text, type)
    type = type or "normal"
    local theme = self.Theme

    local textColor = theme.Console.Text
    if type == "error" then textColor = theme.Console.Error
    elseif type == "warn" then textColor = theme.Console.Warn
    end

    table.insert(self.Lines, { text = text, type = type })

    if #self.Lines > self.MaxLines then
        table.remove(self.Lines, 1)
    end

    if self.ScrollFrame then
        local label = Create("TextLabel", {
            Name = "Line_" .. #self.Lines,
            Size = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1,
            Text = "[@" .. os.date("%H:%M:%S") .. "] " .. text,
            TextColor3 = textColor,
            TextSize = 12,
            Font = Enum.Font.RobotoMono,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Parent = self.ScrollFrame,
        })
    end
end

function Console:Clear()
    self.Lines = {}
    if self.ScrollFrame then
        for _, child in ipairs(self.ScrollFrame:GetChildren()) do
            if child:IsA("TextLabel") then child:Destroy() end
        end
    end
end

function Console:Toggle()
    if not self.Gui then self:Create() end
    self.Visible = not self.Visible
    self.Frame.Visible = self.Visible
end

-- ============================================================
-- NOTIFICATION SYSTEM
-- ============================================================

local function CreateNotification(config)
    local theme = Themes[ActiveWindow and ActiveWindow._themeName or "Default"] or Themes.Default
    local notifTheme = theme.Notification

    local notifType = config.Type or "Info"
    local accentColor = notifTheme[notifType] or notifTheme.Info

    local screenGui
    if not CoreGui:FindFirstChild("Rayfield_Notifications") then
        screenGui = Create("ScreenGui", {
            Name = "Rayfield_Notifications",
            Parent = CoreGui,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        })
    else
        screenGui = CoreGui:FindFirstChild("Rayfield_Notifications")
    end

    local yOffset = 0
    for _, child in ipairs(screenGui:GetChildren()) do
        if child:IsA("Frame") then
            yOffset = yOffset + child.Size.Y.Offset + 8
        end
    end

    local frame = Create("Frame", {
        Name = "Notification_" .. #Notifications + 1,
        Size = UDim2.new(0, 320, 0, 70),
        Position = UDim2.new(1, -340, 0, 20 + yOffset),
        BackgroundColor3 = notifTheme.Background,
        BorderSizePixel = 0,
        Parent = screenGui,
    })

    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = frame })
    Create("UIStroke", { Color = theme.Outline, Thickness = 1, Parent = frame })

    Create("Frame", {
        Name = "Accent",
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = accentColor,
        BorderSizePixel = 0,
        Parent = frame,
    })

    Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -20, 0, 22),
        Position = UDim2.new(0, 14, 0, 10),
        BackgroundTransparency = 1,
        Text = config.Title or "Notification",
        TextColor3 = theme.Text,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
    })

    Create("TextLabel", {
        Name = "Content",
        Size = UDim2.new(1, -20, 0, 22),
        Position = UDim2.new(0, 14, 0, 32),
        BackgroundTransparency = 1,
        Text = config.Content or "",
        TextColor3 = theme.SubText,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Parent = frame,
    })

    local closeBtn = Create("TextButton", {
        Name = "Close",
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -26, 0, 6),
        BackgroundTransparency = 1,
        Text = "X",
        TextColor3 = theme.SubText,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        Parent = frame,
    })

    table.insert(Notifications, frame)

    Tween(frame, {0.3, Enum.EasingStyle.Quint}, {
        Position = UDim2.new(1, -340, 0, 20 + yOffset)
    })

    frame.Position = UDim2.new(1, 0, 0, 20 + yOffset)

    local function closeNotif()
        Tween(frame, {0.3, Enum.EasingStyle.Quint}, {Position = UDim2.new(1, 0, 0, 20 + yOffset)})
        task.delay(0.35, function()
            frame:Destroy()
            for i, n in ipairs(Notifications) do
                if n == frame then table.remove(Notifications, i) break end
            end
        end)
    end

    closeBtn.MouseButton1Click:Connect(closeNotif)

    task.delay(config.Duration or 4, closeNotif)
end

-- ============================================================
-- SCRIPT HUB
-- ============================================================

local ScriptHub = {}
ScriptHub.__index = ScriptHub

function ScriptHub.new(theme)
    local self = setmetatable({}, ScriptHub)
    self.Theme = theme or Themes.Default
    self.Scripts = {}
    self.Favorites = LoadConfig("scripthub_favorites") or {}
    self.Gui = nil
    return self
end

function ScriptHub:AddScript(config)
    table.insert(self.Scripts, {
        Name = config.Name or "Script",
        Description = config.Description or "",
        Code = config.Code or "",
        Author = config.Author or "Unknown",
        Tags = config.Tags or {},
        Image = config.Image or nil,
    })
end

function ScriptHub:Create()
    self.Gui = Create("ScreenGui", {
        Name = "Rayfield_ScriptHub",
        Parent = CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })

    local frame = Create("Frame", {
        Name = "ScriptHubFrame",
        Size = UDim2.new(0, 650, 0, 480),
        Position = UDim2.new(0.5, -325, 0.5, -240),
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0,
        Parent = self.Gui,
    })

    Create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = frame })
    Create("UIStroke", { Color = self.Theme.Outline, Thickness = 1, Parent = frame })

    Create("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = self.Theme.TabBackground,
        BorderSizePixel = 0,
        Parent = frame,
    })

    Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -80, 1, 0),
        Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Text = "Script Hub",
        TextColor3 = self.Theme.Text,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame.TitleBar,
    })

    local favBtn = Create("TextButton", {
        Name = "Favorites",
        Size = UDim2.new(0, 60, 0, 24),
        Position = UDim2.new(1, -150, 0, 8),
        BackgroundColor3 = self.Theme.ElementBackground,
        BorderSizePixel = 0,
        Text = "Favorites",
        TextColor3 = self.Theme.SubText,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        Parent = frame.TitleBar,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = favBtn })

    local closeBtn = Create("TextButton", {
        Name = "Close",
        Size = UDim2.new(0, 30, 1, 0),
        Position = UDim2.new(1, -30, 0, 0),
        BackgroundTransparency = 1,
        Text = "X",
        TextColor3 = self.Theme.Error,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        Parent = frame.TitleBar,
    })

    closeBtn.MouseButton1Click:Connect(function()
        self.Gui:Destroy()
        self.Gui = nil
    end)

    local searchBox = Create("TextBox", {
        Name = "Search",
        Size = UDim2.new(1, -24, 0, 30),
        Position = UDim2.new(0, 12, 0, 48),
        BackgroundColor3 = self.Theme.ElementBackground,
        BorderSizePixel = 0,
        Text = "",
        PlaceholderText = "Search scripts...",
        PlaceholderColor3 = self.Theme.SubText,
        TextColor3 = self.Theme.Text,
        TextSize = 13,
        Font = Enum.Font.Gotham,
        ClearTextOnFocus = false,
        Parent = frame,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = searchBox })

    local scrollFrame = Create("ScrollingFrame", {
        Name = "ScriptList",
        Size = UDim2.new(1, -24, 1, -90),
        Position = UDim2.new(0, 12, 0, 86),
        BackgroundTransparency = 1,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = frame,
    })

    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = scrollFrame,
    })

    Create("UIGridLayout", {
        CellSize = UDim2.new(0, 296, 0, 80),
        CellPadding = UDim2.new(0, 8, 0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = scrollFrame,
    })

    local showingFavorites = false

    local function RenderScripts(filter)
        for _, child in ipairs(scrollFrame:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end

        for i, script in ipairs(self.Scripts) do
            if filter and filter ~= "" then
                if not string.lower(script.Name):find(string.lower(filter)) and
                   not string.lower(script.Description):find(string.lower(filter)) then
                    continue
                end
            end

            if showingFavorites then
                local isFav = false
                for _, fav in ipairs(self.Favorites) do
                    if fav == script.Name then isFav = true break end
                end
                if not isFav then continue end
            end

            local card = Create("Frame", {
                Name = "Script_" .. i,
                Size = UDim2.new(0, 296, 0, 80),
                BackgroundColor3 = self.Theme.ElementBackground,
                BorderSizePixel = 0,
                Parent = scrollFrame,
            })

            Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = card })

            Create("TextLabel", {
                Name = "Name",
                Size = UDim2.new(1, -60, 0, 22),
                Position = UDim2.new(0, 12, 0, 8),
                BackgroundTransparency = 1,
                Text = script.Name,
                TextColor3 = self.Theme.Text,
                TextSize = 14,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = card,
            })

            Create("TextLabel", {
                Name = "Author",
                Size = UDim2.new(0, 100, 0, 16),
                Position = UDim2.new(0, 12, 0, 30),
                BackgroundTransparency = 1,
                Text = "by " .. script.Author,
                TextColor3 = self.Theme.SubText,
                TextSize = 11,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = card,
            })

            Create("TextLabel", {
                Name = "Desc",
                Size = UDim2.new(1, -24, 0, 18),
                Position = UDim2.new(0, 12, 0, 48),
                BackgroundTransparency = 1,
                Text = script.Description,
                TextColor3 = self.Theme.SubText,
                TextSize = 11,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = true,
                Parent = card,
            })

            local isFav = false
            for _, fav in ipairs(self.Favorites) do
                if fav == script.Name then isFav = true break end
            end

            local favBtnCard = Create("TextButton", {
                Name = "Fav",
                Size = UDim2.new(0, 24, 0, 24),
                Position = UDim2.new(1, -36, 0, 8),
                BackgroundTransparency = 1,
                Text = isFav and "★" or "☆",
                TextColor3 = isFav and self.Theme.Warning or self.Theme.SubText,
                TextSize = 16,
                Font = Enum.Font.GothamBold,
                Parent = card,
            })

            favBtnCard.MouseButton1Click:Connect(function()
                local found = false
                for j, fav in ipairs(self.Favorites) do
                    if fav == script.Name then
                        table.remove(self.Favorites, j)
                        found = true
                        break
                    end
                end
                if not found then
                    table.insert(self.Favorites, script.Name)
                end
                SaveConfig("scripthub_favorites", self.Favorites)
                RenderScripts(searchBox.Text)
            end)

            local runBtn = Create("TextButton", {
                Name = "Run",
                Size = UDim2.new(0, 60, 0, 26),
                Position = UDim2.new(1, -72, 0, 46),
                BackgroundColor3 = self.Theme.Accent,
                BorderSizePixel = 0,
                Text = "Execute",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                Parent = card,
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = runBtn })

            runBtn.MouseButton1Click:Connect(function()
                local success, err = pcall(function()
                    loadstring(script.Code)()
                end)
                if success then
                    Rayfield:Notify({
                        Title = "Script Hub",
                        Content = script.Name .. " executed successfully",
                        Duration = 3,
                        Type = "Success",
                    })
                else
                    Rayfield:Notify({
                        Title = "Script Hub",
                        Content = "Error: " .. tostring(err),
                        Duration = 5,
                        Type = "Error",
                    })
                end
            end)
        end
    end

    RenderScripts("")

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        RenderScripts(searchBox.Text)
    end)

    favBtn.MouseButton1Click:Connect(function()
        showingFavorites = not showingFavorites
        favBtn.TextColor3 = showingFavorites and self.Theme.Warning or self.Theme.SubText
        RenderScripts(searchBox.Text)
    end)

    self.RenderScripts = RenderScripts
    self.Frame = frame
end

function ScriptHub:Toggle()
    if self.Gui then
        self.Gui:Destroy()
        self.Gui = nil
        return
    end
    self:Create()
end

-- ============================================================
-- SESSION MANAGER
-- ============================================================

local SessionManager = {}
SessionManager.__index = SessionManager

function SessionManager.new()
    local self = setmetatable({}, SessionManager)
    self.Active = true
    self.StartTime = os.time()
    self.Connections = {}
    return self
end

function SessionManager:AddConnection(name, connection)
    self.Connections[name] = connection
end

function SessionManager:Shutdown()
    self.Active = false
    SessionActive = false

    for name, connection in pairs(self.Connections) do
        pcall(function() connection:Disconnect() end)
    end
    self.Connections = {}

    if ActiveWindow and ActiveWindow._gui then
        pcall(function()
            Tween(ActiveWindow._gui, {0.4, Enum.EasingStyle.Quint}, {
                BackgroundTransparency = 1
            })
        end)
        task.delay(0.5, function()
            pcall(function()
                if ActiveWindow._gui then ActiveWindow._gui:Destroy() end
            end)
        end)
    end

    pcall(function()
        local notifGui = CoreGui:FindFirstChild("Rayfield_Notifications")
        if notifGui then notifGui:Destroy() end
        local consoleGui = CoreGui:FindFirstChild("Rayfield_Console")
        if consoleGui then consoleGui:Destroy() end
    end)

    Rayfield:Notify({
        Title = "Session Ended",
        Content = "Rayfield has been shut down. Goodbye!",
        Duration = 3,
        Type = "Info",
    })
end

function SessionManager:GetUptime()
    local elapsed = os.time() - self.StartTime
    local hours = math.floor(elapsed / 3600)
    local minutes = math.floor((elapsed % 3600) / 60)
    local seconds = elapsed % 60
    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

-- ============================================================
-- UPDATER
-- ============================================================

local Updater = {}
Updater.__index = Updater

function Updater.new()
    local self = setmetatable({}, Updater)
    self.CurrentVersion = VERSION
    self.LatestVersion = nil
    self.UpdateAvailable = false
    self.LastCheck = 0
    return self
end

function Updater:CheckForUpdates()
    local success, response = pcall(function()
        return game:HttpGet(RAW_URL .. "/version.txt")
    end)

    if success and response then
        self.LatestVersion = response:gsub("%s+", "")
        self.UpdateAvailable = self.LatestVersion ~= self.CurrentVersion
        self.LastCheck = os.time()
        return self.UpdateAvailable, self.LatestVersion
    end
    return false, nil
end

function Updater:AutoCheck(interval)
    task.spawn(function()
        while SessionActive do
            if os.time() - self.LastCheck >= (interval or UPDATE_CHECK_INTERVAL) then
                local updateAvailable, newVersion = self:CheckForUpdates()
                if updateAvailable then
                    Rayfield:Notify({
                        Title = "Update Available",
                        Content = "v" .. newVersion .. " is available! Current: v" .. self.CurrentVersion,
                        Duration = 8,
                        Type = "Info",
                    })
                end
            end
            task.wait(60)
        end
    end)
end

-- ============================================================
-- MAIN WINDOW
-- ============================================================

function Rayfield:CreateWindow(config)
    config = config or {}

    local windowName = config.Name or "Rayfield Ultimate"
    local themeName = config.Theme or "Default"
    local theme = Themes[themeName] or Themes.Default
    local keySystemConfig = config.KeySystem

    local session = SessionManager.new()
    local updater = Updater.new()
    local console = Console.new(theme)
    local scriptHub = ScriptHub.new(theme)

    local window = setmetatable({}, { __index = Rayfield })
    window._gui = nil
    window._theme = theme
    window._themeName = themeName
    window._tabs = {}
    window._tabButtons = {}
    window._activeTab = nil
    window._elements = {}
    window._configName = config.Config or windowName
    window._session = session
    window._updater = updater
    window._console = console
    window._scriptHub = scriptHub
    window._minimized = false
    window._locked = false
    ActiveWindow = window

    local function BuildUI()
        -- Destroy old GUI
        if window._gui then window._gui:Destroy() end

        local gui = Create("ScreenGui", {
            Name = "Rayfield_Ultimate",
            Parent = CoreGui,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            ResetOnSpawn = false,
        })

        -- Main Frame
        local mainFrame = Create("Frame", {
            Name = "Main",
            Size = UDim2.new(0, 550, 0, 400),
            Position = UDim2.new(0.5, -275, 0.5, -200),
            BackgroundColor3 = theme.Background,
            BorderSizePixel = 0,
            Active = true,
            Draggable = true,
            Parent = gui,
        })

        Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = mainFrame })
        Create("UIStroke", { Color = theme.Outline, Thickness = 1, Parent = mainFrame })

        -- Drop shadow (visual only)
        Create("ImageLabel", {
            Name = "Shadow",
            Size = UDim2.new(1, 30, 1, 30),
            Position = UDim2.new(0, -15, 0, -15),
            BackgroundTransparency = 1,
            Image = "rbxassetid://5554236805",
            ImageColor3 = Color3.fromRGB(0, 0, 0),
            ImageTransparency = 0.7,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(23, 23, 277, 277),
            Parent = mainFrame,
            ZIndex = -1,
        })

        -- Title Bar
        local titleBar = Create("Frame", {
            Name = "TitleBar",
            Size = UDim2.new(1, 0, 0, 38),
            BackgroundColor3 = theme.TabBackground,
            BorderSizePixel = 0,
            Parent = mainFrame,
        })

        Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = titleBar })

        Create("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, -120, 1, 0),
            Position = UDim2.new(0, 14, 0, 0),
            BackgroundTransparency = 1,
            Text = windowName,
            TextColor3 = theme.Text,
            TextSize = 15,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = titleBar,
        })

        Create("TextLabel", {
            Name = "Version",
            Size = UDim2.new(0, 50, 1, 0),
            Position = UDim2.new(0, 14, 0, 0),
            BackgroundTransparency = 1,
            Text = "v" .. VERSION,
            TextColor3 = theme.SubText,
            TextSize = 11,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = titleBar,
        })

        -- Minimize Button
        local minimizeBtn = Create("TextButton", {
            Name = "Minimize",
            Size = UDim2.new(0, 30, 0, 30),
            Position = UDim2.new(1, -90, 0, 4),
            BackgroundTransparency = 1,
            Text = "—",
            TextColor3 = theme.SubText,
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            Parent = titleBar,
        })

        -- Maximize / Console Button
        local consoleBtn = Create("TextButton", {
            Name = "Console",
            Size = UDim2.new(0, 30, 0, 30),
            Position = UDim2.new(1, -58, 0, 4),
            BackgroundTransparency = 1,
            Text = ">",
            TextColor3 = theme.SubText,
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            Parent = titleBar,
        })

        -- Close Button
        local closeBtn = Create("TextButton", {
            Name = "Close",
            Size = UDim2.new(0, 30, 0, 30),
            Position = UDim2.new(1, -30, 0, 4),
            BackgroundTransparency = 1,
            Text = "X",
            TextColor3 = theme.Error,
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            Parent = titleBar,
        })

        -- Tab Container
        local tabBar = Create("Frame", {
            Name = "TabBar",
            Size = UDim2.new(1, -2, 0, 34),
            Position = UDim2.new(0, 1, 0, 38),
            BackgroundTransparency = 1,
            Parent = mainFrame,
        })

        Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 2),
            Parent = tabBar,
        })

        -- Content Area
        local contentFrame = Create("Frame", {
            Name = "Content",
            Size = UDim2.new(1, -16, 1, -92),
            Position = UDim2.new(0, 8, 0, 78),
            BackgroundTransparency = 1,
            Parent = mainFrame,
        })

        -- Footer
        local footer = Create("Frame", {
            Name = "Footer",
            Size = UDim2.new(1, 0, 0, 14),
            Position = UDim2.new(0, 0, 1, -14),
            BackgroundTransparency = 1,
            Parent = mainFrame,
        })

        local uptimeLabel = Create("TextLabel", {
            Name = "Uptime",
            Size = UDim2.new(0.5, 0, 1, 0),
            Position = UDim2.new(0, 8, 0, 0),
            BackgroundTransparency = 1,
            Text = "Uptime: 00:00:00",
            TextColor3 = theme.SubText,
            TextSize = 9,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = footer,
        })

        local modeLabel = Create("TextLabel", {
            Name = "Mode",
            Size = UDim2.new(0.5, 0, 1, 0),
            Position = UDim2.new(0.5, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = "Theme: " .. themeName .. " | Rayfield Ultimate",
            TextColor3 = theme.SubText,
            TextSize = 9,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Right,
            Parent = footer,
        })

        -- Minimize
        minimizeBtn.MouseButton1Click:Connect(function()
            window._minimized = not window._minimized
            if window._minimized then
                Tween(mainFrame, {0.3, Enum.EasingStyle.Quint}, {Size = UDim2.new(0, 550, 0, 38)})
                minimizeBtn.Text = "+"
            else
                Tween(mainFrame, {0.3, Enum.EasingStyle.Quint}, {Size = UDim2.new(0, 550, 0, 400)})
                minimizeBtn.Text = "—"
            end
        end)

        -- Console
        consoleBtn.MouseButton1Click:Connect(function()
            console:Toggle()
        end)

        -- Close / Shutdown
        closeBtn.MouseButton1Click:Connect(function()
            session:Shutdown()
        end)

        -- Uptime ticker
        session:AddConnection("uptime", RunService.Heartbeat:Connect(function()
            uptimeLabel.Text = "Uptime: " .. session:GetUptime()
        end))

        window._gui = gui
        window._mainFrame = mainFrame
        window._tabBar = tabBar
        window._contentFrame = contentFrame
        window._tabs = {}
        window._tabButtons = {}
    end

    -- Handle KeySystem if configured
    if keySystemConfig then
        local ks = KeySystem.new(keySystemConfig)
        ks:ShowPrompt(function(success)
            if success then
                BuildUI()
                updater:AutoCheck()
                Rayfield:Notify({
                    Title = "Welcome",
                    Content = windowName .. " loaded successfully!",
                    Duration = 4,
                    Type = "Success",
                })
            end
        end)
    else
        BuildUI()
        updater:AutoCheck()
    end

    return window
end

-- ============================================================
-- TAB SYSTEM
-- ============================================================

function Rayfield:CreateTab(config)
    if type(config) == "string" then
        config = { Name = config, Icon = "" }
    end
    config.Name = config.Name or "Tab"
    config.Icon = config.Icon or ""

    local theme = self._theme
    local index = #self._tabs + 1

    local tabData = {
        Name = config.Name,
        Icon = config.Icon,
        Elements = {},
        SectionCount = 0,
    }

    -- Tab Button
    local tabBtn = Create("TextButton", {
        Name = "Tab_" .. config.Name,
        Size = UDim2.new(0, 100, 1, 0),
        BackgroundColor3 = theme.ElementBackground,
        BorderSizePixel = 0,
        Text = config.Icon .. " " .. config.Name,
        TextColor3 = theme.SubText,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        Parent = self._tabBar,
    })

    Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = tabBtn })

    -- Tab Content
    local scrollFrame = Create("ScrollingFrame", {
        Name = "TabContent_" .. config.Name,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = theme.Accent,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = self._contentFrame,
    })

    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        Parent = scrollFrame,
    })

    tabBtn.MouseButton1Click:Connect(function()
        self:SwitchTab(index)
    end)

    self._tabs[index] = tabData
    self._tabButtons[index] = tabBtn
    tabData._scrollFrame = scrollFrame

    -- Auto-switch to first tab
    if index == 1 then
        self:SwitchTab(1)
    end

    local tabObj = setmetatable({}, { __index = Rayfield })
    tabObj._scrollFrame = scrollFrame
    tabObj._parent = self
    tabObj._theme = theme
    tabObj._elements = {}

    return tabObj
end

function Rayfield:SwitchTab(index)
    for i, btn in ipairs(self._tabButtons) do
        if i == index then
            btn.BackgroundColor3 = self._theme.Accent
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.BackgroundColor3 = self._theme.ElementBackground
            btn.TextColor3 = self._theme.SubText
        end
    end

    for i, tab in ipairs(self._tabs) do
        if tab._scrollFrame then
            tab._scrollFrame.Visible = (i == index)
        end
    end

    self._activeTab = index
end

-- ============================================================
-- UI ELEMENTS
-- ============================================================

function Rayfield:CreateSection(name)
    name = name or "Section"
    local parent = self._scrollFrame
    if not parent then return end

    self._sectionCount = (self._sectionCount or 0) + 1

    local section = Create("Frame", {
        Name = "Section_" .. name,
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        Parent = parent,
    })

    Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 4, 0, 0),
        BackgroundTransparency = 1,
        Text = string.upper(name),
        TextColor3 = self._theme.SubText,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = section,
    })

    Create("Frame", {
        Name = "Line",
        Size = UDim2.new(1, -10, 0, 1),
        Position = UDim2.new(0, 4, 1, -2),
        BackgroundColor3 = self._theme.Outline,
        BorderSizePixel = 0,
        Parent = section,
    })
end

function Rayfield:CreateButton(config)
    config = config or {}
    local parent = self._scrollFrame
    if not parent then return end

    local theme = self._theme

    local frame = Create("Frame", {
        Name = "Button_" .. (config.Name or "Button"),
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = theme.ElementBackground,
        BorderSizePixel = 0,
        Parent = parent,
    })

    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = frame })

    Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -120, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = config.Name or "Button",
        TextColor3 = theme.Text,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
    })

    if config.Description then
        Create("TextLabel", {
            Name = "Desc",
            Size = UDim2.new(1, -120, 0, 14),
            Position = UDim2.new(0, 12, 1, -16),
            BackgroundTransparency = 1,
            Text = config.Description,
            TextColor3 = theme.SubText,
            TextSize = 10,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = frame,
        })
    end

    local btn = Create("TextButton", {
        Name = "Action",
        Size = UDim2.new(0, 80, 0, 28),
        Position = UDim2.new(1, -92, 0.5, -14),
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Text = config.InteractText or "Execute",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        Parent = frame,
    })

    Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = btn })

    -- Hover
    frame.MouseEnter:Connect(function()
        Tween(frame, {0.15}, {BackgroundColor3 = theme.ElementHover})
    end)
    frame.MouseLeave:Connect(function()
        Tween(frame, {0.15}, {BackgroundColor3 = theme.ElementBackground})
    end)

    btn.MouseButton1Click:Connect(function()
        Tween(btn, {0.1}, {BackgroundColor3 = theme.AccentDark})
        task.delay(0.1, function()
            Tween(btn, {0.1}, {BackgroundColor3 = theme.Accent})
        end)
        if config.Callback then
            local success, err = pcall(config.Callback)
            if not success then
                Rayfield:Notify({
                    Title = "Error",
                    Content = tostring(err),
                    Duration = 5,
                    Type = "Error",
                })
            end
        end
    end)

    return frame
end

function Rayfield:CreateToggle(config)
    config = config or {}
    local parent = self._scrollFrame
    if not parent then return end

    local theme = self._theme
    local toggled = config.CurrentValue or false

    local frame = Create("Frame", {
        Name = "Toggle_" .. (config.Name or "Toggle"),
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = theme.ElementBackground,
        BorderSizePixel = 0,
        Parent = parent,
    })

    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = frame })

    Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -80, 0, 20),
        Position = UDim2.new(0, 12, 0, 4),
        BackgroundTransparency = 1,
        Text = config.Name or "Toggle",
        TextColor3 = theme.Text,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
    })

    if config.Description then
        Create("TextLabel", {
            Name = "Desc",
            Size = UDim2.new(1, -80, 0, 14),
            Position = UDim2.new(0, 12, 0, 24),
            BackgroundTransparency = 1,
            Text = config.Description,
            TextColor3 = theme.SubText,
            TextSize = 10,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = frame,
        })
    end

    -- Toggle Switch
    local toggleFrame = Create("Frame", {
        Name = "Switch",
        Size = UDim2.new(0, 40, 0, 22),
        Position = UDim2.new(1, -52, 0.5, -11),
        BackgroundColor3 = toggled and theme.Accent or theme.Outline,
        BorderSizePixel = 0,
        Parent = frame,
    })

    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = toggleFrame })

    local circle = Create("Frame", {
        Name = "Circle",
        Size = UDim2.new(0, 16, 0, 16),
        Position = toggled and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Parent = toggleFrame,
    })

    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = circle })

    local interact = Create("TextButton", {
        Name = "Interact",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = frame,
    })

    interact.MouseButton1Click:Connect(function()
        toggled = not toggled
        Tween(toggleFrame, {0.2}, {BackgroundColor3 = toggled and theme.Accent or theme.Outline})
        Tween(circle, {0.2, Enum.EasingStyle.Quint}, {
            Position = toggled and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        })
        if config.Callback then
            pcall(config.Callback, toggled)
        end
    end)

    frame.MouseEnter:Connect(function()
        Tween(frame, {0.15}, {BackgroundColor3 = theme.ElementHover})
    end)
    frame.MouseLeave:Connect(function()
        Tween(frame, {0.15}, {BackgroundColor3 = theme.ElementBackground})
    end)

    return frame
end

function Rayfield:CreateSlider(config)
    config = config or {}
    local parent = self._scrollFrame
    if not parent then return end

    local theme = self._theme
    local min = config.Range and config.Range[1] or 0
    local max = config.Range and config.Range[2] or 100
    local increment = config.Increment or 1
    local currentValue = config.CurrentValue or min

    local frame = Create("Frame", {
        Name = "Slider_" .. (config.Name or "Slider"),
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = theme.ElementBackground,
        BorderSizePixel = 0,
        Parent = parent,
    })

    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = frame })

    Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(0.6, 0, 0, 20),
        Position = UDim2.new(0, 12, 0, 6),
        BackgroundTransparency = 1,
        Text = config.Name or "Slider",
        TextColor3 = theme.Text,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
    })

    local valueLabel = Create("TextLabel", {
        Name = "Value",
        Size = UDim2.new(0.4, -12, 0, 20),
        Position = UDim2.new(0.6, 0, 0, 6),
        BackgroundTransparency = 1,
        Text = tostring(currentValue),
        TextColor3 = theme.Accent,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = frame,
    })

    if config.Description then
        Create("TextLabel", {
            Name = "Desc",
            Size = UDim2.new(1, -24, 0, 14),
            Position = UDim2.new(0, 12, 0, 26),
            BackgroundTransparency = 1,
            Text = config.Description,
            TextColor3 = theme.SubText,
            TextSize = 10,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = frame,
        })
    end

    -- Slider Track
    local track = Create("Frame", {
        Name = "Track",
        Size = UDim2.new(1, -24, 0, 6),
        Position = UDim2.new(0, 12, 1, -14),
        BackgroundColor3 = theme.Outline,
        BorderSizePixel = 0,
        Parent = frame,
    })

    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })

    local fill = Create("Frame", {
        Name = "Fill",
        Size = UDim2.new(0, ((currentValue - min) / (max - min)) * (track.AbsoluteSize.X > 0 and track.AbsoluteSize.X or 500), 1, 0),
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Parent = track,
    })

    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })

    local knob = Create("Frame", {
        Name = "Knob",
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(((currentValue - min) / (max - min)), -7, 0.5, -7),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Parent = track,
    })

    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

    local dragging = false

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)

    knob.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
           input.UserInputType == Enum.UserInputType.Touch) then
            local trackAbs = track.AbsolutePosition.X
            local trackSize = track.AbsoluteSize.X
            local mouseX = input.Position.X
            local fraction = math.clamp((mouseX - trackAbs) / trackSize, 0, 1)

            local rawValue = min + (max - min) * fraction
            local steppedValue = math.floor(rawValue / increment + 0.5) * increment
            steppedValue = math.clamp(steppedValue, min, max)

            currentValue = steppedValue
            valueLabel.Text = tostring(currentValue)

            fill.Size = UDim2.new(0, fraction * trackSize, 1, 0)
            knob.Position = UDim2.new(fraction, -7, 0.5, -7)

            if config.Callback then
                pcall(config.Callback, currentValue)
            end
        end
    end)

    frame.MouseEnter:Connect(function()
        Tween(frame, {0.15}, {BackgroundColor3 = theme.ElementHover})
    end)
    frame.MouseLeave:Connect(function()
        Tween(frame, {0.15}, {BackgroundColor3 = theme.ElementBackground})
    end)

    return frame
end

function Rayfield:CreateDropdown(config)
    config = config or {}
    local parent = self._scrollFrame
    if not parent then return end

    local theme = self._theme
    local options = config.Options or {}
    local current = config.CurrentValue or ""

    local frame = Create("Frame", {
        Name = "Dropdown_" .. (config.Name or "Dropdown"),
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = theme.ElementBackground,
        BorderSizePixel = 0,
        Parent = parent,
    })

    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = frame })

    Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -80, 0, 20),
        Position = UDim2.new(0, 12, 0, 4),
        BackgroundTransparency = 1,
        Text = config.Name or "Dropdown",
        TextColor3 = theme.Text,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
    })

    local displayLabel = Create("TextLabel", {
        Name = "Current",
        Size = UDim2.new(0, 140, 0, 20),
        Position = UDim2.new(1, -152, 0, 4),
        BackgroundTransparency = 1,
        Text = current ~= "" and current or "Select...",
        TextColor3 = current ~= "" and theme.Accent or theme.SubText,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = frame,
    })

    local arrow = Create("TextLabel", {
        Name = "Arrow",
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -28, 0.5, -10),
        BackgroundTransparency = 1,
        Text = "▼",
        TextColor3 = theme.SubText,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        Parent = frame,
    })

    -- Dropdown list
    local listFrame = Create("Frame", {
        Name = "List",
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 1, 4),
        BackgroundColor3 = theme.ElementBackground,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = false,
        Parent = frame,
    })

    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = listFrame })
    Create("UIStroke", { Color = theme.Outline, Thickness = 1, Parent = listFrame })

    local listScroll = Create("ScrollingFrame", {
        Name = "ListScroll",
        Size = UDim2.new(1, -8, 1, -8),
        Position = UDim2.new(0, 4, 0, 4),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = theme.Accent,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = listFrame,
    })

    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        Parent = listScroll,
    })

    local isOpen = false
    local itemHeight = 28

    local function PopulateList()
        for _, child in ipairs(listScroll:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end

        for _, option in ipairs(options) do
            local item = Create("TextButton", {
                Name = option,
                Size = UDim2.new(1, 0, 0, itemHeight),
                BackgroundColor3 = option == current and theme.Accent or Color3.fromRGB(0, 0, 0),
                BackgroundTransparency = option == current and 0 or 1,
                BorderSizePixel = 0,
                Text = option,
                TextColor3 = theme.Text,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                Parent = listScroll,
            })

            Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = item })

            item.MouseButton1Click:Connect(function()
                current = option
                displayLabel.Text = option
                displayLabel.TextColor3 = theme.Accent
                isOpen = false
                listFrame.Visible = false
                arrow.Text = "▼"
                if config.Callback then
                    pcall(config.Callback, option)
                end
            end)

            item.MouseEnter:Connect(function()
                if option ~= current then
                    Tween(item, {0.1}, {BackgroundTransparency = 0.8})
                end
            end)
            item.MouseLeave:Connect(function()
                if option ~= current then
                    Tween(item, {0.1}, {BackgroundTransparency = 1})
                end
            end)
        end
    end

    local interact = Create("TextButton", {
        Name = "Interact",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = frame,
    })

    interact.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            PopulateList()
            local totalHeight = #options * itemHeight + 8
            listFrame.Size = UDim2.new(1, 0, 0, math.min(totalHeight, 180))
            listFrame.Visible = true
            arrow.Text = "▲"
        else
            listFrame.Visible = false
            arrow.Text = "▼"
        end
    end)

    frame.MouseEnter:Connect(function()
        Tween(frame, {0.15}, {BackgroundColor3 = theme.ElementHover})
    end)
    frame.MouseLeave:Connect(function()
        Tween(frame, {0.15}, {BackgroundColor3 = theme.ElementBackground})
    end)

    return frame
end

function Rayfield:CreateInput(config)
    config = config or {}
    local parent = self._scrollFrame
    if not parent then return end

    local theme = self._theme

    local frame = Create("Frame", {
        Name = "Input_" .. (config.Name or "Input"),
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = theme.ElementBackground,
        BorderSizePixel = 0,
        Parent = parent,
    })

    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = frame })

    Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -180, 0, 20),
        Position = UDim2.new(0, 12, 0, 4),
        BackgroundTransparency = 1,
        Text = config.Name or "Input",
        TextColor3 = theme.Text,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
    })

    local input = Create("TextBox", {
        Name = "Input",
        Size = UDim2.new(0, 160, 0, 28),
        Position = UDim2.new(1, -172, 0.5, -14),
        BackgroundColor3 = theme.ElementHover,
        BorderSizePixel = 0,
        Text = config.CurrentValue or "",
        PlaceholderText = config.PlaceholderText or "Type here...",
        PlaceholderColor3 = theme.SubText,
        TextColor3 = theme.Text,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        ClearTextOnFocus = false,
        Parent = frame,
    })

    Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = input })

    input.FocusLost:Connect(function(enterPressed)
        if config.Callback then
            pcall(config.Callback, input.Text)
        end
    end)

    frame.MouseEnter:Connect(function()
        Tween(frame, {0.15}, {BackgroundColor3 = theme.ElementHover})
    end)
    frame.MouseLeave:Connect(function()
        Tween(frame, {0.15}, {BackgroundColor3 = theme.ElementBackground})
    end)

    return frame
end

function Rayfield:CreateParagraph(config)
    config = config or {}
    local parent = self._scrollFrame
    if not parent then return end

    local theme = self._theme

    local frame = Create("Frame", {
        Name = "Paragraph_" .. (config.Title or "Paragraph"),
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = theme.ElementBackground,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = parent,
    })

    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = frame })

    local content = config.Content or ""
    local titleText = config.Title or ""

    Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -24, 0, 20),
        Position = UDim2.new(0, 12, 0, 8),
        BackgroundTransparency = 1,
        Text = titleText,
        TextColor3 = theme.Accent,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = frame,
    })

    Create("TextLabel", {
        Name = "Content",
        Size = UDim2.new(1, -24, 0, 0),
        Position = UDim2.new(0, 12, 0, 28),
        BackgroundTransparency = 1,
        Text = content,
        TextColor3 = theme.SubText,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = frame,
    })

    Create("UIPadding", { PaddingBottom = UDim.new(0, 10), Parent = frame })

    return frame
end

function Rayfield:CreateSeparator()
    local parent = self._scrollFrame
    if not parent then return end

    local frame = Create("Frame", {
        Name = "Separator",
        Size = UDim2.new(1, 0, 0, 12),
        BackgroundTransparency = 1,
        Parent = parent,
    })

    Create("Frame", {
        Name = "Line",
        Size = UDim2.new(1, -20, 0, 1),
        Position = UDim2.new(0, 10, 0.5, 0),
        BackgroundColor3 = self._theme.Outline,
        BorderSizePixel = 0,
        Parent = frame,
    })
end

function Rayfield:CreateColorPicker(config)
    config = config or {}
    local parent = self._scrollFrame
    if not parent then return end

    local theme = self._theme
    local currentColor = config.CurrentValue or Color3.fromRGB(255, 255, 255)

    local frame = Create("Frame", {
        Name = "ColorPicker_" .. (config.Name or "ColorPicker"),
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = theme.ElementBackground,
        BorderSizePixel = 0,
        Parent = parent,
    })

    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = frame })

    Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -100, 0, 20),
        Position = UDim2.new(0, 12, 0, 4),
        BackgroundTransparency = 1,
        Text = config.Name or "Color",
        TextColor3 = theme.Text,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
    })

    -- Color preview
    local preview = Create("Frame", {
        Name = "Preview",
        Size = UDim2.new(0, 30, 0, 20),
        Position = UDim2.new(1, -42, 0.5, -10),
        BackgroundColor3 = currentColor,
        BorderSizePixel = 0,
        Parent = frame,
    })

    Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = preview })

    -- Simple RGB sliders
    local r = currentColor.R * 255
    local g = currentColor.G * 255
    local b = currentColor.B * 255

    local function updateColor()
        currentColor = Color3.fromRGB(r, g, b)
        preview.BackgroundColor3 = currentColor
        if config.Callback then
            pcall(config.Callback, currentColor)
        end
    end

    local colors = {
        { label = "R", value = r, color = Color3.fromRGB(255, 0, 0), key = "R" },
        { label = "G", value = g, color = Color3.fromRGB(0, 255, 0), key = "G" },
        { label = "B", value = b, color = Color3.fromRGB(0, 0, 255), key = "B" },
    }

    for i, c in ipairs(colors) do
        local label = Create("TextLabel", {
            Name = c.label .. "_Label",
            Size = UDim2.new(0, 16, 0, 10),
            Position = UDim2.new(0, 12, 0, 22 + (i - 1) * 0),
            BackgroundTransparency = 1,
            Text = c.label,
            TextColor3 = c.color,
            TextSize = 9,
            Font = Enum.Font.GothamBold,
            Parent = frame,
        })

        local track = Create("Frame", {
            Name = c.label .. "_Track",
            Size = UDim2.new(1, -100, 0, 4),
            Position = UDim2.new(0, 32, 0, 26 + 0),
            BackgroundColor3 = theme.Outline,
            BorderSizePixel = 0,
            Parent = frame,
        })
        Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })
    end

    frame.MouseEnter:Connect(function()
        Tween(frame, {0.15}, {BackgroundColor3 = theme.ElementHover})
    end)
    frame.MouseLeave:Connect(function()
        Tween(frame, {0.15}, {BackgroundColor3 = theme.ElementBackground})
    end)

    return frame
end

-- ============================================================
-- THEME SWITCHING
-- ============================================================

function Rayfield:ChangeTheme(themeName)
    local newTheme = Themes[themeName]
    if not newTheme then
        Rayfield:Notify({
            Title = "Theme Error",
            Content = "Theme '" .. themeName .. "' not found",
            Duration = 4,
            Type = "Error",
        })
        return
    end

    self._theme = newTheme
    self._themeName = themeName

    Rayfield:Notify({
        Title = "Theme Changed",
        Content = "Switched to " .. themeName,
        Duration = 3,
        Type = "Success",
    })
end

function Rayfield:GetThemes()
    local themeList = {}
    for name, _ in pairs(Themes) do
        table.insert(themeList, name)
    end
    return themeList
end

-- ============================================================
-- NOTIFICATION (Global)
-- ============================================================

function Rayfield:Notify(config)
    CreateNotification(config)
end

-- ============================================================
-- SESSION / SHUTDOWN (Global)
-- ============================================================

function Rayfield:Shutdown()
    if ActiveWindow and ActiveWindow._session then
        ActiveWindow._session:Shutdown()
    end
end

function Rayfield:GetVersion()
    return VERSION
end

function Rayfield:GetSession()
    if ActiveWindow and ActiveWindow._session then
        return {
            Uptime = ActiveWindow._session:GetUptime(),
            Active = ActiveWindow._session.Active,
        }
    end
    return nil
end

-- ============================================================
-- SCRIPT HUB (Global)
-- ============================================================

function Rayfield:OpenScriptHub()
    if ActiveWindow and ActiveWindow._scriptHub then
        ActiveWindow._scriptHub:Toggle()
    end
end

function Rayfield:AddToScriptHub(config)
    if ActiveWindow and ActiveWindow._scriptHub then
        ActiveWindow._scriptHub:AddScript(config)
    end
end

-- ============================================================
-- CONSOLE (Global)
-- ============================================================

function Rayfield:LogToConsole(text, type)
    if ActiveWindow and ActiveWindow._console then
        ActiveWindow._console:Log(text, type)
    end
end

function Rayfield:ClearConsole()
    if ActiveWindow and ActiveWindow._console then
        ActiveWindow._console:Clear()
    end
end

function Rayfield:ToggleConsole()
    if ActiveWindow and ActiveWindow._console then
        ActiveWindow._console:Toggle()
    end
end

return Rayfield
