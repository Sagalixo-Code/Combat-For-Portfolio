export type ContextType = {
	Module: string?,
	Func: string?,
	EntityMachine: { [string]: any }?,
}

const Syntax = require("@game/ReplicatedStorage/Shared/Libs/Syntax")
const Logger = require("@game/ReplicatedStorage/Shared/Libs/Logger")

const Result = Syntax.Result

const Ok = Result.Ok
const Err = Result.Err

const ServerActionService = {}

const ServerActionLogger = Logger.new("ServerActionService")

local function TryContext(Context: ContextType?)
	if not Context then
		return Err("Context dont exist")
	end

	if not Context.Module then
		return Err("Module dont exist")
	end

	if not Context.Func then
		return Err("Func dont exist")
	end

	if not Context.EntityMachine then
		return Err("Entity Machine dont exist")
	end

	if not script[Context.Module] then
		return Err("Feature dont exist")
	end

	local Module = require(script[Context.Module])

	if not Module[Context.Func] or typeof(Module[Context.Func]) ~= "function" then
		return Err("Function does not exist")
	end

	return Ok(Module)
end

function ServerActionService.Invoke(Context: ContextType)
	local ResultModule = TryContext(Context)

	if ResultModule:IsErr() then
		ServerActionLogger:Error(`Error to get module, error is: {ResultModule:UnwrapErr()}`)
		return ResultModule
	end

	return ResultModule:Unwrap()[Context.Func](Context)
end

return ServerActionService
