-- Train Signal System
-- Complete train signal controller with chat commands
-- Place this as a Server Script in ServerScriptService
-- Commands: !vmax, !stop, !yellow, !doubleyellow, !greenyellow

-- ============================================================================
-- SERVICES
-- ============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ============================================================================
-- DEBUG SETTINGS
-- ============================================================================

local DEBUG_MODE = true  -- Set to false to disable debug messages

local function DebugPrint(message, ...)
	if DEBUG_MODE then
		local timestamp = os.date("%H:%M:%S")
		print(string.format("[%s] [Train Signal DEBUG] " .. message, timestamp, ...))
	end
end

local function DebugWarn(message, ...)
	if DEBUG_MODE then
		local timestamp = os.date("%H:%M:%S")
		warn(string.format("[%s] [Train Signal DEBUG] " .. message, timestamp, ...))
	end
end

DebugPrint("Script loaded and starting initialization...")

-- ============================================================================
-- SEMAPHORE CLASS
-- ============================================================================

local Semaphore = {}
Semaphore.__index = Semaphore

-- Color constants
local GREEN = Color3.fromRGB(0, 255, 0)
local YELLOW = Color3.fromRGB(255, 255, 0)
local RED = Color3.fromRGB(255, 0, 0)
local BLACK = Color3.fromRGB(0, 0, 0)  -- Off

-- Create a new Semaphore instance
function Semaphore.new(name, light1, light2, light3, light4)
	local self = setmetatable({}, Semaphore)

	self.Name = name or "Semaphore1"
	self.Light1 = light1  -- Top light (Green when set)
	self.Light2 = light2  -- Second light (Yellow)
	self.Light3 = light3  -- Third light (Red - main stop signal)
	self.Light4 = light4  -- Fourth light (Yellow)
	self.CurrentState = "STOP"  -- Track current state

	return self
end

-- Set a light part to a specific color
local function SetLightColor(light, color, semaphoreName, lightNumber)
	if not light then
		DebugWarn("SetLightColor: Light is nil")
		return false
	end

	if not light:IsA("BasePart") then
		DebugWarn("SetLightColor: Light '%s' is not a BasePart (type: %s)", light.Name, light.ClassName)
		return false
	end

	-- Safety: Ensure part is anchored to prevent movement
	if not light.Anchored then
		DebugWarn("Light '%s' is not anchored! Anchoring to prevent movement.", light.Name)
		light.Anchored = true
	end

	-- Set part color and material
	local colorName = "UNKNOWN"
	if color == RED then
		colorName = "RED"
	elseif color == GREEN then
		colorName = "GREEN"
	elseif color == YELLOW then
		colorName = "YELLOW"
	elseif color == BLACK then
		colorName = "BLACK (OFF)"
	end

	light.Color = color

	if color == BLACK then
		-- When off, make it dark/plastic
		light.Material = Enum.Material.Plastic
		light.Transparency = 0.5  -- Semi-transparent when off
	else
		-- When on, make it bright/neon
		light.Material = Enum.Material.Neon
		light.Transparency = 0  -- Fully visible when on
	end

	DebugPrint("Set light '%s' (Light%d) to %s on semaphore '%s'", light.Name, lightNumber or 0, colorName, semaphoreName or "unknown")
	return true
end

-- Turn off all lights
function Semaphore:TurnOffAllLights()
	DebugPrint("Turning off all lights for semaphore '%s'", self.Name)
	SetLightColor(self.Light1, BLACK, self.Name, 1)
	SetLightColor(self.Light2, BLACK, self.Name, 2)
	SetLightColor(self.Light3, BLACK, self.Name, 3)
	SetLightColor(self.Light4, BLACK, self.Name, 4)
end

-- Command functions

-- !stop - Red at Light3
function Semaphore:SetStop()
	DebugPrint("Executing SetStop on semaphore '%s'", self.Name)
	self:TurnOffAllLights()
	SetLightColor(self.Light3, RED, self.Name, 3)
	self.CurrentState = "STOP"
	DebugPrint("Semaphore '%s' set to STOP (red)", self.Name)
end

