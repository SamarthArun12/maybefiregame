--EnemyAI MS, all info and functions to make enemy ai work
local EnemyAI = {}

local playerService = game:GetService("Players")
local rs = game:GetService("ReplicatedStorage")
local weaponModules = rs:WaitForChild("WeaponModules")

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
        reqUpdate = false,
        attackRange = 5,
        effectiveRange = 8,
        attackCooldown = 0.8,
        lastAttackTime = 0,
        weaponName = "Sword",
        activeThreads = {} -- Stores [threadObject] = "behaviorName" purely for debug visibility
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
        reqUpdate = true,
        attackRange = 5,
        effectiveRange = 8,
        attackCooldown = 0.8,
        lastAttackTime = 0,
        weaponName = "Sword",
        activeThreads = {} -- Stores [threadObject] = "behaviorName" purely for debug visibility
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
        if k == "activeThreads" then
            temp[k] = {} -- Give each enemy instance its own fresh thread tracking dictionary
        else
            temp[k] = v
        end
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
    local enemy = EnemyAI.Enemies[enemyId]
    local enemyModel = enemy and enemy.model
    EnemyAI.Enemies[enemyId] = nil
    task.wait(2.5)
    if enemyModel then
        enemyModel:Destroy()
    end
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
        
        local hrp = enemyModel:FindFirstChild("HumanoidRootPart")
        local pHrp = player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp or not pHrp then continue end

        local ePos = hrp.Position
        local pPos = pHrp.Position
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

    local hrp = enemyModel:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
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
    local enemy = EnemyAI.Enemies[enemyId]
    if not enemy then return end

    local enemyModel = enemy.model
    if not enemyModel then return end
    local humanoid = enemyModel:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
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
        local runningThread = coroutine.running()
        enemy.activeThreads[runningThread] = "navigating"

        while current >= 1 and current <= #nodes do
            if enemy.currentAction ~= "navigating" then break end
            if nodePath:GetAttribute("endZone") ~= enemy.targetZone.Name and nodePath:GetAttribute("startZone") ~= enemy.targetZone.Name then break end
            
            local currentTarget = nodes[current]
            humanoid:MoveTo(currentTarget.Position)
            humanoid.MoveToFinished:Wait()
            
            current += increment
        end

        enemy.activeThreads[runningThread] = nil
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
    if not zones or not player.Character then return nil, nil end
    
    local enemyHrp = enemyModel:FindFirstChild("HumanoidRootPart")
    local playerHrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not enemyHrp or not playerHrp then return nil, nil end

    local enemyZone = nil
    local playerZone = nil
    for i, zone in pairs(zones:GetChildren()) do
        if inZone(playerHrp.Position, zone) then
            playerZone = zone
        end
        if inZone(enemyHrp.Position, zone) then
            enemyZone = zone
        end
    end
    return playerZone, enemyZone
end
--#endregion

--Specific enemy behaviors such as patrolling, chasing, etc.
--#region Enemy Behaviors
local Behaviors = {}

function Behaviors.AttackTarget(enemyId, player, enemyType)
    local enemy = EnemyAI.Enemies[enemyId]
    if not enemy or not enemy.model then return end
    local enemyModel = enemy.model

    local moduleScript = weaponModules:FindFirstChild(enemy.weaponName or "Sword")
    if not moduleScript then return end
    local weaponModule = require(moduleScript)

    enemy.currentAction = "attacking"
    enemy.state = "attack"

    task.spawn(function()
        local runningThread = coroutine.running()
        enemy.activeThreads[runningThread] = "attacking"

        local enemyHumanoid = enemyModel:FindFirstChildOfClass("Humanoid")
        local enemyHrp = enemyModel:FindFirstChild("HumanoidRootPart")
        if enemyHrp and enemyHumanoid then
            enemyHumanoid:MoveTo(enemyHrp.Position) -- Halt movement while swinging
        end

        while enemy.currentAction == "attacking" do
            local currentEnemy = EnemyAI.Enemies[enemyId]
            if not currentEnemy or not currentEnemy.model or currentEnemy.state ~= "attack" then break end

            local char = player.Character
            local targetHrp = char and char:FindFirstChild("HumanoidRootPart")
            local currentEnemyHrp = currentEnemy.model:FindFirstChild("HumanoidRootPart")
            if not targetHrp or not currentEnemyHrp then break end

            local distance = (targetHrp.Position - currentEnemyHrp.Position).Magnitude
            
            -- If the target slips past our maximum combat range boundary
            if distance > (currentEnemy.effectiveRange or 8) then
                currentEnemy.currentAction = nil
                currentEnemy.state = nil
                -- Instantly bounce evaluation duties back to the designated module manager
                EnemyAI[enemyType](enemyId)
                break
            end

            -- Combat logic ticks and calls upon weapon system
            local timeSinceLastAttack = os.clock() - (currentEnemy.lastAttackTime or 0)
            if timeSinceLastAttack >= (currentEnemy.attackCooldown or 1) then
                weaponModule.activateEnemy(enemyModel)
                currentEnemy.lastAttackTime = os.clock()
            end

            task.wait(0.1)
        end

        enemy.activeThreads[runningThread] = nil
    end)
