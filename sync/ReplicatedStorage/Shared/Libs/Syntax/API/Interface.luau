return function<T>(Definition: { [string]: T })
	local Interface = {}

	Interface.__definition = Definition

	function Interface:check(Object)
		for name, expectedType in Definition do
			local value = Object[name]

			if value == nil then
				return false
			end

			if type(expectedType) == "string" then
				if type(value) ~= expectedType then
					return false
				end
			elseif type(expectedType) == "table" then
				if not table.find(expectedType, value) then
					return false
				end
			end
		end

		return true
	end

	function Interface:assert(Object)
		if not self:check(Object) then
			error("Object does not implement this interface", 2)
		end

		return true
	end

	function Interface:has(name)
		return Definition[name] ~= nil
	end

	return Interface
end
