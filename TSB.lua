-- Protection
local ProtectionConfig = { SecretKey = "TSBCode1234", HubName = "BasicHub" }
if not _G[ProtectionConfig.SecretKey] then
    local p = game:GetService("Players").LocalPlayer
    if p then p:Kick("\n Unauthorized Execution \n\nUse the official BasicHub key system.") end
    return
end

-------------------------------------------------------------------------------
-- SERVICES
-------------------------------------------------------------------------------
local RunService    = game:GetService("RunService")
local Players       = game:GetService("Players")
local HttpService   = game:GetService("HttpService")
local LocalPlayer   = Players.LocalPlayer

-------------------------------------------------------------------------------
-- CHARACTER REFERENCES  (auto-update on respawn)
-------------------------------------------------------------------------------
local character, humanoid, humanoidRootPart

local function refreshCharacter(char)
    character          = char
    humanoid           = char:WaitForChild("Humanoid")
    humanoidRootPart   = char:WaitForChild("HumanoidRootPart")
end

if LocalPlayer.Character then refreshCharacter(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(refreshCharacter)

-------------------------------------------------------------------------------
-- EXPLOITS  (client-side attribute unlocks used by TSB)
-------------------------------------------------------------------------------
local function applyExploits()
    local name = LocalPlayer.Name
    local uid  = tostring(LocalPlayer.UserId)
    pcall(function()
        if workspace:GetAttribute("VIPServer")      ~= uid  then workspace:SetAttribute("VIPServer",      uid)  end
        if workspace:GetAttribute("VIPServerOwner") ~= name then workspace:SetAttribute("VIPServerOwner", name) end
        if workspace:GetAttribute("NoDashCooldown") == nil  then workspace:SetAttribute("NoDashCooldown", false) end
        if workspace:GetAttribute("NoFatigue")      == nil  then workspace:SetAttribute("NoFatigue",      false) end
        if LocalPlayer:GetAttribute("ExtraSlots")   == nil  then LocalPlayer:SetAttribute("ExtraSlots",   false) end
        if LocalPlayer:GetAttribute("EmoteSearchBar")== nil then LocalPlayer:SetAttribute("EmoteSearchBar",false) end
    end)
end
applyExploits()
LocalPlayer.CharacterAdded:Connect(applyExploits)

-------------------------------------------------------------------------------
-- LOAD RAYFIELD
-------------------------------------------------------------------------------
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name             = "BasicHub | The Strongest Battlegrounds",
    LoadingTitle     = "BasicHub",
    LoadingSubtitle  = "The Strongest Battlegrounds",
    ConfigurationSaving = { Enabled = false },
    Discord             = { Enabled = false },
    KeySystem           = false,
})

-------------------------------------------------------------------------------
-- EMOTEFIX — auto-run silently (no loading GUI, no notifications)
-------------------------------------------------------------------------------
task.spawn(function()
    task.wait(3)
    pcall(function()
        local src = game:HttpGet(
            "https://raw.githubusercontent.com/KHATARSISZX/New/refs/heads/main/EmoteStuff/EmoteFix.lua"
        )
        -- Remove loading ScreenGui: prevent it being parented to CoreGui
        src = src:gsub("screen%.Parent%s*=%s*CG", "-- screen suppressed")
        -- Silence all StarterGui notifications by replacing SG service with a mock
        src = src:gsub(
            'local SG%s*=%s*game:GetService%("StarterGui"%)',
            'local SG = setmetatable({},{__index=function()return function()end end})'
        )
        loadstring(src)()
    end)
end)

-------------------------------------------------------------------------------
-- RGB RAINBOW BORDER ON RAYFIELD WINDOW
-------------------------------------------------------------------------------
task.spawn(function()
    task.wait(2.5)
    pcall(function()
        local rgbGui = game:GetService("CoreGui"):FindFirstChild("Rayfield")
        if not rgbGui then
            rgbGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("Rayfield", 5)
        end
        if not rgbGui then return end

        local mainFrame
        for _, obj in pairs(rgbGui:GetDescendants()) do
            if obj:IsA("Frame") and obj.Name == "Main" and obj.AbsoluteSize.X > 200 then
                mainFrame = obj
                break
            end
        end
        if not mainFrame then
            mainFrame = rgbGui:FindFirstChildWhichIsA("Frame", true)
        end
        if not mainFrame then return end

        local stroke = Instance.new("UIStroke", mainFrame)
        stroke.Thickness          = 2
        stroke.ApplyStrokeMode    = Enum.ApplyStrokeMode.Border
        stroke.LineJoinMode       = Enum.LineJoinMode.Round

        local hue = 0
        RunService.Heartbeat:Connect(function()
            if not stroke.Parent then return end
            hue = (hue + 0.0015) % 1
            stroke.Color = Color3.fromHSV(hue, 1, 1)
        end)
    end)
end)

