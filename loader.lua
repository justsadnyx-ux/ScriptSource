--[[
    ScriptSource - Built on Rayfield
    Version: 1.0.0
    Uses the official Rayfield UI Library
--]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "ScriptSource v1.0.0",
    LoadingTitle = "ScriptSource",
    LoadingSubtitle = "Loading...",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "ScriptSource",
        FileName = "Config"
    },
    KeySystem = false,
})

-- ============================================================
-- UPDATES TAB
-- ============================================================
local UpdatesTab = Window:CreateTab("Updates", "🔄")

UpdatesTab:CreateSection("Version Status")

local currentVersion = "1.0.0"
local latestVersion = currentVersion
local updateAvailable = false

UpdatesTab:CreateParagraph({
    Title = "Current Version: v" .. currentVersion,
    Content = "Click below to check for updates from GitHub."
})

UpdatesTab:CreateButton({
    Name = "Check for Updates",
    Description = "Checks GitHub for a newer version",
    InteractText = "Check",
    Callback = function()
        local success, response = pcall(function()
            return game:HttpGet("https://raw.githubusercontent.com/justsadnyx-ux/ScriptSource/main/version.txt")
        end)
        if success and response then
            latestVersion = response:gsub("%s+", "")
            if latestVersion ~= currentVersion then
                updateAvailable = true
                Rayfield:Notify({
                    Title = "Update Available!",
                    Content = "v" .. latestVersion .. " is available. You have v" .. currentVersion,
                    Duration = 6,
                    Type = "Info",
                })
            else
                updateAvailable = false
                Rayfield:Notify({
                    Title = "Up to Date",
                    Content = "You're running the latest version (v" .. currentVersion .. ")",
                    Duration = 4,
                    Type = "Success",
                })
            end
        else
            Rayfield:Notify({
                Title = "Update Check Failed",
                Content = "Could not reach GitHub. Check your connection.",
                Duration = 4,
                Type = "Error",
            })
        end
    end,
})

UpdatesTab:CreateButton({
    Name = "Update Now",
    Description = "Fetches and executes the latest version",
    InteractText = "Update",
    Callback = function()
        if not updateAvailable then
            Rayfield:Notify({
                Title = "No Update",
                Content = "You're already on the latest version",
                Duration = 3,
                Type = "Warning",
            })
            return
        end
        Rayfield:Notify({
            Title = "Updating...",
            Content = "Fetching latest version from GitHub...",
            Duration = 3,
            Type = "Info",
        })
        local success, source = pcall(function()
            return game:HttpGet("https://raw.githubusercontent.com/justsadnyx-ux/ScriptSource/main/loader.lua")
        end)
        if success and source then
            Rayfield:Notify({
                Title = "Updated!",
                Content = "Version " .. latestVersion .. " downloaded. Execute the new loadstring to use it.",
                Duration = 6,
                Type = "Success",
            })
        else
            Rayfield:Notify({
                Title = "Update Failed",
                Content = "Could not download update.",
                Duration = 4,
                Type = "Error",
            })
        end
    end,
})

UpdatesTab:CreateSeparator()

UpdatesTab:CreateParagraph({
    Title = "Repository",
    Content = "https://github.com/justsadnyx-ux/ScriptSource"
})

-- ============================================================
-- MAIN TAB
-- ============================================================
local MainTab = Window:CreateTab("Main", "🏠")

MainTab:CreateSection("Quick Actions")

MainTab:CreateButton({
    Name = "Open Script Hub",
    Description = "Browse and execute scripts",
    InteractText = "Open",
    Callback = function()
        Rayfield:Notify({Title = "Script Hub", Content = "Add your scripts with Rayfield:CreateButton()", Duration = 3, Type = "Info"})
    end,
})

MainTab:CreateButton({
    Name = "Print Hello",
    Description = "Test callback",
    InteractText = "Run",
    Callback = function()
        print("ScriptSource: Hello!")
        Rayfield:Notify({Title = "Hello!", Content = "Callback executed successfully", Duration = 3, Type = "Success"})
    end,
})

MainTab:CreateSeparator()

MainTab:CreateSection("Character Mods")

MainTab:CreateToggle({
    Name = "Anti-AFK",
    Description = "Prevents idle kicks",
    CurrentValue = false,
    Callback = function(value)
        if value then
            _G._ScriptSource_AntiAFK = game.Players.LocalPlayer.Idled:Connect(function()
                game:GetService("VirtualUser"):CaptureController()
                game:GetService("VirtualUser"):ClickButton2(Vector2.new())
            end)
            Rayfield:Notify({Title = "Anti-AFK", Content = "Enabled", Duration = 3, Type = "Success"})
        else
            if _G._ScriptSource_AntiAFK then _G._ScriptSource_AntiAFK:Disconnect() end
            Rayfield:Notify({Title = "Anti-AFK", Content = "Disabled", Duration = 3, Type = "Warning"})
        end
    end,
})

