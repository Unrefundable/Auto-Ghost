--[[
    Ghost Killaura Script v2
    Automatically attacks ghosts when they spawn using ByteNet packets
    
    Packet Structure (7 bytes):
    - Byte 0: Packet ID (17 = 0x11, attack/hit packet)
    - Byte 1: Attack type (1 = weapon hit)
    - Byte 2: Flags (0)
    - Bytes 3-6: Entity ID (4-byte little-endian int32)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local ByteNetReliable = ReplicatedStorage.ByteNetReliable

-- Settings
local settings = {
    enabled = false,  -- Start disabled, toggle with GUI
    attackDelay = 0.1,  -- Delay between attacks (seconds)
    maxDistance = 20,   -- Maximum distance to attack (20 studs for players and ghosts)
    debug = true,       -- Show debug messages
    attackAllPlayers = false,  -- Attack any player within range (not just target list)
}

-- Player targets list
local targetPlayers = {} -- List of usernames to target

-- Hunger management state
local lastHungerCheck = 0
local HUNGER_CHECK_INTERVAL = 1 -- Check hunger every 1 second

-- Death and respawn state
local isRespawning = false
local TARGET_CRYSTAL = 3 -- Need 3 crystal chunks for crystal stick

-- Create GUI
local function createToggleGUI()
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GhostKillauraGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Main Frame (draggable) - made larger for player list
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 280, 0, 350)
    mainFrame.Position = UDim2.new(0.5, -140, 0.1, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    title.BorderSizePixel = 0
    title.Text = "👻 Ghost Killaura"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = title
    
    -- Status Label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, -20, 0, 25)
    statusLabel.Position = UDim2.new(0, 10, 0, 40)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: Disabled"
    statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    statusLabel.TextSize = 14
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = mainFrame
    
    -- Attack All Players Toggle
    local attackAllToggle = Instance.new("TextButton")
    attackAllToggle.Name = "AttackAllToggle"
    attackAllToggle.Size = UDim2.new(1, -20, 0, 30)
    attackAllToggle.Position = UDim2.new(0, 10, 0, 70)
    attackAllToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    attackAllToggle.BorderSizePixel = 0
    attackAllToggle.Text = "⚔️ Attack All Players: OFF"
    attackAllToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    attackAllToggle.TextSize = 12
    attackAllToggle.Font = Enum.Font.GothamBold
    attackAllToggle.Parent = mainFrame
    
    local attackAllCorner = Instance.new("UICorner")
    attackAllCorner.CornerRadius = UDim.new(0, 6)
    attackAllCorner.Parent = attackAllToggle
    
    -- Player Targets Section
    local playersLabel = Instance.new("TextLabel")
    playersLabel.Name = "PlayersLabel"
    playersLabel.Size = UDim2.new(1, -20, 0, 20)
    playersLabel.Position = UDim2.new(0, 10, 0, 110)
    playersLabel.BackgroundTransparency = 1
    playersLabel.Text = "Target Players:"
    playersLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    playersLabel.TextSize = 12
    playersLabel.Font = Enum.Font.Gotham
    playersLabel.TextXAlignment = Enum.TextXAlignment.Left
    playersLabel.Parent = mainFrame
    
    -- Player input box
    local playerInput = Instance.new("TextBox")
    playerInput.Name = "PlayerInput"
    playerInput.Size = UDim2.new(1, -90, 0, 30)
    playerInput.Position = UDim2.new(0, 10, 0, 135)
    playerInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    playerInput.BorderSizePixel = 0
    playerInput.Text = ""
    playerInput.PlaceholderText = "Enter username..."
    playerInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    playerInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    playerInput.TextSize = 12
    playerInput.Font = Enum.Font.Gotham
    playerInput.Parent = mainFrame
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 6)
    inputCorner.Parent = playerInput
    
    -- Add button
    local addButton = Instance.new("TextButton")
    addButton.Name = "AddButton"
    addButton.Size = UDim2.new(0, 65, 0, 30)
    addButton.Position = UDim2.new(1, -75, 0, 135)
    addButton.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
    addButton.Text = "Add"
    addButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    addButton.TextSize = 12
    addButton.Font = Enum.Font.GothamBold
    addButton.Parent = mainFrame
    
    local addCorner = Instance.new("UICorner")
    addCorner.CornerRadius = UDim.new(0, 6)
    addCorner.Parent = addButton
    
    -- Player list frame
    local listFrame = Instance.new("ScrollingFrame")
    listFrame.Name = "ListFrame"
    listFrame.Size = UDim2.new(1, -20, 0, 105)
    listFrame.Position = UDim2.new(0, 10, 0, 175)
    listFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    listFrame.BorderSizePixel = 0
    listFrame.ScrollBarThickness = 6
    listFrame.Parent = mainFrame
    
    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 6)
    listCorner.Parent = listFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 5)
    listLayout.Parent = listFrame
    
    -- Function to update player list display
    local function updatePlayerList()
        -- Clear existing entries
        for _, child in ipairs(listFrame:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        
        -- Add entries for each player
        for username, _ in pairs(targetPlayers) do
            local entry = Instance.new("Frame")
            entry.Name = username
            entry.Size = UDim2.new(1, -10, 0, 25)
            entry.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            entry.BorderSizePixel = 0
            entry.Parent = listFrame
            
            local entryCorner = Instance.new("UICorner")
            entryCorner.CornerRadius = UDim.new(0, 4)
            entryCorner.Parent = entry
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -35, 1, 0)
            nameLabel.Position = UDim2.new(0, 5, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = username
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.TextSize = 11
            nameLabel.Font = Enum.Font.Gotham
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = entry
            
            local removeBtn = Instance.new("TextButton")
            removeBtn.Size = UDim2.new(0, 25, 0, 20)
            removeBtn.Position = UDim2.new(1, -28, 0.5, -10)
            removeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
            removeBtn.Text = "X"
            removeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            removeBtn.TextSize = 12
            removeBtn.Font = Enum.Font.GothamBold
            removeBtn.Parent = entry
            
            local removeCorner = Instance.new("UICorner")
            removeCorner.CornerRadius = UDim.new(0, 4)
            removeCorner.Parent = removeBtn
            
            removeBtn.MouseButton1Click:Connect(function()
                targetPlayers[username] = nil
                updatePlayerList()
                print("Removed player from targets:", username)
            end)
        end
        
        -- Update canvas size
        listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            listFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
        end)
        listFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    end
    
    -- Add button functionality
    addButton.MouseButton1Click:Connect(function()
        local username = playerInput.Text:gsub("^%s*(.-)%s*$", "%1") -- Trim whitespace
        if username ~= "" and not targetPlayers[username] then
            targetPlayers[username] = true
            playerInput.Text = ""
            updatePlayerList()
            print("Added player to targets:", username)
        end
    end)
    
    -- Attack All Players toggle functionality
    attackAllToggle.MouseButton1Click:Connect(function()
        settings.attackAllPlayers = not settings.attackAllPlayers
        
        if settings.attackAllPlayers then
            attackAllToggle.Text = "⚔️ Attack All Players: ON"
            attackAllToggle.BackgroundColor3 = Color3.fromRGB(255, 150, 50)
            print("Attack All Players: ENABLED - Will attack ANY player within 20 studs")
        else
            attackAllToggle.Text = "⚔️ Attack All Players: OFF"
            attackAllToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            print("Attack All Players: DISABLED - Will only attack players in target list")
        end
    end)
    
    -- Toggle Button
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(1, -20, 0, 35)
    toggleButton.Position = UDim2.new(0, 10, 0, 295)
    toggleButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    toggleButton.BorderSizePixel = 0
    toggleButton.Text = "Enable Killaura"
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.TextSize = 14
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.Parent = mainFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = toggleButton
    
    -- Toggle functionality
    toggleButton.MouseButton1Click:Connect(function()
        settings.enabled = not settings.enabled
        
        if settings.enabled then
            toggleButton.Text = "Disable Killaura"
            toggleButton.BackgroundColor3 = Color3.fromRGB(50, 220, 50)
            statusLabel.Text = "Status: Active"
            statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            print("Killaura: ENABLED")
        else
            toggleButton.Text = "Enable Killaura"
            toggleButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
            statusLabel.Text = "Status: Disabled"
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            print("Killaura: DISABLED")
        end
    end)
    
    -- Make draggable
    local dragging = false
    local dragInput, dragStart, startPos
    
    local function update(input)
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
    
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    title.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
    
    -- Parent to PlayerGui
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    return screenGui
end

