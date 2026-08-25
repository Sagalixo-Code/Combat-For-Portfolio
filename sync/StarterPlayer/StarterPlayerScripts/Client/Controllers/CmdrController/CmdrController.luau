local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CmdrController = {}

function CmdrController.Init()
	task.wait(2)

	local cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient", 99))
	cmdr:SetActivationKeys({ Enum.KeyCode.F2 })
end

return CmdrController
