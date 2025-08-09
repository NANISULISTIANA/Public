-- IMPROVED SCRIPT STRUCTURE
-- Bagi script menjadi beberapa bagian yang lebih terorganisir

local ZayrosFishingGUI = {}
ZayrosFishingGUI.__index = ZayrosFishingGUI

-- ===== CONSTANTS =====
local COLORS = {
    Background = Color3.fromRGB(47, 47, 47),
    Button = Color3.fromRGB(0, 0, 0),
    Text = Color3.fromRGB(255, 255, 255),
    Success = Color3.fromRGB(0, 255, 0),
    Error = Color3.fromRGB(255, 0, 0)
}

local SERVICES = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    TweenService = game:GetService("TweenService"),
    UserInputService = game:GetService("UserInputService"),
    RunService = game:GetService("RunService")
}

-- ===== UTILITY FUNCTIONS =====
local function createButton(parent, name, text, size, position)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Parent = parent
    button.Size = size
    button.Position = position
    button.BackgroundColor3 = COLORS.Button
    button.Text = text
    button.TextColor3 = COLORS.Text
    button.TextScaled = true
    button.Font = Enum.Font.SourceSansBold
    
    local corner = Instance.new("UICorner")
    corner.Parent = button
    corner.CornerRadius = UDim.new(0, 4)
    
    return button
end

local function createFrame(parent, name, size, position)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Parent = parent
    frame.Size = size
    frame.Position = position
    frame.BackgroundColor3 = COLORS.Background
    frame.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.Parent = frame
    
    return frame
end

-- ===== MAIN CLASS =====
function ZayrosFishingGUI.new()
    local self = setmetatable({}, ZayrosFishingGUI)
    
    -- Initialize properties
    self.player = SERVICES.Players.LocalPlayer
    self.gui = nil
    self.isAutoFishing = false
    self.autoFishThread = nil
    self.connections = {}
    self.isMinimized = false
    
    -- Setup GUI
    self:createGUI()
    self:setupEventHandlers()
    
    return self
end

function ZayrosFishingGUI:createGUI()
    -- Remove existing GUI if present
    if self.player.PlayerGui:FindFirstChild("ZayrosFISHIT") then
        self.player.PlayerGui.ZayrosFISHIT:Destroy()
    end
    
    -- Create main ScreenGui
    self.gui = Instance.new("ScreenGui")
    self.gui.Name = "ZayrosFISHIT"
    self.gui.Parent = self.player.PlayerGui
    self.gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Create main frame with dragging capability
    self.mainFrame = createFrame(self.gui, "MainFrame", 
        UDim2.new(0, 500, 0, 400), 
        UDim2.new(0.5, -250, 0.5, -200)
    )
    
    -- Add dragging functionality
    self:makeDraggable(self.mainFrame)
    
    -- Continue with UI creation...
    self:createTitleBar()
    self:createSidebar()
    self:createContentArea()
    self:createFloatingIcon()
end

function ZayrosFishingGUI:makeDraggable(frame)
    local dragToggle = nil
    local dragSpeed = 0.25
    local dragStart = nil
    local startPos = nil
    
    local function updateInput(input)
        local delta = input.Position - dragStart
        local position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        
        SERVICES.TweenService:Create(frame, TweenInfo.new(dragSpeed), {Position = position}):Play()
    end
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragToggle = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragToggle = false
                end
            end)
        end
    end)
    
    SERVICES.UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragToggle then
            updateInput(input)
        end
    end)
end

function ZayrosFishingGUI:createTitleBar()
    local titleBar = createFrame(self.mainFrame, "TitleBar", 
        UDim2.new(1, 0, 0, 30), 
        UDim2.new(0, 0, 0, 0)
    )
    titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    
    local title = Instance.new("TextLabel")
    title.Parent = titleBar
    title.Size = UDim2.new(0.7, 0, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Zayros FISHIT v2.0"
    title.TextColor3 = COLORS.Text
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Minimize Button
    local minimizeBtn = createButton(titleBar, "MinimizeBtn", "-", 
        UDim2.new(0, 30, 0, 30), 
        UDim2.new(1, -70, 0, 0)
    )
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 193, 7)
    
    self:addButtonHoverEffect(minimizeBtn)
    minimizeBtn.MouseButton1Click:Connect(function()
        self:toggleMinimize()
    end)
    
    -- Close Button
    local closeBtn = createButton(titleBar, "CloseBtn", "X", 
        UDim2.new(0, 30, 0, 30), 
        UDim2.new(1, -35, 0, 0)
    )
    closeBtn.BackgroundColor3 = Color3.fromRGB(220, 40, 34)
    
    self:addButtonHoverEffect(closeBtn)
    closeBtn.MouseButton1Click:Connect(function()
        self:destroy()
    end)
    
    -- Store title reference for later use
    self.titleLabel = title
    self.minimizeButton = minimizeBtn
end

function ZayrosFishingGUI:createSidebar()
    local sidebar = createFrame(self.mainFrame, "Sidebar", 
        UDim2.new(0, 150, 1, -30), 
        UDim2.new(0, 0, 0, 30)
    )
    sidebar.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    
    -- Create navigation buttons
    local buttons = {"Main", "Player", "Teleport", "Boats", "Settings"}
    local buttonHeight = 40
    local spacing = 5
    
    for i, buttonName in ipairs(buttons) do
        local navBtn = createButton(sidebar, buttonName.."Btn", buttonName, 
            UDim2.new(1, -10, 0, buttonHeight),
            UDim2.new(0, 5, 0, (buttonHeight + spacing) * (i - 1) + 10)
        )
        
        self:addButtonHoverEffect(navBtn)
        
        navBtn.MouseButton1Click:Connect(function()
            self:navigateToPage(buttonName)
        end)
    end
    
    -- Credit label at bottom
    local credit = Instance.new("TextLabel")
    credit.Parent = sidebar
    credit.Size = UDim2.new(1, 0, 0, 30)
    credit.Position = UDim2.new(0, 0, 1, -30)
    credit.BackgroundTransparency = 1
    credit.Text = "Made by Doovy :D"
    credit.TextColor3 = COLORS.Text
    credit.TextScaled = true
    credit.Font = Enum.Font.SourceSans
