local SexyGroup = select(2, ...)
local Config = SexyGroup:NewModule("Config")
local L = LibStub("AceLocale-3.0"):GetLocale("SexyGroup")
local options

local function set(info, value)
	SexyGroup.db.profile[info[#(info) - 1]][info[#(info)]] = value

	if( info[#(info) - 1] == "comm" ) then
		SexyGroup.modules.Sync:Setup()
	end
end

local function get(info, value)
	return SexyGroup.db.profile[info[#(info) - 1]][info[#(info)]]
end

local function loadOptions()
	options = {
		order = 1,
		type = "group",
		name = "Sexy Group",
		set = set,
		get = get,
		args = {
			general = {
				order = 1,
				type = "group",
				inline = true,
				name = L["General"],
				args = {
					autoPopup = {
						order = 1,
						type = "toggle",
						name = L["Show rating after dungeon"],
						desc = L["After completing a dungeon through the Looking For Dungeon system, automatically popup the /rate frame so you can set notes and rating on your group members."],
						width = "full",
					},
				},
			},
			database = {
				order = 2,
				type = "group",
				inline = true,
				name = L["Database"],
				args = {
					pruneBasic = {
						order = 1,
						type = "range",
						name = L["Prune basic data (days)"],
						desc = L["How many days equipment and achievement data should remain in the database before being removed, in days.\n\nComments and ratings will not be removed!"],
						min = 1, max = 30, step = 1,
					},
					pruneFull = {
						order = 2,
						type = "range",
						name = L["Prune all data (days)"],
						desc = L["How many days before removing all data on a player. This includes comments and ratings, even your own!"],
						min = 30, max = 120, step = 1,
					},
				},
			},
			comm = {
				order = 3,
				type = "group",
				inline = true,
				name = L["Addon communication"],
				disabled = function(info) return not SexyGroup.db.profile.comm.enabled end,
				set = function(info, value) SexyGroup.db.profile.comm.areas[info[#(info)]] = value end,
				get = function(info) return SexyGroup.db.profile.comm.enabled and SexyGroup.db.profile.comm.areas[info[#(info)]] end,
				args = {
					enabled = {
						order = 1,
						type = "toggle",
						name = L["Enable comms"],
						desc = L["Unchecking this will completely disable all communications in Sexy Group.\n\nYou will not be able to send or receive notes on players, or check gear without inspecting."],
						set = set,
						get = get,
						disabled = false,
					},
					gearRequests = {
						order = 2,
						type = "toggle",
						name = L["Allow gear requests"],
						desc = L["Unchecking this disables other Sexy Group users from requesting your gear without inspecting."],
						set = set,
						get = get,
					},
					header = {
						order = 2,
						type = "header",
						name = L["Enabled channels"],
					},
					description = {
						order = 3,
						type = "description",
						name = L["You can choose which channels communication is accepted over. As long as communications are enabled, whisper is accepted. Communications are queued while in combat regardless."],
					},
					GUILD = {
						order = 4,
						type = "toggle",
						name = L["Guild channel"],
					},
					RAID = {
						order = 5,
						type = "toggle",
						name = L["Raid channel"],
					},
					PARTY = {
						order = 6,
						type = "toggle",
						name = L["Party channel"],
					},
					BATTLEGROUND = {
						order = 7,
						type = "toggle",
						name = L["Battleground channel"],
					},
				},
			},
		},
	}
end

SLASH_SEXYGROUP1 = "/sexygroup"
SLASH_SEXYGROUP2 = "/sexygroups"
SLASH_SEXYGROUP3 = "/sg"
SlashCmdList["SEXYGROUP"] = function(msg)
	local cmd, arg = string.split(" ", msg or "", 2)
	cmd = string.lower(cmd or "")

	if( cmd == "config" or cmd == "ui" ) then
		InterfaceOptionsFrame:Show()
		InterfaceOptionsFrame_OpenToCategory("Sexy Group")
		return
	elseif( cmd == "gear" and arg ) then
		SexyGroup.modules.Sync:SendGearRequest(arg)
		return
	elseif( cmd == "notes" and arg ) then
		SexyGroup.modules.Sync:SendNoteRequest(arg)
		return
	elseif( cmd == "help" or cmd == "notes" or cmd == "gear" ) then
		SexyGroup:Print(L["Slash commands"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/sexygroup config - Opens the configuration"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/sexygroup gear <name> - Requests gear from another Sexy Group user without inspecting"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/sexygroup notes <for> - Requests all notes that people have for the name entered"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/sexygroup <name> - When <name> is passed opens up the player viewer for that person, otherwise it opens it on yourself"])
		return
	end
	
	-- Show the players data
	if( cmd == "" ) then
		SexyGroup.modules.Scan:UpdatePlayerData()
		SexyGroup.modules.Users:LoadData(SexyGroup.userData[SexyGroup.playerName])
		return
	end
	
	local data
	local search = not string.match(cmd, "%-") and string.format("^%s%%-", cmd)
	for name in pairs(SexyGroup.db.faction.users) do
		if( ( search and string.match(string.lower(name), search) ) or ( string.lower(name) == cmd ) ) then
			data = SexyGroup.userData[name]
			break
		end
	end
	
	if( not data ) then
		SexyGroup:Print(string.format(L["Cannot find record of %s in your saved database."], msg))
		return
	end
	
	SexyGroup.modules.Users:LoadData(data)
end

local register = CreateFrame("Frame", nil, InterfaceOptionsFrame)
register:SetScript("OnShow", function(self)
	self:SetScript("OnShow", nil)
 
	local AceConfig = LibStub("AceConfig-3.0")
	local AceConfigDialog = LibStub("AceConfigDialog-3.0")
	local AceConfigRegistery = LibStub("AceConfigRegistry-3.0")
	
	loadOptions()

	AceConfigRegistery:RegisterOptionsTable("SexyGroup", options)
	AceConfigDialog:AddToBlizOptions("SexyGroup", "Sexy Group")
	
	local profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(SexyGroup.db, true)
	AceConfigRegistery:RegisterOptionsTable("SexyGroup-Profile", profile)
	AceConfigDialog:AddToBlizOptions("SexyGroup-Profile", profile.name, "Sexy Group")
end)
