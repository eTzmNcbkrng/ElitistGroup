local SexyGroup = select(2, ...)
local History = SexyGroup:NewModule("GroupHistory", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("SexyGroup")
local AceGUI = LibStub("AceGUI-3.0")
local surveyFrame, SpecialFrame, totalPartyMembers
local groupRatings, groupNotes, groupList = {}, {}, {}

function History:LFG_COMPLETION_REWARD()
	if( SexyGroup.db.profile.autoPopup ) then
		self:LogGroup()
	else
		local name, typeID = GetLFGCompletionReward()
		if( typeID == TYPEID_HEROIC_DIFFICULTY ) then
			name = string.format(HEROIC_PREFIX, name)
		end
		
		SexyGroup:Print(string.format(L["Completed %s! Type /rate to rate this group."], name))
	end
end

function History:OnInitialize()
	self:RegisterEvent("LFG_COMPLETION_REWARD")

	SpecialFrame = CreateFrame("Frame", "SexyGroupHistoryHider")
	SpecialFrame:SetScript("OnHide", function()
		if( surveyFrame ) then
			surveyFrame:Hide()
		end
	end)

	table.insert(UISpecialFrames, "SexyGroupHistoryHider")
	
	SLASH_SEXYGROUPRATE1 = "/rate"
	SlashCmdList["SEXYGROUPRATE"] = function(msg, editbox)
		if( GetNumPartyMembers() == 0 and not self.activeGroupID ) then
			SexyGroup:Print(L["You need to currently be in a group, or have been in a group to use the rating tool."])
			return
		end
		
		History:LogGroup()
	end	
end

local function OnEnterPressed(self, event, text)
	groupNotes[self:GetUserData("partyID")] = text
end

local function OnValueChanged(self, event, value)
	groupRatings[self:GetUserData("partyID")] = value
end
			
local function OnHide(self)
	for partyID, data in pairs(groupList) do
		if( groupRatings[partyID] and groupNotes[partyID] ) then
			local userData = SexyGroup.userData[partyID]
			local note
			for i=1, #(userData.notes) do
				if( userData.notes[i].from == SexyGroup.playerName ) then
					note = userData.notes[i]
					table.remove(userData.notes, i)
					break
				end
			end
			
			note = note or {}
			note.from = SexyGroup.playerName
			note.role = note.role and bit.bor(note.role, data.role) or data.role
			note.rating = groupRatings[partyID]
			note.comment = groupNotes[partyID]
			note.time = time()
			table.insert(userData.notes, note)
		end
	end
	
	surveyFrame = nil
	AceGUI:Release(self)
end

function History:InitFrame()
	surveyFrame = AceGUI:Create("Frame")	
	surveyFrame:SetCallback("OnClose", OnHide)
	surveyFrame:SetTitle(L["Rate This Group"])
	surveyFrame:SetStatusText("")
	surveyFrame:SetLayout("Flow")
	surveyFrame:SetWidth(495)
	surveyFrame:SetHeight(245 + (totalPartyMembers > 2 and 155 or 0))
	surveyFrame:Show()

	-- Be do be do be dooooo
	SpecialFrame:Show()
	PlaySoundFile([[Interface\AddOns\SexyGroup\question.mp3]])

	local header = AceGUI:Create("Heading")
	header:SetText(L["Rate and make notes on the players in your group."])
	header.width = "fill"
	surveyFrame:AddChild(header)
	
	for partyID, data in pairs(groupList) do
		local group = AceGUI:Create("InlineGroup")
		group:SetWidth(230)			
		
		local label = AceGUI:Create("Label")
		label:SetWidth(300)
		label:SetText(data.name)
		if( data.classToken ) then
			label:SetImage("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes", CLASS_ICON_TCOORDS[data.classToken][1], CLASS_ICON_TCOORDS[data.classToken][2], CLASS_ICON_TCOORDS[data.classToken][3], CLASS_ICON_TCOORDS[data.classToken][4])
			label:SetImageSize(24, 24)
		else
			label:SetImage("")
		end	
		label:SetFontObject(SystemFont_Huge1)
		group:AddChild(label)
		
		local rating = AceGUI:Create("Slider")
		rating:SetSliderValues(1, SexyGroup.MAX_RATING, 1)
		rating:SetValue(groupRatings[partyID] or 3)
		rating:SetCallback("OnValueChanged", OnValueChanged)
		rating:SetUserData("partyID", partyID)
		rating.lowtext:SetText(L["Terrible"])
		rating.hightext:SetText(L["Great"])
		group:AddChild(rating)

		local notes = AceGUI:Create("EditBox")
		notes:SetLabel(L["Notes"])
		notes:SetText(groupNotes[partyID] or string.format("%s - ", data.roleText))
		notes:SetCallback("OnEnterPressed", OnEnterPressed)
		notes:SetUserData("partyID", partyID)
		group:AddChild(notes)
		
		surveyFrame:AddChild(group)
	end
	
	surveyFrame:SetStatusText((L["Instance run: %s"]):format(
		GetInstanceDifficulty() > 1 and (HEROIC_PREFIX):format(GetRealZoneText()) or GetRealZoneText()
	))
end

function History:LogGroup()
	local groupID = ""
	for i=1, GetNumPartyMembers() do groupID = groupID .. UnitGUID("party" .. i) end
	if( groupID == "" and not self.activeGroupID ) then return end
	
	if( groupID ~= "" and ( not self.activeGroupID or self.activeGroupID ~= groupID ) ) then
		table.wipe(groupList)
		table.wipe(groupNotes)
		table.wipe(groupRatings)
		
		totalPartyMembers = GetNumPartyMembers()
		for i=1, GetNumPartyMembers() do
			SexyGroup.modules.Scan:CreateCoreTable("party" .. i)
			
			local name, server = UnitName("party" .. i)
			local partyID = string.format("%s-%s", name, server and server ~= "" and server or GetRealmName())
			local isTank, isHealer, isDamage = UnitGroupRolesAssigned("party" .. i)
			local role = bit.bor(isTank and SexyGroup.ROLE_TANK or 0, isHealer and SexyGroup.ROLE_HEALER or 0, isDamage and SexyGroup.ROLE_DAMAGE or 0)
			local roleText = (isTank and TANK) or (isHealer and HEALER) or (isDamage and DAMAGE) or ""
			local classToken = select(2, UnitClass("party" .. i))
			
			groupList[partyID] = {role = role, roleText = roleText, name = name, classToken = classToken}
		end

		self.activeGroupID = groupID
	end
	
	self:InitFrame()
end

