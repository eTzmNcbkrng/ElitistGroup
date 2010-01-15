local ElitistGroup = select(2, ...)
local L = ElitistGroup.L
local _G = getfenv(0)

local function loadData()
	local Items = ElitistGroup.Items
	-- While it's true that we could apply additional modifiers like 1.05 for legendaries, it's not really necessary because legendaries aren't items
	-- that people have 70% of their equipment as that need a modifier to separate them.
	ElitistGroup.Items.qualityModifiers = {
		[ITEM_QUALITY_POOR] = 0.50,
		[ITEM_QUALITY_COMMON] = 0.60,
		[ITEM_QUALITY_UNCOMMON] = 0.90,
		[ITEM_QUALITY_RARE] = 0.95,
		[ITEM_QUALITY_EPIC] = 1,
	}

	-- Specific override, epic items must have a rare or higher quality gem in them
	ElitistGroup.Items.gemQualities = {
		[ITEM_QUALITY_EPIC] = ITEM_QUALITY_RARE,
	}

	-- Item level of heirlooms based on the player's level. Currently this is ~2.22/per player level, meaning they work out to 187 item level blues at 80
	-- with the quality modifier they are item level ~177
	-- This will have to change come Cataclysm, not quite sure how Blizzard is going to handle heirlooms then
	ElitistGroup.Items.heirloomLevel = (187 / 80)

	ElitistGroup.Items.inventoryToID = {
		["HeadSlot"] = "head", ["ChestSlot"] = "chest", ["RangedSlot"] = "ranged",
		["WristSlot"] = "wrists", ["Trinket1Slot"] = "trinkets", ["Trinket0Slot"] = "trinkets",
		["MainHandSlot"] = "weapons", ["SecondaryHandSlot"] = "weapons", ["Finger0Slot"] = "rings",
		["Finger1Slot"] = "rings", ["NeckSlot"] = "neck", ["FeetSlot"] = "boots", ["LegsSlot"] = "legs",
		["WaistSlot"] = "waist", ["HandsSlot"] = "hands", ["BackSlot"] = "cloak", ["ShoulderSlot"] = "shoulders",
	}

	ElitistGroup.Items.validInventorySlots = {}
	for slotType in pairs(ElitistGroup.Items.inventoryToID) do
		ElitistGroup.Items.validInventorySlots[GetInventorySlotInfo(slotType)] = slotType
	end

	-- Yes, technically you can enchant rings. But we can't accurately figure out if the person is an enchanter
	-- while we will rate the enchant if one is present, it won't be flagged as they don't have everything enchanted
	-- Setting a class token means that it's unenchantable for everyone except that class
	ElitistGroup.Items.unenchantableTypes = {
		["INVTYPE_NECK"] = true, ["INVTYPE_FINGER"] = true, ["INVTYPE_TRINKET"] = true, ["INVTYPE_HOLDABLE"] = true, ["INVTYPE_THROWN"] = true, ["INVTYPE_RELIC"] = true, ["INVTYPE_WAIST"] = true,
		["INVTYPE_RANGEDRIGHT"] = "HUNTER",
		["INVTYPE_RANGED"] = "HUNTER",
	}

	ElitistGroup.Items.equipToType = {
		["INVTYPE_RANGEDRIGHT"] = "ranged", ["INVTYPE_SHIELD"] = "weapons", ["INVTYPE_WEAPONOFFHAND"] = "weapons",
		["INVTYPE_RANGED"] = "ranged", ["INVTYPE_WEAPON"] = "weapons", ["INVTYPE_2HWEAPON"] = "weapons",
		["INVTYPE_WRIST"] = "wrists", ["INVTYPE_TRINKET"] = "trinkets", ["INVTYPE_NECK"] = "neck",
		["INVTYPE_CLOAK"] = "cloak", ["INVTYPE_HEAD"] = "head", ["INVTYPE_FEET"] = "boots",
		["INVTYPE_SHOULDER"] = "shoulders", ["INVTYPE_WAIST"] = "waist", ["INVTYPE_WEAPONMAINHAND"] = "weapons",
		["INVTYPE_FINGER"] = "rings", ["INVTYPE_THROWN"] = "ranged", ["INVTYPE_HAND"] = "hands",
		["INVTYPE_RELIC"] = "ranged", ["INVTYPE_HOLDABLE"] = "weapons", ["INVTYPE_LEGS"] = "legs",
		["INVTYPE_ROBE"] = "chest", ["INVTYPE_CHEST"] = "chest",
	}

	ElitistGroup.Items.itemRoleText = {["pvp"] = L["PVP"], ["healer"] = L["Healer (All)"], ["caster-dps"] = L["DPS (Caster)"], ["caster"] = L["Caster (All)"], ["tank"] = L["Tank"], ["unknown"] = L["Unknown"], ["melee-dps"] = L["DPS (Melee)"], ["range-dps"] = L["DPS (Ranged)"], ["physical-dps"] = L["DPS (Physical)"], ["melee"] = L["Melee (All)"], ["never"] = L["Always bad"], ["dps"] = L["DPS (All)"], ["healer/dps"] = L["Healer/DPS"], ["tank/dps"] = L["Tank/DPS"], ["all"] = L["All"], ["physical-all"] = L["Physical (All)"], ["tank/pvp"] = L["Tank/PVP"], ["caster-spirit"] = L["Caster (Spirit)"], ["disc-priest"] = L["Priest (Discipline)"], ["manaless"] = L["Disc Priest/Druid"]}

	ElitistGroup.Items.talentToRole = {
		["mp5-healer"] = {["all"] = true, ["healer/dps"] = true, ["healer"] = true, ["caster"] = true},
		["healer"] = {["caster-spirit"] = true, ["all"] = true, ["healer/dps"] = true, ["healer"] = true, ["caster"] = true},
		["caster-dps"] = {["caster-spirit"] = true, ["all"] = true, ["tank/dps"] = true, ["healer/dps"] = true, ["dps"] = true, ["caster"] = true, ["caster-dps"] = true},
		["melee-dps"] = {["all"] = true, ["physical-all"] = true, ["tank/dps"] = true, ["healer/dps"] = true, ["dps"] = true, ["melee-dps"] = true, ["physical-dps"] = true, ["melee"] = true},
		["range-dps"] = {["all"] = true, ["physical-all"] = true, ["tank/dps"] = true, ["healer/dps"] = true, ["dps"] = true, ["physical-dps"] = true, ["ranged"] = true},
		["tank"] = {["tank/pvp"] = true, ["all"] = true, ["physical-all"] = true, ["tank/dps"] = true, ["tank"] = true, ["melee"] = true},
		["feral-tank"] = {["pvp"] = true},
		["dk-tank"] = false, -- Set below
		["disc-priest"] = false,
		["resto-druid"] = false, 
		["balance-druid"] = false,
	}
		
	ElitistGroup.Items.talentToRole["dk-tank"] = ElitistGroup.Items.talentToRole.tank
	ElitistGroup.Items.talentToRole["disc-priest"] = CopyTable(ElitistGroup.Items.talentToRole.healer)
	ElitistGroup.Items.talentToRole["disc-priest"].manaless = true
	ElitistGroup.Items.talentToRole["resto-druid"] = CopyTable(ElitistGroup.Items.talentToRole.healer)
	ElitistGroup.Items.talentToRole["resto-druid"].manaless = true
	ElitistGroup.Items.talentToRole["balance-druid"] = CopyTable(ElitistGroup.Items.talentToRole["caster-dps"])	
	ElitistGroup.Items.talentToRole["balance-druid"].manaless = true

	-- Unfortunately ferals are a pain, because of how they work they essentially are going to wear a mix of tank gear and DPS gear which is still valid for them
	for type in pairs(ElitistGroup.Items.talentToRole["melee-dps"]) do ElitistGroup.Items.talentToRole["feral-tank"][type] = true end
	for type in pairs(ElitistGroup.Items.talentToRole["tank"]) do ElitistGroup.Items.talentToRole["feral-tank"][type] = true end

	-- This will likely have to be cleaned up, but for now this will allow overrides on what is allowed based on slot
	ElitistGroup.Items.roleOverrides = {
		["dk-tank"] = {type = "weapons", ["physical-dps"] = true, ["dps"] = true, ["melee-dps"] = true}
	}

	local function getSpell(id)
		local name = GetSpellInfo(id)
		--@debug@
		if( not name ) then
			print(string.format("Failed to find spell id #%d in Sexy Group.", id or 0))
			return "<error>"
		end
		--@end-debug@
		
		return string.lower(name)
	end

	-- Hybrid relics should be listed in Items.itemOverrides
	ElitistGroup.Items.relicSpells = {
		[getSpell(24974)] = "caster-dps", -- Insect Swarm
		[getSpell(8921)] = "caster-dps", -- Moonfire
		[getSpell(2912)] = "caster-dps", -- Starfire
		[getSpell(5176)] = "caster-dps", -- Wrath
		[getSpell(6807)] = "feral-tank", -- Maul
		[getSpell(50256)] = "tank/dps", -- Swipe
		[getSpell(33917)] = "tank/dps", -- Mangle
		[getSpell(1079) .. " "] = "melee-dps", -- Rip, the space is to stop this from matching "Riptide"
		[getSpell(5221)] = "melee-dps", -- Shred
		[getSpell(774)] = "healer", -- Rejuvenation
		[getSpell(8936)] = "healer", -- Regrowth
		[getSpell(33763)] = "healer", -- Lifebloom
		[getSpell(48438)] = "healer", -- Wild Growth
		[getSpell(50464)] = "healer", -- Nourish
		[getSpell(5185)] = "healer", -- Healing Touch
		
		[getSpell(635)] = "healer", -- Holy Light
		[getSpell(19750)] = "healer", -- Flash of Light
		[getSpell(20929)] = "healer", -- Holy Shock
		[getSpell(35395)] = "melee-dps", -- Crusader Strike
		[getSpell(53385)] = "melee-dps", -- Divine Storm
		[getSpell(53600)] = "tank", -- Shield of Righteousness
		[getSpell(53595)] = "tank", -- Hammer of the Rightousness
		[getSpell(31801)] = "tank", -- Seal of Vengeance
		[getSpell(53736)] = "tank", -- Seal of Corruption
		[getSpell(20925)] = "tank", -- Holy Shield
		[getSpell(26573)] = "tank/dps", -- Consecration
		
		[getSpell(61295)] = "healer", -- Riptide
		[getSpell(1064)] = "healer", -- Chain Heal
		[getSpell(331)] = "healer", -- Healing Wave
		[getSpell(8004)] = "healer", -- Lesser Healing Wave
		[getSpell(8050)] = "caster-dps", -- Flame Shock
		[getSpell(17364)] = "melee-dps", -- Stormstrike
		[getSpell(60103)] = "melee-dps", -- Lava Lash
		[getSpell(403)] = "caster-dps", -- Lightning Bolt
		[getSpell(421)] = "caster-dps", -- Chain Lightning
		[getSpell(51505)] = "caster-dps", -- Lava Burst
		[getSpell(8232)] = "melee-dps", -- Windfury Weapon
			
		[getSpell(56815)] = "tank", -- Rune Strike
		[getSpell(45902)] = "melee-dps", -- Blood Strike
		[getSpell(55258)] = "melee-dps", -- Heart Strike
		[getSpell(45477)] = "melee-dps", -- Icy Touch
		[getSpell(45462)] = "melee-dps", -- Plague Strike
		[getSpell(66198)] = "melee-dps", -- Obliterate
		[getSpell(49998)] = "melee-dps", -- Death Strike
		[getSpell(49892)] = "melee-dps", -- Death Coil
		[getSpell(55265)] = "melee-dps", -- Scourge Strike
		
	}

	-- As with some items, some enchants have special text that doesn't tell you what they do so we need manual flagging
	ElitistGroup.Items.enchantOverrides = {
		[3826] = "all", -- Icewalker
		[3253] = "tank", -- Armsman
		[3852] = "tank/pvp", -- Greater Inscription of the Gladiator
		[3225] = "dps", -- Executioner
		[3870] = "tank/pvp", -- Blood Draining
		[3869] = "tank", -- Blade Ward
		[3232] = "all", -- Tuskarr's Vitality
		[3296] = nil, -- Enhant Cloak - Wisdom, not sure if we want to flag this as a never. Really you should always use cloak - haste
		[3789] = "melee-dps", -- Berserking 
		[3790] = "dps", -- Black Magic 
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
		[3731] = "tank/pvp", -- Titanium Weapon Chain
		[3788] = "tank", -- Accuracy
		[3728] = "caster", -- Darkglow Embroidery
		[3730] = "physical-dps", -- Swordguard Embroidery
		[3722] = "caster", -- Lightweave Embroidery
		[3748] = "tank", -- Titanium Spike
		[3849] = "tank", -- Titanium Plating
		[2673] = "tank/dps", -- Mongoose
		[3606] = "all", -- Nitro Boosts
		[3860] = "tank", -- Reticulated Armor Webbing
		[3599] = "never", -- Personal Elctromagnetic Pulse Generator
		[3859] = "caster", -- Springy Archnoweave
		[3878] = "tank", -- Mind Amplification Dish, it is higher STA than the other one, going for the safe flagging for now. Perhaps flag as never?
		[3603] = "tank/dps", -- Hand-Mounted Pyro Rocket
		[3604] = "healer/dps", -- Hyperspeed Accelerators
		[3599] = "never", -- Personal Electromagnetic Pulse Generator
		[3605] = "physical-all", -- Flexweave Underlay
		[3883] = "tank", -- Rune of the Nerubian Carapace
		[3847] = "tank", -- Rune of the Stoneskin Gargoyle
		[3368] = "melee-dps", -- Rune of the Fallen Crusader
		[3369] = "melee-dps", -- Rune of Cinderglacier
		[3370] = "melee-dps", -- Rune of Razorice
		[3365] = "tank", -- Rune of Swordshattering
		[3594] = "tank", -- Rune of Swordbreaking
		[3367] = "pvp", -- Rune of Spellshattering
		[3595] = "pvp", -- Rune of Spellbreaking
		[3366] = "never", -- Rune of Lichbane
	}

	-- Certain items can't be classified with normal stat scans, you can specify a specific type using this
	ElitistGroup.Items.itemOverrides = {
		[35503] = "manaless", -- Ember Skyfire Diamond
		[41333] = "manaless", -- Ember Skyflare Diamond
		[50458] = "dps", -- Bizuri's Totem of Shattered Ice
		[47666] = "dps", -- Totem of Electrifying Wind
		[40707] = "tank", -- Libram of Obstruction
		[32368] = "tank", -- Tome of the Lightbringer
		[47661] = "tank/dps", -- Libram of Valiance
		[50366] = "healer", -- Althor's Abacus (Heroic)
		[50359] = "healer", -- Althor's Abacus
		[44255] = "caster", -- Darkmoon Card: Greatness (+90 INT)
		[44254] = "caster-spirit", -- Darkmoon Card: Greatness (+90 SPI)
		[44253] = "tank/dps", -- Darkmoon Card: Greantess (+90 AGI)
		[42987] = "tank/dps", -- Darkmoon Card: Greatness (+90 STR)
		[49464] = "caster", -- Shiny Shard of the Flame, this would be only useful if you have both trinkets, but still
		[49463] = "caster", -- Purified Shard of the Flame, ^
		[47668] = "tank/dps", -- Idol of Mutilation
		[50456] = "tank/dps", -- Idol of the Crying Moon
		[38365] = "tank/dps", -- Idol of Perspicacious Attacks
		[42604] = "caster-dps", -- Relentless Gladiator's Totem of Survival
		[42603] = "caster-dps", -- Furious Gladiator's Totem of Survival
		[42602] = "caster-dps", -- Deadly Gladiator's Totem of Survival
		[42601] = "caster-dps", -- Hateful Gladiator's Totme of Survival
		[42594] = "caster-dps", -- Savage Gladiator's Totem of Survival
		[40322] = "melee-dps", -- Totem of Dueling, uses "Storm Strike" when it's "Stormstrike" why do you hate me so Blizard
		[40714] = "tank", -- Sigil of the Unfaltering Knight
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
		[41376] = "disc-priest", -- Revitalizing Skyflare Diamond
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
	ElitistGroup.Items.statMap = {
		RESILIENCE_RATING = "ITEM_MOD_RESILIENCE_RATING_SHORT", SPELL_PENETRATION = "ITEM_MOD_SPELL_PENETRATION_SHORT", SPELL_HEALING_DONE = "ITEM_MOD_SPELL_HEALING_DONE_SHORT",
		HIT_SPELL_RATING = "ITEM_MOD_HIT_SPELL_RATING_SHORT", RANGED_ATTACK_POWER = "ITEM_MOD_RANGED_ATTACK_POWER_SHORT", CRIT_RANGED_RATING = "ITEM_MOD_CRIT_RANGED_RATING_SHORT",
		HIT_RANGED_RATING = "ITEM_MOD_HIT_RANGED_RATING_SHORT", DODGE_RATING = "ITEM_MOD_DODGE_RATING_SHORT", DEFENSE_SKILL_RATING = "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT",
		BLOCK_RATING = "ITEM_MOD_BLOCK_RATING_SHORT", BLOCK_VALUE = "ITEM_MOD_BLOCK_VALUE_SHORT", EXPERTISE_RATING = "ITEM_MOD_EXPERTISE_RATING_SHORT",
		HIT_MELEE_RATING = "ITEM_MOD_HIT_MELEE_RATING_SHORT", MELEE_ATTACK_POWER = "ITEM_MOD_MELEE_ATTACK_POWER_SHORT", STRENGTH = "ITEM_MOD_STRENGTH_SHORT",
		CRIT_MELEE_RATING = "ITEM_MOD_CRIT_MELEE_RATING_SHORT", AGILITY = "ITEM_MOD_AGILITY_SHORT", ARMOR_PENETRATION_RATING = "ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT",
		ATTACK_POWER = "ITEM_MOD_ATTACK_POWER_SHORT", POWER_REGEN0 = "ITEM_MOD_POWER_REGEN0_SHORT", SPELL_DAMAGE_DONE = "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT",
		SPELL_POWER = "ITEM_MOD_SPELL_POWER_SHORT", SPIRIT = "ITEM_MOD_SPIRIT_SHORT", MANA_REGENERATION = "ITEM_MOD_MANA_REGENERATION_SHORT",
		HASTE_SPELL_RATING = "ITEM_MOD_HASTE_SPELL_RATING_SHORT", CRIT_SPELL_RATING = "ITEM_MOD_CRIT_SPELL_RATING_SHORT", INTELLECT = "ITEM_MOD_INTELLECT_SHORT", RESISTANCE0 = "RESISTANCE0_NAME",
		STAMINA = "ITEM_MOD_STAMINA_SHORT", RESIST = "RESIST", CRIT_RATING = "ITEM_MOD_CRIT_RATING_SHORT", MANA = "ITEM_MOD_MANA_SHORT", HIT_RATING = "ITEM_MOD_HIT_RATING_SHORT",
		HASTE_RATING = "ITEM_MOD_HASTE_RATING_SHORT", SPELL_STATALL = "SPELL_STATALL", PARRY_RATING = "ITEM_MOD_PARRY_RATING_SHORT", HEALTH = "HEALTH", DAMAGE = "DAMAGE",
		
		HELPFUL_SPELL = L["helpful spell"], HARMFUL_SPELL = L["harmful spell"], PERIODIC_DAMAGE = L["periodic damage"], MELEE_ATTACK = L["chance on melee attack"],
		CHANCE_MELEE_OR_RANGE = L["chance on melee or range"], CHANCE_MELEE_AND_RANGE = L["chance on melee and range"], RANGED_CRITICAL_STRIKE = L["ranged critical"],
		MELEE_OR_RANGE = L["melee or range"], SPELL_DAMAGE = L["spell damage"], MELEE_AND_RANGE = L["melee and ranged"], DEAL_DAMAGE = L["deal damage"],
		ARMOR_BY = L["armor by"], ARMOR_FOR = L["armor for"], WHEN_HIT = L["when hit"],
	}

	ElitistGroup.Items.safeStatMatch = {}
	for _, key in pairs(ElitistGroup.Items.statMap) do
		local text = _G[key] or key
		text = string.gsub(text, "%(", "%%(")
		text = string.gsub(text, "%)", "%%)")
		text = string.gsub(text, "%.", "%%.")
		ElitistGroup.Items.safeStatMatch[key] = string.lower(text)
	end

	-- Basically, some stats like "armor" will conflict with "armor penetration", as well melee hit and so on
	-- so will set it up so the longest strings get matched first to prevent any chance of conflicts happening
	ElitistGroup.Items.orderedStatMap = {}
	for key in pairs(ElitistGroup.Items.safeStatMatch) do table.insert(ElitistGroup.Items.orderedStatMap, key) end
	table.sort(ElitistGroup.Items.orderedStatMap, function(a, b) return string.len(_G[a] or a) > string.len(_G[b] or b) end)

	-- These are strings returned from GlobalStrings, ITEM_MOD_####_SHORT/####_NAME for GetItemStats, the ordering is important, do not mess with it
	ElitistGroup.Items.statTalents = {
		{type = "pvp",			default = "RESILIENCE_RATING@SPELL_PENETRATION@"},
		{type = "pvp",			gems = "STAMINA@", require = "ITEM_MOD_SPELL_POWER_SHORT", require2 = "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT"},
		{type = "all",			gems = "SPELL_STATALL@", enchants = "SPELL_STATALL@"},
		{type = "never",		gems = "RESIST@"},
		{type = "never",		gems = "MANA@", exclusive = true},
		{type = "healer", 		gems = "MANA@", skipOn = "ITEM_MOD_INTELLECT_SHORT", skipOn2 = "ITEM_MOD_SPELL_POWER_SHORT"},
		{type = "tank",			default = "DEFENSE_SKILL_RATING@", trinkets = "WHEN_HIT@"},
		{type = "healer",		default = "SPELL_HEALING_DONE@", trinkets = "HELPFUL_SPELL@"},
		{type = "caster-dps",	default = "HIT_SPELL_RATING@", trinkets = "HARMFUL_SPELL@PERIODIC_DAMAGE@SPELL_DAMAGE@"},
		{type = "caster-dps",	default = "HIT_RATING@", require = "ITEM_MOD_SPELL_POWER_SHORT", require2 = "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT"},
		{type = "physical-all",	default = "AGILITY@"},
		{type = "physical-dps", default = "ARMOR_PENETRATION_RATING@", trinkets = "ATTACK@MELEE_OR_RANGE_DAMAGE@CHANCE_MELEE_OR_RANGE@MELEE_AND_RANGE@MELEE_AND_RANGE@"},
		{type = "ranged",		default = "RANGED_ATTACK_POWER@CRIT_RANGED_RATING@HIT_RANGED_RATING@RANGED_CRITICAL_STRIKE@"},
		{type = "melee",		gems = "STRENGTH@", require = "ITEM_MOD_STAMINA_SHORT"},
		{type = "caster-spirit",gems = "SPIRIT@", enchants = "SPIRIT@", trinkets = "SPIRIT@"},
		{type = "caster-spirit",default = "SPIRIT@", require = "ITEM_MOD_SPELL_POWER_SHORT", require2 = "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT"},
		{type = "caster",		default = "POWER_REGEN0@SPELL_DAMAGE_DONE@SPELL_POWER@MANA_REGENERATION@HASTE_SPELL_RATING@CRIT_SPELL_RATING@INTELLECT@", gems = "MANA@", enchants = "MANA@"},
		{type = "caster",		default = "MANA@", require = "ITEM_MOD_SPELL_POWER_SHORT", require2 = "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT"},
		{type = "tank",			default = "PARRY_RATING@DODGE_RATING@DEFENSE_SKILL_RATING@BLOCK_RATING@BLOCK_VALUE@", enchants = "STAMINA@HEALTH@RESISTANCE0@", trinkets = "RESISTANCE0@STAMINA@", weapons = "RESISTANCE0@", rings = "RESISTANCE0"},
		{type = "melee",		default = "EXPERTISE_RATING@"},
		{type = "physical-dps",	default = "ATTACK_POWER@"},
		{type = "melee-dps",	default = "HIT_MELEE_RATING@MELEE_ATTACK_POWER@STRENGTH@CRIT_MELEE_RATING@", trinkets = "MELEE_ATTACK@"},
		{type = "tank/dps", 	enchants = "HIT_RATING@", gems = "HIT_RATING@"},
		{type = "dps",			trinkets = "DAMAGE@DEAL_DAMAGE@"},
		{type = "dps",			default = "HIT_RATING@"},
		{type = "healer/dps",	default = "CRIT_RATING@HASTE_RATING@"},
		{type = "tank",			gems = "STAMINA@"},
	}
end

-- This is a trick I'm experiminating with, basically it automatically loads the data then kills the metatable attached to it
-- so for the cost of a table, I get free loading on demand
ElitistGroup.Items = setmetatable({}, {
	__index = function(tbl, key)
		loadData()
		setmetatable(tbl, nil)
		return tbl[key]
end})