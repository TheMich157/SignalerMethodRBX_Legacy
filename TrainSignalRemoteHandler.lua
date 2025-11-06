--!strict
-- ServerScriptService/TrainSignalRemoteHandler.lua
-- Adds emergency lock/cooldown + anti-abuse + normal command handling + broadcasts

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

task.wait(1)
local TSS = (_G.TrainSignalSystem :: any)

-- Remote creator
local function getRemote(name: string)
	local existing = ReplicatedStorage:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	local ev = Instance.new("RemoteEvent")
	ev.Name = name
	ev.Parent = ReplicatedStorage
	return ev
end

local RE_Command    = getRemote("TrainSignalCommand")
local RE_GetList    = getRemote("TrainSignalGetList")
local RE_GetStatus  = getRemote("TrainSignalGetStatus")
local RE_StatusPush = getRemote("TrainSignalStatus")
local RE_Emergency  = getRemote("TrainSignalEmergency") -- NEW: server->clients emergency events

-- Valid commands
local VALID = {
	stop=true, vmax=true, yellow=true, doubleyellow=true, greenyellow=true, subs=true,
	s3=true, s4=true, s7=true, s8=true,
	-- emergency handled specially (we accept it here)
	emergency=true,
}

local STATE_NAME = {
	stop="STOP", vmax="VMAX", yellow="YELLOW", doubleyellow="DOUBLE YELLOW",
	greenyellow="GREEN+YELLOW", subs="SUBS",
	s3="S3", s4="S4", s7="S7", s8="S8",
	emergency="EMERGENCY",
}

-- Emergency config
local lockDuration = 120        -- seconds (2 mins)
local cooldownDuration = 300    -- seconds (5 mins)
local abuseWindow = 600         -- seconds window to count abuses (10 mins)
local abuseKickThreshold = 3    -- kicks after this many emergency triggers within abuseWindow

-- state
local isLockedUntil = 0         -- os.time() until which normal commands are blocked
local cooldownUntil = 0         -- os.time() until which emergency cannot be triggered
local perPlayerUses = {}        -- player.UserId -> {timestamps = {t1,t2,...}}

-- helpers
local function now() return os.time() end

local function safeGetList()
	local out = {}
	local ok,res = pcall(function()
		if TSS and type(TSS.GetSemaphoreList) == "function" then return TSS.GetSemaphoreList() end
		return nil
	end)
	if ok and typeof(res) == "table" then
		for _,v in ipairs(res) do table.insert(out, tostring(v)) end
		if #out>0 then return out end
	end
	-- fallback to TSS.GetAllSemaphores
	local ok2,res2 = pcall(function()
		if TSS and type(TSS.GetAllSemaphores) == "function" then return TSS.GetAllSemaphores() end
		return nil
	end)
	if ok2 and typeof(res2) == "table" then
		for k,v in pairs(res2) do table.insert(out, tostring(k)) end
		if #out>0 then return out end
	end
	-- workspace fallback
	local folder = Workspace:FindFirstChild("Semaphores")
	if folder then
		for _,c in ipairs(folder:GetChildren()) do table.insert(out, c.Name) end
	end
	return out
end

local function safeGetState(name: string)
	local state = "STOP"
	local ok,res = pcall(function()
		if TSS and type(TSS.GetSemaphore) == "function" then
			local sem = TSS.GetSemaphore(name)
			if sem and sem.CurrentState then return sem.CurrentState end
		end
		return nil
	end)
	if ok and typeof(res) == "string" then state = res end
	return state
end

local function setAllToStopAndLock(lockedBy: Player)
	-- set every semaphore to STOP (call sem:SetStop if available)
	if TSS and type(TSS.GetAllSemaphores) == "function" then
		local ok, all = pcall(function() return TSS.GetAllSemaphores() end)
		if ok and typeof(all) == "table" then
			for k,v in pairs(all) do
				if v and type(v.SetStop) == "function" then
					pcall(function() v:SetStop() end)
				elseif v and type(v.CurrentState) ~= "nil" then
					-- best-effort: try to set fields
					pcall(function() v.CurrentState = "STOP" end)
				end
				-- broadcast each sem state
				RE_StatusPush:FireAllClients(k, "STOP")
			end
		end
	end
	-- also broadcast an emergency start event with duration
	RE_Emergency:FireAllClients("start", lockDuration, lockedBy and lockedBy.Name or "Server", now()+lockDuration)
end

local function endEmergency()
	-- broadcast end
	RE_Emergency:FireAllClients("end", 0, nil, now())
	-- set cooldown
	cooldownUntil = now() + cooldownDuration
	-- broadcast cooldown start
	RE_Emergency:FireAllClients("cooldown", cooldownDuration, nil, cooldownUntil)
end

