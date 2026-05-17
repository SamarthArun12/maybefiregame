--ignore the red underline, it works, VS code just thinks it doesnt
local testRoom = game.Workspace:WaitForChild("LongRoom")
local testModule = require(testRoom:WaitForChild("ModuleScript"))
testModule.Environment()

