--!strict
-- Optimized TrainSignalDispatchPanel.lua (Client)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LOCAL = Players.LocalPlayer :: Player
local playerGui = LOCAL:WaitForChild("PlayerGui")

-- Remotes
local RE_Command    = ReplicatedStorage:WaitForChild("TrainSignalCommand") :: RemoteEvent
local RE_GetList    = ReplicatedStorage:WaitForChild("TrainSignalGetList") :: RemoteEvent
local RE_GetStatus  = ReplicatedStorage:WaitForChild("TrainSignalGetStatus") :: RemoteEvent
local RE_StatusPush = ReplicatedStorage:WaitForChild("TrainSignalStatus") :: RemoteEvent
local RE_Emergency  = ReplicatedStorage:WaitForChild("TrainSignalEmergency") :: RemoteEvent

----------------------------------------------------------------
-- Screen + Root
----------------------------------------------------------------
local SCREEN = Instance.new("ScreenGui")
SCREEN.Name = "TrainSignalDispatchPanel"
SCREEN.ResetOnSpawn = false
SCREEN.IgnoreGuiInset = true
SCREEN.ZIndexBehavior = Enum.ZIndexBehavior.Global
SCREEN.Parent = playerGui

local ROOT = Instance.new("Frame")
ROOT.Name = "Panel"
ROOT.Size = UDim2.fromOffset(480, 360)
ROOT.Position = UDim2.new(0, 24, 0.5, -180)
ROOT.BackgroundColor3 = Color3.fromRGB(28,32,40)
ROOT.BorderSizePixel = 0
ROOT.ZIndex = 100
ROOT.Parent = SCREEN
Instance.new("UICorner", ROOT).CornerRadius = UDim.new(0, 10)

-- emergency overlay
local OVERLAY = Instance.new("Frame")
OVERLAY.BackgroundColor3 = Color3.fromRGB(0,0,0)
OVERLAY.BackgroundTransparency = 0.4
OVERLAY.Size = UDim2.new(1,0,1,0)
OVERLAY.Visible = false
OVERLAY.ZIndex = 1000
OVERLAY.Parent = ROOT

local BIG = Instance.new("TextLabel")
BIG.BackgroundTransparency = 1
BIG.Size = UDim2.new(1,0,1,0)
BIG.Font = Enum.Font.GothamBlack
BIG.TextSize = 34
BIG.TextColor3 = Color3.fromRGB(255,80,80)
BIG.Text = ""
BIG.ZIndex = 1001
BIG.Parent = OVERLAY
----------------------------------------------------------------
local TITLE = Instance.new("TextLabel")
TITLE.BackgroundTransparency = 1
TITLE.Font = Enum.Font.GothamBold
TITLE.TextSize = 18
TITLE.TextXAlignment = Enum.TextXAlignment.Left
TITLE.TextColor3 = Color3.fromRGB(240,245,255)
TITLE.Text = "Dispatch Panel"
TITLE.Size = UDim2.new(1, -16, 0, 28)
TITLE.Position = UDim2.new(0, 12, 0, 10)
TITLE.ZIndex = 101
TITLE.Parent = ROOT

local LINE = Instance.new("Frame")
LINE.BackgroundColor3 = Color3.fromRGB(50,58,70)
LINE.BorderSizePixel = 0
LINE.Size = UDim2.new(1, -24, 0, 1)
LINE.Position = UDim2.new(0, 12, 0, 40)
LINE.ZIndex = 100
LINE.Parent = ROOT

----------------------------------------------------------------
-- Selector + Status
----------------------------------------------------------------
local SELECTOR = Instance.new("TextButton")
SELECTOR.Name = "Selector"
SELECTOR.AutoButtonColor = false
SELECTOR.BackgroundColor3 = Color3.fromRGB(38,44,54)
SELECTOR.TextColor3 = Color3.fromRGB(230,235,245)
SELECTOR.Font = Enum.Font.Gotham
SELECTOR.TextSize = 14
SELECTOR.TextXAlignment = Enum.TextXAlignment.Left
SELECTOR.Text = "Loading signals..."
SELECTOR.Size = UDim2.new(0, 240, 0, 28)
SELECTOR.Position = UDim2.new(0, 12, 0, 54)
SELECTOR.ZIndex = 100
SELECTOR.Parent = ROOT
Instance.new("UICorner", SELECTOR).CornerRadius = UDim.new(0, 6)

