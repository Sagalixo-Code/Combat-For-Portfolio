--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")

const ClientReplicator = ReplicatedStorage:WaitForChild("ClientReplicator")

const Common = require("@game/ReplicatedStorage/Shared/Common")
const JanitorClass = require(ReplicatedStorage.Packages.Janitor)
const RockModule = require(ReplicatedStorage.Shared.Libs.RockModule)

const Animations = ReplicatedStorage:WaitForChild("Resources"):WaitForChild("Assets"):WaitForChild("Animations")

const DirectHit = {}

type EntityArray = {
	Machine: {
		Character: Model,
		Player: Player,
	},
	EMachine: {
		Character: Model,
		Humanoid: Humanoid,
	},
}

type AttackInfo = {
	Type: string,
	Damage: number,
	KB: boolean?,
	HitReaction: boolean?,
	HitEffect: boolean?,
}

local function GetRootPart(Character: Model): BasePart?
	local RootPart = Character:FindFirstChild("HumanoidRootPart")

	if RootPart and RootPart:IsA("BasePart") then
		return RootPart
	end

	return nil
end

local function PlayAnimation(
	Humanoid: Humanoid,
	Animation: Animation,
	Priority: Enum.AnimationPriority?
): AnimationTrack
	local Track = Humanoid:LoadAnimation(Animation)

	if Priority then
		Track.Priority = Priority
	end

	Track:Play()

	return Track
end

local function ApplyKnockback(Attacker: Model, Target: Model, Force: number, UpwardForce: number)
	local AttackerRoot = GetRootPart(Attacker)
	local TargetRoot = GetRootPart(Target)

	if not AttackerRoot or not TargetRoot then
		return
	end

	local Offset = TargetRoot.Position - AttackerRoot.Position
	local Direction = Vector3.new(Offset.X, 0, Offset.Z)

	if Direction.Magnitude <= 0.001 then
		local LookVector = AttackerRoot.CFrame.LookVector
		Direction = Vector3.new(LookVector.X, 0, LookVector.Z)
	end

	if Direction.Magnitude <= 0.001 then
		return
	end

	Direction = Direction.Unit

	TargetRoot.AssemblyLinearVelocity = Vector3.new(Direction.X * Force, UpwardForce, Direction.Z * Force)
end

local function CheckWallCollision(Character: Model): (RaycastResult?, Vector3?)
	local RootPart = GetRootPart(Character)

	if not RootPart then
		return nil
	end

	local Velocity = RootPart.AssemblyLinearVelocity

	local HorizontalVelocity = Vector3.new(Velocity.X, 0, Velocity.Z)

	if HorizontalVelocity.Magnitude <= 0.1 then
		return nil
	end

	local Direction = HorizontalVelocity.Unit

	local FrameDistance = HorizontalVelocity.Magnitude / 60

	local DetectionDistance = math.max(FrameDistance + 1.5, 2.5)

	local RaycastParams = RaycastParams.new()
	RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
	RaycastParams.FilterDescendantsInstances = {
		Character,
		workspace.World.Living,
		workspace.World.Debris,
	}
	RaycastParams.IgnoreWater = true

	return workspace:Raycast(RootPart.Position, Direction * DetectionDistance, RaycastParams), Direction
end

local function HandleWallImpact(Character: Model & { Humanoid: any }, HitResult: RaycastResult, Direction: Vector3)
	local RootPart = GetRootPart(Character)

	if not RootPart then
		return
	end

	Common.Sound("WallImpact", Character)

	local Animation = Animations.Stun:FindFirstChild(`H{5}`)

	if not Animation or not Animation:IsA("Animation") then
		return
	end

	local BounceDirection = -Direction

	BounceDirection = Vector3.new(BounceDirection.X, 0, BounceDirection.Z)

	if BounceDirection.Magnitude <= 0.001 then
		return
	end

	BounceDirection = BounceDirection.Unit

	local BounceForce = 100
	local BounceUpwardForce = 8

	RootPart.AssemblyLinearVelocity =
		Vector3.new(BounceDirection.X * BounceForce, BounceUpwardForce, BounceDirection.Z * BounceForce)

	PlayAnimation(Character.Humanoid, Animation, Enum.AnimationPriority.Action2)

	ClientReplicator:FireAllClients({
		Func = "WallImpactEffect",
		Owner = Character,
		HitPart = HitResult.Instance,
		HitPosition = HitResult.Position,
		HitNormal = HitResult.Normal,
		HitMaterial = HitResult.Material,
	})
