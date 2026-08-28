-- humanoidAnimatePlayEmote V2 (Modernizado)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Figure = script.Parent
local Humanoid = Figure:WaitForChild("Humanoid")
local Animator = Humanoid:WaitForChild("Animator", 5) or Instance.new("Animator", Humanoid)
local pose = "Standing"

local TRANSITIONS = {
	Default = 0.2, 
	Walk = 0.3,   
	Idle = 0.3,     
	Fall = 0.4,     
	Emote = 0.2,    
	Tool = 0.1    
}

local FFlagUserAnimateRemoveEmoteChatHook
do
	local success, result = pcall(function()
		return UserSettings():IsUserFeatureEnabled("UserAnimateRemoveEmoteChatHook")
	end)
	FFlagUserAnimateRemoveEmoteChatHook = success and result
end

local function getRigScale()
	return Figure:GetScale()
end

local currentAnim = ""
local currentAnimInstance = nil
local currentAnimTrack = nil
local currentAnimKeyframeHandler = nil
local currentAnimSpeed = 1.0

local animTable = {}
local loadedTracks = {}

local animNames = {
	idle = 	{ { id = "http://www.roblox.com/asset/?id=180435571", weight = 9 }, { id = "http://www.roblox.com/asset/?id=180435792", weight = 1 } },
	walk = 	{ { id = "http://www.roblox.com/asset/?id=180426354", weight = 10 } },
	jump = 	{ { id = "http://www.roblox.com/asset/?id=125750702", weight = 10 } },
	fall = 	{ { id = "http://www.roblox.com/asset/?id=180436148", weight = 10 } },
	climb = { { id = "http://www.roblox.com/asset/?id=180436334", weight = 10 } },
	sit = 	{ { id = "http://www.roblox.com/asset/?id=178130996", weight = 10 } },
	toolnone = { { id = "http://www.roblox.com/asset/?id=182393478", weight = 10 } },
	toolslash = { { id = "http://www.roblox.com/asset/?id=129967390", weight = 10 } },
	toollunge = { { id = "http://www.roblox.com/asset/?id=129967478", weight = 10 } },
	wave = { { id = "http://www.roblox.com/asset/?id=128777973", weight = 10 } },
	point = { { id = "http://www.roblox.com/asset/?id=128853357", weight = 10 } },
	dance1 = { { id = "http://www.roblox.com/asset/?id=182435998", weight = 10 }, { id = "http://www.roblox.com/asset/?id=182491037", weight = 10 }, { id = "http://www.roblox.com/asset/?id=182491065", weight = 10 } },
	dance2 = { { id = "http://www.roblox.com/asset/?id=182436842", weight = 10 }, { id = "http://www.roblox.com/asset/?id=182491248", weight = 10 }, { id = "http://www.roblox.com/asset/?id=182491277", weight = 10 } },
	dance3 = { { id = "http://www.roblox.com/asset/?id=182436935", weight = 10 }, { id = "http://www.roblox.com/asset/?id=182491368", weight = 10 }, { id = "http://www.roblox.com/asset/?id=182491423", weight = 10 } },
	laugh = { { id = "http://www.roblox.com/asset/?id=129423131", weight = 10 } },
	cheer = { { id = "http://www.roblox.com/asset/?id=129423030", weight = 10 } },
}

local dances = {"dance1", "dance2", "dance3"}
local emoteNames = { wave = false, point = false, dance1 = false, dance2 = false, dance3 = false, laugh = false, cheer = false}

function configureAnimationSet(name, fileList)
	if animTable[name] ~= nil then
		for _, connection in pairs(animTable[name].connections) do
			connection:Disconnect()
		end
	end

	animTable[name] = { count = 0, totalWeight = 0, connections = {} }

	local config = script:FindFirstChild(name)
	if config ~= nil then
		table.insert(animTable[name].connections, config.ChildAdded:Connect(function() configureAnimationSet(name, fileList) end))
		table.insert(animTable[name].connections, config.ChildRemoved:Connect(function() configureAnimationSet(name, fileList) end))

		local idx = 1
		for _, childPart in pairs(config:GetChildren()) do
			if childPart:IsA("Animation") then
				table.insert(animTable[name].connections, childPart.Changed:Connect(function() configureAnimationSet(name, fileList) end))
				animTable[name][idx] = { anim = childPart }

				local weightObject = childPart:FindFirstChild("Weight")
				animTable[name][idx].weight = weightObject and weightObject.Value or 1

				animTable[name].count += 1
				animTable[name].totalWeight += animTable[name][idx].weight
				idx += 1
			end
		end
	end

	if animTable[name].count <= 0 then
		for idx, anim in pairs(fileList) do
			animTable[name][idx] = {
				anim = Instance.new("Animation"),
				weight = anim.weight
			}
			animTable[name][idx].anim.Name = name
			animTable[name][idx].anim.AnimationId = anim.id

			animTable[name].count += 1
			animTable[name].totalWeight += anim.weight
		end
	end
