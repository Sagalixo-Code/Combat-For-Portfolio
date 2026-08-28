local RockModule = {}
local TweenSerivce = game:GetService("TweenService")
local Players = game:GetService("Players")
local DebrisFolder

local function CheckDebrisFolder()
	if not workspace:FindFirstChild("Debris") then
		DebrisFolder = Instance.new("Folder")
		DebrisFolder.Name = "Debris"
		DebrisFolder.Parent = workspace
	else
		DebrisFolder = workspace:FindFirstChild("Debris")
	end
end

function RockModule.Crater(Center: CFrame, Radius: number, MinRocks: number, MaxRocks: number, PlayerCollision: boolean)
	Radius = Radius or 7
	MinRocks = MinRocks or 7
	MaxRocks = MaxRocks or 10
	if PlayerCollision == nil then
		PlayerCollision = true
	end

	CheckDebrisFolder()

	local raycastParams = RaycastParams.new()

	local players = { DebrisFolder }
	for i, v in pairs(Players:GetPlayers()) do
		local Character = v.Character
		if Character then
			table.insert(players, Character)
		end
	end
	raycastParams.FilterDescendantsInstances = players
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.IgnoreWater = true
	local ray = workspace:Raycast(Center.Position, Center.UpVector * -1000, raycastParams)

	if ray then
		local numRocks = math.round(math.random(MinRocks, MaxRocks))
		local distance = Radius
		local newCframe = CFrame.new(ray.Position)
		local angle = 0

		for i = 1, numRocks do
			local Rock = Instance.new("Part")
			Rock.Parent = DebrisFolder
			Rock.Name = "GroundSlam"
			Rock.Size = Vector3.new(math.random(3, 5), math.random(2, 3), math.random(2, 4))
			Rock.CFrame = newCframe * CFrame.Angles(0, math.rad(angle), 0) * CFrame.new(0, 0, -distance)
				+ Vector3.new(0, -5, 0)
			Rock.CFrame = CFrame.lookAt(Rock.Position, ray.Position)
			local ray2 = workspace:Raycast(
				Rock.CFrame.Position + Vector3.new(0, 7, 0),
				Vector3.new(0, 1, 0) * -1000,
				raycastParams
			)
			if ray2 then
				Rock.Color = ray2.Instance.Color
				Rock.Material = ray2.Instance.Material
				Rock.Transparency = ray2.Instance.Transparency
			else
				Rock.Color = ray.Instance.Color
				Rock.Material = ray.Instance.Material
				Rock.Transparency = ray.Instance.Transparency
			end
			if PlayerCollision == false then
				Rock.CollisionGroup = "RockDebris"
			end
			Rock.CollisionGroup = "Players"

			Rock.Anchored = true

			Rock.CanCollide = false
			game:GetService("Debris"):AddItem(Rock, 30)
			local Tween = TweenSerivce:Create(
				Rock,
				TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ Position = Rock.Position + Vector3.new(0, 4.5, 0) }
			)
			Tween:Play()
			task.spawn(function()
				task.wait(math.random(650, 950) / 100)
				local Tween = TweenSerivce:Create(
					Rock,
					TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{ Position = Rock.Position + Vector3.new(0, -5, 0), Size = Vector3.new(1, 1, 1) }
				)
				Tween:Play()
			end)
			angle += 360 / numRocks
		end
	end
end

