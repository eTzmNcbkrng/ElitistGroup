SexyGroup = LibStub("AceAddon-3.0"):NewAddon("SexyGroup", "AceEvent-3.0", "AceTimer-3.0")
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