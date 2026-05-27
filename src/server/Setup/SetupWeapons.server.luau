local WeaponsFolder = game:GetService("ReplicatedStorage"):WaitForChild("Weapons")

local weapons = {
    Spear = {
        --attributes can change
        Attributes = {
            Ceiling = 150,
            Mult = 1,
            PrimaryStat = "WalkSpeed",
            SecondaryStat = "None",
            SideAffect = "None",
            Stored = 0,
			sorbState = "None"
        },
        --Properties are fixed
        Properties = {
            BaseDMG = 30,
            BaseAtkCD = 0.75,
            ComboNum = 3,
            ComboWindow = 1,
            Hitbox1 = Vector3.new(4,4,6),
            Hitbox2 = Vector3.new(5,3,6),
            Hitbox3 = Vector3.new(4,3,8),
        },
    },
    Sword = {
        --attributes can change
        Attributes = {
            Ceiling = 150,
            Mult = 1,
            PrimaryStat = "WalkSpeed",
            SecondaryStat = "None",
            SideAffect = "None",
            Stored = 0,
			sorbState = "None"
        },
        --Properties are fixed
        Properties = {
            BaseDMG = 25,
            BaseAtkCD = 0.4,
            ComboNum = 4,
            ComboWindow = 0.75,
            Hitbox1 = Vector3.new(6,4,5),
            Hitbox2 = Vector3.new(5.5,4.5,5),
            Hitbox3 = Vector3.new(4,6,6),
            Hitbox4 = Vector3.new(2.5,5,6),
        },
    }
}

for weaponName, weaponStats in pairs(weapons) do
	local weapon = WeaponsFolder:WaitForChild(weaponName)
	for statName, value in pairs(weaponStats.Attributes) do
		weapon:SetAttribute(statName, value)
	end
end
