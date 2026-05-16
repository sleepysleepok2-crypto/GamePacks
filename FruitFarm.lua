local ProtectionConfig = {
    --  CRITICAL: This MUST exactly match the 'Secret' value in your Key System's Config!
    -- If your Key System has: Secret = "Test"
    -- Then this must also be: SecretKey = "Test"
    SecretKey = "Test",
    
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
    ╔══════════════════════════════════════════╗
    ║         BasicHub | Blox Fruits           ║
    ║       UI Library  : Rayfield             ║
    ║       Key System  : Platoboost           ║
    ╚══════════════════════════════════════════╝
]]

-- ══════════════════════════════════════════
--  SERVICES
-- ══════════════════════════════════════════
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local TeleportService= game:GetService("TeleportService")
local LocalPlayer    = Players.LocalPlayer

-- ══════════════════════════════════════════
--  RAYFIELD
-- ══════════════════════════════════════════
local Rayfield = loadstring(game:HttpGet(
    "https://sirius.menu/rayfield"
))()

-- ══════════════════════════════════════════
--  KEY SYSTEM CONFIG
-- ══════════════════════════════════════════
local KEY_LINK  = "https://lootdest.org/s?bsiC2z3c"  -- Platoboost BasicHub
local KEY_FILE  = "BasicHub_Key.txt"
local VALID_KEYS = {
    -- Добавляй ключи сюда
    "BASICHUB-FREE",
    "BASICHUB-VIP",
}

-- ══════════════════════════════════════════
--  STATE
-- ══════════════════════════════════════════
local State = {
    AutoFarm        = false,
    AutoStats       = false,
    FruitESP        = false,
    PlayerESP       = false,
    AntiAFK         = false,
    SeaBeastFarm    = false,
    FarmConn        = nil,
    AntiAFKConn     = nil,
    FruitConn       = nil,
    PlayerESPConns  = {},
    SelectedStat    = "Melee",
    FarmRange       = 100,
}

-- ══════════════════════════════════════════
--  УТИЛИТЫ
-- ══════════════════════════════════════════
local function Notify(title, content, duration)
    Rayfield:Notify({
        Title    = title,
        Content  = content,
        Duration = duration or 3,
        Image    = 4483362458,
    })
end

local function isKeyValid(key)
    for _, v in pairs(VALID_KEYS) do
        if key:upper() == v:upper() then return true end
    end
    return false
end

local function getSavedKey()
    if isfile and isfile(KEY_FILE) then
        return readfile(KEY_FILE)
    end
    return nil
end

local function saveKey(key)
    if writefile then
        pcall(writefile, KEY_FILE, key)
    end
end

-- ══════════════════════════════════════════
--  BLOX FRUITS — ЛОГИКА
-- ══════════════════════════════════════════

-- Anti-AFK
local function toggleAntiAFK(enabled)
    if State.AntiAFKConn then
        State.AntiAFKConn:Disconnect()
        State.AntiAFKConn = nil
    end
    if enabled then
        State.AntiAFKConn = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = hrp.CFrame
                end
            end
        end)
    end
end

-- Auto Farm (базовый ближний враг)
local function toggleAutoFarm(enabled)
    if State.FarmConn then
        State.FarmConn:Disconnect()
        State.FarmConn = nil
    end
    if not enabled then return end

    State.FarmConn = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then return end

        local closest, dist = nil, State.FarmRange
        for _, mob in pairs(workspace:GetDescendants()) do
            if mob:IsA("Model") and mob ~= char then
                local mobHum = mob:FindFirstChildOfClass("Humanoid")
                local mobHRP = mob:FindFirstChild("HumanoidRootPart")
                if mobHum and mobHum.Health > 0 and mobHRP then
                    local d = (hrp.Position - mobHRP.Position).Magnitude
                    if d < dist then
                        closest = mob
                        dist = d
                    end
                end
            end
        end

        if closest then
            local tool = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
                or char:FindFirstChildOfClass("Tool")
            if tool and not char:FindFirstChild(tool.Name) then
                tool.Parent = char
            end
            hrp.CFrame = CFrame.new(
                closest.HumanoidRootPart.Position +
                Vector3.new(0, 2, 3)
            )
            if tool and tool:FindFirstChild("Handle") then
                local args = {closest.HumanoidRootPart.Position}
                pcall(function() tool:Activate() end)
            end
        end
    end)
end

