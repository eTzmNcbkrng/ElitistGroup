local ElitistGroup = select(2, ...)
local Scan = ElitistGroup:NewModule("Scan", "AceEvent-3.0")
local L = ElitistGroup.L

-- These are the fields that comm are allowed to send, this is used so people don't try and make super complex tables to send to the user and either crash or lag them.
ElitistGroup.VALID_DB_FIELDS = {["name"] = "string", ["server"] = "string", ["level"] = "number", ["classToken"] = "string", ["talentTree1"] = "number", ["talentTree2"] = "number", ["talentTree3"] = "number", ["achievements"] = "table", ["equipment"] = "table", ["specRole"] = "string", ["unspentPoints"] = "number"}
ElitistGroup.VALID_NOTE_FIELDS = {["time"] = "number", ["role"] = "number", ["rating"] = "number", ["comment"] = "string"}
ElitistGroup.MAX_LINK_LENGTH = 80
ElitistGroup.MAX_NOTE_LENGTH = 256

local MAX_QUEUE_RETRIES = 50
local QUEUE_RETRY_TIME = 2
local INSPECTION_TIMEOUT = 2
local GEAR_CHECK_INTERVAL = 0.10
local pending, pendingGear, inspectQueue = {}, {}, {}

function Scan:OnInitialize()
	self:RegisterEvent("INSPECT_TALENT_READY")
	self:RegisterEvent("INSPECT_ACHIEVEMENT_READY")
	self:RegisterEvent("PLAYER_LEAVING_WORLD", "ResetQueue")
	
	self.frame = CreateFrame("Frame")
	self.frame:SetScript("OnUpdate", function(self, elapsed)
		if( self.queueTimer ) then
			self.queueTimer = self.queueTimer - elapsed
			
			if( self.queueTimer <= 0 ) then
				self.queueTimer = self.queueTimer + QUEUE_RETRY_TIME
				Scan:ProcessQueue()
			end
		end
		
		if( self.gearTimer ) then
			self.gearTimer = self.gearTimer - elapsed
			
			if( self.gearTimer <= 0 ) then
				self.gearTimer = self.gearTimer + GEAR_CHECK_INTERVAL
				Scan:CheckInspectGear()
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
	--if( ( unit == "mouseover" or unit == "target" ) and pending.expirationTime and pending.expirationTime > GetTime() ) then return end
	Scan.allowInspect = nil
	
	if( CanInspect(unit) ) then
		pending.activeInspect = true
		pending.expirationTime = GetTime() + INSPECTION_TIMEOUT
	end

	-- Seems that we can inspect them
	if( UnitIsFriend(unit, "player") and CanInspect(unit) and UnitName(unit) ~= UNKNOWN ) then
		table.wipe(pending)
		table.wipe(pendingGear)

		pending.playerID = ElitistGroup:GetPlayerID(unit)
		pending.classToken = select(2, UnitClass(unit))
		pending.totalChecks = 0
		pending.talents = true
		pending.unit = unit
		pending.guid = UnitGUID(unit)
		pending.achievements = true
		
		Scan:UpdateUnitData(unit)
		
		if( AchievementFrameComparison ) then
			AchievementFrameComparison:UnregisterEvent("INSPECT_ACHIEVEMENT_READY")
		end
		SetAchievementComparisonUnit(unit)
		

		Scan.frame.gearTimer = GEAR_CHECK_INTERVAL
		Scan.frame:Show()
	end
end)

hooksecurefunc("ClearAchievementComparisonUnit", function(unit)
	if( pending.achievements ) then
		pending.achievements = nil
	
		if( AchievementFrameComparison ) then
			AchievementFrameComparison:RegisterEvent("INSPECT_ACHIEVEMENT_READY")
		end
	end
end)

function Scan:CheckInspectGear()
	if( not pending.playerID or pending.totalChecks >= 30 or UnitGUID(pending.unit) ~= pending.guid ) then
		self.frame.gearTimer = nil
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
		self.frame.gearTimer = nil
		self:SendMessage("SG_DATA_UPDATED", "gear", pending.playerID)

		-- If achievements and talent data is already available, we have all the info we need and inspects can unblock
		if( not pending.achievements and not pending.talents ) then
			pending.activeInspect = nil
			pending.expirationTime = nil
			self:ProcessQueue()
		end
	end
