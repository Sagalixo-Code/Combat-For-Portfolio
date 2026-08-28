const StringData = require("@game/ReplicatedStorage/Shared/Data/StringData")
const JanitorClass = require("@game/ReplicatedStorage/Packages/Janitor")
const Logger = require("@game/ReplicatedStorage/Shared/Libs/Logger")
const EntityMachine_d = require("@game/ReplicatedStorage/Shared/Definitions/EntityMachine.d")
const Common = require("@game/ReplicatedStorage/Shared/Common")

const WeaponsFolder = script:WaitForChild("Weapons")
const Action = {}

const EquipWeaponLogger = Logger.new("EquipWeapon")

local function GetWeaponAnimation(EntityMachine, WeaponList, AnimationName): AnimationTrack?
	local Animation = WeaponList.Animations:FindFirstChild(AnimationName)

	if not Animation then
		EquipWeaponLogger:Warn(`Missing weapon animation: {AnimationName}`)
		return nil
	end

	return EntityMachine.Humanoid:LoadAnimation(Animation)
end

local function UnequipWeapon(EntityMachine, WeaponList, WeaponName)
	local Character = EntityMachine.Character
	local WeaponInstance = Character:FindFirstChild(WeaponName)

	if not WeaponInstance then
		EquipWeaponLogger:Warn(`Weapon instance does not exist: {WeaponName}`)
		return
	end

	Common.StopIdle(EntityMachine)

	local Animation = GetWeaponAnimation(EntityMachine, WeaponList, "Unnequip")

	if not Animation then
		WeaponInstance:Destroy()
		return
	end

	local Janitor = JanitorClass.new()

	Animation:Play()

	Janitor:Add(Animation:GetMarkerReachedSignal("Unnequip"):Once(function()
		if WeaponInstance.Parent then
			WeaponInstance:Destroy()
		end

		Janitor:Destroy()
	end))
end

local function EquipWeapon(EntityMachine, WeaponList, WeaponName)
	local Character = EntityMachine.Character
	local WeaponTemplate = WeaponsFolder:FindFirstChild(WeaponName)

	if not WeaponTemplate then
		EquipWeaponLogger:Warn(`Weapon does not exist: {WeaponName}`)
		return
	end

	Common.StopAnims(EntityMachine)

	local Weapon = WeaponTemplate:Clone()
	Weapon.Name = WeaponName
	Weapon.Parent = Character

	local RightArm = Character:FindFirstChild("Right Arm")
	local Handle = Weapon:FindFirstChild("Handle")
	local Motor6D = Weapon:FindFirstChild("Motor6D")

	if not RightArm or not Handle or not Motor6D then
		EquipWeaponLogger:Warn(`Invalid weapon setup: {WeaponName}`)
		Weapon:Destroy()
		return
	end

	Motor6D.Part0 = RightArm

	Character:SetAttribute("HasWeapon", true)

	local Idle = GetWeaponAnimation(EntityMachine, WeaponList, "Idle")
	local Equip = GetWeaponAnimation(EntityMachine, WeaponList, "Equip")

	if not Idle then
		return
	end

	Equip.Priority = Enum.AnimationPriority.Action2
	Equip:Play()
	Idle.Priority = Enum.AnimationPriority.Idle
	Idle:Play()

	local Connection = Character:GetAttributeChangedSignal("Sprinting"):Connect(function()
		Idle.Priority = Character:GetAttribute("Sprinting") and Enum.AnimationPriority.Core
			or Enum.AnimationPriority.Action
	end)

	Idle.Stopped:Once(function()
		Connection:Disconnect()
	end)

	task.delay(0.05, function()
		if Handle:FindFirstChild("OnEquipSound") then
			Handle:FindFirstChild("OnEquipSound"):Play()
		end
	end)
end

Action.Trigger = function(Context)
	local EntityMachine: EntityMachine_d.EntityMachine = Context.EntityMachine
	local Character = EntityMachine.Character

	local WeaponName = Character:GetAttribute("Weapon")

	if not WeaponName then
		EquipWeaponLogger:Warn("Current weapon does not exist.")
		return
	end

	local WeaponList = StringData.GrabLists("WeaponList", EntityMachine.Style)

	local HasWeapon = Character:GetAttribute("HasWeapon")

	Character:SetAttribute("HasWeapon", not HasWeapon)

	if HasWeapon then
		UnequipWeapon(EntityMachine, WeaponList, WeaponName)
	else
		EquipWeapon(EntityMachine, WeaponList, WeaponName)
	end
end

return Action
