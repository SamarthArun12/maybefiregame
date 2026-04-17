--EnemyAI MS, all info and functions to make enemy ai work
local EnemyAI = {}

local playerService = game:GetService("Players")

--REMEMBER TO GIT PUSH B4 DOING DEBUGGING

--#region pointless region 

--manages initalization of values, removal on death, etc
--#region Enemy Management
EnemyAI.Enemies = {}
local EnemyDefaults = {
	RegularEnemy = {
		model = nil,
	},
	StealthEnemy = {
		model = nil,
		--used for deciding which section to execute
		state = "patrol",
		--used for task.spawn flags
		currentAction = "idle",
		currentNode = 1,
		targetPlayer = nil,
		lastSeen = nil,
		lastStateChange = nil,
		searchDuration = 2
	}
}

local function getField(enemyId, fieldName)
	return EnemyAI.Enemies[enemyId][fieldName]
end
local function changeField(enemyId, fieldName, change)
	EnemyAI.Enemies[enemyId][fieldName] = change
end
local function cloneTable(table)
	local temp = {}
    for k, v in pairs(table) do
        temp[k] = v
    end
	return temp
end
function EnemyAI.newEnemy(enemyId, enemyModel, type)
	local temp = cloneTable(EnemyDefaults[type])
	temp.model = enemyModel
	temp.lastStateChange = os.clock()
	print(temp)

	EnemyAI.Enemies[enemyId] = temp
	
end
function EnemyAI.removeEnemy(enemyId)
	EnemyAI.Enemies[enemyId] = nil
end
--#endregion

--used by enemies that are always aware of player pos to nav to appropriate positions
--#region Zone Nav
EnemyAI.navigating = {}
EnemyAI.targetZone = {}
--determines wheter a position is in a zone, returns a bool
local function inZone(pos, zone)
	local partPos = zone.CFrame:PointToObjectSpace(pos)
	local size = zone.Size/2
	if math.abs(partPos.X) <= size.X and math.abs(partPos.Y) <= size.Y and math.abs(partPos.Z) <= size.Z then
		return true
	else
		return false
	end
end
--returns the nearest player
local function nearestPlayer(enemyId, players)
	local enemyModel = getField(enemyId, "model")
	local nearestP = nil
	local nearestDist = math.huge
	for i, player in pairs(players) do
		if not player.Character then continue end
		if player.Character:GetAttribute("Hidden") == true then continue end
		--print(enemyId, EnemyAI.Enemies[enemyId])
		local ePos = enemyModel.HumanoidRootPart.Position
		local pPos = player.Character.HumanoidRootPart.Position
		local diff = pPos - ePos
		--so that the nearest player is more likely to be on the same elevation
		local distance = Vector3.new(diff.X, diff.Y * 5, diff.Z).Magnitude
		if distance < nearestDist then
			nearestDist = distance
			nearestP = player
		end
	end
	return nearestP
end
--returns the zone the player and enemy are in
local function getZones(room, player, enemyModel)
	local zones = room:FindFirstChild("Zones")
	local enemyZone = nil
	local playerZone = nil
	for i, zone in pairs(zones:GetChildren()) do
		if not player.Character then return end
		if inZone(player.Character.HumanoidRootPart.Position, zone) then
			playerZone = zone
		end
		if inZone(enemyModel.HumanoidRootPart.Position, zone) then
			enemyZone = zone
		end
	end
	--replace with fixes later
	if playerZone == nil then
		--print("player is somewhere they aren't supposed to be...")
	end
	if enemyZone == nil then
		--print("enemy is to be respawned")
	end
	return playerZone, enemyZone
end
--enemy follows a nodepath
--direction being true means follow path beginning to end, false means beginning to end
local function followPath(enemyId, nodePath, direction)
	--print("began following path")
	local enemyModel = getField(enemyId, "model")
	local humanoid = enemyModel.Humanoid
	
	local nodes = nodePath:GetChildren()
	--ai generated sort
	table.sort(nodes, function(a, b)
		return tonumber(a.Name) < tonumber(b.Name)
	end)
	
	local current, increment
	if direction == true then
		current = 1
		increment = 1
	elseif direction == false then
		current = #nodes
		increment = -1
	end
	
	while current >= 1 and current <= #nodes do
		if not EnemyAI.navigating[enemyId] then break end
		local currentTarget = nodes[current]
		humanoid:MoveTo(currentTarget.Position)
		humanoid.MoveToFinished:Wait()
		current += increment
	end
	EnemyAI.navigating[enemyId] = false
	--print("reached end of path")