end

function Scan:INSPECT_ACHIEVEMENT_READY()
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
	end
end

-- Inspection seems to block until INSPECT_TALENT_READY is fired, then it unblocks
function Scan:INSPECT_TALENT_READY()
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
	local userData = ElitistGroup.userData[playerID] or {talentTree1 = 0, talentTree2 = 0, talentTree3 = 0, from = ElitistGroup.playerName, trusted = true, scanned = time(), notes = {}, achievements = {}, equipment = {}}
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
	local userData = ElitistGroup.userData[playerID] or {talentTree1 = 0, talentTree2 = 0, talentTree3 = 0, from = ElitistGroup.playerName, trusted = true, scanned = time(), notes = {}, achievements = {}, equipment = {}}
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

	local userData = ElitistGroup.userData[ElitistGroup:GetPlayerID(unit)]
	userData.scanned = time()

	table.wipe(userData.equipment)
	for itemType in pairs(ElitistGroup.Items.inventoryToID) do
		local inventoryID = GetInventorySlotInfo(itemType)
		local itemLink = GetInventoryItemLink(unit, inventoryID)
		
		userData.equipment[inventoryID] = ElitistGroup:GetItemLink(itemLink)
				
		-- Basically, this makes sure that either the item has no sockets that need to be loaded, or that the data isn't already present
		if( pending.unit == unit and itemLink ) then
			local totalSockets = ElitistGroup.EMPTY_GEM_SLOTS[itemLink]
			if( totalSockets > 0 ) then
				local gem1, gem2, gem3 = string.match(itemLink, "item:%d+:%d+:(%d+):(%d+):(%d+)")
				local totalUsed = (gem1 ~= "0" and 1 or 0) + (gem2 ~= "0" and 1 or 0) + (gem3 ~= "0" and 1 or 0)
				if( totalUsed ~= totalSockets ) then
					pendingGear[inventoryID] = itemLink
				end
			end
		end
	end
end

function Scan:UpdatePlayerData()
	self:UpdateUnitData("player")
	
	local userData = ElitistGroup.userData[ElitistGroup.playerName]
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
	self.allowInspect = true
	NotifyInspect(unit)
end

-- Handle the queuing aspect of inspection
function Scan:IsInspectPending()
	return pending.activeInspect and pending.expirationTime and pending.expirationTime > GetTime()
end

function Scan:UnitIsQueued(unit)
	return inspectQueue[unit]
end

function Scan:QueueSize()
	return #(inspectQueue)
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
	for i=1, total do
		local unit = unitType .. i
		if( not inspectQueue[unit] and not UnitIsUnit(unit, "player") ) then
			inspectQueue[unit] = 0
			table.insert(inspectQueue, unit)
		end
	end
	
	table.sort(inspectQueue, sortQueue)
	self:QueueStart()
end

function Scan:QueueUnit(unit)
	if( not inspectQueue[unit] ) then
		inspectQueue[unit] = 0
		table.insert(inspectQueue, unit)
	end
end

function Scan:QueueStart()
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")

	if( not InCombatLockdown() ) then
		self:ProcessQueue()
		self.frame.queueTimer = QUEUE_RETRY_TIME
		self.frame:Show()
	end
end

-- We don't want to be processing queues while in combat, so once you enter combat stop processing until its dropped
function Scan:PLAYER_REGEN_DISABLED()
	self.frame.queueTimer = nil
end

function Scan:PLAYER_REGEN_ENABLED()
	self.frame.queueTimer = QUEUE_RETRY_TIME
	self:ProcessQueue()
end

function Scan:ProcessQueue()
	if( #(inspectQueue) == 0 ) then
		self:ResetQueue()
		return
	elseif( pending.activeInspect and ( pending.expirationTime and pending.expirationTime > GetTime() ) ) then
		return
	end
	
	-- Find the first unit we can inspect
	for i=#(inspectQueue), 1, -1 do
		local unit = inspectQueue[i]
		if( UnitIsFriend(unit, "player") and CanInspect(unit) and UnitName(unit) ~= UNKNOWN ) then
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
	self.frame.queueTimer = nil
	self:UnregisterEvent("PLAYER_REGEN_DISABLED")
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	table.wipe(inspectQueue)
end