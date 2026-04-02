local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local RS = game.ReplicatedStorage
local RE = RS.RemoteEvents:WaitForChild("MeleeEvent")
local ModulesFolder = RS:WaitForChild("WeaponModules")

local character = player.Character or player.CharacterAdded:Wait()
local weapon_name = player:GetAttribute("WeaponName")
local weapon = RS:WaitForChild("Weapons"):WaitForChild(weapon_name)
local humanoid = character:WaitForChild("Humanoid")

-- Load weapon module
local weaponModule = require(ModulesFolder:FindFirstChild(weapon_name))

local cooldownTime = weaponModule.AttackCD
local lastAttackTime = 0
local combo = 1
local window = weaponModule.ComboWindow
local maxCombo = weaponModule.ComboNum

local canPlay = player:GetAttribute("CanPlay")
player:GetAttributeChangedSignal("CanPlay"):Connect(function()
	canPlay = player:GetAttribute("CanPlay")
end)

mouse.Button1Down:Connect(function()
	if not canPlay then return end

	local currentTime = os.clock()
	if currentTime - lastAttackTime < cooldownTime then
		return
	end

	weaponModule.activateClient(humanoid, combo)

	-- Combo logic
	if currentTime - lastAttackTime <= window then
		combo += 1
		if combo > maxCombo then
			combo = 1
		end
	else
		combo = 1
	end
	lastAttackTime = currentTime

	RE:FireServer(player.Character, weapon, combo)
end)