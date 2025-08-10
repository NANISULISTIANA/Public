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
    
    -- Method 1: Check for equipped tool with specific name pattern
    for _, tool in pairs(character:GetChildren()) do
        if tool:IsA("Tool") and (tool.Name:lower():find("rod") or tool.Name:lower():find("fishing")) then
            return tool
        end
    end
    
    -- Method 2: Check for !!!EQUIPPED_TOOL!!!
    local equippedTool = character:FindFirstChild("!!!EQUIPPED_TOOL!!!")
    if equippedTool then
        return equippedTool
    end
    
    -- Method 3: Check backpack for rods
    local backpack = Player:FindFirstChild("Backpack")
    if backpack then
        for _, tool in pairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and (tool.Name:lower():find("rod") or tool.Name:lower():find("fishing")) then
                -- Prefer equipped tools, but return backpack tools if nothing equipped
                return tool
            end
        end
    end
    
    -- Method 4: Check all tools regardless of name (last resort)
    for _, tool in pairs(character:GetChildren()) do
        if tool:IsA("Tool") then
            return tool
        end
    end
    
    return nil
end

-- Enhanced Rod Stats Detection
local function getRodStats(rod)
    if not rod then return nil end
    
    local stats = {}
    
    -- Method 1: Check rod attributes
    for name, attr in pairs(rod:GetAttributes()) do
        if type(attr) == "number" and (name:lower():find("luck") or name:lower():find("speed") or name:lower():find("weight") or name:lower():find("efficiency") or name:lower():find("power")) then
            stats[name] = attr
        end
    end
    
    -- Method 2: Check children for stats
    local searchContainers = {
        rod:FindFirstChild("Manifest"),
        rod:FindFirstChild("Stats"),
        rod:FindFirstChild("Configuration"),
        rod:FindFirstChild("Properties"),
        rod:FindFirstChild("RodStats"),
        rod:FindFirstChild("FishingStats"),
        rod:FindFirstChild("Handle")
    }
    
    for _, container in pairs(searchContainers) do
        if container then
            -- Check container's direct children
            for _, child in pairs(container:GetChildren()) do
                if child:IsA("NumberValue") or child:IsA("IntValue") then
                    if child.Name:lower():find("luck") or child.Name:lower():find("speed") or child.Name:lower():find("weight") or 
                       child.Name:lower():find("efficiency") or child.Name:lower():find("power") then
                        stats[child.Name] = child.Value
                    end
                elseif child:IsA("StringValue") and tonumber(child.Value) then
                    if child.Name:lower():find("luck") or child.Name:lower():find("speed") or child.Name:lower():find("weight") then
                        stats[child.Name] = tonumber(child.Value)
                    end
                end
            end
            
            -- Check container's attributes
            for name, attr in pairs(container:GetAttributes()) do
                if type(attr) == "number" and (name:lower():find("luck") or name:lower():find("speed") or name:lower():find("weight")) then
                    stats[name] = attr
                end
            end
        end
    end
    
    -- Method 3: Deep search in Handle's children
    local handle = rod:FindFirstChild("Handle")
    if handle then
        for _, child in pairs(handle:GetChildren()) do
            if child:IsA("Folder") or child:IsA("Configuration") then
                for _, subChild in pairs(child:GetChildren()) do
                    if subChild:IsA("NumberValue") or subChild:IsA("IntValue") then
                        if subChild.Name:lower():find("luck") or subChild.Name:lower():find("speed") or subChild.Name:lower():find("weight") then
                            stats[subChild.Name] = subChild.Value
                        end
                    end
                end
            end
        end
    end
    
    return next(stats) and stats or nil
end

