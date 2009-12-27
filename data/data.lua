local SexyGroup = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("SexyGroup")

SexyGroup.ROLE_TANK = 0x04
SexyGroup.ROLE_HEALER = 0x02
SexyGroup.ROLE_DAMAGE = 0x01
SexyGroup.MAX_RATING = 5

-- required = How many of the talents the DK needs
-- the number set for the talent is how many they need
-- Death Knights for example need capped Blade Barrier, Anticipation or Toughness, any 2 to be a tank
-- This isn't really perfect, if a Druid tries to hybrid it up then it's hard for us to figure out what spec they are
-- a good idea might be to force set their role based on the assignment they chose when possible, and use this as a fallback
SexyGroup.FORCE_SPECROLE = {
	["DEATHKNIGHT"] = {
		["required"] = 2,
		["role"] = "tank",
		
		[GetSpellInfo(16271)] = 5, -- Anticipation
		[GetSpellInfo(40079)] = 5, -- Toughness
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
