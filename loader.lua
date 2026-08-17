local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local OWNER = "HOPOUTHECUPE2"
local IsOwner = LocalPlayer.Name == OWNER
local SS_PREFIX = "SS_"
local LIFETIME_KEY = "KEY20291"
local KEY_SECRET = "x7k9m2p4"

pcall(function()
    if ReplicatedStorage:GetAttribute(SS_PREFIX .. "Active_" .. LocalPlayer.UserId) then return end
    ReplicatedStorage:SetAttribute(SS_PREFIX .. "Active_" .. LocalPlayer.UserId, true)
end)

local function cleanUpPlayer()
    pcall(function()
        ReplicatedStorage:SetAttribute(SS_PREFIX .. "User_" .. LocalPlayer.UserId, nil)
        ReplicatedStorage:SetAttribute(SS_PREFIX .. "Active_" .. LocalPlayer.UserId, nil)
        ReplicatedStorage:SetAttribute(SS_PREFIX .. "Bomb_" .. LocalPlayer.UserId, nil)
        ReplicatedStorage:SetAttribute(SS_PREFIX .. "Shutdown_" .. LocalPlayer.UserId, nil)
    end)
    pcall(function()
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if pg then for _, v in ipairs(pg:GetChildren()) do if v.Name == "ScriptSource" then v:Destroy() end end end
    end)
end

local function simpleHash(str)
    local h = 0
    for i = 1, #str do h = (h * 31 + string.byte(str, i)) % 999999 end
    return h
end