-- !vmax - Green at Light1
function Semaphore:SetVmax()
	DebugPrint("Executing SetVmax on semaphore '%s'", self.Name)
	self:TurnOffAllLights()
	SetLightColor(self.Light1, GREEN, self.Name, 1)
	SetLightColor(self.Light3, BLACK, self.Name, 3)  -- Red light must be black when not in stop
	self.CurrentState = "VMAX"
	DebugPrint("Semaphore '%s' set to VMAX (green)", self.Name)
end

-- !yellow - Yellow at Light2 only
function Semaphore:SetYellow()
	DebugPrint("Executing SetYellow on semaphore '%s'", self.Name)
	self:TurnOffAllLights()
	SetLightColor(self.Light2, YELLOW, self.Name, 2)
	SetLightColor(self.Light3, BLACK, self.Name, 3)  -- Red light must be black
	self.CurrentState = "YELLOW"
	DebugPrint("Semaphore '%s' set to YELLOW", self.Name)
end

-- !doubleyellow - Yellow at Light2 and Light4
function Semaphore:SetDoubleYellow()
	DebugPrint("Executing SetDoubleYellow on semaphore '%s'", self.Name)
	self:TurnOffAllLights()
	SetLightColor(self.Light2, YELLOW, self.Name, 2)
	SetLightColor(self.Light4, YELLOW, self.Name, 4)
	SetLightColor(self.Light3, BLACK, self.Name, 3)  -- Red light must be black
	self.CurrentState = "DOUBLE YELLOW"
	DebugPrint("Semaphore '%s' set to DOUBLE YELLOW", self.Name)
end

-- !greenyellow - Green at Light1, Yellow at Light4
function Semaphore:SetGreenYellow()
	DebugPrint("Executing SetGreenYellow on semaphore '%s'", self.Name)
	self:TurnOffAllLights()
	SetLightColor(self.Light1, GREEN, self.Name, 1)
	SetLightColor(self.Light4, YELLOW, self.Name, 4)
	SetLightColor(self.Light3, BLACK, self.Name, 3)  -- Red light must be black
	self.CurrentState = "GREEN+YELLOW"
	DebugPrint("Semaphore '%s' set to GREEN+YELLOW", self.Name)
end

-- ============================================================================
-- COMMAND HANDLER
-- ============================================================================

-- Command registry with descriptions and aliases
local commandMap = {
	["stop"] = {
		method = "SetStop",
		description = "Set signal to STOP (red light)",
		aliases = {"s", "halt"}
	},
	["vmax"] = {
		method = "SetVmax",
		description = "Set signal to VMAX (green light - maximum speed)",
		aliases = {"go", "green", "clear"}
	},
	["yellow"] = {
		method = "SetYellow",
		description = "Set signal to YELLOW (single yellow light)",
		aliases = {"y"}
	},
	["doubleyellow"] = {
		method = "SetDoubleYellow",
		description = "Set signal to DOUBLE YELLOW (two yellow lights)",
		aliases = {"dy", "yy"}
	},
	["greenyellow"] = {
		method = "SetGreenYellow",
		description = "Set signal to GREEN+YELLOW (green and yellow light)",
		aliases = {"gy"}
	},
	["help"] = {
		method = "ShowHelp",
		description = "Show available commands",
		aliases = {"h", "?"}
	},
	["list"] = {
		method = "ListSemaphores",
		description = "List all available semaphores",
		aliases = {"ls", "semaphores"}
	}
}

-- Store all semaphores
local semaphores = {}

-- Build reverse alias map for faster lookup
local aliasMap = {}
for cmd, data in pairs(commandMap) do
	aliasMap[cmd] = cmd
	for _, alias in ipairs(data.aliases or {}) do
		aliasMap[alias] = cmd
	end
end

local commandCount = 0
local aliasCount = 0
for _ in pairs(commandMap) do commandCount = commandCount + 1 end
for _ in pairs(aliasMap) do aliasCount = aliasCount + 1 end

DebugPrint("Command map initialized with %d commands and %d total aliases", 
	commandCount, aliasCount)

