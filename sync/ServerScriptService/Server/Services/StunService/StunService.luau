const Common = require("@game/ReplicatedStorage/Shared/Common")
local Janitor = require("@game/ReplicatedStorage/Packages/Janitor")

const CharacterType_d = require("@game/ReplicatedStorage/Shared/Definitions/CharacterType.d")

const StunAttributes = table.freeze({
	LightAttack = true,
	HasWeapon = true,
	SoftStun = true,
	HighStun = true,
})
const StunService = {}
const EntityJanitors = {}

function StunService.PlayerAdded(Player: Player)
	EntityJanitors[Player.UserId] = Janitor.new()
end

function StunService.CharacterAdded(_, Player: Player, Character: CharacterType_d.Character)
	for name in pairs(StunAttributes) do
		EntityJanitors[Player.UserId]:Add(Character:GetAttributeChangedSignal(name):Connect(function()
			Common.RenderWalkSpeed({
				Character = Character,
				Humanoid = Character:WaitForChild("Humanoid"),
			})
		end))
	end
end

return StunService
