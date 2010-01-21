local ElitistGroup = select(2, ...)
local Users = ElitistGroup:NewModule("Users", "AceEvent-3.0")
local L = ElitistGroup.L
local backdrop = {bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeSize = 1}
local gemData, enchantData, equipmentData, gemTooltips, enchantTooltips, achievementTooltips, tempList, managePlayerNote
local userList, achievementTooltips, experienceData, experienceDataMain = {}, {}, {}, {}
local MAX_DUNGEON_ROWS, MAX_NOTE_ROWS = 7, 7
local MAX_ACHIEVEMENT_ROWS = 20
local MAX_DATABASE_ROWS = 18
local DungeonData = ElitistGroup.Dungeons

function Users:OnInitialize()
	self:RegisterMessage("SG_DATA_UPDATED", function(event, type, user)
		if( not userList[user] ) then
			self.rebuildDatabase = true
		end
		
		local self = Users
		if( self.frame and self.frame:IsVisible() ) then
			if( self.activeUserID and self.activeUserID == user ) then
				self:BuildUI(ElitistGroup.userData[user], type)
			end
			
			self:UpdateDatabasePage()
		end
	end)
end

local function sortAchievements(a, b)
	local aName, _, _, _, _, _, _, aFlags = select(2, GetAchievementInfo(a))
	local bName, _, _, _, _, _, _, bFlags = select(2, GetAchievementInfo(b))
	local aEarned = Users.activeData.achievements[a] or 0
	local bEarned = Users.activeData.achievements[b] or 0
	local aStatistic = bit.band(aFlags, ACHIEVEMENT_FLAGS_STATISTIC) > 0
	local bStatistic = bit.band(bFlags, ACHIEVEMENT_FLAGS_STATISTIC) > 0
	
	if( not aStatistic and not bStatistic ) then
		return aEarned == bEarned and aName < bName or aEarned > bEarned
	elseif( not aStatistic ) then
		return true
	elseif( not bStatistic ) then
		return false
	end
	
	return aEarned > bEarned
end

function Users:Toggle(userData)
	local userID = string.format("%s-%s", userData.name, userData.server)
	if( self.activeUserID == userID and self.frame:IsVisible() ) then
		self.frame:Hide()
	else
		self:Show(userData)
	end
end

function Users:Show(userData)
	self.activeData = userData
	self.activeUserID = string.format("%s-%s", userData.name, userData.server)

	self:BuildUI(userData)
	self:UpdateDatabasePage()
end

function Users:BuildUI(userData, updateType)
	if( not userData ) then return end
	self:CreateUI()

	local frame = self.frame

	-- Build score as well as figure out their score
	if( not updateType or updateType == "gear" or updateType == "gems" ) then
		ElitistGroup:ReleaseTables(equipmentData, enchantData, gemData)
		if( not userData.pruned ) then
			equipmentData, enchantData, gemData = ElitistGroup:GetGearSummary(userData)
			enchantTooltips, gemTooltips = ElitistGroup:GetGearSummaryTooltip(userData.equipment, enchantData, gemData)
		
			frame.pruneInfo:Hide()
		
			for _, slot in pairs(frame.gearFrame.equipSlots) do
				if( slot.inventoryID and userData.equipment[slot.inventoryID] ) then
					local itemLink = userData.equipment[slot.inventoryID]
					local fullItemLink, itemQuality, itemLevel, _, _, _, _, itemEquipType, itemIcon = select(2, GetItemInfo(itemLink))
					if( itemQuality and itemLevel ) then
						local baseItemLink = ElitistGroup:GetBaseItemLink(itemLink)
					
						-- Now sum it all up
						slot.tooltip = nil
						slot.equippedItem = itemLink
						slot.gemTooltip = gemTooltips[itemLink]
						slot.enchantTooltip = enchantTooltips[itemLink]
						slot.isBadType = equipmentData[itemLink] and "|cffff2020[!]|r " or ""
						slot.itemTalentType = ElitistGroup.Items.itemRoleText[ElitistGroup.ITEM_TALENTTYPE[baseItemLink]] or ElitistGroup.ITEM_TALENTTYPE[baseItemLink]
						slot.fullItemLink = fullItemLink
						slot.icon:SetTexture(itemIcon)
						slot.typeText:SetText(slot.itemTalentType)
						slot:Enable()
						slot:Show()
					
						if( equipmentData[itemLink] ) then
							slot.typeText:SetTextColor(1, 0.15, 0.15)
						else
							slot.typeText:SetTextColor(1, 1, 1)
						end

						if( enchantData[fullItemLink] or gemData[fullItemLink] ) then
							slot.extraText:SetText(L["Enhancements"])
							slot.extraText:SetTextColor(1, 0.15, 0.15)
						else
							local color = ITEM_QUALITY_COLORS[itemQuality] or ITEM_QUALITY_COLORS[-1]
							slot.extraText:SetText(math.floor(ElitistGroup:CalculateScore(itemLink, itemQuality, itemLevel)))
							slot.extraText:SetTextColor(color.r, color.g, color.b)
						end
					else
						slot.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
						slot.extraText:SetText("")
						slot.typeText:SetText("")
						slot.fullItemLink = nil
						slot.equippedItem = nil
						slot.enchantTooltip = nil
						slot.gemTooltip = nil
						slot.tooltip = string.format(L["Cannot find item data for item id %s."], string.match(itemLink, "item:(%d+)"))
						slot:Disable()
						slot:Show()
					end
				elseif( slot.inventoryID ) then
					local texture = slot.emptyTexture
					if( slot.checkRelic and ( userData.classToken == "PALADIN" or userData.classToken == "DRUID" or userData.classToken == "SHAMAN" ) ) then
						texture = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Relic.blp"
					end
				
					slot.icon:SetTexture(texture)
					slot.extraText:SetText("")
					slot.typeText:SetText("")
					slot.tooltip = L["No item equipped"]
					slot.fullItemLink = nil
					slot.equippedItem = nil
					slot.enchantTooltip = nil
					slot.gemTooltip = nil
					slot:Disable()
					slot:Show()
				end
			end
		
			ElitistGroup:ReleaseTables(enchantTooltips, gemTooltips)
				
			-- Now combine these too, in the same way you combine to make a better and more powerful robot
			local equipSlot = frame.gearFrame.equipSlots[18]
			local scoreIcon = equipmentData.totalScore >= 240 and "INV_Shield_72" or equipmentData.totalScore >= 220 and "INV_Shield_61" or equipmentData.totalScore >= 200 and "INV_Shield_26" or "INV_Shield_36"
			equipSlot.text:SetFormattedText("%s%d|r", ElitistGroup:GetItemColor(equipmentData.totalScore), equipmentData.totalScore)
			equipSlot.icon:SetTexture("Interface\\Icons\\" .. scoreIcon)
			equipSlot.tooltip = L["Average item level of all the players equipped items, with modifiers for blue or lower quality items."]
			equipSlot:Show()
		else
			equipmentData, gemData, enchantData = nil, nil, nil
		
			for _, slot in pairs(frame.gearFrame.equipSlots) do slot:Hide() end
			frame.pruneInfo:Show()
		end

		self.activePlayerScore = equipmentData and equipmentData.totalScore or 0
	end

	-- Build the players info
	local coords = CLASS_BUTTONS[userData.classToken]
	if( coords ) then
		frame.userFrame.playerInfo:SetFormattedText("%s (%s)", userData.name, userData.level)
		frame.userFrame.playerInfo.tooltip = string.format(L["%s - %s, level %s %s."], userData.name, userData.server, userData.level, LOCALIZED_CLASS_NAMES_MALE[userData.classToken])
		frame.userFrame.playerInfo.icon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
		frame.userFrame.playerInfo.icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
	else
		frame.userFrame.playerInfo:SetFormattedText("%s (%s)", userData.name, userData.level)
		frame.userFrame.playerInfo.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
		frame.userFrame.playerInfo.icon:SetTexCoord(0, 1, 0, 1)
		frame.userFrame.playerInfo.tooltip = string.format(L["%s - %s, level %s, unknown class."], userData.name, userData.server, userData.level)
	end
	
	if( not userData.pruned and userData.talentTree1 and userData.talentTree2 and userData.talentTree3 ) then
		local specType, specName, specIcon = ElitistGroup:GetPlayerSpec(userData)
		specType = ElitistGroup.Talents.talentText[specType] or specType
		if( not userData.unspentPoints ) then
			frame.userFrame.talentInfo:SetFormattedText("%d/%d/%d (%s)", userData.talentTree1, userData.talentTree2, userData.talentTree3, specType)
			frame.userFrame.talentInfo.tooltip = string.format(L["%s, %s role."], specName, specType)
			frame.userFrame.talentInfo.icon:SetTexture(specIcon)
		else
			frame.userFrame.talentInfo:SetFormattedText(L["%d unspent |4point:points;"], userData.unspentPoints)
			frame.userFrame.talentInfo.tooltip = string.format(L["%s, %s role.\n\nThis player has not spent all of their talent points!"], specName, specType)
			frame.userFrame.talentInfo.icon:SetTexture(specIcon)
		end
	else
		frame.userFrame.talentInfo:SetText(L["Talents unavailable"])
		frame.userFrame.talentInfo.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
	end
		
	local scanAge = (time() - userData.scanned) / 60
	
	if( scanAge <= 2 ) then
		frame.userFrame.scannedInfo:SetText(L["<1 minute old"])
		frame.userFrame.scannedInfo.icon:SetTexture("Interface\\Icons\\INV_JewelCrafting_Gem_41")
	elseif( scanAge < 60 ) then
		frame.userFrame.scannedInfo:SetFormattedText(L["%d |4minute:minutes; old"], scanAge)
		frame.userFrame.scannedInfo.icon:SetTexture("Interface\\Icons\\INV_JewelCrafting_Gem_" .. (scanAge < 30 and 41 or 38))
	elseif( scanAge <= 1440 ) then
		frame.userFrame.scannedInfo:SetFormattedText(L["%d |4hour:hours; old"], scanAge / 60)
		frame.userFrame.scannedInfo.icon:SetTexture("Interface\\Icons\\INV_JewelCrafting_Gem_39")
	else
		frame.userFrame.scannedInfo:SetFormattedText(L["%d |4day:days; old"], scanAge / 1440)
		frame.userFrame.scannedInfo.icon:SetTexture("Interface\\Icons\\INV_JewelCrafting_Gem_37")
	end
	
	if( ElitistGroup:IsTrusted(userData.from) ) then
		frame.userFrame.trustedInfo:SetFormattedText(L["%s (Trusted)"], string.match(userData.from, "(.-)%-"))
		frame.userFrame.trustedInfo.tooltip = L["Data for this player is from a verified source and can be trusted."]
		frame.userFrame.trustedInfo.icon:SetTexture(READY_CHECK_READY_TEXTURE)
	else
		frame.userFrame.trustedInfo:SetFormattedText(L["%s (Untrusted)"], string.match(userData.from, "(.-)%-"))
		frame.userFrame.trustedInfo.tooltip = L["While the player data should be accurate, it is not guaranteed as the source is unverified."]
		frame.userFrame.trustedInfo.icon:SetTexture(READY_CHECK_NOT_READY_TEXTURE)
	end
	
	-- Build the necessary experience data based on the players achievements, this is fun!
	if( not userData.pruned and ( not updateType or updateType == "achievements" ) ) then
		tempList = ElitistGroup:GetTable()
		table.wipe(achievementTooltips)
		table.wipe(experienceData)
		table.wipe(experienceDataMain)

		for _, data in pairs(DungeonData.experience) do
			experienceData[data.id] = experienceData[data.id] or 0
			experienceDataMain[data.id] = experienceDataMain[data.id] or 0
				
			for id, points in pairs(data) do
				if( userData.achievements[id] ) then
					experienceData[data.id] = experienceData[data.id] + (userData.achievements[id] * points)
				end
				
				if( userData.mainAchievements and userData.mainAchievements[id] ) then
					experienceDataMain[data.id] = experienceDataMain[data.id] + (userData.mainAchievements[id] * points)
				end
			end
			
			-- Add the childs score to the parents
			if( not data.parent ) then
				experienceData[data.childOf] = (experienceData[data.childOf] or 0) + experienceData[data.id]
				experienceDataMain[data.childOf] = (experienceDataMain[data.childOf] or 0) + experienceDataMain[data.id]
			end
			
			-- Cascade the scores from this one to whatever it's supposed to
			if( data.cascade ) then
				experienceData[data.cascade] = (experienceData[data.cascade] or 0) + experienceData[data.id]
				experienceDataMain[data.cascade] = (experienceDataMain[data.cascade] or 0) + experienceDataMain[data.id]
			end
			
			-- Build the tooltip, caching it because it really does not need to be recalcualted that often
			table.wipe(tempList)
			for achievementID, points in pairs(data) do
				if( type(achievementID) == "number" and type(points) == "number" ) then
					table.insert(tempList, achievementID)
				end
			end
			
			table.sort(tempList, sortAchievements)
			
			achievementTooltips[data.id] = ""
			for i=1, #(tempList) do
				local achievementID = tempList[i]
				local name, _, _, _, _, _, _, flags = select(2, GetAchievementInfo(achievementID))
				name = string.trim(string.gsub(name, "%((.-)%)$", ""))
				
				local earned = userData.achievements[achievementID]
				local mainEarned = userData.mainAchievements and userData.mainAchievements[achievementID]
				if( mainEarned and userData.mainAchievements ) then
					if( bit.band(flags, ACHIEVEMENT_FLAGS_STATISTIC) > 0 ) then
						achievementTooltips[data.id] = achievementTooltips[data.id] .. "\n" .. string.format("|cffffffff[%d | %d]|r %s", mainEarned or 0, earned or 0, name)
					else
						achievementTooltips[data.id] = achievementTooltips[data.id] .. "\n" .. string.format("|cffffffff[%s | %s]|r %s", mainEarned == 1 and YES or NO, earned == 1 and YES or NO, name)
					end
				else
					if( bit.band(flags, ACHIEVEMENT_FLAGS_STATISTIC) > 0 ) then
						achievementTooltips[data.id] = achievementTooltips[data.id] .. "\n" .. string.format("|cffffffff[%d]|r %s", earned or 0, name)
					else
						achievementTooltips[data.id] = achievementTooltips[data.id] .. "\n" .. string.format("|cffffffff[%s]|r %s", earned == 1 and YES or NO, name)
					end
				end
			end
		end
		
		ElitistGroup:ReleaseTables(tempList)
	end
		
	-- Setup dungeon info
	-- Find where the players score lets them into at least
	local lockedScore
	if( not userData.pruned ) then
		for i=#(DungeonData.suggested), 1, -4 do
			local score = DungeonData.suggested[i - 2]
			if( lockedScore and lockedScore ~= score ) then
				self.forceOffset = math.ceil((i + 1) / 4)
				break
			elseif( self.activePlayerScore >= score ) then
				lockedScore = score
				self.forceOffset = math.ceil((i + 1) / 4)
			end
		end
	else
		self.forceOffset = 0
	end
	
	-- Build notes
	if( not updateType or updateType == "notes" ) then
		frame.userFrame.manageNote:SetText(self.activeData.notes[ElitistGroup.playerID] and L["Edit Note"] or L["Add Note"])
		if( ElitistGroup.playerID ~= self.activeUserID ) then
			frame.userFrame.manageNote.tooltip = L["You can edit or add a note on this player here."]
			frame.userFrame.manageNote:Enable()
		else
			frame.userFrame.manageNote.tooltip = L["You cannot set a note on yourself!"]
			frame.userFrame.manageNote:Disable()
		end
	
		self.activeDataNotes = 0
		for _ in pairs(userData.notes) do 
			self.activeDataNotes = self.activeDataNotes + 1
		end
	
		if( self.frame.manageNote and self.frame.manageNote:IsVisible() ) then
			managePlayerNote()
		end
	end

	-- General updates
	self:UpdateDungeonInfo()
	self:UpdateTabPage()
