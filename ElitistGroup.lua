local ElitistGroup = select(2, ...)
ElitistGroup = LibStub("AceAddon-3.0"):NewAddon(ElitistGroup, "ElitistGroup", "AceEvent-3.0")
local L = ElitistGroup.L

function ElitistGroup:OnInitialize()
	self.defaults = {
		profile = {
			expExpanded = {},
			positions = {},
			general = {
				autoPopup = true,
				autoSummary = false,
				databaseExpanded = true,
				selectedTab = "notes",
			},
			inspect = {
				window = false,
				tooltips = true,
			},
			database = {
				pruneBasic = 30,
				pruneFull = 120,
				saveForeign = true,
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
	
	self.db = LibStub("AceDB-3.0"):New("ElitistGroupDB", self.defaults, true)
	self.db.RegisterCallback(self, "OnDatabaseShutdown", "OnDatabaseShutdown")
	self.db.RegisterCallback(self, "OnDatabaseReset", "OnProfileReset")
	self.db.RegisterCallback(self, "OnProfileShutdown", "OnProfileShutdown")
	self.db.RegisterCallback(self, "OnProfileReset", "OnProfileReset")
	
	self.playerName = string.format("%s-%s", UnitName("player"), GetRealmName())
	self.tooltip = CreateFrame("GameTooltip", "ElitistGroupTooltip", UIParent, "GameTooltipTemplate")
	self.tooltip:Hide()
	
	-- God bless metatables
	self.writeQueue = {}
	self.userData = setmetatable({}, {
		__index = function(tbl, name)
			if( not ElitistGroup.db.faction.users[name] ) then
				tbl[name] = false
				return false
			end
			
			local func, msg = loadstring("return " .. ElitistGroup.db.faction.users[name])
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

	self.ROLE_TANK = 0x04
	self.ROLE_HEALER = 0x02
	self.ROLE_DAMAGE = 0x01
	self.MAX_RATING = 5
	
	-- Data is old enough that we want to remove extra data to save space
	if( self.db.profile.database.pruneBasic > 0 or self.db.database.pruneFull > 0 ) then
		local pruneBasic = time() - (self.db.profile.database.pruneBasic * 86400)
		local pruneFull = time() - (self.db.profile.database.pruneFull * 86400)
		
		for name, modified in pairs(self.db.faction.lastModified) do
			-- Shouldn't happen, but just in case their is a modified field set but not an actual data entry
			if( not self.db.faction.users[name] ) then
				self.db.faction.lastModified[name] = nil
				
			-- Basic pruning, we wipe out any volatile data
			elseif( self.db.profile.database.pruneBasic > 0 and modified <= pruneBasic ) then
				-- If a player has note data on them, then will preserve their entire record, if they don't will just wipe everything out
				local hasNotes
				for note in pairs(self.userData[name].notes) do hasNotes = true break end
				
				if( hasNotes ) then
					local userData = self.userData[name]
					userData.talentTree1 = nil
					userData.talentTree2 = nil
					userData.talentTree3 = nil
					userData.unspentPoints = nil
					userData.specRole = nil
					
					table.wipe(userData.equipment)
					table.wipe(userData.achievements)
					
					userData.pruned = true

					self.db.faction.lastModified[name] = time()
					self.writeQueue[name] = true
				else
					self.db.faction.lastModified[name] = nil
					self.db.faction.users[name] = nil
					self.writeQueue[name] = nil
					self.userData[name] = nil
				end

			-- Full pruning, all data gets removed
			elseif( self.db.profile.database.pruneFull > 0 and modified <= pruneFull ) then
				self.db.faction.lastModified[name] = nil
				self.db.faction.users[name] = nil
				self.writeQueue[name] = nil
				self.userData[name] = nil
			end
		end
	end
		
	if( not ElitistGroup.db.profile.helped ) then
		self:RegisterEvent("PLAYER_ENTERING_WORLD", function()
			ElitistGroup.db.profile.helped = true
			ElitistGroup:Print(L["Welcome! Type /elitistgroup help (or /eg help) to see a list of available slash commands."])
			ElitistGroup:UnregisterEvent("PLAYER_ENTERING_WORLD")
		end)
	end

	self.modules.Sync:Setup()
end

function ElitistGroup:GetItemColor(itemLevel)
	local quality = itemLevel >= 210 and ITEM_QUALITY_EPIC or itemLevel >= 195 and ITEM_QUALITY_RARE or itemLevel >= 170 and ITEM_QUALITY_UNCOMMON or ITEM_QUALITY_COMMON
	return ITEM_QUALITY_COLORS[quality].hex
end

function ElitistGroup:GetItemLink(link)
	return link and string.match(link, "|H(.-)|h")
end

function ElitistGroup:GetItemWithEnchant(link)
	return link and string.match(link, "item:%d+:%d+")
end

function ElitistGroup:GetBaseItemLink(link)
	return link and string.match(link, "item:%d+")
end

function ElitistGroup:GetPlayerID(unit)
	local name, server = UnitName(unit)
	return name and name ~= UNKNOWN and string.format("%s-%s", name, server and server ~= "" and server or GetRealmName())
end

function ElitistGroup:CalculateScore(itemLink, itemQuality, itemLevel)
	-- Quality 7 is heirloom, apply our modifier based on the item level
	if( itemQuality == 7 ) then
		itemLevel = (tonumber(string.match(itemLink, "(%d+)$")) or 1) * ElitistGroup.Items.heirloomLevel
	end
	
	return itemLevel * (self.Items.qualityModifiers[itemQuality] or 1)
end

function ElitistGroup:GetPlayerSpec(playerData)
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
	
	return playerData.specRole or self.Talents.treeData[playerData.classToken][treeOffset], self.Talents.treeData[playerData.classToken][treeOffset + 1], self.Talents.treeData[playerData.classToken][treeOffset + 2] 
end

local tableCache = setmetatable({}, {__mode = "k"})
function ElitistGroup:GetTable()
	return table.remove(tableCache, 1) or {}
end

function ElitistGroup:ReleaseTables(...)	
	for i=1, select("#", ...) do
		local tbl = select(i, ...)
		if( tbl ) then
			table.wipe(tbl)
			table.insert(tableCache, tbl)
		end
	end
end

function ElitistGroup:GetGearSummaryTooltip(equipment, enchantData, gemData)
	local enchantTooltips, gemTooltips = self:GetTable(), self:GetTable()
	
	-- Compile all the gems into tooltips per item
	local lastItemLink, totalBad
	for i=1, #(gemData), 3 do
		local itemLink, gemLink, arg = gemData[gemData[i]], gemData[i + 1], gemData[i + 2]
		
		if( lastItemLink ~= itemLink ) then
			if( lastItemLink ) then
				gemTooltips[lastItemLink] = string.format(L["Gems: |cffff2020[!]|r |cffffffff%d bad|r%s"], totalBad, gemTooltips[lastItemLink])
			end
			
			gemTooltips[itemLink] = ""
			lastItemLink = itemLink
			totalBad = 0
		end
		totalBad = totalBad + 1
				
		if( arg == "missing" ) then
			gemTooltips[itemLink] = gemTooltips[itemLink] .. "\n" .. L["Unused sockets"]
		elseif( type(arg) == "string" ) then
			gemTooltips[itemLink] = gemTooltips[itemLink] .. "\n" .. string.format(L["%s - |cffffffff%s|r gem"], select(2, GetItemInfo(gemLink)) or gemLink, ElitistGroup.Items.itemRoleText[arg] or arg)
		else
			gemTooltips[itemLink] = gemTooltips[itemLink] .. "\n" .. string.format(L["%s - |cffffffff%s|r quality gem"], select(2, GetItemInfo(gemLink)) or gemLink, _G["ITEM_QUALITY" .. arg .. "_DESC"])
		end
	end
	
	-- And grab the last one
	if( lastItemLink ) then
		gemTooltips[lastItemLink] = string.format(L["Gems: |cffff2020[!]|r |cffffffff%d bad|r%s"], totalBad, gemTooltips[lastItemLink])
	end
	
	-- Now compile all the enchants
	for i=1, #(enchantData), 2 do
		local itemLink, enchantTalent = enchantData[enchantData[i]], enchantData[i + 1]
		if( enchantTalent == "missing" ) then
			enchantTooltips[itemLink] = L["Enchant: |cffff2020[!]|r |cffffffffNone found|r"]
		else
			enchantTooltips[itemLink] = string.format(L["Enchant: |cffff2020[!]|r |cffffffff%s enchant|r"], ElitistGroup.Items.itemRoleText[enchantTalent] or enchantTalent)
		end
	end
		
	-- Add the default pass tooltips to anything without them
	for _, link in pairs(equipment) do
		gemTooltips[link] = gemTooltips[link] or self.EMPTY_GEM_SLOTS[link] == 0 and L["Gems: |cffffffffNo sockets|r"] or L["Gems: |cffffffffPass|r"]
		
		enchantTooltips[link] = enchantTooltips[link] or L["Enchant: |cffffffffPass|r"]
	end
	
	return enchantTooltips, gemTooltips
end

function ElitistGroup:GetGeneralSummaryTooltip(gemData, enchantData)
	local tempList = self:GetTable()
	local gemTooltip, enchantTooltip
	local totalLines = 0
	
	-- Gems
	if( gemData.noData ) then
		gemTooltip = L["Gems: |cffffffffFailed to find any gems|r"]
	elseif( gemData.totalBad > 0 ) then
		gemTooltip = string.format(L["Gems: |cffffffff%d bad|r"], gemData.totalBad)
		
		for i=1, #(gemData), 3 do
			local fullItemLink, arg = gemData[i], gemData[i + 2]
			if( arg == "buckle" ) then
				table.insert(tempList, string.format(L["%s - Missing belt buckle or gem"], fullItemLink))
			elseif( arg == "missing" ) then
				table.insert(tempList, string.format(L["%s - Missing gems"], fullItemLink))
			elseif( type(arg) == "string" ) then
				table.insert(tempList, string.format(L["%s - |cffffffff%s|r gem"], fullItemLink, ElitistGroup.Items.itemRoleText[arg] or arg))
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
		enchantTooltip = L["Enchants: |cffffffffThe player does not have any enchants|r"]
	elseif( enchantData.totalBad > 0 ) then
		enchantTooltip = string.format(L["Enchants: |cffffffff%d bad|r"], enchantData.totalBad)
		
		for i=1, #(enchantData), 2 do
			local fullItemLink, enchantTalent = enchantData[i], enchantData[i + 1]
			if( enchantTalent == "missing" ) then
				table.insert(tempList, string.format(L["%s - Unenchanted"], fullItemLink))
			else
				table.insert(tempList, string.format(L["%s - |cffffffff%s|r"], fullItemLink, ElitistGroup.Items.itemRoleText[enchantTalent] or enchantTalent))
			end
		end
		
		table.sort(tempList, sortTable)
		enchantTooltip = enchantTooltip .. "\n" .. table.concat(tempList, "\n")
		totalLines = totalLines + #(tempList)
	end
	
	self:ReleaseTables(tempList)
	
	return gemTooltip or L["Gems: |cffffffffPass|r"], enchantTooltip or L["Enchants: |cffffffffPass|r"], totalLines
end


local MAINHAND_SLOT, OFFHAND_SLOT, WAIST_SLOT = GetInventorySlotInfo("MainHandSlot"), GetInventorySlotInfo("SecondaryHandSlot"), GetInventorySlotInfo("WaistSlot")
function ElitistGroup:GetGearSummary(userData)
	local spec = self:GetPlayerSpec(userData)
	local validSpecTypes = self.Items.talentToSpec[spec]
	local equipment, gems, enchants = self:GetTable(), self:GetTable(), self:GetTable()
	
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
			local baseItemLink, enchantItemLink = string.match(itemLink, "item:%d+"), string.match(itemLink, "item:%d+:(%d+)")
						
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
			local unenchantable = ElitistGroup.Items.unenchantableTypes[itemEquipType]
			if( not unenchantable or type(unenchantable) == "string" and unenchantable == userData.classToken ) then
				enchants.total = enchants.total + 1

				local enchantTalent = ElitistGroup.ENCHANT_TALENTTYPE[enchantItemLink]
				if( enchantTalent ~= "none" ) then
					enchants.totalUsed = enchants.totalUsed + 1
					
					if( enchantTalent ~= "unknown" and validSpecTypes and not validSpecTypes[enchantTalent] ) then
						enchants.totalBad = enchants.totalBad + 1
						enchants[fullItemLink] = itemLink
						enchants.pass = nil
						
						table.insert(enchants, fullItemLink)
						table.insert(enchants, enchantTalent)
					end
				else
					table.insert(enchants, fullItemLink)
					table.insert(enchants, "missing")
					
					enchants[fullItemLink] = itemLink
					enchants.totalBad = enchants.totalBad + 1
					enchants.pass = nil
				end
			end
			
			-- Last but not least, off to the gems
			gems.total = gems.total + self.EMPTY_GEM_SLOTS[itemLink]
			
			local itemUnsocketed = self.EMPTY_GEM_SLOTS[itemLink]
			local alreadyFailed
			for socketID=1, MAX_NUM_SOCKETS do
				local gemLink = ElitistGroup:GetBaseItemLink(select(2, GetItemGem(itemLink, socketID)))
				if( gemLink ) then
					gems.totalUsed = gems.totalUsed + 1
					itemUnsocketed = itemUnsocketed - 1
					
					local gemTalent = self.GEM_TALENTTYPE[gemLink]
					if( gemTalent ~= "unknown" and validSpecTypes and not validSpecTypes[gemTalent] ) then
						table.insert(gems, fullItemLink)
						table.insert(gems, gemLink)
						table.insert(gems, gemTalent)
						
						gems[fullItemLink] = itemLink
						gems.totalBad = gems.totalBad + 1
						gems.pass = nil
					else
						local gemQuality = select(3, GetItemInfo(gemLink))
						if( self.Items.gemQualities[itemQuality] and gemQuality < self.Items.gemQualities[itemQuality] ) then
							gems[fullItemLink] = itemLink
							gems.totalBad = gems.totalBad + 1
							gems.pass = nil

							table.insert(gems, fullItemLink)
							table.insert(gems, gemLink)
							table.insert(gems, gemQuality)
						end
					end
				end
			end	

			if( itemUnsocketed > 0 ) then
				table.insert(gems, fullItemLink)
				table.insert(gems, false)
				table.insert(gems, "missing")
				
				gems.pass = nil
				gems.totalBad = gems.totalBad + 1
				gems[fullItemLink] = itemLink
			end
		end
	end
	
	-- Belt buckles are a special case, you cannot detect them through item links at all or tooltip scanning
	-- what has to be done is scan the base item links sockets
	--[[
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
	]]
	
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

-- Broker plugin
LibStub("LibDataBroker-1.1"):NewDataObject("Elitist Group", {
	type = "launcher",
	icon = "Interface\\Icons\\inv_weapon_glave_01",
	OnClick = function(self, mouseButton)
		-- Inspecting
		if( mouseButton == "LeftButton" ) then
			SlashCmdList["ELITISTGROUP"]("")
		-- Rating
		elseif( IsAltKeyDown() and mouseButton == "RightButton" ) then
			if( GetNumPartyMembers() > 0 ) then
				SlashCmdList["ELITISTGROUPRATE"]("")
			end
		-- Summaries
		elseif( mouseButton == "RightButton" ) then
			if( GetNumRaidMembers() > 0 ) then
				ElitistGroup.modules.RaidSummary:Show()
			elseif( GetNumPartyMembers() > 0 ) then
				ElitistGroup.modules.PartySummary:Show()
			end
		end
	end,
	OnTooltipShow = function(tooltip)
		if( not tooltip ) then return end
		
		tooltip:SetText("Elitist Group")
		tooltip:AddLine(L["Left Click - Open player/target information"], 1, 1, 1, nil, nil)
		
		local instanceType = select(2, IsInInstance())
		if( instanceType == "raid" ) then
			tooltip:AddLine(L["Right Click - Open summary for your raid"], 1, 1, 1, nil, nil)
		elseif( instanceType == "party" ) then
			tooltip:AddLine(L["Right Click - Open summary for your party"], 1, 1, 1, nil, nil)
		end
		
		if( ElitistGroup.modules.RaidHistory.haveActiveGroup ) then
			tooltip:AddLine(L["ALT + Right Click - Open rating window for raid"], 1, 1, 1, nil, nil)
		elseif( ElitistGroup.modules.PartyHistory.haveActiveGroup ) then
			tooltip:AddLine(L["ALT + Right Click - Open rating window for party"], 1, 1, 1, nil, nil)
		end
	end,
})

-- Encodes text in a way that it won't interfere with the table being loaded
local map = {	["{"] = "\\" .. string.byte("{"), ["}"] = "\\" .. string.byte("}"),
				['"'] = "\\" .. string.byte('"'), [";"] = "\\" .. string.byte(";"),
				["%["] = "\\" .. string.byte("["), ["%]"] = "\\" .. string.byte("]"),
				["@"] = "\\" .. string.byte("@")}
function ElitistGroup:SafeEncode(text)
	if( not text ) then return text end
	
	for find, replace in pairs(map) do
		text = string.gsub(text, find, replace)
	end
	
	return text
end

function ElitistGroup:WriteTable(tbl, skipNotes)
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
function ElitistGroup:OnProfileReset()
	table.wipe(self.writeQueue)
	table.wipe(self.userData)
end

-- db:SetProfile called, this is the old profile before it gets switched
function ElitistGroup:OnProfileShutdown()
	self:OnDatabaseShutdown()

	table.wipe(self.writeQueue)
	table.wipe(self.userData)
end

-- Player is logging out, write the cache
function ElitistGroup:OnDatabaseShutdown()
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
		
		if( hasData and userData.level and userData.level >= self.db.profile.database.ignoreBelow and ( self.db.profile.database.saveForeign or userData.server == GetRealmName() ) ) then
			self.db.faction.lastModified[name] = time()
			self.db.faction.users[name] = self:WriteTable(userData)
		else
			self.db.faction.lastModified[name] = nil
			self.db.faction.users[name] = nil
		end
	end
end

function ElitistGroup:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Elitist Group|r: " .. msg)
end

--@debug@
_G.ElitistGroup = ElitistGroup
--@end-debug@