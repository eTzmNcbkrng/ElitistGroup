local SimpleGroup = select(2, ...)
local Config = SimpleGroup:NewModule("Config")
local L = SimpleGroup.L
local options

local function set(info, value)
	SimpleGroup.db.profile[info[#(info) - 1]][info[#(info)]] = value

	if( info[#(info) - 1] == "comm" ) then
		SimpleGroup.modules.Sync:Setup()
	end
end

local function get(info, value)
	return SimpleGroup.db.profile[info[#(info) - 1]][info[#(info)]]
end

local function loadOptions()
	options = {
		order = 1,
		type = "group",
		name = "Simple Group",
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
					},
					autoSummary = {
						order = 2,
						type = "toggle",
						name = L["Show summary on dungeon start"],
						desc = L["Pops up the summary window when you first zone into an instance using the Looking for Dungeon system showing you info on your group."],
					},
				},
			},
			database = {
				order = 2,
				type = "group",
				inline = true,
				name = L["Database"],
				args = {
					ignoreBelow = {
						order = 1,
						type = "range",
						name = L["Ignore below level"],
						desc = L["Do not require players who are below the given level."],
						min = 0, max = MAX_PLAYER_LEVEL, step = 5,
					},
					sep = {order = 1.5, type = "description", name = ""},
					pruneBasic = {
						order = 2,
						type = "range",
						name = L["Prune basic data (days)"],
						desc = L["How many days before talents/experience/equipment should be pruned, notes will be kept!\n\nIf the player has no notes or rating on them, all data is removed."],
						min = 1, max = 30, step = 1,
					},
					pruneFull = {
						order = 3,
						type = "range",
						name = L["Prune all data (days)"],
						desc = L["How many days before removing all data on a player. This includes comments and ratings, even your own!"],
						min = 30, max = 365, step = 1,
					},
				},
			},
			comm = {
				order = 3,
				type = "group",
				inline = true,
				name = L["Addon communication"],
				disabled = function(info) return not SimpleGroup.db.profile.comm.enabled end,
				set = function(info, value) SimpleGroup.db.profile.comm.areas[info[#(info)]] = value end,
				get = function(info) return SimpleGroup.db.profile.comm.enabled and SimpleGroup.db.profile.comm.areas[info[#(info)]] end,
				args = {
					enabled = {
						order = 1,
						type = "toggle",
						name = L["Enable comms"],
						desc = L["Unchecking this will completely disable all communications in Simple Group.\n\nYou will not be able to send or receive notes on players, or check gear without inspecting."],
						set = set,
						get = get,
						disabled = false,
						width = "full",
					},
					autoNotes = {
						order = 2,
						type = "toggle",
						name = L["Auto request notes"],
						desc = L["Automatically requests notes on your group from other Simple Group users. Only sends requests once per session, and you have to be in a guild."],
						set = set,
						get = get,
					},
					gearRequests = {
						order = 3,
						type = "toggle",
						name = L["Allow gear requests"],
						desc = L["Unchecking this disables other Simple Group users from requesting your gear without inspecting."],
						set = set,
						get = get,
					},
					header = {
						order = 10,
						type = "header",
						name = L["Enabled channels"],
					},
					description = {
						order = 11,
						type = "description",
						name = L["You can choose which channels communication is accepted over. As long as communications are enabled, whisper is accepted. Communications are queued while in combat regardless."],
					},
					GUILD = {
						order = 12,
						type = "toggle",
						name = L["Guild channel"],
					},
					RAID = {
						order = 13,
						type = "toggle",
						name = L["Raid channel"],
					},
					PARTY = {
						order = 14,
						type = "toggle",
						name = L["Party channel"],
					},
					BATTLEGROUND = {
						order = 15,
						type = "toggle",
						name = L["Battleground channel"],
					},
				},
			},
		},
	}
end

SLASH_SIMPLEGROUP1 = "/simplegroup"
SLASH_SIMPLEGROUP2 = "/simplegroups"
SLASH_SIMPLEGROUP3 = "/sg"
SlashCmdList["SIMPLEGROUP"] = function(msg)
	local cmd, arg = string.split(" ", msg or "", 2)
	cmd = string.lower(cmd or "")

	if( cmd == "config" or cmd == "ui" ) then
		InterfaceOptionsFrame:Show()
		InterfaceOptionsFrame_OpenToCategory("Simple Group")
		return
	elseif( cmd == "gear" and arg ) then
		SimpleGroup.modules.Sync:SendGearRequest(arg)
		return
	elseif( cmd == "notes" and arg ) then
		SimpleGroup.modules.Sync:SendNoteRequest(arg)
		return
	elseif( cmd == "summary" ) then
		if( GetNumPartyMembers() == 0 ) then
			SimpleGroup:Print(L["You must be in a party to use this."])
			return
		elseif( select(2, IsInInstance()) ~= "party" ) then
			SimpleGroup:Print(L["You must be inside a raid or party instance to use this feature."])
			return
		end
	
		SimpleGroup.modules.Summary:PLAYER_ROLES_ASSIGNED()
		if( not SimpleGroup.modules.Summary.frame or not SimpleGroup.modules.Summary.frame:IsVisible() ) then
			SimpleGroup.modules.Summary:Setup()
		end
		return
	elseif( cmd == "help" or cmd == "notes" or cmd == "gear" ) then
		SimpleGroup:Print(L["Slash commands"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/SimpleGroup config - Opens the configuration"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/SimpleGroup gear <name> - Requests gear from another Simple Group user without inspecting"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/SimpleGroup notes <for> - Requests all notes that people have for the name entered"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/SimpleGroup <name> - When <name> is passed opens up the player viewer for that person, otherwise it opens it on yourself"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/SimpleGroup summary - Displays the summary page for your party"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/rate - Opens the rating panel for your group"])
		return
	end
	
	-- Show the players data
	if( cmd == "" ) then
		local playerID
		if( UnitExists("target") and UnitIsFriend("target", "player") ) then
			if( CanInspect("target", true) ) then
				playerID = SimpleGroup:GetPlayerID("target")
				if( not SimpleGroup.modules.Scan:IsInspectPending() ) then
					SimpleGroup.modules.Scan:InspectUnit("target")
				elseif( not SimpleGroup.userData[playerID] ) then
					SimpleGroup:Print(L["An inspection is currently pending, please wait a second and try again."])
				end
			end
		else
			SimpleGroup.modules.Scan:InspectUnit("player")
			playerID = SimpleGroup.playerName
		end

		local userData = playerID and SimpleGroup.userData[playerID]
		if( userData ) then
			SimpleGroup.modules.Users:LoadData(userData)
		end
		return
	end
	
	local data
	local search = not string.match(cmd, "%-") and string.format("^%s%%-", cmd)
	for name in pairs(SimpleGroup.db.faction.users) do
		if( ( search and string.match(string.lower(name), search) ) or ( string.lower(name) == cmd ) ) then
			data = SimpleGroup.userData[name]
			break
		end
	end
	
	if( not data ) then
		SimpleGroup:Print(string.format(L["Cannot find record of %s in your saved database."], msg))
		return
	end
	
	SimpleGroup.modules.Users:LoadData(data)
end

local register = CreateFrame("Frame", nil, InterfaceOptionsFrame)
register:SetScript("OnShow", function(self)
	self:SetScript("OnShow", nil)
 
	local AceConfig = LibStub("AceConfig-3.0")
	local AceConfigDialog = LibStub("AceConfigDialog-3.0")
	local AceConfigRegistery = LibStub("AceConfigRegistry-3.0")
	
	loadOptions()

	AceConfigRegistery:RegisterOptionsTable("SimpleGroup", options)
	AceConfigDialog:AddToBlizOptions("SimpleGroup", "Simple Group")
	
	local profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(SimpleGroup.db, true)
	AceConfigRegistery:RegisterOptionsTable("SimpleGroup-Profile", profile)
	AceConfigDialog:AddToBlizOptions("SimpleGroup-Profile", profile.name, "Simple Group")
end)