function RockModule.Explosion(
	Center: CFrame,
	TotalRocks: number,
	MinSize: number,
	MaxSize: number,
	PlayerCollision: boolean
)
	TotalRocks = TotalRocks or 7
	MinSize = MinSize or 0.5
	MaxSize = MaxSize or 2.5
	PlayerCollision = PlayerCollision or false

	local numOfRocks = TotalRocks
	CheckDebrisFolder()

	local raycastParams = RaycastParams.new()
	local players = { DebrisFolder }
	for i, v in pairs(Players:GetPlayers()) do
		local Character = v.Character
		if Character then
			table.insert(players, Character)
		end
	end
	raycastParams.FilterDescendantsInstances = players
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.IgnoreWater = true

	local ray = workspace:Raycast(Center.Position, Center.UpVector * -100, raycastParams)

	if ray then
		for i = 1, numOfRocks do
			local Rock = Instance.new("Part")
			Rock.Name = "ExplosionPart"
			Rock.Parent = DebrisFolder

			local RandomSize = (math.random(MinSize * 100, MaxSize * 100)) / 100.0
			if math.random(1, 5) == 3 then
				Rock.Size = Vector3.new(RandomSize * 2, 0.15, RandomSize * 2)
			else
				Rock.Size = Vector3.new(RandomSize, RandomSize, RandomSize)
			end

			Rock.CFrame = Center
			Rock.Color = ray.Instance.Color
			Rock.Material = ray.Instance.Material
			Rock.Anchored = false
			Rock.Orientation = Vector3.new(math.random(-359, 359), math.random(-359, 359), math.random(-359, 359))
			Rock.Transparency = ray.Instance.Transparency
			Rock.CanCollide = true
			if PlayerCollision == false then
				Rock.CollisionGroup = "RockDebris"
			end
			Rock.CollisionGroup = "Players"

			game:GetService("Debris"):AddItem(Rock, 4.5)

			local velocitySpread = 32
			local upwardForce = 22
			local velocity = Vector3.new(
				math.random(-velocitySpread, velocitySpread),
				upwardForce,
				math.random(-velocitySpread, velocitySpread)
			)
			local bodyVelocity = Instance.new("BodyVelocity")

			bodyVelocity.Velocity = velocity
			bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
			bodyVelocity.P = 5000
			bodyVelocity.Parent = Rock

			game:GetService("Debris"):AddItem(bodyVelocity, 0.25)
			task.spawn(function()
				task.wait(4)
				local Tween = TweenSerivce:Create(
					Rock,
					TweenInfo.new(0.75, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut),
					{ Size = Vector3.new(0.1, 0.1, 0.1), Transparency = 1 }
				):Play()
			end)
		end
	end
end

function RockModule.CraterRows(
	Center: CFrame,
	Radius: number,
	Rows: number,
	NextRowRadius: number,
	MinRocks: number,
	MaxRocks: number,
	PlayerCollision: boolean
)
	if PlayerCollision == nil then
		PlayerCollision = true
	end
	Radius = Radius or 7
	MinRocks = MinRocks or 7
	MaxRocks = MaxRocks or 10
	Rows = Rows or 3
	NextRowRadius = NextRowRadius or 4
	local currentRadius = Radius
	for i = 1, Rows do
		RockModule.Crater(Center, currentRadius, MinRocks * i, MaxRocks * i, PlayerCollision)
		currentRadius += NextRowRadius
	end
end

function RockModule.ClearDebris(Fade: boolean)
	CheckDebrisFolder()

	if Fade then
		for i, v in pairs(DebrisFolder:GetChildren()) do
			if v:IsA("BasePart") then
				local Tween = TweenSerivce:Create(
					v,
					TweenInfo.new(0.75, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut),
					{ Size = Vector3.new(0.1, 0.1, 0.1), Transparency = 1 }
				):Play()
				game:GetService("Debris"):AddItem(v, 1)
			end
		end
	else
		for i, v in pairs(DebrisFolder:GetChildren()) do
			v:Destroy()
		end
	end
end