-------------------------------------------------------------------------------
-- SLIDER VISIBILITY FIX
-- When the Rayfield window is toggled off, some slider thumb/fill elements can
-- linger on screen.  Syncing the ScreenGui.Enabled flag with the main frame's
-- Visible state forces all descendants (including stray slider parts) to hide.
-------------------------------------------------------------------------------
task.spawn(function()
    task.wait(3)
    pcall(function()
        local cg = game:GetService("CoreGui")
        local rfGui = cg:FindFirstChild("Rayfield")
        if not rfGui then
            rfGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("Rayfield", 5)
        end
        if not rfGui then return end

        -- Find the main window frame
        local mainFrame
        for _, obj in pairs(rfGui:GetDescendants()) do
            if obj:IsA("Frame") and obj.Name == "Main" and obj.AbsoluteSize.X > 200 then
                mainFrame = obj; break
            end
        end
        if not mainFrame then return end

        -- Slider visibility: Rayfield tweens the frame (doesn't set Visible immediately),
        -- so a signal-based approach fires too late.  Heartbeat polling is instant.
        local lockedInputs    = {}  -- { frame=Frame, size=UDim2 }
        local trackedTextBoxes = {}  -- all TextBox objects found in rfGui

        -- Register a TextBox for per-frame property enforcement
        local function registerTB(obj)
            if not obj:IsA("TextBox") then return end
            for _, tb in ipairs(trackedTextBoxes) do
                if tb == obj then return end
            end
            table.insert(trackedTextBoxes, obj)
        end

        local lastVisible = mainFrame.Visible
        RunService.Heartbeat:Connect(function()
            -- ── Visibility sync ────────────────────────────────────────────
            local v = mainFrame.Visible
            if v ~= lastVisible then lastVisible = v; rfGui.Enabled = v end

            -- ── Input holder size lock ─────────────────────────────────────
            for i = #lockedInputs, 1, -1 do
                local info = lockedInputs[i]
                if info.frame.Parent then
                    if info.frame.Size ~= info.size then
                        info.frame.Size = info.size
                    end
                    -- Also re-enforce clip in case Rayfield resets it
                    info.frame.ClipsDescendants = true
                else
                    table.remove(lockedInputs, i)
                end
            end

            -- ── TextBox overflow prevention (per-frame) ────────────────────
            -- Rayfield resets TextScaled/TextSize after creation, so we must
            -- re-apply every frame.  trackedTextBoxes is small (3–6 items).
            for i = #trackedTextBoxes, 1, -1 do
                local tb = trackedTextBoxes[i]
                if tb.Parent then
                    if tb.TextScaled              then tb.TextScaled  = false          end
                    if tb.TextSize ~= 12          then tb.TextSize    = 12             end
                    if tb.TextTruncate ~= Enum.TextTruncate.AtEnd then
                        tb.TextTruncate = Enum.TextTruncate.AtEnd
                    end
                    local p = tb.Parent
                    if p and not p.ClipsDescendants then p.ClipsDescendants = true end
                    local gp = p and p.Parent
                    if gp and gp:IsA("GuiObject") and not gp.ClipsDescendants then
                        gp.ClipsDescendants = true
                    end
                else
                    table.remove(trackedTextBoxes, i)
                end
            end
        end)

        -- GUI post-processor:
        -- 1. ClipsDescendants = true on rounded containers → nothing bleeds outside corners
        -- 2. Blue UIStrokes → thin grey
        -- 3. Blue fill frames → darker flat colour
        -- 4. TextBox inputs → auto-scale font + clip parent so numbers never overflow
        local function fixGui(root)
            for _, obj in pairs(root:GetDescendants()) do
                pcall(function()
                    -- ── Rounded frames: always clip ──────────────────────────────
                    if obj:IsA("Frame") and obj:FindFirstChildOfClass("UICorner") then
                        obj.ClipsDescendants = true
                        local stroke = obj:FindFirstChildOfClass("UIStroke")
                        if stroke then
                            local c = stroke.Color
                            if c.B > 0.3 and c.B > c.R then
                                stroke.Thickness = 1
                                stroke.Color = Color3.fromRGB(60, 60, 68)
                                local corner = obj:FindFirstChildOfClass("UICorner")
                                if corner then corner.CornerRadius = UDim.new(0, 5) end
                            end
                            for _, g in pairs(obj:GetChildren()) do
                                if g:IsA("UIGradient") then g:Destroy() end
                            end
                        end
                    end
                    -- ── Blue fill frames ─────────────────────────────────────────
                    if obj:IsA("Frame") and obj.BackgroundTransparency < 0.5 then
                        local c = obj.BackgroundColor3
                        if c.B > 0.3 and c.B > c.R then
                            obj.BackgroundColor3 = Color3.fromRGB(38, 78, 160)
                            for _, g in pairs(obj:GetChildren()) do
                                if g:IsA("UIGradient") then g:Destroy() end
                            end
                            local corner = obj:FindFirstChildOfClass("UICorner")
                            if corner then corner.CornerRadius = UDim.new(0, 4) end
                        end
                    end
                    -- ── TextBox inputs ────────────────────────────────────────────
                    -- Register for per-frame Heartbeat enforcement (TextScaled,
                    -- TextTruncate, ClipsDescendants).  Also lock the holder size.
                    if obj:IsA("TextBox") then
                        registerTB(obj)
                        local f = obj.Parent
                        if f and f:IsA("Frame") then
                            f.AutomaticSize = Enum.AutomaticSize.None
                            local alreadyTracked = false
                            for _, info in ipairs(lockedInputs) do
                                if info.frame == f then alreadyTracked = true; break end
                            end
                            if not alreadyTracked then
                                task.delay(0.3, function()
                                    if not f.Parent then return end
                                    local sz = f.Size
                                    if sz.X.Offset < 80 and sz.X.Scale < 0.1 then
                                        sz = UDim2.new(0, 160, sz.Y.Scale, sz.Y.Offset)
                                    end
                                    f.Size = sz
                                    table.insert(lockedInputs, { frame = f, size = sz })
                                end)
                            end
                        end
                    end
                end)
            end
        end
        task.wait(1.5)
        fixGui(rfGui)
        -- Also register any TextBoxes found in the initial scan
        for _, obj in pairs(rfGui:GetDescendants()) do
            pcall(registerTB, obj)
        end
        -- Re-run when new elements are added (tab switches, new inputs)
        rfGui.DescendantAdded:Connect(function(obj)
            task.wait(0.1)
            pcall(registerTB, obj)
            pcall(fixGui, rfGui)
        end)
    end)
end)

-------------------------------------------------------------------------------
-- SPEED / TELEPORT STATE
-------------------------------------------------------------------------------
local tspeed   = 0.1
local tpwalking = false

RunService.Heartbeat:Connect(function()
    if tpwalking and character and humanoid and humanoidRootPart then
        if humanoid.MoveDirection.Magnitude > 0 then
            humanoidRootPart.CFrame = humanoidRootPart.CFrame
                + (humanoid.MoveDirection * tspeed)
        end
    end
end)

-------------------------------------------------------------------------------
-- FLING LOGIC  (SkidFling from K1LAS1K's Multi-Target Fling)
-------------------------------------------------------------------------------
local BH_OldPos   = nil
local BH_FPDH     = workspace.FallenPartsDestroyHeight
local FlingActive = false

local function SkidFling(TargetPlayer)
    local Char     = LocalPlayer.Character
    local Hum      = Char and Char:FindFirstChildOfClass("Humanoid")
    local RootPart = Hum and Hum.RootPart
    if not (Char and Hum and RootPart) then return end

    local TChar    = TargetPlayer.Character
    if not TChar then return end

    local THum     = TChar:FindFirstChildOfClass("Humanoid")
    local TRoot    = THum and THum.RootPart
    local THead    = TChar:FindFirstChild("Head")
    local Acc      = TChar:FindFirstChildOfClass("Accessory")
    local Handle   = Acc and Acc:FindFirstChild("Handle")

    if RootPart.Velocity.Magnitude < 50 then
        BH_OldPos = RootPart.CFrame
    end

    if THum and THum.Sit then return end

    -- Camera follow target
    if THead then
        workspace.CurrentCamera.CameraSubject = THead
    elseif Handle then
        workspace.CurrentCamera.CameraSubject = Handle
    elseif THum and TRoot then
        workspace.CurrentCamera.CameraSubject = THum
    end

    if not TChar:FindFirstChildWhichIsA("BasePart") then return end

    local function FPos(BasePart, Pos, Ang)
        RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
        Char:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
        RootPart.Velocity    = Vector3.new(9e7, 9e7 * 10, 9e7)
        RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
    end

    local function SFBasePart(BasePart)
        local TimeToWait = 2
        local Time       = tick()
        local Angle      = 0
        repeat
            if RootPart and THum then
                if BasePart.Velocity.Magnitude < 50 then
                    Angle = Angle + 100
                    FPos(BasePart, CFrame.new(0,1.5,0) + THum.MoveDirection * BasePart.Velocity.Magnitude/1.25, CFrame.Angles(math.rad(Angle),0,0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0,-1.5,0) + THum.MoveDirection * BasePart.Velocity.Magnitude/1.25, CFrame.Angles(math.rad(Angle),0,0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0,1.5,0) + THum.MoveDirection, CFrame.Angles(math.rad(Angle),0,0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0,-1.5,0) + THum.MoveDirection, CFrame.Angles(math.rad(Angle),0,0))
                    task.wait()
                else
                    FPos(BasePart, CFrame.new(0,1.5,THum.WalkSpeed),  CFrame.Angles(math.rad(90),0,0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0,-1.5,-THum.WalkSpeed),CFrame.Angles(0,0,0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0,1.5,THum.WalkSpeed),  CFrame.Angles(math.rad(90),0,0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0,-1.5,0), CFrame.Angles(math.rad(90),0,0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0,-1.5,0), CFrame.Angles(0,0,0))
                    task.wait()
                end
            end
        until Time + TimeToWait < tick() or not FlingActive
    end

    workspace.FallenPartsDestroyHeight = 0/0

    local BV = Instance.new("BodyVelocity")
    BV.Parent   = RootPart
    BV.Velocity  = Vector3.new(0,0,0)
    BV.MaxForce  = Vector3.new(9e9,9e9,9e9)

    Hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

    if     TRoot  then SFBasePart(TRoot)
    elseif THead  then SFBasePart(THead)
    elseif Handle then SFBasePart(Handle)
    end

    BV:Destroy()
    Hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    workspace.CurrentCamera.CameraSubject = Hum

    if BH_OldPos then
        repeat
            RootPart.CFrame = BH_OldPos * CFrame.new(0,.5,0)
            Char:SetPrimaryPartCFrame(BH_OldPos * CFrame.new(0,.5,0))
            Hum:ChangeState("GettingUp")
            for _, part in pairs(Char:GetChildren()) do
                if part:IsA("BasePart") then
                    part.Velocity = Vector3.new()
                    part.RotVelocity = Vector3.new()
                end
            end
            task.wait()
        until (RootPart.Position - BH_OldPos.p).Magnitude < 25
        workspace.FallenPartsDestroyHeight = BH_FPDH
    end
end

-------------------------------------------------------------------------------
-- FLING GUI  (separate draggable ScreenGui, opened from Rayfield button)
-------------------------------------------------------------------------------
local FlingSelectedTargets = {}
local FlingPlayerCheckboxes = {}
local FlingThread = nil
local FlingGui = nil

local function CreateFlingGUI()
    -- Destroy old GUI if exists
    if FlingGui and FlingGui.Parent then FlingGui:Destroy() end

    local coreGui = game:GetService("CoreGui")
    local parent  = pcall(function() return coreGui end) and coreGui or LocalPlayer:WaitForChild("PlayerGui")

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name           = "BH_FlingGUI"
    ScreenGui.ResetOnSpawn   = false
    ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    pcall(function() ScreenGui.Parent = coreGui end)
    if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    FlingGui = ScreenGui

    -- Main frame
    local Main = Instance.new("Frame", ScreenGui)
    Main.Size              = UDim2.new(0, 320, 0, 400)
    Main.Position          = UDim2.new(0.5, -160, 0.5, -200)
    Main.BackgroundColor3  = Color3.fromRGB(18, 18, 18)
    Main.BorderSizePixel   = 0
    Main.Active            = true
    Main.Draggable         = true
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

    local Stroke = Instance.new("UIStroke", Main)
    Stroke.Thickness = 2
    Stroke.Color     = Color3.fromRGB(220, 50, 50)

    -- Title bar
    local TitleBar = Instance.new("Frame", Main)
    TitleBar.Size             = UDim2.new(1, 0, 0, 36)
    TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    TitleBar.BorderSizePixel  = 0
    Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 12)

    local TitleLabel = Instance.new("TextLabel", TitleBar)
    TitleLabel.Size              = UDim2.new(1, -40, 1, 0)
    TitleLabel.Position          = UDim2.new(0, 10, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text              = "⚔ BasicHub | Fling"
    TitleLabel.TextColor3        = Color3.fromRGB(220, 50, 50)
    TitleLabel.Font              = Enum.Font.GothamBold
    TitleLabel.TextSize          = 15
    TitleLabel.TextXAlignment    = Enum.TextXAlignment.Left

    local CloseBtn = Instance.new("TextButton", TitleBar)
    CloseBtn.Size              = UDim2.new(0, 28, 0, 28)
    CloseBtn.Position          = UDim2.new(1, -32, 0, 4)
    CloseBtn.BackgroundColor3  = Color3.fromRGB(200, 40, 40)
    CloseBtn.Text              = "✕"
    CloseBtn.TextColor3        = Color3.fromRGB(255,255,255)
    CloseBtn.Font              = Enum.Font.GothamBold
    CloseBtn.TextSize          = 14
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

    -- Status label
    local StatusLabel = Instance.new("TextLabel", Main)
    StatusLabel.Size              = UDim2.new(1, -20, 0, 24)
    StatusLabel.Position          = UDim2.new(0, 10, 0, 42)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text              = "Select targets to fling"
    StatusLabel.TextColor3        = Color3.fromRGB(200, 200, 200)
    StatusLabel.Font              = Enum.Font.Gotham
    StatusLabel.TextSize          = 13
    StatusLabel.TextXAlignment    = Enum.TextXAlignment.Left

    -- Player list frame
    local ListOuter = Instance.new("Frame", Main)
    ListOuter.Size             = UDim2.new(1, -20, 0, 220)
    ListOuter.Position         = UDim2.new(0, 10, 0, 70)
    ListOuter.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
    ListOuter.BorderSizePixel  = 0
    Instance.new("UICorner", ListOuter).CornerRadius = UDim.new(0, 8)

    local Scroll = Instance.new("ScrollingFrame", ListOuter)
    Scroll.Size                = UDim2.new(1, -8, 1, -8)
    Scroll.Position            = UDim2.new(0, 4, 0, 4)
    Scroll.BackgroundTransparency = 1
    Scroll.BorderSizePixel     = 0
    Scroll.ScrollBarThickness  = 5
    Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    local ListLayout = Instance.new("UIListLayout", Scroll)
    ListLayout.Padding = UDim.new(0, 4)
    ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Scroll.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 8)
    end)

    -- Count selected
    local function CountSelected()
        local n = 0
        for _ in pairs(FlingSelectedTargets) do n = n + 1 end
        return n
    end

    -- Update status text
    local function UpdateStatus()
        local n = CountSelected()
        if FlingActive then
            StatusLabel.Text      = "⚔ Flinging " .. n .. " player(s)..."
            StatusLabel.TextColor3 = Color3.fromRGB(255,80,80)
        else
            StatusLabel.Text      = n .. " selected | Press START"
            StatusLabel.TextColor3 = Color3.fromRGB(200,200,200)
        end
    end

    -- Build player rows
    local function BuildPlayerList()
        for _, child in pairs(Scroll:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        FlingPlayerCheckboxes = {}

        local allPlayers = Players:GetPlayers()
        table.sort(allPlayers, function(a,b) return a.Name:lower() < b.Name:lower() end)

        for _, plr in ipairs(allPlayers) do
            if plr ~= LocalPlayer then

            local Row = Instance.new("Frame", Scroll)
            Row.Size              = UDim2.new(1, 0, 0, 32)
            Row.BackgroundColor3  = Color3.fromRGB(34, 34, 34)
            Row.BorderSizePixel   = 0
            Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 6)

            -- Checkbox
            local CB = Instance.new("Frame", Row)
            CB.Size             = UDim2.new(0, 20, 0, 20)
            CB.Position         = UDim2.new(0, 6, 0.5, -10)
            CB.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            CB.BorderSizePixel  = 0
            Instance.new("UICorner", CB).CornerRadius = UDim.new(0, 4)

            local Check = Instance.new("TextLabel", CB)
            Check.Size                = UDim2.fromScale(1,1)
            Check.BackgroundTransparency = 1
            Check.Text               = "✓"
            Check.TextColor3         = Color3.fromRGB(80, 255, 80)
            Check.Font               = Enum.Font.GothamBold
            Check.TextSize           = 14
            Check.Visible            = FlingSelectedTargets[plr.Name] ~= nil

            -- Player name
            local NameLabel = Instance.new("TextLabel", Row)
            NameLabel.Size             = UDim2.new(1, -40, 1, 0)
            NameLabel.Position         = UDim2.new(0, 34, 0, 0)
            NameLabel.BackgroundTransparency = 1
            NameLabel.Text             = plr.Name
            NameLabel.TextColor3       = Color3.fromRGB(240, 240, 240)
            NameLabel.Font             = Enum.Font.Gotham
            NameLabel.TextSize         = 13
            NameLabel.TextXAlignment   = Enum.TextXAlignment.Left

            -- Clickable overlay
            local ClickBtn = Instance.new("TextButton", Row)
            ClickBtn.Size              = UDim2.fromScale(1,1)
            ClickBtn.BackgroundTransparency = 1
            ClickBtn.Text              = ""
            ClickBtn.ZIndex            = 5

            ClickBtn.MouseButton1Click:Connect(function()
                if FlingSelectedTargets[plr.Name] then
                    FlingSelectedTargets[plr.Name] = nil
                    Check.Visible = false
                    CB.BackgroundColor3 = Color3.fromRGB(50,50,50)
                else
                    FlingSelectedTargets[plr.Name] = plr
                    Check.Visible = true
                    CB.BackgroundColor3 = Color3.fromRGB(30,80,30)
                end
                UpdateStatus()
            end)

            -- Hover effect
            ClickBtn.MouseEnter:Connect(function()
                Row.BackgroundColor3 = Color3.fromRGB(44,44,44)
            end)
            ClickBtn.MouseLeave:Connect(function()
                Row.BackgroundColor3 = Color3.fromRGB(34,34,34)
            end)

            FlingPlayerCheckboxes[plr.Name] = { Row=Row, Check=Check, CB=CB }
            end -- if plr ~= LocalPlayer
        end -- for
        UpdateStatus()
    end

    -- ── Buttons row ─────────────────────────────────────────────────────────
    local BtnY = 298

    local function MakeBtn(text, color, xScale, xOffset, wScale, wOffset)
        local btn = Instance.new("TextButton", Main)
        btn.Size             = UDim2.new(wScale, wOffset, 0, 36)
        btn.Position         = UDim2.new(xScale, xOffset, 0, BtnY)
        btn.BackgroundColor3 = color
        btn.Text             = text
        btn.TextColor3       = Color3.fromRGB(255,255,255)
        btn.Font             = Enum.Font.GothamBold
        btn.TextSize         = 13
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        return btn
    end

    local StartBtn    = MakeBtn("▶ START",  Color3.fromRGB(0,160,0),   0,10,  0.5,-15)
    local StopBtn     = MakeBtn("■ STOP",   Color3.fromRGB(180,0,0),   0.5,5, 0.5,-15)
    local SelAllBtn   = MakeBtn("✔ All",    Color3.fromRGB(60,60,60),  0,10,  0.5,-15)
    local DeselAllBtn = MakeBtn("✘ None",  Color3.fromRGB(60,60,60),  0.5,5, 0.5,-15)
    SelAllBtn.Position   = UDim2.new(0,10,0,BtnY+44)
    DeselAllBtn.Position = UDim2.new(0.5,5,0,BtnY+44)

    -- ── Logic ────────────────────────────────────────────────────────────────
    local function StartFling()
        if FlingActive then return end
        if CountSelected() == 0 then
            StatusLabel.Text = "Select at least one target!"
            task.wait(1.5)
            UpdateStatus()
            return
        end
        FlingActive = true
        UpdateStatus()
        FlingThread = task.spawn(function()
            while FlingActive do
                for name, plr in pairs(FlingSelectedTargets) do
                    if not (plr and plr.Parent) then
                        FlingSelectedTargets[name] = nil
                        local cb = FlingPlayerCheckboxes[name]
                        if cb then cb.Check.Visible = false; cb.CB.BackgroundColor3 = Color3.fromRGB(50,50,50) end
                    elseif FlingActive then
                        pcall(SkidFling, plr)
                        task.wait(0.1)
                    end
                end
                UpdateStatus()
                task.wait(0.5)
            end
        end)
    end

    local function StopFling()
        if not FlingActive then return end
        FlingActive = false
        FlingThread = nil
        workspace.FallenPartsDestroyHeight = BH_FPDH
        UpdateStatus()
    end

    StartBtn.MouseButton1Click:Connect(StartFling)
    StopBtn.MouseButton1Click:Connect(StopFling)

    SelAllBtn.MouseButton1Click:Connect(function()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                FlingSelectedTargets[plr.Name] = plr
                local cb = FlingPlayerCheckboxes[plr.Name]
                if cb then cb.Check.Visible = true; cb.CB.BackgroundColor3 = Color3.fromRGB(30,80,30) end
            end
        end
        UpdateStatus()
    end)

    DeselAllBtn.MouseButton1Click:Connect(function()
        FlingSelectedTargets = {}
        for _, cb in pairs(FlingPlayerCheckboxes) do
            cb.Check.Visible = false
            cb.CB.BackgroundColor3 = Color3.fromRGB(50,50,50)
        end
        UpdateStatus()
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        StopFling()
        ScreenGui:Destroy()
        FlingGui = nil
    end)

    -- ── Dynamic player list ──────────────────────────────────────────────────
    Players.PlayerAdded:Connect(function(plr)
        if ScreenGui and ScreenGui.Parent then
            BuildPlayerList()
        end
    end)
    Players.PlayerRemoving:Connect(function(plr)
        FlingSelectedTargets[plr.Name] = nil
        if ScreenGui and ScreenGui.Parent then
            BuildPlayerList()
        end
        UpdateStatus()
    end)

    BuildPlayerList()
