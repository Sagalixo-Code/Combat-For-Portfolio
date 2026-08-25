local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Internal = script.Parent:WaitForChild("Internal")

local Signal = require(ReplicatedStorage.Packages.Signal)
local Logger = require(ReplicatedStorage.Shared.Libs.Logger)
local PathUtil = require(ReplicatedStorage.Shared.Utils.PathUtil)
local ProfileManager = require(Internal:WaitForChild("ProfileManager"))

type Path = { string }

type ObserverConnection = { Disconnect: (self: ObserverConnection) -> () }
type Signal = typeof(Signal.new())

type ObserverNode = {
	Signal: Signal,
	Connections: { [number]: ObserverConnection },
	NextId: number,
}

type DataActionPatch<T> = {
	Action: string,
	Value: T?,
	[string]: any,
}

type ServiceRegistry = typeof(require(ReplicatedStorage.Shared.Libs.Forge.Registry))

local State = {
	Observers = {} :: { [Player]: { [string]: ObserverNode } },
	Registry = require(ReplicatedStorage.Shared.Libs.Forge.Registry) :: ServiceRegistry?,
}

local DataService = {}

local DataServiceLogger = Logger.new("DataService")

local function GetPathKey(path: Path): string
	return table.concat(path, ".")
end

function DataService:EnsurePlayer(player: Player)
	ProfileManager:Load(player)
	if not State.Observers[player] then
		State.Observers[player] = {}
	end
end

function DataService.PlayerAdded(player: Player, components: { [string]: any })
	DataService:EnsurePlayer(player)
end

function DataService:PlayerRemoving(player: Player, components: { [string]: any })
	local profile = ProfileManager:Get(player)
	if profile then
		profile:Save()
	end
	ProfileManager:Release(player)

	local playerObservers = State.Observers[player]
	if playerObservers then
		for _, node in pairs(playerObservers) do
			for _, conn in pairs(node.Connections) do
				conn:Disconnect()
			end
			if node.Signal and typeof(node.Signal.Destroy) == "function" then
				node.Signal:Destroy()
			end
		end
	end

	State.Observers[player] = nil
end

function DataService:GetProfile(player: Player): any
	return ProfileManager:Get(player)
end

function DataService:Get<T>(player: Player, path: Path): T?
	local profile = self:GetProfile(player)
	if not profile or not profile.Data then
		return nil
	end

	if not PathUtil.Exists(profile.Data, path) then
		return nil
	end

	return PathUtil.Get(profile.Data, path)
end

function DataService:Set(player: Player, path: Path, value: any)
	local profile = self:GetProfile(player)
	if not profile or not profile.Data then
		return false
	end

	if not PathUtil.Exists(profile.Data, path) then
		return false
	end

	local lastValue = self:Get(player, path)
	local ok = PathUtil.Set(profile.Data, path, value)
	if not ok then
		return false
	end

	if lastValue ~= value then
		self:Fire(
			player,
			path,
			{
				Action = "Set",
				Value = value,
			} :: DataActionPatch<any>
		)
	end

	return true
end

function DataService:Remove(player: Player, path: Path)
	local profile = self:GetProfile(player)
	if not profile or not profile.Data then
		return
	end

	if not PathUtil.Exists(profile.Data, path) then
		return
	end

	local lastValue = self:Get(player, path)
	PathUtil.Remove(profile.Data, path)

	if lastValue ~= nil then
		self:Fire(
			player,
			path,
			{
				Action = "Remove",
				Value = nil,
			} :: DataActionPatch<any>
		)
	end
end

function DataService:Observe<T...>(player: Player, path: Path, callback: (T...) -> ()): ObserverConnection
	self:EnsurePlayer(player)

	local key = GetPathKey(path)
	local playerObservers = State.Observers[player]

	if not playerObservers[key] then
		playerObservers[key] = {
			Signal = Signal.new(),
			Connections = {},
			NextId = 0,
		}
	end

	local node = playerObservers[key]
	node.NextId += 1
	local id = node.NextId

	local conn = node.Signal:Connect(function()
		callback(self:Get(player, path))
	end)

	node.Connections[id] = conn

	local initialValue = self:Get(player, path)
	callback(initialValue)

	return {
		Disconnect = function()
			local connection = node.Connections[id]
			if connection then
				connection:Disconnect()
				node.Connections[id] = nil
			end

			if next(node.Connections) == nil then
				if node.Signal and typeof(node.Signal.Destroy) == "function" then
					node.Signal:Destroy()
				end
				playerObservers[key] = nil
			end
		end,
	}
end

function DataService:Mutate(player: Player, path: Path, mutator: (any) -> any)
	if typeof(mutator) ~= "function" then
		return false
	end

	local profile = self:GetProfile(player)
	if not profile or not profile.Data then
		return false
	end

	if not PathUtil.Exists(profile.Data, path) then
		return false
	end

	local previousValue = self:Get(player, path)
	local nextValue = mutator(previousValue)
	if nextValue == nil and previousValue ~= nil then
		return false
	end

	return self:Set(player, path, nextValue)
end

function DataService:Fire<T>(player: Player, path: Path, ...: DataActionPatch<T>)
	if not State.Registry then
		DataServiceLogger:Error("Registry is nil")
		return
	end

	local replicateService = State.Registry:getService("ReplicateService")
	if replicateService then
		replicateService:Patch(player, path, ...)
	end

	local playerObservers = State.Observers[player]
	if not playerObservers then
		return
	end

	local key = GetPathKey(path)
	local node = playerObservers[key]

	if node then
		node.Signal:Fire()
	end
end

return DataService
