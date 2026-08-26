local PlayerBehavior = {}

PlayerBehavior.Idle = {
	["Enter"] = function(EntityProfile) end,
	["Exit"] = function(EntityProfile) end,

	EquipWeapon = function(EntityProfile) end,

	EquipWeaponNextState = "HasWeapon",
}

PlayerBehavior.HasWeapon = {
	["Enter"] = function(EntityProfile) end,
	["Exit"] = function(EntityProfile) end,

	UnequipWeapon = function(EntityProfile) end,

	UnequipWeaponNextState = "Idle",
}

return PlayerBehavior
