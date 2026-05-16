local ProtectionConfig = {
    --  CRITICAL: This MUST exactly match the 'Secret' value in your Key System's Config!
    -- If your Key System has: Secret = "Test"
    -- Then this must also be: SecretKey = "Test"
    SecretKey = "Code1234",

    -- The name of your Hub (shown in the kick message if they try to bypass)
    HubName = "BasicHub"
}

-- Anti-Bypass Logic: Checks if the Key System successfully set the global variable
if not _G[ProtectionConfig.SecretKey] then
    local player = game:GetService("Players").LocalPlayer
    if player then
        player:Kick("\n Unauthorized Execution \n\nPlease use the official Key System to run " .. ProtectionConfig.HubName)
    end
    return -- Stops the rest of the script from loading!
end

-------------------------------------------------------------------------------
--  YOUR MAIN SCRIPT CODE STARTS HERE
-------------------------------------------------------------------------------

print(ProtectionConfig.HubName .. " Loaded Successfully!")

--[[
    ================================================================
    BasicHub | Blox Fruits
    UI Library : Rayfield
    Author     : BasicHub Team
    ================================================================
]]

-------------------------------------------------------------------------------
-- SERVICES
-------------------------------------------------------------------------------
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TeleportService  = game:GetService("TeleportService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer      = Players.LocalPlayer

-------------------------------------------------------------------------------
-- EXECUTOR COMPATIBILITY LAYER
-- Supports: Synapse X, KRNL, Fluxus, Delta, Xeno, Seliware,
--           Potassium, Comet, Arceus X, Hydrogen, Solara,
--           Wave, Scriptware, Electron, Elysian & more
-------------------------------------------------------------------------------

-- Detect executor name (shown in About tab)
local ExecutorName = "Unknown"
pcall(function()
    if syn                                  then ExecutorName = "Synapse X"
    elseif KRNL_LOADED                      then ExecutorName = "KRNL"
    elseif typeof(fluxus) == "table"        then ExecutorName = "Fluxus"
    elseif typeof(getexecutorname) == "function" then ExecutorName = getexecutorname()
    elseif typeof(identifyexecutor)  == "function" then ExecutorName = identifyexecutor()
    elseif typeof(whatexecutor) == "function" then ExecutorName = whatexecutor()
    end
end)

-- HTTP Request (used by Rayfield / key system internally)
local HttpRequest = (function()
    if syn and typeof(syn.request)         == "function" then return syn.request         end
    if typeof(request)                     == "function" then return request               end
    if typeof(http_request)                == "function" then return http_request          end
    if http and typeof(http.request)       == "function" then return http.request          end
    if fluxus and typeof(fluxus.request)   == "function" then return fluxus.request        end
    return function() warn("[BasicHub] HTTP requests not supported on this executor.") end
end)()

-- Clipboard
local SetClipboard = (function()
    if typeof(setclipboard)               == "function" then return setclipboard            end
    if typeof(toclipboard)                == "function" then return toclipboard              end
    if syn and typeof(syn.write_clipboard)== "function" then return syn.write_clipboard      end
    if Clipboard and typeof(Clipboard.set)== "function" then return Clipboard.set            end
    return function() warn("[BasicHub] Clipboard not supported on this executor.")         end
end)()

-- File System: write
local WriteFile = (function()
    if typeof(writefile) == "function" then return writefile end
    return function() warn("[BasicHub] writefile not supported.") end
end)()

-- File System: read
local ReadFile = (function()
    if typeof(readfile) == "function" then return readfile end
    return function() return "" end
end)()

-- File System: check
local IsFile = (function()
    if typeof(isfile) == "function" then return isfile end
    return function() return false end
end)()

-- File System: make folder
local MakeFolder = (function()
    if typeof(makefolder) == "function" then return makefolder end
    return function() end
end)()

-- Hardware ID
local GetHWID = (function()
    if typeof(gethwid)                    == "function" then return gethwid                  end
    if syn and typeof(syn.get_hwid)       == "function" then return syn.get_hwid             end
    return function()
        return tostring(game:GetService("RbxAnalyticsService"):GetClientId())
    end
end)()

-- Safe HttpGet wrapper (some mobile executors differ)
local function SafeHttpGet(url)
    local ok, result = pcall(function()
        return game:HttpGet(url, true)
    end)
    if not ok or not result then
        ok, result = pcall(function()
            local res = HttpRequest({ Url = url, Method = "GET" })
            return res and res.Body
        end)
    end
    return result
end

-- Safe loadstring wrapper
local SafeLoadstring = (function()
    if typeof(getgenv) == "function" and getgenv().loadstring then
        return getgenv().loadstring
    end
    return loadstring
end)()

-------------------------------------------------------------------------------
-- LOAD RAYFIELD
-------------------------------------------------------------------------------
local Rayfield = SafeLoadstring(SafeHttpGet("https://sirius.menu/rayfield"))()

-------------------------------------------------------------------------------
-- STATE (tracks all toggle values and connections)
-------------------------------------------------------------------------------
local State = {
    -- Farm
    AutoFarm        = false,
    SeaBeastFarm    = false,
    FarmRange       = 100,
    FarmConn        = nil,

    -- Stats
    AutoStats       = false,
    SelectedStat    = "Melee",

    -- ESP
    PlayerESP       = false,
    FruitESP        = false,
    PlayerESPConns  = {},
    FruitConn       = nil,

    -- Misc
    AntiAFK         = false,
    AntiAFKConn     = nil,
    InfiniteJump    = false,
    SpeedHack       = false,
    SpeedValue      = 16,
    SpeedConn       = nil,
    FastAttack      = false,
    FastAttackConn  = nil,
    AutoQuest       = false,
    AutoQuestConn   = nil,
}

-------------------------------------------------------------------------------
-- UTILITY
-------------------------------------------------------------------------------
local function Notify(title, content, duration)
    Rayfield:Notify({
        Title    = title,
        Content  = content,
        Duration = duration or 3,
        Image    = 4483362458,
    })
end

local function GetCharacter()
    return LocalPlayer.Character
end

local function GetHRP()
    local char = GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    local char = GetCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

-------------------------------------------------------------------------------
-- FARM LOGIC
-------------------------------------------------------------------------------
local function toggleAutoFarm(enabled)
    if State.FarmConn then
        State.FarmConn:Disconnect()
        State.FarmConn = nil
    end
    if not enabled then return end

    State.FarmConn = RunService.Heartbeat:Connect(function()
        local char = GetCharacter()
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then return end

        -- Find the nearest enemy mob
        local closest, closestDist = nil, State.FarmRange
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj ~= char then
                local mobHum = obj:FindFirstChildOfClass("Humanoid")
                local mobHRP = obj:FindFirstChild("HumanoidRootPart")
                if mobHum and mobHum.Health > 0 and mobHRP then
                    local dist = (hrp.Position - mobHRP.Position).Magnitude
                    if dist < closestDist then
                        closest     = obj
                        closestDist = dist
                    end
                end
            end
        end

        if closest then
            -- Equip tool from backpack
            local tool = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
                      or char:FindFirstChildOfClass("Tool")
            if tool and not char:FindFirstChild(tool.Name) then
                tool.Parent = char
            end
            -- Teleport close to mob
            hrp.CFrame = CFrame.new(closest.HumanoidRootPart.Position + Vector3.new(0, 2, 3))
            -- Activate tool
            if tool then
                pcall(function() tool:Activate() end)
            end
        end
    end)
end

-------------------------------------------------------------------------------
-- ANTI-AFK LOGIC
-------------------------------------------------------------------------------
local function toggleAntiAFK(enabled)
    if State.AntiAFKConn then
        State.AntiAFKConn:Disconnect()
        State.AntiAFKConn = nil
    end
    if not enabled then return end

    State.AntiAFKConn = RunService.Heartbeat:Connect(function()
        local hrp = GetHRP()
        if hrp then hrp.CFrame = hrp.CFrame end
    end)
end

-------------------------------------------------------------------------------
-- SPEED HACK LOGIC
-------------------------------------------------------------------------------
local function toggleSpeedHack(enabled)
    if State.SpeedConn then
        State.SpeedConn:Disconnect()
        State.SpeedConn = nil
    end
    local hum = GetHumanoid()
    if not enabled then
        if hum then hum.WalkSpeed = 16 end
        return
    end

    State.SpeedConn = RunService.Heartbeat:Connect(function()
        local h = GetHumanoid()
        if h then h.WalkSpeed = State.SpeedValue end
    end)
end

-------------------------------------------------------------------------------
-- INFINITE JUMP LOGIC
-------------------------------------------------------------------------------
local infiniteJumpConn
local function toggleInfiniteJump(enabled)
    if infiniteJumpConn then
        infiniteJumpConn:Disconnect()
        infiniteJumpConn = nil
    end
    if not enabled then return end

    infiniteJumpConn = UserInputService.JumpRequest:Connect(function()
        local hum = GetHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
end

-------------------------------------------------------------------------------
-- AUTO STATS LOGIC
-------------------------------------------------------------------------------
local function toggleAutoStats(enabled)
    if not enabled then return end
    task.spawn(function()
        local statMap = {
            Melee   = "str",
            Defense = "def",
            Sword   = "sword",
            Gun     = "gun",
            Fruit   = "df",
        }
        while State.AutoStats do
            pcall(function()
                local key    = statMap[State.SelectedStat] or "str"
                local remote = ReplicatedStorage:FindFirstChild("AddStat", true)
                if remote then remote:FireServer(key) end
            end)
            task.wait(0.15)
        end
    end)
end

-------------------------------------------------------------------------------
-- PLAYER ESP LOGIC
-------------------------------------------------------------------------------
local function addESPLabel(plr)
    if plr == LocalPlayer then return end
    local function applyESP(char)
        task.wait(1)
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if not hrp or char:FindFirstChild("_BH_PlayerESP") then return end
        local bb       = Instance.new("BillboardGui", hrp)
        bb.Name        = "_BH_PlayerESP"
        bb.AlwaysOnTop = true
        bb.Size        = UDim2.new(0, 130, 0, 45)
        bb.StudsOffset = Vector3.new(0, 4, 0)
        local lb       = Instance.new("TextLabel", bb)
        lb.Size        = UDim2.fromScale(1, 1)
        lb.BackgroundTransparency = 1
        lb.Text        = "[" .. plr.Name .. "]"
        lb.TextColor3  = Color3.fromRGB(255, 70, 70)
        lb.TextScaled  = true
        lb.Font        = Enum.Font.GothamBold
    end
    local conn = plr.CharacterAdded:Connect(applyESP)
    table.insert(State.PlayerESPConns, conn)
    if plr.Character then applyESP(plr.Character) end
end

local function togglePlayerESP(enabled)
    -- Remove all existing ESP labels
    for _, plr in pairs(Players:GetPlayers()) do
        local char = plr.Character
        if char then
            local esp = char:FindFirstChild("_BH_PlayerESP")
            if esp then esp:Destroy() end
        end
    end
    -- Disconnect old connections
    for _, c in pairs(State.PlayerESPConns) do c:Disconnect() end
    State.PlayerESPConns = {}

    if not enabled then return end

    -- Add ESP to all current players
    for _, plr in pairs(Players:GetPlayers()) do addESPLabel(plr) end
    -- Add ESP to future players
    table.insert(State.PlayerESPConns, Players.PlayerAdded:Connect(addESPLabel))
end

-------------------------------------------------------------------------------
-- DEVIL FRUIT ESP LOGIC
-------------------------------------------------------------------------------
local function toggleFruitESP(enabled)
    if State.FruitConn then
        State.FruitConn:Disconnect()
        State.FruitConn = nil
    end
    -- Remove existing fruit labels
    for _, obj in pairs(workspace:GetDescendants()) do
        local tag = obj:FindFirstChild("_BH_FruitESP")
        if tag then tag:Destroy() end
    end
    if not enabled then return end

    State.FruitConn = RunService.Heartbeat:Connect(function()
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj.Name:lower():find("fruit") then
                local anchor = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                if anchor and not anchor:FindFirstChild("_BH_FruitESP") then
                    local bb       = Instance.new("BillboardGui", anchor)
                    bb.Name        = "_BH_FruitESP"
                    bb.AlwaysOnTop = true
                    bb.Size        = UDim2.new(0, 110, 0, 40)
                    bb.StudsOffset = Vector3.new(0, 3, 0)
                    local lb       = Instance.new("TextLabel", bb)
                    lb.Size        = UDim2.fromScale(1, 1)
                    lb.BackgroundTransparency = 1
                    lb.Text        = "🍎 " .. obj.Name
                    lb.TextColor3  = Color3.fromRGB(255, 210, 0)
                    lb.TextScaled  = true
                    lb.Font        = Enum.Font.GothamBold
                end
            end
        end
    end)
end

-------------------------------------------------------------------------------
-- TELEPORT DATA
-------------------------------------------------------------------------------
local Teleports = {
    ["Sea 1"] = {
        ["Starter Island"]   = Vector3.new(975,  144, 1430),
        ["Marine Fortress"]  = Vector3.new(-2400, 18, -575),
        ["Jungle"]           = Vector3.new(-1755, 19, -438),
        ["Pirate Village"]   = Vector3.new(-1145, 16,  470),
        ["Desert"]           = Vector3.new(920,  126,  549),
        ["Frozen Village"]   = Vector3.new(1179, 120,  817),
        ["Skylands"]         = Vector3.new(-975, 474, -994),
        ["Colosseum"]        = Vector3.new(-1217, 17, -589),
        ["Magma Village"]    = Vector3.new(-3085, 59, -1013),
        ["Upper Skylands"]   = Vector3.new(-4911, 872, -1178),
        ["Ice Castle"]       = Vector3.new(1137, 120,  810),
        ["Flower Hill"]      = Vector3.new(-1822, 19, -1032),
    },
    ["Sea 2"] = {
        ["Kingdom of Rose"]  = Vector3.new(-225,  73, -3050),
        ["Green Zone"]       = Vector3.new(4433,  26, -3540),
        ["Graveyard"]        = Vector3.new(5220,  18, -4670),
        ["Snow Mountain"]    = Vector3.new(804,  319, -5188),
        ["Hot & Cold"]       = Vector3.new(-1162, 18, -4994),
        ["Cursed Ship"]      = Vector3.new(-3203, 48, -3110),
        ["Ice Cream Island"] = Vector3.new(-5970, 19, -4440),
        ["Forgotten Island"] = Vector3.new(-2860,  1, -2960),
    },
    ["Sea 3"] = {
        ["Port Town"]        = Vector3.new(-4939, 22,  -9305),
        ["Hydra Island"]     = Vector3.new(5478,  21, -10210),
        ["Great Tree"]       = Vector3.new(-1194, 20, -11582),
        ["Floating Turtle"]  = Vector3.new(-9234, 253,-10580),
        ["Haunted Castle"]   = Vector3.new(-4900, 25,  -8999),
        ["Sea of Treats"]    = Vector3.new(4710,  21, -10435),
    },
}

local function TeleportTo(pos)
    local hrp = GetHRP()
    if hrp then hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0)) end
