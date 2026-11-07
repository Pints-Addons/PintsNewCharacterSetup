-- Pint's New Character Setup - account-wide features: cooldown number style and item tooltip lines.
local ADDON, NS = ...

---------------------------------------------------------------- cooldown numbers: larger, coloured, outlined
local FLAGS = "THICKOUTLINE"
local styled = setmetatable({}, { __mode = "k" })   -- every cooldown we've touched, so a size/colour change updates them all
local font = CreateFont("PintsSetupCooldownFont")

local function Look()
	local db = NS.DB()
	local c = NS.COLORS[db.cdColor] or NS.COLORS[1]
	return db.cdSize or 26, c[2], c[3], c[4]
end

local function IsActionButtonCooldown(cd)
	local p = cd and cd:GetParent()
	if not p then return false end
	local name = p:GetName() or ""
	return p.action ~= nil
		or name:find("ActionButton") or name:find("MultiBar")
		or name:find("Dominos") or name:find("BT4Button")
		or name:find("StanceButton") or name:find("PetActionButton")
		or name:find("PintsBars")
end

-- The size depends on how long the number is: 1-2 characters ("9", "45") at your full size; 3 or more ("56m",
-- "1:26") a size down, so they still fit on the button. Checked a few times a second while a cooldown runs.
local SHORT_MAX = 2
local function Sizes(cd)
	local size = Look()
	local w = cd.GetWidth and cd:GetWidth() or 0
	local small = math.floor(size * 0.65 + 0.5)
	if w and w > 0 then small = math.min(small, math.floor(w * 0.5)) end
	return size, math.max(9, small)
