local MechanicManager = {}

local LightAttacks = script:WaitForChild("LightAttacks")
local Criticals = script:WaitForChild("Criticals")
local ZXCs = script:WaitForChild("ZXC")

MechanicManager.LightAttack = function(Context)
	if not Context then
		return
	end

	local LightAttack = require(LightAttacks[Context.Style])
	LightAttack.Init(Context.EntityMachine)
end

MechanicManager.ZXC = function(Context)
	if not Context then
		return
	end

	local Conteiner = ZXCs[Context.Unit]
	if not Conteiner then
		return
	end

	local ZXC = require(Conteiner[Context.Key])
	ZXC.Init(Context.EntityMachine)
end

MechanicManager.Critical = function(Context)
	if not Context then
		return
	end
	
	local Critical = require(Criticals[Context.Style])
	Critical.Init(Context.EntityMachine)
end

return MechanicManager