local STATUS = Instance.new("TextLabel")
STATUS.BackgroundTransparency = 1
STATUS.Font = Enum.Font.GothamBold
STATUS.TextSize = 14
STATUS.TextXAlignment = Enum.TextXAlignment.Right
STATUS.Text = "—"
STATUS.TextColor3 = Color3.fromRGB(255,255,255)
STATUS.Size = UDim2.new(1, -264, 0, 28)
STATUS.Position = UDim2.new(0, 256, 0, 54)
STATUS.ZIndex = 100
STATUS.Parent = ROOT

----------------------------------------------------------------
-- Dropdown (overlay at top-level so it never hides)
----------------------------------------------------------------
local DROPDOWN = Instance.new("Frame")
DROPDOWN.Visible = false
DROPDOWN.BackgroundColor3 = Color3.fromRGB(38,44,54)
DROPDOWN.BorderSizePixel = 0
DROPDOWN.Size = UDim2.fromOffset(240, 180)
DROPDOWN.ZIndex = 500
DROPDOWN.Parent = SCREEN
Instance.new("UICorner", DROPDOWN).CornerRadius = UDim.new(0, 6)

local DDScroll = Instance.new("ScrollingFrame")
DDScroll.BackgroundTransparency = 1
DDScroll.BorderSizePixel = 0
DDScroll.Size = UDim2.new(1, -8, 1, -8)
DDScroll.Position = UDim2.new(0, 4, 0, 4)
DDScroll.ScrollBarThickness = 4
DDScroll.ZIndex = 501
DDScroll.Parent = DROPDOWN

local DDLayout = Instance.new("UIListLayout")
DDLayout.SortOrder = Enum.SortOrder.LayoutOrder
DDLayout.Padding = UDim.new(0, 6)
DDLayout.Parent = DDScroll

DDLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	DDScroll.CanvasSize = UDim2.new(0,0,0, DDLayout.AbsoluteContentSize.Y + 6)
end)

local function positionDropdown()
	local absPos = SELECTOR.AbsolutePosition
	local absSize = SELECTOR.AbsoluteSize
	local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920,1080)
	local ddSize = Vector2.new(DROPDOWN.Size.X.Offset, DROPDOWN.Size.Y.Offset)

	local x = absPos.X
	local y = absPos.Y + absSize.Y + 4
	if x + ddSize.X > viewport.X - 6 then x = viewport.X - ddSize.X - 6 end
	if y + ddSize.Y > viewport.Y - 6 then y = absPos.Y - ddSize.Y - 4 end
	DROPDOWN.Position = UDim2.fromOffset(x, y)
end

----------------------------------------------------------------
-- Buttons grid
----------------------------------------------------------------
local BUTTONS = Instance.new("Frame")
BUTTONS.BackgroundTransparency = 1
BUTTONS.Position = UDim2.new(0, 12, 0, 126)
BUTTONS.ZIndex = 100
BUTTONS.Parent = ROOT

local Grid = Instance.new("UIGridLayout", BUTTONS)
Grid.CellSize = UDim2.fromOffset(148, 34)
Grid.CellPadding = UDim2.fromOffset(10, 10)
Grid.FillDirectionMaxCells = 3

local function makeButton(text: string, color: Color3): TextButton
	local b = Instance.new("TextButton")
	b.AutoButtonColor = false
	b.BackgroundColor3 = color
	b.TextColor3 = Color3.fromRGB(18,18,22)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 14
	b.Text = text
	b.ZIndex = 101
	b.Parent = BUTTONS
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	return b
end

-- core states
local BTN_STOP         = makeButton("STOP", Color3.fromRGB(255,70,70))
local BTN_VMAX         = makeButton("VMAX", Color3.fromRGB(90,255,110))
local BTN_YELLOW       = makeButton("YELLOW", Color3.fromRGB(255,210,70))
local BTN_DOUBLEYELLOW = makeButton("DOUBLE YELLOW", Color3.fromRGB(255,230,120))
local BTN_GREENYELLOW  = makeButton("GREEN+YELLOW", Color3.fromRGB(120,255,170))
local BTN_SUBS         = makeButton("SUBS", Color3.fromRGB(230,230,230))
-- new states
local BTN_S3           = makeButton("S3 (G blink)",      Color3.fromRGB(90,255,110))
local BTN_S4           = makeButton("S4 (Y blink)",      Color3.fromRGB(255,210,70))
local BTN_S7           = makeButton("S7 (G blink + Y4)", Color3.fromRGB(120,255,170))
local BTN_S8           = makeButton("S8 (Y blink + Y4)", Color3.fromRGB(255,230,120))

