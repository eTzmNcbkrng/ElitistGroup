local ElitistGroup = select(2, ...)
local Summary = ElitistGroup:NewModule("PartySummary", "AceEvent-3.0")
local L = ElitistGroup.L
local buttonList = {"playerInfo", "talentInfo", "trustedInfo", "notesInfo", "gearInfo", "enchantInfo", "gemInfo"}
local notesRequested, unitToRow = {}, {}
local activeGroupID

function Summary:OnInitialize()
	self:RegisterEvent("PLAYER_ROLES_ASSIGNED")
	self:RegisterEvent("UNIT_NAME_UPDATE")
	self:RegisterMessage("SG_DATA_UPDATED")
end

-- My theory with this event, and from looking is it seems to only fire when you are using the LFD system
-- it also seems to only fire once you have data. If your group changes, in theory! It will also refire this event once data is available because someone left etc
function Summary:PLAYER_ROLES_ASSIGNED()
	if( select(2, IsInInstance()) ~= "party" ) then return end
	
	local groupID, notes = ""
	for i=1, GetNumPartyMembers() do
		local guid = UnitGUID("party" .. i)
		if( guid ) then
			groupID = groupID .. guid
			
			if( ElitistGroup.db.profile.database.autoNotes and IsInGuild() and not notesRequested[guid] ) then
				notesRequested[guid] = true
				local name = ElitistGroup:GetPlayerID("party" .. i)
				if( name ) then					if( notes ) then
						notes = notes .. "@" .. name
					else
						notes = name
					end
				end
			end
		end
	end	
	if( activeGroupID == groupID or GetNumPartyMembers() < 4 ) then return end
	activeGroupID = groupID
	
	-- Send a note request for people
	if( notes ) then
		ElitistGroup.modules.Sync:CommMessage(string.format("REQNOTES@%s", notes), "GUILD")
	end
	
	-- Setup the actual UI
	if( ElitistGroup.db.profile.general.autoSummary and not InCombatLockdown() ) then
		self:Show()
	else
		ElitistGroup.modules.Scan:QueueGroup("party", GetNumPartyMembers())
	end
end

function Summary:Show()
	ElitistGroup.modules.Sync:CommMessage("REQGEAR", "RAID")
	ElitistGroup.modules.Scan:QueueGroup("party", GetNumPartyMembers())
	
	self:CreateUI()
	self.frame:SetHeight(35 + (140 * math.ceil(GetNumPartyMembers() / 2)))
	self.frame:SetWidth(30 + (175 * math.ceil(GetNumPartyMembers() / 2)))
	self.frame:Show()
	
	for _, row in pairs(self.summaryRows) do row:Hide() end
	for i=1, GetNumPartyMembers() do
		local row = self:CreateSingle(i)
		row.unitID = "party" .. i
		row:Show()
	end
end

function Summary:UNIT_NAME_UPDATE(event, unit)
	if( unitToRow[unit] and unitToRow[unit]:IsVisible() ) then
		self:UpdateSingle(unitToRow[unit])
	end
end

function Summary:SG_DATA_UPDATED(event, type, name)
	for unit, row in pairs(unitToRow) do
		if( row:IsVisible() and ElitistGroup:GetPlayerID(unit) == name ) then
			self:UpdateSingle(row)
		end
	end
end

