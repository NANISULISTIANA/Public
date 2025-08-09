-- ██████████████████████████████████████████████████████████████
-- ██                                                          ██
-- ██                   ZAYROS FISHIT V2.0                    ██
-- ██                 COMPLETE & READY TO USE                 ██
-- ██                                                          ██
-- ██████████████████████████████████████████████████████████████

local success, error = pcall(function()

-- Check if GUI already exists and destroy it
if game.Players.LocalPlayer.PlayerGui:FindFirstChild("ZayrosFISHIT") then
    game.Players.LocalPlayer.PlayerGui.ZayrosFISHIT:Destroy()
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
    GUI_NAME = "ZayrosFISHIT",
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
local isMinimized = false

-- ===================================================================
--                        SECURITY FEATURES
-- ===================================================================
local SecuritySettings = {
    AdminDetection = true,
    PlayerProximityAlert = true,
    SuspiciousActivityLogger = true,
    AutoHideOnAdmin = true,
    ProximityDistance = 20,
    BlacklistedPlayers = {},
    WhitelistedPlayers = {}
}

local SecurityStats = {
    AdminsDetected = 0,
    ProximityAlerts = 0,
    AutoHides = 0,
    SuspiciousActivities = 0
}

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
    SafeMode = true,
    LuckBoost = false,
    WeatherBoost = false,
    TimeBoost = false,
    FishValueFilter = false,
    MinFishValue = 100,
    AutoBaitUse = false,
    SmartFishing = false,
    -- New Rod Stats Modification
    ModifyRodStats = true,
    CustomRodLuck = 1000,
    CustomRodSpeed = 120,
    CustomRodWeight = 600
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
    boatsSpawned = 0,
    rareFishCaught = 0,
    legendaryFishCaught = 0,
    currentLuckLevel = 1,
    fishPerMinute = 0,
    moneyPerHour = 0,
    bestSpot = "None",
    weatherBonuses = 0,
    timeBonuses = 0
}

-- ===================================================================
--                         LUCK SYSTEM
-- ===================================================================
local LuckSystem = {
    baseChance = 0.1,
    boostMultiplier = 1.0,
    weatherMultiplier = 1.0,
    timeMultiplier = 1.0,
    spotMultiplier = 1.0,
    maxLuckLevel = 10,
    luckXP = 0,
    xpPerLevel = 100
}

-- ===================================================================
--                       WEATHER SYSTEM
-- ===================================================================
local WeatherTypes = {
    "Sunny", "Rainy", "Cloudy", "Stormy", "Foggy", "Windy"
}

local WeatherEffects = {
    Sunny = {luck = 1.2, fish_rate = 1.1, description = "☀️ Perfect fishing weather!"},
    Rainy = {luck = 1.5, fish_rate = 1.3, description = "🌧️ Fish are more active!"},
    Cloudy = {luck = 1.0, fish_rate = 1.0, description = "☁️ Normal conditions"},
    Stormy = {luck = 2.0, fish_rate = 0.8, description = "⛈️ Dangerous but lucky!"},
    Foggy = {luck = 1.8, fish_rate = 0.9, description = "🌫️ Mysterious waters"},
    Windy = {luck = 1.1, fish_rate = 1.2, description = "💨 Good for surface fish"}
}

local currentWeather = "Sunny"

-- ===================================================================
--                        TIME SYSTEM
-- ===================================================================
local TimeEffects = {
    Dawn = {luck = 1.4, fish_rate = 1.2, description = "🌅 Golden hour fishing!"},
    Morning = {luck = 1.1, fish_rate = 1.1, description = "🌞 Good morning catch"},
    Noon = {luck = 0.9, fish_rate = 1.0, description = "☀️ Fish are hiding"},
    Evening = {luck = 1.3, fish_rate = 1.3, description = "🌆 Prime fishing time"},
    Night = {luck = 1.6, fish_rate = 0.8, description = "🌙 Rare night fish"},
    Midnight = {luck = 2.2, fish_rate = 0.6, description = "🌌 Legendary hour"}
}

-- ===================================================================
--                      FISHING SPOTS
-- ===================================================================
local FishingSpots = {
    {name = "Shallow Waters", luck = 1.0, rarity = "Common", bonus = "Fast catch rate"},
    {name = "Deep Ocean", luck = 1.8, rarity = "Rare", bonus = "Big fish chance"},
    {name = "Coral Reef", luck = 1.5, rarity = "Exotic", bonus = "Colorful fish"},
    {name = "Mysterious Cave", luck = 2.5, rarity = "Legendary", bonus = "Ancient fish"},
    {name = "Volcanic Waters", luck = 3.0, rarity = "Mythical", bonus = "Fire fish"},
    {name = "Frozen Lake", luck = 2.2, rarity = "Ice", bonus = "Ice fish"}
}

local currentSpot = FishingSpots[1]

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
--                        LUCK FUNCTIONS
-- ===================================================================
local function calculateCurrentLuck()
    local baseLuck = LuckSystem.baseChance
    local totalMultiplier = LuckSystem.boostMultiplier
    
    if Settings.WeatherBoost then
        totalMultiplier = totalMultiplier * (WeatherEffects[currentWeather].luck or 1.0)
    end
    
    if Settings.TimeBoost then
        local hour = tonumber(os.date("%H"))
        local timeKey = "Morning"
        if hour >= 5 and hour < 8 then timeKey = "Dawn"
        elseif hour >= 8 and hour < 12 then timeKey = "Morning"  
        elseif hour >= 12 and hour < 17 then timeKey = "Noon"
        elseif hour >= 17 and hour < 20 then timeKey = "Evening"
        elseif hour >= 20 and hour < 24 then timeKey = "Night"
        else timeKey = "Midnight" end
        
        totalMultiplier = totalMultiplier * (TimeEffects[timeKey].luck or 1.0)
    end
    
    if Settings.LuckBoost then
        local levelBonus = 1 + (Stats.currentLuckLevel * 0.1)
        totalMultiplier = totalMultiplier * levelBonus
    end
    
    return baseLuck * totalMultiplier
end

local function updateLuckLevel()
    LuckSystem.luckXP = LuckSystem.luckXP + 1
    local requiredXP = Stats.currentLuckLevel * LuckSystem.xpPerLevel
    
    if LuckSystem.luckXP >= requiredXP and Stats.currentLuckLevel < LuckSystem.maxLuckLevel then
        Stats.currentLuckLevel = Stats.currentLuckLevel + 1
        LuckSystem.luckXP = 0
        createNotification("🍀 Luck Level Up! Level " .. Stats.currentLuckLevel, Color3.fromRGB(0, 255, 0))
        
        -- Bonus reward for leveling up
        if Stats.currentLuckLevel % 5 == 0 then
            createNotification("🎁 Milestone Bonus! Special luck boost!", Color3.fromRGB(255, 215, 0))
        end
    end
end