end

local function PlayHitReaction(Array: EntityArray)
	local Combo = Array.Machine.Character:GetAttribute("Combo")

	if typeof(Combo) ~= "string" and typeof(Combo) ~= "number" then
		return
	end

	local Animation = Animations.Stun:FindFirstChild(`H{Combo}`)

	if not Animation or not Animation:IsA("Animation") then
		return
	end

	PlayAnimation(Array.EMachine.Humanoid, Animation, Enum.AnimationPriority.Action2)
end

local function HandleKnockback(Array: EntityArray)
	local Character = Array.EMachine.Character
	local Humanoid = Array.EMachine.Humanoid

	local Janitor = JanitorClass.new()

	Common.StopAnims({
		Character = Character,
		Humanoid = Humanoid,
	})

	ClientReplicator:FireClient(Array.Machine.Player, {
		Owner = Array.Machine.Character,
		Func = "CamShake",
		Type = "CurveStart",
	})

	Humanoid.AutoRotate = false
	Character:SetAttribute("HighStun", true)

	local KnockbackActive = true
	local WallHit = false

	local Track = PlayAnimation(Humanoid, Animations.Knockback)
	Janitor:Add(Track, "Stop")

	local RootPart = GetRootPart(Character)

	if not RootPart then
		Janitor:Cleanup()

		Humanoid.AutoRotate = true
		Character:SetAttribute("HighStun", false)

		return
	end

	Janitor:Add(RunService.Heartbeat:Connect(function()
		if not KnockbackActive or WallHit then
			return
		end

		local CurrentRoot = GetRootPart(Character)

		if not CurrentRoot then
			return
		end

		local HitResult, Direction = CheckWallCollision(Character)

		if not HitResult or not Direction then
			return
		end

		WallHit = true

		Janitor:Cleanup()
		HandleWallImpact(Character, HitResult, Direction)
	end))

	task.spawn(function()
		for _ = 1, 3 do
			if not KnockbackActive then
				break
			end

			if WallHit then
				break
			end

			ApplyKnockback(Array.Machine.Character, Character, 100, 5)

			task.wait(0.01)
		end

		while KnockbackActive do
			if not WallHit then
				ApplyKnockback(Array.Machine.Character, Character, 32, 0)
			end

			task.wait()
		end
	end)

	Janitor:Add(Track:GetMarkerReachedSignal("freeze"):Connect(function()
		Track:AdjustSpeed(0.1)

		task.delay(0.3, function()
			if Track.IsPlaying then
				Track:AdjustSpeed(2)
			end
		end)
	end))

	Janitor:Add(Track:GetMarkerReachedSignal("impact"):Connect(function()
		if WallHit then
			return
		end
		Track:AdjustSpeed(0.1)

		task.delay(0.5, function()
			if Track.IsPlaying then
				Track:AdjustSpeed(1.85)
			end
		end)

		Common.Sound("Ground Slam", Character)

		local CurrentRoot = GetRootPart(Character)

		if not CurrentRoot then
			return
		end

		RockModule.Slam(CurrentRoot.CFrame, 7, 8, 5, false)

		RockModule.Explosion(CurrentRoot.CFrame, math.random(3, 4), 0.5, 1.5, false)
	end))

	Janitor:Add(Track:GetMarkerReachedSignal("landed"):Connect(function()
		KnockbackActive = false

		Humanoid.AutoRotate = true
		Character:SetAttribute("HighStun", false)
	end))

	Janitor:Add(Track.Stopped:Connect(function()
		KnockbackActive = false

		Humanoid.AutoRotate = true
		Character:SetAttribute("HighStun", false)

		Janitor:Cleanup()
	end))
end

function DirectHit.Init(Array: EntityArray, AttackInfo: AttackInfo)
	local Character = Array.EMachine.Character
	local Humanoid = Array.EMachine.Humanoid

	Common.StopAnims({
		Character = Character,
		Humanoid = Humanoid,
	})

	if AttackInfo.HitReaction then
		PlayHitReaction(Array)
	end

	Humanoid:TakeDamage(AttackInfo.Damage)

	if AttackInfo.KB then
		HandleKnockback(Array)
	end

	local HitType = AttackInfo.Type

	if AttackInfo.HitEffect then
		ClientReplicator:FireAllClients({
			Owner = Character,
			Func = `{HitType}HitEffect`,
		})

		Common.Sound(`{HitType}{math.random(1, 5)}`, Character)
	end
end

return DirectHit
