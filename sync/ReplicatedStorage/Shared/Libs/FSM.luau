--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Packages.Signal)
local Result = require(ReplicatedStorage.Shared.Libs.Result)

export type StateHooks<S> = {
	OnEnter: ((from: S?) -> ())?,
	OnExit: ((to: S?) -> ())?,
}

export type FsmError = "UNKNOWN_STATE" | "INVALID_TRANSITION"

export type Fsm<S> = {
	Changed: typeof(Signal.new()),
	AddState: (self: Fsm<S>, state: S, hooks: StateHooks<S>?) -> Fsm<S>,
	AddTransition: (self: Fsm<S>, from: S, to: S) -> Fsm<S>,
	Can: (self: Fsm<S>, to: S) -> boolean,
	Is: (self: Fsm<S>, state: S) -> boolean,
	GetState: (self: Fsm<S>) -> S,
	Fire: (self: Fsm<S>, to: S) -> Result.Result<S, FsmError>,
}

local Fsm = {}
Fsm.__index = Fsm

function Fsm.new<S>(initial: S): Fsm<S>
	local self = setmetatable({
		_current = initial,
		_hooks = {} :: { [any]: StateHooks<S> },
		_transitions = {} :: { [any]: { [any]: boolean } },
		Changed = Signal.new(),
	}, Fsm)
	return (self :: any) :: Fsm<S>
end

function Fsm.AddState<S>(self: Fsm<S>, state: S, hooks: StateHooks<S>?): Fsm<S>
	(self :: any)._hooks[state] = hooks or {}
	return self
end

function Fsm.AddTransition<S>(self: Fsm<S>, from: S, to: S): Fsm<S>
	local anySelf = self :: any
	local map = anySelf._transitions[from]
	if not map then
		map = {}
		anySelf._transitions[from] = map
	end
	map[to] = true
	return self
end

function Fsm.Can<S>(self: Fsm<S>, to: S): boolean
	local anySelf = self :: any
	local map = anySelf._transitions[anySelf._current]
	return map ~= nil and map[to] == true
end

function Fsm.Is<S>(self: Fsm<S>, state: S): boolean
	return (self :: any)._current == state
end

function Fsm.GetState<S>(self: Fsm<S>): S
	return (self :: any)._current
end

function Fsm.Fire<S>(self: Fsm<S>, to: S): Result.Result<S, FsmError>?
	local anySelf = self :: any

	if not anySelf._hooks[to] then
		return Result.Err("UNKNOWN_STATE" :: FsmError) :: any
	end
	if not Fsm.Can(self, to) then
		return Result.Err("INVALID_TRANSITION" :: FsmError) :: any
	end

	local from = anySelf._current :: S

	local fromHooks: StateHooks<S>? = anySelf._hooks[from]
	if fromHooks and fromHooks.OnExit then
		fromHooks.OnExit(to)
	end

	anySelf._current = to

	local toHooks: StateHooks<S>? = anySelf._hooks[to]
	if toHooks and toHooks.OnEnter then
		toHooks.OnEnter(from)
	end

	anySelf.Changed:Fire(from, to)
	return Result.Ok(to)
end

return Fsm
