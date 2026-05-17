local ProtectionConfig = { SecretKey = "Code1234", HubName = "BasicHub" }
if not _G[ProtectionConfig.SecretKey] then
    local p = game:GetService("Players").LocalPlayer
    if p then p:Kick("\n Unauthorized Execution \n\nUse the official BasicHub key system.") end
    return
end

-------------------------------------------------------------------------------
-- SERVICES
-------------------------------------------------------------------------------
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService   = game:GetService("TeleportService")
local Debris            = game:GetService("Debris")
local VIM               = game:GetService("VirtualInputManager")
local LocalPlayer       = Players.LocalPlayer

-------------------------------------------------------------------------------
-- EXECUTOR NAME
-------------------------------------------------------------------------------
local ExecutorName = "Unknown"
pcall(function()
    if syn                                        then ExecutorName = "Synapse X"
    elseif KRNL_LOADED                            then ExecutorName = "KRNL"
    elseif typeof(fluxus) == "table"              then ExecutorName = "Fluxus"
    elseif typeof(getexecutorname) == "function"  then ExecutorName = getexecutorname()
    elseif typeof(identifyexecutor)  == "function" then ExecutorName = identifyexecutor()
    end
end)

-------------------------------------------------------------------------------
-- LOAD RAYFIELD
-------------------------------------------------------------------------------
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------
local HOVER_HEIGHT   = 5      -- studs above mob (close enough for melee/fruit)
local GACHA_INTERVAL = 7200   -- 2 hours in seconds
local GACHA_MIN_BELI = 50000

-------------------------------------------------------------------------------
-- STATE
-------------------------------------------------------------------------------
local State = {
    AutoQuestFarm  = false,
    AutoGacha      = false,
    FruitESP       = false,
    AutoCollect    = false,
    PlayerESP      = false,
    AntiAFK        = false,
    AutoStats      = false,
    SelectedStat   = "Melee",

    FruitESPConn   = nil,
    AntiAFKConn    = nil,
    PlayerESPConns = {},

    GachaLastBuy   = 0,  -- persistent timer, never reset by toggle
    StatusLabel    = nil,
}

-------------------------------------------------------------------------------
-- UTILITY
-------------------------------------------------------------------------------
local function GetChar()  return LocalPlayer.Character end
local function GetHRP()
    local c = GetChar(); return c and c:FindFirstChild("HumanoidRootPart")
end
local function GetHum()
    local c = GetChar(); return c and c:FindFirstChildOfClass("Humanoid")
end
local function GetLevel()
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    return ls and ls:FindFirstChild("Level") and ls.Level.Value or 1
end
local function GetBeli()
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if ls then
        for _, v in pairs(ls:GetChildren()) do
            if v.Name == "Beli" or v.Name == "Money" or v.Name == "Bounty" then
                return v.Value or 0
            end
        end
    end
    return 0
end
local function Notify(title, msg, dur)
    Rayfield:Notify({ Title = title, Content = msg, Duration = dur or 3, Image = 4483362458 })
end
local function SetStatus(txt)
    if State.StatusLabel and State.StatusLabel.Parent then
        State.StatusLabel:Set({ Title = "Status", Content = txt })
    end
end

-------------------------------------------------------------------------------
-- NOCLIP  (temporary, prevents getting stuck in geometry during teleport)
-------------------------------------------------------------------------------
local function Noclip()
    local char = GetChar()
    if not char then return end
    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("BasePart") then v.CanCollide = false end
    end
end

-------------------------------------------------------------------------------
-- TELEPORT  (direct CFrame — most reliable method in Blox Fruits)
-------------------------------------------------------------------------------
local function TeleportTo(pos)
    local hrp = GetHRP()
    if not hrp then return end
    Noclip()
    hrp.CFrame = CFrame.new(pos)
    task.wait(0.15)
end

-- Smooth version for the island teleport tab (looks nicer, same reliability)
local function SmoothTeleportTo(pos)
    local hrp = GetHRP()
    if not hrp then return end
    local startPos = hrp.Position
    local dist     = (startPos - pos).Magnitude
    if dist < 5 then return end
    local steps = math.clamp(math.floor(dist / 80), 3, 18)
    for i = 1, steps do
        if not GetHRP() then return end
        Noclip()
        GetHRP().CFrame = CFrame.new(startPos:Lerp(pos, i / steps) + Vector3.new(0, 8, 0))
        task.wait(0.05)
    end
    TeleportTo(pos)
end

-------------------------------------------------------------------------------
-- WAIT FOR RESPAWN
-------------------------------------------------------------------------------
local function WaitForChar()
    if not GetHRP() then
        repeat task.wait(0.5) until GetHRP()
        task.wait(2)
    end
end

-------------------------------------------------------------------------------
-- PLAYER CHARACTER REGISTRY  (never target real players as mobs)
-------------------------------------------------------------------------------
local playerChars = {}
local function registerChar(p)
    if p == LocalPlayer then return end
    p.CharacterAdded:Connect(function(c)   playerChars[c] = true  end)
    p.CharacterRemoving:Connect(function(c) playerChars[c] = nil   end)
    if p.Character then playerChars[p.Character] = true end
end
Players.PlayerAdded:Connect(registerChar)
Players.PlayerRemoving:Connect(function(p)
    if p.Character then playerChars[p.Character] = nil end
end)
for _, p in pairs(Players:GetPlayers()) do registerChar(p) end

local function IsPlayer(model)
    return playerChars[model] == true
end