end

local function sortNames(a, b)
	if( UnitExists(userList[a]) == UnitExists(userList[b]) ) then
		return a < b
	elseif( UnitExists(userList[a]) ) then
		return true
	elseif( UnitExists(userList[b]) ) then
		return false
	end
end

-- Query builder for searching
local query
local function buildQuery(search)
	search = string.lower(search)
	
--local search = not self.frame.databaseFrame.search.searchText and string.gsub(string.lower(self.frame.databaseFrame.search:GetText() or ""), "%-", "%%-") or ""
	local class = string.match(search, L["c%-\"(.-)\""])
	local minRange, maxRange = string.match(search, "(%d+)%-(%d+)")
	local level = string.match(search, "(%d+)")
	local server = string.match(search, L["s%-\"(.-)\""])
	local name = string.match(search, L["n%-\"(.-)\""])
	
	-- Figure out class
	if( class and class ~= "" ) then
		for classToken, classLocale in pairs(LOCALIZED_CLASS_NAMES_MALE) do
			if( string.lower(classLocale) == class ) then
				query.classToken = classToken
				break
			end
		end

		for classToken, classLocale in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do
			if( string.lower(classLocale) == class ) then
				query.classToken = classToken
				break
			end
		end
	end
	
	-- Figure out level
	query.minLevel = tonumber(minRange) or tonumber(level) or -1
	query.maxLevel = tonumber(maxRange) or tonumber(level) or MAX_PLAYER_LEVEL
	
	-- Figure out server
	if( server and server ~= "" ) then
		query.server = server
	end
	
	-- Figure out just name
	if( name and name ~= "" ) then
		query.name = name
	end
	
	-- No name was set, strip everything else out and will use that as the name
	if( not query.name ) then
		search = string.gsub(search, ".%-\".-\"", "")
		search = string.gsub(search, ".%-\"", "")
		search = string.gsub(search, "%d+%-%d+", "")
		search = string.gsub(search, "%d+", "")
		search = string.trim(search)
		if( search ~= "" ) then
			local name, server = string.split("-", search, 2)
			query.name = name
			query.server = query.server or server ~= "" and server or nil
		end
	end
end

