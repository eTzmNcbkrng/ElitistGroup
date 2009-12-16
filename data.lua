local L = LibStub("AceLocale-3.0"):GetLocale("SexyGroup")

SexyGroup.ROLE_TANK = 0x04
SexyGroup.ROLE_HEALER = 0x02
SexyGroup.ROLE_DAMAGE = 0x01
SexyGroup.MAX_RATING = 5

-- Simple map of valid achievements
SexyGroup.VALID_ACHIEVEMENTS = {}
for _, data in pairs(SexyGroup.EXPERIENCE_POINTS) do
	for achievementID in pairs(data) do
		if( type(achievementID) == "number" ) then
			SexyGroup.VALID_ACHIEVEMENTS[achievementID] = true
		end
	end
end

-- While it's true that we could apply additional modifiers like 1.05 for legendaries, it's not really necessary because legendaries aren't items
-- that people have 70% of their equipment as that need a modifier to separate them.
SexyGroup.QUALITY_MODIFIERS = {
	[ITEM_QUALITY_POOR] = 0.70,
	[ITEM_QUALITY_COMMON] = 0.75,
	[ITEM_QUALITY_UNCOMMON] = 0.80,
	[ITEM_QUALITY_RARE] = 0.95,
	[ITEM_QUALITY_EPIC] = 1,
}
 
-- Tree names
SexyGroup.TREE_DATA = {
	["SHAMAN"] = {
		"casterdps", L["Elemental"], "Interface\\Icons\\Spell_Nature_Lightning",
		"meleedps", L["Enhancement"], "Interface\\Icons\\Spell_Nature_LightningShield",
		"healer", L["Restoration"], "Interface\\Icons\\Spell_Nature_MagicImmunity",
	},
	["MAGE"] = {
		"casterdps", L["Arcane"], "Interface\\Icons\\Spell_Holy_MagicalSentry",
		"casterdps", L["Fire"], "Interface\\Icons\\Spell_Fire_FlameBolt", 
		"casterdps", L["Frost"], "Interface\\Icons\\Spell_Frost_FrostBolt02",
	},
	["WARLOCK"] = {
		"casterdps", L["Affliction"], "Interface\\Icons\\Spell_Shadow_DeathCoil",
		"casterdps", L["Demonology"], "Interface\\Icons\\Spell_Shadow_Metamorphosis",
		"casterdps", L["Destruction"], "Interface\\Icons\\Spell_Shadow_RainOfFire",
	},
	["DRUID"] = {
		"casterdps", L["Balance"], "Interface\\Icons\\Spell_Nature_Lightning",
		"meleedps", L["Feral"], "Interface\\Icons\\Ability_Racial_BearForm",
		"healer", L["Restoration"], "Interface\\Icons\\Spell_Nature_HealingTouch",
	},
	["WARRIOR"] = {
		"meleedps", L["Arms"], "Interface\\Icons\\Ability_Rogue_Eviscerate", 
		"meleedps", L["Fury"], "Interface\\Icons\\Ability_Warrior_InnerRage", 
		"tank", L["Protection"], "Interface\\Icons\\INV_Shield_06",
	},
	["ROGUE"] = {
		"meleedps", L["Assassination"], "Interface\\Icons\\Ability_Rogue_Eviscerate",
		"meleedps", L["Combat"], "Interface\\Icons\\Ability_BackStab", 
		"meleedps", L["Subtlety"], "Interface\\Icons\\Ability_Stealth",
	},
	["PALADIN"] = {
		"healer", L["Holy"], "Interface\\Icons\\Spell_Holy_HolyBolt", 
		"tank", L["Protection"], "Interface\\Icons\\Spell_Holy_DevotionAura",
		"meleedps", L["Retribution"], "Interface\\Icons\\Spell_Holy_AuraOfLight",
	},
	["HUNTER"] = {
		"rangeddps", L["Beast Mastery"], "Interface\\Icons\\Ability_Hunter_BeastTaming",
		"rangeddps", L["Marksmanship"], "Interface\\Icons\\Ability_Marksmanship",
		"rangeddps", L["Survival"], "Interface\\Icons\\Ability_Hunter_SwiftStrike",
	},
	["PRIEST"] = {
		"healer", L["Discipline"], "Interface\\Icons\\Spell_Holy_WordFortitude",
		"healer", L["Holy"], "Interface\\Icons\\Spell_Holy_HolyBolt",
		"casterdps", L["Shadow"], "Interface\\Icons\\Spell_Shadow_ShadowWordPain",
	},
	-- Death Knights will be overriden as tanks if they match at least 2 tank talents
	["DEATHKNIGHT"] = {
		"meleedps", L["Blood"], "Interface\\Icons\\Spell_Shadow_BloodBoil",
		"meleedps", L["Frost"], "Interface\\Icons\\Spell_Frost_FrostNova",
		"meleedps", L["Unholy"], "Interface\\Icons\\Spell_Shadow_ShadeTrueSight",
	},
}

