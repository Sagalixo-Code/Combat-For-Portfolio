local Struct = require("@game/ReplicatedStorage/Shared/Libs/Syntax").Struct

return function()
	describe("Struct", function()
		describe("construction", function()
			it("creates a struct with positional values", function()
				local Vec2 = Struct({
					Struct.field("x", 0),
					Struct.field("y", 0),
				})

				local vector = Vec2.new(10, 20)

				expect(vector.x).to.equal(10)
				expect(vector.y).to.equal(20)
			end)

			it("uses default values when values are omitted", function()
				local Player = Struct({
					Struct.field("name", "Unknown"),
					Struct.field("health", 100),
				})

				local player = Player.new()

				expect(player.name).to.equal("Unknown")
				expect(player.health).to.equal(100)
			end)

			it("allows partial construction", function()
				local Vec3 = Struct({
					Struct.field("x", 0),
					Struct.field("y", 0),
					Struct.field("z", 0),
				})

				local vector = Vec3.new(10, 20)

				expect(vector.x).to.equal(10)
				expect(vector.y).to.equal(20)
				expect(vector.z).to.equal(0)
			end)

			it("rejects too many arguments", function()
				local Vec2 = Struct({
					Struct.field("x", 0),
					Struct.field("y", 0),
				})

				expect(function()
					Vec2.new(10, 20, 30)
				end).to.throw()
			end)
		end)

		describe("fields", function()
			it("rejects undeclared fields", function()
				local Vec2 = Struct({
					Struct.field("x", 0),
					Struct.field("y", 0),
				})

				local vector = Vec2.new()

				expect(function()
					vector.z = 10
				end).to.throw()
			end)

			it("allows modifying declared fields", function()
				local Vec2 = Struct({
					Struct.field("x", 0),
					Struct.field("y", 0),
				})

				local vector = Vec2.new()

				vector.x = 50

				expect(vector.x).to.equal(50)
			end)

			it("rejects invalid field types during construction", function()
				local Player = Struct({
					Struct.field("health", 100),
				})

				expect(function()
					Player.new("invalid")
				end).to.throw()
			end)

			it("rejects invalid field types during assignment", function()
				local Player = Struct({
					Struct.field("health", 100),
				})

				local player = Player.new()

				expect(function()
					player.health = "invalid"
				end).to.throw()
			end)
		end)

		describe("custom validators", function()
			it("accepts valid values", function()
				local Player = Struct({
					Struct.field("health", 100, function(value)
						return value >= 0
					end),
				})

				local player = Player.new(50)

				expect(player.health).to.equal(50)
			end)

			it("rejects invalid values", function()
				local Player = Struct({
					Struct.field("health", 100, function(value)
						return value >= 0
					end),
				})

				expect(function()
					Player.new(-10)
				end).to.throw()
			end)

			it("validates assignments", function()
				local Player = Struct({
					Struct.field("health", 100, function(value)
						return value >= 0
					end),
				})

				local player = Player.new()

				expect(function()
					player.health = -10
				end).to.throw()
			end)
		end)

		describe("definition", function()
			it("rejects duplicate fields", function()
				expect(function()
					Struct({
						Struct.field("x", 0),
						Struct.field("x", 10),
					})
				end).to.throw()
			end)

			it("requires an explicit type when default is nil", function()
				expect(function()
					Struct({
						Struct.field("id", nil),
					})
				end).to.throw()
			end)
		end)

		describe("methods", function()
			it("clones a struct", function()
				local Vec2 = Struct({
					Struct.field("x", 0),
					Struct.field("y", 0),
				})

				local original = Vec2.new(10, 20)
				local clone = original:clone()

				expect(clone.x).to.equal(10)
				expect(clone.y).to.equal(20)

				clone.x = 50

				expect(clone.x).to.equal(50)
				expect(original.x).to.equal(10)
			end)
		end)

		describe("equality", function()
			it("considers equal structs equal", function()
				local Vec2 = Struct({
					Struct.field("x", 0),
					Struct.field("y", 0),
				})

				local a = Vec2.new(10, 20)
				local b = Vec2.new(10, 20)

				expect(a == b).to.equal(true)
			end)

			it("considers different structs unequal", function()
				local Vec2 = Struct({
					Struct.field("x", 0),
					Struct.field("y", 0),
				})

				local a = Vec2.new(10, 20)
				local b = Vec2.new(10, 30)

				expect(a == b).to.equal(false)
			end)
		end)

		describe("string representation", function()
			it("formats the struct", function()
				local Vec2 = Struct({
					Struct.field("x", 0),
					Struct.field("y", 0),
				})

				local vector = Vec2.new(10, 20)

				expect(tostring(vector)).to.equal("Struct { x = 10, y = 20 }")
			end)

			it("supports custom type names", function()
				local Vec2 = Struct({
					Struct.field("x", 0),
					Struct.field("y", 0),
				}, "Vec2")

				local vector = Vec2.new(10, 20)

				expect(tostring(vector)).to.equal("Vec2 { x = 10, y = 20 }")
			end)
		end)
	end)
end
