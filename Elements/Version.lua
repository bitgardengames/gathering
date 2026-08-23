local Name, AddOn = ...
local Gathering = AddOn.Gathering
local L = AddOn.L
local CT = ChatThrottleLib

local AddOnVersion = (C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata)("Gathering", "Version")
local AddOnNum = tonumber(AddOnVersion)
local Me = UnitName("player")
local Prefix = "GATHERING_VRSN"
local ChannelCD = {}

function Gathering:GUILD_ROSTER_UPDATE()
	if IsInGuild() then
		CT:SendAddonMessage("NORMAL", Prefix, AddOnVersion, "GUILD")

		self:UnregisterEvent("GUILD_ROSTER_UPDATE")
	end
end

function Gathering:GROUP_ROSTER_UPDATE()
	local Home = GetNumGroupMembers(LE_PARTY_CATEGORY_HOME)
	local Instance = GetNumGroupMembers(LE_PARTY_CATEGORY_INSTANCE)

	if (Home == 0 and self.SentGroup) then
		self.SentGroup = false
	elseif (Instance == 0 and self.SentInstance) then
		self.SentInstance = false
	end

	if (Instance > 0 and not self.SentInstance) then
		CT:SendAddonMessage("NORMAL", Prefix, AddOnVersion, "INSTANCE_CHAT")
		self.SentInstance = true
	elseif (Home > 0 and not self.SentGroup) then
		CT:SendAddonMessage("NORMAL", Prefix, AddOnVersion, IsInRaid(LE_PARTY_CATEGORY_HOME) and "RAID" or IsInGroup(LE_PARTY_CATEGORY_HOME) and "PARTY")
		self.SentGroup = true
	end
end

function Gathering:ZoneVersionCheck()
	local Now = GetTime()

	if (Now - self.LastYell > 15) then
		CT:SendAddonMessage("NORMAL", Prefix, AddOnVersion, "YELL")

		self.LastYell = Now
	end
end

function Gathering:ZONE_CHANGED()
	self:ZoneVersionCheck()
end

function Gathering:ZONE_CHANGED_NEW_AREA()
	self:ZoneVersionCheck()
end

function Gathering:CHAT_MSG_ADDON(prefix, message, channel, sender)
	if sender:find("-") then
		sender = string.match(sender, "(%S+)-%S+")
	end

	if (sender == Me or prefix ~= Prefix) then
		return
	end

	message = tonumber(message)

	if (not message) then
		return
	end

	if (message >= AddOnNum) then
		ChannelCD[channel] = true
	else
		ChannelCD[channel] = false
	end

	if (AddOnNum > message) then -- We have a higher version, share it
		C_Timer.After(random(1, 8), function()
			if (not ChannelCD[channel]) then
				CT:SendAddonMessage("NORMAL", Prefix, AddOnVersion, channel)
			end
		end)
	elseif (message > AddOnNum) then -- We're behind!
		print(format(L["Update |cffFFC44DGathering|r to version %s! www.curseforge.com/wow/addons/gathering"], message))

		AddOnNum = message
		AddOnVersion = tostring(message)
	end
end

C_ChatInfo.RegisterAddonMessagePrefix(Prefix)

if (Gathering.GameVersion < 90000) then
	Gathering:RegisterEvent("ZONE_CHANGED")
	Gathering:RegisterEvent("ZONE_CHANGED_NEW_AREA")
end

Gathering:RegisterEvent("GROUP_ROSTER_UPDATE")
Gathering:RegisterEvent("GUILD_ROSTER_UPDATE")
Gathering:RegisterEvent("CHAT_MSG_ADDON")