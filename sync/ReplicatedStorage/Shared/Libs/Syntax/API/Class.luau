return function<T>(Class: { [string]: T })
	local constructor = Class.constructor
	local parent = Class.extends

	local NewClass = {}
	NewClass.__index = NewClass

	local Private = setmetatable({}, {
		__mode = "k",
	})

	function NewClass.new(...)
		if Class.abstract then
			error("Cannot instantiate abstract class", 2)
		end

		local self = setmetatable({}, NewClass)

		if constructor then
			constructor(self, ...)
		end

		Private[self] = {}

		return self
	end

	function NewClass:private(values)
		local storage = Private[self]

		for name, value in values do
			storage[name] = value
		end
	end

	function NewClass:getPrivate(name)
		return Private[self][name]
	end

	function NewClass:setPrivate(name, value)
		Private[self][name] = value
	end

	function NewClass:is(target)
		local current = NewClass

		while current do
			if current == target then
				return true
			end

			current = current.__parent
		end

		return false
	end

	function NewClass:destroy()
		Private[self] = nil

		if self.Destroy then
			self:Destroy()
		end
	end

	function NewClass.extend(Child)
		Child.extends = NewClass
		return Child
	end

	if parent then
		NewClass.__parent = parent

		setmetatable(NewClass, {
			__index = parent,
		})
	end

	for name, value in Class do
		if name ~= "constructor" and name ~= "extends" and name ~= "abstract" then
			NewClass[name] = value
		end
	end

	return NewClass
end