local buttonList = {"playerInfo", "notesInfo", "talentInfo", "trustedInfo", "gearInfo", "enchantInfo", "gemInfo"}
function Summary:UpdateSingle(row)
	if( not row.unitID or not UnitExists(row.unitID) ) then
		row:Hide()
		return
	end
	
	local playerID = ElitistGroup:GetPlayerID(row.unitID)
	local userData = ElitistGroup.userData[playerID]
	local level = UnitLevel(row.unitID)
	local classToken = select(2, UnitClass(row.unitID))
	local name, server = UnitName(row.unitID)
	server = server and server ~= "" and server or GetRealmName()

	local position = ElitistGroup.modules.Scan:UnitQueuePosition(row.unitID)
	local positionTooltip = position and string.format(L[", #%d in inspect queue"], position) or ""
	position = position and string.format("[#%d] ", position) or ""
	
	-- Build the players info
	local coords = CLASS_BUTTONS[classToken]
	if( coords ) then
		row.playerInfo:SetFormattedText("%s%s (%s)", position, name, level)
		row.playerInfo.tooltip = string.format(L["%s - %s, level %s %s%s"], name, server, level, LOCALIZED_CLASS_NAMES_MALE[classToken], positionTooltip)
		row.playerInfo.icon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
		row.playerInfo.icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
	else
		row.playerInfo:SetFormattedText("%s (%s)", position, name, level)
		row.playerInfo.tooltip = string.format(L["%s - %s, level %s, unknown class%s"], name, server, level, positionTooltip)
		row.playerInfo.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
	end
	
	row.playerInfo.playerID = userData and playerID or nil
	
	-- No data yet, show the basic info then tell them we're loading
	if( not userData ) then
		for _, key in pairs(buttonList) do
			if( key ~= "playerInfo" ) then
				row[key]:SetText(L["Loading"])
				row[key].icon:SetTexture(READY_CHECK_WAITING_TEXTURE)
			end
		end
	else
		-- Setup notes
		local totalNotes = 0
		for _, note in pairs(userData.notes) do totalNotes = totalNotes + 1 end
		
		-- Player personally left a note on the person
		local playerNote = userData.notes[ElitistGroup.playerName]
		if( playerNote ) then
			local noteAge = (time() - playerNote.time) / 60
			if( noteAge < 60 ) then
				noteAge = string.format(L["%d |4minute:minutes;"], noteAge)
			elseif( noteAge < 1440 ) then
				noteAge = string.format(L["%d |4hour:hours;"], noteAge / 60)
			else
				noteAge = string.format(L["%d |4day:days;"], noteAge / 1440)
			end
			
			row.notesInfo:SetFormattedText(L["Rated %d of %d"], playerNote.rating, ElitistGroup.MAX_RATING)
			row.notesInfo.icon:SetTexture(READY_CHECK_READY_TEXTURE)
			row.notesInfo.tooltip = string.format(L["You wrote %s ago:\n|cffffffff%s|r"], noteAge, playerNote.comment or L["No comment"])
		-- We haven't, but somebody else has left a note on them
		elseif( totalNotes > 0 ) then
			row.notesInfo:SetFormattedText("%d |4note:notes; found", string.format(L["%d notes found"], totalNotes))
			row.notesInfo.icon:SetTexture(READY_CHECK_READY_TEXTURE)
			row.notesInfo.tooltip = L["Other players have left a note on this person."]
		else
			row.notesInfo:SetText(L["No notes found"])
			row.notesInfo.icon:SetTexture(READY_CHECK_NOT_READY_TEXTURE)
			row.notesInfo.tooltip = L["No notes were found for this player."]
		end
		
		-- Make sure they are talented enough
		local specType, specName, specIcon = ElitistGroup:GetPlayerSpec(userData)
		if( not userData.unspentPoints ) then
			row.talentInfo:SetFormattedText("%d/%d/%d (%s)", userData.talentTree1, userData.talentTree2, userData.talentTree3, specName)
			row.talentInfo.icon:SetTexture(specIcon)
			row.talentInfo.tooltip = string.format(L["%s, %s role."], specName, ElitistGroup.TALENT_ROLES[specType])
		else
			row.talentInfo:SetFormattedText(L["%d unspent |4point:points;"], userData.unspentPoints)
			row.talentInfo.icon:SetTexture(specIcon)
			row.talentInfo.tooltip = string.format(L["%s, %s role.\n\nThis player has not spent all of their talent points!"], specName, ElitistGroup.TALENT_ROLES[specType])
		end
		
		-- Add trusted info of course
		if( userData.trusted ) then
			row.trustedInfo:SetFormattedText(L["%s (Trusted)"], string.match(userData.from, "(.-)%-"))
			row.trustedInfo.tooltip = L["Data for this player is from a verified source and can be trusted."]
			row.trustedInfo.icon:SetTexture(READY_CHECK_READY_TEXTURE)
		else
			row.trustedInfo:SetFormattedText(L["%s (Untrusted)"], string.match(userData.from, "(.-)%-"))
			row.trustedInfo.tooltip = L["While the player data should be accurate, it is not guaranteed as the source is unverified."]
			row.trustedInfo.icon:SetTexture(READY_CHECK_NOT_READY_TEXTURE)
		end
		
		local equipmentData, enchantData, gemData = ElitistGroup:GetGearSummary(userData)
		local gemTooltip, enchantTooltip = ElitistGroup:GetGeneralSummaryTooltip(gemData, enchantData)
		
		-- People probably want us to build the gear info, I'd imagine
		if( equipmentData.totalBad == 0 ) then
			row.gearInfo:SetFormattedText(L["Equipment (%d)"], equipmentData.totalScore)
			row.gearInfo.icon:SetTexture(READY_CHECK_READY_TEXTURE)
			row.gearInfo.tooltip = string.format(L["Equipment: |cffffffffAll good|r"], equipmentData.totalEquipped)
		else
			local gearTooltip = string.format(L["Equipment: |cffffffff%d bad items found|r"], equipmentData.totalBad)
			for _, itemLink in pairs(userData.equipment) do
				local fullItemLink = select(2, GetItemInfo(itemLink))
				if( fullItemLink and equipmentData[itemLink] ) then
					gearTooltip = gearTooltip .. "\n" .. string.format(L["%s - %s item"], fullItemLink, ElitistGroup.TALENT_TYPES[equipmentData[itemLink]] or equipmentData[itemLink])
				end
			end

			row.gearInfo:SetFormattedText(L["Equipment (%d)"], equipmentData.totalScore)
			row.gearInfo.icon:SetTexture(READY_CHECK_NOT_READY_TEXTURE)
			row.gearInfo.tooltip = gearTooltip
		end
		
		-- Build enchants
		if( not enchantData.noData ) then
			row.enchantInfo:SetText(L["Enchants"])
			row.enchantInfo.icon:SetTexture(enchantData.pass and READY_CHECK_READY_TEXTURE or READY_CHECK_NOT_READY_TEXTURE)
			row.enchantInfo.tooltip = enchantTooltip
			row.enchantInfo.disableWrap = not enchantData.noData
		else
			row.enchantInfo:SetText(L["Enchants"])
			row.enchantInfo.icon:SetTexture(READY_CHECK_WAITING_TEXTURE)
			row.enchantInfo.tooltip = L["No enchants found."]
			row.enchantInfo.disableWrap = nil
		end

		-- Build gems
		if( not gemData.noData ) then
			row.gemInfo:SetText(L["Gems"])
			row.gemInfo.icon:SetTexture(gemData.pass and READY_CHECK_READY_TEXTURE or READY_CHECK_NOT_READY_TEXTURE)
			row.gemInfo.tooltip = gemTooltip
			row.gemInfo.disableWrap = not gemData.noData
		else
			row.gemInfo:SetText(L["Gems"])
			row.gemInfo.icon:SetTexture(READY_CHECK_WAITING_TEXTURE)
			row.gemInfo.tooltip = L["No gems found. It is possible data failed to load, however it is more likely the player has no gems."]
			row.gemInfo.disableWrap = nil
		end

		ElitistGroup:ReleaseTables(equipmentData, enchantData, gemData)
	end