SexyGroup.INVENTORY_TO_TYPE = {
	["HeadSlot"] = "head", ["ChestSlot"] = "chest", ["RangedSlot"] = "ranged",
	["WristSlot"] = "wrists", ["Trinket1Slot"] = "trinkets", ["Trinket0Slot"] = "trinkets",
	["MainHandSlot"] = "weapons", ["SecondaryHandSlot"] = "weapons", ["Finger0Slot"] = "rings",
	["Finger1Slot"] = "rings", ["NeckSlot"] = "neck", ["FeetSlot"] = "boots", ["LegsSlot"] = "legs",
	["WaistSlot"] = "waist", ["HandsSlot"] = "hands", ["BackSlot"] = "cloak", ["ShoulderSlot"] = "shoulders",
}

local EQUIP_TO_TYPE = {
	["INVTYPE_RANGEDRIGHT"] = "ranged", ["INVTYPE_SHIELD"] = "weapons", ["INVTYPE_WEAPONOFFHAND"] = "weapons",
	["INVTYPE_RANGED"] = "ranged", ["INVTYPE_WEAPON"] = "weapons", ["INVTYPE_2HWEAPON"] = "weapons",
	["INVTYPE_WRIST"] = "wrists", ["INVTYPE_TRINKET"] = "trinkets", ["INVTYPE_NECK"] = "neck",
	["INVTYPE_CLOAK"] = "cloak", ["INVTYPE_HEAD"] = "head", ["INVTYPE_FEET"] = "boots",
	["INVTYPE_SHOULDER"] = "shoulders", ["INVTYPE_WAIST"] = "waist", ["INVTYPE_WEAPONMAINHAND"] = "weapons",
	["INVTYPE_FINGER"] = "rings", ["INVTYPE_THROWN"] = "ranged", ["INVTYPE_HAND"] = "hands",
	["INVTYPE_RELIC"] = "ranged", ["INVTYPE_HOLDABLE"] = "weapons", ["INVTYPE_LEGS"] = "legs",
	["INVTYPE_ROBE"] = "chest", ["INVTYPE_CHEST"] = "chest",
}

SexyGroup.TALENT_ROLES = {["healer"] = L["Healer"], ["casterdps"] = L["Caster DPS"], ["tank"] = L["Tank"], ["unknown"] = L["Unknown"], ["meleedps"] = L["Melee DPS"], ["rangeddps"] = L["Ranged DPS"]}


SexyGroup.TALENT_TYPES = {["pvp"] = L["PVP"], ["healer"] = L["Healer (All)"], ["casterdps"] = L["DPS (Caster)"], ["caster"] = L["Caster (All)"], ["tank"] = L["Tank"], ["unknown"] = L["Unknown"], ["meleedps"] = L["DPS (Melee)"], ["rangeddps"] = L["DPS (Ranged)"], ["physicaldps"] = L["DPS (Physical)"], ["melee"] = L["Melee (All)"]}

SexyGroup.VALID_SPECTYPES = {
	["healer"] = {["healer"] = true, ["caster"] = true},
	["casterdps"] = {["caster"] = true, ["casterdps"] = true},
	["meleedps"] = {["meleedps"] = true, ["physicaldps"] = true, ["melee"] = true},
	["rangeddps"] = {["physicaldps"] = true, ["ranged"] = true},
	["tank"] = {["tank"] = true, ["melee"] = true},
}

-- These are strings returned from GlobalStrings, ITEM_MOD_####_SHORT/####_NAME for GetItemStats, the ordering *IS* important, do not mess with it
local STAT_DATA = {
	-- Resilience or spell penetration is always a pvp item
	{type = "pvp",			default = "RESILIENCE_RATING@SPELL_PENETRATION@"},
	-- Spell healing is always a healer item, this is the only way to really identify a "pure" healer item
	{type = "healer",		default = "SPELL_HEALING_DONE@"},
	-- Spell hit rating is always a caster dps
	{type = "casterdps",	default = "HIT_SPELL_RATING@"},
	-- Ranged AP, ranged crit, ranged hit are always ranged
	{type = "ranged",		default = "RANGED_ATTACK_POWER@CRIT_RANGED_RATING@HIT_RANGED_RATING@"},
	-- Dodge, defense, block rating or value are tank items, as well as rings, trinkets or weapons with armor on them
	{type = "tank",			default = "DODGE_RATING@DEFENSE_SKILL_RATING@BLOCK_RATING@BLOCK_VALUE@", trinkets = "RESISTANCE0@", weapons = "RESISTANCE0@", rings = "RESISTANCE0"},
	-- Expertise is a melee stat, but it's used by both dps and tanks
	{type = "melee",		default = "EXPERTISE_RATING@"},
	-- Hit melee rating, melee AP, melee crit rating are always melee dps items
	{type = "meleedps",		default = "HIT_MELEE_RATING@MELEE_ATTACK_POWER@STRENGTH@CRIT_MELEE_RATING"},
	-- Agility, armor pen, general AP are physical DPS
	{type = "physicaldps",	default = "AGILITY@ARMOR_PENETRATION_RATING@ATTACK_POWER@"},
	-- Casters are +mana, mp5, spell power, spell haste, spell crit, spirit or intellect
	{type = "caster",		default = "POWER_REGEN0@SPELL_DAMAGE_DONE@SPELL_POWER@SPIRIT@MANA@MANA_REGENERATION@HASTE_SPELL_RATING@CRIT_SPELL_RATING@INTELLECT@"},
}

