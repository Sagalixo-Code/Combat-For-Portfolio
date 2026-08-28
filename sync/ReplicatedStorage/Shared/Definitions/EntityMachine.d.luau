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

export type HitResult<T> = {
	TagInfo: {
		EMachine: T,
		Machine: T,
		Outcome: string,
	},
	TagService: any,
}

export type HitManager = {
	new: (
		{
			Shape: "Sphere" | "Box",
			Size: Vector3?,
			CFrame: CFrame | (() -> CFrame)?,

			StartTime: number?,
			EndTime: number?,

			Character: CharacterType_d.Character,

			Filter: { Instance }?,
			Sweep: boolean?,
		}
	) -> HitManager,
	Shape: "Sphere" | "Box",
	Size: Vector3,
	CFrame: CFrame | (() -> CFrame)?,

	StartTime: number,
	EndTime: number,

	Character: CharacterType_d.Character,
	AttackerPlayer: Player?,

	Connection: RBXScriptConnection?,
	Sweep: boolean,
	PreviousCFrame: CFrame?,

	Started: boolean,
	Destroyed: boolean,

	OverlapParams: OverlapParams,
	AlreadyHit: { [Model]: boolean },

	Hit: any,

	EntityService: any,
	TagService: any,

	Start: (self: HitManager) -> RBXScriptConnection?,
	Stop: (self: HitManager) -> (),
	Destroy: (self: HitManager) -> (),

	GenerateHitboxDebugOverlay: (
		self: HitManager,
		hitboxCFrame: CFrame,
		hitboxSize: Vector3,
		Length: number
	) -> (),

	EvaluateImpact: (self: HitManager, targetEntity: Model, attackerPosition: Vector3) -> string,
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

	HitManager: HitManager,
}

return EntityMachineType
