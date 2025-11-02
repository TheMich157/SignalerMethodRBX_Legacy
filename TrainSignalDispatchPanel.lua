-- Train Signal Dispatch Panel UI
-- LocalScript - Place this in StarterGui or StarterPlayer > StarterPlayerScripts
-- Creates a GUI panel for controlling train signals

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for the TrainSignalSystem module (if needed for remote events)
wait(2) -- Wait for server to initialize

-- ============================================================================
-- UI CREATION
-- ============================================================================

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TrainSignalDispatchPanel"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 450, 0, 500)
mainFrame.Position = UDim2.new(0.5, -225, 0.5, -250)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Corner
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 50)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Name = "TitleText"
titleText.Size = UDim2.new(1, -100, 1, 0)
titleText.Position = UDim2.new(0, 15, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "🚂 Train Signal Dispatch Panel"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.TextScaled = true
titleText.Font = Enum.Font.GothamBold
titleText.Parent = titleBar

-- Close Button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 40, 0, 40)
closeButton.Position = UDim2.new(1, -50, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.Text = "✕"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextScaled = true
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

-- Semaphore Selector
local semaphoreSelectorFrame = Instance.new("Frame")
semaphoreSelectorFrame.Name = "SemaphoreSelector"
semaphoreSelectorFrame.Size = UDim2.new(1, -30, 0, 50)
semaphoreSelectorFrame.Position = UDim2.new(0, 15, 0, 60)
semaphoreSelectorFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
semaphoreSelectorFrame.BorderSizePixel = 0
semaphoreSelectorFrame.Parent = mainFrame

local selectorCorner = Instance.new("UICorner")
selectorCorner.CornerRadius = UDim.new(0, 8)
selectorCorner.Parent = semaphoreSelectorFrame

local selectorLabel = Instance.new("TextLabel")
selectorLabel.Name = "Label"
selectorLabel.Size = UDim2.new(0, 150, 1, 0)
selectorLabel.Position = UDim2.new(0, 10, 0, 0)
selectorLabel.BackgroundTransparency = 1
selectorLabel.Text = "Signal:"
selectorLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
selectorLabel.TextScaled = true
selectorLabel.Font = Enum.Font.Gotham
selectorLabel.TextXAlignment = Enum.TextXAlignment.Left
selectorLabel.Parent = semaphoreSelectorFrame

local selectorDropdown = Instance.new("TextButton")
selectorDropdown.Name = "Dropdown"
selectorDropdown.Size = UDim2.new(0, 200, 0, 35)
selectorDropdown.Position = UDim2.new(0, 160, 0, 7.5)
selectorDropdown.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
selectorDropdown.Text = "Select signal"
selectorDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
selectorDropdown.TextScaled = true
selectorDropdown.Font = Enum.Font.Gotham
selectorDropdown.Parent = semaphoreSelectorFrame

local dropdownCorner = Instance.new("UICorner")
dropdownCorner.CornerRadius = UDim.new(0, 6)
dropdownCorner.Parent = selectorDropdown

-- Dropdown hover effect
selectorDropdown.MouseEnter:Connect(function()
	local tween = TweenService:Create(
		selectorDropdown,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundColor3 = Color3.fromRGB(80, 80, 90)}
	)
	tween:Play()
end)

selectorDropdown.MouseLeave:Connect(function()
	local tween = TweenService:Create(
		selectorDropdown,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundColor3 = Color3.fromRGB(60, 60, 70)}
	)
	tween:Play()
end)

-- Status Display
local statusFrame = Instance.new("Frame")
statusFrame.Name = "StatusFrame"
statusFrame.Size = UDim2.new(1, -30, 0, 60)
statusFrame.Position = UDim2.new(0, 15, 0, 120)
statusFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
statusFrame.BorderSizePixel = 0
statusFrame.Parent = mainFrame

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 8)
statusCorner.Parent = statusFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "Label"
statusLabel.Size = UDim2.new(0, 100, 0, 25)
statusLabel.Position = UDim2.new(0, 15, 0, 5)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status:"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.TextScaled = true
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = statusFrame

local statusText = Instance.new("TextLabel")
statusText.Name = "StatusText"
statusText.Size = UDim2.new(1, -30, 0, 30)
statusText.Position = UDim2.new(0, 15, 0, 30)
statusText.BackgroundTransparency = 1
statusText.Text = "STOP"
statusText.TextColor3 = Color3.fromRGB(255, 50, 50)
statusText.TextScaled = true
statusText.Font = Enum.Font.GothamBold
statusText.Parent = statusFrame

