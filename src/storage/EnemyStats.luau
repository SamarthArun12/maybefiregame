local EnemyAI = require(game.ServerStorage.EnemyAI)

local enemyStats = {}
--directly changed to cause permament buffs/debuffs to all enemies for rest of run
local baseStats = {
	HumanoidStats = {
		MaxHealth = 100,
		WalkSpeed = 30,
		JumpPower = 50,
		None = 0
	},
	CharacterStats = {
		DamageMult = 1,
		PatrolSpeed = 20,
		None = 0
	}
}


local activeChangesTemplate = {
	HumanoidStats = {
		MaxHealth = 1,
		WalkSpeed = 1,
		JumpPower = 1,
		None = 1
	},
	CharacterStats = {
		DamageMult = 1,
		PatrolSpeed = 1,
		None = 1
	}
}


local function deepClone(t)
	local clone = {}
	for k, v in pairs(t) do
		if type(v) == "table" then
			clone[k] = deepClone(v)
		else
			clone[k] = v
		end
	end
	return clone
end


function enemyStats.newEnemy(enemyId)
	enemyStats[enemyId] = {
		statValues = deepClone(baseStats),
		activeChanges = deepClone(activeChangesTemplate),
		durations = {},
	}
end


function enemyStats.addChange(enemyId, statName, category, multChange, duration, changeName)
	local enemyTable = enemyStats[enemyId]
	if not enemyTable then return end
	local endTime = os.clock() + duration
	table.insert(enemyTable.durations, {category, statName, multChange, endTime, false, changeName})
end


function enemyStats.refreshChange(enemyId, statName, category, multChange, duration, changeName)
	local enemyTable = enemyStats[enemyId]
	if not enemyTable then return end
	local found = false
	for i, tuple in pairs(enemyTable.durations) do
		if tuple[6] == changeName then
			tuple[4] = os.clock() + duration
			found = true
			break
		end
	end
	if not found then
		enemyStats.addChange(enemyId, statName, category, multChange, duration, changeName)
	end
end


function enemyStats.applyChanges(enemyId)
	local enemyTable = enemyStats[enemyId]
	if not enemyTable then return end
	
	local enemiesList = EnemyAI.Enemies
	local character = enemiesList[enemyId].model
	if not character then return end
	local humanoid = character.Humanoid
	if not humanoid then return end
	
	for category, statsList in pairs(enemyTable.activeChanges) do
		for statName, mult in pairs(statsList) do
			local baseStat = baseStats[category][statName]
			enemyTable.statValues[category][statName] = baseStat * mult
			if mult ~= 1 then
				--print(mult)
			end
		end
	end
	if humanoid then
		for statName, value in pairs(enemyTable.statValues.HumanoidStats) do
			if statName ~= "None" then
				humanoid[statName] = value
			end
		end
	end
	if character then
		for statName, value in pairs(enemyTable.statValues.CharacterStats) do
			if statName ~= "None" then
				character:SetAttribute(statName, value)
			end
		end
	end
end


function enemyStats.recalculateAC(enemyId)
	local enemyTable = enemyStats[enemyId]
	if not enemyTable then return end
	local now = os.clock()
	for i = #enemyTable.durations, 1, -1 do
		local tuple = enemyTable.durations[i]
		if now >= tuple[4] then
			local category = tuple[1]
			local statName = tuple[2]
			local mult = tuple[3]
			enemyTable.activeChanges[category][statName] -= mult
			table.remove(enemyTable.durations, i)
		end
	end
	for index, tuple in ipairs(enemyTable.durations) do
		local category = tuple[1]
		local statName = tuple[2]
		local mult = tuple[3]
		local applied = tuple[5]
		if not applied then
			enemyTable.durations[index][5] = true
			enemyTable.activeChanges[category][statName] += mult
		end
	end
	
	enemyStats.applyChanges(enemyId)
end


function enemyStats.cleanup(enemyId)
	enemyStats[enemyId] = nil
end


function enemyStats.getEnemies()
	local enemyList = {}
	for id, v in pairs(enemyStats) do
		if type(v) == "table" then
			table.insert(enemyList, id)
		end
	end
	return enemyList
end


return enemyStats