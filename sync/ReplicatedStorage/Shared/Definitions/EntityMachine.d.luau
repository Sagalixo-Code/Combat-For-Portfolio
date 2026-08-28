local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Janitor = require(ReplicatedStorage.Packages.Janitor)

local CharacterType_d = require(script.Parent["CharacterType.d"])

local EntityMachineType = {}

export type Cooldown = {
	Duration: number,
	EndsAt: number,

	Start: (self: Cooldown, Duration: number?) -> (),
	IsReady: (self: Cooldown) -> boolean,
	IsActive: (self: Cooldown) -> boolean,
	GetRemaining: (self: Cooldown) -> number,
	GetProgress: (self: Cooldown) -> number,
	Cancel: (self: Cooldown) -> (),
	Destroy: (self: Cooldown) -> (),
}

export type CooldownManager = {
	Cooldowns: { [string]: Cooldown },

	Get: (self: CooldownManager, Name: string) -> Cooldown?,
	Set: (self: CooldownManager, Name: string, Duration: number) -> Cooldown,
	IsReady: (self: CooldownManager, Name: string) -> boolean,
	GetRemaining: (self: CooldownManager, Name: string) -> number,
	TryUse: (self: CooldownManager, Name: string, Duration: number) -> boolean,
	Clear: (self: CooldownManager, Name: string) -> (),
	ClearAll: (self: CooldownManager) -> (),
	Destroy: (self: CooldownManager) -> (),
}

export type EntityMachine = {
	Player: Player,
	Character: CharacterType_d.Character,
	Janitor: typeof(Janitor.new()),
	Humanoid: Humanoid & {
		AnimationController: AnimationController,
	},
	RootPart: BasePart,

	StateMachine: {
		SetState: (...any) -> any,
		Trigger: (...any) -> any,
		PushState: (...any) -> any,
		PopState: (...any) -> any,
	},

	Style: string,
	CooldownManager: CooldownManager,
}

return EntityMachineType
