local modname = "GroupHistory"
local L = LibStub("AceLocale-3.0"):GetLocale("SexyGroup")
local AceGUI = LibStub("AceGUI-3.0")
local parent = SexyGroup
local mod = parent:NewModule(modname, "AceEvent-3.0")
local surveyFrame

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
	surveyFrame = f
	f:SetTitle(L["Rate This Group"])
	f:SetStatusText("")
	f:SetLayout("Flow")
	f:SetWidth(640)
	f:SetHeight(350)
	f:Hide()
end

function mod:InitFrame()
	local f = surveyFrame
	surveyFrame:ReleaseChildren()
	
	for i = 1, 5 do
		-- local key = "player"
		local key = "party" .. i
		if UnitExists(key) then
			local isTank, isHealer, isDamage = UnitGroupRolesAssigned(key)
			local role = (isTank and TANK) or (isHealer and HEALER) or (isDamage and DAMAGE) or ""
			local g = AceGUI:Create("InlineGroup")
			
			local label = AceGUI:Create("Label")
			local name = UnitName(key)
			label:SetText(role ~= "" and (name .. " - " .. role) or name)
			g:AddChild(label)
			
			local rating = AceGUI:Create("Slider")
			rating:SetSliderValues(0, 10, 1)
			rating:SetValue(5)
			rating:SetLabel(L["Rate this player's performance"])
			rating:SetCallback("OnValueChanged", function(self, event, value)
				if not mod.lastRun[UnitGUID(key)] then return end
				mod.lastRun[UnitGUID(key)].rating = value
			end)
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
	f:Show()
	PlaySoundFile([[Interface\AddOns\SexyGroup\question.mp3]])
	f:SetStatusText((L["Instance run: %s"]):format(
		GetInstanceDifficulty() > 1 and (HEROIC_PREFIX):format(GetRealZoneText()) or GetRealZoneText()
	))
end

function mod:OnEnable()
	self:RegisterEvent("LFG_COMPLETION_REWARD")
end

function mod:LogGroup()
	for i = 1, 5 do
		local key = "party" .. i
		if UnitName(key) and not UnitIsUnit(key, "player") then
			local name = UnitName(key)
			local guid = UnitGUID(key)
			chars[guid] = chars[guid] or {}
			local isTank, isHealer, isDamage = UnitGroupRolesAssigned(key)
			local run = {
				role = bit.bor(isTank and SexyGroup.ROLE_TANK or 0, isHealer and SexyGroup.ROLE_HEALER or 0, isDamage and SexyGroup.ROLE_DAMAGE or 0),
				instance = GetRealZoneText(),
				notes = "",
				rating = 0
			}
			tinsert(chars[guid], run)
			mod.lastRun[guid] = run			
		end
	end
	-- surveyFrame:Show()
	self:InitFrame()
end

-- Dungeon complete, popup survey
function mod:LFG_COMPLETION_REWARD()
	wipe(mod.lastRun)
	self:LogGroup()
end