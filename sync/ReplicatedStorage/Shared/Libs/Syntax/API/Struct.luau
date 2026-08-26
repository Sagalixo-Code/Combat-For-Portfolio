export type FieldValidator = (value: any) -> boolean

export type FieldDefinition = {
	name: string,
	default: any,
	kind: string | FieldValidator,
}

local Struct = {}

function Struct.field(name: string, default: any, kind: (string | FieldValidator)?): FieldDefinition
	local resolvedKind: string | FieldValidator

	if kind ~= nil then
		resolvedKind = kind
	elseif default ~= nil then
		resolvedKind = typeof(default)
	else
		error(string.format("field '%s': cannot infer type from nil default, specify the type", name), 2)
	end

	return {
		name = name,
		default = default,
		kind = resolvedKind,
	}
end

local function matchesKind(value: any, kind: string | FieldValidator): boolean
	if typeof(kind) == "function" then
		return (kind :: FieldValidator)(value)
	end

	return typeof(value) == kind
end

local function describeKind(kind: string | FieldValidator): string
	if typeof(kind) == "function" then
		return "custom validator"
	end

	return kind :: string
end

local function makeStruct(definition: { FieldDefinition }, typeName: string?)
	typeName = typeName or "Struct"

	if typeof(typeName) ~= "string" then
		return
	end

	local byName: { [string]: FieldDefinition } = {}
	local fieldCount = #definition

	for index = 1, fieldCount do
		local def = definition[index]

		if byName[def.name] ~= nil then
			error(string.format("%s: duplicate field '%s'", typeName, def.name), 3)
		end

		byName[def.name] = def
	end

	local StructType = {}
	local Methods = {}
	local storage = setmetatable({}, { __mode = "k" })

	local function assign(self, name: string, value: any)
		local def = byName[name]

		if value == nil then
			value = def.default
		elseif not matchesKind(value, def.kind) then
			error(
				string.format(
					"%s: field '%s' expects '%s', received '%s'",
					typeName,
					name,
					describeKind(def.kind),
					typeof(value)
				),
				3
			)
		end

		storage[self][name] = value
	end

	StructType.__index = function(self, key)
		if byName[key] ~= nil then
			return storage[self][key]
		end

		return Methods[key]
	end

	StructType.__newindex = function(self, key, value)
		if byName[key] == nil then
			error(string.format("%s: field '%s' does not exist", typeName, tostring(key)), 2)
		end

		assign(self, key, value)
	end

	StructType.__tostring = function(self)
		local parts = {}

		for index = 1, fieldCount do
			local name = definition[index].name

			table.insert(parts, string.format("%s = %s", name, tostring(storage[self][name])))
		end

		return string.format("%s { %s }", typeName, table.concat(parts, ", "))
	end

	StructType.__eq = function(a, b)
		local storageA, storageB = storage[a], storage[b]

		for index = 1, fieldCount do
			local name = definition[index].name

			if storageA[name] ~= storageB[name] then
				return false
			end
		end

		return true
	end

	function StructType.new(...)
		local argCount = select("#", ...)

		if argCount > fieldCount then
			error(string.format("%s: accepts at most %d value(s), received %d", typeName, fieldCount, argCount), 2)
		end

		local values = { ... }
		local self = setmetatable({}, StructType)

		storage[self] = {}

		for index = 1, fieldCount do
			local def = definition[index]
			assign(self, def.name, values[index])
		end

		return self
	end

	function Methods.clone(self)
		local copy = setmetatable({}, StructType)
		local copyStorage = {}

		for index = 1, fieldCount do
			local name = definition[index].name
			copyStorage[name] = storage[self][name]
		end

		storage[copy] = copyStorage

		return copy
	end

	return StructType
end

return setmetatable(Struct, {
	__call = function(_, definition: { FieldDefinition }, typeName: string?)
		return makeStruct(definition, typeName)
	end,
})