-- Devil Fruit ESP / Notifier
local function toggleFruitESP(enabled)
    if State.FruitConn then
        State.FruitConn:Disconnect()
        State.FruitConn = nil
    end
    if not enabled then return end

    State.FruitConn = RunService.Heartbeat:Connect(function()
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj.Name:find("Fruit") then
                if not obj:FindFirstChild("_BasicHubESP") then
                    local tag = Instance.new("BillboardGui")
                    tag.Name       = "_BasicHubESP"
                    tag.AlwaysOnTop = true
                    tag.Size       = UDim2.new(0, 100, 0, 40)
                    tag.StudsOffset = Vector3.new(0, 3, 0)
                    local lbl      = Instance.new("TextLabel", tag)
                    lbl.Size       = UDim2.fromScale(1, 1)
                    lbl.BackgroundTransparency = 1
                    lbl.Text       = "🍎 " .. obj.Name
                    lbl.TextColor3 = Color3.fromRGB(255, 200, 0)
                    lbl.TextScaled = true
                    lbl.Font       = Enum.Font.GothamBold
                    tag.Parent     = obj:FindFirstChild("HumanoidRootPart") or obj
                end
            end
        end
    end)
end

-- Player ESP
local function addESPToPlayer(plr)
    if plr == LocalPlayer then return end
    local conn = plr.CharacterAdded:Connect(function(char)
        task.wait(1)
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if not hrp then return end
        if char:FindFirstChild("_BasicHubPlayerESP") then return end
        local bb = Instance.new("BillboardGui")
        bb.Name        = "_BasicHubPlayerESP"
        bb.AlwaysOnTop = true
        bb.Size        = UDim2.new(0, 120, 0, 45)
        bb.StudsOffset = Vector3.new(0, 4, 0)
        local lb       = Instance.new("TextLabel", bb)
        lb.Size        = UDim2.fromScale(1, 1)
        lb.BackgroundTransparency = 1
        lb.Text        = "👤 " .. plr.Name
        lb.TextColor3  = Color3.fromRGB(255, 80, 80)
        lb.TextScaled  = true
        lb.Font        = Enum.Font.GothamBold
        bb.Parent      = hrp
    end)
    table.insert(State.PlayerESPConns, conn)
end

local function togglePlayerESP(enabled)
    for _, c in pairs(State.PlayerESPConns) do c:Disconnect() end
    State.PlayerESPConns = {}

    -- Убрать существующие ESP
    for _, plr in pairs(Players:GetPlayers()) do
        local char = plr.Character
        if char then
            local esp = char:FindFirstChild("_BasicHubPlayerESP")
            if esp then esp:Destroy() end
        end
    end

    if not enabled then return end

    for _, plr in pairs(Players:GetPlayers()) do
        addESPToPlayer(plr)
        if plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local bb = Instance.new("BillboardGui")
                bb.Name        = "_BasicHubPlayerESP"
                bb.AlwaysOnTop = true
                bb.Size        = UDim2.new(0, 120, 0, 45)
                bb.StudsOffset = Vector3.new(0, 4, 0)
                local lb       = Instance.new("TextLabel", bb)
                lb.Size        = UDim2.fromScale(1, 1)
                lb.BackgroundTransparency = 1
                lb.Text        = "👤 " .. plr.Name
                lb.TextColor3  = Color3.fromRGB(255, 80, 80)
                lb.TextScaled  = true
                lb.Font        = Enum.Font.GothamBold
                bb.Parent      = hrp
            end
        end
    end
    table.insert(
        State.PlayerESPConns,
        Players.PlayerAdded:Connect(addESPToPlayer)
    )
end

-- Auto Stats
local function toggleAutoStats(enabled)
    if not enabled then return end
    task.spawn(function()
        while State.AutoStats do
            pcall(function()
                local statMap = {
                    Melee   = "str",
                    Defense = "def",
                    Sword   = "sword",
                    Gun     = "gun",
                    Fruit   = "df",
                }
                local statKey = statMap[State.SelectedStat] or "str"
                -- Попытка вызвать Remote для добавления статов
                local remote = game:GetService("ReplicatedStorage")
                    :FindFirstChild("AddStat", true)
                if remote then
                    remote:FireServer(statKey)
                end
            end)
            task.wait(0.2)
        end
    end)
end

