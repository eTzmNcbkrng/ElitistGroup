local ElitistGroup = select(2, ...)
local Scan = ElitistGroup:NewModule("Scan", "AceEvent-3.0")
local L = ElitistGroup.L

-- These are the fields that comm are allowed to send, this is used so people don't try and make super complex tables to send to the user and either crash or lag them.
ElitistGroup.VALID_DB_FIELDS = {["name"] = "string", ["server"] = "string", ["level"] = "number", ["classToken"] = "string", ["talentTree1"] = "number", ["talentTree2"] = "number", ["talentTree3"] = "number", ["achievements"] = "table", ["equipment"] = "table", ["specRole"] = "string", ["unspentPoints"] = "number"}
ElitistGroup.VALID_NOTE_FIELDS = {["time"] = "number", ["role"] = "number", ["rating"] = "number", ["comment"] = "string"}
ElitistGroup.MAX_LINK_LENGTH = 80
ElitistGroup.MAX_NOTE_LENGTH = 256

local MAX_QUEUE_RETRIES = 50
local MAX_GEM_RETRIES = 50
local QUEUE_RECHECK_TIME = 2
local INSPECTION_TIMEOUT = 2
local GEAR_CHECK_INTERVAL = 0.10
local pending, pendingGear, inspectQueue, inspectBadGems = {}, {}, {}, {}

function Scan:OnInitialize()
	self:RegisterEvent("PLAYER_LEAVING_WORLD", "ResetQueue")
	
	self.frame = CreateFrame("Frame")
	self.frame:SetScript("OnUpdate", function(self, elapsed)
		if( self.queueTimer ) then
			self.queueTimer = self.queueTimer - elapsed
			
			if( self.queueTimer <= 0 ) then
				self.queueTimer = self.queueTimer + QUEUE_RECHECK_TIME
				Scan:ProcessQueue()
			end
		end
		
		if( self.gearTimer ) then
			self.gearTimer = self.gearTimer - elapsed
			
			if( self.gearTimer <= 0 ) then
				self.gearTimer = self.gearTimer + GEAR_CHECK_INTERVAL
				Scan:CheckInspectGems()
			end
		end
		
		if( not self.queueTimer and not self.gearTimer ) then
			self:Hide()
		end
	end)
	self.frame:Hide()
end

hooksecurefunc("NotifyInspect", function(unit)
	if( InCombatLockdown() or not Scan.allowInspect ) then return end
	Scan.allowInspect = nil
	
	if( CanInspect(unit) ) then
		pending.activeInspect = true
		pending.expirationTime = GetTime() + INSPECTION_TIMEOUT
	end

	-- Seems that we can inspect them
	if( not UnitIsDeadOrGhost(unit) and UnitIsFriend(unit, "player") and CanInspect(unit) and UnitName(unit) ~= UNKNOWN ) then
		table.wipe(pending)
		table.wipe(pendingGear)

		pending.playerID = ElitistGroup:GetPlayerID(unit)
		pending.classToken = select(2, UnitClass(unit))
		pending.totalChecks = 0
		pending.talents = true
		pending.achievements = true
		pending.unit = unit
		pending.guid = UnitGUID(unit)
		
		Scan:UpdateUnitData(unit)
		Scan:RegisterEvent("INSPECT_TALENT_READY")
		Scan:RegisterEvent("INSPECT_ACHIEVEMENT_READY")
		
		if( AchievementFrameComparison ) then
			AchievementFrameComparison:UnregisterEvent("INSPECT_ACHIEVEMENT_READY")
		end
		SetAchievementComparisonUnit(unit)
	end
end)

hooksecurefunc("ClearAchievementComparisonUnit", function(unit)
	Scan:UnregisterEvent("INSPECT_ACHIEVEMENT_READY")
	if( pending.achievements ) then
		pending.achievements = nil
	
		if( AchievementFrameComparison ) then
			AchievementFrameComparison:RegisterEvent("INSPECT_ACHIEVEMENT_READY")
		end
	end
end)

-- If we have all the necessary data, we can head off to the next queued unit
local function checkPending(unit)
	if( inspectQueue[unit] and not pending.achievements and not pending.gear and not pending.talents ) then
		pending.activeInspect = nil
		pending.expirationTime = nil
		self:ProcessQueue()
	end
end

