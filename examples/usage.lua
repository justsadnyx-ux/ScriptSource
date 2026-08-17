--[[
    Rayfield Ultimate - Full Usage Example
    Demonstrates all features including Update Status, ESP, Anti-AFK, FPS Boost, etc.
--]]

local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/justsadnyx-ux/Rayfield-Ultimate/main/loader.lua"))()

-- Optional Key System
local Window = Rayfield:CreateWindow({
    Name = "My Script Hub",
    Theme = "Default",
    Config = "MyScriptHub",
    KeySystem = false,
})

-- ============================================================
-- UPDATE STATUS TAB (Built-in, auto-populated)
-- ============================================================
local UpdatesTab = Window:CreateTab("Updates", "🔄")
UpdatesTab:CreateUpdateSection()
UpdatesTab:CreateParagraph({
    Title = "About Updates",
    Content = "Rayfield Ultimate automatically checks GitLab for new versions. When an update is available, the status will change and you can click 'Update Now' to download the latest version. Restart your executor to apply the update.",
})

-- ============================================================
-- MAIN TAB
-- ============================================================
local MainTab = Window:CreateTab("Main", "🏠")

MainTab:CreateSection("Quick Actions")

MainTab:CreateButton({
    Name = "Print Hello World",
    Description = "Test button - prints to console",
    InteractText = "Run",
    Callback = function()
        print("Hello from Rayfield Ultimate!")
        Rayfield:LogToConsole("Hello from Rayfield Ultimate!", "info")
        Rayfield:Notify({ Title = "Executed", Content = "Printed hello message!", Duration = 3, Type = "Success" })
    end,
})

MainTab:CreateButton({
    Name = "Open Script Hub",
    Description = "Browse and execute scripts",
    InteractText = "Open",
    Callback = function()
        Rayfield:OpenScriptHub()
    end,
})

MainTab:CreateButton({
    Name = "Open Console",
    Description = "View output logs",
    InteractText = "Open",
    Callback = function()
        Rayfield:ToggleConsole()
    end,
})

MainTab:CreateSeparator()

MainTab:CreateSection("Character Mods")

MainTab:CreateSlider({
    Name = "Walk Speed",
    Description = "Adjust walk speed",
    Range = {16, 200},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(value)
        local char = game.Players.LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = value end
        end
    end,
})

MainTab:CreateSlider({
    Name = "Jump Power",
    Description = "Adjust jump power",
    Range = {50, 300},
    Increment = 5,
    CurrentValue = 50,
    Callback = function(value)
        local char = game.Players.LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.JumpPower = value end
        end
    end,
})

MainTab:CreateSlider({
    Name = "Gravity",
    Description = "World gravity",
    Range = {0, 200},
    Increment = 5,
    CurrentValue = 196,
    Callback = function(value)
        workspace.Gravity = value
    end,
})

-- ============================================================
-- FEATURES TAB
-- ============================================================
local FeaturesTab = Window:CreateTab("Features", "⚡")

FeaturesTab:CreateSection("Player Features")

FeaturesTab:CreateToggle({
    Name = "ESP",
    Description = "Show player names and distance",
    CurrentValue = false,
    Callback = function(value)
        Rayfield._features = Rayfield._features or {}
        if not Rayfield._features then
            Rayfield._features = { ESP = { Enabled = false, Connections = {} } }
        end
        if value then
            -- Enable ESP
            local function addESP(player)
                if player == game.Players.LocalPlayer then return end
                local function onCharacter(char)
                    task.wait(1)
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    local bb = Instance.new("BillboardGui")
                    bb.Name = "RayfieldESP"
                    bb.Size = UDim2.new(0, 150, 0, 40)
                    bb.StudsOffset = Vector3.new(0, 3, 0)
                    bb.AlwaysOnTop = true
                    bb.Adornee = hrp
                    bb.Parent = hrp
                    local nl = Instance.new("TextLabel")
                    nl.Size = UDim2.new(1, 0, 0.5, 0)
                    nl.BackgroundTransparency = 1
                    nl.Text = player.Name
                    nl.TextColor3 = Color3.fromRGB(255, 80, 80)
                    nl.TextStrokeTransparency = 0.5
                    nl.Font = Enum.Font.GothamBold
                    nl.TextSize = 14
                    nl.Parent = bb
                    local dl = Instance.new("TextLabel")
                    dl.Name = "DistLabel"
                    dl.Size = UDim2.new(1, 0, 0.5, 0)
                    dl.Position = UDim2.new(0, 0, 0.5, 0)
                    dl.BackgroundTransparency = 1
                    dl.Text = ""
                    dl.TextColor3 = Color3.fromRGB(255, 255, 255)
                    dl.TextStrokeTransparency = 0.5
                    dl.Font = Enum.Font.Gotham
                    dl.TextSize = 12
                    dl.Parent = bb
                end
                if player.Character then onCharacter(player.Character) end
                player.CharacterAdded:Connect(onCharacter)
            end
            for _, p in ipairs(game.Players:GetPlayers()) do addESP(p) end
            Rayfield:Notify({ Title = "ESP", Content = "Enabled", Duration = 3, Type = "Success" })
        else
            for _, p in ipairs(game.Players:GetPlayers()) do
                if p.Character then
                    for _, v in ipairs(p.Character:GetDescendants()) do
                        if v.Name == "RayfieldESP" then v:Destroy() end
                    end
                end
            end
            Rayfield:Notify({ Title = "ESP", Content = "Disabled", Duration = 3, Type = "Warning" })
        end
    end,
})

