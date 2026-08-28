local ReplicatedStorage = game:GetService("ReplicatedStorage")
const Syntax = require("@game/ReplicatedStorage/Shared/Libs/Syntax")
const Logger = require("@game/ReplicatedStorage/Shared/Libs/Logger")

const ClientReplicator = ReplicatedStorage:WaitForChild("ClientReplicator")

const Result = Syntax.Result

const Ok = Result.Ok
const Err = Result.Err

const MechanicManager = {
	Actions = {
		LightAttacks = script:WaitForChild("LightAttacks"),
		Criticals = script:WaitForChild("Criticals"),
	},
}

const MechanicManagerLogger = Logger.new("MechanicManager")

type DebugContext = {
	Entity: string?,
	State: string?,
	Style: string?,
	Action: string?,
	Error: string?,
}

local function MakeDebugMessage(Level: string, Context: DebugContext)
	local Message = {
		["COMBAT DEBUG"] = {
			Entity = Context.Entity or "unknown",
			State = Context.State or "unknown",
			Style = Context.Style or "unknown",
			Action = Context.Action or "unknown",

			Pipeline = {
				Error = Context.Error or "unknown",
			},

			Time = time(),
		},
	}

	local LogFunction = MechanicManagerLogger[Level]

	if LogFunction then
		LogFunction(MechanicManagerLogger, Message)
	end
end

local function ResolveAction(Context, ActionType)
	local ActionContainer = MechanicManager.Actions[ActionType]

	if not ActionContainer then
		return Err(`Action type "{ActionType}" not found.`)
	end

	if not Context.EntityMachine then
		return Err(`Context.EntityMachine dont exist.`)
	end

	if not Context.EntityMachine.Style then
		return Err(`Context.EntityMachine.Style dont exist.`)
	end

	local FeatureModule = ActionContainer[Context.EntityMachine.Style]

	if not FeatureModule then
		return Err(`No action found for style "{Context.EntityMachine.Style}".`)
	end

	local Success, Action = pcall(require, FeatureModule)

	if not Success then
		return Err(Action)
	end

	return Ok(Action)
end

function MechanicManager.LightAttack(Context)
	local LightAttack = ResolveAction(Context, "LightAttacks")

	if LightAttack:IsErr() then
		MakeDebugMessage("Error", {
			Entity = Context.EntityMachine.Name,
			State = Context.State,
			Style = Context.Style,
			Action = "LightAttack",
			Error = LightAttack:UnwrapErr(),
		})

		return LightAttack
	end

	if LightAttack:Unwrap().Init(Context.EntityMachine) then
		task.delay(0.115, function()
			ClientReplicator:FireClient(Context.EntityMachine.Player, {
				Owner = Context.EntityMachine.Character,
				Func = "AfterImages",
				Data = {
					Duration = 0.15,
					Interaval = 0.035,
					Character = Context.EntityMachine.Character,
				},
			})
			ClientReplicator:FireAllClients({
				Owner = Context.EntityMachine.Character,
				Func = Context.EntityMachine.Style .. "SwingEffect",
			})
		end)
	end

	return LightAttack
end

function MechanicManager.Critical(Context)
	local Critical = ResolveAction(Context, "Criticals")

	if Critical:IsErr() then
		MakeDebugMessage("Error", {
			Entity = Context.EntityMachine.Name,
			State = Context.State,
			Style = Context.Style,
			Action = "Critical",
			Error = Critical:UnwrapErr(),
		})

		return Critical
	end

	Critical:Unwrap().Init(Context.EntityMachine)

	return Critical
end

return MechanicManager