local function b64Encode(data)
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    return (data:gsub(".", function(x)
        local r, b = "", x:byte()
        for i = 8, 1, -1 do r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and "1" or "0") end
        return r
    end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
        if #x ~= 6 then return chars:sub(65, 64) end
        local c = 0
        for i = 1, 6 do c = c + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0) end
        return chars:sub(c + 1, c + 1)
    end) .. ({ "", "==", "=" })[#data % 3 + 1]
end

local function b64Decode(data)
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    data = string.gsub(data, "[^" .. chars .. "=]", "")
    return (data:gsub(".", function(x)
        if x == "=" then return "" end
        local r, f = "", (chars:find(x) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0") end
        return r
    end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
        if #x ~= 8 then return "" end
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0) end
        return string.char(c)
    end))
end

local function generateKey(name, hours)
    local expiry = os.time() + (hours * 3600)
    local payload = string.lower(name) .. "|" .. tostring(expiry)
    local checksum = simpleHash(payload .. KEY_SECRET)
    return "SS-" .. b64Encode(payload .. "|" .. tostring(checksum))
end

local function validateKey(key)
    if not key or key == "" then return false, "Empty key" end
    if key == LIFETIME_KEY then return true, "Lifetime key" end
    if not key:find("^SS%-") then return false, "Invalid format" end
    local raw = b64Decode(key:sub(4))
    if not raw or raw == "" then return false, "Invalid encoding" end
    local name, expiry, checksum = raw:match("^(%S+)|(%d+)|(%d+)$")
    if not name or not expiry or not checksum then return false, "Corrupted key" end
    expiry, checksum = tonumber(expiry), tonumber(checksum)
    if not expiry or not checksum then return false, "Invalid data" end
    if string.lower(name) ~= string.lower(LocalPlayer.Name) then return false, "Device mismatch - key bound to " .. name end
    if os.time() > expiry then return false, "Key expired" end
    if checksum ~= simpleHash(string.lower(name) .. "|" .. tostring(expiry) .. KEY_SECRET) then return false, "Invalid checksum" end
    return true, "Valid"
end

local savedKey = nil
pcall(function() savedKey = _G._SS_Key end)
local keyValid = false
if savedKey then
    local ok = validateKey(savedKey)
    if ok then keyValid = true else pcall(function() _G._SS_Key = nil end) end
end
if IsOwner then keyValid = true end

pcall(function()
    if not keyValid then
        local ok, data = pcall(function() return game:HttpGet("https://raw.githubusercontent.com/justsadnyx-ux/ScriptSource/main/winners.txt") end)
        if ok and data then
            for line in data:gmatch("[^\r\n]+") do
                local name = line:match("^%s*(.-)%s*$")
                if name and name ~= "" and string.lower(name) == string.lower(LocalPlayer.Name) then
                    keyValid = true
                    break
                end
            end
        end
    end
end)

local function startUI()
    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

    local Window = Rayfield:CreateWindow({
        Name = "ScriptSource v1.8.0",
        LoadingTitle = "ScriptSource",
        LoadingSubtitle = IsOwner and "Owner Mode" or (keyValid and "Unlocked" or "Enter Key"),
        ConfigurationSaving = { Enabled = true, FolderName = "ScriptSource", FileName = "Config" },
        KeySystem = false,
    })

    if keyValid then
        -- KEY TAB (shows unlocked status, no input needed)
        local KeyTab = Window:CreateTab("Key", nil)
        KeyTab:CreateSection("Authentication")
        KeyTab:CreateParagraph({ Title = "Unlocked", Content = "All features are unlocked. Enjoy!" })

        -- MAIN TAB
        local MainTab = Window:CreateTab("Main", nil)
        MainTab:CreateSection("Character Mods")
        MainTab:CreateSlider({
            Name = "Walk Speed", Range = {16, 200}, Increment = 1, CurrentValue = 16, Flag = "WalkSpeed",
            Callback = function(v) local c = LocalPlayer.Character; if c then local h = c:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed = v end end end,
        })
        MainTab:CreateSlider({
            Name = "Jump Power", Range = {50, 300}, Increment = 5, CurrentValue = 50, Flag = "JumpPower",
            Callback = function(v) local c = LocalPlayer.Character; if c then local h = c:FindFirstChildOfClass("Humanoid"); if h then h.JumpPower = v end end end,
        })
        MainTab:CreateSlider({
            Name = "Gravity", Range = {0, 200}, Increment = 5, CurrentValue = 196, Flag = "Gravity",
            Callback = function(v) workspace.Gravity = v end,
        })

        -- FEATURES TAB
        local FeaturesTab = Window:CreateTab("Features", nil)
        FeaturesTab:CreateSection("Toggles")
        FeaturesTab:CreateToggle({
            Name = "Anti-AFK", CurrentValue = false, Flag = "AntiAFK",
            Callback = function(v)
                if v then
                    _G._SS_AntiAFK = LocalPlayer.Idled:Connect(function()
                        game:GetService("VirtualUser"):CaptureController()
                        game:GetService("VirtualUser"):ClickButton2(Vector2.new())
                    end)
                    Rayfield:Notify({ Title = "Anti-AFK", Content = "Enabled", Duration = 3 })
                else
                    if _G._SS_AntiAFK then _G._SS_AntiAFK:Disconnect() end
                    Rayfield:Notify({ Title = "Anti-AFK", Content = "Disabled", Duration = 3 })
                end
            end,
        })
        FeaturesTab:CreateToggle({
            Name = "ESP (Name + Distance)", CurrentValue = false, Flag = "ESP",
            Callback = function(v)
                if v then
                    local function addESP(plr)
                        if plr == LocalPlayer then return end
                        local function onChar(char)
                            task.wait(1)
                            local hrp = char:FindFirstChild("HumanoidRootPart")
                            if not hrp or hrp:FindFirstChild("SS_ESP") then return end
                            local bb = Instance.new("BillboardGui", hrp)
                            bb.Name = "SS_ESP"; bb.Size = UDim2.new(0, 150, 0, 40); bb.StudsOffset = Vector3.new(0, 3, 0); bb.AlwaysOnTop = true
                            local n = Instance.new("TextLabel", bb)
                            n.Size = UDim2.new(1, 0, 0.5, 0); n.BackgroundTransparency = 1; n.Text = plr.Name
                            n.TextColor3 = Color3.fromRGB(255, 80, 80); n.TextStrokeTransparency = 0.5; n.Font = Enum.Font.GothamBold; n.TextSize = 14
                            local d = Instance.new("TextLabel", bb)
                            d.Name = "Dist"; d.Size = UDim2.new(1, 0, 0.5, 0); d.Position = UDim2.new(0, 0, 0.5, 0); d.BackgroundTransparency = 1; d.Text = ""
                            d.TextColor3 = Color3.new(1, 1, 1); d.TextStrokeTransparency = 0.5; d.Font = Enum.Font.Gotham; d.TextSize = 12
                        end
                        if plr.Character then onChar(plr.Character) end
                        plr.CharacterAdded:Connect(onChar)
                    end
                    for _, p in ipairs(Players:GetPlayers()) do addESP(p) end
                    _G._SS_ESPJoin = Players.PlayerAdded:Connect(addESP)
                    _G._SS_ESPUpdate = RunService.Heartbeat:Connect(function()
                        local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if not myHRP then return end
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p ~= LocalPlayer and p.Character then
                                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                                if hrp and hrp:FindFirstChild("SS_ESP") then
                                    local d = hrp.SS_ESP:FindFirstChild("Dist")
                                    if d then d.Text = math.floor((myHRP.Position - hrp.Position).Magnitude) .. " studs" end
                                end
                            end
                        end
                    end)
                    Rayfield:Notify({ Title = "ESP", Content = "Enabled", Duration = 3 })
                else
                    if _G._SS_ESPJoin then _G._SS_ESPJoin:Disconnect() end
                    if _G._SS_ESPUpdate then _G._SS_ESPUpdate:Disconnect() end
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p.Character then for _, x in ipairs(p.Character:GetDescendants()) do if x.Name == "SS_ESP" then x:Destroy() end end end
                    end
                    Rayfield:Notify({ Title = "ESP", Content = "Disabled", Duration = 3 })
                end
            end,
        })
        FeaturesTab:CreateToggle({
            Name = "Grid ESP (Red Outline)", CurrentValue = false, Flag = "GridESP",
            Callback = function(v)
                if v then
                    _G._SS_GridESP = RunService.RenderStepped:Connect(function()
                        for _, player in pairs(Players:GetPlayers()) do
                            if player ~= LocalPlayer and player.Character then
                                for _, part in pairs(player.Character:GetChildren()) do
                                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                                        if not part:FindFirstChild("SS_GridESP") then
                                            local box = Instance.new("SelectionBox")
                                            box.Name = "SS_GridESP"
                                            box.Adornee = part
                                            box.Color3 = Color3.fromRGB(255, 0, 0)
                                            box.LineThickness = 0.04
                                            box.Transparency = 0
                                            box.SurfaceColor3 = Color3.fromRGB(255, 0, 0)
                                            box.SurfaceTransparency = 1
                                            box.Parent = part
                                        end
                                    end
                                end
                            end
                        end
                    end)
                    Rayfield:Notify({ Title = "Grid ESP", Content = "Enabled", Duration = 3 })
                else
                    if _G._SS_GridESP then _G._SS_GridESP:Disconnect() end
                    for _, player in pairs(Players:GetPlayers()) do
                        if player.Character then
                            for _, part in pairs(player.Character:GetDescendants()) do
                                if part.Name == "SS_GridESP" then part:Destroy() end
                            end
                        end
                    end
                    Rayfield:Notify({ Title = "Grid ESP", Content = "Disabled", Duration = 3 })
                end
            end,
        })
        FeaturesTab:CreateToggle({
            Name = "Infinite Jump", CurrentValue = false, Flag = "InfJump",
            Callback = function(v)
                if v then
                    _G._SS_InfJump = UserInputService.JumpRequest:Connect(function()
                        local Char = LocalPlayer.Character
                        if Char and Char:FindFirstChildOfClass("Humanoid") then
                            Char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                        end
                    end)
                    Rayfield:Notify({ Title = "Infinite Jump", Content = "Enabled", Duration = 3 })
                else
                    if _G._SS_InfJump then _G._SS_InfJump:Disconnect() end
                    Rayfield:Notify({ Title = "Infinite Jump", Content = "Disabled", Duration = 3 })
                end
            end,
        })
        FeaturesTab:CreateToggle({
            Name = "Noclip", CurrentValue = false, Flag = "Noclip",
            Callback = function(v)
                if v then
                    _G._SS_Noclip = RunService.Stepped:Connect(function()
                        if LocalPlayer.Character then
                            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                                if part:IsA("BasePart") then part.CanCollide = false end
                            end
                        end
                    end)
                    Rayfield:Notify({ Title = "Noclip", Content = "Enabled", Duration = 3 })
                else
                    if _G._SS_Noclip then _G._SS_Noclip:Disconnect() end
                    Rayfield:Notify({ Title = "Noclip", Content = "Disabled", Duration = 3 })
                end
            end,
        })
        FeaturesTab:CreateToggle({
            Name = "Speed Boost", CurrentValue = false, Flag = "SpeedBoost",
            Callback = function(v)
                local c = LocalPlayer.Character
                if c and c:FindFirstChildOfClass("Humanoid") then
                    c.Humanoid.WalkSpeed = v and 30 or 16
                end
                Rayfield:Notify({ Title = "Speed Boost", Content = v and "Enabled (30)" or "Disabled (16)", Duration = 3 })
            end,
        })
        FeaturesTab:CreateToggle({
            Name = "FPS Boost", CurrentValue = false, Flag = "FPSBoost",
            Callback = function(v)
                if v then
                    pcall(function()
                        game.Lighting.FogEnd = 99999; game.Lighting.GlobalShadows = false
                        for _, x in ipairs(workspace:GetDescendants()) do
                            if x:IsA("ParticleEmitter") then x.Enabled = false end
                            if x:IsA("Trail") then x.Enabled = false end
                        end
                    end)
                    Rayfield:Notify({ Title = "FPS Boost", Content = "Enabled", Duration = 3 })
                else
                    pcall(function()
                        game.Lighting.FogEnd = 100000; game.Lighting.GlobalShadows = true
                        for _, x in ipairs(workspace:GetDescendants()) do
                            if x:IsA("ParticleEmitter") then x.Enabled = true end
                            if x:IsA("Trail") then x.Enabled = true end
                        end
                    end)
                    Rayfield:Notify({ Title = "FPS Boost", Content = "Disabled", Duration = 3 })
                end
            end,
        })

        -- BOMB GAME TAB
        local BombTab = Window:CreateTab("Bomb Game", nil)

        local AutoPassEnabled = false
        local TriggerTime = 3
        local IsPassing = false
        local bombActive = false
        local bombTime = 3
        local bombGui = nil
        local bombConn = nil

        local function DoIHaveBomb()
            local Char = LocalPlayer.Character
            if not Char then return false end
            for _, v in pairs(Char:GetChildren()) do
                if v:IsA("BillboardGui") or v:IsA("Highlight") then return true end
            end
            for _, v in pairs(Char:GetChildren()) do
                if v:IsA("Tool") and (v.Name:lower():find("bomb") or v.Name:lower():find("tnt")) then return true end
            end
            if ReplicatedStorage:GetAttribute(SS_PREFIX .. "Bomb_" .. LocalPlayer.UserId) then return true end
            return false
        end

        local function GetNearestPlayer()
            local MyRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not MyRoot then return nil end
            local closest, dist = nil, math.huge
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        local d = (MyRoot.Position - p.Character.HumanoidRootPart.Position).Magnitude
                        if d < dist then dist = d; closest = p.Character.HumanoidRootPart end
                    end
                end
            end
            return closest
        end

        local function ExecutePass()
            if IsPassing then return end
            IsPassing = true
            local Root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not Root then IsPassing = false return end
            local Target = GetNearestPlayer()
            if not Target then IsPassing = false return end
            local Safe = Root.CFrame
            local t0 = tick()
            while DoIHaveBomb() and (tick() - t0 < 4) do
                if Target and Target.Parent then Root.CFrame = Target.CFrame end
                RunService.Heartbeat:Wait()
            end
            Root.CFrame = Safe
            task.wait(0.5)
            IsPassing = false
        end

        local function MonitorTimer()
            if not AutoPassEnabled or IsPassing then return end
            if not DoIHaveBomb() then return end
            local Char = LocalPlayer.Character
            if not Char then return end
            for _, v in pairs(Char:GetDescendants()) do
                if v:IsA("TextLabel") and v.Visible then
                    local num = tonumber(v.Text:match("%d+%.?%d*"))
                    if num and num > 0 and num <= 60 and num <= TriggerTime then
                        ExecutePass()
                        return
                    end
                end
            end
        end

        RunService.Heartbeat:Connect(MonitorTimer)

        local function showBombUI(name, time)
            pcall(function() if bombGui then bombGui:Destroy() end end)
            local sg = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
            sg.Name = "SS_BombUI"; sg.ResetOnSpawn = false; bombGui = sg
            local f = Instance.new("Frame", sg)
            f.Size = UDim2.new(0, 220, 0, 80); f.Position = UDim2.new(0.5, -110, 0, 10)
            f.BackgroundColor3 = Color3.fromRGB(180, 30, 30); f.BorderSizePixel = 0; f.Active = true; f.Draggable = true
            Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
            local t1 = Instance.new("TextLabel", f)
            t1.Size = UDim2.new(1, -10, 0, 30); t1.Position = UDim2.new(0, 5, 0, 5); t1.BackgroundTransparency = 1
            t1.Text = "BOMB: " .. name; t1.TextColor3 = Color3.new(1, 1, 1); t1.Font = Enum.Font.GothamBold; t1.TextSize = 16
            local t2 = Instance.new("TextLabel", f)
            t2.Name = "Timer"; t2.Size = UDim2.new(1, -10, 0, 35); t2.Position = UDim2.new(0, 5, 0, 35); t2.BackgroundTransparency = 1
            t2.Text = tostring(time) .. "s"; t2.TextColor3 = Color3.fromRGB(255, 200, 50); t2.Font = Enum.Font.Code; t2.TextSize = 28
        end

        local function destroyBombUI() pcall(function() if bombGui then bombGui:Destroy(); bombGui = nil end end) end

        BombTab:CreateSection("Bomb Control")
        BombTab:CreateToggle({
            Name = "Auto-Pass", CurrentValue = false, Flag = "AutoPass",
            Callback = function(v) AutoPassEnabled = v; Rayfield:Notify({ Title = "Bomb", Content = v and "Auto-Pass enabled" or "Auto-Pass disabled", Duration = 3 }) end,
        })
        BombTab:CreateSlider({
            Name = "Trigger When Timer Hits", Range = {1, 8}, Increment = 0.5, Suffix = "s", CurrentValue = 3, Flag = "TriggerTime",
            Callback = function(v) TriggerTime = v end,
        })
        BombTab:CreateButton({
            Name = "Force Transfer (Nearest)",
            Callback = function() ExecutePass() end,
        })
        BombTab:CreateSlider({
            Name = "Manual Bomb Timer", Range = {1, 8}, Increment = 1, CurrentValue = 3, Flag = "BombTimer",
            Callback = function(v) bombTime = v end,
        })
        BombTab:CreateParagraph({ Title = "Manual Bomb", Content = "Start a bomb timer manually. Pass it before it hits 0." })
        BombTab:CreateButton({
            Name = "Start Bomb",
            Callback = function()
                if bombActive then Rayfield:Notify({ Title = "Bomb", Content = "Already active!", Duration = 3 }); return end
                bombActive = true
                ReplicatedStorage:SetAttribute(SS_PREFIX .. "Bomb_" .. LocalPlayer.UserId, true)
                showBombUI(LocalPlayer.Name, bombTime)
                Rayfield:Notify({ Title = "Bomb", Content = "Started! " .. bombTime .. "s", Duration = 4 })
                local rem = bombTime
                bombConn = RunService.Heartbeat:Connect(function(dt)
                    if not bombActive then if bombConn then bombConn:Disconnect(); bombConn = nil end; return end
                    rem = rem - dt
                    if bombGui and bombGui:FindFirstChild("Timer", true) then
                        bombGui:FindFirstChild("Timer", true).Text = math.max(0, math.ceil(rem)) .. "s"
                    end
                    if rem <= 2 and bombGui and bombGui:FindFirstChild("Timer", true) then
                        bombGui:FindFirstChild("Timer", true).TextColor3 = Color3.fromRGB(255, 50, 50)
                    end
                    if rem <= 0 then
                        bombActive = false
                        if bombConn then bombConn:Disconnect(); bombConn = nil end
                        ReplicatedStorage:SetAttribute(SS_PREFIX .. "Bomb_" .. LocalPlayer.UserId, nil)
                        destroyBombUI()
                        local tgt = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                        if tgt then tgt.Health = 0 end
                        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local fire = Instance.new("Fire", hrp); fire.Size = 20; fire.Heat = 10
                            task.delay(2, function() pcall(function() fire:Destroy() end) end)
                        end
                        Rayfield:Notify({ Title = "BOOM!", Content = "You exploded!", Duration = 5 })
                    end
                end)
            end,
        })
        BombTab:CreateButton({
            Name = "Stop Bomb",
            Callback = function()
                if not bombActive then return end
                bombActive = false
                if bombConn then bombConn:Disconnect(); bombConn = nil end
                ReplicatedStorage:SetAttribute(SS_PREFIX .. "Bomb_" .. LocalPlayer.UserId, nil)
                destroyBombUI()
                Rayfield:Notify({ Title = "Bomb", Content = "Defused!", Duration = 3 })
            end,
        })

        -- POLL TAB
        local PollTab = Window:CreateTab("Poll", nil)
        PollTab:CreateSection("Vote")
        PollTab:CreateParagraph({ Title = "Live Poll", Content = "When the owner starts a poll, vote here." })
        PollTab:CreateDropdown({
            Name = "Vote",
            Options = (function()
                local opts = ReplicatedStorage:GetAttribute(SS_PREFIX .. "Poll_Opts") or ""
                local t = {}
                for o in opts:gmatch("[^,]+") do table.insert(t, o) end
                if #t == 0 then table.insert(t, "No active poll") end
                return t
            end)(),
            CurrentValue = "No active poll", Flag = "PollVote",
            Callback = function(v)
                if v == "No active poll" then return end
                if not ReplicatedStorage:GetAttribute(SS_PREFIX .. "Poll_Active") then
                    Rayfield:Notify({ Title = "Poll", Content = "No active poll!", Duration = 3 }); return
                end
                local existing = ReplicatedStorage:GetAttribute(SS_PREFIX .. "Poll_Votes") or ""
                local newVotes = existing == "" and (LocalPlayer.Name .. ":" .. v) or existing .. ";" .. LocalPlayer.Name .. ":" .. v
                ReplicatedStorage:SetAttribute(SS_PREFIX .. "Poll_Votes", newVotes)
                Rayfield:Notify({ Title = "Poll", Content = "Voted: " .. v, Duration = 3 })
            end,
        })

        -- SETTINGS TAB
        local SettingsTab = Window:CreateTab("Settings", nil)
        SettingsTab:CreateSection("Appearance")
        SettingsTab:CreateDropdown({
            Name = "Theme",
            Options = { "Default", "Ocean", "AmberGlow", "Light", "Amethyst", "DarkBlue", "Bloom", "Serenity" },
            CurrentValue = "Default", Flag = "Theme",
            Callback = function(v) Rayfield:Notify({ Title = "Theme", Content = "Switched to " .. v, Duration = 3 }) end,
        })
        SettingsTab:CreateSection("Session")
        SettingsTab:CreateButton({
            Name = "Shutdown UI",
            Callback = function() cleanUpPlayer(); Rayfield:Destroy() end,
        })
        SettingsTab:CreateButton({
            Name = "Reload Script",
            Callback = function()
                cleanUpPlayer(); Rayfield:Destroy(); task.wait(0.5)
                local ok, src = pcall(function() return game:HttpGet("https://raw.githubusercontent.com/justsadnyx-ux/ScriptSource/main/loader.lua") end)
                if ok and src then loadstring(src)() end
            end,
        })

        -- UPDATES TAB (always unlocked)
        local UpdatesTab = Window:CreateTab("Updates", nil)
        UpdatesTab:CreateSection("Version")
        UpdatesTab:CreateParagraph({ Title = "ScriptSource v1.8.0", Content = "Check for updates from GitHub." })
        UpdatesTab:CreateButton({
            Name = "Check for Updates",
            Callback = function()
                local ok, ver = pcall(function() return game:HttpGet("https://raw.githubusercontent.com/justsadnyx-ux/ScriptSource/main/version.txt") end)
                if ok and ver and ver:gsub("%s+", "") ~= "1.8.0" then
                    Rayfield:Notify({ Title = "Update Available", Content = "v" .. ver:gsub("%s+", "") .. " ready!", Duration = 6 })
                elseif ok then
                    Rayfield:Notify({ Title = "Up to Date", Content = "Latest version", Duration = 3 })
                else
                    Rayfield:Notify({ Title = "Check Failed", Content = "Could not reach GitHub", Duration = 3 })
                end
            end,
        })
        UpdatesTab:CreateButton({
            Name = "Update Now",
            Callback = function()
                cleanUpPlayer()
                Rayfield:Notify({ Title = "Updating...", Content = "Re-executing...", Duration = 3 })
                task.delay(1, function()
                    Rayfield:Destroy(); task.wait(0.5)
                    local ok, src = pcall(function() return game:HttpGet("https://raw.githubusercontent.com/justsadnyx-ux/ScriptSource/main/loader.lua") end)
                    if ok and src then loadstring(src)() end
                end)
            end,
        })

        -- OWNER TAB
        if IsOwner then
            local OwnerTab = Window:CreateTab("Owner", nil)
            local selectedPlayer = nil
            local ssUsers = {}

            local function getSSUserNames()
                local names = {}; ssUsers = {}
                for _, p in ipairs(Players:GetPlayers()) do
                    if ReplicatedStorage:GetAttribute(SS_PREFIX .. "User_" .. p.UserId) then
                        table.insert(names, p.Name); ssUsers[p.Name] = p
                    end
                end
                if #names == 0 then table.insert(names, "No ScriptSource users") end
                return names
            end

            OwnerTab:CreateSection("ScriptSource Users")
            OwnerTab:CreateParagraph({ Title = "Owner Panel", Content = "Only shows players using ScriptSource." })
            OwnerTab:CreateDropdown({
                Name = "Select User", Options = getSSUserNames(), CurrentValue = "No ScriptSource users", Flag = "OwnerPlayerSelect",
                Callback = function(v) selectedPlayer = ssUsers[v] or nil end,
            })
            OwnerTab:CreateButton({
                Name = "Refresh User List",
                Callback = function()
                    getSSUserNames()
                    local list = {}; for k in pairs(ssUsers) do table.insert(list, k) end
                    Rayfield:Notify({ Title = "Owner", Content = #list > 0 and table.concat(list, ", ") or "No users found", Duration = 5 })
                end,
            })

            OwnerTab:CreateSection("Actions")
            OwnerTab:CreateButton({
                Name = "Kick Selected User",
                Callback = function()
                    if not selectedPlayer then Rayfield:Notify({ Title = "Owner", Content = "No user selected", Duration = 3 }); return end
                    local ok, err = pcall(function() selectedPlayer:Kick("[ScriptSource] Kicked by owner") end)
                    Rayfield:Notify({ Title = "Owner", Content = ok and "Kicked " .. selectedPlayer.Name or "Failed: " .. tostring(err), Duration = 3 })
                end,
            })
            OwnerTab:CreateButton({
                Name = "Shutdown Selected User UI",
                Callback = function()
                    if not selectedPlayer then Rayfield:Notify({ Title = "Owner", Content = "No user selected", Duration = 3 }); return end
                    pcall(function() ReplicatedStorage:SetAttribute(SS_PREFIX .. "Shutdown_" .. selectedPlayer.UserId, true) end)
                    Rayfield:Notify({ Title = "Owner", Content = "Sent shutdown to " .. selectedPlayer.Name, Duration = 3 })
                end,
            })

            OwnerTab:CreateSection("Key Generator")
            OwnerTab:CreateInput({
                Name = "Target Username", PlaceholderText = "Enter username...", RemoveTextAfterFocusLost = false,
                Callback = function(v) _G._SS_KeyTargetName = v end,
            })
            OwnerTab:CreateButton({
                Name = "Generate 24h Key",
                Callback = function()
                    local name = _G._SS_KeyTargetName
                    if not name or name == "" then Rayfield:Notify({ Title = "KeyGen", Content = "Enter username!", Duration = 3 }); return end
                    Rayfield:Notify({ Title = "KeyGen", Content = "Key: " .. generateKey(name, 24), Duration = 15 })
                end,
            })
            OwnerTab:CreateButton({
                Name = "Generate 7d Key",
                Callback = function()
                    local name = _G._SS_KeyTargetName
                    if not name or name == "" then Rayfield:Notify({ Title = "KeyGen", Content = "Enter username!", Duration = 3 }); return end
                    Rayfield:Notify({ Title = "KeyGen", Content = "Key: " .. generateKey(name, 168), Duration = 15 })
                end,
            })
            OwnerTab:CreateButton({
                Name = "Show Lifetime Key",
                Callback = function() Rayfield:Notify({ Title = "KeyGen", Content = "Lifetime: " .. LIFETIME_KEY, Duration = 15 }) end,
            })

            OwnerTab:CreateSection("Notifications")
            OwnerTab:CreateInput({
                Name = "Broadcast Message", PlaceholderText = "Type notification...", RemoveTextAfterFocusLost = true,
                Callback = function(msg)
                    if msg and msg ~= "" then
                        ReplicatedStorage:SetAttribute(SS_PREFIX .. "Broadcast", msg)
                        Rayfield:Notify({ Title = "Owner", Content = "Sent: " .. msg, Duration = 3 })
                    end
                end,
            })
            OwnerTab:CreateButton({
                Name = "Send New UI Alert",
                Callback = function()
                    ReplicatedStorage:SetAttribute(SS_PREFIX .. "Broadcast", "NEW UI UPDATE! Re-execute ScriptSource for the latest features!")
                    Rayfield:Notify({ Title = "Owner", Content = "New UI broadcast sent!", Duration = 3 })
                end,
            })
            OwnerTab:CreateButton({
                Name = "Send Alert",
                Callback = function()
                    ReplicatedStorage:SetAttribute(SS_PREFIX .. "Broadcast", "ALERT: Owner is watching!")
                    Rayfield:Notify({ Title = "Owner", Content = "Alert sent!", Duration = 3 })
                end,
            })

            OwnerTab:CreateSection("Poll")
            OwnerTab:CreateInput({
                Name = "Poll Question", PlaceholderText = "Question...", RemoveTextAfterFocusLost = true,
                Callback = function(q) if q and q ~= "" then _G._SS_PollQ = q end end,
            })
            OwnerTab:CreateInput({
                Name = "Poll Options (comma sep)", PlaceholderText = "Yes,No,Maybe", RemoveTextAfterFocusLost = true,
                Callback = function(o) if o and o ~= "" then _G._SS_PollOpts = o end end,
            })
            OwnerTab:CreateButton({
                Name = "Start Poll",
                Callback = function()
                    local q, o = _G._SS_PollQ, _G._SS_PollOpts
                    if not q or q == "" or not o or o == "" then Rayfield:Notify({ Title = "Poll", Content = "Set question + options!", Duration = 3 }); return end
                    ReplicatedStorage:SetAttribute(SS_PREFIX .. "Poll_Q", q)
                    ReplicatedStorage:SetAttribute(SS_PREFIX .. "Poll_Opts", o)
                    ReplicatedStorage:SetAttribute(SS_PREFIX .. "Poll_Votes", "")
                    ReplicatedStorage:SetAttribute(SS_PREFIX .. "Poll_Active", true)
                    Rayfield:Notify({ Title = "Poll", Content = "Started: " .. q, Duration = 3 })
                end,
            })
            OwnerTab:CreateButton({
                Name = "End Poll & Results",
                Callback = function()
                    ReplicatedStorage:SetAttribute(SS_PREFIX .. "Poll_Active", false)
                    local votes = ReplicatedStorage:GetAttribute(SS_PREFIX .. "Poll_Votes") or ""
                    local opts = ReplicatedStorage:GetAttribute(SS_PREFIX .. "Poll_Opts") or ""
                    local counts = {}; for opt in opts:gmatch("[^,]+") do counts[opt] = 0 end
                    for vote in votes:gmatch("[^;]+") do if counts[vote] then counts[vote] = counts[vote] + 1 end end
                    local result = ""; for opt, c in pairs(counts) do result = result .. opt .. ":" .. c .. " " end
                    if result == "" then result = "No votes" end
                    ReplicatedStorage:SetAttribute(SS_PREFIX .. "Broadcast", "POLL RESULTS: " .. result)
                    Rayfield:Notify({ Title = "Poll", Content = result, Duration = 8 })
                end,
            })

            OwnerTab:CreateSection("Server")
            OwnerTab:CreateButton({
                Name = "Server Info",
                Callback = function()
                    local c = #Players:GetPlayers()
                    local s = 0; for _, p in ipairs(Players:GetPlayers()) do if ReplicatedStorage:GetAttribute(SS_PREFIX .. "User_" .. p.UserId) then s = s + 1 end end
                    local j = game.JobId ~= "" and string.sub(game.JobId, 1, 12) .. "..." or "Private"
                    Rayfield:Notify({ Title = "Server", Content = "Players: " .. c .. " | SS: " .. s .. " | " .. j, Duration = 6 })
                end,
            })
        end
    else
        -- KEY NOT VALID: Only show Key tab (locked) + Updates
        local KeyTab = Window:CreateTab("Key", nil)
        KeyTab:CreateSection("Enter your key to unlock ScriptSource")
        KeyTab:CreateParagraph({ Title = "Locked", Content = "All features are locked. Enter a valid key to continue." })
        KeyTab:CreateInput({
            Name = "Enter Key",
            PlaceholderText = "Paste key here...",
            RemoveTextAfterFocusLost = false,
            Callback = function(k)
                if k and k ~= "" then
                    local ok, msg = validateKey(k)
                    if ok then
                        pcall(function() _G._SS_Key = k end)
                        keyValid = true
                        Rayfield:Notify({ Title = "Unlocked", Content = "Reloading with all features...", Duration = 3 })
                        task.delay(0.5, function()
                            Rayfield:Destroy()
                            task.wait(0.3)
                            local ok2, src = pcall(function() return game:HttpGet("https://raw.githubusercontent.com/justsadnyx-ux/ScriptSource/main/loader.lua") end)
                            if ok2 and src then loadstring(src)() end
                        end)
                    else
                        Rayfield:Notify({ Title = "Invalid Key", Content = msg, Duration = 5 })
                    end
                end
            end,
        })
        KeyTab:CreateButton({
            Name = "Copy Key Link",
            Callback = function()
                pcall(function()
                    if setclipboard then setclipboard("https://justsadnyx-ux.github.io/ScriptSource")
                    else game:GetService("StarterGui"):SetCore("SetClipboard", "https://justsadnyx-ux.github.io/ScriptSource") end
                end)
                Rayfield:Notify({ Title = "Key", Content = "Link copied!", Duration = 3 })
            end,
        })

        -- UPDATES TAB (always accessible)
        local UpdatesTab = Window:CreateTab("Updates", nil)
        UpdatesTab:CreateSection("Version")
        UpdatesTab:CreateParagraph({ Title = "ScriptSource v1.8.0", Content = "Check for updates from GitHub." })
        UpdatesTab:CreateButton({
            Name = "Check for Updates",
            Callback = function()
                local ok, ver = pcall(function() return game:HttpGet("https://raw.githubusercontent.com/justsadnyx-ux/ScriptSource/main/version.txt") end)
                if ok and ver and ver:gsub("%s+", "") ~= "1.8.0" then
                    Rayfield:Notify({ Title = "Update Available", Content = "v" .. ver:gsub("%s+", "") .. " ready!", Duration = 6 })
                elseif ok then
                    Rayfield:Notify({ Title = "Up to Date", Content = "Latest version", Duration = 3 })
                else
                    Rayfield:Notify({ Title = "Check Failed", Content = "Could not reach GitHub", Duration = 3 })
                end
            end,
        })
        UpdatesTab:CreateButton({
            Name = "Update Now",
            Callback = function()
                cleanUpPlayer()
                Rayfield:Notify({ Title = "Updating...", Content = "Re-executing...", Duration = 3 })
                task.delay(1, function()
                    Rayfield:Destroy(); task.wait(0.5)
                    local ok, src = pcall(function() return game:HttpGet("https://raw.githubusercontent.com/justsadnyx-ux/ScriptSource/main/loader.lua") end)
                    if ok and src then loadstring(src)() end
                end)
            end,
        })

        -- OWNER TAB (always accessible for owner even when locked)
        if IsOwner then
            local OwnerTab = Window:CreateTab("Owner", nil)
            local selectedPlayer = nil
            local ssUsers = {}

            local function getSSUserNames()
                local names = {}; ssUsers = {}
                for _, p in ipairs(Players:GetPlayers()) do
                    if ReplicatedStorage:GetAttribute(SS_PREFIX .. "User_" .. p.UserId) then
                        table.insert(names, p.Name); ssUsers[p.Name] = p
                    end
                end
                if #names == 0 then table.insert(names, "No ScriptSource users") end
                return names
            end

            OwnerTab:CreateSection("ScriptSource Users")
            OwnerTab:CreateDropdown({
                Name = "Select User", Options = getSSUserNames(), CurrentValue = "No ScriptSource users", Flag = "OwnerPlayerSelect",
                Callback = function(v) selectedPlayer = ssUsers[v] or nil end,
            })
            OwnerTab:CreateButton({
                Name = "Refresh User List",
                Callback = function()
                    getSSUserNames()
                    local list = {}; for k in pairs(ssUsers) do table.insert(list, k) end
                    Rayfield:Notify({ Title = "Owner", Content = #list > 0 and table.concat(list, ", ") or "No users found", Duration = 5 })
                end,
            })

            OwnerTab:CreateSection("Key Generator")
            OwnerTab:CreateInput({
                Name = "Target Username", PlaceholderText = "Enter username...", RemoveTextAfterFocusLost = false,
                Callback = function(v) _G._SS_KeyTargetName = v end,
            })
            OwnerTab:CreateButton({
                Name = "Generate 24h Key",
                Callback = function()
                    local name = _G._SS_KeyTargetName
                    if not name or name == "" then Rayfield:Notify({ Title = "KeyGen", Content = "Enter username!", Duration = 3 }); return end
                    Rayfield:Notify({ Title = "KeyGen", Content = "Key: " .. generateKey(name, 24), Duration = 15 })
                end,
            })
            OwnerTab:CreateButton({
                Name = "Generate 7d Key",
                Callback = function()
                    local name = _G._SS_KeyTargetName
                    if not name or name == "" then Rayfield:Notify({ Title = "KeyGen", Content = "Enter username!", Duration = 3 }); return end
                    Rayfield:Notify({ Title = "KeyGen", Content = "Key: " .. generateKey(name, 168), Duration = 15 })
                end,
            })
            OwnerTab:CreateButton({
                Name = "Show Lifetime Key",
                Callback = function() Rayfield:Notify({ Title = "KeyGen", Content = "Lifetime: " .. LIFETIME_KEY, Duration = 15 }) end,
            })

            OwnerTab:CreateSection("Notifications")
            OwnerTab:CreateButton({
                Name = "Send New UI Alert",
                Callback = function()
                    ReplicatedStorage:SetAttribute(SS_PREFIX .. "Broadcast", "NEW UI UPDATE! Re-execute ScriptSource for the latest features!")
                    Rayfield:Notify({ Title = "Owner", Content = "New UI broadcast sent!", Duration = 3 })
                end,
            })
            OwnerTab:CreateButton({
                Name = "Send Alert",
                Callback = function()
                    ReplicatedStorage:SetAttribute(SS_PREFIX .. "Broadcast", "ALERT: Owner is watching!")
                    Rayfield:Notify({ Title = "Owner", Content = "Alert sent!", Duration = 3 })
                end,
            })

            OwnerTab:CreateSection("Server")
            OwnerTab:CreateButton({
                Name = "Server Info",
                Callback = function()
                    local c = #Players:GetPlayers()
                    local s = 0; for _, p in ipairs(Players:GetPlayers()) do if ReplicatedStorage:GetAttribute(SS_PREFIX .. "User_" .. p.UserId) then s = s + 1 end end
                    local j = game.JobId ~= "" and string.sub(game.JobId, 1, 12) .. "..." or "Private"
                    Rayfield:Notify({ Title = "Server", Content = "Players: " .. c .. " | SS: " .. s .. " | " .. j, Duration = 6 })
                end,
            })
        end
    end

    Rayfield:LoadConfiguration()

    pcall(function() ReplicatedStorage:SetAttribute(SS_PREFIX .. "User_" .. LocalPlayer.UserId, LocalPlayer.Name) end)

    Players.PlayerRemoving:Connect(function(p)
        pcall(function()
            ReplicatedStorage:SetAttribute(SS_PREFIX .. "User_" .. p.UserId, nil)
            ReplicatedStorage:SetAttribute(SS_PREFIX .. "Active_" .. p.UserId, nil)
            ReplicatedStorage:SetAttribute(SS_PREFIX .. "Bomb_" .. p.UserId, nil)
        end)
    end)

    pcall(function()
        local myId = LocalPlayer.UserId
        local conn
        conn = ReplicatedStorage:GetAttributeChangedSignal(SS_PREFIX .. "Shutdown_" .. myId):Connect(function()
            if ReplicatedStorage:GetAttribute(SS_PREFIX .. "Shutdown_" .. myId) then
                cleanUpPlayer()
                Rayfield:Notify({ Title = "Shutdown", Content = "Owner shut down your UI", Duration = 3 })
                task.delay(1, function() pcall(function() Rayfield:Destroy() end) end)
                if conn then conn:Disconnect() end
            end
        end)
    end)

    pcall(function()
        ReplicatedStorage:GetAttributeChangedSignal(SS_PREFIX .. "Broadcast"):Connect(function()
            local msg = ReplicatedStorage:GetAttribute(SS_PREFIX .. "Broadcast")
            if msg and msg ~= "" then Rayfield:Notify({ Title = "Owner Broadcast", Content = tostring(msg), Duration = 8 }) end
        end)
    end)

    pcall(function()
        ReplicatedStorage:GetAttributeChangedSignal(SS_PREFIX .. "Poll_Active"):Connect(function()
            if ReplicatedStorage:GetAttribute(SS_PREFIX .. "Poll_Active") then
                local q = ReplicatedStorage:GetAttribute(SS_PREFIX .. "Poll_Q") or "?"
                local o = ReplicatedStorage:GetAttribute(SS_PREFIX .. "Poll_Opts") or ""
                Rayfield:Notify({ Title = "NEW POLL", Content = q, Duration = 5 })
                task.delay(2, function() Rayfield:Notify({ Title = "OPTIONS", Content = o, Duration = 8 }) end)
            end
        end)
    end)

    Rayfield:Notify({ Title = "ScriptSource", Content = "v1.8.0 loaded!", Duration = 4 })

    if keyValid and not IsOwner then
        local isWinner = false
        pcall(function()
            local ok, data = pcall(function() return game:HttpGet("https://raw.githubusercontent.com/justsadnyx-ux/ScriptSource/main/winners.txt") end)
            if ok and data then
                for line in data:gmatch("[^\r\n]+") do
                    local name = line:match("^%s*(.-)%s*$")
                    if name and name ~= "" and string.lower(name) == string.lower(LocalPlayer.Name) then
                        isWinner = true
                        break
                    end
                end
            end
        end)
        if isWinner then
            Rayfield:Notify({ Title = "Giveaway Winner!", Content = "You have lifetime access! No key needed.", Duration = 8 })
        end
    end
end

startUI()
