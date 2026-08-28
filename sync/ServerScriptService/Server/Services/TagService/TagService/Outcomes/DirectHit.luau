const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ClientReplicator = ReplicatedStorage:WaitForChild("ClientReplicator")
const Common = require("@game/ReplicatedStorage/Shared/Common")
const JanitorClass = require(ReplicatedStorage.Packages.Janitor)
local RockModule = require(ReplicatedStorage.Shared.Libs.RockModule)

const Animations = ReplicatedStorage:WaitForChild("Resources"):WaitForChild("Assets"):WaitForChild("Animations")

const DirectHit = {}

local function ApplyKnockback(Attacker: Model, Target: Model, Force: number, UpwardForce: number)
	local AttackerRoot = Attacker:FindFirstChild("HumanoidRootPart")
	local TargetRoot = Target:FindFirstChild("HumanoidRootPart")

	if not AttackerRoot or not TargetRoot then
		return
	end

	if not AttackerRoot:IsA("BasePart") or not TargetRoot:IsA("BasePart") then
		return
	end

	local Direction = TargetRoot.Position - AttackerRoot.Position

	if Direction.Magnitude <= 0.001 then
		Direction = AttackerRoot.CFrame.LookVector
	else
		Direction = Direction.Unit
	end

	Direction = Vector3.new(Direction.X, 0, Direction.Z)

	if Direction.Magnitude <= 0.001 then
		Direction = AttackerRoot.CFrame.LookVector
		Direction = Vector3.new(Direction.X, 0, Direction.Z).Unit
	end

	TargetRoot.AssemblyLinearVelocity = Vector3.new(Direction.X * Force, UpwardForce, Direction.Z * Force)
end

DirectHit.Init = function(Array, AttackInfo)
	Common.StopAnims({
		Character = Array.EMachine.Character,
		Humanoid = Array.EMachine.Humanoid,
	})

	if AttackInfo.HitReaction then
		const AnimationInst = Animations.Stun:FindFirstChild("H" .. Array.Machine.Character:GetAttribute("Combo"))

		if AnimationInst then
			const Swing: AnimationTrack = Array.EMachine.Humanoid:LoadAnimation(AnimationInst)
			Swing.Priority = Enum.AnimationPriority.Action2
			Swing:Play()
		end
	end

	local Type = AttackInfo.Type
	Array.EMachine.Character.Humanoid:TakeDamage(AttackInfo.Damage)

	if AttackInfo.KB then
		local Janitor = JanitorClass.new()

		Common.StopAnims({
			Character = Array.EMachine.Character,
			Humanoid = Array.EMachine.Humanoid,
		})

		ClientReplicator:FireClient(
			Array.Machine.Player,
			{ Owner = Array.Machine.Character, Func = "CamShake", Type = "CurveStart" }
		)

		Array.EMachine.Humanoid.AutoRotate = false
		local Velocity = true
		local Swing: AnimationTrack = Array.EMachine.Humanoid:LoadAnimation(Animations.Knockback)
		Swing:Play()

		task.spawn(function()
			for i = 1, 3 do
				ApplyKnockback(Array.Machine.Character, Array.EMachine.Character, 100, 5)
				task.wait(0.01)
			end
			while Velocity do
				ApplyKnockback(Array.Machine.Character, Array.EMachine.Character, 32, 0)
				task.wait()
			end
		end)

		Array.EMachine.Character:SetAttribute("HighStun", true)

		Janitor:Add(Swing:GetMarkerReachedSignal("freeze"):Connect(function()
			Swing:AdjustSpeed(0.1)
			task.delay(0.3, function()
				Swing:AdjustSpeed(2)
			end)
		end))

		Janitor:Add(Swing:GetMarkerReachedSignal("impact"):Connect(function()
			Swing:AdjustSpeed(0.1)
			task.delay(0.5, function()
				Swing:AdjustSpeed(1.85)
			end)

			RockModule.Slam(Array.EMachine.Character.HumanoidRootPart.CFrame, 8, 9, 6, false)
		end))

		Janitor:Add(Swing:GetMarkerReachedSignal("landed"):Connect(function()
			Velocity = false
			Array.EMachine.Humanoid.AutoRotate = true
			Array.EMachine.Character:SetAttribute("HighStun", false)
		end))

		Janitor:Add(Swing.Stopped:Connect(function()
			Janitor:Cleanup()
		end))
	end

	ClientReplicator:FireAllClients({ Owner = Array.EMachine.Character, Func = Type .. "HitEffect" })

	if Type and AttackInfo.HitEffect then
		Common.Sound(Type .. math.random(1, 5), Array.EMachine.Character)
		ClientReplicator:FireAllClients({ Owner = Array.EMachine.Character, Func = Type .. "HitEffect" })
	end
end

return DirectHit
