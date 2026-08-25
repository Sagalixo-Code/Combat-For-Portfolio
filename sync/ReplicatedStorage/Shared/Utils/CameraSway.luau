local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local CameraSway = {}

local BindName = "CameraSway"
local Camera = workspace.CurrentCamera

local Enabled = false
local BaseCFrame

local Config = {
	MaxYaw = 2.5,
	MaxPitch = 1.5,
	Smoothness = 8,
}

local CurrentYaw = 0
local CurrentPitch = 0

local function GetMouseOffset()
	local ViewportSize = Camera.ViewportSize
	local MousePosition = UserInputService:GetMouseLocation()

	local Center = ViewportSize / 2

	local X = (MousePosition.X - Center.X) / Center.X
	local Y = (MousePosition.Y - Center.Y) / Center.Y

	return math.clamp(X, -1, 1), math.clamp(Y, -1, 1)
end

local function Update(DeltaTime)
	if not Enabled then
		return
	end

	if Camera.CameraType ~= Enum.CameraType.Scriptable then
		return
	end

	local MouseX, MouseY = GetMouseOffset()

	local TargetYaw = MouseX * Config.MaxYaw
	local TargetPitch = MouseY * Config.MaxPitch

	local Alpha = 1 - math.exp(-Config.Smoothness * DeltaTime)

	CurrentYaw += (TargetYaw - CurrentYaw) * Alpha
	CurrentPitch += (TargetPitch - CurrentPitch) * Alpha

	Camera.CFrame = BaseCFrame * CFrame.Angles(math.rad(-CurrentPitch), math.rad(-CurrentYaw), 0)
end

function CameraSway.Enable()
	if Enabled then
		return
	end

	Enabled = true

	BaseCFrame = Camera.CFrame

	CurrentYaw = 0
	CurrentPitch = 0

	RunService:BindToRenderStep(BindName, Enum.RenderPriority.Camera.Value + 1, Update)
end

function CameraSway.Disable()
	if not Enabled then
		return
	end

	Enabled = false

	RunService:UnbindFromRenderStep(BindName)

	CurrentYaw = 0
	CurrentPitch = 0
	BaseCFrame = nil
end

function CameraSway.SetMaxYaw(Angle)
	Config.MaxYaw = Angle
end

function CameraSway.SetMaxPitch(Angle)
	Config.MaxPitch = Angle
end

function CameraSway.SetSmoothness(Smoothness)
	Config.Smoothness = Smoothness
end

return CameraSway