end

-------------------------------------------------------------------------------
-- ═══ TAB: MAIN ═══
-------------------------------------------------------------------------------
local mainTab = Window:CreateTab("⚔️ Main", "sword")

mainTab:CreateSection("Movement")

mainTab:CreateToggle({
    Name="Speed Boost", CurrentValue=false, Flag="SpeedBoost",
    Callback=function(v) tpwalking = v end,
})
-- Speed Multiplier: type value 0–5  (replaces slider — no broken min-value look)
mainTab:CreateInput({
    Name="Speed Multiplier  (0 – 5)",
    PlaceholderText="Default: 0.1",
    Flag="SpeedInput",
    RemoveTextAfterFocusLost=false,
    Callback=function(v)
        local n = tonumber(v)
        if n then tspeed = math.clamp(n, 0, 5) end
    end,
})

mainTab:CreateDivider()

mainTab:CreateToggle({
    Name="Jump Boost", CurrentValue=false, Flag="JumpBoost",
    Callback=function(v)
        if humanoid then humanoid.UseJumpPower = not v end
    end,
})
-- Jump Height: type value 7.2–500
mainTab:CreateInput({
    Name="Jump Height  (7.2 – 500)",
    PlaceholderText="Default: 7.2",
    Flag="JumpInput",
    RemoveTextAfterFocusLost=false,
    Callback=function(v)
        local n = tonumber(v)
        if n and humanoid then humanoid.JumpHeight = math.clamp(n, 0, 500) end
    end,
})

