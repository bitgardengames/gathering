local Name, AddOn = ...
local Gathering = AddOn.Gathering

Gathering.DefaultSettings = {
	-- Tracking
	["track-ore"] = true,
	["track-herbs"] = true,
	["track-leather"] = true,
	["track-cooking"] = true,
	["track-cloth"] = true,
	["track-jewelcrafting"] = true,
	["track-enchanting"] = true,
	["track-reagents"] = true,
	["track-consumable"] = true,
	["track-holiday"] = true,
	["track-quest"] = false,
	["track-xp"] = true,

	-- Functionality
	IgnoreBOP = false, -- Ignore bind on pickup gear. IE: ignore BoP loot on a raid run, but show BoE's for the auction house
	HideIdle = false, -- Hide the tracker frame while not running
	IgnoreMailItems = true, -- Ignore items that arrived through mail
	IgnoreMailMoney = true, -- Ignore money that arrived through mail
	ShowTooltipHelp = true, -- Display helpful information in the tooltip (Left click to toggle, right click to reset)
	DisplayMode = "TIME", -- TOTAL; Display total gathered, GPH; display gold per hour, GOLD; display gold collected, TIME; display timer

	-- Styling
	WindowFont = Gathering.SharedMedia.DefaultMedia.font, -- Set the font
	WindowHeight = 24,
	WindowWidth = 130,

	-- Bag Slots
	EnableSlotBar = true,
	SlotBarTooltip = true,
	SlotBarHeight = 6,
	-- Threshold options
}

local function CopySettings(source)
	local copy = {}

	for key, value in next, source or {} do
		copy[key] = value
	end

	return copy
end

function Gathering:InitializeProfiles()
	if (not GatheringProfiles) then
		GatheringProfiles = {
			profileKeys = {},
			profiles = {},
		}
	end

	GatheringProfiles.profileKeys = GatheringProfiles.profileKeys or {}
	GatheringProfiles.profiles = GatheringProfiles.profiles or {}

	local character = UnitName("player") .. " - " .. GetRealmName()
	local profile = GatheringProfiles.profileKeys[character] or "Default"

	if (not GatheringProfiles.profiles[profile]) then
		-- GatheringSettings was the database used before profiles were added.
		GatheringProfiles.profiles[profile] = CopySettings(GatheringSettings)
	end

	GatheringProfiles.profileKeys[character] = profile
	self.ProfileKey = character
	self.ProfileName = profile
	GatheringSettings = GatheringProfiles.profiles[profile]
	self.Settings = setmetatable(GatheringSettings, {__index = self.DefaultSettings})
end

function Gathering:GetProfileNames()
	local profiles = {}

	for name in next, GatheringProfiles.profiles do
		profiles[name] = name
	end

	return profiles
end


function Gathering:ApplyProfile()
	if (not self.Text) then
		return
	end

	-- Once the settings controls have been created, they are the source of truth
	-- for which settings have side effects. Refreshing with notifications keeps
	-- both the controls and every registered hook in sync when a profile changes.
	if (self.Windows) then
		self:RefreshSettingsWidgets()
		return
	end

	self:SetSize(self.Settings.WindowWidth, self.Settings.WindowHeight)
	self.BagSlots:SetHeight(self.Settings.SlotBarHeight)
	self:ToggleSlotBar(self.Settings.EnableSlotBar)
	self:UpdateFontSetting(self.Settings.WindowFont)
	self:UpdateDisplayMode(self.Settings.DisplayMode)
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

	if (self.Settings["hide-idle"] and not self:GetScript("OnUpdate")) then
		self:Hide()
	else
		self:Show()
	end
end

function Gathering:SetProfile(name)
	if (not name or not GatheringProfiles.profiles[name]) then
		return
	end

	GatheringProfiles.profileKeys[self.ProfileKey] = name
	self.ProfileName = name
	GatheringSettings = GatheringProfiles.profiles[name]
	self.Settings = setmetatable(GatheringSettings, {__index = self.DefaultSettings})
	self:ApplyProfile()
	self:RefreshProfilePage()
end

function Gathering:CreateProfile(name)
	name = name and strtrim(name)

	if (not name or name == "" or GatheringProfiles.profiles[name]) then
		return false
	end

	GatheringProfiles.profiles[name] = {}
	self:SetProfile(name)
	return true
end

function Gathering:RenameProfile(name)
	name = name and strtrim(name)

	if (not name or name == "" or name == self.ProfileName or GatheringProfiles.profiles[name]) then
		return false
	end

	local oldName = self.ProfileName
	GatheringProfiles.profiles[name] = GatheringProfiles.profiles[oldName]
	GatheringProfiles.profiles[oldName] = nil

	for character, profile in next, GatheringProfiles.profileKeys do
		if (profile == oldName) then
			GatheringProfiles.profileKeys[character] = name
		end
	end

	self.ProfileName = name
	GatheringSettings = GatheringProfiles.profiles[name]
	self.Settings = setmetatable(GatheringSettings, {__index = self.DefaultSettings})
	self:RefreshProfilePage()
	return true