function Scan:CheckInspectGems()
	if( not pending.gems or not pending.playerID or pending.totalChecks >= 30 or UnitGUID(pending.unit) ~= pending.guid ) then
		self.frame.gearTimer = nil
		pending.gems = nil
		
		if( pending.playerID ) then
			self:SendMessage("SG_DATA_UPDATED", "gems", pending.playerID)
		end
		return
	end
	
	pending.totalChecks = pending.totalChecks + 1
	
	local totalPending = 0
	for inventoryID, itemLink in pairs(pendingGear) do
		local currentLink = GetInventoryItemLink(pending.unit, inventoryID)
		if( currentLink ~= itemLink ) then
			pendingGear[inventoryID] = nil
			ElitistGroup.userData[pending.playerID].equipment[inventoryID] = ElitistGroup:GetItemLink(currentLink)
		else
			totalPending = totalPending + 1
		end
	end
	
	if( totalPending == 0 ) then
		inspectBadGems[pending.unit] = nil
		for i=#(inspectBadGems), 1, -1 do
			if( inspectBadGems[i] == pending.unit ) then
				table.remove(inspectBadGems, i)
			end
		end
		
		pending.gems = nil
		self.frame.gearTimer = nil
		self:SendMessage("SG_DATA_UPDATED", "gems", pending.playerID)

		checkPending(pending.unit)
	end
end

function Scan:INSPECT_ACHIEVEMENT_READY()
	self:UnregisterEvent("INSPECT_ACHIEVEMENT_READY")
	
	if( pending.playerID and pending.achievements and ElitistGroup.userData[pending.playerID] ) then
		local userData = ElitistGroup.userData[pending.playerID]
		for achievementID in pairs(ElitistGroup.Dungeons.achievements) do
			local id, _, _, _, _, _, _, _, flags = GetAchievementInfo(achievementID)
			if( flags == ACHIEVEMENT_FLAGS_STATISTIC ) then
				userData.achievements[achievementID] = tonumber(GetComparisonStatistic(id)) or nil
			else
				userData.achievements[achievementID] = GetAchievementComparisonInfo(id) and 1 or nil
			end
		end
		
		ClearAchievementComparisonUnit()
		self:SendMessage("SG_DATA_UPDATED", "achievements", pending.playerID)
		checkPending(pending.unit)
	end
end

-- Inspection seems to block until INSPECT_TALENT_READY is fired, then it unblocks
function Scan:INSPECT_TALENT_READY()
	self:UnregisterEvent("INSPECT_TALENT_READY")
	
	if( pending.playerID and pending.talents and ElitistGroup.userData[pending.playerID] ) then
		pending.talents = nil
		
		local userData = ElitistGroup.userData[pending.playerID]
		local first, second, third, unspentPoints, specRole = self:GetTalentData(pending.classToken, true)
		userData.talentTree1 = first
		userData.talentTree2 = second
		userData.talentTree3 = third
		userData.unspentPoints = unspentPoints
		userData.specRole = specRole
		
		self:SendMessage("SG_DATA_UPDATED", "talents", pending.playerID)
		checkPending(pending.unit)
	end
end

function Scan:GetTalentData(classToken, inspect)
	local specRole
	local forceData = ElitistGroup.Talents.specOverride[classToken]
	local activeTalentGroup = GetActiveTalentGroup(inspect)
	if( forceData ) then
		local talentMatches = 0
		for tabIndex=1, GetNumTalentTabs(inspect) do
			for talentID=1, GetNumTalents(tabIndex, inspect) do
				local name, _, _, _, spent = GetTalentInfo(tabIndex, talentID, inspect, nil, activeTalentGroup)
				if( forceData[name] and spent >= forceData[name] ) then
					talentMatches = talentMatches + 1
				end
			end
		end
		
		specRole = talentMatches >= forceData.required and forceData.role
	end
	
	local first = select(3, GetTalentTabInfo(1, inspect, nil, activeTalentGroup))
	local second = select(3, GetTalentTabInfo(2, inspect, nil, activeTalentGroup))
	local third = select(3, GetTalentTabInfo(3, inspect, nil, activeTalentGroup))
	local unspentPoints = GetUnspentTalentPoints(inspect, nil, activeTalentGroup)
	unspentPoints = unspentPoints > 0 and unspentPoints or nil
	
	return first or 0, second or 0, third or 0, unspentPoints, specRole
end

function Scan:ManualCreateCore(playerID, level, classToken)
	local name, server = string.split("-", playerID, 2)
	local userData = ElitistGroup.userData[playerID] or {talentTree1 = 0, talentTree2 = 0, talentTree3 = 0, from = ElitistGroup.playerID, scanned = time(), notes = {}, achievements = {}, equipment = {}}
	userData.name = name
	userData.server = server
	userData.level = level
	userData.classToken = classToken
	userData.pruned = nil
	
	ElitistGroup.userData[playerID] = userData
	ElitistGroup.writeQueue[playerID] = true
	
	-- This is just so loops to find players can be simplified to only look through one table
	ElitistGroup.db.faction.users[playerID] = ElitistGroup.db.faction.users[playerID] or ""
