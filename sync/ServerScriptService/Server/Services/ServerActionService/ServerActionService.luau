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

	return Result.Ok(Context)
end

function ServerActionService.Invoke(Context: ContextType)
	if TryContext(Context):IsErr() then
		return
	end

	if Context.Module == "MechanicManager" then
		require(script[Context.Module])[Context.Func](Context)
	end
end

return ServerActionService
