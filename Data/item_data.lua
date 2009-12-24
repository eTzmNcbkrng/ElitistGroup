local SexyGroup = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("SexyGroup")

-- While it's true that we could apply additional modifiers like 1.05 for legendaries, it's not really necessary because legendaries aren't items
-- that people have 70% of their equipment as that need a modifier to separate them.
SexyGroup.QUALITY_MODIFIERS = {
	[ITEM_QUALITY_POOR] = 0.50,
	[ITEM_QUALITY_COMMON] = 0.60,
	[ITEM_QUALITY_UNCOMMON] = 0.90,
	[ITEM_QUALITY_RARE] = 0.95,
	[ITEM_QUALITY_EPIC] = 1,
}

-- Item level of heirlooms based on the player's level. Currently this is ~2.22/per player level, meaning they work out to 187 item level blues at 80
-- This will have to change come Cataclysm, not quite sure how Blizzard is going to handle heirlooms then
SexyGroup.HEIRLOOM_ILEVEL = (187 / 80) * SexyGroup.QUALITY_MODIFIERS[ITEM_QUALITY_RARE]

SexyGroup.INVENTORY_TO_TYPE = {
	["HeadSlot"] = "head", ["ChestSlot"] = "chest", ["RangedSlot"] = "ranged",
	["WristSlot"] = "wrists", ["Trinket1Slot"] = "trinkets", ["Trinket0Slot"] = "trinkets",
	["MainHandSlot"] = "weapons", ["SecondaryHandSlot"] = "weapons", ["Finger0Slot"] = "rings",
	["Finger1Slot"] = "rings", ["NeckSlot"] = "neck", ["FeetSlot"] = "boots", ["LegsSlot"] = "legs",
	["WaistSlot"] = "waist", ["HandsSlot"] = "hands", ["BackSlot"] = "cloak", ["ShoulderSlot"] = "shoulders",
}

-- Yes, technically you can enchant rings. But we can't accurately figure out if the person is an enchanter
-- while we will rate the enchant if one is present, it won't be flagged as they don't have everything enchanted
SexyGroup.EQUIP_UNECHANTABLE = {["INVTYPE_NECK"] = true, ["INVTYPE_FINGER"] = true, ["INVTYPE_TRINKET"] = true, ["INVTYPE_HOLDABLE"] = true, ["INVTYPE_THROWN"] = true, ["INVTYPE_RELIC"] = true, ["INVTYPE_WAIST"] = true}

SexyGroup.EQUIP_TO_TYPE = {
	["INVTYPE_RANGEDRIGHT"] = "ranged", ["INVTYPE_SHIELD"] = "weapons", ["INVTYPE_WEAPONOFFHAND"] = "weapons",
	["INVTYPE_RANGED"] = "ranged", ["INVTYPE_WEAPON"] = "weapons", ["INVTYPE_2HWEAPON"] = "weapons",
	["INVTYPE_WRIST"] = "wrists", ["INVTYPE_TRINKET"] = "trinkets", ["INVTYPE_NECK"] = "neck",
	["INVTYPE_CLOAK"] = "cloak", ["INVTYPE_HEAD"] = "head", ["INVTYPE_FEET"] = "boots",
	["INVTYPE_SHOULDER"] = "shoulders", ["INVTYPE_WAIST"] = "waist", ["INVTYPE_WEAPONMAINHAND"] = "weapons",
	["INVTYPE_FINGER"] = "rings", ["INVTYPE_THROWN"] = "ranged", ["INVTYPE_HAND"] = "hands",
	["INVTYPE_RELIC"] = "ranged", ["INVTYPE_HOLDABLE"] = "weapons", ["INVTYPE_LEGS"] = "legs",
	["INVTYPE_ROBE"] = "chest", ["INVTYPE_CHEST"] = "chest",
}

