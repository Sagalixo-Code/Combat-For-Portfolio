local Common = require("@game/ReplicatedStorage/Shared/Common")
local EntityMachine_d = require("@game/ReplicatedStorage/Shared/Definitions/EntityMachine.d")

local Action = {}

Action.Init = function(EntityMachine: EntityMachine_d.EntityMachine)
	if not Common:ActionCheck(EntityMachine.Character, "LightAttack") then
		return
	end
end

return Action
