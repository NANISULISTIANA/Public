-- FINAL COMPLETE ROBLOX FISHING SCRIPT FIX
-- This script combines all fixes and improvements
-- Copy this entire script and run it in Roblox

print("🔧 Loading complete fishing script with all fixes...")

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

-- Variables
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local autoFishRunning = false

-- Safe Remote Getting
local function getRemotes()
    local success, remotes = pcall(function()
        local Rs = ReplicatedStorage
        local netFolder = Rs.Packages._Index["sleitnick_net@0.2.0"].net
        
        return {
            EquipRod = netFolder:FindFirstChild("RE/EquipToolFromHotbar"),
            UnEquipRod = netFolder:FindFirstChild("RE/UnequipToolFromHotbar"),
            ChargeRod = netFolder:FindFirstChild("RF/ChargeFishingRod"),
            RequestFishing = netFolder:FindFirstChild("RF/RequestFishingMinigameStarted"),
            FishingComplete = netFolder:FindFirstChild("RE/FishingCompleted"),
            CancelFishing = netFolder:FindFirstChild("RF/CancelFishingInputs"),
            SpawnBoat = netFolder:FindFirstChild("RF/SpawnBoat"),
            DespawnBoat = netFolder:FindFirstChild("RF/DespawnBoat"),
            SellAll = netFolder:FindFirstChild("RF/SellAllItems"),
            ModifyRodStats = netFolder:FindFirstChild("RF/ModifyRodStats")
        }
    end)
    
    if not success then
        warn("Failed to get remotes:", remotes)
        return nil
    end
    
    return remotes
end

-- Enhanced Rod Detection
local function getCurrentRod()
    local character = Player.Character
    if not character then return nil end
    
    -- Method 1: Check for equipped tool
    local equippedTool = character:FindFirstChild("!!!EQUIPPED_TOOL!!!")
    if equippedTool then
        return equippedTool
    end
    
    -- Method 2: Check backpack
    local backpack = Player:FindFirstChild("Backpack")
    if backpack then
        for _, tool in pairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and tool.Name:lower():find("rod") then
                return tool
            end
        end
    end
    
    return nil
end

-- Enhanced Rod Stats Detection
local function getRodStats(rod)
    if not rod then return nil end
    
    -- Method 1: Check rod attributes
    local stats = {}
    for name, attr in pairs(rod:GetAttributes()) do
        if type(attr) == "number" then
            stats[name] = attr
        end
    end
    
    if next(stats) then
        return stats
    end
    
    -- Method 2: Check children for stats
    local manifest = rod:FindFirstChild("Manifest")
    if manifest then
        for _, child in pairs(manifest:GetChildren()) do
            if child:IsA("NumberValue") or child:IsA("IntValue") then
                stats[child.Name] = child.Value
            end
        end
    end
    
    -- Method 3: Check handle for stats
    local handle = rod:FindFirstChild("Handle")
    if handle then
        for name, attr in pairs(handle:GetAttributes()) do
            if type(attr) == "number" then
                stats[name] = attr
            end
        end
    end
    
    return next(stats) and stats or nil
end

