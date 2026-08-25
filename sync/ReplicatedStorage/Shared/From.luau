local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.Shared.Libs.Logger)
local Result = require(ReplicatedStorage.Shared.Libs.Result)

local API = {}
local _cachedModules = {}

local FromLogger = Logger.new("From")

setmetatable(API, {
	__index = function(_, moduleName)
		local module = _cachedModules[moduleName]
		if not module then
			FromLogger:Debug(`Module {tostring(moduleName)} dont found.`)
		end
		return module
	end,
})

local function safeReq(moduleScript: ModuleScript)
	if _cachedModules[moduleScript.Name] then
		return _cachedModules[moduleScript.Name]
	end

	local success, result = pcall(require, moduleScript)

	if success then
		return result
	else
		FromLogger:Warn(`Error to load module {moduleScript.Name}. Current error is: {tostring(result)}`)
		return Result.Err(result)
	end
end

function API.import(inst: Folder)
	local result = {}

	for _, child in inst:GetChildren() do
		if child:IsA("ModuleScript") then
			local loadedModule = safeReq(child)

			if loadedModule then
				_cachedModules[child.Name] = loadedModule
				result[child.Name] = loadedModule
			end
		end
	end

	return result
end

function API.export(name: string)
	return _cachedModules[name]
end

return API
