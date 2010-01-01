local SexyGroup = select(2, ...)
local Summary = SexyGroup:NewModule("Summary", "AceEvent-3.0")
local L = SexyGroup.L
local notesRequested, unitToRow = {}, {}
local activeGroupID

function Summary:OnInitialize()
	self:RegisterEvent("PLAYER_ROLES_ASSIGNED")
	self:RegisterEvent("PLAYER_LEAVING_WORLD")
	self:RegisterEvent("UNIT_NAME_UPDATE")
	self:RegisterMessage("SG_DATA_UPDATED")
end

function Summary:PLAYER_LEAVING_WORLD()
	SexyGroup.modules.Scan:ResetQueue()
end

-- My theory with this event, and from looking is it seems to only fire when you are using the LFD system
-- it also seems to only fire once you have data. If your group changes, in theory! It will also refire this event once data is available because someone left etc
function Summary:PLAYER_ROLES_ASSIGNED()
	local groupID, notes = ""
	for i=1, GetNumPartyMembers() do
		local guid = UnitGUID("party" .. i)
		if( guid ) then
			groupID = groupID .. guid
			
			if( SexyGroup.db.profile.database.autoNotes and IsInGuild() and not notesRequested[guid] ) then
				notesRequested[guid] = true
				
				if( notes ) then
					notes = notes .. "@" .. SexyGroup:GetPlayerID("party" .. i)
				else
					notes = SexyGroup:GetPlayerID("party" .. i)
				end
			end
		end
	end
	
	if( activeGroupID == groupID or GetNumPartyMembers() < 4 ) then return end
	activeGroupID = groupID
	
	if( notes ) then
		SexyGroup.modules.Sync:CommMessage(string.format("REQNOTES@%s", notes), "GUILD")
	end
	
	if( SexyGroup.db.profile.general.autoSummary and not InCombatLockdown() ) then
		self:Setup()
	end
	
	for i=1, GetNumPartyMembers() do
		SexyGroup.modules.Scan:QueueAdd("party" .. i)
	end

	SexyGroup.modules.Scan:QueueStart()
end