-- Alternative Rod Stats Modification (Without Remote)
local function modifyRodStats(multiplier)
    local rod = getCurrentRod()
    if not rod then
        warn("No rod found for stats modification")
        if _G.updateStatus then
            _G.updateStatus("❌ No rod found", Color3.fromRGB(255, 59, 48))
        end
        return false
    end

    print("🔧 Attempting to modify rod:", rod.Name)
    if _G.updateStatus then
        _G.updateStatus("🔧 Modifying " .. rod.Name .. "...", Color3.fromRGB(255, 149, 0))
    end

    local success = false
    local modifiedStats = {}

    -- Method 1: Try to modify attributes directly
    pcall(function()
        for name, value in pairs(rod:GetAttributes()) do
            if type(value) == "number" and value > 0 then
                local newValue = value * multiplier
                rod:SetAttribute(name, newValue)
                modifiedStats[name] = {old = value, new = newValue}
                success = true
            end
        end
    end)

    -- Method 2: Try to modify NumberValues in Manifest
    local manifest = rod:FindFirstChild("Manifest")
    if manifest then
        pcall(function()
            for _, child in pairs(manifest:GetChildren()) do
                if child:IsA("NumberValue") or child:IsA("IntValue") then
                    local oldValue = child.Value
                    if oldValue > 0 then
                        child.Value = oldValue * multiplier
                        modifiedStats[child.Name] = {old = oldValue, new = child.Value}
                        success = true
                    end
                end
            end
        end)
    end

    -- Method 3: Try to modify Handle attributes
    local handle = rod:FindFirstChild("Handle")
    if handle then
        pcall(function()
            for name, value in pairs(handle:GetAttributes()) do
                if type(value) == "number" and value > 0 then
                    local newValue = value * multiplier
                    handle:SetAttribute(name, newValue)
                    modifiedStats[name] = {old = value, new = newValue}
                    success = true
                end
            end
        end)
    end

    -- Method 4: Try to find and modify Configuration objects
    local function modifyConfigurations(parent)
        for _, child in pairs(parent:GetChildren()) do
            if child:IsA("Configuration") then
                for _, config in pairs(child:GetChildren()) do
                    if config:IsA("NumberValue") or config:IsA("IntValue") then
                        local oldValue = config.Value
                        if oldValue > 0 then
                            config.Value = oldValue * multiplier
                            modifiedStats[config.Name] = {old = oldValue, new = config.Value}
                            success = true
                        end
                    end
                end
            end
            -- Recursively check children
            if #child:GetChildren() > 0 then
                modifyConfigurations(child)
            end
        end
    end
    
    pcall(function()
        modifyConfigurations(rod)
    end)

    -- Method 5: Try to modify StringValues that contain numbers
    pcall(function()
        for _, child in pairs(rod:GetDescendants()) do
            if child:IsA("StringValue") and tonumber(child.Value) then
                local oldValue = tonumber(child.Value)
                if oldValue and oldValue > 0 then
                    child.Value = tostring(oldValue * multiplier)
                    modifiedStats[child.Name] = {old = oldValue, new = oldValue * multiplier}
                    success = true
                end
            end
        end
    end)

    -- Display results
    if success then
        print("✅ Rod stats modified successfully:")
        for statName, values in pairs(modifiedStats) do
            print("  " .. statName .. ": " .. values.old .. " → " .. values.new)
        end
        if _G.updateStatus then
            _G.updateStatus("✅ Rod stats modified! (x" .. multiplier .. ")", Color3.fromRGB(0, 255, 127))
        end
    else
        warn("❌ No modifiable stats found in rod")
        print("🔍 Rod structure:")
        local function printStructure(obj, indent)
            indent = indent or ""
            for _, child in pairs(obj:GetChildren()) do
                print(indent .. "- " .. child.Name .. " (" .. child.ClassName .. ")")
                if child.ClassName == "NumberValue" or child.ClassName == "IntValue" then
                    print(indent .. "  Value: " .. tostring(child.Value))
                end
                if #child:GetChildren() > 0 and #indent < 8 then
                    printStructure(child, indent .. "  ")
                end
            end
        end
        printStructure(rod)
        
        if _G.updateStatus then
            _G.updateStatus("❌ No modifiable stats found", Color3.fromRGB(255, 59, 48))
        end
    end

    return success
end

