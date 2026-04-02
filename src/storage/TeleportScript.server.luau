local teleporter = script.Parent
local hitbox = teleporter:FindFirstChild("Hitbox")
local targetRoomName = teleporter:GetAttribute("Target")
local workspace = game:GetService("Workspace")
local event = game.ReplicatedStorage.BindableEvents:WaitForChild("RoomChange")
local interacted = false

hitbox.Touched:Connect(function(part)
	task.wait(0.5)
	local character = part.Parent
	local enabled = script.Parent:GetAttribute("Enabled")
	if enabled == false then return end
	if character:FindFirstChild("Humanoid") ~= nil then
		if character:GetAttribute("Affiliation") == "Player" then
			local hrp = character:FindFirstChild("HumanoidRootPart")
			local targetRoom = workspace:FindFirstChild(targetRoomName)
			local target
			if targetRoom and not interacted then
				print(targetRoom)
				target = targetRoom:FindFirstChild("Target")
				hrp.CFrame = target.CFrame + Vector3.new(0, 4, 0)
				event:Fire(targetRoomName)
				print("teleported")
				interacted = true
			end
		end
	end
end)