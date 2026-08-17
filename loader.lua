local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local OWNER = "HOPOUTHECUPE2"
local IsOwner = LocalPlayer.Name == OWNER
local SS_PREFIX = "SS_"

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

local isVerified = false

pcall(function()
    local ok, data = pcall(function() return game:HttpGet("https://raw.githubusercontent.com/justsadnyx-ux/ScriptSource/main/verified.txt") end)
    if ok and data then
        for line in data:gmatch("[^\r\n]+") do
            local name = line:match("^%s*(.-)%s*$")
            if name and name ~= "" and string.lower(name) == string.lower(LocalPlayer.Name) then
                isVerified = true
                break
            end
        end
    end
end)

if IsOwner then isVerified = true end

local function startUI()
    local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

    local Window = WindUI:CreateWindow({
        Title = "ScriptSource",
        Icon = "code",
        Theme = "Dark",
        Folder = "ScriptSource",
    })

    if isVerified then
        local MainTab = Window:Tab({ Title = "Main", Icon = "home" })

        MainTab:Section({ Title = "Character" })

        MainTab:Slider({
            Title = "Walk Speed",
            Step = 1,
            Value = { Min = 16, Max = 200, Default = 16 },
            Callback = function(v) local c = LocalPlayer.Character; if c then local h = c:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed = v end end end,
        })

        MainTab:Slider({
            Title = "Jump Power",
            Step = 5,
            Value = { Min = 50, Max = 300, Default = 50 },
            Callback = function(v) local c = LocalPlayer.Character; if c then local h = c:FindFirstChildOfClass("Humanoid"); if h then h.JumpPower = v end end end,
        })

        MainTab:Slider({
            Title = "Gravity",
            Step = 5,
            Value = { Min = 0, Max = 200, Default = 196 },
            Callback = function(v) workspace.Gravity = v end,
        })

        MainTab:Section({ Title = "Exploits" })

        MainTab:Toggle({
            Title = "Infinite Jump",
            Value = false,
            Callback = function(v)
                if v then
                    _G._SS_InfJump = UserInputService.JumpRequest:Connect(function()
                        local Char = LocalPlayer.Character
                        if Char and Char:FindFirstChildOfClass("Humanoid") then
                            Char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                        end
                    end)
                    WindUI:Notify({ Title = "ScriptSource", Content = "Infinite Jump ON", Duration = 2 })
                else
                    if _G._SS_InfJump then _G._SS_InfJump:Disconnect() end
                    WindUI:Notify({ Title = "ScriptSource", Content = "Infinite Jump OFF", Duration = 2 })
                end
            end,
        })

        MainTab:Toggle({
            Title = "Noclip",
            Value = false,
            Callback = function(v)
                if v then
                    _G._SS_Noclip = RunService.Stepped:Connect(function()
                        if LocalPlayer.Character then
                            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                                if part:IsA("BasePart") then part.CanCollide = false end
                            end
                        end
                    end)
                    WindUI:Notify({ Title = "ScriptSource", Content = "Noclip ON", Duration = 2 })
                else
                    if _G._SS_Noclip then _G._SS_Noclip:Disconnect() end
                    WindUI:Notify({ Title = "ScriptSource", Content = "Noclip OFF", Duration = 2 })
                end
            end,
        })

        MainTab:Toggle({
            Title = "Speed Boost",
            Value = false,
            Callback = function(v)
                local c = LocalPlayer.Character
                if c and c:FindFirstChildOfClass("Humanoid") then
                    c.Humanoid.WalkSpeed = v and 30 or 16
                end
                WindUI:Notify({ Title = "ScriptSource", Content = v and "Speed ON" or "Speed OFF", Duration = 2 })
            end,
        })

        local EspTab = Window:Tab({ Title = "ESP", Icon = "eye" })

        EspTab:Section({ Title = "Visuals" })

        EspTab:Toggle({
            Title = "Name Tags + Distance",
            Value = false,
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
                                    if d then d.Text = math.floor((myHRP.Position - hrp.Position).Magnitude) .. "m" end
                                end
                            end
                        end
                    end)
                    WindUI:Notify({ Title = "ScriptSource", Content = "ESP ON", Duration = 2 })
                else
                    if _G._SS_ESPJoin then _G._SS_ESPJoin:Disconnect() end
                    if _G._SS_ESPUpdate then _G._SS_ESPUpdate:Disconnect() end
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p.Character then for _, x in ipairs(p.Character:GetDescendants()) do if x.Name == "SS_ESP" then x:Destroy() end end end
                    end
                    WindUI:Notify({ Title = "ScriptSource", Content = "ESP OFF", Duration = 2 })
                end
            end,
        })

        EspTab:Toggle({
            Title = "Grid ESP (Red Outline)",
            Value = false,
            Callback = function(v)
                if v then
                    _G._SS_GridESP = RunService.RenderStepped:Connect(function()
                        for _, player in pairs(Players:GetPlayers()) do
                            if player ~= LocalPlayer and player.Character then
                                for _, part in pairs(player.Character:GetChildren()) do
                                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                                        if not part:FindFirstChild("SS_Grid") then
                                            local box = Instance.new("SelectionBox")
                                            box.Name = "SS_Grid"; box.Adornee = part
                                            box.Color3 = Color3.fromRGB(255, 0, 0)
                                            box.LineThickness = 0.04; box.Transparency = 0
                                            box.SurfaceColor3 = Color3.fromRGB(255, 0, 0); box.SurfaceTransparency = 1
                                            box.Parent = part
                                        end
                                    end
                                end
                            end
                        end
                    end)
                    WindUI:Notify({ Title = "ScriptSource", Content = "Grid ESP ON", Duration = 2 })
                else
                    if _G._SS_GridESP then _G._SS_GridESP:Disconnect() end
                    for _, player in pairs(Players:GetPlayers()) do
                        if player.Character then
                            for _, part in pairs(player.Character:GetDescendants()) do
                                if part.Name == "SS_Grid" then part:Destroy() end
                            end
                        end
                    end
                    WindUI:Notify({ Title = "ScriptSource", Content = "Grid ESP OFF", Duration = 2 })
                end
            end,
        })

        local BombTab = Window:Tab({ Title = "Bomb Game", Icon = "bomb" })

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

        BombTab:Section({ Title = "Auto Pass" })

        BombTab:Toggle({
            Title = "Auto-Pass",
            Value = false,
            Callback = function(v) AutoPassEnabled = v; WindUI:Notify({ Title = "ScriptSource", Content = v and "Auto-Pass ON" or "Auto-Pass OFF", Duration = 2 }) end,
        })

        BombTab:Slider({
            Title = "Trigger At",
            Step = 0.5,
            Value = { Min = 1, Max = 8, Default = 3 },
            Callback = function(v) TriggerTime = v end,
        })

        BombTab:Button({
            Title = "Force Transfer (Nearest)",
            Callback = function() ExecutePass() end,
        })

        BombTab:Section({ Title = "Manual Bomb" })

        BombTab:Slider({
            Title = "Timer",
            Step = 1,
            Value = { Min = 1, Max = 8, Default = 3 },
            Callback = function(v) bombTime = v end,
        })

        BombTab:Button({
            Title = "Start Bomb",
            Callback = function()
                if bombActive then WindUI:Notify({ Title = "ScriptSource", Content = "Already active", Duration = 2 }); return end
                bombActive = true
                ReplicatedStorage:SetAttribute(SS_PREFIX .. "Bomb_" .. LocalPlayer.UserId, true)
                showBombUI(LocalPlayer.Name, bombTime)
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
                    end
                end)
            end,
        })

        BombTab:Button({
            Title = "Stop Bomb",
            Callback = function()
                if not bombActive then return end
                bombActive = false
                if bombConn then bombConn:Disconnect(); bombConn = nil end
                ReplicatedStorage:SetAttribute(SS_PREFIX .. "Bomb_" .. LocalPlayer.UserId, nil)
                destroyBombUI()
                WindUI:Notify({ Title = "ScriptSource", Content = "Defused", Duration = 2 })
            end,
        })

        local MiscTab = Window:Tab({ Title = "Misc", Icon = "settings" })

        MiscTab:Section({ Title = "Performance" })

        MiscTab:Toggle({
            Title = "Anti-AFK",
            Value = false,
            Callback = function(v)
                if v then
                    _G._SS_AntiAFK = LocalPlayer.Idled:Connect(function()
                        game:GetService("VirtualUser"):CaptureController()
                        game:GetService("VirtualUser"):ClickButton2(Vector2.new())
                    end)
                    WindUI:Notify({ Title = "ScriptSource", Content = "Anti-AFK ON", Duration = 2 })
                else
                    if _G._SS_AntiAFK then _G._SS_AntiAFK:Disconnect() end
                    WindUI:Notify({ Title = "ScriptSource", Content = "Anti-AFK OFF", Duration = 2 })
                end
            end,
        })

        MiscTab:Toggle({
            Title = "FPS Boost",
            Value = false,
            Callback = function(v)
                if v then
                    pcall(function()
                        game.Lighting.FogEnd = 99999; game.Lighting.GlobalShadows = false
                        for _, x in ipairs(workspace:GetDescendants()) do
                            if x:IsA("ParticleEmitter") then x.Enabled = false end
                            if x:IsA("Trail") then x.Enabled = false end
                        end
                    end)
                    WindUI:Notify({ Title = "ScriptSource", Content = "FPS Boost ON", Duration = 2 })
                else
                    pcall(function()
                        game.Lighting.FogEnd = 100000; game.Lighting.GlobalShadows = true
                        for _, x in ipairs(workspace:GetDescendants()) do
                            if x:IsA("ParticleEmitter") then x.Enabled = true end
                            if x:IsA("Trail") then x.Enabled = true end
                        end
                    end)
                    WindUI:Notify({ Title = "ScriptSource", Content = "FPS Boost OFF", Duration = 2 })
                end
            end,
        })

        MiscTab:Section({ Title = "Poll" })

        MiscTab:Dropdown({
            Title = "Vote",
            Values = (function()
                local opts = ReplicatedStorage:GetAttribute(SS_PREFIX .. "Poll_Opts") or ""
                local t = {}
                for o in opts:gmatch("[^,]+") do table.insert(t, o) end
                if #t == 0 then table.insert(t, "No active poll") end
                return t
            end)(),
            Value = 1,
            Callback = function(v)
                if v == "No active poll" then return end
                if not ReplicatedStorage:GetAttribute(SS_PREFIX .. "Poll_Active") then
                    WindUI:Notify({ Title = "ScriptSource", Content = "No active poll", Duration = 2 }); return
                end
                local existing = ReplicatedStorage:GetAttribute(SS_PREFIX .. "Poll_Votes") or ""
                local newVotes = existing == "" and (LocalPlayer.Name .. ":" .. v) or existing .. ";" .. LocalPlayer.Name .. ":" .. v
                ReplicatedStorage:SetAttribute(SS_PREFIX .. "Poll_Votes", newVotes)
                WindUI:Notify({ Title = "ScriptSource", Content = "Voted: " .. v, Duration = 2 })
            end,
        })

        MiscTab:Section({ Title = "Session" })

        MiscTab:Button({
            Title = "Close ScriptSource",
            Callback = function() cleanUpPlayer(); WindUI:Destroy() end,
        })

        MiscTab:Button({
            Title = "Reload",
            Callback = function()
                cleanUpPlayer(); WindUI:Destroy(); task.wait(0.5)
                local ok, src = pcall(function() return game:HttpGet("https://raw.githubusercontent.com/justsadnyx-ux/ScriptSource/main/loader.lua") end)
                if ok and src then loadstring(src)() end
            end,
        })

        local UpdatesTab = Window:Tab({ Title = "Updates", Icon = "refresh-cw" })

        UpdatesTab:Section({ Title = "Version" })

        UpdatesTab:Button({
            Title = "Check for Updates",
            Callback = function()
                local ok, ver = pcall(function() return game:HttpGet("https://raw.githubusercontent.com/justsadnyx-ux/ScriptSource/main/version.txt") end)
                if ok and ver and ver:gsub("%s+", "") ~= "2.0" then
                    WindUI:Notify({ Title = "ScriptSource", Content = "Update available: v" .. ver:gsub("%s+", ""), Duration = 6 })
                elseif ok then
                    WindUI:Notify({ Title = "ScriptSource", Content = "Up to date", Duration = 3 })
                else
                    WindUI:Notify({ Title = "ScriptSource", Content = "Check failed", Duration = 3 })
                end
            end,
        })

        UpdatesTab:Button({
            Title = "Update Now",
            Callback = function()
                cleanUpPlayer(); WindUI:Destroy(); task.wait(0.5)
                local ok, src = pcall(function() return game:HttpGet("https://raw.githubusercontent.com/justsadnyx-ux/ScriptSource/main/loader.lua") end)
                if ok and src then loadstring(src)() end
            end,
        })

        if IsOwner then
            local OwnerTab = Window:Tab({ Title = "Owner", Icon = "shield" })
            local selectedPlayer = nil
            local ssUsers = {}

            local function getSSUserNames()
                local names = {}; ssUsers = {}
                for _, p in ipairs(Players:GetPlayers()) do
                    if ReplicatedStorage:GetAttribute(SS_PREFIX .. "User_" .. p.UserId) then
                        table.insert(names, p.Name); ssUsers[p.Name] = p
                    end
                end
                if #names == 0 then table.insert(names, "No users online") end
                return names
            end

            OwnerTab:Section({ Title = "Online Users" })

            OwnerTab:Dropdown({
                Title = "Select",
                Values = getSSUserNames(),
                Value = 1,
                Callback = function(v) selectedPlayer = ssUsers[v] or nil end,
            })

            OwnerTab:Button({
                Title = "Refresh",
                Callback = function()
                    getSSUserNames()
                    local list = {}; for k in pairs(ssUsers) do table.insert(list, k) end
                    WindUI:Notify({ Title = "ScriptSource", Content = #list > 0 and table.concat(list, ", ") or "None", Duration = 5 })
                end,
            })

            OwnerTab:Section({ Title = "Actions" })

            OwnerTab:Button({
                Title = "Kick",
                Callback = function()
                    if not selectedPlayer then WindUI:Notify({ Title = "ScriptSource", Content = "Select a user", Duration = 2 }); return end
                    pcall(function() selectedPlayer:Kick("[ScriptSource] Kicked by owner") end)
                end,
            })

            OwnerTab:Button({
                Title = "Shutdown UI",
                Callback = function()
                    if not selectedPlayer then WindUI:Notify({ Title = "ScriptSource", Content = "Select a user", Duration = 2 }); return end
                    pcall(function() ReplicatedStorage:SetAttribute(SS_PREFIX .. "Shutdown_" .. selectedPlayer.UserId, true) end)
                end,
            })

            OwnerTab:Section({ Title = "Broadcast" })

            OwnerTab:Input({
                Title = "Message",
                Placeholder = "Type message...",
                Callback = function(msg)
                    if msg and msg ~= "" then ReplicatedStorage:SetAttribute(SS_PREFIX .. "Broadcast", msg) end
                end,
            })

            OwnerTab:Button({
                Title = "New UI Alert",
                Callback = function()
                    ReplicatedStorage:SetAttribute(SS_PREFIX .. "Broadcast", "NEW UI UPDATE! Re-execute ScriptSource!")
                end,
            })

            OwnerTab:Section({ Title = "Poll" })

            OwnerTab:Input({
                Title = "Question",
                Placeholder = "Question...",
                Callback = function(q) if q and q ~= "" then _G._SS_PollQ = q end end,
            })

            OwnerTab:Input({
                Title = "Options (comma sep)",
                Placeholder = "Yes,No,Maybe",
                Callback = function(o) if o and o ~= "" then _G._SS_PollOpts = o end end,
            })

            OwnerTab:Button({
                Title = "Start Poll",
                Callback = function()
                    local q, o = _G._SS_PollQ, _G._SS_PollOpts
                    if not q or q == "" or not o or o == "" then WindUI:Notify({ Title = "ScriptSource", Content = "Set question + options", Duration = 2 }); return end
                    ReplicatedStorage:SetAttribute(SS_PREFIX .. "Poll_Q", q)
                    ReplicatedStorage:SetAttribute(SS_PREFIX .. "Poll_Opts", o)
                    ReplicatedStorage:SetAttribute(SS_PREFIX .. "Poll_Votes", "")
                    ReplicatedStorage:SetAttribute(SS_PREFIX .. "Poll_Active", true)
                end,
            })

            OwnerTab:Button({
                Title = "End Poll",
                Callback = function()
                    ReplicatedStorage:SetAttribute(SS_PREFIX .. "Poll_Active", false)
                    local votes = ReplicatedStorage:GetAttribute(SS_PREFIX .. "Poll_Votes") or ""
                    local opts = ReplicatedStorage:GetAttribute(SS_PREFIX .. "Poll_Opts") or ""
                    local counts = {}; for opt in opts:gmatch("[^,]+") do counts[opt] = 0 end
                    for vote in votes:gmatch("[^;]+") do if counts[vote] then counts[vote] = counts[vote] + 1 end end
                    local result = ""; for opt, c in pairs(counts) do result = result .. opt .. ":" .. c .. " " end
                    if result == "" then result = "No votes" end
                    ReplicatedStorage:SetAttribute(SS_PREFIX .. "Broadcast", "POLL RESULTS: " .. result)
                end,
            })
        end
    else
        local VerifyTab = Window:Tab({ Title = "Verify", Icon = "check-circle" })

        VerifyTab:Section({ Title = "Account Required" })

        VerifyTab:Paragraph({
            Title = "Not Verified",
            Content = "Go to justsadnyx-ux.github.io/ScriptSource/verify/ and verify your Roblox username to unlock ScriptSource.",
        })

        VerifyTab:Button({
            Title = "Copy Verify Link",
            Callback = function()
                pcall(function()
                    if setclipboard then setclipboard("https://justsadnyx-ux.github.io/ScriptSource/verify/")
                    else game:GetService("StarterGui"):SetCore("SetClipboard", "https://justsadnyx-ux.github.io/ScriptSource/verify/") end
                end)
                WindUI:Notify({ Title = "ScriptSource", Content = "Link copied!", Duration = 3 })
            end,
        })

        VerifyTab:Button({
            Title = "Refresh Verification",
            Callback = function()
                cleanUpPlayer(); WindUI:Destroy(); task.wait(0.5)
                local ok, src = pcall(function() return game:HttpGet("https://raw.githubusercontent.com/justsadnyx-ux/ScriptSource/main/loader.lua") end)
                if ok and src then loadstring(src)() end
            end,
        })
    end

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
                task.delay(1, function() pcall(function() WindUI:Destroy() end) end)
                if conn then conn:Disconnect() end
            end
        end)
    end)

    pcall(function()
        ReplicatedStorage:GetAttributeChangedSignal(SS_PREFIX .. "Broadcast"):Connect(function()
            local msg = ReplicatedStorage:GetAttribute(SS_PREFIX .. "Broadcast")
            if msg and msg ~= "" then WindUI:Notify({ Title = "Broadcast", Content = tostring(msg), Duration = 8 }) end
        end)
    end)

    pcall(function()
        ReplicatedStorage:GetAttributeChangedSignal(SS_PREFIX .. "Poll_Active"):Connect(function()
            if ReplicatedStorage:GetAttribute(SS_PREFIX .. "Poll_Active") then
                local q = ReplicatedStorage:GetAttribute(SS_PREFIX .. "Poll_Q") or "?"
                local o = ReplicatedStorage:GetAttribute(SS_PREFIX .. "Poll_Opts") or ""
                WindUI:Notify({ Title = "NEW POLL", Content = q, Duration = 5 })
                task.delay(2, function() WindUI:Notify({ Title = "OPTIONS", Content = o, Duration = 8 }) end)
            end
        end)
    end)

    WindUI:Notify({ Title = "ScriptSource", Content = "v2.0 loaded", Duration = 3 })
end

startUI()
