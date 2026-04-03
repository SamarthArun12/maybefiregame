local players = game:GetService("Players")
local RE = game.ReplicatedStorage.RemoteEvents:WaitForChild("SetAttributes")
local TemplateACS = game.ServerStorage:WaitForChild("AttributeChangeSystem")

players.PlayerAdded:Connect(function(player)
	--Stuff that stays when death
	player:SetAttribute("Primary", "Damage")
	player:SetAttribute("WeaponName", "Spear")
	player:SetAttribute("EquippedSlot", 1)
	player:SetAttribute("BurstTech", "HealthBurst")
	player:SetAttribute("Equipped", "Offhand")
	player:SetAttribute("CanPlay", false)
end)


RE.OnServerEvent:Connect(function(player)
	local character = player.Character
	if not character then return end

	character:SetAttribute("DamageMult", 1)
	character:SetAttribute("None", 0)
	character:SetAttribute("Affiliation", "Player")
	
	local acs = TemplateACS:Clone()
	acs:SetAttribute("Player", player.Name)
	acs.Parent = game:GetService("ServerScriptService")
end)