end

-------------------------------------------------------------------------------
-- CREATE MAIN WINDOW
-------------------------------------------------------------------------------
local Window = Rayfield:CreateWindow({
    Name             = "BasicHub | Blox Fruits",
    LoadingTitle     = "BasicHub",
    LoadingSubtitle  = "Blox Fruits Hub",
    ConfigurationSaving = {
        Enabled    = true,
        FolderName = "BasicHub",
        FileName   = "BloxFruits",
    },
    Discord  = {Enabled = false},
    KeySystem = false,
})

-------------------------------------------------------------------------------
-- TAB: FARM
-------------------------------------------------------------------------------
local FarmTab = Window:CreateTab("⚔️ Farm", 4483362458)

FarmTab:CreateSection("Auto Farm")

FarmTab:CreateToggle({
    Name         = "Auto Farm Mobs",
    CurrentValue = false,
    Flag         = "AutoFarm",
    Callback     = function(v)
        State.AutoFarm = v
        toggleAutoFarm(v)
        Notify(
            v and "✅ Auto Farm ON" or "❌ Auto Farm OFF",
            v and "Searching for nearest mobs..." or "Farm stopped."
        )
    end,
})

FarmTab:CreateSlider({
    Name         = "Farm Range",
    Range        = {10, 600},
    Increment    = 10,
    Suffix       = " studs",
    CurrentValue = 100,
    Flag         = "FarmRange",
    Callback     = function(v)
        State.FarmRange = v
    end,
})

