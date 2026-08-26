return function(entries: { [string]: any })
	local enum = {}
	local values = {}

	for name, value in entries do
		assert(type(name) == "string", "Enum key must be a string")

		local enumValue = {
			Name = name,
			Value = value,
		}

		setmetatable(enumValue, {
			__tostring = function(self)
				return self.Name
			end,
		})

		enum[name] = enumValue
		values[#values + 1] = enumValue
	end

	local proxy = {}

	setmetatable(proxy, {
		__index = enum,

		--[[__newindex = function()
			error("Enums are immutable", 2)
		end,]]

		__pairs = function()
			return next, enum, nil
		end,

		__tostring = function()
			return "Enum"
		end,
	})

	function proxy:values()
		return table.clone(values)
	end

	function proxy:has(name)
		return enum[name] ~= nil
	end

	function proxy:get(name)
		return enum[name]
	end

	return proxy
end
