--[[
    Rayfield Ultimate - Usage Example
    Copy this into your executor after loading the library
--]]

-- Load the library
local Rayfield = loadstring(game:HttpGet("https://gitlab.com/justsadnyx/Rayfield-Ultimate/-/raw/main/loadstring.lua"))()

-- Create the window
local Window = Rayfield:CreateWindow({
    Name = "My Script Hub",
    LoadingTitle = "Rayfield Ultimate",
    Theme = "Default", -- Default, Dark, Neon, Ocean, Mint
    Config = "MyScriptHub",
    KeySystem = {
        Keys = {"my-secret-key-123"},
        MaxAttempts = 3,
        Title = "Script Hub Key",
        KeyLink = "https://yourkeylink.com",
    }
})

-- Create tabs
local MainTab = Window:CreateTab("Main", "")
local SettingsTab = Window:CreateTab("Settings", "")
local ScriptHubTab = Window:CreateTab("Scripts", "")

-- Add elements to Main tab
MainTab:CreateSection("Main Features")

MainTab:CreateButton({
    Name = "Print Hello",
    Description = "Prints a message to console",
    InteractText = "Run",
    Callback = function()
        print("Hello from Rayfield Ultimate!")
        Rayfield:Notify({
            Title = "Executed",
            Content = "Printed hello message!",
            Duration = 3,
            Type = "Success",
        })
    end,
})

MainTab:CreateToggle({
    Name = "Auto Farm",
    Description = "Toggle auto farming on/off",
    CurrentValue = false,
    Callback = function(value)
        print("Auto Farm:", value)
    end,
})

MainTab:CreateSlider({
    Name = "Walk Speed",
    Description = "Adjust walk speed",
    Range = {0, 100},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(value)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
    end,
})

MainTab:CreateDropdown({
    Name = "Team",
    Description = "Select your team",
    Options = {"Red Team", "Blue Team", "Green Team"},
    CurrentValue = "Red Team",
    Callback = function(value)
        print("Selected team:", value)
    end,
})

MainTab:CreateInput({
    Name = "Player Name",
    Description = "Enter a player name",
    PlaceholderText = "Enter name...",
    Callback = function(value)
        print("Input:", value)
    end,
})

MainTab:CreateParagraph({
    Title = "About",
    Content = "This is Rayfield Ultimate - a custom UI library with Script Hub, Theme Engine, Key System, Console, Notifications, and more!",
})

-- Settings tab
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

SettingsTab:CreateButton({
    Name = "Open Console",
    Description = "Toggle the output console",
    InteractText = "Open",
    Callback = function()
        Rayfield:ToggleConsole()
    end,
})

SettingsTab:CreateButton({
    Name = "Open Script Hub",
    Description = "Browse scripts",
    InteractText = "Open",
    Callback = function()
        Rayfield:OpenScriptHub()
    end,
})

SettingsTab:CreateSeparator()

SettingsTab:CreateButton({
    Name = "Shutdown Session",
    Description = "Close everything and end the session",
    InteractText = "Shutdown",
    Callback = function()
        Rayfield:Shutdown()
    end,
})

-- Add scripts to Script Hub
Rayfield:AddToScriptHub({
    Name = "Infinite Yield",
    Description = "Admin command script",
    Author = "Edge",
    Code = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()',
    Tags = {"admin", "commands"},
})

Rayfield:AddToScriptHub({
    Name = "Dex Explorer",
    Description = "Game explorer tool",
    Author = "Moon",
    Code = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))()',
    Tags = {"explorer", "debug"},
})

-- Log to console
Rayfield:LogToConsole("Rayfield Ultimate loaded successfully!")
Rayfield:LogToConsole("Version: " .. Rayfield:GetVersion(), "info")

-- Check session
local session = Rayfield:GetSession()
if session then
    Rayfield:LogToConsole("Session active: " .. tostring(session.Active))
end