-- Emergency bar (pevne pod gridom)
local EMER_WRAP = Instance.new("Frame")
EMER_WRAP.Name = "EmergencyBar"
EMER_WRAP.BackgroundTransparency = 1
EMER_WRAP.Size = UDim2.new(1, -24, 0, 34)
EMER_WRAP.ZIndex = 100
EMER_WRAP.Parent = ROOT

local BTN_EMERGENCY = Instance.new("TextButton")
BTN_EMERGENCY.Name = "BtnEmergency"
BTN_EMERGENCY.AutoButtonColor = false
BTN_EMERGENCY.BackgroundColor3 = Color3.fromRGB(200,40,40)
BTN_EMERGENCY.TextColor3 = Color3.fromRGB(255,255,255)
BTN_EMERGENCY.Font = Enum.Font.GothamBlack
BTN_EMERGENCY.TextSize = 16
BTN_EMERGENCY.Text = "EMERGENCY ONLY"
BTN_EMERGENCY.Size = UDim2.new(1, 0, 1, 0)
BTN_EMERGENCY.ZIndex = 101
BTN_EMERGENCY.Parent = EMER_WRAP
Instance.new("UICorner", BTN_EMERGENCY).CornerRadius = UDim.new(0, 8)

-- Confirm bar (Are you sure? / Cancel) – pod emergency
local CONFIRM_BAR = Instance.new("Frame")
CONFIRM_BAR.Name = "ConfirmBar"
CONFIRM_BAR.BackgroundTransparency = 1
CONFIRM_BAR.Size = UDim2.new(1, -24, 0, 34)
CONFIRM_BAR.ZIndex = 100
CONFIRM_BAR.Visible = false
CONFIRM_BAR.Parent = ROOT

local ARE_SURE = Instance.new("TextButton")
ARE_SURE.Name = "AreSure"
ARE_SURE.AutoButtonColor = true
ARE_SURE.BackgroundColor3 = Color3.fromRGB(200,40,40)
ARE_SURE.TextColor3 = Color3.fromRGB(255,255,255)
ARE_SURE.Font = Enum.Font.GothamBold
ARE_SURE.TextSize = 14
ARE_SURE.Text = "Are you sure?"
ARE_SURE.Size = UDim2.new(0.5, -6, 1, 0)
ARE_SURE.Position = UDim2.new(0, 0, 0, 0)
ARE_SURE.ZIndex = 101
ARE_SURE.Parent = CONFIRM_BAR
Instance.new("UICorner", ARE_SURE).CornerRadius = UDim.new(0, 6)

local CANCEL_BTN = Instance.new("TextButton")
CANCEL_BTN.Name = "Cancel"
CANCEL_BTN.AutoButtonColor = true
CANCEL_BTN.BackgroundColor3 = Color3.fromRGB(60,60,60)
CANCEL_BTN.TextColor3 = Color3.fromRGB(255,255,255)
CANCEL_BTN.Font = Enum.Font.Gotham
CANCEL_BTN.TextSize = 14
CANCEL_BTN.Text = "Cancel"
CANCEL_BTN.Size = UDim2.new(0.5, -6, 1, 0)
CANCEL_BTN.Position = UDim2.new(0.5, 6, 0, 0)
CANCEL_BTN.ZIndex = 101
CANCEL_BTN.Parent = CONFIRM_BAR
Instance.new("UICorner", CANCEL_BTN).CornerRadius = UDim.new(0, 6)

----------------------------------------------------------------
-- State
----------------------------------------------------------------
local currentSemaphore: string = ""
local availableSemaphores: {string} = {}
local dropdownOpen = false
local controlsEnabled = true

local emergencyUntil = 0      -- os.time() when emergency ends
local cooldownUntil = 0       -- os.time() when cooldown ends

local COLOR_STATE: {[string]: Color3} = {
	STOP = Color3.fromRGB(255, 50, 50),
	VMAX = Color3.fromRGB(50, 255, 50),
	YELLOW = Color3.fromRGB(255, 200, 50),
	["DOUBLE YELLOW"] = Color3.fromRGB(255, 220, 100),
	["GREEN+YELLOW"] = Color3.fromRGB(100, 255, 150),
	SUBS = Color3.fromRGB(220, 220, 220),
	S3 = Color3.fromRGB(50,255,50),
	S4 = Color3.fromRGB(255,200,50),
	S7 = Color3.fromRGB(100,255,150),
	S8 = Color3.fromRGB(255,220,100),
}


