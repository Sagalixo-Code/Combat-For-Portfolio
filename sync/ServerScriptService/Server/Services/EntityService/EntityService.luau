local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local EntityAttributes = require(ReplicatedStorage.Shared.Data.EntityAttributes)
local Logger = require(ReplicatedStorage.Shared.Libs.Logger)
local EntityService = {
	Entities = {},
}

local EntityServiceLogger = Logger.new("EntityService")

local UniqueCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890"

local function CreateID()
	local EntityID = ""
	for i = 1, 8 do
		local randNum = math.random(1, UniqueCharacters:len())
		EntityID = EntityID .. UniqueCharacters:sub(randNum, randNum)
	end
	return EntityID
end

local Attris = EntityAttributes

local function CreateStateMachine(EntityProfile, EntityData)
	local StateMachine = {}
	StateMachine.__index = {}

	function StateMachine.new(InitialState)
		local self = {
			State = EntityData[InitialState],
			StateEnums = EntityData,
			Stack = {},
		}
		setmetatable(self, StateMachine)

		function self:SetState(NewState, ...)
			if not self.StateEnums[NewState] then
				warn(NewState .. " is not a valid state!")
				return
			end

			self.State = self.StateEnums[NewState]

			if EntityProfile.Player then
				EntityProfile.Player:SetAttribute("CurrentState", NewState)

				if EntityProfile.Player.Character then
					EntityProfile.Player.Character:SetAttribute("CurrentState", NewState)
				end
			end

			if self.State.Enter then
				self.State.Enter(EntityProfile, ...)
			end
		end

		function self:Trigger(Action, ...)
			if self.State[Action] then
				self.State[Action](EntityProfile, ...)
				if self.State[Action .. "NextState"] then
					local NextState = self.State[Action .. "NextState"]
					self:SetState(NextState, ...)
				end
			else
				EntityServiceLogger:Debug("Action " .. Action .. " not defined for current state!")
			end
		end

		function self:PushState(State)
			table.insert(self.Stack, self.State)
			self:SetState(State)
		end

		function self:PopState()
			local PreviousState = table.remove(self.Stack)
			if PreviousState then
				self:SetState(PreviousState)
			end
		end

		return self
	end

	return StateMachine.new("Idle")
end

function EntityService.PlayerAdded(Player: Player, Components)
	if Player:GetAttribute("EntityID") then
		EntityServiceLogger:Debug(`{Player.Name} has been registred`)
		return
	end

	local EntityProfile = {
		Player = Player,
		Character = Player.Character or Player.CharacterAdded:Wait(),
		Janitor = Janitor.new(),
	}
	local EntityID = Player.Name .. "_" .. CreateID()

	EntityProfile.Humanoid = EntityProfile.Character:WaitForChild("Humanoid")
	EntityProfile.RootPart = EntityProfile.Character:WaitForChild("HumanoidRootPart")
	EntityProfile.StateMachine = CreateStateMachine(EntityProfile, Components.PlayerBehavior)

	Player:SetAttribute("EntityID", EntityID)
	Player:SetAttribute("CurrentState", "Idle")

	EntityService.Entities[EntityID] = EntityProfile
end

function EntityService.CharacterAdded(_, Player: Player, Character)
	Character:SetAttribute("CurrentState", "Idle")
	Character:SetAttribute("EntityID", Player:GetAttribute("EntityID"))

	Character:SetAttribute("Weapon", "Fists")

	for Name, Type in pairs(Attris) do
		Character:SetAttribute(Name, Type)
	end
end

function EntityService.PlayerRemoving(_, Player: Player)
	local EntityProfile = EntityService.GetEntity(Player)
	if EntityProfile then
		EntityProfile.Janitor:cleanup()
		table.clear(EntityProfile)
		EntityService.Entities[Player:GetAttribute("EntityID")] = nil
	end
end

function EntityService.GetEntity(Player: Player)
	if not Player then
		EntityServiceLogger:Error(`Player dont exist`)
		return
	end
	return EntityService.Entities[Player:GetAttribute("EntityID")]
end

return EntityService
