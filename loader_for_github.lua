-- NANI FISHING SCRIPT LOADER
-- Professional loader for GitHub-hosted script

local function createLoadingGUI()
    -- Create simple loading indicator
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ScriptLoader"
    screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 100)
    frame.Position = UDim2.new(0.5, -150, 0.5, -50)
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.5, 0)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🎣 Loading Fishing Script..."
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = frame
    
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0.5, 0)
    status.Position = UDim2.new(0, 0, 0.5, 0)
    status.BackgroundTransparency = 1
    status.Text = "Connecting to GitHub..."
    status.TextColor3 = Color3.fromRGB(200, 200, 200)
    status.TextScaled = true
    status.Font = Enum.Font.Gotham
    status.Parent = frame
    
    return screenGui, status
end

local function loadNaniScript()
    local loadingGui, statusLabel = createLoadingGUI()
    
    local success, result = pcall(function()
        -- Your GitHub script URL
        local scriptUrl = "https://raw.githubusercontent.com/NANISULISTIANA/Public/refs/heads/main/versi2"
        
        -- Update status
        statusLabel.Text = "📡 Fetching script..."
        wait(0.5)
        
        -- Check if HttpService is available
        local httpService = game:GetService("HttpService")
        if not httpService then
            error("HttpService not available")
        end
        
        -- Download script
        statusLabel.Text = "📥 Downloading..."
        local scriptContent = game:HttpGet(scriptUrl)
        
        if not scriptContent or scriptContent == "" then
            error("Empty script content")
        end
        
        -- Validate script content
        if not scriptContent:find("ZayrosFISHIT") then
            error("Invalid script format")
        end
        
        statusLabel.Text = "🔧 Initializing..."
        wait(0.5)
        
        -- Execute script
        loadstring(scriptContent)()
        
        statusLabel.Text = "✅ Success!"
        statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        
        wait(1)
        loadingGui:Destroy()
        
        print("🎣 Nani Fishing Script loaded successfully!")
        print("📋 Version: 2.0")
        print("👤 User: " .. game.Players.LocalPlayer.Name)
        print("🎮 Game: " .. game.PlaceId)
    end)
    
    if not success then
        statusLabel.Text = "❌ Failed: " .. tostring(result)
        statusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        warn("❌ Loader Error: " .. tostring(result))
        
        wait(3)
        loadingGui:Destroy()
    end
end

-- Anti-detection measures
local function checkEnvironment()
    -- Check if running in proper Roblox environment
    if not game or not game.Players or not game.Players.LocalPlayer then
        return false, "Invalid game environment"
    end
    
    -- Check if in supported game (optional)
    local supportedGames = {
        [16732694052] = "Fisch",
        -- Add more game IDs here if needed
    }
    
    local currentGameId = game.PlaceId
    if supportedGames[currentGameId] then
        print("🎮 Detected game: " .. supportedGames[currentGameId])
    else
        print("⚠️ Unknown game ID: " .. currentGameId .. " (script may still work)")
    end
    
    return true, "Environment OK"
end

-- Main execution
local envOK, envMsg = checkEnvironment()
if envOK then
    print("🚀 Starting Nani Fishing Script Loader...")
    loadNaniScript()
else
    warn("❌ Environment check failed: " .. envMsg)
end