function Summary:Setup()
	self:CreateUI()
	self.frame:SetHeight(35 + (140 * math.floor(GetNumPartyMembers() / 2)))
	self.frame:SetWidth(30 + (175 * math.floor(GetNumPartyMembers() / 2)))
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
		if( row:IsVisible() and SexyGroup:GetPlayerID(unit) == name ) then
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
	
	local playerID = SexyGroup:GetPlayerID(row.unitID)
	local userData = SexyGroup.userData[playerID]
	local level = UnitLevel(row.unitID)
	local classToken = select(2, UnitClass(row.unitID))
	local name, server = UnitName(row.unitID)
	server = server and server ~= "" and server or GetRealmName()

	-- Build the players info
	local coords = CLASS_BUTTONS[classToken]
	if( coords ) then
		row.playerInfo:SetFormattedText("|TInterface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes:16:16:-1:0:%s:%s:%s:%s:%s:%s|t %s (%s)", 256, 256, coords[1] * 256, coords[2] * 256, coords[3] * 256, coords[4] * 256, name, level)
		row.playerInfo.tooltip = string.format(L["%s - %s, level %s %s."], name, server, level, LOCALIZED_CLASS_NAMES_MALE[classToken])
	else
		row.playerInfo:SetFormattedText("|TInterface\\Icons\\INV_Misc_QuestionMark:16:16:-1:0|t %s (%s)", name, level)
		row.playerInfo.tooltip = string.format(L["%s - %s, level %s, unknown class."], name, server, level)
	end

	-- No data yet, show the basic info then tell them we're loading
	if( not userData ) then
		row.notesInfo:SetFormattedText("|T%s:14:14|t %s", READY_CHECK_WAITING_TEXTURE, L["Loading..."])
		row.trustedInfo:SetFormattedText("|T%s:14:14|t %s", READY_CHECK_WAITING_TEXTURE, L["Loading..."])
		row.talentInfo:SetFormattedText("|T%s:14:14|t %s", READY_CHECK_WAITING_TEXTURE, L["Loading..."])
		row.gearInfo:SetFormattedText("|T%s:14:14|t %s", READY_CHECK_WAITING_TEXTURE, L["Loading..."])
		row.enchantInfo:SetFormattedText("|T%s:14:14|t %s", READY_CHECK_WAITING_TEXTURE, L["Loading..."])
		row.gemInfo:SetFormattedText("|T%s:14:14|t %s", READY_CHECK_WAITING_TEXTURE, L["Loading..."])
	else
		-- Setup notes
		local totalNotes = 0
		for _, note in pairs(userData.notes) do totalNotes = totalNotes + 1 end
		
		-- Player personally left a note on the person
		local playerNote = userData.notes[SexyGroup.playerName]
		if( playerNote ) then
			local noteAge = (time() - playerNote.time) / 60
			if( noteAge < 60 ) then
				noteAge = string.format(L["%d minutes"], noteAge)
			elseif( noteAge < 1440 ) then
				noteAge = string.format(L["%d hours"], noteAge / 60)
			else
				noteAge = string.format(L["%d days"], noteAge / 1440)
			end
			
			row.notesInfo:SetFormattedText("|T%s:14:14|t %s", READY_CHECK_READY_TEXTURE, string.format(L["Rated %d of %d"], playerNote.rating, SexyGroup.MAX_RATING))
			row.notesInfo.tooltip = string.format(L["You wrote %s ago:\n|cffffffff%s|r"], noteAge, playerNote.comment or L["No comment"])
		-- We haven't, but somebody else has left a note on them
		elseif( totalNotes > 0 ) then
			row.notesInfo:SetFormattedText("|T%s:14:14|t %s", READY_CHECK_READY_TEXTURE, string.format(L["%d notes found"], totalNotes))
			row.notesInfo.tooltip = L["Other players have left a note on this person."]
		else
			row.notesInfo:SetFormattedText("|T%s:14:14|t %s", READY_CHECK_NOT_READY_TEXTURE, L["No notes found"])
			row.notesInfo.tooltip = L["No notes were found for this player."]
		end
		
		-- Make sure they are talented enough
		local specType, specName, specIcon = SexyGroup:GetPlayerSpec(userData)
		if( not userData.unspentPoints ) then
			row.talentInfo:SetFormattedText("|T%s:16:16:-1:0|t %d/%d/%d (%s)", specIcon, userData.talentTree1, userData.talentTree2, userData.talentTree3, specName)
			row.talentInfo.tooltip = string.format(L["%s, %s role."], specName, SexyGroup.TALENT_ROLES[specType])
		else
			row.talentInfo:SetFormattedText("|T%s:16:16:-1:0|t %d %s", specIcon, userData.unspentPoints, L["unspent points"])
			row.talentInfo.tooltip = string.format(L["%s, %s role.\n\nThis player has not spent all of their talent points!"], specName, SexyGroup.TALENT_ROLES[specType])
		end
		
		-- Add trusted info of course
		if( userData.trusted ) then
			row.trustedInfo:SetFormattedText("|T%s:16:16:-1:0|t %s (%s)", READY_CHECK_READY_TEXTURE, string.match(userData.from, "(.-)%-"), L["Trusted"])
			row.trustedInfo.tooltip = L["Data for this player is from a verified source and can be trusted."]
		else
			row.trustedInfo:SetFormattedText("|T%s:16:16:-1:0|t %s (%s)", READY_CHECK_NOT_READY_TEXTURE, string.match(userData.from, "(.-)%-"), L["Untrusted"])
			row.trustedInfo.tooltip = L["While the player data should be accurate, it is not guaranteed as the source is unverified."]
		end
		
		local equipmentData, enchantData, gemData = SexyGroup:GetGearSummary(userData)
		local gemTooltip, enchantTooltip = SexyGroup:GetGearExtraTooltip(gemData, enchantData)
		
		-- People probably want us to build the gear info, I'd imagine
		if( equipmentData.totalBad == 0 ) then
			row.gearInfo:SetFormattedText("|T%s:14:14|t %s (%d)", READY_CHECK_READY_TEXTURE, L["Equipment"], equipmentData.totalScore)
			row.gearInfo.tooltip = string.format(L["Equipment: |cffffffffAll good|r"], equipmentData.totalEquipped)
		else
			local gearTooltip = string.format(L["Equipment: |cffffffff%d bad items found|r"], equipmentData.totalBad)
			for _, itemLink in pairs(userData.equipment) do
				local fullItemLink = select(2, GetItemInfo(itemLink))
				if( fullItemLink and equipmentData[itemLink] ) then
					gearTooltip = gearTooltip .. "\n" .. string.format(L["%s - %s item"], fullItemLink, SexyGroup.TALENT_TYPES[equipmentData[itemLink]] or equipmentData[itemLink])
				end
			end

			row.gearInfo:SetFormattedText("|T%s:14:14|t %s (%d)", READY_CHECK_NOT_READY_TEXTURE, L["Equipment"], equipmentData.totalScore)
			row.gearInfo.tooltip = gearTooltip
		end
		
		-- Build enchants
		if( not enchantData.noData ) then
			row.enchantInfo:SetFormattedText("|T%s:14:14|t %s", enchantData.pass and READY_CHECK_READY_TEXTURE or READY_CHECK_NOT_READY_TEXTURE, L["Enchants"])
			row.enchantInfo.tooltip = enchantTooltip
		else
			row.enchantInfo:SetFormattedText("|T%s:14:14|t %s", READY_CHECK_WAITING_TEXTURE, L["Loading..."])
			row.enchantInfo.tooltip = L["Enchant information is still loading, you need to be within inspection range for data to become available."]
		end

		-- Build gems
		if( not gemData.noData ) then
			row.gemInfo:SetFormattedText("|T%s:14:14|t %s", gemData.pass and READY_CHECK_READY_TEXTURE or READY_CHECK_NOT_READY_TEXTURE, L["Gems"])
			row.gemInfo.tooltip = gemTooltip
		else
			row.gemInfo:SetFormattedText("|T%s:14:14|t %s", READY_CHECK_WAITING_TEXTURE, L["Loading..."])
			row.gemInfo.tooltip = L["Enchant information is still loading, you need to be within inspection range for data to become available."]
		end

		SexyGroup:DeleteTables(equipmentData, enchantData, gemData)
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

