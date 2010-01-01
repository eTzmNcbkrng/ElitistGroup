local SexyGroup = select(2, ...)
SexyGroup = LibStub("AceAddon-3.0"):NewAddon(SexyGroup, "SexyGroup", "AceEvent-3.0", "AceTimer-3.0")
local L = SexyGroup.L

function SexyGroup:OnInitialize()
	self.defaults = {
		profile = {
			expExpanded = {},
			positions = {},
			general = {
				autoPopup = true,
				autoSummary = false,
				databaseExpanded = true,
			},
			database = {
				pruneBasic = 30,
				pruneFull = 120,
				ignoreBelow = 80,
				autoNotes = true,
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
		
	-- God bless metatables
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

-- These are just parser functions to let me trim down the item links to take better advantage of metatable caching
function SexyGroup:GetItemWithEnchant(link)
	return link and string.match(link, "item:%d+:%d+")
end

function SexyGroup:GetBaseItemLink(link)
	return link and string.match(link, "item:%d+")
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

-- Handles caching of tables for variable tick spells, like Wild Growth
local tableCache = setmetatable({}, {__mode = "k"})
local function getTable()
	return table.remove(tableCache, 1) or {}
end

function SexyGroup:DeleteTables(...)	
	for i=1, select("#", ...) do
		local tbl = select(i, ...)
		if( tbl ) then
			table.wipe(tbl)
			table.insert(tableCache, tbl)
		end
	end
end

function SexyGroup:GetGearExtraTooltip(gemData, enchantData)
	local tempList = getTable()
	local gemTooltip, enchantTooltip
	local totalLines = 0
	
	-- Gems
	if( gemData.noData ) then
		gemTooltip = L["Gems: |cffffffffNo gems found. Either the player has no enchants or the enchant data was not found.|r"]
	elseif( gemData.totalBad > 0 ) then
		gemTooltip = string.format(L["Gems: |cffffffff%d bad|r"], gemData.totalBad)
		
		for i=1, #(gemData), 2 do
			local fullItemLink, arg = gemData[i], gemData[i + 1]
			if( arg == "buckle" ) then
				table.insert(tempList, string.format(L["%s - Missing belt buckle or gem"], fullItemLink))
			elseif( arg == "missing" ) then
				table.insert(tempList, string.format(L["%s - Missing gems"], fullItemLink))
			elseif( type(arg) == "string" ) then
				table.insert(tempList, string.format(L["%s - |cffffffff%s|r gem"], fullItemLink, SexyGroup.TALENT_TYPES[arg] or arg))
			else
				table.insert(tempList, string.format(L["%s - |cffffffff%s|r quality gem"], fullItemLink, _G["ITEM_QUALITY" .. arg .. "_DESC"]))
			end
		end
		
		table.sort(tempList, sortTable)
		gemTooltip = gemTooltip .. "\n" .. table.concat(tempList, "\n")
		totalLines = totalLines + #(tempList)
	end
	
	-- Enchants
	table.wipe(tempList)

	if( enchantData.noData ) then
		enchantTooltip = L["Enchants: |cffffffffNo enchants found. Either the player has no enchants or the enchant data was not found.|r"]
	elseif( enchantData.totalBad > 0 ) then
		enchantTooltip = string.format(L["Enchants: |cffffffff%d bad|r"], enchantData.totalBad)
		
		for i=1, #(enchantData), 2 do
			local fullItemLink, enchantTalent = enchantData[i], enchantData[i + 1]
			if( enchantTalent == "missing" ) then
				table.insert(tempList, string.format(L["%s - Unenchanted"], fullItemLink))
			else
				table.insert(tempList, string.format(L["%s - |cffffffff%s|r enchant"], fullItemLink, SexyGroup.TALENT_TYPES[enchantTalent] or enchantTalent))
			end
		end
		
		table.sort(tempList, sortTable)
		enchantTooltip = enchantTooltip .. "\n" .. table.concat(tempList, "\n")
		totalLines = totalLines + #(tempList)
	end
	
	self:DeleteTables(tempList)
	
	return gemTooltip or L["Gems: |cffffffffAll good|r"], enchantTooltip or L["Enchants: |cffffffffAll good|r"], totalLines
end


local MAINHAND_SLOT, OFFHAND_SLOT, WAIST_SLOT = GetInventorySlotInfo("MainHandSlot"), GetInventorySlotInfo("SecondaryHandSlot"), GetInventorySlotInfo("WaistSlot")
function SexyGroup:GetGearSummary(userData)
	local spec = self:GetPlayerSpec(userData)
	local validSpecTypes = self.VALID_SPECTYPES[spec]
	local equipment, gems, enchants = getTable(), getTable(), getTable()
	
	equipment.totalScore = 0
	equipment.totalEquipped = 0
	equipment.totalBad = 0
	equipment.pass = true
	
	enchants.total = 0
	enchants.totalUsed = 0
	enchants.totalBad = 0
	enchants.pass = true
	
	gems.total = 0
	gems.totalUsed = 0
	gems.totalBad = 0
	gems.pass = true
	
	for inventoryID, itemLink in pairs(userData.equipment) do
		local fullItemLink, itemQuality, itemLevel, _, _, _, _, itemEquipType, itemIcon = select(2, GetItemInfo(itemLink))
		if( fullItemLink ) then
			local baseItemLink, enchantItemLink = string.match(itemLink, "item:%d+"), string.match(itemLink, "item:%d+:%d+")
						
			-- Figure out the items primary info
			equipment.totalScore = equipment.totalScore + self:CalculateScore(itemLink, itemQuality, itemLevel)
			equipment.totalEquipped = equipment.totalEquipped + 1
			
			local itemTalent = self.ITEM_TALENTTYPE[baseItemLink]
			if( itemTalent ~= "unknown" and validSpecTypes and not validSpecTypes[itemTalent] ) then
				equipment.pass = nil
				equipment[itemLink] = itemTalent
				equipment.totalBad = equipment.totalBad + 1
			end
			
			-- Either the item is not unenchantable period, or if it's unenchantable for everyone but a specific class
			local unenchantable = SexyGroup.EQUIP_UNECHANTABLE[itemEquipType]
			if( not unenchantable or type(unenchantable) == "string" and unenchantable == userData.classToken ) then
				enchants.total = enchants.total + 1

				local enchantTalent = SexyGroup.ENCHANT_TALENTTYPE[enchantItemLink]
				if( enchantTalent ~= "none" ) then
					enchants.totalUsed = enchants.totalUsed + 1
					
					if( enchantTalent ~= "unknown" and validSpecTypes and not validSpecTypes[enchantTalent] ) then
						enchants.totalBad = enchants.totalBad + 1
						enchants.pass = nil
						
						table.insert(enchants, fullItemLink)
						table.insert(enchants, enchantTalent)
					end
				else
					table.insert(enchants, fullItemLink)
					table.insert(enchants, "missing")
					
					enchants.totalBad = enchants.totalBad + 1
					enchants.pass = nil
				end
			end
			
			-- Last but not least, off to the gems
			gems.total = gems.total + self.EMPTY_GEM_SLOTS[itemLink]
			
			local itemUnsocketed = self.EMPTY_GEM_SLOTS[itemLink]
			local alreadyFailed
			for socketID=1, MAX_NUM_SOCKETS do
				local gemLink = SexyGroup:GetBaseItemLink(select(2, GetItemGem(itemLink, socketID)))
				if( gemLink ) then
					gems.totalUsed = gems.totalUsed + 1
					itemUnsocketed = itemUnsocketed - 1
					
					local gemTalent = self.GEM_TALENTTYPE[gemLink]
					if( gemTalent ~= "unknown" and validSpecTypes and not validSpecTypes[gemTalent] and not alreadyFailed ) then
						table.insert(gems, fullItemLink)
						table.insert(gems, gemTalent)
						
						gems.totalBad = gems.totalBad + 1
						gems.pass = nil
						alreadyFailed = true
						
					elseif( not alreadyFailed ) then
						local gemQuality = select(3, GetItemInfo(gemLink))
						if( SexyGroup.GEM_THRESHOLDS[itemQuality] and gemQuality < SexyGroup.GEM_THRESHOLDS[itemQuality] ) then
							table.insert(gems, fullItemLink)
							table.insert(gems, gemQuality)

							gems.totalBad = gems.totalBad + 1
							gems.pass = nil
							alreadyFailed = true
						end
					end
				end
			end	

			if( itemUnsocketed > 0 ) then
				table.insert(gems, fullItemLink)
				table.insert(gems, "missing")
				gems.pass = nil
				gems.totalBad = gems.totalBad + 1
			end
		end
	end
	
	-- Belt buckles are a special case, you cannot detect them through item links at all or tooltip scanning
	-- what has to be done is scan the base item links sockets
	local itemLink = userData.equipment[WAIST_SLOT]
	if( itemLink and userData.level >= 70 ) then
		local baseSocketCount = self.EMPTY_GEM_SLOTS[self:GetBaseItemLink(itemLink)]
		local gem1, gem2, gem3 = string.match(itemLink, "item:%d+:%d+:(%d+):(%d+):(%d+)")
		local totalSockets = (gem1 ~= "0" and 1 or 0) + (gem2 ~= "0" and 1 or 0) + (gem3 ~= "0" and 1 or 0)
		
		-- If the base empty socket count and the total active socket count is anything except -1, they are missing a belt buckle
		if( totalSockets >= baseSocketCount and (baseSocketCount - totalSockets) ~= -1 ) then
			table.insert(gems, (select(2, GetItemInfo(itemLink))))
			table.insert(gems, "buckle")
			gems.pass = nil
			gems.totalBad = gems.totalBad + 1
		end
	end
	
	-- Try and account for the fact that the inspection can fail to find gems, so if we find 0 gems used will give a warning
	if( gems.total > 0 and gems.totalUsed == 0 ) then
		gems.noData = true
	end
	
	if( enchants.total > 0 and enchants.totalUsed == 0 ) then
		enchants.noData = true
	end
	
	if( equipment.totalEquipped == 0 ) then
		equipment.noData = true
	end
	
	equipment.totalScore = equipment.totalEquipped > 0 and equipment.totalScore / equipment.totalEquipped or 0
	return equipment, enchants, gems
end

-- Encodes text in a way that it won't interfere with the table being loaded
local map = {	["{"] = "\\" .. string.byte("{"), ["}"] = "\\" .. string.byte("}"),
				['"'] = "\\" .. string.byte('"'), [";"] = "\\" .. string.byte(";"),
				["%["] = "\\" .. string.byte("["), ["%]"] = "\\" .. string.byte("]"),
				["@"] = "\\" .. string.byte("@")}
function SexyGroup:SafeEncode(text)
	if( not text ) then return text end
	
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