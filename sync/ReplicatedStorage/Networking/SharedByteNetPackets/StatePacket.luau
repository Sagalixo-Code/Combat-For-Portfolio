local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Bytenet = require(ReplicatedStorage.Packages.Bytenet)

return Bytenet.defineNamespace("State", function()
	return {
		StateManager = Bytenet.definePacket({
			reliabilityType = "reliable",

			value = Bytenet.struct({
				Action = Bytenet.string,
				Params = Bytenet.struct({}),
			}),
		}),
	}
end)