-- ===== AUTO LAYOUT (teraz až po tom, čo existuje Grid/EMER_WRAP/CONFIRM_BAR) =====

-- pevná výška panela (ak ju používaš)
local PANEL_MAX_HEIGHT = 380  -- uprav podľa seba

-- prepočet layoutu (NEvolá refreshEmergencyButton)
local function relayout()
    local h = Grid and Grid.AbsoluteContentSize.Y or 0
    BUTTONS.Size = UDim2.new(1, -24, 0, h)

    -- emergency pod grid
    local emerY = BUTTONS.Position.Y.Offset + h + 12
    EMER_WRAP.Position = UDim2.new(0, 12, 0, emerY)

    -- confirm bar vždy pod emergency (bez posúvania panelu)
    local confirmY = emerY + EMER_WRAP.Size.Y.Offset + 6
    CONFIRM_BAR.Position = UDim2.new(0, 12, 0, confirmY)

    -- fixná výška panela (nechceš autoexpanziu)
    ROOT.Size = UDim2.fromOffset(ROOT.Size.X.Offset, PANEL_MAX_HEIGHT)
end

-- SKRY/SHOW emergency tlačidla (volá len relayout, NIE naopak)
local function refreshEmergencyButton()
	local t = os.time()
	local hide = (t < emergencyUntil) or (t < cooldownUntil)
	BTN_EMERGENCY.Visible = not hide
	if hide and CONFIRM_BAR.Visible then
		CONFIRM_BAR.Visible = false
	end
	relayout()
end


-- prepočet pri zmene obsahu gridu
Grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(relayout)

-- pravidelný refresh tlačidla a layoutu (napr. každých 0.2 s)
task.spawn(function()
    while true do
        refreshEmergencyButton()
        task.wait(0.2)
    end
end)


----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------
local function setControlsEnabled(enabled: boolean)
	if controlsEnabled == enabled then return end
	controlsEnabled = enabled
	for _,c in ipairs(BUTTONS:GetChildren()) do
		if c:IsA("TextButton") then
			c.Active = enabled
			c.AutoButtonColor = enabled
			c.TextTransparency = enabled and 0 or 0.35
			c.BackgroundTransparency = enabled and 0 or 0.2
		end
	end
	SELECTOR.Active = enabled
end

local function bump(btn: TextButton?)
	if not btn then return end
	TweenService:Create(btn, TweenInfo.new(0.10), {Size = UDim2.new(btn.Size.X.Scale, btn.Size.X.Offset+8, btn.Size.Y.Scale, btn.Size.Y.Offset+4)}):Play()
	task.delay(0.12, function()
		if btn then TweenService:Create(btn, TweenInfo.new(0.10), {Size = UDim2.new(btn.Size.X.Scale, btn.Size.X.Offset-8, btn.Size.Y.Scale, btn.Size.Y.Offset-4)}):Play() end
	end)
end

local function UpdateStatusText(state: string)
	STATUS.Text = state
	STATUS.TextColor3 = COLOR_STATE[state] or Color3.fromRGB(255,255,255)
end

local function rebuildDropdown()
	for _,c in ipairs(DDScroll:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	for _, name in ipairs(availableSemaphores) do
		local item = Instance.new("TextButton")
		item.AutoButtonColor = true
		item.BackgroundColor3 = Color3.fromRGB(48,54,66)
		item.TextColor3 = Color3.fromRGB(240,244,255)
		item.Font = Enum.Font.Gotham
		item.TextSize = 14
		item.TextXAlignment = Enum.TextXAlignment.Left
		item.Text = name
		item.ZIndex = 502
		item.Size = UDim2.new(1, -6, 0, 26)
		item.Parent = DDScroll
		Instance.new("UICorner", item).CornerRadius = UDim.new(0, 4)
		item.MouseButton1Click:Connect(function()
			currentSemaphore = name
			SELECTOR.Text = name
			if RE_GetStatus then RE_GetStatus:FireServer(name) end
			DROPDOWN.Visible = false
			dropdownOpen = false
		end)
	end
end

local function toggleDropdown()
	dropdownOpen = not dropdownOpen
	if dropdownOpen then
		rebuildDropdown()
		positionDropdown()
	end
	DROPDOWN.Visible = dropdownOpen
end

----------------------------------------------------------------
-- Drag (no jitter, Vector3→Vector2 safe)
----------------------------------------------------------------
do
	local dragging = false
	local activeInput: InputObject? = nil
	local startPos = ROOT.Position
	local dragStart = Vector2.new()

	local function vec2(input: InputObject): Vector2
		local p = input.Position
		if typeof(p) == "Vector3" then return Vector2.new(p.X, p.Y) end
		return p :: Vector2
	end

	local function update(input: InputObject)
		local d = vec2(input) - dragStart
		ROOT.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		if dropdownOpen then positionDropdown() end
	end

	local function begin(input: InputObject)
		dragging = true
		activeInput = input
		dragStart = vec2(input)
		startPos = ROOT.Position
	end

	local function finish(input: InputObject)
		if input == activeInput then
			dragging = false
			activeInput = nil
		end
	end

	local function hook(gui: GuiObject)
		gui.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				begin(input)
			end
		end)
		gui.InputEnded:Connect(function(input) finish(input) end)
	end

	hook(ROOT)
	hook(TITLE)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input == activeInput then
			update(input)
		end
	end)