mainTab:CreateDivider()

-- Gravity: type value 0–300  (default 192.6 = normal)
mainTab:CreateInput({
    Name="Gravity  (0 – 300, default 192.6)",
    PlaceholderText="Default: 192.6",
    Flag="GravityInput",
    RemoveTextAfterFocusLost=false,
    Callback=function(v)
        local n = tonumber(v)
        if n then workspace.Gravity = math.clamp(n, 0, 300) end
    end,
})

-- FOV: type value 10–120  (default 70)
mainTab:CreateInput({
    Name="FOV  (10 – 120)",
    PlaceholderText="Default: 70",
    Flag="FOVInput",
    RemoveTextAfterFocusLost=false,
    Callback=function(v)
        local n = tonumber(v)
        if n and workspace.CurrentCamera then
            workspace.CurrentCamera.FieldOfView = math.clamp(n, 10, 120)
        end
    end,
})

mainTab:CreateDivider()
mainTab:CreateSection("Exploits")

mainTab:CreateToggle({
    Name="No Dash Cooldown", CurrentValue=false, Flag="NoDashCooldown",
    Callback=function(v)
        pcall(function() workspace:SetAttribute("NoDashCooldown", v) end)
    end,
})
mainTab:CreateToggle({
    Name="No Fatigue", CurrentValue=false, Flag="NoFatigue",
    Callback=function(v)
        pcall(function() workspace:SetAttribute("NoFatigue", v) end)
    end,
})

