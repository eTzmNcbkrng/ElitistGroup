-- Some of the sanity checks in this are a bit unnecessary and me being super paranoid
-- but I know how much people will love to try and break this, so I am going to give them as little way to break it as possible
local ElitistGroup = select(2, ...)
local Sync = ElitistGroup:NewModule("Sync", "AceEvent-3.0", "AceComm-3.0")
local L = ElitistGroup.L
local playerName = UnitName("player")
local combatQueue, requestThrottle, requestedInfo, cachedPlayerData, blockOfflineMessage = {}, {}, {}
local COMM_PREFIX = "ELITG"
local MAX_QUEUE = 20
local REQUEST_TIMEOUT = 10
-- This should be raised most likely, but for now only allow a notes or gear request every 5 seconds from someoneone
local REQUEST_THROTTLE = 5

function Sync:Setup()
	if( ElitistGroup.db.profile.comm.enabled ) then
		self:RegisterComm(COMM_PREFIX)
		self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", "ResetCacheData")
		self:RegisterEvent("ACHIEVEMENT_EARNED", "ResetCacheData")
		self:RegisterEvent("PLAYER_LEAVING_WORLD", "ResetThrottle")
	else
		self:UnregisterComm(COMM_PREFIX)
		self:UnregisterAllEvents()
		
		table.wipe(combatQueue)
		cachedPlayerData = nil, nil
	end
end

function Sync:ResetCacheData()
	cachedPlayerData = nil
end

function Sync:ResetThrottle()
	requestThrottle = {}
	requestedInfo = {}
end

local function getFullName(name)
	local name = string.match(name, "(.-)%-") or name
	local server = string.match(name, "%-(.+)") or GetRealmName()

	return string.format("%s-%s", name, server), name, server
end

function Sync:VerifyTable(tbl, checkTbl)
	if( type(tbl) ~= "table" ) then return nil end
	
	for key, value in pairs(tbl) do
		if( not checkTbl[key] or type(value) ~= checkTbl[key] ) then
			tbl[key] = nil
		end
	end
	
	return tbl
end

-- Not quite sure how this should get implemented, will add it later since it's of less importance
--[[
local function filterOffline(self, event, msg)
	return blockOfflineMessage == msg
end

function Sync:EnableOfflineBlock(target)
	blockOfflineMessage = string.format(ERR_CHAT_PLAYER_NOT_FOUND_S, target)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", filterOffline)
end

function Sync:DisableOfflineBlock()
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", filterOffline)
end
]]

-- This will have to be changed, I'm not quite sure a good way of doing it yet
function Sync:SG_DATA_UPDATED(event, type, name)
	if( requestedInfo[name] ) then
		requestedInfo[name] = nil
		ElitistGroup:Print(string.format(L["Successfully got data on %s, type /elitistgroup %s to view!"], name, name))
	end
	
	local hasData
	for key in pairs(requestedInfo) do hasData = true break end
	if( not hasData ) then
		self:UnregisterMessage("SG_DATA_UPDATED")
	end
end

local function verifyInput(name, forceServer)
	if( not name or name == "" ) then
		ElitistGroup:Print(L["You have to enter a name for this to work."])
		return nil
	elseif( name == "target" or name == "focus" or name == "mouseover" ) then
		local unit = name
		local server
		name, server = UnitName(name)
		if( not UnitExists(name) or name == UNKNOWN ) then
			ElitistGroup:Print(string.format(L["No player found for unit %s."], unit))
			return nil
		end

		return ( server and server ~= "" ) and string.format("%s-%s", name, server) or forceServer and string.format("%s-%s", name, GetRealmName()) or name
	end
	
	return name
end

function Sync:SendCmdGear(name)
	local name = verifyInput(name)
	if( name ) then
		self:SendGearData(name, true)
		ElitistGroup:Print(string.format(L["Sent your gear to %s! It will arrive in a few seconds"], name))
	end
end

-- Request somebodies gear
function Sync:RequestGear(name)
	local name = verifyInput(name)
	if( name ) then
		requestedInfo[name] = true
		self:CommMessage("REQGEAR", "WHISPER", name)
		self:RegisterMessage("SG_DATA_UPDATED")
	end
