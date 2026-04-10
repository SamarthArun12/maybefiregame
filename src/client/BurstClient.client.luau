local UIS = game:GetService("UserInputService")
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
player.CharacterAdded:Connect(function(char)character = char end)

local canPlay = player:GetAttribute("CanPlay")
while not canPlay do
	task.wait(0.1)
	canPlay = player:GetAttribute("CanPlay")
end
local folderName = player.Name.."Folder"
local folder = game.ReplicatedStorage.PlayerFolders:WaitForChild(folderName)
local playerItems = folder:GetChildren()
for i, v in ipairs(playerItems) do
	if v:IsA("Tool") then
		v:SetAttribute("HotbarSlot", i)
	end
end

local current = "None"

player:GetAttributeChangedSignal("CanPlay"):Connect(function()
	canPlay = player:GetAttribute("CanPlay")
end)

--make sure cost + cd are server validated b4 publish
UIS.InputBegan:Connect(function(input, processed)
	if processed then return end
	if not canPlay then return end
	local event = game.ReplicatedStorage.RemoteEvents:WaitForChild("BurstTechActivate")
	local burstScripts = game.ReplicatedStorage:WaitForChild("BurstScripts")
	local burstScript = require(burstScripts:WaitForChild(player:GetAttribute("BurstTech")))
	local cooldownTime = burstScript.cooldown
	local lastAttackTime = 0
	local cost = burstScript.cost
	local stat = burstScript.stat
	
	if input.KeyCode == Enum.KeyCode.Q  then
		local currentTime = os.clock()
		print("burst tech pressed")

		if currentTime - lastAttackTime < cooldownTime then
			return
		end
		
		local equippedSlot = player:GetAttribute("EquippedSlot")
		local equippedItem = playerItems[equippedSlot]
		
		if equippedItem:GetAttribute("PrimaryStat") ~= stat then 
			print("current:"..equippedItem:GetAttribute("PrimaryStat"))
			print("required: "..stat)
			return 
		else
			local stored = tonumber(equippedItem:GetAttribute("Stored"))
			if stored > cost then
				print(stored)
				print(cost)
				-- set stat -= 30 on server later

				lastAttackTime = currentTime
				
				burstScript.clientChanges(character)
				
				local BurstTech = player:GetAttribute("BurstTech")
				event:FireServer(current)
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
