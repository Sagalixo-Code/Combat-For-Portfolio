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

local function checkForHits(hitManager)
	if hitManager.Shape == "Sphere" then
		return workspace:GetPartBoundsInRadius(
			hitManager.CFrame.Position,
			hitManager.Size.X / 2,
			hitManager.OverlapParams
		)
	end
	return workspace:GetPartBoundsInBox(hitManager.CFrame, hitManager.Size, hitManager.OverlapParams)
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
		this.Shape = args.Shape or "Sphere"
		this.Size = args.Size or Vector3.new(5, 5, 5)
		this.CFrame = args.CFrame
		this.StartTime = args.StartTime or time()
		this.EndTime = args.EndTime or this.StartTime + 1
		this.Character = args.Character
		this.Connection = nil
		this.AttackerPlayer = Players:GetPlayerFromCharacter(this.Character)

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
		if not this.CFrame then
			return
		end

		if this.Destroyed then
			return
		end

		if RunService:IsStudio() then
			this:GenerateHitboxDebugOverlay(this.CFrame, this.Size, this.EndTime - this.StartTime)
		end

		local elapsedTime = 0
		this.Started = true
		this.Stop = false

		this.Connection = RunService.Heartbeat:Connect(function(dt: number)
			elapsedTime += dt

			if elapsedTime >= this.EndTime - this.StartTime then
				this.Connection:Disconnect()
				return
			end

			for _, hittedPart in ipairs(checkForHits(this)) do
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

				local ImpactResult = this:EvaluateImpact(Target, this.Character.HumanoidRootPart.Position)
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
		this.Stop = true
		this.Started = false
		this.Connection:Disconnect()
	end,

	Destroy = function(this)
		this.Destroyed = true
		this.Started = false
		this.Connection:Disconnect()
		this.Hit:Destroy()
		this.Connection = nil
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
		debugIndicator.Transparency = 0.8
		debugIndicator.Material = Enum.Material.ForceField
		debugIndicator.BrickColor = BrickColor.new("Bright red")
		debugIndicator.Parent = workspace
		TweenService:Create(
			debugIndicator,
			TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
			{ Transparency = 1 }
		):Play()
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