end

for name, fileList in pairs(animNames) do 
	configureAnimationSet(name, fileList)
end

for _, track in ipairs(Animator:GetPlayingAnimationTracks()) do
	track:Stop(0)
	track:Destroy()
end

function stopAllAnimations(transitionOverride)
	local oldAnim = currentAnim
	if emoteNames[oldAnim] ~= nil and emoteNames[oldAnim] == false then
		oldAnim = "idle"
	end

	currentAnim = ""
	currentAnimInstance = nil

	if currentAnimKeyframeHandler then
		currentAnimKeyframeHandler:Disconnect()
	end

	if currentAnimTrack then
		currentAnimTrack:Stop(transitionOverride or TRANSITIONS.Default)
		currentAnimTrack = nil
	end
	return oldAnim
end

function setAnimationSpeed(speed)
	if speed ~= currentAnimSpeed and currentAnimTrack then
		currentAnimSpeed = speed
		currentAnimTrack:AdjustSpeed(currentAnimSpeed)
	end
end

function keyFrameReachedFunc(frameName)
	if frameName == "End" then
		local repeatAnim = currentAnim
		if emoteNames[repeatAnim] ~= nil and emoteNames[repeatAnim] == false then
			repeatAnim = "idle"
		end

		local animSpeed = currentAnimSpeed
		playAnimation(repeatAnim, TRANSITIONS.Idle)
		setAnimationSpeed(animSpeed)
	end
end

function playAnimation(animName, transitionTime) 
	local roll = math.random(1, animTable[animName].totalWeight) 
	local idx = 1
	while roll > animTable[animName][idx].weight do
		roll -= animTable[animName][idx].weight
		idx += 1
	end

	local anim = animTable[animName][idx].anim

	if anim ~= currentAnimInstance then
		if currentAnimTrack then
			currentAnimTrack:Stop(transitionTime or TRANSITIONS.Default)
		end

		currentAnimSpeed = 1.0

		if not loadedTracks[anim] then
			loadedTracks[anim] = Animator:LoadAnimation(anim)
			loadedTracks[anim].Priority = Enum.AnimationPriority.Core
		end

		currentAnimTrack = loadedTracks[anim]
		currentAnimTrack:Play(transitionTime or TRANSITIONS.Default)

		currentAnim = animName
		currentAnimInstance = anim

		if currentAnimKeyframeHandler then
			currentAnimKeyframeHandler:Disconnect()
		end
		currentAnimKeyframeHandler = currentAnimTrack.KeyframeReached:Connect(keyFrameReachedFunc)
	end
end

local toolAnimName = ""
local toolAnimTrack = nil
local toolAnimInstance = nil
local currentToolAnimKeyframeHandler = nil

function toolKeyFrameReachedFunc(frameName)
	if frameName == "End" then
		playToolAnimation(toolAnimName, 0.0)
	end
end

function playToolAnimation(animName, transitionTime, priority)	 
	local roll = math.random(1, animTable[animName].totalWeight) 
	local idx = 1
	while roll > animTable[animName][idx].weight do
		roll -= animTable[animName][idx].weight
		idx += 1
	end

	local anim = animTable[animName][idx].anim

	if toolAnimInstance ~= anim then
		if toolAnimTrack then
			toolAnimTrack:Stop(TRANSITIONS.Tool)
			transitionTime = 0
		end

		if not loadedTracks[anim] then
			loadedTracks[anim] = Animator:LoadAnimation(anim)
		end

		toolAnimTrack = loadedTracks[anim]
		if priority then
			toolAnimTrack.Priority = priority
		end

		toolAnimTrack:Play(transitionTime or TRANSITIONS.Tool)
		toolAnimName = animName
		toolAnimInstance = anim

		if currentToolAnimKeyframeHandler then
			currentToolAnimKeyframeHandler:Disconnect()
		end
		currentToolAnimKeyframeHandler = toolAnimTrack.KeyframeReached:Connect(toolKeyFrameReachedFunc)
	end
end