end

function Gathering:CopyProfile(name)
	if (not name or name == self.ProfileName or not GatheringProfiles.profiles[name]) then
		return
	end

	wipe(GatheringSettings)

	for key, value in next, GatheringProfiles.profiles[name] do
		GatheringSettings[key] = value
	end

	self:ApplyProfile()
	self:RefreshProfilePage()
end

function Gathering:ResetProfile()
	wipe(GatheringSettings)
	self:ApplyProfile()
	self:RefreshProfilePage()
end

function Gathering:DeleteProfile(name)
	if (not name or name == self.ProfileName or not GatheringProfiles.profiles[name]) then
		return
	end

	GatheringProfiles.profiles[name] = nil
	GatheringProfiles.profiles.Default = GatheringProfiles.profiles.Default or {}

	for character, profile in next, GatheringProfiles.profileKeys do
		if (profile == name) then
			GatheringProfiles.profileKeys[character] = "Default"
		end
	end

	self:RefreshProfilePage()
end

Gathering.TrackedItemTypes = {
	[Enum.ItemClass.Consumable] = {},
	[Enum.ItemClass.Weapon] = {},
	[Enum.ItemClass.Armor] = {},
	[Enum.ItemClass.Tradegoods] = {},
	[Enum.ItemClass.Miscellaneous] = {},
	[Enum.ItemClass.Questitem] = {},
}

function Gathering:UpdateWeaponTracking(value)
	Gathering.TrackedItemTypes[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Axe1H] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Axe2H] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Bows] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Guns] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Mace1H] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Mace2H] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Polearm] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Sword1H] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Sword2H] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Warglaive] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Staff] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Bearclaw] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Catclaw] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Unarmed] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Generic] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Dagger] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Thrown] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Crossbow] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Wand] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Fishingpole] = value
end

function Gathering:UpdateArmorTracking(value)
	Gathering.TrackedItemTypes[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Generic] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Cloth] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Leather] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Mail] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Plate] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Cosmetic] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Shield] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Libram] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Idol] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Totem] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Sigil] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Relic] = value
end

function Gathering:UpdateJewelcraftingTracking(value)
	Gathering.TrackedItemTypes[Enum.ItemClass.Tradegoods][4] = value
end

function Gathering:UpdateClothTracking(value)
	Gathering.TrackedItemTypes[Enum.ItemClass.Tradegoods][5] = value
end

function Gathering:UpdateLeatherTracking(value)
	Gathering.TrackedItemTypes[Enum.ItemClass.Tradegoods][6] = value
end

function Gathering:UpdateOreTracking(value)
	Gathering.TrackedItemTypes[Enum.ItemClass.Tradegoods][7] = value
end

function Gathering:UpdateCookingTracking(value)
	Gathering.TrackedItemTypes[Enum.ItemClass.Tradegoods][0] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Tradegoods][8] = value
end

function Gathering:UpdateHerbTracking(value)
	Gathering.TrackedItemTypes[Enum.ItemClass.Tradegoods][9] = value
end

function Gathering:UpdateEnchantingTracking(value)
	Gathering.TrackedItemTypes[Enum.ItemClass.Tradegoods][12] = value
end

function Gathering:UpdateHolidayTracking(value)
	Gathering.TrackedItemTypes[Enum.ItemClass.Miscellaneous][Enum.ItemMiscellaneousSubclass.Holiday] = value
end

function Gathering:UpdateMountTracking(value)
	Gathering.TrackedItemTypes[Enum.ItemClass.Miscellaneous][Enum.ItemMiscellaneousSubclass.Mount] = value
end

function Gathering:UpdateConsumableTracking(value)
	Gathering.TrackedItemTypes[Enum.ItemClass.Consumable][1] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Consumable][2] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Consumable][3] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Consumable][4] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Consumable][5] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Consumable][6] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Consumable][7] = value
end

function Gathering:UpdateReagentTracking(value)
	Gathering.TrackedItemTypes[Enum.ItemClass.Miscellaneous][Enum.ItemMiscellaneousSubclass.Reagent] = value
	Gathering.TrackedItemTypes[Enum.ItemClass.Tradegoods][10] = value
end

function Gathering:UpdateOtherTracking(value)
	Gathering.TrackedItemTypes[Enum.ItemClass.Miscellaneous][Enum.ItemMiscellaneousSubclass.Other] = value
end

function Gathering:UpdateQuestTracking(value)
	Gathering.TrackedItemTypes[Enum.ItemClass.Questitem][0] = value
end
