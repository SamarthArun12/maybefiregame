local CritModule = {}

CritModule.base = 1

local playerStatsMS = require(game.ReplicatedStorage:WaitForChild("PlayerStats"))

function CritModule.change(humanoid, mult, primary, IncDec, toggle)
	local factor = 1
	local player = game.Players:GetPlayerFromCharacter(humanoid.Parent)
	if IncDec == "Dec" then
		factor = -1
	end
	if primary == true then
		playerStatsMS.SBChange(player, "char_stats", "CritChance", mult * 0.1 * factor, toggle, true)
		playerStatsMS.SBChange(player, "char_stats", "CritDamage", mult * 0.025 * factor, toggle, true)
	else
		playerStatsMS.SBChange(player, "char_stats", "CritChance", mult * 0.05 * factor, toggle, false)
	end
end

return CritModule