-------------------------------------------------------------------------------
-- FIND NEAREST MOB
-------------------------------------------------------------------------------
local function FindNearestMob(nameFilter)
    local hrp = GetHRP()
    if not hrp then return nil end
    local best, bestDist = nil, math.huge
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= GetChar() and not IsPlayer(obj) then
            local hum  = obj:FindFirstChildOfClass("Humanoid")
            local mhrp = obj:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and mhrp then
                if not nameFilter or obj.Name:lower():find(nameFilter:lower(), 1, true) then
                    local d = (hrp.Position - mhrp.Position).Magnitude
                    if d < bestDist then
                        best     = obj
                        bestDist = d
                    end
                end
            end
        end
    end
    return best
end

-------------------------------------------------------------------------------
-- EQUIP TOOL  (sword / devil fruit from backpack)
-------------------------------------------------------------------------------
local function EquipTool()
    local char = GetChar()
    if not char then return nil end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then
        tool = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
        if tool then tool.Parent = char end
    end
    return tool
end

-------------------------------------------------------------------------------
-- SIMULATE KEY PRESS  (for devil fruit / melee skills)
-------------------------------------------------------------------------------
local function SimKey(key)
    pcall(function()
        VIM:SendKeyEvent(true,  key, false, game)
        task.wait(0.05)
        VIM:SendKeyEvent(false, key, false, game)
    end)
end

-------------------------------------------------------------------------------
-- ATTACK
-- 1. Equipped tool (sword / melee) — tool:Activate()
-- 2. Devil fruit & melee skills  — Z, X, C key simulation
-- 3. Fallback: firetouchinterest on nearby HRPs
-------------------------------------------------------------------------------
local function DoAttack()
    -- Tool attack (sword / melee tool)
    local tool = EquipTool()
    if tool then
        pcall(function() tool:Activate() end)
    end

    -- Skill keys: Z = basic skill, X = skill 2, C = skill 3
    -- Works for devil fruits, melee styles (Black Leg, Dragon Talon, etc.)
    SimKey(Enum.KeyCode.Z)
    task.wait(0.05)
    SimKey(Enum.KeyCode.X)
    task.wait(0.05)
    SimKey(Enum.KeyCode.C)

    -- Fallback touch damage (works for many sword hit boxes)
    pcall(function()
        local hrp = GetHRP()
        if not hrp then return end
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Humanoid") and obj.Health > 0 then
                local mhrp = obj.Parent and obj.Parent:FindFirstChild("HumanoidRootPart")
                if mhrp
                and not IsPlayer(obj.Parent)
                and (hrp.Position - mhrp.Position).Magnitude < 15 then
                    firetouchinterest(hrp, mhrp, 0)
                    firetouchinterest(hrp, mhrp, 1)
                end
            end
        end
    end)
end

-------------------------------------------------------------------------------
-- KILL MOB  (teleport directly above mob, attack until dead)
-------------------------------------------------------------------------------
local function KillMob(mob)
    if not mob or not mob.Parent then return end
    local mhrp = mob:FindFirstChild("HumanoidRootPart")
    if not mhrp then return end

    local maxTime = os.clock() + 25
    while State.AutoQuestFarm and mob.Parent and os.clock() < maxTime do
        local hum = mob:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then break end

        if not GetHRP() then break end

        -- Keep teleporting above mob as it moves
        TeleportTo(mhrp.Position + Vector3.new(0, HOVER_HEIGHT, 0))
        DoAttack()
        task.wait(0.08)
    end
end

