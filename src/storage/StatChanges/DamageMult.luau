local DMModule = {}

DMModule.base = 1

local playerStatsMS = require(game.ServerStorage:WaitForChild("PlayerStats"))

function DMModule.change(humanoid, mult, primary, IncDec, toggle)
	local factor = 1
	local player = game.Players:GetPlayerFromCharacter(humanoid.Parent)
	if IncDec == "Dec" then
		factor = -1
	end
	if primary == true then
		playerStatsMS.SBChange(player, "char_stats", "DamageMult", mult * 0.1 * factor, toggle)
	else
		playerStatsMS.SBChange(player, "char_stats", "DamageMult", mult * 0.05 * factor, toggle)
	end
end

return DMModule

