local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedByteNetPackets = require(ReplicatedStorage.Networking.SharedByteNetPackets)
local Registry = require(ReplicatedStorage.Shared.Libs.Forge.Registry)
local StateService = {}

local function isAllowedAction(EntityMachine: any, Action: any): boolean
	if typeof(Action) ~= "string" or Action == "" then
		return false
	end

	if Action == "PushState" or Action == "PopState" then
		return true
	end

	if not EntityMachine or not EntityMachine.StateMachine then
		return false
	end

	local state = EntityMachine.StateMachine.State
	return type(state) == "table" and state[Action] ~= nil
end

function StateService.Start()
	local EntityService = Registry:getService("EntityService")

	SharedByteNetPackets.CombatPacket.StateManager.listen(function(
		Data: {
			Action: string,
			Params: {},
		},
		Player: Player
	)
		if typeof(Data) ~= "table" then
			return
		end

		local EntityMachine = EntityService.GetEntity(Player)
		local Action = Data.Action

		if not isAllowedAction(EntityMachine, Action) then
			return
		end

		if Action == "PushState" then
			if typeof(Data.Params) ~= "string" then
				return
			end

			EntityMachine.StateMachine:PushState(Data.Params)
			return
		end

		if Action == "PopState" then
			EntityMachine.StateMachine:PopState()
			return
		end

		if typeof(Data.Params) ~= "table" and Data.Params ~= nil then
			return
		end

		EntityMachine.StateMachine:Trigger(Action, Data.Params)
	end)
end

return StateService
