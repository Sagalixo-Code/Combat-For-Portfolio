local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Syntax = require("@game/ReplicatedStorage/Shared/Libs/Syntax")
local Registry = require("@game/ReplicatedStorage/Shared/Libs/Forge/Registry")
local Signal = require("@game/ReplicatedStorage/Packages/Signal")

local Class = Syntax.Class

local function isAttackFromBehind(attackerPosition: Vector3, targetPart: BasePart): boolean
	local vectorToTarget = (targetPart.Position - attackerPosition).Unit
	local targetForwardDirection = targetPart.CFrame.LookVector

	return vectorToTarget:Dot(targetForwardDirection) > 0.3
end

local function checkForHits(hitManager, cframe: CFrame)
	if hitManager.Shape == "Sphere" then
		return workspace:GetPartBoundsInRadius(cframe.Position, hitManager.Size.X / 2, hitManager.OverlapParams)
	end

	return workspace:GetPartBoundsInBox(cframe, hitManager.Size, hitManager.OverlapParams)
end

local function getSweepSteps(hitManager, previousCFrame: CFrame, currentCFrame: CFrame): number
	local displacement = (currentCFrame.Position - previousCFrame.Position).Magnitude

	local relativeRotation = previousCFrame:ToObjectSpace(currentCFrame)
	local _, rotationAngle = relativeRotation:ToAxisAngle()

	local halfDiagonal = hitManager.Size.Magnitude / 2
	local rotationalDistance = halfDiagonal * rotationAngle

	local totalDistance = displacement + rotationalDistance

	local smallestAxis = math.min(hitManager.Size.X, hitManager.Size.Y, hitManager.Size.Z)

	local maxStepDistance = math.max(smallestAxis * 0.5, 0.01)

	return math.max(1, math.ceil(totalDistance / maxStepDistance))
end

local function checkForSweepHits(hitManager, previousCFrame: CFrame, currentCFrame: CFrame)
	local steps = getSweepSteps(hitManager, previousCFrame, currentCFrame)
	local results = {}

	for step = 0, steps do
		local alpha = step / steps
		local sampleCFrame = previousCFrame:Lerp(currentCFrame, alpha)

		for _, part in ipairs(checkForHits(hitManager, sampleCFrame)) do
			results[part] = true
		end
	end

	local hits = {}

	for part in results do
		table.insert(hits, part)
	end

	return hits
end

local evaluations = {
	{
		check = function(entity)
			return entity:GetAttribute("CounterFrames") == true
		end,

		result = "Counter",
	},

	{
		check = function(entity)
			return entity:GetAttribute("DeflectFrames") == true
		end,

		result = "Deflected",
	},

	{
		check = function(entity)
			return entity:GetAttribute("EvadeFrames") == true
		end,

		result = "Evaded",
	},

	{
		check = function(entity, attackerPos)
			return isAttackFromBehind(attackerPos, entity.HumanoidRootPart)
		end,

		result = "DirectHit",
	},

	{
		check = function(entity, attackerPos)
			return not isAttackFromBehind(attackerPos, entity.HumanoidRootPart)
				and entity:GetAttribute("Blocking") == true
		end,

		result = "Blocked",
	},
}

