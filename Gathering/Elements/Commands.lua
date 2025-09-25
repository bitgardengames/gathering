local Name, AddOn = ...
local Gathering = AddOn.Gathering
local L = AddOn.L

SLASH_GATHERING1 = "/gt"
SLASH_GATHERING2 = "/gather"
SLASH_GATHERING3 = "/gathering"
SlashCmdList["GATHERING"] = function(cmd)
	cmd = (cmd or ""):match("^%s*(.-)%s*$")

	if (cmd == "" or cmd:lower() == "toggle") then
		if (not Gathering.GUI) then
			Gathering:CreateGUI()

			return
		end

		if Gathering.GUI:IsShown() then
			Gathering.GUI:Hide()
		else
			Gathering.GUI:Show()
		end

		return
	end

	cmd = cmd:lower()

	if (cmd == "summary") then
		Gathering:PrintSessionSummary()
	elseif (cmd == "reset") then
		Gathering:Reset()
		print(L["Gathering data reset."])
	elseif (cmd == "config" or cmd == "options" or cmd == "settings") then
		if (not Gathering.GUI) then
			Gathering:CreateGUI()
		end

		Gathering.GUI:Show()
	else
		print(L["Gathering commands:"])
		print(L[" /gathering - Toggle interface"])
		print(L[" /gathering summary - Print session summary"])
		print(L[" /gathering reset - Reset session data"])
		print(L[" /gathering config - Open configuration"])
	end
end