-- Enhanced Auto Fishing with Status Updates
local function startAutoFish()
    if autoFishRunning then
        print("Auto fishing already running!")
        if _G.updateStatus then
            _G.updateStatus("🔄 Auto fishing already running!", Color3.fromRGB(255, 193, 7))
        end
        return
    end
    
    autoFishRunning = true
    print("🎣 Starting enhanced auto fishing...")
    if _G.updateStatus then
        _G.updateStatus("🎣 Auto fishing started!", Color3.fromRGB(0, 255, 127))
    end
    
    local consecutiveErrors = 0
    local maxErrors = 3
    local fishCount = 0
    
    task.spawn(function()
        while autoFishRunning do
            local success, result = pcall(function()
                local remotes = getRemotes()
                if not remotes then
                    error("Remotes not available")
                end
                
                local character = Player.Character
                if not character or not character:FindFirstChild("HumanoidRootPart") then
                    task.wait(2)
                    return
                end
                
                -- Check/equip rod
                local rod = getCurrentRod()
                if not rod or not character:FindFirstChild("!!!EQUIPPED_TOOL!!!") then
                    print("🎣 Equipping rod...")
                    if _G.updateStatus then
                        _G.updateStatus("🎣 Equipping rod...", Color3.fromRGB(255, 149, 0))
                    end
                    if remotes.CancelFishing then
                        remotes.CancelFishing:InvokeServer()
                    end
                    task.wait(0.3)
                    if remotes.EquipRod then
                        remotes.EquipRod:FireServer(1)
                    end
                    task.wait(1.5)
                    return
                end
                
                -- Perform fishing cycle
                local baseX, baseY = -1.2379989624023438, 0.9800224985802423
                local variance = 0.05
                local x = baseX + (math.random(-100, 100) * variance / 100)
                local y = baseY + (math.random(-100, 100) * variance / 100)
                
                print("🎣 Fishing at:", math.floor(x*1000)/1000, math.floor(y*1000)/1000)
                fishCount = fishCount + 1
                if _G.updateStatus then
                    _G.updateStatus("🎣 Fishing... (Cast #" .. fishCount .. ")", Color3.fromRGB(0, 255, 127))
                end
                
                if remotes.ChargeRod then
                    remotes.ChargeRod:InvokeServer(workspace:GetServerTimeNow())
                end
                task.wait(0.1)
                
                if remotes.RequestFishing then
                    remotes.RequestFishing:InvokeServer(x, y)
                end
                task.wait(0.5)
                
                if remotes.FishingComplete then
                    remotes.FishingComplete:FireServer()
                end
                
                consecutiveErrors = 0
            end)
            
            if not success then
                consecutiveErrors = consecutiveErrors + 1
                warn("❌ Fishing error #" .. consecutiveErrors .. ":", result)
                
                if _G.updateStatus then
                    _G.updateStatus("❌ Error #" .. consecutiveErrors .. ": " .. tostring(result):sub(1,30), Color3.fromRGB(255, 59, 48))
                end
                
                if consecutiveErrors >= maxErrors then
                    print("🛑 Too many errors, stopping auto fishing")
                    if _G.updateStatus then
                        _G.updateStatus("🛑 Stopped: Too many errors", Color3.fromRGB(255, 59, 48))
                    end
                    autoFishRunning = false
                    break
                end
                
                task.wait(5)
            else
                task.wait(0.15)
            end
        end
        
        print("⏹️ Auto fishing stopped")
        if _G.updateStatus then
            _G.updateStatus("⏹️ Auto fishing stopped", Color3.fromRGB(255, 193, 7))
        end
    end)
end

-- Stop Auto Fishing with Status Update
local function stopAutoFish()
    autoFishRunning = false
    local remotes = getRemotes()
    if remotes and remotes.CancelFishing then
        pcall(function()
            remotes.CancelFishing:InvokeServer()
        end)
    end
    print("⏹️ Auto fishing manually stopped")
    if _G.updateStatus then
        _G.updateStatus("⏹️ Auto fishing manually stopped", Color3.fromRGB(255, 193, 7))
    end
end

-- Safe Boat Functions
local function spawnBoat(boatName)
    local remotes = getRemotes()
    if not remotes or not remotes.SpawnBoat then
        warn("SpawnBoat remote not available")
        return false
    end
    
    local success = pcall(function()
        remotes.SpawnBoat:InvokeServer(boatName or "Small Boat")
    end)
    
    if success then
        print("✅ Spawned boat:", boatName or "Small Boat")
    else
        warn("❌ Failed to spawn boat")
    end
    
    return success
end

local function despawnBoat()
    local remotes = getRemotes()
    if not remotes or not remotes.DespawnBoat then
        warn("DespawnBoat remote not available")
        return false
    end
    
    local success = pcall(function()
        remotes.DespawnBoat:InvokeServer()
    end)
    
    if success then
        print("✅ Boat despawned")
    else
        warn("❌ Failed to despawn boat")
    end
    
    return success
end

-- Safe Sell Function
local function sellAllFish()
    local remotes = getRemotes()
    if not remotes or not remotes.SellAll then
        warn("SellAll remote not available")
        return false
    end
    
    local success = pcall(function()
        remotes.SellAll:InvokeServer()
    end)
    
    if success then
        print("✅ All fish sold successfully")
    else
        warn("❌ Failed to sell fish")
    end
    
    return success
end

