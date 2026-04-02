local UIS = game:GetService("UserInputService")
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
player.CharacterAdded:Connect(function(char)character = char end)
local humanoidRoot = character:WaitForChild("HumanoidRootPart")

local event = game.ReplicatedStorage.RemoteEvents:WaitForChild("BurstTechActivate")
local burstScripts = game.ReplicatedStorage:WaitForChild("BurstScripts")
local burstScript = require(burstScripts:WaitForChild(player:GetAttribute("BurstTech")))
local cooldownTime = burstScript.cooldown
local lastAttackTime = 0
local cost = burstScript.cost
local stat = burstScript.stat

local animation = burstScript.animationId
local animator = humanoid:WaitForChild("Animator")
local anim = Instance.new("Animation")
anim.AnimationId = animation
local track = animator:LoadAnimation(anim)

task.wait(0.25)
local playerItems = game:GetService("StarterPack"):GetChildren()
table.sort(playerItems, function(a, b)
	return a.Name < b.Name
end)
for i, v in ipairs(playerItems) do
	if v:IsA("Tool") then
		v:SetAttribute("HotbarSlot", i)
	end
end

local current = "None"

local canPlay = player:GetAttribute("CanPlay")

player:GetAttributeChangedSignal("CanPlay"):Connect(function()
	canPlay = player:GetAttribute("CanPlay")
end)

UIS.InputBegan:Connect(function(input, processed)
	if processed then return end
	if not canPlay then return end
	
	if input.KeyCode == Enum.KeyCode.Q  then
		local currentTime = os.clock()
		print("burst tech pressed")

		if currentTime - lastAttackTime < cooldownTime then
			return
		end
		
		local equippedSlot = player:GetAttribute("EquippedSlot")
		local equippedItem = playerItems[equippedSlot]
		
		if equippedItem:GetAttribute("PrimaryStat") ~= stat then 
			print(equippedItem:GetAttribute("PrimaryStat"))
			print(stat)
			return 
		else
			local stored = tonumber(equippedItem:GetAttribute("Stored"))
			if stored > cost then
				print(stored)
				print(cost)
				-- set stat -= 30 on server later
				track:Play()

				lastAttackTime = currentTime
				
				local pos = humanoidRoot.CFrame
				burstScript.clientChanges(character)
				
				local BurstTech = player:GetAttribute("BurstTech")
				event:FireServer(current, pos)
				print("Sent burst! Tech name: " .. tostring(BurstTech) .. ", From: " .. tostring(player))
				task.delay(cooldownTime, function()
				end)
			else
				print("not enough stored")
			end
		end
	end
	--Tool retrieval
	local activeNum = player:GetAttribute("EquippedSlot")
	local current_tool = playerItems[activeNum]
	if current_tool  then
		current = current_tool
	else
		current = "None"
	end
	
end)
