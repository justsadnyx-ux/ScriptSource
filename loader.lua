local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local OWNER = "HOPOUTHECUPE2"
local IsOwner = LocalPlayer.Name == OWNER
local SS_PREFIX = "SS_"
local LIFETIME_KEY = "KEY20291"
local KEY_SECRET = "x7k9m2p4"

pcall(function()
    if ReplicatedStorage:GetAttribute(SS_PREFIX .. "Active_" .. LocalPlayer.UserId) then
        return
    end
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
        if pg then
            for _, v in ipairs(pg:GetChildren()) do
                if v.Name == "ScriptSource" then v:Destroy() end
            end
        end
    end)
end

local function simpleHash(str)
    local h = 0
    for i = 1, #str do
        h = (h * 31 + string.byte(str, i)) % 999999
    end
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

local function generateKey(userId, hours)
    local expiry = os.time() + (hours * 3600)
    local payload = tostring(userId) .. "|" .. tostring(expiry)
    local checksum = simpleHash(payload .. KEY_SECRET)
    local raw = payload .. "|" .. tostring(checksum)
    return "SS-" .. b64Encode(raw)
end

local function validateKey(key)
    if not key or key == "" then return false, "Empty key" end
    if key == LIFETIME_KEY then return true, "Lifetime key" end
    if not key:find("^SS%-") then return false, "Invalid format" end
    local raw = b64Decode(key:sub(4))
    if not raw or raw == "" then return false, "Invalid encoding" end
    local userId, expiry, checksum = raw:match("^(%d+)|(%d+)|(%d+)$")
    if not userId or not expiry or not checksum then return false, "Corrupted key" end
    userId, expiry, checksum = tonumber(userId), tonumber(expiry), tonumber(checksum)
    if not userId or not expiry or not checksum then return false, "Invalid data" end
    if userId ~= LocalPlayer.UserId then return false, "Device mismatch - key bound to another account" end
    if os.time() > expiry then return false, "Key expired" end
    local expected = simpleHash(tostring(userId) .. "|" .. tostring(expiry) .. KEY_SECRET)
    if checksum ~= expected then return false, "Invalid checksum" end
    return true, "Valid"
end

local function getKeyFromConfig()
    local v = nil
    pcall(function()
        v = _G._SS_Key
    end)
    return v
end

local function saveKeyToConfig(key)
    pcall(function()
        _G._SS_Key = key
    end)
end