end


local function OnShow(self)
	if( self.unitID ) then
		unitToRow[self.unitID] = self
		Summary:UpdateSingle(self)
	end
end

local function OnHide(self)
	if( self.unitID ) then
		unitToRow[self.unitID] = nil
	end
end

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

local function OnClick(self)
	local userData = ElitistGroup.userData[self.playerID]
	if( userData ) then
		ElitistGroup.modules.Users:LoadData(userData)
	end
end

local backdrop = {bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeSize = 1}
function Summary:CreateSingle(id)
	if( self.summaryRows[id] ) then
		return self.summaryRows[id]
	end
	
	-- User data container
	local row = CreateFrame("Frame", nil, self.frame)   
	row:SetBackdrop(backdrop)
	row:SetBackdropBorderColor(0.60, 0.60, 0.60, 1)
	row:SetBackdropColor(0, 0, 0, 0)
	row:SetWidth(175)
	row:SetHeight(135)
	row:Hide()
	row:SetScript("OnShow", OnShow)
	row:SetScript("OnHide", OnHide)

	for i, key in pairs(buttonList) do
		local button = CreateFrame("Button", nil, row)
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
		button:GetFontString():SetWidth(row:GetWidth() - 23)
		button:GetFontString():SetHeight(15)
		
		if( i > 1 ) then
			button:SetPoint("TOPLEFT", row[buttonList[i - 1]], "BOTTOMLEFT", 0, -4)
			button:SetPoint("TOPRIGHT", row[buttonList[i - 1]], "BOTTOMRIGHT", 0, -4)
		else
			button:SetPoint("TOPLEFT", row, "TOPLEFT", 3, -4)
			button:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
		end
		
		row[key] = button
	end
	
	row.playerInfo:SetPushedTextOffset(2, -2)
	row.playerInfo:SetScript("OnClick", OnClick)
	
	row.gemInfo.disableWrap = true
	row.enchantInfo.disableWrap = true
	row.gearInfo.disableWrap = true
	
	if( id == 3 ) then
		row:SetPoint("TOPLEFT", self.summaryRows[1], "BOTTOMLEFT", 0, -5)
	elseif( id > 1 ) then
		row:SetPoint("TOPLEFT", self.summaryRows[id - 1], "TOPRIGHT", 5, 0)
	else
		row:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 12, -28)
	end
	
	self.summaryRows[id] = row
	return row