-- Initialize GUI
local gui = createToggleGUI()

-- Track active targets
local activeGhosts = {}
local activePlayers = {}
local isAttacking = false

-- Helper: Check if player is dead
local function isDead()
    if not LocalPlayer.Character then
        return true
    end
    
    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    if not humanoid then
        return true
    end
    
    return humanoid.Health <= 0
end

-- Helper: Activate spawn button
local function activateSpawnButton()
    local spawnGui = LocalPlayer.PlayerGui:FindFirstChild("SpawnGui")
    if not spawnGui then
        return false
    end
    
    local customization = spawnGui:FindFirstChild("Customization")
    if not customization then
        return false
    end
    
    local playButton = customization:FindFirstChild("PlayButton")
    if not playButton then
        return false
    end
    
    firesignal(playButton.Activated)
    print("[Killaura] Spawn button activated")
    return true
end

-- Helper: Get crystal chunk count
local function getCrystalCount()
    local success, count = pcall(function()
        local mainGui = LocalPlayer.PlayerGui:FindFirstChild("MainGui")
        if not mainGui then return 0 end
        
        local rightPanel = mainGui:FindFirstChild("RightPanel")
        if not rightPanel then return 0 end
        
        local inventory = rightPanel:FindFirstChild("Inventory")
        if not inventory then return 0 end
        
        local list = inventory:FindFirstChild("List")
        if not list then return 0 end
        
        local crystalEntry = list:FindFirstChild("Crystal Chunk")
        if not crystalEntry then return 0 end
        
        local quantityImage = crystalEntry:FindFirstChild("QuantityImage")
        if not quantityImage then return 0 end
        
        local quantityText = quantityImage:FindFirstChild("QuantityText")
        if not quantityText then return 0 end
        
        local text = quantityText.Text
        local number = tonumber(text:match("%d+"))
        return number or 0
    end)
    
    return success and count or 0