function Users:RebuildDatabaseTable()
	if( not self.rebuildDatabase ) then return end
	self.rebuildDatabase = nil
	
	for playerID, data in pairs(ElitistGroup.db.faction.users) do
		local user = userList[playerID]
		if( not user or not user.classToken or not user.level or not user.server or not user.name ) then
			local classToken, level, server, name
			-- Get the data first
			if( rawget(ElitistGroup.userData, playerID) ) then
				name, server, level, classToken = ElitistGroup.userData[playerID].name, ElitistGroup.userData[playerID].server, ElitistGroup.userData[playerID].level, ElitistGroup.userData[playerID].classToken
			elseif( data ~= "" ) then
				name, server, level, classToken = string.match(data, "name=\"(.-)\""), string.match(data, "server=\"(.-)\""), tonumber(string.match(data, "level=([0-9]+)")), string.match(data, "classToken=\"([A-Z]+)\"")
			end
			
			user = user or {}
			user.playerID = playerID
			user.classToken = classToken
			user.level = level
			user.name = name
			user.server = server
			
			if( not userList[playerID] ) then
				userList[playerID] = user
				table.insert(userList, playerID)
			end
		end
	end
end

function Users:UpdateDatabasePage()
	self = Users
	if( not ElitistGroup.db.profile.general.databaseExpanded ) then return end
	
	for _, row in pairs(self.frame.databaseFrame.rows) do row:Hide() end
	
	-- Don't need to recheck these during scroll
	if( not self.scrollUpdate ) then
		query = query or {}
		table.wipe(query)

		local useSearch = not self.frame.databaseFrame.search.searchText and self.frame.databaseFrame.search:GetText()
		useSearch = useSearch and useSearch ~= "" and useSearch or nil
		if( useSearch ) then
			buildQuery(useSearch)
		end
		
		self:RebuildDatabaseTable()
		self.frame.databaseFrame.visibleUsers = 0

		for i=1, #(userList) do
			local user = userList[userList[i]]
			user.visible = nil
			-- Search name
			if( not query.name or string.match(string.lower(user.name), query.name) ) then
				-- Search server
				if( not query.server or string.match(string.lower(user.server), query.server) ) then
					-- Search level
					if( not user.level or not query.minLevel or ( user.level >= query.minLevel and user.level <= query.maxLevel ) ) then
						-- Search class token
						if( not query.classToken or not user.classToken or user.classToken == query.classToken ) then
							user.visible = true
							self.frame.databaseFrame.visibleUsers = self.frame.databaseFrame.visibleUsers + 1
						end
					end
				end
			end
		end
		
		table.sort(userList, sortNames)
	end
	
	FauxScrollFrame_Update(self.frame.databaseFrame.scroll, self.frame.databaseFrame.visibleUsers, MAX_DATABASE_ROWS, 16)
	ElitistGroupDatabaseSearch:SetWidth(self.frame.databaseFrame.scroll:IsVisible() and 195 or 210)

	local offset = FauxScrollFrame_GetOffset(self.frame.databaseFrame.scroll)
	local rowWidth = self.frame.databaseFrame:GetWidth() - (self.frame.databaseFrame.scroll:IsVisible() and 40 or 24)
	
	local rowID, userID = 1, 1
	for id=1, #(userList) do
		local user = userList[userList[id]]
		if( userID > offset and user.visible ) then
			local row = self.frame.databaseFrame.rows[rowID]
			row.userID = user.playerID
			row.tooltip = string.format(L["View info on %s."], user.playerID)
			row:SetWidth(rowWidth)
			row:Show()
			
			local classHex, selected = "", ""
			local classColor = user.classToken and RAID_CLASS_COLORS[user.classToken]
			if( self.activeData and row.userID == self.activeUserID ) then
				selected = "[*] "
				classHex = "|cffffffff"
			elseif( classColor ) then
				classHex = string.format("|cff%02x%02x%02x", classColor.r * 255, classColor.g * 255, classColor.b * 255)
			end
			
			if( user.playerID ~= ElitistGroup.playerID and UnitExists(user.name) ) then
				row:SetFormattedText("%s|cffffffff[%s]|r %s%s|r", selected, GROUP, classHex, user.playerID)
			else
				row:SetFormattedText("%s%s%s|r", selected, classHex, user.playerID)
			end
			
			rowID = rowID + 1
			if( rowID > MAX_DATABASE_ROWS ) then break end
		end
		
		if( user.visible ) then
			userID = userID + 1
		end
	end
end

function Users:UpdateTabPage()
	self.frame.userTabFrame.notesButton:SetFormattedText(L["Notes (%d)"], self.activeDataNotes)
	if( self.activeData.pruned ) then
		self.frame.userTabFrame.selectedTab = "notes"
		self.frame.userTabFrame.notesButton:Enable()
		self.frame.userTabFrame.achievementsButton:Disable()
	elseif( self.activeDataNotes == 0 ) then
		self.frame.userTabFrame.selectedTab = "achievements"
		self.frame.userTabFrame.notesButton:Disable()
		self.frame.userTabFrame.achievementsButton:Enable()
	else
		self.frame.userTabFrame.notesButton:Enable()
		self.frame.userTabFrame.achievementsButton:Enable()
	end
	
	if( self.frame.userTabFrame.selectedTab == "notes" ) then
		self.frame.noteFrame:Show()
		self.frame.achievementFrame:Hide()

		self.frame.userTabFrame.notesButton:LockHighlight()
		self.frame.userTabFrame.achievementsButton:UnlockHighlight()
		
		self:UpdateNoteInfo()
	else
		self.frame.noteFrame:Hide()
		self.frame.achievementFrame:Show()

		self.frame.userTabFrame.notesButton:UnlockHighlight()
		self.frame.userTabFrame.achievementsButton:LockHighlight()

		self:UpdateAchievementInfo()
	end
end

function Users:UpdateAchievementInfo()
	local self = Users
	local totalEntries = self.activeData.mainAchievements and 1 or 0
	for id, data in pairs(DungeonData.experience) do
		experienceData[data.id] = experienceData[data.id] or 0
		if( not data.childOf or ( data.childOf and ElitistGroup.db.profile.expExpanded[data.childOf] and ( not DungeonData.experienceParents[data.childOf] or ElitistGroup.db.profile.expExpanded[DungeonData.experienceParents[data.childOf]] ) ) ) then
			totalEntries = totalEntries + 1
			data.isVisible = true
		else
			data.isVisible = nil
		end
	end
	
	FauxScrollFrame_Update(self.frame.achievementFrame.scroll, totalEntries, MAX_ACHIEVEMENT_ROWS, 18)
	
	for _, row in pairs(self.frame.achievementFrame.rows) do row.tooltip = nil; row.toggle:Hide(); row:Hide() end

	local rowID, rowOffset, id = 1, 0, 0
	local rowWidth = self.frame.achievementFrame:GetWidth() - (self.frame.achievementFrame.scroll:IsVisible() and 26 or 10)
	local offset = FauxScrollFrame_GetOffset(self.frame.achievementFrame.scroll)
	
	if( self.activeData.mainAchievements and offset == 0 ) then
		local row = self.frame.achievementFrame.rows[rowID]
		row.nameText:SetFormattedText(L["Mains experience on left, %s on right"], self.activeData.name)
		row.tooltip = row.nameText:GetText()
		row.expandedInfo = nil
		row:SetWidth(rowWidth - 4)
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", self.frame.achievementFrame, "TOPLEFT", 2, -2)
		row.toggle.id = nil
		row.toggle:Hide()
		row:Show()

		rowID = rowID + 1
	end
	
	for _, data in pairs(DungeonData.experience) do
		if( data.isVisible ) then
			id = id + 1
			if( id >= offset ) then
				local row = self.frame.achievementFrame.rows[rowID]

				-- Setup toggle button
				if( not data.childless and ( DungeonData.experienceParents[data.id] or data.parent ) ) then
					local type = not ElitistGroup.db.profile.expExpanded[data.id] and "Plus" or "Minus"
					row.toggle:SetNormalTexture("Interface\\Buttons\\UI-" .. type .. "Button-UP")
					row.toggle:SetPushedTexture("Interface\\Buttons\\UI-" .. type .. "Button-DOWN")
					row.toggle:SetHighlightTexture("Interface\\Buttons\\UI-" .. type .. "Button-Hilight", "ADD")
					row.toggle.id = data.id
					row.toggle:Show()
				else
					row.toggle.id = nil
					row.toggle:Hide()
				end

				local rowOffset = data.subParent and 20 or DungeonData.experienceParents[data.childOf] and 10 or data.childOf and 4 or 16
				
				local players = data.parent and data.players and string.format(L[" (%d-man)"], data.players) or ""
				-- Children categories without experience requirements should be shown in the experienceText so we don't get an off looking gap
				local heroicIcon = data.heroic and "|TInterface\\LFGFrame\\UI-LFG-ICON-HEROIC:16:13:-2:-2:32:32:0:16:0:20|t" or ""
				if( not data.experienced ) then
					row.nameText:SetFormattedText("%s%s%s", heroicIcon, data.name, players)
				-- Anything with an experience requirement obviously should show it
				elseif( data.experienced ) then
					local experienceText
					-- Not an alt, so do the simple display
					if( not self.activeData.mainAchievements ) then
						local percent = math.min(experienceData[data.id] / data.experienced, 1)
						local r = (percent > 0.5 and (1.0 - percent) * 2 or 1.0) * 255
						local g = (percent > 0.5 and 1.0 or percent * 2) * 255
						experienceText = percent >= 1 and L["Experienced"] or percent >= 0.8 and L["Nearly-experienced"] or percent >= 0.5 and L["Semi-experienced"] or L["Inexperienced"]
						
						if( data.childOf and not row.toggle:IsShown() ) then
							row.nameText:SetFormattedText("- [|cff%02x%02x00%d%%|r] %s%s", r, g, percent * 100, heroicIcon, data.name)
						else
							row.nameText:SetFormattedText("[|cff%02x%02x00%d%%|r] %s%s%s", r, g, percent * 100, heroicIcon, data.name, players)
						end
					-- An alt, fun times
					else
						-- Calculate the alts (the shown characters) experience
						local percentAlt = math.min(experienceData[data.id] / data.experienced, 1)
						local altR = (percentAlt > 0.5 and (1.0 - percentAlt) * 2 or 1.0) * 255
						local altG = (percentAlt > 0.5 and 1.0 or percentAlt * 2) * 255
						-- Now calculate the mains
						local percentMain = math.min(experienceDataMain[data.id] / data.experienced, 1)
						local mainR = (percentMain > 0.5 and (1.0 - percentMain) * 2 or 1.0) * 255
						local mainG = (percentMain > 0.5 and 1.0 or percentMain * 2) * 255

						local totalPercent = percentAlt + percentMain
						experienceText = totalPercent >= 1 and L["Experienced"] or totalPercent >= 0.8 and L["Nearly-experienced"] or totalPercent >= 0.5 and L["Semi-experienced"] or L["Inexperienced"]
						
						if( data.childOf and not row.toggle:IsShown() ) then
							row.nameText:SetFormattedText("- [|cff%02x%02x00%d%%|r | |cff%02x%02x00%d%%|r] %s%s", mainR, mainG, percentMain * 100, altR, altG, percentAlt * 100, heroicIcon, data.name)
						else
							row.nameText:SetFormattedText("[|cff%02x%02x00%d%%|r | |cff%02x%02x00%d%%|r] %s%s%s", mainR, mainG, percentMain * 100, altR, altG, percentAlt * 100, heroicIcon, data.name, players)
						end
					end
					
					row.tooltip = string.format(L["%s - %d-man %s (%s)"], experienceText, data.players, data.name, data.heroic and L["Heroic"] or L["Normal"])
					row.expandedInfo = achievementTooltips[data.id]
				end
				
				row:SetWidth(rowWidth - rowOffset)
				row:ClearAllPoints()
				row:SetPoint("TOPLEFT", self.frame.achievementFrame, "TOPLEFT", 4 + rowOffset, -3 - 17 * (rowID - 1))
				row:Show()
				
				rowID = rowID + 1
				if( rowID > MAX_ACHIEVEMENT_ROWS ) then break end
			end
		end
	end
