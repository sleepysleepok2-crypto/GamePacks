local ProtectionConfig = { SecretKey = "Code1234", HubName = "BasicHub" }
if not _G[ProtectionConfig.SecretKey] then
    local p = game:GetService("Players").LocalPlayer
    if p then p:Kick("\n Unauthorized Execution \n\nUse the official BasicHub key system.") end
    return
end

-------------------------------------------------------------------------------
-- SERVICES
-------------------------------------------------------------------------------
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local TeleportService  = game:GetService("TeleportService")
local Debris           = game:GetService("Debris")
local LocalPlayer      = Players.LocalPlayer

-------------------------------------------------------------------------------
-- EXECUTOR NAME
-------------------------------------------------------------------------------
local ExecutorName = "Unknown"
pcall(function()
    if syn                                       then ExecutorName = "Synapse X"
    elseif KRNL_LOADED                           then ExecutorName = "KRNL"
    elseif typeof(fluxus) == "table"             then ExecutorName = "Fluxus"
    elseif typeof(getexecutorname) == "function" then ExecutorName = getexecutorname()
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
local TWEEN_SPEED     = 135   -- studs/sec for farm movement (above average)
local TP_SPEED        = 160   -- studs/sec for island teleports
local HOVER_HEIGHT    = 12    -- studs above mob
local GACHA_INTERVAL  = 7200  -- 2 hours in seconds
local GACHA_MIN_BELI  = 50000 -- minimum beli to attempt gacha

-------------------------------------------------------------------------------
-- STATE
-------------------------------------------------------------------------------
local State = {
    AutoQuestFarm  = false,
    AutoGacha      = false,
    FruitESP       = false,
    AutoCollect    = false,
    PlayerESP      = false,
    InfiniteJump   = false,
    SpeedHack      = false,
    SpeedValue     = 28,
    AntiAFK        = false,
    AutoStats      = false,
    SelectedStat   = "Melee",

    -- internal connections
    FarmThread      = nil,
    FruitESPConn    = nil,
    AntiAFKConn     = nil,
    SpeedConn       = nil,
    JumpConn        = nil,
    PlayerESPConns  = {},

    -- gacha persistent timer (never reset on toggle)
    GachaLastBuy   = 0,

    -- status label reference (updated by farm loop)
    StatusLabel    = nil,
}

-------------------------------------------------------------------------------
-- UTILITY
-------------------------------------------------------------------------------
local function GetChar()     return LocalPlayer.Character end
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
    Rayfield:Notify({ Title=title, Content=msg, Duration=dur or 3, Image=4483362458 })
end
local function SetStatus(txt)
    if State.StatusLabel and State.StatusLabel.Parent then
        State.StatusLabel:Set(txt)
    end
end

-------------------------------------------------------------------------------
-- SAFE TWEEN MOVEMENT (anti-cheat friendly)
-- Moves HRP via TweenService so position delta looks natural to server checks
-------------------------------------------------------------------------------
local function SafeTweenTo(targetPos, speed)
    local hrp = GetHRP()
    if not hrp then return end
    speed = speed or TWEEN_SPEED
    local dist = (hrp.Position - targetPos).Magnitude
    if dist < 3 then return end
    local dur  = math.clamp(dist / speed, 0.05, 12)
    local tw   = TweenService:Create(hrp,
        TweenInfo.new(dur, Enum.EasingStyle.Linear),
        { CFrame = CFrame.new(targetPos) }
    )
    tw:Play()
    tw.Completed:Wait()
end

-- Teleport tab uses slightly faster tween for islands
local function IslandTweenTo(pos)
    SafeTweenTo(pos, TP_SPEED)
end

-------------------------------------------------------------------------------
-- HOVER (keep player airborne above a point, no gravity)
-------------------------------------------------------------------------------
local function HoverAt(pos)
    local hrp = GetHRP()
    if not hrp then return end
    local old = hrp:FindFirstChild("_BH_BP")
    if old then old:Destroy() end
    local bp       = Instance.new("BodyPosition")
    bp.Name        = "_BH_BP"
    bp.Position    = pos
    bp.MaxForce    = Vector3.new(1e9, 1e9, 1e9)
    bp.D           = 500
    bp.P           = 60000
    bp.Parent      = hrp
end
local function StopHover()
    local hrp = GetHRP()
    if hrp then
        local bp = hrp:FindFirstChild("_BH_BP")
        if bp then bp:Destroy() end
    end
end

-------------------------------------------------------------------------------
-- PLAYER CHARACTER REGISTRY  (never target real players as mobs)
-------------------------------------------------------------------------------
local playerChars = {}
local function registerChar(p)
    if p == LocalPlayer then return end
    p.CharacterAdded:Connect(function(c) playerChars[c] = true end)
    p.CharacterRemoving:Connect(function(c) playerChars[c] = nil end)
    if p.Character then playerChars[p.Character] = true end
end
Players.PlayerAdded:Connect(registerChar)
Players.PlayerRemoving:Connect(function(p) if p.Character then playerChars[p.Character] = nil end end)
for _, p in pairs(Players:GetPlayers()) do registerChar(p) end

local function IsPlayer(model)
    return playerChars[model] == true
end

-------------------------------------------------------------------------------
-- FIND NEAREST MOB  (optional name filter, excludes real players & own char)
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
                        best      = obj
                        bestDist  = d
                    end
                end
            end
        end
    end
    return best
end

-------------------------------------------------------------------------------
-- ATTACK  (equip tool → activate every frame while hovering)
-------------------------------------------------------------------------------
local function AttackWithTool()
    local char = GetChar()
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then
        tool = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
        if tool then tool.Parent = char end
    end
    if tool then pcall(function() tool:Activate() end) end
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
-- QUEST DATA  (level ranges → quest NPC positions → mob area)
-- Positions are approximate and may shift slightly with game updates.
-------------------------------------------------------------------------------
local QuestData = {
    -- ══ SEA 1 ══
    { level={1,14},    area="Starter Island",  mobName="Bandit",              questPos=Vector3.new(956,144,1425),    farmPos=Vector3.new(945,126,1395)    },
    { level={15,29},   area="Marine Fortress", mobName="Marine",              questPos=Vector3.new(-2422,17,-578),   farmPos=Vector3.new(-2450,18,-600)    },
    { level={30,44},   area="Pirate Village",  mobName="Pirate",              questPos=Vector3.new(-1144,16,472),    farmPos=Vector3.new(-1180,16,500)     },
    { level={45,59},   area="Jungle",          mobName="Gorilla",             questPos=Vector3.new(-1755,19,-438),   farmPos=Vector3.new(-1800,20,-460)    },
    { level={60,74},   area="Desert",          mobName="Desert Bandit",       questPos=Vector3.new(920,126,549),     farmPos=Vector3.new(895,126,525)      },
    { level={75,89},   area="Frozen Village",  mobName="Snow Bandit",         questPos=Vector3.new(1179,120,817),    farmPos=Vector3.new(1150,120,800)     },
    { level={90,109},  area="Skylands",        mobName="Sky Bandit",          questPos=Vector3.new(-975,474,-994),   farmPos=Vector3.new(-1000,474,-1020)  },
    { level={110,134}, area="Colosseum",       mobName="Prisoner",            questPos=Vector3.new(-1217,17,-589),   farmPos=Vector3.new(-1250,17,-600)    },
    { level={135,174}, area="Magma Village",   mobName="Magma Ninja",         questPos=Vector3.new(-3085,59,-1013),  farmPos=Vector3.new(-3110,60,-1030)   },
    { level={175,209}, area="Upper Skylands",  mobName="Wyvern",              questPos=Vector3.new(-4911,872,-1178), farmPos=Vector3.new(-4940,873,-1200)  },
    { level={210,249}, area="Upper Skylands",  mobName="Demonic Soul",        questPos=Vector3.new(-4850,872,-1150), farmPos=Vector3.new(-4870,872,-1180)  },
    { level={250,299}, area="Ice Castle",      mobName="Snow Demon",          questPos=Vector3.new(1137,120,810),    farmPos=Vector3.new(1100,120,790)     },
    { level={300,374}, area="Flower Hill",     mobName="Chief Pirate",        questPos=Vector3.new(-1822,19,-1032),  farmPos=Vector3.new(-1850,19,-1060)   },
    { level={375,449}, area="Middle Town",     mobName="Citizen",             questPos=Vector3.new(-562,6,1618),     farmPos=Vector3.new(-580,6,1640)      },
    { level={450,549}, area="Underwater City", mobName="Fishman",             questPos=Vector3.new(61437,12,1524),   farmPos=Vector3.new(61420,12,1500)    },
    { level={550,624}, area="Fountain City",   mobName="Fountain City Guard", questPos=Vector3.new(3803,23,3870),    farmPos=Vector3.new(3820,23,3890)     },
    { level={625,699}, area="Skylands II",     mobName="Dragon Crew",         questPos=Vector3.new(-4826,507,-1136), farmPos=Vector3.new(-4840,508,-1150)  },
    -- ══ SEA 2 ══
    { level={700,774},   area="Kingdom of Rose",  mobName="Mercenary",          questPos=Vector3.new(-225,73,-3050),   farmPos=Vector3.new(-255,73,-3085)   },
    { level={775,849},   area="Green Zone",       mobName="Factory Worker",     questPos=Vector3.new(4433,26,-3540),   farmPos=Vector3.new(4450,26,-3560)   },
    { level={850,924},   area="Graveyard",        mobName="Zombie",             questPos=Vector3.new(5220,18,-4670),   farmPos=Vector3.new(5240,18,-4695)   },
    { level={925,999},   area="Snow Mountain",    mobName="Snow Demon",         questPos=Vector3.new(804,319,-5188),   farmPos=Vector3.new(780,320,-5210)   },
    { level={1000,1074}, area="Hot & Cold",       mobName="Snowstorm Warrior",  questPos=Vector3.new(-1162,18,-4994),  farmPos=Vector3.new(-1180,18,-5015)  },
    { level={1075,1149}, area="Cursed Ship",      mobName="Cursed Pirate",      questPos=Vector3.new(-3203,48,-3110),  farmPos=Vector3.new(-3220,48,-3135)  },
    { level={1150,1249}, area="Ice Cream Island", mobName="Chocolate Bar",      questPos=Vector3.new(-5970,19,-4440),  farmPos=Vector3.new(-5990,19,-4460)  },
    { level={1250,1349}, area="Forgotten Island", mobName="Tide Keeper",        questPos=Vector3.new(-2860,1,-2960),   farmPos=Vector3.new(-2880,1,-2985)   },
    { level={1350,1499}, area="Library",          mobName="Sea Soldier",        questPos=Vector3.new(-3227,825,-4394), farmPos=Vector3.new(-3245,826,-4415) },
    -- ══ SEA 3 ══
    { level={1500,1574}, area="Port Town",         mobName="Hunter",            questPos=Vector3.new(-4939,22,-9305),  farmPos=Vector3.new(-4960,22,-9330)  },
    { level={1575,1649}, area="Hydra Island",      mobName="Marine Lieutenant", questPos=Vector3.new(5478,21,-10210),  farmPos=Vector3.new(5500,21,-10235)  },
    { level={1650,1724}, area="Great Tree",        mobName="Living Zombie",     questPos=Vector3.new(-1194,20,-11582), farmPos=Vector3.new(-1215,20,-11605) },
    { level={1725,1799}, area="Floating Turtle",   mobName="Toad",              questPos=Vector3.new(-9234,253,-10580),farmPos=Vector3.new(-9255,254,-10605)},
    { level={1800,1874}, area="Haunted Castle",    mobName="Possessed Mummy",   questPos=Vector3.new(-4900,25,-8999),  farmPos=Vector3.new(-4920,25,-9025)  },
    { level={1875,1999}, area="Sea of Treats",     mobName="Sweet Thief",       questPos=Vector3.new(4710,21,-10435),  farmPos=Vector3.new(4730,21,-10460)  },
    { level={2000,2149}, area="Great Tree (High)", mobName="Tree Spirit",       questPos=Vector3.new(-1200,220,-11590),farmPos=Vector3.new(-1220,221,-11615)},
    { level={2150,2299}, area="Demonic Dimension", mobName="Demonic Soul",      questPos=Vector3.new(-1580,208,-11500),farmPos=Vector3.new(-1600,210,-11525)},
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
-- QUEST ACCEPT  (proximity + try click/proximity-prompt)
-------------------------------------------------------------------------------
local function TryAcceptQuest(questPos)
    SafeTweenTo(questPos + Vector3.new(0,3,0), TWEEN_SPEED)
    task.wait(0.4)
    -- Try to click nearby ClickDetectors / fire ProximityPrompts
    for _, obj in pairs(workspace:GetDescendants()) do
        if (obj:IsA("ClickDetector") or obj:IsA("ProximityPrompt")) then
            local part = obj.Parent
            local partPos = part and (part:IsA("BasePart") and part.Position
                         or (part:FindFirstChild("HumanoidRootPart") and part.HumanoidRootPart.Position))
            if partPos and (partPos - questPos).Magnitude < 20 then
                pcall(function()
                    if obj:IsA("ClickDetector") then
                        fireClickDetector(obj)
                    else
                        fireproximityprompt(obj)
                    end
                end)
                task.wait(0.2)
            end
        end
    end
    task.wait(0.6)
    -- Try to auto-click any Accept/Quest dialog that appeared
    pcall(function()
        for _, gui in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
            if gui:IsA("TextButton") then
                local t = gui.Text:lower()
                if t:find("accept") or t:find("quest") or t:find("start") then
                    gui.MouseButton1Click:Fire()
                end
            end
        end
    end)
end

-------------------------------------------------------------------------------
-- COLLECT NEARBY FRUITS  (called opportunistically during farm loop)
-------------------------------------------------------------------------------
local function CollectNearbyFruits()
    local hrp = GetHRP()
    if not hrp then return end
    for _, obj in pairs(workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("BasePart")) and not IsPlayer(obj:IsA("Model") and obj or obj.Parent) then
            local n = obj.Name:lower()
            if n:find("fruit") or n:find("_fruit") then
                local pos
                if obj:IsA("Model") then
                    local p = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                    pos = p and p.Position
                else
                    pos = obj.Position
                end
                if pos and (hrp.Position - pos).Magnitude < 2000 then
                    -- Tween to fruit
                    SetStatus("🍎 Collecting fruit: " .. obj.Name)
                    SafeTweenTo(pos + Vector3.new(0,3,0), TWEEN_SPEED)
                    task.wait(0.5)
                    -- Try proximity / click
                    pcall(function()
                        for _, child in pairs((obj:IsA("Model") and obj or obj.Parent):GetDescendants()) do
                            if child:IsA("ClickDetector")    then fireClickDetector(child) break end
                            if child:IsA("ProximityPrompt") then fireproximityprompt(child) break end
                        end
                    end)
                    task.wait(0.3)
                end
            end
        end
    end
end

-------------------------------------------------------------------------------
-- FRUIT ESP LABELS
-------------------------------------------------------------------------------
local function AddFruitESPLabel(obj, pos)
    -- Avoid double-labelling
    if obj:FindFirstChild("_BH_FruitESP") then return end
    local bb        = Instance.new("BillboardGui")
    bb.Name         = "_BH_FruitESP"
    bb.AlwaysOnTop  = true
    bb.Size         = UDim2.new(0, 140, 0, 44)
    bb.StudsOffset  = Vector3.new(0, 4, 0)
    bb.Parent       = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart") or obj) or obj
    local lb        = Instance.new("TextLabel", bb)
    lb.Size         = UDim2.fromScale(1, 1)
    lb.BackgroundTransparency = 1
    lb.Text         = "🍎 " .. obj.Name
    lb.TextColor3   = Color3.fromRGB(255, 210, 0)
    lb.TextScaled   = true
    lb.Font         = Enum.Font.GothamBold
end

local function RemoveAllFruitESP()
    for _, obj in pairs(workspace:GetDescendants()) do
        local tag = obj:FindFirstChild("_BH_FruitESP")
        if tag then tag:Destroy() end
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
                if n:find("fruit") or n:find("_fruit") then
                    local target = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or obj
                    if target and target:IsA("BasePart") and not target:FindFirstChild("_BH_FruitESP") then
                        AddFruitESPLabel(obj, target.Position)
                    end
                end
            end
        end
    end)
end

-------------------------------------------------------------------------------
-- GACHA DEALERS
-------------------------------------------------------------------------------
local GachaDealers = {
    [1] = Vector3.new(1009, 144, 1441),   -- Sea 1 dealer
    [2] = Vector3.new(-224, 73, -3205),   -- Sea 2 dealer
    [3] = Vector3.new(-4960, 22, -9280),  -- Sea 3 dealer
}

local function TryBuyGachaFruit()
    if GetBeli() < GACHA_MIN_BELI then
        Notify("Gacha", "Not enough Beli (" .. GetBeli() .. " / " .. GACHA_MIN_BELI .. ")", 4)
        return false
    end
    -- Find nearest dealer
    local hrp = GetHRP()
    if not hrp then return false end
    local bestDealerPos, bestDist = nil, math.huge
    for _, pos in pairs(GachaDealers) do
        local d = (hrp.Position - pos).Magnitude
        if d < bestDist then bestDealerPos = pos; bestDist = d end
    end
    if not bestDealerPos then return false end

    SetStatus("🎰 Flying to Gacha Dealer...")
    SafeTweenTo(bestDealerPos + Vector3.new(0, 3, 0), TP_SPEED)
    task.wait(0.5)

    -- Try to interact with dealer
    local bought = false
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("ClickDetector") or obj:IsA("ProximityPrompt") then
            local p = obj.Parent
            local pPos = p and ((p:IsA("BasePart") and p.Position) or (p.HumanoidRootPart and p.HumanoidRootPart.Position))
            if pPos and (pPos - bestDealerPos).Magnitude < 25 then
                pcall(function()
                    if obj:IsA("ClickDetector") then fireClickDetector(obj)
                    else fireproximityprompt(obj) end
                end)
                task.wait(0.3)
                -- Try to click the "Random" or "Gacha" button in any dialog
                pcall(function()
                    for _, gui in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
                        if gui:IsA("TextButton") then
                            local t = gui.Text:lower()
                            if t:find("random") or t:find("gacha") or t:find("spin") or t:find("buy") then
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

    if bought then
        Notify("🎰 Gacha", "Bought a random fruit!", 4)
    end
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
    -- Method 1: ReplicatedStorage remotes
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return end
        for _, name in ipairs({"Code","Codes","RedeemCode","CodeRemote","Misc"}) do
            local r = remotes:FindFirstChild(name, true)
            if r then
                if r:IsA("RemoteFunction") then
                    r:InvokeServer(code); done = true
                elseif r:IsA("RemoteEvent") then
                    r:FireServer(code); done = true
                end
                if done then break end
            end
        end
    end)
    -- Method 2: Find code TextBox in PlayerGui
    if not done then
        pcall(function()
            for _, gui in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
                if gui:IsA("TextBox") then
                    local ph = gui.PlaceholderText:lower()
                    if ph:find("code") or gui.Name:lower():find("code") then
                        gui.Text = code
                        local frame = gui.Parent
                        for _, btn in pairs(frame:GetDescendants()) do
                            if btn:IsA("TextButton") then
                                local t = btn.Text:lower()
                                if t:find("submit") or t:find("redeem") or t:find("enter") or t:find("ok") then
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
    Notify("📜 Codes Done", "Redeemed: " .. ok .. " | Skipped/Failed: " .. fail, 6)
end

-------------------------------------------------------------------------------
-- ITEM SHOP DATA
-------------------------------------------------------------------------------
local ShopItems = {
    -- SEA 1 SWORDS
    { name="Cutlass",        cost=1000,    npcName="Sword Dealer",   npcPos=Vector3.new(964,144,1436)   },
    { name="Katana",         cost=10000,   npcName="Sword Dealer",   npcPos=Vector3.new(-2410,18,-570)  },
    { name="Pirate Sword",   cost=2500,    npcName="Sword Dealer",   npcPos=Vector3.new(-1140,16,465)   },
    { name="Long Sword",     cost=5000,    npcName="Sword Dealer",   npcPos=Vector3.new(-1760,19,-430)  },
    { name="Iron Mace",      cost=7000,    npcName="Weapon Dealer",  npcPos=Vector3.new(916,126,545)    },
    { name="Battle Axe",     cost=8500,    npcName="Weapon Dealer",  npcPos=Vector3.new(-3085,59,-1010) },
    -- SEA 2 SWORDS
    { name="Dual Katana",    cost=2000000, npcName="Sword Dealer 2", npcPos=Vector3.new(-230,73,-3048)  },
    { name="Pole (1st form)",cost=3000000, npcName="Sword Dealer 2", npcPos=Vector3.new(4430,26,-3535)  },
    { name="Rengoku",        cost=3000000, npcName="Blacksmith",     npcPos=Vector3.new(-3215,48,-3105) },
    -- SEA 3 SWORDS
    { name="Gravity Cane",   cost=5000000, npcName="Sword Dealer 3", npcPos=Vector3.new(-4945,22,-9300) },
    { name="Dark Blade",     cost=1,       npcName="Special Dealer", npcPos=Vector3.new(-4945,22,-9300) },
    -- ACCESSORIES
    { name="White Coat",     cost=50000,   npcName="Clothing Shop",  npcPos=Vector3.new(960,144,1430)   },
    { name="Cape",           cost=20000,   npcName="Clothing Shop",  npcPos=Vector3.new(-2415,18,-572)  },
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
    if not item then Notify("Shop", "Item not found: " .. itemName, 3); return end
    if GetBeli() < item.cost then
        Notify("Shop", "Not enough Beli! Need: " .. item.cost .. ", Have: " .. GetBeli(), 4)
        return
    end
    Notify("Shop", "Flying to " .. item.npcName .. "...", 2)
    SafeTweenTo(item.npcPos + Vector3.new(0,3,0), TP_SPEED)
    task.wait(0.5)
    -- Find and interact with NPC
    for _, obj in pairs(workspace:GetDescendants()) do
        local isNPC = obj:IsA("Model") and obj.Name:lower():find(item.npcName:lower(), 1, true)
        if isNPC then
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
        local bb        = Instance.new("BillboardGui", hrp)
        bb.Name         = "_BH_PESP"
        bb.AlwaysOnTop  = true
        bb.Size         = UDim2.new(0, 130, 0, 45)
        bb.StudsOffset  = Vector3.new(0, 4, 0)
        local lb        = Instance.new("TextLabel", bb)
        lb.Size         = UDim2.fromScale(1,1)
        lb.BackgroundTransparency = 1
        lb.Text         = "[" .. plr.Name .. "]"
        lb.TextColor3   = Color3.fromRGB(255, 70, 70)
        lb.TextScaled   = true
        lb.Font         = Enum.Font.GothamBold
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
-- INFINITE JUMP  (BodyVelocity impulse — less detectable than state change)
-------------------------------------------------------------------------------
local function ToggleInfiniteJump(enabled)
    if State.JumpConn then State.JumpConn:Disconnect(); State.JumpConn = nil end
    if not enabled then return end
    State.JumpConn = UserInputService.JumpRequest:Connect(function()
        local hrp = GetHRP()
        if not hrp then return end
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(0, 5e4, 0)
        bv.Velocity = Vector3.new(0, 52, 0)
        bv.Parent   = hrp
        Debris:AddItem(bv, 0.15)
    end)
end

-------------------------------------------------------------------------------
-- SPEED HACK  (capped at 50 to avoid AC kick; BodyVelocity boost while moving)
-------------------------------------------------------------------------------
local function ToggleSpeedHack(enabled)
    if State.SpeedConn then State.SpeedConn:Disconnect(); State.SpeedConn = nil end
    local hum = GetHum()
    if not enabled then if hum then hum.WalkSpeed = 16 end; return end
    State.SpeedConn = RunService.Heartbeat:Connect(function()
        local h = GetHum(); if not h then return end
        local safe = math.min(State.SpeedValue, 50)
        h.WalkSpeed = safe
    end)
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
                local key = map[State.SelectedStat] or "str"
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
                SetStatus("⚠️ No quest found for level " .. lvl)
                task.wait(3)
                continue -- Lua 5.1: use goto or restructure — see below
            end

            SetStatus("📜 Level " .. lvl .. " → " .. quest.area)
            Notify("Auto Farm", "Level " .. lvl .. " → " .. quest.area, 3)

            -- Fly to quest NPC and accept quest
            TryAcceptQuest(quest.questPos)

            -- Fly to mob farm area
            SetStatus("⚔️ Farming: " .. quest.mobName)
            local hoverFarmPos = quest.farmPos + Vector3.new(0, HOVER_HEIGHT, 0)
            SafeTweenTo(hoverFarmPos, TWEEN_SPEED)

            local startLvl   = GetLevel()
            local cycleStart = os.clock()

            -- Farm until level-up or 4 min timeout
            while State.AutoQuestFarm and GetLevel() == startLvl and (os.clock() - cycleStart) < 240 do
                WaitForChar()

                -- Auto-collect fruits if enabled (interrupt farming)
                if State.AutoCollect then
                    CollectNearbyFruits()
                end

                -- Find nearest quest mob (or any mob if none found by name)
                local mob = FindNearestMob(quest.mobName)
                        or FindNearestMob(nil)

                if mob then
                    local mhrp = mob:FindFirstChild("HumanoidRootPart")
                    if mhrp then
                        -- Hover above mob
                        local hoverPos = mhrp.Position + Vector3.new(0, HOVER_HEIGHT, 0)
                        SafeTweenTo(hoverPos, TWEEN_SPEED)
                        HoverAt(hoverPos)

                        -- Kill aura: attack rapidly while hovering
                        local atkStart = os.clock()
                        while State.AutoQuestFarm
                          and mob.Parent
                          and mob:FindFirstChildOfClass("Humanoid")
                          and mob:FindFirstChildOfClass("Humanoid").Health > 0
                          and (os.clock() - atkStart) < 15 do
                            AttackWithTool()
                            task.wait(0.08)
                        end

                        StopHover()
                    end
                else
                    -- No mobs nearby — hover at farm area and wait
                    HoverAt(hoverFarmPos)
                    task.wait(2)
                    StopHover()
                end
                task.wait(0.05)
            end

            StopHover()

            if GetLevel() > startLvl then
                local newLvl = GetLevel()
                Notify("⬆️ Level Up!", "Now level " .. newLvl, 4)
                SetStatus("⬆️ Level up! Now " .. newLvl)
            end

            task.wait(0.5)
        end

        StopHover()
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
            local now = os.time()
            local remaining = GACHA_INTERVAL - (now - State.GachaLastBuy)
            if remaining <= 0 then
                SetStatus("🎰 Buying Gacha Fruit...")
                local ok = TryBuyGachaFruit()
                if ok then
                    State.GachaLastBuy = os.time()
                end
            else
                local mins = math.ceil(remaining / 60)
                SetStatus("🎰 Next Gacha in " .. mins .. " min")
            end
        end
    end
end)

-------------------------------------------------------------------------------
-- TELEPORT DATA
-------------------------------------------------------------------------------
local Teleports = {
    ["🌊 Sea 1"] = {
        ["Starter Island"]  = Vector3.new(975,  144, 1430),
        ["Marine Fortress"] = Vector3.new(-2400, 18, -575),
        ["Jungle"]          = Vector3.new(-1755, 19, -438),
        ["Pirate Village"]  = Vector3.new(-1145, 16,  470),
        ["Desert"]          = Vector3.new(920,  126,  549),
        ["Frozen Village"]  = Vector3.new(1179, 120,  817),
        ["Skylands"]        = Vector3.new(-975, 474, -994),
        ["Colosseum"]       = Vector3.new(-1217, 17, -589),
        ["Magma Village"]   = Vector3.new(-3085, 59,-1013),
        ["Upper Skylands"]  = Vector3.new(-4911,872,-1178),
        ["Ice Castle"]      = Vector3.new(1137, 120,  810),
        ["Flower Hill"]     = Vector3.new(-1822, 19,-1032),
    },
    ["🌊 Sea 2"] = {
        ["Kingdom of Rose"] = Vector3.new(-225,  73,-3050),
        ["Green Zone"]      = Vector3.new(4433,  26,-3540),
        ["Graveyard"]       = Vector3.new(5220,  18,-4670),
        ["Snow Mountain"]   = Vector3.new(804,  319,-5188),
        ["Hot & Cold"]      = Vector3.new(-1162, 18,-4994),
        ["Cursed Ship"]     = Vector3.new(-3203, 48,-3110),
        ["Ice Cream Island"]= Vector3.new(-5970, 19,-4440),
        ["Forgotten Island"]= Vector3.new(-2860,  1,-2960),
    },
    ["🌊 Sea 3"] = {
        ["Port Town"]       = Vector3.new(-4939, 22, -9305),
        ["Hydra Island"]    = Vector3.new(5478,  21,-10210),
        ["Great Tree"]      = Vector3.new(-1194, 20,-11582),
        ["Floating Turtle"] = Vector3.new(-9234,253,-10580),
        ["Haunted Castle"]  = Vector3.new(-4900, 25, -8999),
        ["Sea of Treats"]   = Vector3.new(4710,  21,-10435),
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
            Notify("⚔️ Farm", "Starting quest farm at level " .. GetLevel(), 3)
            StartQuestFarm()
        else
            StopHover()
            Notify("⚔️ Farm", "Farm stopped.", 2)
        end
    end,
})

FarmTab:CreateSection("Kill Aura Info")
FarmTab:CreateParagraph({
    Title   = "Kill Aura — How it works",
    Content = "The script hovers " .. HOVER_HEIGHT ..
              " studs above the mob and rapidly activates your equipped tool.\n" ..
              "Equip a sword or devil fruit before starting for best results.\n" ..
              "Mobs cannot reach the player from below.",
})

-- ═══ TAB: FRUITS ═══
local FruitTab = Window:CreateTab("🍎 Fruits", 4483362458)
FruitTab:CreateSection("Fruit ESP & Auto-Collect")

FruitTab:CreateToggle({
    Name="Fruit ESP (Floor Only)", CurrentValue=false, Flag="FruitESP",
    Callback=function(v)
        State.FruitESP = v
        ToggleFruitESP(v)
        Notify(v and "🍎 Fruit ESP ON" or "🍎 Fruit ESP OFF",
               v and "Showing fruits on the floor." or "ESP removed.", 2)
    end,
})

FruitTab:CreateToggle({
    Name="Auto-Collect Fruits (during farm)", CurrentValue=false, Flag="AutoCollect",
    Callback=function(v)
        State.AutoCollect = v
        Notify(v and "🍎 Auto-Collect ON" or "🍎 Auto-Collect OFF",
               v and "Will collect fruits found on floor." or "Disabled.", 2)
    end,
})

FruitTab:CreateSection("Fruit Gacha (2-hour timer)")

FruitTab:CreateToggle({
    Name="Auto-Buy Fruit Gacha", CurrentValue=false, Flag="AutoGacha",
    Callback=function(v)
        State.AutoGacha = v
        if v then
            local rem = GACHA_INTERVAL - (os.time() - State.GachaLastBuy)
            if rem > 0 then
                Notify("🎰 Gacha", "Next purchase in " .. math.ceil(rem/60) .. " min", 4)
            else
                Notify("🎰 Gacha", "Will buy on next farm tick (≤30 sec).", 3)
            end
        end
    end,
})

FruitTab:CreateParagraph({
    Title="Gacha Info",
    Content="Buys one random fruit from the nearest Blox Fruit Dealer (Gacha) every 2 hours.\nTimer continues even when the toggle is OFF."
        .. "\nMinimum Beli required: " .. GACHA_MIN_BELI,
})

-- ═══ TAB: PLAYER ═══
local PlayerTab = Window:CreateTab("🏃 Player", 4483362458)
PlayerTab:CreateSection("Movement")

PlayerTab:CreateToggle({
    Name="Infinite Jump", CurrentValue=false, Flag="InfJump",
    Callback=function(v)
        State.InfiniteJump = v
        ToggleInfiniteJump(v)
        Notify(v and "⬆️ Infinite Jump ON" or "⬆️ Infinite Jump OFF", "", 2)
    end,
})

PlayerTab:CreateToggle({
    Name="Speed Hack", CurrentValue=false, Flag="SpeedHack",
    Callback=function(v)
        State.SpeedHack = v
        ToggleSpeedHack(v)
        Notify(v and "💨 Speed ON" or "💨 Speed OFF",
               v and "Speed: " .. State.SpeedValue or "Reset to 16.", 2)
    end,
})

PlayerTab:CreateSlider({
    Name="Walk Speed", Range={16,50}, Increment=1, Suffix=" spd",
    CurrentValue=28, Flag="WalkSpeed",
    Callback=function(v)
        State.SpeedValue = v
        local hum = GetHum()
        if State.SpeedHack and hum then hum.WalkSpeed = math.min(v, 50) end
    end,
})

PlayerTab:CreateParagraph({
    Title="Anti-Cheat Note",
    Content="Speed is capped at 50 to avoid Blox Fruits anti-cheat kick.\nInfinite Jump uses a velocity impulse (safer than state change).",
})

PlayerTab:CreateSection("Combat")
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
    Title="Smooth Tween Teleport",
    Content="Uses TweenService movement to avoid the anti-cheat 'push-back' effect.\nSpeed: " .. TP_SPEED .. " studs/sec.",
})