function RockModule.Slam(
	Center: CFrame,
	CraterRadius: number,
	RockCount: number,
	ExplosionCount: number,
	PlayerCollision: boolean
)
	CraterRadius = CraterRadius or 10
	RockCount = RockCount or 10
	ExplosionCount = ExplosionCount or 10
	if PlayerCollision == nil then
		PlayerCollision = false
	end

	CheckDebrisFolder()

	-- Crater chunks
	RockModule.Crater(Center, CraterRadius, RockCount, RockCount + 5, PlayerCollision)

	-- Explosion debris
	RockModule.Explosion(Center, ExplosionCount, 1.5, 3, PlayerCollision)

	-- Optional: shockwave ring
	local Shockwave = Instance.new("Part")
	Shockwave.Name = "ShockwaveRing"
	Shockwave.Size = Vector3.new(1, 0.2, 1)
	Shockwave.Anchored = true
	Shockwave.CanCollide = false
	Shockwave.Transparency = 0.5
	Shockwave.Material = Enum.Material.Neon
	Shockwave.Color = Color3.fromRGB(200, 200, 255)
	Shockwave.CFrame = Center * CFrame.new(0, 0.05, 0)
	Shockwave.Shape = Enum.PartType.Cylinder
	Shockwave.Orientation = Vector3.new(90, 0, 0)
	Shockwave.Parent = DebrisFolder
	Shockwave.CollisionGroup = "Players"

	game:GetService("Debris"):AddItem(Shockwave, 2)

	local expandTween =
		TweenSerivce:Create(Shockwave, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			Size = Vector3.new(CraterRadius * 4, 0.2, CraterRadius * 4),
			Transparency = 1,
		})
	expandTween:Play()

	-- Optional: dust particles
	local Attachment = Instance.new("Attachment")
	Attachment.Position = Vector3.new(0, 0, 0)
	Attachment.Parent = workspace.Terrain or Shockwave

	local Dust = Instance.new("ParticleEmitter")
	Dust.Texture = "rbxassetid://771221224"
	Dust.Lifetime = NumberRange.new(0.8)
	Dust.Rate = 0
	Dust.Speed = NumberRange.new(12, 20)
	Dust.Rotation = NumberRange.new(0, 360)
	Dust.RotSpeed = NumberRange.new(-30, 30)
	Dust.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 5), NumberSequenceKeypoint.new(1, 0) })
	Dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) })
	Dust.Color = ColorSequence.new(Color3.fromRGB(170, 170, 170))
	Dust.VelocitySpread = 180
	Dust.Parent = Attachment

	Dust:Emit(40)
	game:GetService("Debris"):AddItem(Attachment, 2)
end

