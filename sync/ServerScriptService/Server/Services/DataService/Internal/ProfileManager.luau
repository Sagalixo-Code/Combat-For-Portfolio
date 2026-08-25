local HttpService = game:GetService("HttpService")
local ServerScriptService = game:GetService("ServerScriptService")
local profilestore = require(ServerScriptService.Server.ServerPackages.ProfileStore)
local Store = profilestore.New(HttpService:GenerateGUID(false), require(script.Parent.DefaultData))

local ProfileManager = {}

local Profiles = {}

function ProfileManager:Load(Player)
	local Profile = Store:StartSessionAsync(tostring(Player.UserId))

	if not Profile then
		Player:Kick()
		return
	end

	Profile:Reconcile()

	Profiles[Player] = Profile

	return Profile
end

function ProfileManager:Get(Player)
	return Profiles[Player]
end

function ProfileManager:Release(Player)
	local Profile = Profiles[Player]

	if Profile then
		Profile:EndSession()
	end

	Profiles[Player] = nil
end

return ProfileManager
