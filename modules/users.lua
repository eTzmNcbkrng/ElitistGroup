local SimpleGroup = select(2, ...)
local Users = SimpleGroup:NewModule("Users", "AceEvent-3.0")
local L = SimpleGroup.L

local MAX_DUNGEON_ROWS, MAX_NOTE_ROWS = 7, 7
local MAX_ACHIEVEMENT_ROWS = 20
local MAX_DATABASE_ROWS = 18
local backdrop = {bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeSize = 1}
local gemData, enchantData, equipmentData, gemTooltips, enchantTooltips

function Users:OnInitialize()
	self:RegisterMessage("SG_DATA_UPDATED", function(event, type, user)
		local self = Users
		if( self.activeUserID and user == self.activeUserID and self.frame and self.frame:IsVisible() ) then
			self:LoadData(SimpleGroup.userData[user])
		end
	end)
end

function Users:LoadData(userData)
	if( not userData ) then return end
	
	self:CreateUI()
	local frame = self.frame

	self.activeData = userData
	self.activeUserID = string.format("%s-%s", userData.name, userData.server)

	-- Build score as well as figure out their score
	SimpleGroup:DeleteTables(equipmentData, enchantData, gemData, gemTooltips, enchantTooltips)

	if( not userData.pruned ) then
		equipmentData, enchantData, gemData = SimpleGroup:GetGearSummary(userData)
		enchantTooltips, gemTooltips = SimpleGroup:GetGearSummaryTooltip(userData.equipment, enchantData, gemData)
		
		frame.pruneInfo:Hide()
		
		for _, slot in pairs(frame.gearFrame.equipSlots) do
			if( slot.inventoryID and userData.equipment[slot.inventoryID] ) then
				local itemLink = userData.equipment[slot.inventoryID]
				local fullItemLink, itemQuality, itemLevel, _, _, _, _, itemEquipType, itemIcon = select(2, GetItemInfo(itemLink))
				if( itemQuality and itemLevel ) then
					local baseItemLink = SimpleGroup:GetBaseItemLink(itemLink)
					
					-- Now sum it all up
					slot.tooltip = nil
					slot.equippedItem = itemLink
					slot.gemTooltip = gemTooltips[itemLink]
					slot.enchantTooltip = enchantTooltips[itemLink]
					slot.itemTalentType = SimpleGroup.TALENT_TYPES[SimpleGroup.ITEM_TALENTTYPE[baseItemLink]] or SimpleGroup.ITEM_TALENTTYPE[baseItemLink]
					slot.icon:SetTexture(itemIcon)
					slot.typeText:SetText(slot.itemTalentType)
					slot.typeText.icon:SetTexture(not equipmentData[itemLink] and READY_CHECK_READY_TEXTURE or READY_CHECK_NOT_READY_TEXTURE)
					slot:Enable()
					slot:Show()

					if( enchantData[fullItemLink] or gemData[fullItemLink] ) then
						slot.typeText.icon:ClearAllPoints()
						slot.typeText.icon:SetPoint("TOPLEFT", slot.icon, "TOPRIGHT", -1, 0)

						slot.extraText:SetText(L["Enhancements"])
						slot.extraText.icon:SetTexture(READY_CHECK_NOT_READY_TEXTURE)
						slot.extraText.icon:Show()
						slot.extraText:Show()
					else
						slot.typeText.icon:ClearAllPoints()
						slot.typeText.icon:SetPoint("LEFT", slot.icon, "RIGHT", -1, 0)
						slot.extraText:Hide()
						slot.extraText.icon:Hide()
					end
				else
					slot.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
					slot.extraText:SetText("")
					slot.extraText.icon:SetTexture(nil)
					slot.typeText:SetText("")
					slot.typeText.icon:SetTexture(nil)
					slot.equippedItem = nil
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
				slot.extraText.icon:SetTexture(nil)
				slot.typeText:SetText("")
				slot.typeText.icon:SetTexture(nil)
				slot.tooltip = L["No item equipped"]
				slot:Disable()
				slot:Show()
			end
		end
				
		-- Now combine these too, in the same way you combine to make a better and more powerful robot
		local equipSlot = frame.gearFrame.equipSlots[18]
		local scoreIcon = equipmentData.totalScore >= 240 and "INV_Shield_72" or equipmentData.totalScore >= 220 and "INV_Shield_61" or equipmentData.totalScore >= 200 and "INV_Shield_26" or "INV_Shield_36"
		local quality = equipmentData.totalScore >= 210 and ITEM_QUALITY_EPIC or equipmentData.totalScore >= 195 and ITEM_QUALITY_RARE or equipmentData.totalScore >= 170 and ITEM_QUALITY_UNCOMMON or ITEM_QUALITY_COMMON
		
		equipSlot.text:SetFormattedText(L["%s%d|r score"], ITEM_QUALITY_COLORS[quality].hex, equipmentData.totalScore)
		equipSlot.icon:SetTexture("Interface\\Icons\\" .. scoreIcon)
		equipSlot.tooltip = L["Score is the average item level of all the players equipped items."]
		equipSlot:Show()
	else
		equipmentData, gemData, enchantData, gemTooltips, enchantTooltips = nil, nil, nil, nil, nil
		
		for _, slot in pairs(frame.gearFrame.equipSlots) do slot:Hide() end
		frame.pruneInfo:Show()
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
		frame.userFrame.playerInfo.tooltip = string.format(L["%s - %s, level %s, unknown class."], userData.name, userData.server, userData.level)
	end
	
	self.activePlayerScore = equipmentData and equipmentData.totalScore or 0
	if( not userData.pruned ) then
		local specType, specName, specIcon = SimpleGroup:GetPlayerSpec(userData)
		if( not userData.unspentPoints ) then
			frame.userFrame.talentInfo:SetFormattedText("%d/%d/%d (%s)", userData.talentTree1, userData.talentTree2, userData.talentTree3, specName)
			frame.userFrame.talentInfo.tooltip = string.format(L["%s, %s role."], specName, SimpleGroup.TALENT_ROLES[specType])
			frame.userFrame.talentInfo.icon:SetTexture(specIcon)
		else
			frame.userFrame.talentInfo:SetFormattedText("%d %s", userData.unspentPoints, L["unspent points"])
			frame.userFrame.talentInfo.tooltip = string.format(L["%s, %s role.\n\nThis player has not spent all of their talent points!"], specName, SimpleGroup.TALENT_ROLES[specType])
			frame.userFrame.talentInfo.icon:SetTexture(specIcon)
		end
	else
		frame.userFrame.talentInfo:SetText(L["Talents unavailable"])
		frame.userFrame.talentInfo.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
	end
		
	local scanAge = (time() - userData.scanned) / 60
	
	if( scanAge <= 5 ) then
		frame.userFrame.scannedInfo:SetText(L["Just now"])
		frame.userFrame.scannedInfo.icon:SetTexture("Interface\\Icons\\INV_JewelCrafting_Gem_41")
	elseif( scanAge < 60 ) then
		frame.userFrame.scannedInfo:SetFormattedText(L["%d minutes old"], scanAge)
		frame.userFrame.scannedInfo.icon:SetTexture("Interface\\Icons\\INV_JewelCrafting_Gem_" .. (scanAge < 30 and 41 or 38))
	elseif( scanAge <= 1440 ) then
		frame.userFrame.scannedInfo:SetFormattedText(L["%d hours old"], scanAge / 60)
		frame.userFrame.scannedInfo.icon:SetTexture("Interface\\Icons\\INV_JewelCrafting_Gem_39")
	else
		frame.userFrame.scannedInfo:SetFormattedText(L["%d days old"], scanAge / 1440)
		frame.userFrame.scannedInfo.icon:SetTexture("Interface\\Icons\\INV_JewelCrafting_Gem_37")
	end
	
	if( userData.trusted ) then
		frame.userFrame.trustedInfo:SetFormattedText(L["%s (Trusted)"], string.match(userData.from, "(.-)%-"))
		frame.userFrame.trustedInfo.tooltip = L["Data for this player is from a verified source and can be trusted."]
		frame.userFrame.trustedInfo.icon:SetTexture(READY_CHECK_READY_TEXTURE)
	else
		frame.userFrame.trustedInfo:SetFormattedText(L["%s (Untrusted)"], string.match(userData.from, "(.-)%-"))
		frame.userFrame.trustedInfo.tooltip = L["While the player data should be accurate, it is not guaranteed as the source is unverified."]
		frame.userFrame.trustedInfo.icon:SetTexture(READY_CHECK_NOT_READY_TEXTURE)
	end
	
	-- Build the necessary experience data based on the players achievements, this is fun!
	self.experienceData = {}
	for _, data in pairs(SimpleGroup.EXPERIENCE_POINTS) do
		self.experienceData[data.id] = self.experienceData[data.id] or 0
				
		for id, points in pairs(data) do
			if( type(id) == "number" and userData.achievements[id] ) then
				self.experienceData[data.id] = self.experienceData[data.id] + (points * userData.achievements[id])
			end
		end
		
		-- Add the childs score to the parents
		if( not data.parent ) then
			self.experienceData[data.childOf] = (self.experienceData[data.childOf] or 0) + self.experienceData[data.id]
		end
		
		-- Cascade the scores from this one to whatever it's supposed to
		if( data.cascade ) then
			self.experienceData[data.cascade] = (self.experienceData[data.cascade] or 0) + self.experienceData[data.id]
		end
	end
	
	-- Setup dungeon info
	-- Find where the players score lets them into at least
	local lockedScore
	if( equipmentData ) then
		for i=#(SimpleGroup.DUNGEON_DATA), 1, -4 do
			local score = SimpleGroup.DUNGEON_DATA[i - 2]
			if( lockedScore and lockedScore ~= score ) then
				self.forceOffset = math.ceil((i + 1) / 4)
				break
			elseif( equipmentData.totalScore >= score ) then
				lockedScore = score
				self.forceOffset = math.ceil((i + 1) / 4)
			end
		end
	end
	
	self.activeDataNotes = 0
	for _ in pairs(userData.notes) do 
		self.activeDataNotes = self.activeDataNotes + 1
		break
	end

	self:UpdateDatabasePage()
	self:UpdateDungeonInfo()
	self:UpdateTabPage()
