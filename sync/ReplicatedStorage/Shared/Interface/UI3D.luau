--!strict

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local UI3DManager = require(script.UI3DManager)

assert(RunService:IsClient(), "UI3D is a client module")

local UI3D = {}

local registry: { [BasePart]: any } = {}

local registeredParts: { BasePart } = {}

local hoveredManager = nil

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Include

local function rebuildFilter()
	raycastParams.FilterDescendantsInstances = registeredParts
end

local function getCamera()
	return Workspace.CurrentCamera
end

local function getTargetUnderMouse()
	if #registeredParts == 0 then
		return nil
	end

	local camera = getCamera()
	if not camera then
		return nil
	end

	local mouseLocation = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)

	local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
	if not result then
		return nil
	end

	return registry[result.Instance]
end

local function updateHover()
	local target = getTargetUnderMouse()

	if target == hoveredManager then
		return
	end

	if hoveredManager then
		hoveredManager:_setHovered(false)
	end

	hoveredManager = target

	if hoveredManager then
		hoveredManager:_setHovered(true)
	end
end

RunService:BindToRenderStep("UI3D_HitDetection", Enum.RenderPriority.Input.Value, updateHover)

local BUTTON_MAP = {
	[Enum.UserInputType.MouseButton1] = "MouseButton1",
	[Enum.UserInputType.MouseButton2] = "MouseButton2",
	[Enum.UserInputType.Touch] = "MouseButton1",
}

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	local button = BUTTON_MAP[input.UserInputType]
	if not button then
		return
	end

	if input.UserInputType == Enum.UserInputType.Touch then
		updateHover()
	end

	if hoveredManager then
		hoveredManager:_setPressed(true, button)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	local button = BUTTON_MAP[input.UserInputType]
	if not button then
		return
	end

	if hoveredManager then
		hoveredManager:_setPressed(false, button)
	end
end)

function UI3D.make(part, options)
	local existing = registry[part]
	if existing then
		return existing
	end

	options = options or {}

	local manager = UI3DManager.make({
		object = part,
		enabled = options.enabled,
		onDestroy = function(self)
			registry[part] = nil
			for i, p in registeredParts do
				if p == part then
					table.remove(registeredParts, i)
					break
				end
			end
			rebuildFilter()
			if hoveredManager == self then
				hoveredManager = nil
			end
		end,
	})

	registry[part] = manager
	table.insert(registeredParts, part)
	rebuildFilter()

	part.AncestryChanged:Connect(function(_, parent)
		if not parent and registry[part] then
			manager:Destroy()
		end
	end)

	return manager
end

function UI3D.get(part)
	return registry[part]
end

return UI3D
