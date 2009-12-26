local SexyGroup = select(2, ...)
local Scan = SexyGroup:NewModule("Scan", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("SexyGroup")

function Scan:CreateCoreTable(unit)
	local name, server = UnitName(unit)
	server = server and server ~= "" and server or GetRealmName()

	local playerID = string.format("%s-%s", name, server)
	local classToken = select(2, UnitClass(unit))
	local level = UnitLevel(unit)
	
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
			for talentID=1, GetNumTalents(tabIndex) do
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

function Scan:UpdatePlayerData()
	self:CreateCoreTable("player")

	local first, second, third, specRole = self:GetTalentData(select(2, UnitClass("player")))
	local userData = SexyGroup.userData[SexyGroup.playerName]
	userData.talentTree1 = first
	userData.talentTree2 = second
	userData.talentTree3 = third
	userData.specRole = specRole
	userData.scanned = time()
	
	table.wipe(userData.equipment)
	for itemType in pairs(SexyGroup.INVENTORY_TO_TYPE) do
		local inventoryID = GetInventorySlotInfo(itemType)
		userData.equipment[inventoryID] = SexyGroup:GetItemLink(GetInventoryItemLink("player", inventoryID))
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
end
