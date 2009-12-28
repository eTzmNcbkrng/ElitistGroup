local SexyGroup = select(2, ...)
local Scan = SexyGroup:NewModule("Scan", "AceEvent-3.0", "AceHook-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("SexyGroup")

-- These are the fields that comm are allowed to send, this is used so people don't try and make super complex tables to send to the user and either crash or lag them.
SexyGroup.VALID_DB_FIELDS = { ["name"] = "string", ["server"] = "string", ["level"] = "number", ["classToken"] = "string", ["talentTree1"] = "number", ["talentTree2"] = "number", ["talentTree3"] = "number", ["achievements"] = "table", ["equipment"] = "table", ["specRole"] = "string"}
SexyGroup.VALID_NOTE_FIELDS = {["time"] = "number", ["role"] = "number", ["rating"] = "number", ["comment"] = "string"}
SexyGroup.MAX_LINK_LENGTH = 80

local showUnit = nil

function Scan:OnEnable()
	self:RegisterEvent("INSPECT_TALENT_READY")
	self:Hook("NotifyInspect", true)	
	
	-- Queue flushing is a possibility - if we want to scan and cache the whole raid in the background or something?
	-- We can stick with active scanning via inspect for now.
	-- self:ScheduleRepeatingTimer("FlushQueue", 3.0)
end

local pendingInspectUnitToken = nil
do
	local inspectQueue = {}
	local pushInspectQueue, popInspectQueue

	function pushInspectQueue(token)
		for i = 1, #inspectQueue do
			if inspectQueue[i] == token then return end		
		end
		tinsert(inspectQueue, 1, token)
		popInspectQueue()
	end

	function popInspectQueue()
		if pendingInspectUnitToken ~= nil then return end		
		local token = tremove(inspectQueue)
		if token then
			if UnitPlayerControlled("target") and CheckInteractDistance("target", 1) and CanInspect(token, false) then
				NotifyInspect(token)
			else
				tinsert(inspectQueue, 1, token)
			end
		end
	end
	
	function Scan:FlushQueue()
		 if #inspectQueue > 0 then
			popInspectQueue()
		end
	end
	
end

function Scan:NotifyInspect(unit)
	pendingInspectUnitToken = unit
end

function Scan:INSPECT_TALENT_READY()
	if pendingInspectUnitToken then
		self:UpdatePlayerData(pendingInspectUnitToken, showUnit == pendingInspectUnitToken)
		pendingInspectUnitToken = nil
	end
end

function Scan:CreateCoreTable(unit)
	local classToken = select(2, UnitClass(unit))
	local level = UnitLevel(unit)
	
	local playerID, name, server = SexyGroup.GetPlayerID(unit)
	local data = SexyGroup.userData[playerID] or {talentTree1 = 0, talentTree2 = 0, talentTree3 = 0, from = UnitName("player"), trusted = true, scanned = time(), notes = {}, achievements = {}, equipment = {}}
	data.name = name
	data.server = server
	data.level = level
	data.classToken = classToken
	
	SexyGroup.userData[playerID] = data
	SexyGroup.writeQueue[playerID] = true
	
	-- This is just so loops to find players can be simplified to only look through one table
	SexyGroup.db.faction.users[playerID] = SexyGroup.db.faction.users[playerID] or ""
end

function Scan:GetTalentData(classToken, inspect)
	local forceData = SexyGroup.FORCE_SPECROLE[classToken]
	local specRole
	if( forceData ) then
		local talentMatches = 0
		for tabIndex=1, GetNumTalentTabs(inspect) do
			for talentID=1, GetNumTalents(tabIndex, inspect) do
				local name, _, _, _, spent = GetTalentInfo(tabIndex, talentID, inspect)
				if( forceData[name] and spent >= forceData[name] ) then
					talentMatches = talentMatches + 1
				end
			end
		end
		
		specRole = talentMatches >= forceData.required and forceData.role
	end
	
	local first, second, third = select(3, GetTalentTabInfo(1, inspect)), select(3, GetTalentTabInfo(2, inspect)), select(3, GetTalentTabInfo(3, inspect))
	return first or 0, second or 0, third or 0, specRole
end

function Scan:UpdatePartyData()
	for i = 1, 4 do
		self:GetTalentData("party" .. i, true)
	end
end

function Scan:UpdatePlayerData(unit, showResults)
	-- We need data. Go inspectin'. The inspect handler will get us back here.
	if not UnitIsUnit(unit, "player") and not pendingInspectUnitToken then
		if showResults then
			showUnit = unit
		end
		NotifyInspect(unit)
		return
	end
	
	-- We have data...
	self:CreateCoreTable(unit)

	local first, second, third, specRole = self:GetTalentData(select(2, UnitClass(unit)), not UnitIsUnit(unit, "player"))
	local userData = SexyGroup.userData[SexyGroup.GetPlayerID(unit)]
	userData.talentTree1 = first
	userData.talentTree2 = second
	userData.talentTree3 = third
	userData.specRole = specRole
	userData.scanned = time()
	
	table.wipe(userData.equipment)
	for itemType in pairs(SexyGroup.INVENTORY_TO_TYPE) do
		local inventoryID = GetInventorySlotInfo(itemType)
		userData.equipment[inventoryID] = SexyGroup:GetItemLink(GetInventoryItemLink(unit, inventoryID))
	end
	
	table.wipe(userData.achievements)
	for achievementID in pairs(SexyGroup.VALID_ACHIEVEMENTS) do
		local id, _, _, completed, _, _, _, _, flags = GetAchievementInfo(achievementID)
		if( flags == ACHIEVEMENT_FLAGS_STATISTIC ) then
			userData.achievements[id] = tonumber(GetStatistic(id)) or nil
		else
			userData.achievements[id] = completed and 1 or nil
		end
	end
	
	if showResults then
		SexyGroup.modules.Users:LoadData(userData)
	end
end
