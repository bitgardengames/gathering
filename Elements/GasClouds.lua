local Name, AddOn = ...
local Gathering = AddOn.Gathering
local L = AddOn.L

local GetItemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo
local GetContainerNumSlots = C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
local GetContainerItemID = C_Container and C_Container.GetContainerItemID or GetContainerItemID
local GetContainerItemCount

if C_Container then
	GetContainerItemCount = function(bag, slot)
		local info = C_Container.GetContainerItemInfo(bag, slot)

		return info and info.stackCount
	end
else
	GetContainerItemCount = function(bag, slot)
		local _, count = GetContainerItemInfo(bag, slot)

		return count
	end
end

local function RecordLoot(self, ID, Quantity, SubType, BindType)
	if (BindType and BindType ~= 0 and self.Settings["ignore-bop"]) then
		return false
	end

	local GatheredByType = self.Gathered[SubType]

	if (not GatheredByType) then
		GatheredByType = {}
		self.Gathered[SubType] = GatheredByType
	end

	local Now = GetTime()
	local Info = GatheredByType[ID]

	if (not Info) then
		Info = {Initial = Now}
		GatheredByType[ID] = Info
	end

	Info.Collected = (Info.Collected or 0) + Quantity
	Info.Last = Now

	self.TotalGathered = self.TotalGathered + Quantity

	if (self.Settings.DisplayMode == "TOTAL") then
		self.Text:SetFormattedText(L["Total: %s"], self.TotalGathered)
	end

	if (not self:GetScript("OnUpdate")) then
		self:StartTimer()
	end

	return true
end

function Gathering:BAG_UPDATE_DELAYED()
	if (not self.BagResults) then
		self:UpdateItemsStat()

		return
	end

	local ID, Count
	local Updated = false

	for Bag = 0, NUM_BAG_SLOTS do
		for Slot = 1, GetContainerNumSlots(Bag) do
			ID = GetContainerItemID(Bag, Slot)

			if ID then
				local _, _, _, _, _, _, SubType, _, _, _, _, ClassID, SubClassID, BindType = GetItemInfo(ID)

				if (self.TrackedItemTypes[ClassID] and self.TrackedItemTypes[ClassID][SubClassID]) then
					Count = GetContainerItemCount(Bag, Slot)

					local Previous = self.BagResults[Bag][Slot]
					local PreviousCount = Previous and Previous[1] == ID and Previous[2] or 0
					local Change = Count and Count - PreviousCount or 0

					if (Change > 0) then
						Updated = RecordLoot(self, ID, Change, SubType, BindType) or Updated
					end
				end
			end
		end
	end

	self.BagResults = nil

	if (Updated and self.MouseIsOver) then
		self:OnLeave()
		self:OnEnter()
	end
end

function Gathering:UNIT_SPELLCAST_CHANNEL_START(unit, guid, id)
	if (unit ~= "player") then
		return
	end

	if (not id or id ~= 30427) then -- Extract Gas
		return
	end

	self.BagResults = {}

	local ID, Count, ClassID, SubClassID

	for Bag = 0, NUM_BAG_SLOTS do
		if (not self.BagResults[Bag]) then
			self.BagResults[Bag] = {}
		end

		for Slot = 1, GetContainerNumSlots(Bag) do
			ID = GetContainerItemID(Bag, Slot)

			if ID then
				Count = GetContainerItemCount(Bag, Slot)
				ClassID, SubClassID = select(12, GetItemInfo(ID))

				if (self.TrackedItemTypes[ClassID] and self.TrackedItemTypes[ClassID][SubClassID]) then
					self.BagResults[Bag][Slot] = {ID, Count}
				end
			end
		end
	end

	self:AddStat("clouds", 1)
end

Gathering:RegisterEvent("BAG_UPDATE_DELAYED")
Gathering:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
