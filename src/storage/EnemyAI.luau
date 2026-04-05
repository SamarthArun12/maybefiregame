local EnemyAI = {}

local playerService = game:GetService("Players")

--#region Enemy Management
EnemyAI.Enemies = {}
local EnemyDefaults = {
	RegularEnemy = {
		model = nil,
	},
	StealthEnemy = {
		model = nil,
		state = "patrol",
		currentNode = 1
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
	print(type, EnemyDefaults[type])
	local temp = cloneTable(EnemyDefaults[type])
	temp.model = enemyModel

	EnemyAI.Enemies[enemyId] = temp
end
function EnemyAI.removeEnemy(enemyId)
	EnemyAI.Enemies[enemyId] = nil
end
--#endregion

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
		if player.Character == nil then continue end
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
	local hrp = character.HumanoidRootPart
	local enemyModel = getField(enemyId, "model")
	local enemyHumanoid = enemyModel.Humanoid
	enemyHumanoid:MoveTo(hrp.Position)
end
--#endregion

--#enemy ai meant to have been hand placed, and assigned a patrol path by hand
--#region StealthEnemy AI
local patrolling = {}
local chasing = {}

function EnemyAI.StealthEnemy(enemyId)
	local currentState = getField(enemyId, "state")
	local nearestPlayer = EnemyAI.nearestPlayerInLOS(enemyId)
	if nearestPlayer ~= nil and currentState == "patrol" then
		changeField(enemyId, "state", "chase")
		chasing[enemyId] = nearestPlayer
	end

	currentState = getField(enemyId, "state")
	if currentState == "patrol" then
		if not patrolling[enemyId] then
			task.spawn(function()
				patrolling[enemyId] = true
				EnemyAI.StealthEnemyPatrol(enemyId)
			end)
		end
	elseif currentState == "chase" then
		patrolling[enemyId] = false
		local target = chasing[enemyId]
		EnemyAI.StealthEnemyChase(target, enemyId)
	end
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
		if not patrolling[enemyId] then break end
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
		rayParams.FilterDescendantsInstances = {enemyModel, player.Character}
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		local result = workspace:Raycast(hrp.Position, toPlayer, rayParams)

		if result == nil and distance < nearestDist then
			nearestDist = distance
			nearestPlayer = player
		end
	end

	return nearestPlayer
end

--Enemy chases after player mindlessly
function EnemyAI.StealthEnemyChase(player, enemyId)
	--print("stealth enemy chasing")
	print(player)
	if player == nil then return end
	local character = player.Character
	local hrp = character.HumanoidRootPart
	local enemyModel = EnemyAI.Enemies[enemyId].model
	local enemyHumanoid = enemyModel.Humanoid
	enemyHumanoid:MoveTo(hrp.Position)
end
--#endregion

--calls appropriate logic 
function EnemyAI.updateEnemy(enemyId, enemyType)
	EnemyAI[enemyType](enemyId)
end

return EnemyAI