end

function Users:UpdateNoteInfo()
	local self = Users
	FauxScrollFrame_Update(self.frame.noteFrame.scroll, self.activeDataNotes, MAX_NOTE_ROWS - 1, 48)
		
	for _, row in pairs(self.frame.noteFrame.rows) do row:Hide() end
	local rowWidth = self.frame.noteFrame:GetWidth() - (self.frame.noteFrame.scroll:IsVisible() and 24 or 10)
	
	local id, rowID = 1, 1
	local offset = FauxScrollFrame_GetOffset(self.frame.noteFrame.scroll)
	for from, note in pairs(self.activeData.notes) do
		if( id >= offset ) then
			local row = self.frame.noteFrame.rows[rowID]

			local percent = (note.rating - 1) / (ElitistGroup.MAX_RATING - 1)
			local r = (percent > 0.5 and (1.0 - percent) * 2 or 1.0) * 255
			local g = (percent > 0.5 and 1.0 or percent * 2) * 255
			local roles = ""
			if( bit.band(note.role, ElitistGroup.ROLE_HEALER) > 0 ) then roles = HEALER end
			if( bit.band(note.role, ElitistGroup.ROLE_TANK) > 0 ) then roles = roles .. ", " .. TANK end
			if( bit.band(note.role, ElitistGroup.ROLE_DAMAGE) > 0 ) then roles = roles .. ", " .. DAMAGE end
			roles = roles == "" and UNKNOWN or roles
			
			row.infoText:SetFormattedText("|cff%02x%02x00%d|r/|cff20ff20%s|r from %s", r, g, note.rating, ElitistGroup.MAX_RATING, string.match(from, "(.-)%-") or from)
			row.commentText:SetText(ElitistGroup:Decode(note.comment) or L["No comment"])
			row.tooltip = string.format(L["Seen as %s - %s:\n|cffffffff%s|r"], string.trim(string.gsub(roles, "^, ", "")), date("%m/%d/%Y", note.time), note.comment or L["No comment"])
			row:SetWidth(rowWidth)
			row:Show()
			
			rowID = rowID + 1
			if( rowID > MAX_NOTE_ROWS ) then break end
		end
		
		id = id + 1
	end
end

function Users:UpdateDungeonInfo()
	local self = Users
	local TOTAL_DUNGEONS = #(DungeonData.suggested) / 4

	FauxScrollFrame_Update(self.frame.dungeonFrame.scroll, TOTAL_DUNGEONS, MAX_DUNGEON_ROWS - 1, 28)
	if( self.forceOffset ) then
		self.forceOffset = math.min(self.forceOffset, TOTAL_DUNGEONS - MAX_DUNGEON_ROWS + 1)
		self.frame.dungeonFrame.scroll.offset = self.forceOffset
		self.frame.dungeonFrame.scroll.bar:SetValue(28 * self.forceOffset)
		self.forceOffset = nil
	end

	for _, row in pairs(self.frame.dungeonFrame.rows) do row:Hide() end
	
	local id, rowID = 1, 1
	local offset = FauxScrollFrame_GetOffset(self.frame.dungeonFrame.scroll)
	for dataID=1, #(DungeonData.suggested), 4 do
		if( id >= offset ) then
			local row = self.frame.dungeonFrame.rows[rowID]
			
			local name, score, players, type = DungeonData.suggested[dataID], DungeonData.suggested[dataID + 1], DungeonData.suggested[dataID + 2], DungeonData.suggested[dataID + 3]
			local levelDiff = score - self.activePlayerScore
			local percent = levelDiff <= 0 and 1 or levelDiff >= 30 and 0 or levelDiff <= 10 and 0.80 or levelDiff <= 20 and 0.50 or levelDiff <= 30 and 0.40
			local r = (percent > 0.5 and (1.0 - percent) * 2 or 1.0) * 255
			local g = (percent > 0.5 and 1.0 or percent * 2) * 255
			local heroicIcon = (type == "heroic" or type == "hard") and "|TInterface\\LFGFrame\\UI-LFG-ICON-HEROIC:16:13:-2:-1:32:32:0:16:0:20|t" or ""
			
			row.dungeonName:SetFormattedText("%s|cff%02x%02x00%s|r", heroicIcon, r, g, name)
			row.dungeonInfo:SetFormattedText(L["|cff%02x%02x00%d|r avg, %d-man (%s)"], r, g, score, players, DungeonData.types[type])
			row:Show()

			rowID = rowID + 1
			if( rowID > MAX_DUNGEON_ROWS ) then break end
		end
		
		id = id + 1
	end
end

