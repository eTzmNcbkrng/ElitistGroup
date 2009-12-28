local SexyGroup = select(2, ...)
SexyGroup = LibStub("AceAddon-3.0"):NewAddon(SexyGroup, "SexyGroup", "AceEvent-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("SexyGroup")

function SexyGroup:OnInitialize()
	self.defaults = {
		profile = {
			expExpanded = {},
			general = {
				autoPopup = true,
			},
			database = {
				pruneBasic = 30,
				pruneFull = 120,
			},
			comm = {
				enabled = true,
				areas = {GUILD = true, WHISPER = true, RAID = true, PARTY = true, BATTLEGROUND = false},
			},
		},
		faction = {
			lastModified = {},
			users = {},
		},
	}
	
	self.db = LibStub("AceDB-3.0"):New("SexyGroupDB", self.defaults, true)
	self.db.RegisterCallback(self, "OnDatabaseShutdown", "OnDatabaseShutdown")
	self.db.RegisterCallback(self, "OnDatabaseReset", "OnProfileReset")
	self.db.RegisterCallback(self, "OnProfileShutdown", "OnProfileShutdown")
	self.db.RegisterCallback(self, "OnProfileReset", "OnProfileReset")
	
	self.playerName = string.format("%s-%s", UnitName("player"), GetRealmName())
	self.modules.Sync:Setup()
	
	-- Data is old enough that we want to remove extra data to save space
	if( self.db.profile.database.pruneBasic > 0 or self.db.database.pruneFull > 0 ) then
		local pruneBasic = time() - (self.db.profile.database.pruneBasic * 86400)
		local pruneFull = time() - (self.db.profile.database.pruneFull * 86400)
		
		for name, modified in pairs(self.db.faction.lastModified) do
			-- Basic pruning, we wipe out any volatile data
			if( self.db.profile.database.pruneBasic > 0 and modified <= pruneBasic ) then
				self.db.faction.lastModified[name] = time()
				
				local name, server, level, classToken, notes = self.userData[name].name, self.userData[name].server, self.userData[name].level, self.userData[name].classToken, self.userData[name].notes
				table.wipe(self.userData[name])
				self.userData[name].name = name
				self.userData[name].server = server
				self.userData[name].level = level
				self.userData[name].classToken = classToken
				self.userData[name].notes = notes
				self.userData[name].pruned = true
			-- Full pruning, all data gets removed
			elseif( self.db.profile.database.pruneFull > 0 and modified <= pruneFull ) then
				self.db.faction.lastModified[name] = nil
				self.db.faction.users[name] = nil
				self.writeQueue[name] = nil
				self.userData[name] = nil
			end
		end
	end
	
	-- God bless meta tables
	self.writeQueue = {}
	self.userData = setmetatable({}, {
		__index = function(tbl, name)
			if( not SexyGroup.db.faction.users[name] ) then
				tbl[name] = false
				return false
			end
			
			local func, msg = loadstring("return " .. SexyGroup.db.faction.users[name])
			if( func ) then
				func = func()
			elseif( msg ) then
				error(msg, 3)
				tbl[name] = false
				return false
			end
			
			tbl[name] = func
			return tbl[name]
		end
	})
	
	if( not SexyGroup.db.profile.helped ) then
		self:RegisterEvent("PLAYER_ENTERING_WORLD", function()
			SexyGroup.db.profile.helped = true
			SexyGroup:Print(L["Welcome! Type /sexygroup help to see a list of available slash commands."])
			SexyGroup:UnregisterEvent("PLAYER_ENTERING_WORLD")
		end)
	end
end

function SexyGroup:GetItemLink(link)
	return link and string.match(link, "|H(.-)|h")
end

function SexyGroup:CalculateScore(itemLink, itemQuality, itemLevel)
	-- Quality 7 is heirloom, apply our modifier based on the item level
	if( itemQuality == 7 ) then
		itemLevel = (tonumber(string.match(itemLink, "(%d+)|h")) or 1) * SexyGroup.HEIRLOOM_ILEVEL
	end
	
	return itemLevel * (self.QUALITY_MODIFIERS[itemQuality] or 1)
end

--Protector of the Pack, Natural Reaction
--Bladed Armor, Blade Barrier, Toughness, Anticipation
function SexyGroup:GetPlayerSpec(playerData)
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

function SexyGroup:IsValidGem(itemLink, playerData)
	local spec = self:GetPlayerSpec(playerData)
	local itemType = self.GEM_TALENTTYPE[itemLink]
	return spec ~= "unknown" and itemType ~= "unknown" and self.VALID_SPECTYPES[spec] and self.VALID_SPECTYPES[spec][itemType]
end

function SexyGroup:IsValidEnchant(itemLink, playerData)
	local spec = self:GetPlayerSpec(playerData)
	local itemType = self.ENCHANT_TALENTTYPE[itemLink]
	return spec ~= "unknown" and itemType ~= "unknown" and self.VALID_SPECTYPES[spec] and self.VALID_SPECTYPES[spec][itemType]
end

-- Encodes text in a way that it won't interfere with the table being loaded
local map = {	["{"] = "\\" .. string.byte("{"), ["}"] = "\\" .. string.byte("}"),
				['"'] = "\\" .. string.byte('"'), [";"] = "\\" .. string.byte(";"),
				["%["] = "\\" .. string.byte("["), ["%]"] = "\\" .. string.byte("]"),
				["@"] = "\\" .. string.byte("@")}
function SexyGroup:SafeEncode(text)
	for find, replace in pairs(map) do
		text = string.gsub(text, find, replace)
	end
	
	return text
end

function SexyGroup:WriteTable(tbl, skipNotes)
	local data = ""
	for key, value in pairs(tbl) do
		if( not skipNotes or key ~= "notes" ) then
			local valueType = type(value)
			
			-- Wrap the key in brackets if it's a number
			if( type(key) == "number" ) then
				key = string.format("[%s]", key)
			-- This will match any punctuation, spacing or control characters, basically anything that requires wrapping around them
			elseif( string.match(key, "[%p%s%c]") ) then
				key = string.format("[\"%s\"]", key)
			end
			
			-- foo = {bar = 5}
			if( valueType == "table" ) then
				data = string.format("%s%s=%s;", data, key, self:WriteTable(value))
			-- foo = true / foo = 5
			elseif( valueType == "number" or valueType == "boolean" ) then
				data = string.format("%s%s=%s;", data, key, tostring(value))
			-- foo = "bar"
			else
				data = string.format("%s%s=\"%s\";", data, key, tostring(value))
			end
		end
	end
	
	return "{" .. data .. "}"
end

-- db:ResetProfile or db:ResetDB called
function SexyGroup:OnProfileReset()
	table.wipe(self.writeQueue)
	table.wipe(self.userData)
end

-- db:SetProfile called, this is the old profile before it gets switched
function SexyGroup:OnProfileShutdown()
	self:OnDatabaseShutdown()

	table.wipe(self.writeQueue)
	table.wipe(self.userData)
end

-- Player is logging out, write the cache
function SexyGroup:OnDatabaseShutdown()
	for name in pairs(self.writeQueue) do
		self.db.faction.lastModified[name] = time()
		self.db.faction.users[name] = self:WriteTable(self.userData[name])
	end
end

-- General cache functions that handle figuring out item data
-- Yay metatable caching, can only get gem totals via tooltip scanning, GetItemStats won't return a prismatic socketed item
local statCache = {}
local tooltip = CreateFrame("GameTooltip", nil, UIParent)
tooltip:SetOwner(UIParent, "ANCHOR_NONE")
tooltip.TextLeft = {}
tooltip.TextRight = {}

for i=1, 30 do
	tooltip.TextLeft[i] = tooltip:CreateFontString()
	tooltip.TextRight[i] = tooltip:CreateFontString()
	tooltip:AddFontStrings(tooltip.TextLeft[i], tooltip.TextRight[i])
end

SexyGroup.EMPTY_GEM_SLOTS = setmetatable({}, {
	__index = function(tbl, link)
		tooltip:SetOwner(UIParent, "ANCHOR_NONE")
		tooltip:SetHyperlink("item:" .. string.match(link, "item:(%d+)"))

		local total = 0
		for i=1, tooltip:NumLines() do
			local text = tooltip.TextLeft[i]:GetText()
			if( text == EMPTY_SOCKET_BLUE or text == EMPTY_SOCKET_META or text == EMPTY_SOCKET_NO_COLOR or text == EMPTY_SOCKET_RED or text == EMPTY_SOCKET_YELLOW ) then
				total = total + 1
			end
		end
		
		rawset(tbl, link, total)
		return total
	end,
})

SexyGroup.GEM_TALENTTYPE = setmetatable({}, {
	__index = function(tbl, link)
		local itemID = link and tonumber(string.match(link, "item:(%d+)"))
		if( itemID and SexyGroup.OVERRIDE_ITEMS[itemID] ) then
			rawset(tbl, link, SexyGroup.OVERRIDE_ITEMS[itemID])
			return SexyGroup.OVERRIDE_ITEMS[itemID]
		elseif( not itemID or not GetItemInfo(itemID) ) then
			rawset(tbl, link, "unknown")
			return "unknown"
		end
		
		local foundData
		table.wipe(statCache)
		
		tooltip:SetOwner(UIParent, "ANCHOR_NONE")
		tooltip:SetHyperlink(link)

		for i=1, tooltip:NumLines() do
			local text = string.lower(tooltip.TextLeft[i]:GetText())
			for key, stat in pairs(SexyGroup.STAT_MAP) do
				if( string.match(text, string.lower(_G[stat])) ) then
					foundData = true
					statCache[key] = true
				end
			end
			
			if( foundData ) then break end
		end
		
		if( not foundData ) then
			rawset(tbl, link, "unknown")
			return "unknown"
		end

		for i=1, #(SexyGroup.STAT_DATA) do
			local data = SexyGroup.STAT_DATA[i]
			local statString = (data.default or "") .. (data.gems or "")
			if( statString ~= "" ) then
				for statKey in string.gmatch(statString, "(.-)@") do
					if( statCache[statKey] ) then
						rawset(tbl, link, data.type)
						return data.type
					end
				end
			end
		end
			
		rawset(tbl, link, "unknown")
		return "unknown"
	end,
})

local function parseText(text)
	text = string.gsub(text, "%%d", "%%d+")
	text = string.gsub(text, "%%s", ".+")
	return string.lower(text)
end

-- Note: Regular enchants show up above sockets and below the items base stats. Engineering enchants are at the very bottom :|
local ARMOR_MATCH = parseText(ARMOR_TEMPLATE)
local SOCKET_MATCH = parseText(ITEM_SOCKET_BONUS)
local ENCHANT_ITEM_REQ_SKILL = parseText(ENCHANT_ITEM_REQ_LEVEL)
local ITEM_HEROIC = parseText(ITEM_HEROIC)
local ITEM_HEROIC_EPIC = parseText(ITEM_HEROIC_EPIC)
local ITEM_LEVEL_RANGE_CURRENT = parseText(ITEM_LEVEL_RANGE_CURRENT)
local ITEM_LEVEL_RANGE = parseText(ITEM_LEVEL_RANGE)
local ITEM_MIN_LEVEL = parseText(ITEM_MIN_LEVEL)
local ITEM_CLASSES_ALLOWED = parseText(ITEM_CLASSES_ALLOWED)

SexyGroup.ENCHANT_TALENTTYPE = setmetatable({}, {
	__index = function(tbl, link)
		local enchantID = link and tonumber(string.match(link, "item:%d+:(%d+)"))
		local type = not enchantID and "unknown" or enchantID == 0 and "none" or SexyGroup.OVERRIDE_ENCHANTS[enchantID]
		if( type ) then
			rawset(tbl, link, type)
			return type
		end
		
		-- Sadly, we cannot find enchant info without tooltip scanning, so we have to find the first green text that is not armor :(
		tooltip:SetOwner(UIParent, "ANCHOR_NONE")
		tooltip:SetHyperlink(link)

		local enchantText
		for i=1, tooltip:NumLines() do
			local text = string.lower(tooltip.TextLeft[i]:GetText())
			local r, g, b = tooltip.TextLeft[i]:GetTextColor()

			-- The person viewing this item is not high enough to use the enchant, the text will be red but we know it's going to be right above us
			if( string.match(text, ENCHANT_ITEM_REQ_SKILL) ) then
				enchantText = string.lower(tooltip.TextLeft[i - 1]:GetText())
				break
			-- Socket, or level we went too far
			elseif( string.match(text, SOCKET_MATCH) or string.match(text, ITEM_MIN_LEVEL) or string.match(text, ITEM_LEVEL_RANGE_CURRENT) or string.match(text, ITEM_LEVEL_RANGE) ) then
				break
			-- Valid enchant
			elseif( r == 0 and g >= 0.97 and b == 0 and not string.match(text, ARMOR_MATCH) and text ~= ITEM_HEROIC_EPIC and text ~= ITEM_HEROIC ) then
				enchantText = text
				break
			end	
		end
		
		if( not enchantText ) then
			rawset(tbl, link, "unknown")
			return "unknown"
		end

		-- Parse out the stats
		table.wipe(statCache)
		for key, stat in pairs(SexyGroup.STAT_MAP) do
			if( string.match(enchantText, string.lower(_G[stat])) ) then
				foundData = true
				statCache[key] = true
			end
		end
		
		if( not foundData ) then
			rawset(tbl, link, "unknown")
			return "unknown"
		end
		
		-- Now figure out wehat spec type
		for i=1, #(SexyGroup.STAT_DATA) do
			local data = SexyGroup.STAT_DATA[i]
			local statString = (data.default or "") .. (data.enchants or "")
			if( statString ~= "" ) then
				for statKey in string.gmatch(statString, "(.-)@") do
					if( statCache[statKey] ) then
						rawset(tbl, link, data.type)
						return data.type
					end
				end
			end
		end
			
		rawset(tbl, link, "unknown")
		return "unknown"
	end,
})

SexyGroup.ITEM_TALENTTYPE = setmetatable({}, {
	__index = function(tbl, link)
		local itemID = link and tonumber(string.match(link, "item:(%d+)"))
		if( itemID and SexyGroup.OVERRIDE_ITEMS[itemID] ) then
			rawset(tbl, link, SexyGroup.OVERRIDE_ITEMS[itemID])
			return SexyGroup.OVERRIDE_ITEMS[itemID]
		end
		
		local inventoryType = select(9, GetItemInfo(itemID))
		local equipType = inventoryType and SexyGroup.EQUIP_TO_TYPE[inventoryType]
		if( not equipType ) then 
			rawset(tbl, link, "unknown")
			return "unknown"
		end
		
		table.wipe(statCache)
		GetItemStats(link, statCache)

		for i=1, #(SexyGroup.STAT_DATA) do
			local data = SexyGroup.STAT_DATA[i]
			local statString = (data.default or "") .. (data[equipType] or "")
			if( statString ~= "" ) then
				for statKey in string.gmatch(statString, "(.-)@") do
					if( statCache[SexyGroup.STAT_MAP[statKey]] ) then
						rawset(tbl, link, data.type)
						return data.type
					end
				end
			end
		end
			
		rawset(tbl, link, "unknown")
		return "unknown"
	end,
})

function SexyGroup.GetPlayerID(unit)
	local name, server = UnitName(unit)
	server = server and server ~= "" and server or GetRealmName()
	return string.format("%s-%s", name, server), name, server
end

function SexyGroup:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Sexy Group|r: " .. msg)
end

--@debug@
_G.SexyGroup = SexyGroup
--@end-debug@