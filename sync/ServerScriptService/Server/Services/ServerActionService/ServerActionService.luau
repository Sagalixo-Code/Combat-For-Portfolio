export type ContextType = {
	Module: string?,
	Func: string?,
	EntityMachine: { [string]: any }?,
}

local Syntax = require("@game/ReplicatedStorage/Shared/Libs/Syntax")

local Result = Syntax.Result

local ServerActionService = {}

local function TryContext(Context: ContextType?)
	if not Context then
		return Result.Err("Context dont exist")
	end

	if not Context.Module then
		return Result.Err("Module dont exist")
	end

	if not Context.Func then
		return Result.Err("Func dont exist")
	end

	if not Context.EntityMachine then
		return Result.Err("Entity Machine dont exist")
	end

	if not script[Context.Module] then
		return Result.Err("Feature dont exist")
	end

	local Module = require(script[Context.Module])

	if not Module[Context.Func] or typeof(Module[Context.Func]) ~= "function" then
		return Result.Err("Function does not exist")
	end

	return Result.Ok(Module)
end

function ServerActionService.Invoke(Context: ContextType)
	local ResultModule = TryContext(Context)

	if ResultModule:IsErr() then
		return ResultModule
	end

	return ResultModule:Unwrap()[Context.Func](Context)
end

return ServerActionService
