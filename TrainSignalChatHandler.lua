-- Train Signal Chat Message Handler
-- LocalScript - Place this in StarterGui or StarterPlayer > StarterPlayerScripts
-- Handles displaying chat messages from the server

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- Wait for RemoteEvent
local chatRemote = ReplicatedStorage:WaitForChild("TrainSignalChatMessage", 10)

if chatRemote then
	-- Listen for chat messages from server
	chatRemote.OnClientEvent:Connect(function(message, color)
		-- Display in chat
		StarterGui:SetCore("ChatMakeSystemMessage", {
			Text = message,
			Color = color or Color3.fromRGB(100, 200, 255)
		})
	end)
	
	print("[Train Signal Chat] Client-side chat handler initialized")
else
	warn("[Train Signal Chat] RemoteEvent not found - chat messages will only show in Output")
end

