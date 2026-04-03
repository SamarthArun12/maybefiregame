local player = game:GetService("Players"):WaitForChild(script:GetAttribute("Player")) or "None"
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local event = game.ReplicatedStorage.RemoteEvents:WaitForChild("StoreBurnInput")
local event2 = game.ReplicatedStorage.RemoteEvents:WaitForChild("StoreBurnActivateRE")
local playerStats = require(game.ServerStorage:WaitForChild("PlayerStats"))
local dt = 0.05

local rate = 0.5
local storing = false
local burning = false
local stat = "None"
local secondary = "None"
local sideAffect = "None"
local stored, ceiling, tool, on
local mult_cap = 9
local mult_floor = 1
local mult = 1
local LastPrint = 0

local StatsFolder = game.ServerStorage.StatChanges:GetChildren()
local statsModules = {}
for i, v in pairs(StatsFolder) do
	statsModules[v.Name] = require(v)
end

--Fix issue where burning health at a really low mult is the optimal way to use health storing/burning
--because it the store depletes really slowly at a 0.25x mult and you still heal really fast
function change_stats(humanoid, mode, mult, primary, secondary, side, toggle)
	local IncDec
	if mode == "store" then
		IncDec = "Dec"
	else
		IncDec = "Inc"
	end
	
	local prim = statsModules[primary]
	local sec
	if secondary ~= nil then
		sec = statsModules[secondary]
	end
	local sideAffect = statsModules[side]

	prim.change(humanoid, mult, true, IncDec, toggle)
	if secondary ~= nil then
		sec.change(humanoid, mult, false, IncDec, toggle)
	end
	if mode == "burn" then
		sideAffect.change(humanoid, mult, false, "Dec", toggle)
	end
end

event.OnServerEvent:Connect(function(player, action, current, inMult, toggle, sorb)
	if player == "None" then return end

	print("Received! " .. "Action: " .. tostring(action) .. ", Tool: " .. tostring(current) .. ", Mult: " .. tostring(inMult)  .. ", On/Off: " .. tostring(toggle))

	if current ~= "None" then
		stored = current:GetAttribute("Stored")
		ceiling = current:GetAttribute("Ceiling")
		mult = current:GetAttribute("Mult")
		tool = current
		LastPrint = stored
		on = toggle

		stat = current:GetAttribute("PrimaryStat")
		secondary = current:GetAttribute("SecondaryStat")
		sideAffect = current:GetAttribute("SideAffect")

		if action == "storing" then
			change_stats(humanoid, "store", mult, stat, secondary, sideAffect, toggle)
			storing = toggle

		elseif action == "burning" then
			change_stats(humanoid, "burn", mult, stat, secondary, sideAffect, toggle)
			burning = toggle

		elseif action == "mult change" then
			mult = inMult and mult + 1 or mult - 1

			if mult < mult_floor then
				mult = mult_floor
			elseif mult > mult_cap then
				mult = mult_cap
			end

			tool:SetAttribute("Mult", mult)
			print(mult)
			
			if sorb == "s" then
				change_stats(humanoid, "store", mult, stat, secondary, sideAffect, toggle)
			end
			if sorb == "b" then
				change_stats(humanoid, "burn", mult, stat, secondary, sideAffect, toggle)
			end
		end

		wasStoring = storing
		wasBurning = burning

	else
		stat = "None"
		print("no changing aha")
		print(current)
		wasStoring = false
		wasBurning = false
	end

end)

while true do
	task.wait(dt)
	local isActive = storing or burning
	if player == "None" then continue end
	if isActive == false then continue end
	if stat ~= "None" and tool and tool.Parent then

		local changed = false

		if storing and stored < ceiling then
			stored = math.min(stored + mult * dt * rate, ceiling)
			changed = true

		elseif burning and stored > 0 then
			stored = math.max(stored - mult * dt * rate, 0)
			changed = true
		end

		if stored == ceiling then
			storing = false
			playerStats.resetSB(player)
		end
		if stored == 0  then
			burning = false
			playerStats.resetSB(player)
		end

		if changed then
			tool:SetAttribute("Stored", stored)
		end

		if storing and on == false then
			print("Storing has ended!")
			wasStoring = false
		elseif burning and on == false then
			print("Burning has ended!")
			wasBurning = false
		end


		if math.abs(stored - LastPrint) >= 0.25 then
			stored = math.round(stored / 0.25) * 0.25
			--print(stored)
			LastPrint = stored
			--print(stored)
			event2:FireClient(player, tool)
		end
	end
end

game.Players.PlayerRemoving:Connect(function(plr)
	if plr == player and player ~= "None" then
		script:Destroy()
	end
end)