local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "ScriptSource v1.1.0",
    LoadingTitle = "ScriptSource",
    LoadingSubtitle = "Loading...",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "ScriptSource",
        FileName = "Config"
    },
    KeySystem = false,
})

local MainTab = Window:CreateTab("Main", nil)
local MainSection = MainTab:CreateSection("Quick Actions")

MainTab:CreateButton({
    Name = "Print Hello",
    Callback = function()
        Rayfield:Notify({Title = "ScriptSource", Content = "Hello from ScriptSource!", Duration = 3})
    end,
})

MainSection = MainTab:CreateSection("Character Mods")

MainTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 200},
    Increment = 1,
    CurrentValue = 16,
    Flag = "WalkSpeed",
    Callback = function(v)
        local c = game.Players.LocalPlayer.Character
        if c then local h = c:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed = v end end
    end,
})

MainTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 300},
    Increment = 5,
    CurrentValue = 50,
    Flag = "JumpPower",
    Callback = function(v)
        local c = game.Players.LocalPlayer.Character
        if c then local h = c:FindFirstChildOfClass("Humanoid"); if h then h.JumpPower = v end end
    end,
})

MainTab:CreateSlider({
    Name = "Gravity",
    Range = {0, 200},
    Increment = 5,
    CurrentValue = 196,
    Flag = "Gravity",
    Callback = function(v)
        workspace.Gravity = v
    end,
})

local FeaturesTab = Window:CreateTab("Features", nil)
local FeaturesSection = FeaturesTab:CreateSection("Toggles")

FeaturesTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = false,
    Flag = "AntiAFK",
    Callback = function(v)
        if v then
            _G._SS_AntiAFK = game.Players.LocalPlayer.Idled:Connect(function()
                game:GetService("VirtualUser"):CaptureController()
                game:GetService("VirtualUser"):ClickButton2(Vector2.new())
            end)
            Rayfield:Notify({Title = "Anti-AFK", Content = "Enabled", Duration = 3})
        else
            if _G._SS_AntiAFK then _G._SS_AntiAFK:Disconnect() end
            Rayfield:Notify({Title = "Anti-AFK", Content = "Disabled", Duration = 3})
        end
    end,
})

FeaturesTab:CreateToggle({
    Name = "ESP",
    CurrentValue = false,
    Flag = "ESP",
    Callback = function(v)
        if v then
            local function addESP(plr)
                if plr == game.Players.LocalPlayer then return end
                local function onChar(char)
                    task.wait(1)
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if not hrp or hrp:FindFirstChild("SS_ESP") then return end
                    local bb = Instance.new("BillboardGui", hrp)
                    bb.Name = "SS_ESP"
                    bb.Size = UDim2.new(0, 150, 0, 40)
                    bb.StudsOffset = Vector3.new(0, 3, 0)
                    bb.AlwaysOnTop = true
                    local n = Instance.new("TextLabel", bb)
                    n.Size = UDim2.new(1, 0, 0.5, 0)
                    n.BackgroundTransparency = 1
                    n.Text = plr.Name
                    n.TextColor3 = Color3.fromRGB(255, 80, 80)
                    n.TextStrokeTransparency = 0.5
                    n.Font = Enum.Font.GothamBold
                    n.TextSize = 14
                    local d = Instance.new("TextLabel", bb)
                    d.Name = "Dist"
                    d.Size = UDim2.new(1, 0, 0.5, 0)
                    d.Position = UDim2.new(0, 0, 0.5, 0)
                    d.BackgroundTransparency = 1
                    d.Text = ""
                    d.TextColor3 = Color3.fromRGB(255, 255, 255)
                    d.TextStrokeTransparency = 0.5
                    d.Font = Enum.Font.Gotham
                    d.TextSize = 12
                end
                if plr.Character then onChar(plr.Character) end
                plr.CharacterAdded:Connect(onChar)
            end
            for _, p in ipairs(game.Players:GetPlayers()) do addESP(p) end
            _G._SS_ESPJoin = game.Players.PlayerAdded:Connect(addESP)
            _G._SS_ESPUpdate = game:GetService("RunService").Heartbeat:Connect(function()
                local myHRP = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not myHRP then return end
                for _, p in ipairs(game.Players:GetPlayers()) do
                    if p ~= game.Players.LocalPlayer and p.Character then
                        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                        if hrp and hrp:FindFirstChild("SS_ESP") then
                            local d = hrp.SS_ESP:FindFirstChild("Dist")
                            if d then d.Text = math.floor((myHRP.Position - hrp.Position).Magnitude) .. " studs" end
                        end
                    end
                end
            end)
            Rayfield:Notify({Title = "ESP", Content = "Enabled", Duration = 3})
        else
            if _G._SS_ESPJoin then _G._SS_ESPJoin:Disconnect() end
            if _G._SS_ESPUpdate then _G._SS_ESPUpdate:Disconnect() end
            for _, p in ipairs(game.Players:GetPlayers()) do
                if p.Character then for _, v in ipairs(p.Character:GetDescendants()) do if v.Name == "SS_ESP" then v:Destroy() end end end
            end
            Rayfield:Notify({Title = "ESP", Content = "Disabled", Duration = 3})
        end
    end,
})

