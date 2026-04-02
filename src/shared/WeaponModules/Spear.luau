local SpearModule = {}
local rs = game.ReplicatedStorage

-- Combat stats
SpearModule.BaseDMG = 30
SpearModule.AttackCD = 0.75
SpearModule.ComboNum = 3
SpearModule.ComboWindow = 1
SpearModule.Hitboxes = {
	Vector3.new(4, 4, 6),
	Vector3.new(5, 3, 6),
	Vector3.new(4, 3, 8)
}
SpearModule.Animations = {
	"rbxassetid://139580504376878",
	"rbxassetid://139580504376878",
	"rbxassetid://139580504376878"
}

--Damage n other stuff I want on server
function SpearModule.activateServer(player, char, weapon, combo)
	local humanoidRoot = char:FindFirstChild("HumanoidRootPart")
	local DamageMult = char:GetAttribute("DamageMult") or 1
	if not humanoidRoot then return end
	local hit_objects = {}
	local hitboxSize = SpearModule.Hitboxes[combo]
	local baseDamage = SpearModule.BaseDMG
	for i = 1, 20 do
		local hitbox = Instance.new("Part")
		hitbox.Size = hitboxSize
		hitbox.CFrame = humanoidRoot.CFrame * CFrame.new(0, 0, -3)
		hitbox.Transparency = 0.9
		hitbox.Color = Color3.fromRGB(255, 0, 0)
		hitbox.Material = Enum.Material.SmoothPlastic
		hitbox.Anchored = true
		hitbox.CanCollide = false
		hitbox.Parent = workspace
		for _, obj in pairs(workspace:GetPartsInPart(hitbox)) do
			if obj.Name ~= "LineOfSight" then
				if obj.Parent:FindFirstChild("Humanoid") and obj.Parent ~= char then
					if not table.find(hit_objects, obj.Parent:GetAttribute("EnemyId")) then
						obj.Parent.Humanoid:TakeDamage(baseDamage * DamageMult)
						table.insert(hit_objects, obj.Parent:GetAttribute("EnemyId"))
					end
				elseif obj:GetAttribute("Attackable") == true and not table.find(hit_objects, obj.Parent) then
					obj.Parent:SetAttribute("RecentlyHit", true)
					table.insert(hit_objects, obj.Parent)
				end
			end
		end
		game:GetService("Debris"):AddItem(hitbox, 0.1)
		task.wait(0.01)
	end
end

--animations n stuff I want on client
function SpearModule.activateClient(humanoid, combo)
	local animator = humanoid:WaitForChild("Animator")
	local anim = Instance.new("Animation")
	anim.AnimationId = SpearModule.Animations[combo]
	local track = animator:LoadAnimation(anim)
	track:Play()
end

function SpearModule.setup(player)
	local character = player.Character
	local weapon_name = player:GetAttribute('WeaponName')
	local weapon = rs.Weapons:FindFirstChild(weapon_name)
	if not weapon then return end
	local rightArm = character:FindFirstChild('Right Arm')
	local clonedWeapon = weapon:Clone()
	clonedWeapon.Parent = character
	local handle = clonedWeapon:FindFirstChild('Handle')
	local cframeValue = clonedWeapon:FindFirstChild('Value')
	local motor6d = Instance.new('Motor6D')
	motor6d.Part0 = rightArm
	motor6d.Part1 = handle
	motor6d.C1 = cframeValue.Value
	motor6d.Parent = handle
end

return SpearModule