-- Control Buttons Frame
local buttonsFrame = Instance.new("Frame")
buttonsFrame.Name = "ButtonsFrame"
buttonsFrame.Size = UDim2.new(1, -30, 0, 310)
buttonsFrame.Position = UDim2.new(0, 15, 0, 190)
buttonsFrame.BackgroundTransparency = 1
buttonsFrame.Parent = mainFrame

-- Button Template Function
local function CreateControlButton(name, text, color, position, size)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size or UDim2.new(0, 130, 0, 55)
	button.Position = position
	button.BackgroundColor3 = color
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.Parent = buttonsFrame
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = button
	
	-- Hover effect
	button.MouseEnter:Connect(function()
		local r, g, b = color.R * 255, color.G * 255, color.B * 255
		local hoverColor = Color3.fromRGB(
			math.min(r + 30, 255),
			math.min(g + 30, 255),
			math.min(b + 30, 255)
		)
		local tween = TweenService:Create(
			button,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundColor3 = hoverColor}
		)
		tween:Play()
	end)
	
	button.MouseLeave:Connect(function()
		local tween = TweenService:Create(
			button,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundColor3 = color}
		)
		tween:Play()
	end)
	
	-- Click effect
	button.MouseButton1Down:Connect(function()
		local tween = TweenService:Create(
			button,
			TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Size = button.Size - UDim2.new(0, 5, 0, 5)}
		)
		tween:Play()
	end)
	
	button.MouseButton1Up:Connect(function()
		local tween = TweenService:Create(
			button,
			TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Size = button.Size}
		)
		tween:Play()
	end)
	
	return button
end

-- Create Control Buttons
local stopButton = CreateControlButton("StopButton", "STOP", Color3.fromRGB(200, 50, 50), UDim2.new(0, 0, 0, 0))
local vmaxButton = CreateControlButton("VmaxButton", "VMAX", Color3.fromRGB(50, 200, 50), UDim2.new(0, 140, 0, 0))
local yellowButton = CreateControlButton("YellowButton", "YELLOW", Color3.fromRGB(255, 200, 50), UDim2.new(0, 280, 0, 0))

local doubleYellowButton = CreateControlButton("DoubleYellowButton", "DOUBLE YELLOW", Color3.fromRGB(255, 220, 100), UDim2.new(0, 0, 0, 65), UDim2.new(0, 200, 0, 55))
local greenYellowButton = CreateControlButton("GreenYellowButton", "GREEN+YELLOW", Color3.fromRGB(100, 255, 150), UDim2.new(0, 210, 0, 65), UDim2.new(0, 200, 0, 55))

-- Info Section
local infoFrame = Instance.new("Frame")
infoFrame.Name = "InfoFrame"
infoFrame.Size = UDim2.new(1, -30, 0, 80)
infoFrame.Position = UDim2.new(0, 15, 0, 130)
infoFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
infoFrame.BorderSizePixel = 0
infoFrame.Parent = buttonsFrame
infoFrame.Position = UDim2.new(0, 0, 0, 130)

local infoCorner = Instance.new("UICorner")
infoCorner.CornerRadius = UDim.new(0, 8)
infoCorner.Parent = infoFrame

local infoText = Instance.new("TextLabel")
infoText.Name = "InfoText"
infoText.Size = UDim2.new(1, -20, 1, -10)
infoText.Position = UDim2.new(0, 10, 0, 5)
infoText.BackgroundTransparency = 1
infoText.Text = "Direct control panel - Click any button to instantly change the signal state. Status updates in real-time."
infoText.TextColor3 = Color3.fromRGB(180, 180, 180)
infoText.TextWrapped = true
infoText.TextSize = 14
infoText.Font = Enum.Font.Gotham
infoText.TextXAlignment = Enum.TextXAlignment.Left
infoText.TextYAlignment = Enum.TextYAlignment.Top
infoText.Parent = infoFrame

-- Toggle Button (to show/hide panel)
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(0, 60, 0, 60)
toggleButton.Position = UDim2.new(1, -70, 0, 20)
toggleButton.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
toggleButton.Text = "🚂"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextScaled = true
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Visible = false
toggleButton.Parent = screenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 25)
toggleCorner.Parent = toggleButton

