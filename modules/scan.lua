local SexyGroup = select(2, ...)
local Scan = SexyGroup:NewModule("Scan", "AceEvent-3.0", "AceTimer-3.0")
local L = SexyGroup.L

-- These are the fields that comm are allowed to send, this is used so people don't try and make super complex tables to send to the user and either crash or lag them.
SexyGroup.VALID_DB_FIELDS = {["name"] = "string", ["server"] = "string", ["level"] = "number", ["classToken"] = "string", ["talentTree1"] = "number", ["talentTree2"] = "number", ["talentTree3"] = "number", ["achievements"] = "table", ["equipment"] = "table", ["specRole"] = "string", ["unspentPoints"] = "number"}
SexyGroup.VALID_NOTE_FIELDS = {["time"] = "number", ["role"] = "number", ["rating"] = "number", ["comment"] = "string"}
SexyGroup.MAX_LINK_LENGTH = 80

local pending = {}

function Scan:OnInitialize()
	self:RegisterEvent("INSPECT_TALENT_READY")
	self:RegisterEvent("INSPECT_ACHIEVEMENT_READY")
end

do
	local inspectQueue = {}

	function Scan:PushQueue(unit)
		for i = 1, #inspectQueue do
			if inspectQueue[i] == unit then return end		
		end
		
		table.insert(inspectQueue, 1, unit)
	end
	
	function Scan:RemoveQueue(unit)
		for i=#(inspectQueue), 1, -1 do
			if( inspectQueue[i] == unit ) then
				table.remove(inspectQueue, 1, unit)
			end
		end
	end
	
	function popInspectQueue()
		Scan:ScheduleTimer("FlushQueue", 3)
		if pending.activeInspect then return end		

		local unit = table.remove(inspectQueue)
		if UnitPlayerControlled(unit) and CheckInteractDistance(unit, 1) and CanInspect(unit, false) then
			NotifyInspect(unit)
		elseif( not CheckInteractDistance(unit, 1) ) then
			table.insert(inspectQueue, 1, unit)
		end
	end
	
	function Scan:FlushQueue()
		if #inspectQueue > 0 then
			popInspectQueue()
		else
			self:CancelTimer("FlushQueue", true)
		end
	end
end

hooksecurefunc("NotifyInspect", function(unit)
	if( UnitIsFriend(unit, "player") and CanInspect(unit) and not pending.playerID ) then
		table.wipe(pending)
		pending.playerID = SexyGroup:GetPlayerID(unit)
		pending.classToken = select(2, UnitClass(unit))
		pending.totalChecks = 0
		pending.talents = true
		pending.gear = true
		pending.unit = unit
		pending.guid = UnitGUID(unit)

		if( not Scan.isValidInspect ) then
			Scan:UpdateUnitData(unit)
		end
		
		SetAchievementComparisonUnit(unit)
		Scan:ScheduleRepeatingTimer("CheckInspectGear", 0.20)
	end

	if( CanInspect(unit) ) then
		pending.activeInspect = true
		Scan:CancelTimer("ResetPendingInspect", true)
		Scan:ScheduleTimer("ResetPendingInspect", 3)
	end
end)

hooksecurefunc("SetAchievementComparisonUnit", function(unit) pending.achievements = true end)
hooksecurefunc("ClearAchievementComparisonUnit", function(unit) pending.achievements = nil end)

function Scan:ResetPendingInspect()
	table.wipe(pending)

	self:CancelTimer("CheckInspectGear", true)
end

function Scan:CheckInspectGear()
	if( not pending.playerID or not pending.gear or pending.totalChecks > 15 or UnitGUID(pending.unit) ~= pending.guid ) then
		self:CancelTimer("CheckInspectGear", true)
		return
	end
	
	pending.totalChecks = pending.totalChecks + 1
	for itemType in pairs(SexyGroup.INVENTORY_TO_TYPE) do
		local inventoryID = GetInventorySlotInfo(itemType)
		local link = GetInventoryItemLink(pending.unit, inventoryID)
		if( link ~= pending[inventoryID] ) then
			SexyGroup.userData[pending.playerID].equipment[inventoryID] = SexyGroup:GetItemLink(link)
			pending.gear = nil
		end
	end
	
	if( not pending.gear ) then
		pending.totalChecks = nil
		self:CancelTimer("CheckInspectGear", true)
		self:SendMessage("SG_DATA_UPDATED", "gear", pending.playerID)
	end
end

function Scan:INSPECT_ACHIEVEMENT_READY()
	if( pending.playerID and pending.achievements and SexyGroup.userData[pending.playerID] ) then
		pending.achievements = nil
		
		local userData = SexyGroup.userData[pending.playerID]
		for achievementID in pairs(SexyGroup.VALID_ACHIEVEMENTS) do
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
	if( pending.playerID and pending.talents and SexyGroup.userData[pending.playerID] ) then
		pending.talents = nil
		
		local userData = SexyGroup.userData[pending.playerID]
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
	local forceData = SexyGroup.FORCE_SPECROLE[classToken]
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
	local playerID = SexyGroup:GetPlayerID(unit)
	local userData = SexyGroup.userData[playerID] or {talentTree1 = 0, talentTree2 = 0, talentTree3 = 0, from = SexyGroup.playerName, trusted = true, scanned = time(), notes = {}, achievements = {}, equipment = {}}
	userData.name = name
	userData.server = server and server ~= "" and server or GetRealmName()
	userData.level = UnitLevel(unit)
	userData.classToken = select(2, UnitClass(unit))
	
	SexyGroup.userData[playerID] = userData
	SexyGroup.writeQueue[playerID] = true
	
	-- This is just so loops to find players can be simplified to only look through one table
	SexyGroup.db.faction.users[playerID] = SexyGroup.db.faction.users[playerID] or ""
end

function Scan:UpdateUnitData(unit)
	self:CreateCoreTable(unit)

	local userData = SexyGroup.userData[SexyGroup:GetPlayerID(unit)]
	userData.scanned = time()

	table.wipe(userData.equipment)
	for itemType in pairs(SexyGroup.INVENTORY_TO_TYPE) do
		local inventoryID = GetInventorySlotInfo(itemType)
		userData.equipment[inventoryID] = SexyGroup:GetItemLink(GetInventoryItemLink(unit, inventoryID))
		
		if( pending.unit == unit ) then
			pending[inventoryID] = GetInventoryItemLink(unit, inventoryID)
		end
	end
end

function Scan:UpdatePlayerData()
	self:UpdateUnitData("player")
	
	local userData = SexyGroup.userData[SexyGroup.playerName]
	local first, second, third, unspentPoints, specRole = self:GetTalentData(select(2, UnitClass("player")), nil)
	userData.talentTree1 = first
	userData.talentTree2 = second
	userData.talentTree3 = third
	userData.unspentPoints = unspentPoints
	userData.specRole = specRole

	table.wipe(userData.achievements)
	for achievementID in pairs(SexyGroup.VALID_ACHIEVEMENTS) do
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
		self.isValidInspect = true
		NotifyInspect(unit)
		self:UpdateUnitData(unit)
		self.isValidInspect = nil
	end
end