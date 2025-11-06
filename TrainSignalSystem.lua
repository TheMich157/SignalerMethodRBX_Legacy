--!strict
-- Train Signal System (no chat commands; UI/Remotes only)

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Colors
local GREEN  = Color3.fromRGB(0,255,0)
local YELLOW = Color3.fromRGB(255,255,0)
local RED    = Color3.fromRGB(255,0,0)
local BLACK  = Color3.fromRGB(0,0,0)
local WHITE  = Color3.fromRGB(255,255,255)

-- =================== Semaphore class ===================
local Semaphore = {} ; Semaphore.__index = Semaphore

function Semaphore.new(name: string, l1: BasePart?, l2: BasePart?, l3: BasePart?, l4: BasePart?, l5: BasePart?, ls1: BasePart?, ls2: BasePart?, ls3: BasePart?)
	local self = setmetatable({}, Semaphore)
	self.Name, self.Light1, self.Light2, self.Light3, self.Light4, self.Light5 = name, l1, l2, l3, l4, l5
	self.LightStrip1, self.LightStrip2, self.LightStrip3 = ls1, ls2, ls3
	self.CurrentState = "STOP"
	self._blinkTasks = {} :: { {light: BasePart, flag: {active: boolean}, onColor: Color3, offColor: Color3} }
	return self
end

local function SetLightColor(light: BasePart?, color: Color3, _semName: string?, _idx: number?)
	if not light or not light:IsA("BasePart") then return false end
	if not light.Anchored then light.Anchored = true end
	light.Color = color
	if color == BLACK then
		light.Material = Enum.Material.Plastic
		light.Transparency = 0.5
	else
		light.Material = Enum.Material.Neon
		light.Transparency = 0
	end
	return true
end

function Semaphore:_stopBlink(light: BasePart?)
	if not light then return end
	for i = #self._blinkTasks, 1, -1 do
		local e = self._blinkTasks[i]
		if e.light == light then
			e.flag.active = false
			table.remove(self._blinkTasks, i)
		end
	end
end

function Semaphore:_stopAllBlinks()
	for _, e in ipairs(self._blinkTasks) do e.flag.active = false end
	self._blinkTasks = {}
end

-- blink helper with chosen color
function Semaphore:_startBlinkColor(light: BasePart?, onColor: Color3, period: number?, offColor: Color3?)
	if not light then return end
	self:_stopBlink(light)
	local flag = {active = true}
	table.insert(self._blinkTasks, {light = light, flag = flag, onColor = onColor, offColor = offColor or BLACK})
	task.spawn(function()
		local p = period or 0.6
		local on = false
		while flag.active do
			on = not on
			if on then SetLightColor(light, onColor, self.Name) else SetLightColor(light, offColor or BLACK, self.Name) end
			task.wait(p)
		end
		SetLightColor(light, offColor or BLACK, self.Name)
	end)
end

-- strip helpers
function Semaphore:_stripsOnGreen()
	SetLightColor(self.LightStrip1, GREEN, self.Name)
	SetLightColor(self.LightStrip2, GREEN, self.Name)
	SetLightColor(self.LightStrip3, GREEN, self.Name)
end
function Semaphore:_stripsOff()
	SetLightColor(self.LightStrip1, BLACK, self.Name)
	SetLightColor(self.LightStrip2, BLACK, self.Name)
	SetLightColor(self.LightStrip3, BLACK, self.Name)
end

function Semaphore:TurnOffAllLights()
	self:_stopAllBlinks()
	SetLightColor(self.Light1, BLACK, self.Name, 1)
	SetLightColor(self.Light2, BLACK, self.Name, 2)
	SetLightColor(self.Light3, BLACK, self.Name, 3)
	SetLightColor(self.Light4, BLACK, self.Name, 4)
	SetLightColor(self.Light5, BLACK, self.Name, 5)
	self:_stripsOff()
end

-- ===== Basic states =====
function Semaphore:SetStop()
	self:TurnOffAllLights()
	SetLightColor(self.Light3, RED, self.Name, 3)
	self.CurrentState = "STOP"
end

function Semaphore:SetVmax()
	self:TurnOffAllLights()
	SetLightColor(self.Light1, GREEN, self.Name, 1)
	self.CurrentState = "VMAX"
end

function Semaphore:SetYellow()
	self:TurnOffAllLights()
	SetLightColor(self.Light2, YELLOW, self.Name, 2)
	self.CurrentState = "YELLOW"
end

function Semaphore:SetDoubleYellow()
	self:TurnOffAllLights()
	SetLightColor(self.Light2, YELLOW, self.Name, 2)
	SetLightColor(self.Light4, YELLOW, self.Name, 4)
	self:_stripsOnGreen() -- strips active
	self.CurrentState = "DOUBLE YELLOW"
end

function Semaphore:SetGreenYellow()
	self:TurnOffAllLights()
	SetLightColor(self.Light1, GREEN, self.Name, 1)
	SetLightColor(self.Light4, YELLOW, self.Name, 4)
	self:_stripsOnGreen() -- strips active
	self.CurrentState = "GREEN+YELLOW"