-- Yay metatable caching, can only get gem totals via tooltip scanning, GetItemStats won't return a prismatic socketed item
local tooltip = CreateFrame("GameTooltip")
tooltip:SetOwner(UIParent, "ANCHOR_NONE")
for i=1, 20 do
	tooltip.TextLeft1 = tooltip:CreateFontString()
	tooltip.TextRight1 = tooltip:CreateFontString()
	tooltip:AddFontStrings(tooltip.TextLeft1, tooltip.TextRight1)
end

SexyGroup.TOTAL_GEMSLOTS = setmetatable({}, {
	__index = function(tbl, link)
		tooltip:SetHyperlink("item:" .. string.match(link, "item:(%d+)"))

		local total = 0
		for i=1, tooltip:NumLines() do
			local text = tooltip["TextLeft" .. i]:GetText()
			if( text == EMPTY_SOCKET_BLUE or text == EMPTY_SOCKET_META or text == EMPTY_SOCKET_NO_COLOR or text == EMPTY_SOCKET_RED or text == EMPTY_SOCKET_YELLOW ) then
				total = total + 1
			end
		end
		
		rawset(tbl, link, total)
		return total
	end,
})

local statCache = {}
SexyGroup.ITEM_TALENTTYPE = setmetatable({}, {
	__index = function(tbl, link)
		local inventoryType = select(9, GetItemInfo(link))
		local equipType = inventoryType and EQUIP_TO_TYPE[inventoryType]
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

		for _, data in pairs(STAT_DATA) do
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
		
-- normal/heroic is for separating the dungeons like TotC/TotGC, hard will be for dungeons like Ulduar or Sartharion with hard modes on heroic
SexyGroup.DUNGEON_TYPES = {["normal"] = L["Normal"], ["heroic"] = L["Heroic"], ["hard"] = L["Hard"]}
local MOD = 0.87
SexyGroup.DUNGEON_DATA = {
	L["T7 Dungeons"],					200 * MOD, 5,	"heroic",
	L["Sartharion"],					200 * MOD, 10,	"normal",
	L["Naxxramas"],						200 * MOD, 10,	"normal",
	L["Archavon, Vault"],				200 * MOD, 10,	"normal",
	L["Naxxramas"],						213 * MOD, 25,	"normal",
	L["Malygos"], 						213 * MOD, 10,	"normal",
	L["Archavon, Vault"],				213 * MOD, 25,	"normal",
	L["Ulduar"], 						219 * MOD, 10,	"normal",
	L["Emalon, Vault"],					219 * MOD, 10,	"normal",
	L["T9 Dungeons"],					219 * MOD, 5,	"heroic",
	L["Ulduar"],						226 * MOD, 10,	"heroic",
	L["Ulduar"], 						226 * MOD, 25,	"normal",
	L["Emalon, Vault"], 				226 * MOD, 25,	"normal",
	L["Malygos"], 						226 * MOD, 25,	"normal",
	L["Sartharion"], 					226 * MOD, 25,	"normal",
	L["T10 Dungeons"], 					232 * MOD, 5,	"heroic",
	L["Koralon, Vault"],				232 * MOD, 10,	"normal",
	L["Trial of the Crusader"],			232 * MOD, 10,	"normal",
	L["Onyxia's Lair"], 				232 * MOD, 10,	"normal",
	L["Ulduar"],						239 * MOD, 25,	"heroic",
	L["Onyxia's Lair"], 				245 * MOD, 25,	"normal",
	L["Trial of the Grand Crusader"],	245 * MOD, 10,	"heroic",
	L["Koralon, Vault"], 				245 * MOD, 25,	"normal",
	L["Trial of the Crusader"],			245 * MOD, 25,	"normal",
	L["Icecrown Citadel"], 				251 * MOD, 10,	"normal",
	L["Trial of the Grand Crusader"],	258 * MOD, 25,	"heroic",
	L["Icecrown Citadel"],				264 * MOD, 10,	"heroic",
	L["Icecrown Citadel"], 				264 * MOD, 25,	"normal", 
	L["Icecrown Citadel"], 				277 * MOD, 25,	"heroic",
}

-- I'm lazy!
SexyGroup.DUNGEON_MIN = 1000
SexyGroup.DUNGEON_MAX = 0
for i=2, #(SexyGroup.DUNGEON_DATA), 4 do
	SexyGroup.DUNGEON_DATA[i] = math.floor(SexyGroup.DUNGEON_DATA[i])
	SexyGroup.DUNGEON_MIN = math.min(SexyGroup.DUNGEON_MIN, SexyGroup.DUNGEON_DATA[i])
	SexyGroup.DUNGEON_MAX = math.max(SexyGroup.DUNGEON_MAX, SexyGroup.DUNGEON_DATA[i])
end

SexyGroup.DUNGEON_DIFF = SexyGroup.DUNGEON_MAX - SexyGroup.DUNGEON_MIN