end

local userList = {}
function Users:UpdateDatabasePage()
	self = Users
	for _, row in pairs(self.frame.databaseFrame.rows) do row:Hide() end
	
	if( not self.scrollUpdate ) then
		local search = not self.frame.databaseFrame.search.searchText and string.gsub(string.lower(self.frame.databaseFrame.search:GetText() or ""), "%-", "%%-") or ""
	
		table.wipe(userList)
		for name in pairs(SimpleGroup.db.faction.users) do
			if( search == "" or string.match(string.lower(name), search) ) then
				table.insert(userList, name)
			end
		end
		
		table.sort(userList, sortNames)
	end
	
	FauxScrollFrame_Update(self.frame.databaseFrame.scroll, #(userList), MAX_DATABASE_ROWS, 16)
	local offset = FauxScrollFrame_GetOffset(self.frame.databaseFrame.scroll)
	local rowWidth = self.frame.databaseFrame:GetWidth() - (self.frame.databaseFrame.scroll:IsVisible() and 40 or 10)
	
	local rowID = 1
	for id=1, #(userList) do
		if( id > offset ) then
			local row = self.frame.databaseFrame.rows[rowID]
			row.userID = userList[id]
			row:SetText(userList[id])
			row:SetWidth(rowWidth)
			row:Show()
			
			if( self.activeData and row.userID == self.activeUserID ) then
				row:LockHighlight()
			else
				row:UnlockHighlight()
			end
			
			rowID = rowID + 1
			if( rowID > MAX_DATABASE_ROWS ) then break end
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
	local totalEntries = 0
	for id, data in pairs(SimpleGroup.EXPERIENCE_POINTS) do
		if( not data.childOf or ( data.childOf and SimpleGroup.db.profile.expExpanded[data.childOf] and ( data.tier or SimpleGroup.db.profile.expExpanded[SimpleGroup.CHILD_PARENTS[data.childOf]] ) ) ) then
			totalEntries = totalEntries + 1
		end
	end
	
	FauxScrollFrame_Update(self.frame.achievementFrame.scroll, totalEntries, MAX_ACHIEVEMENT_ROWS, 18)
	
	for _, row in pairs(self.frame.achievementFrame.rows) do row.tooltip = nil; row.toggle:Hide(); row:Hide() end

	local rowID, rowOffset, id = 1, 0, 0
	local rowWidth = self.frame.achievementFrame:GetWidth() - (self.frame.achievementFrame.scroll:IsVisible() and 26 or 10)
	
	local offset = FauxScrollFrame_GetOffset(self.frame.achievementFrame.scroll)
	for _, data in pairs(SimpleGroup.EXPERIENCE_POINTS) do
		if( not data.childOf or ( data.childOf and SimpleGroup.db.profile.expExpanded[data.childOf] and ( data.tier or SimpleGroup.db.profile.expExpanded[SimpleGroup.CHILD_PARENTS[data.childOf]] ) ) ) then
			id = id + 1
			if( id >= offset ) then
				local row = self.frame.achievementFrame.rows[rowID]
				local rowOffset = 16
				if( data.tier and not data.childless ) then
					rowOffset = 30
				elseif( data.childOf ) then
					rowOffset = 20
				end
				
				-- Setup toggle button
				if( not data.childless and ( SimpleGroup.CHILD_PARENTS[data.id] or data.parent ) ) then
					local type = not SimpleGroup.db.profile.expExpanded[data.id] and "Plus" or "Minus"
					row.toggle:SetNormalTexture("Interface\\Buttons\\UI-" .. type .. "Button-UP")
					row.toggle:SetPushedTexture("Interface\\Buttons\\UI-" .. type .. "Button-DOWN")
					row.toggle:SetHighlightTexture("Interface\\Buttons\\UI-" .. type .. "Button-Hilight", "ADD")
					row.toggle.id = data.id
					row.toggle:Show()
				end
				
				local players = data.parent and data.players and string.format(L[" (%d-man)"], data.players) or ""
				-- Children categories without experience requirements should be shown in the experienceText so we don't get an off looking gap
				local heroicIcon = data.heroic and "|TInterface\\LFGFrame\\UI-LFG-ICON-HEROIC:16:13:-2:-2:32:32:0:16:0:20|t" or ""
				if( not data.experienced ) then
					row.nameText:SetFormattedText("%s%s%s", heroicIcon, data.name, players)
				-- Anything with an experience requirement obviously should show it
				elseif( data.experienced ) then
					local percent = math.min(self.experienceData[data.id] / data.experienced, 1)
					local experienceText = percent >= 1 and L["Experienced"] or percent >= 0.8 and L["Nearly-experienced"] or percent >= 0.5 and L["Semi-experienced"] or L["Inexperienced"]
					local r = (percent > 0.5 and (1.0 - percent) * 2 or 1.0) * 255
					local g = (percent > 0.5 and 1.0 or percent * 2) * 255
					
					if( data.childOf ) then
						row.nameText:SetFormattedText("- [|cff%02x%02x00%d%%|r] %s%s", r, g, percent * 100, heroicIcon, data.name)
					else
						row.nameText:SetFormattedText("[|cff%02x%02x00%d%%|r] %s%s%s", r, g, percent * 100, heroicIcon, data.name, players)
					end
					
					row.tooltip = string.format(L["%s: %d/%d in %d-man %s (%s)"], experienceText, self.experienceData[data.id], data.experienced, data.players, data.name, data.heroic and L["Heroic"] or L["Normal"])
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

			local percent = (note.rating - 1) / (SimpleGroup.MAX_RATING - 1)
			local r = (percent > 0.5 and (1.0 - percent) * 2 or 1.0) * 255
			local g = (percent > 0.5 and 1.0 or percent * 2) * 255
			local roles = ""
			if( bit.band(note.role, SimpleGroup.ROLE_HEALER) > 0 ) then roles = HEALER end
			if( bit.band(note.role, SimpleGroup.ROLE_TANK) > 0 ) then roles = roles .. ", " .. TANK end
			if( bit.band(note.role, SimpleGroup.ROLE_DAMAGE) > 0 ) then roles = roles .. ", " .. DAMAGE end
			
			row.infoText:SetFormattedText("|cff%02x%02x00%d|r/|cff20ff20%s|r from %s", r, g, note.rating, SimpleGroup.MAX_RATING, string.match(from, "(.-)%-") or from)
			row.commentText:SetText(note.comment or L["No comment"])
			row.tooltip = string.format(L["Seen as %s - %s:\n|cffffffff%s|r"], string.trim(string.gsub(roles, "^, ", "")), date("%m/%d/%Y", note.time), note.comment or L["No comment"])
			row:SetWidth(rowWidth)
			row:Show()
			
			rowID = rowID + 1
			if( rowID > MAX_NOTE_ROWS ) then break end
		end
		
		id = id + 1
	end
end

local TOTAL_DUNGEONS = #(SimpleGroup.DUNGEON_DATA) / 4
function Users:UpdateDungeonInfo()
	local self = Users

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
	for dataID=1, #(SimpleGroup.DUNGEON_DATA), 4 do
		if( id >= offset ) then
			local row = self.frame.dungeonFrame.rows[rowID]
			
			local name, score, players, type = SimpleGroup.DUNGEON_DATA[dataID], SimpleGroup.DUNGEON_DATA[dataID + 1], SimpleGroup.DUNGEON_DATA[dataID + 2], SimpleGroup.DUNGEON_DATA[dataID + 3]
			local percent = 1.0 - ((score - SimpleGroup.DUNGEON_MIN) / SimpleGroup.DUNGEON_DIFF)
			-- This shows colors relative to how close the player is to the score, not sure if we want to use this.
			--local percent = math.max(math.min(1 - ((score - self.activePlayerScore) / SimpleGroup.DUNGEON_DIFF), 1), 0)
			local r = (percent > 0.5 and (1.0 - percent) * 2 or 1.0) * 255
			local g = (percent > 0.5 and 1.0 or percent * 2) * 255
			local heroicIcon = (type == "heroic" or type == "hard") and "|TInterface\\LFGFrame\\UI-LFG-ICON-HEROIC:16:13:-2:-1:32:32:0:16:0:20|t" or ""
			
			row.dungeonName:SetFormattedText("%s|cff%02x%02x00%s|r", heroicIcon, r, g, name)
			row.dungeonInfo:SetFormattedText(L["|cff%02x%02x00%d|r score, %s-man (%s)"], r, g, score, players, SimpleGroup.DUNGEON_TYPES[type])
			row:Show()

			rowID = rowID + 1
			if( rowID > MAX_DUNGEON_ROWS ) then break end
		end
		
		id = id + 1
	end
end

-- Really need to restructure all of this soon
function Users:CreateUI()
	if( Users.frame ) then
		Users.frame:Show()
		return
	end

	local extraTooltip
	local function OnEnter(self)
		if( self.tooltip ) then
			GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
			GameTooltip:SetText(self.tooltip, nil, nil, nil, nil, not self.disableWrap)
			GameTooltip:Show()

		elseif( self.equippedItem ) then
			GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
			GameTooltip:SetHyperlink(self.equippedItem)
			GameTooltip:Show()

			extraTooltip = extraTooltip or CreateFrame("GameTooltip", "SimpleGroupUserTooltip", UIParent, "GameTooltipTemplate")
			extraTooltip:SetOwner(GameTooltip, "ANCHOR_NONE")
			extraTooltip:SetPoint("TOPLEFT", GameTooltip, "TOPRIGHT", 10, 0)
			
			if( self.itemTalentType ) then
				extraTooltip:SetText(string.format(L["|cfffed000Item Type:|r %s"], self.itemTalentType), 1, 1, 1)
			end
			if( self.enchantTooltip ) then
				extraTooltip:AddLine(self.enchantTooltip)
			end
			if( self.gemTooltip ) then
				extraTooltip:AddLine(self.gemTooltip)
			end
			
			extraTooltip:Show()
		end
	end

	local function OnLeave(self)
		GameTooltip:Hide()
		
		if( extraTooltip ) then
			extraTooltip:Hide()
		end
	end
		
	-- Main container
	local frame = CreateFrame("Frame", "SimpleGroupUserInfo", UIParent)
	self.frame = frame
	frame:SetClampedToScreen(true)
	frame:SetWidth(675)
	frame:SetHeight(400)
	frame:RegisterForDrag("LeftButton", "RightButton")
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetFrameStrata("HIGH")
	frame:SetFrameLevel(5)
	frame:SetScript("OnDragStart", function(self, mouseButton)
		if( mouseButton == "RightButton" ) then
			frame:ClearAllPoints()
			frame:SetPoint("CENTER", UIParent, "CENTER", SimpleGroup.db.profile.general.databaseExpanded and -75 or 0, 0)
			SimpleGroup.db.profile.positions.user = nil
			return
		end
		
		self:StartMoving()
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		
		local scale = self:GetEffectiveScale()
		SimpleGroup.db.profile.positions.user = {x = self:GetLeft() * scale, y = self:GetTop() * scale}
	end)
	frame:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		edgeSize = 26,
		insets = {left = 9, right = 9, top = 9, bottom = 9},
	})
	frame:SetBackdropColor(0, 0, 0, 0.90)
	
	table.insert(UISpecialFrames, "SimpleGroupUserInfo")
	
	if( SimpleGroup.db.profile.positions.user ) then
		local scale = frame:GetEffectiveScale()
		frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", SimpleGroup.db.profile.positions.user.x / scale, SimpleGroup.db.profile.positions.user.y / scale)
	else
		frame:SetPoint("CENTER", UIParent, "CENTER", SimpleGroup.db.profile.general.databaseExpanded and -75 or 0, 0)
	end

	frame.titleBar = frame:CreateTexture(nil, "ARTWORK")
	frame.titleBar:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
	frame.titleBar:SetPoint("TOP", 0, 8)
	frame.titleBar:SetWidth(200)
	frame.titleBar:SetHeight(45)

	frame.title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	frame.title:SetPoint("TOP", 0, 0)
	frame.title:SetText("Simple Group")

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

	if( SimpleGroup.db.profile.general.databaseExpanded ) then
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

	frame.databaseFrame.scroll = CreateFrame("ScrollFrame", "SimpleGroupUserFrameDatabase", frame.databaseFrame.fadeFrame, "FauxScrollFrameTemplate")
	frame.databaseFrame.scroll.bar = SimpleGroupUserFrameDatabase
	frame.databaseFrame.scroll:SetPoint("TOPLEFT", frame.databaseFrame, "TOPLEFT", 0, -7)
	frame.databaseFrame.scroll:SetPoint("BOTTOMRIGHT", frame.databaseFrame, "BOTTOMRIGHT", -28, 6)
	frame.databaseFrame.scroll:SetScript("OnVerticalScroll", function(self, value) Users.scrollUpdate = true; FauxScrollFrame_OnVerticalScroll(self, value, 14, Users.UpdateDatabasePage); Users.scrollUpdate = nil end)

	frame.databaseFrame.toggle = CreateFrame("Button", nil, frame.databaseFrame)
	frame.databaseFrame.toggle:SetPoint("LEFT", frame.databaseFrame, "RIGHT", -3, 0)
	frame.databaseFrame.toggle:SetFrameLevel(frame:GetFrameLevel() + 2)
	frame.databaseFrame.toggle:SetHeight(128)
	frame.databaseFrame.toggle:SetWidth(8)
	frame.databaseFrame.toggle:SetNormalTexture("Interface\\AddOns\\SimpleGroup\\media\\tabhandle")
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
		if( SimpleGroup.db.profile.general.databaseExpanded ) then
			frame.databaseFrame.startOffset = -10
			frame.databaseFrame.endOffset = -220

			UIFrameFadeIn(frame.databaseFrame.fadeFrame, 0.25, 1, 0)
		else
			frame.databaseFrame.startOffset = -220
			frame.databaseFrame.endOffset = 210
			
			UIFrameFadeIn(frame.databaseFrame.fadeFrame, 0.50, 0, 1)
		end
		
		SimpleGroup.db.profile.general.databaseExpanded = not SimpleGroup.db.profile.general.databaseExpanded
		frame.databaseFrame:SetScript("OnUpdate", frameAnimator)
	end)

	frame.databaseFrame.search = CreateFrame("EditBox", "SimpleGroupDatabaseSearch", frame.databaseFrame.fadeFrame, "InputBoxTemplate")
	frame.databaseFrame.search:SetHeight(18)
	frame.databaseFrame.search:SetWidth(150)
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
		Users:LoadData(SimpleGroup.userData[self.userID])
	end

	frame.databaseFrame.rows = {}
	for i=1, MAX_DATABASE_ROWS do
		local button = CreateFrame("Button", nil, frame.databaseFrame.fadeFrame)
		button:SetScript("OnClick", viewUserData)
		button:SetHeight(14)
		button:SetNormalFontObject(GameFontNormal)
		button:SetHighlightFontObject(GameFontHighlight)
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
	frame.pruneInfo:SetText(L["Gear and achievement data for this player has been pruned to reduce database size.\nNotes and basic data have been kept, you can view gear and achievements again by inspecting the player.\n\n\nIf you do not want data to be pruned or you want to increase the time before pruning, go to /SimpleGroup and change the value."])

	local inventoryMap = {"HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "WristSlot", "HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "Trinket0Slot", "Trinket1Slot", "MainHandSlot", "SecondaryHandSlot", "RangedSlot"}
	frame.gearFrame.equipSlots = {}
	for i=1, 18 do
		local slot = CreateFrame("Button", nil, frame.gearFrame)
		slot:SetHeight(30)
		slot:SetWidth(100)
		slot:SetScript("OnEnter", OnEnter)
		slot:SetScript("OnLeave", OnLeave)
		slot:SetMotionScriptsWhileDisabled(true)
		slot.icon = slot:CreateTexture(nil, "BACKGROUND")
		slot.icon:SetHeight(30)
		slot.icon:SetWidth(30)
		slot.icon:SetPoint("TOPLEFT", slot)

		if( i < 18 ) then
			slot.typeText = slot:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
			slot.typeText.icon = slot:CreateTexture(nil, "ARTWORK")
			slot.typeText.icon:SetPoint("TOPLEFT", slot.icon, "TOPRIGHT", -1, 0)
			slot.typeText.icon:SetSize(14, 14)
			slot.typeText:SetPoint("LEFT", slot.typeText.icon, "RIGHT", 0, 0)
			slot.typeText:SetJustifyV("CENTER")
			slot.typeText:SetJustifyH("LEFT")
			slot.typeText:SetWidth(60)
			slot.typeText:SetHeight(11)

			slot.extraText = slot:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
			slot.extraText.icon = slot:CreateTexture(nil, "ARTWORK")
			slot.extraText.icon:SetPoint("BOTTOMLEFT", slot.icon, "BOTTOMRIGHT", -1, 1)
			slot.extraText.icon:SetSize(12, 12)
			slot.extraText:SetPoint("LEFT", slot.extraText.icon, "RIGHT", 2, 0)
			slot.extraText:SetJustifyV("CENTER")
			slot.extraText:SetJustifyH("LEFT")
			slot.extraText:SetWidth(60)
			slot.extraText:SetHeight(11)
			slot.extraText:SetTextColor(0.85, 0.85, 0.85, 0.95)
		else
			slot.text = slot:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
			slot.text:SetPoint("LEFT", slot.icon, "RIGHT", 2, 0)
			slot.text:SetWidth(72)
			slot.text:SetHeight(14)
			slot.text:SetJustifyV("CENTER")
			slot.text:SetJustifyH("LEFT")
		end
			
	   if( i == 10 ) then
		  slot:SetPoint("TOPLEFT", frame.gearFrame.equipSlots[1], "TOPRIGHT", 9, 0)    
	   elseif( i > 1 ) then
		  slot:SetPoint("TOPLEFT", frame.gearFrame.equipSlots[i - 1], "BOTTOMLEFT", 0, -9)
	   else
		  slot:SetPoint("TOPLEFT", frame.gearFrame, "TOPLEFT", 5, -8)
	   end

		if( inventoryMap[i] ) then
			slot.inventorySlot = inventoryMap[i]
			slot.inventoryType = SimpleGroup.INVENTORY_TO_TYPE[inventoryMap[i]]
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
	frame.userFrame:SetHeight(80)
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
	
	-- Dungeon suggested container
	frame.dungeonFrame = CreateFrame("Frame", nil, frame)   
	frame.dungeonFrame:SetBackdrop(backdrop)
	frame.dungeonFrame:SetBackdropBorderColor(0.60, 0.60, 0.60, 1)
	frame.dungeonFrame:SetBackdropColor(0, 0, 0, 0)
	frame.dungeonFrame:SetWidth(175)
	frame.dungeonFrame:SetHeight(243)
	frame.dungeonFrame:SetPoint("TOPLEFT", frame.userFrame, "BOTTOMLEFT", 0, -24)

	frame.dungeonFrame.headerText = frame.dungeonFrame:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
	frame.dungeonFrame.headerText:SetPoint("BOTTOMLEFT", frame.dungeonFrame, "TOPLEFT", 0, 5)
	frame.dungeonFrame.headerText:SetText(L["Suggested dungeons"])

	frame.dungeonFrame.scroll = CreateFrame("ScrollFrame", "SimpleGroupUserFrameDungeon", frame.dungeonFrame, "FauxScrollFrameTemplate")
	frame.dungeonFrame.scroll.bar = SimpleGroupUserFrameDungeonScrollBar
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
			button:SetPoint("TOPLEFT", frame.dungeonFrame.rows[i - 1], "BOTTOMLEFT", 0, -7)
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

	frame.achievementFrame.scroll = CreateFrame("ScrollFrame", "SimpleGroupUserFrameAchievements", frame.achievementFrame, "FauxScrollFrameTemplate")
	frame.achievementFrame.scroll.bar = SimpleGroupUserFrameAchievementsScrollBar
	frame.achievementFrame.scroll:SetPoint("TOPLEFT", frame.achievementFrame, "TOPLEFT", 0, -2)
	frame.achievementFrame.scroll:SetPoint("BOTTOMRIGHT", frame.achievementFrame, "BOTTOMRIGHT", -24, 1)
	frame.achievementFrame.scroll:SetScript("OnVerticalScroll", function(self, value) FauxScrollFrame_OnVerticalScroll(self, value, 14, Users.UpdateAchievementInfo) end)

	local function toggleCategory(self)
		local id = self.toggle and self.toggle.id or self.id
		if( not id ) then return end
		
		SimpleGroup.db.profile.expExpanded[id] = not SimpleGroup.db.profile.expExpanded[id]
		Users:UpdateAchievementInfo()
	end
	
	frame.achievementFrame.rows = {}
	for i=1, MAX_ACHIEVEMENT_ROWS do
		local button = CreateFrame("Button", nil, frame.achievementFrame)
		button:SetScript("OnEnter", OnEnter)
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
	
	frame.noteFrame.scroll = CreateFrame("ScrollFrame", "SimpleGroupUserFrameNotes", frame.noteFrame, "FauxScrollFrameTemplate")
	frame.noteFrame.scroll.bar = SimpleGroupUserFrameNotesScrollBar
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
		button.commentText:SetHeight(30)
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

