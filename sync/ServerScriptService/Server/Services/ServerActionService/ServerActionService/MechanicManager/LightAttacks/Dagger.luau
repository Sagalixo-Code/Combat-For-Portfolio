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

	local HitManager = EntityMachine.HitManager.new({
		Shape = "Box",
		Size = Vector3.new(AttackInfo.Width, AttackInfo.Height, AttackInfo.Reach),
		CFrame = Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -AttackInfo.Reach / 2),
		StartTime = time(),
		EndTime = time() + 1,
		Character = Character,
		Sweep = true,
	})

	Combo += 1

	if Combo >= 5 then
		AttackInfo.Type = "Kick"
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
	EntityMachine.Janitor:Add(HitManager, "Destroy")

	Common.Sound("SpinSwing" .. math.random(1, 2), EntityMachine.Character)

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

	EntityMachine.Janitor:Add(Animation:GetMarkerReachedSignal("AttackFrame"):Connect(function()
		Character:SetAttribute("CanFeint", false)

		HitManager.Hit:Connect(function(HitResult: EntityMachine_d.HitResult<typeof(EntityMachine)>)
			HitResult.TagInfo.EMachine.Character:SetAttribute("SoftStun", true)
			task.delay(1, function()
				HitResult.TagInfo.EMachine.Character:SetAttribute("SoftStun", false)
			end)
			HitResult.TagService.Tag(HitResult.TagInfo, AttackInfo)
		end)

		HitManager:Start()
	end))

	EntityMachine.Janitor:Add(Animation.Stopped:Connect(function()
		Character:SetAttribute("LightAttack", false)
		Character:SetAttribute("CanFeint", false)
		EntityMachine.Janitor:Cleanup()
	end))

	return Animation
end

return Action