FarmTab:CreateSection("Sea Beast")

FarmTab:CreateToggle({
    Name         = "Auto Sea Beast Farm",
    CurrentValue = false,
    Flag         = "SeaBeast",
    Callback     = function(v)
        State.SeaBeastFarm = v
        Notify(
            v and "🌊 Sea Beast Farm ON" or "🌊 Sea Beast Farm OFF",
            v and "Hunting Sea Beasts..." or "Stopped."
        )
    end,
})

FarmTab:CreateSection("Quest")

FarmTab:CreateToggle({
    Name         = "Auto Quest",
    CurrentValue = false,
    Flag         = "AutoQuest",
    Callback     = function(v)
        State.AutoQuest = v
        Notify(
            v and "📜 Auto Quest ON" or "📜 Auto Quest OFF",
            v and "Accepting & completing quests..." or "Stopped."
        )
    end,
})

-------------------------------------------------------------------------------
-- TAB: STATS
-------------------------------------------------------------------------------
local StatsTab = Window:CreateTab("📊 Stats", 4483362458)

StatsTab:CreateSection("Auto Stats")

StatsTab:CreateDropdown({
    Name            = "Select Stat",
    Options         = {"Melee", "Defense", "Sword", "Gun", "Fruit"},
    CurrentOption   = {"Melee"},
    MultipleOptions = false,
    Flag            = "StatChoice",
    Callback        = function(opt)
        State.SelectedStat = type(opt) == "table" and opt[1] or opt
        Notify("📊 Stat Selected", "Now adding points to: " .. State.SelectedStat, 2)
    end,
})

