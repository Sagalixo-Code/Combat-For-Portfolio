const Common = require("@game/ReplicatedStorage/Shared/Common")

local DirectHit = {}
DirectHit.Init = function(Array)
	if Array.Damage then
		Array.EMachine.Character.Humanoid:TakeDamage(Array.Damage)
	end
end

return DirectHit
