local EnemyAI = {}

local playerService = game:GetService("Players")

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
function nearestPlayer(enemyId, players)
	local enemyModel = EnemyAI.Enemies[enemyId]
	local nearestP = nil
	local nearestDist = math.huge
	for i, player in pairs(players) do
		if player.Character == nil then continue end
		if player.Character:GetAttribute("Hidden") == true then continue end
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
function getZones(room, player, enemyModel)
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
function followPath(enemyId, nodePath, direction)
	--print("began following path")
	local enemyModel = EnemyAI.Enemies[enemyId]
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

function navToZone(enemyId, room, currentZone, targetZone)
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

EnemyAI.Enemies = {}
EnemyAI.navigating = {}
EnemyAI.targetZone = {}

function EnemyAI.newEnemy(enemyId, enemyModel)
	EnemyAI.Enemies[enemyId] = enemyModel
end

function EnemyAI.removeEnemy(enemyId)
	EnemyAI.Enemies[enemyId] = nil
end

--regular enemy chases after the player mindlessly
function EnemyAI.RegularEnemyChase(player, enemyId)
	--print("regular enemy chasing")
	local character = player.Character
	local hrp = character.HumanoidRootPart
	local enemyModel = EnemyAI.Enemies[enemyId]
	local enemyHumanoid = enemyModel.Humanoid
	enemyHumanoid:MoveTo(hrp.Position)
end

function EnemyAI.updateEnemy(enemyId, enemyType)
	local players = playerService:GetPlayers()
	local enemyModel = EnemyAI.Enemies[enemyId]
	
	local nearest = nearestPlayer(enemyId, players)
	if not nearest then return end
	
	local playerZone, enemyZone = getZones(enemyModel.Parent, nearest, enemyModel)
	if playerZone == nil or enemyZone == nil then return end
	--print("player is in "..tostring(playerZone).." and enemy is in "..tostring(enemyZone))
	
	if playerZone == enemyZone then
		--print("player and enemy "..enemyId.." are in the same zone")
		EnemyAI.navigating[enemyId] = false
		local funcName = enemyType.."Chase"
		EnemyAI[funcName](nearest, enemyId)
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

return EnemyAI