local RE = game.ReplicatedStorage.RemoteEvents:WaitForChild("MeleeEvent")
local ModulesFolder = game.ReplicatedStorage:WaitForChild("WeaponModules")

RE.OnServerEvent:Connect(function(player, char, weapon, combo)
	print("event received")
	local moduleName = weapon.Name
	print(moduleName)
	if not moduleName then return end

	local weaponModule = require(ModulesFolder:FindFirstChild(moduleName))
	print(weaponModule)
	weaponModule.activateServer(player, char, weapon, combo)
end)