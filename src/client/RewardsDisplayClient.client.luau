--[[
local RunService = game:GetService("RunService")
local DisplayRewardsRE = game.ReplicatedStorage:FindFirstChild("RemoteEvents"):FindFirstChild("DisplayRewards")
local RewardsMS = require(game.ServerStorage:WaitForChild("RewardsMS"))

local active = false

local rewardsList = nil
local currentChoice = nil

DisplayRewardsRE.OnClientevent:Connect(function(rewards)
    active = true
    rewardsList = rewards

end)

RunService.Heartbeat:Connect(function(dt)
    if not active then return end
    if not rewardsList then return end

end)
]]