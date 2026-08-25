local CharacterType = {}

export type Character = Model & {
	Humanoid: Humanoid,
	HumanoidRootPart: BasePart,

	[string]: Instance,
}

return CharacterType
