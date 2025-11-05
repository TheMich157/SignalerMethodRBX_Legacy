--!strict
-- ServerScriptService/TrainSignalRemoteHandler.lua

----------------------------------------------------------------
-- Services
----------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

----------------------------------------------------------------
-- Wait for TrainSignalSystem exported in _G
----------------------------------------------------------------
-- (daj systému chvíľu na init)
task.wait(1)
local TSS = (_G.TrainSignalSystem :: any)
if not TSS then
	warn("[TrainSignalRemoteHandler] _G.TrainSignalSystem not found; handler will still serve fallbacks.")
end

----------------------------------------------------------------
-- RemoteEvent helpers
----------------------------------------------------------------
local function getRemote(name: string): RemoteEvent
	local existing = ReplicatedStorage:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	local ev = Instance.new("RemoteEvent")
	ev.Name = name
	ev.Parent = ReplicatedStorage
	return ev
end

-- Single source of truth for event names
local RE_Command     = getRemote("TrainSignalCommand")     -- client->server: (command, semaphoreName?)
local RE_GetList     = getRemote("TrainSignalGetList")     -- client->server (request), server->client(list)
local RE_GetStatus   = getRemote("TrainSignalGetStatus")   -- client->server (name?), server->client(name, state)
local RE_StatusPush  = getRemote("TrainSignalStatus")      -- server->all: (name, state)  [broadcast]

----------------------------------------------------------------
-- Safe wrappers over TrainSignalSystem
----------------------------------------------------------------
-- Return list of semaphore names (always a flat {string})
local function safeGetList(): {string}
	-- 1) Prefer TSS.GetSemaphoreList()
	local ok1, res1 = pcall(function()
		if TSS and type(TSS.GetSemaphoreList) == "function" then
			return TSS.GetSemaphoreList()
		end
		return nil
	end)
	if ok1 and typeof(res1) == "table" then
		local out: {string} = {}
		for k, v in pairs(res1) do
			if typeof(v) == "string" then
				table.insert(out, v)
			elseif typeof(k) == "string" then
				table.insert(out, k) -- map -> keys
			elseif typeof(v) == "Instance" then
				table.insert(out, v.Name)
			elseif typeof(v) == "table" and typeof((v :: any).Name) == "string" then
				table.insert(out, (v :: any).Name)
			end
		end
		if #out > 0 then return out end
	end

	-- 2) Fallback TSS.GetAllSemaphores() -> keys / .Name
	local ok2, res2 = pcall(function()
		if TSS and type(TSS.GetAllSemaphores) == "function" then
			return TSS.GetAllSemaphores()
		end
		return nil
	end)
	if ok2 and typeof(res2) == "table" then
		local out2: {string} = {}
		for k, v in pairs(res2) do
			if typeof(k) == "string" then
				table.insert(out2, k)
			elseif typeof(v) == "table" and typeof((v :: any).Name) == "string" then
				table.insert(out2, (v :: any).Name)
			end
		end
		if #out2 > 0 then return out2 end
	end

	-- 3) Last fallback: workspace.Semaphores children names
	local out3: {string} = {}
	local folder = Workspace:FindFirstChild("Semaphores")
	if folder then
		for _, inst in ipairs(folder:GetChildren()) do
			table.insert(out3, inst.Name)
		end
	end
	return out3
end

-- Return current state of a semaphore (string), defaults to "STOP"
local function safeGetState(name: string): string
	local ok, state = pcall(function()
		if TSS and type(TSS.GetSemaphore) == "function" then
			local sem = TSS.GetSemaphore(name)
			if sem and sem.CurrentState then
				return sem.CurrentState
			end
		end
		return nil
	end)
	if ok and typeof(state) == "string" then
		return state :: string
	end
	return "STOP"
end

-- Resolve target semaphore name
local function resolveTargetName(optName: string?): string
	if optName and optName ~= "" then return optName end

	-- Try explicit "default"
	if TSS and type(TSS.GetSemaphore) == "function" then
		local ok, def = pcall(function() return TSS.GetSemaphore("default") end)
		if ok and def and typeof(def.Name) == "string" then
			return def.Name
		end
	end

	-- Take first from list
	local lst = safeGetList()
	return lst[1] or "Semaphore1"
end

----------------------------------------------------------------
-- Command whitelist & state mapping
----------------------------------------------------------------
local VALID: {[string]: boolean} = {
	stop=true, vmax=true, yellow=true, doubleyellow=true, greenyellow=true, subs=true
}
local STATE_NAME: {[string]: string} = {
	stop="STOP",
	vmax="VMAX",
	yellow="YELLOW",
	doubleyellow="DOUBLE YELLOW",
	greenyellow="GREEN+YELLOW",
	subs="SUBS",
}

----------------------------------------------------------------
-- Handlers
----------------------------------------------------------------
-- Client requests to change a signal
RE_Command.OnServerEvent:Connect(function(player: Player, command: string, semaphoreName: string?)
	if not VALID[command] then
		RE_Command:FireClient(player, "error", "Invalid command: "..tostring(command))
		return
	end

	local target = resolveTargetName(semaphoreName)

	-- Execute system command
	local okExec, errMsg = pcall(function()
		if not (TSS and type(TSS.ProcessCommand) == "function") then
			error("TrainSignalSystem.ProcessCommand missing")
		end
		return TSS.ProcessCommand(command, target, player)
	end)

	local success: boolean = false
	local resultMsg: any = nil

	if okExec then
		-- If ProcessCommand returns (ok, msg), capture it
		if typeof(errMsg) == "table" then
			-- unlikely path, ignore
			success = true
		elseif typeof(errMsg) == "boolean" then
			success = errMsg
		else
			-- Some implementations return nothing -> assume success
			success = true
		end
	else
		RE_Command:FireClient(player, "error", "Internal error: "..tostring(errMsg))
		return
	end

	if not success then
		RE_Command:FireClient(player, "error", tostring(resultMsg or "Failed"))
		return
	end

	-- Prefer actual state from system (robust to custom logic)
	local newState = safeGetState(target)
	if newState == "STOP" then
		-- fallback map (in case system didn't update yet)
		newState = STATE_NAME[command] or "STOP"
	end

	-- Confirm to the caller
	RE_Command:FireClient(player, "success", newState)

	-- Broadcast to everyone (keep all UIs in sync)
	RE_StatusPush:FireAllClients(target, newState)
end)

-- Client asks for list
RE_GetList.OnServerEvent:Connect(function(player: Player)
	local list = safeGetList()
	RE_GetList:FireClient(player, list)
end)

-- Client asks for one-shot status
RE_GetStatus.OnServerEvent:Connect(function(player: Player, name: string?)
	local target = resolveTargetName(name)
	local state = safeGetState(target)
	RE_GetStatus:FireClient(player, target, state)
end)

print("[TrainSignalRemoteHandler] ready (command/list/status + broadcast, safe wrappers, SUBS).")
