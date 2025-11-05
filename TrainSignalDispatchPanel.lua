--!strict
-- TrainSignalDispatchPanel.lua
-- StarterPlayerScripts (alebo StarterGui -> LocalScript)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LOCAL = Players.LocalPlayer
assert(LOCAL, "LocalPlayer missing (this script must run client-side)")

local playerGui = LOCAL:WaitForChild("PlayerGui")


-- Remote Events
local RE_Command    = ReplicatedStorage:WaitForChild("TrainSignalCommand", 10) :: RemoteEvent?
local RE_GetList    = ReplicatedStorage:WaitForChild("TrainSignalGetList", 10) :: RemoteEvent?
local RE_GetStatus  = ReplicatedStorage:WaitForChild("TrainSignalGetStatus", 10) :: RemoteEvent?
local RE_StatusPush = ReplicatedStorage:WaitForChild("TrainSignalStatus", 10) :: RemoteEvent? -- broadcast

-- ===================== SIMPLE UI =====================
-- Malý, čistý panel bez blur, s dropdownom + tlačidlami na stavy
local SCREEN = Instance.new("ScreenGui")
SCREEN.Name = "TrainSignalDispatchPanel"
SCREEN.ResetOnSpawn = false
SCREEN.IgnoreGuiInset = true
SCREEN.ZIndexBehavior = Enum.ZIndexBehavior.Global
SCREEN.Parent = playerGui

local ROOT = Instance.new("Frame")
ROOT.Name = "Panel"
ROOT.Size = UDim2.fromOffset(460, 280)
ROOT.Position = UDim2.new(0, 24, 0.5, -140)
ROOT.BackgroundColor3 = Color3.fromRGB(28, 32, 40)
ROOT.BorderSizePixel = 0
ROOT.Parent = SCREEN
Instance.new("UICorner", ROOT).CornerRadius = UDim.new(0, 10)

local TITLE = Instance.new("TextLabel")
TITLE.BackgroundTransparency = 1
TITLE.Font = Enum.Font.GothamBold
TITLE.TextSize = 18
TITLE.TextXAlignment = Enum.TextXAlignment.Left
TITLE.TextColor3 = Color3.fromRGB(240, 245, 255)
TITLE.Text = "Dispatch Panel"
TITLE.Size = UDim2.new(1, -16, 0, 28)
TITLE.Position = UDim2.new(0, 12, 0, 10)
TITLE.Parent = ROOT

local LINE = Instance.new("Frame")
LINE.BackgroundColor3 = Color3.fromRGB(50, 58, 70)
LINE.BorderSizePixel = 0
LINE.Size = UDim2.new(1, -24, 0, 1)
LINE.Position = UDim2.new(0, 12, 0, 40)
LINE.Parent = ROOT

-- Selector + status
local SELECTOR = Instance.new("TextButton")
SELECTOR.Name = "Selector"
SELECTOR.AutoButtonColor = false
SELECTOR.BackgroundColor3 = Color3.fromRGB(38, 44, 54)
SELECTOR.TextColor3 = Color3.fromRGB(230, 235, 245)
SELECTOR.Font = Enum.Font.Gotham
SELECTOR.TextSize = 14
SELECTOR.TextXAlignment = Enum.TextXAlignment.Left
SELECTOR.Text = "Loading signals..."
SELECTOR.Size = UDim2.new(0, 220, 0, 28)
SELECTOR.Position = UDim2.new(0, 12, 0, 54)
SELECTOR.Parent = ROOT
Instance.new("UICorner", SELECTOR).CornerRadius = UDim.new(0, 6)
SELECTOR:SetAttribute("OriginalSizeX", 220)
SELECTOR:SetAttribute("OriginalSizeY", 28)

local STATUS = Instance.new("TextLabel")
STATUS.BackgroundTransparency = 1
STATUS.Font = Enum.Font.GothamBold
STATUS.TextSize = 14
STATUS.TextXAlignment = Enum.TextXAlignment.Right
STATUS.Text = "—"
STATUS.TextColor3 = Color3.fromRGB(255,255,255)
STATUS.Size = UDim2.new(1, -244, 0, 28)
STATUS.Position = UDim2.new(0, 236, 0, 54)
STATUS.Parent = ROOT

