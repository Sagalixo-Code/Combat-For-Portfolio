local Players = game:GetService("Players")
local Character = script.Parent
local Player = Players:GetPlayerFromCharacter(Character)

local Combo = Character:GetAttribute("Combo")

Character:GetAttributeChangedSignal("Combo"):Connect(function()
	local currentCombo = Character:GetAttribute("Combo")

	if currentCombo > 0 then
		if firsthit == false then
			reset()
		end
		firsthit = false
		local check = false
		function reset()
			check = true
		end
		task.delay(1.6, function()
			if check == false then
				Character:SetAttribute("Combo", 0)
			end
		end)
	end

	--[[if currentCombo >= 5 then
		task.spawn(1.6,function()
			Character:SetAttribute("Combo", 0)
		end)
	end]]
end)

Character.Parent = workspace.World.Living