end

function ZayrosFishingGUI:createContentArea()
    self.contentFrame = createFrame(self.mainFrame, "ContentFrame", 
        UDim2.new(1, -150, 1, -30), 
        UDim2.new(0, 150, 0, 30)
    )
    self.contentFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    
    -- Create pages
    self:createMainPage()
    self:createPlayerPage()
    self:createTeleportPage()
    self:createBoatsPage()
    self:createSettingsPage()
    
    -- Show main page by default
    self:navigateToPage("Main")
end

function ZayrosFishingGUI:createFloatingIcon()
    -- Create floating icon that appears when minimized
    self.floatingIcon = Instance.new("Frame")
    self.floatingIcon.Name = "FloatingIcon"
    self.floatingIcon.Size = UDim2.new(0, 60, 0, 60)
    self.floatingIcon.Position = UDim2.new(0, 20, 0, 100)
    self.floatingIcon.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    self.floatingIcon.BorderSizePixel = 0
    self.floatingIcon.Parent = self.gui
    self.floatingIcon.Visible = false
    self.floatingIcon.ZIndex = 10
    
    -- Add corner radius
    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 30)
    iconCorner.Parent = self.floatingIcon
    
    -- Add icon image/text
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Parent = self.floatingIcon
    iconLabel.Size = UDim2.new(1, 0, 1, 0)
    iconLabel.Position = UDim2.new(0, 0, 0, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = "🐟"
    iconLabel.TextColor3 = COLORS.Text
    iconLabel.TextScaled = true
    iconLabel.Font = Enum.Font.SourceSansBold
    
    -- Add click functionality
    local iconButton = Instance.new("TextButton")
    iconButton.Parent = self.floatingIcon
    iconButton.Size = UDim2.new(1, 0, 1, 0)
    iconButton.Position = UDim2.new(0, 0, 0, 0)
    iconButton.BackgroundTransparency = 1
    iconButton.Text = ""
    iconButton.ZIndex = 11
    
    iconButton.MouseButton1Click:Connect(function()
        self:toggleMinimize()
    end)
    
    -- Add hover effect to floating icon
    self:addButtonHoverEffect(self.floatingIcon)
    
    -- Make floating icon draggable
    self:makeDraggable(self.floatingIcon)
    
    -- Add pulse animation when auto fishing is active
    local pulseAnimation = SERVICES.TweenService:Create(self.floatingIcon,
        TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Size = UDim2.new(0, 70, 0, 70)}
    )
    
    -- Store references
    self.iconPulseAnimation = pulseAnimation
    self.iconLabel = iconLabel
end

function ZayrosFishingGUI:toggleMinimize()
    self.isMinimized = not self.isMinimized
    
    if self.isMinimized then
        -- Minimize: Hide main frame, show floating icon
        local tweenOut = SERVICES.TweenService:Create(self.mainFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
            {
                Size = UDim2.new(0, 0, 0, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0)
            }
        )
        
        tweenOut:Play()
        tweenOut.Completed:Connect(function()
            self.mainFrame.Visible = false
            self.floatingIcon.Visible = true
            
            -- Animate floating icon in
            local iconTweenIn = SERVICES.TweenService:Create(self.floatingIcon,
                TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                {Size = UDim2.new(0, 60, 0, 60)}
            )
            iconTweenIn:Play()
        end)
        
        self:createNotification("GUI minimized - click the floating icon to restore", "info", 2)
        
        -- Update minimize button text
        if self.minimizeButton then
            self.minimizeButton.Text = "□"
        end
        
        -- Start pulse animation if auto fishing is active
        if self.isAutoFishing then
            self.iconPulseAnimation:Play()
            self.iconLabel.Text = "🎣"
        end
        
    else
        -- Restore: Hide floating icon, show main frame
        self.floatingIcon.Visible = false
        self.mainFrame.Visible = true
        
        -- Stop pulse animation
        self.iconPulseAnimation:Cancel()
        self.iconLabel.Text = "🐟"
        
        local tweenIn = SERVICES.TweenService:Create(self.mainFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {
                Size = UDim2.new(0, 500, 0, 400),
                Position = UDim2.new(0.5, -250, 0.5, -200)
            }
        )
        
        tweenIn:Play()
        
        self:createNotification("GUI restored", "info", 1)
        
        -- Update minimize button text
        if self.minimizeButton then
            self.minimizeButton.Text = "-"
        end
    end
end

