local Name, AddOn = ...
local Gathering = AddOn.Gathering

local GetTime = GetTime
local GetCurrencyInfo = GetCurrencyInfo
local GetCurrencyListSize = GetCurrencyListSize
local GetCurrencyListInfo = GetCurrencyListInfo

if C_CurrencyInfo then
	GetCurrencyInfo = C_CurrencyInfo.GetCurrencyInfo
	GetCurrencyListSize = C_CurrencyInfo.GetCurrencyListSize
	GetCurrencyListInfo = C_CurrencyInfo.GetCurrencyListInfo
end

Gathering.LastCurrency = Gathering.LastCurrency or {}
Gathering.TrackedCurrencies = {}

function Gathering:ScanCurrencies()
	if not self.CurrencyReady then
		return
	end

	self.TrackedCurrencies = {}

	local count = GetCurrencyListSize()
	for i = 1, count do
		local info = GetCurrencyListInfo(i)

		if info and not info.isHeader and not info.isTypeUnused and info.quantity > 0 then
			self.TrackedCurrencies[info.currencyTypesID or info.currencyID] = info.name
		end
	end
end

function Gathering:UpdateCurrencies()
	if not self.CurrencyStartTime then
		self.CurrencyStartTime = GetTime()
	end

	if not next(self.TrackedCurrencies) then
		self:ScanCurrencies()
	end

	for id, name in pairs(self.TrackedCurrencies) do
		local info = GetCurrencyInfo(id)

		if info and info.quantity then
			local current = info.quantity
			local last = self.LastCurrency[id] or current
			local gained = current - last

			if gained > 0 then
				self:AddStat("currency:" .. id, gained)
			end

			self.LastCurrency[id] = current
		end
	end

	--self:UpdateCurrencyStat()
end

function Gathering:CURRENCY_DISPLAY_UPDATE()
	self:UpdateCurrencies()
end

Gathering:RegisterEvent("CURRENCY_DISPLAY_UPDATE")