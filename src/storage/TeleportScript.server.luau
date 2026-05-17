local teleporter = script.Parent
local hitbox = teleporter:FindFirstChild("Hitbox")
local RoomFunctions = require(game.ServerStorage:FindFirstChild("RoomFunctions"))


hitbox.Touched:Connect(function(part)
	if RoomFunctions.enabledTeleporters == false then 
		print("teleporters disabled, not teleporting")
		return
	end
	print("hitbox touched")

	RoomFunctions.teleportFunction(part)
end)