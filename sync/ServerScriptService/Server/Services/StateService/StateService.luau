local ReplicatedStorage = game:GetService("ReplicatedStorage")
const SharedByteNetPackets = require("@game/ReplicatedStorage/Networking/SharedByteNetPackets")
const Syntax = require("@game/ReplicatedStorage/Shared/Libs/Syntax")
local Registry = require(ReplicatedStorage.Shared.Libs.Forge.Registry)

const Interface = Syntax.Interface
const Result = Syntax.Result

const Ok = Result.Ok
const Err = Result.Err

const StateService = {}

const function TryGetState(Context)
	if not Context.Params then
		return Err("Missing params")
	end

	local State = Context.Params.State

	if State == nil then
		return Err("Missing state")
	end

	return Ok(State)
end

function StateService.Start()
	const EntityService = Registry:getService("EntityService")

	const StateMachineInterface = Interface({
		SetState = "function",
		Trigger = "function",
		PushState = "function",
		PopState = "function",
	})

	SharedByteNetPackets.StatePacket.StateManager.listen(function(
		Context: {
			Action: string,
			Params: { [any]: any },
		},
		Player: Player
	)
		local EntityMachine = EntityService.getEntity(Player.Name)

		if not EntityMachine or not StateMachineInterface:check(EntityMachine.StateMachine) then
			return
		end

		if EntityMachine.StateMachine[Context.Action] then
			if Context.Action == "PushState" then
				local State = TryGetState(Context)

				if State:IsErr() then
					return
				end

				EntityMachine.StateMachine:PushState(State:Unwrap())
			elseif Context.Action == "PopState" then
				EntityMachine.StateMachine:PopState()
			else
				local State = TryGetState(Context)

				if State:IsErr() then
					return
				end

				EntityMachine.StateMachine:Trigger(State:Unwrap())
			end
		end
	end)
end

return StateService
