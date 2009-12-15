SexyGroup = LibStub("AceAddon-3.0"):NewAddon("SexyGroup", "AceEvent-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("SexyGroup")
local defaults = {}

function SexyGroup:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("SexyGroupDB", defaults)
end

function SexyGroup:CalculateScore(itemQuality, itemLevel)
	if( not itemLevel and itemQuality ) then
		itemQuality, itemLevel = select(3, GetItemInfo(itemLevel))
	end
	
	if( not itemQuality and not itemLevel ) then return 0 end
	return itemLevel * (self.QUALITY_MODIFIERS[itemQuality] or 1)
end

--Protector of the Pack, Natural Reaction
--Bladed Armor, Blade Barrier, Toughness, Anticipation
function SexyGroup:GetPlayerSpec(playerData)
	if( not playerData ) then return "unknown", L["Unknown"], "Interface\\Icons\\INV_Misc_QuestionMark" end

	local treeOffset
	if( playerData.talentTree1 > playerData.talentTree2 and playerData.talentTree1 > playerData.talentTree3 ) then
		treeOffset = 1
	elseif( playerData.talentTree2 > playerData.talentTree1 and playerData.talentTree2 > playerData.talentTree3 ) then
		treeOffset = 4
	elseif( playerData.talentTree3 > playerData.talentTree1 and playerData.talentTree3 > playerData.talentTree2 ) then
		treeOffset = 7
	else
		return "unknown", L["Unknown"], "Interface\\Icons\\INV_Misc_QuestionMark"
	end
	
	return playerData.specRole or self.TREE_DATA[playerData.classToken][treeOffset], self.TREE_DATA[playerData.classToken][treeOffset + 1], self.TREE_DATA[playerData.classToken][treeOffset + 2] 
end

function SexyGroup:IsValidItem(itemLink, playerData)
	local spec = self:GetPlayerSpec(playerData)
	local itemType = self.ITEM_TALENTTYPE[itemLink]
	return spec ~= "unknown" and itemType ~= "unknown" and self.VALID_SPECTYPES[spec] and self.VALID_SPECTYPES[spec][itemType]
end

local timeTable = {}
function SexyGroup:ConvertToSeconds(dateText)
	local month, day, year, hour, minutes, seconds = string.match(dateText, "([0-9]+)/([0-9]+)/([0-9]+) ([0-9]+):([0-9]+):([0-9]+)")
	timeTable.month = month
	timeTable.day = day
	timeTable.year = year
	timeTable.min = minutes
	timeTable.sec = seconds
	
	return time(timeTable)
end