-------------------------------------------------------------------------------
-- QUEST DATA
-- Y coordinates raised above ground so player doesn't spawn in water/terrain.
-- questNPC field is used to narrow the ClickDetector search near questPos.
-------------------------------------------------------------------------------
local QuestData = {
    -- ══ SEA 1 ══
    { level={1,14},    area="Starter Island",  mobName="Bandit",              questPos=Vector3.new(980, 155,1412),    farmPos=Vector3.new(975,155,1405)     },
    { level={15,29},   area="Marine Fortress", mobName="Marine",              questPos=Vector3.new(-2428, 25,-582),   farmPos=Vector3.new(-2465,25,-605)    },
    { level={30,44},   area="Pirate Village",  mobName="Pirate",              questPos=Vector3.new(-1141, 22, 479),   farmPos=Vector3.new(-1175,22,505)     },
    { level={45,59},   area="Jungle",          mobName="Gorilla",             questPos=Vector3.new(-1756, 25,-445),   farmPos=Vector3.new(-1810,25,-465)    },
    { level={60,74},   area="Desert",          mobName="Desert Bandit",       questPos=Vector3.new(922, 132, 551),    farmPos=Vector3.new(900,132,528)      },
    { level={75,89},   area="Frozen Village",  mobName="Snow Bandit",         questPos=Vector3.new(1182,126, 820),    farmPos=Vector3.new(1155,126,805)     },
    { level={90,109},  area="Skylands",        mobName="Sky Bandit",          questPos=Vector3.new(-972,480,-990),    farmPos=Vector3.new(-1005,480,-1025)  },
    { level={110,134}, area="Colosseum",       mobName="Prisoner",            questPos=Vector3.new(-1222, 25,-592),   farmPos=Vector3.new(-1255,25,-605)    },
    { level={135,174}, area="Magma Village",   mobName="Magma Ninja",         questPos=Vector3.new(-3090, 68,-1018),  farmPos=Vector3.new(-3115,68,-1035)   },
    { level={175,209}, area="Upper Skylands",  mobName="Wyvern",              questPos=Vector3.new(-4915,878,-1182),  farmPos=Vector3.new(-4945,878,-1205)  },
    { level={210,249}, area="Upper Skylands",  mobName="Demonic Soul",        questPos=Vector3.new(-4852,878,-1152),  farmPos=Vector3.new(-4875,878,-1182)  },
    { level={250,299}, area="Ice Castle",      mobName="Snow Demon",          questPos=Vector3.new(1140,126, 812),    farmPos=Vector3.new(1105,126,793)     },
    { level={300,374}, area="Flower Hill",     mobName="Chief Pirate",        questPos=Vector3.new(-1825, 27,-1038),  farmPos=Vector3.new(-1855,27,-1065)   },
    { level={375,449}, area="Middle Town",     mobName="Citizen",             questPos=Vector3.new(-565, 15,1622),    farmPos=Vector3.new(-585,15,1645)     },
    { level={450,549}, area="Underwater City", mobName="Fishman",             questPos=Vector3.new(61440,20,1528),    farmPos=Vector3.new(61422,20,1503)    },
    { level={550,624}, area="Fountain City",   mobName="Fountain City Guard", questPos=Vector3.new(3806, 32,3875),    farmPos=Vector3.new(3825,32,3898)     },
    { level={625,699}, area="Skylands II",     mobName="Dragon Crew",         questPos=Vector3.new(-4828,514,-1138),  farmPos=Vector3.new(-4843,514,-1153)  },
    -- ══ SEA 2 ══
    { level={700,774},   area="Kingdom of Rose",  mobName="Mercenary",          questPos=Vector3.new(-228, 82,-3055),   farmPos=Vector3.new(-258,82,-3090)    },
    { level={775,849},   area="Green Zone",       mobName="Factory Worker",     questPos=Vector3.new(4436, 35,-3545),   farmPos=Vector3.new(4453,35,-3565)    },
    { level={850,924},   area="Graveyard",        mobName="Zombie",             questPos=Vector3.new(5223, 27,-4675),   farmPos=Vector3.new(5243,27,-4698)    },
    { level={925,999},   area="Snow Mountain",    mobName="Snow Demon",         questPos=Vector3.new(806,328,-5192),    farmPos=Vector3.new(783,328,-5214)    },
    { level={1000,1074}, area="Hot & Cold",       mobName="Snowstorm Warrior",  questPos=Vector3.new(-1165, 26,-4998),  farmPos=Vector3.new(-1183,26,-5018)   },
    { level={1075,1149}, area="Cursed Ship",      mobName="Cursed Pirate",      questPos=Vector3.new(-3206, 57,-3115),  farmPos=Vector3.new(-3223,57,-3140)   },
    { level={1150,1249}, area="Ice Cream Island", mobName="Chocolate Bar",      questPos=Vector3.new(-5973, 28,-4445),  farmPos=Vector3.new(-5993,28,-4465)   },
    { level={1250,1349}, area="Forgotten Island", mobName="Tide Keeper",        questPos=Vector3.new(-2863, 10,-2965),  farmPos=Vector3.new(-2883,10,-2990)   },
    { level={1350,1499}, area="Library",          mobName="Sea Soldier",        questPos=Vector3.new(-3230,835,-4398),  farmPos=Vector3.new(-3248,835,-4418)  },
    -- ══ SEA 3 ══
    { level={1500,1574}, area="Port Town",         mobName="Hunter",            questPos=Vector3.new(-4942, 32,-9310),  farmPos=Vector3.new(-4963,32,-9335)   },
    { level={1575,1649}, area="Hydra Island",      mobName="Marine Lieutenant", questPos=Vector3.new(5480, 30,-10215),  farmPos=Vector3.new(5502,30,-10240)   },
    { level={1650,1724}, area="Great Tree",        mobName="Living Zombie",     questPos=Vector3.new(-1197, 30,-11587), farmPos=Vector3.new(-1218,30,-11610)  },
    { level={1725,1799}, area="Floating Turtle",   mobName="Toad",              questPos=Vector3.new(-9237,263,-10585), farmPos=Vector3.new(-9258,263,-10610) },
    { level={1800,1874}, area="Haunted Castle",    mobName="Possessed Mummy",   questPos=Vector3.new(-4903, 35,-9005),  farmPos=Vector3.new(-4923,35,-9030)   },
    { level={1875,1999}, area="Sea of Treats",     mobName="Sweet Thief",       questPos=Vector3.new(4713, 30,-10440),  farmPos=Vector3.new(4733,30,-10465)   },
    { level={2000,2149}, area="Great Tree (High)", mobName="Tree Spirit",       questPos=Vector3.new(-1203,230,-11595), farmPos=Vector3.new(-1223,231,-11620) },
    { level={2150,2299}, area="Demonic Dimension", mobName="Demonic Soul",      questPos=Vector3.new(-1583,218,-11505), farmPos=Vector3.new(-1603,220,-11530) },
}

local function GetQuestForLevel(lvl)
    local best = nil
    for _, q in ipairs(QuestData) do
        if lvl >= q.level[1] and lvl <= q.level[2] then return q end
        if lvl > q.level[2] then
            if not best or q.level[1] > best.level[1] then best = q end
        end
    end
    return best
end

-------------------------------------------------------------------------------
-- QUEST ACCEPT
-- 1. Teleport directly to quest NPC position
-- 2. Fire every ClickDetector within 35 studs of that position
-- 3. Click the "Accept" button that appears in PlayerGui
-------------------------------------------------------------------------------
local function TryAcceptQuest(quest)
    -- Teleport to quest NPC
    TeleportTo(quest.questPos + Vector3.new(0, 5, 0))
    task.wait(0.6)

    -- Fire ClickDetectors near quest position
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("ClickDetector") then
            local part    = obj.Parent
            local partPos = nil
            if part then
                if part:IsA("BasePart") then
                    partPos = part.Position
                elseif part:FindFirstChild("HumanoidRootPart") then
                    partPos = part.HumanoidRootPart.Position
                elseif part:FindFirstChildWhichIsA("BasePart") then
                    partPos = part:FindFirstChildWhichIsA("BasePart").Position
                end
            end
            if partPos and (partPos - quest.questPos).Magnitude < 35 then
                pcall(fireClickDetector, obj, 0)
                task.wait(0.15)
            end
        end
    end

    task.wait(0.4)

    -- Click Accept / Start in any dialog that appeared
    pcall(function()
        for _, gui in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
            if gui:IsA("TextButton") then
                local t = gui.Text:lower()
                if t:find("accept") or t:find("start") or t:find("quest") then
                    gui.MouseButton1Click:Fire()
                end
            end
        end
    end)

    task.wait(0.4)
