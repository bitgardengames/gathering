local Name, AddOn = ...
local Gathering = AddOn.Gathering
local L = AddOn.L

local LootMatch = "([^|]+)|cff%x+|H([^|]+)|h%[([^%]]+)%]|h|r[^%d]*(%d*)"

if (Gathering.GameVersion > 100000) then -- The War Within+ uses different item quality color codes
	LootMatch = "([^|]+)|c[^|]+|H([^|]+)|h%[([^%]]+)%]|h|r[^%d]*(%d*)"
end

local GetItemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo

local ValidMessages = {
	[LOOT_ITEM_SELF:gsub("%%.*", "")] = true,
	[LOOT_ITEM_PUSHED_SELF:gsub("%%.*", "")] = true,
}

function Gathering:CHAT_MSG_LOOT(msg)
    if not msg then return end

    if (self.Settings.IgnoreMailItems and InboxFrame:IsVisible()) or (GuildBankFrame and GuildBankFrame:IsVisible()) then
        return
    end

    local PreMessage, ItemString, Name, Quantity = msg:match(LootMatch)

    if not ItemString or not Name then return end

    if PreMessage and not ValidMessages[PreMessage] then
        return
    end

    Quantity = tonumber(Quantity) or 1

    local LinkType, ID = ItemString:match("^(%a+):(%d+)")
    ID = tonumber(ID)
    if not ID then return end

    local _, _, Quality, _, _, Type, SubType, _, _, Texture, _, ClassID, SubClassID, BindType = GetItemInfo(ID)
    if self.Ignored[ID] or self.Ignored[Name] or not self.TrackedItemTypes[ClassID] or not self.TrackedItemTypes[ClassID][SubClassID] then
        return
    end

    if BindType and BindType ~= 0 and self.Settings["ignore-bop"] then
        return
    end

    local Now = GetTime()
    if not self.Gathered[SubType] then self.Gathered[SubType] = {} end
    if not self.Gathered[SubType][ID] then self.Gathered[SubType][ID] = {Initial = Now} end

    local Info = self.Gathered[SubType][ID]
    Info.Collected = (Info.Collected or 0) + Quantity
    Info.Last = Now

    self.TotalGathered = self.TotalGathered + Quantity

    if self.Settings.DisplayMode == "TOTAL" then
        self.Text:SetFormattedText(L["Total: %s"], self.TotalGathered)
    end

    if not self:GetScript("OnUpdate") then
        self:StartTimer()
    end

    self:AddStat("total", Quantity)
    self:UpdateItemsStat()

    if self.MouseIsOver then
        self:OnLeave()
        self:OnEnter()
    end
end

Gathering:RegisterEvent("CHAT_MSG_LOOT")