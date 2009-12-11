local L = LibStub("AceLocale-3.0"):GetLocale("SexyGroup")
local modname = "GroupHistory"
local parent = SexyGroup
local mod = parent:NewModule(modname)

local defaults = {
	global = {
		characters = {}
	}
}

function mod:OnInitialize()
	self.db = parent.db:RegisterNamespace(modName, defaults)
end

function mod:OnEnable()
	self:RegisterEvent("LFG_COMPLETION_REWARD")
end

function mod:LogGroup()
	for i = 1, 5 do
		local key = "party" .. i
		if UnitName(key) and not UnitIsUnit(key, "player") then
			local name = UnitName(key)
			characters[name] = characters[name] or {}
			local isTank, isHealer, isDamage = UnitGroupRolesAssigned(key)
		end
	end
end

-- Dungeon complete, popup survey
function mod:LFG_COMPLETION_REWARD()
end