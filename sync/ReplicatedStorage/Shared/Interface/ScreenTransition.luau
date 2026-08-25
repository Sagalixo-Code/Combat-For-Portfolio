local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenManager = require(ReplicatedStorage.Shared.Utils.TweenManager)
local ScreenTransition = {}

local Interface = ((Players.LocalPlayer.PlayerGui) :: typeof(StarterGui)):WaitForChild("ScreenTransition")

function ScreenTransition:Blackout()
	Interface.Main.Visible = true
	Interface.Main.Size = UDim2.fromScale(1.5, 3)

	TweenManager.Play(Interface.Main, {
		Size = UDim2.fromScale(1.5, 0),
	}, 0.8, Enum.EasingStyle.Quad)
end

function ScreenTransition:Reveal()
	TweenManager.Play(Interface.Main, {
		Size = UDim2.fromScale(1.5, 2),
	}, 1, Enum.EasingStyle.Back, Enum.EasingDirection.In).Completed
		:Connect(function()
			Interface.Main.Visible = false
		end)
end

return ScreenTransition