-- Enhanced Rod Stats Modification with Better Detection
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

    -- Enhanced stat detection focusing on actual fishing stats
    local function findAndModifyStats(container, containerName)
        if not container then return end
        
        local statNames = {
            -- Primary fishing stats
            "Luck", "luck", "LUCK", "LuckValue", "fishing_luck", "FishingLuck",
            "Speed", "speed", "SPEED", "SpeedValue", "fishing_speed", "FishingSpeed", 
            "Weight", "weight", "WEIGHT", "WeightValue", "fishing_weight", "FishingWeight",
            -- Alternative names
            "LuckStat", "SpeedStat", "WeightStat", "RodLuck", "RodSpeed", "RodWeight",
            "Efficiency", "Power", "Range", "Durability"
        }
        
        -- Check attributes first
        for _, statName in ipairs(statNames) do
            if container:GetAttribute(statName) and type(container:GetAttribute(statName)) == "number" then
                local oldValue = container:GetAttribute(statName)
                if oldValue > 0 then
                    local newValue = oldValue * multiplier
                    container:SetAttribute(statName, newValue)
                    modifiedStats[containerName .. "." .. statName] = {old = oldValue, new = newValue}
                    success = true
                    print("✅ Modified attribute:", statName, oldValue, "→", newValue)
                end
            end
        end
        
        -- Check direct children
        for _, child in pairs(container:GetChildren()) do
            if child:IsA("NumberValue") or child:IsA("IntValue") then
                for _, statName in ipairs(statNames) do
                    if child.Name:lower():find(statName:lower()) or child.Name == statName then
                        local oldValue = child.Value
                        if oldValue > 0 then
                            child.Value = oldValue * multiplier
                            modifiedStats[containerName .. "." .. child.Name] = {old = oldValue, new = child.Value}
                            success = true
                            print("✅ Modified value:", child.Name, oldValue, "→", child.Value)
                        end
                    end
                end
            elseif child:IsA("StringValue") then
                for _, statName in ipairs(statNames) do
                    if child.Name:lower():find(statName:lower()) or child.Name == statName then
                        local oldValue = tonumber(child.Value)
                        if oldValue and oldValue > 0 then
                            child.Value = tostring(oldValue * multiplier)
                            modifiedStats[containerName .. "." .. child.Name] = {old = oldValue, new = oldValue * multiplier}
                            success = true
                            print("✅ Modified string value:", child.Name, oldValue, "→", oldValue * multiplier)
                        end
                    end
                end
            end
        end
    end
    
    -- Try different locations where stats might be stored
    local searchLocations = {
        {rod, "Rod"},
        {rod:FindFirstChild("Handle"), "Handle"},
        {rod:FindFirstChild("Manifest"), "Manifest"},
        {rod:FindFirstChild("Stats"), "Stats"},
        {rod:FindFirstChild("Configuration"), "Configuration"},
        {rod:FindFirstChild("Properties"), "Properties"},
        {rod:FindFirstChild("RodStats"), "RodStats"},
        {rod:FindFirstChild("FishingStats"), "FishingStats"}
    }
    
    for _, location in ipairs(searchLocations) do
        findAndModifyStats(location[1], location[2])
    end
    
    -- Advanced search in Handle's children
    local handle = rod:FindFirstChild("Handle")
    if handle then
        for _, child in pairs(handle:GetChildren()) do
            if child:IsA("Folder") or child:IsA("Configuration") then
                findAndModifyStats(child, "Handle." .. child.Name)
            end
        end
    end
    
    -- Try remote-based modification as backup
    if not success then
        print("🔄 Trying remote-based modification...")
        local remotes = getRemotes()
        if remotes and remotes.ModifyRodStats then
            pcall(function()
                -- Try different stat modification approaches
                local attempts = {
                    {Luck = 999, Speed = 999, Weight = 999},
                    {luck = 999, speed = 999, weight = 999},
                    {LuckValue = 999, SpeedValue = 999, WeightValue = 999}
                }
                
                for _, attempt in ipairs(attempts) do
                    local result = remotes.ModifyRodStats:InvokeServer(attempt)
                    if result then
                        modifiedStats["Remote"] = attempt
                        success = true
                        print("✅ Modified via remote:", result)
                        break
                    end
                end
            end)
        end
    end
    
    -- Force equipment refresh to apply changes
    if success then
        pcall(function()
            local remotes = getRemotes()
            if remotes then
                -- Try to unequip and re-equip rod to refresh stats
                if remotes.UnEquipRod then
                    remotes.UnEquipRod:FireServer()
                    task.wait(0.1)
                end
                if remotes.EquipRod then
                    remotes.EquipRod:FireServer(1)
                end
            end
        end)
    end

    -- Display results
    if success then
        print("✅ Rod stats modified successfully:")
        for statName, values in pairs(modifiedStats) do
            print("  " .. statName .. ": " .. values.old .. " → " .. values.new)
        end
        if _G.updateStatus then
            _G.updateStatus("✅ Rod stats modified! (x" .. multiplier .. ")", Color3.fromRGB(0, 255, 127))
        end
        
        -- Additional verification
        task.wait(0.5)
        print("🔍 Verifying changes...")
        local newStats = getRodStats(rod)
        if newStats then
            print("📊 Current rod stats after modification:")
            for name, value in pairs(newStats) do
                print("  " .. name .. ":", value)
            end
        end
    else
        warn("❌ No modifiable stats found in rod")
        print("🔍 Detailed rod structure analysis:")
        
        local function printStructure(obj, indent, maxDepth)
            indent = indent or ""
            maxDepth = maxDepth or 3
            if #indent > maxDepth * 2 then return end
            
            for _, child in pairs(obj:GetChildren()) do
                print(indent .. "- " .. child.Name .. " (" .. child.ClassName .. ")")
                
                -- Show values
                if child:IsA("NumberValue") or child:IsA("IntValue") then
                    print(indent .. "  Value: " .. tostring(child.Value))
                elseif child:IsA("StringValue") then
                    print(indent .. "  Value: " .. tostring(child.Value))
                end
                
                -- Show attributes
                local attrs = child:GetAttributes()
                if next(attrs) then
                    for name, value in pairs(attrs) do
                        print(indent .. "  @" .. name .. ": " .. tostring(value))
                    end
                end
                
                -- Recurse into children
                if #child:GetChildren() > 0 then
                    printStructure(child, indent .. "  ", maxDepth)
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

-- Teleport Functions
local function teleportToLocation(cframe)
    local success = pcall(function()
        local character = Player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            character.HumanoidRootPart.CFrame = cframe
        else
            error("Character or HumanoidRootPart not found")
        end
    end)
    
    if success then
        print("✅ Teleported successfully!")
        if _G.updateStatus then
            _G.updateStatus("✅ Teleported successfully!", Color3.fromRGB(0, 255, 127))
        end
    else
        warn("❌ Failed to teleport")
        if _G.updateStatus then
            _G.updateStatus("❌ Failed to teleport", Color3.fromRGB(255, 59, 48))
        end
    end
    
    return success
end

local function teleportToPlayer(targetPlayerName)
    local success, result = pcall(function()
        local targetPlayer = nil
        
        -- Find the target player
        for _, player in pairs(Players:GetPlayers()) do
            if player.Name:lower():find(targetPlayerName:lower()) or player.DisplayName:lower():find(targetPlayerName:lower()) then
                targetPlayer = player
                break
            end
        end
        
        if not targetPlayer then
            error("Player '" .. targetPlayerName .. "' not found")
        end
        
        if not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            error("Target player has no character or HumanoidRootPart")
        end
        
        return teleportToLocation(targetPlayer.Character.HumanoidRootPart.CFrame)
    end)
    
    if not success then
        warn("❌ Failed to teleport to player:", result)
        if _G.updateStatus then
            _G.updateStatus("❌ Player teleport failed: " .. tostring(result):sub(1,25), Color3.fromRGB(255, 59, 48))
        end
    end
    
    return success
end

local function teleportToIsland(islandName)
    local success, result = pcall(function()
        -- Common fishing game island locations
        local islandCoordinates = {
            ["Spawn"] = CFrame.new(1.3, 56, -177.9),
            ["Moosewood"] = CFrame.new(373, 179, 430),
            ["Roslit Bay"] = CFrame.new(-1477, 179, 686),
            ["Snowcap Island"] = CFrame.new(2648, 179, 2522),
            ["Mushgrove Swamp"] = CFrame.new(2500, 179, -723),
            ["Vertigo"] = CFrame.new(-112, 179, -1026),
            ["Pharaoh's Den"] = CFrame.new(-1863, 179, 1567),
            ["Desolate Deep"] = CFrame.new(-1751, 179, -2847),
            ["The Depths"] = CFrame.new(1000, -500, -3000),
            ["Ancient Isle"] = CFrame.new(-910, 179, -1123),
            ["Statue Of Sovereignty"] = CFrame.new(41, 177, -1030),
            ["Sunstone Island"] = CFrame.new(-966, 179, -1097),
            ["Forsaken Shores"] = CFrame.new(-2893, 179, 1714),
            ["Altar"] = CFrame.new(1296, 179, -801)
        }
        
        -- Try to find exact match first
        local targetCFrame = islandCoordinates[islandName]
        if targetCFrame then
            return teleportToLocation(targetCFrame)
        end
        
        -- Try to find partial match
        for name, cframe in pairs(islandCoordinates) do
            if name:lower():find(islandName:lower()) then
                print("🔍 Found partial match:", name)
                return teleportToLocation(cframe)
            end
        end
        
        -- Try to find island in workspace
        local islandFolder = workspace:FindFirstChild("!!!! ISLAND LOCATIONS !!!!")
        if islandFolder then
            for _, island in pairs(islandFolder:GetChildren()) do
                if island:IsA("BasePart") and island.Name:lower():find(islandName:lower()) then
                    print("🔍 Found island in workspace:", island.Name)
                    return teleportToLocation(island.CFrame)
                end
            end
        end
        
        error("Island '" .. islandName .. "' not found")
    end)
    
    if not success then
        warn("❌ Failed to teleport to island:", result)
        if _G.updateStatus then
            _G.updateStatus("❌ Island teleport failed: " .. tostring(result):sub(1,25), Color3.fromRGB(255, 59, 48))
        end
    end
    
    return success
