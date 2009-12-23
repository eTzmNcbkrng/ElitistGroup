local SexyGroup = select(2, ...)
SexyGroup = LibStub("AceAddon-3.0"):NewAddon(SexyGroup, "SexyGroup", "AceEvent-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("SexyGroup")

function SexyGroup:OnInitialize()
	self.defaults = {
		profile = {
			expExpanded = {},
			pruneAfter = 30,
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
	
	-- Data is old enough that we want to remove extra data to save space
	if( self.db.profile.pruneAfter > 0 ) then
		local pruneBefore = time() - (self.db.profile.pruneAfter * 86400)
		for name, modified in pairs(self.db.faction.lastModified) do
			if( modified <= pruneBefore ) then
				self.db.faction.lastModified[name] = time()
				
				local name, server, level, classToken, notes = self.userData[name].name, self.userData[name].server, self.userData[name].level, self.userData[name].classToken, self.userData[name].notes
				table.wipe(self.userData[name])
				self.userData[name].name = name
				self.userData[name].server = server
				self.userData[name].level = level
				self.userData[name].classToken = classToken
				self.userData[name].notes = notes
				self.userData[name].pruned = true
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
end

function test()
	local testTable = {
		name = "Shadow",
		realm = "Mal'Ganis",
		level = 80,
		classToken = "DRUID",
		talentTree1 = 10,
		talentTree2 = 0,
		talentTree3 = 61,
		specRole = nil,
		from = "Selari",
		trusted = false,
		scanned = 1260940351, -- time()
		achievements = {},
		equipment = {
			[9] = "item:40323:2332:3520:0:0:0:0:1909562656:80",
			[15] = "item:45493:3831:0:0:0:0:0:1071947136:80",
			[13] = "item:37835:0:0:0:0:0:0:2104852352:80",
			[8] = "item:45565:3232:3545:3520:0:0:0:140590272:80",
			[7] = "item:45847:3719:3520:3734:0:0:0:0:80",
			[11] = "item:49486:0:0:0:0:0:0:1347394432:80",
			[18] = "item:40342:0:0:0:0:0:0:0:80",
			[14] = "item:45929:0:0:0:0:0:0:-2054043520:80",
			[1] = "item:45346:3819:3627:3734:0:0:0:0:80",
			[16] = "item:40488:3834:0:0:0:0:0:-1988596908:80",
			[17] = "item:40192:0:0:0:0:0:0:2005934728:80",
			[6] = "item:45556:0:3520:3520:3866:0:0:1962653440:80",
			[5] = "item:46186:3832:3734:3558:0:0:0:0:80",
			[3] = "item:40594:3809:0:0:0:0:0:-1469749462:80",
			[12] = "item:51558:0:0:0:0:0:0:0:80",
			[2] = "item:45822:0:0:0:0:0:0:0:80",
			[10] = "item:45345:3246:3545:0:0:0:0:0:80",
		},
		notes = {
			{
				rating = 5,
				from = "Mayen",
				comment = "The quick brown fox, happens to be quick enough when it's jumping over a very lazy dog.",
				role = bit.bor(SexyGroup.ROLE_HEALER, SexyGroup.ROLE_TANK),
			},
			{
				rating = 4,
				from = "Mayen",
				comment = "Amazing, best there's ever been!",
				role = bit.bor(SexyGroup.ROLE_HEALER, SexyGroup.ROLE_TANK),
			},
			{
				rating = 3,
				from = "Jerkface",
				comment = "Feh!",
				role = SexyGroup.ROLE_DAMAGE,
			},
			{
				rating = 2,
				from = "Jerkface",
				comment = "Feh!",
				role = SexyGroup.ROLE_DAMAGE,
			},
			{
				rating = 1,
				from = "Jerkface",
				comment = "Feh!",
				role = SexyGroup.ROLE_DAMAGE,
			},
			{
				rating = 0,
				from = "Jerkface",
				comment = "Feh!",
				role = SexyGroup.ROLE_DAMAGE, 
			},
		}
	}

	SexyGroup.userData["Shadow-Mal'Ganis"] = CopyTable(testTable)
	SexyGroup.writeQueue["Shadow-Mal'Ganis"] = true
	print("Wrote test data for Shadow - Mal'Ganis")
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

function SexyGroup:IsValidGem(itemLink, playerData)
	local spec = self:GetPlayerSpec(playerData)
	local itemType = self.GEM_TALENTTYPE[itemLink]
	return spec ~= "unknown" and itemType ~= "unknown" and self.VALID_SPECTYPES[spec] and self.VALID_SPECTYPES[spec][itemType]
end

local function writeTable(tbl)
	local data = ""

	for key, value in pairs(tbl) do
		local valueType = type(value)
		
		-- Wrap the key in brackets if it's a number
		if( type(key) == "number" ) then
			key = string.format("[%s]", key)
		-- Wrap the string with quotes if it has a space in it
		elseif( string.match(key, " ") ) then
			key = string.format("[\"%s\"]", key)
		end
		
		-- foo = {bar = 5}
		if( valueType == "table" ) then
			data = string.format("%s%s=%s;", data, key, writeTable(value))
		-- foo = true / foo = 5
		elseif( valueType == "number" or valueType == "boolean" ) then
			data = string.format("%s%s=%s;", data, key, tostring(value))
		-- foo = "bar"
		else
			data = string.format("%s%s=\"%s\";", data, key, tostring(value))
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
		self.db.faction.users[name] = writeTable(self.userData[name])
	end
end

-- General cache functions that handle figuring out item data
-- Yay metatable caching, can only get gem totals via tooltip scanning, GetItemStats won't return a prismatic socketed item
local statCache = {}
local tooltip = CreateFrame("GameTooltip")
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

		tooltip:SetHyperlink(link)
		for i=1, tooltip:NumLines() do
			local text = string.lower(tooltip.TextLeft[i]:GetText())
			for key, stat in pairs(SexyGroup.STAT_MAP) do
				if( string.match(text, string.lower(stat)) ) then
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

		for _, data in pairs(SexyGroup.STAT_DATA) do
			local statString = (data.default or "") .. (data.gems or "")
			if( statString ) then
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
	
		-- Yes yes, I could just store everything in the STAT_DATA using the full key, but I'm lazy and it's ugly
		table.wipe(statCache)
		statCache = GetItemStats(link, statCache)
		for statKey, amount in pairs(statCache) do
			statKey = string.gsub(statKey, "^ITEM_MOD_", "")
			statKey = string.gsub(statKey, "_SHORT$", "")
			statKey = string.gsub(statKey, "_NAME$", "")
			statCache[string.trim(statKey)] = amount
		end

		for _, data in pairs(SexyGroup.STAT_DATA) do
			local statString = data[equipType] or data.default
			if( statString ) then
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

function SexyGroup:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Sexy Group|r: " .. msg)
end

SLASH_SEXYGROUP1 = "/sexygroup"
SLASH_SEXYGROUP2 = "/sg"
SLASH_SEXYGROUP3 = "/sexygroups"
SlashCmdList["SEXYGROUP"] = function(msg)
	local arg = string.trim(string.lower(msg or ""))
	if( arg == "config" ) then
		print("Nothing to see here yet.")
		return
	end
	
	if( arg == "" ) then arg = string.format("%s-%s", UnitName("player"), GetRealmName()) end
	
	local data
	local search = not string.match(arg, "%-") and string.format("^%s%%-", arg)
	for name in pairs(SexyGroup.db.faction.users) do
		if( ( search and string.match(string.lower(name), search) ) or ( string.lower(name) == arg ) ) then
			data = SexyGroup.userData[name]
			break
		end
	end
	
	if( not data ) then
		SexyGroup:Print(string.format(L["Cannot find record of %s in your saved database."], msg))
		return
	end
	
	SexyGroup.modules.Users:LoadData(data)
	
end

--@debug@
_G.SexyGroup = SexyGroup
--@end-debug@
