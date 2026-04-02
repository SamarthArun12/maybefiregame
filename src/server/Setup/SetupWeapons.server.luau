local WeaponsFolder = game:GetService("ReplicatedStorage"):WaitForChild("Weapons")

local weapons = {
	Spear = {
		BaseDMG = 30,
		AttackCD = 0.75,
		ComboNum = 3,
		ComboWindow = 1,
		Hitbox1 = Vector3.new(4,4,6),
		Hitbox2 = Vector3.new(5,3,6),
		Hitbox3 = Vector3.new(4,3,8),
		Ceiling = 150,
		Mult = 1,
		PrimaryStat = "WalkSpeed",
		SecondaryStat = "None",
		SideAffect = "None",
		Stored = 0,
	},
	Sword = {
		BaseDMG = 25,
		AttackCD = 0.4,
		ComboNum = 4,
		ComboWindow = 0.75,
		Hitbox1 = Vector3.new(6,4,5),
		Hitbox2 = Vector3.new(5.5,4.5,5),
		Hitbox3 = Vector3.new(4,6,6),
		Hitbox4 = Vector3.new(2.5,5,6),
		Ceiling = 150,
		Mult = 1,
		PrimaryStat = "WalkSpeed",
		SecondaryStat = "None",
		SideAffect = "None",
		Stored = 0,

	}
}

for weaponName, weaponStats in pairs(weapons) do
	local weapon = WeaponsFolder:WaitForChild(weaponName)
	for statName, value in pairs(weaponStats) do
		weapon:SetAttribute(statName, value)
	end
end
