local Name, AddOn = ...
local Gathering = AddOn.Gathering
local L = AddOn.L

L["Profiles"] = L["Profiles"] or "Profiles"
L["Profile Name"] = L["Profile Name"] or "Profile Name"
L["Current Profile: %s"] = L["Current Profile: %s"] or "Current Profile: %s"
L["Save"] = L["Save"] or "Save"
L["Load"] = L["Load"] or "Load"
L["Delete"] = L["Delete"] or "Delete"
L["Profile name is required."] = L["Profile name is required."] or "Profile name is required."
L["Profile names may not be longer than 32 characters."] = L["Profile names may not be longer than 32 characters."] or "Profile names may not be longer than 32 characters."
L["Profile saved: %s"] = L["Profile saved: %s"] or "Profile saved: %s"
L["Profile loaded: %s"] = L["Profile loaded: %s"] or "Profile loaded: %s"
L["Profile deleted: %s"] = L["Profile deleted: %s"] or "Profile deleted: %s"
L["Select a profile first."] = L["Select a profile first."] or "Select a profile first."

local function CopySettings(source)
	local result = {}

	for key, default in next, Gathering.DefaultSettings do
		local value = source[key]

		if (value ~= nil and type(value) == type(default)) then
			if ((key == "WindowWidth" and (value < 50 or value > 500)) or
				(key == "WindowHeight" and (value < 10 or value > 100)) or
				(key == "SlotBarHeight" and (value < 1 or value > 20)) or
				(key == "DisplayMode" and value ~= "TIME" and value ~= "GPH" and value ~= "GOLD" and value ~= "TOTAL") or
				(key == "WindowFont" and not Gathering.Fonts[value])) then
				value = default
			end

			result[key] = value
		end
	end

	return result
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
	name = type(name) == "string" and name:gsub("^%s+", ""):gsub("%s+$", ""):gsub("[%c]", "") or ""

	if (name == "") then
		return nil, L["Profile name is required."]
	elseif (#name > 32) then
		return nil, L["Profile names may not be longer than 32 characters."]
	end

	return name
end

function Gathering:SaveProfile(name)
	local errorMessage
	name, errorMessage = self:NormalizeProfileName(name)

	if (not name) then
		print(errorMessage)
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
	local profile = name and GatheringProfiles.profiles[name]

	if (type(profile) ~= "table") then
		print(L["Select a profile first."])
		return false
	end

	wipe(GatheringSettings)

	for key, value in next, CopySettings(profile) do
		GatheringSettings[key] = value
	end

	GatheringProfiles.active = name
	self.Settings = setmetatable(GatheringSettings, {__index = self.DefaultSettings})
	self:ApplySettings()

	if self.GUI then
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