local DROPDOWN = Instance.new("Frame")
DROPDOWN.Visible = false
DROPDOWN.BackgroundColor3 = Color3.fromRGB(38, 44, 54)
DROPDOWN.BorderSizePixel = 0
DROPDOWN.Position = UDim2.new(0, 12, 0, 90)
DROPDOWN.Size = UDim2.new(0, 220, 0, 160)
DROPDOWN.Parent = ROOT
Instance.new("UICorner", DROPDOWN).CornerRadius = UDim.new(0, 6)

local DDScroll = Instance.new("ScrollingFrame")
DDScroll.BackgroundTransparency = 1
DDScroll.BorderSizePixel = 0
DDScroll.Size = UDim2.new(1, -8, 1, -8)
DDScroll.Position = UDim2.new(0, 4, 0, 4)
DDScroll.ScrollBarThickness = 4
DDScroll.Parent = DROPDOWN

local DDLayout = Instance.new("UIListLayout")
DDLayout.SortOrder = Enum.SortOrder.LayoutOrder
DDLayout.Padding = UDim.new(0, 6)
DDLayout.Parent = DDScroll

DDLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	DDScroll.CanvasSize = UDim2.new(0,0,0, DDLayout.AbsoluteContentSize.Y + 6)
end)

-- Buttons (stavy)
local BUTTONS = Instance.new("Frame")
BUTTONS.BackgroundTransparency = 1
BUTTONS.Size = UDim2.new(1, -24, 0, 140)
BUTTONS.Position = UDim2.new(0, 12, 0, 126)
BUTTONS.Parent = ROOT

local Grid = Instance.new("UIGridLayout", BUTTONS)
Grid.CellSize = UDim2.fromOffset(140, 34)
Grid.CellPadding = UDim2.fromOffset(10, 10)
Grid.FillDirectionMaxCells = 3

local function makeButton(text: string, color: Color3): TextButton
	local b = Instance.new("TextButton")
	b.AutoButtonColor = false
	b.BackgroundColor3 = color
	b.TextColor3 = Color3.fromRGB(18, 18, 22)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 14
	b.Text = text
	b.Parent = BUTTONS
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	b:SetAttribute("OriginalSizeX", 140)
	b:SetAttribute("OriginalSizeY", 34)
	return b
end

local BTN_STOP         = makeButton("STOP", Color3.fromRGB(255, 70, 70))
local BTN_VMAX         = makeButton("VMAX", Color3.fromRGB(90, 255, 110))
local BTN_YELLOW       = makeButton("YELLOW", Color3.fromRGB(255, 210, 70))
local BTN_DOUBLEYELLOW = makeButton("DOUBLE YELLOW", Color3.fromRGB(255, 230, 120))
local BTN_GREENYELLOW  = makeButton("GREEN+YELLOW", Color3.fromRGB(120, 255, 170))
local BTN_SUBS         = makeButton("SUBS", Color3.fromRGB(230, 230, 230))

-- ===================== LOGIC =====================
local currentSemaphore: string = ""
local availableSemaphores: {string} = {}
local isOpenDropdown = false
local isVisible = true

local COLOR_STATE: {[string]: Color3} = {
	STOP = Color3.fromRGB(255, 50, 50),
	VMAX = Color3.fromRGB(50, 255, 50),
	YELLOW = Color3.fromRGB(255, 200, 50),
	["DOUBLE YELLOW"] = Color3.fromRGB(255, 220, 100),
	["GREEN+YELLOW"] = Color3.fromRGB(100, 255, 150),
	SUBS = Color3.fromRGB(220, 220, 220),
}

local function bump(btn: TextButton?)
	if not btn then return end
	local ox = btn:GetAttribute("OriginalSizeX") or btn.Size.X.Offset
	local oy = btn:GetAttribute("OriginalSizeY") or btn.Size.Y.Offset
	TweenService:Create(btn, TweenInfo.new(0.12), {Size = UDim2.fromOffset(ox+10, oy+6)}):Play()
	task.delay(0.14, function()
		TweenService:Create(btn, TweenInfo.new(0.12), {Size = UDim2.fromOffset(ox, oy)}):Play()
	end)
end

local function UpdateStatusText(state: string)
	STATUS.Text = state
	STATUS.TextColor3 = COLOR_STATE[state] or Color3.fromRGB(255,255,255)
end

local function selectSemaphore(name: string)
	currentSemaphore = name
	SELECTOR.Text = name
	-- pýtame si jeho aktuálny stav
	if RE_GetStatus then
		RE_GetStatus:FireServer(currentSemaphore)
	end
end