-- Create Enhanced GUI with Minimize and Floating
local function createGUI()
    -- Remove existing GUI
    local existingGUI = PlayerGui:FindFirstChild("FishingGUI")
    if existingGUI then
        existingGUI:Destroy()
    end
    
    -- Main GUI
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "FishingGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = PlayerGui
    
    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 300, 0, 470)
    MainFrame.Position = UDim2.new(0, 50, 0, 50)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui
    
    -- Corner for main frame
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 12)
    MainCorner.Parent = MainFrame
    
    -- Shadow Frame (for floating effect)
    local ShadowFrame = Instance.new("Frame")
    ShadowFrame.Name = "Shadow"
    ShadowFrame.Size = UDim2.new(1, 6, 1, 6)
    ShadowFrame.Position = UDim2.new(0, -3, 0, -3)
    ShadowFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    ShadowFrame.BackgroundTransparency = 0.7
    ShadowFrame.BorderSizePixel = 0
    ShadowFrame.ZIndex = -1
    ShadowFrame.Parent = MainFrame
    
    local ShadowCorner = Instance.new("UICorner")
    ShadowCorner.CornerRadius = UDim.new(0, 12)
    ShadowCorner.Parent = ShadowFrame
    
    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 40)
    TitleBar.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 12)
    TitleCorner.Parent = TitleBar
    
    -- Fix title bar corners (only top corners)
    local TitleFix = Instance.new("Frame")
    TitleFix.Size = UDim2.new(1, 0, 0, 20)
    TitleFix.Position = UDim2.new(0, 0, 1, -20)
    TitleFix.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    TitleFix.BorderSizePixel = 0
    TitleFix.Parent = TitleBar
    
    -- Title Text
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(0.7, 0, 1, 0)
    Title.Position = UDim2.new(0.05, 0, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "🎣 Enhanced Fishing Script"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextScaled = true
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TitleBar
    
    -- Minimize Button
    local MinimizeBtn = Instance.new("TextButton")
    MinimizeBtn.Name = "MinimizeBtn"
    MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
    MinimizeBtn.Position = UDim2.new(1, -70, 0, 5)
    MinimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 193, 7)
    MinimizeBtn.BorderSizePixel = 0
    MinimizeBtn.Text = "−"
    MinimizeBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    MinimizeBtn.TextScaled = true
    MinimizeBtn.Font = Enum.Font.GothamBold
    MinimizeBtn.Parent = TitleBar
    
    local MinimizeCorner = Instance.new("UICorner")
    MinimizeCorner.CornerRadius = UDim.new(0, 15)
    MinimizeCorner.Parent = MinimizeBtn
    
    -- Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "CloseBtn"
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -35, 0, 5)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 59, 48)
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Text = "×"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.TextScaled = true
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Parent = TitleBar
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 15)
    CloseCorner.Parent = CloseBtn
    
    -- Content Frame
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "Content"
    ContentFrame.Size = UDim2.new(1, 0, 1, -45)
    ContentFrame.Position = UDim2.new(0, 0, 0, 45)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Parent = MainFrame
    
    -- Status Label
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Name = "Status"
    StatusLabel.Size = UDim2.new(0.9, 0, 0, 25)
    StatusLabel.Position = UDim2.new(0.05, 0, 0, 5)
    StatusLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    StatusLabel.BorderSizePixel = 0
    StatusLabel.Text = "🔍 Status: Ready"
    StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 127)
    StatusLabel.TextScaled = true
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.Parent = ContentFrame
    
    local StatusCorner = Instance.new("UICorner")
    StatusCorner.CornerRadius = UDim.new(0, 5)
    StatusCorner.Parent = StatusLabel
    
    -- Buttons
    local buttonData = {
        {"🎣 Start Auto Fish", startAutoFish, Color3.fromRGB(0, 200, 83)},
        {"⏹️ Stop Auto Fish", stopAutoFish, Color3.fromRGB(255, 59, 48)},
        {"⚡ Modify Rod Stats (x999)", function() modifyRodStats(999) end, Color3.fromRGB(255, 149, 0)},
        {"🔍 Inspect Rod Structure", function() 
            local rod = getCurrentRod()
            if rod then
                print("🔍 Inspecting rod:", rod.Name)
                print("📊 Current stats:", getRodStats(rod))
                if _G.updateStatus then
                    _G.updateStatus("🔍 Rod inspection in console", Color3.fromRGB(0, 191, 255))
                end
            else
                warn("No rod found to inspect")
                if _G.updateStatus then
                    _G.updateStatus("❌ No rod to inspect", Color3.fromRGB(255, 59, 48))
                end
            end
        end, Color3.fromRGB(0, 191, 255)},
        {"🚤 Spawn Small Boat", function() spawnBoat("Small Boat") end, Color3.fromRGB(0, 122, 255)},
        {"🛥️ Spawn Large Boat", function() spawnBoat("Large Boat") end, Color3.fromRGB(88, 86, 214)},
        {"❌ Despawn Boat", despawnBoat, Color3.fromRGB(255, 45, 85)},
        {"💰 Sell All Fish", sellAllFish, Color3.fromRGB(255, 204, 0)}
    }
    
    for i, data in ipairs(buttonData) do
        local Button = Instance.new("TextButton")
        Button.Name = "Button" .. i
        Button.Size = UDim2.new(0.9, 0, 0, 40)
        Button.Position = UDim2.new(0.05, 0, 0, 35 + (i-1) * 50)
        Button.BackgroundColor3 = data[3]
        Button.BorderSizePixel = 0
        Button.Text = data[1]
        Button.TextColor3 = Color3.fromRGB(255, 255, 255)
        Button.TextScaled = true
        Button.Font = Enum.Font.GothamSemibold
        Button.Parent = ContentFrame
        
        local ButtonCorner = Instance.new("UICorner")
        ButtonCorner.CornerRadius = UDim.new(0, 8)
        ButtonCorner.Parent = Button
        
        Button.MouseButton1Click:Connect(data[2])
        
        -- Enhanced hover effect
        Button.MouseEnter:Connect(function()
            local originalColor = data[3]
            local hoverColor = Color3.fromRGB(
                math.min(255, originalColor.R * 255 + 30),
                math.min(255, originalColor.G * 255 + 30),
                math.min(255, originalColor.B * 255 + 30)
            )
            TweenService:Create(Button, TweenInfo.new(0.2), {
                BackgroundColor3 = hoverColor,
                Size = UDim2.new(0.92, 0, 0, 42)
            }):Play()
        end)
        
        Button.MouseLeave:Connect(function()
            TweenService:Create(Button, TweenInfo.new(0.2), {
                BackgroundColor3 = data[3],
                Size = UDim2.new(0.9, 0, 0, 40)
            }):Play()
        end)
    end
    
    -- Variables for minimize functionality
    local isMinimized = false
    local originalSize = MainFrame.Size
    local minimizedSize = UDim2.new(0, 300, 0, 40)
    
    -- Minimize functionality
    MinimizeBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        
        if isMinimized then
            MinimizeBtn.Text = "+"
            ContentFrame.Visible = false
            TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
                Size = minimizedSize
            }):Play()
        else
            MinimizeBtn.Text = "−"
            TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
                Size = originalSize
            }):Play()
            task.wait(0.3)
            ContentFrame.Visible = true
        end
    end)
    
    -- Close functionality
    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)
    
    -- Update status function
    _G.updateStatus = function(text, color)
        StatusLabel.Text = text
        StatusLabel.TextColor3 = color or Color3.fromRGB(0, 255, 127)
    end
    
    -- Floating animation
    spawn(function()
        local floating = true
        while MainFrame.Parent and floating do
            TweenService:Create(MainFrame, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                Position = MainFrame.Position + UDim2.new(0, 0, 0, 3)
            }):Play()
            task.wait(2)
        end
    end)
    
    print("✅ Enhanced GUI created successfully with minimize and floating effects")
