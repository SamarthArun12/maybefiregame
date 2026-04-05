local RS = game:GetService("ReplicatedStorage")
local event = RS.BindableEvents:WaitForChild("SpawnEnemy")
local event2 = game.ReplicatedStorage.BindableEvents:WaitForChild("EnemyDeath")
local enemyStats = require(game.ServerStorage.EnemyStats)
local EnemyAI = require(game.ServerStorage.EnemyAI)

local EnemyId = 0

--Part used for spawn location, enemyName to assign it correct AI, id for the source part's id
event.Event:Connect(function(part, enemyName, id)
	print("Received spawn event!")
	local enemy = RS.Enemies:FindFirstChild(enemyName)
	print(enemyName)
	if not enemy then return end
	local enemyType = enemy:GetAttribute("Type")
	
	local pos = part.Position + Vector3.new(0, 1, 0)
	local enemyClone = enemy:Clone()
	
	--print(enemyClone:GetAttributes())
	
	enemyClone:SetAttribute("SourceId", id)
	enemyClone:SetAttribute("EnemyId", EnemyId)
	enemyClone:SetAttribute("Affiliation", "Enemy")
	if enemyType == "StealthEnemy" then
		enemyClone:SetAttribute("AssignedPath", "PatrolPath1")
	end
	EnemyId += 1
	
	--task.spawn stuff ai generated
	enemyStats.newEnemy(EnemyId)
	EnemyAI.newEnemy(EnemyId, enemyClone, enemyType)
	enemyClone.Parent = workspace.AITestRoom
	enemyClone:SetPrimaryPartCFrame(CFrame.new(pos))
	
	local capturedId = EnemyId
	local capturedType = enemyType
	local source = id
	task.spawn(function()
		local humanoid = enemyClone:FindFirstChild("Humanoid")
		humanoid.Died:Connect(function()
			EnemyAI.removeEnemy(capturedId)
			event2:Fire(source)
		end)
		task.wait(1)
		while enemyClone and humanoid.Health > 0 do
			EnemyAI.updateEnemy(capturedId, capturedType)
			task.wait(0.1)
		end
	end)
	
	--print("Spawned enemy!")
end)

while true do
	task.wait(0.5)
	local enemies = enemyStats.getEnemies()
	for _, enemy in pairs(enemies) do
		enemyStats.recalculateAC(enemy)
	end
end