end

-- Helper: Buy crystal chunks
local function buyCrystalChunks(amount)
    for i = 1, amount do
        local buf = buffer.fromstring("\136\180\1")
        ByteNetReliable:FireServer(buf)
        print("[Killaura] Bought crystal chunk", i, "/", amount)
        task.wait(0.1)
    end
end

-- Helper: Craft crystal stick
local function craftCrystalStick()
    local buf = buffer.fromstring("\5e\2")
    ByteNetReliable:FireServer(buf)
    print("[Killaura] Crafted crystal stick")
    task.wait(0.5)
end

-- Helper: Respawn and prepare equipment
local function handleRespawn()
    if isRespawning then return end
    isRespawning = true
    
    print("\n[Killaura] Player died - respawning...")
    task.wait(3)
    
    -- Activate spawn button
    if activateSpawnButton() then
        task.wait(2)
        
        -- Check crystal chunks
        local crystalCount = getCrystalCount()
        print("[Killaura] Crystal chunks in inventory:", crystalCount)
        
        if crystalCount < TARGET_CRYSTAL then
            local needed = TARGET_CRYSTAL - crystalCount
            print("[Killaura] Need", needed, "more crystal chunks")
            buyCrystalChunks(needed)
            task.wait(0.5)
        end
        
        -- Craft crystal stick
        print("[Killaura] Crafting crystal stick...")
        craftCrystalStick()
        
        print("[Killaura] Ready to attack!")
    else
        warn("[Killaura] Failed to activate spawn button")
    end
    
    isRespawning = false
end