end

local function getAvailableIslands()
    local islands = {}
    
    -- Add predefined islands
    local predefinedIslands = {
        "Spawn", "Moosewood", "Roslit Bay", "Snowcap Island", 
        "Mushgrove Swamp", "Vertigo", "Pharaoh's Den", 
        "Desolate Deep", "The Depths", "Ancient Isle",
        "Statue Of Sovereignty", "Sunstone Island", 
        "Forsaken Shores", "Altar"
    }
    
    for _, island in ipairs(predefinedIslands) do
        table.insert(islands, island)
    end
    
    -- Try to find additional islands in workspace
    pcall(function()
        local islandFolder = workspace:FindFirstChild("!!!! ISLAND LOCATIONS !!!!")
        if islandFolder then
            for _, island in pairs(islandFolder:GetChildren()) do
                if island:IsA("BasePart") then
                    -- Avoid duplicates
                    local found = false
                    for _, existing in ipairs(islands) do
                        if existing:lower() == island.Name:lower() then
                            found = true
                            break
                        end
                    end
                    if not found then
                        table.insert(islands, island.Name)
                    end
                end
            end
        end
    end)
    
    return islands
end

local function getAvailablePlayers()
    local players = {}
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= Player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(players, player.Name)
        end
    end
    
    return players
end