end

-------------------------------------------------------------------------------
-- COLLECT NEARBY FRUITS
-------------------------------------------------------------------------------
local function CollectNearbyFruits()
    local hrp = GetHRP()
    if not hrp then return end
    for _, obj in pairs(workspace:GetDescendants()) do
        if not IsPlayer(obj:IsA("Model") and obj or obj.Parent) then
            local n = obj.Name:lower()
            if n:find("fruit") then
                local pos
                if obj:IsA("Model") then
                    local p = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                    pos = p and p.Position
                elseif obj:IsA("BasePart") then
                    pos = obj.Position
                end
                if pos and (hrp.Position - pos).Magnitude < 2000 then
                    SetStatus("🍎 Collecting: " .. obj.Name)
                    TeleportTo(pos + Vector3.new(0, 3, 0))
                    task.wait(0.3)
                    pcall(function()
                        for _, child in pairs(workspace:GetDescendants()) do
                            if (child:IsA("ClickDetector") or child:IsA("ProximityPrompt")) then
                                local cp = child.Parent
                                local cPos = cp and (cp:IsA("BasePart") and cp.Position)
                                if cPos and (cPos - pos).Magnitude < 10 then
                                    if child:IsA("ClickDetector") then
                                        fireClickDetector(child)
                                    else
                                        fireproximityprompt(child)
                                    end
                                end
                            end
                        end
                    end)
                    task.wait(0.2)
                end
            end
        end
    end
end

-------------------------------------------------------------------------------
-- FRUIT ESP
-------------------------------------------------------------------------------
local function AddFruitESPLabel(obj)
    if obj:FindFirstChild("_BH_FruitESP") then return end
    local target = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or obj
    if not target or not target:IsA("BasePart") then return end
    local bb       = Instance.new("BillboardGui")
    bb.Name        = "_BH_FruitESP"
    bb.AlwaysOnTop = true
    bb.Size        = UDim2.new(0, 140, 0, 44)
    bb.StudsOffset = Vector3.new(0, 4, 0)
    bb.Parent      = target
    local lb       = Instance.new("TextLabel", bb)
    lb.Size        = UDim2.fromScale(1, 1)
    lb.BackgroundTransparency = 1
    lb.Text        = "🍎 " .. obj.Name
    lb.TextColor3  = Color3.fromRGB(255, 210, 0)
    lb.TextScaled  = true
    lb.Font        = Enum.Font.GothamBold
end
local function RemoveAllFruitESP()
    for _, obj in pairs(workspace:GetDescendants()) do
        local t = obj:FindFirstChild("_BH_FruitESP")
        if t then t:Destroy() end
    end
end
local function ToggleFruitESP(enabled)
    if State.FruitESPConn then State.FruitESPConn:Disconnect(); State.FruitESPConn = nil end
    RemoveAllFruitESP()
    if not enabled then return end
    State.FruitESPConn = RunService.Heartbeat:Connect(function()
        for _, obj in pairs(workspace:GetDescendants()) do
            if not IsPlayer(obj:IsA("Model") and obj or obj.Parent) then
                local n = obj.Name:lower()
                if n:find("fruit") then
                    AddFruitESPLabel(obj:IsA("Model") and obj or obj.Parent)
                end
            end
        end
    end)
end

-------------------------------------------------------------------------------
-- GACHA DEALERS
-------------------------------------------------------------------------------
local GachaDealers = {
    Vector3.new(1009, 155, 1441),  -- Sea 1
    Vector3.new(-224,  82,-3205),  -- Sea 2
    Vector3.new(-4960, 32,-9280),  -- Sea 3
}
local function TryBuyGachaFruit()
    if GetBeli() < GACHA_MIN_BELI then
        Notify("Gacha", "Not enough Beli (" .. GetBeli() .. "/" .. GACHA_MIN_BELI .. ")", 4)
        return false
    end
    local hrp = GetHRP()
    if not hrp then return false end
    local bestPos, bestDist = nil, math.huge
    for _, pos in pairs(GachaDealers) do
        local d = (hrp.Position - pos).Magnitude
        if d < bestDist then bestPos = pos; bestDist = d end
    end
    if not bestPos then return false end
    SetStatus("🎰 Flying to Gacha Dealer...")
    TeleportTo(bestPos + Vector3.new(0, 3, 0))
    task.wait(0.8)
    local bought = false
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("ClickDetector") or obj:IsA("ProximityPrompt") then
            local p    = obj.Parent
            local pPos = p and ((p:IsA("BasePart") and p.Position)
                             or (p.HumanoidRootPart and p.HumanoidRootPart.Position))
            if pPos and (pPos - bestPos).Magnitude < 30 then
                pcall(function()
                    if obj:IsA("ClickDetector") then fireClickDetector(obj)
                    else fireproximityprompt(obj) end
                end)
                task.wait(0.3)
                pcall(function()
                    for _, gui in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
                        if gui:IsA("TextButton") then
                            local t = gui.Text:lower()
                            if t:find("random") or t:find("gacha") or t:find("spin") then
                                gui.MouseButton1Click:Fire()
                                bought = true
                            end
                        end
                    end
                end)
                if bought then break end
            end
        end
    end
    if bought then Notify("🎰 Gacha", "Bought a random fruit!", 4) end
    return bought