function stopToolAnimations()
	local oldAnim = toolAnimName
	if currentToolAnimKeyframeHandler then
		currentToolAnimKeyframeHandler:Disconnect()
	end

	toolAnimName = ""
	toolAnimInstance = nil
	if toolAnimTrack then
		toolAnimTrack:Stop(TRANSITIONS.Tool)
		toolAnimTrack = nil
	end
	return oldAnim
end

Humanoid.Running:Connect(function(speed)
	speed /= getRigScale()
	if speed > 0.01 then
		playAnimation("walk", TRANSITIONS.Walk)
		if currentAnimInstance and currentAnimInstance.AnimationId == "http://www.roblox.com/asset/?id=180426354" then
			setAnimationSpeed(speed / 14.5)
		end
		pose = "Running"
	else
		if emoteNames[currentAnim] == nil then
			playAnimation("idle", TRANSITIONS.Idle)
			pose = "Standing"
		end
	end
end)

Humanoid.Jumping:Connect(function()
	playAnimation("jump", TRANSITIONS.Default)
	pose = "Jumping"
end)

Humanoid.Climbing:Connect(function(speed)
	speed /= getRigScale()
	playAnimation("climb", TRANSITIONS.Default)
	setAnimationSpeed(speed / 12.0)
	pose = "Climbing"
end)

Humanoid.FreeFalling:Connect(function()
	playAnimation("fall", TRANSITIONS.Fall)
	pose = "FreeFall"
end)

Humanoid.Seated:Connect(function()
	playAnimation("sit", TRANSITIONS.Default)
	pose = "Seated"
end)

Humanoid.Died:Connect(function() pose = "Dead" end)
Humanoid.GettingUp:Connect(function() pose = "GettingUp" end)
Humanoid.FallingDown:Connect(function() pose = "FallingDown" end)
Humanoid.PlatformStanding:Connect(function() pose = "PlatformStanding" end)
Humanoid.Swimming:Connect(function(speed)
	pose = speed > 0 and "Running" or "Standing"
end)

local function getTool()	
	for _, kid in ipairs(Figure:GetChildren()) do
		if kid:IsA("Tool") then return kid end
	end
	return nil
end

local function getToolAnim(tool)
	for _, c in ipairs(tool:GetChildren()) do
		if c.Name == "toolanim" and c:IsA("StringValue") then
			return c
		end
	end
	return nil
end

local toolAnim = "None"
local toolAnimTime = 0

RunService.Heartbeat:Connect(function(deltaTime)
	if pose == "Dead" or pose == "GettingUp" or pose == "FallingDown" or pose == "PlatformStanding" then
		stopAllAnimations()
	end

	
	local tool = getTool()
	if tool and tool:FindFirstChild("Handle") then
		local animStringValueObject = getToolAnim(tool)

		if animStringValueObject then
			toolAnim = animStringValueObject.Value
			animStringValueObject.Parent = nil
			toolAnimTime = tick() + 0.3
		end

		if tick() > toolAnimTime then
			toolAnimTime = 0
			toolAnim = "None"
		end

		if toolAnim == "None" then playToolAnimation("toolnone", TRANSITIONS.Tool, Enum.AnimationPriority.Idle)
		elseif toolAnim == "Slash" then playToolAnimation("toolslash", 0, Enum.AnimationPriority.Action)
		elseif toolAnim == "Lunge" then playToolAnimation("toollunge", 0, Enum.AnimationPriority.Action) end
	else
		stopToolAnimations()
		toolAnim = "None"
		toolAnimInstance = nil
		toolAnimTime = 0
	end
end)

if not FFlagUserAnimateRemoveEmoteChatHook then
	local LocalPlayer = Players.LocalPlayer
	if LocalPlayer then
		LocalPlayer.Chatted:Connect(function(msg)
			local emote = ""
			if msg == "/e dance" then emote = dances[math.random(1, #dances)]
			elseif string.sub(msg, 1, 3) == "/e " then emote = string.sub(msg, 4)
			elseif string.sub(msg, 1, 7) == "/emote " then emote = string.sub(msg, 8) end

			if pose == "Standing" and emoteNames[emote] ~= nil then
				playAnimation(emote, TRANSITIONS.Emote)
			end
		end)
	end
end

script:WaitForChild("PlayEmote").OnInvoke = function(emote)
	if pose ~= "Standing" then return false end
	if emoteNames[emote] ~= nil then
		playAnimation(emote, TRANSITIONS.Emote)
		return true, currentAnimTrack
	end
	return false
end

playAnimation("idle", 0.1)
pose = "Standing"