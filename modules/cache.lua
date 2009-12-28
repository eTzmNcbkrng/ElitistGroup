local SexyGroup = select(2, ...)
local Cache = SexyGroup:NewModule("Cache", "AceEvent-3.0")

local CACHE_TIMEOUT = 30 * 60
local statCache, itemMetaTable, gemMetaTable, emptyGemMetaTable, enchantMetaTable = {}
local lastCache = GetTime() + CACHE_TIMEOUT

-- Especially once we start doing mass inspections, the cache will get quite big
-- so every 30 minutes or so on zoning we want to release the old cache tables and let them become GCed
function Cache:OnInitialize()
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function Cache:PLAYER_ENTERING_WORLD()
	if( lastCache > GetTime() ) then return end
	lastCache = GetTime() + CACHE_TIMEOUT
	
	statCache = {}
	SexyGroup.ENCHANT_TALENTTYPE = setmetatable({}, enchantMetaTable)
	SexyGroup.GEM_TALENTTYPE = setmetatable({}, gemMetaTable)
	SexyGroup.EMPTY_GEM_SLOTS = setmetatable({}, emptyGemMetaTable)
	SexyGroup.ITEM_TALENTTYPE = setmetatable({}, itemMetaTable)
end

-- General cache functions that handle figuring out item data
-- Yay metatable caching, can only get gem totals via tooltip scanning, GetItemStats won't return a prismatic socketed item
local tooltip = CreateFrame("GameTooltip", "SexyGroupTooltip", UIParent, "GameTooltipTemplate")
tooltip:SetOwner(UIParent, "ANCHOR_NONE")

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
local ITEM_ONEQUIP = "^" .. string.lower(ITEM_SPELL_TRIGGER_ONEQUIP)
local RESILIENCE_MATCH = string.lower(ITEM_MOD_RESILIENCE_RATING_SHORT)

emptyGemMetaTable = {
	__index = function(tbl, link)
		tooltip:SetOwner(UIParent, "ANCHOR_NONE")
		tooltip:SetHyperlink(link)

		local total = 0
		for i=1, MAX_NUM_SOCKETS do
			local texture = _G["SexyGroupTooltipTexture" .. i]
			if( texture and texture:IsVisible() ) then
				total = total + 1
			end
		end
		
		rawset(tbl, link, total)
		return total
	end,
}

gemMetaTable = {
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
}

enchantMetaTable = {
	__index = function(tbl, link)
		local enchantID = tonumber(string.match(link, "item:%d+:(%d+)"))
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
}

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

itemMetaTable = {
	__index = function(tbl, link)
		local itemID = tonumber(string.match(link, "item:(%d+)"))
		if( itemID and SexyGroup.OVERRIDE_ITEMS[itemID] ) then
			rawset(tbl, link, SexyGroup.OVERRIDE_ITEMS[itemID])
			return SexyGroup.OVERRIDE_ITEMS[itemID]
		end
		
		local inventoryType = select(9, GetItemInfo(link))
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

		-- Failed to identify the item, check everything
		if( inventoryType == "INVTYPE_TRINKET" ) then
			local hasData
			for _ in pairs(statCache) do hasData = true; break end
			
			-- Basically. 99% of trinkets say the stat they increase, regardless of whether it's "chance to increase spell power by X every 20 seconds"
			-- so will find that part of the text and scan it to try and identify what kind of item it is, we only do this if we failed to find it through the stats
			if( not hasData ) then
				local statText
				for i=tooltip:NumLines(), 1, -1 do
					local row = _G["SexyGroupTooltipTextLeft" .. i]
					local text = string.lower(row:GetText())
					local r, g, b = row:GetTextColor()
					
					if( r == 0 and g > 0.97 and b == 0 ) then
						if( string.match(text, ITEM_SPELL_TRIGGER_ONEQUIP) or string.match(text, ITEM_SPELL_TRIGGER_ONPROC) or string.match(text, ITEM_SPELL_TRIGGER_ONUSE) ) then
							statText = text
							break
						end
					end
				end
				
				-- Yay we found the enchant proc
				if( statText ) then
					for key, stat in pairs(SexyGroup.STAT_MAP) do
						if( string.match(enchantText, string.lower(_G[stat])) ) then
							statCache[key] = true
						end
					end
				end
			end
		end

		-- Now scan and figure out what the spec is
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
}

SexyGroup.ENCHANT_TALENTTYPE = setmetatable({}, enchantMetaTable)
SexyGroup.GEM_TALENTTYPE = setmetatable({}, gemMetaTable)
SexyGroup.EMPTY_GEM_SLOTS = setmetatable({}, emptyGemMetaTable)
SexyGroup.ITEM_TALENTTYPE = setmetatable({}, itemMetaTable)