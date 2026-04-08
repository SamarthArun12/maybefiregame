local RS = game:GetService("ReplicatedStorage")
local RE = RS.RemoteEvents:WaitForChild("BurstTechActivate")
local burstScripts = RS:WaitForChild("BurstScripts")

RE.OnServerEvent:Connect(function(player, current)
	local burstScript = require(burstScripts:WaitForChild(player:GetAttribute("BurstTech")))
	if burstScript.requiresPos then
		local char = player.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local pos = hrp.Position
		burstScript.activate(player, pos)
	else
		burstScript.activate(player)
	end
end)

