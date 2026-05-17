local RoomFunctions = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Gets relevant instances one time at top of script
local roomFolder = ReplicatedStorage:WaitForChild("Rooms")
local tpScript = game:GetService("ServerStorage"):WaitForChild("TeleportScript")
local mapsFolder = game.Workspace:FindFirstChild("MapsFolder")
local TPTargets = mapsFolder:FindFirstChild("TPTargets")
local players = game.Players

-- State Management variables
RoomFunctions.enabledTeleporters = true
RoomFunctions.currentIndex = 0 -- Game strictly starts at index 0 (Rewards Room)
RoomFunctions.roomTemplates = {} -- Holds the 3 instances for the current theme loop
RoomFunctions.currentRoom = nil
RoomFunctions.currentModule = nil

-- Functions for selecting theme and rooms
local function selectTheme()
	local randomNum = math.random(1, #roomFolder:GetChildren())
	local selectedTheme = roomFolder:GetChildren()[randomNum]
	print("Selected Theme: " .. selectedTheme.Name)
	return selectedTheme
end

local function selectRooms(theme)
	local rooms = theme:GetChildren()
	local finalRoomName = theme:GetAttribute("FinalRoom")
	
	local selectedRooms = {}
	local selectedNum = 0
	while selectedNum < 2 do
		local randomnNum = math.random(1, #rooms)
		local room = rooms[randomnNum]
		if room.Name == finalRoomName then continue end
		if table.find(selectedRooms, room) then continue end
		selectedNum += 1
		table.insert(selectedRooms, room)
	end
	
	table.insert(selectedRooms, theme:FindFirstChild(finalRoomName))
	return selectedRooms
end

-- =====================================================================
-- STANDALONE GENERATION FUNCTION (Procedural-Ready)
-- =====================================================================
local function createRoom(roomTemplate, index)
	if not roomTemplate then
		warn("createRoom called with a nil roomTemplate!")
		return nil
	end

	-- 1. Clone and parent
	local newRoomInstance = roomTemplate:Clone()
	newRoomInstance.Name = "Room" .. tostring(index)
	newRoomInstance.Parent = mapsFolder

	-- 2. Position around LocX
	local targetLocName = "Loc" .. tostring(index)
	local targetLoc = mapsFolder:FindFirstChild("Locs"):FindFirstChild(targetLocName)
	
	if targetLoc then
		local roomCframe = targetLoc.CFrame * CFrame.new(0, 1, 0)
		newRoomInstance:PivotTo(roomCframe)
	else
		warn("Generation location " .. targetLocName .. " not found in Workspace.MapsFolder.Locs!")
	end

	-- 3. Teleporter configuration
	local teleporter = newRoomInstance:FindFirstChild("Teleporter")
	if teleporter then
		local teleportScript = tpScript:Clone()
		teleportScript.Parent = teleporter
	end
	
	return newRoomInstance
end
-- =====================================================================

function RoomFunctions.runModules(moduleToRun)
	print("Running modules for: " .. tostring(moduleToRun))
	local currentModule = require(moduleToRun)
	currentModule.startRoom()
	currentModule.Environment()
end

-- Consolidated state updates to track current active objects
local function updateRoomState()
	if RoomFunctions.currentIndex == 0 or RoomFunctions.currentIndex == 4 then
		RoomFunctions.currentRoom = mapsFolder:FindFirstChild("RewardsRoom")
	else
		RoomFunctions.currentRoom = mapsFolder:FindFirstChild("Room" .. tostring(RoomFunctions.currentIndex))
	end

	if RoomFunctions.currentRoom then
		RoomFunctions.currentModule = RoomFunctions.currentRoom:FindFirstChild("ModuleScript")
	else
		RoomFunctions.currentModule = nil
	end
end

-- Teleports all players to TargetX inside TPTargets where X is the current index
local function tpAllPlayers()
	-- If index is 0, we use Target4 because index 4 and 0 share the RewardsRoom physical space
	local targetIndex = (RoomFunctions.currentIndex == 0) and 4 or RoomFunctions.currentIndex
	local targetName = "Target" .. tostring(targetIndex)
	local target = TPTargets:FindFirstChild(targetName)
	
	if not target then 
		print("CRITICAL: Target platform not found: " .. tostring(targetName))
		return nil
	end

	print("Teleporting players to platform: " .. targetName)
	target.CanCollide = true

	for _, player in ipairs(players:GetPlayers()) do
		local character = player.Character
		if not character then continue end
		
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then continue end

		hrp.CFrame = target.CFrame + Vector3.new(0, 4, 0)
	end
	
	return target
end

function RoomFunctions.teleportFunction(part)
	local char = part.Parent
	if char:FindFirstChild("Humanoid") == nil then return end
	if char:GetAttribute("Affiliation") ~= "Player" then return end
	
	if not RoomFunctions.enabledTeleporters then return end
	
	RoomFunctions.enabledTeleporters = false
	RoomFunctions.transitionToNew()
end

-- Initializes the startup state inside the predefined RewardsRoom
function RoomFunctions.initializeGame()
	RoomFunctions.currentIndex = 0
	updateRoomState()
	
	-- Setup the permanent RewardsRoom teleporter script ONCE on server start
	if RoomFunctions.currentRoom then
		local teleporter = RoomFunctions.currentRoom:FindFirstChild("Teleporter")
		if teleporter and not teleporter:FindFirstChild("TeleportScript") then
			local teleportScript = tpScript:Clone()
			teleportScript.Parent = teleporter
		end
		
		if RoomFunctions.currentModule then
			RoomFunctions.runModules(RoomFunctions.currentModule)
		end
	end
end

function RoomFunctions.transitionToNew()
	print("--- TRANSITION STARTED ---")
	print("Old Index: " .. tostring(RoomFunctions.currentIndex))
	
	-- 1. End old modules and clean up previous physical room
	if RoomFunctions.currentModule then
		local activeModule = require(RoomFunctions.currentModule)
		if activeModule.endRoom then activeModule.endRoom() end
	end
	
	-- Only destroy rooms 1, 2, or 3. Never destroy the permanent RewardsRoom.
	if RoomFunctions.currentRoom and RoomFunctions.currentIndex >= 1 and RoomFunctions.currentIndex <= 3 then
		RoomFunctions.currentRoom:Destroy()
	end

	-- 2. Increment index by 1 immediately when teleporter is touched
	RoomFunctions.currentIndex += 1
	print("New Incremented Index: " .. tostring(RoomFunctions.currentIndex))

	-- 3. Teleport players to TargetX where X is the current index
	local activePlatform = tpAllPlayers()

	-- 4. Conditional generation rules
	if RoomFunctions.currentIndex == 4 then
		-- Rule: If index is 4, do NOT call createRoom, set index to 0 after teleporting
		print("Rewards Phase triggered! Resetting state index back to 0.")
		RoomFunctions.currentIndex = 0
		updateRoomState()
	elseif RoomFunctions.currentIndex == 1 then
		-- Rule: If index is 1, we just left the RewardsRoom. Roll a fresh theme set and generate Room 1.
		RoomFunctions.roomTemplates = selectRooms(selectTheme())
		
		local templateToBuild = RoomFunctions.roomTemplates[1]
		createRoom(templateToBuild, 1)
		updateRoomState()
	elseif RoomFunctions.currentIndex == 2 or RoomFunctions.currentIndex == 3 then
		-- Rule: If index is 2 or 3, build normal progression map
		local templateToBuild = RoomFunctions.roomTemplates[RoomFunctions.currentIndex]
		createRoom(templateToBuild, RoomFunctions.currentIndex)
		updateRoomState()
	end

	-- 5. Drop players off the safety platform into the environment
	task.wait(0.2)
	if activePlatform then
		activePlatform.CanCollide = false
		print("Dropped players into Area.")
	end

	-- 6. Fire newly linked modules if they exist
	if RoomFunctions.currentModule then
		RoomFunctions.runModules(RoomFunctions.currentModule)
	end

	-- 7. Reset debounce gate
	task.wait(1.5)
	RoomFunctions.enabledTeleporters = true
	print("--- TRANSITION COMPLETE ---")
end

-- Initialize game on script start directly at index 0
RoomFunctions.initializeGame()

return RoomFunctions