end

-- Request the notes on a specific person
function Sync:RequestNotes(name)
	local name = verifyInput(name, true)
	if( name and not IsInGuild() ) then
		ElitistGroup:Print(L["You need to be in a guild to request notes on players."])
		return
	elseif( name ) then
		requestedInfo[name] = true
		self:CommMessage(string.format("REQNOTES@%s", name), "GUILD")
		self:RegisterMessage("SG_DATA_UPDATED")
	end
end

-- Send our gear to somebody else
function Sync:SendGearData(sender, override)
	if( not override and not ElitistGroup.db.profile.comm.gearRequests ) then return end
	
	-- Players info should rarely change, so we can just cache it and that will be all we need most of the time
	if( not cachedPlayerData ) then
		ElitistGroup.modules.Scan:UpdatePlayerData("player")
		cachedPlayerData = string.format("GEAR@%s", ElitistGroup:WriteTable(ElitistGroup.userData[ElitistGroup.playerName], true))
	end
	
	self:CommMessage(cachedPlayerData, "WHISPER", sender)
end

-- Received a notes request, send off whatever we have
function Sync:ParseNotesRequest(sender, ...)
	-- To pull note data, we do have to unserialize stuff, so we probably shouldn't let people request more than 5 notes at a time
	-- since it means we can delay it on the clients side too to prevent any lag
	if( select("#", ...) == 0 or select("#", ...) > 5 ) then return end

	local tempList = {}
	local queuedData = ""
	for i=1, select("#", ...) do
		local name = select(i, ...)
		if( not tempList[name] and name ~= ElitistGroup.playerName ) then
			local userData = ElitistGroup.userData[name]
			local note = userData and userData.notes[ElitistGroup.playerName]
			if( note ) then
				queuedData = string.format('%s["%s"] = %s;', queuedData, name, ElitistGroup:WriteTable(note))
			end
			
			tempList[name] = true
		end
	end
	
	if( queuedData ~= "" ) then
		self:CommMessage(string.format("NOTES@%d@{%s}", time(), queuedData), "WHISPER", sender)
	end
end

-- Parse the gear somebody sent
function Sync:ParseSentGear(sender, data)
	if( not data ) then return end
	
	local sentData, msg = loadstring("return " .. data)
	if( not sentData ) then
		--@debug@
		error(string.format("Failed to load sent data: %s", msg), 3)
		--@end-debug@
		return
	end
	
	sentData = self:VerifyTable(sentData(), ElitistGroup.VALID_DB_FIELDS)
	if( not sentData or not sentData.achievements or not sentData.equipment ) then return end
	
	-- Verify gear
	for key, value in pairs(sentData.equipment) do
		if( type(key) ~= "number" or type(value) ~= "string" or not string.match(value, "item:(%d+)") or string.len(value) > ElitistGroup.MAX_LINK_LENGTH or not ElitistGroup.Items.validInventorySlots ) then
			sentData.equipment[key] = nil
		end
	end
	
	-- Verify achievements
	for key, value in pairs(sentData.achievements) do
		if( type(key) ~= "number" or type(value) ~= "number" or not ElitistGroup.Dungeons.achievements[key] ) then
			sentData.achievements[key] = nil
		end
	end
		
	-- Merge everything into the current table
	local senderName, name, server = getFullName(sender)
	local userData = ElitistGroup.userData[senderName] or {}
	local notes = userData.notes or {}

	-- If the player already has trusted data on this person from within 10 minutes, don't accept the comm
	local threshold = time() - 600
	if( userData.trusted and userData.scanned < threshold ) then
		return
	end

	-- Finalize it all
	table.wipe(userData)

	for key, value in pairs(sentData) do userData[key] = value end
	userData.name = name
	userData.server = server
	userData.notes = notes
	userData.scanned = time()
	userData.from = senderName
	userData.trusted = nil
		
	ElitistGroup.writeQueue[senderName] = true
	ElitistGroup.userData[senderName] = userData
	ElitistGroup.db.faction.users[senderName] = ElitistGroup.db.faction.users[senderName] or ""

	self:SendMessage("SG_DATA_UPDATED", "gear", senderName)
