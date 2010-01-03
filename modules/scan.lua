local SimpleGroup = select(2, ...)
local Scan = SimpleGroup:NewModule("Scan", "AceEvent-3.0")
local L = SimpleGroup.L

-- These are the fields that comm are allowed to send, this is used so people don't try and make super complex tables to send to the user and either crash or lag them.
SimpleGroup.VALID_DB_FIELDS = {["name"] = "string", ["server"] = "string", ["level"] = "number", ["classToken"] = "string", ["talentTree1"] = "number", ["talentTree2"] = "number", ["talentTree3"] = "number", ["achievements"] = "table", ["equipment"] = "table", ["specRole"] = "string", ["unspentPoints"] = "number"}
SimpleGroup.VALID_NOTE_FIELDS = {["time"] = "number", ["role"] = "number", ["rating"] = "number", ["comment"] = "string"}
SimpleGroup.MAX_LINK_LENGTH = 80
SimpleGroup.MAX_NOTE_LENGTH = 256

local MAX_QUEUE_RETRIES = 20
local QUEUE_RETRY_TIME = 2
local INSPECTION_TIMEOUT = 2
local GEAR_CHECK_INTERVAL = 0.20
local pending, pendingGear, inspectQueue, queueRetries = {}, {}, {}, {}

function Scan:OnInitialize()
	self:RegisterEvent("INSPECT_TALENT_READY")
	self:RegisterEvent("INSPECT_ACHIEVEMENT_READY")
	
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

function Scan:IsInspectPending()
	return pending.activeInspect and pending.expirationTime and pending.expirationTime > GetTime()
end

function Scan:QueueAdd(unit)
	if( not queueRetries[unit] ) then
		queueRetries[unit] = 0
		table.insert(inspectQueue, unit)
	end
end

function Scan:ResetQueue()
	table.wipe(inspectQueue)
	table.wipe(queueRetries)
end