end
local function navToZone(enemyId, room, currentZone, targetZone)
	local nodePaths = room:FindFirstChild("NodePaths"):GetChildren()
	local foundPath = false
	for i, path in pairs(nodePaths) do
		if (path:GetAttribute("startZone") == currentZone.Name or path:GetAttribute("startZone") == targetZone.Name) and (path:GetAttribute("endZone") == targetZone.Name or path:GetAttribute("endZone") == currentZone.Name) then
			if path:GetAttribute("startZone") == currentZone.Name then
				followPath(enemyId, path, true)
				foundPath = true
			elseif path:GetAttribute("startZone") == targetZone.Name then
				followPath(enemyId, path, false)
				foundPath = true
			end
		end
	end
	if not foundPath then
		print("no path was found :<")
	end
end
--#endregion

--spawned in by spawners
--#region RegularEnemy AI
--decides which reg enemy ai function to call
function EnemyAI.RegularEnemy(enemyId)
	local enemyModel = getField(enemyId, "model")
	local players = playerService:GetPlayers()
	
	local nearest = nearestPlayer(enemyId, players)
	if not nearest then return end
	
	local playerZone, enemyZone = getZones(enemyModel.Parent, nearest, enemyModel)
	if playerZone == nil or enemyZone == nil then return end
	--print("player is in "..tostring(playerZone).." and enemy is in "..tostring(enemyZone))
	
	if playerZone == enemyZone then
		--print("player and enemy "..enemyId.." are in the same zone")
		EnemyAI.navigating[enemyId] = false
		EnemyAI.RegularEnemyChase(nearest, enemyId)
	else
		if EnemyAI.targetZone[enemyId] ~= playerZone then
			EnemyAI.navigating[enemyId] = false
			EnemyAI.targetZone[enemyId] = playerZone
			task.spawn(function()
				--print("enemy: "..enemyId.." is navigating")
				EnemyAI.navigating[enemyId] = true
				navToZone(enemyId, enemyModel.Parent, enemyZone, playerZone)
				EnemyAI.targetZone[enemyId] = nil
			end)
		end
	end
end
--regular enemy chases after the player mindlessly
function EnemyAI.RegularEnemyChase(player, enemyId)
	--print("regular enemy chasing")
	local character = player.Character
	if not character then return end
	local hrp = character.HumanoidRootPart
	local enemyModel = getField(enemyId, "model")
	local enemyHumanoid = enemyModel.Humanoid
	enemyHumanoid:MoveTo(hrp.Position)
end
--#endregion

--#enemy ai meant to have been hand placed, and assigned a patrol path by hand
--#region StealthEnemy AI
function EnemyAI.StealthEnemy(enemyId)
	--first section changes flags and values
	EnemyAI.StealthEnemyUpdateFlags(enemyId)

	--second section acts upon values n flags
	local currentState = getField(enemyId, "state")
	EnemyAI.StealthEnemyAct(enemyId, currentState)
end

--Enemy follows patrol path
function EnemyAI.StealthEnemyPatrol(enemyId)
	local enemyModel = getField(enemyId, "model")
	local pathName = enemyModel:GetAttribute("AssignedPath")
	local room = enemyModel.Parent
	local path = room.PatrolPaths:FindFirstChild(pathName)

	EnemyAI.StealthEnemyFollowPatrol(enemyId, path)
end

--self explanatory
function EnemyAI.StealthEnemyFollowPatrol(enemyId, path)
	local enemyModel = getField(enemyId, "model")
	local humanoid = enemyModel:FindFirstChild("Humanoid")
	local nodes = path:GetChildren()
	table.sort(nodes, function(a, b)
		return tonumber(a.Name) < tonumber(b.Name)
	end)
	
	local current = getField(enemyId, "currentNode")
	local increment = 1
	
	while current >= 1 and current <= #nodes do
		if getField(enemyId, "currentAction") ~= "patrolling" then break end
		local currentTarget = nodes[current]
		humanoid:MoveTo(currentTarget.Position)
		humanoid.MoveToFinished:Wait()
		current += increment
		if current > #nodes then
			current = 1
		end
		changeField(enemyId, "currentNode", current)
	end
end

