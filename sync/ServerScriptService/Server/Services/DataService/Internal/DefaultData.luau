local UniqueCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890"

local function CreateID()
	local EntityID = ""
	for i = 1, 8 do
		local randNum = math.random(1, UniqueCharacters:len())
		EntityID = EntityID .. UniqueCharacters:sub(randNum, randNum)
	end
	return EntityID
end

return {
	Stats = {
		Exp = 0,
		ExpNeed = 0,
		Gems = 0,
		Gold = 0,
		LevelReward = 0,
	},

	Profile = {
		BossKilled = 0,
		GamePlayed = 0,
		GameWon = 0,
		GemSpent = 0,
		MobKilled = 0,
		Playtime = 0,
		RobuxSpent = 0,
	},

	Inventory = {
		UnitsMaxBag = 100,
		UnitsBag = {
			["Saga" .. CreateID()] = {
				Name = "Saga",
				Rarity = "Comum",
				EquippedInSlot = "unknown",
				Damage = 17,
				Health = 200,
			},
			["Aizen" .. CreateID()] = {
				Name = "Aizen",
				Rarity = "Comum",
				EquippedInSlot = "unknown",
				Damage = 23,
				Health = 500,
			},
		},
		UnitsSlot = {
			Slot1 = "unknown",
			Slot2 = "unknown",
			Slot3 = "unknown",
		},
	},

	Products = {
		-- Gamepass
	},
}
