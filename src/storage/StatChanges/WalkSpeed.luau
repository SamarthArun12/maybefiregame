local WSModule = {}

WSModule.base = 32

local playerStatsMS = require(game.ServerStorage:WaitForChild("PlayerStats"))

function WSModule.change(humanoid, mult, primary, IncDec, toggle)
	local factor = 1
	local player = game.Players:GetPlayerFromCharacter(humanoid.Parent)
	if IncDec == "Dec" then
		factor = -1
	end
	if primary == true then
		playerStatsMS.SBChange(player, "humanoid_stats", "WalkSpeed", mult * 0.1 * factor, toggle)
	else
		playerStatsMS.SBChange(player, "humanoid_stats", "WalkSpeed", mult * 0.05 * factor, toggle)
	end
end

return WSModule
