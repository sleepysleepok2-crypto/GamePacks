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
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local HttpService      = game:GetService("HttpService")
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
-- CUSTOM GUI LIBRARY  (Rayfield-compatible API)
-------------------------------------------------------------------------------
local function MakeBasicHubLib()
    local lib = {}

    -- ── ScreenGui ─────────────────────────────────────────────────────────────
    local coreGui = game:GetService("CoreGui")
    local guiRoot
    pcall(function()
        if guiRoot then return end
        local sg = Instance.new("ScreenGui")
        sg.Name           = "BasicHub_GUI"
        sg.ResetOnSpawn   = false
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        sg.Parent         = coreGui
        guiRoot           = sg
    end)
    if not guiRoot then
        local sg = Instance.new("ScreenGui")
        sg.Name         = "BasicHub_GUI"
        sg.ResetOnSpawn = false
        sg.Parent       = LocalPlayer:WaitForChild("PlayerGui")
        guiRoot         = sg
    end

    -- ── Dimensions & colours ──────────────────────────────────────────────────
    local SIDEBAR_W = 148
    local WINDOW_W  = 540
    local WINDOW_H  = 420
    local TOPBAR_H  = 38

    local C_WIN_BG  = Color3.fromRGB(8,   10,  22 )
    local C_TOP_BG  = Color3.fromRGB(10,  14,  28 )
    local C_SIDE_BG = Color3.fromRGB(6,   8,   18 )
    local C_CONT_BG = Color3.fromRGB(8,   12,  24 )
    local C_ELEM_BG = Color3.fromRGB(14,  18,  36 )
    local C_TEXT    = Color3.fromRGB(215, 230, 255)
    local C_SUB     = Color3.fromRGB(130, 150, 190)
    local C_ACCENT  = Color3.fromRGB(0,   200, 255)
    local C_TOG_ON  = Color3.fromRGB(0,   210, 120)
    local C_TOG_OFF = Color3.fromRGB(25,  32,  60 )

    -- ── Main window ───────────────────────────────────────────────────────────
    local MainFrame = Instance.new("Frame", guiRoot)
    MainFrame.Name             = "MainWindow"
    MainFrame.Size             = UDim2.new(0, WINDOW_W, 0, WINDOW_H)
    MainFrame.Position         = UDim2.new(0.5, -WINDOW_W/2, 0.5, -WINDOW_H/2)
    MainFrame.BackgroundColor3 = C_WIN_BG
    MainFrame.BorderSizePixel  = 0
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

    -- Cosmic-blue background gradient
    local bgGrad = Instance.new("UIGradient", MainFrame)
    bgGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(10, 16, 40)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(5,  8,  22)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(8,  18, 44)),
    })
    bgGrad.Rotation = 135

    -- Rainbow border
    local borderStroke = Instance.new("UIStroke", MainFrame)
    borderStroke.Thickness       = 2
    borderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    borderStroke.LineJoinMode    = Enum.LineJoinMode.Round
    do
        local hue = 0
        RunService.Heartbeat:Connect(function()
            if not borderStroke.Parent then return end
            hue = (hue + 0.0015) % 1
            borderStroke.Color = Color3.fromHSV(hue, 1, 1)
        end)
    end

    -- Top bar
    local TopBar = Instance.new("Frame", MainFrame)
    TopBar.Size             = UDim2.new(1, 0, 0, TOPBAR_H)
    TopBar.BackgroundColor3 = C_TOP_BG
    TopBar.BorderSizePixel  = 0
    Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 10)
    local topPatch = Instance.new("Frame", TopBar)
    topPatch.Size             = UDim2.new(1, 0, 0.5, 0)
    topPatch.Position         = UDim2.new(0, 0, 0.5, 0)
    topPatch.BackgroundColor3 = C_TOP_BG
    topPatch.BorderSizePixel  = 0

    local TitleLbl = Instance.new("TextLabel", TopBar)
    TitleLbl.Size               = UDim2.new(1, -70, 1, 0)
    TitleLbl.Position           = UDim2.new(0, 12, 0, 0)
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.TextColor3         = C_TEXT
    TitleLbl.Font               = Enum.Font.GothamBold
    TitleLbl.TextSize           = 14
    TitleLbl.TextXAlignment     = Enum.TextXAlignment.Left
    TitleLbl.Text               = "BasicHub"

    local CloseBtn = Instance.new("TextButton", TopBar)
    CloseBtn.Size              = UDim2.new(0, 26, 0, 26)
    CloseBtn.Position          = UDim2.new(1, -32, 0.5, -13)
    CloseBtn.BackgroundColor3  = Color3.fromRGB(190, 40, 40)
    CloseBtn.Text              = "✕"
    CloseBtn.TextColor3        = Color3.fromRGB(255, 255, 255)
    CloseBtn.Font              = Enum.Font.GothamBold
    CloseBtn.TextSize          = 11
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

    local winVisible = true
    CloseBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = false
        winVisible        = false
    end)

    -- TopBar drag  (Rayfield-style: dragInput tracking + input.Changed end detection)
    local dragToggle, dragInput, dragStart, dragStartPos = false, nil, nil, nil
    local function applyDrag(input)
        local delta = input.Position - dragStart
        TweenService:Create(MainFrame, TweenInfo.new(0.025), {
            Position = UDim2.new(
                dragStartPos.X.Scale, dragStartPos.X.Offset + delta.X,
                dragStartPos.Y.Scale, dragStartPos.Y.Offset + delta.Y
            ),
        }):Play()
    end
    TopBar.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or
            input.UserInputType == Enum.UserInputType.Touch) and
            UserInputService:GetFocusedTextBox() == nil then
            dragToggle   = true
            dragStart    = input.Position
            dragStartPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragToggle = false
                end
            end)
        end
    end)
    TopBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or
           input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragToggle then
            applyDrag(input)
        end
    end)

    -- K toggle
    UserInputService.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == Enum.KeyCode.K then
            winVisible        = not winVisible
            MainFrame.Visible = winVisible
        end
    end)

    -- Bottom drag handle  (Rayfield-style, Frame so InputBegan propagates cleanly)
    local BottomBar = Instance.new("Frame", MainFrame)
    BottomBar.Name             = "BottomDragBar"
    BottomBar.Size             = UDim2.new(0, 90, 0, 18)
    BottomBar.Position         = UDim2.new(0.5, -45, 1, -22)
    BottomBar.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    BottomBar.BackgroundTransparency = 0.5
    BottomBar.BorderSizePixel  = 0
    BottomBar.ZIndex           = 8
    Instance.new("UICorner", BottomBar).CornerRadius = UDim.new(1, 0)
    -- Grip dots
    for i = 1, 3 do
        local dot = Instance.new("Frame", BottomBar)
        dot.Size             = UDim2.new(0, 4, 0, 4)
        dot.Position         = UDim2.new(0.5, (i - 2) * 10 - 2, 0.5, -2)
        dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        dot.BackgroundTransparency = 0.3
        dot.BorderSizePixel  = 0
        dot.ZIndex           = 9
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    end

    -- Rayfield-style drag on BottomBar
    local bToggle, bInput, bStart, bStartPos = false, nil, nil, nil
    local function applyBDrag(input)
        local delta = input.Position - bStart
        TweenService:Create(MainFrame, TweenInfo.new(0.025), {
            Position = UDim2.new(
                bStartPos.X.Scale, bStartPos.X.Offset + delta.X,
                bStartPos.Y.Scale, bStartPos.Y.Offset + delta.Y
            ),
        }):Play()
    end
    BottomBar.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or
            input.UserInputType == Enum.UserInputType.Touch) and
            UserInputService:GetFocusedTextBox() == nil then
            bToggle   = true
            bStart    = input.Position
            bStartPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    bToggle = false
                end
            end)
        end
    end)
    BottomBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or
           input.UserInputType == Enum.UserInputType.Touch then
            bInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == bInput and bToggle then
            applyBDrag(input)
        end
    end)

    -- Sidebar
    local Sidebar = Instance.new("Frame", MainFrame)
    Sidebar.Size             = UDim2.new(0, SIDEBAR_W, 1, -TOPBAR_H)
    Sidebar.Position         = UDim2.new(0, 0, 0, TOPBAR_H)
    Sidebar.BackgroundColor3 = C_SIDE_BG
    Sidebar.BorderSizePixel  = 0
    Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 10)
    local sidePatch = Instance.new("Frame", Sidebar)
    sidePatch.Size             = UDim2.new(0.5, 0, 1, 0)
    sidePatch.Position         = UDim2.new(0.5, 0, 0, 0)
    sidePatch.BackgroundColor3 = C_SIDE_BG
    sidePatch.BorderSizePixel  = 0

    local TabList = Instance.new("ScrollingFrame", Sidebar)
    TabList.Size                   = UDim2.new(1, -4, 1, -8)
    TabList.Position               = UDim2.new(0, 2, 0, 8)
    TabList.BackgroundTransparency = 1
    TabList.BorderSizePixel        = 0
    TabList.ScrollBarThickness     = 0
    TabList.CanvasSize             = UDim2.new(0, 0, 0, 0)
    local TabLayout = Instance.new("UIListLayout", TabList)
    TabLayout.Padding   = UDim.new(0, 2)
    TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabList.CanvasSize = UDim2.new(0, 0, 0, TabLayout.AbsoluteContentSize.Y + 8)
    end)

    -- Content area
    local Content = Instance.new("Frame", MainFrame)
    Content.Size             = UDim2.new(1, -SIDEBAR_W, 1, -TOPBAR_H)
    Content.Position         = UDim2.new(0, SIDEBAR_W, 0, TOPBAR_H)
    Content.BackgroundColor3 = C_CONT_BG
    Content.BorderSizePixel  = 0
    Instance.new("UICorner", Content).CornerRadius = UDim.new(0, 10)
    local contPatch = Instance.new("Frame", Content)
    contPatch.Size             = UDim2.new(0.15, 0, 1, 0)
    contPatch.BackgroundColor3 = C_CONT_BG
    contPatch.BorderSizePixel  = 0

    -- Notification container (bottom-right of screen)
    local NotifFrame = Instance.new("Frame", guiRoot)
    NotifFrame.Name                   = "Notifications"
    NotifFrame.Size                   = UDim2.new(0, 278, 1, 0)
    NotifFrame.Position               = UDim2.new(1, -288, 0, 0)
    NotifFrame.BackgroundTransparency = 1
    NotifFrame.BorderSizePixel        = 0
    local NotifLayout = Instance.new("UIListLayout", NotifFrame)
    NotifLayout.Padding           = UDim.new(0, 6)
    NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    NotifLayout.SortOrder         = Enum.SortOrder.LayoutOrder

    -- ── Shared helpers ────────────────────────────────────────────────────────
    local function makeScroll()
        local sf = Instance.new("ScrollingFrame", Content)
        sf.Size                   = UDim2.new(1, -6, 1, -6)
        sf.Position               = UDim2.new(0, 3, 0, 3)
        sf.BackgroundTransparency = 1
        sf.BorderSizePixel        = 0
        sf.ScrollBarThickness     = 3
        sf.ScrollBarImageColor3   = Color3.fromRGB(70, 70, 90)
        sf.CanvasSize             = UDim2.new(0, 0, 0, 0)
        sf.Visible                = false
        local layout = Instance.new("UIListLayout", sf)
        layout.Padding   = UDim.new(0, 4)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        local pad = Instance.new("UIPadding", sf)
        pad.PaddingLeft   = UDim.new(0, 8)
        pad.PaddingRight  = UDim.new(0, 8)
        pad.PaddingTop    = UDim.new(0, 6)
        pad.PaddingBottom = UDim.new(0, 6)
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            sf.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 14)
        end)
        return sf, layout
    end

    local function makeElem(parent, h)
        local f = Instance.new("Frame", parent)
        f.Size             = UDim2.new(1, 0, 0, h or 34)
        f.BackgroundColor3 = C_ELEM_BG
        f.BorderSizePixel  = 0
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
        return f
    end

    -- ── Rayfield-compatible API ───────────────────────────────────────────────
    function lib:CreateWindow(opts)
        opts = opts or {}
        TitleLbl.Text = opts.Name or "BasicHub"

        local activeScroll = nil
        local activeTabBtn = nil

        local function showTab(sf, btn)
            if activeScroll then activeScroll.Visible = false end
            if activeTabBtn then
                activeTabBtn.BackgroundColor3 = C_SIDE_BG
                local l = activeTabBtn:FindFirstChildOfClass("TextLabel")
                if l then l.TextColor3 = C_SUB end
            end
            sf.Visible             = true
            btn.BackgroundColor3   = Color3.fromRGB(30, 30, 44)
            local l = btn:FindFirstChildOfClass("TextLabel")
            if l then l.TextColor3 = C_ACCENT end
            activeScroll = sf
            activeTabBtn = btn
        end

        local win      = {}
        local tabCount = 0

        function win:CreateTab(name, _icon)
            tabCount = tabCount + 1
            local scroll, _layout = makeScroll()
            local elemOrder = 0
            local function nextOrder()
                elemOrder = elemOrder + 1
                return elemOrder
            end

            -- Sidebar button
            local tabBtn = Instance.new("TextButton", TabList)
            tabBtn.Size             = UDim2.new(1, -4, 0, 30)
            tabBtn.BackgroundColor3 = C_SIDE_BG
            tabBtn.BorderSizePixel  = 0
            tabBtn.Text             = ""
            tabBtn.LayoutOrder      = tabCount
            Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 6)

            local tabLbl = Instance.new("TextLabel", tabBtn)
            tabLbl.Size                   = UDim2.new(1, -10, 1, 0)
            tabLbl.Position               = UDim2.new(0, 8, 0, 0)
            tabLbl.BackgroundTransparency = 1
            tabLbl.Text                   = name
            tabLbl.TextColor3             = C_SUB
            tabLbl.Font                   = Enum.Font.Gotham
            tabLbl.TextSize               = 11
            tabLbl.TextXAlignment         = Enum.TextXAlignment.Left

            tabBtn.MouseButton1Click:Connect(function() showTab(scroll, tabBtn) end)
            tabBtn.MouseEnter:Connect(function()
                if tabBtn ~= activeTabBtn then
                    tabBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
                end
            end)
            tabBtn.MouseLeave:Connect(function()
                if tabBtn ~= activeTabBtn then
                    tabBtn.BackgroundColor3 = C_SIDE_BG
                end
            end)

            if tabCount == 1 then showTab(scroll, tabBtn) end

            local tab = {}

            function tab:CreateSection(title)
                local f = Instance.new("Frame", scroll)
                f.Size                   = UDim2.new(1, 0, 0, 20)
                f.BackgroundTransparency = 1
                f.LayoutOrder            = nextOrder()
                local lbl = Instance.new("TextLabel", f)
                lbl.Size                   = UDim2.new(1, -8, 1, 0)
                lbl.Position               = UDim2.new(0, 4, 0, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text                   = title:upper()
                lbl.TextColor3             = C_ACCENT
                lbl.Font                   = Enum.Font.GothamBold
                lbl.TextSize               = 10
                lbl.TextXAlignment         = Enum.TextXAlignment.Left
                local line = Instance.new("Frame", f)
                line.Size             = UDim2.new(1, 0, 0, 1)
                line.Position         = UDim2.new(0, 0, 1, -1)
                line.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
                line.BorderSizePixel  = 0
            end

            function tab:CreateDivider()
                local f = Instance.new("Frame", scroll)
                f.Size                   = UDim2.new(1, 0, 0, 8)
                f.BackgroundTransparency = 1
                f.LayoutOrder            = nextOrder()
                local line = Instance.new("Frame", f)
                line.Size             = UDim2.new(1, 0, 0, 1)
                line.Position         = UDim2.new(0, 0, 0.5, 0)
                line.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
                line.BorderSizePixel  = 0
            end

            function tab:CreateLabel(text)
                local f = makeElem(scroll, 26)
                f.LayoutOrder            = nextOrder()
                f.BackgroundTransparency = 0.55
                local lbl = Instance.new("TextLabel", f)
                lbl.Size                   = UDim2.new(1, -10, 1, 0)
                lbl.Position               = UDim2.new(0, 6, 0, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text                   = text
                lbl.TextColor3             = C_SUB
                lbl.Font                   = Enum.Font.Gotham
                lbl.TextSize               = 11
                lbl.TextXAlignment         = Enum.TextXAlignment.Left
                lbl.TextWrapped            = true
                return lbl
            end

            function tab:CreateParagraph(opts2)
                opts2 = opts2 or {}
                local content2 = opts2.Content or ""
                local lineCount = 0
                for _ in content2:gmatch("[^\n]+") do lineCount = lineCount + 1 end
                local h = 28 + math.max(lineCount, 1) * 13
                local f = makeElem(scroll, h)
                f.LayoutOrder = nextOrder()
                local tl = Instance.new("TextLabel", f)
                tl.Size                   = UDim2.new(1, -10, 0, 18)
                tl.Position               = UDim2.new(0, 6, 0, 4)
                tl.BackgroundTransparency = 1
                tl.Text                   = opts2.Title or ""
                tl.TextColor3             = C_TEXT
                tl.Font                   = Enum.Font.GothamBold
                tl.TextSize               = 12
                tl.TextXAlignment         = Enum.TextXAlignment.Left
                local cl = Instance.new("TextLabel", f)
                cl.Size                   = UDim2.new(1, -10, 1, -22)
                cl.Position               = UDim2.new(0, 6, 0, 22)
                cl.BackgroundTransparency = 1
                cl.Text                   = content2
                cl.TextColor3             = C_SUB
                cl.Font                   = Enum.Font.Gotham
                cl.TextSize               = 11
                cl.TextXAlignment         = Enum.TextXAlignment.Left
                cl.TextWrapped            = true
            end

            function tab:CreateButton(opts2)
                opts2 = opts2 or {}
                local f = makeElem(scroll, 34)
                f.LayoutOrder = nextOrder()
                local bar = Instance.new("Frame", f)
                bar.Size             = UDim2.new(0, 3, 0.6, 0)
                bar.Position         = UDim2.new(0, 0, 0.2, 0)
                bar.BackgroundColor3 = C_ACCENT
                bar.BorderSizePixel  = 0
                Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 2)
                local btn2 = Instance.new("TextButton", f)
                btn2.Size                   = UDim2.new(1, 0, 1, 0)
                btn2.BackgroundTransparency = 1
                btn2.Text                   = opts2.Name or "Button"
                btn2.TextColor3             = C_TEXT
                btn2.Font                   = Enum.Font.GothamSemibold
                btn2.TextSize               = 12
                btn2.MouseButton1Click:Connect(function()
                    TweenService:Create(f, TweenInfo.new(0.08), { BackgroundColor3 = Color3.fromRGB(36,36,50) }):Play()
                    task.delay(0.16, function()
                        TweenService:Create(f, TweenInfo.new(0.12), { BackgroundColor3 = C_ELEM_BG }):Play()
                    end)
                    if opts2.Callback then task.spawn(opts2.Callback) end
                end)
                btn2.MouseEnter:Connect(function()
                    TweenService:Create(f, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(34,34,44) }):Play()
                end)
                btn2.MouseLeave:Connect(function()
                    TweenService:Create(f, TweenInfo.new(0.1), { BackgroundColor3 = C_ELEM_BG }):Play()
                end)
                return btn2
            end

            function tab:CreateToggle(opts2)
                opts2 = opts2 or {}
                local val = opts2.CurrentValue or false
                local f   = makeElem(scroll, 34)
                f.LayoutOrder = nextOrder()
                local lbl = Instance.new("TextLabel", f)
                lbl.Size                   = UDim2.new(1, -50, 1, 0)
                lbl.Position               = UDim2.new(0, 8, 0, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text                   = opts2.Name or "Toggle"
                lbl.TextColor3             = C_TEXT
                lbl.Font                   = Enum.Font.Gotham
                lbl.TextSize               = 12
                lbl.TextXAlignment         = Enum.TextXAlignment.Left
                local track = Instance.new("Frame", f)
                track.Size             = UDim2.new(0, 34, 0, 18)
                track.Position         = UDim2.new(1, -42, 0.5, -9)
                track.BackgroundColor3 = val and C_TOG_ON or C_TOG_OFF
                track.BorderSizePixel  = 0
                Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
                local knob = Instance.new("Frame", track)
                knob.Size             = UDim2.new(0, 14, 0, 14)
                knob.Position         = val and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)
                knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                knob.BorderSizePixel  = 0
                Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
                local cBtn = Instance.new("TextButton", f)
                cBtn.Size                   = UDim2.new(1, 0, 1, 0)
                cBtn.BackgroundTransparency = 1
                cBtn.Text                   = ""
                cBtn.MouseButton1Click:Connect(function()
                    val = not val
                    TweenService:Create(track, TweenInfo.new(0.14), { BackgroundColor3 = val and C_TOG_ON or C_TOG_OFF }):Play()
                    TweenService:Create(knob, TweenInfo.new(0.14), {
                        Position = val and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)
                    }):Play()
                    if opts2.Callback then task.spawn(opts2.Callback, val) end
                end)
                cBtn.MouseEnter:Connect(function()
                    TweenService:Create(f, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(32,32,42) }):Play()
                end)
                cBtn.MouseLeave:Connect(function()
                    TweenService:Create(f, TweenInfo.new(0.1), { BackgroundColor3 = C_ELEM_BG }):Play()
                end)
                local togObj = {}
                function togObj:SetValue(v)
                    val = v
                    track.BackgroundColor3 = v and C_TOG_ON or C_TOG_OFF
                    knob.Position = v and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)
                end
                return togObj
            end

            function tab:CreateInput(opts2)
                opts2 = opts2 or {}
                local f = makeElem(scroll, 52)
                f.LayoutOrder = nextOrder()
                local lbl = Instance.new("TextLabel", f)
                lbl.Size                   = UDim2.new(1, -10, 0, 20)
                lbl.Position               = UDim2.new(0, 8, 0, 4)
                lbl.BackgroundTransparency = 1
                lbl.Text                   = opts2.Name or "Input"
                lbl.TextColor3             = C_TEXT
                lbl.Font                   = Enum.Font.Gotham
                lbl.TextSize               = 12
                lbl.TextXAlignment         = Enum.TextXAlignment.Left
                local holder = Instance.new("Frame", f)
                holder.Size             = UDim2.new(1, -16, 0, 24)
                holder.Position         = UDim2.new(0, 8, 0, 22)
                holder.BackgroundColor3 = Color3.fromRGB(13, 13, 17)
                holder.BorderSizePixel  = 0
                Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 5)
                local iStroke = Instance.new("UIStroke", holder)
                iStroke.Thickness = 1
                iStroke.Color     = Color3.fromRGB(46, 46, 62)
                local tb = Instance.new("TextBox", holder)
                tb.Size                   = UDim2.new(1, -8, 1, 0)
                tb.Position               = UDim2.new(0, 4, 0, 0)
                tb.BackgroundTransparency = 1
                tb.Text                   = ""
                tb.PlaceholderText        = opts2.PlaceholderText or ""
                tb.PlaceholderColor3      = Color3.fromRGB(85, 85, 105)
                tb.TextColor3             = C_TEXT
                tb.Font                   = Enum.Font.Gotham
                tb.TextSize               = 12
                tb.TextXAlignment         = Enum.TextXAlignment.Left
                tb.ClearTextOnFocus       = false
                tb.ClipsDescendants       = true
                tb.Focused:Connect(function()
                    TweenService:Create(iStroke, TweenInfo.new(0.12), { Color = C_ACCENT }):Play()
                end)
                tb.FocusLost:Connect(function()
                    TweenService:Create(iStroke, TweenInfo.new(0.12), { Color = Color3.fromRGB(46,46,62) }):Play()
                    if opts2.RemoveTextAfterFocusLost then tb.Text = "" end
                    if opts2.Callback then task.spawn(opts2.Callback, tb.Text) end
                end)
                return tb
            end

            function tab:CreateSlider(opts2)
                opts2 = opts2 or {}
                local rMin = (opts2.Range and opts2.Range[1]) or 0
                local rMax = (opts2.Range and opts2.Range[2]) or 100
                local inc  = opts2.Increment or 1
                local sVal = opts2.CurrentValue or rMin
                local f    = makeElem(scroll, 52)
                f.LayoutOrder = nextOrder()
                local lbl = Instance.new("TextLabel", f)
                lbl.Size                   = UDim2.new(1, -55, 0, 20)
                lbl.Position               = UDim2.new(0, 8, 0, 4)
                lbl.BackgroundTransparency = 1
                lbl.Text                   = opts2.Name or "Slider"
                lbl.TextColor3             = C_TEXT
                lbl.Font                   = Enum.Font.Gotham
                lbl.TextSize               = 12
                lbl.TextXAlignment         = Enum.TextXAlignment.Left
                local valLbl = Instance.new("TextLabel", f)
                valLbl.Size                   = UDim2.new(0, 50, 0, 20)
                valLbl.Position               = UDim2.new(1, -54, 0, 4)
                valLbl.BackgroundTransparency = 1
                valLbl.Text                   = tostring(sVal)
                valLbl.TextColor3             = C_ACCENT
                valLbl.Font                   = Enum.Font.GothamBold
                valLbl.TextSize               = 11
                valLbl.TextXAlignment         = Enum.TextXAlignment.Right
                local trackBG = Instance.new("Frame", f)
                trackBG.Size             = UDim2.new(1, -16, 0, 5)
                trackBG.Position         = UDim2.new(0, 8, 0, 34)
                trackBG.BackgroundColor3 = Color3.fromRGB(38, 38, 52)
                trackBG.BorderSizePixel  = 0
                Instance.new("UICorner", trackBG).CornerRadius = UDim.new(1, 0)
                local fill = Instance.new("Frame", trackBG)
                fill.Size             = UDim2.new((sVal-rMin)/math.max(rMax-rMin,0.001), 0, 1, 0)
                fill.BackgroundColor3 = C_ACCENT
                fill.BorderSizePixel  = 0
                Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
                local function setSVal(v)
                    v = math.clamp(math.floor(v/inc+0.5)*inc, rMin, rMax)
                    sVal = v
                    valLbl.Text = tostring(v)
                    fill.Size = UDim2.new((v-rMin)/math.max(rMax-rMin,0.001), 0, 1, 0)
                    if opts2.Callback then task.spawn(opts2.Callback, v) end
                end
                local sliding = false
                local hitbox = Instance.new("TextButton", trackBG)
                hitbox.Size                   = UDim2.new(1, 0, 0, 16)
                hitbox.Position               = UDim2.new(0, 0, 0.5, -8)
                hitbox.BackgroundTransparency = 1
                hitbox.Text                   = ""
                hitbox.ZIndex                 = 5
                hitbox.MouseButton1Down:Connect(function() sliding = true end)
                UserInputService.InputChanged:Connect(function(inp)
                    if sliding and inp.UserInputType == Enum.UserInputType.MouseMovement then
                        local abs = trackBG.AbsolutePosition
                        local w   = trackBG.AbsoluteSize.X
                        setSVal(rMin + (rMax-rMin) * math.clamp((inp.Position.X-abs.X)/w, 0, 1))
                    end
                end)
                UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        sliding = false
                    end
                end)
                local slObj = {}
                function slObj:SetValue(v) setSVal(v) end
                return slObj
            end

            return tab
        end -- CreateTab

        return win
    end -- CreateWindow

    -- ── Notify ────────────────────────────────────────────────────────────────
    function lib:Notify(opts)
        opts = opts or {}
        local ntitle   = opts.Title    or "Notification"
        local ncontent = opts.Content  or ""
        local ndur     = opts.Duration or 4

        local n = Instance.new("Frame", NotifFrame)
        n.Size             = UDim2.new(1, 0, 0, 56)
        n.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
        n.BorderSizePixel  = 0
        n.BackgroundTransparency = 1
        Instance.new("UICorner", n).CornerRadius = UDim.new(0, 8)
        local nS = Instance.new("UIStroke", n)
        nS.Thickness    = 1
        nS.Color        = C_ACCENT
        nS.Transparency = 1

        local ntl = Instance.new("TextLabel", n)
        ntl.Size                   = UDim2.new(1, -10, 0, 22)
        ntl.Position               = UDim2.new(0, 8, 0, 4)
        ntl.BackgroundTransparency = 1
        ntl.Text                   = ntitle
        ntl.TextColor3             = C_TEXT
        ntl.Font                   = Enum.Font.GothamBold
        ntl.TextSize               = 12
        ntl.TextXAlignment         = Enum.TextXAlignment.Left
        ntl.TextTransparency       = 1

        local ncl = Instance.new("TextLabel", n)
        ncl.Size                   = UDim2.new(1, -10, 0, 22)
        ncl.Position               = UDim2.new(0, 8, 0, 26)
        ncl.BackgroundTransparency = 1
        ncl.Text                   = ncontent
        ncl.TextColor3             = C_SUB
        ncl.Font                   = Enum.Font.Gotham
        ncl.TextSize               = 11
        ncl.TextXAlignment         = Enum.TextXAlignment.Left
        ncl.TextWrapped            = true
        ncl.TextTransparency       = 1

        TweenService:Create(n,   TweenInfo.new(0.3), { BackgroundTransparency = 0 }):Play()
        TweenService:Create(nS,  TweenInfo.new(0.3), { Transparency = 0 }):Play()
        TweenService:Create(ntl, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
        TweenService:Create(ncl, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()

        task.delay(ndur, function()
            if not (n and n.Parent) then return end
            TweenService:Create(n,   TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
            TweenService:Create(nS,  TweenInfo.new(0.35), { Transparency = 1 }):Play()
            TweenService:Create(ntl, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
            TweenService:Create(ncl, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
            task.delay(0.4, function()
                if n and n.Parent then n:Destroy() end
            end)
        end)
    end

    return lib
end

local Rayfield = MakeBasicHubLib()

local Window = Rayfield:CreateWindow({
    Name = "BasicHub | The Strongest Battlegrounds",
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

local noDashEndlagEnabled = false
mainTab:CreateToggle({
    Name="No Dash Endlag", CurrentValue=false, Flag="NoDashEndlag",
    Callback=function(v)
        noDashEndlagEnabled = v
    end,
})

-- No Dash Endlag logic: on Q press, stop long animation tracks after ~0.3s
UserInputService.InputBegan:Connect(function(inp, gp)
    if gp or not noDashEndlagEnabled then return end
    if inp.KeyCode == Enum.KeyCode.Q then
        task.delay(0.3, function()
            if not noDashEndlagEnabled then return end
            local char = LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            pcall(function()
                for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
                    if track.Length and track.Length > 0.45 then
                        track:Stop(0.08)
                    end
                end
            end)
        end)
    end
end)

mainTab:CreateToggle({
    Name="No Fatigue", CurrentValue=false, Flag="NoFatigue",
    Callback=function(v)
        pcall(function() workspace:SetAttribute("NoFatigue", v) end)
    end,
})
mainTab:CreateLabel("⚠ No Fatigue: Update needed.")

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

-- No Stun: reactive via GetPropertyChangedSignal — fires the instant TSB changes the value
local noStunEnabled  = false
local noStunSpd      = 16
local noStunConns    = {}
local noStunCharConn = nil

local function disconnectNoStun()
    for i = 1, #noStunConns do
        noStunConns[i]:Disconnect()
    end
    noStunConns = {}
end

local function applyNoStun(char)
    disconnectNoStun()
    if not noStunEnabled or not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum then return end

    -- Set values immediately on connect
    pcall(function() hum.WalkSpeed     = noStunSpd end)
    pcall(function() hum.PlatformStand = false      end)

    -- WalkSpeed: the moment TSB changes it → instantly restore
    noStunConns[#noStunConns + 1] = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        pcall(function()
            if hum.WalkSpeed ~= noStunSpd then
                hum.WalkSpeed = noStunSpd
            end
        end)
    end)

    -- PlatformStand: the moment TSB sets it true → instantly false
    noStunConns[#noStunConns + 1] = hum:GetPropertyChangedSignal("PlatformStand"):Connect(function()
        pcall(function()
            if hum.PlatformStand then hum.PlatformStand = false end
        end)
    end)

    -- HumanoidRootPart velocity: the moment a large knockback is applied → zero horizontal
    if hrp then
        noStunConns[#noStunConns + 1] = hrp:GetPropertyChangedSignal("AssemblyLinearVelocity"):Connect(function()
            pcall(function()
                local vel  = hrp.AssemblyLinearVelocity
                local hMag = Vector3.new(vel.X, 0, vel.Z).Magnitude
                if hMag > 25 then
                    hrp.AssemblyLinearVelocity = Vector3.new(0, vel.Y, 0)
                end
            end)
        end)
    end
end

mainTab:CreateToggle({
    Name="No Stun", CurrentValue=false, Flag="NoStun",
    Callback=function(v)
        noStunEnabled = v
        if v then
            local char = LocalPlayer.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            noStunSpd = (hum and hum.WalkSpeed > 2) and hum.WalkSpeed or 16
            applyNoStun(char)
            noStunCharConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
                task.wait(0.5)
                noStunSpd = 16
                applyNoStun(newChar)
            end)
        else
            disconnectNoStun()
            if noStunCharConn then noStunCharConn:Disconnect(); noStunCharConn = nil end
        end
    end,
})
mainTab:CreateLabel("⚠ Beta: Set speed boost for better work.")

mainTab:CreateDivider()
mainTab:CreateSection("Wall Combo")
mainTab:CreateLabel("Press button to load Wall Combo script (auto-detect walls, auto-combo).")

local wallComboLoaded = false
mainTab:CreateButton({
    Name = "Load Wall Combo",
    Callback = function()
        if wallComboLoaded then
            Rayfield:Notify({ Title="Wall Combo", Content="Already loaded!", Duration=2, Image=4483362458 })
            return
        end
        wallComboLoaded = true
        task.spawn(function()
            pcall(function()
                local src = game:HttpGet(
                    "https://rawscripts.net/raw/The-Strongest-Battlegrounds-KEYLESS-TSB-Wall-Combo-Anywhere-and-Auto-Wall-Combo-98317"
                )
                -- Silence all StarterGui SetCore notifications
                src = src:gsub(
                    'game:GetService%("StarterGui"%)',
                    'setmetatable({},{__index=function()return function()end end})'
                )
                src = src:gsub('StarterGui:SetCore%b()', '')
                -- Silence prints
                src = src:gsub('print%b()', '')
                loadstring(src)()
            end)
        end)
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

movesetTab:CreateDivider()
movesetTab:CreateLabel("Movesets update soon.")

-------------------------------------------------------------------------------
-- ═══ TAB: COMBAT ═══
-------------------------------------------------------------------------------
local autoFarmTab = Window:CreateTab("⚔ Combat", "zap")

-- ── TP to Player (player picker popup) ────────────────────────────────────────
autoFarmTab:CreateSection("Teleport to Player")
autoFarmTab:CreateLabel("Opens a list of all players on the server. Click a name to teleport.")

-- Player picker popup (separate ScreenGui so it floats above the main window)
local pickerGui = Instance.new("ScreenGui")
pickerGui.Name           = "BH_PlayerPicker"
pickerGui.ResetOnSpawn   = false
pickerGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() pickerGui.Parent = game:GetService("CoreGui") end)
if not pickerGui.Parent then
    pickerGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local pickerFrame = Instance.new("Frame", pickerGui)
pickerFrame.Name             = "Picker"
pickerFrame.Size             = UDim2.new(0, 200, 0, 240)
pickerFrame.Position         = UDim2.new(0.5, -100, 0.5, -120)
pickerFrame.BackgroundColor3 = Color3.fromRGB(10, 12, 28)
pickerFrame.BorderSizePixel  = 0
pickerFrame.Visible          = false
pickerFrame.Active           = true
Instance.new("UICorner", pickerFrame).CornerRadius = UDim.new(0, 8)
local pkStroke = Instance.new("UIStroke", pickerFrame)
pkStroke.Color     = Color3.fromRGB(0, 200, 255)
pkStroke.Thickness = 1

-- Drag for picker
local pkDrag, pkDragStart, pkDragPos = false, nil, nil
local pkTitleBar = Instance.new("TextLabel", pickerFrame)
pkTitleBar.Size               = UDim2.new(1, -30, 0, 28)
pkTitleBar.BackgroundTransparency = 1
pkTitleBar.Text               = "Select Player"
pkTitleBar.TextColor3         = Color3.fromRGB(0, 200, 255)
pkTitleBar.Font               = Enum.Font.GothamBold
pkTitleBar.TextSize           = 13
pkTitleBar.TextXAlignment     = Enum.TextXAlignment.Left
pkTitleBar.Position           = UDim2.new(0, 8, 0, 0)

local pkClose = Instance.new("TextButton", pickerFrame)
pkClose.Size             = UDim2.new(0, 22, 0, 22)
pkClose.Position         = UDim2.new(1, -26, 0, 3)
pkClose.BackgroundColor3 = Color3.fromRGB(190, 40, 40)
pkClose.Text             = "✕"
pkClose.TextColor3       = Color3.fromRGB(255, 255, 255)
pkClose.Font             = Enum.Font.GothamBold
pkClose.TextSize         = 11
Instance.new("UICorner", pkClose).CornerRadius = UDim.new(0, 4)
pkClose.MouseButton1Click:Connect(function() pickerFrame.Visible = false end)

-- Picker drag
pickerFrame.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        pkDrag      = true
        pkDragStart = UserInputService:GetMouseLocation()
        pkDragPos   = pickerFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if pkDrag and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local cur   = UserInputService:GetMouseLocation()
        local delta = cur - pkDragStart
        pickerFrame.Position = UDim2.new(
            pkDragPos.X.Scale, pkDragPos.X.Offset + delta.X,
            pkDragPos.Y.Scale, pkDragPos.Y.Offset + delta.Y
        )
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then pkDrag = false end
end)

-- Divider line under title
local pkLine = Instance.new("Frame", pickerFrame)
pkLine.Size             = UDim2.new(1, -8, 0, 1)
pkLine.Position         = UDim2.new(0, 4, 0, 28)
pkLine.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
pkLine.BackgroundTransparency = 0.6
pkLine.BorderSizePixel  = 0

-- Scrollable player list
local pkScroll = Instance.new("ScrollingFrame", pickerFrame)
pkScroll.Size                   = UDim2.new(1, -8, 1, -36)
pkScroll.Position               = UDim2.new(0, 4, 0, 32)
pkScroll.BackgroundTransparency = 1
pkScroll.BorderSizePixel        = 0
pkScroll.ScrollBarThickness     = 3
pkScroll.ScrollBarImageColor3   = Color3.fromRGB(0, 200, 255)
pkScroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
local pkLayout = Instance.new("UIListLayout", pkScroll)
pkLayout.Padding   = UDim.new(0, 3)
pkLayout.SortOrder = Enum.SortOrder.LayoutOrder
pkLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    pkScroll.CanvasSize = UDim2.new(0, 0, 0, pkLayout.AbsoluteContentSize.Y + 6)
end)

local function openPlayerPicker()
    -- Rebuild list fresh each time
    for _, c in ipairs(pkScroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    local order = 0
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            order = order + 1
            local pb = Instance.new("TextButton", pkScroll)
            pb.Size             = UDim2.new(1, 0, 0, 30)
            pb.BackgroundColor3 = Color3.fromRGB(14, 18, 36)
            pb.BorderSizePixel  = 0
            pb.Text             = plr.Name
            pb.TextColor3       = Color3.fromRGB(215, 230, 255)
            pb.Font             = Enum.Font.Gotham
            pb.TextSize         = 12
            pb.LayoutOrder      = order
            Instance.new("UICorner", pb).CornerRadius = UDim.new(0, 5)
            local pbStroke = Instance.new("UIStroke", pb)
            pbStroke.Color     = Color3.fromRGB(30, 40, 80)
            pbStroke.Thickness = 1
            pb.MouseEnter:Connect(function()
                pb.BackgroundColor3 = Color3.fromRGB(0, 50, 90)
                pbStroke.Color      = Color3.fromRGB(0, 200, 255)
            end)
            pb.MouseLeave:Connect(function()
                pb.BackgroundColor3 = Color3.fromRGB(14, 18, 36)
                pbStroke.Color      = Color3.fromRGB(30, 40, 80)
            end)
            local capturedPlr = plr
            pb.MouseButton1Click:Connect(function()
                pickerFrame.Visible = false
                local myHRP = humanoidRootPart
                if not myHRP then
                    Rayfield:Notify({ Title="Combat", Content="No character!", Duration=3, Image=4483362458 })
                    return
                end
                local tChar = capturedPlr.Character
                local tHRP  = tChar and tChar:FindFirstChild("HumanoidRootPart")
                if not tHRP then
                    Rayfield:Notify({ Title="Combat", Content=capturedPlr.Name .. " has no character!", Duration=3, Image=4483362458 })
                    return
                end
                myHRP.CFrame = tHRP.CFrame + Vector3.new(0, 3, 0)
                Rayfield:Notify({ Title="Combat", Content="Teleported to " .. capturedPlr.Name, Duration=3, Image=4483362458 })
            end)
        end
    end
    if order == 0 then
        local nob = Instance.new("TextLabel", pkScroll)
        nob.Size = UDim2.new(1, 0, 0, 30)
        nob.BackgroundTransparency = 1
        nob.Text = "No other players"
        nob.TextColor3 = Color3.fromRGB(130, 150, 190)
        nob.Font = Enum.Font.Gotham
        nob.TextSize = 12
        nob.LayoutOrder = 1
    end
    pickerFrame.Visible = true
end

autoFarmTab:CreateButton({
    Name = "Select Player & Teleport",
    Callback = function() openPlayerPicker() end,
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
-- ═══ TAB: ESP ═══
-------------------------------------------------------------------------------
local espTab = Window:CreateTab("👁 ESP", "eye")

-- ── Death Counter detection ──────────────────────────────────────────────────
-- Saitama's "Death Counter" ultimate in TSB adds identifiable objects to the
-- character (BoolValues / StringValues / ParticleEmitters).  We scan for them.
local DC_KEYWORDS = { "death", "counter", "ultimate", "rage", "dc", "saitama" }

local function strHasKeyword(s)
    s = s:lower()
    for _, kw in ipairs(DC_KEYWORDS) do
        if s:find(kw, 1, true) then return true end
    end
    return false
end

local function isInDeathCounter(char)
    if not char then return false end
    for _, obj in ipairs(char:GetDescendants()) do
        if strHasKeyword(obj.Name) then
            if obj:IsA("BoolValue")   and obj.Value          then return true end
            if obj:IsA("StringValue") and obj.Value ~= ""    then return true end
            if obj:IsA("NumberValue") and obj.Value > 0      then return true end
            if obj:IsA("ParticleEmitter") or obj:IsA("Beam") then return true end
        end
    end
    return false
end

-- ── ESP state ────────────────────────────────────────────────────────────────
local espEnabled = false
local espObjects = {}   -- player → { billboard, label, healthBar, healthFill }

local ESP_NORMAL_COLOR = Color3.fromRGB(255, 255, 255)
local ESP_DC_COLOR     = Color3.fromRGB(255, 50, 50)

local function buildESP(player)
    if player == LocalPlayer then return end
    if espObjects[player] then return end

    local function attach(char)
        if not char then return end
        local hrp = char:WaitForChild("HumanoidRootPart", 3)
        if not hrp then return end

        -- Remove stale billboard if character respawned
        if espObjects[player] then
            pcall(function() espObjects[player].billboard:Destroy() end)
            espObjects[player] = nil
        end

        local bb = Instance.new("BillboardGui")
        bb.Name         = "BasicHubESP"
        bb.Size         = UDim2.new(0, 130, 0, 50)
        bb.StudsOffset  = Vector3.new(0, 4, 0)
        bb.AlwaysOnTop  = true
        bb.MaxDistance  = 1200
        bb.Parent       = hrp

        -- Name label
        local nameLabel = Instance.new("TextLabel", bb)
        nameLabel.Size                  = UDim2.new(1, 0, 0.55, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3            = ESP_NORMAL_COLOR
        nameLabel.TextStrokeTransparency = 0.5
        nameLabel.TextStrokeColor3      = Color3.fromRGB(0, 0, 0)
        nameLabel.Font                  = Enum.Font.GothamBold
        nameLabel.TextSize              = 13
        nameLabel.Text                  = player.Name
        nameLabel.TextXAlignment        = Enum.TextXAlignment.Center

        -- Health bar background
        local hBG = Instance.new("Frame", bb)
        hBG.Size               = UDim2.new(0.8, 0, 0, 6)
        hBG.Position           = UDim2.new(0.1, 0, 0.7, 0)
        hBG.BackgroundColor3   = Color3.fromRGB(40, 40, 40)
        hBG.BorderSizePixel    = 0
        local hBGCorner = Instance.new("UICorner", hBG)
        hBGCorner.CornerRadius = UDim.new(1, 0)

        -- Health bar fill
        local hFill = Instance.new("Frame", hBG)
        hFill.Size             = UDim2.new(1, 0, 1, 0)
        hFill.BackgroundColor3 = Color3.fromRGB(80, 220, 80)
        hFill.BorderSizePixel  = 0
        local hFillCorner = Instance.new("UICorner", hFill)
        hFillCorner.CornerRadius = UDim.new(1, 0)

        espObjects[player] = {
            billboard   = bb,
            label       = nameLabel,
            healthBG    = hBG,
            healthFill  = hFill,
        }
    end

    if player.Character then attach(player.Character) end
    player.CharacterAdded:Connect(attach)
end

local function removeESP(player)
    if espObjects[player] then
        pcall(function() espObjects[player].billboard:Destroy() end)
        espObjects[player] = nil
    end
end

local function enableESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        buildESP(plr)
    end
end

local function disableESP()
    for plr in pairs(espObjects) do
        removeESP(plr)
    end
end

-- Update labels + health bars every frame
RunService.Heartbeat:Connect(function()
    if not espEnabled then return end
    for player, data in pairs(espObjects) do
        pcall(function()
            if not data.billboard.Parent then return end
            local char = player.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")

            -- Death Counter label
            if isInDeathCounter(char) then
                data.label.Text       = "☠ " .. player.Name .. "\n[DEATH COUNTER]"
                data.label.TextColor3 = ESP_DC_COLOR
            else
                data.label.Text       = player.Name
                data.label.TextColor3 = ESP_NORMAL_COLOR
            end

            -- Health bar
            if hum then
                local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                data.healthFill.Size = UDim2.new(pct, 0, 1, 0)
                if pct > 0.5 then
                    data.healthFill.BackgroundColor3 = Color3.fromRGB(80, 220, 80)
                elseif pct > 0.25 then
                    data.healthFill.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
                else
                    data.healthFill.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
                end
            end
        end)
    end
end)

-- Player join/leave
Players.PlayerAdded:Connect(function(plr)
    if espEnabled then buildESP(plr) end
end)
Players.PlayerRemoving:Connect(function(plr)
    removeESP(plr)
end)

-- ── ESP UI ───────────────────────────────────────────────────────────────────
espTab:CreateSection("Players")

espTab:CreateToggle({
    Name         = "Player ESP  (names + health)",
    CurrentValue = false,
    Flag         = "PlayerESP",
    Callback     = function(v)
        espEnabled = v
        if v then enableESP() else disableESP() end
    end,
})

espTab:CreateLabel("DeathCounter: ESP auto-highlights players using Saitama's ultimate in red.")

espTab:CreateDivider()
espTab:CreateSection("Death Counter ESP")
espTab:CreateLabel("Separate floating window: shows 💢 when player has Death Counter skill, ☠ after.")

-- ── Death Counter ESP Window ─────────────────────────────────────────────────
local dcEspGui = Instance.new("ScreenGui")
dcEspGui.Name           = "BH_DC_ESP"
dcEspGui.ResetOnSpawn   = false
dcEspGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() dcEspGui.Parent = game:GetService("CoreGui") end)
if not dcEspGui.Parent then dcEspGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local dcFrame = Instance.new("Frame", dcEspGui)
dcFrame.Size             = UDim2.new(0, 250, 0, 90)
dcFrame.Position         = UDim2.new(0.5, -125, 0.1, 0)
dcFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
dcFrame.BorderSizePixel  = 0
dcFrame.ClipsDescendants = true
dcFrame.Visible          = false
Instance.new("UICorner", dcFrame)

local dcTitle = Instance.new("TextLabel", dcFrame)
dcTitle.Size                   = UDim2.new(1, 0, 0, 28)
dcTitle.BackgroundTransparency = 1
dcTitle.Text                   = "ESP Death Counter"
dcTitle.TextColor3             = Color3.fromRGB(255, 80, 80)
dcTitle.Font                   = Enum.Font.GothamBold
dcTitle.TextSize               = 15

local dcToggleBtn = Instance.new("TextButton", dcFrame)
dcToggleBtn.Size             = UDim2.new(1, -20, 0, 32)
dcToggleBtn.Position         = UDim2.new(0, 10, 0, 32)
dcToggleBtn.BackgroundColor3 = Color3.fromRGB(70, 200, 100)
dcToggleBtn.TextColor3       = Color3.new(1, 1, 1)
dcToggleBtn.Font             = Enum.Font.GothamSemibold
dcToggleBtn.TextSize         = 13
dcToggleBtn.Text             = "DC ESP: ON"
Instance.new("UICorner", dcToggleBtn)

local dcColBtn = Instance.new("TextButton", dcFrame)
dcColBtn.Size             = UDim2.new(0, 22, 0, 22)
dcColBtn.Position         = UDim2.new(1, -26, 0, 3)
dcColBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
dcColBtn.TextColor3       = Color3.new(1, 1, 1)
dcColBtn.Font             = Enum.Font.GothamBold
dcColBtn.TextSize         = 16
dcColBtn.Text             = "-"
Instance.new("UICorner", dcColBtn)

-- Collapse / expand
local dcExpanded = true
dcColBtn.MouseButton1Click:Connect(function()
    if dcExpanded then
        TweenService:Create(dcFrame, TweenInfo.new(0.25), { Size = UDim2.new(0, 250, 0, 28) }):Play()
        dcColBtn.Text = "+"
        dcExpanded    = false
    else
        TweenService:Create(dcFrame, TweenInfo.new(0.25), { Size = UDim2.new(0, 250, 0, 90) }):Play()
        dcColBtn.Text = "-"
        dcExpanded    = true
    end
end)

-- DC ESP toggle
local dcEspOn = true
dcToggleBtn.MouseButton1Click:Connect(function()
    dcEspOn = not dcEspOn
    dcToggleBtn.BackgroundColor3 = dcEspOn and Color3.fromRGB(70, 200, 100) or Color3.fromRGB(100, 100, 100)
    dcToggleBtn.Text             = dcEspOn and "DC ESP: ON" or "DC ESP: OFF"
end)

-- DC ESP drag (Rayfield-style)
local dcToggle, dcDragInput, dcDragStart, dcDragStartPos = false, nil, nil, nil
local function applyDCDrag(input)
    local delta = input.Position - dcDragStart
    TweenService:Create(dcFrame, TweenInfo.new(0.025), {
        Position = UDim2.new(
            dcDragStartPos.X.Scale, dcDragStartPos.X.Offset + delta.X,
            dcDragStartPos.Y.Scale, dcDragStartPos.Y.Offset + delta.Y
        ),
    }):Play()
end
dcFrame.InputBegan:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or
        input.UserInputType == Enum.UserInputType.Touch) and
        UserInputService:GetFocusedTextBox() == nil then
        dcToggle       = true
        dcDragStart    = input.Position
        dcDragStartPos = dcFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dcToggle = false
            end
        end)
    end
end)
dcFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or
       input.UserInputType == Enum.UserInputType.Touch then
        dcDragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dcDragInput and dcToggle then
        applyDCDrag(input)
    end
end)

-- DC ESP skill detection
local dcStrongSkills = {
    ["Omni Directional Punch"] = true, ["Death Counter"] = true,
    ["Serious Punch"] = true,          ["Table Flip"]    = true,
}
local dcWeakSkills = {
    ["Consecutive Punches"] = true, ["Normal Punch"] = true,
    ["Shove"] = true, ["Uppercut"] = true,
}
local dcState = {}

local function dcCreateBillboard(char, text)
    if not (char and char:FindFirstChild("Head")) then return end
    local head = char.Head
    local bb   = head:FindFirstChild("DC_SkillTag") or Instance.new("BillboardGui")
    bb.Name        = "DC_SkillTag"
    bb.Size        = UDim2.new(0, 80, 0, 34)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.Adornee     = head
    bb.AlwaysOnTop = true
    if not bb.Parent then bb.Parent = head end
    local lbl = bb:FindFirstChild("TextLabel") or Instance.new("TextLabel", bb)
    lbl.Size                     = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency   = 1
    lbl.Font                     = Enum.Font.GothamBold
    lbl.TextScaled               = true
    lbl.TextColor3               = Color3.new(1, 1, 1)
    lbl.TextStrokeTransparency   = 0.4
    lbl.Text                     = text
end

local function dcRemoveBillboard(char)
    if char and char:FindFirstChild("Head") then
        local t = char.Head:FindFirstChild("DC_SkillTag")
        if t then t:Destroy() end
    end
end

local function dcGetSkillType(backpack)
    for _, tool in ipairs(backpack:GetChildren()) do
        if dcStrongSkills[tool.Name] then return "strong" end
        if dcWeakSkills[tool.Name]   then return "weak"   end
    end
end

RunService.Heartbeat:Connect(function()
    if not dcEspOn or not dcFrame.Visible then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char     = plr.Character
            local backpack = plr:FindFirstChildOfClass("Backpack")
            if char and backpack then
                local skillType = dcGetSkillType(backpack)
                local lastState = dcState[plr]
                if not lastState then
                    dcState[plr] = skillType
                    if skillType == "strong" then dcCreateBillboard(char, "DeathCounter")
                    else dcRemoveBillboard(char) end
                else
                    if skillType == "strong" then
                        if lastState ~= "strong" then dcCreateBillboard(char, "DeathCounter") end
                        dcState[plr] = "strong"
                    elseif skillType == "weak" and lastState == "strong" then
                        dcState[plr] = "weak"
                        dcRemoveBillboard(char)
                    end
                end
            end
        end
    end
end)

-- Player leave: clean up state
Players.PlayerRemoving:Connect(function(plr)
    dcState[plr] = nil
end)

-- Tab button to show/hide DC ESP window
local dcWindowOpen = false
espTab:CreateButton({
    Name = "Toggle DC ESP Window",
    Callback = function()
        dcWindowOpen = not dcWindowOpen
        dcFrame.Visible = dcWindowOpen
    end,
})

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
    Content = "UI Library  : Custom (BasicHub)\n"
           .. "Key System  : PlatoBoost\n"
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

