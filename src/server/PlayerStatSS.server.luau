local PlayerStats = require(game.ServerStorage.PlayerStats)

-- Initialize players
game.Players.PlayerAdded:Connect(function(player)
	
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid")
		task.wait(0.1)
		PlayerStats.newPlayer(player)
		PlayerStats.applyChanges(player)
	end)
	
end)

game.Players.PlayerRemoving:Connect(function(player)
	PlayerStats.cleanup(player)
end)



-- Recalculation loop
while true do
	task.wait(0.1)
	for _, player in pairs(game.Players:GetPlayers()) do
		PlayerStats.recalculateAC(player)
	end
end