local ServerActionService = {}

local Internal = script.Parent:WaitForChild("Internal")

local AllowedModules = {
	MechanicManager = {
		LightAttack = true,
		ZXC = true,
		Criticals = true
	},
}

function ServerActionService.Trigger(Context)
	if typeof(Context) ~= "table" then
		return
	end

	local ModuleName = Context.Module
	local FuncName = Context.Func
	if typeof(ModuleName) ~= "string" or typeof(FuncName) ~= "string" then
		return
	end

	local AllowedFuncs = AllowedModules[ModuleName]
	if not AllowedFuncs or not AllowedFuncs[FuncName] then
		return
	end

	if not Context.EntityMachine or typeof(Context.EntityMachine) ~= "table" then
		return
	end

	if not Context.EntityMachine.Player or typeof(Context.EntityMachine.Player) ~= "Instance" then
		return
	end

	local Module = Internal[ModuleName]
	if not Module then
		return
	end

	local Handler = require(Module)[FuncName]
	if typeof(Handler) ~= "function" then
		return
	end

	if ModuleName == "MechanicManager" then
		Handler(Context)
		return
	end

	Handler(Context.EntityMachine)
end

return ServerActionService
