local UIS = game:GetService("UserInputService")
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
player.CharacterAdded:Connect(function(char)character = char end)
local event = game.ReplicatedStorage.RemoteEvents:WaitForChild("StoreBurnInput")
local event2 = game.ReplicatedStorage.RemoteEvents:WaitForChild("EquippedChanged")
local event3 = game.ReplicatedStorage.BindableEvents:WaitForChild("StoreBurnActivate")

task.wait(0.25)
local playerItems = game:GetService("StarterPack"):GetChildren()
--Lines 11-13 AI generated
table.sort(playerItems, function(a, b)
	return a.Name < b.Name
end)
for i, v in ipairs(playerItems) do
	if v:IsA("Tool") then
		v:SetAttribute("HotbarSlot", i)
	end
end
print(playerItems)

local current = nil
local storing = false
local burning = false
local mult_inc = false

local action = nil
local send = false

local toggle = false

local canPlay = player:GetAttribute("CanPlay")

player:GetAttributeChangedSignal("CanPlay"):Connect(function()
	canPlay = player:GetAttribute("CanPlay")
end)

player:GetAttributeChangedSignal("EquippedSlot"):Connect(function()
	storing = false
	burning = false
	toggle = false

	event:FireServer("storing", current, false, false)
	event:FireServer("burning", current, false, false)
end)

UIS.InputBegan:Connect(function(input, processed)
	if processed then return end
	if not canPlay then return end
	local sorb = false

	--Storing 
	if input.KeyCode == Enum.KeyCode.R then
		action = "storing"
		if storing == true then
			storing = false
			burning = false
			toggle = false
		else
			storing = true
			burning = false
			toggle = true
		end
		send = true

		--Burning	
	elseif input.KeyCode == Enum.KeyCode.E then
		action = "burning"
		if burning == true then
			burning = false
			storing = false
			toggle = false
		else
			burning = true
			storing = false
			toggle = true
		end
		send = true

		--Mult decrease
	elseif input.KeyCode == Enum.KeyCode.C then
		mult_inc = false
		action = "mult change"
		toggle = true
		send = true
		if storing then
			sorb = "s"
		elseif burning then
			sorb = "b"
		end

		--Mult increaase
	elseif input.KeyCode == Enum.KeyCode.V then
		mult_inc = true
		action = "mult change"
		toggle = true
		send = true
		if storing then
			sorb = "s"
		elseif burning then
			sorb = "b"
		end
		
	elseif input.KeyCode == Enum.KeyCode.F then
		print("sent change equip")
		event2:FireServer(current)
	end
	
	
	--Tool checking
	local activeNum = player:GetAttribute("EquippedSlot")
	local inHand = player:GetAttribute("Equipped")
	local current_tool
	if inHand == "Weapon" then
		local weaponInUse = player:GetAttribute("WeaponName")
		current_tool = character:WaitForChild(weaponInUse)
	elseif inHand == "Offhand" then
		current_tool = playerItems[activeNum]
	end
	if current_tool then
		current = current_tool
	else
		current = "None"
	end
	
	--Fire info
	if send == true then
		event:FireServer(action, current, mult_inc, toggle, sorb)
		event3:Fire(player, current)
		send = false
		--Print is ai generated
		print("Sent! " .. "Action: " .. tostring(action) .. ", Tool: " .. tostring(current) .. ", MultChange: " .. tostring(mult_inc) .. ", On/Off: " .. tostring(toggle) .. ", SorB: " .. tostring(sorb))
		toggle = false
	end
end)