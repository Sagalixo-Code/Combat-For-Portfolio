--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Packages.Signal)
local From = require(ReplicatedStorage.Shared.From)
local Result = require(ReplicatedStorage.Shared.Libs.Result)

local UI3DManager = {}
UI3DManager.__index = UI3DManager

local Presets = From.import(script.Parent:WaitForChild("Presets"))

local function safeReq(moduleScript)
	if not moduleScript then
		return
	end

	assert(typeof(moduleScript) == "Instance", "Not is a instance")
	assert(moduleScript:IsA("ModuleScript"), "Not is a moduleScript")

	local sucess, resultOrErr = pcall(function()
		return require(moduleScript)
	end)

	if sucess then
		return Result.Ok(resultOrErr)
	end

	return Result.Err(resultOrErr)
end

local STATE = {
	Idle = "idle",
	Hovered = "hovered",
	Pressed = "pressed",
	Disabled = "disabled",
}
UI3DManager.State = STATE

function UI3DManager.make(context)
	local self = setmetatable({
		_object = context.object,
		_state = context.state or STATE.Idle,

		IsHovered = false,
		IsPressed = false,
		IsEnabled = if context.enabled == nil then true else context.enabled,

		_activeButton = nil,

		_onDestroy = context.onDestroy,

		MouseEnter = Signal.new(),
		MouseLeave = Signal.new(),
		MouseButton1Down = Signal.new(),
		MouseButton1Up = Signal.new(),
		MouseButton2Down = Signal.new(),
		MouseButton2Up = Signal.new(),
		Activated = Signal.new(),
	}, UI3DManager)

	if self._state == STATE.Disabled or not self.IsEnabled then
		self.IsEnabled = false
		self._state = STATE.Disabled
	end

	return self
end

function UI3DManager:GetObject()
	return self._object
end

function UI3DManager:GetState()
	return self._state
end

function UI3DManager:SetEnabled(enabled)
	if self.IsEnabled == enabled then
		return
	end

	self.IsEnabled = enabled

	if not enabled then
		if self.IsHovered then
			self:_setHovered(false)
		end
		if self.IsPressed then
			self:_setPressed(false)
		end
		self._state = STATE.Disabled
	else
		self._state = STATE.Idle
	end
end

function UI3DManager:_setHovered(isHovered)
	if not self.IsEnabled or self.IsHovered == isHovered then
		return
	end

	self.IsHovered = isHovered

	if isHovered then
		self._state = STATE.Hovered
		self.MouseEnter:Fire()
	else
		if self.IsPressed then
			self:_setPressed(false)
		end
		self._state = STATE.Idle
		self.MouseLeave:Fire()
	end
end

function UI3DManager:_setPressed(isPressed, button)
	if not self.IsEnabled then
		return
	end

	button = button or self._activeButton or "MouseButton1"

	if isPressed then
		if self.IsPressed then
			return
		end
		self.IsPressed = true
		self._activeButton = button
		self._state = STATE.Pressed

		if button == "MouseButton2" then
			self.MouseButton2Down:Fire()
		else
			self.MouseButton1Down:Fire()
		end
	else
		if not self.IsPressed then
			return
		end
		self.IsPressed = false
		local heldButton = self._activeButton
		self._activeButton = nil
		self._state = if self.IsHovered then STATE.Hovered else STATE.Idle

		if heldButton == "MouseButton2" then
			self.MouseButton2Up:Fire()
		else
			self.MouseButton1Up:Fire()
		end

		if self.IsHovered then
			self.Activated:Fire()
		end
	end
end

function UI3DManager:Style(context)
	if not context then
		return
	end

	local PresetModule = safeReq(Presets[context])
	if PresetModule:IsErr() then
		return
	end

	return PresetModule:Unwrap()
end

function UI3DManager:Destroy()
	self.MouseEnter:Destroy()
	self.MouseLeave:Destroy()
	self.MouseButton1Down:Destroy()
	self.MouseButton1Up:Destroy()
	self.MouseButton2Down:Destroy()
	self.MouseButton2Up:Destroy()
	self.Activated:Destroy()

	if self._onDestroy then
		self._onDestroy(self)
	end
end

return UI3DManager
