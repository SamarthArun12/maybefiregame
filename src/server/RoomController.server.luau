local event = game.ReplicatedStorage.BindableEvents:WaitForChild("RoomChange")
local currentRoom = game.Workspace:WaitForChild("Room1")
local currentModule = require(currentRoom:FindFirstChild("ModuleScript"))
local prevRoom = nil
local prevModule = nil


function runModules(moduleScript)
	moduleScript.startRoom()
	moduleScript.Environment()
end

event.Event:Connect(function(roomName)
	prevRoom = currentRoom
	prevModule = currentModule
	prevModule.endRoom()
	currentRoom = game.Workspace:FindFirstChild(roomName)
	currentModule = require(currentRoom:FindFirstChild("ModuleScript"))
	runModules(currentModule)
end)

local testRoom = game.Workspace:WaitForChild("LongRoom")
local testModule = require(testRoom:WaitForChild("ModuleScript"))
testModule.Environment()

