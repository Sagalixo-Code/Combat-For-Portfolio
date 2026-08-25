local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local SharedByteNetPackets = require(ReplicatedStorage.Networking.SharedByteNetPackets)
local StateController = {}

local function SendAction(Action)
	SharedByteNetPackets.CombatPacket.StateManager.send({
		Action = Action,
	})
end

local Inputs = {
	[Enum.UserInputType.MouseButton1] = function()
		SendAction("LightAttack")
	end,

	[Enum.KeyCode.Z] = function()
		SendAction("Z")
	end,

	[Enum.KeyCode.X] = function()
		SendAction("X")
	end,

	[Enum.KeyCode.C] = function()
		SendAction("C")
	end,
}

function StateController.Start()
	UserInputService.InputBegan:Connect(function(input: InputObject, chat: boolean)
		if chat then
			return
		end

		local InputFunc = Inputs[input.KeyCode] or Inputs[input.UserInputType]
		if InputFunc then
			InputFunc()
		end
	end)
end

return StateController