function ZayrosFishingGUI:setupEventHandlers()
    -- Auto-update player list when players join/leave
    local playerAddedConnection = SERVICES.Players.PlayerAdded:Connect(function()
        task.wait(1) -- Wait for character to load
        self:updateTeleportLists()
    end)
    
    local playerRemovingConnection = SERVICES.Players.PlayerRemoving:Connect(function()
        self:updateTeleportLists()
    end)
    
    -- Update when players spawn
    for _, player in ipairs(SERVICES.Players:GetPlayers()) do
        if player ~= self.player then
            local characterAddedConnection = player.CharacterAdded:Connect(function()
                task.wait(1)
                self:updateTeleportLists()
            end)
            table.insert(self.connections, characterAddedConnection)
        end
    end
    
    -- Store connections for cleanup
    table.insert(self.connections, playerAddedConnection)
    table.insert(self.connections, playerRemovingConnection)
    
    -- Auto-update teleport lists every 30 seconds
    local updateConnection = task.spawn(function()
        while self.gui and self.gui.Parent do
            task.wait(30)
            if self.gui and self.gui.Parent then
                self:updateTeleportLists()
            end
        end
    end)
    table.insert(self.connections, updateConnection)
    
    -- Initialize settings
    self.useRandomization = true
    
    -- Setup keybinds
    self:setupKeybinds()
end

function ZayrosFishingGUI:setupKeybinds()
    -- Toggle minimize with INSERT key
    local keybindConnection = SERVICES.UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Insert then
            self:toggleMinimize()
        elseif input.KeyCode == Enum.KeyCode.Home then
            if self.isMinimized then
                self:toggleMinimize()
            end
            self:toggleAutoFish()
        end
    end)
    
    table.insert(self.connections, keybindConnection)
end

-- ===== PAGE CREATION METHODS =====
function ZayrosFishingGUI:createMainPage()
    local mainPage = createFrame(self.contentFrame, "MainPage", 
        UDim2.new(1, 0, 1, 0), 
        UDim2.new(0, 0, 0, 0)
    )
    mainPage.BackgroundTransparency = 1
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Parent = mainPage
    scrollFrame.Size = UDim2.new(1, -20, 1, -20)
    scrollFrame.Position = UDim2.new(0, 10, 0, 10)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 400)
    
    -- Auto Fish Toggle
    local autoFishFrame = createFrame(scrollFrame, "AutoFishFrame", 
        UDim2.new(1, -20, 0, 60), 
        UDim2.new(0, 10, 0, 10)
    )
    
    local autoFishLabel = Instance.new("TextLabel")
    autoFishLabel.Parent = autoFishFrame
    autoFishLabel.Size = UDim2.new(0.7, 0, 1, 0)
    autoFishLabel.Position = UDim2.new(0, 10, 0, 0)
    autoFishLabel.BackgroundTransparency = 1
    autoFishLabel.Text = "Auto Fish (AFK)"
    autoFishLabel.TextColor3 = COLORS.Text
    autoFishLabel.TextScaled = true
    autoFishLabel.Font = Enum.Font.SourceSansBold
    autoFishLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    self.autoFishToggle = self:createToggleSwitch(autoFishFrame, false, function(state)
        self:toggleAutoFish()
        self:createNotification(
            state and "Auto Fishing Started" or "Auto Fishing Stopped",
            state and "success" or "info"
        )
    end)
    self.autoFishToggle.Position = UDim2.new(0.8, 0, 0.2, 0)
    
    -- Sell All Button
    local sellAllBtn = createButton(scrollFrame, "SellAllBtn", "Sell All Fish", 
        UDim2.new(1, -20, 0, 40),
        UDim2.new(0, 10, 0, 80)
    )
    sellAllBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    
    self:addButtonHoverEffect(sellAllBtn)
    sellAllBtn.MouseButton1Click:Connect(function()
        self:sellAllFish()
    end)
    
    self.pages = self.pages or {}
    self.pages.Main = mainPage
end