end

-------------------------------------------------------------------------------
-- CODES
-------------------------------------------------------------------------------
local CODES = {
    "BIGNEWS","SUB2GAMER","ThanksFor500M","THEGREATACE","CHANDLER",
    "FUDD10","ONEPIECE","BLUXXY","DEVSCOOKING","kittgaming",
    "Sub2OfficialNoobie","Sub2Daigrock","Enyu_is_Pro","Magicbus",
    "JCWK","Axiore","TantaiGaming","StrawHatMaine","BLASTEDLORD",
    "2BILLION","3BILLION","4BILLION","5BILLION",
    "INDOMINUSARMY","UPD15","UPD16","UPD17","UPD17V2",
    "Sub2UncleKizaru","DEVSCOOKINGAGAIN","FruitsAreLife",
    "NEWYEAR2025","XMAS2024","THIRDSEA","Strawhat",
    "ANNIVERSARY","RESET_STATS","TRIPLE_EXP","FREEBELI",
}
local function RedeemCode(code)
    local done = false
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return end
        for _, name in ipairs({"Code","Codes","RedeemCode","CodeRemote","Misc"}) do
            local r = remotes:FindFirstChild(name, true)
            if r then
                if r:IsA("RemoteFunction") then
                    r:InvokeServer(code); done = true
                elseif r:IsA("RemoteEvent") then
                    r:FireServer(code);   done = true
                end
                if done then break end
            end
        end
    end)
    if not done then
        pcall(function()
            for _, gui in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
                if gui:IsA("TextBox") then
                    local ph = gui.PlaceholderText:lower()
                    if ph:find("code") or gui.Name:lower():find("code") then
                        gui.Text = code
                        for _, btn in pairs(gui.Parent:GetDescendants()) do
                            if btn:IsA("TextButton") then
                                local t = btn.Text:lower()
                                if t:find("submit") or t:find("redeem") or t:find("enter") then
                                    btn.MouseButton1Click:Fire()
                                    done = true
                                    break
                                end
                            end
                        end
                    end
                end
                if done then break end
            end
        end)
    end
    return done