for seaName, islands in pairs(Teleports) do
    TpTab:CreateSection(seaName)
    for islandName, pos in pairs(islands) do
        TpTab:CreateButton({
            Name=islandName,
            Callback=function()
                Notify("🌍", "Flying to " .. islandName .. "...", 2)
                task.spawn(function()
                    IslandTweenTo(pos + Vector3.new(0, 5, 0))
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
    CurrentOption={ShopItemNames[1]}, MultipleOptions=false,
    Flag="ShopItem",
    Callback=function(opt)
        selectedShopItem = type(opt)=="table" and opt[1] or opt
        -- Show cost info
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
            task.spawn(function()
                BuyShopItem(selectedShopItem)
            end)
        end
    end,
})

ShopTab:CreateParagraph({
    Title="How it works",
    Content="Select an item from the dropdown, then click Buy.\nThe script will fly to the appropriate NPC and attempt the purchase.\nMake sure you have enough Beli.",
})

-- ═══ TAB: CODES ═══
local CodesTab = Window:CreateTab("📜 Codes", 4483362458)
CodesTab:CreateSection("Auto-Redeem")

CodesTab:CreateButton({
    Name="Redeem ALL Working Codes (" .. #CODES .. " codes)",
    Callback=function()
        task.spawn(RedeemAllCodes)
    end,
})

CodesTab:CreateSection("Manual Code")
local manualCode = ""
CodesTab:CreateInput({
    Name="Enter Code", PlaceholderText="Type code here...", RemoveTextAfterFocusLost=false,
    Flag="ManualCode",
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
        State.SelectedStat = type(opt)=="table" and opt[1] or opt
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
        Notify("📋 Copied", "Server ID copied.", 2)
    end,
})

MiscTab:CreateSection("About")
MiscTab:CreateParagraph({
    Title="BasicHub | Blox Fruits",
    Content="UI Library  : Rayfield\n" ..
            "Key System  : Platoboost\n" ..
            "Developer   : BasicHub Team\n" ..
            "Executor    : " .. ExecutorName .. "\n" ..
            "Anti-AC     : Tween movement, capped speed, BodyVelocity jump",
})

-------------------------------------------------------------------------------
-- READY
-------------------------------------------------------------------------------
Notify("✅ BasicHub Loaded!", "Welcome " .. LocalPlayer.Name .. "! Level: " .. GetLevel(), 5)