FeaturesTab:CreateToggle({
    Name = "FPS Boost",
    CurrentValue = false,
    Flag = "FPSBoost",
    Callback = function(v)
        if v then
            pcall(function()
                game.Lighting.FogEnd = 99999
                game.Lighting.GlobalShadows = false
                for _, x in ipairs(workspace:GetDescendants()) do
                    if x:IsA("ParticleEmitter") then x.Enabled = false end
                    if x:IsA("Trail") then x.Enabled = false end
                end
            end)
            Rayfield:Notify({Title = "FPS Boost", Content = "Enabled", Duration = 3})
        else
            pcall(function()
                game.Lighting.FogEnd = 100000
                game.Lighting.GlobalShadows = true
                for _, x in ipairs(workspace:GetDescendants()) do
                    if x:IsA("ParticleEmitter") then x.Enabled = true end
                    if x:IsA("Trail") then x.Enabled = true end
                end
            end)
            Rayfield:Notify({Title = "FPS Boost", Content = "Disabled", Duration = 3})
        end
    end,
})

local UpdatesTab = Window:CreateTab("Updates", nil)
local UpdatesSection = UpdatesTab:CreateSection("Version")

UpdatesTab:CreateParagraph({
    Title = "ScriptSource v1.1.0",
    Content = "Check for updates from GitHub."
})

UpdatesTab:CreateButton({
    Name = "Check for Updates",
    Callback = function()
        local ok, ver = pcall(function()
            return game:HttpGet("https://raw.githubusercontent.com/justsadnyx-ux/ScriptSource/main/version.txt")
        end)
        if ok and ver and ver:gsub("%s+", "") ~= "1.1.0" then
            Rayfield:Notify({Title = "Update Available", Content = "v" .. ver:gsub("%s+", "") .. " is ready!", Duration = 6})
        elseif ok then
            Rayfield:Notify({Title = "Up to Date", Content = "You have the latest version", Duration = 3})
        else
            Rayfield:Notify({Title = "Check Failed", Content = "Could not reach GitHub", Duration = 3})
        end
    end,
})

UpdatesTab:CreateButton({
    Name = "Update Now",
    Callback = function()
        Rayfield:Notify({Title = "Updating...", Content = "Fetching latest version...", Duration = 3})
        task.delay(1, function()
            Rayfield:Destroy()
            task.wait(0.5)
            local ok, src = pcall(function()
                return game:HttpGet("https://raw.githubusercontent.com/justsadnyx-ux/ScriptSource/main/loader.lua")
            end)
            if ok and src then
                loadstring(src)()
            end
        end)
    end,
})

local SettingsTab = Window:CreateTab("Settings", nil)
SettingsTab:CreateSection("Appearance")

SettingsTab:CreateDropdown({
    Name = "Theme",
    Options = {"Default", "Ocean", "AmberGlow", "Light", "Amethyst", "DarkBlue", "Bloom", "Serenity"},
    CurrentValue = "Default",
    Flag = "Theme",
    Callback = function(v)
        Rayfield:Notify({Title = "Theme", Content = "Switched to " .. v, Duration = 3})
    end,
})

SettingsTab:CreateSection("Session")

SettingsTab:CreateButton({
    Name = "Shutdown UI",
    Callback = function()
        Rayfield:Destroy()
    end,
})

Rayfield:LoadConfiguration()

Rayfield:Notify({Title = "ScriptSource", Content = "v1.1.0 loaded successfully!", Duration = 4})