local HitManager = Class({
	constructor = function(this, args)
		print("new")
		this.Shape = args.Shape or "Sphere"
		this.Size = args.Size or Vector3.new(5, 5, 5)
		this.CFrame = args.CFrame

		this.StartTime = args.StartTime or time()
		this.EndTime = args.EndTime or this.StartTime + 1

		this.Character = args.Character
		this.Connection = nil

		this.AttackerPlayer = Players:GetPlayerFromCharacter(this.Character)

		this.Sweep = args.Sweep == true
		this.PreviousCFrame = nil

		this.Started = false
		this.Destroyed = false

		this.OverlapParams = OverlapParams.new()
		this.OverlapParams.FilterType = Enum.RaycastFilterType.Exclude

		local filterList = { this.Character }

		if args.Filter then
			for _, instance in ipairs(args.Filter) do
				table.insert(filterList, instance)
			end
		end

		this.OverlapParams.FilterDescendantsInstances = filterList

		this.AlreadyHit = {}

		this.Hit = Signal.new()

		this.EntityService = Registry:getService("EntityService")
		this.TagService = Registry:getService("TagService")
	end,

	Start = function(this)
		if this.Destroyed or this.Started then
			return
		end

		if not this.CFrame then
			return
		end

		this.Started = true

		if RunService:IsStudio() then
			this:GenerateHitboxDebugOverlay(
				this.CFrame,
				this.Size,
				math.max(this.EndTime - math.max(time(), this.StartTime), 0)
			)
		end

		this.PreviousCFrame = this.CFrame

		local duration = math.max(this.EndTime - this.StartTime, 0)

		local function disconnect()
			if this.Connection then
				this.Connection:Disconnect()
				this.Connection = nil
			end
		end

		this.Connection = RunService.Heartbeat:Connect(function()
			local now = time()

			if now < this.StartTime then
				return
			end

			if now >= this.EndTime or duration <= 0 then
				disconnect()
				this.Started = false
				return
			end

			local currentCFrame = this.CFrame

			if not currentCFrame then
				disconnect()
				this.Started = false
				return
			end

			local hits

			if this.Sweep and this.PreviousCFrame then
				hits = checkForSweepHits(this, this.PreviousCFrame, currentCFrame)
			else
				hits = checkForHits(this, currentCFrame)
			end

			this.PreviousCFrame = currentCFrame

			for _, hittedPart in ipairs(hits) do
				local Target = hittedPart:FindFirstAncestorOfClass("Model")

				if not Target or this.AlreadyHit[Target] then
					continue
				end

				local Humanoid = Target:FindFirstChildOfClass("Humanoid")
				local RootPart = Humanoid and Humanoid.RootPart

				if not Humanoid or not RootPart or Humanoid.Health <= 0 then
					continue
				end

				local targetPlayer = Players:GetPlayerFromCharacter(Target)

				if not this.AttackerPlayer or not targetPlayer then
					continue
				end

				this.AlreadyHit[Target] = true

				local attackerRootPart = this.Character:FindFirstChild("HumanoidRootPart")

				if not attackerRootPart then
					continue
				end

				local ImpactResult = this:EvaluateImpact(Target, attackerRootPart.Position)

				local TagInfo = {
					EMachine = this.EntityService.getEntity(targetPlayer.UserId),
					Machine = this.EntityService.getEntity(this.AttackerPlayer.UserId),
					Outcome = ImpactResult,
				}

				this.Hit:Fire({
					TagInfo = TagInfo,
					TagService = this.TagService,
				})
			end
		end)

		return this.Connection
	end,

	Stop = function(this)
		if not this.Started then
			return
		end

		this.Started = false

		if this.Connection then
			this.Connection:Disconnect()
			this.Connection = nil
		end
	end,

	Destroy = function(this)
		if this.Destroyed then
			return
		end

		this.Destroyed = true
		this.Started = false

		if this.Connection then
			this.Connection:Disconnect()
			this.Connection = nil
		end

		if this.Hit then
			this.Hit:Destroy()
		end

		table.clear(this.AlreadyHit)

		this.PreviousCFrame = nil
	end,

	GenerateHitboxDebugOverlay = function(this, hitboxCFrame: CFrame, hitboxSize: Vector3, Length: number)
		if not RunService:IsStudio() then
			return
		end

		local debugIndicator = Instance.new("Part")

		debugIndicator.Size = hitboxSize
		debugIndicator.CFrame = hitboxCFrame
		debugIndicator.Anchored = true
		debugIndicator.Massless = true
		debugIndicator.CanCollide = false
		debugIndicator.CanQuery = false
		debugIndicator.Transparency = 0.5
		debugIndicator.Material = Enum.Material.ForceField
		debugIndicator.BrickColor = BrickColor.new("Bright red")
		debugIndicator.Parent = workspace

		TweenService:Create(debugIndicator, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
			Transparency = 1,
		}):Play()

		Debris:AddItem(debugIndicator, Length or 0.1)
	end,

	EvaluateImpact = function(this, targetEntity, attackerPosition)
		for _, evaluation in ipairs(evaluations) do
			if evaluation.check(targetEntity, attackerPosition) then
				return evaluation.result
			end
		end

		return "DirectHit"
	end,
})

return HitManager