-- Ensure nothing clips the dropdown
mainFrame.ClipsDescendants = false
semaphoreSelectorFrame.ClipsDescendants = false
buttonsFrame.ClipsDescendants = false

-- Push dropdown to the top



-- ============================================================================
-- FUNCTIONALITY
-- ============================================================================

local currentSemaphore = "Semaphore1"  -- Use actual semaphore name
local currentState = "STOP"
local isVisible = true
local listListenerConnected = false


-- Update Status Display
local function UpdateStatus(state)
	currentState = state
	local colors = {
		STOP = Color3.fromRGB(255, 50, 50),
		VMAX = Color3.fromRGB(50, 255, 50),
		YELLOW = Color3.fromRGB(255, 200, 50),
		["DOUBLE YELLOW"] = Color3.fromRGB(255, 220, 100),
		["GREEN+YELLOW"] = Color3.fromRGB(100, 255, 150)
	}
	
	statusText.Text = state
	statusText.TextColor3 = colors[state] or Color3.fromRGB(255, 255, 255)
end

-- Store button states for visual feedback
local activeButton = nil
local allButtons = {}

-- Update button active state
local function SetActiveButton(button, stateText)
	-- Reset all buttons
	for _, btn in pairs(allButtons) do
		local tween = TweenService:Create(
			btn,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Size = UDim2.new(0, btn:GetAttribute("OriginalSizeX") or 130, 0, btn:GetAttribute("OriginalSizeY") or 55)}
		)
		tween:Play()
	end
	
	-- Highlight active button
	if button then
		activeButton = button
		local originalX = button:GetAttribute("OriginalSizeX") or 130
		local originalY = button:GetAttribute("OriginalSizeY") or 55
		local tween = TweenService:Create(
			button,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Size = UDim2.new(0, originalX + 10, 0, originalY + 10)}
		)
		tween:Play()
	end
	
	UpdateStatus(stateText)
end

-- Send Command to Server (Direct UI Control - Game-like)
local function SendCommand(command, button, stateText)
	-- Wait for RemoteEvent
	local remoteEvent = ReplicatedStorage:WaitForChild("TrainSignalCommand", 5)
	
	if not remoteEvent then
		warn("[Dispatch Panel] RemoteEvent not found! Make sure TrainSignalRemoteHandler is running.")
		return false
	end
	
	-- Visual feedback: Set button as active
	SetActiveButton(button, stateText)
	
	-- Send command directly via RemoteEvent
	remoteEvent:FireServer(command, currentSemaphore)
	
	-- Play click sound effect (optional - uncomment if you have sound IDs)
	-- game:GetService("SoundService"):PlaySound(soundId)
	
	return true
end

-- Create button click handler with game-like feedback
local function CreateButtonHandler(button, command, stateText)
	button.MouseButton1Click:Connect(function()
		-- Visual feedback on click
		local originalX = button:GetAttribute("OriginalSizeX") or 130
		local originalY = button:GetAttribute("OriginalSizeY") or 55
		local originalSize = UDim2.new(0, originalX, 0, originalY)
		
		-- Click animation: shrink
		local clickTween = TweenService:Create(
			button,
			TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{Size = originalSize - UDim2.new(0, 8, 0, 8)}
		)
		clickTween:Play()
		
		clickTween.Completed:Connect(function()
			-- Restore size
			local restoreTween = TweenService:Create(
				button,
				TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Size = originalSize}
			)
			restoreTween:Play()
			
			-- Send command (which will then highlight the button)
			restoreTween.Completed:Wait()
			SendCommand(command, button, stateText)
		end)
	end)
end

-- Register all buttons
table.insert(allButtons, stopButton)
table.insert(allButtons, vmaxButton)
table.insert(allButtons, yellowButton)
table.insert(allButtons, doubleYellowButton)
table.insert(allButtons, greenYellowButton)

-- Store original sizes
for _, btn in pairs(allButtons) do
	local size = btn.Size
	btn:SetAttribute("OriginalSizeX", size.X.Offset)
	btn:SetAttribute("OriginalSizeY", size.Y.Offset)
end

