-- Train Signal Remote Handler
-- Server Script - Handles RemoteEvent commands from the UI
-- Place this as a Server Script in ServerScriptService

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for TrainSignalSystem to initialize (it runs as Server Script and exports to _G)
wait(2) -- Give TrainSignalSystem time to initialize

local TrainSignalSystem = _G.TrainSignalSystem

if not TrainSignalSystem then
	warn("[Train Signal Remote] TrainSignalSystem not found in _G")
	warn("[Train Signal Remote] Make sure TrainSignalSystem.lua is running as Server Script")
	return
end

-- Create RemoteEvent for UI commands
local remoteEvent = Instance.new("RemoteEvent")
remoteEvent.Name = "TrainSignalCommand"
remoteEvent.Parent = ReplicatedStorage

-- Handle commands from UI
remoteEvent.OnServerEvent:Connect(function(player, command, semaphoreName)
	-- Validate command
	local validCommands = {
		"stop", "vmax", "yellow", "doubleyellow", "greenyellow"
	}

	local isValid = false
	for _, cmd in ipairs(validCommands) do
		if command == cmd then
			isValid = true
			break
		end
	end

	if not isValid then
		warn("[Train Signal] Invalid command from UI: " .. tostring(command))
		return
	end

	-- Process command (use default semaphore if not specified)
	-- First try to get default, otherwise fall back to first available
	local targetSemaphore = semaphoreName
	if not targetSemaphore then
		local defaultSem = TrainSignalSystem.GetSemaphore("default")
		if defaultSem then
			targetSemaphore = defaultSem.Name
		else
			local semList = TrainSignalSystem.GetSemaphoreList()
			targetSemaphore = semList[1] or "Semaphore1"
		end
	end
	local success, result = TrainSignalSystem.ProcessCommand(command, targetSemaphore, player)

	if success then
		print("[Train Signal] UI command executed by " .. player.Name .. ": " .. command .. " on " .. targetSemaphore)

		-- Send confirmation back to client with state info
		local stateMap = {
			stop = "STOP",
			vmax = "VMAX",
			yellow = "YELLOW",
			doubleyellow = "DOUBLE YELLOW",
			greenyellow = "GREEN+YELLOW"
		}
		local stateName = stateMap[command] or "STOP"

		-- Get actual state from semaphore
		local sem = TrainSignalSystem.GetSemaphore(targetSemaphore)
		if sem and sem.CurrentState then
			stateName = sem.CurrentState
		end

		remoteEvent:FireClient(player, "success", stateName)
	else
		warn("[Train Signal] UI command failed: " .. tostring(result))
		remoteEvent:FireClient(player, "error", result)
	end
end)

-- Create RemoteEvent for getting semaphore list
local listRemote = Instance.new("RemoteEvent")
listRemote.Name = "TrainSignalGetList"
listRemote.Parent = ReplicatedStorage

-- Handle list requests from UI
listRemote.OnServerEvent:Connect(function(player)
	local semList = TrainSignalSystem.GetSemaphoreList()
	listRemote:FireClient(player, semList)
end)

-- Create RemoteEvent for getting current status
local statusRemote = Instance.new("RemoteEvent")
statusRemote.Name = "TrainSignalGetStatus"
statusRemote.Parent = ReplicatedStorage

-- Handle status requests from UI
statusRemote.OnServerEvent:Connect(function(player, semaphoreName)
	-- Resolve semaphore name (default handling)
	local targetName = semaphoreName
	if not targetName then
		local defaultSem = TrainSignalSystem.GetSemaphore("default")
		if defaultSem then
			targetName = defaultSem.Name
		else
			local semList = TrainSignalSystem.GetSemaphoreList()
			targetName = semList[1] or "Semaphore1"
		end
	end

	local sem = TrainSignalSystem.GetSemaphore(targetName)
	if sem then
		-- Get current state from semaphore
		local state = sem.CurrentState or "STOP"
		statusRemote:FireClient(player, targetName, state)
	else
		statusRemote:FireClient(player, targetName, nil)
	end
end)

print("[Train Signal] Remote handler initialized - UI commands enabled")