SexyGroup.TALENT_ROLES = {["healer"] = L["Healer"], ["caster-dps"] = L["Caster DPS"], ["tank"] = L["Tank"], ["unknown"] = L["Unknown"], ["melee-dps"] = L["Melee DPS"], ["range-dps"] = L["Ranged DPS"]}
SexyGroup.TALENT_TYPES = {["pvp"] = L["PVP"], ["healer"] = L["Healer (All)"], ["caster-dps"] = L["DPS (Caster)"], ["caster"] = L["Caster (All)"], ["tank"] = L["Tank"], ["unknown"] = L["Unknown"], ["melee-dps"] = L["DPS (Melee)"], ["range-dps"] = L["DPS (Ranged)"], ["physical-dps"] = L["DPS (Physical)"], ["melee"] = L["Melee (All)"], ["never"] = L["Always Bad"], ["dps"] = L["DPS (All)"], ["healer/dps"] = L["Healer/DPS"], ["tank/dps"] = L["Tank/DPS"], ["all"] = L["All"]}

SexyGroup.VALID_SPECTYPES = {
	["healer"] = {["all"] = true, ["healer/dps"] = true, ["healer"] = true, ["caster"] = true},
	["caster-dps"] = {["all"] = true, ["tank/dps"] = true, ["healer/dps"] = true, ["dps"] = true, ["caster"] = true, ["caster-dps"] = true},
	["melee-dps"] = {["all"] = true, ["tank/dps"] = true, ["healer/dps"] = true, ["dps"] = true, ["melee-dps"] = true, ["physical-dps"] = true, ["melee"] = true},
	["range-dps"] = {["all"] = true, ["tank/dps"] = true, ["healer/dps"] = true, ["dps"] = true, ["physical-dps"] = true, ["ranged"] = true},
	["tank"] = {["all"] = true, ["tank/dps"] = true, ["tank"] = true, ["melee"] = true},
}


-- As with some items, some enchants have special text that doesn't tell you what they do so we need manual flagging
SexyGroup.OVERRIDE_ENCHANTS = {
	[3870] = "pvp", -- Blood Draining
	[3869] = "tank", -- Blade Ward
	[3232] = "all", -- Tuskarr's Vitality
	[3296] = nil, -- Enhant Cloak - Wisdom, not sure if we want to flag this as a never. Really you should always use cloak - haste
	[3789] = "meleedps", -- Berserking 
	[3790] = "never", -- Black Magic 
	[3247] = "never", -- Scourgebane 
	[3251] = "never", -- Giant Slayer 
	[3239] = "never", -- Icebreaker
	[3241] = "never", -- Lifeward
	[3244] = "caster", -- Greater Vitality
	[846] = "never", -- Angler 
	[3238] = "never", -- Gatherer 
	[2940] = "all", -- Boar's Speed 
	[2939] = "physical-dps", -- Cat's Swiftness 
	[2675] = "never", -- Battlemaster 
	[2674] = "never", -- Spellsurge 
	[910] = "pvp", -- Enchant Cloak - Stealth
	[2621] = "never", -- Enchant Cloak - Subtlety 
	[2613] = "never", -- Enchant Gloves - Threat 
	[1900] = "melee-dps", -- Crusader
	[1896] = "never", -- Lifestealing
	[930] = "never", -- Riding Skill
	[803] = "melee-dps", -- Fiery Weapon
	[3731] = "pvp", -- Titanium Weapon Chain
	[3728] = "caster", -- Darkglow Embroidery
	[3730] = "physical-dps", -- Swordguard Embroidery
	[3748] = "tank", -- Titanium Spike
	[3849] = "tank", -- Titanium plating
	[3878] = "tank", -- Mind Amplification Dish, it is higher STA than the other one, going for the safe flagging for now. Perhaps flag as never?
	[3603] = "tank/dps", -- Hand-Mounted Pyro Rocket
	[3604] = "dps", -- Hyperspeed Accelerators
	[3599] = "never", -- Personal Electromagnetic Pulse Generator
	[3605] = "physical-dps", -- Flexweave Underlay
	[3601] = "never", -- Frag Belt
}

