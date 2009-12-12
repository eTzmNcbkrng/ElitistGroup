SexyGroup = LibStub("AceAddon-3.0"):NewAddon("SexyGroup", "AceEvent-3.0", "AceTimer-3.0")
-- local L = LibStub("AceLocale-3.0"):GetLocale("SexyGroup")
local mod = SexyGroup

local defaults = {}

function mod:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("SexyGroupDB", defaults)
end
