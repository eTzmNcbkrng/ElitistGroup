local SexyGroup = select(2, ...)
local Users = SexyGroup:NewModule("Users", "AceEvent-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("SexyGroup")
local MAX_DUNGEON_ROWS, MAX_NOTE_ROWS = 7, 7
local MAX_ACHIEVEMENT_ROWS = 20
local backdrop = {bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeSize = 1}
local gemList = {}

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(self)
	self:UnregisterAllEvents()
	--Users:LoadData(SexyGroup.userData["Shadow-Mal'Ganis"])
end)	

local function sortGems(a, b)
	return gemList[a] > gemList[b]
end

function Users:LoadData(playerData)
	self:CreateUI()
	local frame = self.frame

	table.wipe(gemList)

	-- Build score as well as figure out their score
	local tempList = {}
	local totalEquipped, totalSockets, totalUsedSockets, totalScore, mainLevel, offLevel = 0, 0, 0, 0, 0, 0

	for _, slot in pairs(frame.gearFrame.equipSlots) do
		if( slot.inventoryID and playerData.equipment[slot.inventoryID] ) then
			local itemLink = playerData.equipment[slot.inventoryID]
			local itemQuality, itemLevel, _, _, _, _, _, itemIcon = select(3, GetItemInfo(itemLink))
			if( itemQuality and itemLevel ) then
				local itemScore = SexyGroup:CalculateScore(itemQuality, itemLevel)
				if( slot.inventorySlot == "MainHandSlot" ) then
					mainLevel = itemScore
				elseif( slot.inventorySlot == "SecondaryHandSlot" ) then
					offLevel = itemScore
				else
					totalEquipped = totalEquipped + 1
					totalScore = totalScore + itemScore
				end
				
				totalSockets = totalSockets + SexyGroup.EMPTY_GEM_SLOTS[itemLink]
				for socketID=1, MAX_NUM_SOCKETS do
					local gemLink = select(2, GetItemGem(itemLink, socketID))
					if( gemLink ) then
						totalUsedSockets = totalUsedSockets + 1
						gemList[gemLink] = (gemList[gemLink] or 0) + 1
					end
				end
				
				slot.icon:SetTexture(itemIcon)
				slot.levelText:SetFormattedText("%s%d|r", ITEM_QUALITY_COLORS[itemQuality] and ITEM_QUALITY_COLORS[itemQuality].hex or "", itemScore)
				slot.typeText:SetFormattedText("|T%s:16:16:-1:0|t%s", SexyGroup:IsValidItem(itemLink, playerData) and READY_CHECK_READY_TEXTURE or READY_CHECK_NOT_READY_TEXTURE, SexyGroup.TALENT_TYPES[SexyGroup.ITEM_TALENTTYPE[itemLink]])
				slot.equippedItem = itemLink
				slot.tooltip = nil
				slot:Enable()
			else
				slot.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
				slot.levelText:SetText("----")
				slot.typeText:SetText("----")
				slot.equippedItem = nil
				slot.tooltip = string.format(L["Cannot find item data for item id %s."], string.match(itemLink, "item:(%d+)"))
				slot:Disable()
			end
		elseif( slot.inventoryID ) then
			local texture = slot.emptyTexture
			if( slot.checkRelic and ( playerData.classToken == "PALADIN" or playerData.classToken == "DRUID" or playerData.classToken == "SHAMAN" ) ) then
				texture = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Relic.blp"
			end
			
			slot.icon:SetTexture(texture)
			slot.levelText:SetText("---")
			slot.typeText:SetText("---")
			slot.tooltip = L["No item equipped"]
			slot:Disable()
		end
	end
	
	-- Figure out if gems and enchants are valid
	local enchantTooltip, gemTooltip = L["|cfffed000Enchants:|r All good"], L["|cfffed000Gems:|r All good"]
	local passEnchants, passGems = true, true
	if( totalUsedSockets < totalSockets ) then
		passGems = false
		gemTooltip = string.format(L["|cfffed000Gems:|r %d empty gem sockets"], totalSockets - totalUsedSockets)
	else
		for gemLink, total in pairs(gemList) do
			if( not SexyGroup:IsValidGem(gemLink, playerData) ) then
				table.insert(tempList, gemLink)
			end
		end
		
		if( #(tempList) > 0 ) then
			passGems = false
			table.sort(tempList, sortGems)
			
			local gems = ""
			for _, gemLink in pairs(tempList) do
				if( gems ~= "" ) then gems = gems .. "\n" end
				gems = gems .. string.format("%d x %s - %s", gemList[gemLink], select(2, GetItemInfo(gemLink)), SexyGroup.TALENT_TYPES[SexyGroup.GEM_TALENTTYPE[gemLink]])
			end
			
			gemTooltip = string.format(L["|cfffed000Gems:|r Found |cffff2020%d|r bad gems\n%s"], #(tempList), gems)
		end
	end
	
	frame.gearFrame.equipSlots[18].icon:SetTexture("Interface\\Icons\\INV_JewelCrafting_Gem_42")
	frame.gearFrame.equipSlots[18].levelText:SetFormattedText(L["|T%s:14:14|t Enchants"], passEnchants and READY_CHECK_READY_TEXTURE or READY_CHECK_NOT_READY_TEXTURE)
	frame.gearFrame.equipSlots[18].typeText:SetFormattedText(L["|T%s:14:14|t Gems"], passGems and READY_CHECK_READY_TEXTURE or READY_CHECK_NOT_READY_TEXTURE)
	frame.gearFrame.equipSlots[18].tooltip = enchantTooltip .. "\n" .. gemTooltip
	frame.gearFrame.equipSlots[18].disableWrap = true
	frame.gearFrame.equipSlots[18].tooltipR = 1
	frame.gearFrame.equipSlots[18].tooltipG = 1
	frame.gearFrame.equipSlots[18].tooltipB = 1
	
	-- If the player is using both a mainhand and an offhand, average the two as if they were a single item
	if( mainLevel and offLevel ) then
		totalEquipped = totalEquipped + 1
		totalScore = math.floor((totalScore + ((mainLevel + offLevel) / 2)) / totalEquipped)
	else
		totalEquipped = totalEquipped + 1
		totalScore = math.floor((totalScore + (mainLevel or 0) + (offLevel or 0)) / totalEquipped)
	end

	-- Build the players info
	local coords = CLASS_BUTTONS[playerData.classToken]
	if( coords ) then
		frame.userFrame.playerInfo:SetFormattedText("|TInterface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes:16:16:-1:0:%s:%s:%s:%s:%s:%s|t %s (%s)", 256, 256, coords[1] * 256, coords[2] * 256, coords[3] * 256, coords[4] * 256, playerData.name, playerData.level)
		frame.userFrame.playerInfo.tooltip = string.format(L["%s - %s, level %s %s."], playerData.name, playerData.realm, playerData.level, LOCALIZED_CLASS_NAMES_MALE[playerData.classToken])
	else
		frame.userFrame.playerInfo:SetFormattedText("|TInterface\\Icons\\INV_Misc_QuestionMark:16:16:-1:0|t %s (%s)", playerData.name, playerData.level)
		frame.userFrame.playerInfo.tooltip = string.format(L["%s - %s, level %s, unknown class."], playerData.name, playerData.realm, playerData.level)
	end
	
	local specType, specName, specIcon = SexyGroup:GetPlayerSpec(playerData)
	
	frame.userFrame.talentInfo:SetFormattedText("|T%s:16:16:-1:0|t %d/%d/%d (%s)", specIcon, playerData.talentTree1, playerData.talentTree2, playerData.talentTree3, specName)
	frame.userFrame.talentInfo.tooltip = string.format(L["%s, %s role."], specName, SexyGroup.TALENT_ROLES[specType])
	
	local scoreIcon = totalScore >= 240 and "INV_Shield_72" or totalScore >= 220 and "INV_Shield_61" or totalScore >= 200 and "INV_Shield_26" or "INV_Shield_36"
	frame.userFrame.scoreInfo:SetFormattedText("|TInterface\\Icons\\%s:16:16:-1:0|t %d %s", scoreIcon, totalScore, L["score"])

	local scanAge = (time() - playerData.scanned) / 3600
	local scanIcon = scanAge >= 5 and 37 or scanAge >= 2 and 39 or scanAge >= 1 and 38 or 41
	if( scanAge == 0 ) then
		frame.userFrame.scannedInfo:SetFormattedText("|TInterface\\Icons\\INV_JewelCrafting_Gem_%s:16:16:-1:0|t %s", scanIcon, L["Scanned today"])
	elseif( scanAge >= 24 ) then
		frame.userFrame.scannedInfo:SetFormattedText("|TInterface\\Icons\\INV_JewelCrafting_Gem_%s:16:16:-1:0|t %s", scanIcon, string.format(L["%d days old"], scanAge / 24))
	else
		frame.userFrame.scannedInfo:SetFormattedText("|TInterface\\Icons\\INV_JewelCrafting_Gem_%s:16:16:-1:0|t %s", scanIcon, string.format(L["%d hours old"], scanAge))
	end
	
	if( playerData.trusted ) then
		frame.userFrame.trustedInfo:SetFormattedText("|T%s:16:16:-1:0|t %s (%s)", READY_CHECK_READY_TEXTURE, playerData.from, L["Trusted"])
		frame.userFrame.trustedInfo.tooltip = L["Player data is from a verified source and is accurate!"]
	else
		frame.userFrame.trustedInfo:SetFormattedText("|T%s:16:16:-1:0|t %s (%s)", READY_CHECK_NOT_READY_TEXTURE, playerData.from, L["Untrusted"])
		frame.userFrame.trustedInfo.tooltip = L["While the player data should be accurate, it is not guaranteed."]
	end
	
	-- Build the necessary experience data based on the players achievements, this is fun!
	self.experienceData = {}
	for _, data in pairs(SexyGroup.EXPERIENCE_POINTS) do
		self.experienceData[data.id] = self.experienceData[data.id] or 0
				
		for id, points in pairs(data) do
			if( type(id) == "number" and playerData.achievements[id] ) then
				self.experienceData[data.id] = self.experienceData[data.id] + (points * playerData.achievements[id])
			end
		end
		
		-- Add the childs score to the parents
		if( not data.parent ) then
			self.experienceData[data.child] = (self.experienceData[data.child] or 0) + self.experienceData[data.id]
		end
		
		-- Cascade the scores from this one to whatever it's supposed to
		if( data.cascade ) then
			self.experienceData[data.cascade] = (self.experienceData[data.cascade] or 0) + self.experienceData[data.id]
		end
	end
	
	-- Setup dungeon info
	-- Find where the players score lets them into at least
	local lockedScore
	for i=#(SexyGroup.DUNGEON_DATA), 1, -4 do
		local score = SexyGroup.DUNGEON_DATA[i - 2]
		if( lockedScore and lockedScore ~= score ) then
			self.forceOffset = math.ceil((i + 1) / 4)
			break
		elseif( totalScore >= score ) then
			lockedScore = score
			self.forceOffset = math.ceil((i + 1) / 4)
		end
	end

	self.activeData = playerData
	self:UpdateDungeonInfo()
	self:UpdateTabPage()
end

function Users:UpdateTabPage()
	self.frame.tabFrame.notesButton:SetFormattedText(L["Notes (%d)"], #(self.activeData.notes))
	if( #(self.activeData.notes) == 0 ) then
		self.frame.tabFrame.selectedTab = "achievements"
		self.frame.tabFrame.notesButton:Disable()
	else
		self.frame.tabFrame.notesButton:Enable()
	end
	
	if( self.frame.tabFrame.selectedTab == "notes" ) then
		self.frame.noteFrame:Show()
		self.frame.achievementFrame:Hide()

		self.frame.tabFrame.notesButton:LockHighlight()
		self.frame.tabFrame.achievementsButton:UnlockHighlight()
		
		self:UpdateNoteInfo()
	else
		self.frame.noteFrame:Hide()
		self.frame.achievementFrame:Show()

		self.frame.tabFrame.notesButton:UnlockHighlight()
		self.frame.tabFrame.achievementsButton:LockHighlight()

		self:UpdateAchievementInfo()
	end
end

function Users:UpdateAchievementInfo()
	local self = Users
	local totalEntries = 0
	for id, data in pairs(SexyGroup.EXPERIENCE_POINTS) do
		if( not data.child or data.child and SexyGroup.db.profile.expExpanded[data.child] ) then
			totalEntries = totalEntries + 1
		end
	end
	
	FauxScrollFrame_Update(self.frame.achievementFrame.scroll, totalEntries, MAX_ACHIEVEMENT_ROWS - 1, 14)
	
	for _, row in pairs(self.frame.achievementFrame.rows) do row.tooltip = nil; row.toggle:Hide(); row:Hide() end

	local rowID, rowOffset, id = 1, 0, 0
	local rowWidth = self.frame.achievementFrame:GetWidth() - (self.frame.achievementFrame.scroll:IsVisible() and 26 or 10)
	
	local offset = FauxScrollFrame_GetOffset(self.frame.achievementFrame.scroll)
	for _, data in pairs(SexyGroup.EXPERIENCE_POINTS) do
		if( not data.child or data.child and SexyGroup.db.profile.expExpanded[data.child] ) then
			id = id + 1
			if( id >= offset ) then
				local row = self.frame.achievementFrame.rows[rowID]
				local rowOffset = not data.child and 16 or 4
				
				-- Setup toggle button
				if( not data.child and not data.childLess ) then
					local type = not SexyGroup.db.profile.expExpanded[data.id] and "Minus" or "Plus"
					row.toggle:SetNormalTexture("Interface\\Buttons\\UI-" .. type .. "Button-UP")
					row.toggle:SetPushedTexture("Interface\\Buttons\\UI-" .. type .. "Button-DOWN")
					row.toggle:SetHighlightTexture("Interface\\Buttons\\UI-" .. type .. "Button-Hilight", "ADD")
					row.toggle.id = data.id
					row.toggle:Show()
				end
				
				-- Children categories without experience requirements should be shown in the experienceText so we don't get an off looking gap
				local heroicIcon = data.heroic and "|TInterface\\LFGFrame\\UI-LFG-ICON-HEROIC:16:13:-2:-2:32:32:0:16:0:20|t" or ""
				if( not data.child and not data.experienced ) then
					row.nameText:SetFormattedText(L["%s%s (%d-man)"], heroicIcon, data.name, data.players)
				-- Anything with an experience requirement obviously should show it
				elseif( data.experienced ) then
					local percent = math.min(self.experienceData[data.id] / data.experienced, 1)
					local experienceText = percent >= 1 and L["Experienced"] or percent >= 0.8 and L["Nearly-experienced"] or percent >= 0.5 and L["Semi-experienced"] or L["Inexperienced"]
					local r = (percent > 0.5 and (1.0 - percent) * 2 or 1.0) * 255
					local g = (percent > 0.5 and 1.0 or percent * 2) * 255
					
					if( data.child ) then
						row.nameText:SetFormattedText(L["- [|cff%02x%02x00%d%%|r] %s%s"], r, g, percent * 100, heroicIcon, data.name)
					else
						row.nameText:SetFormattedText(L["[|cff%02x%02x00%d%%|r] %s%s (%d-man)"], r, g, percent * 100, heroicIcon, data.name, data.players)
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
	FauxScrollFrame_Update(self.frame.noteFrame.scroll, #(self.activeData.notes), MAX_NOTE_ROWS - 1, 48)
	
	for _, row in pairs(self.frame.noteFrame.rows) do row:Hide() end
	local rowWidth = self.frame.noteFrame:GetWidth() - (self.frame.noteFrame.scroll:IsVisible() and 24 or 10)
	
	local rowID = 1
	local offset = FauxScrollFrame_GetOffset(self.frame.noteFrame.scroll)
	for id, note in pairs(self.activeData.notes) do
		if( id >= offset ) then
			local row = self.frame.noteFrame.rows[rowID]

			local percent = note.rating / SexyGroup.MAX_RATING
			local r = (percent > 0.5 and (1.0 - percent) * 2 or 1.0) * 255
			local g = (percent > 0.5 and 1.0 or percent * 2) * 255
			
			row.infoText:SetFormattedText("|cff%02x%02x00%d|r/|cff20ff20%s|r from %s", r, g, note.rating, SexyGroup.MAX_RATING, note.from)
			row.commentText:SetText(note.comment)
			row.tooltip = string.format(L["%s wrote: %s"], note.from, note.comment)
			row:SetWidth(rowWidth)
			row:Show()
			
			rowID = rowID + 1
			if( rowID > MAX_NOTE_ROWS ) then break end
		end
	end
end

local TOTAL_DUNGEONS = #(SexyGroup.DUNGEON_DATA) / 4
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
	for dataID=1, #(SexyGroup.DUNGEON_DATA), 4 do
		if( id >= offset ) then
			local row = self.frame.dungeonFrame.rows[rowID]
			
			local name, score, players, type = SexyGroup.DUNGEON_DATA[dataID], SexyGroup.DUNGEON_DATA[dataID + 1], SexyGroup.DUNGEON_DATA[dataID + 2], SexyGroup.DUNGEON_DATA[dataID + 3]
			local percent = 1.0 - ((score - SexyGroup.DUNGEON_MIN) / SexyGroup.DUNGEON_DIFF)
			local r = (percent > 0.5 and (1.0 - percent) * 2 or 1.0) * 255
			local g = (percent > 0.5 and 1.0 or percent * 2) * 255
			local heroicIcon = type == "heroic" and "|TInterface\\LFGFrame\\UI-LFG-ICON-HEROIC:16:13:-2:-1:32:32:0:16:0:20|t" or ""
			
			row.dungeonName:SetFormattedText("%s|cff%02x%02x00%s|r", heroicIcon, r, g, name)
			row.dungeonInfo:SetFormattedText(L["|cff%02x%02x00%d|r score, %s-man (%s)"], r, g, score, players, SexyGroup.DUNGEON_TYPES[type])
			row:Show()

			rowID = rowID + 1
			if( rowID > MAX_DUNGEON_ROWS ) then break end
		end
		
		id = id + 1
	end
end

function Users:CreateUI()
	if( Users.frame ) then
		Users.frame:Show()
		return
	end

	local function OnEnter(self)
		if( self.tooltip ) then
			GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
			GameTooltip:SetText(self.tooltip, self.tooltipR, self.tooltipG, self.tooltipB, nil, self.disableWrap == nil and true)
			GameTooltip:Show()
		elseif( self.equippedItem ) then
			GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
			GameTooltip:SetHyperlink(self.equippedItem)
		end
	end

	local function OnLeave(self)
		GameTooltip:Hide()
	end
		
	-- Main container
	local frame = CreateFrame("Frame", nil, UIParent)
	Users.frame = frame
	frame:SetClampedToScreen(true)
	frame:SetWidth(675)
	frame:SetHeight(400)
	frame:RegisterForDrag("LeftButton")
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
	frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
	frame:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		edgeSize = 26,
		insets = {left = 9, right = 9, top = 9, bottom = 9},
	})
	frame:SetBackdropColor(0, 0, 0, 0.90)
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

	frame.titleBar = frame:CreateTexture(nil, "ARTWORK")
	frame.titleBar:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
	frame.titleBar:SetPoint("TOP", 0, 8)
	frame.titleBar:SetWidth(200)
	frame.titleBar:SetHeight(45)

	frame.title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	frame.title:SetPoint("TOP", 0, 0)
	frame.title:SetText("Sexy Group")

	-- Close button
	local button = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	button:SetPoint("TOPRIGHT", -3, -3)
	button:SetHeight(24)
	button:SetWidth(24)
	button:SetScript("OnClick", function()
		frame:Hide()
	end)
		
	-- Create the equipment frame
	frame.gearFrame = CreateFrame("Frame", nil, frame)
	frame.gearFrame:SetWidth(230)
	frame.gearFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -10)
	frame.gearFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 10)

	frame.gearFrame.headerText = frame.gearFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	frame.gearFrame.headerText:SetHeight(14)
	frame.gearFrame.headerText:SetText(L["Items equipped"])
	frame.gearFrame.headerText:SetPoint("TOPLEFT", frame.gearFrame, "TOPLEFT", 0, 0)
	frame.gearFrame:SetBackdrop(backdrop)
	frame.gearFrame:SetBackdropBorderColor(0.60, 0.60, 0.60, 1)
	frame.gearFrame:SetBackdropColor(0, 0, 0, 0)
	frame.gearFrame:ClearAllPoints()
	frame.gearFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -30)
	frame.gearFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 15)
	frame.gearFrame:SetWidth(225)
	frame.gearFrame.headerText:ClearAllPoints()
	frame.gearFrame.headerText:SetPoint("BOTTOMLEFT", frame.gearFrame, "TOPLEFT", 0, 5)

	local inventoryMap = {"HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "WristSlot", "HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "Trinket0Slot", "Trinket1Slot", "MainHandSlot", "SecondaryHandSlot", "RangedSlot"}
	
	frame.gearFrame.equipSlots = {}
	for i=1, 18 do
	   local slot = CreateFrame("Button", nil, frame.gearFrame)
	   slot:SetHeight(30)
	   slot:SetWidth(70)
	   slot:SetScript("OnEnter", OnEnter)
	   slot:SetScript("OnLeave", OnLeave)
	   slot:SetMotionScriptsWhileDisabled(true)
	   slot.icon = slot:CreateTexture(nil, "BACKGROUND")
	   slot.icon:SetHeight(30)
	   slot.icon:SetWidth(30)
	   slot.icon:SetPoint("TOPLEFT", slot)
	   
	   slot.levelText = slot:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	   slot.levelText:SetPoint("TOPLEFT", slot.icon, "TOPRIGHT", 2, -3)
	   slot.typeText = slot:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	   slot.typeText:SetPoint("BOTTOMLEFT", slot.icon, "BOTTOMRIGHT", 2, 3)
		  
	   if( i == 10 ) then
		  slot:SetPoint("TOPLEFT", frame.gearFrame.equipSlots[1], "TOPRIGHT", 40, 0)    
	   elseif( i > 1 ) then
		  slot:SetPoint("TOPLEFT", frame.gearFrame.equipSlots[i - 1], "BOTTOMLEFT", 0, -9)
	   else
		  slot:SetPoint("TOPLEFT", frame.gearFrame, "TOPLEFT", 5, -8)
	   end

		if( inventoryMap[i] ) then
			slot.inventorySlot = inventoryMap[i]
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
	frame.userFrame:SetHeight(100)
	frame.userFrame:SetPoint("TOPLEFT", frame.gearFrame, "TOPRIGHT", 10, -8)

	frame.userFrame.headerText = frame.userFrame:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
	frame.userFrame.headerText:SetPoint("BOTTOMLEFT", frame.userFrame, "TOPLEFT", 0, 5)
	frame.userFrame.headerText:SetText(L["Player info"])

	local buttonList = {"playerInfo", "talentInfo", "scoreInfo", "scannedInfo", "trustedInfo"}
	for i, key in pairs(buttonList) do
		local button = CreateFrame("Button", nil, frame.userFrame)
		button:SetNormalFontObject(GameFontHighlight)
		button:SetText("*")
		button:SetHeight(15)
		button:SetScript("OnEnter", OnEnter)
		button:SetScript("OnLeave", OnLeave)
		button:GetFontString():SetJustifyH("LEFT")
		button:GetFontString():SetPoint("LEFT", button, "LEFT", 0, 0)
		button:GetFontString():SetJustifyV("CENTER")
		
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
	frame.dungeonFrame:SetHeight(223)
	frame.dungeonFrame:SetPoint("TOPLEFT", frame.userFrame, "BOTTOMLEFT", 0, -24)

	frame.dungeonFrame.headerText = frame.dungeonFrame:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
	frame.dungeonFrame.headerText:SetPoint("BOTTOMLEFT", frame.dungeonFrame, "TOPLEFT", 0, 5)
	frame.dungeonFrame.headerText:SetText(L["Suggested dungeons"])

	frame.dungeonFrame.scroll = CreateFrame("ScrollFrame", "SexyGroupUserFrameDungeon", frame.dungeonFrame, "FauxScrollFrameTemplate")
	frame.dungeonFrame.scroll.bar = SexyGroupUserFrameDungeonScrollBar
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
			button:SetPoint("TOPLEFT", frame.dungeonFrame.rows[i - 1], "BOTTOMLEFT", 0, -4)
		else
			button:SetPoint("TOPLEFT", frame.dungeonFrame, "TOPLEFT", 3, -1)
		end

		frame.dungeonFrame.rows[i] = button
	end
	
	-- Parent container
	frame.tabFrame = CreateFrame("Frame", nil, frame)   
	frame.tabFrame:SetBackdrop(backdrop)
	frame.tabFrame:SetBackdropBorderColor(0.60, 0.60, 0.60, 1)
	frame.tabFrame:SetBackdropColor(0, 0, 0, 0)
	frame.tabFrame:SetWidth(235)
	frame.tabFrame:SetHeight(347)
	frame.tabFrame:SetPoint("TOPLEFT", frame.userFrame, "TOPRIGHT", 10, 0)
	
	frame.tabFrame.selectedTab = "notes"
	local function tabClicked(self)
		frame.tabFrame.selectedTab = self.tabID
		Users:UpdateTabPage()
	end
	
	frame.tabFrame.notesButton = CreateFrame("Button", nil, frame.tabFrame)
	frame.tabFrame.notesButton:SetNormalFontObject(GameFontNormal)
	frame.tabFrame.notesButton:SetHighlightFontObject(GameFontHighlight)
	frame.tabFrame.notesButton:SetDisabledFontObject(GameFontDisable)
	frame.tabFrame.notesButton:SetPoint("BOTTOMLEFT", frame.tabFrame, "TOPLEFT", 0, -1)
	frame.tabFrame.notesButton:SetScript("OnClick", tabClicked)
	frame.tabFrame.notesButton:SetText("*")
	frame.tabFrame.notesButton:GetFontString():SetPoint("LEFT", 3, 0)
	frame.tabFrame.notesButton:SetHeight(22)
	frame.tabFrame.notesButton:SetWidth(90)
	frame.tabFrame.notesButton:SetBackdrop(backdrop)
	frame.tabFrame.notesButton:SetBackdropColor(0, 0, 0, 0)
	frame.tabFrame.notesButton:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
	frame.tabFrame.notesButton.tabID = "notes"

	frame.tabFrame.achievementsButton = CreateFrame("Button", nil, frame.tabFrame)
	frame.tabFrame.achievementsButton:SetNormalFontObject(GameFontNormal)
	frame.tabFrame.achievementsButton:SetHighlightFontObject(GameFontHighlight)
	frame.tabFrame.achievementsButton:SetDisabledFontObject(GameFontDisable)
	frame.tabFrame.achievementsButton:SetPoint("TOPLEFT", frame.tabFrame.notesButton, "TOPRIGHT", 4, 0)
	frame.tabFrame.achievementsButton:SetScript("OnClick", tabClicked)
	frame.tabFrame.achievementsButton:SetText(L["Experience"])
	frame.tabFrame.achievementsButton:GetFontString():SetPoint("LEFT", 3, 0)
	frame.tabFrame.achievementsButton:SetHeight(22)
	frame.tabFrame.achievementsButton:SetWidth(90)
	frame.tabFrame.achievementsButton:SetBackdrop(backdrop)
	frame.tabFrame.achievementsButton:SetBackdropColor(0, 0, 0, 0)
	frame.tabFrame.achievementsButton:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
	frame.tabFrame.achievementsButton.tabID = "achievements"

	-- Achievement container
	frame.achievementFrame = CreateFrame("Frame", nil, frame.tabFrame)   
	frame.achievementFrame:SetAllPoints(frame.tabFrame)

	frame.achievementFrame.scroll = CreateFrame("ScrollFrame", "SexyGroupUserFrameAchievements", frame.achievementFrame, "FauxScrollFrameTemplate")
	frame.achievementFrame.scroll.bar = SexyGroupUserFrameAchievementsScrollBar
	frame.achievementFrame.scroll:SetPoint("TOPLEFT", frame.achievementFrame, "TOPLEFT", 0, -2)
	frame.achievementFrame.scroll:SetPoint("BOTTOMRIGHT", frame.achievementFrame, "BOTTOMRIGHT", -24, 1)
	frame.achievementFrame.scroll:SetScript("OnVerticalScroll", function(self, value) FauxScrollFrame_OnVerticalScroll(self, value, 14, Users.UpdateAchievementInfo) end)

	local function toggleCategory(self)
		local id = self.toggle and self.toggle.id or self.id
		SexyGroup.db.profile.expExpanded[id] = not SexyGroup.db.profile.expExpanded[id]
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
	frame.noteFrame = CreateFrame("Frame", nil, frame.tabFrame)   
	frame.noteFrame:SetAllPoints(frame.tabFrame)
	
	frame.noteFrame.scroll = CreateFrame("ScrollFrame", "SexyGroupUserFrameNotes", frame.noteFrame, "FauxScrollFrameTemplate")
	frame.noteFrame.scroll.bar = SexyGroupUserFrameNotesScrollBar
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