end

function Behaviors.ChasePlayer(enemyId, player, enemyType)
    local enemy = EnemyAI.Enemies[enemyId]
    if not enemy or not enemy.model then return end

    enemy.currentAction = "chasing"
    task.spawn(function()
        local runningThread = coroutine.running()
        enemy.activeThreads[runningThread] = "chasing"

        while enemy.currentAction == "chasing" do
            local currentEnemy = EnemyAI.Enemies[enemyId]
            if not currentEnemy or not currentEnemy.model then break end
            
            local enemyHumanoid = currentEnemy.model:FindFirstChildOfClass("Humanoid")
            if not enemyHumanoid or currentEnemy.targetPlayer ~= player then break end

            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local enemyHrp = currentEnemy.model:FindFirstChild("HumanoidRootPart")
            if not hrp or not enemyHrp then break end

            local distance = (hrp.Position - enemyHrp.Position).Magnitude

            -- If we are within valid reach thresholds, execute state upgrade immediately inside the thread
            if distance <= (currentEnemy.attackRange or 5) then
                currentEnemy.currentAction = "attacking"
                currentEnemy.state = "attack"
                EnemyAI[enemyType](enemyId)
                break
            end

            enemyHumanoid:MoveTo(hrp.Position)
            task.wait(0.1)
        end

        enemy.activeThreads[runningThread] = nil
    end)
end

function Behaviors.Patrol(enemyId)
    local enemy = EnemyAI.Enemies[enemyId]
    if not enemy or not enemy.model then return end
    local enemyModel = enemy.model

    local pathName = enemyModel:GetAttribute("AssignedPath")
    local room = enemyModel.Parent
    if not room or not room:FindFirstChild("PatrolPaths") then return end

    local path = room.PatrolPaths:FindFirstChild(pathName)
    local humanoid = enemyModel:FindFirstChildOfClass("Humanoid")
    if not path or not humanoid then return end
    
    local nodes = path:GetChildren()
    table.sort(nodes, function(a, b)
        return tonumber(a.Name) < tonumber(b.Name)
    end)
    

    local current = getField(enemyId, "currentNode") or 1
    local increment = 1
    
    task.spawn(function()
        local runningThread = coroutine.running()
        enemy.activeThreads[runningThread] = "patrolling"

        while current >= 1 and current <= #nodes do
            if enemy.state ~= "patrol" then break end
            if not EnemyAI.Enemies[enemyId] or not EnemyAI.Enemies[enemyId].model then return end
            local currentTarget = nodes[current]

            humanoid:MoveTo(currentTarget.Position)
            humanoid.MoveToFinished:Wait()

            if enemy.state ~= "patrol" then break end
            current += increment
            if current > #nodes then
                current = 1
            end
            changeField(enemyId, "currentNode", current)
        end

        enemy.activeThreads[runningThread] = nil
    end)
end

function Behaviors.NavToZone(enemyId, room, currentZone, targetZone)
    local nodePathsFolder = room:FindFirstChild("NodePaths")
    if not nodePathsFolder then return end
    local nodePaths = nodePathsFolder:GetChildren()

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
    
    task.spawn(function()
        local runningThread = coroutine.running()
        enemy.activeThreads[runningThread] = "investigating"

        humanoid:MoveTo(position)
        
        while enemy.currentAction == "investigating" do
            if enemy.state ~= "investigate" then 
                break 
            end
            task.wait(0.5)
        end

        enemy.activeThreads[runningThread] = nil
    end)
end
--#endregion

