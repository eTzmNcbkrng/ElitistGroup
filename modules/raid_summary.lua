local ElitistGroup = select(2, ...)
local Summary = ElitistGroup:NewModule("RaidSummary", "AceEvent-3.0")
local L = ElitistGroup.L
local headerKeys = {"name", "average", "rating", "equipment", "enchants", "gems"}
local headerNames = {["name"] = L["Name"], ["average"] = L["Average"], ["rating"] = L["Rating"], ["equipment"] = L["Equipment"], ["enchants"] = L["Enchants"], ["gems"] = L["Gems"]}
local userSummaryData, sortedData, queuedUnits = {}, {}, {}
local MAX_SUMMARY_ROWS = 10

function Summary:Show()
	local inInstance, instanceType = IsInInstance()
	if( instanceType == "pvp" or instanceType == "arena" ) then
		ElitistGroup.modules.Sync:CommMessage("REQGEAR", "BATTLEGROUND")
	elseif( GetNumRaidMembers() > 0 ) then
		ElitistGroup.modules.Sync:CommMessage("REQGEAR", "RAID")
	end
	
	if( inInstance ) then
		ElitistGroup.modules.Scan:QueueGroup("raid", GetNumRaidMembers())
	end
	
	self:RAID_ROSTER_UPDATE()
	self:CreateUI()
	self:Update()
end

-- Handle data caching
function Summary:CacheUnit(unit)
	local playerID = ElitistGroup:GetPlayerID(unit)
	-- Unknown name, wait until we get an update then will recache
	if( not playerID ) then
		queuedUnits[unit] = true
		self:RegisterEvent("UNIT_NAME_UPDATE")
	-- No data, cache gogogogo!
	elseif( not userSummaryData[playerID] ) then
		local name, server = UnitName(unit)
		userSummaryData[playerID] = {name = name, totalRatings = 0, rating = -1, average = -1,  totalEquipment = 0, equipment = -1, enchants = -1, totalEnchants = 0, gems = -1, totalGems = 0, classToken = select(2, UnitClass(unit)), fullName = server and server ~= "" and string.format("%s-%s", name, server) or name}
		table.insert(sortedData, playerID)
		
		if( ElitistGroup.userData[playerID] ) then
			self:SG_DATA_UPDATED(nil, nil, playerID)
		elseif( not ElitistGroup.modules.Scan:UnitIsQueued(unit) ) then
			ElitistGroup.modules.Scan:QueueUnit(unit)
			ElitistGroup.modules.Scan:ProcessQueue()
		end
	end
	
	userSummaryData[playerID].unit = unit
end

-- This is only registered while the UI is open
function Summary:SG_DATA_UPDATED(event, type, name)
	local summaryData = userSummaryData[name]
	local userData = ElitistGroup.userData[name]
	if( summaryData and userData ) then
		local equipmentData, enchantData, gemData = ElitistGroup:GetGearSummary(userData)
		local gemTooltip, enchantTooltip = ElitistGroup:GetGeneralSummaryTooltip(gemData, enchantData)
	
		if( equipmentData.totalBad ) then
			summaryData.equipmentTooltip = string.format(L["|cffffffff%d bad items found|r"], equipmentData.totalBad)
			for _, itemLink in pairs(userData.equipment) do
				local fullItemLink = select(2, GetItemInfo(itemLink))
				if( fullItemLink and equipmentData[itemLink] ) then
					summaryData.equipmentTooltip = summaryData.equipmentTooltip .. "\n" .. string.format(L["%s - %s item"], fullItemLink, ElitistGroup.Items.itemRoleText[equipmentData[itemLink]] or equipmentData[itemLink])
				end
			end
		end
		
		summaryData.totalEquipment = equipmentData.totalEquipped
		summaryData.equipment = equipmentData.totalBad
		summaryData.totalEnchants = enchantData.total
		summaryData.enchants = enchantData.totalBad
		summaryData.enchantTooltip = enchantTooltip
		summaryData.totalGems = gemData.total
		summaryData.gems = gemData.totalBad
		summaryData.gemTooltip = gemTooltip
		summaryData.average = math.floor(equipmentData.totalScore)
		summaryData.rating = 0
		summaryData.totalRatings = 0
		
		for _, note in pairs(userData.notes) do
			summaryData.totalRatings = summaryData.totalRatings + 1
			summaryData.rating = summaryData.rating + note.rating
		end
		
		summaryData.rating = summaryData.rating / summaryData.totalRatings
		ElitistGroup:ReleaseTables(equipmentData, enchantData, gemData)
		
		if( event and type ) then
			self:Update()
		end
	end