local backdrop = {bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeSize = 1}
local buttonList = {"playerInfo", "talentInfo", "trustedInfo", "notesInfo", "gearInfo", "enchantInfo", "gemInfo"}
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
		button:GetFontString():SetPoint("LEFT", button, "LEFT", 0, 0)
		button:GetFontString():SetJustifyH("LEFT")
		button:GetFontString():SetJustifyV("CENTER")
		button:GetFontString():SetWidth(row:GetWidth() - 5)
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
	local frame = CreateFrame("Frame", "SexyGroupSummaryFrame", UIParent)
	frame:SetClampedToScreen(true)
	frame:RegisterForDrag("LeftButton", "RightButton")
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetFrameStrata("HIGH")
	frame:SetScript("OnHide", function() SexyGroup:DeleteTables(equipmentData, enchantData, gemData) end)
	frame:SetScript("OnDragStart", function(self, mouseButton)
		if( mouseButton == "RightButton" ) then
			frame:ClearAllPoints()
			frame:SetPoint("CENTER", UIParent, "CENTER", SexyGroup.db.profile.general.databaseExpanded and -75 or 0, 0)
			SexyGroup.db.profile.position = nil
			return
		end
		
		self:StartMoving()
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		
		local scale = self:GetEffectiveScale()
		SexyGroup.db.profile.position = {x = self:GetLeft() * scale, y = self:GetTop() * scale}
	end)
	frame:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		edgeSize = 26,
		insets = {left = 9, right = 9, top = 9, bottom = 9},
	})
	frame:SetBackdropColor(0, 0, 0, 0.90)
	
	table.insert(UISpecialFrames, "SexyGroupSummaryFrame")
	
	if( SexyGroup.db.profile.positions.summary ) then
		local scale = frame:GetEffectiveScale()
		frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", SexyGroup.db.profile.positions.summary.x / scale, SexyGroup.db.profile.positions.summary.y / scale)
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
	frame.title:SetText("Sexy Group")

	-- Close button
	local button = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	button:SetPoint("TOPRIGHT", -3, -3)
	button:SetHeight(28)
	button:SetWidth(28)
	button:SetScript("OnClick", function() frame:Hide() end)

	self.frame = frame
end