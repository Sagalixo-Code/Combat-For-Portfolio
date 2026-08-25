local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Registry = require(ReplicatedStorage.Shared.Libs.Forge.Registry)

local PathSAS

local function GetServerActionService()
	if not PathSAS then
		PathSAS = Registry:getService("ServerActionService")
	end

	return PathSAS
end

local PlayerBehavior = {}

PlayerBehavior.Idle = {
	["Enter"] = function(EntityProfile) end,
	["Exit"] = function(EntityProfile) end,

	["LightAttack"] = function(EntityProfile)
		if EntityProfile.Character:GetAttribute("Unit") then
			return
		end

		local ServerActionService = GetServerActionService()

		ServerActionService.Trigger({
			Module = "MechanicManager",
			Unit = EntityProfile.Character:GetAttribute("Unit"),
			Func = "LightAttack",
			EntityMachine = EntityProfile,
		})
	end,

	["Z"] = function(EntityProfile)
		if EntityProfile.Character:GetAttribute("Unit") then
			return
		end

		local ServerActionService = GetServerActionService()

		ServerActionService.Trigger({
			Module = "MechanicManager",
			Unit = EntityProfile.Character:GetAttribute("Unit"),
			Func = "ZXC",
			Key = "Z",
			EntityMachine = EntityProfile,
		})
	end,
	["X"] = function(EntityProfile)
		if EntityProfile.Character:GetAttribute("Unit") then
			return
		end

		local ServerActionService = GetServerActionService()

		ServerActionService.Trigger({
			Module = "MechanicManager",
			Unit = EntityProfile.Character:GetAttribute("Unit"),
			Func = "ZXC",
			Key = "X",
			EntityMachine = EntityProfile,
		})
	end,

	["C"] = function(EntityProfile)
		if EntityProfile.Character:GetAttribute("Unit") then
			return
		end

		local ServerActionService = GetServerActionService()

		ServerActionService.Trigger({
			Module = "MechanicManager",
			Unit = EntityProfile.Character:GetAttribute("Unit"),
			Func = "ZXC",
			Key = "C",
			EntityMachine = EntityProfile,
		})
	end,
}

return PlayerBehavior