end

function Summary:UNIT_NAME_UPDATE(event, unit)
	if( queuedUnits[unit] ) then
		queuedUnits[unit] = nil
		self:CacheUnit(unit)
		self:Update()
		
		local haveUnits
		for _, unit in pairs(queuedUnits) do haveUnits = true break end
		if( not haveUnits ) then
			self:UnregisterEvent("UNIT_NAME_UPDATE")
		end
	end
end

-- This is only registered while the UI is open
function Summary:RAID_ROSTER_UPDATE()
	if( GetNumRaidMembers() == 0 ) then
		userSummaryData = nil
		table.wipe(sortedData)
		return
	elseif( not userSummaryData ) then
		userSummaryData = {}
	end
	
	-- Remove any people who have left
	for name, data in pairs(userSummaryData) do
		if( not UnitExists(data.fullName) ) then
			userSummaryData[name] = nil
			
			for i=#(sortedData), 1, -1 do
				if( sortedData[i] == name ) then
					table.remove(sortedData, i)
					break
				end
			end
		end
	end

	if( not InCombatLockdown() ) then
		for i=1, GetNumRaidMembers() do
			self:CacheUnit("raid" .. i)
		end
	end
end

-- Build the visual portions
local function sortUserData(a, b)
	if( Summary.sortOrder ) then
		return userSummaryData[a][Summary.sortType] < userSummaryData[b][Summary.sortType]
	else
		return userSummaryData[a][Summary.sortType] > userSummaryData[b][Summary.sortType]
	end
end

