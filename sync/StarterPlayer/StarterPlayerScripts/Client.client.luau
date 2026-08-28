local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientReplicator = require(ReplicatedStorage.Shared.Libs.ClientReplicator)
local Logger = require(ReplicatedStorage.Shared.Libs.Logger)

local Player = Players.LocalPlayer

local Forge = require(ReplicatedStorage.Shared.Libs.Forge).new()

local SystemLogger = Logger.new()

local Components = {}

for _, module in script.Components:GetChildren() do
	Components[module.Name] = require(module)
end

Forge:bootstrap(script.Controllers, Components)
Forge:run(script.UI)

ReplicatedStorage.ClientReplicator.OnClientEvent:Connect(function(Args)
	local Owner = Args.Owner

	if not Owner then
		SystemLogger:Debug(`Owner dont exist`)
		return
	end

	if (Owner.PrimaryPart.Position - Player.Character.PrimaryPart.Position).Magnitude >= 300 then
		return
	end

	local Func = ClientReplicator[Args.Func]

	if Func then
		Func(Args)
	end
end)
