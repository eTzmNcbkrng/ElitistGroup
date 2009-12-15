local Users = SexyGroup:NewModule("Users", "AceEvent-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("SexyGroup")
local MAX_DUNGEON_ROWS, MAX_NOTE_ROWS = 7, 7
local MAX_ACHIEVEMENT_ROWS = 12
local backdrop = {bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeSize = 1}

local TEST_DATA = {
	name = "Mayen",
	realm = "Mal'Ganis",
	level = 80,
	classToken = "DRUID",
	talentTree1 = 10,
	talentTree2 = 0,
	talentTree3 = 61,
	specRole = nil,
	from = "Selari",
	trusted = false,
	scanned = "12/14/2009 0:10:20", -- MM/DD/YYYY HH:MM:SS
	items = {
		["WristSlot"] = "item:40323:2332:3520:0:0:0:0:1909562656:80",
		["BackSlot"] = "item:45493:3831:0:0:0:0:0:1071947136:80",
		["Trinket0Slot"] = "item:37835:0:0:0:0:0:0:2104852352:80",
		["FeetSlot"] = "item:45565:3232:3545:3520:0:0:0:140590272:80",
		["LegsSlot"] = "item:45847:3719:3520:3734:0:0:0:0:80",
		["Finger1Slot"] = "item:49486:0:0:0:0:0:0:1347394432:80",
		["RangedSlot"] = "item:40342:0:0:0:0:0:0:0:80",
		["Trinket1Slot"] = "item:45929:0:0:0:0:0:0:-2054043520:80",
		["HeadSlot"] = "item:45346:3819:3627:3734:0:0:0:0:80",
		["MainHandSlot"] = "item:40488:3834:0:0:0:0:0:-1988596908:80",
		["SecondaryHandSlot"] = "item:40192:0:0:0:0:0:0:2005934728:80",
		["WaistSlot"] = "item:45556:0:3520:3520:3866:0:0:1962653440:80",
		["ChestSlot"] = "item:46186:3832:3734:3558:0:0:0:0:80",
		["ShoulderSlot"] = "item:40594:3809:0:0:0:0:0:-1469749462:80",
		["Finger0Slot"] = "item:51558:0:0:0:0:0:0:0:80",
		["NeckSlot"] = "item:45822:0:0:0:0:0:0:0:80",
		["HandsSlot"] = "item:45345:3246:3545:0:0:0:0:0:80",
	},
	notes = {
		{
			rating = 5,
			from = "Mayen",
			comment = "The quick brown fox, happens to be quick enough when it's jumping over a very lazy dog.",
			role = bit.bor(SexyGroup.ROLE_HEALER, SexyGroup.ROLE_TANK), -- Tank, Healer
			dungeon = "Halls of Reflection",
		},
		{
			rating = 4,
			from = "Mayen",
			comment = "Amazing, best there's ever been!",
			role = bit.bor(SexyGroup.ROLE_HEALER, SexyGroup.ROLE_TANK), -- Tank, Healer
			dungeon = "Halls of Reflection",
		},
		{
			rating = 3,
			from = "Jerkface",
			comment = "Feh!",
			role = SexyGroup.ROLE_DAMAGE, -- DPS
			dungeon = "Halls of Reflection",
		},
		{
			rating = 2,
			from = "Jerkface",
			comment = "Feh!",
			role = SexyGroup.ROLE_DAMAGE, -- DPS
			dungeon = "Halls of Reflection",
		},
		{
			rating = 1,
			from = "Jerkface",
			comment = "Feh!",
			role = SexyGroup.ROLE_DAMAGE, -- DPS
			dungeon = "Halls of Reflection",
		},
		{
			rating = 0,
			from = "Jerkface",
			comment = "Feh!",
			role = SexyGroup.ROLE_DAMAGE, -- DPS
			dungeon = "Halls of Reflection",
		},
	},
}

--[[
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(self)
	self:UnregisterAllEvents()
	Users:LoadData(TEST_DATA)
end)	
]]

function Users:LoadData(playerData)
	self:CreateUI()
	
	local frame = self.frame
	-- Build score as well as figure out their score
	local totalEquipped, totalScore, mainLevel, offLevel = 0, 0, 0, 0
	for _, slot in pairs(frame.gearFrame.equipSlots) do
		if( slot.inventoryID and playerData.items[slot.inventorySlot] ) then
			local itemLink = playerData.items[slot.inventorySlot]
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
	
	-- Not sure how this will be implemented yet
	frame.gearFrame.equipSlots[18].icon:SetTexture("Interface\\Icons\\INV_JewelCrafting_Gem_42")
	frame.gearFrame.equipSlots[18].levelText:SetFormattedText(L["|T%s:14:14|t Enchants"], READY_CHECK_READY_TEXTURE)
	frame.gearFrame.equipSlots[18].typeText:SetFormattedText(L["|T%s:14:14|t Gems"], READY_CHECK_NOT_READY_TEXTURE)
	
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

	local scanAge = (time() - SexyGroup:ConvertToSeconds(playerData.scanned)) / 3600
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

			local ratingPercent = note.rating / SexyGroup.MAX_RATING
			local r = (ratingPercent > 0.5 and (1.0 - ratingPercent) * 2 or 1.0) * 255
			local g = (ratingPercent > 0.5 and 1.0 or ratingPercent * 2) * 255
			
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
			local difficulty = 1.0 - ((score - SexyGroup.DUNGEON_MIN) / SexyGroup.DUNGEON_DIFF)
			local r = (difficulty > 0.5 and (1.0 - difficulty) * 2 or 1.0) * 255
			local g = (difficulty > 0.5 and 1.0 or difficulty * 2) * 255
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
			GameTooltip:SetText(self.tooltip, nil, nil, nil, nil, true)
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
	frame.achievementFrame.scroll:SetScript("OnVerticalScroll", function(self, value) FauxScrollFrame_OnVerticalScroll(self, value, 46, Users.UpdateAchievementInfo) end)

	frame.achievementFrame.rows = {}
	for i=1, MAX_ACHIEVEMENT_ROWS do
		local button = CreateFrame("Frame", nil, frame.achievementFrame)
		button:SetScript("OnEnter", OnEnter)
		button:SetScript("OnLeave", OnLeave)
		button:EnableMouse(true)
		button:SetHeight(16)
		button:SetWidth(frame.achievementFrame:GetWidth() - 24)
		button.infoText = button:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		button.infoText:SetHeight(16)
		button.infoText:SetJustifyH("LEFT")
		button.infoText:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
		button.infoText:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)

		button.detailsText = button:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		button.detailsText:SetHeight(16)
		button.detailsText:SetJustifyH("LEFT")
		button.detailsText:SetJustifyV("TOP")
		button.detailsText:SetPoint("TOPLEFT", button.infoText, "BOTTOMLEFT", 0, 0)
		button.detailsText:SetPoint("TOPRIGHT", button.infoText, "BOTTOMRIGHT", 0, 0)

		if( i > 1 ) then
			button:SetPoint("TOPLEFT", frame.achievementFrame.rows[i - 1], "BOTTOMLEFT", 0, -4)
		else
			button:SetPoint("TOPLEFT", frame.achievementFrame, "TOPLEFT", 4, -2)
		end
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

