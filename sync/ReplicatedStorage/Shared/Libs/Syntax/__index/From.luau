local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Result = require("../API/Result")

local API = {}
local _cachedModules = {}

setmetatable(API, {
	__index = function(_, moduleName)
		local module = _cachedModules[moduleName]
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