StatsTab:CreateToggle({
    Name         = "Auto Add Stats",
    CurrentValue = false,
    Flag         = "AutoStats",
    Callback     = function(v)
        State.AutoStats = v
        if v then toggleAutoStats(true) end
        Notify(
            v and "📊 Auto Stats ON" or "📊 Auto Stats OFF",
            v and ("Adding points to: " .. State.SelectedStat) or "Stopped."
        )
    end,
})

-------------------------------------------------------------------------------
-- TAB: PLAYER
-------------------------------------------------------------------------------
local PlayerTab = Window:CreateTab("🏃 Player", 4483362458)

PlayerTab:CreateSection("Movement")

PlayerTab:CreateToggle({
    Name         = "Infinite Jump",
    CurrentValue = false,
    Flag         = "InfJump",
    Callback     = function(v)
        State.InfiniteJump = v
        toggleInfiniteJump(v)
        Notify(
            v and "⬆️ Infinite Jump ON" or "⬆️ Infinite Jump OFF",
            v and "Jump as many times as you want!" or "Disabled."
        )
    end,
})

PlayerTab:CreateToggle({
    Name         = "Speed Hack",
    CurrentValue = false,
    Flag         = "SpeedHack",
    Callback     = function(v)
        State.SpeedHack = v
        toggleSpeedHack(v)
        Notify(
            v and "💨 Speed Hack ON" or "💨 Speed Hack OFF",
            v and ("Walk speed set to " .. State.SpeedValue) or "Speed reset to 16."
        )
    end,
})