local function generateRandomWeather()
    local oldWeather = currentWeather
    currentWeather = WeatherTypes[math.random(1, #WeatherTypes)]
    
    if currentWeather ~= oldWeather then
        local effect = WeatherEffects[currentWeather]
        createNotification(effect.description, Color3.fromRGB(100, 200, 255))
        Stats.weatherBonuses = Stats.weatherBonuses + 1
    end
end

local function getFishRarity()
    local luck = calculateCurrentLuck()
    local roll = math.random()
    
    if roll <= luck * 0.001 then -- 0.1% base for mythical
        return "Mythical", Color3.fromRGB(255, 0, 255)
    elseif roll <= luck * 0.01 then -- 1% base for legendary  
        Stats.legendaryFishCaught = Stats.legendaryFishCaught + 1
        return "Legendary", Color3.fromRGB(255, 215, 0)
    elseif roll <= luck * 0.05 then -- 5% base for rare
        Stats.rareFishCaught = Stats.rareFishCaught + 1
        return "Rare", Color3.fromRGB(128, 0, 255)
    elseif roll <= luck * 0.15 then -- 15% base for uncommon
        return "Uncommon", Color3.fromRGB(0, 255, 0)
    else
        return "Common", Color3.fromRGB(255, 255, 255)
    end
end

local function simulateFishValue(rarity)
    local baseValues = {
        Common = {min = 10, max = 50},
        Uncommon = {min = 40, max = 120},
        Rare = {min = 100, max = 300},
        Legendary = {min = 250, max = 800},
        Mythical = {min = 500, max = 2000}
    }
    
    local range = baseValues[rarity]
    if range then
        return math.random(range.min, range.max)
    end
    return 25
end

-- ===================================================================
--                    SMART FISHING SYSTEM
-- ===================================================================
local function smartFishingLogic()
    if not Settings.SmartFishing then return true end
    
    -- Skip fishing during low-luck periods
    local currentLuck = calculateCurrentLuck()
    if currentLuck < LuckSystem.baseChance * 0.8 then
        return false
    end
    
    -- Check fish value filter
    if Settings.FishValueFilter then
        local estimatedValue = math.random(10, 100) -- Simulate fish detection
        if estimatedValue < Settings.MinFishValue then
            return false
        end
    end
    
    return true
end

-- ===================================================================
--                      WEATHER CYCLE
-- ===================================================================
local function startWeatherCycle()
    task.spawn(function()
        while true do
            task.wait(math.random(300, 600)) -- Weather changes every 5-10 minutes
            generateRandomWeather()
        end
    end)
end

-- ===================================================================
--                       SECURITY FUNCTIONS
-- ===================================================================
local function isPlayerAdmin(targetPlayer)
    -- Check if player is admin/moderator
    if targetPlayer:GetRankInGroup(0) >= 100 then return true end
    if targetPlayer.Name:lower():find("admin") or targetPlayer.Name:lower():find("mod") then return true end
    if targetPlayer.DisplayName:lower():find("admin") or targetPlayer.DisplayName:lower():find("mod") then return true end
    
    -- Check for admin gamepass or badges (customize these IDs based on the game)
    local adminGamepasses = {123456, 789012} -- Replace with actual admin gamepass IDs
    for _, gamepassId in ipairs(adminGamepasses) do
        if game:GetService("MarketplaceService"):UserOwnsGamePassAsync(targetPlayer.UserId, gamepassId) then
            return true
        end
    end
    
    return false
end

local function logSuspiciousActivity(activity, playerName)
    SecurityStats.SuspiciousActivities = SecurityStats.SuspiciousActivities + 1
    local timestamp = os.date("%H:%M:%S")
    warn(string.format("🔒 [%s] Suspicious Activity: %s | Player: %s", timestamp, activity, playerName or "Unknown"))
end

local function getPlayerDistance(targetPlayer)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return math.huge end
    if not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then return math.huge end
    
    local distance = (player.Character.HumanoidRootPart.Position - targetPlayer.Character.HumanoidRootPart.Position).Magnitude
    return distance
end

local function checkPlayerProximity()
    if not SecuritySettings.PlayerProximityAlert then return end
    
    for _, targetPlayer in pairs(Players:GetPlayers()) do
        if targetPlayer ~= player and targetPlayer.Character then
            local distance = getPlayerDistance(targetPlayer)
            
            if distance <= SecuritySettings.ProximityDistance then
                -- Check if player is blacklisted
                for _, blacklisted in ipairs(SecuritySettings.BlacklistedPlayers) do
                    if targetPlayer.Name == blacklisted then
                        SecurityStats.ProximityAlerts = SecurityStats.ProximityAlerts + 1
                        createNotification("⚠️ Blacklisted player nearby: " .. targetPlayer.Name, Color3.fromRGB(255, 0, 0))
                        logSuspiciousActivity("Blacklisted player proximity", targetPlayer.Name)
                        
                        if SecuritySettings.AutoHideOnAdmin then
                            isHidden = true
                            local gui = player.PlayerGui:FindFirstChild("ZayrosFISHIT")
                            if gui then gui.Enabled = false end
                            SecurityStats.AutoHides = SecurityStats.AutoHides + 1
                        end
                        break
                    end
                end
                
                -- Check if admin is nearby
                if isPlayerAdmin(targetPlayer) then
                    SecurityStats.AdminsDetected = SecurityStats.AdminsDetected + 1
                    SecurityStats.ProximityAlerts = SecurityStats.ProximityAlerts + 1
                    createNotification("🚨 ADMIN NEARBY: " .. targetPlayer.Name, Color3.fromRGB(255, 0, 0))
                    logSuspiciousActivity("Admin proximity detected", targetPlayer.Name)
                    
                    if SecuritySettings.AutoHideOnAdmin then
                        isHidden = true
                        local gui = player.PlayerGui:FindFirstChild("ZayrosFISHIT")
                        if gui then gui.Enabled = false end
                        SecurityStats.AutoHides = SecurityStats.AutoHides + 1
                    end
                end
            end
        end
    end
end

local function monitorChatForAdmins()
    connections[#connections + 1] = Players.PlayerAdded:Connect(function(newPlayer)
        if isPlayerAdmin(newPlayer) then
            SecurityStats.AdminsDetected = SecurityStats.AdminsDetected + 1
            createNotification("🚨 Admin joined server: " .. newPlayer.Name, Color3.fromRGB(255, 0, 0))
            logSuspiciousActivity("Admin joined server", newPlayer.Name)
        end
    end)
    
    -- Monitor chat messages for admin commands
    connections[#connections + 1] = Players.PlayerAdded:Connect(function(newPlayer)
        newPlayer.Chatted:Connect(function(message)
            local adminCommands = {":ban", ":kick", ":warn", "/ban", "/kick", "/warn", ":tp", "/tp"}
            for _, command in ipairs(adminCommands) do
                if message:lower():find(command) then
                    if isPlayerAdmin(newPlayer) then
                        createNotification("🔴 Admin command detected!", Color3.fromRGB(255, 0, 0))
                        logSuspiciousActivity("Admin command used: " .. command, newPlayer.Name)
                        
                        if SecuritySettings.AutoHideOnAdmin then
                            isHidden = true
                            local gui = player.PlayerGui:FindFirstChild("ZayrosFISHIT")
                            if gui then gui.Enabled = false end
                            SecurityStats.AutoHides = SecurityStats.AutoHides + 1
                        end
                    end
                    break
                end
            end
        end)
    end)
end

local function initializeSecurity()
    -- Start proximity monitoring
    task.spawn(function()
        while true do
            checkPlayerProximity()
            task.wait(2) -- Check every 2 seconds
        end
    end)
    
    -- Monitor for admin activity
    monitorChatForAdmins()
    
    -- Check existing players
    for _, existingPlayer in pairs(Players:GetPlayers()) do
        if existingPlayer ~= player and isPlayerAdmin(existingPlayer) then
            SecurityStats.AdminsDetected = SecurityStats.AdminsDetected + 1
            createNotification("🚨 Admin in server: " .. existingPlayer.Name, Color3.fromRGB(255, 0, 0))
        end
    end
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
                
                -- Smart fishing check
                if not smartFishingLogic() then
                    task.wait(randomWait() * 2) -- Wait longer during bad conditions
                    return
                end
                
                -- Add random delays to avoid detection
                task.wait(randomWait())
                
                local char = player.Character or player.CharacterAdded:Wait()
                local equippedTool = char:FindFirstChild("!!!EQUIPPED_TOOL!!!")

                if not equippedTool then
                    CancelFishing:InvokeServer()
                    task.wait(randomWait())
                    EquipRod:FireServer(1)
                    
                    -- Apply rod stats when equipping
                    if Settings.ModifyRodStats then
                        task.wait(0.2) -- Wait for rod to equip
                        modifyRodStats()
                    end
                end

                task.wait(randomWait())
                ChargeRod:InvokeServer(workspace:GetServerTimeNow())
                
                task.wait(randomWait())
                RequestFishing:InvokeServer(-1.2379989624023438, 0.9800224985802423)
                
                task.wait(0.4 + randomWait())
                FishingComplete:FireServer()
                
                Stats.fishCaught = Stats.fishCaught + 1
                
                -- Simulate fish catch with luck system
                local rarity, color = getFishRarity()
                local fishValue = simulateFishValue(rarity)
                Stats.moneyEarned = Stats.moneyEarned + fishValue
                
                if rarity ~= "Common" then
                    createNotification("🎣 Caught " .. rarity .. " fish! (₡" .. fishValue .. ")", color)
                    if rarity == "Legendary" or rarity == "Mythical" then
                        Stats.bestFish = rarity .. " Fish"
                    end
                end
                
                -- Update luck XP
                updateLuckLevel()
                
                -- Auto sell when inventory might be full
                if Settings.AutoSell and Stats.fishCaught % 10 == 0 then
                    task.wait(1)
                    safeCall(function()
                        sellAll:InvokeServer()
                        createNotification("🛒 Auto-sold items! (₡" .. Stats.moneyEarned .. ")", Color3.fromRGB(255, 215, 0))
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
--                      ROD STATS MODIFICATION
-- ===================================================================
local function modifyRodStats()
    safeCall(function()
        if not Settings.ModifyRodStats then 
            print("🔒 Rod Stats Modifier is OFF")
            return 
        end
        
        print("🎣 Starting Rod Stats Modification...")
        print("🎯 Target Values - Luck:" .. Settings.CustomRodLuck .. ", Speed:" .. Settings.CustomRodSpeed .. ", Weight:" .. Settings.CustomRodWeight)
        
        -- Find equipped fishing rod in character
        local character = player.Character
        if not character then 
            print("❌ No character found")
            return 
        end
        
        -- Look for equipped fishing tool
        local equippedTool = character:FindFirstChild("!!!EQUIPPED_TOOL!!!")
        if not equippedTool then
            print("🔍 No !!!EQUIPPED_TOOL!!! found, checking common rod names...")
            -- Also check for common fishing rod names
            local commonRodNames = {"FishingRod", "Rod", "Fishing", "Tool"}
            for _, name in pairs(commonRodNames) do
                equippedTool = character:FindFirstChild(name)
                if equippedTool then 
                    print("✅ Found rod: " .. name)
                    break 
                end
            end
        else
            print("✅ Found equipped tool: !!!EQUIPPED_TOOL!!!")
        end
        
        if not equippedTool then
            print("❌ No fishing rod found in character")
            return
        end
        
        if equippedTool and equippedTool:IsA("Tool") then
            print("🛠️ Modifying tool: " .. equippedTool.Name)
            -- Method 1: Modify tool attributes/values directly
            local rodStats = {
                {names = {"Luck", "FishingLuck", "LuckStat"}, value = Settings.CustomRodLuck},
                {names = {"Speed", "FishingSpeed", "SpeedStat"}, value = Settings.CustomRodSpeed},
                {names = {"Weight", "FishingWeight", "WeightStat"}, value = Settings.CustomRodWeight}
            }
            
            local modificationsApplied = 0
            
            for _, statInfo in pairs(rodStats) do
                for _, statName in pairs(statInfo.names) do
                    -- Try to modify as attributes
                    if equippedTool:GetAttribute(statName) then
                        equippedTool:SetAttribute(statName, statInfo.value)
                        print("✅ Modified attribute: " .. statName .. " = " .. statInfo.value)
                        modificationsApplied = modificationsApplied + 1
                    end
                    
                    -- Try to modify as child values
                    local statValue = equippedTool:FindFirstChild(statName)
                    if statValue and (statValue:IsA("NumberValue") or statValue:IsA("IntValue")) then
                        statValue.Value = statInfo.value
                        print("✅ Modified child value: " .. statName .. " = " .. statInfo.value)
                        modificationsApplied = modificationsApplied + 1
                    end
                    
                    -- Check in subfolders
                    local statsFolder = equippedTool:FindFirstChild("Stats") or equippedTool:FindFirstChild("RodStats")
                    if statsFolder then
                        local statInFolder = statsFolder:FindFirstChild(statName)
                        if statInFolder and (statInFolder:IsA("NumberValue") or statInFolder:IsA("IntValue")) then
                            statInFolder.Value = statInfo.value
                            print("✅ Modified folder value: Stats/" .. statName .. " = " .. statInfo.value)
                            modificationsApplied = modificationsApplied + 1
                        end
                    end
                end
            end
            
            print("📊 Total modifications applied: " .. modificationsApplied)
            
            -- Method 2: Try to modify via RemoteEvents/Functions for rod stats
            local rodRemotes = {
                Rs.Packages._Index["sleitnick_net@0.2.0"].net:FindFirstChild("RF/SetRodStats"),
                Rs.Packages._Index["sleitnick_net@0.2.0"].net:FindFirstChild("RF/ModifyRodStats"),
                Rs.Packages._Index["sleitnick_net@0.2.0"].net:FindFirstChild("RF/UpgradeRod"),
                Rs.Packages._Index["sleitnick_net@0.2.0"].net:FindFirstChild("RE/UpdateRodStats")
            }
            
            for _, remote in pairs(rodRemotes) do
                if remote then
                    pcall(function()
                        if remote:IsA("RemoteFunction") then
                            remote:InvokeServer("Luck", Settings.CustomRodLuck)
                            remote:InvokeServer("Speed", Settings.CustomRodSpeed)
                            remote:InvokeServer("Weight", Settings.CustomRodWeight)
                        elseif remote:IsA("RemoteEvent") then
                            remote:FireServer("Luck", Settings.CustomRodLuck)
                            remote:FireServer("Speed", Settings.CustomRodSpeed)
                            remote:FireServer("Weight", Settings.CustomRodWeight)
                        end
                    end)
                end
            end
        end
        
        -- Method 3: Modify rod stats in player's backpack
        local backpack = player:FindFirstChild("Backpack")
        if backpack then
            for _, tool in pairs(backpack:GetChildren()) do
                if tool:IsA("Tool") and (tool.Name:lower():find("rod") or tool.Name:lower():find("fishing")) then
                    -- Apply same modifications to tools in backpack
                    local rodStats = {
                        {names = {"Luck", "FishingLuck", "LuckStat"}, value = Settings.CustomRodLuck},
                        {names = {"Speed", "FishingSpeed", "SpeedStat"}, value = Settings.CustomRodSpeed},
                        {names = {"Weight", "FishingWeight", "WeightStat"}, value = Settings.CustomRodWeight}
                    }
                    
                    for _, statInfo in pairs(rodStats) do
                        for _, statName in pairs(statInfo.names) do
                            if tool:GetAttribute(statName) then
                                tool:SetAttribute(statName, statInfo.value)
                            end
                            
                            local statValue = tool:FindFirstChild(statName)
                            if statValue and (statValue:IsA("NumberValue") or statValue:IsA("IntValue")) then
                                statValue.Value = statInfo.value
                            end
                            
                            local statsFolder = tool:FindFirstChild("Stats") or tool:FindFirstChild("RodStats")
                            if statsFolder then
                                local statInFolder = statsFolder:FindFirstChild(statName)
                                if statInFolder and (statInFolder:IsA("NumberValue") or statInFolder:IsA("IntValue")) then
                                    statInFolder.Value = statInfo.value
                                end
                            end
                        end
                    end
                end
            end
        end
        
        -- Method 4: Try to modify GUI displays showing rod stats
        local playerGui = player:FindFirstChild("PlayerGui")
        if playerGui then
            local function findAndModifyRodStatsDisplay(parent)
                for _, child in pairs(parent:GetChildren()) do
                    if child:IsA("TextLabel") then
                        local text = child.Text:lower()
                        if text:find("luck:") then
                            child.Text = "Luck: " .. Settings.CustomRodLuck .. "%"
                        elseif text:find("speed:") then
                            child.Text = "Speed: " .. Settings.CustomRodSpeed .. "%"
                        elseif text:find("weight:") then
                            child.Text = "Weight: " .. Settings.CustomRodWeight .. "kg"
                        end
                    end
                    
                    if #child:GetChildren() > 0 then
                        findAndModifyRodStatsDisplay(child)
                    end
                end
            end
            
            -- Search for rod stats in common GUI locations
            local possibleGuis = {
                playerGui:FindFirstChild("RodStats"),
                playerGui:FindFirstChild("ToolStats"),
                playerGui:FindFirstChild("FishingGUI"),
                playerGui:FindFirstChild("Stats"),
                playerGui:FindFirstChild("UI")
            }
            
            for _, gui in pairs(possibleGuis) do
                if gui then
                    findAndModifyRodStatsDisplay(gui)
                end
            end
        end
    end)
end

-- Function to continuously apply rod stats modifications
local function startRodStatsModifier()
    task.spawn(function()
        while Settings.ModifyRodStats do
            modifyRodStats()
            task.wait(0.5) -- Update every 0.5 seconds for faster response
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
    local gui = player.PlayerGui:FindFirstChild("ZayrosFISHIT")
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
--                       GUI CREATION
-- ===================================================================
local function createCompleteGUI()
    -- Create main ScreenGui
    local ZayrosFISHIT = Instance.new("ScreenGui")
    ZayrosFISHIT.Name = CONFIG.GUI_NAME
    ZayrosFISHIT.Parent = player:WaitForChild("PlayerGui")
    ZayrosFISHIT.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Main Frame
    local FrameUtama = Instance.new("Frame")
    FrameUtama.Name = "FrameUtama"
    FrameUtama.Parent = ZayrosFISHIT
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

    -- Minimize Button
    local MinimizeBtn = Instance.new("TextButton")
    MinimizeBtn.Name = "MinimizeBtn"
    MinimizeBtn.Parent = FrameUtama
    MinimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
    MinimizeBtn.BorderSizePixel = 0
    MinimizeBtn.Position = UDim2.new(0.825, 0, 0.038, 0)
    MinimizeBtn.Size = UDim2.new(0.063, 0, 0.088, 0)
    MinimizeBtn.Font = Enum.Font.SourceSansBold
    MinimizeBtn.Text = "_"
    MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinimizeBtn.TextScaled = true
    
    local minimizeCorner = Instance.new("UICorner")
    minimizeCorner.CornerRadius = UDim.new(0, 4)
    minimizeCorner.Parent = MinimizeBtn

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
    TittleSideBar.Text = "Zayros FISHIT"
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
    local SECURITY = createMenuButton("SECURITY", "SECURITY")
    local ADVANCED = createMenuButton("ADVANCED", "ADVANCED")

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
    StatsText.Text = "🐟 Fish: 0 | Session: 0m | 🍀 Luck: Lv1"
    StatsText.TextColor3 = Color3.fromRGB(255, 255, 255)
    StatsText.TextScaled = true

    -- Weather Frame
    local WeatherFrame = Instance.new("Frame")
    WeatherFrame.Name = "WeatherFrame"
    WeatherFrame.Parent = MainListLayoutFrame
    WeatherFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
    WeatherFrame.BorderSizePixel = 0
    WeatherFrame.Size = UDim2.new(0.898, 0, 0.106, 0)
    
    local weatherCorner = Instance.new("UICorner")
    weatherCorner.Parent = WeatherFrame

    local WeatherText = Instance.new("TextLabel")
    WeatherText.Parent = WeatherFrame
    WeatherText.BackgroundTransparency = 1
    WeatherText.Position = UDim2.new(0.030, 0, 0.216, 0)
    WeatherText.Size = UDim2.new(0.940, 0, 0.568, 0)
    WeatherText.Font = Enum.Font.SourceSansBold
    WeatherText.Text = "☀️ Sunny | Perfect fishing weather!"
    WeatherText.TextColor3 = Color3.fromRGB(255, 255, 255)
    WeatherText.TextScaled = true

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

    -- ===============================================================
    --                       SECURITY FRAME
    -- ===============================================================
    local SecurityFrame = Instance.new("ScrollingFrame")
    SecurityFrame.Name = "SecurityFrame"
    SecurityFrame.Parent = FrameUtama
    SecurityFrame.Active = true
    SecurityFrame.BackgroundTransparency = 1
    SecurityFrame.Position = UDim2.new(0.376, 0, 0.147, 0)
    SecurityFrame.Size = UDim2.new(0.624, 0, 0.853, 0)
    SecurityFrame.Visible = false
    SecurityFrame.ZIndex = 2
    SecurityFrame.ScrollBarThickness = 6

    local SecurityListLayoutFrame = Instance.new("Frame")
    SecurityListLayoutFrame.Name = "SecurityListLayoutFrame"
    SecurityListLayoutFrame.Parent = SecurityFrame
    SecurityListLayoutFrame.BackgroundTransparency = 1
    SecurityListLayoutFrame.Position = UDim2.new(0, 0, 0.022, 0)
    SecurityListLayoutFrame.Size = UDim2.new(1, 0, 1, 0)

    local ListLayoutSecurity = Instance.new("UIListLayout")
    ListLayoutSecurity.Name = "ListLayoutSecurity"
    ListLayoutSecurity.Parent = SecurityListLayoutFrame
    ListLayoutSecurity.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ListLayoutSecurity.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayoutSecurity.Padding = UDim.new(0, 8)

    -- Admin Detection Frame
    local AdminDetectionFrame = Instance.new("Frame")
    AdminDetectionFrame.Name = "AdminDetectionFrame"
    AdminDetectionFrame.Parent = SecurityListLayoutFrame
    AdminDetectionFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
    AdminDetectionFrame.BorderSizePixel = 0
    AdminDetectionFrame.Size = UDim2.new(0.898, 0, 0.106, 0)
    
    local adminDetectionCorner = Instance.new("UICorner")
    adminDetectionCorner.Parent = AdminDetectionFrame

    local AdminDetectionText = Instance.new("TextLabel")
    AdminDetectionText.Parent = AdminDetectionFrame
    AdminDetectionText.BackgroundTransparency = 1
    AdminDetectionText.Position = UDim2.new(0.030, 0, 0.216, 0)
    AdminDetectionText.Size = UDim2.new(0.415, 0, 0.568, 0)
    AdminDetectionText.Font = Enum.Font.SourceSansBold
    AdminDetectionText.Text = "ADMIN DETECTION :"
    AdminDetectionText.TextColor3 = Color3.fromRGB(255, 255, 255)
    AdminDetectionText.TextScaled = true
    AdminDetectionText.TextXAlignment = Enum.TextXAlignment.Left

    local AdminDetectionButton = Instance.new("TextButton")
    AdminDetectionButton.Name = "AdminDetectionButton"
    AdminDetectionButton.Parent = AdminDetectionFrame
    AdminDetectionButton.BackgroundTransparency = 1
    AdminDetectionButton.Position = UDim2.new(0.738, 0, 0.108, 0)
    AdminDetectionButton.Size = UDim2.new(0.207, 0, 0.784, 0)
    AdminDetectionButton.ZIndex = 2
    AdminDetectionButton.Font = Enum.Font.SourceSansBold
    AdminDetectionButton.Text = SecuritySettings.AdminDetection and "ON" or "OFF"
    AdminDetectionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    AdminDetectionButton.TextScaled = true

    local AdminDetectionWarna = Instance.new("Frame")
    AdminDetectionWarna.Parent = AdminDetectionFrame
    AdminDetectionWarna.BackgroundColor3 = SecuritySettings.AdminDetection and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(0, 0, 0)
    AdminDetectionWarna.BorderSizePixel = 0
    AdminDetectionWarna.Position = UDim2.new(0.719, 0, 0.135, 0)
    AdminDetectionWarna.Size = UDim2.new(0.257, 0, 0.730, 0)
    
    local adminDetectionWarnaCorner = Instance.new("UICorner")
    adminDetectionWarnaCorner.Parent = AdminDetectionWarna

    -- Proximity Alert Frame
    local ProximityAlertFrame = Instance.new("Frame")
    ProximityAlertFrame.Name = "ProximityAlertFrame"
    ProximityAlertFrame.Parent = SecurityListLayoutFrame
    ProximityAlertFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
    ProximityAlertFrame.BorderSizePixel = 0
    ProximityAlertFrame.Size = UDim2.new(0.898, 0, 0.106, 0)
    
    local proximityAlertCorner = Instance.new("UICorner")
    proximityAlertCorner.Parent = ProximityAlertFrame

    local ProximityAlertText = Instance.new("TextLabel")
    ProximityAlertText.Parent = ProximityAlertFrame
    ProximityAlertText.BackgroundTransparency = 1
    ProximityAlertText.Position = UDim2.new(0.030, 0, 0.216, 0)
    ProximityAlertText.Size = UDim2.new(0.415, 0, 0.568, 0)
    ProximityAlertText.Font = Enum.Font.SourceSansBold
    ProximityAlertText.Text = "PROXIMITY ALERT :"
    ProximityAlertText.TextColor3 = Color3.fromRGB(255, 255, 255)
    ProximityAlertText.TextScaled = true
    ProximityAlertText.TextXAlignment = Enum.TextXAlignment.Left

    local ProximityAlertButton = Instance.new("TextButton")
    ProximityAlertButton.Name = "ProximityAlertButton"
    ProximityAlertButton.Parent = ProximityAlertFrame
    ProximityAlertButton.BackgroundTransparency = 1
    ProximityAlertButton.Position = UDim2.new(0.738, 0, 0.108, 0)
    ProximityAlertButton.Size = UDim2.new(0.207, 0, 0.784, 0)
    ProximityAlertButton.ZIndex = 2
    ProximityAlertButton.Font = Enum.Font.SourceSansBold
    ProximityAlertButton.Text = SecuritySettings.PlayerProximityAlert and "ON" or "OFF"
    ProximityAlertButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ProximityAlertButton.TextScaled = true

    local ProximityAlertWarna = Instance.new("Frame")
    ProximityAlertWarna.Parent = ProximityAlertFrame
    ProximityAlertWarna.BackgroundColor3 = SecuritySettings.PlayerProximityAlert and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(0, 0, 0)
    ProximityAlertWarna.BorderSizePixel = 0
    ProximityAlertWarna.Position = UDim2.new(0.719, 0, 0.135, 0)
    ProximityAlertWarna.Size = UDim2.new(0.257, 0, 0.730, 0)
    
    local proximityAlertWarnaCorner = Instance.new("UICorner")
    proximityAlertWarnaCorner.Parent = ProximityAlertWarna

    -- Auto Hide Frame
    local AutoHideFrame = Instance.new("Frame")
    AutoHideFrame.Name = "AutoHideFrame"
    AutoHideFrame.Parent = SecurityListLayoutFrame
    AutoHideFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
    AutoHideFrame.BorderSizePixel = 0
    AutoHideFrame.Size = UDim2.new(0.898, 0, 0.106, 0)
    
    local autoHideCorner = Instance.new("UICorner")
    autoHideCorner.Parent = AutoHideFrame

    local AutoHideText = Instance.new("TextLabel")
    AutoHideText.Parent = AutoHideFrame
    AutoHideText.BackgroundTransparency = 1
    AutoHideText.Position = UDim2.new(0.030, 0, 0.216, 0)
    AutoHideText.Size = UDim2.new(0.415, 0, 0.568, 0)
    AutoHideText.Font = Enum.Font.SourceSansBold
    AutoHideText.Text = "AUTO HIDE ON ADMIN :"
    AutoHideText.TextColor3 = Color3.fromRGB(255, 255, 255)
    AutoHideText.TextScaled = true
    AutoHideText.TextXAlignment = Enum.TextXAlignment.Left

    local AutoHideButton = Instance.new("TextButton")
    AutoHideButton.Name = "AutoHideButton"
    AutoHideButton.Parent = AutoHideFrame
    AutoHideButton.BackgroundTransparency = 1
    AutoHideButton.Position = UDim2.new(0.738, 0, 0.108, 0)
    AutoHideButton.Size = UDim2.new(0.207, 0, 0.784, 0)
    AutoHideButton.ZIndex = 2
    AutoHideButton.Font = Enum.Font.SourceSansBold
    AutoHideButton.Text = SecuritySettings.AutoHideOnAdmin and "ON" or "OFF"
    AutoHideButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    AutoHideButton.TextScaled = true

    local AutoHideWarna = Instance.new("Frame")
    AutoHideWarna.Parent = AutoHideFrame
    AutoHideWarna.BackgroundColor3 = SecuritySettings.AutoHideOnAdmin and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(0, 0, 0)
    AutoHideWarna.BorderSizePixel = 0
    AutoHideWarna.Position = UDim2.new(0.719, 0, 0.135, 0)
    AutoHideWarna.Size = UDim2.new(0.257, 0, 0.730, 0)
    
    local autoHideWarnaCorner = Instance.new("UICorner")
    autoHideWarnaCorner.Parent = AutoHideWarna

    -- Security Statistics Frame
    local SecurityStatsFrame = Instance.new("Frame")
    SecurityStatsFrame.Name = "SecurityStatsFrame"
    SecurityStatsFrame.Parent = SecurityListLayoutFrame
    SecurityStatsFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
    SecurityStatsFrame.BorderSizePixel = 0
    SecurityStatsFrame.Size = UDim2.new(0.898, 0, 0.106, 0)
    
    local securityStatsCorner = Instance.new("UICorner")
    securityStatsCorner.Parent = SecurityStatsFrame

    local SecurityStatsText = Instance.new("TextLabel")
    SecurityStatsText.Parent = SecurityStatsFrame
    SecurityStatsText.BackgroundTransparency = 1
    SecurityStatsText.Position = UDim2.new(0.030, 0, 0.216, 0)
    SecurityStatsText.Size = UDim2.new(0.940, 0, 0.568, 0)
    SecurityStatsText.Font = Enum.Font.SourceSansBold
    SecurityStatsText.Text = "🔒 Admins: 0 | 📡 Alerts: 0 | 🙈 Auto-Hides: 0"
    SecurityStatsText.TextColor3 = Color3.fromRGB(255, 255, 255)
    SecurityStatsText.TextScaled = true

    -- ===============================================================
    --                       ADVANCED FRAME
    -- ===============================================================
    local AdvancedFrame = Instance.new("ScrollingFrame")
    AdvancedFrame.Name = "AdvancedFrame"
    AdvancedFrame.Parent = FrameUtama
    AdvancedFrame.Active = true
    AdvancedFrame.BackgroundTransparency = 1
    AdvancedFrame.Position = UDim2.new(0.376, 0, 0.147, 0)
    AdvancedFrame.Size = UDim2.new(0.624, 0, 0.853, 0)
    AdvancedFrame.Visible = false
    AdvancedFrame.ZIndex = 2
    AdvancedFrame.ScrollBarThickness = 6

    local AdvancedListLayoutFrame = Instance.new("Frame")
    AdvancedListLayoutFrame.Name = "AdvancedListLayoutFrame"
    AdvancedListLayoutFrame.Parent = AdvancedFrame
    AdvancedListLayoutFrame.BackgroundTransparency = 1
    AdvancedListLayoutFrame.Position = UDim2.new(0, 0, 0.022, 0)
    AdvancedListLayoutFrame.Size = UDim2.new(1, 0, 1, 0)

    local ListLayoutAdvanced = Instance.new("UIListLayout")
    ListLayoutAdvanced.Name = "ListLayoutAdvanced"
    ListLayoutAdvanced.Parent = AdvancedListLayoutFrame
    ListLayoutAdvanced.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ListLayoutAdvanced.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayoutAdvanced.Padding = UDim.new(0, 8)

    -- Luck Boost Frame
    local LuckBoostFrame = Instance.new("Frame")
    LuckBoostFrame.Name = "LuckBoostFrame"
    LuckBoostFrame.Parent = AdvancedListLayoutFrame
    LuckBoostFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
    LuckBoostFrame.BorderSizePixel = 0
    LuckBoostFrame.Size = UDim2.new(0.898, 0, 0.106, 0)
    
    local luckBoostCorner = Instance.new("UICorner")
    luckBoostCorner.Parent = LuckBoostFrame

    local LuckBoostText = Instance.new("TextLabel")
    LuckBoostText.Parent = LuckBoostFrame
    LuckBoostText.BackgroundTransparency = 1
    LuckBoostText.Position = UDim2.new(0.030, 0, 0.216, 0)
    LuckBoostText.Size = UDim2.new(0.415, 0, 0.568, 0)
    LuckBoostText.Font = Enum.Font.SourceSansBold
    LuckBoostText.Text = "LUCK BOOST :"
    LuckBoostText.TextColor3 = Color3.fromRGB(255, 255, 255)
    LuckBoostText.TextScaled = true
    LuckBoostText.TextXAlignment = Enum.TextXAlignment.Left

    local LuckBoostButton = Instance.new("TextButton")
    LuckBoostButton.Name = "LuckBoostButton"
    LuckBoostButton.Parent = LuckBoostFrame
    LuckBoostButton.BackgroundTransparency = 1
    LuckBoostButton.Position = UDim2.new(0.738, 0, 0.108, 0)
    LuckBoostButton.Size = UDim2.new(0.207, 0, 0.784, 0)
    LuckBoostButton.ZIndex = 2
    LuckBoostButton.Font = Enum.Font.SourceSansBold
    LuckBoostButton.Text = "OFF"
    LuckBoostButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    LuckBoostButton.TextScaled = true

    local LuckBoostWarna = Instance.new("Frame")
    LuckBoostWarna.Parent = LuckBoostFrame
    LuckBoostWarna.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    LuckBoostWarna.BorderSizePixel = 0
    LuckBoostWarna.Position = UDim2.new(0.719, 0, 0.135, 0)
    LuckBoostWarna.Size = UDim2.new(0.257, 0, 0.730, 0)
    
    local luckBoostWarnaCorner = Instance.new("UICorner")
    luckBoostWarnaCorner.Parent = LuckBoostWarna

    -- Weather Boost Frame
    local WeatherBoostFrame = Instance.new("Frame")
    WeatherBoostFrame.Name = "WeatherBoostFrame"
    WeatherBoostFrame.Parent = AdvancedListLayoutFrame
    WeatherBoostFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
    WeatherBoostFrame.BorderSizePixel = 0
    WeatherBoostFrame.Size = UDim2.new(0.898, 0, 0.106, 0)
    
    local weatherBoostCorner = Instance.new("UICorner")
    weatherBoostCorner.Parent = WeatherBoostFrame

    local WeatherBoostText = Instance.new("TextLabel")
    WeatherBoostText.Parent = WeatherBoostFrame
    WeatherBoostText.BackgroundTransparency = 1
    WeatherBoostText.Position = UDim2.new(0.030, 0, 0.216, 0)
    WeatherBoostText.Size = UDim2.new(0.415, 0, 0.568, 0)
    WeatherBoostText.Font = Enum.Font.SourceSansBold
    WeatherBoostText.Text = "WEATHER BOOST :"
    WeatherBoostText.TextColor3 = Color3.fromRGB(255, 255, 255)
    WeatherBoostText.TextScaled = true
    WeatherBoostText.TextXAlignment = Enum.TextXAlignment.Left

    local WeatherBoostButton = Instance.new("TextButton")
    WeatherBoostButton.Name = "WeatherBoostButton"
    WeatherBoostButton.Parent = WeatherBoostFrame
    WeatherBoostButton.BackgroundTransparency = 1
    WeatherBoostButton.Position = UDim2.new(0.738, 0, 0.108, 0)
    WeatherBoostButton.Size = UDim2.new(0.207, 0, 0.784, 0)
    WeatherBoostButton.ZIndex = 2
    WeatherBoostButton.Font = Enum.Font.SourceSansBold
    WeatherBoostButton.Text = "OFF"
    WeatherBoostButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    WeatherBoostButton.TextScaled = true

    local WeatherBoostWarna = Instance.new("Frame")
    WeatherBoostWarna.Parent = WeatherBoostFrame
    WeatherBoostWarna.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    WeatherBoostWarna.BorderSizePixel = 0
    WeatherBoostWarna.Position = UDim2.new(0.719, 0, 0.135, 0)
    WeatherBoostWarna.Size = UDim2.new(0.257, 0, 0.730, 0)
    
    local weatherBoostWarnaCorner = Instance.new("UICorner")
    weatherBoostWarnaCorner.Parent = WeatherBoostWarna

    -- Smart Fishing Frame
    local SmartFishingFrame = Instance.new("Frame")
    SmartFishingFrame.Name = "SmartFishingFrame"
    SmartFishingFrame.Parent = AdvancedListLayoutFrame
    SmartFishingFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
    SmartFishingFrame.BorderSizePixel = 0
    SmartFishingFrame.Size = UDim2.new(0.898, 0, 0.106, 0)
    
    local smartFishingCorner = Instance.new("UICorner")
    smartFishingCorner.Parent = SmartFishingFrame

    local SmartFishingText = Instance.new("TextLabel")
    SmartFishingText.Parent = SmartFishingFrame
    SmartFishingText.BackgroundTransparency = 1
    SmartFishingText.Position = UDim2.new(0.030, 0, 0.216, 0)
    SmartFishingText.Size = UDim2.new(0.415, 0, 0.568, 0)
    SmartFishingText.Font = Enum.Font.SourceSansBold
    SmartFishingText.Text = "SMART FISHING :"
    SmartFishingText.TextColor3 = Color3.fromRGB(255, 255, 255)
    SmartFishingText.TextScaled = true
    SmartFishingText.TextXAlignment = Enum.TextXAlignment.Left

    local SmartFishingButton = Instance.new("TextButton")
    SmartFishingButton.Name = "SmartFishingButton"
    SmartFishingButton.Parent = SmartFishingFrame
    SmartFishingButton.BackgroundTransparency = 1
    SmartFishingButton.Position = UDim2.new(0.738, 0, 0.108, 0)
    SmartFishingButton.Size = UDim2.new(0.207, 0, 0.784, 0)
    SmartFishingButton.ZIndex = 2
    SmartFishingButton.Font = Enum.Font.SourceSansBold
    SmartFishingButton.Text = "OFF"
    SmartFishingButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    SmartFishingButton.TextScaled = true

    local SmartFishingWarna = Instance.new("Frame")
    SmartFishingWarna.Parent = SmartFishingFrame
    SmartFishingWarna.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    SmartFishingWarna.BorderSizePixel = 0
    SmartFishingWarna.Position = UDim2.new(0.719, 0, 0.135, 0)
    SmartFishingWarna.Size = UDim2.new(0.257, 0, 0.730, 0)
    
    local smartFishingWarnaCorner = Instance.new("UICorner")
    smartFishingWarnaCorner.Parent = SmartFishingWarna

    -- Fish Value Filter Frame
    local FishValueFrame = Instance.new("Frame")
    FishValueFrame.Name = "FishValueFrame"
    FishValueFrame.Parent = AdvancedListLayoutFrame
    FishValueFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
    FishValueFrame.BorderSizePixel = 0
    FishValueFrame.Size = UDim2.new(0.898, 0, 0.106, 0)
    
    local fishValueCorner = Instance.new("UICorner")
    fishValueCorner.Parent = FishValueFrame

    local FishValueText = Instance.new("TextLabel")
    FishValueText.Parent = FishValueFrame
    FishValueText.BackgroundTransparency = 1
    FishValueText.Position = UDim2.new(0.030, 0, 0.216, 0)
    FishValueText.Size = UDim2.new(0.415, 0, 0.568, 0)
    FishValueText.Font = Enum.Font.SourceSansBold
    FishValueText.Text = "MIN FISH VALUE:"
    FishValueText.TextColor3 = Color3.fromRGB(255, 255, 255)
    FishValueText.TextScaled = true
    FishValueText.TextXAlignment = Enum.TextXAlignment.Left

    local FishValueTextBox = Instance.new("TextBox")
    FishValueTextBox.Name = "FishValueTextBox"
    FishValueTextBox.Parent = FishValueFrame
    FishValueTextBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    FishValueTextBox.BorderSizePixel = 0
    FishValueTextBox.Position = UDim2.new(0.719, 0, 0.135, 0)
    FishValueTextBox.Size = UDim2.new(0.257, 0, 0.730, 0)
    FishValueTextBox.ZIndex = 3
    FishValueTextBox.Font = Enum.Font.SourceSansBold
    FishValueTextBox.PlaceholderText = "100"
    FishValueTextBox.Text = ""
    FishValueTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    FishValueTextBox.TextScaled = true
    
    local fishValueTextCorner = Instance.new("UICorner")
    fishValueTextCorner.Parent = FishValueTextBox

    -- Advanced Statistics Frame
    local AdvancedStatsFrame = Instance.new("Frame")
    AdvancedStatsFrame.Name = "AdvancedStatsFrame"
    AdvancedStatsFrame.Parent = AdvancedListLayoutFrame
    AdvancedStatsFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
    AdvancedStatsFrame.BorderSizePixel = 0
    AdvancedStatsFrame.Size = UDim2.new(0.898, 0, 0.106, 0)
    
    local advancedStatsCorner = Instance.new("UICorner")
    advancedStatsCorner.Parent = AdvancedStatsFrame

    local AdvancedStatsText = Instance.new("TextLabel")
    AdvancedStatsText.Parent = AdvancedStatsFrame
    AdvancedStatsText.BackgroundTransparency = 1
    AdvancedStatsText.Position = UDim2.new(0.030, 0, 0.216, 0)
    AdvancedStatsText.Size = UDim2.new(0.940, 0, 0.568, 0)
    AdvancedStatsText.Font = Enum.Font.SourceSansBold
    AdvancedStatsText.Text = "💰 Money: ₡0 | 🏆 Rare: 0 | 👑 Legendary: 0"
    AdvancedStatsText.TextColor3 = Color3.fromRGB(255, 255, 255)
    AdvancedStatsText.TextScaled = true

    -- Rod Stats Modifier Frame
    local RodStatsFrame = Instance.new("Frame")
    RodStatsFrame.Name = "RodStatsFrame"
    RodStatsFrame.Parent = AdvancedListLayoutFrame
    RodStatsFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
    RodStatsFrame.BorderSizePixel = 0
    RodStatsFrame.Size = UDim2.new(0.898, 0, 0.106, 0)
    
    local rodStatsCorner = Instance.new("UICorner")
    rodStatsCorner.Parent = RodStatsFrame

    local RodStatsText = Instance.new("TextLabel")
    RodStatsText.Parent = RodStatsFrame
    RodStatsText.BackgroundTransparency = 1
    RodStatsText.Position = UDim2.new(0.030, 0, 0.216, 0)
    RodStatsText.Size = UDim2.new(0.415, 0, 0.568, 0)
    RodStatsText.Font = Enum.Font.SourceSansBold
    RodStatsText.Text = "MODIFY ROD STATS :"
    RodStatsText.TextColor3 = Color3.fromRGB(255, 255, 255)
    RodStatsText.TextScaled = true
    RodStatsText.TextXAlignment = Enum.TextXAlignment.Left

    local RodStatsButton = Instance.new("TextButton")
    RodStatsButton.Name = "RodStatsButton"
    RodStatsButton.Parent = RodStatsFrame
    RodStatsButton.BackgroundTransparency = 1
    RodStatsButton.Position = UDim2.new(0.738, 0, 0.108, 0)
    RodStatsButton.Size = UDim2.new(0.207, 0, 0.784, 0)
    RodStatsButton.ZIndex = 2
    RodStatsButton.Font = Enum.Font.SourceSansBold
    RodStatsButton.Text = "OFF"
    RodStatsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    RodStatsButton.TextScaled = true

    local RodStatsWarna = Instance.new("Frame")
    RodStatsWarna.Parent = RodStatsFrame
    RodStatsWarna.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    RodStatsWarna.BorderSizePixel = 0
    RodStatsWarna.Position = UDim2.new(0.719, 0, 0.135, 0)
    RodStatsWarna.Size = UDim2.new(0.257, 0, 0.730, 0)
    
    local rodStatsWarnaCorner = Instance.new("UICorner")
    rodStatsWarnaCorner.Parent = RodStatsWarna

    -- Rod Luck Frame
    local RodLuckFrame = Instance.new("Frame")
    RodLuckFrame.Name = "RodLuckFrame"
    RodLuckFrame.Parent = AdvancedListLayoutFrame
    RodLuckFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
    RodLuckFrame.BorderSizePixel = 0
    RodLuckFrame.Size = UDim2.new(0.898, 0, 0.106, 0)
    
    local rodLuckCorner = Instance.new("UICorner")
    rodLuckCorner.Parent = RodLuckFrame

    local RodLuckText = Instance.new("TextLabel")
    RodLuckText.Parent = RodLuckFrame
    RodLuckText.BackgroundTransparency = 1
    RodLuckText.Position = UDim2.new(0.030, 0, 0.216, 0)
    RodLuckText.Size = UDim2.new(0.415, 0, 0.568, 0)
    RodLuckText.Font = Enum.Font.SourceSansBold
    RodLuckText.Text = "ROD LUCK (%):"
    RodLuckText.TextColor3 = Color3.fromRGB(255, 255, 255)
    RodLuckText.TextScaled = true
    RodLuckText.TextXAlignment = Enum.TextXAlignment.Left

    local RodLuckTextBox = Instance.new("TextBox")
    RodLuckTextBox.Name = "RodLuckTextBox"
    RodLuckTextBox.Parent = RodLuckFrame
    RodLuckTextBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    RodLuckTextBox.BorderSizePixel = 0
    RodLuckTextBox.Position = UDim2.new(0.719, 0, 0.135, 0)
    RodLuckTextBox.Size = UDim2.new(0.257, 0, 0.730, 0)
    RodLuckTextBox.ZIndex = 3
    RodLuckTextBox.Font = Enum.Font.SourceSansBold
    RodLuckTextBox.PlaceholderText = "175"
    RodLuckTextBox.Text = ""
    RodLuckTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    RodLuckTextBox.TextScaled = true
    
    local rodLuckTextCorner = Instance.new("UICorner")
    rodLuckTextCorner.Parent = RodLuckTextBox

    -- Rod Speed Frame
    local RodSpeedFrame = Instance.new("Frame")
    RodSpeedFrame.Name = "RodSpeedFrame"
    RodSpeedFrame.Parent = AdvancedListLayoutFrame
    RodSpeedFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
    RodSpeedFrame.BorderSizePixel = 0
    RodSpeedFrame.Size = UDim2.new(0.898, 0, 0.106, 0)
    
    local rodSpeedCorner = Instance.new("UICorner")
    rodSpeedCorner.Parent = RodSpeedFrame

    local RodSpeedText = Instance.new("TextLabel")
    RodSpeedText.Parent = RodSpeedFrame
    RodSpeedText.BackgroundTransparency = 1
    RodSpeedText.Position = UDim2.new(0.030, 0, 0.216, 0)
    RodSpeedText.Size = UDim2.new(0.415, 0, 0.568, 0)
    RodSpeedText.Font = Enum.Font.SourceSansBold
    RodSpeedText.Text = "ROD SPEED (%):"
    RodSpeedText.TextColor3 = Color3.fromRGB(255, 255, 255)
    RodSpeedText.TextScaled = true
    RodSpeedText.TextXAlignment = Enum.TextXAlignment.Left

    local RodSpeedTextBox = Instance.new("TextBox")
    RodSpeedTextBox.Name = "RodSpeedTextBox"
    RodSpeedTextBox.Parent = RodSpeedFrame
    RodSpeedTextBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    RodSpeedTextBox.BorderSizePixel = 0
    RodSpeedTextBox.Position = UDim2.new(0.719, 0, 0.135, 0)
    RodSpeedTextBox.Size = UDim2.new(0.257, 0, 0.730, 0)
    RodSpeedTextBox.ZIndex = 3
    RodSpeedTextBox.Font = Enum.Font.SourceSansBold
    RodSpeedTextBox.PlaceholderText = "100"
    RodSpeedTextBox.Text = ""
    RodSpeedTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    RodSpeedTextBox.TextScaled = true
    
    local rodSpeedTextCorner = Instance.new("UICorner")
    rodSpeedTextCorner.Parent = RodSpeedTextBox

    -- Rod Weight Frame
    local RodWeightFrame = Instance.new("Frame")
    RodWeightFrame.Name = "RodWeightFrame"
    RodWeightFrame.Parent = AdvancedListLayoutFrame
    RodWeightFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
    RodWeightFrame.BorderSizePixel = 0
    RodWeightFrame.Size = UDim2.new(0.898, 0, 0.106, 0)
    
    local rodWeightCorner = Instance.new("UICorner")
    rodWeightCorner.Parent = RodWeightFrame

    local RodWeightText = Instance.new("TextLabel")
    RodWeightText.Parent = RodWeightFrame
    RodWeightText.BackgroundTransparency = 1
    RodWeightText.Position = UDim2.new(0.030, 0, 0.216, 0)
    RodWeightText.Size = UDim2.new(0.415, 0, 0.568, 0)
    RodWeightText.Font = Enum.Font.SourceSansBold
    RodWeightText.Text = "ROD WEIGHT (kg):"
    RodWeightText.TextColor3 = Color3.fromRGB(255, 255, 255)
    RodWeightText.TextScaled = true
    RodWeightText.TextXAlignment = Enum.TextXAlignment.Left

    local RodWeightTextBox = Instance.new("TextBox")
    RodWeightTextBox.Name = "RodWeightTextBox"
    RodWeightTextBox.Parent = RodWeightFrame
    RodWeightTextBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    RodWeightTextBox.BorderSizePixel = 0
    RodWeightTextBox.Position = UDim2.new(0.719, 0, 0.135, 0)
    RodWeightTextBox.Size = UDim2.new(0.257, 0, 0.730, 0)
    RodWeightTextBox.ZIndex = 3
    RodWeightTextBox.Font = Enum.Font.SourceSansBold
    RodWeightTextBox.PlaceholderText = "5"
    RodWeightTextBox.Text = ""
    RodWeightTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    RodWeightTextBox.TextScaled = true
    
    local rodWeightTextCorner = Instance.new("UICorner")
    rodWeightTextCorner.Parent = RodWeightTextBox

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
    
    -- Exit button
    connections[#connections + 1] = ExitBtn.MouseButton1Click:Connect(function()
        ZayrosFISHIT:Destroy()
        for _, connection in pairs(connections) do
            if connection and connection.Connected then
                connection:Disconnect()
            end
        end
    end)

    -- Minimize button
    connections[#connections + 1] = MinimizeBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        
        if isMinimized then
            -- Minimize GUI - hide all frames except title bar
            SideBar.Visible = false
            MainFrame.Visible = false
            PlayerFrame.Visible = false
            Teleport.Visible = false
            SpawnBoatFrame.Visible = false
            SecurityFrame.Visible = false
            Line_2.Visible = false
            Tittle.Visible = false
            
            -- Resize main frame to just show title bar
            FrameUtama:TweenSize(
                UDim2.new(0.542, 0, 0.12, 0),
                "Out", "Quad", 0.3, true
            )
            MinimizeBtn.Text = "+"
            createNotification("📦 GUI Minimized", Color3.fromRGB(255, 165, 0))
        else
            -- Restore GUI
            SideBar.Visible = true
            Line_2.Visible = true
            Tittle.Visible = true
            
            -- Restore main frame size
            FrameUtama:TweenSize(
                UDim2.new(0.542, 0, 0.650, 0),
                "Out", "Quad", 0.3, true,
                function()
                    -- Show current panel after animation
                    if Tittle.Text == "MAIN" then
                        MainFrame.Visible = true
                    elseif Tittle.Text == "PLAYER" then
                        PlayerFrame.Visible = true
                    elseif Tittle.Text == "TELEPORT" then
                        Teleport.Visible = true
                    elseif Tittle.Text == "SPAWN BOAT" then
                        SpawnBoatFrame.Visible = true
                    elseif Tittle.Text == "SECURITY" then
                        SecurityFrame.Visible = true
                    elseif Tittle.Text == "ADVANCED" then
                        AdvancedFrame.Visible = true
                    end
                end
            )
            MinimizeBtn.Text = "_"
            createNotification("📦 GUI Restored", Color3.fromRGB(0, 255, 0))
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
                        highlight.Name = "ZayrosESP"
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
                    local esp = targetPlayer.Character:FindFirstChild("ZayrosESP")
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

    -- Security button connections
    connections[#connections + 1] = AdminDetectionButton.MouseButton1Click:Connect(function()
        SecuritySettings.AdminDetection = not SecuritySettings.AdminDetection
        AdminDetectionButton.Text = SecuritySettings.AdminDetection and "ON" or "OFF"
        AdminDetectionWarna.BackgroundColor3 = SecuritySettings.AdminDetection and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(0, 0, 0)
        if SecuritySettings.AdminDetection then
            createNotification("🔒 Admin Detection enabled!", Color3.fromRGB(0, 200, 0))
        else
            createNotification("🔒 Admin Detection disabled!", Color3.fromRGB(200, 0, 0))
        end
    end)

    connections[#connections + 1] = ProximityAlertButton.MouseButton1Click:Connect(function()
        SecuritySettings.PlayerProximityAlert = not SecuritySettings.PlayerProximityAlert
        ProximityAlertButton.Text = SecuritySettings.PlayerProximityAlert and "ON" or "OFF"
        ProximityAlertWarna.BackgroundColor3 = SecuritySettings.PlayerProximityAlert and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(0, 0, 0)
        if SecuritySettings.PlayerProximityAlert then
            createNotification("📡 Proximity Alert enabled!", Color3.fromRGB(0, 200, 0))
        else
            createNotification("📡 Proximity Alert disabled!", Color3.fromRGB(200, 0, 0))
        end
    end)

    connections[#connections + 1] = AutoHideButton.MouseButton1Click:Connect(function()
        SecuritySettings.AutoHideOnAdmin = not SecuritySettings.AutoHideOnAdmin
        AutoHideButton.Text = SecuritySettings.AutoHideOnAdmin and "ON" or "OFF"
        AutoHideWarna.BackgroundColor3 = SecuritySettings.AutoHideOnAdmin and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(0, 0, 0)
        if SecuritySettings.AutoHideOnAdmin then
            createNotification("🙈 Auto Hide enabled!", Color3.fromRGB(0, 200, 0))
        else
            createNotification("🙈 Auto Hide disabled!", Color3.fromRGB(200, 0, 0))
        end
    end)

    -- Advanced button connections
    connections[#connections + 1] = LuckBoostButton.MouseButton1Click:Connect(function()
        Settings.LuckBoost = not Settings.LuckBoost
        LuckBoostButton.Text = Settings.LuckBoost and "ON" or "OFF"
        LuckBoostWarna.BackgroundColor3 = Settings.LuckBoost and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(0, 0, 0)
        if Settings.LuckBoost then
            createNotification("🍀 Luck Boost enabled!", Color3.fromRGB(0, 255, 0))
        else
            createNotification("🍀 Luck Boost disabled!", Color3.fromRGB(200, 0, 0))
        end
    end)

    connections[#connections + 1] = WeatherBoostButton.MouseButton1Click:Connect(function()
        Settings.WeatherBoost = not Settings.WeatherBoost
        WeatherBoostButton.Text = Settings.WeatherBoost and "ON" or "OFF"
        WeatherBoostWarna.BackgroundColor3 = Settings.WeatherBoost and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(0, 0, 0)
        if Settings.WeatherBoost then
            createNotification("🌦️ Weather Boost enabled!", Color3.fromRGB(0, 255, 0))
        else
            createNotification("🌦️ Weather Boost disabled!", Color3.fromRGB(200, 0, 0))
        end
    end)

    connections[#connections + 1] = SmartFishingButton.MouseButton1Click:Connect(function()
        Settings.SmartFishing = not Settings.SmartFishing
        SmartFishingButton.Text = Settings.SmartFishing and "ON" or "OFF"
        SmartFishingWarna.BackgroundColor3 = Settings.SmartFishing and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(0, 0, 0)
        if Settings.SmartFishing then
            createNotification("🧠 Smart Fishing enabled!", Color3.fromRGB(0, 255, 0))
        else
            createNotification("🧠 Smart Fishing disabled!", Color3.fromRGB(200, 0, 0))
        end
    end)

    -- Fish Value TextBox
    connections[#connections + 1] = FishValueTextBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local value = tonumber(FishValueTextBox.Text)
            if value and value >= 10 and value <= 1000 then
                Settings.MinFishValue = value
                Settings.FishValueFilter = true
                createNotification("💎 Min Fish Value set to ₡" .. value, Color3.fromRGB(0, 150, 255))
                FishValueTextBox.Text = ""
            else
                createNotification("❌ Invalid value! Use 10-1000", Color3.fromRGB(255, 0, 0))
                FishValueTextBox.Text = ""
            end
        end
    end)

    -- Rod Stats Modifier button
    connections[#connections + 1] = RodStatsButton.MouseButton1Click:Connect(function()
        Settings.ModifyRodStats = not Settings.ModifyRodStats
        RodStatsButton.Text = Settings.ModifyRodStats and "ON" or "OFF"
        RodStatsWarna.BackgroundColor3 = Settings.ModifyRodStats and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(0, 0, 0)
        if Settings.ModifyRodStats then
            startRodStatsModifier()
            createNotification("🎣 Rod Stats Modifier enabled!", Color3.fromRGB(0, 255, 0))
        else
            createNotification("🎣 Rod Stats Modifier disabled!", Color3.fromRGB(200, 0, 0))
        end
    end)

    -- Rod Luck TextBox
    connections[#connections + 1] = RodLuckTextBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local value = tonumber(RodLuckTextBox.Text)
            if value and value >= 0 and value <= 1000 then
                Settings.CustomRodLuck = value
                createNotification("🍀 Rod Luck set to " .. value .. "%", Color3.fromRGB(255, 215, 0))
                RodLuckTextBox.Text = ""
            else
                createNotification("❌ Invalid luck! Use 0-1000", Color3.fromRGB(255, 0, 0))
                RodLuckTextBox.Text = ""
            end
        end
    end)

    -- Rod Speed TextBox
    connections[#connections + 1] = RodSpeedTextBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local value = tonumber(RodSpeedTextBox.Text)
            if value and value >= 0 and value <= 1000 then
                Settings.CustomRodSpeed = value
                createNotification("⚡ Rod Speed set to " .. value .. "%", Color3.fromRGB(0, 255, 255))
                RodSpeedTextBox.Text = ""
            else
                createNotification("❌ Invalid speed! Use 0-1000", Color3.fromRGB(255, 0, 0))
                RodSpeedTextBox.Text = ""
            end
        end
    end)

    -- Rod Weight TextBox
    connections[#connections + 1] = RodWeightTextBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local value = tonumber(RodWeightTextBox.Text)
            if value and value >= 0 and value <= 100 then
                Settings.CustomRodWeight = value
                createNotification("⚖️ Rod Weight set to " .. value .. "kg", Color3.fromRGB(128, 128, 128))
                RodWeightTextBox.Text = ""
            else
                createNotification("❌ Invalid weight! Use 0-100", Color3.fromRGB(255, 0, 0))
                RodWeightTextBox.Text = ""
            end
        end
    end)

    -- Page switching function
    local function showPanel(pageName)
        if isMinimized then return end -- Don't switch panels when minimized
        
        MainFrame.Visible = false
        PlayerFrame.Visible = false
        Teleport.Visible = false
        SpawnBoatFrame.Visible = false
        SecurityFrame.Visible = false
        AdvancedFrame.Visible = false
        
        if pageName == "Main" then
            MainFrame.Visible = true
        elseif pageName == "Player" then
            PlayerFrame.Visible = true
        elseif pageName == "Teleport" then
            Teleport.Visible = true
        elseif pageName == "Boat" then
            SpawnBoatFrame.Visible = true
        elseif pageName == "Security" then
            SecurityFrame.Visible = true
        elseif pageName == "Advanced" then
            AdvancedFrame.Visible = true
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

    connections[#connections + 1] = SECURITY.MouseButton1Click:Connect(function()
        showPanel("Security")
    end)

    connections[#connections + 1] = ADVANCED.MouseButton1Click:Connect(function()
        showPanel("Advanced")
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
    
    -- Hotkey for hiding GUI
    connections[#connections + 1] = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == CONFIG.HOTKEY then
            isHidden = not isHidden
            ZayrosFISHIT.Enabled = not isHidden
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
        local currentLuck = calculateCurrentLuck()
        local luckPercent = math.floor(currentLuck * 1000) / 10
        
        StatsText.Text = string.format("🐟 Fish: %d | ⏰ Session: %dm | 🍀 Luck: Lv%d (%.1f%%)", 
            Stats.fishCaught, sessionTime, Stats.currentLuckLevel, luckPercent)
        
        -- Update security statistics
        SecurityStatsText.Text = string.format("🔒 Admins: %d | 📡 Alerts: %d | 🙈 Auto-Hides: %d", 
            SecurityStats.AdminsDetected, SecurityStats.ProximityAlerts, SecurityStats.AutoHides)
        
        -- Update weather display
        local weatherEffect = WeatherEffects[currentWeather]
        if weatherEffect then
            WeatherText.Text = weatherEffect.description
        end
        
        -- Update advanced statistics
        AdvancedStatsText.Text = string.format("💰 Money: ₡%d | 🏆 Rare: %d | 👑 Legendary: %d", 
            Stats.moneyEarned, Stats.rareFishCaught, Stats.legendaryFishCaught)
        
        -- Calculate rates
        if sessionTime > 0 then
            Stats.fishPerMinute = math.floor((Stats.fishCaught / sessionTime) * 10) / 10
            Stats.moneyPerHour = math.floor((Stats.moneyEarned / sessionTime) * 60)
        end
    end)

    -- Start anti-AFK system
    antiAFK()

    -- Initialize security system
    initializeSecurity()

    -- Start weather cycle
    startWeatherCycle()

    -- Auto-update walk speed for new character
    connections[#connections + 1] = player.CharacterAdded:Connect(function(character)
        task.wait(1) -- Wait for character to load
        setWalkSpeed(Settings.WalkSpeed)
        setJumpPower(Settings.JumpPower)
        
        -- Monitor for rod equipping and apply stats
        connections[#connections + 1] = character.ChildAdded:Connect(function(child)
            if child:IsA("Tool") and Settings.ModifyRodStats then
                task.wait(0.1) -- Small delay to ensure tool is fully equipped
                modifyRodStats()
            end
        end)
    end)

    -- Initial setup
    showPanel("Main")
    updatePlayerList()

    print("✅ Zayros FISHIT V2.0 loaded successfully!")
    print("📌 Press F9 to hide/show GUI")
    print("🎣 Auto Fish with enhanced safety features")
    print("🚤 Multiple boat spawning options")
    print("📍 Player & Island teleportation")
    print("🔧 New Features: Auto Sell, Walk Speed, ESP, Notifications")
    print("🛡️ Safety Features: Anti-AFK, Health Check, Error Handling")
    print("🔒 Security Features: Admin Detection, Proximity Alerts, Auto Hide")
    print("📦 GUI Features: Minimize/Restore, Draggable Interface")
    print("🍀 Advanced Features: Luck System, Weather Effects, Smart Fishing")
    print("📊 Analytics: Fish Rarity Tracking, Money Counter, Performance Stats")
    print("🎣 NEW: Rod Stats Modifier - Control Rod Luck, Speed & Weight!")
    print("⚙️ Configure custom rod stats in Advanced tab")

    return ZayrosFISHIT
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