mainTab:CreateDivider()
mainTab:CreateSection("Emotes")

mainTab:CreateToggle({
    Name="Extra Emote Slots", CurrentValue=false, Flag="EmoteExtraSlots",
    Callback=function(v)
        pcall(function() LocalPlayer:SetAttribute("ExtraSlots", v) end)
    end,
})
mainTab:CreateToggle({
    Name="Emote Search Bar", CurrentValue=false, Flag="EmoteSearchBar",
    Callback=function(v)
        pcall(function() LocalPlayer:SetAttribute("EmoteSearchBar", v) end)
    end,
})

mainTab:CreateDivider()
mainTab:CreateSection("Combat")

-- No Stun: keeps player moving freely even when hit (restores WalkSpeed & clears stun attributes)
local NoStunConn    = nil
local PRE_STUN_SPEED = 16  -- fallback restore speed

mainTab:CreateToggle({
    Name="No Stun", CurrentValue=false, Flag="NoStun",
    Callback=function(v)
        if v then
            NoStunConn = RunService.Heartbeat:Connect(function()
                if not humanoid then return end
                pcall(function()
                    -- Restore WalkSpeed if a stun set it to 0
                    if humanoid.WalkSpeed < 1 then
                        humanoid.WalkSpeed = PRE_STUN_SPEED
                    else
                        PRE_STUN_SPEED = humanoid.WalkSpeed  -- track current speed
                    end
                    -- Clear TSB stun attributes
                    if LocalPlayer:GetAttribute("Stunned")            then LocalPlayer:SetAttribute("Stunned", false) end
                    if LocalPlayer:GetAttribute("IsStunned")          then LocalPlayer:SetAttribute("IsStunned", false) end
                    if character and character:GetAttribute("Stunned") then character:SetAttribute("Stunned", false) end
                    -- Disable ragdoll / falling states
                    humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                    humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,     false)
                end)
            end)
        else
            if NoStunConn then NoStunConn:Disconnect(); NoStunConn = nil end
            if humanoid then
                pcall(function()
                    humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
                    humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,     true)
                end)
            end
        end
    end,
})

-------------------------------------------------------------------------------
-- ═══ TAB: FLING ═══
-------------------------------------------------------------------------------
local flingTab = Window:CreateTab("💥 Fling", "zap")

flingTab:CreateSection("Multi-Target Fling")

flingTab:CreateButton({
    Name = "⚔ Open Fling GUI",
    Callback = function()
        if FlingGui and FlingGui.Parent then
            FlingGui:Destroy()
            FlingGui = nil
        else
            CreateFlingGUI()
            Rayfield:Notify({
                Title   = "Fling GUI",
                Content = "Window opened! Select targets.",
                Duration = 2,
                Image   = 4483362458,
            })
        end
    end,
})

flingTab:CreateDivider()
flingTab:CreateSection("Anti-Fling")

local AntiFlingActive = false
local AntiFlingConn   = nil

local function applyAntiFling()
    if humanoid then
        pcall(function() humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false) end)
    end
    AntiFlingConn = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        for _, part in ipairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") and not part.Anchored and not part:IsDescendantOf(char) then
                if part.AssemblyLinearVelocity.Magnitude > 3
                or part.AssemblyAngularVelocity.Magnitude > 3 then
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function removeAntiFling()
    if AntiFlingConn then AntiFlingConn:Disconnect(); AntiFlingConn = nil end
    if humanoid then
        pcall(function() humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end)
    end
end

flingTab:CreateToggle({
    Name = "Anti-Fling",
    CurrentValue = false,
    Flag = "AntiFling",
    Callback = function(v)
        AntiFlingActive = v
        if v then
            applyAntiFling()
        else
            removeAntiFling()
        end
    end,
})

-- Re-apply on respawn
LocalPlayer.CharacterAdded:Connect(function()
    if AntiFlingActive then
        task.wait(1)
        applyAntiFling()
    end
end)