function RockModule.Impact(Data)
	Data = Data or {}

	local Center = Data.CFrame
	if not Center then
		return
	end

	local Radius = Data.Radius or 10
	local RockCount = Data.RockCount or 20

	local RockSize = Data.RockSize or Vector2.new(2, 6)
	local RockHeight = Data.RockHeight or Vector2.new(1, 3)
	local RiseHeight = Data.RiseHeight or Vector2.new(0.5, 1.5)

	local RiseTime = Data.RiseTime or 0.12
	local HoldTime = Data.HoldTime or 0.8
	local FadeTime = Data.FadeTime or 0.5

	local DebrisEnabled = Data.Debris
	if DebrisEnabled == nil then
		DebrisEnabled = true
	end

	local DebrisCount = Data.DebrisCount or 15
	local DebrisRadius = Data.DebrisRadius or Radius * 1.15

	CheckDebrisFolder()

	local RaycastParams = RaycastParams.new()

	local Filter = { DebrisFolder }

	for _, Player in ipairs(Players:GetPlayers()) do
		if Player.Character then
			table.insert(Filter, Player.Character)
		end
	end

	RaycastParams.FilterDescendantsInstances = Filter
	RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
	RaycastParams.IgnoreWater = true

	local GroundRay = workspace:Raycast(Center.Position + Vector3.new(0, 10, 0), Vector3.new(0, -100, 0), RaycastParams)

	if not GroundRay then
		return
	end

	local GroundPosition = GroundRay.Position
	local GroundNormal = GroundRay.Normal

	local function GetGround(Position)
		local Result = workspace:Raycast(Position + Vector3.new(0, 10, 0), Vector3.new(0, -30, 0), RaycastParams)

		return Result
	end

	local function RandomRange(Range: Vector2)
		return Range.X + math.random() * (Range.Y - Range.X)
	end

	for Index = 1, RockCount do
		local Angle = math.rad((360 / RockCount) * Index + math.random(-12, 12))

		local Distance = Radius * (0.55 + math.random() * 0.45)

		local Offset = Vector3.new(math.cos(Angle) * Distance, 0, math.sin(Angle) * Distance)

		local CandidatePosition = GroundPosition + Offset
		local Ground = GetGround(CandidatePosition)

		if not Ground then
			continue
		end

		local Width = RandomRange(RockSize)
		local Height = RandomRange(RockHeight)
		local Depth = RandomRange(RockSize)

		local Rock = Instance.new("Part")
		Rock.Name = "ImpactRock"
		Rock.Size = Vector3.new(Width, Height, Depth)

		Rock.Anchored = true
		Rock.CanCollide = false
		Rock.CanTouch = false
		Rock.CanQuery = false
		Rock.CastShadow = true

		Rock.Color = Ground.Instance.Color
		Rock.Material = Ground.Instance.Material
		Rock.Transparency = Ground.Instance.Transparency

		local Direction =
			Vector3.new(CandidatePosition.X - Center.Position.X, 0, CandidatePosition.Z - Center.Position.Z)

		if Direction.Magnitude <= 0 then
			Direction = Vector3.zAxis
		else
			Direction = Direction.Unit
		end

		local Yaw = math.rad(math.random(0, 359))
		local Pitch = math.rad(math.random(-30, 30))
		local Roll = math.rad(math.random(-30, 30))

		local Rise = RandomRange(RiseHeight)

		local FinalPosition = Ground.Position + Ground.Normal * (Height * 0.15 + Rise)

		local FinalCFrame = CFrame.lookAt(FinalPosition, FinalPosition + Direction) * CFrame.Angles(Pitch, Yaw, Roll)

		local StartCFrame = FinalCFrame * CFrame.new(0, -Rise, 0)

		Rock.CFrame = StartCFrame
		Rock.Parent = DebrisFolder

		local RiseTween =
			TweenSerivce:Create(Rock, TweenInfo.new(RiseTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				CFrame = FinalCFrame,
			})

		RiseTween:Play()

		task.delay(RiseTime + HoldTime, function()
			if not Rock.Parent then
				return
			end

			local FadeTween =
				TweenSerivce:Create(Rock, TweenInfo.new(FadeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
					CFrame = FinalCFrame * CFrame.new(0, -Rise, 0),
					Transparency = 1,
					Size = Rock.Size * 0.65,
				})

			FadeTween:Play()

			FadeTween.Completed:Once(function()
				if Rock then
					Rock:Destroy()
				end
			end)
		end)
	end

	if not DebrisEnabled then
		return
	end

	for Index = 1, DebrisCount do
		local Angle = math.random() * math.pi * 2
		local Distance = math.random() * DebrisRadius

		local Offset = Vector3.new(math.cos(Angle) * Distance, 0, math.sin(Angle) * Distance)

		local Ground = GetGround(GroundPosition + Offset)

		if not Ground then
			continue
		end

		local Size = math.random(4, 12) / 10

		local Rock = Instance.new("Part")
		Rock.Name = "ImpactDebris"

		Rock.Size =
			Vector3.new(Size * math.random(7, 12) / 10, Size * math.random(5, 9) / 10, Size * math.random(7, 12) / 10)

		Rock.Anchored = false
		Rock.CanCollide = false
		Rock.CanTouch = false
		Rock.CanQuery = false
		Rock.CastShadow = true

		Rock.Color = Ground.Instance.Color
		Rock.Material = Ground.Instance.Material
		Rock.Transparency = Ground.Instance.Transparency

		Rock.Position = Ground.Position + Ground.Normal * 0.25

		Rock.Orientation = Vector3.new(math.random(-180, 180), math.random(-180, 180), math.random(-180, 180))

		Rock.Parent = DebrisFolder

		local Direction = Vector3.new(math.cos(Angle), math.random(4, 10) / 10, math.sin(Angle)).Unit

		local Velocity = Direction * math.random(12, 25)

		Rock.AssemblyLinearVelocity = Velocity
		Rock.AssemblyAngularVelocity = Vector3.new(math.random(-15, 15), math.random(-15, 15), math.random(-15, 15))

		task.delay(0.35 + math.random() * 0.25, function()
			if not Rock.Parent then
				return
			end

			local FadeTween =
				TweenSerivce:Create(Rock, TweenInfo.new(FadeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
					Size = Rock.Size * 0.1,
					Transparency = 1,
				})

			FadeTween:Play()

			FadeTween.Completed:Once(function()
				if Rock then
					Rock:Destroy()
				end
			end)
		end)
	end
end

return RockModule
-- Written by @LxckyDev
