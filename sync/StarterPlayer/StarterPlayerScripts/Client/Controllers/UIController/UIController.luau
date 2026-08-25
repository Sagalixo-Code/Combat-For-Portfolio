local ReplicatedStorage = game:GetService("ReplicatedStorage")
local From = require(ReplicatedStorage.Shared.From)

local UIController = {
	_UIS = From.import(script.Parent.Parent.Parent:WaitForChild("UI")),
	_currentUI = "unknown",
}

function UIController:GetCurrentUI()
	return self._currentUI
end

function UIController:SetCurrentUI(name)
	self._currentUI = name or "unknown"
end

function UIController:Pop(API, fn)
	if API[fn] then
		task.spawn(API[fn], API)
	end
end

function UIController:OpenUI(name)
	local PathUI = self._UIS[name]

	if not PathUI or PathUI.InCooldown then
		return
	end

	if PathUI.Cooldown then
		PathUI.InCooldown = true
		task.delay(PathUI.Cooldown, function()
			PathUI.InCooldown = false
		end)
	end

	if self:GetCurrentUI() == name then
		self:Pop(PathUI, "Close")
		self:SetCurrentUI("unknown")
		return
	end

	self:CloseUI(name)
	self:SetCurrentUI(name)
	self:Pop(PathUI, "Open")
end

function UIController:CloseUI(exception)
	for Name, API in pairs(self._UIS) do
		if Name ~= exception and type(API) == "table" then
			self:Pop(API, "Close")
		end
	end

	if not exception then
		self:SetCurrentUI("unknown")
	end
end

return UIController