-- record per-player use and detect abuse
local function recordEmergencyUse(player: Player)
	if not player then return false, "No player" end
	local uid = player.UserId
	perPlayerUses[uid] = perPlayerUses[uid] or {}
	table.insert(perPlayerUses[uid], now())
	-- prune old
	local t = perPlayerUses[uid]
	local cutoff = now() - abuseWindow
	local i = 1
	while i <= #t do
		if t[i] < cutoff then table.remove(t, i) else i = i + 1 end
	end
	-- check threshold
	if #t >= abuseKickThreshold then
		-- kick player
		pcall(function() player:Kick("Abuse: repeated Emergency usage") end)
		perPlayerUses[uid] = {} -- reset
		return true, "kicked"
	end
	return false, tostring(#t)
end

-- ===== Command handler =====
RE_Command.OnServerEvent:Connect(function(player: Player, command: string, semaphoreName: string?)
	command = tostring(command or ""):lower()
	if not VALID[command] then
		RE_Command:FireClient(player, "error", "Invalid command: "..tostring(command))
		return
	end

-- Emergency special-case
if command == "emergency" then
    -- už beží emergency? zakáž
    if now() < isLockedUntil then
        RE_Command:FireClient(player, "error", "Emergency already active.")
        return
    end
    -- cooldown?
    if now() < cooldownUntil then
        RE_Command:FireClient(player, "error", "Emergency on cooldown. Wait " .. tostring(cooldownUntil - now()) .. "s.")
        return
    end

    -- (ďalej nechaj ako máš)
    local kicked, cnt = recordEmergencyUse(player)
    if kicked then return end

    isLockedUntil = now() + lockDuration
    setAllToStopAndLock(player)

    RE_Command:FireClient(player, "success", "Emergency started for " .. tostring(lockDuration) .. "s")
    task.delay(lockDuration, function()
        endEmergency()     -- nastaví cooldown a notifikuje klientov
        isLockedUntil = 0
    end)
    return
end
	-- If we're currently locked, deny normal commands
	if now() < isLockedUntil then
		RE_Command:FireClient(player, "error", "System locked (Emergency).")
		return
	end

	-- normal commands => proxy to TSS.ProcessCommand when possible, else mirror older behavior
	if TSS and type(TSS.ProcessCommand) == "function" then
		local ok, res = pcall(function()
			return TSS.ProcessCommand(command, semaphoreName, player)
		end)
		if not ok then
			RE_Command:FireClient(player, "error", "ProcessCommand error: "..tostring(res))
			return
		end
		-- Try to determine state and broadcast
		local state = STATE_NAME[command] or safeGetState(semaphoreName or "")
		RE_StatusPush:FireAllClients(semaphoreName or "unknown", state)
		RE_Command:FireClient(player, "success", state)
		return
	end

	-- fallback: use TSS GetSemaphore + method name mapping
	if TSS and type(TSS.GetSemaphore) == "function" then
		local sem = nil
		local ok, s = pcall(function() return TSS.GetSemaphore(semaphoreName) end)
		if ok then sem = s end
		if not sem then
			RE_Command:FireClient(player, "error", "Semaphore not found")
			return
		end
		local methodName = nil
		-- map command -> method name consistent with old mapping
		local methodMap = {
			stop="SetStop", vmax="SetVmax", yellow="SetYellow",
			doubleyellow="SetDoubleYellow", greenyellow="SetGreenYellow",
			subs="SetSubstitute",
			s3="SetS3", s4="SetS4", s7="SetS7", s8="SetS8",
		}
		methodName = methodMap[command]
		if not methodName or type(sem[methodName]) ~= "function" then
			RE_Command:FireClient(player, "error", "Command not available: "..tostring(command))
			return
		end
		local ok2, r2 = pcall(function() return sem[methodName](sem) end)
		if not ok2 then
			RE_Command:FireClient(player, "error", "Execution error: "..tostring(r2))
			return
		end
		RE_StatusPush:FireAllClients(semaphoreName or sem.Name, STATE_NAME[command] or "UNKNOWN")
		RE_Command:FireClient(player, "success", STATE_NAME[command] or "OK")
		return
	end

	RE_Command:FireClient(player, "error", "No backend available")
end)

-- ===== List handler =====
RE_GetList.OnServerEvent:Connect(function(player)
	local list = safeGetList()
	RE_GetList:FireClient(player, list)
end)

-- ===== Status handler =====
RE_GetStatus.OnServerEvent:Connect(function(player, name: string?)
	local target = name
	if not target or target == "" then
		local lst = safeGetList()
		target = lst[1] or "Semaphore1"
	end
	local state = safeGetState(target)
	RE_GetStatus:FireClient(player, target, state)
end)

print("[TrainSignalRemoteHandler] ready (with Emergency lock/cooldown/anti-abuse).")
