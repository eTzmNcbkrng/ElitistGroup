local modname = "GroupHistory"
local L = LibStub("AceLocale-3.0"):GetLocale("SexyGroup")
local AceGUI = LibStub("AceGUI-3.0")
local parent = SexyGroup
local mod = parent:NewModule(modname, "AceEvent-3.0")
local surveyFrame
local SpecialFrame = CreateFrame("Frame", "SexyGroupHistoryHider")
SpecialFrame:SetScript("OnHide", function()
	surveyFrame:Hide()
end)
local defaults = {
	global = {
		characters = {}
	}
}
local chars

mod.lastRun = {}
function mod:OnInitialize()
	self.db = parent.db:RegisterNamespace(modname, defaults)
	chars = self.db.global.characters
	f = AceGUI:Create("Frame")	
	tinsert(UISpecialFrames,"SexyGroupHistoryHider")
	surveyFrame = f
	f:SetTitle(L["Rate This Group"])
	f:SetStatusText("")
	f:SetLayout("Flow")
	f:SetWidth(495)
	f:SetHeight(395)
	f:Hide()
	
	SLASH_SEXYGROUPRATE1 = "/rate"
	SlashCmdList["SEXYGROUPRATE"] = function(msg, editbox)
		mod:LogGroup()
	end	
end

function mod:InitFrame()
	local f = surveyFrame
	surveyFrame:ReleaseChildren()

	local header = AceGUI:Create("Heading")
	header:SetText(L["Rate and make notes on the players in your group."])
	header.width = "fill"
	f:AddChild(header)
	
	for i = 1, 4 do
		-- local key = "player"
		local key = "party" .. i
		if UnitExists(key) then
			local isTank, isHealer, isDamage = UnitGroupRolesAssigned(key)
			local role = (isTank and TANK) or (isHealer and HEALER) or (isDamage and DAMAGE) or ""
			local classToken = select(2, UnitClass(key))
			local g = AceGUI:Create("InlineGroup")
			g:SetWidth(230)			
			
			local label = AceGUI:Create("Label")
			label:SetWidth(230)
			local name = UnitName(key)
			label:SetText(role ~= "" and (name .. " - " .. role) or name)
			if( classToken ) then
				label:SetImage("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes", CLASS_ICON_TCOORDS[classToken][1], CLASS_ICON_TCOORDS[classToken][2], CLASS_ICON_TCOORDS[classToken][3], CLASS_ICON_TCOORDS[classToken][4])
				label:SetImageSize(24, 24)
			else
				label:SetImage("")
			end	
			label:SetFontObject(SystemFont_Huge1)
			g:AddChild(label)
			
			local rating = AceGUI:Create("Slider")
			rating:SetSliderValues(1, 5, 1)
			rating:SetValue(3)
			-- rating:SetLabel(L["Rate this player's performance"])
			rating:SetCallback("OnValueChanged", function(self, event, value)
				if not mod.lastRun[UnitGUID(key)] then return end
				mod.lastRun[UnitGUID(key)].rating = value
			end)
			rating.lowtext:SetText(L["Terrible"])
			rating.hightext:SetText(L["Great"])
			g:AddChild(rating)

			local notes = AceGUI:Create("EditBox")
			notes:SetLabel(L["Notes"])
			notes:SetCallback("OnEnterPressed", function(self, event, text)
				if not mod.lastRun[UnitGUID(key)] then return end
				mod.lastRun[UnitGUID(key)].notes = text
			end)
			g:AddChild(notes)
			
			f:AddChild(g)
		end
	end
	f:SetStatusText((L["Instance run: %s"]):format(
		GetInstanceDifficulty() > 1 and (HEROIC_PREFIX):format(GetRealZoneText()) or GetRealZoneText()
	))
	self:ShowFrame()
end

function mod:ShowFrame()
	surveyFrame:Show()
	-- surveyFrame:SetAlpha(0)
	SpecialFrame:Show()
	PlaySoundFile([[Interface\AddOns\SexyGroup\question.mp3]])
end

function mod:OnEnable()
	self:RegisterEvent("LFG_COMPLETION_REWARD")
end

local guids = {}
function mod:BuildGroupKey()
	wipe(guids)
	for i = 1, 4 do
		if UnitExists("party" .. i) then
			tinsert(guids, UnitGUID("party" .. i))
		end
	end
	return table.concat(guids)
end

function mod:LogGroup()
	local groupKey = self:BuildGroupKey()
	if mod.groupKey ~= groupKey then
		mod.groupKey = groupKey
		for i = 1, 4 do
			local key = "party" .. i
			if UnitName(key) and not UnitIsUnit(key, "player") then
				local name = UnitName(key)
				local guid = UnitGUID(key)
				chars[guid] = chars[guid] or {}
				local isTank, isHealer, isDamage = UnitGroupRolesAssigned(key)
				local run = {
					role = bit.bor(isTank and 4 or 0, isHealer and 2 or 0, isDamage and 1 or 0),
					instance = GetRealZoneText(),
					notes = "",
					rating = 0
				}
				tinsert(chars[guid], run)
				mod.lastRun[guid] = run			
			end
		end
		self:InitFrame()
	else
		self:ShowFrame()
	end
end

-- Dungeon complete, popup survey
function mod:LFG_COMPLETION_REWARD()
	wipe(mod.lastRun)
	self:LogGroup()
end