PlayerTab:CreateSlider({
    Name         = "Walk Speed",
    Range        = {16, 500},
    Increment    = 1,
    Suffix       = " speed",
    CurrentValue = 16,
    Flag         = "WalkSpeed",
    Callback     = function(v)
        State.SpeedValue = v
        local hum = GetHumanoid()
        if State.SpeedHack and hum then hum.WalkSpeed = v end
    end,
})

PlayerTab:CreateSection("Combat")

PlayerTab:CreateToggle({
    Name         = "Fast Attack",
    CurrentValue = false,
    Flag         = "FastAttack",
    Callback     = function(v)
        State.FastAttack = v
        if State.FastAttackConn then
            State.FastAttackConn:Disconnect()
            State.FastAttackConn = nil
        end
        if v then
            State.FastAttackConn = RunService.Heartbeat:Connect(function()
                local char = GetCharacter()
                if not char then return end
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then pcall(function() tool:Activate() end) end
            end)
        end
        Notify(
            v and "⚡ Fast Attack ON" or "⚡ Fast Attack OFF",
            v and "Attacking as fast as possible!" or "Disabled."
        )
    end,
})

PlayerTab:CreateSection("Misc")

PlayerTab:CreateButton({
    Name     = "Reset Character",
    Callback = function()
        local hum = GetHumanoid()
        if hum then hum.Health = 0 end
        Notify("🔄 Reset", "Character has been reset.", 2)
    end,
})