end

function Semaphore:SetSubstitute()
	self:TurnOffAllLights()
	SetLightColor(self.Light3, RED, self.Name, 3)
	self:_startBlinkColor(self.Light5, WHITE, 0.6)
	self.CurrentState = "SUBS"
end

-- ===== New states =====
-- S3: Light1 GREEN blinking
function Semaphore:SetS3()
	self:TurnOffAllLights()
	self:_startBlinkColor(self.Light1, GREEN, 0.6)
	self.CurrentState = "S3"
end

-- S4: Light2 YELLOW blinking
function Semaphore:SetS4()
	self:TurnOffAllLights()
	self:_startBlinkColor(self.Light2, YELLOW, 0.6)
	self.CurrentState = "S4"
end

-- S7: like GREEN+YELLOW but Light1 GREEN blinking; strips ON
function Semaphore:SetS7()
	self:TurnOffAllLights()
	self:_startBlinkColor(self.Light1, GREEN, 0.6)
	SetLightColor(self.Light4, YELLOW, self.Name, 4)
	self:_stripsOnGreen()
	self.CurrentState = "S7"
end

-- S8: Light2 YELLOW blinking + Light4 solid YELLOW; strips ON
function Semaphore:SetS8()
	self:TurnOffAllLights()
	self:_startBlinkColor(self.Light2, YELLOW, 0.6)
	SetLightColor(self.Light4, YELLOW, self.Name, 4)
	self:_stripsOnGreen()
	self.CurrentState = "S8"
end

-- =================== Registry / commands ===================
local semaphores: {[string]: any} = {}

local commandMap: {[string]: {method: string}} = {
	stop           = {method="SetStop"},
	vmax           = {method="SetVmax"},
	yellow         = {method="SetYellow"},
	doubleyellow   = {method="SetDoubleYellow"},
	greenyellow    = {method="SetGreenYellow"},
	subs           = {method="SetSubstitute"},
	-- new:
	s3             = {method="SetS3"},
	s4             = {method="SetS4"},
	s7             = {method="SetS7"},
	s8             = {method="SetS8"},
}

local aliasMap: {[string]: string} = {}
for cmd in pairs(commandMap) do aliasMap[cmd] = cmd end

local function InitializeSemaphores()
	local folder = workspace:FindFirstChild("Semaphores")
	if not folder then warn("[Train Signal] Semaphores folder missing"); return end

	for _, m in ipairs(folder:GetChildren()) do
		if m:IsA("Model") or m:IsA("Folder") then
			local l1 = m:FindFirstChild("Light1") :: BasePart?
			local l2 = m:FindFirstChild("Light2") :: BasePart?
			local l3 = m:FindFirstChild("Light3") :: BasePart?
			local l4 = m:FindFirstChild("Light4") :: BasePart?
			local l5 = m:FindFirstChild("Light5") :: BasePart?
			local ls1 = m:FindFirstChild("LightStrip1") :: BasePart?
			local ls2 = m:FindFirstChild("LightStrip2") :: BasePart?
			local ls3 = m:FindFirstChild("LightStrip3") :: BasePart?

			if l1 and l2 and l3 and l4 and l5 then
				-- ensure strips anchored if they exist
				for _, strip in ipairs({ls1, ls2, ls3}) do
					if strip and not strip.Anchored then strip.Anchored = true end
				end
				semaphores[m.Name] = Semaphore.new(m.Name, l1, l2, l3, l4, l5, ls1, ls2, ls3)
				if not semaphores["default"] then semaphores["default"] = semaphores[m.Name] end
				semaphores[m.Name]:SetStop()
				print("[Train Signal] ✓ " .. m.Name .. " initialized")
			end
		end
	end
end

local function ProcessCommand(command: string, semName: string?, _player: Player?)
	command = string.lower(command or "")
	local real = aliasMap[command]
	if not real then return false, "Unknown command: "..tostring(command) end

	local sem = semaphores[semName or "Semaphore1"] or semaphores["default"]
	if not sem then return false, "No semaphore available" end

	local methodName = commandMap[real].method
	local method = sem[methodName]
	if not method then return false, "Method missing: "..methodName end

	local ok, err = pcall(method, sem)
	if not ok then return false, tostring(err) end
	return true, real
end

local function InitializeSystem()
	InitializeSemaphores()
end
InitializeSystem()

_G.TrainSignalSystem = {
	ProcessCommand = ProcessCommand,
	GetSemaphore = function(name: string) return semaphores[name] end,
	GetAllSemaphores = function() local r = {}; for k,v in pairs(semaphores) do r[k]=v end; return r end,
	GetSemaphoreList = function()
		local seen: {[string]: boolean} = {}
		local list: {string} = {}
		for _, sem in pairs(semaphores) do
			if sem and not seen[sem.Name] then
				seen[sem.Name] = true
				table.insert(list, sem.Name)
			end
		end
		table.sort(list)
		return list
	end,
}