local function rebuildDropdown()
	for _,c in ipairs(DDScroll:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	for i, name in ipairs(availableSemaphores) do
		local item = Instance.new("TextButton")
		item.AutoButtonColor = false
		item.BackgroundColor3 = Color3.fromRGB(48, 54, 66)
		item.TextColor3 = Color3.fromRGB(240, 244, 255)
		item.Font = Enum.Font.Gotham
		item.TextSize = 14
		item.TextXAlignment = Enum.TextXAlignment.Left
		item.Text = name
		item.Size = UDim2.new(1, -6, 0, 26)
		item.Parent = DDScroll
		Instance.new("UICorner", item).CornerRadius = UDim.new(0, 4)

		item.MouseEnter:Connect(function()
			TweenService:Create(item, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(58, 66, 80)}):Play()
		end)
		item.MouseLeave:Connect(function()
			TweenService:Create(item, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(48, 54, 66)}):Play()
		end)

		item.MouseButton1Click:Connect(function()
			selectSemaphore(name)
			DROPDOWN.Visible = false
			isOpenDropdown = false
		end)
	end
end

-- Dropdown toggle
SELECTOR.MouseButton1Click:Connect(function()
	isOpenDropdown = not isOpenDropdown
	DROPDOWN.Visible = isOpenDropdown
	if isOpenDropdown then rebuildDropdown() end
end)

-- F8 toggle panel
UserInputService.InputBegan:Connect(function(inp, gp)
	if gp then return end
	if inp.KeyCode == Enum.KeyCode.F8 then
		isVisible = not isVisible
		ROOT.Visible = isVisible
	end
end)

-- Send command helper
local function sendCommand(cmd: string, btn: TextButton?, localStateText: string)
	if not RE_Command then
		warn("[Dispatch] TrainSignalCommand missing")
		return
	end
	bump(btn)
	UpdateStatusText(localStateText) -- okamžitá lokálna odozva
	RE_Command:FireServer(cmd, currentSemaphore)
end

BTN_STOP.MouseButton1Click:Connect(function()         sendCommand("stop",         BTN_STOP, "STOP") end)
BTN_VMAX.MouseButton1Click:Connect(function()         sendCommand("vmax",         BTN_VMAX, "VMAX") end)
BTN_YELLOW.MouseButton1Click:Connect(function()       sendCommand("yellow",       BTN_YELLOW, "YELLOW") end)
BTN_DOUBLEYELLOW.MouseButton1Click:Connect(function() sendCommand("doubleyellow", BTN_DOUBLEYELLOW, "DOUBLE YELLOW") end)
BTN_GREENYELLOW.MouseButton1Click:Connect(function()  sendCommand("greenyellow",  BTN_GREENYELLOW, "GREEN+YELLOW") end)
BTN_SUBS.MouseButton1Click:Connect(function()         sendCommand("subs",         BTN_SUBS, "SUBS") end)

-- Init list (request)
local listBound = false
local function requestList()
	if not RE_GetList then return end
	if not listBound then
		listBound = true
		RE_GetList.OnClientEvent:Connect(function(list: {string})
			availableSemaphores = list or {}
			if #availableSemaphores == 0 then
				SELECTOR.Text = "No signals found"
				return
			end
			-- zachovaj výber ak existuje
			if currentSemaphore == "" or not table.find(availableSemaphores, currentSemaphore) then
				currentSemaphore = availableSemaphores[1]
			end
			SELECTOR.Text = currentSemaphore
			-- inicializuj dropdown
			rebuildDropdown()
			-- načítaj status vybraného semaforu
			if RE_GetStatus then
				RE_GetStatus:FireServer(currentSemaphore)
			end
		end)
	end
	RE_GetList:FireServer()
end

-- One-shot status response
if RE_GetStatus then
	RE_GetStatus.OnClientEvent:Connect(function(name: string, state: string)
		if name == currentSemaphore then
			UpdateStatusText(state)
		end
	end)
end

-- Broadcast update (živý update aj keď klikol iný hráč)
if RE_StatusPush then
	RE_StatusPush.OnClientEvent:Connect(function(name: string, state: string)
		if name == currentSemaphore then
			UpdateStatusText(state)
		end
	end)
end

-- Boot
task.defer(function()
	requestList()
	task.wait(0.3)
	if currentSemaphore ~= "" and RE_GetStatus then
		RE_GetStatus:FireServer(currentSemaphore)
	end
end)

print("[DispatchPanel] ready (F8 toggle, dropdown, live status, SUBS).")
