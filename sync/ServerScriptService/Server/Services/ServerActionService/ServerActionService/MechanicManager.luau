local Syntax = require("@game/ReplicatedStorage/Shared/Libs/Syntax")

local Result = Syntax.Result

const MechanicManager = {
	Actions = {
		LightAttacks = script:WaitForChild("LightAttacks"),
		Criticals = script:WaitForChild("Criticals"),
	},
}

local function ResolveAction(Context, ActionType)
	local ActionConteiner = MechanicManager.Actions[ActionType]

	if not ActionConteiner then
		return Result.Err(`Action type "{ActionType}" not found`)
	end

	local FeatureModule = ActionConteiner[Context.Style]

	if not FeatureModule then
		return Result.Err(`No action found for style "{Context.Style}"`)
	end

	local Success, Action = pcall(require, FeatureModule)

	if not Success then
		return Result.Err(Action)
	end

	return Action
end

function MechanicManager.LightAttack(Context)
	local LightAttack = ResolveAction(Context, "LightAttacks")

	if not LightAttack:IsOk() then
		return
	end

	LightAttack:Unwrap().Init(Context.EntityMachine)
end

function MechanicManager.Critical(Context)
	local Critical = ResolveAction(Context, "Criticals")

	if not Critical:IsOk() then
		return
	end

	Critical:Unwrap().Init(Context.EntityMachine)
end

return MechanicManager
