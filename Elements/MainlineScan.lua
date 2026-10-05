local Name, AddOn = ...
local Gathering = AddOn.Gathering
local L = AddOn.L

local ReplicateItems = C_AuctionHouse.ReplicateItems
local GetNumReplicateItems = C_AuctionHouse.GetNumReplicateItems
local GetReplicateItemInfo = C_AuctionHouse.GetReplicateItemInfo

GatheringMarketPrices = GatheringMarketPrices or {}
Gathering.MarketPrices = GatheringMarketPrices

local function StorePrice(self, index)
	local _, _, Count, _, _, _, _, _, _, Buyout, _, _, _, _, _, _, ID = GetReplicateItemInfo(index)

	if (not ID or not Count or Count <= 0 or not Buyout or Buyout <= 0) then
		return
	end

	local PerUnit = Buyout / Count

	if (not self.MarketPrices[ID] or PerUnit < self.MarketPrices[ID]) then
		self.MarketPrices[ID] = PerUnit
	end
end

function Gathering:ScanButtonOnClick()
	local TimeDiff = (GetTime() - (GatheringLastScan or 0))

	if Gathering.ScanInProgress then
		if (TimeDiff <= 900) then
			return
		end

		-- Recover if the auction house never delivered results for an old scan.
		Gathering.ScanInProgress = false
		Gathering:UnregisterEvent("REPLICATE_ITEM_LIST_UPDATE")
	end

	if (TimeDiff > 0) and (900 > TimeDiff) then -- 15 minute throttle
		print(format(L["You must wait %s until you can scan again."], Gathering:FormatTime(900 - TimeDiff)))
		return
	end

	Gathering:RegisterEvent("REPLICATE_ITEM_LIST_UPDATE")
	Gathering.ScanInProgress = true
	Gathering.ScanGeneration = (Gathering.ScanGeneration or 0) + 1

	ReplicateItems()

	print(L["|cffFFC44DGathering|r is scanning market prices. This should take less than 10 seconds."])

	GatheringLastScan = GetTime()
end

function Gathering:AUCTION_HOUSE_SHOW()
	if (not self.ScanButton and AuctionHouseFrame) then
		self.ScanButton = CreateFrame("Button", "Gathering Scan Button", AuctionHouseFrame.MoneyFrameBorder, "UIPanelButtonTemplate")
		self.ScanButton:SetSize(140, 24)
		self.ScanButton:SetPoint("LEFT", AuctionHouseFrame.MoneyFrameBorder, "RIGHT", 3, 0)
		self.ScanButton:SetText(L["Gathering Scan"])
		self.ScanButton:SetScript("OnClick", self.ScanButtonOnClick)
	end
end

function Gathering:REPLICATE_ITEM_LIST_UPDATE()
	local PendingItems = 0
	local ResultsReceived = false
	local ScanGeneration = self.ScanGeneration

	local function ItemLoaded()
		if (ScanGeneration ~= self.ScanGeneration) then
			return
		end

		PendingItems = PendingItems - 1

		if (ResultsReceived and PendingItems == 0) then
			self.ScanInProgress = false
			print(L["|cffFFC44DGathering|r updated market prices."])
		end
	end

	for i = 0, (GetNumReplicateItems() - 1) do
		local _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, ID, HasAllInfo = GetReplicateItemInfo(i)

		if HasAllInfo then
			StorePrice(self, i)
		elseif ID then
			local Index = i
			PendingItems = PendingItems + 1

			Item:CreateFromItemID(ID):ContinueOnItemLoad(function()
				if (ScanGeneration == self.ScanGeneration) then
					StorePrice(self, Index)
					ItemLoaded()
				end
			end)
		end
	end

	self:UnregisterEvent("REPLICATE_ITEM_LIST_UPDATE")
	ResultsReceived = true

	if (PendingItems == 0) then
		self.ScanInProgress = false
		print(L["|cffFFC44DGathering|r updated market prices."])
	end
end

Gathering:RegisterEvent("AUCTION_HOUSE_SHOW")
