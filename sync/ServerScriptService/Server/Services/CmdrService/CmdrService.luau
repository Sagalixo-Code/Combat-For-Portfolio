local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Internal = script.Parent:WaitForChild("Internal")

local CmdrServer = {}

function CmdrServer.Init()
	task.wait(1)

	local Cmdr = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Cmdr"))

	Cmdr:RegisterDefaultCommands()

	Cmdr:RegisterHooksIn(Internal.Hooks)
	Cmdr:RegisterTypesIn(Internal.Types)
	Cmdr:RegisterCommandsIn(Internal.Commands)
end

return CmdrServer
