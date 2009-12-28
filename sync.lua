-- Some of the sanity checks in this are a bit unnecessary and me being super paranoid
-- but I know how much people will love to try and break this, so I am going to give them as little way to break it as possible
local SexyGroup = select(2, ...)
local Sync = SexyGroup:NewModule("Sync", "AceEvent-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceComm-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("SexyGroup")
local playerName = UnitName("player")
local combatQueue, requestThrottle, cachedPlayerData = {}, {}
local COMM_PREFIX = "SEXYG"
local MAX_QUEUE = 20
-- This should be raised most likely, but for now only allow a notes or gear request every 5 seconds from someoneone
local REQUEST_THROTTLE = 5

function Sync:Setup()
	if( SexyGroup.db.profile.comm.enabled ) then
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

local function getName(name)
	return string.match(name, "%-") and name or string.format("%s-%s", name, GetRealmName())
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

function Sync:SendGearRequest(gearFor)

end

function Sync:SendNoteRequest(notesOn)

end

function Sync:ParseGearRequest(sender)
	-- Players info should rarely change, so we can just cache it and that will be all we need most of the time
	if( not cachedPlayerData ) then
		SexyGroup.modules.Scan:UpdatePlayerData("player")
		cachedPlayerData = string.format("GEAR@%s", SexyGroup:WriteTable(SexyGroup.userData[SexyGroup.playerName], true))
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
		if( not tempList[name] ) then
			local userData = SexyGroup.userData[name]
			local note = userData and userData.notes[SexyGroup.playerName]
			if( note ) then
				queuedData = string.format('%s["%s"] = %s;', queuedData, name, SexyGroup:WriteTable(note))
			end
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
	
	sentData = self:VerifyTable(sentData(), SexyGroup.VALID_DB_FIELDS)
	if( not sentData or not sentData.achievements or not sentData.equipment ) then return end
	
	-- Verify gear
	for key, value in pairs(sentData.equipment) do
		if( type(key) ~= "number" or type(value) ~= "string" or not string.match(value, "item:(%d+)") or string.len(value) > SexyGroup.MAX_LINK_LENGTH or not SexyGroup.VALID_INVENTORY_SLOTS ) then
			sentData.equipment[key] = nil
		end
	end
	
	-- Verify achievements
	for key, value in pairs(sentData.achievements) do
		if( type(key) ~= "number" or type(value) ~= "number" or not SexyGroup.VALID_ACHIEVEMENTS[key] ) then
			sentData.achievements[key] = nil
		end
	end
		
	-- Merge everything into the current table
	local senderName = getName(sender)
	local userData = SexyGroup.userData[senderName] or {}
	local notes = userData.notes
	table.wipe(userData)

	for key, value in pairs(sentData) do userData[key] = value end
	userData.name = string.match(senderName, "(.-)%-")
	userData.server = string.match(senderName, "%-(.+)")
	userData.notes = notes
	userData.scanned = time()
	userData.from = sender
	userData.trusted = nil
	
	SexyGroup.writeQueue[senderName] = true
	SexyGroup.db.faction.users[senderName] = SexyGroup.db.faction.users[senderName] or ""

	self:SendMessage("SG_DATA_UPDATED", senderName)
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
	local senderName = getName(sender)
	
	for noteFor, note in pairs(sentNotes()) do
		note = self:VerifyTable(note, SexyGroup.VALID_NOTE_FIELDS)
		if( type(note) == "table" and type(noteFor) == "string" and note.time and note.role and note.rating and note.comment ) then
			local name, server = string.split("-", noteFor, 2)
			local userData = SexyGroup.userData[noteFor] or {}
			
			-- If the time drift is over a day, reset the time of the comment to right now
			note.time = timeDrift > 86400 and time() or note.time + timeDrift
			note.comment = SexyGroup:SafeEncode(note.comment)
			note.from = senderName
			note.rating = math.max(math.min(5, note.rating), 0)
			
			userData.notes[senderName] = note
			
			SexyGroup.userData[noteFor] = userData
			SexyGroup.db.faction.users[noteFor] = SexyGroup.db.faction.users[noteFor] or ""
			SexyGroup.writeQueue[noteFor] = true

			self:SendMessage("SG_DATA_UPDATED", noteFor)
		end
	end
end

function Sync:OnCommReceived(prefix, message, distribution, sender, currentTime)
	if( prefix ~= COMM_PREFIX or sender == playerName or not SexyGroup.db.profile.comm.areas[distribution] ) then return end
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