-- Create Advanced Teleport Menu
local function createTeleportMenu()
    -- Remove existing teleport menu
    local existingMenu = PlayerGui:FindFirstChild("TeleportMenu")
    if existingMenu then
        existingMenu:Destroy()
    end
    
    -- Create teleport menu GUI
    local TeleportGui = Instance.new("ScreenGui")
    TeleportGui.Name = "TeleportMenu"
    TeleportGui.ResetOnSpawn = false
    TeleportGui.Parent = PlayerGui
    
    -- Main frame
    local MenuFrame = Instance.new("Frame")
    MenuFrame.Name = "MenuFrame"
    MenuFrame.Size = UDim2.new(0, 400, 0, 500)
    MenuFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
    MenuFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MenuFrame.BorderSizePixel = 0
    MenuFrame.Parent = TeleportGui
    
    local MenuCorner = Instance.new("UICorner")
    MenuCorner.CornerRadius = UDim.new(0, 15)
    MenuCorner.Parent = MenuFrame
    
    -- Title bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 40)
    TitleBar.BackgroundColor3 = Color3.fromRGB(128, 0, 128)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MenuFrame
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 15)
    TitleCorner.Parent = TitleBar
    
    local TitleFix = Instance.new("Frame")
    TitleFix.Size = UDim2.new(1, 0, 0, 20)
    TitleFix.Position = UDim2.new(0, 0, 1, -20)
    TitleFix.BackgroundColor3 = Color3.fromRGB(128, 0, 128)
    TitleFix.BorderSizePixel = 0
    TitleFix.Parent = TitleBar
    
    local TitleText = Instance.new("TextLabel")
    TitleText.Size = UDim2.new(0.8, 0, 1, 0)
    TitleText.Position = UDim2.new(0.05, 0, 0, 0)
    TitleText.BackgroundTransparency = 1
    TitleText.Text = "🗺️ Teleport Menu"
    TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleText.TextScaled = true
    TitleText.Font = Enum.Font.GothamBold
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    TitleText.Parent = TitleBar
    
    -- Close button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(0, 30, 0, 30)
    CloseButton.Position = UDim2.new(1, -35, 0, 5)
    CloseButton.BackgroundColor3 = Color3.fromRGB(255, 59, 48)
    CloseButton.BorderSizePixel = 0
    CloseButton.Text = "×"
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.TextScaled = true
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.Parent = TitleBar
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 15)
    CloseCorner.Parent = CloseButton
    
    CloseButton.MouseButton1Click:Connect(function()
        TeleportGui:Destroy()
    end)
    
    -- Tab buttons
    local TabFrame = Instance.new("Frame")
    TabFrame.Size = UDim2.new(1, 0, 0, 40)
    TabFrame.Position = UDim2.new(0, 0, 0, 45)
    TabFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    TabFrame.BorderSizePixel = 0
    TabFrame.Parent = MenuFrame
    
    local IslandTab = Instance.new("TextButton")
    IslandTab.Size = UDim2.new(0.5, 0, 1, 0)
    IslandTab.Position = UDim2.new(0, 0, 0, 0)
    IslandTab.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    IslandTab.BorderSizePixel = 0
    IslandTab.Text = "🏝️ Islands"
    IslandTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    IslandTab.TextScaled = true
    IslandTab.Font = Enum.Font.GothamSemibold
    IslandTab.Parent = TabFrame
    
    local PlayerTab = Instance.new("TextButton")
    PlayerTab.Size = UDim2.new(0.5, 0, 1, 0)
    PlayerTab.Position = UDim2.new(0.5, 0, 0, 0)
    PlayerTab.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    PlayerTab.BorderSizePixel = 0
    PlayerTab.Text = "👥 Players"
    PlayerTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    PlayerTab.TextScaled = true
    PlayerTab.Font = Enum.Font.GothamSemibold
    PlayerTab.Parent = TabFrame
    
    -- Content area
    local ContentArea = Instance.new("ScrollingFrame")
    ContentArea.Size = UDim2.new(1, -20, 1, -100)
    ContentArea.Position = UDim2.new(0, 10, 0, 90)
    ContentArea.BackgroundTransparency = 1
    ContentArea.BorderSizePixel = 0
    ContentArea.ScrollBarThickness = 6
    ContentArea.CanvasSize = UDim2.new(0, 0, 0, 0)
    ContentArea.Parent = MenuFrame
    
    local ContentLayout = Instance.new("UIListLayout")
    ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ContentLayout.Padding = UDim.new(0, 5)
    ContentLayout.Parent = ContentArea
    
    -- Function to create teleport button
    local function createTeleportButton(name, action, color)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, -10, 0, 40)
        button.BackgroundColor3 = color or Color3.fromRGB(70, 70, 70)
        button.BorderSizePixel = 0
        button.Text = name
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextScaled = true
        button.Font = Enum.Font.GothamSemibold
        button.Parent = ContentArea
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 8)
        buttonCorner.Parent = button
        
        button.MouseButton1Click:Connect(function()
            action()
            TeleportGui:Destroy()
        end)
        
        -- Hover effect
        button.MouseEnter:Connect(function()
            local hoverColor = Color3.fromRGB(
                math.min(255, color.R * 255 + 30),
                math.min(255, color.G * 255 + 30),
                math.min(255, color.B * 255 + 30)
            )
            TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor}):Play()
        end)
        
        button.MouseLeave:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
        end)
        
        return button
    end
    
    -- Function to populate islands
    local function showIslands()
        -- Clear content
        for _, child in pairs(ContentArea:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        local islands = getAvailableIslands()
        for _, island in ipairs(islands) do
            createTeleportButton("🏝️ " .. island, function()
                teleportToIsland(island)
            end, Color3.fromRGB(34, 139, 34))
        end
        
        -- Update canvas size
        ContentArea.CanvasSize = UDim2.new(0, 0, 0, #islands * 45)
    end
    
    -- Function to populate players
    local function showPlayers()
        -- Clear content
        for _, child in pairs(ContentArea:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        local players = getAvailablePlayers()
        if #players == 0 then
            local noPlayersLabel = Instance.new("TextLabel")
            noPlayersLabel.Size = UDim2.new(1, 0, 0, 40)
            noPlayersLabel.BackgroundTransparency = 1
            noPlayersLabel.Text = "No players available to teleport to"
            noPlayersLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            noPlayersLabel.TextScaled = true
            noPlayersLabel.Font = Enum.Font.Gotham
            noPlayersLabel.Parent = ContentArea
        else
            for _, playerName in ipairs(players) do
                createTeleportButton("👤 " .. playerName, function()
                    teleportToPlayer(playerName)
                end, Color3.fromRGB(255, 69, 0))
            end
        end
        
        -- Update canvas size
        ContentArea.CanvasSize = UDim2.new(0, 0, 0, math.max(#players, 1) * 45)
    end
    
    -- Tab switching
    IslandTab.MouseButton1Click:Connect(function()
        IslandTab.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        PlayerTab.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        showIslands()
    end)
    
    PlayerTab.MouseButton1Click:Connect(function()
        PlayerTab.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        IslandTab.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        showPlayers()
    end)
    
    -- Make draggable
    local dragToggle = false
    local dragStart = nil
    local startPos = nil
    
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragToggle = true
            dragStart = input.Position
            startPos = MenuFrame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragToggle and input.UserInputType == Enum.UserInputType.MouseMovement and dragStart and startPos then
            local delta = input.Position - dragStart
            MenuFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragToggle = false
        end
    end)
    
    -- Show islands by default
    showIslands()
    
    print("✅ Teleport menu opened")
    if _G.updateStatus then
        _G.updateStatus("📱 Teleport menu opened", Color3.fromRGB(128, 0, 128))
    end
end

-- Create Compact Structured GUI
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
    
    -- Floating Icon Button
    local FloatingIcon = Instance.new("TextButton")
    FloatingIcon.Name = "FloatingIcon"
    FloatingIcon.Size = UDim2.new(0, 50, 0, 50)
    FloatingIcon.Position = UDim2.new(0, 20, 0.5, -25)
    FloatingIcon.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    FloatingIcon.BorderSizePixel = 0
    FloatingIcon.Text = "🎣"
    FloatingIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
    FloatingIcon.TextScaled = true
    FloatingIcon.Font = Enum.Font.GothamBold
    FloatingIcon.Active = true
    FloatingIcon.Draggable = true
    FloatingIcon.Parent = ScreenGui
    
    local IconCorner = Instance.new("UICorner")
    IconCorner.CornerRadius = UDim.new(0, 25)
    IconCorner.Parent = FloatingIcon
    
    -- Main Panel (Compact Design)
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 420, 0, 280)
    MainFrame.Position = UDim2.new(0.5, -210, 0.5, -140)
    MainFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Visible = false
    MainFrame.Parent = ScreenGui
    
    -- Main Frame Corner
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 8)
    MainCorner.Parent = MainFrame
    
    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 30)
    TitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 8)
    TitleCorner.Parent = TitleBar
    
    -- Fix title bar corners (only top corners)
    local TitleFix = Instance.new("Frame")
    TitleFix.Size = UDim2.new(1, 0, 0, 15)
    TitleFix.Position = UDim2.new(0, 0, 1, -15)
    TitleFix.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
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
    Title.Font = Enum.Font.SourceSansBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TitleBar
    
    -- Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "CloseBtn"
    CloseBtn.Size = UDim2.new(0, 25, 0, 25)
    CloseBtn.Position = UDim2.new(1, -28, 0, 2.5)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 40, 34)
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Text = "×"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.TextScaled = true
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Parent = TitleBar
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 12)
    CloseCorner.Parent = CloseBtn
    
    -- Sidebar for Navigation
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 100, 1, -30)
    Sidebar.Position = UDim2.new(0, 0, 0, 30)
    Sidebar.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainFrame
    
    -- Content Area
    local ContentArea = Instance.new("Frame")
    ContentArea.Name = "ContentArea"
    ContentArea.Size = UDim2.new(1, -100, 1, -30)
    ContentArea.Position = UDim2.new(0, 100, 0, 30)
    ContentArea.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    ContentArea.BorderSizePixel = 0
    ContentArea.Parent = MainFrame
    
    -- Create Navigation Buttons
    local navButtons = {"Main", "Teleport", "Boats", "Rod Mod"}
    local currentPage = "Main"
    
    local function createNavButton(name, index)
        local btn = Instance.new("TextButton")
        btn.Name = name .. "Btn"
        btn.Size = UDim2.new(1, -6, 0, 30)
        btn.Position = UDim2.new(0, 3, 0, 5 + (index-1) * 35)
        btn.BackgroundColor3 = name == "Main" and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(0, 0, 0)
        btn.BorderSizePixel = 0
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextScaled = true
        btn.Font = Enum.Font.SourceSansBold
        btn.Parent = Sidebar
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = btn
        
        return btn
    end
    
    -- Create Pages Container
    local Pages = Instance.new("Frame")
    Pages.Name = "Pages"
    Pages.Size = UDim2.new(1, -10, 1, -10)
    Pages.Position = UDim2.new(0, 5, 0, 5)
    Pages.BackgroundTransparency = 1
    Pages.Parent = ContentArea
    
    -- Status Label
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Name = "Status"
    StatusLabel.Size = UDim2.new(1, -10, 0, 25)
    StatusLabel.Position = UDim2.new(0, 5, 1, -30)
    StatusLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    StatusLabel.BorderSizePixel = 0
    StatusLabel.Text = "🔍 Status: Ready"
    StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 127)
    StatusLabel.TextScaled = true
    StatusLabel.Font = Enum.Font.SourceSans
    StatusLabel.Parent = MainFrame
    
    local StatusCorner = Instance.new("UICorner")
    StatusCorner.CornerRadius = UDim.new(0, 4)
    StatusCorner.Parent = StatusLabel
    
    -- Create Pages
    local function createPage(name, isVisible)
        local page = Instance.new("ScrollingFrame")
        page.Name = name .. "Page"
        page.Size = UDim2.new(1, 0, 1, 0)
        page.Position = UDim2.new(0, 0, 0, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 4
        page.Visible = isVisible or false
        page.Parent = Pages
        
        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 5)
        layout.Parent = page
        
        return page
    end
    
    -- Create Main Page
    local MainPage = createPage("Main", true)
    MainPage.CanvasSize = UDim2.new(0, 0, 0, 300)
    
    -- Auto Fish Toggle
    local AutoFishFrame = Instance.new("Frame")
    AutoFishFrame.Size = UDim2.new(1, -10, 0, 40)
    AutoFishFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    AutoFishFrame.BorderSizePixel = 0
    AutoFishFrame.Parent = MainPage
    
    local AFCorner = Instance.new("UICorner")
    AFCorner.CornerRadius = UDim.new(0, 6)
    AFCorner.Parent = AutoFishFrame
    
    local AutoFishLabel = Instance.new("TextLabel")
    AutoFishLabel.Size = UDim2.new(0.7, 0, 1, 0)
    AutoFishLabel.Position = UDim2.new(0, 8, 0, 0)
    AutoFishLabel.BackgroundTransparency = 1
    AutoFishLabel.Text = "🎣 Auto Fish (AFK)"
    AutoFishLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    AutoFishLabel.TextScaled = true
    AutoFishLabel.Font = Enum.Font.SourceSansBold
    AutoFishLabel.TextXAlignment = Enum.TextXAlignment.Left
    AutoFishLabel.Parent = AutoFishFrame
    
    local AutoFishToggle = Instance.new("TextButton")
    AutoFishToggle.Size = UDim2.new(0, 60, 0, 25)
    AutoFishToggle.Position = UDim2.new(1, -70, 0.5, -12.5)
    AutoFishToggle.BackgroundColor3 = Color3.fromRGB(255, 59, 48)
    AutoFishToggle.BorderSizePixel = 0
    AutoFishToggle.Text = "START"
    AutoFishToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    AutoFishToggle.TextScaled = true
    AutoFishToggle.Font = Enum.Font.SourceSansBold
    AutoFishToggle.Parent = AutoFishFrame
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 4)
    ToggleCorner.Parent = AutoFishToggle
    
    -- Main Page Buttons
    local mainButtons = {
        {"💰 Sell All Fish", sellAllFish, Color3.fromRGB(255, 204, 0)},
        {"⚡ Modify Rod Stats (x999)", function() modifyRodStats(999) end, Color3.fromRGB(255, 149, 0)},
        {"🔧 Force Stat Modification", function() 
            local rod = getCurrentRod()
            if not rod then
                warn("No rod equipped!")
                if _G.updateStatus then
                    _G.updateStatus("❌ No rod equipped!", Color3.fromRGB(255, 59, 48))
                end
                return
            end
            
            print("🔧 Force modifying all possible stats...")
            if _G.updateStatus then
                _G.updateStatus("🔧 Force modifying stats...", Color3.fromRGB(255, 149, 0))
            end
            
            local modified = 0
            
            -- Brute force modification - try everything
            for _, child in pairs(rod:GetDescendants()) do
                if child:IsA("NumberValue") or child:IsA("IntValue") then
                    if child.Value > 0 and child.Value < 999 then
                        local oldVal = child.Value
                        child.Value = 999
                        print("Modified " .. child:GetFullName() .. ": " .. oldVal .. " → 999")
                        modified = modified + 1
                    end
                elseif child:IsA("StringValue") and tonumber(child.Value) then
                    local oldVal = tonumber(child.Value)
                    if oldVal and oldVal > 0 and oldVal < 999 then
                        child.Value = "999"
                        print("Modified " .. child:GetFullName() .. ": " .. oldVal .. " → 999")
                        modified = modified + 1
                    end
                end
            end
            
            -- Also try attributes on all descendants
            for _, child in pairs(rod:GetDescendants()) do
                for name, value in pairs(child:GetAttributes()) do
                    if type(value) == "number" and value > 0 and value < 999 then
                        child:SetAttribute(name, 999)
                        print("Modified attribute " .. child:GetFullName() .. "." .. name .. ": " .. value .. " → 999")
                        modified = modified + 1
                    end
                end
            end
            
            if modified > 0 then
                print("✅ Force modified", modified, "stats/attributes")
                if _G.updateStatus then
                    _G.updateStatus("✅ Force modified " .. modified .. " values", Color3.fromRGB(0, 255, 127))
                end
                
                -- Try to refresh by re-equipping
                task.spawn(function()
                    task.wait(0.5)
                    local remotes = getRemotes()
                    if remotes then
                        pcall(function()
                            if remotes.UnEquipRod then remotes.UnEquipRod:FireServer() end
                            task.wait(0.1)
                            if remotes.EquipRod then remotes.EquipRod:FireServer(1) end
                        end)
                    end
                end)
            else
                print("❌ No values found to modify")
                if _G.updateStatus then
                    _G.updateStatus("❌ No values found to modify", Color3.fromRGB(255, 59, 48))
                end
            end
        end, Color3.fromRGB(255, 69, 0)},
        {"🔍 Inspect Rod Structure", function() 
            local rod = getCurrentRod()
            if rod then
                print("🔍 Inspecting rod:", rod.Name)
                print("📊 Current stats:", getRodStats(rod))
                
                -- Advanced rod analysis
                print("🔬 Advanced Rod Analysis:")
                print("Rod Class:", rod.ClassName)
                print("Rod Parent:", rod.Parent and rod.Parent.Name or "None")
                
                -- Show all attributes
                local attrs = rod:GetAttributes()
                if next(attrs) then
                    print("📋 Rod Attributes:")
                    for name, value in pairs(attrs) do
                        print("  " .. name .. ":", value, "(" .. type(value) .. ")")
                    end
                else
                    print("❌ No attributes found on rod")
                end
                
                -- Detailed structure analysis
                local function analyzeContainer(container, path, depth)
                    if depth > 3 then return end
                    
                    for _, child in pairs(container:GetChildren()) do
                        local childPath = path .. "." .. child.Name
                        print(string.rep("  ", depth) .. "└─ " .. child.Name .. " (" .. child.ClassName .. ")")
                        
                        if child:IsA("NumberValue") or child:IsA("IntValue") then
                            print(string.rep("  ", depth + 1) .. "Value: " .. tostring(child.Value))
                        elseif child:IsA("StringValue") then
                            print(string.rep("  ", depth + 1) .. "Value: '" .. tostring(child.Value) .. "'")
                        end
                        
                        local childAttrs = child:GetAttributes()
                        if next(childAttrs) then
                            for name, value in pairs(childAttrs) do
                                print(string.rep("  ", depth + 1) .. "@" .. name .. ": " .. tostring(value))
                            end
                        end
                        
                        if #child:GetChildren() > 0 then
                            analyzeContainer(child, childPath, depth + 1)
                        end
                    end
                end
                
                print("🏗️ Rod Structure:")
                analyzeContainer(rod, "Rod", 0)
                
                if _G.updateStatus then
                    _G.updateStatus("🔍 Rod analysis in console", Color3.fromRGB(0, 191, 255))
                end
            else
                warn("No rod found to inspect")
                if _G.updateStatus then
                    _G.updateStatus("❌ No rod to inspect", Color3.fromRGB(255, 59, 48))
                end
            end
        end, Color3.fromRGB(0, 191, 255)}
    }
    
    for i, data in ipairs(mainButtons) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 35)
        btn.BackgroundColor3 = data[3]
        btn.BorderSizePixel = 0
        btn.Text = data[1]
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextScaled = true
        btn.Font = Enum.Font.SourceSansBold
        btn.Parent = MainPage
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(data[2])
    end
    
    -- Create Teleport Page
    local TeleportPage = createPage("Teleport", false)
    TeleportPage.CanvasSize = UDim2.new(0, 0, 0, 400)
    
    local quickTeleports = {
        {"🏝️ TP to Spawn", function() teleportToIsland("Spawn") end, Color3.fromRGB(0, 191, 255)},
        {"🌊 TP to Moosewood", function() teleportToIsland("Moosewood") end, Color3.fromRGB(34, 139, 34)},
        {"🌹 TP to Roslit Bay", function() teleportToIsland("Roslit Bay") end, Color3.fromRGB(255, 20, 147)},
        {"❄️ TP to Snowcap", function() teleportToIsland("Snowcap Island") end, Color3.fromRGB(135, 206, 250)},
        {"🏜️ TP to Vertigo", function() teleportToIsland("Vertigo") end, Color3.fromRGB(139, 69, 19)},
        {"🗂️ Advanced Teleport Menu", function() createTeleportMenu() end, Color3.fromRGB(128, 0, 128)}
    }
    
    for i, data in ipairs(quickTeleports) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 35)
        btn.BackgroundColor3 = data[3]
        btn.BorderSizePixel = 0
        btn.Text = data[1]
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextScaled = true
        btn.Font = Enum.Font.SourceSansBold
        btn.Parent = TeleportPage
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(data[2])
    end
    
    -- Create Boats Page
    local BoatsPage = createPage("Boats", false)
    BoatsPage.CanvasSize = UDim2.new(0, 0, 0, 200)
    
    local boatButtons = {
        {"🚤 Spawn Small Boat", function() spawnBoat("Small Boat") end, Color3.fromRGB(0, 122, 255)},
        {"🛥️ Spawn Large Boat", function() spawnBoat("Large Boat") end, Color3.fromRGB(88, 86, 214)},
        {"❌ Despawn Boat", despawnBoat, Color3.fromRGB(255, 45, 85)}
    }
    
    for i, data in ipairs(boatButtons) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 35)
        btn.BackgroundColor3 = data[3]
        btn.BorderSizePixel = 0
        btn.Text = data[1]
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextScaled = true
        btn.Font = Enum.Font.SourceSansBold
        btn.Parent = BoatsPage
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(data[2])
    end
    
    -- Create Rod Mod Page
    local RodModPage = createPage("Rod Mod", false)
    RodModPage.CanvasSize = UDim2.new(0, 0, 0, 250)
    
    -- Current Rod Info
    local RodInfoFrame = Instance.new("Frame")
    RodInfoFrame.Size = UDim2.new(1, -10, 0, 60)
    RodInfoFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    RodInfoFrame.BorderSizePixel = 0
    RodInfoFrame.Parent = RodModPage
    
    local RodInfoCorner = Instance.new("UICorner")
    RodInfoCorner.CornerRadius = UDim.new(0, 6)
    RodInfoCorner.Parent = RodInfoFrame
    
    local RodInfoLabel = Instance.new("TextLabel")
    RodInfoLabel.Size = UDim2.new(1, -10, 1, -10)
    RodInfoLabel.Position = UDim2.new(0, 5, 0, 5)
    RodInfoLabel.BackgroundTransparency = 1
    RodInfoLabel.Text = "Current Rod: No rod equipped"
    RodInfoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    RodInfoLabel.TextScaled = true
    RodInfoLabel.Font = Enum.Font.SourceSans
    RodInfoLabel.TextWrapped = true
    RodInfoLabel.TextYAlignment = Enum.TextYAlignment.Top
    RodInfoLabel.Parent = RodInfoFrame
    
    -- Rod Modification Inputs
    local ModInputFrame = Instance.new("Frame")
    ModInputFrame.Size = UDim2.new(1, -10, 0, 80)
    ModInputFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    ModInputFrame.BorderSizePixel = 0
    ModInputFrame.Parent = RodModPage
    
    local ModInputCorner = Instance.new("UICorner")
    ModInputCorner.CornerRadius = UDim.new(0, 6)
    ModInputCorner.Parent = ModInputFrame
    
    -- Quick Mod Values
    local QuickModLabel = Instance.new("TextLabel")
    QuickModLabel.Size = UDim2.new(1, 0, 0, 25)
    QuickModLabel.Position = UDim2.new(0, 0, 0, 0)
    QuickModLabel.BackgroundTransparency = 1
    QuickModLabel.Text = "Quick Modification Values:"
    QuickModLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    QuickModLabel.TextScaled = true
    QuickModLabel.Font = Enum.Font.SourceSansBold
    QuickModLabel.Parent = ModInputFrame
    
    local QuickModButtons = {
        {"x100", 100},
        {"x500", 500},
        {"x999", 999},
        {"x9999", 9999}
    }
    
    for i, data in ipairs(QuickModButtons) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.2, -5, 0, 25)
        btn.Position = UDim2.new((i-1) * 0.25, 0, 0, 30)
        btn.BackgroundColor3 = Color3.fromRGB(255, 149, 0)
        btn.BorderSizePixel = 0
        btn.Text = data[1]
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextScaled = true
        btn.Font = Enum.Font.SourceSansBold
        btn.Parent = ModInputFrame
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            modifyRodStats(data[2])
        end)
    end
    
    -- Advanced Rod Tools
    local advancedRodTools = {
        {"🔧 Force Stat Modification", Color3.fromRGB(255, 69, 0)},
        {"🔍 Inspect Rod Structure", Color3.fromRGB(0, 191, 255)}
    }
    
    for i, data in ipairs(advancedRodTools) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 35)
        btn.BackgroundColor3 = data[2]
        btn.BorderSizePixel = 0
        btn.Text = data[1]
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextScaled = true
        btn.Font = Enum.Font.SourceSansBold
        btn.Parent = RodModPage
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn
        
        if i == 1 then
            btn.MouseButton1Click:Connect(function()
                local rod = getCurrentRod()
                if not rod then
                    warn("No rod equipped!")
                    if _G.updateStatus then
                        _G.updateStatus("❌ No rod equipped!", Color3.fromRGB(255, 59, 48))
                    end
                    return
                end
                
                print("🔧 Force modifying all possible stats...")
                if _G.updateStatus then
                    _G.updateStatus("🔧 Force modifying stats...", Color3.fromRGB(255, 149, 0))
                end
                
                local modified = 0
                
                -- Brute force modification - try everything
                for _, child in pairs(rod:GetDescendants()) do
                    if child:IsA("NumberValue") or child:IsA("IntValue") then
                        if child.Value > 0 and child.Value < 999 then
                            local oldVal = child.Value
                            child.Value = 999
                            print("Modified " .. child:GetFullName() .. ": " .. oldVal .. " → 999")
                            modified = modified + 1
                        end
                    elseif child:IsA("StringValue") and tonumber(child.Value) then
                        local oldVal = tonumber(child.Value)
                        if oldVal and oldVal > 0 and oldVal < 999 then
                            child.Value = "999"
                            print("Modified " .. child:GetFullName() .. ": " .. oldVal .. " → 999")
                            modified = modified + 1
                        end
                    end
                end
                
                -- Also try attributes on all descendants
                for _, child in pairs(rod:GetDescendants()) do
                    for name, value in pairs(child:GetAttributes()) do
                        if type(value) == "number" and value > 0 and value < 999 then
                            child:SetAttribute(name, 999)
                            print("Modified attribute " .. child:GetFullName() .. "." .. name .. ": " .. value .. " → 999")
                            modified = modified + 1
                        end
                    end
                end
                
                if modified > 0 then
                    print("✅ Force modified", modified, "stats/attributes")
                    if _G.updateStatus then
                        _G.updateStatus("✅ Force modified " .. modified .. " values", Color3.fromRGB(0, 255, 127))
                    end
                    
                    -- Try to refresh by re-equipping
                    task.spawn(function()
                        task.wait(0.5)
                        local remotes = getRemotes()
                        if remotes then
                            pcall(function()
                                if remotes.UnEquipRod then remotes.UnEquipRod:FireServer() end
                                task.wait(0.1)
                                if remotes.EquipRod then remotes.EquipRod:FireServer(1) end
                            end)
                        end
                    end)
                else
                    print("❌ No values found to modify")
                    if _G.updateStatus then
                        _G.updateStatus("❌ No values found to modify", Color3.fromRGB(255, 59, 48))
                    end
                end
            end)
        else
            btn.MouseButton1Click:Connect(function()
                local rod = getCurrentRod()
                if rod then
                    print("🔍 Inspecting rod:", rod.Name)
                    print("📊 Current stats:", getRodStats(rod))
                    
                    -- Advanced rod analysis
                    print("🔬 Advanced Rod Analysis:")
                    print("Rod Class:", rod.ClassName)
                    print("Rod Parent:", rod.Parent and rod.Parent.Name or "None")
                    
                    -- Show all attributes
                    local attrs = rod:GetAttributes()
                    if next(attrs) then
                        print("📋 Rod Attributes:")
                        for name, value in pairs(attrs) do
                            print("  " .. name .. ":", value, "(" .. type(value) .. ")")
                        end
                    else
                        print("❌ No attributes found on rod")
                    end
                    
                    -- Detailed structure analysis
                    local function analyzeContainer(container, path, depth)
                        if depth > 3 then return end
                        
                        for _, child in pairs(container:GetChildren()) do
                            local childPath = path .. "." .. child.Name
                            print(string.rep("  ", depth) .. "└─ " .. child.Name .. " (" .. child.ClassName .. ")")
                            
                            if child:IsA("NumberValue") or child:IsA("IntValue") then
                                print(string.rep("  ", depth + 1) .. "Value: " .. tostring(child.Value))
                            elseif child:IsA("StringValue") then
                                print(string.rep("  ", depth + 1) .. "Value: '" .. tostring(child.Value) .. "'")
                            end
                            
                            local childAttrs = child:GetAttributes()
                            if next(childAttrs) then
                                for name, value in pairs(childAttrs) do
                                    print(string.rep("  ", depth + 1) .. "@" .. name .. ": " .. tostring(value))
                                end
                            end
                            
                            if #child:GetChildren() > 0 then
                                analyzeContainer(child, childPath, depth + 1)
                            end
                        end
                    end
                    
                    print("🏗️ Rod Structure:")
                    analyzeContainer(rod, "Rod", 0)
                    
                    if _G.updateStatus then
                        _G.updateStatus("🔍 Rod analysis in console", Color3.fromRGB(0, 191, 255))
                    end
                else
                    warn("No rod found to inspect")
                    if _G.updateStatus then
                        _G.updateStatus("❌ No rod to inspect", Color3.fromRGB(255, 59, 48))
                    end
                end
            end)
        end
    end
    
    -- Page Navigation Functions
    local navBtns = {}
    
    local function switchPage(pageName)
        -- Hide all pages
        for _, page in pairs({MainPage, TeleportPage, BoatsPage, RodModPage}) do
            page.Visible = false
        end
        
        -- Update button colors
        for _, btn in pairs(navBtns) do
            btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        end
        
        -- Show selected page and highlight button
        if pageName == "Main" then
            MainPage.Visible = true
            navBtns[1].BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        elseif pageName == "Teleport" then
            TeleportPage.Visible = true
            navBtns[2].BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        elseif pageName == "Boats" then
            BoatsPage.Visible = true
            navBtns[3].BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        elseif pageName == "Rod Mod" then
            RodModPage.Visible = true
            navBtns[4].BackgroundColor3 = Color3.fromRGB(0, 150, 255)
            -- Update rod info when entering rod mod page
            task.spawn(function()
                local rod = getCurrentRod()
                if rod then
                    local stats = getRodStats(rod)
                    local infoText = "Current Rod: " .. rod.Name
                    if stats then
                        infoText = infoText .. "\nStats detected: " .. tostring(#stats > 0)
                    end
                    RodInfoLabel.Text = infoText
                else
                    RodInfoLabel.Text = "Current Rod: No rod equipped"
                end
            end)
        end
        
        Title.Text = "🎣 Enhanced Fishing - " .. pageName
    end
    
    -- Create Navigation Buttons
    for i, name in ipairs(navButtons) do
        local btn = createNavButton(name, i)
        navBtns[i] = btn
        
        btn.MouseButton1Click:Connect(function()
            switchPage(name)
        end)
    end
    
    -- Auto Fish Toggle Logic
    AutoFishToggle.MouseButton1Click:Connect(function()
        if autoFishRunning then
            stopAutoFish()
            AutoFishToggle.Text = "START"
            AutoFishToggle.BackgroundColor3 = Color3.fromRGB(0, 200, 83)
        else
            startAutoFish()
            AutoFishToggle.Text = "STOP"
            AutoFishToggle.BackgroundColor3 = Color3.fromRGB(255, 59, 48)
        end
    end)
    
    -- Variables for panel visibility
    local isPanelVisible = false
    
    -- Floating Icon Click Functionality
    FloatingIcon.MouseButton1Click:Connect(function()
        isPanelVisible = not isPanelVisible
        
        if isPanelVisible then
            MainFrame.Visible = true
            MainFrame.Size = UDim2.new(0, 0, 0, 0)
            MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
            
            -- Animate opening
            TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 420, 0, 280),
                Position = UDim2.new(0.5, -210, 0.5, -140)
            }):Play()
            
            -- Change icon
            FloatingIcon.Text = "📱"
            FloatingIcon.BackgroundColor3 = Color3.fromRGB(255, 149, 0)
        else
            -- Animate closing
            TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 0, 0, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0)
            }):Play()
            
            task.wait(0.2)
            MainFrame.Visible = false
            
            -- Change icon back
            FloatingIcon.Text = "🎣"
            FloatingIcon.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        end
    end)
    
    -- Close functionality
    CloseBtn.MouseButton1Click:Connect(function()
        isPanelVisible = false
        TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }):Play()
        
        task.wait(0.2)
        MainFrame.Visible = false
        
        -- Change icon back
        FloatingIcon.Text = "🎣"
        FloatingIcon.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    end)
    
    -- Icon hover effects
    FloatingIcon.MouseEnter:Connect(function()
        TweenService:Create(FloatingIcon, TweenInfo.new(0.2), {
            Size = UDim2.new(0, 55, 0, 55)
        }):Play()
    end)
    
    FloatingIcon.MouseLeave:Connect(function()
        TweenService:Create(FloatingIcon, TweenInfo.new(0.2), {
            Size = UDim2.new(0, 50, 0, 50)
        }):Play()
    end)
    
    -- Update status function
    _G.updateStatus = function(text, color)
        StatusLabel.Text = text
        StatusLabel.TextColor3 = color or Color3.fromRGB(0, 255, 127)
    end
    
    -- Gentle floating animation for the icon only
    task.spawn(function()
        while FloatingIcon.Parent do
            TweenService:Create(FloatingIcon, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Rotation = 3
            }):Play()
            task.wait(3)
            TweenService:Create(FloatingIcon, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Rotation = -3
            }):Play()
            task.wait(3)
        end
    end)
    
    print("✅ Compact structured GUI created")
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
    runDiagnostics = runDiagnostics,
    teleportToLocation = teleportToLocation,
    teleportToPlayer = teleportToPlayer,
    teleportToIsland = teleportToIsland,
    getAvailableIslands = getAvailableIslands,
    getAvailablePlayers = getAvailablePlayers,
    createTeleportMenu = createTeleportMenu
}

-- Initialize
print("✅ Enhanced Fishing Script loaded successfully!")
print("📋 Available commands:")
print("  _G.FishingScript.startAutoFish() - Start auto fishing")
print("  _G.FishingScript.stopAutoFish() - Stop auto fishing")
print("  _G.FishingScript.modifyRodStats(999) - Modify rod stats")
print("  _G.FishingScript.createTeleportMenu() - Open teleport menu")
print("  _G.FishingScript.teleportToIsland('IslandName') - Teleport to island")
print("  _G.FishingScript.teleportToPlayer('PlayerName') - Teleport to player")
print("  _G.FishingScript.getAvailableIslands() - List available islands")
print("  _G.FishingScript.runDiagnostics() - Run diagnostics")

-- Create GUI and run diagnostics
createGUI()
task.wait(1)
runDiagnostics()

print("🎣 Script ready! Use the GUI or commands above.")