end

function Scan:CreateCoreTable(unit)
	local name, server = UnitName(unit)
	local playerID = ElitistGroup:GetPlayerID(unit)
	local userData = ElitistGroup.userData[playerID] or {talentTree1 = 0, talentTree2 = 0, talentTree3 = 0, from = ElitistGroup.playerID, scanned = time(), notes = {}, achievements = {}, equipment = {}}
	userData.name = name
	userData.server = server and server ~= "" and server or GetRealmName()
	userData.level = UnitLevel(unit)
	userData.classToken = select(2, UnitClass(unit))
	userData.pruned = nil
	
	ElitistGroup.userData[playerID] = userData
	ElitistGroup.writeQueue[playerID] = true
	
	-- This is just so loops to find players can be simplified to only look through one table
	ElitistGroup.db.faction.users[playerID] = ElitistGroup.db.faction.users[playerID] or ""
end

function Scan:UpdateUnitData(unit)
	self:CreateCoreTable(unit)

	local badGems
	local userData = ElitistGroup.userData[ElitistGroup:GetPlayerID(unit)]
	userData.scanned = time()
	
	for itemType in pairs(ElitistGroup.Items.inventoryToID) do
		local inventoryID = GetInventorySlotInfo(itemType)
		local itemLink = ElitistGroup:GetItemLink(GetInventoryItemLink(unit, inventoryID))
		
		-- No item, clear it
		if( not itemLink ) then
			userData.equipment[inventoryID] = nil
		-- We didn't inspect the person, no data yet or we have a previous one saved, but the itemid changed
		elseif( pending.unit ~= unit or ( userData.equipment[inventoryID] and string.match(itemLink, "item:(%d+)") ~= string.match(userData.equipment[inventoryID], "item:(%d+)") ) ) then
			userData.equipment[inventoryID] = itemLink
		-- We have data, and the item is the same figure out what is different.
		else
			-- The item has gems, so we need to make sure we have data for it (or don't)
			local totalSockets = ElitistGroup.EMPTY_GEM_SLOTS[itemLink]
			if( totalSockets > 0 ) then
				local enchantID, gem1, gem2, gem3 = string.match(itemLink, "item:%d+:(%d+):(%d+):(%d+):(%d+)")
				-- Invalid gem data, queue it up, don't change the saved data
				if( gem1 == "0" and gem2 == "0" and gem3 == "0" ) then
					pendingGear[inventoryID] = GetInventoryItemLink(unit, inventoryID)
					badGems = true
					
					-- Set it in case we don't have it already
					userData.equipment[inventoryID] = userData.equipment[inventoryID] or itemLink
					
				-- Have data! save it and don't worry
				else
					userData.equipment[inventoryID] = itemLink
				end
			-- No sockets, just save
			else
				userData.equipment[inventoryID] = itemLink
			end
		end
	end
	
	if( badGems ) then
		inspectQueue.gems = true
		
		if( inspectQueue[unit] and not inspectBadGems[unit] ) then
			inspectBadGems[unit] = 0
			table.insert(inspectBadGems, unit)
		end

		Scan.frame.gearTimer = GEAR_CHECK_INTERVAL
		Scan.frame:Show()
	elseif( pending.unit == unit ) then
		self:SendMessage("SG_DATA_UPDATED", "gems", pending.playerID)
	end
end

function Scan:UpdatePlayerData()
	self:UpdateUnitData("player")
	
	local userData = ElitistGroup.userData[ElitistGroup.playerID]
	local first, second, third, unspentPoints, specRole = self:GetTalentData(select(2, UnitClass("player")), nil)
	userData.talentTree1 = first
	userData.talentTree2 = second
	userData.talentTree3 = third
	userData.unspentPoints = unspentPoints
	userData.specRole = specRole

	table.wipe(userData.achievements)
	for achievementID in pairs(ElitistGroup.Dungeons.achievements) do
		local id, _, _, completed, _, _, _, _, flags = GetAchievementInfo(achievementID)
		if( bit.band(flags, ACHIEVEMENT_FLAGS_STATISTIC) > 0 ) then
			userData.achievements[id] = tonumber(GetStatistic(id)) or nil
		else
			userData.achievements[id] = completed and 1 or nil
		end
	end
end

function Scan:InspectUnit(unit)
	if( UnitIsUnit(unit, "player") ) then
		self:UpdatePlayerData()
	else
		self.allowInspect = true
		NotifyInspect(unit)
	end
end

-- Handle the queuing aspect of inspection
function Scan:IsInspectPending()
	return pending.activeInspect and pending.expirationTime and pending.expirationTime > GetTime()
end

function Scan:UnitIsQueued(unit)
	return inspectQueue[unit]
end

function Scan:QueueSize()
	return #(inspectQueue) + #(inspectBadGems)
end

-- Try and speed up the queue so people who are initially in range are done first not perfectly obviously, but better than nothing
local function sortQueue(a, b)
	local aInspect = a and CanInspect(a)
	local bInspect = b and CanInspect(b)
	
	if( aInspect == bInspect ) then
		return a < b
	elseif( aInspect ) then
		return true
	elseif( bInspect ) then
		return false
	end
end

function Scan:QueueGroup(unitType, total)
	table.wipe(inspectQueue)
	
	for i=1, total do
		local unit = unitType .. i
		if( not inspectQueue[unit] and not UnitIsUnit(unit, "player") ) then
			inspectQueue[unit] = 0
			table.insert(inspectQueue, unit)
		end
	end
	
	table.wipe(inspectBadGems)
	table.sort(inspectQueue, sortQueue)
	self:QueueStart()
end

function Scan:QueueUnit(unit)
	if( not inspectQueue[unit] ) then
		inspectQueue[unit] = 0
		inspectBadGems[unit] = nil
		table.insert(inspectQueue, unit)
	end
end

function Scan:QueueStart()
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")

	if( not InCombatLockdown() ) then
		self:ProcessQueue()
		self.frame.queueTimer = QUEUE_RECHECK_TIME
		self.frame:Show()
	end
end

-- We don't want to be processing queues while in combat, so once you enter combat stop processing until its dropped
function Scan:PLAYER_REGEN_DISABLED()
	self.frame.queueTimer = nil
end

function Scan:PLAYER_REGEN_ENABLED()
	self.frame.queueTimer = QUEUE_RECHECK_TIME
	self:ProcessQueue()
end

--hooksecurefunc("NotifyInspect", function(...) print(...) end)

local checkGemQueue
function Scan:ProcessQueue()
	if( #(inspectQueue) == 0 and #(inspectBadGems) == 0 ) then
		self:ResetQueue()
		return
	elseif( InCombatLockdown() or ( pending.activeInspect and pending.expirationTime and pending.expirationTime > GetTime() ) ) then
		return
	end
	
	-- First check the bad gem queue
	if( not checkGemQueue ) then
		for i=#(inspectBadGems), 1, -1 do
			local unit = inspectBadGems[i]
			if( not UnitIsDeadOrGhost(unit) and UnitExists(unit) and UnitIsVisible(unit) and UnitIsFriend(unit, "player") and CanInspect(unit) and UnitName(unit) ~= UNKNOWN ) then
				checkGemQueue = true
				self:InspectUnit(unit)
				break
			-- Kill them, figuratively
			elseif( inspectBadGems[unit] > MAX_GEM_RETRIES ) then
				table.remove(inspectBadGems, i)
			else
				inspectBadGems[unit] = inspectBadGems[unit] + 1
			end
		end
	
		if( checkGemQueue or pending.activeInspect and ( pending.expirationTime and pending.expirationTime > GetTime() ) ) then
			return
		end
	end
	
	checkGemQueue = nil

	-- Find the first unit we can inspect
	for i=#(inspectQueue), 1, -1 do
		local unit = inspectQueue[i]
		if( not UnitIsDeadOrGhost(unit) and UnitExists(unit) and UnitIsVisible(unit) and UnitIsFriend(unit, "player") and CanInspect(unit) and UnitName(unit) ~= UNKNOWN ) then
			self:InspectUnit(unit)
			
			table.remove(inspectQueue, i)
			inspectQueue[unit] = nil
			break
		-- Kill them, figuratively
		elseif( inspectQueue[unit] > MAX_QUEUE_RETRIES ) then
			table.remove(inspectQueue, i)
			inspectQueue[unit] = nil
		else
			inspectQueue[unit] = inspectQueue[unit] + 1
		end
	end
end

function Scan:ResetQueue()
	checkGemQueue = nil
	self.frame.queueTimer = nil

	self:UnregisterEvent("PLAYER_REGEN_DISABLED")
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	table.wipe(inspectQueue)
	table.wipe(inspectBadGems)
end