end

----------------------------------------------------------------
-- Buttons → Commands (debounced by setControlsEnabled)
----------------------------------------------------------------
local function send(cmd: string, btn: TextButton?, label: string)
	if not controlsEnabled then return end
	bump(btn)
	UpdateStatusText(label)
	RE_Command:FireServer(cmd, currentSemaphore)
end

BTN_STOP.MouseButton1Click:Connect(function()         send("stop",         BTN_STOP, "STOP") end)
BTN_VMAX.MouseButton1Click:Connect(function()         send("vmax",         BTN_VMAX, "VMAX") end)
BTN_YELLOW.MouseButton1Click:Connect(function()       send("yellow",       BTN_YELLOW, "YELLOW") end)
BTN_DOUBLEYELLOW.MouseButton1Click:Connect(function() send("doubleyellow", BTN_DOUBLEYELLOW, "DOUBLE YELLOW") end)
BTN_GREENYELLOW.MouseButton1Click:Connect(function()  send("greenyellow",  BTN_GREENYELLOW, "GREEN+YELLOW") end)
BTN_SUBS.MouseButton1Click:Connect(function()         send("subs",         BTN_SUBS, "SUBS") end)
BTN_S3.MouseButton1Click:Connect(function() send("s3", BTN_S3, "S3") end)
BTN_S4.MouseButton1Click:Connect(function() send("s4", BTN_S4, "S4") end)
BTN_S7.MouseButton1Click:Connect(function() send("s7", BTN_S7, "S7") end)
BTN_S8.MouseButton1Click:Connect(function() send("s8", BTN_S8, "S8") end)

SELECTOR.MouseButton1Click:Connect(function()
	if not controlsEnabled then return end
	toggleDropdown()
end)

-- F8 show/hide
UserInputService.InputBegan:Connect(function(inp, gp)
	if gp then return end
	if inp.KeyCode == Enum.KeyCode.F8 then
		ROOT.Visible = not ROOT.Visible
		if not ROOT.Visible then
			DROPDOWN.Visible = false
			dropdownOpen = false
		end
	end
end)

----------------------------------------------------------------
-- Emergency UI (single confirm + single ticker)
----------------------------------------------------------------
local function toggleConfirmBar(show: boolean)
	CONFIRM_BAR.Visible = show
	relayout()
end

BTN_EMERGENCY.MouseButton1Click:Connect(function()
	-- ak je button skrytý, nerob nič
	if not BTN_EMERGENCY.Visible then return end
	
	local now = os.time()

	-- Emergency prebieha
	if now < emergencyUntil then
		local left = emergencyUntil - now
		ARE_SURE.Text = ("Emergency %d:%02d"):format(math.floor(left/60), left%60)
		ARE_SURE.BackgroundColor3 = Color3.fromRGB(120,120,120)
		ARE_SURE.Active = false
		toggleConfirmBar(true)

		task.delay(1.6, function()
			if CONFIRM_BAR then
				ARE_SURE.Text = "Are you sure?"
				ARE_SURE.BackgroundColor3 = Color3.fromRGB(200,40,40)
				ARE_SURE.Active = true
				toggleConfirmBar(false)
			end
		end)
		
		refreshEmergencyButton()
		return
	end

	-- Cooldown beží
	if now < cooldownUntil then
		local left = cooldownUntil - now
		ARE_SURE.Text = ("Cooldown %d:%02d"):format(math.floor(left/60), left%60)
		ARE_SURE.BackgroundColor3 = Color3.fromRGB(120,120,120)
		ARE_SURE.Active = false
		toggleConfirmBar(true)

		task.delay(1.6, function()
			if CONFIRM_BAR then
				ARE_SURE.Text = "Are you sure?"
				ARE_SURE.BackgroundColor3 = Color3.fromRGB(200,40,40)
				ARE_SURE.Active = true
				toggleConfirmBar(false)
			end
		end)

		refreshEmergencyButton()
		return
	end

	-- Normálny klik (pýta potvrdenie)
	ARE_SURE.Text = "Are you sure?"
	ARE_SURE.BackgroundColor3 = Color3.fromRGB(200,40,40)
	ARE_SURE.Active = true
	toggleConfirmBar(true)
end)


