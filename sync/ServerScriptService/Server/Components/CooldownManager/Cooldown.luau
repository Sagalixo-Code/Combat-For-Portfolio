local Syntax = require("@game/ReplicatedStorage/Shared/Libs/Syntax")

local Class = Syntax.Class

local Cooldown = Class({
	constructor = function(self, Duration: number)
		self.Duration = Duration
		self.EndsAt = 0
	end,

	Start = function(self, Duration: number?)
		self.Duration = Duration or self.Duration
		self.EndsAt = time() + self.Duration
	end,

	IsReady = function(self): boolean
		return time() >= self.EndsAt
	end,

	GetRemaining = function(self): number
		return math.max(0, self.EndsAt - time())
	end,

	GetProgress = function(self): number
		if self.Duration <= 0 then
			return 1
		end

		return math.clamp(1 - (self:GetRemaining() / self.Duration), 0, 1)
	end,

	Cancel = function(self)
		self.EndsAt = 0
	end,

	IsActive = function(self): boolean
		return not self:IsReady()
	end,

	Destroy = function(self)
		self.Duration = nil
		self.EndsAt = nil
	end,
})

return Cooldown
