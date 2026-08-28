local ReplicatedStorage = game:GetService("ReplicatedStorage")
const AnimationsFolder = ReplicatedStorage:WaitForChild("Resources"):WaitForChild("Assets"):WaitForChild("Animations")

const StringData = {}

StringData.LoadLists = function(Array, List, Find)
	for Info, Giver in StringData[List][Find] do
		Array[Info] = Giver
	end
end

StringData.GrabLists = function(List, Find)
	return StringData[List][Find]
end

StringData.WeaponList = table.freeze({
	["Dagger"] = {
		Damage = 7,
		HitSpeed = 0.4,
		AdjustSpeed = 1.25,
		HitReaction = true,
		HitEffect = true,
		Animations = AnimationsFolder["Dagger"],
		Type = "Sharp",
		Sheathe = nil,
		Weapon = "Normal",
		Cost = 0,
		Width = 7,
		Reach = 6.775,
		Height = 7,
	},
})

return StringData
