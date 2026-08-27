local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local CharacterType_d = require(script.Parent["CharacterType.d"])
local EntityMachineType = {}

export type EntityMachine = Model & {
	Player: Player,
	Character: CharacterType_d.Character,
	Janitor: typeof(Janitor.new()),
	Humanoid: Humanoid,
	RootPart: BasePart,
	StateMachine: {
		SetState: (...any) -> any,
		Trigger: (...any) -> any,
		PushState: (...any) -> any,
		PopState: (...any) -> any,
	},
}

return EntityMachineType