end
local function RedeemAllCodes()
    Notify("📜 Codes", "Redeeming " .. #CODES .. " codes...", 3)
    local ok, fail = 0, 0
    for _, code in ipairs(CODES) do
        local success = RedeemCode(code)
        if success then ok = ok + 1 else fail = fail + 1 end
        task.wait(1.2)
    end
    Notify("📜 Done", "Redeemed: " .. ok .. "  Failed: " .. fail, 6)
end

-------------------------------------------------------------------------------
-- ITEM SHOP
-------------------------------------------------------------------------------
local ShopItems = {
    { name="Cutlass",         cost=1000,    npcName="Sword Dealer",   npcPos=Vector3.new(964, 155,1436)   },
    { name="Katana",          cost=10000,   npcName="Sword Dealer",   npcPos=Vector3.new(-2410,25,-570)   },
    { name="Pirate Sword",    cost=2500,    npcName="Sword Dealer",   npcPos=Vector3.new(-1140,22, 465)   },
    { name="Long Sword",      cost=5000,    npcName="Sword Dealer",   npcPos=Vector3.new(-1760,25,-430)   },
    { name="Iron Mace",       cost=7000,    npcName="Weapon Dealer",  npcPos=Vector3.new(916, 132, 545)   },
    { name="Battle Axe",      cost=8500,    npcName="Weapon Dealer",  npcPos=Vector3.new(-3085,68,-1010)  },
    { name="Dual Katana",     cost=2000000, npcName="Sword Dealer 2", npcPos=Vector3.new(-230, 82,-3048)  },
    { name="Pole (1st form)", cost=3000000, npcName="Sword Dealer 2", npcPos=Vector3.new(4430, 35,-3535)  },
    { name="Rengoku",         cost=3000000, npcName="Blacksmith",     npcPos=Vector3.new(-3215,57,-3105)  },
    { name="Gravity Cane",    cost=5000000, npcName="Sword Dealer 3", npcPos=Vector3.new(-4945,32,-9300)  },
    { name="White Coat",      cost=50000,   npcName="Clothing Shop",  npcPos=Vector3.new(960, 155,1430)   },
    { name="Cape",            cost=20000,   npcName="Clothing Shop",  npcPos=Vector3.new(-2415,25,-572)   },
}
local ShopItemNames = (function()
    local t = {}
    for _, v in ipairs(ShopItems) do table.insert(t, v.name) end
    return t
end)()
local function BuyShopItem(itemName)
    local item = nil
    for _, v in ipairs(ShopItems) do
        if v.name == itemName then item = v; break end
    end
    if not item then Notify("Shop", "Item not found", 3); return end
    if GetBeli() < item.cost then
        Notify("Shop", "Need " .. item.cost .. " Beli, have " .. GetBeli(), 4); return
    end
    Notify("Shop", "Flying to " .. item.npcName, 2)
    TeleportTo(item.npcPos + Vector3.new(0, 3, 0))
    task.wait(0.6)
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:lower():find(item.npcName:lower(), 1, true) then
            local cd = obj:FindFirstChildOfClass("ClickDetector", true)
            local pp = obj:FindFirstChildOfClass("ProximityPrompt", true)
            pcall(function()
                if cd then fireClickDetector(cd)
                elseif pp then fireproximityprompt(pp) end
            end)
            task.wait(0.4)
            pcall(function()
                for _, gui in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
                    if gui:IsA("TextButton") and gui.Text:lower():find(itemName:lower(), 1, true) then
                        gui.MouseButton1Click:Fire()
                    end
                end
            end)
            break
        end
    end
    Notify("Shop", "Purchase attempted: " .. itemName, 3)
end

-------------------------------------------------------------------------------
-- PLAYER ESP
-------------------------------------------------------------------------------
local function AddPlayerESP(plr)
    if plr == LocalPlayer then return end
    local function apply(char)
        task.wait(1)
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if not hrp or char:FindFirstChild("_BH_PESP") then return end
        local bb       = Instance.new("BillboardGui", hrp)
        bb.Name        = "_BH_PESP"
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
    local c = plr.CharacterAdded:Connect(apply)
    table.insert(State.PlayerESPConns, c)
    if plr.Character then apply(plr.Character) end
end
local function TogglePlayerESP(enabled)
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character then
            local e = p.Character:FindFirstChild("_BH_PESP")
            if e then e:Destroy() end
        end
    end
    for _, c in pairs(State.PlayerESPConns) do c:Disconnect() end
    State.PlayerESPConns = {}
    if not enabled then return end
    for _, p in pairs(Players:GetPlayers()) do AddPlayerESP(p) end
    table.insert(State.PlayerESPConns, Players.PlayerAdded:Connect(AddPlayerESP))
end

-------------------------------------------------------------------------------
-- ANTI-AFK
-------------------------------------------------------------------------------
local function ToggleAntiAFK(enabled)
    if State.AntiAFKConn then State.AntiAFKConn:Disconnect(); State.AntiAFKConn = nil end
    if not enabled then return end
    State.AntiAFKConn = RunService.Heartbeat:Connect(function()
        local hrp = GetHRP()
        if hrp then hrp.CFrame = hrp.CFrame end
    end)
end

-------------------------------------------------------------------------------
-- AUTO STATS
-------------------------------------------------------------------------------
local function ToggleAutoStats(enabled)
    if not enabled then return end
    task.spawn(function()
        local map = { Melee="str", Defense="def", Sword="sword", Gun="gun", Fruit="df" }
        while State.AutoStats do
            pcall(function()
                local key    = map[State.SelectedStat] or "str"
                local remote = ReplicatedStorage:FindFirstChild("AddStat", true)
                if remote then remote:FireServer(key) end
            end)
            task.wait(0.15)
        end
    end)
end

-------------------------------------------------------------------------------
-- MAIN QUEST FARM LOOP
-------------------------------------------------------------------------------
local function StartQuestFarm()
    task.spawn(function()
        while State.AutoQuestFarm do
            WaitForChar()

            local lvl   = GetLevel()
            local quest = GetQuestForLevel(lvl)

            if not quest then
                SetStatus("⚠️ No quest for level " .. lvl)
                task.wait(3)
            else
                SetStatus("📜 Lvl " .. lvl .. " → " .. quest.area)
                Notify("Auto Farm", "Lvl " .. lvl .. " → " .. quest.area, 3)

                -- Step 1: Accept the quest
                TryAcceptQuest(quest)

                -- Step 2: Move to farm area
                SetStatus("⚔️ Farming: " .. quest.mobName)
                TeleportTo(quest.farmPos + Vector3.new(0, 5, 0))
                task.wait(0.5)

                local startLvl   = GetLevel()
                local cycleStart = os.clock()

                -- Step 3: Kill mobs until level-up or 4-min timeout
                while State.AutoQuestFarm
                  and GetLevel() == startLvl
                  and (os.clock() - cycleStart) < 240 do
                    WaitForChar()

                    -- Auto-collect fruits if enabled
                    if State.AutoCollect then
                        CollectNearbyFruits()
                    end

                    -- Find and kill nearest mob
                    local mob = FindNearestMob(quest.mobName) or FindNearestMob(nil)
                    if mob then
                        SetStatus("⚔️ Killing: " .. mob.Name)
                        KillMob(mob)
                    else
                        -- No mobs visible — return to farm area and wait
                        SetStatus("🔍 Searching: " .. quest.mobName)
                        TeleportTo(quest.farmPos + Vector3.new(0, 5, 0))
                        task.wait(2)
                    end
                    task.wait(0.05)
                end

                -- Level-up notification
                if GetLevel() > startLvl then
                    local newLvl = GetLevel()
                    Notify("⬆️ Level Up!", "Now level " .. newLvl, 4)
                    SetStatus("⬆️ Level up! Now " .. newLvl)
                end

                task.wait(0.5)
            end
        end
        SetStatus("Farm stopped.")
    end)
end

-------------------------------------------------------------------------------
-- GACHA AUTO-BUY LOOP  (timer persists across toggles)
-------------------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(30)
        if State.AutoGacha then
            local rem = GACHA_INTERVAL - (os.time() - State.GachaLastBuy)
            if rem <= 0 then
                SetStatus("🎰 Buying Gacha Fruit...")
                if TryBuyGachaFruit() then
                    State.GachaLastBuy = os.time()
                end
            else
                SetStatus("🎰 Next Gacha in " .. math.ceil(rem / 60) .. " min")
            end
        end
    end
end)