-- Certain items can't be classified with normal stat scans, you can specify a specific type using this
SexyGroup.OVERRIDE_ITEMS = {
	[25899] = "never", -- Brutal Earthstorm Diamond
	[34220] = "dps", -- Chaotic Skyfire Diamond
	[41285] = "dps", -- Chaotic Skyflare Diamond
	[25890] = "never", -- Destructive Skyfire Diamond
	[41307] = "never", -- Destructive Skyflare Diamond
	[25895] = "never", -- Enigmatic Skyfire Diamond
	[41335] = "never", -- Enigmatic Skyflare Diamond
	[44081] = "never", -- Enigmatic Starflare Diamond
	[41378] = "never", -- Forlorn Skyflare Diamond
	[44084] = "never", -- Forlorn Starflare Diamond
	[32641] = "never", -- Imbued Unstable Diamond
	[41379] = "never", -- Impassive Skyflare Diamond
	[44082] = "never", -- Impassive Starflare Diamond
	[41385] = "never", -- Invigorating Earthsiege Diamond
	[25893] = "never", -- Mystical Skyfire Diamond
	[44087] = "never", -- Persistent Earthshatter Diamond
	[41381] = "never", -- Persistent Earthsiege Diamond
	[32640] = "never", -- Potent Unstable Diamond
	[41376] = "never", -- Revitalizing Skyflare Diamond
	[25894] = "never", -- Swift Skyfire Diamond
	[41339] = "never", -- Swift Skyflare Diamond
	[28557] = "never", -- Swift Starfire Diamond
	[44076] = "never", -- Swift Starflare Diamond
	[28556] = "never", -- Swift Windfire Diamond
	[25898] = "never", -- Tenacious Earthstorm Diamond
	[32410] = "never", -- Thundering Skyfire Diamond
	[41400] = "never", -- Thundering Skyflare Diamond
	[41375] = "never", -- Tireless Skyflare Diamond
	[44078] = "never", -- Tireless Starflare Diamond
	[44089] = "never", -- Trenchant Earthshatter Diamond
	[41382] = "never", -- Trenchant Earthsiege Diamond
}

-- Map for checking stats on gems and enchants
SexyGroup.STAT_MAP = {
	RESILIENCE_RATING = ITEM_MOD_RESILIENCE_RATING_SHORT, SPELL_PENETRATION = ITEM_MOD_SPELL_PENETRATION_SHORT, SPELL_HEALING_DONE = ITEM_MOD_SPELL_HEALING_DONE_SHORT,
	HIT_SPELL_RATING = ITEM_MOD_HIT_SPELL_RATING_SHORT, RANGED_ATTACK_POWER = ITEM_MOD_RANGED_ATTACK_POWER_SHORT, CRIT_RANGED_RATING = ITEM_MOD_CRIT_RANGED_RATING_SHORT,
	HIT_RANGED_RATING = ITEM_MOD_HIT_RANGED_RATING_SHORT, DODGE_RATING = ITEM_MOD_DODGE_RATING_SHORT, DEFENSE_SKILL_RATING = ITEM_MOD_DEFENSE_SKILL_RATING_SHORT,
	BLOCK_RATING = ITEM_MOD_BLOCK_RATING_SHORT, BLOCK_VALUE = ITEM_MOD_BLOCK_VALUE_SHORT, EXPERTISE_RATING = ITEM_MOD_EXPERTISE_RATING_SHORT,
	HIT_MELEE_RATING = ITEM_MOD_HIT_MELEE_RATING_SHORT, MELEE_ATTACK_POWER = ITEM_MOD_MELEE_ATTACK_POWER_SHORT, STRENGTH = ITEM_MOD_STRENGTH_SHORT,
	CRIT_MELEE_RATING = ITEM_MOD_CRIT_MELEE_RATING_SHORT, AGILITY = ITEM_MOD_AGILITY_SHORT, ARMOR_PENETRATION_RATING = ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT,
	ATTACK_POWER = ITEM_MOD_ATTACK_POWER_SHORT, POWER_REGEN0 = ITEM_MOD_POWER_REGEN0_SHORT, SPELL_DAMAGE_DONE = ITEM_MOD_SPELL_DAMAGE_DONE_SHORT,
	SPELL_POWER = ITEM_MOD_SPELL_POWER_SHORT, SPIRIT = ITEM_MOD_SPIRIT_SHORT, MANA_REGENERATION = ITEM_MOD_MANA_REGENERATION_SHORT,
	HASTE_SPELL_RATING = ITEM_MOD_HASTE_SPELL_RATING_SHORT, CRIT_SPELL_RATING = ITEM_MOD_CRIT_SPELL_RATING_SHORT, INTELLECT = ITEM_MOD_INTELLECT_SHORT, RESISTANCE0 = RESISTANCE0_NAME,
	STAMINA = ITEM_MOD_STAMINA_SHORT, RESIST = RESIST, CRIT_RATING = ITEM_MOD_CRIT_RATING_SHORT, MANA_REGENERATION = ITEM_MOD_MANA_SHORT, HIT_RATING = ITEM_MOD_HIT_RATING_SHORT,
	HASTE_RATING = ITEM_MOD_HASTE_RATING_SHORT, SPELL_STATALL = SPELL_STATALL, PARRY_RATING = ITEM_MOD_PARRY_RATING_SHORT,
}

