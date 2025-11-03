-- Ghost Script - Auto Reset with Player Tracking
-- Resets for 10 minutes, then tries to spawn near target player

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Toggle state
local autoResetEnabled = false
local targetPlayers = {} -- Dictionary of usernames to track
local RESET_DURATION = 600 -- 10 minutes in seconds
local SEARCH_RADIUS = 20 -- 20 studs

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GhostResetGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Create main frame (larger to fit player list)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 280, 0, 350)
mainFrame.Position = UDim2.new(0.5, -140, 0.1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Add UI Corner for rounded edges
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- Create title label
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.Position = UDim2.new(0, 0, 0, 5)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Ghost Player Tracker"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 16
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame

-- Create username label
local usernameLabel = Instance.new("TextLabel")
usernameLabel.Name = "UsernameLabel"
usernameLabel.Size = UDim2.new(1, -20, 0, 20)
usernameLabel.Position = UDim2.new(0, 10, 0, 40)
usernameLabel.BackgroundTransparency = 1
usernameLabel.Text = "Target Username:"
usernameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
usernameLabel.TextSize = 12
usernameLabel.Font = Enum.Font.Gotham
usernameLabel.TextXAlignment = Enum.TextXAlignment.Left
usernameLabel.Parent = mainFrame

-- Create player input box
local playerInput = Instance.new("TextBox")
playerInput.Name = "PlayerInput"
playerInput.Size = UDim2.new(1, -90, 0, 30)
playerInput.Position = UDim2.new(0, 10, 0, 65)
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
addButton.Position = UDim2.new(1, -75, 0, 65)
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
listFrame.Size = UDim2.new(1, -20, 0, 180)
listFrame.Position = UDim2.new(0, 10, 0, 105)
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

-- Create toggle button
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(1, -20, 0, 35)
toggleButton.Position = UDim2.new(0, 10, 0, 295)
toggleButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
toggleButton.Text = "OFF"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = 14
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Parent = mainFrame

-- Add UI Corner to button
local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 6)
buttonCorner.Parent = toggleButton

-- Helper: Get player position
local function getPlayerPosition()
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		return player.Character.HumanoidRootPart.Position
	end
	return nil
end

-- Helper: Check if any target player is in radius
local function isAnyTargetInRadius()
	local myPos = getPlayerPosition()
	if not myPos then
		return false, nil
	end
	
	-- Check all target players
	for username, _ in pairs(targetPlayers) do
		local targetPlayer = Players:FindFirstChild(username)
		if targetPlayer and targetPlayer.Character then
			local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
			if targetHRP then
				local distance = (targetHRP.Position - myPos).Magnitude
				if distance <= SEARCH_RADIUS then
					return true, username
				end
			end
		end
	end
	
	return false, nil
end

-- Helper: Check if player is dead
local function isDead()
	if not player.Character then
		return true
	end
	
	local humanoid = player.Character:FindFirstChild("Humanoid")
	if not humanoid then
		return true
	end
	
	return humanoid.Health <= 0
end

-- Function to reset character
local function resetCharacter()
	if player.Character and player.Character:FindFirstChild("Humanoid") then
		player.Character.Humanoid.Health = 0
	end
end

-- Function to activate spawn button (like bedSpawn in Auto Rebirth)
local function activateSpawnButton()
	local spawnGui = playerGui:FindFirstChild("SpawnGui")
	if not spawnGui then
		warn("SpawnGui not found!")
		return false
	end
	
	local customization = spawnGui:FindFirstChild("Customization")
	if not customization then
		warn("Customization not found!")
		return false
	end
	
	local playButton = customization:FindFirstChild("PlayButton")
	if not playButton then
		warn("PlayButton not found!")
		return false
	end
	
	-- Activate the button like in Auto Rebirth
	firesignal(playButton.Activated)
	print("Spawn button activated")
	return true
end

-- Update button appearance
local function updateButton()
	if autoResetEnabled then
		toggleButton.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
		toggleButton.Text = "ACTIVE"
	else
		toggleButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
		toggleButton.Text = "OFF"
	end
end

-- Toggle button click handler
toggleButton.MouseButton1Click:Connect(function()
	-- Check if there are any target players
	local hasTargets = false
	for _ in pairs(targetPlayers) do
		hasTargets = true
		break
	end
	
	if not hasTargets then
		warn("Please add at least one target player first!")
		return
	end
	
	autoResetEnabled = not autoResetEnabled
	updateButton()
	print("Ghost Tracker:", autoResetEnabled and "Enabled" or "Disabled")
end)

-- Main loop
task.spawn(function()
	while true do
		if autoResetEnabled then
			print("\n=== Starting Ghost Tracker ===")
			
			-- Check if we still have target players
			local hasTargets = false
			for _ in pairs(targetPlayers) do
				hasTargets = true
				break
			end
			
			if not hasTargets then
				print("No target players - disabling tracker")
				autoResetEnabled = false
				updateButton()
				task.wait(1)
			else
				-- Phase 1: Try to spawn near any target player
				local foundTarget = false
				while not foundTarget and autoResetEnabled do
					-- Activate spawn button
					print("Activating spawn button...")
					if activateSpawnButton() then
						task.wait(2)
						
						-- Check if any target player is in radius
						local inRange, foundUsername = isAnyTargetInRadius()
						if inRange then
							print("✓ Target player found in radius:", foundUsername)
							foundTarget = true
							
							-- Phase 2: Wait until killed
							print("Waiting for death...")
							while not isDead() and autoResetEnabled do
								task.wait(1)
							end
							
							print("Player died - waiting 3 seconds before respawn")
							task.wait(3)
							-- Loop will restart and activate spawn button again
						else
							print("✗ No target players in radius - resetting...")
							resetCharacter()
							task.wait(3)
							-- Loop continues to try spawn again
						end
					else
						warn("Failed to activate spawn button - waiting before retry")
						task.wait(5)
					end
				end
			end
		else
			task.wait(1)
		end
	end
end)
