local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Forge = require("@game/ReplicatedStorage/Shared/Libs/Forge").new()
local TestEZ = require("@game/ReplicatedStorage/TestEZ")

local Components = {}

for _, module in script.Components:GetChildren() do
	Components[module.Name] = require(module)
end

TestEZ.TestBootstrap:run({
	ReplicatedStorage.Shared.Libs.__TESTS__,
})
Forge:bootstrap(script.Services, Components)
Forge:run(script.Systems)