-- Initialize semaphores
function InitializeSemaphores()
	DebugPrint("Starting semaphore initialization...")
	DebugPrint("Searching for semaphores in workspace.Semaphores folder...")

	-- Look for Semaphores folder
	local semaphoresFolder = workspace:FindFirstChild("Semaphores")
	if not semaphoresFolder then
		warn("[Train Signal] ✗ Semaphores folder not found in workspace!")
		warn("[Train Signal] Create a folder named 'Semaphores' in workspace and place your semaphore models inside it.")
		DebugWarn("Semaphores folder missing - cannot initialize signals")
		return
	end

	DebugPrint("Found Semaphores folder in workspace")

	-- Find all semaphore models in the Semaphores folder
	local semaphoreCount = 0
	for _, child in pairs(semaphoresFolder:GetChildren()) do
		-- Look for models that might be semaphores (Model or Folder with Light1-Light4)
		if child:IsA("Model") or child:IsA("Folder") then
			local semName = child.Name
			DebugPrint("Checking potential semaphore: '%s'", semName)

			local light1 = child:FindFirstChild("Light1")
			local light2 = child:FindFirstChild("Light2")
			local light3 = child:FindFirstChild("Light3")
			local light4 = child:FindFirstChild("Light4")

			DebugPrint("Light search results for '%s' - Light1: %s, Light2: %s, Light3: %s, Light4: %s",
				semName,
				light1 and light1.Name or "NOT FOUND",
				light2 and light2.Name or "NOT FOUND",
				light3 and light3.Name or "NOT FOUND",
				light4 and light4.Name or "NOT FOUND")

			if light1 and light2 and light3 and light4 then
				-- Verify all lights are BaseParts
				local allValid = true
				for i, light in ipairs({light1, light2, light3, light4}) do
					if not light:IsA("BasePart") then
						DebugWarn("Light%d ('%s') is not a BasePart (type: %s) in '%s'", i, light.Name, light.ClassName, semName)
						allValid = false
					end
				end

				if allValid then
					-- Safety: Ensure all lights are anchored to prevent movement
					local unanchoredLights = {}
					for i, light in ipairs({light1, light2, light3, light4}) do
						if not light.Anchored then
							light.Anchored = true
							table.insert(unanchoredLights, light.Name)
							DebugPrint("Anchored light '%s' (Light%d) to prevent movement in '%s'", light.Name, i, semName)
						end
					end

					if #unanchoredLights > 0 then
						warn(string.format("[Train Signal] ⚠ Some lights were unanchored in '%s' and have been anchored: %s", semName, table.concat(unanchoredLights, ", ")))
					end

					-- Register semaphore by its folder/model name
					semaphores[semName] = Semaphore.new(semName, light1, light2, light3, light4)

					-- Register first semaphore as default if none exists
					if not semaphores["default"] then
						semaphores["default"] = semaphores[semName]
						DebugPrint("Registered '%s' as default semaphore", semName)
					end

					-- If it's "Semaphore1", also register as lowercase for compatibility
					if semName == "Semaphore1" or semName == "semaphore1" then
						semaphores["semaphore1"] = semaphores[semName]
					end

					DebugPrint("Semaphore created successfully. Initializing to STOP state...")
					semaphores[semName]:SetStop()  -- Initialize to red (stop) by default
					print(string.format("[Train Signal] ✓ %s initialized successfully (default: STOP)", semName))
					DebugPrint("%s fully initialized and ready", semName)
					semaphoreCount = semaphoreCount + 1
				else
					warn(string.format("[Train Signal] ✗ '%s' found but one or more lights are not BaseParts", semName))
				end
			else
				DebugPrint("'%s' does not have all required lights (Light1-Light4)", semName)
			end
		end
	end

	if semaphoreCount == 0 then
		warn("[Train Signal] ✗ No valid semaphores found in Semaphores folder!")
		warn("[Train Signal] Expected structure: workspace.Semaphores.Semaphore1 (with Light1, Light2, Light3, Light4)")
	else
		DebugPrint("Successfully initialized %d semaphore(s)", semaphoreCount)
	end

	-- All semaphores are now automatically discovered from the Semaphores folder
	-- To add more semaphores, just add more models/folders to workspace.Semaphores
	-- Each should contain Light1, Light2, Light3, Light4 as BaseParts
