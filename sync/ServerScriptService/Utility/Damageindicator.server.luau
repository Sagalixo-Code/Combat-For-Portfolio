local Players = game:GetService("Players")

-- Applies a fading red highlight to the character
local function applyDamageHighlight(character)
	local highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.fromRGB(255, 0, 0)
	highlight.FillTransparency = 0.3
	highlight.OutlineTransparency = 1
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Adornee = character
	highlight.Parent = character

	-- Fade out over time
	task.spawn(function()
		task.wait(0.05)
		for i = 0.3, 1, 0.025 do
			if highlight then
				highlight.FillTransparency = i
				task.wait(0.000035)
			end
		end
		if highlight then
			highlight:Destroy()
		end
	end)
end

-- Sets up damage listener on a character
local function setupDamageListener(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local lastHealth = humanoid.Health

	humanoid.HealthChanged:Connect(function(currentHealth)
		if currentHealth < lastHealth then
			applyDamageHighlight(character)
		end
		lastHealth = currentHealth
	end)
end

-- Listen for players spawning
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		setupDamageListener(character)
	end)
end)

-- Optional: support existing players in Studio test mode
for _, player in ipairs(Players:GetPlayers()) do
	if player.Character then
		setupDamageListener(player.Character)
	end
	player.CharacterAdded:Connect(setupDamageListener)
end
