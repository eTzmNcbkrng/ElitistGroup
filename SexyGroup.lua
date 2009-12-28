local SexyGroup = select(2, ...)
SexyGroup = LibStub("AceAddon-3.0"):NewAddon(SexyGroup, "SexyGroup", "AceEvent-3.0", "AceTimer-3.0")
local L = SexyGroup.L

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
				ignoreBelow = 80,
			},
			comm = {
				enabled = true,
				gearRequests = true,
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

function SexyGroup:GetPlayerID(unit)
	local name, server = UnitName(unit)
	return name and string.format("%s-%s", name, server and server ~= "" and server or GetRealmName())
end

function SexyGroup:CalculateScore(itemLink, itemQuality, itemLevel)
	-- Quality 7 is heirloom, apply our modifier based on the item level
	if( itemQuality == 7 ) then
		itemLevel = (tonumber(string.match(itemLink, "(%d+)|h")) or 1) * SexyGroup.HEIRLOOM_ILEVEL
	end
	
	return itemLevel * (self.QUALITY_MODIFIERS[itemQuality] or 1)
end

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
		-- We need to make sure what we are writing has data, for example if we inspect scan someone we create the template
		-- if we fail to find talent data for them, and we don't have notes then will just throw out their data and not bother writing it
		local userData = self.userData[name]
		local hasData = userData.talentTree1 ~= 0 or userData.talentTree2 ~= 0 or userData.talentTree3 ~= 0
		if( not hasData ) then
			for _, note in pairs(userData.notes) do
				hasData = true
				break
			end
		end
		
		if( hasData and userData.level and userData.level >= self.db.profile.database.ignoreBelow ) then
			self.db.faction.lastModified[name] = time()
			self.db.faction.users[name] = self:WriteTable(userData)
		else
			self.db.faction.lastModified[name] = nil
			self.db.faction.users[name] = nil
		end
	end
end

-- General cache functions that handle figuring out item data
-- Yay metatable caching, can only get gem totals via tooltip scanning, GetItemStats won't return a prismatic socketed item
local statCache = {}
local tooltip = CreateFrame("GameTooltip", "SexyGroupTooltip", UIParent, "GameTooltipTemplate")
tooltip:SetOwner(UIParent, "ANCHOR_NONE")

SexyGroup.EMPTY_GEM_SLOTS = setmetatable({}, {
	__index = function(tbl, link)
		tooltip:SetOwner(UIParent, "ANCHOR_NONE")
		tooltip:SetHyperlink("item:" .. string.match(link, "item:(%d+)"))

		local total = 0
		for i=1, tooltip:NumLines() do
			local text = _G["SexyGroupTooltipTextLeft" .. i]:GetText()
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
			local text = string.lower(_G["SexyGroupTooltipTextLeft" .. i]:GetText())
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
-- Because of how engineering enchants are done, we cannot scan for them. They have to be manually overridden cause Blizzard are jerks.
local ARMOR_MATCH = parseText(ARMOR_TEMPLATE)
local ITEM_SPELL_TRIGGER_ONEQUIP = parseText(ITEM_SPELL_TRIGGER_ONEQUIP)
local ITEM_SPELL_TRIGGER_ONPROC = parseText(ITEM_SPELL_TRIGGER_ONPROC)
local ITEM_SPELL_TRIGGER_ONUSE = parseText(ITEM_SPELL_TRIGGER_ONUSE)
local ITEM_SET_BONUS = parseText(ITEM_SET_BONUS)
local ITEM_HEROIC = parseText(ITEM_HEROIC)
local ITEM_HEROIC_EPIC = parseText(ITEM_HEROIC_EPIC)
local ITEM_REQUIRES_ENGINEERING = string.lower(string.format(ENCHANT_ITEM_REQ_SKILL, (GetSpellInfo(4036))))

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

		-- The first check is we hit the row with an icon anchored to it, this is where gems start
		local stopAt = SexyGroupTooltipTexture1:IsVisible() and select(2, SexyGroupTooltipTexture1:GetPoint())
		local enchantText
		for i=1, tooltip:NumLines() do
			local row = _G["SexyGroupTooltipTextLeft" .. i]
			if( row == stopAt ) then break end

			-- Don't scan anything with right text, this fixes issues where "Main-Hand" is red for the weapon type line
			if( not _G["SexyGroupTooltipTextRight" .. i]:GetText() ) then
				local text = string.lower(row:GetText())
				local r, g, b = row:GetTextColor()
										
				-- If we hit these we're out of stuff
				if( string.match(text, ITEM_SPELL_TRIGGER_ONEQUIP) or string.match(text, ITEM_SPELL_TRIGGER_ONPROC) or string.match(text, ITEM_SPELL_TRIGGER_ONUSE) or string.match(text, ITEM_SET_BONUS) ) then
					break
				-- Should be a valid line, or at least god I hope it is
				elseif( ( r >= 0.97 and g < 0.15 and b < 0.15 ) or ( r == 0 and g >= 0.97 and b == 0 ) ) then
					if( not string.match(text, ARMOR_MATCH) and text ~= ITEM_HEROIC_EPIC and text ~= ITEM_HEROIC ) then
						enchantText = text
						break
					end
				end	
			end
		end
		
		if( not enchantText ) then
			rawset(tbl, link, "unknown")
			return "unknown"
		end
		
		-- Parse out the stats
		local foundData
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

local ITEM_ONEQUIP = "^" .. string.lower(ITEM_SPELL_TRIGGER_ONEQUIP)
local RESILIENCE_MATCH = string.lower(ITEM_MOD_RESILIENCE_RATING_SHORT)
local function getRelicSpecType(link)
	tooltip:SetOwner(UIParent, "ANCHOR_NONE")
	tooltip:SetHyperlink(link)
		
	local equipText
	for i=tooltip:NumLines(), 1, -1 do
		local text = string.lower(_G["SexyGroupTooltipTextLeft" .. i]:GetText())
		if( string.match(text, ITEM_ONEQUIP) ) then
			equipText = text
			break
		end
	end
	
	if( not equipText ) then
		return "unknown"
	elseif( string.match(equipText, RESILIENCE_MATCH) ) then
		return "pvp"
	end

	-- Some relics can be forced into a type by spell, eg Rejuvenation means it's obviously for healers
	-- some relics... actually realy only ferals, are classified as hybrid by doing two things which
	-- is where the stat scanning comes into play
	for spell, type in pairs(SexyGroup.RELIC_SPELLTYPES) do
		if( string.match(equipText, spell) ) then
			return type
		end
	end

	return "unknown"
end

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
		-- Relics need special handling, because they do not have passive stats :(
		elseif( inventoryType == "INVTYPE_RELIC" ) then
			local itemType = getRelicSpecType(link)
			
			rawset(tbl, link, itemType)
			return itemType
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

function SexyGroup:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Sexy Group|r: " .. msg)
end

--@debug@
SexyGroup.L = setmetatable(SexyGroup.L, {
	__index = function(tbl, value)
		rawset(tbl, value, value)
		return value
	end,
})

_G.SexyGroup = SexyGroup
--@end-debug@