end

-- Send message to player via chat or output
local function SendMessage(player, message, color)
	if not player or not player:IsA("Player") then
		print(message)
		return
	end

	-- Send to chat using RemoteEvent (since SetCore only works in LocalScript)
	local chatRemote = ReplicatedStorage:FindFirstChild("TrainSignalChatMessage")

	if not chatRemote then
		-- Create RemoteEvent for chat messages
		chatRemote = Instance.new("RemoteEvent")
		chatRemote.Name = "TrainSignalChatMessage"
		chatRemote.Parent = ReplicatedStorage
		DebugPrint("Created TrainSignalChatMessage RemoteEvent")
	end

	-- Fire to client (which will display in chat via LocalScript)
	chatRemote:FireClient(player, message, color or Color3.fromRGB(100, 200, 255))

	-- Also print for Output window
	print("[Train Signal → " .. player.Name .. "] " .. message)
end

-- Send multiple lines to chat (for help/list commands)
local function SendChatLines(player, lines, color)
	if not player or not player:IsA("Player") then
		for _, line in ipairs(lines) do
			print(line)
		end
		return
	end

	-- Send each line as a separate chat message
	for _, line in ipairs(lines) do
		if line and line ~= "" then
			SendMessage(player, line, color)
		end
	end
end

-- Show help message
local function ShowHelp(player)
	local helpLines = {
		"═══════════════════════════════════════",
		"[Train Signal Help]",
		"═══════════════════════════════════════",
		"Available commands:",
		"  !stop / !s          - Set signal to STOP (red)",
		"  !vmax / !go / !green - Set signal to VMAX (green)",
		"  !yellow / !y         - Set signal to YELLOW",
		"  !doubleyellow / !dy  - Set signal to DOUBLE YELLOW",
		"  !greenyellow / !gy   - Set signal to GREEN+YELLOW",
		"  !list / !ls          - List all semaphores",
		"  !help / !h           - Show this help",
		"",
		"Usage: !command [semaphore_name]",
		"Examples:",
		"  !vmax                  - Set default signal to VMAX",
		"  !vmax Semaphore1       - Set Semaphore1 to VMAX",
		"  !stop Semaphore1       - Set Semaphore1 to STOP",
		"  !yellow Semaphore1     - Set Semaphore1 to YELLOW"
	}

	-- List available semaphores (show unique ones only)
	local uniqueNames = {}
	local seen = {}
	for name, sem in pairs(semaphores) do
		-- Use sem.Name as the unique identifier to avoid duplicates
		if not seen[sem.Name] then
			seen[sem.Name] = true
			-- Prefer the exact name match as primary
			local displayName = name
			if name ~= sem.Name and semaphores[sem.Name] then
				displayName = sem.Name
			end
			table.insert(uniqueNames, displayName)
		end
	end
	table.sort(uniqueNames)
	if #uniqueNames > 0 then
		table.insert(helpLines, "Available semaphores: " .. table.concat(uniqueNames, ", "))
	end
	table.insert(helpLines, "═══════════════════════════════════════")

	-- Print to Output
	print("\n" .. table.concat(helpLines, "\n") .. "\n")

	-- Send to chat
	SendChatLines(player, helpLines, Color3.fromRGB(100, 200, 255))
end