-- Button Click Handlers (Game-like Direct Control)
CreateButtonHandler(stopButton, "stop", "STOP")
CreateButtonHandler(vmaxButton, "vmax", "VMAX")
CreateButtonHandler(yellowButton, "yellow", "YELLOW")
CreateButtonHandler(doubleYellowButton, "doubleyellow", "DOUBLE YELLOW")
CreateButtonHandler(greenYellowButton, "greenyellow", "GREEN+YELLOW")

-- Close Button
closeButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
	toggleButton.Visible = true
	isVisible = false
end)

-- Toggle Button
toggleButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = true
	toggleButton.Visible = false
	isVisible = true
	
	-- Animate panel opening
	mainFrame.Size = UDim2.new(0, 0, 0, 0)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	local tween = TweenService:Create(
		mainFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{
			Size = UDim2.new(0, 450, 0, 500),
			Position = UDim2.new(0.5, -225, 0.5, -250)
		}
	)
	tween:Play()
end)

-- Semaphore list and dropdown functionality
local availableSemaphores = {}
local isDropdownOpen = false

-- Function to request status for current semaphore
local statusRemote = ReplicatedStorage:WaitForChild("TrainSignalGetStatus", 10)
local function RequestInitialStatus()
	if currentSemaphore and statusRemote then
		statusRemote:FireServer(currentSemaphore)
	end
end

-- Create dropdown menu (hidden by default)
local dropdownMenu = Instance.new("Frame")
dropdownMenu.Name = "DropdownMenu"
dropdownMenu.Size = UDim2.new(0, 200, 0, 120)
dropdownMenu.Position = UDim2.new(0, 160, 0, 42)
dropdownMenu.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
dropdownMenu.BorderSizePixel = 0
dropdownMenu.Visible = false
dropdownMenu.ZIndex = 10
dropdownMenu.Parent = semaphoreSelectorFrame

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 6)
menuCorner.Parent = dropdownMenu

-- Scroll frame for many semaphores
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "ScrollFrame"
scrollFrame.Size = UDim2.new(1, -4, 1, -4)
scrollFrame.Position = UDim2.new(0, 2, 0, 2)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 4
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.Parent = dropdownMenu

local menuListLayout = Instance.new("UIListLayout")
menuListLayout.Padding = UDim.new(0, 2)
menuListLayout.SortOrder = Enum.SortOrder.Name
menuListLayout.Parent = scrollFrame

menuListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, menuListLayout.AbsoluteContentSize.Y + 4)
	-- Limit dropdown height
	local maxHeight = 150
	local actualHeight = math.min(menuListLayout.AbsoluteContentSize.Y + 8, maxHeight)
	dropdownMenu.Size = UDim2.new(0, 200, 0, actualHeight)
end)

-- Update dropdown menu items
local function UpdateDropdownMenu()
	-- Clear existing items
	for _, child in pairs(scrollFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
			
		end
	end
	
	-- Add semaphore options
	local itemHeight = 30
	for i, semName in ipairs(availableSemaphores) do
		local item = Instance.new("TextButton")
		item.Name = semName
		item.Size = UDim2.new(1, -4, 0, itemHeight)
		item.Position = UDim2.new(0, 2, 0, (i - 1) * (itemHeight + 2))
		item.BackgroundColor3 = (semName == currentSemaphore) and Color3.fromRGB(70, 100, 150) or Color3.fromRGB(60, 60, 70)
		item.Text = semName
		item.TextColor3 = Color3.fromRGB(255, 255, 255)
		item.TextScaled = true
		item.Font = Enum.Font.Gotham
		item.ZIndex = 102
		item.Parent = scrollFrame
		
		local itemCorner = Instance.new("UICorner")
		itemCorner.CornerRadius = UDim.new(0, 4)
		itemCorner.Parent = item
		
		-- Hover effect
		item.MouseEnter:Connect(function()
			if item.BackgroundColor3 ~= Color3.fromRGB(70, 100, 150) then
				local tween = TweenService:Create(
					item,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{BackgroundColor3 = Color3.fromRGB(80, 80, 90)}
				)
				tween:Play()
			end
		end)
		
		item.MouseLeave:Connect(function()
			if item.BackgroundColor3 ~= Color3.fromRGB(70, 100, 150) then
				local tween = TweenService:Create(
					item,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{BackgroundColor3 = Color3.fromRGB(60, 60, 70)}
				)
				tween:Play()
			end
		end)
		
		-- Click to select
		item.MouseButton1Click:Connect(function()
			currentSemaphore = semName
			selectorDropdown.Text = semName
			dropdownMenu.Visible = false
			isDropdownOpen = false
			
			-- Request status for new semaphore
			RequestInitialStatus()
		end)
	end
	
	-- Size is handled by UIListLayout connection above
end

-- Toggle dropdown
selectorDropdown.MouseButton1Click:Connect(function()
	isDropdownOpen = not isDropdownOpen
	dropdownMenu.Visible = isDropdownOpen
	
	if isDropdownOpen then
		-- Refresh list when opening
		local listRemote   = ReplicatedStorage:WaitForChild("TrainSignalGetList", 10)
		if listRemote then
			listRemote:FireServer()
		end
	end
end)

-- Close dropdown when clicking outside
local userInputService = game:GetService("UserInputService")
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if isDropdownOpen then
			local mousePos = userInputService:GetMouseLocation()
			-- Check if click is outside dropdown
			-- This is simplified - in full implementation you'd check bounds
			isDropdownOpen = false
			dropdownMenu.Visible = false
		end
	end
end)

