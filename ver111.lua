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

-- Safe Rod Stats Modification
local function modifyRodStats(multiplier)
    local rod = getCurrentRod()
    if not rod then
        warn("No rod found for stats modification")
        return false
    end
    
    local stats = getRodStats(rod)
    if not stats then
        warn("No stats found in rod:", rod.Name)
        return false
    end
    
    print("Found rod stats:", stats)
    
    local remotes = getRemotes()
    if not remotes or not remotes.ModifyRodStats then
        warn("ModifyRodStats remote not found")
        return false
    end
    
    local success = pcall(function()
        remotes.ModifyRodStats:InvokeServer(rod, multiplier)
    end)
    
    if success then
        print("✅ Rod stats modified successfully")
    else
        warn("❌ Failed to modify rod stats")
    end
    
    return success
end

-- Enhanced Auto Fishing
local function startAutoFish()
    if autoFishRunning then
        print("Auto fishing already running!")
        return
    end
    
    autoFishRunning = true
    print("🎣 Starting enhanced auto fishing...")
    
    local consecutiveErrors = 0
    local maxErrors = 3
    
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
                
                if consecutiveErrors >= maxErrors then
                    print("🛑 Too many errors, stopping auto fishing")
                    autoFishRunning = false
                    break
                end
                
                task.wait(5)
            else
                task.wait(0.15)
            end
        end
        
        print("⏹️ Auto fishing stopped")
    end)
end

-- Stop Auto Fishing
local function stopAutoFish()
    autoFishRunning = false
    local remotes = getRemotes()
    if remotes and remotes.CancelFishing then
        pcall(function()
            remotes.CancelFishing:InvokeServer()
        end)
    end
    print("⏹️ Auto fishing manually stopped")
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

-- Create GUI
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
    MainFrame.Size = UDim2.new(0, 300, 0, 400)
    MainFrame.Position = UDim2.new(0, 50, 0, 50)
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui
    
    -- Corner for main frame
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 10)
    MainCorner.Parent = MainFrame
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, 0, 0, 50)
    Title.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
    Title.BorderSizePixel = 0
    Title.Text = "🎣 Enhanced Fishing Script"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextScaled = true
    Title.Font = Enum.Font.GothamBold
    Title.Parent = MainFrame
    
    -- Title corner
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 10)
    TitleCorner.Parent = Title
    
    -- Buttons
    local buttonData = {
        {"🎣 Start Auto Fish", startAutoFish},
        {"⏹️ Stop Auto Fish", stopAutoFish},
        {"⚡ Modify Rod Stats (x999)", function() modifyRodStats(999) end},
        {"🚤 Spawn Small Boat", function() spawnBoat("Small Boat") end},
        {"🛥️ Spawn Large Boat", function() spawnBoat("Large Boat") end},
        {"❌ Despawn Boat", despawnBoat},
        {"💰 Sell All Fish", sellAllFish}
    }
    
    for i, data in ipairs(buttonData) do
        local Button = Instance.new("TextButton")
        Button.Name = "Button" .. i
        Button.Size = UDim2.new(0.9, 0, 0, 40)
        Button.Position = UDim2.new(0.05, 0, 0, 60 + (i-1) * 50)
        Button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        Button.BorderSizePixel = 0
        Button.Text = data[1]
        Button.TextColor3 = Color3.fromRGB(255, 255, 255)
        Button.TextScaled = true
        Button.Font = Enum.Font.Gotham
        Button.Parent = MainFrame
        
        local ButtonCorner = Instance.new("UICorner")
        ButtonCorner.CornerRadius = UDim.new(0, 5)
        ButtonCorner.Parent = Button
        
        Button.MouseButton1Click:Connect(data[2])
        
        -- Hover effect
        Button.MouseEnter:Connect(function()
            TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 70, 70)}):Play()
        end)
        
        Button.MouseLeave:Connect(function()
            TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
        end)
    end
    
    print("✅ GUI created successfully")
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