end
local function FitText(cd, reg)
	local t = reg:GetText()
	if type(t) ~= "string" or (issecretvalue and issecretvalue(t)) then return end
	local big, small = Sizes(cd)
	local want = (#t <= SHORT_MAX) and big or small
	-- a size we already shrank to so this many characters fit the button
	if reg.pnsFitLen == #t and reg.pnsFit then want = math.min(want, reg.pnsFit) end
	-- check the size it really has (the game can put the font back behind our backs), not just what we last set
	local _, cur = reg:GetFont()
	if not cur or math.abs(cur - want) > 0.5 then reg:SetFont(STANDARD_TEXT_FONT, want, FLAGS); cur = want end
	reg.pnsSize = cur
	-- never wider than the button: shrink until it fits
	local w = cd.GetWidth and cd:GetWidth() or 0
	local ok, sw = pcall(reg.GetStringWidth, reg)
	if w > 0 and ok and type(sw) == "number" and not (issecretvalue and issecretvalue(sw)) and sw > w * 0.9 then
		local fit = math.max(9, math.floor(cur * w * 0.9 / sw))
		if fit < cur then reg:SetFont(STANDARD_TEXT_FONT, fit, FLAGS); reg.pnsSize = fit; reg.pnsFit, reg.pnsFitLen = fit, #t end
	end
end
local function StyleRegions(cd)
	local size, r, g, b = Look()
	for _, reg in ipairs({ cd:GetRegions() }) do
		if reg.GetObjectType and reg:GetObjectType() == "FontString" then
			reg.pnsSize = size
			reg:SetFont(STANDARD_TEXT_FONT, size, FLAGS)
			reg:SetTextColor(r, g, b)
			reg:SetShadowColor(0, 0, 0, 1)
			reg:SetShadowOffset(2, -2)
			FitText(cd, reg)
		end
	end
end
-- (the game writes the countdown itself, without telling add-ons: so look at the running ones a few times a second)
do
	local acc = 0
	local tick = CreateFrame("Frame")
	tick:SetScript("OnUpdate", function(_, el)
		acc = acc + el
		if acc < 0.2 then return end
		acc = 0
		if not (PintsSetupDB and PintsSetupDB.cdStyle) then return end
		for cd in pairs(styled) do
			if cd:IsVisible() then
				for _, reg in ipairs({ cd:GetRegions() }) do
					if reg.GetObjectType and reg:GetObjectType() == "FontString" and reg:IsShown() then FitText(cd, reg) end
				end
			end
		end
	end)
end

local function Style(cd)
	if not (PintsSetupDB and PintsSetupDB.cdStyle) then return end
	if not IsActionButtonCooldown(cd) then return end
	if cd.SetCountdownFont and not styled[cd] then pcall(cd.SetCountdownFont, cd, "PintsSetupCooldownFont") end
	styled[cd] = true
	StyleRegions(cd)
end

-- called when the options change
function NS.UpdateCooldownFont()
	local size, r, g, b = Look()
	font:SetFont(STANDARD_TEXT_FONT, size, FLAGS)
	font:SetTextColor(r, g, b)
	font:SetShadowColor(0, 0, 0, 1)
	font:SetShadowOffset(2, -2)
	if NS.DB().cdStyle then for cd in pairs(styled) do StyleRegions(cd) end end
end

local probe = CreateFrame("Cooldown", nil, UIParent, "CooldownFrameTemplate")
local mt = getmetatable(probe).__index
hooksecurefunc(mt, "SetCooldown", Style)
if mt.SetCooldownFromDurationObject then hooksecurefunc(mt, "SetCooldownFromDurationObject", Style) end
probe:Hide()

---------------------------------------------------------------- tooltips: "Stacks to: N" and "Used in: <professions>"
local GetItemInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
local PROF_NAMES = {
	[1] = "First Aid", [2] = "Blacksmithing", [3] = "Leatherworking", [4] = "Alchemy",
	[6] = "Cooking", [8] = "Tailoring", [9] = "Engineering", [10] = "Enchanting",
	[11] = "Fishing", [12] = "Mining", [13] = "Poisons", [14] = "Jewelcrafting", [15] = "Inscription",
}
local PROF_ORDER = { 4, 2, 6, 10, 9, 1, 11, 15, 14, 3, 12, 13, 8 }   -- alphabetical by name
local usedInCache = {}

local function UsedInText(itemID)
	local mask = PintsSetup_ReagentProfs and PintsSetup_ReagentProfs[itemID]
	if not mask then return nil end
	if usedInCache[itemID] ~= nil then return usedInCache[itemID] or nil end
	local names = {}
	for _, p in ipairs(PROF_ORDER) do
		if bit.band(mask, bit.lshift(1, p)) ~= 0 then names[#names + 1] = PROF_NAMES[p] end
	end
	usedInCache[itemID] = (#names > 0) and table.concat(names, ", ") or false
	return usedInCache[itemID] or nil
end

local function AddLines(tooltip, item)
	local db = PintsSetupDB
	if not (tooltip and item and db) or not (db.tipStack or db.tipUsedIn) then return end
	local added = false
	if db.tipStack then
		local ok, _, _, _, _, _, _, _, stackCount = pcall(GetItemInfo, item)
		if ok and type(stackCount) == "number" and stackCount > 1 then
			tooltip:AddLine("Stacks to: " .. stackCount, 0.6, 0.8, 1)
			added = true
		end
	end
	if db.tipUsedIn then
		local itemID = tonumber(item) or (type(item) == "string" and tonumber(item:match("item:(%d+)")))
		local usedIn = itemID and UsedInText(itemID)
		if usedIn then tooltip:AddLine("Used in: " .. usedIn, 0.6, 0.8, 1, true); added = true end
	end
	if added then tooltip:Show() end   -- resize to fit the new lines
end

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
		if tooltip and tooltip.AddLine then AddLines(tooltip, data and data.id) end
	end)
else
	local function Hook(tt)
		if tt and tt.HookScript then
			tt:HookScript("OnTooltipSetItem", function(self) local _, link = self:GetItem(); AddLines(self, link) end)
		end
	end
	Hook(GameTooltip); Hook(ItemRefTooltip)
end

NS.OnLoaded = function() NS.UpdateCooldownFont(); if NS.BuildOptions then NS.BuildOptions() end end
