local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Resources = ReplicatedStorage:WaitForChild("Resources")
local Assets = Resources:WaitForChild("Assets")

local Common = {}

local StunInfo = require(script.StunInfo)

function Common:ActionCheck(Character: Model, ActionName: string): boolean
	if ActionName == "LightAttack" then
		if Character:GetAttribute("LightAttack") then
			return false
		end
	end
	return true
end

function Common.StopIdle(Vars)
	for _, Anims in pairs(Vars.Character.Humanoid:GetPlayingAnimationTracks()) do
		Anims:Stop(0.045)
	end
end

function Common.Sound(SoundName, Character)
	local SoundInst = Assets.Sounds:FindFirstChild(tostring(SoundName))

	if not SoundInst then
		warn("Sound dont found.")
		return
	end

	local Clone: Sound = SoundInst:Clone()
	Clone.Parent = Character:WaitForChild("HumanoidRootPart")

	if Clone.IsLoaded then
		Clone:Play()
	else
		local conn

		conn = Clone.Loaded:Connect(function()
			Clone:Play()
			conn:Disconnect()
		end)
	end

	Debris:AddItem(Clone, Clone.TimeLength)
end

function Common.RenderWalkSpeed(Vars)
	local Holders = {
		Walkspeed = 11,
		JumpPower = 50,
		HighestPriority = 0,
	}

	for StunName, StunTable in pairs(StunInfo) do
		local isActive = Vars.Character:GetAttribute(StunName)
		if isActive then
			local Priority = StunTable.Priority or 0
			local StunWalkSpeed = StunTable.WalkSpeed
			local StunJumpPower = StunTable.JumpPower

			if Priority > Holders.HighestPriority then
				Holders.HighestPriority = Priority
				Holders.Walkspeed, Holders.JumpPower = StunWalkSpeed, StunJumpPower
			end
		end
	end

	if Vars.Humanoid.WalkSpeed ~= Holders.Walkspeed or Vars.Humanoid.JumpPower ~= Holders.JumpPower then
		Vars.Humanoid.WalkSpeed, Vars.Humanoid.JumpPower = Holders.Walkspeed, Holders.JumpPower
	end
end

function Common.StopAnims(Vars)
	local Humanoid = Vars.Character.Humanoid

	local ExcludedAnimations = {
		GuardBreak = true,
		DeflectCast = true,
	}

	for _, Track in Humanoid:GetPlayingAnimationTracks() do
		local Name = Track.Name

		local IsIdle = string.find(Name, "Idle", 1, true) ~= nil
		local IsWalking = string.find(Name, "Walk", 1, true) ~= nil
		local IsExcluded = ExcludedAnimations[Name]

		if not IsIdle and not IsWalking and not IsExcluded then
			Track:Stop(0.075)
		end
	end
end

return Common
