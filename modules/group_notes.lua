local SexyGroup = select(2, ...)
local History = SexyGroup:NewModule("History", "AceEvent-3.0")
local L = SexyGroup.L

local AceGUI = LibStub("AceGUI-3.0")
local surveyFrame, SpecialFrame, instanceName, wasAutoPopped
local groupData, queuedUnits = {}, {}
local totalGroupMembers = 0

function History:OnInitialize()
	self:RegisterEvent("LFG_COMPLETION_REWARD")
	self:RegisterEvent("PARTY_MEMBERS_CHANGED")

	SpecialFrame = CreateFrame("Frame", "SexyGroupHistoryHider")
	SpecialFrame:SetScript("OnHide", function()
		if( surveyFrame ) then
			surveyFrame:Hide()
		end
	end)

	table.insert(UISpecialFrames, "SexyGroupHistoryHider")
	
	SLASH_SEXYGROUPRATE1 = "/rate"
	SlashCmdList["SEXYGROUPRATE"] = function(msg, editbox)
		if( GetNumPartyMembers() == 0 and not self.haveActiveGroup ) then
			SexyGroup:Print(L["You need to currently be in a group, or have been in a group to use the rating tool."])
			return
		end
		
		History:LogGroup()
	end	
end

function History:UpdateUnitData(unit)
	if( UnitName(unit) == UNKNOWN ) then
		queuedUnits[unit] = true
		self:RegisterEvent("UNIT_NAME_UPDATE")
		return 
	end
	
	SexyGroup.modules.Scan:CreateCoreTable(unit)

	local partyID = SexyGroup:GetPlayerID(unit)
	if( not groupData[partyID] ) then
		totalGroupMembers = totalGroupMembers + 1
		
		local userData = SexyGroup.userData[partyID]
		local playerNote = userData.notes[SexyGroup.playerName]
		groupData[partyID] = {name = userData.name, classToken = userData.classToken, rating = playerNote and playerNote.rating or 3, comment = playerNote and playerNote.comment}
	end
	
	local isTank, isHealer, isDamage = UnitGroupRolesAssigned(unit)
	local role = bit.bor(isTank and SexyGroup.ROLE_TANK or 0, isHealer and SexyGroup.ROLE_HEALER or 0, isDamage and SexyGroup.ROLE_DAMAGE or 0)
	local roleText = (isTank and TANK) or (isHealer and HEALER) or (isDamage and DAMAGE) or ""
	
	groupData[partyID].role = role
	groupData[partyID].roletext = roleText
end

function History:UNIT_NAME_UPDATE(event, unit)
	if( queuedUnits[unit] ) then
		queuedUnits[unit] = nil
		self:UpdateUnitData(unit)
		
		local hasQueue
		for unit in pairs(queuedUnits) do hasQueue = true; break end
		if( not hasQueue ) then
			self:UnregisterEvent("UNIT_NAME_UPDATE")
		end
	end
end

function History:PARTY_MEMBERS_CHANGED(event)
	if( GetNumPartyMembers() == 0 ) then
		self.resetGroup = true
	elseif( GetNumPartyMembers() == MAX_PARTY_MEMBERS and ( not event or select(2, IsInInstance()) == "party" ) ) then
		if( self.resetGroup ) then
			groupData = {}
			
			self.resetGroup = nil
			totalGroupMembers = 0
			instanceName = nil
		end
		
		instanceName = instanceName or GetInstanceDifficulty() > 1 and string.format("%s (%s)", GetRealZoneText(), PLAYER_DIFFICULTY2) or GetRealZoneText()
		self.haveActiveGroup = true
		
		for i=1, GetNumPartyMembers() do
			self:UpdateUnitData("party" .. i)
		end
	end
end

function History:LFG_COMPLETION_REWARD()
	if( SexyGroup.db.profile.general.autoPopup ) then
		wasAutoPopped = true
		self:LogGroup()
	else
		local name, typeID = GetLFGCompletionReward()
		if( typeID == TYPEID_HEROIC_DIFFICULTY ) then
			name = string.format(HEROIC_PREFIX, name)
		end
		
		SexyGroup:Print(string.format(L["Completed %s! Type /rate to rate this group."], name))
	end
