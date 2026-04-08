--very base version for testing features, nothing close to final
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

--ignore the red underline, it works, VS code just thinks it doesnt
local testRoom = game.Workspace:WaitForChild("LongRoom")
local testModule = require(testRoom:WaitForChild("ModuleScript"))
testModule.Environment()

