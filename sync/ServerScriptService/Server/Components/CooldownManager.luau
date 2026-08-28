local Syntax = require("@game/ReplicatedStorage/Shared/Libs/Syntax")

local Cooldown = require("./CooldownManager/Cooldown")

local Class = Syntax.Class

local CooldownManager = Class({
	constructor = function(this)
		this.Cooldowns = {}
	end,

	Get = function(this, Name: string)
		return this.Cooldowns[Name]
	end,

	Set = function(this, Name: string, Duration: number)
		local CooldownInstance = this.Cooldowns[Name]

		if not CooldownInstance then
			CooldownInstance = Cooldown.new(Duration)
			this.Cooldowns[Name] = CooldownInstance
		end

		CooldownInstance:Start(Duration)

		return CooldownInstance
	end,

	IsReady = function(this, Name: string): boolean
		local CooldownInstance = this.Cooldowns[Name]

		if not CooldownInstance then
			return true
		end

		return CooldownInstance:IsReady()
	end,

	GetRemaining = function(this, Name: string): number
		local CooldownInstance = this.Cooldowns[Name]

		if not CooldownInstance then
			return 0
		end

		return CooldownInstance:GetRemaining()
	end,

	TryUse = function(this, Name: string, Duration: number): boolean
		local CooldownInstance = this.Cooldowns[Name]

		if CooldownInstance and CooldownInstance:IsActive() then
			return false
		end

		this:Set(Name, Duration)

		return true
	end,

	Clear = function(this, Name: string)
		local CooldownInstance = this.Cooldowns[Name]

		if not CooldownInstance then
			return
		end

		CooldownInstance:Destroy()
		this.Cooldowns[Name] = nil
	end,

	ClearAll = function(this)
		for Name, CooldownInstance in this.Cooldowns do
			CooldownInstance:Destroy()
			this.Cooldowns[Name] = nil
		end
	end,

	Destroy = function(this)
		this:ClearAll()
	end,
})

return CooldownManager
