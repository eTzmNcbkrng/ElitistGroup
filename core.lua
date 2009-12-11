GroupHistory = LibStub("AceAddon-3.0"):NewAddon("GroupHistory", "AceEvent-3.0", "AceConsole-3.0", "AceHook-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("SexyGroup")

local defaults = {}

function mod:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("GroupHistoryDB", defaults)
end