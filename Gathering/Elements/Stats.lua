local Name, AddOn = ...
local Gathering = AddOn.Gathering
local L = AddOn.L

local GetItemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo
local GetTime = GetTime
local format = string.format
local floor = math.floor
local max = math.max

-- Generic counting of numbers
local SessionStat = {}

function Gathering:AddStat(stat, value)
        if (not GatheringStats) then
                GatheringStats = {}
        end

        local Amount = value or 1

        GatheringStats[stat] = (GatheringStats[stat] or 0) + Amount
        SessionStat[stat] = (SessionStat[stat] or 0) + Amount
end

Gathering.SessionStats = SessionStat

function Gathering:GetSessionValue()
	local Total = 0

	for _, Items in pairs(self.Gathered or {}) do
		for ID, Info in pairs(Items) do
			local Link = select(2, GetItemInfo(ID))
			local Price = self:GetPrice(Link, ID)

			if Price then
				Total = Total + (Price * (Info.Collected or 0))
			end
		end
	end

	return Total
end

function Gathering:PrintSessionSummary()
	local TotalItems = self.SessionStats.total or 0
	local GoldGained = self.GoldGained or 0
	local XPGained = (self.Settings and self.Settings["track-xp"]) and self.XPGained or 0
	local Duration = self.Seconds or 0

	if (Duration <= 0 and self.SessionStart) then
		Duration = floor(GetTime() - self.SessionStart)
	end

	local EstimatedValue = self:GetSessionValue()

	if (TotalItems == 0 and GoldGained == 0 and XPGained == 0 and EstimatedValue == 0) then
		print(L["Gathering: No session data to summarize."])

		return
	end

	print(L["Gathering Session Summary"])
	print(format(L[" - Time: %s"], self:FormatFullTime(Duration)))

	if (TotalItems > 0) then
		print(format(L[" - Items: %s"], self:Comma(TotalItems)))
	end

	if (EstimatedValue > 0) then
		print(format(L[" - Estimated value: %s"], self:CopperToGold(EstimatedValue)))
	end

	if (GoldGained ~= 0) then
		print(format(L[" - Gold: %s"], self:CopperToGold(GoldGained)))
	end

	if (XPGained and XPGained > 0) then
		local PerHour = 0

		if (Duration > 0) then
			PerHour = floor(((XPGained / max(Duration, 1)) * 60) * 60)
		end

		print(format(L[" - XP: %s"], self:Comma(XPGained)))
		print(format(L[" - XP / hr: %s"], self:Comma(PerHour)))
	end
end
