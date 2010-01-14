local ElitistGroup = select(2, ...)
local L = ElitistGroup.L

local function loadData()
	local Talents = ElitistGroup.Talents

	Talents.talentText = {["healer"] = L["Healer"], ["caster-dps"] = L["Caster DPS"], ["tank"] = L["Tank"], ["unknown"] = L["Unknown"], ["melee-dps"] = L["Melee DPS"], ["range-dps"] = L["Ranged DPS"], ["feral-tank"] = L["Tank"], ["mp5-healer"] = L["Healer"], ["disc-priest"] = L["Healer"], ["dk-tank"] = L["Tank"], ["resto-druid"] = L["Healer"], ["balance-druid"] = L["Caster DPS"]}

	-- required = How many of the talents the class needs
	-- the number set for the talent is how many they need
	-- Death Knights for example need capped Blade Barrier, Anticipation or Toughness, any 2 to be a tank
	-- This isn't really perfect, if a Druid tries to hybrid it up then it's hard for us to figure out what spec they are
	-- a good idea might be to force set their role based on the assignment they chose when possible, and use this as a fallback
	Talents.specOverride = {
		["DEATHKNIGHT"] = {
			["required"] = 2,
			["role"] = "dk-tank",
			
			[GetSpellInfo(16271)] = 5, -- Anticipation
			[GetSpellInfo(49042)] = 5, -- Toughness
			[GetSpellInfo(55225)] = 5, -- Blade Barrier
		},
		["DRUID"] = {
			["required"] = 2,
			["role"] = "feral-tank",
			
			[GetSpellInfo(57881)] = 2, -- Natural Reaction
			[GetSpellInfo(16929)] = 3, -- Thick Hide
			[GetSpellInfo(61336)] = 1, -- Survival Instincts
		},
	}

	-- Tree names
	Talents.treeData = {
		["SHAMAN"] = {
			"caster-dps", L["Elemental"], "Interface\\Icons\\Spell_Nature_Lightning",
			"melee-dps", L["Enhancement"], "Interface\\Icons\\Spell_Nature_LightningShield",
			"mp5-healer", L["Restoration"], "Interface\\Icons\\Spell_Nature_MagicImmunity",
		},
		["MAGE"] = {
			"caster-dps", L["Arcane"], "Interface\\Icons\\Spell_Holy_MagicalSentry",
			"caster-dps", L["Fire"], "Interface\\Icons\\Spell_Fire_FlameBolt", 
			"caster-dps", L["Frost"], "Interface\\Icons\\Spell_Frost_FrostBolt02",
		},
		["WARLOCK"] = {
			"caster-dps", L["Affliction"], "Interface\\Icons\\Spell_Shadow_DeathCoil",
			"caster-dps", L["Demonology"], "Interface\\Icons\\Spell_Shadow_Metamorphosis",
			"caster-dps", L["Destruction"], "Interface\\Icons\\Spell_Shadow_RainOfFire",
		},
		["DRUID"] = {
			"balance-druid", L["Balance"], "Interface\\Icons\\Spell_Nature_Lightning",
			"melee-dps", L["Feral"], "Interface\\Icons\\Ability_Racial_BearForm",
			"resto-druid", L["Restoration"], "Interface\\Icons\\Spell_Nature_HealingTouch",
		},
		["WARRIOR"] = {
			"melee-dps", L["Arms"], "Interface\\Icons\\Ability_Rogue_Eviscerate", 
			"melee-dps", L["Fury"], "Interface\\Icons\\Ability_Warrior_InnerRage", 
			"tank", L["Protection"], "Interface\\Icons\\INV_Shield_06",
		},
		["ROGUE"] = {
			"melee-dps", L["Assassination"], "Interface\\Icons\\Ability_Rogue_Eviscerate",
			"melee-dps", L["Combat"], "Interface\\Icons\\Ability_BackStab", 
			"melee-dps", L["Subtlety"], "Interface\\Icons\\Ability_Stealth",
		},
		["PALADIN"] = {
			"mp5-healer", L["Holy"], "Interface\\Icons\\Spell_Holy_HolyBolt", 
			"tank", L["Protection"], "Interface\\Icons\\Spell_Holy_DevotionAura",
			"melee-dps", L["Retribution"], "Interface\\Icons\\Spell_Holy_AuraOfLight",
		},
		["HUNTER"] = {
			"range-dps", L["Beast Mastery"], "Interface\\Icons\\Ability_Hunter_BeastTaming",
			"range-dps", L["Marksmanship"], "Interface\\Icons\\Ability_Marksmanship",
			"range-dps", L["Survival"], "Interface\\Icons\\Ability_Hunter_SwiftStrike",
		},
		["PRIEST"] = {
			"disc-priest", L["Discipline"], "Interface\\Icons\\Spell_Holy_WordFortitude",
			"healer", L["Holy"], "Interface\\Icons\\Spell_Holy_HolyBolt",
			"caster-dps", L["Shadow"], "Interface\\Icons\\Spell_Shadow_ShadowWordPain",
		},
		["DEATHKNIGHT"] = {
			"melee-dps", L["Blood"], "Interface\\Icons\\Spell_Shadow_BloodBoil",
			"melee-dps", L["Frost"], "Interface\\Icons\\Spell_Frost_FrostNova",
			"melee-dps", L["Unholy"], "Interface\\Icons\\Spell_Shadow_ShadeTrueSight",
		},
	}
end

-- This is a trick I'm experiminating with, basically it automatically loads the data then kills the metatable attached to it
-- so for the cost of a table, I get free loading on demand
ElitistGroup.Talents = setmetatable({}, {
	__index = function(tbl, key)
		loadData()
		setmetatable(tbl, nil)
		return tbl[key]
end})
