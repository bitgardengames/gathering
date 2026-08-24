local Name, AddOn = ...
local Gathering = AddOn.Gathering

SLASH_GATHERING1 = "/gt"
SLASH_GATHERING2 = "/gather"
SLASH_GATHERING3 = "/gathering"
SlashCmdList["GATHERING"] = function(cmd)
	if (not Gathering.GUI) then
		Gathering:CreateGUI()

		return
	end

	if cmd and cmd == "reset" then
		Gathering:Reset()
	else
		if Gathering.GUI:IsShown() then
			Gathering.GUI:Hide()
		else
			Gathering.GUI:Show()
		end
	end
end