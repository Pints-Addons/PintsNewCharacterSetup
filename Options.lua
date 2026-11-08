-- Pint's New Character Setup - options: what new characters start with, plus the cooldown and tooltip features.
-- Esc > Options > AddOns > Pint's New Character Setup, or /setup.
local ADDON, NS = ...
local category, panel

local function Check(parent, label, tip, get, set)
	local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	cb:SetSize(24, 24)
	local t = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); t:SetPoint("LEFT", cb, "RIGHT", 4, 1); t:SetText(label)
	cb.label = t
	cb:SetScript("OnShow", function(self) self:SetChecked(get()) end)
	cb:SetScript("OnClick", function(self) set(self:GetChecked() and true or false) end)
	if tip then
		cb:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:AddLine(label); GameTooltip:AddLine(tip, 1, 1, 1, true); GameTooltip:Show() end)
		cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
	end
	cb:SetChecked(get())
	return cb
end

local function Button(parent, text, w)
	local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	b:SetSize(w or 120, 22); b:SetText(text)
	return b
end

local function Heading(parent, text, y)
	local h = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal"); h:SetPoint("TOPLEFT", 16, y); h:SetText(text)
	local line = parent:CreateTexture(nil, "ARTWORK"); line:SetColorTexture(1, 0.82, 0, 0.25); line:SetHeight(1)
	line:SetPoint("LEFT", h, "RIGHT", 8, 0); line:SetPoint("RIGHT", parent, "RIGHT", -16, 0)
	return h
end

function NS.BuildOptions()
	if panel then return end
	local db = NS.DB()
	panel = CreateFrame("Frame"); panel.name = "Pint's New Character Setup"; panel:Hide()

	local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); title:SetPoint("TOPLEFT", 16, -16)
	title:SetText("|cffd4a017Pint's|r New Character Setup")
	local sub = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
	sub:SetWidth(600); sub:SetJustifyH("LEFT")
	sub:SetText("The game saves these settings per character, so every new character starts with them off. Tick what every new character "
		.. "should start with - each character gets them the first time it logs in. After that you can change them on that character as normal.")

	-- what new characters start with
	local y = -76
	Heading(panel, "Every new character starts with", y); y = y - 24
	for _, s in ipairs(NS.CHAR) do
		local key = s[1]
		local cb = Check(panel, s[2], s[3], function() return db.char[key] end, function(v) db.char[key] = v end)
		cb:SetPoint("TOPLEFT", 20, y); y = y - 26
	end
	local apply = Button(panel, "Apply to this character now", 210); apply:SetPoint("TOPLEFT", 22, y - 4)
	apply:SetScript("OnClick", function() NS.ApplyDefaults() end)
	local note = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"); note:SetPoint("LEFT", apply, "RIGHT", 10, 0)
	note:SetText("Turns on everything ticked above for the character you're playing.")
	y = y - 44

	-- cooldown numbers
	Heading(panel, "Cooldown numbers (all characters)", y); y = y - 24
	local cd = Check(panel, "Large, easy-to-read cooldown numbers", "Makes the countdown numbers on your action bars bigger, bolder and coloured.",
		function() return db.cdStyle end, function(v) db.cdStyle = v; NS.UpdateCooldownFont(); print("|cffd4a017Pint's|r New Character Setup: /reload to see the change on every button.") end)
	cd:SetPoint("TOPLEFT", 20, y); y = y - 30

	local sizeL = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); sizeL:SetPoint("TOPLEFT", 48, y - 4)
	local function ShowSize() sizeL:SetText("Size: |cffffffff" .. db.cdSize .. "|r") end
	ShowSize()
	local minus = Button(panel, "-", 26); minus:SetPoint("TOPLEFT", 130, y)
	local plus = Button(panel, "+", 26); plus:SetPoint("LEFT", minus, "RIGHT", 4, 0)
	minus:SetScript("OnClick", function() db.cdSize = math.max(12, db.cdSize - 2); ShowSize(); NS.UpdateCooldownFont() end)
	plus:SetScript("OnClick", function() db.cdSize = math.min(40, db.cdSize + 2); ShowSize(); NS.UpdateCooldownFont() end)
	local dflt = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"); dflt:SetPoint("LEFT", plus, "RIGHT", 8, 0); dflt:SetText("(game default is about 16)")
	y = y - 30

	local colL = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); colL:SetPoint("TOPLEFT", 48, y - 4); colL:SetText("Colour:")
	local swatches = {}
	local function ShowColor() for i, b in ipairs(swatches) do b.sel:SetShown(i == db.cdColor) end end
	for i, c in ipairs(NS.COLORS) do
		local b = CreateFrame("Button", nil, panel); b:SetSize(84, 20)
		b:SetPoint("TOPLEFT", 130 + (i - 1) * 90, y)
		b.bg = b:CreateTexture(nil, "BACKGROUND"); b.bg:SetAllPoints(); b.bg:SetColorTexture(0, 0, 0, 0.5)
		b.sel = b:CreateTexture(nil, "BORDER"); b.sel:SetAllPoints(); b.sel:SetColorTexture(1, 0.82, 0, 0.35)
		local t = b:CreateFontString(nil, "OVERLAY", "GameFontNormal"); t:SetPoint("CENTER"); t:SetText(c[1]); t:SetTextColor(c[2], c[3], c[4])
		b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
		b:SetScript("OnClick", function() db.cdColor = i; ShowColor(); NS.UpdateCooldownFont() end)
		swatches[i] = b
	end
	ShowColor()
	y = y - 36

	-- tooltips
	Heading(panel, "Item tooltips (all characters)", y); y = y - 24
	local st = Check(panel, "Show \"Stacks to\"", "Adds how many of an item fit in one stack.", function() return db.tipStack end, function(v) db.tipStack = v end)
	st:SetPoint("TOPLEFT", 20, y); y = y - 26
	local ui = Check(panel, "Show \"Used in\" for crafting materials", "Adds which professions use a material (Alchemy, Tailoring...).",
		function() return db.tipUsedIn end, function(v) db.tipUsedIn = v end)
	ui:SetPoint("TOPLEFT", 20, y); y = y - 34

	local an = Check(panel, "Say in chat what was set up on a new character", nil, function() return db.announce end, function(v) db.announce = v end)
	an:SetPoint("TOPLEFT", 20, y)

	if Settings and Settings.RegisterCanvasLayoutCategory then
		category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
		Settings.RegisterAddOnCategory(category)
	elseif InterfaceOptions_AddCategory then
		InterfaceOptions_AddCategory(panel)
	end
end

function NS.OpenOptions()
	if category and Settings and Settings.OpenToCategory then Settings.OpenToCategory(category:GetID())
	elseif InterfaceOptionsFrame_OpenToCategory then InterfaceOptionsFrame_OpenToCategory(panel); InterfaceOptionsFrame_OpenToCategory(panel) end
end

SLASH_PINTSSETUP1 = "/setup"
SLASH_PINTSSETUP2 = "/pns"
SLASH_PINTSSETUP3 = "/newchar"
SlashCmdList.PINTSSETUP = function(msg)
	msg = (msg or ""):lower()
	if msg == "apply" then NS.ApplyDefaults()
	elseif msg == "cd" then NS.CooldownDump()
	else NS.OpenOptions() end
end
