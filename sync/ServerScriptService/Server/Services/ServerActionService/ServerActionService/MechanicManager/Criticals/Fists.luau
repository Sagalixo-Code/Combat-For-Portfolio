const Common = require("@game/ReplicatedStorage/Shared/Common")
const EntityMachine_d = require("@game/ReplicatedStorage/Shared/Definitions/EntityMachine.d")
const _CharacterType_d = require("@game/ReplicatedStorage/Shared/Definitions/CharacterType.d")

const Action = {}

Action.Init = function(EntityMachine: EntityMachine_d.EntityMachine)
	if not Common:ActionCheck<<_CharacterType_d.Character>>(EntityMachine.Character, "LightAttack") then
		return
	end
	
	-- TODO: Logic Of Critical Here
end

return Action
