local event = game.ReplicatedStorage.RemoteEvents:WaitForChild("EquippedChanged")

event.OnServerEvent:Connect(function(player)
	print("receive equip")
	local current = player:GetAttribute("Equipped")
	if current == "Weapon" then
		player:SetAttribute("Equipped", "Offhand")
		print("change from weapon to offhand")
	elseif current == "Offhand" then
		player:SetAttribute("Equipped", "Weapon")
		print("change from offhand to weapon")
	end
end)