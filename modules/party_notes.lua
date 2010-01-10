local ElitistGroup = select(2, ...)
local History = ElitistGroup:NewModule("PartyHistory", "AceEvent-3.0")
local L = ElitistGroup.L

local AceGUI = LibStub("AceGUI-3.0")
local surveyFrame, SpecialFrame, instanceName, wasAutoPopped
local groupData, queuedUnits = {}, {}
local totalGroupMembers = 0

function History:OnInitialize()
	self:RegisterEvent("LFG_COMPLETION_REWARD")
	self:RegisterEvent("PARTY_MEMBERS_CHANGED")

	SpecialFrame = CreateFrame("Frame", "ElitistGroupHistoryHider")
	SpecialFrame:SetScript("OnHide", function()
		if( surveyFrame ) then
			surveyFrame:Hide()
		end
	end)

	table.insert(UISpecialFrames, "ElitistGroupHistoryHider")
end

function History:UpdateUnitData(unit)
	if( UnitName(unit) == UNKNOWN ) then
		queuedUnits[unit] = true
		self:RegisterEvent("UNIT_NAME_UPDATE")
		return 
	end
	
	ElitistGroup.modules.Scan:CreateCoreTable(unit)

	local partyID = ElitistGroup:GetPlayerID(unit)
	if( not groupData[partyID] ) then
		totalGroupMembers = totalGroupMembers + 1
		
		local userData = ElitistGroup.userData[partyID]
		local playerNote = userData.notes[ElitistGroup.playerName]
		groupData[partyID] = {name = userData.name, classToken = userData.classToken, rating = playerNote and playerNote.rating or 3, comment = playerNote and playerNote.comment}
	end
	
	local isTank, isHealer, isDamage = UnitGroupRolesAssigned(unit)
	local role = bit.bor(isTank and ElitistGroup.ROLE_TANK or 0, isHealer and ElitistGroup.ROLE_HEALER or 0, isDamage and ElitistGroup.ROLE_DAMAGE or 0)
	local roleText = (isTank and TANK) or (isHealer and HEALER) or (isDamage and DAMAGE) or ""
	
	groupData[partyID].role = role
	groupData[partyID].talentText = roleText
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
	elseif( not event or ( GetNumPartyMembers() == MAX_PARTY_MEMBERS and select(2, IsInInstance()) == "party" ) ) then
		if( self.resetGroup ) then
			groupData = {}
			
			self.resetGroup = nil
			totalGroupMembers = 0
			instanceName = nil
		end
		
		self.haveActiveGroup = true
		
		for i=1, GetNumPartyMembers() do
			self:UpdateUnitData("party" .. i)
		end
	end
end

function History:LFG_COMPLETION_REWARD()
	if( ElitistGroup.db.profile.general.autoPopup ) then
		wasAutoPopped = true
		self:Show()
	else
		local name, typeID = GetLFGCompletionReward()
		instanceName = typeID == TYPEID_HEROIC_DIFFICULTY and string.format("%s (%s)", name, PLAYER_DIFFICULTY2) or name
		
		ElitistGroup:Print(string.format(L["Completed %s! Type /rate to rate this group."], instanceName))
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

		local note = ElitistGroup.userData[partyID].notes[ElitistGroup.playerName] or {}
		note.role = note.role and bit.bor(note.role, data.role) or data.role
		note.rating = data.rating
		note.comment = ElitistGroup:SafeEncode(data.comment and data.comment ~= "" and data.comment)
		note.time = time()
		
		ElitistGroup.userData[partyID].notes[ElitistGroup.playerName] = note
	end
	
	-- Remind people to rate their group if they have it on auto popup that they didn't rate everyone
	if( missing > 0 and wasAutoPopped ) then
		ElitistGroup:Print(string.format(L["Defaulting to no comment on %d players, type /rate to set a specific comment."], missing))
	end
	
	wasAutoPopped = nil
	surveyFrame = nil
	AceGUI:Release(self)
end

function History:InitFrame()
	local perRow = totalGroupMembers <= 4 and 2 or 3
	instanceName = instanceName or GetInstanceDifficulty() > 1 and string.format("%s (%s)", GetRealZoneText(), PLAYER_DIFFICULTY2) or GetRealZoneText()
	
	surveyFrame = AceGUI:Create("Frame")	
	surveyFrame:SetCallback("OnClose", OnHide)
	surveyFrame:SetTitle("Elitist Group")
	surveyFrame:SetStatusText("")
	surveyFrame:SetLayout("Flow")
	surveyFrame:SetWidth(35 + (perRow * 230))
	surveyFrame:SetHeight(90 + (math.ceil(totalGroupMembers / perRow) * 130))
	surveyFrame:SetStatusText(string.format(L["Instance: %s"], instanceName or UNKNOWN))
	surveyFrame:Show()

	-- Be do be do be dooooo
	SpecialFrame:Show()
	PlaySoundFile("Interface\\AddOns\\ElitistGroup\\question.mp3")

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
		rating:SetSliderValues(1, ElitistGroup.MAX_RATING, 1)
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
		groupData["Test" .. i .. "-Mal'Ganis"] = {role = ElitistGroup.ROLE_TANK, roleText = "Tank", name = "Test" .. i, classToken = "DRUID", rating = 3}
	end
	
	instanceName = "Test"
	totalGroupMembers = GetNumPartyMembers()
	History:InitFrame()
end
]]

function History:Show()
	self:PARTY_MEMBERS_CHANGED()
	self:InitFrame()
end

