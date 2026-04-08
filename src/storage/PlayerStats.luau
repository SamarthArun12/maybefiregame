local PlayerStats = {}
--almost entirely made by me :)

local baseStats = {
	humanoid_stats = {
		MaxHealth = 100,
		WalkSpeed = 32,
		JumpPower = 50,
		None = 0
	},
	char_stats = {
		DamageMult = 1,
		None = 0
	}
}

local activeChangesTemplate = {
	humanoid_stats = {
		MaxHealth = { items = 1, sb = 1 },
		WalkSpeed = { items = 1, sb = 1 },
		JumpPower = { items = 1, sb = 1 },
		None = { items = 1, sb = 1 }
	},
	char_stats = {
		DamageMult = { items = 1, sb = 1 },
		None = { items = 1, sb = 1 }
	},
	reqUpdate = false
}

--ai generated function
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

function PlayerStats.newPlayer(player)
	PlayerStats[player] = {
		statValues = deepClone(baseStats),
		activeChanges = deepClone(activeChangesTemplate),
		durations = {},
	}
end

function PlayerStats.addChange(player, statName, category, multChange, duration, changeName)
	local playerTable = PlayerStats[player]
	if not playerTable then return end

	local endTime = os.clock() + duration
	table.insert(playerTable.durations,{category, statName, multChange, endTime, false, changeName})
end

function PlayerStats.healthChange()
end

function PlayerStats.refreshChange(player, statName, category, multChange, duration, changeName)
	local playerTable = PlayerStats[player]
	if not playerTable then return end
	
	local found = false
	for i, tuple in pairs(playerTable.durations) do
		if tuple[6] == changeName then
			local newEndTime = os.clock() + duration
			tuple[4] = newEndTime
			found = true
			print("change found, refreshed")
			break
		end
	end
	if not found then
		PlayerStats.addChange(player, statName, category, multChange, duration, changeName)
		print("change not present, added")
	end
end

function PlayerStats.SBChange(player, category, stat, change, toggle, isprimary)
	local playerTable = PlayerStats[player]
	if not playerTable then return end
	if isprimary then
		PlayerStats.resetSB(player)
	end
	--print(string.format("player: %s | category: %s | stat: %s | change: %s | toggle: %s", tostring(player), tostring(category), tostring(stat), tostring(change), tostring(toggle)))
	if toggle then
		--print("toggle is true")
		playerTable.activeChanges[category][stat].sb += (change)
		playerTable.activeChanges.reqUpdate = true
	end
end

function PlayerStats.resetSB(player)
	local playerTable = PlayerStats[player]
	if not playerTable then return end
	for _, statsList in pairs(playerTable.activeChanges) do
		for _, value in pairs(statsList) do
			value.sb = 1
		end
	end
end

local function healthSBChange(statName, mult, humanoid)
	if statName ~= "MaxHealth" then return end
	--print(mult)
	if mult == 1 then return end

	mult = (mult - 1) * 10
	local change = 0.05 * mult
	humanoid.Health += change
	print("health change by "..change)
end

function PlayerStats.applyChanges(player)
	local playerTable = PlayerStats[player]
	if not playerTable then return end
	if playerTable.activeChanges.reqUpdate == false then return end
	playerTable.activeChanges.reqUpdate = false

	local char = player.Character
	if not char then return end
	local humanoid = char:FindFirstChild("Humanoid")
	if not humanoid then return end

	for category, statsList in pairs(playerTable.activeChanges) do
		for statName, mult in pairs(statsList) do
			local baseStat = baseStats[category][statName]
			local changeMult = mult.sb + mult.items - 1
			playerTable.statValues[category][statName] = baseStat * changeMult
			healthSBChange(statName, mult.sb, humanoid)
		end
	end

	for statName, value in pairs(playerTable.statValues.humanoid_stats) do
		if statName ~= "None" then
			humanoid[statName] = value
		end
	end
	for statName, value in pairs(playerTable.statValues.char_stats) do
		if statName ~= "None" then
			char:SetAttribute(statName, value)
		end
	end
end

function PlayerStats.recalculateAC(player)
	local playerTable = PlayerStats[player]
	if not playerTable then return end

	local now = os.clock()
	local wasChanged = false

	-- Remove expired durations, does in reverse order to avoid skipping
	for i = #playerTable.durations, 1, -1 do
		local tuple = playerTable.durations[i]
		if now >= tuple[4] then
			local category = tuple[1]
			local statName = tuple[2]
			local mult = tuple[3]
			playerTable.activeChanges[category][statName].items -= mult
			table.remove(playerTable.durations, i)
			wasChanged = true
		end
	end

	-- Apply all unapplied durations to activeChanges
	for index, tuple in ipairs(playerTable.durations) do
		local category = tuple[1]
		local statName = tuple[2]
		local mult = tuple[3]
		local applied = tuple[5]
		if not applied then
			playerTable.durations[index][5] = true
			playerTable.activeChanges[category][statName].items += mult
			wasChanged = true
		end
	end
	
	if wasChanged then playerTable.activeChanges.reqUpdate = true end
	PlayerStats.applyChanges(player)
end

function PlayerStats.cleanup(player)
	PlayerStats[player] = nil
end

return PlayerStats