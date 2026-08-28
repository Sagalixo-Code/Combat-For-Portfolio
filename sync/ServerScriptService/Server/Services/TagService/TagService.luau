const Common = require("@game/ReplicatedStorage/Shared/Common")
const Signal = require("@game/ReplicatedStorage/Packages/Signal")

const Outcomes = script:WaitForChild("Outcomes")

local TagService = {}
TagService.Tagged = Signal.new()

function TagService.Tag(Data)
	if Common:ActionCheck(Data.Machine, "Stun") and not Data.Bypass then
		return
	end

	if Data.Machine and Data.EMachine and Data.EMachine.Character then
		TagService.Tagged:Fire({
			Target = Data.EMachine.Character,
			Source = Data.Machine.Character,
			Info = Data,
		})
	end

	local outcomeFunc = require(Outcomes[Data.Outcome])
	outcomeFunc.Init(Data)
end

return TagService
