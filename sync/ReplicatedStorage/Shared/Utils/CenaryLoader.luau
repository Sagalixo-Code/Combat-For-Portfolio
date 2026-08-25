local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Result = require(ReplicatedStorage.Shared.Libs.Forge.Result)
local Logger = require(ReplicatedStorage.Shared.Libs.Logger)
local API = {}

local CenaryConteiner = workspace

local CurrentCamera

if RunService:IsClient() then
	CurrentCamera = workspace.CurrentCamera
end

local Cenaries = script:WaitForChild("Cenaries")

local CenaryLoaderDebug = Logger.new("CenaryLoader")

local function GetCenary(CenaryName)
	local sucess, result = pcall(function(...)
		return Cenaries:FindFirstChild(CenaryName)
	end)

	if not sucess then
		CenaryLoaderDebug:Warn(`Error to get cenary, cenary name is: {CenaryName} and current error is: {result}`)
		return Result.err(result)
	end

	return Result.ok(result):unwrap():Clone()
end

function API.Validate(Context)
	if not Context.CenaryName and not Context.Cenary then
		CenaryLoaderDebug:Debug(`Cenary is nil`)
		return false
	end

	if RunService:IsServer() and Context.ClientRequire then
		CenaryLoaderDebug:Warn(`ClientRequire`)
		return false
	end

	if Context.CenaryName then
		if typeof(Context.CenaryName) ~= "string" then
			CenaryLoaderDebug:Warn(`CenaryName is not a string`)
			return
		elseif not Cenaries:FindFirstChild(Context.CenaryName) then
			CenaryLoaderDebug:Warn(`Cenary dont exist`)
		end
	elseif Context.Cenary then
		if typeof(Context.Cenary) ~= "Instance" then
			if Context._error then
				CenaryLoaderDebug:Warn(`Error to validate cenary. Current Error is: {(Context._error or "unknown")}`)
			end
			return
		end
	end

	return true
end

function API.ApplyCamera(Cenary: Model & { [string]: any })
	if not API.Validate({ Cenary = Cenary, ClientRequire = true }) then
		return
	end

	local CameraPoint = Cenary:FindFirstChild("CameraPoint")

	if not CameraPoint then
		CenaryLoaderDebug:Debug("Camera point dont exist.")
		return
	end

	CurrentCamera.CameraType = Enum.CameraType.Scriptable
	CurrentCamera.CFrame = CameraPoint.CFrame
end

function API.GetCenary(CenaryName)
	if not API.Validate({ CenaryName = CenaryName }) then
		return
	end

	local Cenary = CenaryConteiner:FindFirstChild(CenaryName)

	return Cenary
end

function API.LoadCenary(CenaryName)
	if not API.Validate({ CenaryName = CenaryName }) then
		return
	end

	local Cenary = GetCenary(CenaryName)

	if not API.Validate({ Cenary = Cenary }) then
		return
	end

	for _, eff in ipairs(Lighting:GetChildren()) do
		if eff.Name:lower():match(CenaryName:lower()) then
			eff.Enabled = true
		end
	end

	Cenary.Parent = CenaryConteiner

	return Cenary
end

return API