managePlayerNote = function()
	local self = Users
	local frame = self.frame
	if( self.activeUserID == ElitistGroup.playerID ) then
		if( frame.manageNote ) then
			frame.manageNote:Hide()
		end
		frame.userFrame.manageNote:UnlockHighlight()
		return
	end
	
	local defaultRole = 0
	if( not frame.manageNote ) then
		local function getNote()
			if( not Users.activeData.notes[ElitistGroup.playerID] ) then
				Users.activeDataNotes = Users.activeDataNotes + 1
				Users.activeData.notes[ElitistGroup.playerID] = {rating = 3, role = defaultRole, time = time()}
			end
			
			ElitistGroup.writeQueue[Users.activeUserID] = true
			frame.manageNote.delete:Enable()
			return Users.activeData.notes[ElitistGroup.playerID]
		end
		
		local function UpdateComment(self)
			local text = self:GetText()
			if( text ~= self.lastText ) then
				self.lastText = text
				
				local playerNote = getNote()
				playerNote.comment = string.trim(text) ~= "" and text or nil
				Users:UpdateTabPage()
			end
		end
		
		local function UpdateRole(self)
			local playerNote = getNote()
			local isTank, isHealer, isDamage = bit.band(playerNote.role, ElitistGroup.ROLE_TANK) > 0, bit.band(playerNote.role, ElitistGroup.ROLE_HEALER) > 0, bit.band(playerNote.role, ElitistGroup.ROLE_DAMAGE) > 0
			if( self.roleID == ElitistGroup.ROLE_TANK ) then
				isTank = not isTank
			elseif( self.roleID == ElitistGroup.ROLE_HEALER ) then
				isHealer = not isHealer
			elseif( self.roleID == ElitistGroup.ROLE_DAMAGE ) then
				isDamage = not isDamage
			end
			
			playerNote.role = bit.bor(isTank and ElitistGroup.ROLE_TANK or 0, isHealer and ElitistGroup.ROLE_HEALER or 0, isDamage and ElitistGroup.ROLE_DAMAGE or 0)
			SetDesaturation(self:GetNormalTexture(), bit.band(playerNote.role, self.roleID) == 0)
			Users:UpdateTabPage()
		end
		
		local function UpdateRating(self)
			local playerNote = getNote()
			playerNote.rating = self:GetValue()
			Users:UpdateTabPage()
		end
		
		frame.manageNote = CreateFrame("Frame", nil, frame)
		frame.manageNote:SetFrameLevel(frame.dungeonFrame:GetFrameLevel() + 10)
		frame.manageNote:SetFrameStrata("MEDIUM")
		frame.manageNote:SetBackdrop(backdrop)
		frame.manageNote:SetBackdropBorderColor(0.60, 0.60, 0.60, 1)
		frame.manageNote:SetBackdropColor(0, 0, 0)
		frame.manageNote:SetHeight(252)
		frame.manageNote:SetWidth(175)
		frame.manageNote:SetPoint("TOPLEFT", frame.userFrame.manageNote, "BOTTOMLEFT", -3, -1)
		frame.manageNote:Hide()
		
		frame.manageNote.role = frame.manageNote:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		frame.manageNote.role:SetPoint("TOPLEFT", frame.manageNote, "TOPLEFT", 4, -14)
		frame.manageNote.role:SetText("Role")

		frame.manageNote.roleTank = CreateFrame("Button", nil, frame.manageNote)
		frame.manageNote.roleTank:SetSize(18, 18)
		frame.manageNote.roleTank:SetNormalTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
		frame.manageNote.roleTank:GetNormalTexture():SetTexCoord(0, 19/64, 22/64, 41/64)
		frame.manageNote.roleTank:SetPoint("LEFT", frame.manageNote.role, "RIGHT", 24, 0)
		frame.manageNote.roleTank:SetScript("OnClick", UpdateRole)
		frame.manageNote.roleTank.roleID = ElitistGroup.ROLE_TANK

		frame.manageNote.roleHealer = CreateFrame("Button", nil, frame.manageNote)
		frame.manageNote.roleHealer:SetSize(18, 18)
		frame.manageNote.roleHealer:SetNormalTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
		frame.manageNote.roleHealer:GetNormalTexture():SetTexCoord(20/64, 39/64, 1/64, 20/64)
		frame.manageNote.roleHealer:SetPoint("LEFT", frame.manageNote.roleTank, "RIGHT", 6, 0)
		frame.manageNote.roleHealer:SetScript("OnClick", UpdateRole)
		frame.manageNote.roleHealer.roleID = ElitistGroup.ROLE_HEALER

		frame.manageNote.roleDamage = CreateFrame("Button", nil, frame.manageNote)
		frame.manageNote.roleDamage:SetSize(18, 18)
		frame.manageNote.roleDamage:SetNormalTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
		frame.manageNote.roleDamage:GetNormalTexture():SetTexCoord(20/64, 39/64, 22/64, 41/64)
		frame.manageNote.roleDamage:SetPoint("LEFT", frame.manageNote.roleHealer, "RIGHT", 6, 0)
		frame.manageNote.roleDamage:SetScript("OnClick", UpdateRole)
		frame.manageNote.roleDamage.roleID = ElitistGroup.ROLE_DAMAGE

		frame.manageNote.rating = CreateFrame("Slider", nil, frame.manageNote)
		frame.manageNote.rating:SetBackdrop({bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
			edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
			tile = true, tileSize = 8, edgeSize = 8,
			insets = { left = 3, right = 3, top = 6, bottom = 6 }
		})

		frame.manageNote.rating:SetPoint("TOPLEFT", frame.manageNote.role, "BOTTOMLEFT", 1, -26)
		frame.manageNote.rating:SetHeight(15)
		frame.manageNote.rating:SetWidth(165)
		frame.manageNote.rating:SetOrientation("HORIZONTAL")
		frame.manageNote.rating:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
		frame.manageNote.rating:SetMinMaxValues(1, 5)
		frame.manageNote.rating:SetValue(3)
		frame.manageNote.rating:SetValueStep(1)
		frame.manageNote.rating:SetScript("OnValueChanged", UpdateRating)

		local rating = frame.manageNote:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		rating:SetPoint("BOTTOMLEFT", frame.manageNote.rating, "TOPLEFT", 0, 3)
		rating:SetPoint("BOTTOMRIGHT", frame.manageNote.rating, "TOPRIGHT", 0, 3)
		rating:SetText(L["Rating"])

		local min = frame.manageNote:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		min:SetText(L["Terrible"])
		min:SetPoint("TOPLEFT", frame.manageNote.rating, "BOTTOMLEFT", 0, -2)

		local max = frame.manageNote:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		max:SetText(L["Great"])
		max:SetPoint("TOPRIGHT", frame.manageNote.rating, "BOTTOMRIGHT", 0, -2)

		frame.manageNote.comment = CreateFrame("EditBox", "ElitistGroupUsersComment", frame.manageNote, "InputBoxTemplate")
		frame.manageNote.comment:SetHeight(18)
		frame.manageNote.comment:SetWidth(166)
		frame.manageNote.comment:SetAutoFocus(false)
		frame.manageNote.comment:SetPoint("TOPLEFT", frame.manageNote.rating, "BOTTOMLEFT", 2, -46)
		frame.manageNote.comment:SetScript("OnTextChanged", UpdateComment)
		frame.manageNote.comment:SetMaxLetters(256)

		local text = frame.manageNote:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		text:SetText(L["Comment"])
		text:SetPoint("BOTTOMLEFT", frame.manageNote.comment, "TOPLEFT", -4, 4)
		
		frame.manageNote.delete = CreateFrame("Button", nil, frame.manageNote, "UIPanelButtonGrayTemplate")
		frame.manageNote.delete:SetHeight(18)
		frame.manageNote.delete:SetWidth(140)
		frame.manageNote.delete:SetText(L["Delete your note"])
		frame.manageNote.delete:SetPoint("BOTTOMLEFT", frame.manageNote, "BOTTOMLEFT", 0, 1)
		frame.manageNote.delete:SetScript("OnClick", function(self)
			frame.userFrame.manageNote:UnlockHighlight()

			local parent = self:GetParent()
			parent.lastText = ""
			parent.comment:SetText("")
			parent.rating:SetValue(3)
			parent:Hide()

			SetDesaturation(parent.roleTank:GetNormalTexture(), true)
			SetDesaturation(parent.roleHealer:GetNormalTexture(), true)
			SetDesaturation(parent.roleDamage:GetNormalTexture(), true)

			ElitistGroup.userData[Users.activeUserID].notes[ElitistGroup.playerID] = nil
			ElitistGroup.writeQueue[Users.activeUserID] = true

			Users.activeDataNotes = Users.activeDataNotes - 1
			Users:UpdateTabPage()
			self:Disable()
		end)
	end
		
	-- Now setup what we got
	local note = self.activeData.notes[ElitistGroup.playerID]
	if( note ) then
		frame.manageNote.comment.lastText = note.comment or ""
		frame.manageNote.comment:SetText(note.comment or "")
		frame.manageNote.rating:SetValue(note.rating)
		frame.manageNote.delete:Enable()
	else
		frame.manageNote.comment.lastText = ""
		frame.manageNote.comment:SetText("")
		frame.manageNote.rating:SetValue(3)
		frame.manageNote.delete:Disable()
		
		if( not self.activeData.pruned ) then
			local specType = ElitistGroup:GetPlayerSpec(self.activeData)
			defaultRole = specType == "unknown" and 0 or specType == "healer" and ElitistGroup.ROLE_HEALER or ( specType == "feral-tank" or specType == "tank" ) and ElitistGroup.ROLE_TANK or ElitistGroup.ROLE_DAMAGE
		end
	end

	local role = note and note.role or defaultRole
	SetDesaturation(frame.manageNote.roleTank:GetNormalTexture(), bit.band(role, ElitistGroup.ROLE_TANK) == 0)
	SetDesaturation(frame.manageNote.roleHealer:GetNormalTexture(), bit.band(role, ElitistGroup.ROLE_HEALER) == 0)
	SetDesaturation(frame.manageNote.roleDamage:GetNormalTexture(), bit.band(role, ElitistGroup.ROLE_DAMAGE) == 0)
end