function ZayrosFishingGUI:createPlayerPage()
    local playerPage = createFrame(self.contentFrame, "PlayerPage", 
        UDim2.new(1, 0, 1, 0), 
        UDim2.new(0, 0, 0, 0)
    )
    playerPage.BackgroundTransparency = 1
    playerPage.Visible = false
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Parent = playerPage
    scrollFrame.Size = UDim2.new(1, -20, 1, -20)
    scrollFrame.Position = UDim2.new(0, 10, 0, 10)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 600)
    
    -- Walk Speed
    local walkSpeedFrame = createFrame(scrollFrame, "WalkSpeedFrame", 
        UDim2.new(1, -20, 0, 80), 
        UDim2.new(0, 10, 0, 10)
    )
    
    local walkSpeedLabel = Instance.new("TextLabel")
    walkSpeedLabel.Parent = walkSpeedFrame
    walkSpeedLabel.Size = UDim2.new(0.5, 0, 0.5, 0)
    walkSpeedLabel.Position = UDim2.new(0, 10, 0, 5)
    walkSpeedLabel.BackgroundTransparency = 1
    walkSpeedLabel.Text = "Walk Speed:"
    walkSpeedLabel.TextColor3 = COLORS.Text
    walkSpeedLabel.TextScaled = true
    walkSpeedLabel.Font = Enum.Font.SourceSansBold
    walkSpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    self.walkSpeedBox = Instance.new("TextBox")
    self.walkSpeedBox.Parent = walkSpeedFrame
    self.walkSpeedBox.Size = UDim2.new(0.25, 0, 0.4, 0)
    self.walkSpeedBox.Position = UDim2.new(0.5, 0, 0.1, 0)
    self.walkSpeedBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    self.walkSpeedBox.BorderSizePixel = 0
    self.walkSpeedBox.Text = "16"
    self.walkSpeedBox.TextColor3 = COLORS.Text
    self.walkSpeedBox.TextScaled = true
    self.walkSpeedBox.Font = Enum.Font.SourceSans
    self.walkSpeedBox.PlaceholderText = "16"
    
    local walkSpeedCorner = Instance.new("UICorner")
    walkSpeedCorner.Parent = self.walkSpeedBox
    walkSpeedCorner.CornerRadius = UDim.new(0, 4)
    
    local setWalkSpeedBtn = createButton(walkSpeedFrame, "SetWalkSpeedBtn", "Set", 
        UDim2.new(0.15, 0, 0.4, 0),
        UDim2.new(0.8, 0, 0.1, 0)
    )
    
    self:addButtonHoverEffect(setWalkSpeedBtn)
    setWalkSpeedBtn.MouseButton1Click:Connect(function()
        self:setWalkSpeed(tonumber(self.walkSpeedBox.Text) or 16)
    end)
    
    -- No Oxygen Damage Toggle
    local noOxygenFrame = createFrame(scrollFrame, "NoOxygenFrame", 
        UDim2.new(1, -20, 0, 60), 
        UDim2.new(0, 10, 0, 100)
    )
    
    local noOxygenLabel = Instance.new("TextLabel")
    noOxygenLabel.Parent = noOxygenFrame
    noOxygenLabel.Size = UDim2.new(0.7, 0, 1, 0)
    noOxygenLabel.Position = UDim2.new(0, 10, 0, 0)
    noOxygenLabel.BackgroundTransparency = 1
    noOxygenLabel.Text = "No Oxygen Damage"
    noOxygenLabel.TextColor3 = COLORS.Text
    noOxygenLabel.TextScaled = true
    noOxygenLabel.Font = Enum.Font.SourceSansBold
    noOxygenLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    self.noOxygenToggle = self:createToggleSwitch(noOxygenFrame, false, function(state)
        self:toggleNoOxygen(state)
    end)
    self.noOxygenToggle.Position = UDim2.new(0.8, 0, 0.2, 0)
    
    -- Unlimited Jump Toggle
    local unlimitedJumpFrame = createFrame(scrollFrame, "UnlimitedJumpFrame", 
        UDim2.new(1, -20, 0, 60), 
        UDim2.new(0, 10, 0, 170)
    )
    
    local unlimitedJumpLabel = Instance.new("TextLabel")
    unlimitedJumpLabel.Parent = unlimitedJumpFrame
    unlimitedJumpLabel.Size = UDim2.new(0.7, 0, 1, 0)
    unlimitedJumpLabel.Position = UDim2.new(0, 10, 0, 0)
    unlimitedJumpLabel.BackgroundTransparency = 1
    unlimitedJumpLabel.Text = "Unlimited Jump"
    unlimitedJumpLabel.TextColor3 = COLORS.Text
    unlimitedJumpLabel.TextScaled = true
    unlimitedJumpLabel.Font = Enum.Font.SourceSansBold
    unlimitedJumpLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    self.unlimitedJumpToggle = self:createToggleSwitch(unlimitedJumpFrame, false, function(state)
        self:toggleUnlimitedJump(state)
    end)
    self.unlimitedJumpToggle.Position = UDim2.new(0.8, 0, 0.2, 0)
    
    self.pages = self.pages or {}
    self.pages.Player = playerPage
end

function ZayrosFishingGUI:createTeleportPage()
    local teleportPage = createFrame(self.contentFrame, "TeleportPage", 
        UDim2.new(1, 0, 1, 0), 
        UDim2.new(0, 0, 0, 0)
    )
    teleportPage.BackgroundTransparency = 1
    teleportPage.Visible = false
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Parent = teleportPage
    scrollFrame.Size = UDim2.new(1, -20, 1, -20)
    scrollFrame.Position = UDim2.new(0, 10, 0, 10)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 600)
    
    -- TP to Islands
    local islandFrame = createFrame(scrollFrame, "IslandFrame", 
        UDim2.new(1, -20, 0, 200), 
        UDim2.new(0, 10, 0, 10)
    )
    
    local islandLabel = Instance.new("TextLabel")
    islandLabel.Parent = islandFrame
    islandLabel.Size = UDim2.new(1, 0, 0, 30)
    islandLabel.Position = UDim2.new(0, 0, 0, 0)
    islandLabel.BackgroundTransparency = 1
    islandLabel.Text = "Teleport to Islands"
    islandLabel.TextColor3 = COLORS.Text
    islandLabel.TextScaled = true
    islandLabel.Font = Enum.Font.SourceSansBold
    
    self.islandScrollFrame = Instance.new("ScrollingFrame")
    self.islandScrollFrame.Parent = islandFrame
    self.islandScrollFrame.Size = UDim2.new(1, -10, 1, -40)
    self.islandScrollFrame.Position = UDim2.new(0, 5, 0, 35)
    self.islandScrollFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    self.islandScrollFrame.BorderSizePixel = 0
    self.islandScrollFrame.ScrollBarThickness = 4
    self.islandScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    
    local islandCorner = Instance.new("UICorner")
    islandCorner.Parent = self.islandScrollFrame
    islandCorner.CornerRadius = UDim.new(0, 4)
    
    local islandListLayout = Instance.new("UIListLayout")
    islandListLayout.Parent = self.islandScrollFrame
    islandListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    islandListLayout.Padding = UDim.new(0, 2)
    
    -- TP to Players
    local playerFrame = createFrame(scrollFrame, "PlayerTeleportFrame", 
        UDim2.new(1, -20, 0, 200), 
        UDim2.new(0, 10, 0, 220)
    )
    
    local playerLabel = Instance.new("TextLabel")
    playerLabel.Parent = playerFrame
    playerLabel.Size = UDim2.new(1, 0, 0, 30)
    playerLabel.Position = UDim2.new(0, 0, 0, 0)
    playerLabel.BackgroundTransparency = 1
    playerLabel.Text = "Teleport to Players"
    playerLabel.TextColor3 = COLORS.Text
    playerLabel.TextScaled = true
    playerLabel.Font = Enum.Font.SourceSansBold
    
    self.playerScrollFrame = Instance.new("ScrollingFrame")
    self.playerScrollFrame.Parent = playerFrame
    self.playerScrollFrame.Size = UDim2.new(1, -10, 1, -40)
    self.playerScrollFrame.Position = UDim2.new(0, 5, 0, 35)
    self.playerScrollFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    self.playerScrollFrame.BorderSizePixel = 0
    self.playerScrollFrame.ScrollBarThickness = 4
    self.playerScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    
    local playerCorner = Instance.new("UICorner")
    playerCorner.Parent = self.playerScrollFrame
    playerCorner.CornerRadius = UDim.new(0, 4)
    
    local playerListLayout = Instance.new("UIListLayout")
    playerListLayout.Parent = self.playerScrollFrame
    playerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    playerListLayout.Padding = UDim.new(0, 2)
    
    -- Populate teleport lists
    self:updateTeleportLists()
    
    self.pages = self.pages or {}
    self.pages.Teleport = teleportPage