-- Helper: Get current hunger value
local function getHungerValue()
    local success, hunger = pcall(function()
        local hungerLabel = LocalPlayer.PlayerGui.MainGui.Panels.Stats.Bars.Hunger.ValueLabel
        local text = hungerLabel.Text
        -- Extract number from text (format might be "80/100" or just "80")
        local value = tonumber(text:match("%d+"))
        return value
    end)
    
    if success and hunger then
        return hunger
    end
    return nil
end

-- Helper: Find cooked meat in inventory and get its slot
local function findCookedMeatSlot()
    local success, result = pcall(function()
        local mainGui = LocalPlayer.PlayerGui:FindFirstChild("MainGui")
        if not mainGui then
            return nil
        end
        
        local rightPanel = mainGui:FindFirstChild("RightPanel")
        if not rightPanel then
            return nil
        end
        
        local inventory = rightPanel:FindFirstChild("Inventory")
        if not inventory then
            return nil
        end
        
        local list = inventory:FindFirstChild("List")
        if not list then
            return nil
        end
        
        -- Look for "Cooked Meat" item in the list
        local cookedMeatItem = list:FindFirstChild("Cooked Meat")
        if cookedMeatItem then
            -- Get the LayoutOrder property directly
            local layoutOrder = cookedMeatItem.LayoutOrder
            if layoutOrder then
                return layoutOrder
            end
        end
        
        return nil
    end)
    
    if success and result then
        return result
    end
    return nil
end

-- Helper: Create eating buffer for specific inventory slot
local function createEatingBuffer(slot)
    local buf = buffer.create(3)
    buffer.writeu8(buf, 0, 43)  -- Packet ID 43 (eating/consume)
    buffer.writeu8(buf, 1, slot) -- Inventory slot (1-based)
    buffer.writeu8(buf, 2, 0)    -- Flags
    
    return buf
end

-- Helper: Eat cooked meat to restore hunger
local function eatCookedMeat()
    -- Find cooked meat in inventory
    local slot = findCookedMeatSlot()
    
    if not slot then
        warn("[Ghost Killaura] No cooked meat found in inventory!")
        return false
    end
    
    -- Create eating packet with the found slot
    local eatBuf = createEatingBuffer(slot)
    
    local success, err = pcall(function()
        ByteNetReliable:FireServer(eatBuf)
    end)
    
    return success
end

-- Helper: Check and manage hunger
local function checkAndEatIfNeeded()
    local hunger = getHungerValue()
    
    if not hunger then
        return
    end
    
    -- If hunger equals 80, eat once
    if hunger == 80 then
        eatCookedMeat()
    -- If hunger is below 80, calculate meals needed and eat
    elseif hunger < 80 then
        local mealsNeeded = math.ceil((100 - hunger) / 20)
        
        for i = 1, mealsNeeded do
            eatCookedMeat()
            task.wait(0.2) -- Wait 0.2 seconds between eating
        end
    end
end