-------------------------------------------------------------------------------
-- TELEPORT DATA
-------------------------------------------------------------------------------
local Teleports = {
    ["🌊 Sea 1"] = {
        ["Starter Island"]  = Vector3.new(975, 155, 1430),
        ["Marine Fortress"] = Vector3.new(-2400, 25, -575),
        ["Jungle"]          = Vector3.new(-1755, 25, -438),
        ["Pirate Village"]  = Vector3.new(-1145, 22,  470),
        ["Desert"]          = Vector3.new(920,  132,  549),
        ["Frozen Village"]  = Vector3.new(1179, 126,  817),
        ["Skylands"]        = Vector3.new(-975, 480, -994),
        ["Colosseum"]       = Vector3.new(-1217, 25, -589),
        ["Magma Village"]   = Vector3.new(-3085, 68, -1013),
        ["Upper Skylands"]  = Vector3.new(-4911,878, -1178),
        ["Ice Castle"]      = Vector3.new(1137, 126,  810),
        ["Flower Hill"]     = Vector3.new(-1822, 27, -1032),
    },
    ["🌊 Sea 2"] = {
        ["Kingdom of Rose"] = Vector3.new(-225,  82, -3050),
        ["Green Zone"]      = Vector3.new(4433,  35, -3540),
        ["Graveyard"]       = Vector3.new(5220,  27, -4670),
        ["Snow Mountain"]   = Vector3.new(804,  328, -5188),
        ["Hot & Cold"]      = Vector3.new(-1162, 26, -4994),
        ["Cursed Ship"]     = Vector3.new(-3203, 57, -3110),
        ["Ice Cream Island"]= Vector3.new(-5970, 28, -4440),
        ["Forgotten Island"]= Vector3.new(-2860, 10, -2960),
    },
    ["🌊 Sea 3"] = {
        ["Port Town"]       = Vector3.new(-4939, 32,  -9305),
        ["Hydra Island"]    = Vector3.new(5478,  30, -10210),
        ["Great Tree"]      = Vector3.new(-1194, 30, -11582),
        ["Floating Turtle"] = Vector3.new(-9234,263, -10580),
        ["Haunted Castle"]  = Vector3.new(-4900, 35,  -8999),
        ["Sea of Treats"]   = Vector3.new(4710,  30, -10435),
    },
}

-------------------------------------------------------------------------------
-- RAYFIELD WINDOW
-------------------------------------------------------------------------------
local Window = Rayfield:CreateWindow({
    Name             = "BasicHub | Blox Fruits",
    LoadingTitle     = "BasicHub",
    LoadingSubtitle  = "Loading...",
    ConfigurationSaving = { Enabled=true, FolderName="BasicHub", FileName="BloxFruits" },
    Discord          = { Enabled=false },
    KeySystem        = false,
})

-- ═══ TAB: AUTO FARM ═══
local FarmTab = Window:CreateTab("⚔️ Auto Farm", 4483362458)
FarmTab:CreateSection("Quest Farming")

local farmStatusParagraph = FarmTab:CreateParagraph({ Title="Status", Content="Idle" })
State.StatusLabel = farmStatusParagraph

FarmTab:CreateToggle({
    Name="Auto Quest Farm (Level-Based)",
    CurrentValue=false, Flag="AutoQuestFarm",
    Callback=function(v)
        State.AutoQuestFarm = v
        if v then
            Notify("⚔️ Farm", "Starting at level " .. GetLevel(), 3)
            StartQuestFarm()
        else
            Notify("⚔️ Farm", "Farm stopped.", 2)
        end
    end,
})

FarmTab:CreateSection("How It Works")
FarmTab:CreateParagraph({
    Title   = "Kill Aura",
    Content = "1. Flies to quest NPC → accepts quest\n"
           .. "2. Teleports to mob farm area\n"
           .. "3. Teleports " .. HOVER_HEIGHT .. " studs above each mob\n"
           .. "4. Attacks with equipped tool (sword / devil fruit)\n"
           .. "5. On level-up, finds the next quest automatically\n"
           .. "Equip a sword or devil fruit before starting!",
})

-- ═══ TAB: FRUITS ═══
local FruitTab = Window:CreateTab("🍎 Fruits", 4483362458)
FruitTab:CreateSection("Fruit ESP & Auto-Collect")

FruitTab:CreateToggle({
    Name="Fruit ESP (Floor Only)", CurrentValue=false, Flag="FruitESP",
    Callback=function(v)
        State.FruitESP = v
        ToggleFruitESP(v)
        Notify(v and "🍎 Fruit ESP ON" or "🍎 Fruit ESP OFF", "", 2)
    end,
})
FruitTab:CreateToggle({
    Name="Auto-Collect Fruits (during farm)", CurrentValue=false, Flag="AutoCollect",
    Callback=function(v)
        State.AutoCollect = v
        Notify(v and "🍎 Auto-Collect ON" or "🍎 Auto-Collect OFF", "", 2)
    end,
})

FruitTab:CreateSection("Fruit Gacha (2-hour timer)")
FruitTab:CreateToggle({
    Name="Auto-Buy Fruit Gacha", CurrentValue=false, Flag="AutoGacha",
    Callback=function(v)
        State.AutoGacha = v
        if v then
            local rem = GACHA_INTERVAL - (os.time() - State.GachaLastBuy)
            Notify("🎰 Gacha",
                rem > 0 and ("Next in " .. math.ceil(rem/60) .. " min") or "Will buy on next tick!", 4)
        end
    end,
})
FruitTab:CreateParagraph({
    Title   = "Gacha Info",
    Content = "Buys 1 random fruit from the nearest Gacha Dealer every 2 hours.\n"
           .. "Timer continues even when toggle is OFF.\n"
           .. "Minimum Beli needed: " .. GACHA_MIN_BELI,
})

-- ═══ TAB: PLAYER ═══
local PlayerTab = Window:CreateTab("🏃 Player", 4483362458)
PlayerTab:CreateSection("Actions")
PlayerTab:CreateButton({
    Name="Reset Character",
    Callback=function()
        local hum = GetHum()
        if hum then hum.Health = 0 end
        Notify("🔄", "Character reset.", 2)
    end,
})
PlayerTab:CreateButton({
    Name="Rejoin Server",
    Callback=function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end,
})

