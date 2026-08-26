local ReplicatedStorage = game:GetService("ReplicatedStorage")
const Syntax = require("@game/ReplicatedStorage/Shared/Libs/Syntax")
local CharacterType_d = require(ReplicatedStorage.Shared.Definitions["CharacterType.d"])
const Janitor = require("@game/ReplicatedStorage/Packages/Janitor")

const Class = Syntax.Class
const Struct = Syntax.Struct

const EntityStruct = Struct({
	Struct.field("State", {}),
	Struct.field("StateEnums", {}),
	Struct.field("Stack", {}),
})

const Attributes = table.freeze({
	LightAttack = false,
})

const Entities = {}

local PlayerBehavior

const CreateStateMachineClass = Class({
	constructor = function(this, EntityProfile)
		this.EntityProfile = EntityProfile
		this.Struct = EntityStruct.new(PlayerBehavior.Idle, PlayerBehavior, {})
	end,

	SetState = function(this, NewState, ...)
		const State = this.Struct.StateEnums[NewState]

		if not State then
			warn(`{NewState} is not a valid state!`)
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
		end
	end,
})

const EntityService = {}

function EntityService.PlayerAdded(Player: Player, Components)
	if not PlayerBehavior then
		PlayerBehavior = Components.PlayerBehavior
	end

	local Character = Player.Character or Player.CharacterAdded:Wait()
	local Humanoid = Character:WaitForChild("Humanoid")
	local RootPart = Character:WaitForChild("HumanoidRootPart")

	const EntityProfileStruct = Struct({
		Struct.field("Player", Player),
		Struct.field("Character", Character),
		Struct.field("Janitor", {}),
		Struct.field("Humanoid", Humanoid),
		Struct.field("RootPart", RootPart),
		Struct.field("StateMachine", {}),
	})

	local EntityProfile = EntityProfileStruct.new(Player, Character, Janitor.new(), Humanoid, RootPart, nil)
	EntityProfile.StateMachine = CreateStateMachineClass.new(EntityProfile)

	Entities[Player.Name] = EntityProfile
end

function EntityService.CharacterAdded(_, Player: Player, Character: CharacterType_d.Character)
	for name, value in pairs(Attributes) do
		Character:SetAttribute(name, value)
	end
end

function EntityService.getEntity(PlayerName)
	return Entities[PlayerName]
end

return EntityService
