--EnemyAI MS, all info and functions to make enemy ai work
local EnemyAI = {}

local playerService = game:GetService("Players")

--manages initalization of values, removal on death, etc
--#region Enemy Management
EnemyAI.Enemies = {}
local EnemyDefaults = {
	RegularEnemy = {
		model = nil,
		state = nil,
		currentAction = nil,
		targetPlayer = nil,
		targetZone = nil,
		reqUpdate = false
	},
	StealthEnemy = {
		model = nil,
		--used for deciding which section to execute
		state = "patrol",
		--used for task.spawn flags
		currentAction = "patrolling",
		currentNode = 1,
		targetPlayer = nil,
		lastKnownPos = nil,
		lastSeenTime = nil,
		lastStateChange = nil,
		searchDuration = 5,
		attentionSpan = 2,
		reqUpdate = true
	}
}

local function getField(enemyId, fieldName)
	if not EnemyAI.Enemies[enemyId] then return nil end
	return EnemyAI.Enemies[enemyId][fieldName]
end
local function changeField(enemyId, fieldName, change)
	if not EnemyAI.Enemies[enemyId] then return end
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
	local enemyModel = EnemyAI.Enemies[enemyId].model
	EnemyAI.Enemies[enemyId] = nil
	task.wait(2.5)
	enemyModel:Destroy()
end
--#endregion

--eg followPath, LOS checks, etc. Functions that aren't big enough to deserve their own functions
--in Behaviors, but are still used in multiple places or would make code look cleaner if abstracted 
--#region Utility Functions 
--returns nearest player
local function nearestPlayer(enemyId)
	local enemy = EnemyAI.Enemies[enemyId]
	if not enemy or not enemy.model then return nil end
	local enemyModel = enemy.model
	if not enemyModel then return end
	local players = playerService:GetPlayers()
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
--for enemies with LOS ranges
local function nearestPlayerInLOS(enemyId)
	local enemy = EnemyAI.Enemies[enemyId]
	if not enemy or not enemy.model then return nil end
	local enemyModel = enemy.model
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

--follows designated path in direction, true for start to end, false for end to start
local function followPath(enemyId, nodePath, direction)
	--print("began following path")
	local enemy = EnemyAI.Enemies[enemyId]
	if not enemy then return end

	local enemyModel = enemy.model
	if not enemyModel then return end
	local humanoid = enemyModel.Humanoid
	
	local nodes = nodePath:GetChildren()
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
	
	task.spawn(function()
		while current >= 1 and current <= #nodes do
			-- Check the action: If it's no longer "navigating", drop out!
			if enemy.currentAction ~= "navigating" then break end
			if nodePath:GetAttribute("endZone") ~= enemy.targetZone.Name and nodePath:GetAttribute("startZone") ~= enemy.targetZone.Name then break end
			
			local currentTarget = nodes[current]
			humanoid:MoveTo(currentTarget.Position)
			humanoid.MoveToFinished:Wait()
			
			current += increment
		end
		--print("reached end of path")
	end)
end

--these 2 go as a pair, getZones relies on inZone
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
--#endregion

--Specific enemy behaviors such as patrolling, chasing, etc.
--#region Enemy Behaviors
local Behaviors = {}

function Behaviors.ChasePlayer(enemyId, player)
	--make sure enemy exists
    local enemy = EnemyAI.Enemies[enemyId]
    if not enemy or not enemy.model then return end

    -- Set the action flag and move the engine toward the player
    enemy.currentAction = "chasing"
	--print("chasing player: ", player.Name)
	task.spawn(function()
		while enemy.currentAction == "chasing" do
			if not enemy or not enemy.model then return end
			local enemyHumanoid = enemy.model:FindFirstChildOfClass("Humanoid")
			if not enemyHumanoid then return end
			if enemy.targetPlayer ~= player then break end

			local char = player.Character
			if not char then break end
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if not hrp then break end
    		enemyHumanoid:MoveTo(hrp.Position)
			task.wait(0.1)
		end
		return
	end)
end

function Behaviors.Patrol(enemyId)
	--make sure enemy exists
	local enemy = EnemyAI.Enemies[enemyId]
	if not enemy or not enemy.model then return end
	local enemyModel = enemy.model
	--fetching the path and humanoid
	local pathName = enemyModel:GetAttribute("AssignedPath")
	local room = enemyModel.Parent
	local path = room.PatrolPaths:FindFirstChild(pathName)
	local humanoid = enemyModel:FindFirstChild("Humanoid")
	--getChildren doesn't return in reliable order, so a sort is necessary to make sure nodes are followed in the correct order
	local nodes = path:GetChildren()
	table.sort(nodes, function(a, b)
		return tonumber(a.Name) < tonumber(b.Name)
	end)
	

	local current = getField(enemyId, "currentNode")
	if not current then return end
	local increment = 1
	
	--no need to double check if paths get deleted inside the function b/c there is no event that would cause this.
	--note to self make sure enemies are deleted before room gets deleted during cleanup
	--print("beginning patrol on path: " .. pathName)
	task.spawn(function()
		while current >= 1 and current <= #nodes do
			if enemy.state ~= "patrol" then break end
			if not EnemyAI.Enemies[enemyId] or not EnemyAI.Enemies[enemyId].model then return end
			local currentTarget = nodes[current]

			humanoid:MoveTo(currentTarget.Position)
			humanoid.MoveToFinished:Wait()

			-- Check one more time right after the walk loop
			if enemy.state ~= "patrol" then break end
			current += increment
			if current > #nodes then
				current = 1
			end
			changeField(enemyId, "currentNode", current)
		end
		return
	end)