end

-- Parse the notes somebody sent us
function Sync:ParseSentNotes(sender, currentTime, senderTime, data)
	senderTime = tonumber(senderTime)
	if( not senderTime or not data ) then return end

	local sentNotes, msg = loadstring("return " .. data)
	if( not sentNotes ) then
		--@debug@
		error(string.format("Failed to load sent notes: %s", msg), 3)
		--@end-debug@
		return
	end
	
	-- time() can differ between players, will have the player send their time so it can be calibrated
	-- this is still maybe 2-3 seconds off, but better 2-3 seconds off than hours
	local timeDrift = senderTime - currentTime
	local senderName, name, server = getFullName(sender)
	
	for noteFor, note in pairs(sentNotes()) do
		note = self:VerifyTable(note, ElitistGroup.VALID_NOTE_FIELDS)
		if( type(note) == "table" and type(noteFor) == "string" and note.time and note.role and note.rating and string.match(noteFor, "%-") and senderName ~= noteFor and ( not note.comment or string.len(note.comment) <= ElitistGroup.MAX_NOTE_LENGTH ) ) then
			local name, server = string.split("-", noteFor, 2)
			local userData = ElitistGroup.userData[noteFor] or {}
			
			-- If the time drift is over a day, reset the time of the comment to right now
			note.time = timeDrift > 86400 and time() or note.time + timeDrift
			note.comment = note.comment
			note.from = senderName
			note.rating = math.max(math.min(5, note.rating), 0)
			
			userData.notes[senderName] = note
			
			ElitistGroup.userData[noteFor] = userData
			ElitistGroup.db.faction.users[noteFor] = ElitistGroup.db.faction.users[noteFor] or ""
			ElitistGroup.writeQueue[noteFor] = true

			self:SendMessage("SG_DATA_UPDATED", "note", noteFor)
		end
	end
end

-- Handle the actual comm
function Sync:OnCommReceived(prefix, message, distribution, sender, currentTime)
	if( prefix ~= COMM_PREFIX or sender == playerName or not ElitistGroup.db.profile.comm.areas[distribution] ) then return end
	if( InCombatLockdown() ) then
		if( #(combatQueue) < MAX_QUEUE ) then
			table.insert(combatQueue, {message, distribution, sender, time()})
			self:RegisterEvent("PLAYER_REGEN_ENABLED")
		end
		return
	end
	
	local cmd, args = string.split("@", message, 2)
	-- REQGEAR - Requests your currently equipped data in case you are out of inspection range
	if( cmd == "REQGEAR" ) then
		self:SendGearData(sender)
	-- REQNOTES:playerA@playerBplayerC@etc - Request notes on the given players
	elseif( cmd == "REQNOTES" and args ) then
		self:ParseNotesRequest(sender, string.split("@", args))
	-- GEAR:<serialized table of the persons gear>
	elseif( cmd == "GEAR" and args and ( not requestThrottle[sender] or requestThrottle[sender] < GetTime() ) ) then
		requestThrottle[sender] = GetTime() + REQUEST_THROTTLE
		self:ParseSentGear(sender, string.split("@", args))
	-- NOTES:<serialized table of the notes on the people requested through REQNOTES
	elseif( cmd == "NOTES" and args and ( not requestThrottle[sender] or requestThrottle[sender] < GetTime() ) ) then
		requestThrottle[sender] = GetTime() + REQUEST_THROTTLE
		self:ParseSentNotes(sender, currentTime or time(), string.split("@", args))
	end
end

-- If the fact that the comm is not delayed causes issues, then will have to fix it
function Sync:PLAYER_REGEN_ENABLED()
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	
	for i=#(combatQueue), 1, -1 do
		local data = table.remove(combatQueue, i)
		self:OnCommReceived(COMM_PREFIX, data[1], data[2], data[3], data[4])
	end
end

function Sync:CommMessage(message, channel, target)
	if( ElitistGroup.db.profile.comm.enabled ) then
		self:SendCommMessage(COMM_PREFIX, message, channel, target)
	end
end
