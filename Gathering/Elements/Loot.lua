local Name, AddOn = ...
local Gathering = AddOn.Gathering
local L = AddOn.L

local LootMatch = "([^|]+)|cff%x+|H([^|]+)|h%[([^%]]+)%]|h|r[^%d]*(%d*)"

if (Gathering.GameVersion > 100000) then -- The War Within+ uses different item quality color codes
	LootMatch = "([^|]+)|c[^|]+|H([^|]+)|h%[([^%]]+)%]|h|r[^%d]*(%d*)"
end

local GetItemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo
local GetTime = GetTime
local RequestLoadItemDataByID = C_Item and C_Item.RequestLoadItemDataByID
local format = string.format
local tinsert = table.insert

local PendingLoot = {}

function Gathering:CheckAnnounceLoot(link, name, id, quantity, value)
	if (not self.Settings.AnnounceLoot) then
		return
	end

	local Threshold = (self.Settings.AnnounceThreshold or Gathering.DefaultSettings.AnnounceThreshold or 0) * 100 * 100

	if (Threshold <= 0 or not value or value < Threshold) then
		return
	end

	local ItemLabel = link or name

	if (not ItemLabel and id) then
		ItemLabel = select(2, GetItemInfo(id)) or name or format("item:%d", id)
	end

	print(format(L["Gathering: %s x%d worth %s"], ItemLabel or name or "?", quantity or 1, self:CopperToGold(value)))
end

local HandleLoot = function(self, ID, Quantity, Name, Timestamp)
	local ItemName, Link, _, _, _, _, SubType, _, _, _, _, ClassID, SubClassID, BindType = GetItemInfo(ID)

	if (not ClassID or not SubClassID or not SubType) then
		if RequestLoadItemDataByID then
			PendingLoot[ID] = PendingLoot[ID] or {}
			tinsert(PendingLoot[ID], {Quantity = Quantity, Name = Name, Time = Timestamp or GetTime()})
			RequestLoadItemDataByID(ID)
		end

		return
	end

	Name = ItemName or Name

	if (self.Ignored[ID] or (Name and self.Ignored[Name]) or not self.TrackedItemTypes[ClassID] or not self.TrackedItemTypes[ClassID][SubClassID]) then
		return
	end

	if (BindType and BindType ~= 0 and self.Settings["ignore-bop"]) then
		return
	end

	local Now = Timestamp or GetTime()

	if (not self.Gathered[SubType]) then
		self.Gathered[SubType] = {}
	end

	if (not self.Gathered[SubType][ID]) then
		self.Gathered[SubType][ID] = { Initial = Now }
	end

	local Info = self.Gathered[SubType][ID]
	Info.Collected = (Info.Collected or 0) + Quantity
	Info.Last = Now

	self.TotalGathered = self.TotalGathered + Quantity

	local Price = self:GetPrice(Link, ID)

	if Price then
		self:CheckAnnounceLoot(Link, Name, ID, Quantity, Price * Quantity)
	end

	if (self.Settings.DisplayMode == "TOTAL") then
		self.Text:SetFormattedText(L["Total: %s"], self.TotalGathered)
	end

	if (not self:GetScript("OnUpdate")) then
		self:StartTimer()
	end

	self:AddStat("total", Quantity)
	self:UpdateItemsStat()

	if (self.MouseIsOver) then
		self:OnLeave()
		self:OnEnter()
	end
end

local ValidMessages = {
	[LOOT_ITEM_SELF:gsub("%%.*", "")] = true,
	[LOOT_ITEM_PUSHED_SELF:gsub("%%.*", "")] = true,
}

function Gathering:CHAT_MSG_LOOT(msg)
	if (not msg) then
		return
	end

	if ((self.Settings.IgnoreMailItems and InboxFrame and InboxFrame:IsVisible()) or (GuildBankFrame and GuildBankFrame:IsVisible())) then
		return
	end

	local PreMessage, ItemString, Name, Quantity = msg:match(LootMatch)

	if (not ItemString or not Name) then
		return
	end

	if (PreMessage and not ValidMessages[PreMessage]) then
		return
	end

	Quantity = tonumber(Quantity) or 1

	local LinkType, ID = ItemString:match("^(%a+):(%d+)")
	ID = tonumber(ID)

	if (LinkType ~= "item" or not ID) then
		return
	end

	local Now = GetTime()

	HandleLoot(self, ID, Quantity, Name, Now)
end

function Gathering:ITEM_DATA_LOAD_RESULT(ID, Success)
	local Queue = PendingLoot[ID]

	if (not Queue) then
		return
	end

	PendingLoot[ID] = nil

	if (not Success) then
		return
	end

	for i = 1, #Queue do
		local Entry = Queue[i]
		HandleLoot(self, ID, Entry.Quantity, Entry.Name, Entry.Time)
	end
end

Gathering:RegisterEvent("CHAT_MSG_LOOT")

if RequestLoadItemDataByID then
	Gathering:RegisterEvent("ITEM_DATA_LOAD_RESULT")
end
