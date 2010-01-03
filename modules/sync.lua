-- Some of the sanity checks in this are a bit unnecessary and me being super paranoid
-- but I know how much people will love to try and break this, so I am going to give them as little way to break it as possible
local ElitistGroup = select(2, ...)
local Sync = ElitistGroup:NewModule("Sync", "AceEvent-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceComm-3.0")
local L = ElitistGroup.L
local playerName = UnitName("player")
local combatQueue, requestThrottle, cachedPlayerData, blockOfflineMessage = {}, {}
local COMM_PREFIX = "SMPGRP"
local MAX_QUEUE = 20
local REQUEST_TIMEOUT = 10
-- This should be raised most likely, but for now only allow a notes or gear request every 5 seconds from someoneone
local REQUEST_THROTTLE = 5

function Sync:Setup()
	if( ElitistGroup.db.profile.comm.enabled ) then
		self:RegisterComm(COMM_PREFIX)
		self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", "ResetCacheData")
		self:RegisterEvent("ACHIEVEMENT_EARNED", "ResetCacheData")
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

function Sync:ResetThrottle(sender)
	requestThrottle[sender] = nil
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

-- This will have to be changed, I'm not quite sure a good way of doing it yet
function Sync:RequestSuccessful(event, type, name)
	ElitistGroup:Print(string.format(L["Successfully got data on %s, type /ElitistGroup %s to view!"], name, name))
	self:UnregisterMessage("SG_DATA_UPDATED")
end

function Sync:SendGearRequest(gearFor)
	if( not gearFor or gearFor == "" ) then
		ElitistGroup:Print(L["Invalid name entered."])
		return
	elseif( gearFor == "target" or gearFor == "focus" or gearFor == "mouseover" ) then
		local server
		gearFor, server = UnitName(gearFor)
		if( server and server ~= "" ) then gearFor = string.format("%s-%s", gearFor, server) end

		if( not gearFor ) then
			ElitistGroup:Print(L["No name found for unit."])
			return
		end
	end
	
	self:CommMessage("REQGEAR", "WHISPER", gearFor)
	self:RegisterMessage("SG_DATA_UPDATED", "RequestSuccessful")
	self:ScheduleTimer("UnregisterMessage", REQUEST_TIMEOUT, "SG_DATA_UPDATED")
end

function Sync:SendNoteRequest(notesOn)
	if( not IsInGuild() ) then
		ElitistGroup:Print(L["You need to be in a guild to request notes on players."])
		return
	elseif( not notesOn or notesOn == "" ) then
		ElitistGroup:Print(L["Invalid name entered."])
		return
	elseif( notesOn == "target" or notesOn == "focus" or notesOn == "mouseover" ) then
		notesOn = ElitistGroup:GetPlayerID(notesOn)
		if( not notesOn ) then
			ElitistGroup:Print(L["No name found for unit."])
			return
		end
	elseif( not string.match(notesOn, "%-") ) then
		notesOn = string.format("%s-%s", notesOn, GetRealmName())
	end
		
	self:CommMessage(string.format("REQNOTES@%s", notesOn), "GUILD")
	self:RegisterMessage("SG_DATA_UPDATED", "RequestSuccessful")
	self:ScheduleTimer("UnregisterMessage", REQUEST_TIMEOUT, "SG_DATA_UPDATED")
end

function Sync:ParseGearRequest(sender)
	if( not ElitistGroup.db.profile.comm.gearRequests ) then return end
	
	-- Players info should rarely change, so we can just cache it and that will be all we need most of the time
	if( not cachedPlayerData ) then
		ElitistGroup.modules.Scan:UpdatePlayerData("player")
		cachedPlayerData = string.format("GEAR@%s", ElitistGroup:WriteTable(ElitistGroup.userData[ElitistGroup.playerName], true))
	end
	
	self:CommMessage(cachedPlayerData, "WHISPER", sender)
end

function Sync:ParseNotesRequest(sender, ...)
	-- To pull note data, we do have to unserialize stuff, so we probably shouldn't let people request more than 5 notes at a time
	-- since it means we can delay it on the clients side too to prevent any lag
	if( select("#", ...) == 0 or select("#", ...) > 5 ) then return end
	requestThrottle[sender] = true
	self:ScheduleTimer("ResetThrottle", REQUEST_THROTTLE, sender)

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

function Sync:ParseSentGear(sender, data)
	if( not data ) then return end
	requestThrottle[sender] = true
	self:ScheduleTimer("ResetThrottle", REQUEST_THROTTLE, sender)
	
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
		if( type(key) ~= "number" or type(value) ~= "string" or not string.match(value, "item:(%d+)") or string.len(value) > ElitistGroup.MAX_LINK_LENGTH or not ElitistGroup.VALID_INVENTORY_SLOTS ) then
			sentData.equipment[key] = nil
		end
	end
	
	-- Verify achievements
	for key, value in pairs(sentData.achievements) do
		if( type(key) ~= "number" or type(value) ~= "number" or not ElitistGroup.VALID_ACHIEVEMENTS[key] ) then
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
			note.comment = ElitistGroup:SafeEncode(note.comment)
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
		self:ParseGearRequest(sender)
	-- REQNOTES:playerA@playerBplayerC@etc - Request notes on the given players
	elseif( cmd == "REQNOTES" and args ) then
		self:ParseNotesRequest(sender, string.split("@", args))
	elseif( cmd == "GEAR" and args and not requestThrottle[sender] ) then
		self:ParseSentGear(sender, string.split("@", args))
	elseif( cmd == "NOTES" and args and not requestThrottle[sender] ) then
		self:ParseSentNotes(sender, currentTime or time(), string.split("@", args))
	end
end

-- Rather than instantly processing the queue, will slowly process it over 6 seconds so the client doesn't lock up at all
function Sync:PLAYER_REGEN_ENABLED()
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	
	for i=#(combatQueue), 1, -1 do
		self:ScheduleTimer("DelayedComm", i * 0.3, table.remove(combatQueue, i))
	end
end

function Sync:DelayedComm(data)
	self:OnCommReceived(COMM_PREFIX, data[1], data[2], data[3], data[4])
end

function Sync:CommMessage(message, channel, target)
	self:SendCommMessage(COMM_PREFIX, message, channel, target)
end
