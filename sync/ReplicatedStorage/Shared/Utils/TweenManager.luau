local TweenService = game:GetService("TweenService")

local TweenManager = {}

local DefaultDuration = 0.5
local DefaultStyle = Enum.EasingStyle.Quad
local DefaultDirection = Enum.EasingDirection.Out

function TweenManager.Play(instance, properties, duration, style, direction, repeats, reverses)
	duration = duration or DefaultDuration
	style = style or DefaultStyle
	direction = direction or DefaultDirection
	repeats = repeats or 0
	reverses = reverses or false

	local tweenInfo = TweenInfo.new(duration, style, direction, repeats, reverses, 0)

	local tween = TweenService:Create(instance, tweenInfo, properties)

	tween:Play()

	tween.Completed:Connect(function()
		tween:Destroy()
	end)

	return tween
end

function TweenManager.Pulse(instance, properties, duration)
	return TweenManager.Play(instance, properties, duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, true)
end

return TweenManager