ARE_SURE.MouseButton1Click:Connect(function()
	toggleConfirmBar(false)
	setControlsEnabled(false)
	RE_Command:FireServer("emergency", currentSemaphore)
end)

CANCEL_BTN.MouseButton1Click:Connect(function()
	toggleConfirmBar(false)
end)





----------------------------------------------------------------
-- One ticker loop for overlay (no multiple spawns)
----------------------------------------------------------------
local function updateOverlay()
	local t = os.time()
	if t < emergencyUntil then
		local left = emergencyUntil - t
		BIG.Text = ("EMERGENCY\n%d:%02d"):format(math.floor(left/60), left%60)
		OVERLAY.Visible = true
		return
	end
	if t < cooldownUntil then
		local left = cooldownUntil - t
		BIG.Text = ("Cooldown\n%d:%02d"):format(math.floor(left/60), left%60)
		OVERLAY.Visible = true
		return
	end
	OVERLAY.Visible = false
end
RunService.Heartbeat:Connect(function(_dt)
	updateOverlay()
	refreshEmergencyButton()
end)

RE_Emergency.OnClientEvent:Connect(function(action: string, duration: number, _who: string?, untilTs: number?)
    if action == "start" then
        emergencyUntil = untilTs or (os.time() + (duration or 0))
        setControlsEnabled(false)   -- ak chceš mať panel zamknutý počas emergency, nechaj
        refreshEmergencyButton()    -- ⬅️ skry tlačidlo
    elseif action == "end" then
        -- čakáme na "cooldown"
    elseif action == "cooldown" then
        cooldownUntil = untilTs or (os.time() + (duration or 0))
        setControlsEnabled(false)   -- počas cooldownu nech je panel stále zamknutý
        refreshEmergencyButton()    -- ⬅️ stále skryté
    end
end)



----------------------------------------------------------------
-- List + status (idempotent, single bind)
----------------------------------------------------------------
local listBound = false
local function requestList()
	if listBound then
		RE_GetList:FireServer()
		return
	end
	listBound = true
	RE_GetList.OnClientEvent:Connect(function(list: {string})
		availableSemaphores = list or {}
		if #availableSemaphores == 0 then
			SELECTOR.Text = "No signals found"; return
		end
		if currentSemaphore == "" or not table.find(availableSemaphores, currentSemaphore) then
			currentSemaphore = availableSemaphores[1]
		end
		SELECTOR.Text = currentSemaphore
		if RE_GetStatus then RE_GetStatus:FireServer(currentSemaphore) end
	end)
	RE_GetList:FireServer()
end

RE_GetStatus.OnClientEvent:Connect(function(name: string, state: string)
	if name == currentSemaphore then UpdateStatusText(state) end
end)
RE_StatusPush.OnClientEvent:Connect(function(name: string, state: string)
	if name == currentSemaphore then UpdateStatusText(state) end
end)

----------------------------------------------------------------
-- Keep dropdown pinned while moving or resizing
----------------------------------------------------------------
ROOT:GetPropertyChangedSignal("Position"):Connect(function()
	if dropdownOpen then positionDropdown() end
end)
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	task.defer(function() if dropdownOpen then positionDropdown() end end)
end)


----------------------------------------------------------------
-- Boot
----------------------------------------------------------------
task.defer(function()
	requestList()
	task.wait(0.2)
	if currentSemaphore ~= "" then RE_GetStatus:FireServer(currentSemaphore) end
end)

print("[DispatchPanel v1.0.1] ready andoptimized, with Emergency & cooldown.")
print("[DispatchPanel v1.0.1] Anti-Abuse System Active.")