-- These are strings returned from GlobalStrings, ITEM_MOD_####_SHORT/####_NAME for GetItemStats, the ordering is important, do not mess with it
SexyGroup.STAT_DATA = {
	{type = "all",			gems = "SPELL_STATALL@", enchants = "SPELL_STATALL@"},
	-- This is my favorite category out of them all
	{type = "never",		gems = "RESIST@"},
	-- Resilience or spell penetration is always a pvp item
	{type = "pvp",			default = "RESILIENCE_RATING@SPELL_PENETRATION@"},
	-- Spell healing is always a healer item, this is the only way to really identify a "pure" healer item
	{type = "healer",		default = "SPELL_HEALING_DONE@"},
	-- Spell hit rating is always a caster dps
	{type = "caster-dps",	default = "HIT_SPELL_RATING@"},
	-- Ranged AP, ranged crit, ranged hit are always ranged
	{type = "ranged",		default = "RANGED_ATTACK_POWER@CRIT_RANGED_RATING@HIT_RANGED_RATING@"},
	-- Dodge, defense, block rating or value are tank items, as well as rings, trinkets or weapons with armor on them
	{type = "tank",			default = "PARRY_RATING@DODGE_RATING@DEFENSE_SKILL_RATING@BLOCK_RATING@BLOCK_VALUE@", gems = "STAMINA@", enchants = "STAMINA@", trinkets = "RESISTANCE0@", weapons = "RESISTANCE0@", rings = "RESISTANCE0"},
	-- Expertise is a melee stat, but it's used by both dps and tanks
	{type = "melee",		default = "EXPERTISE_RATING@"},
	-- Hit melee rating, melee AP, melee crit rating are always melee dps items
	{type = "melee-dps",	default = "HIT_MELEE_RATING@MELEE_ATTACK_POWER@STRENGTH@CRIT_MELEE_RATING"},
	-- Agility, armor pen, general AP are physical DPS
	{type = "physical-dps",	default = "AGILITY@ARMOR_PENETRATION_RATING@ATTACK_POWER@"},
	-- Casters are +mana, mp5, spell power, spell haste, spell crit, spirit or intellect
	{type = "caster",		default = "POWER_REGEN0@SPELL_DAMAGE_DONE@SPELL_POWER@SPIRIT@MANA@MANA_REGENERATION@HASTE_SPELL_RATING@CRIT_SPELL_RATING@INTELLECT@"},
	-- Hybrid, works for DPS and Healers
	{type = "healer/dps",	default = "CRIT_RATING@HASTE_RATING@"},
	-- Hybrid, works for DPS and Tanks
	{type = "tank/dps",		default = "HIT_RATING@"},
}