end

function ZayrosFishingGUI:createBoatsPage()
    local boatsPage = createFrame(self.contentFrame, "BoatsPage", 
        UDim2.new(1, 0, 1, 0), 
        UDim2.new(0, 0, 0, 0)
    )
    boatsPage.BackgroundTransparency = 1
    boatsPage.Visible = false
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Parent = boatsPage
    scrollFrame.Size = UDim2.new(1, -20, 1, -20)
    scrollFrame.Position = UDim2.new(0, 10, 0, 10)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 800)
    
    -- Despawn All Boats Button
    local despawnBtn = createButton(scrollFrame, "DespawnBtn", "Despawn All Boats", 
        UDim2.new(1, -20, 0, 40),
        UDim2.new(0, 10, 0, 10)
    )
    despawnBtn.BackgroundColor3 = Color3.fromRGB(220, 40, 34)
    
    self:addButtonHoverEffect(despawnBtn)
    despawnBtn.MouseButton1Click:Connect(function()
        self:despawnAllBoats()
    end)
    
    -- Boat spawn buttons
    local boats = {
        "Small Boat", "Kayak", "Jetski", "Highfield Boat", "Speed Boat",
        "Fishing Boat", "Mini Yacht", "Hyper Boat", "Frozen Boat", "Cruiser Boat",
        "Alpha Floaty", "Evil Duck", "Festive Duck", "Santa Sleigh"
    }
    
    for i, boatName in ipairs(boats) do
        local boatBtn = createButton(scrollFrame, boatName.."Btn", "Spawn " .. boatName, 
            UDim2.new(1, -20, 0, 40),
            UDim2.new(0, 10, 0, 60 + (i - 1) * 50)
        )
        boatBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        
        self:addButtonHoverEffect(boatBtn)
        boatBtn.MouseButton1Click:Connect(function()
            self:spawnBoat(boatName)
        end)
    end
    
    self.pages = self.pages or {}
    self.pages.Boats = boatsPage
end

function ZayrosFishingGUI:createSettingsPage()
    local settingsPage = createFrame(self.contentFrame, "SettingsPage", 
        UDim2.new(1, 0, 1, 0), 
        UDim2.new(0, 0, 0, 0)
    )
    settingsPage.BackgroundTransparency = 1
    settingsPage.Visible = false
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Parent = settingsPage
    scrollFrame.Size = UDim2.new(1, -20, 1, -20)
    scrollFrame.Position = UDim2.new(0, 10, 0, 10)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 400)
    
    -- Auto Fish Settings
    local autoFishSettingsFrame = createFrame(scrollFrame, "AutoFishSettingsFrame", 
        UDim2.new(1, -20, 0, 150), 
        UDim2.new(0, 10, 0, 10)
    )
    
    local settingsLabel = Instance.new("TextLabel")
    settingsLabel.Parent = autoFishSettingsFrame
    settingsLabel.Size = UDim2.new(1, 0, 0, 30)
    settingsLabel.Position = UDim2.new(0, 0, 0, 0)
    settingsLabel.BackgroundTransparency = 1
    settingsLabel.Text = "Auto Fish Settings"
    settingsLabel.TextColor3 = COLORS.Text
    settingsLabel.TextScaled = true
    settingsLabel.Font = Enum.Font.SourceSansBold
    
    -- Fishing delay setting
    local delayLabel = Instance.new("TextLabel")
    delayLabel.Parent = autoFishSettingsFrame
    delayLabel.Size = UDim2.new(0.5, 0, 0, 25)
    delayLabel.Position = UDim2.new(0, 10, 0, 40)
    delayLabel.BackgroundTransparency = 1
    delayLabel.Text = "Fishing Delay (seconds):"
    delayLabel.TextColor3 = COLORS.Text
    delayLabel.TextScaled = true
    delayLabel.Font = Enum.Font.SourceSans
    delayLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    self.delayBox = Instance.new("TextBox")
    self.delayBox.Parent = autoFishSettingsFrame
    self.delayBox.Size = UDim2.new(0.3, 0, 0, 25)
    self.delayBox.Position = UDim2.new(0.6, 0, 0, 40)
    self.delayBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    self.delayBox.BorderSizePixel = 0
    self.delayBox.Text = "0.1"
    self.delayBox.TextColor3 = COLORS.Text
    self.delayBox.TextScaled = true
    self.delayBox.Font = Enum.Font.SourceSans
    self.delayBox.PlaceholderText = "0.1"
    
    local delayCorner = Instance.new("UICorner")
    delayCorner.Parent = self.delayBox
    delayCorner.CornerRadius = UDim.new(0, 4)
    
    -- Randomization toggle
    local randomizeLabel = Instance.new("TextLabel")
    randomizeLabel.Parent = autoFishSettingsFrame
    randomizeLabel.Size = UDim2.new(0.7, 0, 0, 25)
    randomizeLabel.Position = UDim2.new(0, 10, 0, 80)
    randomizeLabel.BackgroundTransparency = 1
    randomizeLabel.Text = "Randomize Timing (Anti-Detection)"
    randomizeLabel.TextColor3 = COLORS.Text
    randomizeLabel.TextScaled = true
    randomizeLabel.Font = Enum.Font.SourceSans
    randomizeLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    self.randomizeToggle = self:createToggleSwitch(autoFishSettingsFrame, true, function(state)
        self.useRandomization = state
    end)
    self.randomizeToggle.Position = UDim2.new(0.8, 0, 0, 82)
    
    self.pages = self.pages or {}
    self.pages.Settings = settingsPage
