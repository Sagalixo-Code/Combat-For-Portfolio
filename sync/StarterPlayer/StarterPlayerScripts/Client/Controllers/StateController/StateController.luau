local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local SharedByteNetPackets = require(ReplicatedStorage.Networking.SharedByteNetPackets)
const StateController = {}

function StateController.Start()
	UserInputService.InputBegan:Connect(function(Input: InputObject, Chat: boolean)
		if Chat then
			return
		end

		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			SharedByteNetPackets.StatePacket.StateManager.send({
				Action = "LightAttack",
				Params = {},
			})
		elseif Input.KeyCode == Enum.KeyCode.E then
			SharedByteNetPackets.StatePacket.StateManager.send({
				Action = "EquipWeapon",
				Params = {},
			})
		end
	end)
end

return StateController