FeaturesTab:CreateToggle({
    Name = "Anti-AFK",
    Description = "Prevents idle kicks",
    CurrentValue = false,
    Callback = function(value)
        if value then
            Rayfield._antiAFKConn = game.Players.LocalPlayer.Idled:Connect(function()
                game:GetService("VirtualUser"):CaptureController()
                game:GetService("VirtualUser"):ClickButton2(Vector2.new())
            end)
            Rayfield:Notify({ Title = "Anti-AFK", Content = "Enabled", Duration = 3, Type = "Success" })
        else
            if Rayfield._antiAFKConn then Rayfield._antiAFKConn:Disconnect() end
            Rayfield:Notify({ Title = "Anti-AFK", Content = "Disabled", Duration = 3, Type = "Warning" })
        end
    end,
})

FeaturesTab:CreateToggle({
    Name = "FPS Boost",
    Description = "Disable particles & shadows for performance",
    CurrentValue = false,
    Callback = function(value)
        if value then
            pcall(function()
                game.Lighting.FogEnd = 99999
                game.Lighting.GlobalShadows = false
                for _, v in ipairs(workspace:GetDescendants()) do
                    if v:IsA("ParticleEmitter") then v.Enabled = false end
                    if v:IsA("Trail") then v.Enabled = false end
                end
            end)
            Rayfield:Notify({ Title = "FPS Boost", Content = "Enabled", Duration = 3, Type = "Success" })
        else
            pcall(function()
                game.Lighting.FogEnd = 100000
                game.Lighting.GlobalShadows = true
                for _, v in ipairs(workspace:GetDescendants()) do
                    if v:IsA("ParticleEmitter") then v.Enabled = true end
                    if v:IsA("Trail") then v.Enabled = true end
                end
            end)
            Rayfield:Notify({ Title = "FPS Boost", Content = "Disabled", Duration = 3, Type = "Warning" })
        end
    end,
})

FeaturesTab:CreateSeparator()

FeaturesTab:CreateSection("Keybinds")

FeaturesTab:CreateKeybind({
    Name = "Toggle ESP",
    Description = "Press a key to toggle ESP",
    CurrentKey = "Q",
    Callback = function(key)
        print("ESP keybind set to:", key)
    end,
})

FeaturesTab:CreateKeybind({
    Name = "Toggle Console",
    Description = "Press a key to toggle console",
    CurrentKey = "F9",
    Callback = function(key)
        Rayfield:ToggleConsole()
    end,
})

-- ============================================================
-- SETTINGS TAB
-- ============================================================
local SettingsTab = Window:CreateTab("Settings", "⚙️")

SettingsTab:CreateSection("Appearance")

SettingsTab:CreateDropdown({
    Name = "Theme",
    Description = "Change the UI theme",
    Options = Rayfield:GetThemes(),
    CurrentValue = "Default",
    Callback = function(value)
        Rayfield:ChangeTheme(value)
    end,
})

SettingsTab:CreateSeparator()

SettingsTab:CreateSection("Session")

SettingsTab:CreateButton({
    Name = "Check for Updates",
    Description = "Manually check GitLab for new version",
    InteractText = "Check",
    Callback = function()
        local available, version = Rayfield:CheckForUpdates()
        if available then
            Rayfield:Notify({ Title = "Update Available", Content = "v" .. (version or "?") .. " is ready", Duration = 5, Type = "Info" })
        else
            Rayfield:Notify({ Title = "Up to Date", Content = "You have the latest version", Duration = 3, Type = "Success" })
        end
    end,
})

SettingsTab:CreateButton({
    Name = "Update Now",
    Description = "Download latest version from GitLab",
    InteractText = "Update",
    Callback = function()
        Rayfield:UpdateNow()
    end,
})

SettingsTab:CreateSeparator()

SettingsTab:CreateButton({
    Name = "Shutdown Session",
    Description = "Close everything",
    InteractText = "Shutdown",
    Callback = function()
        Rayfield:Shutdown()
    end,
})

-- ============================================================
-- SCRIPT HUB PRELOAD
-- ============================================================
Rayfield:AddToScriptHub({
    Name = "Infinite Yield",
    Description = "Admin command script",
    Author = "Edge",
    Code = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()',
})

Rayfield:AddToScriptHub({
    Name = "Dex Explorer",
    Description = "Game explorer tool",
    Author = "Moon",
    Code = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))()',
})

-- Log startup
Rayfield:LogToConsole("Rayfield Ultimate v" .. Rayfield:GetVersion() .. " loaded", "info")
Rayfield:LogToConsole("All systems operational", "info")