-- Helper function to get entity ID from ghost instance
local function getEntityId(ghost)
    if not ghost then
        return nil
    end
    
    -- Method 1: Try GetAttribute("EntityID") - the correct attribute name
    local entityId = ghost:GetAttribute("EntityID")
    if entityId then
        if settings.debug then
            print(string.format("Found EntityID: %d (0x%08x)", entityId, entityId))
        end
        return entityId
    end
    
    -- Method 2: Try Name as number (fallback)
    local nameAsNumber = tonumber(ghost.Name)
    if nameAsNumber then
        if settings.debug then
            print(string.format("Found EntityId from Name: %d (0x%08x)", nameAsNumber, nameAsNumber))
        end
        return nameAsNumber
    end
    
    -- Method 3: Try other attribute variations (fallback)
    local attributes = ghost:GetAttributes()
    for attrName, attrValue in pairs(attributes) do
        if type(attrValue) == "number" and (attrName:lower():find("id") or attrName:lower():find("entity")) then
            if settings.debug then
                print(string.format("Found EntityId from Attribute '%s': %d (0x%08x)", attrName, attrValue, attrValue))
            end
            return attrValue
        end
    end
    
    -- Method 3: Check PrimaryPart and its attributes
    if ghost:IsA("Model") and ghost.PrimaryPart then
        local ppAttrs = ghost.PrimaryPart:GetAttributes()
        for attrName, attrValue in pairs(ppAttrs) do
            if type(attrValue) == "number" and (attrName:lower():find("id") or attrName:lower():find("entity")) then
                if settings.debug then
                    print(string.format("Found EntityId from PrimaryPart Attribute '%s': %d (0x%08x)", attrName, attrValue, attrValue))
                end
                return attrValue
            end
        end
    end
    
    -- Method 4: Try common child names (check all children for Value objects)
    for _, child in ipairs(ghost:GetChildren()) do
        -- Check if child name contains "id" or "entity"
        if child.Name:lower():find("id") or child.Name:lower():find("entity") then
            if child:IsA("IntValue") or child:IsA("NumberValue") then
                if settings.debug then
                    print(string.format("Found EntityId from %s: %d (0x%08x)", child.Name, child.Value, child.Value))
                end
                return child.Value
            end
        end
        
        -- Check Configuration for values
        if child:IsA("Configuration") then
            for _, configChild in ipairs(child:GetChildren()) do
                if (configChild.Name:lower():find("id") or configChild.Name:lower():find("entity")) and configChild:IsA("IntValue") then
                    if settings.debug then
                        print(string.format("Found EntityId from Configuration.%s: %d (0x%08x)", configChild.Name, configChild.Value, configChild.Value))
                    end
                    return configChild.Value
                end
            end
        end
    end
    
    -- Method 5: Check all descendants for any numeric values that might be the ID
    for _, descendant in ipairs(ghost:GetDescendants()) do
        if descendant:IsA("IntValue") or descendant:IsA("NumberValue") then
            local value = descendant.Value
            -- Entity IDs in the examples are in the millions (4104462, 4105432, 6396880)
            if value > 1000000 and value < 10000000 then
                if settings.debug then
                    print(string.format("Found potential EntityId from %s: %d (0x%08x)", descendant:GetFullName(), value, value))
                end
                return value
            end
        end
    end
    
    -- Debug: Print detailed information about what we found
    if settings.debug then
        warn("\n" .. string.rep("=", 50))
        warn("Could not find EntityId for ghost!")
        warn("  Full Path:", ghost:GetFullName())
        warn("  Name:", ghost.Name, "(" .. ghost.ClassName .. ")")
        
        -- Print all attributes
        local attrs = ghost:GetAttributes()
        if next(attrs) then
            warn("  Attributes:")
            for k, v in pairs(attrs) do
                warn(string.format("    %s = %s (%s)", k, tostring(v), type(v)))
            end
        else
            warn("  Attributes: (none)")
        end
        
        -- Print all children with details
        warn("  Children:")
        for _, child in ipairs(ghost:GetChildren()) do
            local childInfo = string.format("    - %s (%s)", child.Name, child.ClassName)
            if child:IsA("IntValue") or child:IsA("NumberValue") then
                childInfo = childInfo .. string.format(" = %d", child.Value)
            end
            warn(childInfo)
            
            -- Print attributes of children
            local childAttrs = child:GetAttributes()
            if next(childAttrs) then
                for k, v in pairs(childAttrs) do
                    warn(string.format("      Attribute: %s = %s", k, tostring(v)))
                end
            end
        end
        warn(string.rep("=", 50) .. "\n")
    end
    
    return nil
end

-- Create attack buffer for a ghost (attack type 1)
local function createGhostAttackBuffer(entityId)
    local buf = buffer.create(7)
    
    -- Byte 0: Packet ID (17)
    buffer.writeu8(buf, 0, 17)
    
    -- Byte 1: Attack type (1 for ghosts)
    buffer.writeu8(buf, 1, 1)
    
    -- Byte 2: Flags (0)
    buffer.writeu8(buf, 2, 0)
    
    -- Bytes 3-6: Entity ID (little-endian int32)
    buffer.writeu32(buf, 3, entityId)
    
    return buf
end

