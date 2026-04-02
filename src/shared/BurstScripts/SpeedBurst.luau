local SpeedBurst = {}

SpeedBurst.name = "Speed Burst"
SpeedBurst.cost = 30
SpeedBurst.cooldown = 0.5
SpeedBurst.stat = "WalkSpeed"
SpeedBurst.animationId = "rbxassetid://139580504376878"
SpeedBurst.requiresPos = true

function SpeedBurst.clientChanges(character)
	if not character then return end
	local humanoid = character:FindFirstChild("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then return end
	
	root.CFrame = root.CFrame * CFrame.new(0,0,-25)
end

function SpeedBurst.activate(player, pos)
	local character = player.Character
	local humanoid = character:FindFirstChild("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")

	local DamageMult = character:GetAttribute("DamageMult") or 1

	local dashDistance = 25
	
	root.CFrame = pos * CFrame.new(0, 0, -dashDistance)

	local hitbox = Instance.new("Part")
	hitbox.Size = Vector3.new(10, 10, dashDistance)
	hitbox.CFrame = root.CFrame * CFrame.new(0, 0, dashDistance/2)
	hitbox.Transparency = 0.9
	hitbox.Color = Color3.fromRGB(255, 0, 0)
	hitbox.Material = Enum.Material.SmoothPlastic
	hitbox.Anchored = true
	hitbox.CanCollide = false
	hitbox.Parent = workspace

	local hitHumanoids = {}
	for _, part in pairs(workspace:GetPartsInPart(hitbox)) do
		local partHumanoid = part.Parent:FindFirstChild("Humanoid")
		if partHumanoid and partHumanoid ~= humanoid and not hitHumanoids[partHumanoid] then
			partHumanoid:TakeDamage(20 * DamageMult)
			hitHumanoids[partHumanoid] = true
		end
	end

	game:GetService("Debris"):AddItem(hitbox, 0.1)
end

return SpeedBurst