function Scan:ProcessQueue()
	if( #(inspectQueue) == 0 ) then
		self.frame.queueTimer = nil
		table.wipe(queueRetries)
		return
	end
	
	if( not pending.activeInspect or pending.expirationTime and pending.expirationTime < GetTime() ) then
		local unit = table.remove(inspectQueue, 1)

		NotifyInspect(unit)
		if( pending.unit ~= unit and UnitExists(unit) and queueRetries[unit] < MAX_QUEUE_RETRIES ) then
			queueRetries[unit] = queueRetries[unit] + 1
			table.insert(inspectQueue, unit)
		end
	end
end

function Scan:QueueStart()
	self:ProcessQueue()
	self.frame.queueTimer = QUEUE_RETRY_TIME
	self.frame:Show()
end

hooksecurefunc("NotifyInspect", function(unit)
	if( not pending.activeInspect or pending.expirationTime and pending.expirationTime < GetTime() ) then
		table.wipe(pending)
		table.wipe(pendingGear)
	end
	
	if( UnitIsFriend(unit, "player") and CanInspect(unit) and UnitName(unit) ~= UNKNOWN and not pending.playerID and not pending.activeInspect ) then
		pending.playerID = SimpleGroup:GetPlayerID(unit)
		pending.classToken = select(2, UnitClass(unit))
		pending.totalChecks = 0
		pending.talents = true
		pending.unit = unit
		pending.guid = UnitGUID(unit)

		Scan:UpdateUnitData(unit)
		SetAchievementComparisonUnit(unit)

		Scan.frame.gearTimer = GEAR_CHECK_INTERVAL
		Scan.frame:Show()
	end

	if( CanInspect(unit) ) then
		pending.activeInspect = true
		pending.expirationTime = GetTime() + INSPECTION_TIMEOUT
	end
end)

hooksecurefunc("SetAchievementComparisonUnit", function(unit) pending.achievements = true end)
hooksecurefunc("ClearAchievementComparisonUnit", function(unit) pending.achievements = nil end)

function Scan:CheckInspectGear()
	if( not pending.playerID or pending.totalChecks >= 25 or UnitGUID(pending.unit) ~= pending.guid ) then
		self.frame.gearTimer = nil
		return
	end
	
	pending.totalChecks = pending.totalChecks + 1
	
	local totalPending = 0
	for inventoryID, itemLink in pairs(pendingGear) do
		local currentLink = GetInventoryItemLink(pending.unit, inventoryID)
		if( currentLink ~= itemLink ) then
			pendingGear[inventoryID] = nil
			SimpleGroup.userData[pending.playerID].equipment[inventoryID] = SimpleGroup:GetItemLink(currentLink)
		else
			totalPending = totalPending + 1
		end
	end
	
	if( totalPending == 0 ) then
		self.frame.gearTimer = nil
		self:SendMessage("SG_DATA_UPDATED", "gear", pending.playerID)
	end
end

function Scan:INSPECT_ACHIEVEMENT_READY()
	if( pending.playerID and pending.achievements and SimpleGroup.userData[pending.playerID] ) then
		pending.achievements = nil
		
		local userData = SimpleGroup.userData[pending.playerID]
		for achievementID in pairs(SimpleGroup.VALID_ACHIEVEMENTS) do
			local id, _, _, _, _, _, _, _, flags = GetAchievementInfo(achievementID)
			if( flags == ACHIEVEMENT_FLAGS_STATISTIC ) then
				userData.achievements[achievementID] = tonumber(GetComparisonStatistic(id)) or nil
			else
				userData.achievements[achievementID] = GetAchievementComparisonInfo(id) and 1 or nil
			end
		end
		
		self:SendMessage("SG_DATA_UPDATED", "achievements", pending.playerID)
	end
end

function Scan:INSPECT_TALENT_READY()
	if( pending.playerID and pending.talents and SimpleGroup.userData[pending.playerID] ) then
		pending.talents = nil
		
		local userData = SimpleGroup.userData[pending.playerID]
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
	local forceData = SimpleGroup.FORCE_SPECROLE[classToken]
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

function Scan:CreateCoreTable(unit)
	local name, server = UnitName(unit)
	local playerID = SimpleGroup:GetPlayerID(unit)
	local userData = SimpleGroup.userData[playerID] or {talentTree1 = 0, talentTree2 = 0, talentTree3 = 0, from = SimpleGroup.playerName, trusted = true, scanned = time(), notes = {}, achievements = {}, equipment = {}}
	userData.name = name
	userData.server = server and server ~= "" and server or GetRealmName()
	userData.level = UnitLevel(unit)
	userData.classToken = select(2, UnitClass(unit))
	
	SimpleGroup.userData[playerID] = userData
	SimpleGroup.writeQueue[playerID] = true
	
	-- This is just so loops to find players can be simplified to only look through one table
	SimpleGroup.db.faction.users[playerID] = SimpleGroup.db.faction.users[playerID] or ""
end

function Scan:UpdateUnitData(unit)
	self:CreateCoreTable(unit)

	local userData = SimpleGroup.userData[SimpleGroup:GetPlayerID(unit)]
	userData.scanned = time()

	table.wipe(userData.equipment)
	for itemType in pairs(SimpleGroup.INVENTORY_TO_TYPE) do
		local inventoryID = GetInventorySlotInfo(itemType)
		local itemLink = GetInventoryItemLink(unit, inventoryID)
		userData.equipment[inventoryID] = SimpleGroup:GetItemLink(itemLink)
				
		-- Basically, this makes sure that either the item has no sockets that need to be loaded, or that the data isn't already present
		if( pending.unit == unit and itemLink ) then
			local totalSockets = SimpleGroup.EMPTY_GEM_SLOTS[itemLink]
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
	
	local userData = SimpleGroup.userData[SimpleGroup.playerName]
	local first, second, third, unspentPoints, specRole = self:GetTalentData(select(2, UnitClass("player")), nil)
	userData.talentTree1 = first
	userData.talentTree2 = second
	userData.talentTree3 = third
	userData.unspentPoints = unspentPoints
	userData.specRole = specRole

	table.wipe(userData.achievements)
	for achievementID in pairs(SimpleGroup.VALID_ACHIEVEMENTS) do
		local id, _, _, completed, _, _, _, _, flags = GetAchievementInfo(achievementID)
		if( flags == ACHIEVEMENT_FLAGS_STATISTIC ) then
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
		NotifyInspect(unit)
	end
end