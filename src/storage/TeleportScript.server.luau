local teleporter = script.Parent
local hitbox = teleporter:FindFirstChild("Hitbox")
local room = script.Parent.Parent
local targetRoomName = teleporter:GetAttribute("Target")
local workspace = game:GetService("Workspace")
local event = game.ReplicatedStorage.BindableEvents:FindFirstChild("RoomChange")
local interacted = false

local rewardsMS = require(game.ServerStorage:FindFirstChild("RewardsMS"))

hitbox.Touched:Connect(function(part)
	task.wait(0.5)
	local character = part.Parent
	local enabled = script.Parent:GetAttribute("Enabled")

	if enabled == false then return end
	if character:FindFirstChild("Humanoid") == nil then return end
	if character:GetAttribute("Affiliation") ~= "Player" then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	local targetRoom = workspace:FindFirstChild(targetRoomName)
	local target
	if targetRoom and not interacted then

		if room:GetAttribute("RewardRoom") == true then
			rewardsMS.ShowRewards()
		end

		--unsure if paused until rewards show is finished
		print(targetRoom)
		target = targetRoom:FindFirstChild("Target")
		hrp.CFrame = target.CFrame + Vector3.new(0, 4, 0)
		event:Fire(targetRoomName)
		print("teleported")
		interacted = true
	end
end)