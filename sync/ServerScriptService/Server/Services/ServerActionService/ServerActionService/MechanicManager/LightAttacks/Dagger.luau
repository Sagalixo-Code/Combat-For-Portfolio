--!strict

const Common = require("@game/ReplicatedStorage/Shared/Common")
const StringData = require("@game/ReplicatedStorage/Shared/Data/StringData")
const Logger = require("@game/ReplicatedStorage/Shared/Libs/Logger")

const EntityMachine_d = require("@game/ReplicatedStorage/Shared/Definitions/EntityMachine.d")
const CharacterType_d = require("@game/ReplicatedStorage/Shared/Definitions/CharacterType.d")

type EntityMachine = EntityMachine_d.EntityMachine
type Character = CharacterType_d.Character

const Action = {}

const DaggerLightAttackLogger = Logger.new("Daggger Light Attack")

function Action.Init(EntityMachine: EntityMachine)
	local Character = EntityMachine.Character

	if not Common:ActionCheck(Character, "LightAttack") or not EntityMachine.CooldownManager:IsReady("LightAttack") then
		DaggerLightAttackLogger:Debug(`LightAttack is in cooldown or no is possible to user.`)
		return
	end

	local Combo = tonumber(Character:GetAttribute("Combo"))

	if not Combo then
		DaggerLightAttackLogger:Debug(`LightAttack is in cooldown or no is possible to user.`)
		return
	end

	local AttackInfo: { [string]: any } = {
		LightAttack = true,
	}

	StringData.LoadLists(AttackInfo, "WeaponList", script.Name)

	Combo += 1

	if Combo >= 4 then
		AttackInfo.KB = true
		EntityMachine.CooldownManager:Set("LightAttack", AttackInfo.HitSpeed * 4)
	else
		EntityMachine.CooldownManager:Set("LightAttack", AttackInfo.HitSpeed)
	end

	Character:SetAttribute("Combo", Combo)
	Character:SetAttribute("LightAttack", true)
	Character:SetAttribute("CanFeint", true)

	local Animation = EntityMachine.Humanoid:LoadAnimation(AttackInfo.Animations["Swing" .. Combo])

	Animation.Priority = Enum.AnimationPriority.Action3
	Animation:Play()
	Animation:AdjustSpeed(AttackInfo.AdjustSpeed or 1)

	EntityMachine.Janitor:Add(Animation, "Stop")

	EntityMachine.Janitor:Add(EntityMachine.Character.AttributeChanged:Connect(function(Attribute)
		if Attribute == "Feinted" then
			EntityMachine.Character:SetAttribute("Combo", 0)
			Animation:Stop()
			Character:SetAttribute("Combo", 0)
			Character:SetAttribute("LightAttack", false)
			EntityMachine.Janitor:Cleanup()
			return
		end
	end))

	EntityMachine.Janitor:Add(Animation:GetMarkerReachedSignal("Hit"):Connect(function()
		Character:SetAttribute("CanFeint", false)
	end))

	EntityMachine.Janitor:Add(Animation.Stopped:Connect(function()
		Character:SetAttribute("LightAttack", false)
		Character:SetAttribute("CanFeint", false)
		EntityMachine.Janitor:Cleanup()
	end))

	return Animation
end

return Action
