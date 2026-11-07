-- Pint's New Character Setup
-- Every new character starts with default settings that make sense: Auto Loot, cooldown numbers, class-coloured names
-- in chat and a few more. The game saves these per character, so new characters normally start with them off.
-- Also: big, easy-to-read cooldown numbers on your action bars, and "Stacks to" / "Used in" lines on item tooltips.
-- /setup (or /pns, /newchar) opens the options.
local ADDON, NS = ...

---------------------------------------------------------------- what a new character starts with
-- { key, label, tooltip, default on?, how to turn it on }
local CHAR = {
	{ "autoLoot", "Auto Loot", "Loot everything with a right-click, no window to click through.", true, { cvar = "autoLootDefault" } },
	{ "cdNumbers", "Cooldown numbers on action bars", "Shows how many seconds are left on every cooldown.", true, { cvar = "countdownForCooldowns" } },
	{ "chatColors", "Class-coloured names in chat", "Names in every chat type and channel are coloured by class.", true, { chat = true } },
	{ "tot", "Target of Target", "Shows who your target is targeting, under the target frame.", true, { cvar = "showTargetOfTarget" } },
	{ "camera", "Maximum camera distance", "Lets you zoom the camera out further than the game's default.", true, { cvar = "cameraDistanceMaxZoomFactor", value = "2.6" } },
	{ "questTrack", "Track quests when accepted", "New quests go straight onto your quest tracker.", true, { cvar = "autoQuestWatch" } },
	{ "leftClickTarget", "Left-click only targets", "Left-clicking a mob (or a corpse) just targets it; right-click attacks, talks and loots. (WoW Forever's own default loots and talks on left-click too.)", true, { cvar = "interactOnLeftClick", value = "0" } },
	{ "lootMouse", "Open loot window at mouse", "The loot window opens where your cursor is, not in the corner.", false, { cvar = "lootUnderMouse" } },
}
NS.CHAR = CHAR

-- account-wide features, always running unless switched off here
local DEFAULTS = {
	cdStyle = true, cdSize = 26, cdColor = 1,   -- cooldown number style (size, colour preset)
	tipStack = true, tipUsedIn = true,          -- tooltip lines
	announce = true,                            -- say in chat what was set up on a new character
}
NS.COLORS = {
	{ "Yellow", 1, 0.82, 0 }, { "White", 1, 1, 1 }, { "Orange", 1, 0.5, 0.1 }, { "Green", 0.3, 1, 0.3 }, { "Light blue", 0.4, 0.8, 1 },
}

local function DB() return PintsSetupDB end
NS.DB = DB

---------------------------------------------------------------- applying the defaults
local CHAT_TYPES = {
	"SAY", "YELL", "EMOTE", "WHISPER", "WHISPER_INFORM", "BN_WHISPER", "BN_WHISPER_INFORM",
	"PARTY", "PARTY_LEADER", "RAID", "RAID_LEADER", "RAID_WARNING",
	"GUILD", "OFFICER", "GUILD_ACHIEVEMENT", "ACHIEVEMENT",
	"BATTLEGROUND", "BATTLEGROUND_LEADER", "INSTANCE_CHAT", "INSTANCE_CHAT_LEADER",
	"TEXT_EMOTE", "COMMUNITIES_CHANNEL",
}
local function ChatColors()
	local was = ChatTypeInfo and ChatTypeInfo.SAY and ChatTypeInfo.SAY.colorNameByClass
	local function On(t)
		local info = ChatTypeInfo and ChatTypeInfo[t]
		if not info then return end
		if SetChatColorNameByClass then pcall(SetChatColorNameByClass, t, true) end
		info.colorNameByClass = true
	end
	for _, t in ipairs(CHAT_TYPES) do On(t) end
	for i = 1, 20 do On("CHANNEL" .. i) end
	return not was
end

-- turn one setting on; returns true if it changed something
local function TurnOn(s)
	local how = s[5]
	if how.chat then return ChatColors() end
	local ok, cur = pcall(GetCVar, how.cvar)
	if not ok or cur == nil then return false end      -- this client doesn't have that setting
	local want = how.value or "1"
	if cur == want then return false end
	pcall(SetCVar, how.cvar, want)
	return true
end

-- apply every ticked default to the character you're on
function NS.ApplyDefaults(quiet)
	local done = {}
	for _, s in ipairs(CHAR) do
		if DB().char[s[1]] and TurnOn(s) then done[#done + 1] = s[2] end
	end
	PintsSetupCharDB.setUp = true
	NS.justApplied = true
	if not quiet and DB().announce then
		if #done > 0 then print("|cffd4a017Pint's|r New Character Setup: turned on " .. table.concat(done, ", ") .. ". |cff909090(/setup to change)|r")
		else print("|cffd4a017Pint's|r New Character Setup: this character already has your defaults.") end
	end
	return done
end

---------------------------------------------------------------- login
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function(self, event, arg)
	if event == "ADDON_LOADED" and arg == ADDON then
		PintsSetupDB = PintsSetupDB or {}
		local db = PintsSetupDB
		for k, v in pairs(DEFAULTS) do if db[k] == nil then db[k] = v end end
		db.char = db.char or {}
		for _, s in ipairs(CHAR) do if db.char[s[1]] == nil then db.char[s[1]] = s[4] end end
		PintsSetupCharDB = PintsSetupCharDB or {}
		if NS.OnLoaded then NS.OnLoaded() end
	elseif event == "PLAYER_LOGIN" then
		-- a character's first login with this add-on: give it the defaults
		if not PintsSetupCharDB.setUp then NS.ApplyDefaults() end
		-- 1.0.1: "left-click only targets" is new - give it once to characters set up before it existed
		if not PintsSetupCharDB.leftClickDone then
			PintsSetupCharDB.leftClickDone = true
			for _, s in ipairs(CHAR) do
				if s[1] == "leftClickTarget" and DB().char[s[1]] and TurnOn(s) and DB().announce then
					print("|cffd4a017Pint's|r New Character Setup: left-click now only targets; right-click loots. |cff909090(/setup to change)|r")
				end
			end
		end
	elseif event == "PLAYER_ENTERING_WORLD" then
		-- the chat frames finish setting up after login; set the class colours again on the login we set this character up
		if NS.justApplied and DB().char.chatColors then ChatColors() end
		self:UnregisterEvent(event)
	end
end)