MainTab:CreateToggle({
    Name = "ESP",
    Description = "Show player names and distance",
    CurrentValue = false,
    Callback = function(value)
        if value then
            local function addESP(player)
                if player == game.Players.LocalPlayer then return end
                local function onCharacter(char)
                    task.wait(1)
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    if hrp:FindFirstChild("ScriptSourceESP") then return end
                    local bb = Instance.new("BillboardGui")
                    bb.Name = "ScriptSourceESP"
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
                    dl.Name = "Dist"
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
            _G._ScriptSource_ESPAdded = game.Players.PlayerAdded:Connect(addESP)
            _G._ScriptSource_ESPUpdater = game:GetService("RunService").Heartbeat:Connect(function()
                local myHRP = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not myHRP then return end
                for _, p in ipairs(game.Players:GetPlayers()) do
                    if p ~= game.Players.LocalPlayer and p.Character then
                        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                        if hrp and hrp:FindFirstChild("ScriptSourceESP") then
                            local d = hrp:FindFirstChild("ScriptSourceESP"):FindFirstChild("Dist")
                            if d then d.Text = math.floor((myHRP.Position - hrp.Position).Magnitude) .. " studs" end
                        end
                    end
                end
            end)
            Rayfield:Notify({Title = "ESP", Content = "Enabled", Duration = 3, Type = "Success"})
        else
            if _G._ScriptSource_ESPAdded then _G._ScriptSource_ESPAdded:Disconnect() end
            if _G._ScriptSource_ESPUpdater then _G._ScriptSource_ESPUpdater:Disconnect() end
            for _, p in ipairs(game.Players:GetPlayers()) do
                if p.Character then
                    for _, v in ipairs(p.Character:GetDescendants()) do
                        if v.Name == "ScriptSourceESP" then v:Destroy() end
                    end
                end
            end
            Rayfield:Notify({Title = "ESP", Content = "Disabled", Duration = 3, Type = "Warning"})
        end
    end,
})

MainTab:CreateToggle({
    Name = "FPS Boost",
    Description = "Disable particles and shadows",
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
            Rayfield:Notify({Title = "FPS Boost", Content = "Enabled", Duration = 3, Type = "Success"})
        else
            pcall(function()
                game.Lighting.FogEnd = 100000
                game.Lighting.GlobalShadows = true
                for _, v in ipairs(workspace:GetDescendants()) do
                    if v:IsA("ParticleEmitter") then v.Enabled = true end
                    if v:IsA("Trail") then v.Enabled = true end
                end
            end)
            Rayfield:Notify({Title = "FPS Boost", Content = "Disabled", Duration = 3, Type = "Warning"})
        end
    end,
})

MainTab:CreateSeparator()

MainTab:CreateSlider({
    Name = "Walk Speed",
    Description = "Change walk speed",
    Range = {16, 200},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(value)
        local c = game.Players.LocalPlayer.Character
        if c then local h = c:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed = value end end
    end,
})

MainTab:CreateSlider({
    Name = "Jump Power",
    Description = "Change jump power",
    Range = {50, 300},
    Increment = 5,
    CurrentValue = 50,
    Callback = function(value)
        local c = game.Players.LocalPlayer.Character
        if c then local h = c:FindFirstChildOfClass("Humanoid"); if h then h.JumpPower = value end end
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
-- SETTINGS TAB
-- ============================================================
local SettingsTab = Window:CreateTab("Settings", "⚙️")

SettingsTab:CreateSection("Appearance")

SettingsTab:CreateDropdown({
    Name = "Theme",
    Description = "Change UI theme",
    Options = {"Default", "Dark", "Blood", "Pure Blue", "Dark Blue", "Grape", "Ocean", "Light", "AmberGlow", "Mint"},
    CurrentValue = "Default",
    Callback = function(value)
        Rayfield:Notify({Title = "Theme", Content = "Switch to " .. value .. " (reloads on next open)", Duration = 3, Type = "Info"})
    end,
})

SettingsTab:CreateSection("Session")

SettingsTab:CreateButton({
    Name = "Shutdown UI",
    Description = "Close everything",
    InteractText = "Close",
    Callback = function()
        Rayfield:Destroy()
    end,
})

Rayfield:Notify({
    Title = "ScriptSource",
    Content = "v" .. currentVersion .. " loaded successfully!",
    Duration = 4,
    Type = "Success",
})