-- List all semaphores
local function ListSemaphores(player)
	-- Get unique semaphores (by their actual Name, not registration keys)
	local uniqueSemaphores = {}
	local registrationKeys = {}

	for key, sem in pairs(semaphores) do
		-- Use sem.Name as the unique identifier
		if not uniqueSemaphores[sem.Name] then
			uniqueSemaphores[sem.Name] = {}
			registrationKeys[sem.Name] = {}
		end
		-- Store all registration keys for this semaphore
		table.insert(registrationKeys[sem.Name], key)
	end

	-- Build display list
	local semDisplayList = {}
	for semName, keys in pairs(registrationKeys) do
		-- Find the primary key (prefer exact name match, then alphabetical)
		local primaryKey = semName
		for _, key in ipairs(keys) do
			if key == semName then
				primaryKey = key
				break
			end
		end
		-- If multiple keys, show primary and indicate aliases
		if #keys > 1 then
			local aliasText = ""
			local aliases = {}
			for _, key in ipairs(keys) do
				if key ~= primaryKey then
					table.insert(aliases, key)
				end
			end
			if #aliases > 0 then
				aliasText = " (aliases: " .. table.concat(aliases, ", ") .. ")"
			end
			table.insert(semDisplayList, primaryKey .. aliasText)
		else
			table.insert(semDisplayList, primaryKey)
		end
	end

	-- Sort alphabetically
	table.sort(semDisplayList)

	if #semDisplayList == 0 then
		local msg = "[Train Signal] No semaphores found."
		SendMessage(player, msg)
		print(msg)
	else
		local listLines = {
			"═══════════════════════════════════════",
			"[Train Signal] Available Semaphores:",
			table.concat(semDisplayList, ", "),
			"═══════════════════════════════════════"
		}

		-- Print to Output
		local outputMsg = "[Train Signal] Available semaphores: " .. table.concat(semDisplayList, ", ")
		print(outputMsg)

		-- Send to chat
		SendChatLines(player, listLines, Color3.fromRGB(150, 255, 150))

		DebugPrint("List command executed - showing %d unique semaphore(s)", #semDisplayList)
	end
end

-- Parse command from message
local function ParseCommand(message, playerName)
	DebugPrint("Parsing command from player '%s': '%s'", playerName or "unknown", message)

	message = message:gsub("%s+", " "):match("^%s*(.-)%s*$")  -- Trim whitespace
	local originalMessage = message  -- Keep original for semaphore name matching
	local lowerMessage = string.lower(message)

	-- Check if message starts with ! or is a direct command
	local prefix = ""
	local cmdText = ""

	if lowerMessage:match("^!") then
		prefix = "!"
		cmdText = lowerMessage:sub(2)  -- Remove ! (lowercase)
		DebugPrint("Command has ! prefix")
	else
		-- Try without prefix (for flexibility)
		cmdText = lowerMessage
		DebugPrint("Command without ! prefix")
	end

	-- Split command and arguments (using ORIGINAL message to preserve case for semaphore name)
	local originalCmdText = originalMessage:match("^!") and originalMessage:sub(2) or originalMessage
	local originalParts = {}
	for part in originalCmdText:gmatch("%S+") do
		table.insert(originalParts, part)
	end

	-- Split lowercase for command matching
	local parts = {}
	for part in cmdText:gmatch("%S+") do
		table.insert(parts, part)
	end

	if #parts == 0 then
		DebugPrint("No command parts found")
		return nil, nil
	end

	local command = parts[1]  -- Command (lowercase)
	local semaphoreName = nil

	DebugPrint("Command parsed: '%s' with %d parts", command, #parts)

	-- Check if second part is a semaphore name (use ORIGINAL case)
	if #parts > 1 and #originalParts > 1 then
		local requestedName = originalParts[2]  -- Use original case!

		-- Try exact match first (case-sensitive)
		if semaphores[requestedName] then
			semaphoreName = requestedName
			DebugPrint("Semaphore name specified (exact match): '%s'", semaphoreName)
			-- Try case-insensitive match
		else
			-- Check all registered semaphore names (case-insensitive)
			for registeredName, _ in pairs(semaphores) do
				if string.lower(registeredName) == string.lower(requestedName) then
					semaphoreName = registeredName  -- Use the registered name (correct case)
					DebugPrint("Semaphore name found (case-insensitive): '%s' -> '%s'", requestedName, semaphoreName)
					break
				end
			end

			if not semaphoreName then
				DebugPrint("Second part '%s' is not a valid semaphore name", requestedName)
			end
		end
	end

	return command, semaphoreName
end

-- Process command from chat
local function ProcessCommand(command, semaphoreName, player)
	command = string.lower(command or "")
	local playerName = player and player.Name or "unknown"

	DebugPrint("Processing command '%s' for semaphore '%s' by player '%s'", 
		command, semaphoreName or "default", playerName)

	-- Resolve alias
	local resolvedCmd = aliasMap[command]
	if not resolvedCmd then
		DebugWarn("Unknown command '%s' from player '%s'", command, playerName)
		return false, "Unknown command: !" .. command .. ". Type !help for available commands."
	end

	DebugPrint("Command '%s' resolved to '%s'", command, resolvedCmd)

	local cmdData = commandMap[resolvedCmd]
	if not cmdData then
		DebugWarn("Command data not found for '%s'", resolvedCmd)
		return false, "Command data not found: " .. resolvedCmd
	end

	-- Handle special commands that don't need semaphore
	if resolvedCmd == "help" then
		DebugPrint("Showing help to player '%s'", playerName)
		ShowHelp(player)
		return true, "Help displayed"
	elseif resolvedCmd == "list" then
		DebugPrint("Listing semaphores for player '%s'", playerName)
		ListSemaphores(player)
		return true, "Semaphores listed"
	end

	-- Get semaphore (default to "Semaphore1" if not specified)
	local semName = semaphoreName or "Semaphore1"
	local sem = semaphores[semName]

	-- Try case-insensitive lookup if exact match failed
	if not sem and semaphoreName then
		-- Check all registered semaphore names (case-insensitive)
		for registeredName, registeredSem in pairs(semaphores) do
			if string.lower(registeredName) == string.lower(semaphoreName) then
				sem = registeredSem
				semName = registeredName  -- Use the registered name (correct case)
				DebugPrint("Found semaphore via case-insensitive match: '%s' -> '%s'", semaphoreName, semName)
				break
			end
		end
	end

	-- Try lowercase if still not found (for backward compatibility)
	if not sem and semaphoreName then
		sem = semaphores[string.lower(semaphoreName)]
		if sem then 
			semName = string.lower(semaphoreName)
			DebugPrint("Found semaphore via lowercase match: '%s'", semName)
		end
	end

	-- Final fallback: try default semaphore
	if not sem then
		if semaphoreName == "default" or not semaphoreName then
			sem = semaphores["default"]
			if sem then
				semName = sem.Name
				DebugPrint("Using default semaphore: '%s'", semName)
			else
				-- Last resort: try Semaphore1
				semName = "Semaphore1"
				sem = semaphores[semName]
				DebugPrint("Trying fallback to Semaphore1")
			end
		end
	end
	if not sem then
		local availableSems = {}
		for name, _ in pairs(semaphores) do
			table.insert(availableSems, name)
		end
		DebugWarn("Semaphore '%s' not found. Available semaphores: %s", 
			semName, table.concat(availableSems, ", "))
		return false, "Semaphore '" .. semName .. "' not found. Use !list to see available semaphores."
	end

	DebugPrint("Found semaphore '%s' (%s)", semName, sem.Name)

	-- Execute command
	local methodName = cmdData.method
	if sem[methodName] then
		DebugPrint("Executing method '%s' on semaphore '%s'", methodName, sem.Name)
		local success, err = pcall(function()
			sem[methodName](sem)
		end)

		if success then
			DebugPrint("Command executed successfully")
			return true, "Signal '" .. sem.Name .. "' set to " .. resolvedCmd:upper()
		else
			DebugWarn("Error executing command: %s", tostring(err))
			return false, "Error executing command: " .. tostring(err)
		end
	else
		DebugWarn("Method '%s' not found on semaphore '%s'", methodName, sem.Name)
		return false, "Method not found: " .. methodName
	end
end

-- Chat command handler
Players.PlayerAdded:Connect(function(player)
	DebugPrint("Player '%s' joined - setting up chat handler", player.Name)

	player.Chatted:Connect(function(message)
		DebugPrint("Player '%s' sent chat message: '%s'", player.Name, message)

		-- Parse command
		local command, semaphoreName = ParseCommand(message, player.Name)

		if command then
			DebugPrint("Valid command detected from '%s'", player.Name)
			-- If no semaphore specified, default to "Semaphore1"
			local targetSemaphore = semaphoreName or "Semaphore1"
			-- Process command
			local success, result = ProcessCommand(command, targetSemaphore, player)

			-- Send feedback to player
			if success then
				DebugPrint("Command successful for player '%s': %s", player.Name, result or "no message")
				-- Success feedback
				if result and result ~= "Help displayed" and result ~= "Semaphores listed" then
					SendMessage(player, "[Train Signal] " .. result, Color3.fromRGB(150, 255, 150))
				end
			else
				DebugWarn("Command failed for player '%s': %s", player.Name, result or "unknown error")
				-- Error feedback
				SendMessage(player, "[Train Signal] Error: " .. (result or "Unknown error"), Color3.fromRGB(255, 150, 150))
			end
		else
			DebugPrint("No valid command detected in message from '%s'", player.Name)
		end
	end)
end)

-- Handle players already in game
DebugPrint("Setting up chat handlers for players already in game (%d players)", #Players:GetPlayers())
for _, player in pairs(Players:GetPlayers()) do
	DebugPrint("Setting up chat handler for existing player '%s'", player.Name)
	player.Chatted:Connect(function(message)
		DebugPrint("Player '%s' sent chat message: '%s'", player.Name, message)

		local command, semaphoreName = ParseCommand(message, player.Name)
		if command then
			DebugPrint("Valid command detected from '%s'", player.Name)
			-- If no semaphore specified, default to "Semaphore1"
			local targetSemaphore = semaphoreName or "Semaphore1"
			local success, result = ProcessCommand(command, targetSemaphore, player)
			if success then
				DebugPrint("Command successful for player '%s': %s", player.Name, result or "no message")
				if result and result ~= "Help displayed" and result ~= "Semaphores listed" then
					SendMessage(player, "[Train Signal] " .. result, Color3.fromRGB(150, 255, 150))
				end
			else
				DebugWarn("Command failed for player '%s': %s", player.Name, result or "unknown error")
				SendMessage(player, "[Train Signal] Error: " .. (result or "Unknown error"), Color3.fromRGB(255, 150, 150))
			end
		end
	end)
end

-- Initialize function (called automatically or can be called manually)
local function InitializeSystem()
	DebugPrint("Waiting 1 second for workspace to fully load...")
	wait(1)  -- Wait for workspace to load
	DebugPrint("Starting semaphore initialization...")
	InitializeSemaphores()

	-- Summary
	local semaphoreCount = 0
	for _ in pairs(semaphores) do
		semaphoreCount = semaphoreCount + 1
	end

	print(string.rep("=", 60))
	print("[Train Signal System] Initialization Complete")
	print(string.rep("=", 60))
	print("  Semaphores loaded: " .. semaphoreCount)
	local cmdCount = 0
	for _ in pairs(commandMap) do cmdCount = cmdCount + 1 end
	print("  Commands available: " .. cmdCount)
	print("  Debug mode: " .. (DEBUG_MODE and "ON" or "OFF"))
	print(string.rep("=", 60))
	DebugPrint("System ready. Waiting for commands...")
end

-- Auto-initialize on server start (runs as Server Script)
InitializeSystem()

-- Export functions for programmatic use (accessible globally via _G or through RemoteHandler)
_G.TrainSignalSystem = {
	ProcessCommand = ProcessCommand,
	AddSemaphore = function(name, light1, light2, light3, light4)
		semaphores[name] = Semaphore.new(name, light1, light2, light3, light4)
		semaphores[name]:SetStop()  -- Initialize to red (stop) by default
		print("Semaphore added: " .. name .. " (default: stop)")
	end,
	GetSemaphore = function(name)
		return semaphores[name]
	end,
	GetAllSemaphores = function()
		-- Return copy of semaphores table for external access
		local result = {}
		for key, sem in pairs(semaphores) do
			result[key] = sem
		end
		return result
	end,
	GetSemaphoreList = function()
		-- Return unique semaphore names
		local uniqueNames = {}
		local seen = {}
		for name, sem in pairs(semaphores) do
			if not seen[sem.Name] then
				seen[sem.Name] = true
				-- Prefer exact name match as primary
				local displayName = name
				if name ~= sem.Name and semaphores[sem.Name] then
					displayName = sem.Name
				end
				table.insert(uniqueNames, displayName)
			end
		end
		table.sort(uniqueNames)
		return uniqueNames
	end
}