-- Teleport таблица
local Teleports = {
    ["Море 1"] = {
        ["Starter Island"]  = Vector3.new(975,  144, 1430),
        ["Marine Fortress"] = Vector3.new(-2400, 18, -575),
        ["Jungle"]          = Vector3.new(-1755, 19, -438),
        ["Pirate Village"]  = Vector3.new(-1145, 16, 470),
        ["Desert"]          = Vector3.new(920,  126,  549),
        ["Frozen Village"]  = Vector3.new(1179, 120,  817),
        ["Skylands"]        = Vector3.new(-975, 474, -994),
        ["Colosseum"]       = Vector3.new(-1217, 17, -589),
        ["Magma Village"]   = Vector3.new(-3085, 59, -1013),
        ["Upper Skylands"]  = Vector3.new(-4911, 872, -1178),
        ["Ice Castle"]      = Vector3.new(1137, 120, 810),
        ["Flower Hill"]     = Vector3.new(-1822, 19, -1032),
    },
    ["Море 2"] = {
        ["Kingdom of Rose"] = Vector3.new(-225, 73, -3050),
        ["Green Zone"]      = Vector3.new(4433, 26, -3540),
        ["Graveyard"]       = Vector3.new(5220, 18, -4670),
        ["Snow Mountain"]   = Vector3.new(804,  319, -5188),
        ["Hot & Cold"]      = Vector3.new(-1162, 18, -4994),
        ["Cursed Ship"]     = Vector3.new(-3203, 48, -3110),
        ["Ice Cream Island"]= Vector3.new(-5970, 19, -4440),
        ["Forgotten Island"]= Vector3.new(-2860, 1,  -2960),
    },
    ["Море 3"] = {
        ["Port Town"]       = Vector3.new(-4939, 22, -9305),
        ["Hydra Island"]    = Vector3.new(5478,  21, -10210),
        ["Great Tree"]      = Vector3.new(-1194, 20, -11582),
        ["Floating Turtle"] = Vector3.new(-9234, 253,-10580),
        ["Haunted Castle"]  = Vector3.new(-4900, 25, -8999),
        ["Sea of Treats"]   = Vector3.new(4710,  21, -10435),
    },
}

local function teleportTo(pos)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
    end
end

-- ══════════════════════════════════════════
--  ГЛАВНЫЙ ХАБ
-- ══════════════════════════════════════════
local function LoadMainHub()

    local Window = Rayfield:CreateWindow({
        Name              = "BasicHub | Blox Fruits",
        LoadingTitle      = "BasicHub",
        LoadingSubtitle   = "Blox Fruits Hub",
        ConfigurationSaving = {
            Enabled    = true,
            FolderName = "BasicHub",
            FileName   = "BloxFruits",
        },
        Discord = {Enabled = false},
        KeySystem = false,
    })

    -- ── ⚔️ FARM ──────────────────────────────
    local FarmTab = Window:CreateTab("⚔️ Farm", 4483362458)

    FarmTab:CreateSection("Авто-фарм мобов")

    FarmTab:CreateToggle({
        Name         = "Auto Farm",
        CurrentValue = false,
        Flag         = "AutoFarm",
        Callback     = function(v)
            State.AutoFarm = v
            toggleAutoFarm(v)
            Notify(
                v and "✅ Auto Farm включён" or "❌ Auto Farm выключен",
                v and "Ищем ближайших мобов..." or "Фарм остановлен."
            )
        end,
    })

    FarmTab:CreateSlider({
        Name         = "Дальность фарма",
        Range        = {10, 500},
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
                v and "Поиск Sea Beast..." or "Остановлено."
            )
        end,
    })

    -- ── 📊 STATS ─────────────────────────────
    local StatsTab = Window:CreateTab("📊 Stats", 4483362458)

    StatsTab:CreateSection("Авто-статы")

    StatsTab:CreateDropdown({
        Name           = "Выберите стат",
        Options        = {"Melee", "Defense", "Sword", "Gun", "Fruit"},
        CurrentOption  = {"Melee"},
        MultipleOptions = false,
        Flag           = "StatChoice",
        Callback       = function(opt)
            State.SelectedStat = type(opt) == "table" and opt[1] or opt
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
                v and ("Добавляем статы: " .. State.SelectedStat) or "Остановлено."
            )
        end,
    })

    -- ── 👁️ ESP ───────────────────────────────
    local ESPTab = Window:CreateTab("👁️ ESP", 4483362458)

    ESPTab:CreateSection("Игроки")

    ESPTab:CreateToggle({
        Name         = "Player ESP",
        CurrentValue = false,
        Flag         = "PlayerESP",
        Callback     = function(v)
            State.PlayerESP = v
            togglePlayerESP(v)
            Notify(
                v and "👁️ Player ESP ON" or "👁️ Player ESP OFF",
                v and "ESP активирован." or "ESP отключён."
            )
        end,
    })

    ESPTab:CreateSection("Devil Fruits")

    ESPTab:CreateToggle({
        Name         = "Devil Fruit Notifier / ESP",
        CurrentValue = false,
        Flag         = "FruitESP",
        Callback     = function(v)
            State.FruitESP = v
            toggleFruitESP(v)
            Notify(
                v and "🍎 Fruit ESP ON" or "🍎 Fruit ESP OFF",
                v and "Отображаем фрукты на карте." or "Fruit ESP отключён."
            )
        end,
    })

    -- ── 🌍 TELEPORT ──────────────────────────
    local TpTab = Window:CreateTab("🌍 Teleport", 4483362458)

    for seaName, islands in pairs(Teleports) do
        TpTab:CreateSection(seaName)
        for islandName, pos in pairs(islands) do
            TpTab:CreateButton({
                Name     = islandName,
                Callback = function()
                    teleportTo(pos)
                    Notify("🌍 Телепорт", "Перемещение на " .. islandName, 2)
                end,
            })
        end
    end

    -- ── ⚙️ MISC ──────────────────────────────
    local MiscTab = Window:CreateTab("⚙️ Misc", 4483362458)

    MiscTab:CreateSection("Утилиты")

    MiscTab:CreateToggle({
        Name         = "Anti-AFK",
        CurrentValue = false,
        Flag         = "AntiAFK",
        Callback     = function(v)
            State.AntiAFK = v
            toggleAntiAFK(v)
            Notify(
                v and "✅ Anti-AFK ON" or "❌ Anti-AFK OFF",
                v and "Тебя не кикнут за AFK." or "Защита отключена."
            )
        end,
    })

    MiscTab:CreateButton({
        Name     = "Rejoin Server",
        Callback = function()
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end,
    })

    MiscTab:CreateButton({
        Name     = "Скопировать Server ID",
        Callback = function()
            setclipboard(game.JobId)
            Notify("📋 Скопировано", "Server ID скопирован в буфер.")
        end,
    })

    MiscTab:CreateSection("BasicHub")

    MiscTab:CreateParagraph({
        Title   = "BasicHub | Blox Fruits",
        Content = "Ключ-система: Platoboost\nUI: Rayfield Library\nДля получения ключа: " .. KEY_LINK,
    })

    Notify("✅ BasicHub загружен!", "Добро пожаловать, " .. LocalPlayer.Name .. "!", 4)
