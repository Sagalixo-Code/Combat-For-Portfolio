const Registry = require("@game/ReplicatedStorage/Shared/Libs/Forge/Registry")
const PlayerBehavior = {}

local ServerActionService

local function GetServerActionService(): {
	["Invoke"]: (Context: { Module: string?, Func: string?, EntityMachine: { [string]: any }? }) -> (),
}
	if not ServerActionService then
		ServerActionService = Registry:getService("ServerActionService")
	end

	return ServerActionService
end

PlayerBehavior.Idle = {
	["Enter"] = function(EntityProfile) end,
	["Exit"] = function(EntityProfile) end,

	EquipWeapon = function(EntityProfile)
		GetServerActionService().Invoke({
			Module = "EquipWeapon",
			Func = "Trigger",
			EntityMachine = EntityProfile,
		})
	end,

	EquipWeaponNextState = "HasWeapon",
}

PlayerBehavior.HasWeapon = {
	["Enter"] = function(EntityProfile) end,
	["Exit"] = function(EntityProfile) end,

	LightAttack = function(EntityProfile)
		GetServerActionService().Invoke({
			Module = "MechanicManager",
			Func = "LightAttack",
			EntityMachine = EntityProfile,
		})
	end,

	UnequipWeapon = function(EntityProfile) end,

	UnequipWeaponNextState = "Idle",
}

return PlayerBehavior
