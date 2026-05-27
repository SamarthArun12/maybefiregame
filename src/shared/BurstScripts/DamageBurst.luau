local DamageBurst = {}

DamageBurst.name = "Damage Burst"
DamageBurst.cost = 20
DamageBurst.cooldown = 0.5
DamageBurst.stat = "DamageMult"
DamageBurst.animationId = "rbxassetid://139580504376878"

function DamageBurst.clientChanges(character)
	local humanoid = character:FindFirstChild("Humanoid")
	local animation = DamageBurst.animationId
	local animator = humanoid:WaitForChild("Animator")
	local anim = Instance.new("Animation")
	anim.AnimationId = animation
	local track = animator:LoadAnimation(anim)
	track:Play()
end

function DamageBurst.activate(player)
    local character = player.Character
    local humanoid = character:FindFirstChild("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    
    local critChance = character:GetAttribute("CritChance") or 0
    
    -- Calculate critical hit multiplier
    local critDamage = 1
    if math.random() <= critChance then
        critDamage = 1 + (character:GetAttribute("CritDamage") or 0)
        print("crit!")
    end

    local hitbox = Instance.new("Part")
    hitbox.Size = Vector3.new(10, 10, 10)
    hitbox.CFrame = root.CFrame * CFrame.new(0, 0, -3)
    hitbox.Transparency = 0.9
    hitbox.Color = Color3.fromRGB(255, 0, 0)
    hitbox.Material = Enum.Material.SmoothPlastic
    hitbox.Anchored = true
    hitbox.CanCollide = false
    hitbox.Parent = workspace

    local hitHumanoids = {}
    for _, part in pairs(workspace:GetPartsInPart(hitbox)) do
        local partHumanoid = part.Parent:FindFirstChild("Humanoid")
        if partHumanoid and partHumanoid ~= humanoid and not hitHumanoids[partHumanoid] then
            -- Scaled damage with critDamage
            partHumanoid:TakeDamage(80 * critDamage)
            hitHumanoids[partHumanoid] = true
        end
    end

    game:GetService("Debris"):AddItem(hitbox, 0.1)
end

return DamageBurst