end

local function OnTextChanged(self, event, text)
	groupData[self:GetUserData("partyID")].comment = text and text ~= "" and text
end

local function OnValueChanged(self, event, value)
	groupData[self:GetUserData("partyID")].rating = value
end
			
local function OnHide(self)
	local missing = 0
	for partyID, data in pairs(groupData) do
		if( not data.comment ) then
			missing = missing + 1
		end

		local note = SexyGroup.userData[partyID].notes[SexyGroup.playerName] or {}
		note.role = note.role and bit.bor(note.role, data.role) or data.role
		note.rating = data.rating
		note.comment = SexyGroup:SafeEncode(data.comment)
		note.time = time()
		
		SexyGroup.userData[partyID].notes[SexyGroup.playerName] = note
	end
	
	-- Remind people to rate their group if they have it on auto popup that they didn't rate everyone
	if( missing > 0 and wasAutoPopped ) then
		SexyGroup:Print(string.format(L["Defaulting to no comment on %d players, type /rate to set a specific comment."], missing))
	end
	
	surveyFrame = nil
	AceGUI:Release(self)
end

function History:InitFrame()
	local perRow = totalGroupMembers <= 4 and 2 or 3
	
	surveyFrame = AceGUI:Create("Frame")	
	surveyFrame:SetCallback("OnClose", OnHide)
	surveyFrame:SetTitle("Sexy Group")
	surveyFrame:SetStatusText("")
	surveyFrame:SetLayout("Flow")
	surveyFrame:SetWidth(35 + (perRow * 230))
	surveyFrame:SetHeight(90 + (math.ceil(totalGroupMembers / perRow) * 130))
	surveyFrame:SetStatusText(string.format(L["Instance: %s"], instanceName or UNKNOWN))
	surveyFrame:Show()

	-- Be do be do be dooooo
	SpecialFrame:Show()
	PlaySoundFile("Interface\\AddOns\\SexyGroup\\question.mp3")

	local header = AceGUI:Create("Heading")
	header:SetText(L["Rate and comment on the players in your group."])
	header.width = "fill"
	surveyFrame:AddChild(header)
	
	for partyID, data in pairs(groupData) do
		local group = AceGUI:Create("InlineGroup")
		group:SetWidth(230)		
		
		local classColor = RAID_CLASS_COLORS[data.classToken]
		if( classColor ) then
			group:SetTitle(string.format("|cff%02x%02x%02x%s|r", classColor.r * 255, classColor.g * 255, classColor.b * 255, data.name))
		else
			group:SetTitle(string.format("|cffffffff%s|r", data.name))
		end
		
		local rating = AceGUI:Create("Slider")
		rating:SetSliderValues(1, SexyGroup.MAX_RATING, 1)
		rating:SetValue(groupData[partyID].rating)
		rating:SetCallback("OnValueChanged", OnValueChanged)
		rating:SetUserData("partyID", partyID)
		rating:SetLabel("")
		rating.lowtext:SetText(L["Terrible"])
		rating.hightext:SetText(L["Great"])
		group:AddChild(rating)

		local comment = AceGUI:Create("EditBox")
		comment:SetLabel(L["Comment"])
		comment:SetText(groupData[partyID].comment or "")
		comment:SetCallback("OnTextChanged", OnTextChanged)
		comment:SetUserData("partyID", partyID)
		comment.showbutton = nil
		group:AddChild(comment)
		
		
		surveyFrame:AddChild(group)
	end
end

--[[
function test(num)
	if( surveyFrame ) then
		AceGUI:Release(surveyFrame)
	end
	
	GetNumPartyMembers = function() return num end
	table.wipe(groupData)
	for i=1, GetNumPartyMembers() do
		groupData["Test" .. i .. "-Mal'Ganis"] = {role = SexyGroup.ROLE_TANK, roleText = "Tank", name = "Test" .. i, classToken = "DRUID", rating = 3}
	end
	
	instanceName = "Test"
	totalGroupMembers = GetNumPartyMembers()
	History:InitFrame()
end
]]

function History:LogGroup()
	self:PARTY_MEMBERS_CHANGED()
	self:InitFrame()
end

