local player = game:GetService("Players"):WaitForChild(script:GetAttribute("Player")) or "None"
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local event = game.ReplicatedStorage.RemoteEvents:WaitForChild("StoreBurnInput")
local event2 = game.ReplicatedStorage.RemoteEvents:WaitForChild("StoreBurnActivateRE")
local playerStats = require(game.ServerStorage:WaitForChild("PlayerStats"))
local dt = 0.05

local rate = 0.5
-- DELETED: Global state variables (storing, burning, tool, stat, etc.) are gone.
local mult_cap = 9
local mult_floor = 1

local StatsFolder = game.ServerStorage.StatChanges:GetChildren()
local statsModules = {}
for i, v in pairs(StatsFolder) do
    statsModules[v.Name] = require(v)
end

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
    if player == nil then return end

    local folderName = player.Name.."Folder"
    local playerFolder = game.ReplicatedStorage.PlayerFolders:FindFirstChild(folderName)
    if not playerFolder then return end
    local confirmation = playerFolder:FindFirstChild(current.Name)
    if confirmation == nil then return end

    print("Received! " .. "Action: " .. tostring(action) .. ", Tool: " .. tostring(current) .. ", Mult: " .. tostring(inMult)  .. ", On/Off: " .. tostring(toggle))

    if current ~= "None" then
        -- Read config data localized to the triggered weapon instance
        local stat = current:GetAttribute("PrimaryStat")
        local secondary = current:GetAttribute("SecondaryStat")
        local sideAffect = current:GetAttribute("SideAffect")
        local mult = current:GetAttribute("Mult")

        if action == "storing" then
            current:SetAttribute("sorbState", toggle and "Store" or "None")
            change_stats(humanoid, "store", mult, stat, secondary, sideAffect, toggle)

        elseif action == "burning" then
            current:SetAttribute("sorbState", toggle and "Burn" or "None")
            change_stats(humanoid, "burn", mult, stat, secondary, sideAffect, toggle)

        elseif action == "mult change" then
            mult = inMult and mult + 1 or mult - 1

            if mult < mult_floor then
                mult = mult_floor
            elseif mult > mult_cap then
                mult = mult_cap
            end

            current:SetAttribute("Mult", mult)
            print(mult)
            
            local activeState = current:GetAttribute("sorbState")
            if sorb == "s" or activeState == "Store" then
                change_stats(humanoid, "store", mult, stat, secondary, sideAffect, toggle)
            end
            if sorb == "b" or activeState == "Burn" then
                change_stats(humanoid, "burn", mult, stat, secondary, sideAffect, toggle)
            end
        end
    else
        print("no changing aha")
        print(current)
    end
end)

while true do
    task.wait(dt)
    if player == "None" then continue end
    
    local folderName = player.Name.."Folder"
    local playerFolder = game.ReplicatedStorage.PlayerFolders:FindFirstChild(folderName)
    
    if playerFolder then
        -- Process every item in the folder concurrently
        for _, item in ipairs(playerFolder:GetChildren()) do
            local state = item:GetAttribute("sorbState")
            
            -- Explicit verification rule: Crash if state is unrecognized
            if state ~= "Store" and state ~= "Burn" and state ~= "None" then
                error("Invalid sorb state detected: " .. tostring(state))
            end

            if state ~= "None" and item.Parent then
                local stat = item:GetAttribute("PrimaryStat")
                
                if stat ~= "None" then
                    local stored = item:GetAttribute("Stored") or 0
                    local ceiling = item:GetAttribute("Ceiling") or 150
                    local mult = item:GetAttribute("Mult") or 1
                    local secondary = item:GetAttribute("SecondaryStat")
                    local sideAffect = item:GetAttribute("SideAffect")
                    
                    local changed = false

                    if state == "Store" and stored < ceiling then
                        stored = math.min(stored + mult * dt * rate, ceiling)
                        changed = true
                        
                        if stored == ceiling then
                            item:SetAttribute("sorbState", "None")
                            -- Turn off stat modifications when capped
                            change_stats(humanoid, "store", mult, stat, secondary, sideAffect, false)
                            playerStats.resetSB(player)
                        end

                    elseif state == "Burn" and stored > 0 then
                        stored = math.max(stored - mult * dt * rate, 0)
                        changed = true
                        
                        if stored == 0 then
                            item:SetAttribute("sorbState", "None")
                            -- Turn off stat modifications when depleted
                            change_stats(humanoid, "burn", mult, stat, secondary, sideAffect, false)
                            playerStats.resetSB(player)
                        end
                    end

                    if changed then
                        item:SetAttribute("Stored", stored)
                        --print("storing/burning in " .. item.Name)
                    end

                    -- Threshold check for client UI replication
                    local lastPrint = item:GetAttribute("LastPrint") or 0
                    if math.abs(stored - lastPrint) >= 0.25 then
                        stored = math.round(stored / 0.25) * 0.25
                        item:SetAttribute("LastPrint", stored)
                        event2:FireClient(player, item)
                    end
                end
            end
        end
    end
end

game.Players.PlayerRemoving:Connect(function(plr)
    if plr == player then
        script:Destroy()
    end
end)