--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Replicator = ReplicatedStorage:WaitForChild("Replicator") :: RemoteEvent

local Signal = require(ReplicatedStorage.Packages.Signal)
local PathUtil = require(ReplicatedStorage.Shared.Utils.PathUtil)

local ReplicatorModule = {}

ReplicatorModule.Data = {}
ReplicatorModule.Observers = {}

local function PathKey(Path: { string }): string
	return table.concat(Path, ".")
end

function ReplicatorModule.Start()
	Replicator.OnClientEvent:Connect(function(Packet)
		if Packet.Type == "Sync" then
			ReplicatorModule:ClientSync(Packet)
		elseif Packet.Type == "Patch" then
			ReplicatorModule:ClientPatch(Packet)
		end
	end)
end

function ReplicatorModule.PlayerRemoving()
	ReplicatorModule:Destroy()
end

function ReplicatorModule:Get(Path: { string })
	return PathUtil.Get(self.Data, Path)
end

function ReplicatorModule:Observe<T>(Path: { string }, Callback: (T?, string?) -> ())
	local key = PathKey(Path)

	if not self.Observers[key] then
		self.Observers[key] = {
			signal = Signal.new(),
			connections = {},
			nextId = 0,
		}
	end

	local obj = self.Observers[key]

	local id = obj.nextId + 1
	obj.nextId = id

	local conn = obj.signal:Connect(function(action)
		Callback(self:Get(Path), action)
	end)

	obj.connections[id] = conn

	return {
		Disconnect = function()
			local connection = obj.connections[id]

			if connection then
				connection:Disconnect()
				obj.connections[id] = nil
			end

			if next(obj.connections) == nil then
				if obj.signal and typeof(obj.signal.Destroy) == "function" then
					obj.signal:Destroy()
				end

				self.Observers[key] = nil
			end
		end,
	}
end

function ReplicatorModule:ClientSync(Packet)
	self.Data = Packet.Data

	for _, obj in pairs(self.Observers) do
		obj.signal:Fire("Set")
	end
end

function ReplicatorModule:ClientPatch(Packet)
	if Packet.Data.Action == "Set" then
		PathUtil.Set(self.Data, Packet.Path, Packet.Data.Value)
	elseif Packet.Data.Action == "Remove" then
		PathUtil.Remove(self.Data, Packet.Path)
	end

	local key = PathKey(Packet.Path)
	local obj = self.Observers[key]

	if obj then
		obj.signal:Fire(Packet.Data.Action)
	end
end

function ReplicatorModule:Destroy()
	for _, obj in pairs(self.Observers) do
		for _, connection in pairs(obj.connections) do
			connection:Disconnect()
		end

		if obj.signal and typeof(obj.signal.Destroy) == "function" then
			obj.signal:Destroy()
		end
	end

	table.clear(self.Observers)
	table.clear(self.Data)
end

return ReplicatorModule