function Summary:Update()
	self = Summary

	if( not self.scrollUpdate ) then
		table.sort(sortedData, sortUserData)
	end
	
	local queueSize = ElitistGroup.modules.Scan:QueueSize()
	if( not IsInInstance() ) then
		self.frame.inspectQueue:SetText(L["Inspecting only in an instance"])
	elseif( queueSize == 0 ) then
		self.frame.inspectQueue:SetText(L["Inspect queue empty"])
	else
		self.frame.inspectQueue:SetFormattedText(L["Queue: %d players left"], queueSize)
	end
	
	FauxScrollFrame_Update(self.frame.scroll, #(sortedData), MAX_SUMMARY_ROWS, 24)
	local offset = FauxScrollFrame_GetOffset(self.frame.scroll)
		
	for id, row in pairs(self.frame.rows) do
		local name = sortedData[id + offset]
		if( name ) then
			local summaryData = userSummaryData[name]
			local userData = ElitistGroup.userData[name]
			
			local classColor = RAID_CLASS_COLORS[summaryData.classToken]
			
			if( classColor ) then
				row.name:SetFormattedText("|cff%02x%02x%02x%s|r", classColor.r * 255, classColor.g * 255, classColor.b * 255, summaryData.name)
				row.name.tooltip = string.format(L["%s, %s"], name, LOCALIZED_CLASS_NAMES_MALE[summaryData.classToken])
			else
				row.name:SetFormattedText("|cffffffff%s|r", summaryData.name)
				row.name.tooltip = string.format(L["%s, unknown class"], name)
			end

			if( userData ) then
				row.name.playerID = name
				row.name.tooltip = row.name.tooltip .. "\n" .. L["Click to view detailed information."]
				
				if( summaryData.average >= 0 ) then
					local quality = summaryData.average >= 210 and ITEM_QUALITY_EPIC or summaryData.average >= 195 and ITEM_QUALITY_RARE or summaryData.average >= 170 and ITEM_QUALITY_UNCOMMON or ITEM_QUALITY_COMMON
					row.average:SetFormattedText("%s%d|r", ITEM_QUALITY_COLORS[quality].hex, summaryData.average)
					row.average.tooltip = L["Average item level of the players equipment."]
				else
					row.average:SetText("---")
					row.average.tooltip = L["Could not calculate average item level, no data found."]
				end
					
				if( summaryData.totalRatings > 0 ) then
					row.rating:SetFormattedText("%.1f", summaryData.rating) 
					row.rating.tooltip = string.format(L["Average rating %.2f of %d, rated %d times."], summaryData.rating, ElitistGroup.MAX_RATING, summaryData.totalRatings)
				else
					row.rating:SetText("---")
					row.rating.tooltip = L["No rating data on this player found."]
				end
				
				row.equipment.disableWrap = nil
				row.enchants.disableWrap = nil
				row.gems.disableWrap = nil
				
				if( summaryData.equipment == -1 ) then
					row.equipment:SetText(L["Loading"])
					row.equipment.tooltip = L["Loading data"]
				elseif( summaryData.equipment == 0 ) then
					row.equipment:SetText("|cff20ff20100%|r")
					row.equipment.tooltip = L["Nothing is wrong with this players equipment!"]
				else
					local percent = math.min(1, (summaryData.totalEquipment - summaryData.equipment) / summaryData.totalEquipment)
					local r = (percent > 0.5 and (1.0 - percent) * 2 or 1.0) * 255
					local g = (percent > 0.5 and 1.0 or percent * 2) * 255

					row.equipment:SetFormattedText("|cff%02x%02x00%d%%|r", r, g, percent * 100)
					row.equipment.tooltip = summaryData.equipmentTooltip
					row.equipment.disableWrap = true
				end

				if( summaryData.enchants == -1 ) then
					row.enchants:SetText(L["Loading"])
					row.enchants.tooltip = L["Loading data"]
				elseif( summaryData.enchants == 0 ) then
					row.enchants:SetText("|cff20ff20100%|r")
					row.enchants.tooltip = L["Nothing is wrong with this players enchants!"]
				else
					local percent = math.min(1, (summaryData.totalEnchants - summaryData.enchants) / summaryData.totalGems)
					local r = (percent > 0.5 and (1.0 - percent) * 2 or 1.0) * 255
					local g = (percent > 0.5 and 1.0 or percent * 2) * 255

					row.enchants:SetFormattedText("|cff%02x%02x00%d%%|r", r, g, percent * 100)
					row.enchants.tooltip = summaryData.enchantTooltip
					row.enchants.disableWrap = true
				end

				if( summaryData.gems == -1 ) then
					row.gems:SetText(L["Loading"])
					row.gems.tooltip = L["Loading data"]
				elseif( summaryData.gems == 0 ) then
					row.gems:SetText("|cff20ff20100%|r")
					row.gems.tooltip = L["Nothing is wrong with this players gems!"]
				else
					local percent = math.min(1, (summaryData.totalGems - summaryData.gems) / summaryData.totalGems)
					local r = (percent > 0.5 and (1.0 - percent) * 2 or 1.0) * 255
					local g = (percent > 0.5 and 1.0 or percent * 2) * 255

					row.gems:SetFormattedText("|cff%02x%02x00%d%%|r", r, g, percent * 100)
					row.gems.tooltip = summaryData.gemTooltip
					row.gems.disableWrap = true
				end
			else
				row.name.playerID = nil
				row.name.tooltip = row.name.tooltip .. "\n" .. L["User data not available yet."]

				row.average:SetText(L["Loading"])
				row.average.tooltip = L["Loading data"]
				row.rating:SetText("---")
				row.rating.tooltip = L["Loading data"]
				row.equipment:SetText(L["---"])
				row.equipment.tooltip = L["Loading data"]
				row.enchants:SetText(L["--"])
				row.enchants.tooltip = L["Loading data"]
				row.gems:SetText(L["---"])
				row.gems.tooltip = L["Loading data"]
			end
			
			for _, button in pairs(row) do
				button:Show()
			end
		else
			for _, button in pairs(row) do
				button:Hide()
			end
		end
	end
end

function Summary:CreateUI()
	if( self.frame ) then
		self.frame:Show()
		return
	end
	
	Summary.sortType = "name"
	Summary.sortOrder = true

	local function OnEnter(self)
		if( self.tooltip ) then
			GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
			GameTooltip:SetText(self.tooltip, nil, nil, nil, nil, not self.disableWrap)
			GameTooltip:Show()
		end
	end

	local function OnLeave(self)
		GameTooltip:Hide()
	end
	
	-- Main container
	local frame = CreateFrame("Frame", "ElitistGroupRaidSummaryFrame", UIParent)
	frame:SetClampedToScreen(true)
	frame:RegisterForDrag("LeftButton", "RightButton")
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetToplevel(true)
	frame:SetHeight(300)
	frame:SetWidth(545)
	frame:Hide()
	frame:SetScript("OnShow", function(self)
		Summary:RegisterMessage("SG_DATA_UPDATED")
		Summary:RegisterEvent("RAID_ROSTER_UPDATE")
	end)
	frame:SetScript("OnHide", function()
		Summary:UnregisterMessage("SG_DATA_UPDATED")
		Summary:UnregisterEvent("RAID_ROSTER_UPDATE")
	end)
	frame:SetScript("OnDragStart", function(self, mouseButton)
		if( mouseButton == "RightButton" ) then
			frame:ClearAllPoints()
			frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
			ElitistGroup.db.profile.positions.raidsummary = nil
			return
		end
		
		self:StartMoving()
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		
		local scale = self:GetEffectiveScale()
		ElitistGroup.db.profile.positions.raidsummary = {x = self:GetLeft() * scale, y = self:GetTop() * scale}
	end)
	frame:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		edgeSize = 26,
		insets = {left = 9, right = 9, top = 9, bottom = 9},
	})
	frame:SetBackdropColor(0, 0, 0, 0.90)
	
	table.insert(UISpecialFrames, "ElitistGroupRaidSummaryFrame")
	
	if( ElitistGroup.db.profile.positions.raidsummary ) then
		local scale = frame:GetEffectiveScale()
		frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", ElitistGroup.db.profile.positions.raidsummary.x / scale, ElitistGroup.db.profile.positions.raidsummary.y / scale)
	else
		frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end

	frame.titleBar = frame:CreateTexture(nil, "ARTWORK")
	frame.titleBar:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
	frame.titleBar:SetPoint("TOP", 0, 8)
	frame.titleBar:SetWidth(200)
	frame.titleBar:SetHeight(45)

	frame.title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	frame.title:SetPoint("TOP", 0, 0)
	frame.title:SetText("Elitist Group")

	frame.inspectQueue = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	frame.inspectQueue:SetPoint("TOPLEFT", frame, "TOPLEFT", 11, -14)

	-- Close button
	local button = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	button:SetPoint("TOPRIGHT", -3, -3)
	button:SetHeight(28)
	button:SetWidth(28)
	button:SetScript("OnClick", function() frame:Hide() end)
	
	local function sortRows(self)
		if( Summary.sortType == self.sortType ) then
			Summary.sortOrder = not Summary.sortOrder
		else
			Summary.sortType = self.sortType
			Summary.sortOrder = true
		end
		
		Summary:Update()
	end

	frame.headers = {}
	for _, key in pairs(headerKeys) do
	   local headerButton = CreateFrame("Button", nil, frame)
	   headerButton:SetNormalFontObject(GameFontNormal)
	   headerButton:SetHighlightFontObject(GameFontHighlight)
	   headerButton:SetDisabledFontObject(GameFontDisable)
	   headerButton:SetText(headerNames[key])
	   headerButton:GetFontString():SetPoint("LEFT", 3, 0)
	   headerButton:SetHeight(20)
	   headerButton:SetScript("OnClick", sortRows)
	   headerButton.sortType = key
	   
	   frame.headers[key] = headerButton
	end

	frame.headers.name:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -30)
	frame.headers.name:SetWidth(135)
	frame.headers.average:SetPoint("TOPLEFT", frame.headers.name, "TOPRIGHT", 5, 0)
	frame.headers.average:SetWidth(60)
	frame.headers.rating:SetPoint("TOPLEFT", frame.headers.average, "TOPRIGHT", 15, 0)
	frame.headers.rating:SetWidth(45)
	frame.headers.equipment:SetPoint("TOPLEFT", frame.headers.rating, "TOPRIGHT", 20, 0)
	frame.headers.equipment:SetWidth(75)
	frame.headers.enchants:SetPoint("TOPLEFT", frame.headers.equipment, "TOPRIGHT", 15, 0)
	frame.headers.enchants:SetWidth(60)
	frame.headers.gems:SetPoint("TOPLEFT", frame.headers.enchants, "TOPRIGHT", 15, 0)
	frame.headers.gems:SetWidth(55)

	frame.scroll = CreateFrame("ScrollFrame", "ElitistGroupRaidSummaryScroll", frame, "FauxScrollFrameTemplate")
	frame.scroll.bar = ElitistGroupUserFrameScroll
	frame.scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -32)
	frame.scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -33, 10)
	frame.scroll:SetScript("OnVerticalScroll", function(self, value) Summary.scrollUpdate = true; FauxScrollFrame_OnVerticalScroll(self, value, 24, Summary.Update); Summary.scrollUpdate = nil end)
	
	local function viewDetailedInfo(self)
		local userData = self.playerID and ElitistGroup.userData[self.playerID]
		if( userData ) then
			ElitistGroup.modules.Users:Toggle(userData)
		end
	end
	
	frame.rows = {}
	for i=1, MAX_SUMMARY_ROWS do
		local row = {}
		for keyID, key in pairs(headerKeys) do
			local button = CreateFrame("Button", nil, frame)
			button:SetNormalFontObject(GameFontHighlight)
			button:SetPushedTextOffset(0, 0)
			button:SetFormattedText("*")
			button:SetHeight(22)
			button:SetScript("OnEnter", OnEnter)
			button:SetScript("OnLeave", OnLeave)
			
			local fontString = button:GetFontString()
			fontString:SetPoint("TOPLEFT", 0, 0)
			fontString:SetPoint("BOTTOMRIGHT", 0, 0)
			fontString:SetJustifyH("LEFT")
			fontString:SetJustifyV("CENTER")      

			if( i > 1 ) then
				button:SetPoint("TOPLEFT", frame.rows[i - 1][key], "BOTTOMLEFT", 0, -2)
				button:SetPoint("TOPRIGHT", frame.rows[i - 1][key], "BOTTOMRIGHT", 0, -2)
			else
				button:SetPoint("TOPLEFT", frame.headers[key], "BOTTOMLEFT", 3, -2)
				button:SetPoint("TOPRIGHT", frame.headers[key], "BOTTOMRIGHT", 0, -2)
			end

			row[key] = button
		end
		
		row.name:SetScript("OnClick", viewDetailedInfo)
		row.name:SetPushedTextOffset(2, -2)
		
		frame.rows[i] = row
	end
	
	-- This isn't really perfect, it's mostly to try and give some sort of "constraint" to the panel so it doesn't look so hackish
	frame.backdropFrame = CreateFrame("Frame", nil, frame)
	frame.backdropFrame:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeSize = 1})
	frame.backdropFrame:SetBackdropBorderColor(0.60, 0.60, 0.60, 1)
	frame.backdropFrame:SetBackdropColor(0, 0, 0, 0)
	frame.backdropFrame:SetPoint("TOPLEFT", frame.headers.name, "TOPLEFT", 0, 0)
	frame.backdropFrame:SetPoint("TOPRIGHT", frame.headers.gems, "TOPRIGHT", 26, 0)
	frame.backdropFrame:SetHeight(261)

	self.frame = frame
	self.frame:Show()
end