-------------------------------------------------------------------------------
-- ═══ TAB: MOVESETS ═══
-------------------------------------------------------------------------------
local movesetTab = Window:CreateTab("🥊 Movesets", "activity")

movesetTab:CreateSection("Jujutsu Kaisen")

-- ── GOJO SATORU ──────────────────────────────────────────────────────────────
local function runGojoMoveset()
    task.spawn(function()
        local plr  = game.Players.LocalPlayer
        repeat task.wait() until plr.Character
        local char = plr.Character or plr.CharacterAdded:Wait()
        local hum  = char:WaitForChild("Humanoid")
        local pGui = plr.PlayerGui

        -- Hotbar labels
        pcall(function()
            local hotbar = pGui:FindFirstChild("Hotbar")
            local bp     = hotbar and hotbar:FindFirstChild("Backpack")
            local hf     = bp and bp:FindFirstChild("Hotbar")
            if hf then
                local names = {"Reversal Red","Barrage Attack","Strong Punch","Justice throw"}
                for i, n in ipairs(names) do
                    pcall(function() hf:FindFirstChild(tostring(i)).Base.ToolName.Text = n end)
                end
            end
        end)

        -- MagicHealth label
        pcall(function()
            local sg = pGui:FindFirstChild("ScreenGui")
            local mh = sg and sg:FindFirstChild("MagicHealth")
            local tl = mh and mh:FindFirstChild("TextLabel")
            if tl then tl.Text = "Let's Get Crazy" end
        end)
        pGui.DescendantAdded:Connect(function()
            pcall(function()
                local sg = pGui:FindFirstChild("ScreenGui")
                local mh = sg and sg:FindFirstChild("MagicHealth")
                local tl = mh and mh:FindFirstChild("TextLabel")
                if tl then tl.Text = "Let's Get Crazy" end
            end)
        end)

        -- Animation replacements (trigger anim ID → replacement anim ID, speed, startTime)
        local simpleSwaps = {
            { src=10468665991, dst="13073745835",   spd=0.9, st=0,   adjSpd0=0.1 },
            { src=10466974800, dst="13560306510",   spd=3,   st=0,   adjSpd0=4   },
            { src=10471336737, dst="10469643643",   spd=1,   st=0.5, adjSpd0=0,  stopAfter=1.8 },
            { src=12510170988, dst="13813955149",   spd=1,   st=0,   adjSpd0=0   },
            { src=11343318134, dst="12983333733",   spd=0.5, st=2,   adjSpd0=0   },
            { src=15955393872, dst="15943915877",   spd=1,   st=0.05,adjSpd0=0   },
            { src=12983333733, dst="13073745835",   spd=0.2, st=0,   adjSpd0=0   },
            { src=12447707844, dst="18435303746",   spd=1,   st=0,   adjSpd0=0   },
            { src=10479335397, dst="17838006839",   spd=0.7, st=0,   adjSpd0=0,  stopAfter=1.2 },
            { src=10503381238, dst="14900168720",   spd=0.7, st=1.3, adjSpd0=0   },
            { src=10470104242, dst="12447247483",   spd=6,   st=0,   adjSpd0=0,  waitBefore=0.2 },
        }

        for _, s in ipairs(simpleSwaps) do
            local swap = s
            hum.AnimationPlayed:Connect(function(track)
                if track.Animation.AnimationId == "rbxassetid://" .. swap.src then
                    for _, t in pairs(hum:GetPlayingAnimationTracks()) do t:Stop() end
                    local a = Instance.new("Animation")
                    a.AnimationId = "rbxassetid://" .. swap.dst
                    local loaded = hum:LoadAnimation(a)
                    if swap.waitBefore then task.wait(swap.waitBefore) end
                    loaded:Play()
                    loaded:AdjustSpeed(swap.adjSpd0 or 0)
                    loaded.TimePosition = swap.st
                    loaded:AdjustSpeed(swap.spd)
                    if swap.stopAfter then
                        task.delay(swap.stopAfter, function() loaded:Stop() end)
                    end
                end
            end)
        end

        -- Queued animation set (M1 chain)
        local stopSet = {[17859015788]=true,[10469493270]=true,[10469630950]=true,
                         [10469639222]=true,[10469643643]=true}
        local repMap  = {
            ["17859015788"]="rbxassetid://12684185971",
            ["10469643643"]="rbxassetid://17889290569",
            ["10469639222"]="rbxassetid://17889471098",
            ["10469630950"]="rbxassetid://17889461810",
            ["10469493270"]="rbxassetid://17889458563",
            ["11365563255"]="rbxassetid://14516273501",
        }
        local queue2, isAnim = {}, false
        local function playRep(animId)
            if isAnim then table.insert(queue2, animId); return end
            isAnim = true
            local rep = repMap[tostring(animId)]
            if rep then
                local a = Instance.new("Animation"); a.AnimationId = rep
                local loaded = hum:LoadAnimation(a); loaded:Play()
                loaded.Stopped:Connect(function()
                    isAnim = false
                    if #queue2 > 0 then playRep(table.remove(queue2,1)) end
                end)
            else isAnim = false end
        end
        hum.AnimationPlayed:Connect(function(track)
            local id = tonumber(track.Animation.AnimationId:match("%d+"))
            if stopSet[id] then
                for _, t in ipairs(hum:GetPlayingAnimationTracks()) do
                    if stopSet[tonumber(t.Animation.AnimationId:match("%d+"))] then t:Stop() end
                end
                track:Stop(); playRep(id)
            end
        end)

        -- Block Y BodyVelocity (prevent launch)
        local function patchBV(d)
            if d:IsA("BodyVelocity") then
                d.Velocity = Vector3.new(d.Velocity.X, 0, d.Velocity.Z)
            end
        end
        for _, d in pairs(char:GetDescendants()) do patchBV(d) end
        char.DescendantAdded:Connect(patchBV)

        Rayfield:Notify({ Title="Moveset", Content="Gojo Satoru loaded!", Duration=3, Image=4483362458 })
    end)
end

movesetTab:CreateButton({ Name = "Gojo Satoru", Callback = runGojoMoveset })

-- ── RYOMEN SUKUNA ─────────────────────────────────────────────────────────────
movesetTab:CreateButton({
    Name = "Ryomen Sukuna",
    Callback = function()
        task.spawn(function()
            local ok, err = pcall(function()
                loadstring(game:HttpGet("https://pastes.io/raw/O0Rpknka"))()
            end)
            Rayfield:Notify({
                Title   = "Moveset",
                Content = ok and "Sukuna loaded!" or ("Error: " .. tostring(err)),
                Duration = ok and 3 or 6, Image = 4483362458,
            })
        end)
    end,
})

-------------------------------------------------------------------------------
-- ═══ TAB: AVATAR LOADER ═══
-------------------------------------------------------------------------------
local avatarTab = Window:CreateTab("👤 Avatar", "user")

local avatarUserId   = ""
local avatarApplying = false

-- ── Pure visual helpers (no ApplyDescription / server calls) ────────────────