end

function Summary:CreateUI()
	if( self.frame ) then
		self.frame:Show()
		return
	end

	self.summaryRows = {}
	
	-- Main container
	local frame = CreateFrame("Frame", "ElitistGroupPartySummaryFrame", UIParent)
	frame:SetClampedToScreen(true)
	frame:RegisterForDrag("LeftButton", "RightButton")
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetToplevel(true)
	frame:SetScript("OnHide", function() ElitistGroup:ReleaseTables(equipmentData, enchantData, gemData) end)
	frame:SetScript("OnDragStart", function(self, mouseButton)
		if( mouseButton == "RightButton" ) then
			frame:ClearAllPoints()
			frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
			ElitistGroup.db.profile.positions.summary = nil
			return
		end
		
		self:StartMoving()
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		
		local scale = self:GetEffectiveScale()
		ElitistGroup.db.profile.positions.summary = {x = self:GetLeft() * scale, y = self:GetTop() * scale}
	end)
	frame:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		edgeSize = 26,
		insets = {left = 9, right = 9, top = 9, bottom = 9},
	})
	frame:SetBackdropColor(0, 0, 0, 0.90)
	
	table.insert(UISpecialFrames, "ElitistGroupPartySummaryFrame")
	
	if( ElitistGroup.db.profile.positions.summary ) then
		local scale = frame:GetEffectiveScale()
		frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", ElitistGroup.db.profile.positions.summary.x / scale, ElitistGroup.db.profile.positions.summary.y / scale)
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

	-- Close button
	local button = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	button:SetPoint("TOPRIGHT", -3, -3)
	button:SetHeight(28)
	button:SetWidth(28)
	button:SetScript("OnClick", function() frame:Hide() end)

	self.frame = frame
end