-- Get semaphore list from server
local function RefreshSemaphoreList()
	local listRemote = ReplicatedStorage:WaitForChild("TrainSignalGetList", 10)
	if not listRemote then return end

	if not listListenerConnected then
		listListenerConnected = true

		listRemote.OnClientEvent:Connect(function(semaphoreList)
			if semaphoreList and #semaphoreList > 0 then
				availableSemaphores = semaphoreList

				local found = false
				for _, name in ipairs(semaphoreList) do
					if name == currentSemaphore then
						found = true
						break
					end
				end
				if not found then
					currentSemaphore = semaphoreList[1]
				end

				selectorDropdown.Text = currentSemaphore or "Select signal"
				UpdateDropdownMenu()
				if currentSemaphore then
					RequestInitialStatus()
				end
			else
				selectorDropdown.Text = "No signals found"
				availableSemaphores = {}
				UpdateDropdownMenu()
			end
		end)
	end

	listRemote:FireServer()
end





-- Listen for server updates (Game-like feedback)
local remoteEvent = ReplicatedStorage:WaitForChild("TrainSignalCommand", 5)
if remoteEvent then
	remoteEvent.OnClientEvent:Connect(function(status, message)
		if status == "success" then
			-- Update status directly from message (message is the state name)
			if type(message) == "string" then
				-- Message is the state name directly: "STOP", "VMAX", "YELLOW", etc.
				UpdateStatus(message)
			end
			
			-- Success feedback: Brief flash on status display
			local originalColor = statusText.TextColor3
			local flashTween = TweenService:Create(
				statusText,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{TextColor3 = Color3.fromRGB(150, 255, 150)}
			)
			flashTween:Play()
			flashTween.Completed:Wait()
			local restoreTween = TweenService:Create(
				statusText,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{TextColor3 = originalColor}
			)
			restoreTween:Play()
		elseif status == "error" then
			-- Error feedback: Red flash
			local originalColor = statusText.TextColor3
			local errorTween = TweenService:Create(
				statusText,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{TextColor3 = Color3.fromRGB(255, 50, 50)}
			)
			errorTween:Play()
			errorTween.Completed:Wait()
			local restoreTween = TweenService:Create(
				statusText,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{TextColor3 = originalColor}
			)
			restoreTween:Play()
			warn("[Dispatch Panel] Command failed: " .. tostring(message))
		end
	end)
else
	warn("[Dispatch Panel] Could not find TrainSignalCommand RemoteEvent")
end
dropdownMenu.ZIndex = 100
scrollFrame.ZIndex  = 101
-- Request semaphore list on startup (will set currentSemaphore)
wait(2) -- Wait for server to be ready
RefreshSemaphoreList()

-- Also wait a bit more and try to get status if we have a semaphore
spawn(function()
	wait(1)
	if currentSemaphore then
		RequestInitialStatus()
	end
end)

-- Initialize
UpdateStatus("STOP")

-- Hide toggle button initially (panel is visible)
toggleButton.Visible = false

-- Set up status listener (after statusRemote is found)
if statusRemote then
	statusRemote.OnClientEvent:Connect(function(semName, status)
		-- Only update if this is the current semaphore
		if currentSemaphore and semName == currentSemaphore and status then
			UpdateStatus(status)
		end
	end)
end

print("[Dispatch Panel] UI loaded successfully")