function EnemyAI.nearestPlayerInLOS(enemyId)
	local enemyModel = getField(enemyId, "model")
	local LineOfSight = enemyModel:FindFirstChild("LineOfSight")
	if not LineOfSight then return nil end

	local hrp = enemyModel.HumanoidRootPart
	local maxRange = LineOfSight.Size.Z
	local halfAngle = math.atan((LineOfSight.Size.X / 2) / LineOfSight.Size.Z)

	local nearestPlayer = nil
	local nearestDist = math.huge

	-- build filter once, excluding all enemies
	local enemyModels = {enemyModel}
	for id, data in pairs(EnemyAI.Enemies) do
		if data.model then
			table.insert(enemyModels, data.model)
		end
	end

	for _, player in pairs(playerService:GetPlayers()) do
		if not player.Character then continue end
		local playerHRP = player.Character:FindFirstChild("HumanoidRootPart")
		if not playerHRP then continue end

		local toPlayer = playerHRP.Position - hrp.Position
		local distance = toPlayer.Magnitude

		if distance > maxRange then continue end

		local forward = hrp.CFrame.LookVector
		local angle = math.acos(math.clamp(forward:Dot(toPlayer.Unit), -1, 1))
		if angle > halfAngle then continue end

		local rayParams = RaycastParams.new()
		table.insert(enemyModels, player.Character)
		rayParams.FilterDescendantsInstances = enemyModels
		rayParams.FilterType = Enum.RaycastFilterType.Exclude

		local result = workspace:Raycast(hrp.Position, toPlayer, rayParams)

		-- also cast upward to catch players standing on top of enemy
		local toPlayerUp = (playerHRP.Position + Vector3.new(0, 5, 0)) - hrp.Position
		local resultUp = workspace:Raycast(hrp.Position, toPlayerUp, rayParams)

		if (result == nil or resultUp == nil) and distance < nearestDist then
			nearestDist = distance
			nearestPlayer = player
		end

		table.remove(enemyModels, #enemyModels)
	end

	return nearestPlayer
end

--Enemy chases after player mindlessly 
function EnemyAI.StealthEnemyChase(player, enemyId)
	--print("stealth enemy chasing")

	--print(player)
	if player == nil then return end
	local character = player.Character
	if not character then return end
	local hrp = character.HumanoidRootPart
	local enemyModel = EnemyAI.Enemies[enemyId].model
	local enemyHumanoid = enemyModel.Humanoid
	changeField(enemyId, "lastSeen", hrp.Position)
	enemyHumanoid:MoveTo(hrp.Position)
end

--abstraction yay
function EnemyAI.StealthEnemyUpdateFlags(enemyId)
	local nearestPlayer = EnemyAI.nearestPlayerInLOS(enemyId)
	--if there is a valid player in LOS
	if nearestPlayer ~= nil then
		changeField(enemyId, "state", "chase")
		changeField(enemyId, "lastStateChange", os.clock())
		changeField(enemyId, "targetPlayer", nearestPlayer)
		local pChar = nearestPlayer.Character
		if not pChar then return end
		local prhrp = pChar.HumanoidRootPart
		local pos = prhrp.Position
		changeField(enemyId, "lastSeen", pos)

	--executes if nearest player is nil, sends enemy into lost state (skipped if player isnt nil)
	elseif getField(enemyId, "state") == "chase" then
		if os.clock() - getField(enemyId, "lastStateChange") < getField(enemyId, "searchDuration") then return end
		changeField(enemyId, "state", "lost")
		changeField(enemyId, "lastStateChange", os.clock())

		changeField(enemyId, "targetPlayer", nil)
	end
end
function EnemyAI.StealthEnemyAct(enemyId, state)
	if state == "patrol" then
		--print("patrolling")
		if getField(enemyId, "currentAction") ~= "patrolling" then
			task.spawn(function()
				changeField(enemyId, "currentAction", "patrolling")
				EnemyAI.StealthEnemyPatrol(enemyId)
			end)
		end
	elseif state == "chase" then
		changeField(enemyId, "currentAction", "chasing")
		--print("in chase")
		local target = getField(enemyId, "targetPlayer")
		EnemyAI.StealthEnemyChase(target, enemyId)
	elseif state == "lost" then
		local lastSeenPos = getField(enemyId, "lastSeen")
		local enemyModel = getField(enemyId, "model")
		local humanoid = enemyModel:FindFirstChild("Humanoid")
		local hrp = enemyModel:FindFirstChild("HumanoidRootPart")
		--makes sure not creating multiple coroutines
		if getField(enemyId, "currentAction") ~= "searching" then
			task.spawn(function()
				changeField(enemyId, "currentAction", "searching")
				while getField(enemyId, "state") == "lost" do
					--print(lastSeenPos)
					humanoid:MoveTo(lastSeenPos)
					humanoid.MoveToFinished:Wait()
					task.wait(1)
					print("last seen pos reached")
					if (hrp.Position - lastSeenPos).Magnitude < 10 then break end
				end
				changeField(enemyId, "state", "patrol")
			end)
		end
	end
end
--#endregion

--calls appropriate logic for an enemy based on its type
function EnemyAI.updateEnemy(enemyId, enemyType)
	EnemyAI[enemyType](enemyId)
end
--#endregion

return EnemyAI