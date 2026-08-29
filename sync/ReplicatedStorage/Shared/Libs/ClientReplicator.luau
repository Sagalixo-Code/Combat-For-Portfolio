local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local EmitModule = require(ReplicatedStorage.EmitModule)

local Resources = ReplicatedStorage:WaitForChild("Resources")
local Assets = Resources:WaitForChild("Assets")

local CameraShaker = require(script.CameraShaker)

local rig = workspace.World.Living:WaitForChild(Players.LocalPlayer.Name)
rig.Archivable = true

local DEFAULTS = {
	GhostColor = Color3.fromRGB(255, 255, 255),
	OutlineColor = Color3.fromRGB(255, 255, 255),

	Duration = 0.3,
	Interval = 0.06,

	Transparency = 0.9,

	FillTransparency = 0.5,
	OutlineTransparency = 0,

	DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,

	EasingStyle = Enum.EasingStyle.Quad,
	EasingDirection = Enum.EasingDirection.Out,
}

local function createTemplate(Data)
	local template = rig:Clone()

	for _, obj in ipairs(template:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Anchored = true
			obj.CanCollide = false
			obj.CanTouch = false
			obj.CanQuery = false
			obj.CastShadow = false

			obj.Transparency = Data.Transparency
			obj.Color = Data.GhostColor
			obj.Material = Enum.Material.Neon

			if obj.Name == "HumanoidRootPart" then
				obj:Destroy()
			end
		elseif not (obj:IsA("SpecialMesh") or obj:IsA("MeshPart")) then
			obj:Destroy()
		end
	end

	return template
end

local function createAfterImage(Data)
	local template = createTemplate(Data)
	local ghost = template:Clone()

	local TweenInfoData = TweenInfo.new(Data.FadeTime, Data.EasingStyle, Data.EasingDirection)

	for _, part in ipairs(ghost:GetDescendants()) do
		if not part:IsA("BasePart") then
			continue
		end

		local originalPart = rig:FindFirstChild(part.Name, true)

		if originalPart and originalPart:IsA("BasePart") then
			part.CFrame = originalPart.CFrame
			TweenService:Create(part, TweenInfoData, {
				Transparency = 1,
			}):Play()
		end
	end

	local highlight = Instance.new("Highlight")

	highlight.FillColor = Data.GhostColor
	highlight.FillTransparency = Data.FillTransparency

	highlight.OutlineColor = Data.OutlineColor
	highlight.OutlineTransparency = Data.OutlineTransparency

	highlight.DepthMode = Data.DepthMode
	highlight.Parent = ghost

	TweenService:Create(highlight, TweenInfoData, {
		FillTransparency = 1,
		OutlineTransparency = 1,
	}):Play()

	ghost.Parent = workspace

	Debris:AddItem(ghost, Data.FadeTime + 0.1)
end

local isCreatingAfterImages = false

local function startAfterImageLoop(Data)
	if isCreatingAfterImages then
		return
	end

	isCreatingAfterImages = true

	task.spawn(function()
		while isCreatingAfterImages do
			createAfterImage(Data)
			task.wait(Data.Interval)
		end
	end)
end

local function stopAfterImageLoop()
	isCreatingAfterImages = false
end

local function getData(Data)
	Data = Data or {}

	return {
		GhostColor = Data.GhostColor or DEFAULTS.GhostColor,
		OutlineColor = Data.OutlineColor or DEFAULTS.OutlineColor,

		Duration = Data.Duration or DEFAULTS.Duration,
		Interval = Data.Interval or DEFAULTS.Interval,

		Transparency = Data.Transparency or DEFAULTS.Transparency,

		FillTransparency = Data.FillTransparency or DEFAULTS.FillTransparency,
		OutlineTransparency = Data.OutlineTransparency or DEFAULTS.OutlineTransparency,

		DepthMode = Data.DepthMode or DEFAULTS.DepthMode,

		FadeTime = Data.FadeTime or Data.Duration or DEFAULTS.Duration,

		EasingStyle = Data.EasingStyle or DEFAULTS.EasingStyle,
		EasingDirection = Data.EasingDirection or DEFAULTS.EasingDirection,
	}
end

local function camShake(whatType)
	local CamShake = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(ShakeCFrame)
		workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame * ShakeCFrame
	end)
	CamShake:Start()
	CamShake:Shake(CameraShaker.Presets[whatType])
