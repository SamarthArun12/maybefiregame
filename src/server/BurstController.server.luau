local RS = game:GetService("ReplicatedStorage")
local RE = RS.RemoteEvents:WaitForChild("BurstTechActivate")
local burstScripts = RS:WaitForChild("BurstScripts")

RE.OnServerEvent:Connect(function(player, current, pos)
	local burstScript = require(burstScripts:WaitForChild(player:GetAttribute("BurstTech")))
	burstScript.activate(player, pos)
end)

