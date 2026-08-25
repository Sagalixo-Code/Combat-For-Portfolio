local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Registry = require(ReplicatedStorage.Shared.Libs.Forge.Registry)
local Logger = require(ReplicatedStorage.Shared.Libs.Logger)

local ReplicatorRemote = Instance.new("RemoteEvent")
ReplicatorRemote.Name = "Replicator"
ReplicatorRemote.Parent = game:GetService("ReplicatedStorage")

local ReplicateService = {}

local PacketType = table.freeze({
	Sync = "Sync",
	Patch = "Patch",
})

local ReplicateLogger = Logger.new("Replicate")

function ReplicateService:Patch<T>(Player: Player, Path: { string }, Value: { [string]: T })
	const PacketPayload = table.freeze({
		Path = Path,
		Type = PacketType.Patch,
		Data = Value,
	})
	ReplicatorRemote:FireClient(Player, PacketPayload)
end

function ReplicateService:Sync<T>(Player: Player, ProfileData: { [string]: T })
	const PacketPayload = table.freeze({
		Data = ProfileData,
		Type = PacketType.Sync,
	})

	ReplicatorRemote:FireClient(Player, PacketPayload)
end

function ReplicateService.PlayerAdded<T>(Player: Player)
	local DataService = Registry:getService("DataService")

	task.spawn(function()
		local profile
		local timeout = 0.5
		local timeoutBreak = false

		repeat
			profile = DataService:GetProfile(Player)
			if timeout >= 5 then
				timeoutBreak = true
				ReplicateLogger:Error(`Player {Player.Name} Profile Not Found`)
				break
			end
			task.wait(0.5)
			timeout += 0.5
		until profile

		if timeoutBreak then
			ReplicateLogger:Warn(`TimoutBreak - Player {Player.Name} has been kicked.`)
			Player:Kick("Rejoin")
			return
		end

		ReplicateService:Sync(Player, profile.Data)
	end)
end

return ReplicateService
