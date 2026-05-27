local HealthBurst = {}

HealthBurst.name = "Health Burst"
HealthBurst.cost = 30
HealthBurst.cooldown = 0.5
HealthBurst.stat = "MaxHealth"
HealthBurst.animationId = "rbxassetid://139580504376878"

function HealthBurst.clientChanges(character)
	local humanoid = character:FindFirstChild("Humanoid")
	local animation = HealthBurst.animationId
	local animator = humanoid:WaitForChild("Animator")
	local anim = Instance.new("Animation")
	anim.AnimationId = animation
	local track = animator:LoadAnimation(anim)
	track:Play()
end

function HealthBurst.activate(player)
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
    hitbox.Size = Vector3.new(25,25,25)
    hitbox.CFrame = root.CFrame * CFrame.new(0, 0, 0)
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
            partHumanoid:TakeDamage(20 * critDamage)
            hitHumanoids[partHumanoid] = true
        end
    end
    for i, v in pairs(hitHumanoids) do
        --dont want self heal scaling too much
        humanoid.Health += 5 * (critDamage/2)
    end

    game:GetService("Debris"):AddItem(hitbox, 0.1)
end

return HealthBurst