-- Strip all visual decorations from the character (client-side only)
local function clearVisuals(char)
    for _, c in ipairs(char:GetChildren()) do
        if c:IsA("Accessory") or c:IsA("Hat") or c:IsA("Shirt") or
           c:IsA("Pants") or c:IsA("ShirtGraphic") or c:IsA("CharacterMesh") then
            pcall(function() c:Destroy() end)
        end
    end
    -- Remove face decal from Head
    local head = char:FindFirstChild("Head")
    if head then
        for _, d in ipairs(head:GetChildren()) do
            if d:IsA("Decal") and d.Name:lower() == "face" then
                pcall(function() d:Destroy() end)
            end
        end
    end
    -- Remove BodyColors so skin colour is fully replaced
    local bc = char:FindFirstChildOfClass("BodyColors")
    if bc then pcall(function() bc:Destroy() end) end
end

-- Attach an accessory visually using WeldConstraint + Attachment name matching
local function attachAccessory(char, accessory)
    local handle = accessory:FindFirstChild("Handle")
    if not handle then return end
    local targetAtt, accAtt
    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            for _, att in ipairs(part:GetChildren()) do
                if att:IsA("Attachment") then
                    local match = handle:FindFirstChild(att.Name)
                    if match and match:IsA("Attachment") then
                        targetAtt = att
                        accAtt    = match
                        break
                    end
                end
            end
        end
        if targetAtt then break end
    end
    if targetAtt and accAtt then
        handle.CFrame = targetAtt.WorldCFrame * accAtt.CFrame:Inverse()
    else
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then handle.CFrame = root.CFrame end
    end
    local weld   = Instance.new("WeldConstraint")
    weld.Part0   = handle
    weld.Part1   = (targetAtt and targetAtt.Parent)
                or char:FindFirstChild("HumanoidRootPart")
                or char:FindFirstChild("Head")
    weld.Parent  = handle
    accessory.Parent = char
end

-- Apply appearance from any userId — purely visual, no server side-effects
local function applyVisual(userId)
    if avatarApplying then
        Rayfield:Notify({ Title="Avatar", Content="Already applying, please wait...", Duration=2, Image=4483362458 })
        return
    end
    avatarApplying = true
    Rayfield:Notify({ Title="Avatar", Content="Loading appearance...", Duration=2, Image=4483362458 })
    task.spawn(function()
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            avatarApplying = false
            Rayfield:Notify({ Title="Avatar", Content="No character!", Duration=3, Image=4483362458 })
            return
        end
        local ok, model = pcall(function()
            return Players:GetCharacterAppearanceAsync(userId)
        end)
        if not ok or not model then
            avatarApplying = false
            Rayfield:Notify({ Title="Avatar", Content="Failed to load appearance!", Duration=4, Image=4483362458 })
            return
        end
        clearVisuals(char)
        -- Body colours
        local bc = model:FindFirstChildOfClass("BodyColors")
        if bc then bc:Clone().Parent = char end
        -- Clothing
        for _, item in ipairs(model:GetChildren()) do
            if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then
                item:Clone().Parent = char
            end
        end
        -- Accessories (WeldConstraint-based visual attachment)
        for _, acc in ipairs(model:GetChildren()) do
            if acc:IsA("Accessory") or acc:IsA("Hat") then
                pcall(function() attachAccessory(char, acc:Clone()) end)
            end
        end
        -- Face decal
        local head = char:FindFirstChild("Head")
        if head then
            local face = model:FindFirstChild("face", true)
            if face and face:IsA("Decal") then face:Clone().Parent = head end
        end
        model:Destroy()
        avatarApplying = false
        Rayfield:Notify({ Title="Avatar", Content="Skin applied!", Duration=3, Image=4483362458 })
    end)
end

-- ── Avatar tab UI ────────────────────────────────────────────────────────────

avatarTab:CreateSection("⚠ Warning")
avatarTab:CreateLabel("To avoid bugs, remove all accessories from your avatar before applying a skin.")

avatarTab:CreateSection("Load Avatar by User ID")
avatarTab:CreateInput({
    Name                     = "User ID",
    PlaceholderText          = "e.g. 1234567890",
    Flag                     = "AvatarUserId",
    RemoveTextAfterFocusLost = false,
    Callback                 = function(v) avatarUserId = v end,
})

avatarTab:CreateButton({
    Name = "Apply Skin",
    Callback = function()
        local uid = tonumber(avatarUserId)
        if not uid then
            Rayfield:Notify({ Title="Avatar", Content="Invalid User ID!", Duration=3, Image=4483362458 })
            return
        end
        applyVisual(uid)
    end,
})

avatarTab:CreateButton({
    Name = "Reset Avatar",
    Callback = function()
        -- Re-applies the player's own appearance using the same visual path
        applyVisual(LocalPlayer.UserId)
    end,
})


-------------------------------------------------------------------------------
-- ═══ TAB: TELEPORT ═══
-------------------------------------------------------------------------------
local tpTab = Window:CreateTab("🌍 Teleport", "map-pin")

tpTab:CreateSection("Locations")

local Locations = {
    { name="Middle (Centre Map)",    pos=CFrame.new(148, 441, 27)       },
    { name="Death Counter Room",     pos=CFrame.new(-92, 29, 20347)     },
    { name="Mountain 1",             pos=CFrame.new(266, 699, 458)      },
}

for _, loc in ipairs(Locations) do
    tpTab:CreateButton({
        Name = loc.name,
        Callback = function()
            if humanoidRootPart then
                humanoidRootPart.CFrame = loc.pos
                Rayfield:Notify({
                    Title   = "Teleport",
                    Content = "→ " .. loc.name,
                    Duration = 2,
                    Image   = 4483362458,
                })
            end
        end,
    })
end

tpTab:CreateSection("Custom Position")
local customX, customY, customZ = 0, 0, 0
tpTab:CreateInput({ Name="X", PlaceholderText="0", Flag="TpX", RemoveTextAfterFocusLost=false,
    Callback=function(v) customX = tonumber(v) or 0 end })
tpTab:CreateInput({ Name="Y", PlaceholderText="0", Flag="TpY", RemoveTextAfterFocusLost=false,
    Callback=function(v) customY = tonumber(v) or 0 end })
tpTab:CreateInput({ Name="Z", PlaceholderText="0", Flag="TpZ", RemoveTextAfterFocusLost=false,
    Callback=function(v) customZ = tonumber(v) or 0 end })
tpTab:CreateButton({
    Name = "Teleport to Coordinates",
    Callback = function()
        if humanoidRootPart then
            humanoidRootPart.CFrame = CFrame.new(customX, customY, customZ)
            Rayfield:Notify({ Title="Teleport", Content=customX..", "..customY..", "..customZ, Duration=2, Image=4483362458 })
        end
    end,
})

-------------------------------------------------------------------------------
-- ═══ TAB: AUTO TECH ═══
-------------------------------------------------------------------------------
local autoTechTab = Window:CreateTab("⚡ AutoTech", "zap")

