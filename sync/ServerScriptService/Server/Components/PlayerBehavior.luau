local PlayerBehavior = {}

PlayerBehavior.Idle = {
	["Enter"] = function(EntityProfile) end,
	["Exit"] = function(EntityProfile) end,

	EquipWeapon = function(EntityProfile)
		print("Equip")
	end,

	EquipWeaponNextState = "HasWeapon",
}

PlayerBehavior.HasWeapon = {
	["Enter"] = function(EntityProfile) end,
	["Exit"] = function(EntityProfile) end,

	LightAttack = function(EntityProfile)
		print("M1")
	end,

	UnequipWeapon = function(EntityProfile) end,

	UnequipWeaponNextState = "Idle",
}

return PlayerBehavior
