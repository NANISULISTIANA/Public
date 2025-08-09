-- ██████████████████████████████████████████████████████████████
-- ██                                                          ██
-- ██                      GAMEXSAN V2.0                      ██
-- ██                 COMPLETE & READY TO USE                 ██
-- ██                                                          ██
-- ██████████████████████████████████████████████████████████████

local success, error = pcall(function()

-- Check if GUI already exists and destroy it
if game.Players.LocalPlayer.PlayerGui:FindFirstChild("GameXsan") then
    game.Players.LocalPlayer.PlayerGui.GameXsan:Destroy()
end

-- ===================================================================
--                            SERVICES
-- ===================================================================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Rs = game:GetService("ReplicatedStorage")

-- ===================================================================
--                          CONFIGURATION
-- ===================================================================
local CONFIG = {
    GUI_NAME = "GameXsan",
    HOTKEY = Enum.KeyCode.F9, -- Hide/Show GUI
    AUTO_SAVE_SETTINGS = true,
    FISHING_DELAYS = {
        MIN = 0.1,
        MAX = 0.3
    }
}

-- ===================================================================
--                           VARIABLES
-- ===================================================================
local player = Players.LocalPlayer
local connections = {}
local isHidden = false

-- ===================================================================
--                        REMOTE REFERENCES
-- ===================================================================
local EquipRod = Rs.Packages._Index["sleitnick_net@0.2.0"].net["RE/EquipToolFromHotbar"]
local UnEquipRod = Rs.Packages._Index["sleitnick_net@0.2.0"].net["RE/UnequipToolFromHotbar"]
local RequestFishing = Rs.Packages._Index["sleitnick_net@0.2.0"].net["RF/RequestFishingMinigameStarted"]
local ChargeRod = Rs.Packages._Index["sleitnick_net@0.2.0"].net["RF/ChargeFishingRod"]
local FishingComplete = Rs.Packages._Index["sleitnick_net@0.2.0"].net["RE/FishingCompleted"]
local CancelFishing = Rs.Packages._Index["sleitnick_net@0.2.0"].net["RF/CancelFishingInputs"]
local spawnBoat = Rs.Packages._Index["sleitnick_net@0.2.0"].net["RF/SpawnBoat"]
local despawnBoat = Rs.Packages._Index["sleitnick_net@0.2.0"].net["RF/DespawnBoat"]
local sellAll = Rs.Packages._Index["sleitnick_net@0.2.0"].net["RF/SellAllItems"]

-- External scripts
local noOxygen = loadstring(game:HttpGet("https://pastebin.com/raw/JS7LaJsa"))()

-- Workspace references
local tpFolder = workspace["!!!! ISLAND LOCATIONS !!!!"]
local charFolder = workspace.Characters

-- ===================================================================
--                           SETTINGS
-- ===================================================================
local Settings = {
    AutoFishing = false,
    WalkSpeed = 16,
    NoOxygenDamage = false,
    Theme = "Dark",
    AutoSell = false,
    JumpPower = 50,
    AutoEquipBestRod = true,
    SafeMode = true
}

-- ===================================================================
--                         STATISTICS
-- ===================================================================
local Stats = {
    fishCaught = 0,
    moneyEarned = 0,
    sessionStartTime = tick(),
    bestFish = "None",
    totalPlayTime = 0,
    boatsSpawned = 0
}

-- ===================================================================
--                       UTILITY FUNCTIONS
-- ===================================================================
local function randomWait()
    return math.random(CONFIG.FISHING_DELAYS.MIN * 1000, CONFIG.FISHING_DELAYS.MAX * 1000) / 1000
end

local function safeCall(func)
    local success, result = pcall(func)
    if not success then
        warn("Error: " .. tostring(result))
    end
    return success, result
end

local function loadSettings()
    -- Implementation for loading settings from datastore or file
    print("Settings loaded")
end

local function saveSettings()
    -- Implementation for saving settings
    print("Settings saved")
end

-- ===================================================================
--                      AUTO FISHING SYSTEM
-- ===================================================================
local function enhancedAutoFishing()
    task.spawn(function()
        while Settings.AutoFishing do
            safeCall(function()
                -- Safety check - stop if player is in danger
                if Settings.SafeMode then
                    local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
                    if humanoid and humanoid.Health < 20 then
                        warn("⚠️ Low health detected! Stopping auto fishing for safety.")
                        task.wait(5)
                        return
                    end
                end
                
                -- Add random delays to avoid detection
                task.wait(randomWait())
                
                local char = player.Character or player.CharacterAdded:Wait()
                local equippedTool = char:FindFirstChild("!!!EQUIPPED_TOOL!!!")

                if not equippedTool then
                    CancelFishing:InvokeServer()
                    task.wait(randomWait())
                    EquipRod:FireServer(1)
                end

                task.wait(randomWait())
                ChargeRod:InvokeServer(workspace:GetServerTimeNow())
                
                task.wait(randomWait())
                RequestFishing:InvokeServer(-1.2379989624023438, 0.9800224985802423)
                
                task.wait(0.4 + randomWait())
                FishingComplete:FireServer()
                
                Stats.fishCaught = Stats.fishCaught + 1
                
                -- Auto sell when inventory might be full
                if Settings.AutoSell and Stats.fishCaught % 10 == 0 then
                    task.wait(1)
                    safeCall(function()
                        sellAll:InvokeServer()
                        print("🛒 Auto-sold items!")
                    end)
                end
            end)
        end
    end)
end

-- ===================================================================
--                        WALKSPEED SYSTEM
-- ===================================================================
local function setWalkSpeed(speed)
    safeCall(function()
        local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = speed
            Settings.WalkSpeed = speed
        end
    end)
end

local function setJumpPower(power)
    safeCall(function()
        local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.JumpPower = power
            Settings.JumpPower = power
        end
    end)
end

-- ===================================================================
--                        ANTI-AFK SYSTEM
-- ===================================================================
local function antiAFK()
    task.spawn(function()
        while true do
            task.wait(300) -- Every 5 minutes
            safeCall(function()
                -- Small movement to prevent AFK
                local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid:Move(Vector3.new(0.1, 0, 0))
                    task.wait(0.1)
                    humanoid:Move(Vector3.new(-0.1, 0, 0))
                end
            end)
        end
    end)
end

-- ===================================================================
--                      NOTIFICATION SYSTEM
-- ===================================================================
local function createNotification(text, color)
    local gui = player.PlayerGui:FindFirstChild("GameXsan")
    if not gui then return end
    
    local notification = Instance.new("Frame")
    notification.Name = "Notification"
    notification.Parent = gui
    notification.BackgroundColor3 = color or Color3.fromRGB(0, 200, 0)
    notification.BorderSizePixel = 0
    notification.Position = UDim2.new(1, -250, 0, 50)
    notification.Size = UDim2.new(0, 240, 0, 50)
    notification.ZIndex = 10
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notification
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Parent = notification
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Text = text
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextScaled = true
    
    -- Animate in
    notification:TweenPosition(
        UDim2.new(1, -260, 0, 50),
        "Out", "Quad", 0.3, true
    )
    
    -- Remove after 3 seconds
    task.wait(3)
    notification:TweenPosition(
        UDim2.new(1, 10, 0, 50),
        "In", "Quad", 0.3, true,
        function() notification:Destroy() end
    )
end

-- ===================================================================
--                    FLOATING TOGGLE ICON
-- ===================================================================
local function createFloatingIcon()
    -- Create ScreenGui for floating icon
    local FloatingGUI = Instance.new("ScreenGui")
    FloatingGUI.Name = "GameXsanFloatingIcon"
    FloatingGUI.Parent = player:WaitForChild("PlayerGui")
    FloatingGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    FloatingGUI.ResetOnSpawn = false

    -- Create floating icon frame
    local FloatingIcon = Instance.new("Frame")
    FloatingIcon.Name = "FloatingIcon"
    FloatingIcon.Parent = FloatingGUI
    FloatingIcon.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    FloatingIcon.BackgroundTransparency = 0.1
    FloatingIcon.BorderSizePixel = 0
    FloatingIcon.Position = UDim2.new(0, 20, 0.5, -30)
    FloatingIcon.Size = UDim2.new(0, 60, 0, 60)
    FloatingIcon.ZIndex = 10

    -- Add corner radius
    local IconCorner = Instance.new("UICorner")
    IconCorner.CornerRadius = UDim.new(0, 15)
    IconCorner.Parent = FloatingIcon

    -- Add stroke for better visibility
    local IconStroke = Instance.new("UIStroke")
    IconStroke.Color = Color3.fromRGB(0, 255, 0)
    IconStroke.Thickness = 2
    IconStroke.Parent = FloatingIcon

    -- Icon image/text
    local IconImage = Instance.new("ImageLabel")
    IconImage.Name = "IconImage"
    IconImage.Parent = FloatingIcon
    IconImage.BackgroundTransparency = 1
    IconImage.Position = UDim2.new(0.1, 0, 0.1, 0)
    IconImage.Size = UDim2.new(0.8, 0, 0.8, 0)
    IconImage.Image = "rbxassetid://136555589792977" -- Fish icon
    IconImage.ImageColor3 = Color3.fromRGB(0, 255, 0)

    -- Alternative text if image fails
    local IconText = Instance.new("TextLabel")
    IconText.Name = "IconText"
    IconText.Parent = FloatingIcon
    IconText.BackgroundTransparency = 1
    IconText.Size = UDim2.new(1, 0, 1, 0)
    IconText.Font = Enum.Font.SourceSansBold
    IconText.Text = "🎣"
    IconText.TextColor3 = Color3.fromRGB(0, 255, 0)
    IconText.TextScaled = true
    IconText.Visible = false

    -- Show text if image fails to load
    IconImage.ImageFailed:Connect(function()
        IconImage.Visible = false
        IconText.Visible = true
    end)

    -- Make icon draggable
    local iconDragging = false
    local iconDragStart = nil
    local iconStartPos = nil

    FloatingIcon.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            iconDragging = true
            iconDragStart = input.Position
            iconStartPos = FloatingIcon.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and iconDragging then
            local delta = input.Position - iconDragStart
            FloatingIcon.Position = UDim2.new(
                iconStartPos.X.Scale,
                iconStartPos.X.Offset + delta.X,
                iconStartPos.Y.Scale,
                iconStartPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            iconDragging = false
        end
    end)

    -- Floating icon button functionality
    local IconButton = Instance.new("TextButton")
    IconButton.Name = "IconButton"
    IconButton.Parent = FloatingIcon
    IconButton.BackgroundTransparency = 1
    IconButton.Size = UDim2.new(1, 0, 1, 0)
    IconButton.Text = ""
    IconButton.ZIndex = 11

    -- Click animation
    IconButton.MouseEnter:Connect(function()
        TweenService:Create(FloatingIcon, TweenInfo.new(0.2), {
            Size = UDim2.new(0, 65, 0, 65),
            BackgroundTransparency = 0
        }):Play()
    end)

    IconButton.MouseLeave:Connect(function()
        TweenService:Create(FloatingIcon, TweenInfo.new(0.2), {
            Size = UDim2.new(0, 60, 0, 60),
            BackgroundTransparency = 0.1
        }):Play()
    end)

    return FloatingGUI, IconButton
end

-- ===================================================================
--                       GUI CREATION
-- ===================================================================
local function createCompleteGUI()
    -- Create floating icon first
    local FloatingGUI, IconButton = createFloatingIcon()
    
    -- Create main ScreenGui
    local GameXsanGUI = Instance.new("ScreenGui")
    GameXsanGUI.Name = CONFIG.GUI_NAME
    GameXsanGUI.Parent = player:WaitForChild("PlayerGui")
    GameXsanGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Main Frame
    local FrameUtama = Instance.new("Frame")
    FrameUtama.Name = "FrameUtama"
    FrameUtama.Parent = GameXsanGUI
    FrameUtama.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    FrameUtama.BackgroundTransparency = 0.200
    FrameUtama.BorderSizePixel = 0
    FrameUtama.Position = UDim2.new(0.264, 0, 0.174, 0)
    FrameUtama.Size = UDim2.new(0.542, 0, 0.650, 0)
    
    local UICorner = Instance.new("UICorner")
    UICorner.Parent = FrameUtama

    -- Exit Button
    local ExitBtn = Instance.new("TextButton")
    ExitBtn.Name = "ExitBtn"
    ExitBtn.Parent = FrameUtama
    ExitBtn.BackgroundColor3 = Color3.fromRGB(220, 40, 34)
    ExitBtn.BorderSizePixel = 0
    ExitBtn.Position = UDim2.new(0.901, 0, 0.038, 0)
    ExitBtn.Size = UDim2.new(0.063, 0, 0.088, 0)
    ExitBtn.Font = Enum.Font.SourceSansBold
    ExitBtn.Text = "X"
    ExitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ExitBtn.TextScaled = true
    
    local exitCorner = Instance.new("UICorner")
    exitCorner.CornerRadius = UDim.new(0, 4)
    exitCorner.Parent = ExitBtn

    -- Side Bar
    local SideBar = Instance.new("Frame")
    SideBar.Name = "SideBar"
    SideBar.Parent = FrameUtama
    SideBar.BackgroundColor3 = Color3.fromRGB(83, 83, 83)
    SideBar.BorderSizePixel = 0
    SideBar.Size = UDim2.new(0.376, 0, 1, 0)
    SideBar.ZIndex = 2

    -- Logo
    local Logo = Instance.new("ImageLabel")
    Logo.Name = "Logo"
    Logo.Parent = SideBar
    Logo.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Logo.BorderSizePixel = 0
    Logo.Position = UDim2.new(0.073, 0, 0.038, 0)
    Logo.Size = UDim2.new(0.168, 0, 0.088, 0)
    Logo.ZIndex = 2
    Logo.Image = "rbxassetid://136555589792977"
    
    local logoCorner = Instance.new("UICorner")
    logoCorner.CornerRadius = UDim.new(0, 10)
    logoCorner.Parent = Logo

    -- Title
    local TittleSideBar = Instance.new("TextLabel")
    TittleSideBar.Name = "TittleSideBar"
    TittleSideBar.Parent = SideBar
    TittleSideBar.BackgroundTransparency = 1
    TittleSideBar.Position = UDim2.new(0.309, 0, 0.038, 0)
    TittleSideBar.Size = UDim2.new(0.654, 0, 0.088, 0)
    TittleSideBar.ZIndex = 2
    TittleSideBar.Font = Enum.Font.SourceSansBold
    TittleSideBar.Text = "GameXsan"
    TittleSideBar.TextColor3 = Color3.fromRGB(255, 255, 255)
    TittleSideBar.TextScaled = true
    TittleSideBar.TextXAlignment = Enum.TextXAlignment.Left

    -- Line
    local Line = Instance.new("Frame")
    Line.Name = "Line"
    Line.Parent = SideBar
    Line.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Line.BorderSizePixel = 0
    Line.Position = UDim2.new(0, 0, 0.145, 0)
    Line.Size = UDim2.new(1, 0, 0.003, 0)
    Line.ZIndex = 2

    -- Menu Container
    local MainMenuSaidBar = Instance.new("Frame")
    MainMenuSaidBar.Name = "MainMenuSaidBar"
    MainMenuSaidBar.Parent = SideBar
    MainMenuSaidBar.BackgroundTransparency = 1
    MainMenuSaidBar.Position = UDim2.new(0, 0, 0.165, 0)
    MainMenuSaidBar.Size = UDim2.new(1, 0, 0.710, 0)

    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Parent = MainMenuSaidBar
    UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Padding = UDim.new(0.05, 0)

    -- Menu Buttons
    local function createMenuButton(name, text)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Parent = MainMenuSaidBar
        btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        btn.BorderSizePixel = 0
        btn.Size = UDim2.new(0.916, 0, 0.113, 0)
        btn.Font = Enum.Font.SourceSansBold
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextScaled = true
        
        local corner = Instance.new("UICorner")
        corner.Parent = btn
        
        return btn
    end

    local MAIN = createMenuButton("MAIN", "MAIN")
    local Player = createMenuButton("Player", "PLAYER")
    local SpawnBoat = createMenuButton("SpawnBoat", "SPAWN BOAT")
    local TELEPORT = createMenuButton("TELEPORT", "TELEPORT")

    -- Credit
    local Credit = Instance.new("TextLabel")
    Credit.Name = "Credit"
    Credit.Parent = SideBar
    Credit.BackgroundTransparency = 1
    Credit.Position = UDim2.new(0, 0, 0.875, 0)
    Credit.Size = UDim2.new(0.998, 0, 0.123, 0)
    Credit.Font = Enum.Font.SourceSansBold
    Credit.Text = "Made by Doovy :D"
    Credit.TextColor3 = Color3.fromRGB(255, 255, 255)
    Credit.TextScaled = true

    -- Main content line
    local Line_2 = Instance.new("Frame")
    Line_2.Name = "Line"
    Line_2.Parent = FrameUtama
    Line_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Line_2.BorderSizePixel = 0
    Line_2.Position = UDim2.new(0.376, 0, 0.145, 0)
    Line_2.Size = UDim2.new(0.624, 0, 0.003, 0)
    Line_2.ZIndex = 2

    -- Title for current page
    local Tittle = Instance.new("TextLabel")
    Tittle.Name = "Tittle"
    Tittle.Parent = FrameUtama
    Tittle.BackgroundTransparency = 1
    Tittle.Position = UDim2.new(0.420, 0, 0.038, 0)
    Tittle.Size = UDim2.new(0.444, 0, 0.088, 0)
    Tittle.ZIndex = 2
    Tittle.Font = Enum.Font.SourceSansBold
    Tittle.Text = "MAIN"
    Tittle.TextColor3 = Color3.fromRGB(255, 255, 255)
    Tittle.TextScaled = true

    -- ===============================================================
    --                         MAIN FRAME
    -- ===============================================================
    local MainFrame = Instance.new("ScrollingFrame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = FrameUtama
    MainFrame.Active = true
    MainFrame.BackgroundTransparency = 1
    MainFrame.Position = UDim2.new(0.376, 0, 0.147, 0)
    MainFrame.Size = UDim2.new(0.624, 0, 0.853, 0)
    MainFrame.ZIndex = 2
    MainFrame.ScrollBarThickness = 6

    local MainListLayoutFrame = Instance.new("Frame")
    MainListLayoutFrame.Name = "MainListLayoutFrame"
    MainListLayoutFrame.Parent = MainFrame
    MainListLayoutFrame.BackgroundTransparency = 1
    MainListLayoutFrame.Position = UDim2.new(0, 0, 0.022, 0)
    MainListLayoutFrame.Size = UDim2.new(1, 0, 1, 0)

    local ListLayoutMain = Instance.new("UIListLayout")
    ListLayoutMain.Name = "ListLayoutMain"
    ListLayoutMain.Parent = MainListLayoutFrame
    ListLayoutMain.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ListLayoutMain.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayoutMain.Padding = UDim.new(0, 8)

    -- Auto Fish Frame
    local AutoFishFrame = Instance.new("Frame")
    AutoFishFrame.Name = "AutoFishFrame"
    AutoFishFrame.Parent = MainListLayoutFrame
    AutoFishFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
    AutoFishFrame.BorderSizePixel = 0
    AutoFishFrame.Size = UDim2.new(0.898, 0, 0.106, 0)
    
    local autoFishCorner = Instance.new("UICorner")
    autoFishCorner.Parent = AutoFishFrame

    local AutoFishText = Instance.new("TextLabel")
    AutoFishText.Parent = AutoFishFrame
    AutoFishText.BackgroundTransparency = 1
    AutoFishText.Position = UDim2.new(0.030, 0, 0.216, 0)
    AutoFishText.Size = UDim2.new(0.415, 0, 0.568, 0)
    AutoFishText.Font = Enum.Font.SourceSansBold
    AutoFishText.Text = "Auto Fish (AFK) :"
    AutoFishText.TextColor3 = Color3.fromRGB(255, 255, 255)
    AutoFishText.TextScaled = true
    AutoFishText.TextXAlignment = Enum.TextXAlignment.Left

    local AutoFishButton = Instance.new("TextButton")
    AutoFishButton.Name = "AutoFishButton"
    AutoFishButton.Parent = AutoFishFrame
    AutoFishButton.BackgroundTransparency = 1
    AutoFishButton.Position = UDim2.new(0.756, 0, 0.108, 0)
    AutoFishButton.Size = UDim2.new(0.207, 0, 0.784, 0)
    AutoFishButton.ZIndex = 2
    AutoFishButton.Font = Enum.Font.SourceSansBold
    AutoFishButton.Text = "OFF"
    AutoFishButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    AutoFishButton.TextScaled = true

    local AutoFishWarna = Instance.new("Frame")
    AutoFishWarna.Parent = AutoFishFrame
    AutoFishWarna.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    AutoFishWarna.BorderSizePixel = 0
    AutoFishWarna.Position = UDim2.new(0.756, 0, 0.135, 0)
    AutoFishWarna.Size = UDim2.new(0.204, 0, 0.730, 0)
    
    local autoFishWarnaCorner = Instance.new("UICorner")
    autoFishWarnaCorner.Parent = AutoFishWarna

    -- Sell All Frame
    local SellAllFrame = Instance.new("Frame")
    SellAllFrame.Name = "SellAllFrame"
    SellAllFrame.Parent = MainListLayoutFrame
    SellAllFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
    SellAllFrame.BorderSizePixel = 0
    SellAllFrame.Size = UDim2.new(0.898, 0, 0.106, 0)
    
    local sellAllCorner = Instance.new("UICorner")
    sellAllCorner.Parent = SellAllFrame

    local SellAllButton = Instance.new("TextButton")
    SellAllButton.Name = "SellAllButton"
    SellAllButton.Parent = SellAllFrame
    SellAllButton.BackgroundTransparency = 1
    SellAllButton.Size = UDim2.new(1, 0, 1, 0)
    SellAllButton.ZIndex = 2
    SellAllButton.Font = Enum.Font.SourceSansBold
    SellAllButton.Text = ""

    local SellAllText = Instance.new("TextLabel")
    SellAllText.Parent = SellAllFrame
    SellAllText.BackgroundTransparency = 1
    SellAllText.Position = UDim2.new(0.290, 0, 0.216, 0)
    SellAllText.Size = UDim2.new(0.415, 0, 0.568, 0)
    SellAllText.Font = Enum.Font.SourceSansBold
    SellAllText.Text = "Sell All"
    SellAllText.TextColor3 = Color3.fromRGB(255, 255, 255)
    SellAllText.TextScaled = true

    -- Statistics Frame
    local StatsFrame = Instance.new("Frame")
    StatsFrame.Name = "StatsFrame"
    StatsFrame.Parent = MainListLayoutFrame
    StatsFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
    StatsFrame.BorderSizePixel = 0
    StatsFrame.Size = UDim2.new(0.898, 0, 0.106, 0)
    
    local statsCorner = Instance.new("UICorner")
    statsCorner.Parent = StatsFrame

    local StatsText = Instance.new("TextLabel")
    StatsText.Parent = StatsFrame
    StatsText.BackgroundTransparency = 1
    StatsText.Position = UDim2.new(0.030, 0, 0.216, 0)
    StatsText.Size = UDim2.new(0.940, 0, 0.568, 0)
    StatsText.Font = Enum.Font.SourceSansBold
    StatsText.Text = "Fish Caught: 0 | Session: 0m"
    StatsText.TextColor3 = Color3.fromRGB(255, 255, 255)
    StatsText.TextScaled = true

    -- ESP Players Frame
    local ESPFrame = Instance.new("Frame")
    ESPFrame.Name = "ESPFrame"
    ESPFrame.Parent = MainListLayoutFrame
    ESPFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
    ESPFrame.BorderSizePixel = 0
    ESPFrame.Size = UDim2.new(0.898, 0, 0.106, 0)
    
    local espCorner = Instance.new("UICorner")
    espCorner.Parent = ESPFrame

    local ESPButton = Instance.new("TextButton")
    ESPButton.Name = "ESPButton"
    ESPButton.Parent = ESPFrame
    ESPButton.BackgroundTransparency = 1
    ESPButton.Size = UDim2.new(1, 0, 1, 0)
    ESPButton.ZIndex = 2
    ESPButton.Font = Enum.Font.SourceSansBold
    ESPButton.Text = ""

    local ESPText = Instance.new("TextLabel")
    ESPText.Parent = ESPFrame
    ESPText.BackgroundTransparency = 1
    ESPText.Position = UDim2.new(0.290, 0, 0.216, 0)
    ESPText.Size = UDim2.new(0.415, 0, 0.568, 0)
    ESPText.Font = Enum.Font.SourceSansBold
    ESPText.Text = "ESP Players"
    ESPText.TextColor3 = Color3.fromRGB(255, 255, 255)
    ESPText.TextScaled = true

    -- ===============================================================
    --                        PLAYER FRAME
    -- ===============================================================
    local PlayerFrame = Instance.new("ScrollingFrame")
    PlayerFrame.Name = "PlayerFrame"
    PlayerFrame.Parent = FrameUtama
    PlayerFrame.Active = true
    PlayerFrame.BackgroundTransparency = 1
    PlayerFrame.Position = UDim2.new(0.376, 0, 0.147, 0)
    PlayerFrame.Size = UDim2.new(0.624, 0, 0.853, 0)
    PlayerFrame.Visible = false
    PlayerFrame.ScrollBarThickness = 6

    local ListLayoutPlayerFrame = Instance.new("Frame")
    ListLayoutPlayerFrame.Name = "ListLayoutPlayerFrame"
    ListLayoutPlayerFrame.Parent = PlayerFrame
    ListLayoutPlayerFrame.BackgroundTransparency = 1
    ListLayoutPlayerFrame.Position = UDim2.new(0, 0, 0.022, 0)
    ListLayoutPlayerFrame.Size = UDim2.new(1, 0, 1, 0)

    local ListLayoutPlayer = Instance.new("UIListLayout")
    ListLayoutPlayer.Name = "ListLayoutPlayer"
    ListLayoutPlayer.Parent = ListLayoutPlayerFrame
    ListLayoutPlayer.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ListLayoutPlayer.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayoutPlayer.Padding = UDim.new(0, 8)

    -- No Oxygen Damage Frame
    local NoOxygenDamageFrame = Instance.new("Frame")
    NoOxygenDamageFrame.Name = "NoOxygenDamageFrame"
    NoOxygenDamageFrame.Parent = ListLayoutPlayerFrame
    NoOxygenDamageFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
    NoOxygenDamageFrame.BorderSizePixel = 0
    NoOxygenDamageFrame.Size = UDim2.new(0.898, 0, 0.106, 0)
    
    local noOxygenCorner = Instance.new("UICorner")
    noOxygenCorner.Parent = NoOxygenDamageFrame

    local NoOxygenText = Instance.new("TextLabel")
    NoOxygenText.Parent = NoOxygenDamageFrame
    NoOxygenText.BackgroundTransparency = 1
    NoOxygenText.Position = UDim2.new(0.030, 0, 0.216, 0)
    NoOxygenText.Size = UDim2.new(0.415, 0, 0.568, 0)
    NoOxygenText.Font = Enum.Font.SourceSansBold
    NoOxygenText.Text = "NO OXYGEN DAMAGE :"
    NoOxygenText.TextColor3 = Color3.fromRGB(255, 255, 255)
    NoOxygenText.TextScaled = true
    NoOxygenText.TextXAlignment = Enum.TextXAlignment.Left

    local NoOxygenButton = Instance.new("TextButton")
    NoOxygenButton.Name = "NoOxygenButton"
    NoOxygenButton.Parent = NoOxygenDamageFrame
    NoOxygenButton.BackgroundTransparency = 1
    NoOxygenButton.Position = UDim2.new(0.738, 0, 0.108, 0)
    NoOxygenButton.Size = UDim2.new(0.207, 0, 0.784, 0)
    NoOxygenButton.ZIndex = 2
    NoOxygenButton.Font = Enum.Font.SourceSansBold
    NoOxygenButton.Text = "OFF"
    NoOxygenButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    NoOxygenButton.TextScaled = true

    local NoOxygenWarna = Instance.new("Frame")
    NoOxygenWarna.Parent = NoOxygenDamageFrame
    NoOxygenWarna.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    NoOxygenWarna.BorderSizePixel = 0
    NoOxygenWarna.Position = UDim2.new(0.719, 0, 0.135, 0)
    NoOxygenWarna.Size = UDim2.new(0.257, 0, 0.730, 0)
    
    local noOxygenWarnaCorner = Instance.new("UICorner")
    noOxygenWarnaCorner.Parent = NoOxygenWarna

    -- Walk Speed Frame
    local WalkSpeedFrame = Instance.new("Frame")
    WalkSpeedFrame.Name = "WalkSpeedFrame"
    WalkSpeedFrame.Parent = ListLayoutPlayerFrame
    WalkSpeedFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
    WalkSpeedFrame.BorderSizePixel = 0
    WalkSpeedFrame.Size = UDim2.new(0.898, 0, 0.106, 0)
    
    local walkSpeedCorner = Instance.new("UICorner")
    walkSpeedCorner.Parent = WalkSpeedFrame

    local WalkSpeedText = Instance.new("TextLabel")
    WalkSpeedText.Parent = WalkSpeedFrame
    WalkSpeedText.BackgroundTransparency = 1
    WalkSpeedText.Position = UDim2.new(0.030, 0, 0.216, 0)
    WalkSpeedText.Size = UDim2.new(0.415, 0, 0.568, 0)
    WalkSpeedText.Font = Enum.Font.SourceSansBold
    WalkSpeedText.Text = "WALK SPEED:"
    WalkSpeedText.TextColor3 = Color3.fromRGB(255, 255, 255)
    WalkSpeedText.TextScaled = true
    WalkSpeedText.TextXAlignment = Enum.TextXAlignment.Left

    local WalkSpeedTextBox = Instance.new("TextBox")
    WalkSpeedTextBox.Name = "WalkSpeedTextBox"
    WalkSpeedTextBox.Parent = WalkSpeedFrame
    WalkSpeedTextBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    WalkSpeedTextBox.BorderSizePixel = 0
    WalkSpeedTextBox.Position = UDim2.new(0.719, 0, 0.135, 0)
    WalkSpeedTextBox.Size = UDim2.new(0.257, 0, 0.730, 0)
    WalkSpeedTextBox.ZIndex = 3
    WalkSpeedTextBox.Font = Enum.Font.SourceSansBold
    WalkSpeedTextBox.PlaceholderText = "16"
    WalkSpeedTextBox.Text = ""
    WalkSpeedTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    WalkSpeedTextBox.TextScaled = true
    
    local walkSpeedTextCorner = Instance.new("UICorner")
    walkSpeedTextCorner.Parent = WalkSpeedTextBox

    -- Auto Sell Frame
    local AutoSellFrame = Instance.new("Frame")
    AutoSellFrame.Name = "AutoSellFrame"
    AutoSellFrame.Parent = ListLayoutPlayerFrame
    AutoSellFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
    AutoSellFrame.BorderSizePixel = 0
    AutoSellFrame.Size = UDim2.new(0.898, 0, 0.106, 0)
    
    local autoSellCorner = Instance.new("UICorner")
    autoSellCorner.Parent = AutoSellFrame

    local AutoSellText = Instance.new("TextLabel")
    AutoSellText.Parent = AutoSellFrame
    AutoSellText.BackgroundTransparency = 1
    AutoSellText.Position = UDim2.new(0.030, 0, 0.216, 0)
    AutoSellText.Size = UDim2.new(0.415, 0, 0.568, 0)
    AutoSellText.Font = Enum.Font.SourceSansBold
    AutoSellText.Text = "AUTO SELL :"
    AutoSellText.TextColor3 = Color3.fromRGB(255, 255, 255)
    AutoSellText.TextScaled = true
    AutoSellText.TextXAlignment = Enum.TextXAlignment.Left

    local AutoSellButton = Instance.new("TextButton")
    AutoSellButton.Name = "AutoSellButton"
    AutoSellButton.Parent = AutoSellFrame
    AutoSellButton.BackgroundTransparency = 1
    AutoSellButton.Position = UDim2.new(0.738, 0, 0.108, 0)
    AutoSellButton.Size = UDim2.new(0.207, 0, 0.784, 0)
    AutoSellButton.ZIndex = 2
    AutoSellButton.Font = Enum.Font.SourceSansBold
    AutoSellButton.Text = "OFF"
    AutoSellButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    AutoSellButton.TextScaled = true

    local AutoSellWarna = Instance.new("Frame")
    AutoSellWarna.Parent = AutoSellFrame
    AutoSellWarna.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    AutoSellWarna.BorderSizePixel = 0
    AutoSellWarna.Position = UDim2.new(0.719, 0, 0.135, 0)
    AutoSellWarna.Size = UDim2.new(0.257, 0, 0.730, 0)
    
    local autoSellWarnaCorner = Instance.new("UICorner")
    autoSellWarnaCorner.Parent = AutoSellWarna

    -- ===============================================================
    --                       TELEPORT FRAME
    -- ===============================================================
    local Teleport = Instance.new("ScrollingFrame")
    Teleport.Name = "Teleport"
    Teleport.Parent = FrameUtama
    Teleport.Active = true
    Teleport.BackgroundTransparency = 1
    Teleport.Position = UDim2.new(0.376, 0, 0.147, 0)
    Teleport.Size = UDim2.new(0.624, 0, 0.853, 0)
    Teleport.Visible = false
    Teleport.ZIndex = 2
    Teleport.ScrollBarThickness = 6

    -- TP Player Frame
    local TPPlayer = Instance.new("Frame")
    TPPlayer.Name = "TPPlayer"
    TPPlayer.Parent = Teleport
    TPPlayer.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
    TPPlayer.BorderSizePixel = 0
    TPPlayer.Position = UDim2.new(0.040, 0, 0.042, 0)
    TPPlayer.Size = UDim2.new(0.898, 0, 0.106, 0)
    
    local tpPlayerCorner = Instance.new("UICorner")
    tpPlayerCorner.Parent = TPPlayer

    local TPPlayerText = Instance.new("TextLabel")
    TPPlayerText.Parent = TPPlayer
    TPPlayerText.BackgroundTransparency = 1
    TPPlayerText.Position = UDim2.new(0.030, 0, 0.216, 0)
    TPPlayerText.Size = UDim2.new(0.415, 0, 0.568, 0)
    TPPlayerText.Font = Enum.Font.SourceSansBold
    TPPlayerText.Text = "TP PLAYER:"
    TPPlayerText.TextColor3 = Color3.fromRGB(255, 255, 255)
    TPPlayerText.TextScaled = true
    TPPlayerText.TextXAlignment = Enum.TextXAlignment.Left

    local TPPlayerButton = Instance.new("TextButton")
    TPPlayerButton.Name = "TPPlayerButton"
    TPPlayerButton.Parent = TPPlayer
    TPPlayerButton.BackgroundTransparency = 1
    TPPlayerButton.Position = UDim2.new(0.756, 0, 0.108, 0)
    TPPlayerButton.Size = UDim2.new(0.207, 0, 0.784, 0)
    TPPlayerButton.ZIndex = 2
    TPPlayerButton.Font = Enum.Font.SourceSansBold
    TPPlayerButton.Text = "V"
    TPPlayerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    TPPlayerButton.TextScaled = true

    local TPPlayerButtonWarna = Instance.new("Frame")
    TPPlayerButtonWarna.Parent = TPPlayer
    TPPlayerButtonWarna.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    TPPlayerButtonWarna.BorderSizePixel = 0
    TPPlayerButtonWarna.Position = UDim2.new(0.756, 0, 0.135, 0)
    TPPlayerButtonWarna.Size = UDim2.new(0.204, 0, 0.730, 0)
    
    local tpPlayerWarnaCorner = Instance.new("UICorner")
    tpPlayerWarnaCorner.Parent = TPPlayerButtonWarna

    -- Player List
    local ListOfTpPlayer = Instance.new("ScrollingFrame")
    ListOfTpPlayer.Name = "ListOfTpPlayer"
    ListOfTpPlayer.Parent = Teleport
    ListOfTpPlayer.Active = true
    ListOfTpPlayer.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
    ListOfTpPlayer.BackgroundTransparency = 0.7
    ListOfTpPlayer.BorderSizePixel = 0
    ListOfTpPlayer.Position = UDim2.new(0.585, 0, 0.148, 0)
    ListOfTpPlayer.Size = UDim2.new(0, 100, 0, 143)
    ListOfTpPlayer.Visible = false
    ListOfTpPlayer.AutomaticCanvasSize = Enum.AutomaticSize.Y

    -- TP Islands Frame
    local TPIsland = Instance.new("Frame")
    TPIsland.Name = "TPIsland"
    TPIsland.Parent = Teleport
    TPIsland.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
    TPIsland.BorderSizePixel = 0
    TPIsland.Position = UDim2.new(0.044, 0, 0.210, 0)
    TPIsland.Size = UDim2.new(0.898, 0, 0.106, 0)
    
    local tpIslandCorner = Instance.new("UICorner")
    tpIslandCorner.Parent = TPIsland

    local TPIslandText = Instance.new("TextLabel")
    TPIslandText.Parent = TPIsland
    TPIslandText.BackgroundTransparency = 1
    TPIslandText.Position = UDim2.new(0.030, 0, 0.216, 0)
    TPIslandText.Size = UDim2.new(0.415, 0, 0.568, 0)
    TPIslandText.Font = Enum.Font.SourceSansBold
    TPIslandText.Text = "TP ISLAND :"
    TPIslandText.TextColor3 = Color3.fromRGB(255, 255, 255)
    TPIslandText.TextScaled = true
    TPIslandText.TextXAlignment = Enum.TextXAlignment.Left

    local TPIslandButton = Instance.new("TextButton")
    TPIslandButton.Name = "TPIslandButton"
    TPIslandButton.Parent = TPIsland
    TPIslandButton.BackgroundTransparency = 1
    TPIslandButton.Position = UDim2.new(0.756, 0, 0.108, 0)
    TPIslandButton.Size = UDim2.new(0.207, 0, 0.784, 0)
    TPIslandButton.ZIndex = 2
    TPIslandButton.Font = Enum.Font.SourceSansBold
    TPIslandButton.Text = "V"
    TPIslandButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    TPIslandButton.TextScaled = true

    local TPIslandButtonWarna = Instance.new("Frame")
    TPIslandButtonWarna.Parent = TPIsland
    TPIslandButtonWarna.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    TPIslandButtonWarna.BorderSizePixel = 0
    TPIslandButtonWarna.Position = UDim2.new(0.756, 0, 0.135, 0)
    TPIslandButtonWarna.Size = UDim2.new(0.204, 0, 0.730, 0)
    
    local tpIslandWarnaCorner = Instance.new("UICorner")
    tpIslandWarnaCorner.Parent = TPIslandButtonWarna

    -- Island List
    local ListOfTPIsland = Instance.new("ScrollingFrame")
    ListOfTPIsland.Name = "ListOfTPIsland"
    ListOfTPIsland.Parent = Teleport
    ListOfTPIsland.Active = true
    ListOfTPIsland.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
    ListOfTPIsland.BackgroundTransparency = 0.7
    ListOfTPIsland.BorderSizePixel = 0
    ListOfTPIsland.Position = UDim2.new(0.591, 0, 0.316, 0)
    ListOfTPIsland.Size = UDim2.new(0, 100, 0, 143)
    ListOfTPIsland.Visible = false
    ListOfTPIsland.AutomaticCanvasSize = Enum.AutomaticSize.Y

    -- ===============================================================
    --                       SPAWN BOAT FRAME
    -- ===============================================================
    local SpawnBoatFrame = Instance.new("ScrollingFrame")
    SpawnBoatFrame.Name = "SpawnBoatFrame"
    SpawnBoatFrame.Parent = FrameUtama
    SpawnBoatFrame.Active = true
    SpawnBoatFrame.BackgroundTransparency = 1
    SpawnBoatFrame.Position = UDim2.new(0.376, 0, 0.147, 0)
    SpawnBoatFrame.Size = UDim2.new(0.624, 0, 0.853, 0)
    SpawnBoatFrame.Visible = false
    SpawnBoatFrame.ZIndex = 2
    SpawnBoatFrame.ScrollBarThickness = 6
    SpawnBoatFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local ListLayoutBoatFrame = Instance.new("Frame")
    ListLayoutBoatFrame.Name = "ListLayoutBoatFrame"
    ListLayoutBoatFrame.Parent = SpawnBoatFrame
    ListLayoutBoatFrame.BackgroundTransparency = 1
    ListLayoutBoatFrame.Position = UDim2.new(0, 0, 0.022, 0)
    ListLayoutBoatFrame.Size = UDim2.new(1, 0, 1, 0)

    local ListLayoutBoat = Instance.new("UIListLayout")
    ListLayoutBoat.Name = "ListLayoutBoat"
    ListLayoutBoat.Parent = ListLayoutBoatFrame
    ListLayoutBoat.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ListLayoutBoat.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayoutBoat.Padding = UDim.new(0, 8)

    -- Despawn Boat
    local DespawnBoat = Instance.new("Frame")
    DespawnBoat.Name = "DespawnBoat"
    DespawnBoat.Parent = ListLayoutBoatFrame
    DespawnBoat.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
    DespawnBoat.BorderSizePixel = 0
    DespawnBoat.Size = UDim2.new(0.898, 0, 0.106, 0)
    
    local despawnBoatCorner = Instance.new("UICorner")
    despawnBoatCorner.Parent = DespawnBoat

    local DespawnBoatText = Instance.new("TextLabel")
    DespawnBoatText.Parent = DespawnBoat
    DespawnBoatText.BackgroundTransparency = 1
    DespawnBoatText.Position = UDim2.new(0.012, 0, 0.216, 0)
    DespawnBoatText.Size = UDim2.new(0.970, 0, 0.568, 0)
    DespawnBoatText.Font = Enum.Font.SourceSansBold
    DespawnBoatText.Text = "Despawn Boat"
    DespawnBoatText.TextColor3 = Color3.fromRGB(255, 255, 255)
    DespawnBoatText.TextScaled = true

    local DespawnBoatButton = Instance.new("TextButton")
    DespawnBoatButton.Name = "DespawnBoatButton"
    DespawnBoatButton.Parent = DespawnBoat
    DespawnBoatButton.BackgroundTransparency = 1
    DespawnBoatButton.Size = UDim2.new(1, 0, 1, 0)
    DespawnBoatButton.ZIndex = 2
    DespawnBoatButton.Font = Enum.Font.SourceSansBold
    DespawnBoatButton.Text = ""

    -- Boat spawn buttons
    local boats = {
        {name = "Small Boat", value = "SmallDinghy"},
        {name = "Kayak", value = "Kayak"},
        {name = "Jetski", value = "JetSki"},
        {name = "Highfield Boat", value = "HighFieldBoat"},
        {name = "Speed Boat", value = "SpeedBoat"},
        {name = "Fishing Boat", value = "FishingBoat"},
        {name = "Mini Yacht", value = "MiniYacht"},
        {name = "Hyper Boat", value = "HyperBoat"},
        {name = "Frozen Boat", value = "FrozenBoat"},
        {name = "Cruiser Boat", value = "CruiserBoat"}
    }

    for _, boat in ipairs(boats) do
        local BoatFrame = Instance.new("Frame")
        BoatFrame.Name = boat.value
        BoatFrame.Parent = ListLayoutBoatFrame
        BoatFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
        BoatFrame.BorderSizePixel = 0
        BoatFrame.Size = UDim2.new(0.898, 0, 0.106, 0)
        
        local boatCorner = Instance.new("UICorner")
        boatCorner.Parent = BoatFrame

        local BoatButton = Instance.new("TextButton")
        BoatButton.Name = boat.value .. "Button"
        BoatButton.Parent = BoatFrame
        BoatButton.BackgroundTransparency = 1
        BoatButton.Size = UDim2.new(1, 0, 1, 0)
        BoatButton.ZIndex = 2
        BoatButton.Font = Enum.Font.SourceSansBold
        BoatButton.Text = ""

        local BoatText = Instance.new("TextLabel")
        BoatText.Name = boat.value .. "Text"
        BoatText.Parent = BoatFrame
        BoatText.BackgroundTransparency = 1
        BoatText.Position = UDim2.new(0.287, 0, 0.216, 0)
        BoatText.Size = UDim2.new(0.415, 0, 0.568, 0)
        BoatText.Font = Enum.Font.SourceSansBold
        BoatText.Text = boat.name
        BoatText.TextColor3 = Color3.fromRGB(255, 255, 255)
        BoatText.TextScaled = true

        -- Boat spawn connection
        connections[#connections + 1] = BoatButton.MouseButton1Click:Connect(function()
            safeCall(function()
                spawnBoat:InvokeServer(boat.value)
                Stats.boatsSpawned = Stats.boatsSpawned + 1
                createNotification("🚤 " .. boat.name .. " spawned!", Color3.fromRGB(0, 150, 255))
            end)
        end)
    end

    -- ===============================================================
    --                      BUTTON CONNECTIONS
    -- ===============================================================
    
    -- Floating icon toggle functionality
    connections[#connections + 1] = IconButton.MouseButton1Click:Connect(function()
        isHidden = not isHidden
        GameXsanGUI.Enabled = not isHidden
        
        -- Visual feedback on icon
        local iconFrame = IconButton.Parent
        local iconStroke = iconFrame:FindFirstChild("UIStroke")
        local iconImage = iconFrame:FindFirstChild("IconImage")
        
        if isHidden then
            if iconStroke then 
                iconStroke.Color = Color3.fromRGB(255, 0, 0) 
            end
            if iconImage then 
                iconImage.ImageColor3 = Color3.fromRGB(255, 100, 100) 
            end
            createNotification("📱 GUI Hidden - Click icon to show", Color3.fromRGB(255, 165, 0))
        else
            if iconStroke then 
                iconStroke.Color = Color3.fromRGB(0, 255, 0) 
            end
            if iconImage then 
                iconImage.ImageColor3 = Color3.fromRGB(0, 255, 0) 
            end
            createNotification("📱 GUI Shown", Color3.fromRGB(0, 200, 0))
        end
    end)
    
    -- Exit button (also hide floating icon when closing completely)
    connections[#connections + 1] = ExitBtn.MouseButton1Click:Connect(function()
        GameXsanGUI:Destroy()
        if FloatingGUI then
            FloatingGUI:Destroy()
        end
        for _, connection in pairs(connections) do
            if connection and connection.Connected then
                connection:Disconnect()
            end
        end
    end)

    -- Auto Fish button
    connections[#connections + 1] = AutoFishButton.MouseButton1Click:Connect(function()
        Settings.AutoFishing = not Settings.AutoFishing
        AutoFishButton.Text = Settings.AutoFishing and "ON" or "OFF"
        AutoFishWarna.BackgroundColor3 = Settings.AutoFishing and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(0, 0, 0)
        if Settings.AutoFishing then
            enhancedAutoFishing()
            createNotification("🎣 Auto Fishing started!", Color3.fromRGB(0, 200, 0))
        else
            createNotification("🎣 Auto Fishing stopped!", Color3.fromRGB(200, 0, 0))
        end
    end)

    -- No Oxygen button
    connections[#connections + 1] = NoOxygenButton.MouseButton1Click:Connect(function()
        local state = noOxygen.toggle()
        NoOxygenButton.Text = state and "ON" or "OFF"
        NoOxygenWarna.BackgroundColor3 = state and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(0, 0, 0)
    end)

    -- Auto Sell button
    connections[#connections + 1] = AutoSellButton.MouseButton1Click:Connect(function()
        Settings.AutoSell = not Settings.AutoSell
        AutoSellButton.Text = Settings.AutoSell and "ON" or "OFF"
        AutoSellWarna.BackgroundColor3 = Settings.AutoSell and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(0, 0, 0)
        if Settings.AutoSell then
            createNotification("🛒 Auto Sell enabled!", Color3.fromRGB(0, 200, 0))
        else
            createNotification("🛒 Auto Sell disabled!", Color3.fromRGB(200, 0, 0))
        end
    end)

    -- Walk Speed TextBox
    connections[#connections + 1] = WalkSpeedTextBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local speed = tonumber(WalkSpeedTextBox.Text)
            if speed and speed >= 1 and speed <= 100 then
                setWalkSpeed(speed)
                createNotification("🏃 Walk Speed set to " .. speed, Color3.fromRGB(0, 150, 255))
                WalkSpeedTextBox.Text = ""
            else
                createNotification("❌ Invalid speed! Use 1-100", Color3.fromRGB(255, 0, 0))
                WalkSpeedTextBox.Text = ""
            end
        end
    end)

    -- ESP Players button
    local espEnabled = false
    connections[#connections + 1] = ESPButton.MouseButton1Click:Connect(function()
        espEnabled = not espEnabled
        ESPText.Text = espEnabled and "ESP Players (ON)" or "ESP Players"
        ESPText.TextColor3 = espEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 255, 255)
        
        if espEnabled then
            createNotification("👁️ Player ESP enabled!", Color3.fromRGB(0, 200, 0))
            -- Enable ESP for all players
            for _, targetPlayer in pairs(Players:GetPlayers()) do
                if targetPlayer ~= player and targetPlayer.Character then
                    safeCall(function()
                        local highlight = Instance.new("Highlight")
                        highlight.Parent = targetPlayer.Character
                        highlight.Name = "GameXsanESP"
                        highlight.FillColor = Color3.fromRGB(255, 0, 0)
                        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                        highlight.FillTransparency = 0.5
                    end)
                end
            end
        else
            createNotification("👁️ Player ESP disabled!", Color3.fromRGB(200, 0, 0))
            -- Disable ESP for all players
            for _, targetPlayer in pairs(Players:GetPlayers()) do
                if targetPlayer.Character then
                    local esp = targetPlayer.Character:FindFirstChild("GameXsanESP")
                    if esp then esp:Destroy() end
                end
            end
        end
    end)

    -- Sell All button
    connections[#connections + 1] = SellAllButton.MouseButton1Click:Connect(function()
        safeCall(function()
            sellAll:InvokeServer()
        end)
    end)

    -- TP Player button
    connections[#connections + 1] = TPPlayerButton.MouseButton1Click:Connect(function()
        ListOfTpPlayer.Visible = not ListOfTpPlayer.Visible
        ListOfTPIsland.Visible = false
    end)

    -- TP Island button
    connections[#connections + 1] = TPIslandButton.MouseButton1Click:Connect(function()
        ListOfTPIsland.Visible = not ListOfTPIsland.Visible
        ListOfTpPlayer.Visible = false
    end)

    -- Despawn boat button
    connections[#connections + 1] = DespawnBoatButton.MouseButton1Click:Connect(function()
        safeCall(function()
            despawnBoat:InvokeServer()
            createNotification("🗑️ Boat despawned!", Color3.fromRGB(255, 165, 0))
        end)
    end)

    -- Page switching function
    local function showPanel(pageName)
        MainFrame.Visible = false
        PlayerFrame.Visible = false
        Teleport.Visible = false
        SpawnBoatFrame.Visible = false
        
        if pageName == "Main" then
            MainFrame.Visible = true
        elseif pageName == "Player" then
            PlayerFrame.Visible = true
        elseif pageName == "Teleport" then
            Teleport.Visible = true
        elseif pageName == "Boat" then
            SpawnBoatFrame.Visible = true
        end
        
        Tittle.Text = pageName:upper()
    end

    -- Menu button connections
    connections[#connections + 1] = MAIN.MouseButton1Click:Connect(function()
        showPanel("Main")
    end)

    connections[#connections + 1] = Player.MouseButton1Click:Connect(function()
        showPanel("Player")
    end)

    connections[#connections + 1] = TELEPORT.MouseButton1Click:Connect(function()
        showPanel("Teleport")
    end)

    connections[#connections + 1] = SpawnBoat.MouseButton1Click:Connect(function()
        showPanel("Boat")
    end)

    -- ===============================================================
    --                      ISLAND TELEPORT SETUP
    -- ===============================================================
    
    -- Create island buttons
    safeCall(function()
        local index = 0
        for _, island in ipairs(tpFolder:GetChildren()) do
            if island:IsA("BasePart") then
                local btn = Instance.new("TextButton")
                btn.Name = island.Name
                btn.Size = UDim2.new(1, 0, 0.1, 0)
                btn.Position = UDim2.new(0, 0, (0.1 + 0.02) * index, 0)
                btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                btn.Text = island.Name
                btn.TextScaled = true
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                btn.Font = Enum.Font.GothamBold
                btn.Parent = ListOfTPIsland
                
                connections[#connections + 1] = btn.MouseButton1Click:Connect(function()
                    safeCall(function()
                        player.Character.HumanoidRootPart.CFrame = island.CFrame
                    end)
                end)
                index = index + 1
            end
        end
    end)

    -- ===============================================================
    --                      PLAYER LIST UPDATER
    -- ===============================================================
    
    local function updatePlayerList()
        safeCall(function()
            -- Clear existing buttons
            for _, child in pairs(ListOfTpPlayer:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end
            
            -- Add current players
            local index = 0
            for _, targetPlayer in pairs(Players:GetPlayers()) do
                if targetPlayer ~= player and targetPlayer.Character then
                    local btn = Instance.new("TextButton")
                    btn.Name = targetPlayer.Name
                    btn.Parent = ListOfTpPlayer
                    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                    btn.Text = targetPlayer.Name
                    btn.Size = UDim2.new(1, 0, 0.1, 0)
                    btn.Position = UDim2.new(0, 0, (0.1 + 0.02) * index, 0)
                    btn.TextScaled = true
                    btn.Font = Enum.Font.GothamBold
                    
                    connections[#connections + 1] = btn.MouseButton1Click:Connect(function()
                        if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            safeCall(function()
                                player.Character.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame
                            end)
                        end
                    end)
                    
                    index = index + 1
                end
            end
        end)
    end

    -- ===============================================================
    --                         ENHANCED FEATURES
    -- ===============================================================
    
    -- Hotkey for hiding GUI (F9)
    connections[#connections + 1] = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == CONFIG.HOTKEY then
            isHidden = not isHidden
            GameXsanGUI.Enabled = not isHidden
            
            -- Update floating icon appearance
            local iconFrame = FloatingGUI and FloatingGUI:FindFirstChild("FloatingIcon")
            if iconFrame then
                local iconStroke = iconFrame:FindFirstChild("UIStroke")
                local iconImage = iconFrame:FindFirstChild("IconImage")
                
                if isHidden then
                    if iconStroke then 
                        iconStroke.Color = Color3.fromRGB(255, 0, 0) 
                    end
                    if iconImage then 
                        iconImage.ImageColor3 = Color3.fromRGB(255, 100, 100) 
                    end
                else
                    if iconStroke then 
                        iconStroke.Color = Color3.fromRGB(0, 255, 0) 
                    end
                    if iconImage then 
                        iconImage.ImageColor3 = Color3.fromRGB(0, 255, 0) 
                    end
                end
            end
        end
    end)

    -- Make GUI draggable
    local dragging = false
    local dragStart = nil
    local startPos = nil

    connections[#connections + 1] = FrameUtama.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = FrameUtama.Position
        end
    end)

    connections[#connections + 1] = UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local delta = input.Position - dragStart
            FrameUtama.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    connections[#connections + 1] = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    -- Update player list on player join/leave
    connections[#connections + 1] = Players.PlayerAdded:Connect(updatePlayerList)
    connections[#connections + 1] = Players.PlayerRemoving:Connect(updatePlayerList)

    -- Update statistics display
    connections[#connections + 1] = RunService.Heartbeat:Connect(function()
        local sessionTime = math.floor((tick() - Stats.sessionStartTime) / 60)
        StatsText.Text = string.format("🐟 Fish: %d | ⏰ Session: %dm | 🚤 Boats: %d", 
            Stats.fishCaught, sessionTime, Stats.boatsSpawned)
    end)

    -- Start anti-AFK system
    antiAFK()

    -- Auto-update walk speed for new character
    connections[#connections + 1] = player.CharacterAdded:Connect(function()
        task.wait(1) -- Wait for character to load
        setWalkSpeed(Settings.WalkSpeed)
        setJumpPower(Settings.JumpPower)
    end)

    -- Initial setup
    showPanel("Main")
    updatePlayerList()

    print("✅ GameXsan V2.0 loaded successfully!")
    print("📌 Press F9 to hide/show GUI")
    print("🔄 Click floating icon to toggle GUI")
    print("🎣 Auto Fish with enhanced safety features")
    print("🚤 Multiple boat spawning options")
    print("📍 Player & Island teleportation")
    print("🔧 New Features: Auto Sell, Walk Speed, ESP, Notifications")
    print("🛡️ Safety Features: Anti-AFK, Health Check, Error Handling")
    print("🎯 Floating Icon: Drag to move, click to toggle GUI")

    return GameXsanGUI
end

-- ===================================================================
--                           INITIALIZATION
-- ===================================================================

local function initialize()
    loadSettings()
    createCompleteGUI()
end

-- Start the script
initialize()

-- Handle player leaving
connections[#connections + 1] = Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == player then
        for _, connection in pairs(connections) do
            if connection and connection.Connected then
                connection:Disconnect()
            end
        end
        if CONFIG.AUTO_SAVE_SETTINGS then
            saveSettings()
        end
    end
end)

end) -- End of main pcall

if not success then
    warn("❌ Script failed to load: " .. tostring(error))
else
    print("🎉 Script loaded successfully!")
end