end

-- Run diagnostics on startup
local function runDiagnostics()
    print("🔍 Running startup diagnostics...")
    
    local player = Players.LocalPlayer
    print("✅ Player:", player.Name)
    
    if player.Character then
        print("✅ Character loaded")
        
        local rod = getCurrentRod()
        if rod then
            print("✅ Rod found:", rod.Name)
            local stats = getRodStats(rod)
            if stats then
                print("✅ Rod stats detected:", stats)
            else
                print("⚠️ No rod stats detected")
            end
        else
            print("⚠️ No rod found")
        end
    else
        print("⚠️ Character not loaded yet")
    end
    
    local remotes = getRemotes()
    if remotes then
        local count = 0
        for name, remote in pairs(remotes) do
            if remote then count = count + 1 end
        end
        print("✅ Remotes found:", count .. "/10")
    else
        print("❌ No remotes found")
    end
    
    print("🔍 Diagnostics complete")
end

-- Global exports
_G.FishingScript = {
    startAutoFish = startAutoFish,
    stopAutoFish = stopAutoFish,
    modifyRodStats = modifyRodStats,
    spawnBoat = spawnBoat,
    despawnBoat = despawnBoat,
    sellFish = sellAllFish,
    getCurrentRod = getCurrentRod,
    getRodStats = getRodStats,
    getRemotes = getRemotes,
    runDiagnostics = runDiagnostics
}

-- Initialize
print("✅ Enhanced Fishing Script loaded successfully!")
print("📋 Available commands:")
print("  _G.FishingScript.startAutoFish() - Start auto fishing")
print("  _G.FishingScript.stopAutoFish() - Stop auto fishing")
print("  _G.FishingScript.modifyRodStats(999) - Modify rod stats")
print("  _G.FishingScript.runDiagnostics() - Run diagnostics")

-- Create GUI and run diagnostics
createGUI()
task.wait(1)
runDiagnostics()

print("🎣 Script ready! Use the GUI or commands above.")