-- Create attack buffer for a player (attack type 2, 11 bytes)
local function createPlayerAttackBuffer(entityId)
    local buf = buffer.create(11)
    
    -- Byte 0: Packet ID (17)
    buffer.writeu8(buf, 0, 17)
    
    -- Byte 1: Attack type (2 for players)
    buffer.writeu8(buf, 1, 2)
    
    -- Byte 2: Flags (0)
    buffer.writeu8(buf, 2, 0)
    
    -- Bytes 3-10: Based on packet analysis (11 bytes total)
    -- This appears to be a more complex structure for player attacks
    buffer.writeu8(buf, 3, 1)
    buffer.writeu8(buf, 4, 30)
    buffer.writeu8(buf, 5, 0)
    buffer.writeu8(buf, 6, 0)
    buffer.writeu32(buf, 7, entityId)
    
    return buf
end

-- Helper: Get player's EntityID
local function getPlayerEntityId(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then
        return nil
    end
    
    -- Try to get EntityID from character
    local entityId = targetPlayer.Character:GetAttribute("EntityID")
    if entityId then
        return entityId
    end
    
    -- Try from HumanoidRootPart
    local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        entityId = hrp:GetAttribute("EntityID")
        if entityId then
            return entityId
        end
    end
    
    return nil
end

-- Attack a ghost
local function attackGhost(ghost)
    if not ghost or not ghost.Parent then
        return false
    end
    
    -- Check distance
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local ghostPos = ghost:GetPivot().Position
        local playerPos = LocalPlayer.Character.HumanoidRootPart.Position
        local distance = (ghostPos - playerPos).Magnitude
        
        if distance > settings.maxDistance then
            return false
        end
    end
    
    -- Get entity ID
    local entityId = getEntityId(ghost)
    if not entityId then
        return false
    end
    
    -- Create and send attack packet for ghost
    local attackBuffer = createGhostAttackBuffer(entityId)
    ByteNetReliable:FireServer(attackBuffer)
    
    if settings.debug then
        print(string.format("Attacked ghost (EntityId: %d)", entityId))
    end
    
    return true
end

-- Attack a player
local function attackPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then
        return false
    end
    
    -- Check distance
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not targetHRP then
            return false
        end
        
        local playerPos = LocalPlayer.Character.HumanoidRootPart.Position
        local targetPos = targetHRP.Position
        local distance = (targetPos - playerPos).Magnitude
        
        if distance > settings.maxDistance then
            return false
        end
    end
    
    -- Get entity ID
    local entityId = getPlayerEntityId(targetPlayer)
    if not entityId then
        if settings.debug then
            warn("Cannot find EntityID for player:", targetPlayer.Name)
        end
        return false
    end
    
    -- Create and send attack packet for player
    local attackBuffer = createPlayerAttackBuffer(entityId)
    ByteNetReliable:FireServer(attackBuffer)
    
    if settings.debug then
        print(string.format("Attacked player %s (EntityId: %d)", targetPlayer.Name, entityId))
    end
    
    return true
end

-- Attack loop for a specific ghost
local function attackLoop(ghost)
    -- Allow multiple attack loops for different ghosts
    local ghostKey = tostring(ghost)
    
    while ghost and ghost.Parent and settings.enabled do
        if attackGhost(ghost) then
            task.wait(settings.attackDelay)
        else
            -- If attack failed, wait a bit before trying again
            task.wait(0.5)
        end
    end
    
    if settings.debug then
        print("Ghost killed or despawned:", ghost.Name)
    end
    
    activeGhosts[ghost] = nil
end

-- Attack loop for players
local function playerAttackLoop(targetPlayer)
    while targetPlayer and targetPlayer.Parent and settings.enabled do
        -- Check if still in target list (or if attack all mode is enabled)
        if not settings.attackAllPlayers and not targetPlayers[targetPlayer.Name] then
            break
        end
        
        if attackPlayer(targetPlayer) then
            task.wait(settings.attackDelay)
        else
            task.wait(0.5)
        end
    end
    
    if settings.debug then
        print("Stopped attacking player:", targetPlayer.Name)
    end
    
    activePlayers[targetPlayer] = nil
end

-- Monitor for target players
local function monitorPlayers()
    -- Scan for target players
    local function scanForPlayers()
        if settings.attackAllPlayers then
            -- Attack all players in range
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and settings.enabled then
                    if not activePlayers[player] then
                        activePlayers[player] = true
                        if settings.debug then
                            print("Attacking all - detected player:", player.Name)
                        end
                        task.spawn(playerAttackLoop, player)
                    end
                end
            end
        else
            -- Only attack players in target list
            for username, _ in pairs(targetPlayers) do
                local targetPlayer = Players:FindFirstChild(username)
                if targetPlayer and targetPlayer ~= LocalPlayer and settings.enabled then
                    if not activePlayers[targetPlayer] then
                        activePlayers[targetPlayer] = true
                        if settings.debug then
                            print("Target player detected:", username)
                        end
                        task.spawn(playerAttackLoop, targetPlayer)
                    end
                end
            end
        end
    end
    
    -- Scan periodically
    task.spawn(function()
        while true do
            task.wait(1)
            if settings.enabled then
                scanForPlayers()
            end
        end
    end)
    
    -- Monitor player added
    Players.PlayerAdded:Connect(function(player)
        task.wait(2) -- Wait for character to load
        if settings.enabled and (settings.attackAllPlayers or targetPlayers[player.Name]) then
            scanForPlayers()
        end
    end)
end

-- Monitor for ghost spawns
local function monitorGhosts()
    local ghostsFolder = workspace:WaitForChild("Critters")
    
    -- Handle existing ghosts when script starts
    local function scanForGhosts()
        for _, child in ipairs(ghostsFolder:GetChildren()) do
            if child.Name == "Ghost" and not activeGhosts[child] and settings.enabled then
                activeGhosts[child] = true
                if settings.debug then
                    print("Ghost detected! Starting attack...")
                end
                task.spawn(attackLoop, child)
            end
        end
    end
    
    -- Scan initially
    scanForGhosts()
    
    -- Monitor for new ghosts
    ghostsFolder.ChildAdded:Connect(function(child)
        task.wait(0.1)  -- Give the ghost time to fully load
        
        if child.Name == "Ghost" and settings.enabled and not activeGhosts[child] then
            activeGhosts[child] = true
            if settings.debug then
                print("Ghost spawned! Starting attack...")
            end
            task.spawn(attackLoop, child)
        end
    end)
    
    -- Clean up when ghosts are removed
    ghostsFolder.ChildRemoved:Connect(function(child)
        if child.Name == "Ghost" then
            activeGhosts[child] = nil
        end
    end)
    
    -- Periodically scan for ghosts (in case we missed any)
    task.spawn(function()
        while true do
            task.wait(2)
            if settings.enabled then
                scanForGhosts()
            end
        end
    end)
end

-- Start the killaura system
print("=== Ghost & Player Killaura Loaded ===")
print("Settings:")
print("  Attack Delay:", settings.attackDelay, "seconds")
print("  Max Distance:", settings.maxDistance, "studs")
print("  Debug Mode:", settings.debug)
print("\nGUI created! Add target players and enable killaura")
print("Status: DISABLED")

monitorGhosts()
monitorPlayers()

-- Monitor for death and handle respawn
local wasAlive = true
task.spawn(function()
    while true do
        task.wait(0.5)
        
        if settings.enabled and not isRespawning then
            local currentlyDead = isDead()
            
            -- Detect death (transition from alive to dead)
            if wasAlive and currentlyDead then
                print("[Killaura] Death detected!")
                task.spawn(handleRespawn)
            end
            
            wasAlive = not currentlyDead
        end
    end
end)

-- Keep script running and check hunger
RunService.Heartbeat:Connect(function()
    local currentTime = tick()
    
    -- Check hunger every 1 second when killaura is enabled
    if settings.enabled and currentTime - lastHungerCheck >= HUNGER_CHECK_INTERVAL then
        lastHungerCheck = currentTime
        checkAndEatIfNeeded()
    end
end)
