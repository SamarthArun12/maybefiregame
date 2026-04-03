local MHModule = {}

MHModule.base = 100

local playerStatsMS = require(game.ServerStorage:WaitForChild("PlayerStats"))

--maxhealth changes temp commented out for debugging
function MHModule.change(humanoid, mult, primary, IncDec, toggle)
	local factor = 1
	local player = game.Players:GetPlayerFromCharacter(humanoid.Parent)
	if IncDec == "Dec" then
		factor = -1
	end
	if primary == true then
		playerStatsMS.SBChange(player, "humanoid_stats", "MaxHealth", mult * 0.1 * factor, toggle, true)
	else
		playerStatsMS.SBChange(player, "humanoid_stats", "MaxHealth", mult * 0.05 * factor, toggle, false)
	end
end

return MHModule