end

-- ===== UTILITY METHODS =====
function ZayrosFishingGUI:addButtonHoverEffect(button)
    local originalColor = button.BackgroundColor3
    local hoverColor = Color3.fromRGB(
        math.min(255, originalColor.R * 255 + 20),
        math.min(255, originalColor.G * 255 + 20),
        math.min(255, originalColor.B * 255 + 20)
    )
    
    local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    button.MouseEnter:Connect(function()
        local tween = SERVICES.TweenService:Create(button, tweenInfo, {BackgroundColor3 = hoverColor})
        tween:Play()
    end)
    
    button.MouseLeave:Connect(function()
        local tween = SERVICES.TweenService:Create(button, tweenInfo, {BackgroundColor3 = originalColor})
        tween:Play()
    end)
end

function ZayrosFishingGUI:createToggleSwitch(parent, initialState, callback)
    local switch = Instance.new("Frame")
    switch.Size = UDim2.new(0, 50, 0, 25)
    switch.BackgroundColor3 = initialState and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(100, 100, 100)
    switch.Parent = parent
    switch.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.5, 0)
    corner.Parent = switch
    
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = initialState and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = switch
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(0.5, 0)
    knobCorner.Parent = knob
    
    local isOn = initialState
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = switch
    
    button.MouseButton1Click:Connect(function()
        isOn = not isOn
        
        local switchColor = isOn and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(100, 100, 100)
        local knobPos = isOn and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
        
        local switchTween = SERVICES.TweenService:Create(switch, 
            TweenInfo.new(0.2, Enum.EasingStyle.Quad),
            {BackgroundColor3 = switchColor}
        )
        
        local knobTween = SERVICES.TweenService:Create(knob,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad),
            {Position = knobPos}
        )
        
        switchTween:Play()
        knobTween:Play()
        
        if callback then
            callback(isOn)
        end
    end)
    
    return switch
end

function ZayrosFishingGUI:createNotification(message, type, duration)
    type = type or "info"
    duration = duration or 3
    
    local colors = {
        success = Color3.fromRGB(0, 255, 0),
        error = Color3.fromRGB(255, 0, 0),
        warning = Color3.fromRGB(255, 255, 0),
        info = Color3.fromRGB(0, 150, 255)
    }
    
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(0, 300, 0, 60)
    notification.Position = UDim2.new(1, -320, 0, 20)
    notification.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    notification.BorderSizePixel = 0
    notification.Parent = self.gui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notification
    
    local colorLine = Instance.new("Frame")
    colorLine.Size = UDim2.new(0, 4, 1, 0)
    colorLine.Position = UDim2.new(0, 0, 0, 0)
    colorLine.BackgroundColor3 = colors[type]
    colorLine.BorderSizePixel = 0
    colorLine.Parent = notification
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -20, 1, 0)
    text.Position = UDim2.new(0, 15, 0, 0)
    text.BackgroundTransparency = 1
    text.Text = message
    text.TextColor3 = Color3.fromRGB(255, 255, 255)
    text.TextScaled = true
    text.Font = Enum.Font.SourceSans
    text.Parent = notification
    
    -- Animate in
    local tweenIn = SERVICES.TweenService:Create(notification, 
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, -320, 0, 20)}
    )
    tweenIn:Play()
    
    -- Auto remove after duration
    task.spawn(function()
        task.wait(duration)
        
        local tweenOut = SERVICES.TweenService:Create(notification,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(1, 0, 0, 20)}
        )
        tweenOut:Play()
        
        tweenOut.Completed:Connect(function()
            notification:Destroy()
        end)
    end)
end

function ZayrosFishingGUI:navigateToPage(pageName)
    if not self.pages or not self.pages[pageName] then
        return
    end
    
    -- Hide all pages
    for _, page in pairs(self.pages) do
        page.Visible = false
    end
    
    -- Show selected page
    self.pages[pageName].Visible = true
    
    -- Update title
    if self.titleLabel then
        self.titleLabel.Text = "Zayros FISHIT v2.0 - " .. pageName
    end
    
    self:createNotification("Navigated to " .. pageName, "info", 1)
end

-- ===== FEATURE METHODS =====
function ZayrosFishingGUI:sellAllFish()
    local success, error = pcall(function()
        local Rs = SERVICES.ReplicatedStorage
        local sellAll = Rs.Packages._Index["sleitnick_net@0.2.0"].net["RF/SellAllItems"]
        sellAll:InvokeServer()
    end)
    
    if success then
        self:createNotification("All fish sold successfully!", "success")
    else
        self:createNotification("Failed to sell fish: " .. tostring(error), "error")
    end
