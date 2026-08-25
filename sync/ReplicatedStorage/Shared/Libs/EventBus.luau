local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)

local EventBus = {}
EventBus._events = {}

local function GetEvent(self, eventName: string)
	local event = self._events[eventName]

	if not event then
		event = Signal.new()
		self._events[eventName] = event
	end

	return event
end

function EventBus:Subscribe<T...>(eventName: string, callback: (T...) -> ())
	assert(typeof(eventName) == "string", "eventName must be a string")
	assert(typeof(callback) == "function", "callback must be a function")

	return GetEvent(self, eventName):Connect(callback)
end

function EventBus:Once<T...>(eventName: string, callback: (T...) -> ())
	assert(typeof(eventName) == "string")
	assert(typeof(callback) == "function")

	return GetEvent(self, eventName):Once(callback)
end

function EventBus:Publish(eventName: string, ...)
	local event = self._events[eventName]

	if not event then
		return
	end

	event:Fire(...)
end

function EventBus:Destroy(eventName: string)
	local event = self._events[eventName]

	if not event then
		return
	end

	event:Destroy()
	self._events[eventName] = nil
end

return EventBus