local function showKeyUI(onSuccess)
    local sg = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
    sg.Name = "SS_KeyUI"
    sg.ResetOnSpawn = false

    local overlay = Instance.new("Frame", sg)
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(5, 5, 10)
    overlay.BackgroundTransparency = 0.3
    overlay.BorderSizePixel = 0

    local frame = Instance.new("Frame", sg)
    frame.Size = UDim2.new(0, 380, 0, 320)
    frame.Position = UDim2.new(0.5, -190, 0.5, -160)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(100, 50, 200)
    stroke.Thickness = 2

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, -20, 0, 40)
    title.Position = UDim2.new(0, 10, 0, 20)
    title.BackgroundTransparency = 1
    title.Text = "ScriptSource"
    title.TextColor3 = Color3.fromRGB(150, 100, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 26

    local sub = Instance.new("TextLabel", frame)
    sub.Size = UDim2.new(1, -20, 0, 20)
    sub.Position = UDim2.new(0, 10, 0, 58)
    sub.BackgroundTransparency = 1
    sub.Text = "Enter your key to continue"
    sub.TextColor3 = Color3.fromRGB(100, 100, 120)
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 13

    local input = Instance.new("TextBox", frame)
    input.Size = UDim2.new(1, -40, 0, 44)
    input.Position = UDim2.new(0, 20, 0, 90)
    input.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
    input.BorderSizePixel = 0
    input.TextColor3 = Color3.new(1, 1, 1)
    input.PlaceholderText = "Paste key here..."
    input.PlaceholderColor3 = Color3.fromRGB(60, 60, 80)
    input.Font = Enum.Font.Code
    input.TextSize = 15
    input.ClearTextOnFocus = false
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 8)

    local errText = Instance.new("TextLabel", frame)
    errText.Size = UDim2.new(1, -40, 0, 20)
    errText.Position = UDim2.new(0, 20, 0, 140)
    errText.BackgroundTransparency = 1
    errText.Text = ""
    errText.TextColor3 = Color3.fromRGB(255, 70, 70)
    errText.Font = Enum.Font.Gotham
    errText.TextSize = 12

    local submitBtn = Instance.new("TextButton", frame)
    submitBtn.Size = UDim2.new(1, -40, 0, 44)
    submitBtn.Position = UDim2.new(0, 20, 0, 165)
    submitBtn.BackgroundColor3 = Color3.fromRGB(90, 40, 200)
    submitBtn.BorderSizePixel = 0
    submitBtn.Text = "Submit Key"
    submitBtn.TextColor3 = Color3.new(1, 1, 1)
    submitBtn.Font = Enum.Font.GothamBold
    submitBtn.TextSize = 16
    Instance.new("UICorner", submitBtn).CornerRadius = UDim.new(0, 8)

    local link = Instance.new("TextLabel", frame)
    link.Size = UDim2.new(1, -40, 0, 16)
    link.Position = UDim2.new(0, 20, 0, 220)
    link.BackgroundTransparency = 1
    link.Text = "Get a key at: justsadnyx-ux.github.io/ScriptSource/get-key"
    link.TextColor3 = Color3.fromRGB(80, 80, 120)
    link.Font = Enum.Font.Gotham
    link.TextSize = 11

    local ownerKey = Instance.new("TextLabel", frame)
    ownerKey.Size = UDim2.new(1, -40, 0, 14)
    ownerKey.Position = UDim2.new(0, 20, 0, 240)
    ownerKey.BackgroundTransparency = 1
    ownerKey.Text = "Owner key available in-game"
    ownerKey.TextColor3 = Color3.fromRGB(60, 60, 80)
    ownerKey.Font = Enum.Font.Gotham
    ownerKey.TextSize = 10

    local function attemptSubmit()
        local k = input.Text
        local ok, msg = validateKey(k)
        if ok then
            saveKeyToConfig(k)
            sg:Destroy()
            onSuccess()
        else
            errText.Text = msg
        end
    end

    submitBtn.MouseButton1Click:Connect(attemptSubmit)
    input.FocusLost:Connect(function(enter)
        if enter then attemptSubmit() end
    end)
end

local savedKey = getKeyFromConfig()
local keyValid = false

if savedKey then
    local ok, _ = validateKey(savedKey)
    if ok then
        keyValid = true
    else
        pcall(function() _G._SS_Key = nil end)
    end
end

if IsOwner then keyValid = true end