end

-- ══════════════════════════════════════════
--  KEY SYSTEM
-- ══════════════════════════════════════════
local saved = getSavedKey()

if saved and isKeyValid(saved) then
    -- Ключ уже сохранён — грузим хаб сразу
    LoadMainHub()
else
    -- Показать окно ключ-системы
    local KeyWindow = Rayfield:CreateWindow({
        Name            = "BasicHub | Ключ-система",
        LoadingTitle    = "BasicHub",
        LoadingSubtitle = "Требуется ключ",
        ConfigurationSaving = {Enabled = false},
        Discord         = {Enabled = false},
        KeySystem       = false,
    })

    local KeyTab = KeyWindow:CreateTab("🔑 Ключ", 4483362458)

    KeyTab:CreateSection("BasicHub — Верификация")

    KeyTab:CreateParagraph({
        Title   = "Добро пожаловать в BasicHub!",
        Content = "Для доступа к хабу введите ключ.\n"
               .. "Ключ сохраняется автоматически — вводить повторно не нужно.",
    })

    local inputKey = ""

    KeyTab:CreateInput({
        Name          = "Введите ключ",
        Placeholder   = "BASICHUB-XXXXX",
        CharacterLimit = 50,
        OnChanged     = function(v)
            inputKey = v
        end,
    })

    -- ── Кнопка 1: Подтвердить ключ ──
    KeyTab:CreateButton({
        Name     = "✅  Подтвердить ключ",
        Callback = function()
            if isKeyValid(inputKey) then
                saveKey(inputKey)
                Notify("✅ Успех!", "Ключ принят. Загрузка BasicHub...", 3)
                task.wait(2)
                KeyWindow:Destroy()
                LoadMainHub()
            else
                Notify("❌ Неверный ключ", "Проверь ключ или получи новый по ссылке.", 4)
            end
        end,
    })

    -- ── Кнопка 2: Скопировать ссылку ──
    KeyTab:CreateButton({
        Name     = "🔗  Скопировать ссылку для получения ключа",
        Callback = function()
            setclipboard(KEY_LINK)
            Notify(
                "📋 Ссылка скопирована!",
                "Вставь в браузер и выполни задание для получения ключа.",
                5
            )
        end,
    })
end
