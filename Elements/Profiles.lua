local Name, AddOn = ...
local Gathering = AddOn.Gathering
local L = AddOn.L

local function IsValidSetting(key, value)
	if (key == "WindowWidth") then
		return value >= 50 and value <= 500
	elseif (key == "WindowHeight") then
		return value >= 10 and value <= 100
	elseif (key == "SlotBarHeight") then
		return value >= 1 and value <= 20
	elseif (key == "DisplayMode") then
		return value == "TIME" or value == "GPH" or value == "GOLD" or value == "TOTAL"
	elseif (key == "WindowFont") then
		return Gathering.Fonts[value] ~= nil
	end

	return true
end

local function CopySettings(source)
	local Settings = {}

	for Key, Default in next, Gathering.DefaultSettings do
		local Value = source[Key]

		if (Value ~= nil and type(Value) == type(Default)) then
			if (not IsValidSetting(Key, Value)) then
				Value = Default
			end

			Settings[Key] = Value
		end
	end

	return Settings
end

function Gathering:InitializeProfiles()
	if (type(GatheringProfiles) ~= "table") then
		GatheringProfiles = {}
	end

	GatheringProfiles.version = 1
	GatheringProfiles.profiles = type(GatheringProfiles.profiles) == "table" and GatheringProfiles.profiles or {}
	GatheringProfiles.active = type(GatheringProfiles.active) == "string" and GatheringProfiles.active or "Default"

	if (type(GatheringProfiles.profiles[GatheringProfiles.active]) ~= "table") then
		GatheringProfiles.active = "Default"
	end

	if (type(GatheringProfiles.profiles.Default) ~= "table") then
		GatheringProfiles.profiles.Default = CopySettings(GatheringSettings or {})
	end
end

function Gathering:NormalizeProfileName(name)
	if (type(name) ~= "string") then
		name = ""
	else
		name = name:gsub("^%s+", "")
		name = name:gsub("%s+$", "")
		name = name:gsub("[%c]", "")
	end

	if (name == "") then
		return nil, L["Profile name is required."]
	elseif (#name > 32) then
		return nil, L["Profile names may not be longer than 32 characters."]
	end

	return name
end

function Gathering:SaveProfile(name)
	local ErrorMessage
	name, ErrorMessage = self:NormalizeProfileName(name)

	if (not name) then
		print(ErrorMessage)
		return false
	end

	GatheringProfiles.profiles[name] = CopySettings(self.Settings)
	GatheringProfiles.active = name
	self:RefreshProfilesPage(name)
	print(format(L["Profile saved: %s"], name))

	return true
end

function Gathering:ApplySettings()
	self:SetSize(self.Settings.WindowWidth, self.Settings.WindowHeight)
	self.BagSlots:SetHeight(self.Settings.SlotBarHeight)
	self:ToggleSlotBar(self.Settings.EnableSlotBar)
	GatheringFont:SetFont(self.SharedMedia:Fetch("font", self.Settings.WindowFont), 12, "")
	GatheringFont14:SetFont(self.SharedMedia:Fetch("font", self.Settings.WindowFont), 14, "")
	self:UpdateHerbTracking(self.Settings["track-herbs"])
	self:UpdateClothTracking(self.Settings["track-cloth"])
	self:UpdateLeatherTracking(self.Settings["track-leather"])
	self:UpdateOreTracking(self.Settings["track-ore"])
	self:UpdateJewelcraftingTracking(self.Settings["track-jewelcrafting"])
	self:UpdateEnchantingTracking(self.Settings["track-enchanting"])
	self:UpdateCookingTracking(self.Settings["track-cooking"])
	self:UpdateReagentTracking(self.Settings["track-reagents"])
	self:UpdateConsumableTracking(self.Settings["track-consumable"])
	self:UpdateHolidayTracking(self.Settings["track-holiday"])
	self:UpdateQuestTracking(self.Settings["track-quest"])
	self:Reset()
end

function Gathering:LoadProfile(name)
	local Profile = name and GatheringProfiles.profiles[name]

	if (type(Profile) ~= "table") then
		print(L["Select a profile first."])
		return false
	end

	wipe(GatheringSettings)

	for Key, Value in next, CopySettings(Profile) do
		GatheringSettings[Key] = Value
	end

	GatheringProfiles.active = name
	self.Settings = setmetatable(GatheringSettings, {__index = self.DefaultSettings})
	self:ApplySettings()

	if (self.GUI) then
		self.GUI:Hide()
		self.GUI = nil
		self:CreateGUI()
		self:ShowPage(L["Profiles"])
	end

	print(format(L["Profile loaded: %s"], name))

	return true
end

function Gathering:DeleteProfile(name)
	if (not name or not GatheringProfiles.profiles[name]) then
		print(L["Select a profile first."])
		return false
	end

	GatheringProfiles.profiles[name] = nil

	if (name == GatheringProfiles.active) then
		if (not GatheringProfiles.profiles.Default) then
			GatheringProfiles.profiles.Default = {}
		end

		self:LoadProfile("Default")
	else
		self:RefreshProfilesPage()
	end

	print(format(L["Profile deleted: %s"], name))

	return true
end
