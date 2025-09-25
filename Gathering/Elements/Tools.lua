local Name, AddOn = ...
local Gathering = AddOn.Gathering

local gsub = string.gsub
local match = string.match
local format = string.format
local reverse = string.reverse
local ceil = math.ceil
local floor = math.floor

local GetContainerNumSlots = GetContainerNumSlots
local GetContainerItemInfo = GetContainerItemInfo
local GetContainerItemLink = GetContainerItemLink
local GetItemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo

if C_Container then
	GetContainerNumSlots = C_Container.GetContainerNumSlots
	GetContainerItemInfo = C_Container.GetContainerItemInfo
	GetContainerItemLink = C_Container.GetContainerItemLink
end

function Gathering:FormatTime(seconds)
	if (seconds > 59) then
		return format("%dm", ceil(seconds / 60))
	else
		return format("%0.1fs", seconds)
	end
end

function Gathering:FormatFullTime(seconds)
	local Days = floor(seconds / 86400)
	local Hours = floor((seconds % 86400) / 3600)
	local Mins = floor((seconds % 3600) / 60)

	if (Days > 0) then
		return format("%dd", Days)
	elseif (Hours > 0) then
		return format("%dh %sm", Hours, Mins)
	elseif (Mins > 0) then
		return format("%sm", Mins)
	else
		return format("%ss", floor(seconds))
	end
end

function Gathering:Comma(number)
	if (not number) then
		return
	end

   	local Left, Number = match(floor(number + 0.5), "^([^%d]*%d)(%d+)(.-)$")

	return Left and Left .. reverse(gsub(reverse(Number), "(%d%d%d)", "%1,")) or number
end

function Gathering:CopperToGold(copper)
	if (not copper) then
		return
	end

	local Gold = floor(copper / (100 * 100))
	local Silver = floor((copper - (Gold * 100 * 100)) / 100)
	local Copper = floor(copper % 100)
	local Separator = ""
	local String = ""

	if (Gold > 0) then
		String = self:Comma(Gold) .. "|cffffe02eg|r"
		Separator = " "
	end

	if (Silver > 0) then
		String = String .. Separator .. Silver .. "|cffd6d6d6s|r"
		Separator = " "
	end

	if (Copper > 0 or String == "") then
		String = String .. Separator .. Copper .. "|cfffc8d2bc|r"
	end

	return String
end

function Gathering:GetPrice(link, id)
	if self.HasTSM and link then
		local Price = TSM_API.GetCustomPriceValue("dbMarket", TSM_API.ToItemString(link))

		if Price and Price > 0 then
			return Price, "market"
		end
	end

	if self.HasAuctionator and link then
		local Price = Auctionator.API.v1.GetAuctionPriceByItemLink("Gathering", link)

		if Price and Price > 0 then
			return Price, "market"
		end
	end

	if self.Settings and self.Settings.UseVendorValue then
		local VendorPrice = select(11, GetItemInfo(id or link))

		if VendorPrice and VendorPrice > 0 then
			return VendorPrice, "vendor"
		end
	end
end

function Gathering:GetTrashValue()
        local Profit = 0

        for Bag = 0, 4 do
                local Slots = GetContainerNumSlots(Bag) or 0

                for Slot = 1, Slots do
                        local Link = GetContainerItemLink(Bag, Slot)

                        if Link then
                                local _, _, Quality, _, _, _, _, _, _, _, VendorPrice = GetItemInfo(Link)
                                local ItemInfo, Count = GetContainerItemInfo(Bag, Slot)
                                local StackCount = 1

                                if (type(ItemInfo) == "table") then
                                        StackCount = ItemInfo.stackCount or ItemInfo.count or 1
                                else
                                        StackCount = Count or 1
                                end

                                if ((Quality and Quality < 1) and VendorPrice and VendorPrice > 0) then
                                        Profit = Profit + (VendorPrice * StackCount)
                                end
                        end
                end
        end

        return Profit
end
