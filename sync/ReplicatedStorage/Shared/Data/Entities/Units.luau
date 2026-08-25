local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UnitsModel =
	ReplicatedStorage:WaitForChild("Resources"):WaitForChild("Assets"):WaitForChild("Models"):WaitForChild("Units")

local UnitsDataFolder =
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Data"):WaitForChild("Entities"):WaitForChild("UnitsData")

local EntityIDHandler = require(script.Parent:WaitForChild("EntityIDHandle"))

local Resources = ReplicatedStorage:WaitForChild("Resources")
local Assets = Resources:WaitForChild("Assets")
local UnitAnimations = Assets:WaitForChild("Animations"):WaitForChild("Units")

local Module = {}

local Units: { [string]: any } = {}
local UnitsByID: { [string]: any } = {}
local UnitNames: { string } = {}

local function RecursiveFreeze(tbl: any)
	if typeof(tbl) ~= "table" or table.isfrozen(tbl) then
		return
	end

	table.freeze(tbl)

	for _, value in tbl do
		if typeof(value) == "table" then
			RecursiveFreeze(value)
		end
	end
end

for _, moduleScript in UnitsDataFolder:GetDescendants() do
	if not moduleScript:IsA("ModuleScript") then
		continue
	end

	if Units[moduleScript.Name] then
		warn(`[UnitsModule] Unidade duplicada "{moduleScript.Name}" em {moduleScript:GetFullName()}, ignorando`)
		continue
	end

	local ok, data = pcall(require, moduleScript)
	if not ok then
		warn(`[UnitsModule] Falha ao dar require em {moduleScript:GetFullName()}: {data}`)
		continue
	end

	data.Name = data.Name or moduleScript.Name
	data.Groups = data.Groups or {}
	data.Model = (data.Model or "") .. data.Name
	if data.ShinyModel then
		data.ShinyModel = data.ShinyModel .. data.Name .. " (Shiny)"
	end
	if not data.Rarity then
		data.Rarity = moduleScript.Parent.Name
	end
	data.ID = data.Name

	Units[data.Name] = data
	UnitsByID[tostring(data.ID)] = data
	table.insert(UnitNames, data.Name)
end

RecursiveFreeze(Units)
RecursiveFreeze(UnitsByID)
table.freeze(UnitNames)

function Module:GetUnits()
	return Units
end

function Module:GetUnitNames(): { string }
	return UnitNames
end

function Module:GetUnitByName(name: string)
	return Units[name]
end

function Module:GetUnitDataFromID(id: any)
	return UnitsByID[tostring(id)]
end

function Module:GetUnitNameByID(id: any): string?
	local unit = UnitsByID[tostring(id)]
	return unit and unit.Name
end

function Module:GetUnitObjectByData(info, data): Instance?
	local folder = if data.Evolved
		then UnitsModel:FindFirstChild("EvolvedFolder")
		else UnitsModel:FindFirstChild(data.Rarity)

	if not folder then
		return nil
	end

	return folder:FindFirstChild(info.Name)
end

function Module:GetUnitAnimations(name)
	return UnitAnimations:FindFirstChild(name)
end

function Module:GetUnitInfo(id: any)
	return EntityIDHandler:GetNameFromID("Unit", id)
end

return Module