end

function Behaviors.NavToZone(enemyId, room, currentZone, targetZone)
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

function Behaviors.investigate(enemyId, position)
    local enemy = EnemyAI.Enemies[enemyId]
    if not enemy or not enemy.model then return end
    local humanoid = enemy.model:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    enemy.currentAction = "investigating"
    enemy.state = "investigate"
    
    -- task.spawn lets this loop run in the background without freezing the game!
	--print("investigating position: ", position)
    task.spawn(function()
        -- Walk toward the point once
        humanoid:MoveTo(position)
        
        while enemy.currentAction == "investigating" do
            if enemy.state ~= "investigate" then 
                break 
            end
            
            task.wait(0.5)
        end
    end)
end
--#endregion

--Acc managers for each enemy type, called in EnemyAI.updateEnemy
--#region Enemy Type Managers
function EnemyAI.RegularEnemy(enemyId)
	--getting enemy info
	local enemy = EnemyAI.Enemies[enemyId]
	if not enemy or not enemy.model then return end
	local enemyModel = enemy.model

	--getting the target player
	local nearestP = nearestPlayer(enemyId)
	local prevTarget = enemy.targetPlayer
	enemy.targetPlayer = nearestP
	if prevTarget ~= nearestP then
		enemy.reqUpdate = true
	end
	if not nearestP then return end

	--getting zones
	local prevZone = enemy.targetZone
	local playerZone, enemyZone = getZones(enemyModel.Parent, nearestP, enemyModel)
	if not playerZone or not enemyZone then return end
	enemy.targetZone = playerZone
	--makes sure enemy tracks to new zone if player leaves old. 
	if prevZone ~= playerZone then
		enemy.reqUpdate = true
	end

	--determining behavior and whether an update is needed
	if playerZone == enemyZone then
		local oldState = enemy.state
		local oldAction = enemy.currentAction
		enemy.currentAction = "chasing"
		enemy.state = "chase"
		if oldState ~= enemy.state or oldAction ~= enemy.currentAction then
			enemy.reqUpdate = true
		end
	else
		local oldState = enemy.state
		local oldAction = enemy.currentAction
		enemy.currentAction = "navigating"
		enemy.state = "navigate"
		if oldState ~= enemy.state or oldAction ~= enemy.currentAction then
			enemy.reqUpdate = false
			enemy.reqUpdate = true
		end
	end
	
	--executing behavior if update is needed
	if enemy.reqUpdate == true then
		enemy.reqUpdate = false
		if enemy.state == "chase" then
			Behaviors.ChasePlayer(enemyId, nearestP)
		elseif enemy.state == "navigate" then
			Behaviors.NavToZone(enemyId, enemyModel.Parent, enemyZone, playerZone)
		end
	end
end

function EnemyAI.StealthEnemy(enemyId)
	local enemy = EnemyAI.Enemies[enemyId]
	if not enemy or not enemy.model then return end

	--getting the nearest player in LOS, no check for nil bc if there isn't one, enemy continue patrol
	local nearestP = nearestPlayerInLOS(enemyId)
	local prevTarget = enemy.targetPlayer
	if prevTarget ~= nearestP then
		enemy.reqUpdate = true
	end

	local oldState = enemy.state
	local oldAction = enemy.currentAction

	--determining behavior and whether an update is needed
	--player in LOS
	if nearestP then
		enemy.currentAction = "chasing"
		enemy.state = "chase"
		enemy.lastStateChange = os.clock()
		enemy.lastSeenTime = os.clock()
		enemy.lastKnownPos = nearestP.Character.HumanoidRootPart.Position
		enemy.targetPlayer = nearestP
		if oldState ~= enemy.state or oldAction ~= enemy.currentAction then
			enemy.reqUpdate = true
		end
	--player not currently in LOS
	else
		--dont want enemy to isntantly lose chase on losing LOS
		if enemy.lastSeenTime and os.clock() - enemy.lastSeenTime < enemy.attentionSpan then
			enemy.state = "chase"
			enemy.currentAction = "chasing"
			enemy.lastStateChange = os.clock()
			
			nearestP = prevTarget
			if not nearestP then return end
			enemy.lastKnownPos = nearestP.Character.HumanoidRootPart.Position
		--seen recently within search duration, investigate
		elseif os.clock() - enemy.lastStateChange <= enemy.searchDuration and (oldState == "chase" or oldState == "investigate") then
			enemy.currentAction = "investigating"
			enemy.state = "investigate"
			if oldState ~= enemy.state or oldAction ~= enemy.currentAction then
				enemy.reqUpdate = true
			end
		--not seen recently withing search duration, patrol
		else
			enemy.currentAction = "patrolling"
			enemy.state = "patrol"
			if oldState ~= enemy.state or oldAction ~= enemy.currentAction then
				enemy.reqUpdate = true
			end
		end
	end

	--executing behavior if update is needed
	if enemy.reqUpdate == true then
		enemy.reqUpdate = false
		print("state: " .. enemy.state .. " action: " .. enemy.currentAction)
		if enemy.state == "chase" then
			Behaviors.ChasePlayer(enemyId, nearestP)
		elseif enemy.state == "investigate" then
			Behaviors.investigate(enemyId, enemy.lastKnownPos)
		elseif enemy.state == "patrol" then
			Behaviors.Patrol(enemyId)
		end
	end
end
--#endregion

--calls appropriate logic for an enemy based on its type
function EnemyAI.updateEnemy(enemyId, enemyType)
	EnemyAI[enemyType](enemyId)
end

return EnemyAI