--Acc managers for each enemy type, called in EnemyAI.updateEnemy
--#region Enemy Type Managers
function EnemyAI.RegularEnemy(enemyId)
    local enemy = EnemyAI.Enemies[enemyId]
    if not enemy or not enemy.model then return end
    local enemyModel = enemy.model

    local nearestP = nearestPlayer(enemyId)
    local prevTarget = enemy.targetPlayer
    enemy.targetPlayer = nearestP
    if prevTarget ~= nearestP then
        enemy.reqUpdate = true
    end
    if not nearestP then return end

    local prevZone = enemy.targetZone
    local playerZone, enemyZone = getZones(enemyModel.Parent, nearestP, enemyModel)
    if not playerZone or not enemyZone then return end
    enemy.targetZone = playerZone

    if prevZone ~= playerZone then
        enemy.reqUpdate = true
    end

    if playerZone == enemyZone then
        -- If an internal thread shifted us to attack mode, make sure we actually boot the behavior
        if enemy.state == "attack" and enemy.currentAction == "attacking" then
            -- Check if an attacking thread is already registered in our debug table
            local hasAttackThread = false
            for _, behavior in pairs(enemy.activeThreads) do
                if behavior == "attacking" then
                    hasAttackThread = true
                    break
                end
            end
            if not hasAttackThread then
                enemy.reqUpdate = true
            end
        elseif enemy.state ~= "chase" and enemy.state ~= "attack" then
            enemy.currentAction = "chasing"
            enemy.state = "chase"
            enemy.reqUpdate = true
        end
    else
        local oldState = enemy.state
        local oldAction = enemy.currentAction
        enemy.currentAction = "navigating"
        enemy.state = "navigate"
        if oldState ~= enemy.state or oldAction ~= enemy.currentAction then
            enemy.reqUpdate = true
        end
    end
    
    if enemy.reqUpdate == true then
        enemy.reqUpdate = false
        if enemy.state == "chase" then
            Behaviors.ChasePlayer(enemyId, nearestP, "RegularEnemy")
        elseif enemy.state == "attack" then
            Behaviors.AttackTarget(enemyId, nearestP, "RegularEnemy")
        elseif enemy.state == "navigate" then
            Behaviors.NavToZone(enemyId, enemyModel.Parent, enemyZone, playerZone)
        end
    end
end
function EnemyAI.StealthEnemy(enemyId)
    local enemy = EnemyAI.Enemies[enemyId]
    if not enemy or not enemy.model then return end

    local nearestP = nearestPlayerInLOS(enemyId)
    local prevTarget = enemy.targetPlayer
    if prevTarget ~= nearestP then
        enemy.reqUpdate = true
    end

    local oldState = enemy.state
    local oldAction = enemy.currentAction

    if nearestP then
        enemy.lastStateChange = os.clock()
        enemy.lastSeenTime = os.clock()
        
        local hrp = nearestP.Character and nearestP.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            enemy.lastKnownPos = hrp.Position
        end
        enemy.targetPlayer = nearestP

        -- If internal thread declared an attack state, check if the thread actually exists
        if enemy.state == "attack" and enemy.currentAction == "attacking" then
            local hasAttackThread = false
            for _, behavior in pairs(enemy.activeThreads) do
                if behavior == "attacking" then
                    hasAttackThread = true
                    break
                end
            end
            if not hasAttackThread then
                enemy.reqUpdate = true
            end
        elseif enemy.state ~= "chase" and enemy.state ~= "attack" then
            enemy.currentAction = "chasing"
            enemy.state = "chase"
            enemy.reqUpdate = true
        end
    else
        if enemy.lastSeenTime and os.clock() - enemy.lastSeenTime < enemy.attentionSpan then
            if enemy.state ~= "chase" and enemy.state ~= "attack" then
                enemy.state = "chase"
                enemy.currentAction = "chasing"
                enemy.reqUpdate = true
            end
            enemy.lastStateChange = os.clock()
            
            nearestP = prevTarget
            if not nearestP then return end
            local hrp = nearestP.Character and nearestP.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                enemy.lastKnownPos = hrp.Position
            end
        elseif os.clock() - enemy.lastStateChange <= enemy.searchDuration and (oldState == "chase" or oldState == "investigate") then
            enemy.currentAction = "investigating"
            enemy.state = "investigate"
            if oldState ~= enemy.state or oldAction ~= enemy.currentAction then
                enemy.reqUpdate = true
            end
        else
            enemy.currentAction = "patrolling"
            enemy.state = "patrol"
            if oldState ~= enemy.state or oldAction ~= enemy.currentAction then
                enemy.reqUpdate = true
            end
        end
    end

    if enemy.reqUpdate == true then
        enemy.reqUpdate = false
        print("state: " .. enemy.state .. " action: " .. enemy.currentAction)
        if enemy.state == "chase" then
            Behaviors.ChasePlayer(enemyId, nearestP, "StealthEnemy")
        elseif enemy.state == "attack" then
            Behaviors.AttackTarget(enemyId, nearestP, "StealthEnemy")
        elseif enemy.state == "investigate" then
            if enemy.lastKnownPos then
                Behaviors.investigate(enemyId, enemy.lastKnownPos)
            end
        elseif enemy.state == "patrol" then
            Behaviors.Patrol(enemyId)
        end
    end
end
--#endregion

--calls appropriate logic for an enemy based on its type
function EnemyAI.updateEnemy(enemyId, enemyType)
    if EnemyAI[enemyType] then
        EnemyAI[enemyType](enemyId)
    end
end

return EnemyAI