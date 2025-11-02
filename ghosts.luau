-- Ghost Script - Auto Reset with Player Tracking
-- Resets for 10 minutes, then tries to spawn near target player

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Toggle state
local autoResetEnabled = false
local targetUsername = "" -- Username to search for
local RESET_DURATION = 600 -- 10 minutes in seconds
local SEARCH_RADIUS = 20 -- 20 studs

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GhostResetGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Create main frame (larger to fit username input)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 250, 0, 160)
mainFrame.Position = UDim2.new(0.5, -125, 0.1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
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

-- Create username input box
local usernameInput = Instance.new("TextBox")
usernameInput.Name = "UsernameInput"
usernameInput.Size = UDim2.new(1, -20, 0, 30)
usernameInput.Position = UDim2.new(0, 10, 0, 65)
usernameInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
usernameInput.BorderSizePixel = 0
usernameInput.Text = ""
usernameInput.PlaceholderText = "Enter username..."
usernameInput.TextColor3 = Color3.fromRGB(255, 255, 255)
usernameInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
usernameInput.TextSize = 14
usernameInput.Font = Enum.Font.Gotham
usernameInput.Parent = mainFrame

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 6)
inputCorner.Parent = usernameInput

-- Create toggle button
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(1, -20, 0, 40)
toggleButton.Position = UDim2.new(0, 10, 0, 110)
toggleButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
toggleButton.Text = "OFF"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = 18
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

-- Helper: Get target player position
local function getTargetPlayerPosition()
	if targetUsername == "" then
		return nil
	end
	
	local targetPlayer = Players:FindFirstChild(targetUsername)
	if not targetPlayer then
		return nil
	end
	
	if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
		return targetPlayer.Character.HumanoidRootPart.Position
	end
	
	return nil
end

-- Helper: Check if target player is in radius
local function isTargetInRadius()
	local myPos = getPlayerPosition()
	local targetPos = getTargetPlayerPosition()
	
	if not myPos or not targetPos then
		return false
	end
	
	local distance = (targetPos - myPos).Magnitude
	return distance <= SEARCH_RADIUS
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

-- Update username input handler
usernameInput.FocusLost:Connect(function(enterPressed)
	targetUsername = usernameInput.Text
	print("Target username set to:", targetUsername)
end)

-- Toggle button click handler
toggleButton.MouseButton1Click:Connect(function()
	if usernameInput.Text == "" then
		warn("Please enter a target username first!")
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
			
			-- Phase 1: Try to spawn near target player
			local foundTarget = false
			while not foundTarget and autoResetEnabled do
				-- Activate spawn button
				print("Activating spawn button...")
				if activateSpawnButton() then
					task.wait(2)
					
					-- Check if target player is in radius
					if isTargetInRadius() then
						print("✓ Target player found in radius!")
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
						print("✗ Target player not in radius - resetting...")
						resetCharacter()
						task.wait(3)
						-- Loop continues to try spawn again
					end
				else
					warn("Failed to activate spawn button - waiting before retry")
					task.wait(5)
				end
			end
		else
			task.wait(1)
		end
	end
end)
