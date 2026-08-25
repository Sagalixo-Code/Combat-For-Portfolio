local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local function SetupMovement(character: Model, player)
	task.wait(5)

	local root = character:WaitForChild("HumanoidRootPart", 5)
	local humanoid = character:WaitForChild("Humanoid", 5)
	local torso = character:WaitForChild("Torso", 5)

	if not root or not humanoid or not torso then
		return
	end

	torso:WaitForChild("Neck", 5)
	torso:WaitForChild("Right Shoulder", 5)
	torso:WaitForChild("Left Shoulder", 5)
	torso:WaitForChild("Right Hip", 5)
	torso:WaitForChild("Left Hip", 5)
	root:WaitForChild("RootJoint", 5)

	local Joints = {
		RootJoint = root.RootJoint,
		Neck = torso.Neck,
		RightShoulder = torso["Right Shoulder"],
		LeftShoulder = torso["Left Shoulder"],
		RightHip = torso["Right Hip"],
		LeftHip = torso["Left Hip"],
	}

	local BackupJointsC0 = {}

	local JointTilts = {}

	for name, joint in pairs(Joints) do
		BackupJointsC0[name] = joint.C0
		JointTilts[name] = CFrame.new()
	end

	local function RefreshJointBases()
		for name, joint in pairs(Joints) do
			JointTilts[name] = CFrame.new()

			local scaledC0 = joint:GetAttribute("ScaledC0")

			if scaledC0 then
				BackupJointsC0[name] = scaledC0
			else
				BackupJointsC0[name] = joint.C0
			end

			joint.C0 = BackupJointsC0[name]
		end
	end

	local SMOOTH_SPEED = 7

	local function SmoothCFrame(current, target, dt)
		local alpha = 1 - math.exp(-SMOOTH_SPEED * dt)
		return current:Lerp(target, alpha)
	end

	local function ApplyJoint(name, angles, dt)
		local joint = Joints[name]
		if not joint then
			return
		end

		local baseC0 = joint:GetAttribute("ScaledC0") or BackupJointsC0[name]

		if not baseC0 then
			return
		end

		local target = CFrame.Angles(unpack(angles))

		JointTilts[name] = SmoothCFrame(JointTilts[name], target, dt)

		joint.C0 = baseC0 * JointTilts[name]
	end

	local function ResetJoints(dt)
		for name in pairs(JointTilts) do
			ApplyJoint(name, { 0, 0, 0 }, dt)
		end
	end

	local refreshing = false

	local function Refresh()
		if refreshing then
			return
		end

		refreshing = true

		task.defer(function()
			if not character:IsDescendantOf(workspace) then
				refreshing = false
				return
			end

			RefreshJointBases()

			refreshing = false
		end)
	end

	character:GetAttributeChangedSignal("Unit"):Connect(Refresh)

	RefreshJointBases()

	local conn

	conn = RunService.Heartbeat:Connect(function(dt)
		if not character:IsDescendantOf(workspace) or humanoid.Health <= 0 then
			conn:Disconnect()
			return
		end

		local moveWorld = humanoid.MoveDirection

		if moveWorld.Magnitude < 0.1 or player:GetAttribute("NotDirectional") then
			ResetJoints(dt)
			return
		end

		local move = root.CFrame:VectorToObjectSpace(moveWorld)

		move = Vector3.new(math.clamp(move.X, -1, 1), 0, math.clamp(move.Z, -1, 1))

		local forwardLean = -move.Z * 10
		local sideLean = -move.X * 35

		ApplyJoint("RootJoint", { math.rad(forwardLean), 0, math.rad(sideLean) }, dt)

		ApplyJoint("Neck", { math.rad(-forwardLean), 0, math.rad(-sideLean) }, dt)

		ApplyJoint("RightShoulder", { 0, math.rad(sideLean * 0.4), 0 }, dt)

		ApplyJoint("LeftShoulder", { 0, math.rad(sideLean * 0.4), 0 }, dt)

		ApplyJoint("RightHip", { 0, math.rad(sideLean * 0.4), 0 }, dt)

		ApplyJoint("LeftHip", { 0, math.rad(sideLean * 0.4), 0 }, dt)
	end)
end

local function onCharacterAdded(player, character)
	task.spawn(SetupMovement, character, player)
end

local function onPlayerAdded(player)
	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	end

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