-- Really need to restructure all of this soon
function Users:CreateUI()
	if( Users.frame ) then
		Users.frame:Show()
		return
	end
	
	-- Initial database has to be built still
	self.rebuildDatabase = true
	

	local function OnAchievementEnter(self)
		if( self.tooltip ) then
			GameTooltip:SetOwner(self.toggle:IsVisible() and self.toggle or self, "ANCHOR_LEFT")
			GameTooltip:SetText(self.tooltip, nil, nil, nil, nil, true)
			GameTooltip:AddLine(self.expandedInfo)
			GameTooltip:Show()
		end
	end
	
	local function OnEnter(self)
		if( self.tooltip ) then
			GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
			GameTooltip:SetText(self.tooltip, nil, nil, nil, nil, not self.disableWrap)
			GameTooltip:Show()

		elseif( self.equippedItem ) then
			GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
			
			if( self.itemTalentType ) then
				GameTooltip:SetText(string.format(L["|cfffed000Item Type:|r %s%s"], self.isBadType, self.itemTalentType), 1, 1, 1)
			end
			if( self.enchantTooltip ) then
				GameTooltip:AddLine(self.enchantTooltip)
			end
			if( self.gemTooltip ) then
				GameTooltip:AddLine(self.gemTooltip)
			end
			
			GameTooltip:Show()
			
			-- Show the item as a second though
			ElitistGroup.tooltip:SetOwner(GameTooltip, "ANCHOR_NONE")
			ElitistGroup.tooltip:SetPoint("TOPLEFT", GameTooltip, "TOPRIGHT", 10, 0)
			ElitistGroup.tooltip:SetHyperlink(self.equippedItem)
			ElitistGroup.tooltip:Show()
		end
	end

	local function OnLeave(self)
		GameTooltip:Hide()
		ElitistGroup.tooltip:Hide()
	end
		
	-- Main container
	local frame = CreateFrame("Frame", "ElitistGroupUserInfo", UIParent)
	self.frame = frame
	frame:SetClampedToScreen(true)
	frame:SetWidth(675)
	frame:SetHeight(400)
	frame:RegisterForDrag("LeftButton", "RightButton")
	frame:EnableMouse(true)
	frame:SetToplevel(true)
	frame:SetMovable(true)
	frame:SetFrameLevel(5)
	frame:SetScript("OnDragStart", function(self, mouseButton)
		if( mouseButton == "RightButton" ) then
			frame:ClearAllPoints()
			frame:SetPoint("CENTER", UIParent, "CENTER", ElitistGroup.db.profile.general.databaseExpanded and -75 or 0, 0)
			ElitistGroup.db.profile.positions.user = nil
			return
		end
		
		self:StartMoving()
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		
		local scale = self:GetEffectiveScale()
		ElitistGroup.db.profile.positions.user = {x = self:GetLeft() * scale, y = self:GetTop() * scale}
	end)
	frame:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		edgeSize = 26,
		insets = {left = 9, right = 9, top = 9, bottom = 9},
	})
	frame:SetBackdropColor(0, 0, 0, 0.90)
	
	table.insert(UISpecialFrames, "ElitistGroupUserInfo")
	
	if( ElitistGroup.db.profile.positions.user ) then
		local scale = frame:GetEffectiveScale()
		frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", ElitistGroup.db.profile.positions.user.x / scale, ElitistGroup.db.profile.positions.user.y / scale)
	else
		frame:SetPoint("CENTER", UIParent, "CENTER", ElitistGroup.db.profile.general.databaseExpanded and -75 or 0, 0)
	end

	frame.titleBar = frame:CreateTexture(nil, "ARTWORK")
	frame.titleBar:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
	frame.titleBar:SetPoint("TOP", 0, 8)
	frame.titleBar:SetWidth(200)
	frame.titleBar:SetHeight(45)

	frame.title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	frame.title:SetPoint("TOP", 0, 0)
	frame.title:SetText("Elitist Group")

	-- Close button
	local button = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	button:SetPoint("TOPRIGHT", -3, -3)
	button:SetHeight(28)
	button:SetWidth(28)
	button:SetScript("OnClick", function() frame:Hide() end)
	
	-- Database frame
	frame.databaseFrame = CreateFrame("Frame", nil, frame)   
	frame.databaseFrame:SetHeight(frame:GetHeight() - 6)
	frame.databaseFrame:SetWidth(230)
	frame.databaseFrame:SetFrameLevel(2)
	frame.databaseFrame:SetBackdrop({
		  bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		  edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		  edgeSize = 20,
		  insets = {left = 6, right = 6, top = 6, bottom = 6},
	})
	frame.databaseFrame:SetBackdropColor(0, 0, 0, 0.9)
	frame.databaseFrame.fadeFrame = CreateFrame("Frame", nil, frame.databaseFrame)
	frame.databaseFrame.fadeFrame:SetAllPoints(frame.databaseFrame)
	frame.databaseFrame.fadeFrame:SetFrameLevel(3)

	if( ElitistGroup.db.profile.general.databaseExpanded ) then
		frame.databaseFrame:SetPoint("TOPLEFT", frame, "TOPRIGHT", -10, -3)
	else
		frame.databaseFrame:SetPoint("TOPLEFT", frame, "TOPRIGHT", -230, -3)
		frame.databaseFrame.fadeFrame:SetAlpha(0)
	end

	local TIME_TO_MOVE = 0.50
	local TIME_TO_FADE = 0.25
	
	frame.databaseFrame.timeElapsed = 0
	local function frameAnimator(self, elapsed)
		self.timeElapsed = self.timeElapsed + elapsed
		self:SetPoint("TOPLEFT", frame, "TOPRIGHT", self.startOffset + (self.endOffset * math.min((self.timeElapsed / TIME_TO_MOVE), 1)), -3)
		
		if( self.timeElapsed >= TIME_TO_MOVE ) then
			self.timeElapsed = 0
			self:SetScript("OnUpdate", nil)
		end
	end

	frame.databaseFrame.scroll = CreateFrame("ScrollFrame", "ElitistGroupUserFrameDatabase", frame.databaseFrame.fadeFrame, "FauxScrollFrameTemplate")
	frame.databaseFrame.scroll.bar = ElitistGroupUserFrameDatabase
	frame.databaseFrame.scroll:SetPoint("TOPLEFT", frame.databaseFrame, "TOPLEFT", 0, -7)
	frame.databaseFrame.scroll:SetPoint("BOTTOMRIGHT", frame.databaseFrame, "BOTTOMRIGHT", -28, 6)
	frame.databaseFrame.scroll:SetScript("OnVerticalScroll", function(self, value) Users.scrollUpdate = true; FauxScrollFrame_OnVerticalScroll(self, value, 14, Users.UpdateDatabasePage); Users.scrollUpdate = nil end)

	frame.databaseFrame.toggle = CreateFrame("Button", nil, frame.databaseFrame)
	frame.databaseFrame.toggle:SetPoint("LEFT", frame.databaseFrame, "RIGHT", -3, 0)
	frame.databaseFrame.toggle:SetFrameLevel(frame:GetFrameLevel() + 2)
	frame.databaseFrame.toggle:SetHeight(128)
	frame.databaseFrame.toggle:SetWidth(8)
	frame.databaseFrame.toggle:SetNormalTexture("Interface\\AddOns\\ElitistGroup\\media\\tabhandle")
	frame.databaseFrame.toggle:SetScript("OnEnter", function(self)
		SetCursor("INTERACT_CURSOR")
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
		GameTooltip:SetText(L["Click to open and close the database viewer."])
		GameTooltip:Show()
	end)
	frame.databaseFrame.toggle:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
		SetCursor(nil)
	end)
	frame.databaseFrame.toggle:SetScript("OnClick", function(self)
		if( ElitistGroup.db.profile.general.databaseExpanded ) then
			frame.databaseFrame.startOffset = -10
			frame.databaseFrame.endOffset = -220

			UIFrameFadeIn(frame.databaseFrame.fadeFrame, 0.25, 1, 0)
		else
			frame.databaseFrame.startOffset = -220
			frame.databaseFrame.endOffset = 210
			
			UIFrameFadeIn(frame.databaseFrame.fadeFrame, 0.50, 0, 1)
		end
		
		ElitistGroup.db.profile.general.databaseExpanded = not ElitistGroup.db.profile.general.databaseExpanded
		Users:UpdateDatabasePage()
		frame.databaseFrame:SetScript("OnUpdate", frameAnimator)
	end)

	frame.databaseFrame.search = CreateFrame("EditBox", "ElitistGroupDatabaseSearch", frame.databaseFrame.fadeFrame, "InputBoxTemplate")
	frame.databaseFrame.search:SetHeight(18)
	frame.databaseFrame.search:SetWidth(195)
	frame.databaseFrame.search:SetAutoFocus(false)
	frame.databaseFrame.search:ClearAllPoints()
	frame.databaseFrame.search:SetPoint("TOPLEFT", frame.databaseFrame, "TOPLEFT", 12, -7)
	frame.databaseFrame.search:SetFrameLevel(3)

	frame.databaseFrame.search.searchText = true
	frame.databaseFrame.search:SetText(L["Search..."])
	frame.databaseFrame.search:SetTextColor(0.90, 0.90, 0.90, 0.80)
	frame.databaseFrame.search:SetScript("OnTextChanged", function(self) Users:UpdateDatabasePage() end)
	frame.databaseFrame.search:SetScript("OnEditFocusGained", function(self)
		if( self.searchText ) then
			self.searchText = nil
			self:SetText("")
			self:SetTextColor(1, 1, 1, 1)
		end
	end)
	frame.databaseFrame.search:SetScript("OnEditFocusLost", function(self)
		if( not self.searchText and string.trim(self:GetText()) == "" ) then
			self.searchText = true
			self:SetText(L["Search..."])
			self:SetTextColor(0.90, 0.90, 0.90, 0.80)
		end
	end)

	local function viewUserData(self)
		Users:Show(ElitistGroup.userData[self.userID])
	end

	frame.databaseFrame.rows = {}
	for i=1, MAX_DATABASE_ROWS do
		local button = CreateFrame("Button", nil, frame.databaseFrame.fadeFrame)
		button:SetScript("OnClick", viewUserData)
		button:SetScript("OnEnter", OnEnter)
		button:SetScript("OnLeave", OnLeave)
		button:SetHeight(14)
		button:SetNormalFontObject(GameFontNormal)
		--button:SetHighlightFontObject(GameFontHighlight)
		button:SetText("*")
		button:GetFontString():SetPoint("TOPLEFT", button, "TOPLEFT")
		button:GetFontString():SetPoint("TOPRIGHT", button, "TOPRIGHT")
		button:GetFontString():SetJustifyH("LEFT")
		button:GetFontString():SetJustifyV("CENTER")
		
		if( i > 1 ) then
			button:SetPoint("TOPLEFT", frame.databaseFrame.rows[i - 1], "BOTTOMLEFT", 0, -6)
		else
			button:SetPoint("TOPLEFT", frame.databaseFrame, "TOPLEFT", 12, -30)
		end

		frame.databaseFrame.rows[i] = button
	end

	-- Equipment frame
	frame.gearFrame = CreateFrame("Frame", nil, frame)
	frame.gearFrame:SetBackdrop(backdrop)
	frame.gearFrame:SetBackdropBorderColor(0.60, 0.60, 0.60, 1)
	frame.gearFrame:SetBackdropColor(0, 0, 0, 0)
	frame.gearFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -30)
	frame.gearFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 15)
	frame.gearFrame:SetWidth(225)

	frame.gearFrame.headerText = frame.gearFrame:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
	frame.gearFrame.headerText:SetPoint("BOTTOMLEFT", frame.gearFrame, "TOPLEFT", 0, 5)
	frame.gearFrame.headerText:SetText(L["Equipped gear"])
	
	frame.pruneInfo = frame.gearFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	frame.pruneInfo:SetPoint("TOPLEFT", frame.gearFrame, "TOPLEFT", 4, -4)
	frame.pruneInfo:SetPoint("BOTTOMRIGHT", frame.gearFrame, "BOTTOMRIGHT", -4, 4)
	frame.pruneInfo:SetJustifyH("LEFT")
	frame.pruneInfo:SetJustifyV("TOP")
	frame.pruneInfo:SetText(L["Gear and achievement data for this player has been pruned to reduce database size.\nNotes and basic data have been kept, you can view gear and achievements again by inspecting the player.\n\n\nPruning settings can be changed through /elitistgroup."])

	local function OnItemClick(self)
		if( self.fullItemLink ) then
			HandleModifiedItemClick(self.fullItemLink)
		end
	end
		local inventoryMap = {"HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "WristSlot", "HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "Trinket0Slot", "Trinket1Slot", "MainHandSlot", "SecondaryHandSlot", "RangedSlot"}
	frame.gearFrame.equipSlots = {}
	for i=1, 18 do
		local slot = CreateFrame("Button", nil, frame.gearFrame)
		slot:SetHeight(30)
		slot:SetWidth(100)
		slot:SetScript("OnEnter", OnEnter)
		slot:SetScript("OnLeave", OnLeave)
		slot:SetScript("OnClick", OnItemClick)
		slot:SetMotionScriptsWhileDisabled(true)
		slot.icon = slot:CreateTexture(nil, "BACKGROUND")
		slot.icon:SetHeight(30)
		slot.icon:SetWidth(30)
		slot.icon:SetPoint("TOPLEFT", slot)

		if( i < 18 ) then
			slot.typeText = slot:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
			slot.typeText:SetPoint("TOPLEFT", slot.icon, "TOPRIGHT", 2, -1)
			slot.typeText:SetJustifyV("CENTER")
			slot.typeText:SetJustifyH("LEFT")
			slot.typeText:SetWidth(74)
			slot.typeText:SetHeight(11)

			slot.extraText = slot:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
			slot.extraText:SetPoint("BOTTOMLEFT", slot.icon, "BOTTOMRIGHT", 2, 2)
			slot.extraText:SetJustifyV("CENTER")
			slot.extraText:SetJustifyH("LEFT")
			slot.extraText:SetWidth(74)
			slot.extraText:SetHeight(11)
			slot.extraText:SetTextColor(0.90, 0.90, 0.90)
		else
			slot.text = slot:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
			slot.text:SetFont(GameFontHighlight:GetFont(), 16)
			slot.text:SetPoint("LEFT", slot.icon, "RIGHT", 2, 0)
			slot.text:SetWidth(72)
			slot.text:SetHeight(14)
			slot.text:SetJustifyV("CENTER")
			slot.text:SetJustifyH("LEFT")
		end
			
	   if( i == 10 ) then
		  slot:SetPoint("TOPLEFT", frame.gearFrame.equipSlots[1], "TOPRIGHT", 10, 0)    
	   elseif( i > 1 ) then
		  slot:SetPoint("TOPLEFT", frame.gearFrame.equipSlots[i - 1], "BOTTOMLEFT", 0, -9)
	   else
		  slot:SetPoint("TOPLEFT", frame.gearFrame, "TOPLEFT", 3, -8)
	   end

		if( inventoryMap[i] ) then
			slot.inventorySlot = inventoryMap[i]
			slot.inventoryType = ElitistGroup.Items.inventoryToID[inventoryMap[i]]
			slot.inventoryID, slot.emptyTexture, slot.checkRelic = GetInventorySlotInfo(inventoryMap[i])
		end
		
		frame.gearFrame.equipSlots[i] = slot
	end
		
	-- User data container
	frame.userFrame = CreateFrame("Frame", nil, frame)   
	frame.userFrame:SetBackdrop(backdrop)
	frame.userFrame:SetBackdropBorderColor(0.60, 0.60, 0.60, 1)
	frame.userFrame:SetBackdropColor(0, 0, 0, 0)
	frame.userFrame:SetWidth(175)
	frame.userFrame:SetHeight(97)
	frame.userFrame:SetPoint("TOPLEFT", frame.gearFrame, "TOPRIGHT", 10, -8)

	frame.userFrame.headerText = frame.userFrame:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
	frame.userFrame.headerText:SetPoint("BOTTOMLEFT", frame.userFrame, "TOPLEFT", 0, 5)
	frame.userFrame.headerText:SetText(L["Player info"])

	local buttonList = {"playerInfo", "talentInfo", "scannedInfo", "trustedInfo"}
	for i, key in pairs(buttonList) do
		local button = CreateFrame("Button", nil, frame.userFrame)
		button:SetNormalFontObject(GameFontHighlight)
		button:SetText("*")
		button:SetHeight(15)
		button:SetScript("OnEnter", OnEnter)
		button:SetScript("OnLeave", OnLeave)
		button:SetPushedTextOffset(0, 0)
		button.icon = button:CreateTexture(nil, "ARTWORK")
		button.icon:SetPoint("LEFT", button, "LEFT", 0, 0)
		button.icon:SetSize(16, 16)
		button:GetFontString():SetPoint("LEFT", button.icon, "RIGHT", 2, 0)
		button:GetFontString():SetJustifyH("LEFT")
		button:GetFontString():SetJustifyV("CENTER")
		button:GetFontString():SetWidth(frame.userFrame:GetWidth() - 23)
		button:GetFontString():SetHeight(15)
		
		if( i > 1 ) then
			button:SetPoint("TOPLEFT", frame.userFrame[buttonList[i - 1]], "BOTTOMLEFT", 0, -4)
			button:SetPoint("TOPRIGHT", frame.userFrame[buttonList[i - 1]], "BOTTOMRIGHT", 0, -4)
		else
			button:SetPoint("TOPLEFT", frame.userFrame, "TOPLEFT", 3, -4)
			button:SetPoint("TOPRIGHT", frame.userFrame, "TOPRIGHT", 0, 0)
		end
		
		frame.userFrame[key] = button
	end
	
	local button = CreateFrame("Button", nil, frame.userFrame, "UIPanelButtonGrayTemplate")
	button:SetHeight(15)
	button:SetWidth(100)
	button:SetPoint("TOPLEFT", frame.userFrame.trustedInfo, "BOTTOMLEFT", 0, -3)
	button:SetText(L["Edit Note"])
	button:SetScript("OnClick", function(self)
		managePlayerNote()
		
		if( frame.manageNote:IsVisible() ) then
			frame.manageNote:Hide()
			frame.userFrame.manageNote:UnlockHighlight()
		else
			frame.manageNote:Show()
			frame.userFrame.manageNote:LockHighlight()
		end
	end)
	button:SetScript("OnEnter", OnEnter)
	button:SetScript("OnLeave", OnLeave)
	button:SetMotionScriptsWhileDisabled(true)
	frame.userFrame.manageNote = button
	
	-- Dungeon suggested container
	frame.dungeonFrame = CreateFrame("Frame", nil, frame)   
	frame.dungeonFrame:SetBackdrop(backdrop)
	frame.dungeonFrame:SetBackdropBorderColor(0.60, 0.60, 0.60, 1)
	frame.dungeonFrame:SetBackdropColor(0, 0, 0, 0)
	frame.dungeonFrame:SetWidth(175)
	frame.dungeonFrame:SetHeight(226)
	frame.dungeonFrame:SetPoint("TOPLEFT", frame.userFrame, "BOTTOMLEFT", 0, -24)
	frame.dungeonFrame:SetScript("OnShow", function(self)
		local parent = self:GetParent()
		if( parent.manageNote ) then
			parent.manageNote:SetFrameLevel(self:GetFrameLevel() + 10)
		end
	end)

	frame.dungeonFrame.headerText = frame.dungeonFrame:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
	frame.dungeonFrame.headerText:SetPoint("BOTTOMLEFT", frame.dungeonFrame, "TOPLEFT", 0, 5)
	frame.dungeonFrame.headerText:SetText(L["Suggested dungeons"])

	frame.dungeonFrame.scroll = CreateFrame("ScrollFrame", "ElitistGroupUserFrameDungeon", frame.dungeonFrame, "FauxScrollFrameTemplate")
	frame.dungeonFrame.scroll.bar = ElitistGroupUserFrameDungeonScrollBar
	frame.dungeonFrame.scroll:SetPoint("TOPLEFT", frame.dungeonFrame, "TOPLEFT", 0, -2)
	frame.dungeonFrame.scroll:SetPoint("BOTTOMRIGHT", frame.dungeonFrame, "BOTTOMRIGHT", -24, 1)
	frame.dungeonFrame.scroll:SetScript("OnVerticalScroll", function(self, value) FauxScrollFrame_OnVerticalScroll(self, value, 28, Users.UpdateDungeonInfo) end)

	frame.dungeonFrame.rows = {}
	for i=1, MAX_DUNGEON_ROWS do
		local button = CreateFrame("Frame", nil, frame.dungeonFrame)
		button:SetHeight(28)
		button:SetWidth(frame.dungeonFrame:GetWidth() - 25)
		button.dungeonName = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		button.dungeonName:SetHeight(14)
		button.dungeonName:SetJustifyH("LEFT")
		button.dungeonName:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
		button.dungeonName:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)

		button.dungeonInfo = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		button.dungeonInfo:SetHeight(14)
		button.dungeonInfo:SetJustifyH("LEFT")
		button.dungeonInfo:SetPoint("TOPLEFT", button.dungeonName, "BOTTOMLEFT", 0, 2)
		button.dungeonInfo:SetPoint("TOPRIGHT", button.dungeonName, "BOTTOMRIGHT", 0, 2)

		if( i > 1 ) then
			button:SetPoint("TOPLEFT", frame.dungeonFrame.rows[i - 1], "BOTTOMLEFT", 0, -5)
		else
			button:SetPoint("TOPLEFT", frame.dungeonFrame, "TOPLEFT", 3, -2)
		end

		frame.dungeonFrame.rows[i] = button
	end
	
	-- Parent container
	frame.userTabFrame = CreateFrame("Frame", nil, frame)   
	frame.userTabFrame:SetBackdrop(backdrop)
	frame.userTabFrame:SetBackdropBorderColor(0.60, 0.60, 0.60, 1)
	frame.userTabFrame:SetBackdropColor(0, 0, 0, 0)
	frame.userTabFrame:SetWidth(235)
	frame.userTabFrame:SetHeight(347)
	frame.userTabFrame:SetPoint("TOPLEFT", frame.userFrame, "TOPRIGHT", 10, 0)
	
	frame.userTabFrame.selectedTab = "notes"
	local function tabClicked(self)
		frame.userTabFrame.selectedTab = self.tabID
		Users:UpdateTabPage()
	end
	
	frame.userTabFrame.notesButton = CreateFrame("Button", nil, frame.userTabFrame)
	frame.userTabFrame.notesButton:SetNormalFontObject(GameFontNormal)
	frame.userTabFrame.notesButton:SetHighlightFontObject(GameFontHighlight)
	frame.userTabFrame.notesButton:SetDisabledFontObject(GameFontDisable)
	frame.userTabFrame.notesButton:SetPoint("BOTTOMLEFT", frame.userTabFrame, "TOPLEFT", 0, -1)
	frame.userTabFrame.notesButton:SetScript("OnClick", tabClicked)
	frame.userTabFrame.notesButton:SetText("*")
	frame.userTabFrame.notesButton:GetFontString():SetPoint("LEFT", 3, 0)
	frame.userTabFrame.notesButton:SetHeight(22)
	frame.userTabFrame.notesButton:SetWidth(90)
	frame.userTabFrame.notesButton:SetBackdrop(backdrop)
	frame.userTabFrame.notesButton:SetBackdropColor(0, 0, 0, 0)
	frame.userTabFrame.notesButton:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
	frame.userTabFrame.notesButton.tabID = "notes"
	
	frame.userTabFrame.achievementsButton = CreateFrame("Button", nil, frame.userTabFrame)
	frame.userTabFrame.achievementsButton:SetNormalFontObject(GameFontNormal)
	frame.userTabFrame.achievementsButton:SetHighlightFontObject(GameFontHighlight)
	frame.userTabFrame.achievementsButton:SetDisabledFontObject(GameFontDisable)
	frame.userTabFrame.achievementsButton:SetPoint("TOPLEFT", frame.userTabFrame.notesButton, "TOPRIGHT", 4, 0)
	frame.userTabFrame.achievementsButton:SetScript("OnClick", tabClicked)
	frame.userTabFrame.achievementsButton:SetText(L["Experience"])
	frame.userTabFrame.achievementsButton:GetFontString():SetPoint("LEFT", 3, 0)
	frame.userTabFrame.achievementsButton:SetHeight(22)
	frame.userTabFrame.achievementsButton:SetWidth(90)
	frame.userTabFrame.achievementsButton:SetBackdrop(backdrop)
	frame.userTabFrame.achievementsButton:SetBackdropColor(0, 0, 0, 0)
	frame.userTabFrame.achievementsButton:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
	frame.userTabFrame.achievementsButton.tabID = "achievements"

	-- Achievement container
	frame.achievementFrame = CreateFrame("Frame", nil, frame.userTabFrame)   
	frame.achievementFrame:SetAllPoints(frame.userTabFrame)

	frame.achievementFrame.scroll = CreateFrame("ScrollFrame", "ElitistGroupUserFrameAchievements", frame.achievementFrame, "FauxScrollFrameTemplate")
	frame.achievementFrame.scroll.bar = ElitistGroupUserFrameAchievementsScrollBar
	frame.achievementFrame.scroll:SetPoint("TOPLEFT", frame.achievementFrame, "TOPLEFT", 0, -2)
	frame.achievementFrame.scroll:SetPoint("BOTTOMRIGHT", frame.achievementFrame, "BOTTOMRIGHT", -24, 1)
	frame.achievementFrame.scroll:SetScript("OnVerticalScroll", function(self, value) FauxScrollFrame_OnVerticalScroll(self, value, 14, Users.UpdateAchievementInfo) end)

	local function toggleCategory(self)
		local id = self.toggle and self.toggle.id or self.id
		if( not id ) then return end
		
		ElitistGroup.db.profile.expExpanded[id] = not ElitistGroup.db.profile.expExpanded[id]
		Users:UpdateAchievementInfo()
	end
	
	frame.achievementFrame.rows = {}
	for i=1, MAX_ACHIEVEMENT_ROWS do
		local button = CreateFrame("Button", nil, frame.achievementFrame)
		button:SetScript("OnEnter", OnAchievementEnter)
		button:SetScript("OnLeave", OnLeave)
		button:SetScript("OnClick", toggleCategory)
		button:SetHeight(14)
		button.nameText = button:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		button.nameText:SetHeight(14)
		button.nameText:SetJustifyH("LEFT")
		button.nameText:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
		button.nameText:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)

		button.toggle = CreateFrame("Button", nil, button)
		button.toggle:SetScript("OnClick", toggleCategory)
		button.toggle:SetPoint("TOPRIGHT", button, "TOPLEFT", -2, 0)
		button.toggle:SetHeight(14)
		button.toggle:SetWidth(14)

		frame.achievementFrame.rows[i] = button
	end

	-- Notes container
	frame.noteFrame = CreateFrame("Frame", nil, frame.userTabFrame)   
	frame.noteFrame:SetAllPoints(frame.userTabFrame)
	
	frame.noteFrame.scroll = CreateFrame("ScrollFrame", "ElitistGroupUserFrameNotes", frame.noteFrame, "FauxScrollFrameTemplate")
	frame.noteFrame.scroll.bar = ElitistGroupUserFrameNotesScrollBar
	frame.noteFrame.scroll:SetPoint("TOPLEFT", frame.noteFrame, "TOPLEFT", 0, -2)
	frame.noteFrame.scroll:SetPoint("BOTTOMRIGHT", frame.noteFrame, "BOTTOMRIGHT", -24, 1)
	frame.noteFrame.scroll:SetScript("OnVerticalScroll", function(self, value) FauxScrollFrame_OnVerticalScroll(self, value, 46, Users.UpdateNoteInfo) end)

	frame.noteFrame.rows = {}
	for i=1, MAX_NOTE_ROWS do
		local button = CreateFrame("Frame", nil, frame.noteFrame)
		button:SetScript("OnEnter", OnEnter)
		button:SetScript("OnLeave", OnLeave)
		button:EnableMouse(true)
		button:SetHeight(46)
		button:SetWidth(frame.noteFrame:GetWidth() - 24)
		button.infoText = button:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		button.infoText:SetHeight(16)
		button.infoText:SetJustifyH("LEFT")
		button.infoText:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
		button.infoText:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)

		button.commentText = button:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		button.commentText:SetHeight(32)
		button.commentText:SetJustifyH("LEFT")
		button.commentText:SetJustifyV("TOP")
		button.commentText:SetPoint("TOPLEFT", button.infoText, "BOTTOMLEFT", 0, 0)
		button.commentText:SetPoint("TOPRIGHT", button.infoText, "BOTTOMRIGHT", 0, 0)

		if( i > 1 ) then
			button:SetPoint("TOPLEFT", frame.noteFrame.rows[i - 1], "BOTTOMLEFT", 0, -4)
		else
			button:SetPoint("TOPLEFT", frame.noteFrame, "TOPLEFT", 4, -2)
		end
		frame.noteFrame.rows[i] = button
	end
end

