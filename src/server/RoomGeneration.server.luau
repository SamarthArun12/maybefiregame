local ReplicatedStorage = game:GetService("ReplicatedStorage")
local roomFolder = ReplicatedStorage:WaitForChild("Rooms")
local tpScript = game:GetService("ServerStorage"):WaitForChild("TeleportScript")
local roomNum = 10

--will need to rework this entire thing so that only 2-3 rooms exist at once
for i = 1, roomNum do
	local randomNum = math.random(1, #roomFolder:GetChildren())
	local room = roomFolder:GetChildren()[randomNum]:Clone()
	
	room.Parent = workspace
	room.Name = "Room" .. tostring(i)
	local teleportScript = tpScript:Clone()
	teleportScript.Parent = room:FindFirstChild("Teleporter")
	local roomCframe = CFrame.new(200 * i, 50, 200 * i)
	room:PivotTo(roomCframe)
 	local teleporter = room:FindFirstChild("Teleporter")
	if i ~= roomNum then
		targetRoomName = "Room" .. tostring(i + 1)
		teleporter:SetAttribute("Target", targetRoomName)
		teleporter:SetAttribute("Enabled", true)
		if i % 5 == 0 then
			room:SetAttribute("RewardRoom", true)
		else
			room:SetAttribute("RewardRoom", false)
		end
	end
	
end
