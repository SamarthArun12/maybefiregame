local UIS = game:GetService("UserInputService")
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
player.CharacterAdded:Connect(function(char) character = char end)
local event = game.ReplicatedStorage.RemoteEvents:WaitForChild("StoreBurnInput")
local event2 = game.ReplicatedStorage.RemoteEvents:WaitForChild("EquippedChanged")
local event3 = game.ReplicatedStorage.BindableEvents:WaitForChild("StoredBarUpdate")

local canPlay = player:GetAttribute("CanPlay")
while not canPlay do
    task.wait(0.1)
    canPlay = player:GetAttribute("CanPlay")
end

local folderName = player.Name.."Folder"
local folder = game.ReplicatedStorage.PlayerFolders:WaitForChild(folderName)
local playerItems = folder:GetChildren()
for i, v in ipairs(playerItems) do
    if v:IsA("Tool") then
        v:SetAttribute("HotbarSlot", i)
    end
end
print(playerItems)

local current = nil
local mult_inc = false
local action = nil
local send = false
local toggle = false

player:GetAttributeChangedSignal("CanPlay"):Connect(function()
    canPlay = player:GetAttribute("CanPlay")
end)

UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if not canPlay then return end
    local sorb = false

    --get current tool b4 handling tates
    local activeNum = player:GetAttribute("EquippedSlot")
    local inHand = player:GetAttribute("Equipped")
    local current_tool = nil
    
    if inHand == "Weapon" then
        local weaponInUse = player:GetAttribute("WeaponName")
        current_tool = character:WaitForChild(weaponInUse)
    elseif inHand == "Offhand" then
        current_tool = playerItems[activeNum]
    end
    

    current = current_tool

    local currentSorbState = current and current:GetAttribute("sorbState") or "None"

    --soring 
    if input.KeyCode == Enum.KeyCode.R then
        if not current then return end -- Crash/exit out if no item is held
        action = "storing"
        
        if currentSorbState == "Store" then
            toggle = false
        else
            toggle = true
        end
        send = true

    --orbing   
    elseif input.KeyCode == Enum.KeyCode.E then
        if not current then return end
        action = "burning"
        
        if currentSorbState == "Burn" then
            toggle = false
        else
            toggle = true
        end
        send = true

    --Mult decrease
    elseif input.KeyCode == Enum.KeyCode.C then
        if not current then return end
        mult_inc = false
        action = "mult change"
        toggle = true
        send = true
        if currentSorbState == "Store" then
            sorb = "s"
        elseif currentSorbState == "Burn" then
            sorb = "b"
        end

    --Mult increase
    elseif input.KeyCode == Enum.KeyCode.V then
        if not current then return end
        mult_inc = true
        action = "mult change"
        toggle = true
        send = true
        if currentSorbState == "Store" then
            sorb = "s"
        elseif currentSorbState == "Burn" then
            sorb = "b"
        end
        
    elseif input.KeyCode == Enum.KeyCode.F then
        print("sent change equip")
        event2:FireServer(current)
    end
    
    --Fire info
    if send == true then
        -- Passes raw instance or nil instead of a fake string
        event:FireServer(action, current, mult_inc, toggle, sorb)
        if current then
            event3:Fire(current)
        end
        send = false
        print("Sent! " .. "Action: " .. tostring(action) .. ", Tool: " .. tostring(current) .. ", MultChange: " .. tostring(mult_inc) .. ", On/Off: " .. tostring(toggle) .. ", SorB: " .. tostring(sorb))
        toggle = false
    end
end)