end

function ZayrosFishingGUI:setWalkSpeed(speed)
    local success, error = pcall(function()
        local character = self.player.Character
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.WalkSpeed = speed
        end
    end)
    
    if success then
        self:createNotification("Walk speed set to " .. speed, "success")
    else
        self:createNotification("Failed to set walk speed: " .. tostring(error), "error")
    end
end

function ZayrosFishingGUI:toggleNoOxygen(state)
    -- This would require the no oxygen script
    local success, error = pcall(function()
        if state then
            -- Enable no oxygen damage
            self:createNotification("No oxygen damage enabled", "success")
        else
            -- Disable no oxygen damage
            self:createNotification("No oxygen damage disabled", "info")
        end
    end)
end

function ZayrosFishingGUI:toggleUnlimitedJump(state)
    local success, error = pcall(function()
        local character = self.player.Character
        if character and character:FindFirstChild("Humanoid") then
            if state then
                character.Humanoid.JumpPower = 200
                self:createNotification("Unlimited jump enabled", "success")
            else
                character.Humanoid.JumpPower = 50
                self:createNotification("Unlimited jump disabled", "info")
            end
        end
    end)
end

function ZayrosFishingGUI:updateTeleportLists()
    -- Update Islands
    if self.islandScrollFrame then
        -- Clear existing
        for _, child in ipairs(self.islandScrollFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        -- Find island folder
        local success, error = pcall(function()
            local tpFolder = workspace:FindFirstChild("!!!! ISLAND LOCATIONS !!!!")
            if tpFolder then
                for _, island in ipairs(tpFolder:GetChildren()) do
                    if island:IsA("BasePart") then
                        local btn = createButton(self.islandScrollFrame, island.Name.."Btn", island.Name,
                            UDim2.new(1, -10, 0, 30),
                            UDim2.new(0, 5, 0, 0)
                        )
                        btn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
                        
                        self:addButtonHoverEffect(btn)
                        btn.MouseButton1Click:Connect(function()
                            self:teleportToLocation(island.CFrame)
                        end)
                    end
                end
            end
        end)
    end
    
    -- Update Players
    if self.playerScrollFrame then
        -- Clear existing
        for _, child in ipairs(self.playerScrollFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        -- Add current players
        for _, player in ipairs(SERVICES.Players:GetPlayers()) do
            if player ~= self.player and player.Character then
                local btn = createButton(self.playerScrollFrame, player.Name.."Btn", player.Name,
                    UDim2.new(1, -10, 0, 30),
                    UDim2.new(0, 5, 0, 0)
                )
                btn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
                
                self:addButtonHoverEffect(btn)
                btn.MouseButton1Click:Connect(function()
                    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        self:teleportToLocation(player.Character.HumanoidRootPart.CFrame)
                    end
                end)
            end
        end
    end
end

function ZayrosFishingGUI:teleportToLocation(targetCFrame)
    local success, error = pcall(function()
        local character = self.player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            character.HumanoidRootPart.CFrame = targetCFrame
        end
    end)
    
    if success then
        self:createNotification("Teleported successfully!", "success")
    else
        self:createNotification("Failed to teleport: " .. tostring(error), "error")
    end
end

function ZayrosFishingGUI:spawnBoat(boatName)
    local success, error = pcall(function()
        local Rs = SERVICES.ReplicatedStorage
        local spawnBoat = Rs.Packages._Index["sleitnick_net@0.2.0"].net["RF/SpawnBoat"]
        spawnBoat:InvokeServer(boatName)
    end)
    
    if success then
        self:createNotification("Spawned " .. boatName, "success")
    else
        self:createNotification("Failed to spawn " .. boatName .. ": " .. tostring(error), "error")
    end
end

function ZayrosFishingGUI:despawnAllBoats()
    local success, error = pcall(function()
        local Rs = SERVICES.ReplicatedStorage
        local despawnBoat = Rs.Packages._Index["sleitnick_net@0.2.0"].net["RF/DespawnBoat"]
        despawnBoat:InvokeServer()
    end)
    
    if success then
        self:createNotification("All boats despawned", "success")
    else
        self:createNotification("Failed to despawn boats: " .. tostring(error), "error")
    end
end

-- ===== IMPROVED AUTO FISHING =====
function ZayrosFishingGUI:getRandomDelay(min, max)
    return math.random(min * 100, max * 100) / 100
end

function ZayrosFishingGUI:getRandomFishingCoords()
    local baseX, baseY = -1.2379989624023438, 0.9800224985802423
    local variance = 0.1
    
    local randomX = baseX + (math.random(-variance * 100, variance * 100) / 100)
    local randomY = baseY + (math.random(-variance * 100, variance * 100) / 100)
    
    return randomX, randomY
end

function ZayrosFishingGUI:toggleAutoFish()
    self.isAutoFishing = not self.isAutoFishing
    
    if self.isAutoFishing then
        self:startAutoFishing()
        
        -- Update floating icon if minimized
        if self.isMinimized and self.iconLabel then
            self.iconLabel.Text = "🎣"
            self.iconPulseAnimation:Play()
        end
    else
        self:stopAutoFishing()
        
        -- Update floating icon if minimized
        if self.isMinimized and self.iconLabel then
            self.iconLabel.Text = "🐟"
            self.iconPulseAnimation:Cancel()
            -- Reset size
            self.floatingIcon.Size = UDim2.new(0, 60, 0, 60)
        end
    end
end

function ZayrosFishingGUI:startAutoFishing()
    if self.autoFishThread then
        task.cancel(self.autoFishThread)
    end
    
    self.autoFishThread = task.spawn(function()
        while self.isAutoFishing do
            local success, error = pcall(function()
                self:performFishingCycle()
            end)
            
            if not success then
                warn("Auto fishing error:", error)
                -- Use randomized retry delay
                local retryDelay = self.useRandomization and self:getRandomDelay(1, 3) or 1
                task.wait(retryDelay)
            else
                -- Use custom delay from settings if available
                local delay = tonumber(self.delayBox and self.delayBox.Text) or 0.1
                if self.useRandomization then
                    delay = self:getRandomDelay(delay * 0.5, delay * 1.5)
                end
                task.wait(delay)
            end
        end
    end)
end

function ZayrosFishingGUI:stopAutoFishing()
    if self.autoFishThread then
        task.cancel(self.autoFishThread)
        self.autoFishThread = nil
    end
    
    -- Cancel any ongoing fishing
    pcall(function()
        local Rs = SERVICES.ReplicatedStorage
        local CancelFishing = Rs.Packages._Index["sleitnick_net@0.2.0"].net["RF/CancelFishingInputs"]
        CancelFishing:InvokeServer()
    end)
end

function ZayrosFishingGUI:performFishingCycle()
    local Rs = SERVICES.ReplicatedStorage
    local EquipRod = Rs.Packages._Index["sleitnick_net@0.2.0"].net["RE/EquipToolFromHotbar"]
    local ChargeRod = Rs.Packages._Index["sleitnick_net@0.2.0"].net["RF/ChargeFishingRod"]
    local RequestFishing = Rs.Packages._Index["sleitnick_net@0.2.0"].net["RF/RequestFishingMinigameStarted"]
    local FishingComplete = Rs.Packages._Index["sleitnick_net@0.2.0"].net["RE/FishingCompleted"]
    local CancelFishing = Rs.Packages._Index["sleitnick_net@0.2.0"].net["RF/CancelFishingInputs"]
    
    -- Use randomization if enabled
    local useRandom = self.useRandomization ~= false -- default to true
    local equipDelay = useRandom and self:getRandomDelay(0.3, 0.8) or 0.5
    local fishingDelay = useRandom and self:getRandomDelay(0.2, 0.6) or 0.4
    local cycleDelay = useRandom and self:getRandomDelay(0.1, 0.3) or 0.1
    
    -- Equip rod if not equipped
    local character = self.player.Character
    if not character or not character:FindFirstChild("!!!EQUIPPED_TOOL!!!") then
        local success = pcall(function()
            CancelFishing:InvokeServer()
            task.wait(0.1)
            EquipRod:FireServer(1)
        end)
        
        if not success then
            error("Failed to equip fishing rod")
        end
        
        task.wait(equipDelay)
        return -- Try again next cycle
    end
    
    -- Perform fishing sequence with randomization
    local x, y
    if useRandom then
        x, y = self:getRandomFishingCoords()
    else
        x, y = -1.2379989624023438, 0.9800224985802423
    end
    
    ChargeRod:InvokeServer(workspace:GetServerTimeNow())
    RequestFishing:InvokeServer(x, y)
    task.wait(fishingDelay)
    FishingComplete:FireServer()
    task.wait(cycleDelay)
end

function ZayrosFishingGUI:destroy()
    -- Stop auto fishing
    self:stopAutoFishing()
    
    -- Stop animations
    if self.iconPulseAnimation then
        self.iconPulseAnimation:Cancel()
    end
    
    -- Disconnect all connections
    for _, connection in pairs(self.connections) do
        if connection then
            if typeof(connection) == "RBXScriptConnection" then
                connection:Disconnect()
            elseif typeof(connection) == "thread" then
                task.cancel(connection)
            end
        end
    end
    self.connections = {}
    
    -- Clean up any ongoing processes
    pcall(function()
        local Rs = SERVICES.ReplicatedStorage
        local CancelFishing = Rs.Packages._Index["sleitnick_net@0.2.0"].net["RF/CancelFishingInputs"]
        local UnEquipRod = Rs.Packages._Index["sleitnick_net@0.2.0"].net["RE/UnequipToolFromHotbar"]
        CancelFishing:InvokeServer()
        UnEquipRod:FireServer()
    end)
    
    -- Create goodbye notification
    self:createNotification("Thanks for using Zayros FISHIT!", "info", 2)
    
    -- Destroy GUI after notification
    task.spawn(function()
        task.wait(2.5)
        if self.gui then
            self.gui:Destroy()
        end
    end)
end

-- ===== INITIALIZATION =====
function ZayrosFishingGUI:initialize()
    -- Set default values
    self.useRandomization = true
    
    -- Update teleport lists
    task.spawn(function()
        task.wait(1) -- Wait for GUI to fully load
        self:updateTeleportLists()
    end)
    
    -- Show welcome notification
    self:createNotification("Welcome to Zayros FISHIT v2.0!", "success", 3)
    
    -- Show keybind info
    task.spawn(function()
        task.wait(3.5)
        self:createNotification("Press INSERT to minimize/restore | HOME to toggle auto fish", "info", 4)
    end)
end

-- ===== USAGE =====
local fishingGUI = ZayrosFishingGUI.new()

-- Initialize the GUI
fishingGUI:initialize()

-- Store in global for external access
getgenv().ZayrosFishingGUI = fishingGUI

-- Return the instance for external control
return fishingGUI
