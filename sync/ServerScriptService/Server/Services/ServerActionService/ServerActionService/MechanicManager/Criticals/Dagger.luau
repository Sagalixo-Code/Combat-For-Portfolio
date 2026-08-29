--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

	if not Common:ActionCheck(Character, "Critical") or not EntityMachine.CooldownManager:IsReady("Critical") then
		DaggerLightAttackLogger:Debug(`Critical is in cooldown or no is possible to user.`)
		return
	end

	local AttackInfo: { [string]: any } = {
		LightAttack = true,
	}

	StringData.LoadLists(AttackInfo, "WeaponList", script.Name)

	AttackInfo.KB = true
	AttackInfo.Damage = AttackInfo.Damage * 1.3

	EntityMachine.CooldownManager:Set("Critical", 5)

	local HitManager = EntityMachine.HitManager.new({
		Shape = "Box",
		Size = Vector3.new(AttackInfo.Width, AttackInfo.Height, AttackInfo.Reach),
		CFrame = Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -AttackInfo.Reach / 2),
		StartTime = time(),
		EndTime = time() + 1,
		Character = Character,
		Sweep = true,
	})

	local Animation = EntityMachine.Humanoid:LoadAnimation(AttackInfo.Animations["Critical"])

	Animation.Priority = Enum.AnimationPriority.Action3
	Animation:Play()
	Animation:AdjustSpeed(AttackInfo.AdjustSpeed or 1)

	EntityMachine.Janitor:Add(Animation, "Stop")
	EntityMachine.Janitor:Add(HitManager, "Destroy")

	Common.Sound("SekiroCrit", Character)

	task.delay(0.415, function()
		ReplicatedStorage.ClientReplicator:FireAllClients({
			Owner = EntityMachine.Character,
			Func = "DaggerSwingEffect",
			Combo = 5,
		})
	end)

	EntityMachine.Janitor:Add(Animation:GetMarkerReachedSignal("AttackFrame"):Connect(function()
		Common.Sound("Stabbing", Character)
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
		Character:SetAttribute("CanFeint", false)
		EntityMachine.Janitor:Cleanup()
	end))

	return Animation
end

return Action
