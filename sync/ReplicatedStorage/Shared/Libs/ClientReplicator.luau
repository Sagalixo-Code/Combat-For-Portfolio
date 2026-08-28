local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EmitModule = require(ReplicatedStorage.EmitModule)

local Resources = ReplicatedStorage:WaitForChild("Resources")
local Assets = Resources:WaitForChild("Assets")

EmitModule.init()

local ClientReplicator = {}

function ClientReplicator.DaggerSwingEffect(Args)
	local Owner = Args.Owner
	local Combo = Args.Owner:GetAttribute("Combo") and tostring(Args.Owner:GetAttribute("Combo"))

	if not Combo then
		print("dont have Combo")
		return
	end

	local M1SwingDagger = Assets.VFX.Swing.M1SwingDagger:FindFirstChild(Combo)

	if not M1SwingDagger then
		print(Assets.VFX.Swing.M1SwingDagger)
		print(Assets.VFX.Swing.M1SwingDagger:GetChildren())
		print("dont have vfx")
		return
	end

	M1SwingDagger = M1SwingDagger:Clone()
	M1SwingDagger.Parent = Owner.HumanoidRootPart

	task.delay(0.01, function()
		EmitModule.emit(M1SwingDagger)
	end)
end

return ClientReplicator
