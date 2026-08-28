return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Workspace = game:GetService("Workspace")
	local animationsGrabbed = {}

	local function grabAnimations(givenDesc)
		for _, v in pairs(givenDesc:GetDescendants()) do
			if v:IsA("Animation") then
				table.insert(animationsGrabbed, v)
			end
		end
	end

	grabAnimations(ReplicatedStorage:WaitForChild("Resources"):WaitForChild("Assets"):WaitForChild("Animations"))

	warn("# of Animations: " .. #animationsGrabbed)

	local function createRig()
		local preloadRig = script.PreloadRig:Clone()
		preloadRig.Parent = Workspace
		return preloadRig
	end

	local rigs = {}
	local rigCount = 1

	local function preloadAnimations()
		for i, animation in animationsGrabbed do
			if i > (256 * rigCount) then
				rigCount = rigCount + 1
			end

			if not rigs[rigCount] then
				rigs[rigCount] = createRig()
				warn("Created Rig: " .. rigCount)
			end

			local Errored = select(2, pcall(function()
				if animation.AnimationId ~= "" then
					local rig = rigs[rigCount]
					local humanoid = rig:FindFirstChildOfClass("Humanoid")
					local animator = humanoid:FindFirstChildOfClass("Animator")
					local anim = (animator or humanoid):LoadAnimation(animation)
					anim:Play(0, 0, math.huge)
					task.defer(anim.Stop, anim)
				end
			end))
			if Errored then
				warn(Errored)
			end
		end
	end

	preloadAnimations()

	for count, rig in rigs do
		rig:Destroy()
		warn(rig.Name .. " " .. count .. " Destroyed")
	end

	warn("Done Preloading!")
end