local ReplicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local RE = game.ReplicatedStorage.RemoteEvents:WaitForChild("SetAttributes")
local TemplateACS = game.ServerStorage:WaitForChild("AttributeChangeSystem")
local playerItems = game:GetService("StarterPack"):GetChildren()
table.sort(playerItems, function(a, b)
	return a.Name < b.Name
end)

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

	local folderName = player.Name.."Folder"
	local folder = Instance.new("Folder")
	folder.Name = folderName
	folder.Parent = ReplicatedStorage.PlayerFolders
	--update later to be just what stuff player has last used
	for i, item in ipairs(playerItems) do
		local clone = item:Clone()
		clone.Parent = folder
	end
end)

