-- Pint's New Character Setup - the new-character window: on a character's first login, a checklist of the settings
-- it can start with (ticked as chosen in /setup). Untick any you don't want, then Turn on - or Not now / Skip.
-- /setup welcome shows it any time (it then just turns on what you tick).
local ADDON, NS = ...
local win

local function Build()
	local f = CreateFrame("Frame", "PintsSetupWelcome", UIParent, "BackdropTemplate")
	f:SetSize(420, 120); f:SetPoint("CENTER", 0, 80); f:SetFrameStrata("DIALOG")
	f:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 32, edgeSize = 32, insets = { left = 11, right = 12, top = 12, bottom = 11 } })
	f:EnableMouse(true); f:SetMovable(true); f:RegisterForDrag("LeftButton"); f:SetClampedToScreen(true)
	f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing)
	tinsert(UISpecialFrames, "PintsSetupWelcome")     -- Esc closes it (it comes back next login)

	local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); title:SetPoint("TOP", 0, -20)
	title:SetText("|cffd4a017Pint's|r New Character Setup")
	f.sub = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); f.sub:SetPoint("TOP", title, "BOTTOM", 0, -8)
	f.sub:SetWidth(370); f.sub:SetJustifyH("CENTER")

	f.checks = {}
	local y = -70
	for i, s in ipairs(NS.CHAR) do
		local cb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate"); cb:SetSize(24, 24); cb:SetPoint("TOPLEFT", 30, y)
		local t = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); t:SetPoint("LEFT", cb, "RIGHT", 4, 1); t:SetText(s[2])
		cb:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:AddLine(s[2]); GameTooltip:AddLine(s[3], 1, 1, 1, true); GameTooltip:Show() end)
		cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
		cb.key = s[1]; f.checks[i] = cb
		y = y - 26
	end

	y = y - 6
	f.remember = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate"); f.remember:SetSize(22, 22); f.remember:SetPoint("TOPLEFT", 30, y)
	local rt = f.remember:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"); rt:SetPoint("LEFT", f.remember, "RIGHT", 4, 1)
	rt:SetText("Make these the ticks for future new characters too")
	y = y - 26
	f.again = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate"); f.again:SetSize(22, 22); f.again:SetPoint("TOPLEFT", 30, y)
	local at = f.again:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"); at:SetPoint("LEFT", f.again, "RIGHT", 4, 1)
	at:SetText("Show this window on new characters (otherwise they just get these)")
	y = y - 34

	local function Btn(text, w) local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate"); b:SetSize(w, 24); b:SetText(text); return b end
	f.ok = Btn("Turn on", 110); f.ok:SetPoint("TOPLEFT", 40, y)
	f.later = Btn("Not now", 100); f.later:SetPoint("LEFT", f.ok, "RIGHT", 10, 0)
	f.skip = Btn("Skip", 100); f.skip:SetPoint("LEFT", f.later, "RIGHT", 10, 0)
	f.later:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:AddLine("Ask again next time this character logs in", 1, 1, 1); GameTooltip:Show() end)
	f.later:SetScript("OnLeave", function() GameTooltip:Hide() end)
	f.skip:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:AddLine("Leave this character's settings as they are", 1, 1, 1); GameTooltip:AddLine("(/setup apply turns your defaults on later)", 0.7, 0.7, 0.7); GameTooltip:Show() end)
	f.skip:SetScript("OnLeave", function() GameTooltip:Hide() end)
	f:SetHeight(-y + 44)

	f.ok:SetScript("OnClick", function()
		local db = NS.DB()
		local picks = {}
		for _, cb in ipairs(f.checks) do picks[cb.key] = cb:GetChecked() and true or false end
		if f.remember:GetChecked() then for k, v in pairs(picks) do db.char[k] = v end end
		db.welcome = f.again:GetChecked() and true or false
		NS.ApplyDefaults(false, picks)
		f:Hide()
	end)
	f.later:SetScript("OnClick", function() NS.DB().welcome = f.again:GetChecked() and true or false; f:Hide() end)
	f.skip:SetScript("OnClick", function()
		NS.DB().welcome = f.again:GetChecked() and true or false
		PintsSetupCharDB.setUp = true
		if NS.DB().announce then print("|cffd4a017Pint's|r New Character Setup: left this character's settings as they are. |cff909090(/setup apply to turn your defaults on)|r") end
		f:Hide()
	end)
	return f
end

-- preview: shown from /setup (Not now and Skip then just close it)
function NS.ShowWelcome(preview)
	win = win or Build()
	local db = NS.DB()
	for _, cb in ipairs(win.checks) do cb:SetChecked(db.char[cb.key] and true or false) end
	win.remember:SetChecked(false)
	win.again:SetChecked(db.welcome ~= false)
	win.sub:SetText(preview and "Tick the settings to turn on for this character:"
		or ("New character, |cffffffff" .. (UnitName("player") or "") .. "|r! Tick the settings this character should start with:"))
	win:Show()
end