-- Shared animation hook helper (re-hooks on respawn)
local function hookAnimation(animId, callback)
    local id = tostring(animId):gsub("rbxassetid://", "")
    local function hookChar(char)
        local hum = char:FindFirstChildWhichIsA("Humanoid")
            or char:WaitForChild("Humanoid", 3)
        if not hum then return end
        hum.AnimationPlayed:Connect(function(track)
            local raw = track.Animation and track.Animation.AnimationId or ""
            if tostring(raw):gsub("rbxassetid://", "") == id then
                callback(track, char)
            end
        end)
    end
    if LocalPlayer.Character then hookChar(LocalPlayer.Character) end
    LocalPlayer.CharacterAdded:Connect(hookChar)
end

-- ── 1. Flowing Water + Dash ──────────────────────────────────────────────────
autoTechTab:CreateSection("Combat Techs")

local flowingEnabled = false
autoTechTab:CreateToggle({
    Name         = "Flowing Water + Dash",
    CurrentValue = false,
    Flag         = "AutoFlowing",
    Callback     = function(v) flowingEnabled = v end,
})

hookAnimation("12273188754", function(track, char)
    if not flowingEnabled then return end
    local comm = char:FindFirstChild("Communicate")
    if not comm then return end
    task.wait(1.57)
    pcall(function()
        comm:FireServer({ Dash = Enum.KeyCode.W, Key = Enum.KeyCode.Q, Goal = "KeyPress" })
    end)
end)

-- ── 2. Auto Kyoto ────────────────────────────────────────────────────────────
local kyotoEnabled = false
autoTechTab:CreateToggle({
    Name         = "Auto Kyoto",
    CurrentValue = false,
    Flag         = "AutoKyoto",
    Callback     = function(v) kyotoEnabled = v end,
})

hookAnimation("12273188754", function(track, char)
    if not kyotoEnabled then return end
    local comm = char:FindFirstChild("Communicate")
    if not comm then return end
    local tool = LocalPlayer.Backpack:FindFirstChild("Lethal Whirlwind Stream")
        or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Lethal Whirlwind Stream"))
    if not tool then return end
    task.wait(1.49)
    pcall(function()
        comm:FireServer({ Tool = tool, Goal = "Console Move" })
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = hrp.CFrame + hrp.CFrame.LookVector * 16 end
    end)
end)

-- ── 3. Sky Upper Dash ────────────────────────────────────────────────────────
local skyEnabled = false
autoTechTab:CreateToggle({
    Name         = "Sky Upper Dash",
    CurrentValue = false,
    Flag         = "AutoSkyDash",
    Callback     = function(v) skyEnabled = v end,
})

hookAnimation("10503381238", function(track, char)
    if not skyEnabled then return end
    local comm = char:FindFirstChild("Communicate")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not comm or not root then return end
    task.wait(0.5)
    pcall(function()
        root.CFrame = root.CFrame + Vector3.new(0, 5, 0)
        comm:FireServer({ Dash = Enum.KeyCode.W, Key = Enum.KeyCode.Q, Goal = "KeyPress" })
        root.Anchored = true
        task.wait(1)
        root.Anchored = false
    end)
end)

-- ── 4. Instant Lethal Dash ───────────────────────────────────────────────────
local lethalEnabled = false
autoTechTab:CreateToggle({
    Name         = "Instant Lethal Dash",
    CurrentValue = false,
    Flag         = "AutoLethalDash",
    Callback     = function(v) lethalEnabled = v end,
})

hookAnimation("12296113986", function(track, char)
    if not lethalEnabled then return end
    local comm = char:FindFirstChild("Communicate")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not comm or not root then return end
    task.wait(1.59)
    pcall(function()
        root.CFrame = root.CFrame + Vector3.new(0, 5, 0)
        comm:FireServer({ Dash = Enum.KeyCode.W, Key = Enum.KeyCode.Q, Goal = "KeyPress" })
        root.Anchored = true
        task.wait(1)
        root.Anchored = false
    end)
end)

-------------------------------------------------------------------------------
-- ═══ TAB: MISC ═══
-------------------------------------------------------------------------------
local miscTab = Window:CreateTab("⚙️ Misc", "settings")

miscTab:CreateSection("Player")
miscTab:CreateButton({
    Name = "Reset Character",
    Callback = function()
        if humanoid then humanoid.Health = 0 end
    end,
})
miscTab:CreateButton({
    Name = "Copy Server ID",
    Callback = function()
        pcall(function() (setclipboard or toclipboard)(game.JobId) end)
        Rayfield:Notify({ Title="Copied", Content="Server ID copied!", Duration=2, Image=4483362458 })
    end,
})

miscTab:CreateDivider()
miscTab:CreateSection("Performance")

miscTab:CreateButton({
    Name = "FPS Unlocker (9999)",
    Callback = function()
        local ok = pcall(function() setfpscap(9999) end)
        Rayfield:Notify({
            Title   = "FPS Unlocker",
            Content = ok and "FPS cap set to 9999!" or "setfpscap not supported by your executor.",
            Duration = 3,
            Image   = 4483362458,
        })
    end,
})

miscTab:CreateButton({
    Name = "Open Developer Console",
    Callback = function()
        pcall(function()
            game:GetService("StarterGui"):SetCore("DevConsoleVisible", true)
        end)
    end,
})

miscTab:CreateDivider()
miscTab:CreateSection("Protection")

local AntiDCActive = false
local AntiDCConn   = nil
miscTab:CreateToggle({
    Name = "Anti-Disconnect",
    CurrentValue = false,
    Flag = "AntiDC",
    Callback = function(v)
        AntiDCActive = v
        if v then
            AntiDCConn = RunService.Heartbeat:Connect(function()
                pcall(function()
                    -- Suppress kick RemoteEvents fired to client
                    local rs = game:GetService("ReplicatedStorage")
                    for _, obj in pairs(rs:GetDescendants()) do
                        if obj:IsA("RemoteEvent") and
                           (obj.Name:lower():find("kick") or obj.Name:lower():find("ban")) then
                            obj.OnClientEvent:Connect(function() end)
                        end
                    end
                end)
            end)
        else
            if AntiDCConn then AntiDCConn:Disconnect(); AntiDCConn = nil end
        end
    end,
})

miscTab:CreateDivider()
miscTab:CreateSection("About")
miscTab:CreateParagraph({
    Title   = "BasicHub | The Strongest Battlegrounds",
    Content = "UI Library  : Rayfield\n"
           .. "Key System  : Platoboost\n"
           .. "Game        : The Strongest Battlegrounds\n"
           .. "Press K     : Toggle UI",
})

-------------------------------------------------------------------------------
-- READY
-------------------------------------------------------------------------------
Rayfield:Notify({
    Title   = "✅ BasicHub Loaded!",
    Content = "Welcome, " .. LocalPlayer.Name .. "! Press K to toggle UI.",
    Duration = 5,
    Image   = 4483362458,
})