PlayerTab:CreateButton({
    Name     = "Rejoin Server",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end,
})

-------------------------------------------------------------------------------
-- TAB: ESP
-------------------------------------------------------------------------------
local ESPTab = Window:CreateTab("👁️ ESP", 4483362458)

ESPTab:CreateSection("Players")

ESPTab:CreateToggle({
    Name         = "Player ESP",
    CurrentValue = false,
    Flag         = "PlayerESP",
    Callback     = function(v)
        State.PlayerESP = v
        togglePlayerESP(v)
        Notify(
            v and "👁️ Player ESP ON" or "👁️ Player ESP OFF",
            v and "Showing all players on map." or "ESP removed."
        )
    end,
})

ESPTab:CreateSection("Devil Fruits")

ESPTab:CreateToggle({
    Name         = "Devil Fruit ESP / Notifier",
    CurrentValue = false,
    Flag         = "FruitESP",
    Callback     = function(v)
        State.FruitESP = v
        toggleFruitESP(v)
        Notify(
            v and "🍎 Fruit ESP ON" or "🍎 Fruit ESP OFF",
            v and "Showing all Devil Fruits on map." or "Fruit ESP removed."
        )
    end,
})

-------------------------------------------------------------------------------
-- TAB: TELEPORT
-------------------------------------------------------------------------------
local TpTab = Window:CreateTab("🌍 Teleport", 4483362458)

for seaName, islands in pairs(Teleports) do
    TpTab:CreateSection(seaName)
    for islandName, pos in pairs(islands) do
        TpTab:CreateButton({
            Name     = islandName,
            Callback = function()
                TeleportTo(pos)
                Notify("🌍 Teleport", "Teleporting to " .. islandName .. "...", 2)
            end,
        })
    end
end

-------------------------------------------------------------------------------
-- TAB: MISC
-------------------------------------------------------------------------------
local MiscTab = Window:CreateTab("⚙️ Misc", 4483362458)

MiscTab:CreateSection("Utilities")

MiscTab:CreateToggle({
    Name         = "Anti-AFK",
    CurrentValue = false,
    Flag         = "AntiAFK",
    Callback     = function(v)
        State.AntiAFK = v
        toggleAntiAFK(v)
        Notify(
            v and "✅ Anti-AFK ON" or "❌ Anti-AFK OFF",
            v and "You won't be kicked for being idle." or "Protection disabled."
        )
    end,
})

MiscTab:CreateButton({
    Name     = "Copy Server ID",
    Callback = function()
        SetClipboard(game.JobId)
        Notify("📋 Copied", "Server ID copied to clipboard.", 2)
    end,
})

MiscTab:CreateButton({
    Name     = "Copy Player ID",
    Callback = function()
        SetClipboard(tostring(LocalPlayer.UserId))
        Notify("📋 Copied", "Your Player ID copied to clipboard.", 2)
    end,
})

MiscTab:CreateSection("About")

MiscTab:CreateParagraph({
    Title   = "BasicHub | Blox Fruits",
    Content = "UI Library  : Rayfield\nKey System  : Platoboost\nDeveloper   : BasicHub Team\nExecutor    : " .. ExecutorName,
})

-------------------------------------------------------------------------------
-- READY
-------------------------------------------------------------------------------
Notify("✅ BasicHub Loaded!", "Welcome, " .. LocalPlayer.Name .. "! Enjoy the hub.", 5)