local function startUI()
    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

    local Window = Rayfield:CreateWindow({
        Name = "ScriptSource v1.5.0",
        LoadingTitle = "ScriptSource",
        LoadingSubtitle = IsOwner and "Owner Mode" or "Welcome",
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
            local c = LocalPlayer.Character
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
            local c = LocalPlayer.Character
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
                _G._SS_AntiAFK = LocalPlayer.Idled:Connect(function()
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
                    if plr == LocalPlayer then return end
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
                Rayfield:Notify({Title = "ESP", Content = "Enabled", Duration = 3})
            else
                if _G._SS_ESPJoin then _G._SS_ESPJoin:Disconnect() end
                if _G._SS_ESPUpdate then _G._SS_ESPUpdate:Disconnect() end
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Character then for _, x in ipairs(p.Character:GetDescendants()) do if x.Name == "SS_ESP" then x:Destroy() end end end
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

    local PollTab = Window:CreateTab("Poll", nil)

    PollTab:CreateParagraph({
        Title = "Live Poll",
        Content = "When the owner starts a poll, vote here."
    })

    PollTab:CreateDropdown({
        Name = "Vote",
        Options = (function()
            local opts = ReplicatedStorage:GetAttribute(SS_PREFIX .. "Poll_Opts") or ""
            local t = {}
            for o in opts:gmatch("[^,]+") do table.insert(t, o) end
            if #t == 0 then table.insert(t, "No active poll") end
            return t
        end)(),
        CurrentValue = "No active poll",
        Flag = "PollVote",
        Callback = function(v)
            if v == "No active poll" then return end
            local active = ReplicatedStorage:GetAttribute(SS_PREFIX .. "Poll_Active")
            if not active then
                Rayfield:Notify({Title = "Poll", Content = "No active poll!", Duration = 3})
                return
            end
            local existing = ReplicatedStorage:GetAttribute(SS_PREFIX .. "Poll_Votes") or ""
            local myVote = LocalPlayer.Name .. ":" .. v
            local newVotes = existing == "" and myVote or existing .. ";" .. myVote
            ReplicatedStorage:SetAttribute(SS_PREFIX .. "Poll_Votes", newVotes)
            Rayfield:Notify({Title = "Poll", Content = "Voted: " .. v, Duration = 3})
        end,
    })

    local BombTab = Window:CreateTab("Bomb Game", nil)
    BombTab:CreateSection("Bomb Control")

    local bombActive = false
    local bombTime = 3
    local bombHolder = nil
    local bombGui = nil
    local bombConn = nil

    local function getBomblessPlayers()
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local hasBomb = ReplicatedStorage:GetAttribute(SS_PREFIX .. "Bomb_" .. p.UserId)
                if not hasBomb then
                    table.insert(list, p.Name)
                end
            end
        end
        if #list == 0 then table.insert(list, "No targets") end
        return list
    end

    local function showBombUI(holderName, timeLeft)
        pcall(function() if bombGui then bombGui:Destroy() end end)
        local sg = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
        sg.Name = "SS_BombUI"
        sg.ResetOnSpawn = false
        bombGui = sg
        local frame = Instance.new("Frame", sg)
        frame.Size = UDim2.new(0, 220, 0, 80)
        frame.Position = UDim2.new(0.5, -110, 0, 10)
        frame.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
        frame.BorderSizePixel = 0
        frame.Active = true
        frame.Draggable = true
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
        local titleLbl = Instance.new("TextLabel", frame)
        titleLbl.Size = UDim2.new(1, -10, 0, 30)
        titleLbl.Position = UDim2.new(0, 5, 0, 5)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Text = "BOMB: " .. holderName
        titleLbl.TextColor3 = Color3.new(1, 1, 1)
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.TextSize = 16
        local timerLbl = Instance.new("TextLabel", frame)
        timerLbl.Name = "Timer"
        timerLbl.Size = UDim2.new(1, -10, 0, 35)
        timerLbl.Position = UDim2.new(0, 5, 0, 35)
        timerLbl.BackgroundTransparency = 1
        timerLbl.Text = tostring(timeLeft) .. "s"
        timerLbl.TextColor3 = Color3.fromRGB(255, 200, 50)
        timerLbl.Font = Enum.Font.Code
        timerLbl.TextSize = 28
    end

    local function destroyBombUI()
        pcall(function()
            if bombGui then bombGui:Destroy() bombGui = nil end
        end)
    end

    local function explodeBomb(playerName)
        destroyBombUI()
        local target = Players:FindFirstChild(playerName)
        if target and target.Character then
            local hrp = target.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local boom = Instance.new("Explosion", workspace)
                boom.Position = hrp.Position
                boom.BlastPressure = 0
                boom.DestroyJointRadiusPercent = 0
                local fire = Instance.new("Fire", hrp)
                fire.Size = 20
                fire.Heat = 10
                task.delay(2, function() pcall(function() fire:Destroy() end) end)
            end
            local hum = target.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health = 0 end
        end
        Rayfield:Notify({Title = "BOOM!", Content = playerName .. " was eliminated!", Duration = 5})
    end

    BombTab:CreateSlider({
        Name = "Bomb Timer (seconds)",
        Range = {1, 8},
        Increment = 1,
        CurrentValue = 3,
        Flag = "BombTimer",
        Callback = function(v) bombTime = v end,
    })

    BombTab:CreateParagraph({
        Title = "How it works",
        Content = "Start the bomb, pass it to someone without it, or force pass it. When timer hits 0, the holder explodes."
    })

    BombTab:CreateButton({
        Name = "Start Bomb",
        Callback = function()
            if bombActive then
                Rayfield:Notify({Title = "Bomb", Content = "Bomb is already active!", Duration = 3})
                return
            end
            bombActive = true
            bombHolder = LocalPlayer.Name
            ReplicatedStorage:SetAttribute(SS_PREFIX .. "Bomb_" .. LocalPlayer.UserId, true)
            Rayfield:Notify({Title = "Bomb", Content = "Bomb started! Pass it before " .. bombTime .. "s!", Duration = 4})
            showBombUI(LocalPlayer.Name, bombTime)
            local remaining = bombTime
            bombConn = RunService.Heartbeat:Connect(function(dt)
                if not bombActive then
                    if bombConn then bombConn:Disconnect() bombConn = nil end
                    return
                end
                remaining = remaining - dt
                if bombGui and bombGui:FindFirstChild("Timer", true) then
                    bombGui:FindFirstChild("Timer", true).Text = math.max(0, math.ceil(remaining)) .. "s"
                end
                if remaining <= 2 and bombGui then
                    bombGui:FindFirstChild("Timer", true).TextColor3 = Color3.fromRGB(255, 50, 50)
                end
                if remaining <= 0 then
                    bombActive = false
                    if bombConn then bombConn:Disconnect() bombConn = nil end
                    ReplicatedStorage:SetAttribute(SS_PREFIX .. "Bomb_" .. LocalPlayer.UserId, nil)
                    explodeBomb(LocalPlayer.Name)
                end
            end)
        end,
    })

    BombTab:CreateDropdown({
        Name = "Pass Bomb To",
        Options = getBomblessPlayers(),
        CurrentValue = "No targets",
        Flag = "BombTarget",
        Callback = function(v)
            if not bombActive then
                Rayfield:Notify({Title = "Bomb", Content = "Start the bomb first!", Duration = 3})
                return
            end
            if v == "No targets" then return end
            local target = Players:FindFirstChild(v)
            if target then
                ReplicatedStorage:SetAttribute(SS_PREFIX .. "Bomb_" .. LocalPlayer.UserId, nil)
                ReplicatedStorage:SetAttribute(SS_PREFIX .. "Bomb_" .. target.UserId, true)
                bombHolder = v
                Rayfield:Notify({Title = "Bomb", Content = "Passed to " .. v .. "!", Duration = 3})
                showBombUI(v, bombTime)
            end
        end,
    })

    BombTab:CreateButton({
        Name = "Force Pass (Random)",
        Callback = function()
            if not bombActive then
                Rayfield:Notify({Title = "Bomb", Content = "Start the bomb first!", Duration = 3})
                return
            end
            local targets = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and not ReplicatedStorage:GetAttribute(SS_PREFIX .. "Bomb_" .. p.UserId) then
                    table.insert(targets, p)
                end
            end
            if #targets == 0 then
                Rayfield:Notify({Title = "Bomb", Content = "No valid targets!", Duration = 3})
                return
            end
            local pick = targets[math.random(1, #targets)]
            ReplicatedStorage:SetAttribute(SS_PREFIX .. "Bomb_" .. LocalPlayer.UserId, nil)
            ReplicatedStorage:SetAttribute(SS_PREFIX .. "Bomb_" .. pick.UserId, true)
            bombHolder = pick.Name
            Rayfield:Notify({Title = "Bomb", Content = "Force passed to " .. pick.Name .. "!", Duration = 3})
            showBombUI(pick.Name, bombTime)
        end,
    })

    BombTab:CreateButton({
        Name = "Weld Away (Escape)",
        Callback = function()
            if not bombActive then
                Rayfield:Notify({Title = "Bomb", Content = "No bomb active!", Duration = 3})
                return
            end
            if not ReplicatedStorage:GetAttribute(SS_PREFIX .. "Bomb_" .. LocalPlayer.UserId) then
                Rayfield:Notify({Title = "Bomb", Content = "You don't have the bomb!", Duration = 3})
                return
            end
            local targets = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and not ReplicatedStorage:GetAttribute(SS_PREFIX .. "Bomb_" .. p.UserId) then
                    table.insert(targets, p)
                end
            end
            if #targets == 0 then
                Rayfield:Notify({Title = "Bomb", Content = "No targets to weld to!", Duration = 3})
                return
            end
            local pick = targets[math.random(1, #targets)]
            ReplicatedStorage:SetAttribute(SS_PREFIX .. "Bomb_" .. LocalPlayer.UserId, nil)
            ReplicatedStorage:SetAttribute(SS_PREFIX .. "Bomb_" .. pick.UserId, true)
            bombHolder = pick.Name
            if LocalPlayer.Character and pick.Character then
                local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local targetRoot = pick.Character:FindFirstChild("HumanoidRootPart")
                if myRoot and targetRoot then
                    pcall(function()
                        local weld = Instance.new("WeldConstraint", myRoot)
                        weld.Part0 = myRoot
                        weld.Part1 = targetRoot
                        game:GetService("Debris"):AddItem(weld, 3)
                    end)
                end
            end
            Rayfield:Notify({Title = "Bomb", Content = "Welded bomb to " .. pick.Name .. "!", Duration = 3})
            showBombUI(pick.Name, bombTime)
        end,
    })

    BombTab:CreateButton({
        Name = "Stop Bomb",
        Callback = function()
            if not bombActive then
                Rayfield:Notify({Title = "Bomb", Content = "No bomb active!", Duration = 3})
                return
            end
            bombActive = false
            if bombConn then bombConn:Disconnect() bombConn = nil end
            ReplicatedStorage:SetAttribute(SS_PREFIX .. "Bomb_" .. LocalPlayer.UserId, nil)
            for _, p in ipairs(Players:GetPlayers()) do
                if ReplicatedStorage:GetAttribute(SS_PREFIX .. "Bomb_" .. p.UserId) then
                    ReplicatedStorage:SetAttribute(SS_PREFIX .. "Bomb_" .. p.UserId, nil)
                end
            end
            destroyBombUI()
            Rayfield:Notify({Title = "Bomb", Content = "Bomb has been defused!", Duration = 3})
        end,
    })

    local UpdatesTab = Window:CreateTab("Updates", nil)
    UpdatesTab:CreateSection("Version")

    UpdatesTab:CreateParagraph({
        Title = "ScriptSource v1.5.0",
        Content = "Check for updates from GitHub."
    })

    UpdatesTab:CreateButton({
        Name = "Check for Updates",
        Callback = function()
            local ok, ver = pcall(function()
                return game:HttpGet("https://raw.githubusercontent.com/justsadnyx-ux/ScriptSource/main/version.txt")
            end)
            if ok and ver and ver:gsub("%s+", "") ~= "1.5.0" then
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
            cleanUpPlayer()
            Rayfield:Notify({Title = "Updating...", Content = "Re-executing with latest version...", Duration = 3})
            task.delay(1, function()
                Rayfield:Destroy()
                task.wait(0.5)
                local ok, src = pcall(function()
                    return game:HttpGet("https://raw.githubusercontent.com/justsadnyx-ux/ScriptSource/main/loader.lua")
                end)
                if ok and src then loadstring(src)() end
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
            cleanUpPlayer()
            Rayfield:Destroy()
        end,
    })

    SettingsTab:CreateButton({
        Name = "Reload Script",
        Callback = function()
            cleanUpPlayer()
            Rayfield:Destroy()
            task.wait(0.5)
            local ok, src = pcall(function()
                return game:HttpGet("https://raw.githubusercontent.com/justsadnyx-ux/ScriptSource/main/loader.lua")
            end)
            if ok and src then loadstring(src)() end
        end,
    })

    if IsOwner then
        local OwnerTab = Window:CreateTab("Owner", nil)
        local OwnerSection = OwnerTab:CreateSection("ScriptSource Users")

        local selectedPlayer = nil
        local ssUsers = {}

        local function getSSUserNames()
            local names = {}
            ssUsers = {}
            for _, p in ipairs(Players:GetPlayers()) do
                local attr = ReplicatedStorage:GetAttribute(SS_PREFIX .. "User_" .. p.UserId)
                if attr then
                    table.insert(names, p.Name)
                    ssUsers[p.Name] = p
                end
            end
            if #names == 0 then table.insert(names, "No ScriptSource users") end
            return names
        end

        OwnerTab:CreateParagraph({
            Title = "Owner Panel",
            Content = "Only shows players using ScriptSource."
        })

        OwnerTab:CreateDropdown({
            Name = "Select User",
            Options = getSSUserNames(),
            CurrentValue = "No ScriptSource users",
            Flag = "OwnerPlayerSelect",
            Callback = function(v) selectedPlayer = ssUsers[v] or nil end,
        })

        OwnerTab:CreateButton({
            Name = "Refresh User List",
            Callback = function()
                getSSUserNames()
                local list = {}
                for k in pairs(ssUsers) do table.insert(list, k) end
                local msg = #list > 0 and table.concat(list, ", ") or "No ScriptSource users found"
                Rayfield:Notify({Title = "Owner", Content = "Users: " .. msg, Duration = 5})
            end,
        })

        OwnerTab:CreateSection("Actions")

        OwnerTab:CreateButton({
            Name = "Teleport to Selected",
            Callback = function()
                if not selectedPlayer then
                    Rayfield:Notify({Title = "Owner", Content = "No user selected", Duration = 3})
                    return
                end
                Rayfield:Notify({Title = "Owner", Content = "Teleporting...", Duration = 3})
                local ok, err = pcall(function()
                    game:GetService("TeleportService"):Teleport(game.PlaceId)
                end)
                if not ok then
                    Rayfield:Notify({Title = "Owner", Content = "Failed: " .. tostring(err), Duration = 5})
                end
            end,
        })

        OwnerTab:CreateButton({
            Name = "Kick Selected User",
            Callback = function()
                if not selectedPlayer then
                    Rayfield:Notify({Title = "Owner", Content = "No user selected", Duration = 3})
                    return
                end
                local ok, err = pcall(function()
                    selectedPlayer:Kick("[ScriptSource] Kicked by owner")
                end)
                if ok then
                    Rayfield:Notify({Title = "Owner", Content = "Kicked " .. selectedPlayer.Name, Duration = 3})
                else
                    Rayfield:Notify({Title = "Owner", Content = "Failed: " .. tostring(err), Duration = 5})
                end
            end,
        })

        OwnerTab:CreateButton({
            Name = "Shutdown Selected User UI",
            Callback = function()
                if not selectedPlayer then
                    Rayfield:Notify({Title = "Owner", Content = "No user selected", Duration = 3})
                    return
                end
                local ok, err = pcall(function()
                    ReplicatedStorage:SetAttribute(SS_PREFIX .. "Shutdown_" .. selectedPlayer.UserId, true)
                end)
                if ok then
                    Rayfield:Notify({Title = "Owner", Content = "Sent shutdown to " .. selectedPlayer.Name, Duration = 3})
                else
                    Rayfield:Notify({Title = "Owner", Content = "Failed: " .. tostring(err), Duration = 5})
                end
            end,
        })

        OwnerTab:CreateSection("Key Generator")

        OwnerTab:CreateInput({
            Name = "Target User ID",
            PlaceholderText = "Enter UserId...",
            RemoveTextAfterFocusLost = false,
            Callback = function(v)
                _G._SS_KeyTarget = tonumber(v)
            end,
        })

        OwnerTab:CreateButton({
            Name = "Generate 24h Key",
            Callback = function()
                local uid = _G._SS_KeyTarget
                if not uid then
                    Rayfield:Notify({Title = "KeyGen", Content = "Enter a UserId first!", Duration = 3})
                    return
                end
                local key = generateKey(uid, 24)
                Rayfield:Notify({Title = "KeyGen", Content = "Key for " .. uid .. ": " .. key, Duration = 15})
            end,
        })

        OwnerTab:CreateButton({
            Name = "Generate 7d Key",
            Callback = function()
                local uid = _G._SS_KeyTarget
                if not uid then
                    Rayfield:Notify({Title = "KeyGen", Content = "Enter a UserId first!", Duration = 3})
                    return
                end
                local key = generateKey(uid, 168)
                Rayfield:Notify({Title = "KeyGen", Content = "Key for " .. uid .. ": " .. key, Duration = 15})
            end,
        })

        OwnerTab:CreateButton({
            Name = "Generate Lifetime Key",
            Callback = function()
                Rayfield:Notify({Title = "KeyGen", Content = "Lifetime key: " .. LIFETIME_KEY, Duration = 15})
            end,
        })

        OwnerTab:CreateSection("Notifications")

        OwnerTab:CreateInput({
            Name = "Broadcast Message",
            PlaceholderText = "Type notification to send to all...",
            RemoveTextAfterFocusLost = true,
            Callback = function(msg)
                if msg and msg ~= "" then
                    ReplicatedStorage:SetAttribute(SS_PREFIX .. "Broadcast", msg)
                    Rayfield:Notify({Title = "Owner", Content = "Broadcast sent: " .. msg, Duration = 3})
                end
            end,
        })

        OwnerTab:CreateButton({
            Name = "Send Alert (All Users)",
            Callback = function()
                ReplicatedStorage:SetAttribute(SS_PREFIX .. "Broadcast", "ALERT: Owner is watching!")
                Rayfield:Notify({Title = "Owner", Content = "Alert sent to all users", Duration = 3})
            end,
        })

        OwnerTab:CreateSection("Poll")

        OwnerTab:CreateInput({
            Name = "Poll Question",
            PlaceholderText = "Type poll question...",
            RemoveTextAfterFocusLost = true,
            Callback = function(q)
                if q and q ~= "" then _G._SS_PollQuestion = q end
            end,
        })

        OwnerTab:CreateInput({
            Name = "Poll Options (comma separated)",
            PlaceholderText = "Yes,No,Maybe",
            RemoveTextAfterFocusLost = true,
            Callback = function(o)
                if o and o ~= "" then _G._SS_PollOptions = o end
            end,
        })

        OwnerTab:CreateButton({
            Name = "Start Poll",
            Callback = function()
                local q = _G._SS_PollQuestion
                local o = _G._SS_PollOptions
                if not q or q == "" or not o or o == "" then
                    Rayfield:Notify({Title = "Poll", Content = "Set question and options first!", Duration = 3})
                    return
                end
                ReplicatedStorage:SetAttribute(SS_PREFIX .. "Poll_Q", q)
                ReplicatedStorage:SetAttribute(SS_PREFIX .. "Poll_Opts", o)
                ReplicatedStorage:SetAttribute(SS_PREFIX .. "Poll_Votes", "")
                ReplicatedStorage:SetAttribute(SS_PREFIX .. "Poll_Active", true)
                Rayfield:Notify({Title = "Poll", Content = "Poll started: " .. q, Duration = 3})
            end,
        })

        OwnerTab:CreateButton({
            Name = "End Poll & Show Results",
            Callback = function()
                ReplicatedStorage:SetAttribute(SS_PREFIX .. "Poll_Active", false)
                local votes = ReplicatedStorage:GetAttribute(SS_PREFIX .. "Poll_Votes") or ""
                local opts = ReplicatedStorage:GetAttribute(SS_PREFIX .. "Poll_Opts") or ""
                local counts = {}
                for opt in opts:gmatch("[^,]+") do counts[opt] = 0 end
                for vote in votes:gmatch("[^;]+") do
                    if counts[vote] then counts[vote] = counts[vote] + 1 end
                end
                local result = ""
                for opt, c in pairs(counts) do result = result .. opt .. ": " .. c .. "  " end
                if result == "" then result = "No votes" end
                ReplicatedStorage:SetAttribute(SS_PREFIX .. "Broadcast", "POLL RESULTS: " .. result)
                Rayfield:Notify({Title = "Poll", Content = "Results: " .. result, Duration = 8})
            end,
        })

        OwnerTab:CreateSection("Server")

        OwnerTab:CreateButton({
            Name = "Server Info",
            Callback = function()
                local count = #Players:GetPlayers()
                local ssCount = 0
                for _, p in ipairs(Players:GetPlayers()) do
                    if ReplicatedStorage:GetAttribute(SS_PREFIX .. "User_" .. p.UserId) then
                        ssCount = ssCount + 1
                    end
                end
                local serverId = game.JobId ~= "" and string.sub(game.JobId, 1, 12) .. "..." or "Private"
                Rayfield:Notify({Title = "Server Info", Content = "Players: " .. count .. " | ScriptSource: " .. ssCount .. " | " .. serverId, Duration = 6})
            end,
        })
    end

    Rayfield:LoadConfiguration()

    pcall(function()
        ReplicatedStorage:SetAttribute(SS_PREFIX .. "User_" .. LocalPlayer.UserId, LocalPlayer.Name)
    end)

    Players.PlayerRemoving:Connect(function(p)
        pcall(function()
            ReplicatedStorage:SetAttribute(SS_PREFIX .. "User_" .. p.UserId, nil)
            ReplicatedStorage:SetAttribute(SS_PREFIX .. "Active_" .. p.UserId, nil)
            ReplicatedStorage:SetAttribute(SS_PREFIX .. "Bomb_" .. p.UserId, nil)
        end)
    end)

    do
        local myId = LocalPlayer.UserId
        local conn
        conn = ReplicatedStorage:GetAttributeChangedSignal(SS_PREFIX .. "Shutdown_" .. myId):Connect(function()
            if ReplicatedStorage:GetAttribute(SS_PREFIX .. "Shutdown_" .. myId) then
                cleanUpPlayer()
                Rayfield:Notify({Title = "Shutdown", Content = "Owner has shut down your UI", Duration = 3})
                task.delay(1, function()
                    pcall(function() Rayfield:Destroy() end)
                end)
                if conn then conn:Disconnect() end
            end
        end)
    end

    pcall(function()
        ReplicatedStorage:GetAttributeChangedSignal(SS_PREFIX .. "Broadcast"):Connect(function()
            local msg = ReplicatedStorage:GetAttribute(SS_PREFIX .. "Broadcast")
            if msg and msg ~= "" then
                Rayfield:Notify({Title = "Owner Broadcast", Content = tostring(msg), Duration = 8})
            end
        end)
    end)

    pcall(function()
        ReplicatedStorage:GetAttributeChangedSignal(SS_PREFIX .. "Poll_Active"):Connect(function()
            local active = ReplicatedStorage:GetAttribute(SS_PREFIX .. "Poll_Active")
            if active then
                local q = ReplicatedStorage:GetAttribute(SS_PREFIX .. "Poll_Q") or "?"
                local opts = ReplicatedStorage:GetAttribute(SS_PREFIX .. "Poll_Opts") or ""
                Rayfield:Notify({Title = "NEW POLL", Content = q, Duration = 5})
                task.delay(2, function()
                    Rayfield:Notify({Title = "POLL OPTIONS", Content = opts, Duration = 8})
                end)
            end
        end)
    end)

    Rayfield:Notify({Title = "ScriptSource", Content = "v1.5.0 loaded successfully!", Duration = 4})
end

if keyValid then
    startUI()
else
    showKeyUI(function()
        keyValid = true
        startUI()
    end)
end
