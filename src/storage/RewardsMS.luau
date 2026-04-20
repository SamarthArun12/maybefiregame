Rewards = {}
local RS = game.ReplicatedStorage
local players = game:GetService("Players")
local remote = game.ReplicatedStorage.RemoteEvents:FindFirstChild("DisplayRewards")

--inflated values to make testing easier
local rewardsTable = {
    {
        RewardType = "StatBuff",
        Name = "StatBuff1",
        Description = "Buff player MaxHealth and Damage",
        Buffs = {{"MaxHealth", 5}, {"DamageMult", 100}}
    },
    {
        RewardType = "StatBuff",
        Name = "StatBuff2",
        Description = "Buff player Speed and Jump",
        Buffs = {{"WalkSpeed", 25}, {"JumpPower", 50}}
    },
    {
        RewardType = "Gift",
        Name = "ItemGift1",
        Description = "Gives the item [Health Pot]",
        ItemName = "HealthPot"
    },
    {
        RewardType = "BurstChange",
        Name = "BurstChange1",
        Description = "Switch your burst technique!",
    },
}

local trialsTable = {
    {
        RewardType = "StatBuff",
        Name = "StatBuff1",
        Description = "Buff enemy Health and Damage",
        Buffs = {{"MaxHealth", 100}, {"DamageMult", 5}}
    },
    {
        RewardType = "StatBuff",
        Name = "StatBuff2",
        Description = "Buff enemy Speed and Jump",
        Buffs = {{"WalkSpeed", 25}, {"JumpPower", 50}}
    },
    {
        RewardType = "StatBuff",
        Name = "StatBuff3",
        Description = "Buff enemy Speed and Health",
        Buffs = {{"WalkSpeed", 100}}
    },
    {
        RewardType = "StatBuff",
        Name = "StatBuff4",
        Description = "Buff Health and Jump",
        Buffs = {{"MaxHealth", 50}, {"JumpPower", 50}}
    },
}

function pickRandom()
    local selectedPairs = {}

    local numRewards = 0
    while numRewards < Rewards.numRewards do
        local selectedReward = rewardsTable[math.random(1, #rewardsTable)]
        local selectedTrial = trialsTable[math.random(1, #trialsTable)]
        local pair = {selectedReward, selectedTrial}
        local dupeFound = false
        for _, tuple in ipairs(selectedPairs) do
            if tuple[1].Name == selectedReward.Name then
                dupeFound = true
                break
            end
        end
        if dupeFound then continue end
        table.insert(selectedPairs, pair)
        numRewards += 1
    end
    return selectedPairs
end

function selectPair()
    print("selected")
end

function burstChangeFunc(player)
    local currentBurst = player:GetAttribute("BurstTech")
    local currentModule = require(RS.BurstScripts:FindFirstChild(currentBurst))
    local currentStat = currentModule.stat
    local possibleBursts = {}
    for index, MS in ipairs(RS.BurstScripts) do
        local new = require(MS)
        if new.stat ~= currentStat then continue end
        table.insert(possibleBursts, MS)
    end
    local selectedBurst = possibleBursts[math.random(1, #possibleBursts)]
    return currentBurst, selectedBurst
end

--intended to run on client
function Rewards.selectReward(rewardOptions)
    
end

Rewards.numRewards = 3
function Rewards.changeNumRewards(newValue)
    Rewards.numRewards = newValue
end

function Rewards.ShowRewards()
    print("Showing rewards")

    --later add teleport to physical room
    for _, player in ipairs(players:GetPlayers()) do
        print(player)
        local pairsTable = pickRandom()
        remote:FireClient(player, pairsTable)
        for index, pair in ipairs(pairsTable) do
            local rewardName = pair[1].Name
            local trialName = pair[2].Name
            print("Pair #"..tostring(index)..": ".." Reward: ".. rewardName.." Trial: "..trialName)
        end
    end
    
end

return Rewards