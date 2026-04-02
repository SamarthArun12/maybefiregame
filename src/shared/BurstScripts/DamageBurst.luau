local DamageBurst = {}

DamageBurst.name = "Speed Burst"
DamageBurst.cost = 20
DamageBurst.cooldown = 0.5
DamageBurst.stat = "DamageMult"
DamageBurst.animationId = "rbxassetid://139580504376878"

function DamageBurst.clientChanges(character)
	print("none for this burst")
end

function DamageBurst.activate(player)
	local character = player.Character
	local humanoid = character:FindFirstChild("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")

	local hitbox = Instance.new("Part")
	hitbox.Size = Vector3.new(10, 10, 10)
	hitbox.CFrame = root.CFrame * CFrame.new(0, 0, -3)
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
			partHumanoid:TakeDamage(80)
			hitHumanoids[partHumanoid] = true
		end
	end

	game:GetService("Debris"):AddItem(hitbox, 0.1)
end

return DamageBurst
