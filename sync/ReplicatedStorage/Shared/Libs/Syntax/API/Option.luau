local Option = {}

local Some = {}
Some.__index = Some

local None = {}
None.__index = None

function Option.some(value)
	return setmetatable({
		value = value,
	}, Some)
end

function Option.none()
	return setmetatable({}, None)
end

function Some:isSome()
	return true
end

function Some:isNone()
	return false
end

function Some:get()
	return self.value
end

function Some:unwrapOr(_)
	return self.value
end

function Some:map(callback)
	return Option.some(callback(self.value))
end

function None:isSome()
	return false
end

function None:isNone()
	return true
end

function None:get()
	error("Cannot get value from None", 2)
end

function None:unwrapOr(default)
	return default
end

function None:map(_)
	return self
end

return Option
