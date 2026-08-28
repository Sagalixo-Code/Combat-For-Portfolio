const Syntax = require("@game/ReplicatedStorage/Shared/Libs/Syntax")
const Logger = require("@game/ReplicatedStorage/Shared/Libs/Logger")
const Janitor = require("@game/ReplicatedStorage/Packages/Janitor")

const CharacterType_d = require("@game/ReplicatedStorage/Shared/Definitions/CharacterType.d")

const Class = Syntax.Class
const Struct = Syntax.Struct

const EntityStruct = Struct({
	Struct.field("State", {}),
	Struct.field("StateEnums", {}),
	Struct.field("Stack", {}),
})

const Attributes = table.freeze({
	LightAttack = false,
	CanFeint = false,
	HasWeapon = false,
	Combo = 1,
	CombatTimer = 0,
	Sprinting = false,
	Blocking = false,
	DeflectFrames = false,
	Critical = false,
	Uppercut = false,
	SoftStun = false,
})
const Entities = setmetatable({}, {
	__weak = "kv",
})

const EntityServiceLogger = Logger.new("EntityService")
local PlayerBehavior

const CreateStateMachineClass = Class({
	constructor = function(this, EntityProfile)
		this.EntityProfile = EntityProfile
		this.Struct = EntityStruct.new(PlayerBehavior.Idle, PlayerBehavior, {})
	end,

	SetState = function(this, NewState, ...)
		const State = this.Struct.StateEnums[NewState]

		if not State then
			EntityServiceLogger:Debug(`{NewState} is not a valid state!`)
			return
		end

		this.Struct.State = State

		const Player = this.EntityProfile.Player

		if Player then
			Player:SetAttribute("CurrentState", NewState)

			const Character = Player.Character

			if Character then
				Character:SetAttribute("CurrentState", NewState)
			end
		end

		if State.Enter then
			State.Enter(this.EntityProfile, ...)
		end
	end,

	Trigger = function(this, Action, ...)
		const State = this.Struct.State
		const Handler = State[Action]

		if not Handler then
			EntityServiceLogger:Debug(`State Handler is nil. Current State: {this.Struct.State}, Action: Action`)
			return
		end

		Handler(this.EntityProfile, ...)

		const NextState = State[Action .. "NextState"]

		if NextState then
			this:SetState(NextState, ...)
		end
	end,

	PushState = function(this, State)
		table.insert(this.Struct.Stack, this.Struct.State)
		this:SetState(State)
	end,

	PopState = function(this)
		const PreviousState = table.remove(this.Struct.Stack)

		if PreviousState then
			this:SetState(PreviousState)
		else
			EntityServiceLogger:Debug(`PreviousState is nil.`)
		end
	end,
})

const EntityService = {}

function EntityService.PlayerAdded(Player: Player, Components)
	if not PlayerBehavior then
		PlayerBehavior = Components.PlayerBehavior
	end

	const Character = Player.Character or Player.CharacterAdded:Wait()
	const Humanoid = Character:WaitForChild("Humanoid")
	const RootPart = Character:WaitForChild("HumanoidRootPart")

	const EntityProfileStruct = Struct({
		Struct.field("Player", Player),
		Struct.field("Character", Character),
		Struct.field("Janitor", {}),
		Struct.field("Humanoid", Humanoid),
		Struct.field("RootPart", RootPart),
		Struct.field("StateMachine", {}),
		Struct.field("CooldownManager", {}),
		Struct.field("HitManager", {}),
		Struct.field("Style", ""),
	})

	local EntityProfile = EntityProfileStruct.new(
		Player,
		Character,
		Janitor.new(),
		Humanoid,
		RootPart,
		nil,
		Components.CooldownManager.new(),
		Components.HitManager,
		"Dagger"
	)

	Character:SetAttribute("Weapon", "Dagger")
	EntityProfile.StateMachine = CreateStateMachineClass.new(EntityProfile)

	Entities[Player.UserId] = EntityProfile
end

function EntityService.CharacterAdded(_, Player: Player, Character: CharacterType_d.Character)
	for name, value in pairs(Attributes) do
		Character:SetAttribute(name, value)
	end
end

function EntityService.PlayerRemoving(Player)
	local EntityProfile = Entities[Player.UserId]
	if EntityProfile then
		EntityProfile.Janitor:Cleanup()
		table.clear(EntityProfile)
	end

	if Entities[Player.UserId] then
		Entities[Player.UserId] = nil
	end
end

function EntityService.getEntity(PlayerId)
	return Entities[PlayerId]
end

return EntityService