-- ═══ TAB: ESP ═══
local ESPTab = Window:CreateTab("👁️ ESP", 4483362458)
ESPTab:CreateSection("Players")
ESPTab:CreateToggle({
    Name="Player ESP", CurrentValue=false, Flag="PlayerESP",
    Callback=function(v)
        State.PlayerESP = v
        TogglePlayerESP(v)
        Notify(v and "👁️ Player ESP ON" or "👁️ Player ESP OFF", "", 2)
    end,
})

-- ═══ TAB: TELEPORT ═══
local TpTab = Window:CreateTab("🌍 Teleport", 4483362458)
TpTab:CreateParagraph({
    Title   = "Instant Teleport",
    Content = "Teleports directly to the selected island.\nUses smooth stepped movement to reduce rubber-banding.",
})
for seaName, islands in pairs(Teleports) do
    TpTab:CreateSection(seaName)
    for islandName, pos in pairs(islands) do
        TpTab:CreateButton({
            Name=islandName,
            Callback=function()
                Notify("🌍", "Teleporting to " .. islandName .. "...", 2)
                task.spawn(function()
                    SmoothTeleportTo(pos + Vector3.new(0, 5, 0))
                    Notify("✅ Arrived", islandName, 2)
                end)
            end,
        })
    end
end

-- ═══ TAB: SHOP ═══
local ShopTab = Window:CreateTab("🛒 Shop", 4483362458)
ShopTab:CreateSection("Buy Items & Weapons")
local selectedShopItem = ShopItemNames[1]
ShopTab:CreateDropdown({
    Name="Select Item", Options=ShopItemNames,
    CurrentOption={ShopItemNames[1]}, MultipleOptions=false, Flag="ShopItem",
    Callback=function(opt)
        selectedShopItem = type(opt) == "table" and opt[1] or opt
        for _, v in ipairs(ShopItems) do
            if v.name == selectedShopItem then
                Notify("🛒 " .. v.name, "Cost: " .. v.cost .. " Beli | NPC: " .. v.npcName, 4)
                break
            end
        end
    end,
})
ShopTab:CreateButton({
    Name="Buy Selected Item",
    Callback=function()
        if selectedShopItem then
            task.spawn(function() BuyShopItem(selectedShopItem) end)
        end
    end,
})
ShopTab:CreateParagraph({
    Title   = "How it works",
    Content = "Select an item → click Buy.\nScript teleports to the NPC and attempts the purchase.\nMake sure you have enough Beli.",
})

-- ═══ TAB: CODES ═══
local CodesTab = Window:CreateTab("📜 Codes", 4483362458)
CodesTab:CreateSection("Auto-Redeem")
CodesTab:CreateButton({
    Name="Redeem ALL Working Codes (" .. #CODES .. " codes)",
    Callback=function() task.spawn(RedeemAllCodes) end,
})
CodesTab:CreateSection("Manual Code")
local manualCode = ""
CodesTab:CreateInput({
    Name="Enter Code", PlaceholderText="Type code here...",
    RemoveTextAfterFocusLost=false, Flag="ManualCode",
    Callback=function(txt) manualCode = txt end,
})
CodesTab:CreateButton({
    Name="Redeem Manual Code",
    Callback=function()
        if manualCode ~= "" then
            local ok = RedeemCode(manualCode)
            Notify("📜 Code", ok and ("Redeemed: " .. manualCode) or ("Failed: " .. manualCode), 3)
        end
    end,
})

-- ═══ TAB: STATS ═══
local StatsTab = Window:CreateTab("📊 Stats", 4483362458)
StatsTab:CreateSection("Auto Stats")
StatsTab:CreateDropdown({
    Name="Select Stat", Options={"Melee","Defense","Sword","Gun","Fruit"},
    CurrentOption={"Melee"}, MultipleOptions=false, Flag="StatChoice",
    Callback=function(opt)
        State.SelectedStat = type(opt) == "table" and opt[1] or opt
    end,
})
StatsTab:CreateToggle({
    Name="Auto Add Stats", CurrentValue=false, Flag="AutoStats",
    Callback=function(v)
        State.AutoStats = v
        if v then ToggleAutoStats(true) end
        Notify(v and "📊 Auto Stats ON" or "📊 Auto Stats OFF",
               v and "Adding to: " .. State.SelectedStat or "Stopped.", 2)
    end,
})

-- ═══ TAB: MISC ═══
local MiscTab = Window:CreateTab("⚙️ Misc", 4483362458)
MiscTab:CreateSection("Utilities")
MiscTab:CreateToggle({
    Name="Anti-AFK", CurrentValue=false, Flag="AntiAFK",
    Callback=function(v)
        State.AntiAFK = v
        ToggleAntiAFK(v)
        Notify(v and "✅ Anti-AFK ON" or "❌ Anti-AFK OFF", "", 2)
    end,
})
MiscTab:CreateButton({
    Name="Copy Server ID",
    Callback=function()
        local sc = setclipboard or toclipboard or function() end
        sc(game.JobId)
        Notify("📋 Copied", "Server ID copied to clipboard.", 2)
    end,
})
MiscTab:CreateSection("About")
MiscTab:CreateParagraph({
    Title   = "BasicHub | Blox Fruits",
    Content = "UI Library : Rayfield\n"
           .. "Key System : Platoboost\n"
           .. "Executor   : " .. ExecutorName,
})

-------------------------------------------------------------------------------
-- READY
-------------------------------------------------------------------------------
Notify("✅ BasicHub Loaded!", "Welcome " .. LocalPlayer.Name .. "! Level: " .. GetLevel(), 5)