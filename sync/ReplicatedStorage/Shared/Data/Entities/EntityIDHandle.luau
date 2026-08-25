local EntityIDHandle = {
	Utilitys = {
		Components = {
			["Instance"] = script.Components,
		},
	},
}

for _, inst in EntityIDHandle.Utilitys.Components.Instance:GetChildren() do
	EntityIDHandle.Utilitys.Components[inst.Name] = require(inst)
end

local Enemies = EntityIDHandle.Utilitys.Components["Enemies"]
local Units = EntityIDHandle.Utilitys.Components["Units"]

local function IsUnit(Entity)
	if Entity == "Unit" then
		return true, "Unit"
	else
		return false, "Enemy"
	end
end

function EntityIDHandle:GetNameFromID(typeName, id)
	local IsUnit, Type = IsUnit(typeName)
	if IsUnit then
		local name = Units[id]
		if not name then
			error(("Invalid unit ID '%s'"):format(tostring(id)))
		end

		return name
	elseif not IsUnit and Type == "Enemy" then
		local name = Enemies[id]
		if not name then
			error(("Invalid enemy ID '%s'"):format(tostring(id)))
		end
		return name
	end

	error(("Invalid type '%s'"):format(tostring(typeName)))
end

return EntityIDHandle