end

EmitModule.init()

local ClientReplicator = {}

ClientReplicator.CamShake = function(Args)
	camShake(Args.Type)
end

function ClientReplicator.AfterImages(Args)
	local Data = getData(Args.Data)

	startAfterImageLoop(Data)

	task.delay(Data.Duration, function()
		stopAfterImageLoop()
	end)
end

function ClientReplicator.DaggerSwingEffect(Args)
	local Owner = Args.Owner

	local Combo = Args.Combo

	if not Combo then
		Combo = Args.Owner:GetAttribute("Combo") and tostring(Args.Owner:GetAttribute("Combo"))
	end

	local M1SwingDagger = Assets.VFX.Swing.M1SwingDagger:FindFirstChild(Combo)

	if not M1SwingDagger then
		print(Assets.VFX.Swing.M1SwingDagger)
		print(Assets.VFX.Swing.M1SwingDagger:GetChildren())
		print("dont have vfx")
		return
	end

	M1SwingDagger = M1SwingDagger:Clone()

	Debris:AddItem(M1SwingDagger, 5)

	M1SwingDagger.Parent = Owner.HumanoidRootPart

	task.delay(0.01, function()
		EmitModule.emit(M1SwingDagger)
	end)
end

function ClientReplicator.SharpHitEffect(Args)
	local Owner = Args.Owner

	local SharpHitEffect = Assets.VFX:FindFirstChild("Sharp")

	if not SharpHitEffect then
		print("dont have vfx")
		return
	end

	SharpHitEffect = SharpHitEffect:Clone()

	Debris:AddItem(SharpHitEffect, 5)

	SharpHitEffect.Parent = workspace.World.Debris
	SharpHitEffect.CFrame = Owner.HumanoidRootPart.CFrame

	task.delay(0.01, function()
		EmitModule.emit(SharpHitEffect)
	end)
end

function ClientReplicator.KickHitEffect(Args)
	local Owner = Args.Owner

	local KickHit = Assets.VFX:FindFirstChild("KickHit")

	if not KickHit then
		print("dont have vfx")
		return
	end

	KickHit = KickHit:Clone()

	Debris:AddItem(KickHit, 5)

	KickHit.Parent = workspace.World.Debris
	KickHit.CFrame = Owner.HumanoidRootPart.CFrame

	task.delay(0.01, function()
		EmitModule.emit(KickHit)
	end)
end

function ClientReplicator.WallImpactEffect(Args)
	local WallImpactSmoke = Assets.VFX:FindFirstChild("WallImpactSmoke")

	if not WallImpactSmoke then
		print("dont have vfx")
		return
	end

	WallImpactSmoke = WallImpactSmoke:Clone()

	Debris:AddItem(WallImpactSmoke, 5)

	WallImpactSmoke.Parent = workspace.World.Debris
	WallImpactSmoke.Orientation = Args.HitNormal
	WallImpactSmoke.Position = Args.HitPosition + (Args.HitPart.CFrame.LookVector * 0.25)

	task.delay(0.01, function()
		EmitModule.emit(WallImpactSmoke)
	end)
end

function ClientReplicator.Critical(Args)
	local Owner = Args.Owner

	local CRIT = Assets.VFX:FindFirstChild("CRIT")

	if not CRIT then
		print("dont have vfx")
		return
	end

	CRIT = CRIT:Clone()

	Debris:AddItem(CRIT, 5)

	CRIT.Parent = workspace.World.Debris
	CRIT.CFrame = Owner.HumanoidRootPart.CFrame

	task.delay(0.01, function()
		local highlight = Instance.new("Highlight")
		highlight.FillColor = Color3.fromRGB(255, 255, 255)
		highlight.FillTransparency = 0.3
		highlight.OutlineTransparency = 1
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.Adornee = Owner
		highlight.Parent = Owner

		task.spawn(function()
			task.wait(0.05)
			for i = 0.3, 1, 0.025 do
				if highlight then
					highlight.FillTransparency = i
					task.wait(0.0001)
				end
			end
			if highlight then
				highlight:Destroy()
			end
		end)

		EmitModule.emit(CRIT)
	end)
end

return ClientReplicator
