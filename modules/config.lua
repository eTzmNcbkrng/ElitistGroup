local ElitistGroup = select(2, ...)
local Config = ElitistGroup:NewModule("Config")
local L = ElitistGroup.L
local options

local function set(info, value)
	ElitistGroup.db.profile[info[#(info) - 1]][info[#(info)]] = value

	if( info[#(info) - 1] == "comm" ) then
		ElitistGroup.modules.Sync:Setup()
	end
end

local function get(info, value)
	return ElitistGroup.db.profile[info[#(info) - 1]][info[#(info)]]
end

local function loadOptions()
	options = {
		order = 1,
		type = "group",
		name = "Elitist Group",
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
				disabled = function(info) return not ElitistGroup.db.profile.comm.enabled end,
				set = function(info, value) ElitistGroup.db.profile.comm.areas[info[#(info)]] = value end,
				get = function(info) return ElitistGroup.db.profile.comm.enabled and ElitistGroup.db.profile.comm.areas[info[#(info)]] end,
				args = {
					enabled = {
						order = 1,
						type = "toggle",
						name = L["Enable comms"],
						desc = L["Unchecking this will completely disable all communications in Elitist Group.\n\nYou will not be able to send or receive notes on players, or check gear without inspecting."],
						set = set,
						get = get,
						disabled = false,
						width = "full",
					},
					autoNotes = {
						order = 2,
						type = "toggle",
						name = L["Auto request notes"],
						desc = L["Automatically requests notes on your group from other Elitist Group users. Only sends requests once per session, and you have to be in a guild."],
						set = set,
						get = get,
					},
					gearRequests = {
						order = 3,
						type = "toggle",
						name = L["Allow gear requests"],
						desc = L["Unchecking this disables other Elitist Group users from requesting your gear without inspecting."],
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

SLASH_ELITISTGROUP1 = "/elitistgroup"
SLASH_ELITISTGROUP2 = "/elitistgroups"
SLASH_ELITISTGROUP3 = "/eg"
SlashCmdList["ELITISTGROUP"] = function(msg)
	local cmd, arg = string.split(" ", msg or "", 2)
	cmd = string.lower(cmd or "")

	if( cmd == "config" or cmd == "ui" ) then
		InterfaceOptionsFrame:Show()
		InterfaceOptionsFrame_OpenToCategory("Elitist Group")
		return
	elseif( cmd == "gear" and arg ) then
		ElitistGroup.modules.Sync:SendGearRequest(arg)
		return
	elseif( cmd == "notes" and arg ) then
		ElitistGroup.modules.Sync:SendNoteRequest(arg)
		return
	elseif( cmd == "summary" ) then
		if( GetNumPartyMembers() == 0 ) then
			ElitistGroup:Print(L["You must be in a party to use this."])
			return
		elseif( select(2, IsInInstance()) ~= "party" ) then
			ElitistGroup:Print(L["You must be inside a raid or party instance to use this feature."])
			return
		end
	
		ElitistGroup.modules.Summary:PLAYER_ROLES_ASSIGNED()
		if( not ElitistGroup.modules.Summary.frame or not ElitistGroup.modules.Summary.frame:IsVisible() ) then
			ElitistGroup.modules.Summary:Setup()
		end
		return
	elseif( cmd == "help" or cmd == "notes" or cmd == "gear" ) then
		ElitistGroup:Print(L["Slash commands"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/elitistgroup config - Opens the configuration"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/elitistgroup gear <name> - Requests gear from another Elitist Group user without inspecting"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/elitistgroup notes <for> - Requests all notes that people have for the name entered"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/elitistgroup <name> - When <name> is passed opens up the player viewer for that person, otherwise it opens it on yourself"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/elitistgroup summary - Displays the summary page for your party"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/rate - Opens the rating panel for your group"])
		return
	end
	
	-- Show the players data
	if( cmd == "" ) then
		local playerID
		if( UnitExists("target") and UnitIsFriend("target", "player") ) then
			if( CanInspect("target", true) ) then
				playerID = ElitistGroup:GetPlayerID("target")
				if( not ElitistGroup.modules.Scan:IsInspectPending() ) then
					ElitistGroup.modules.Scan:InspectUnit("target")
				elseif( not ElitistGroup.userData[playerID] ) then
					ElitistGroup:Print(L["An inspection is currently pending, please wait a second and try again."])
				end
			end
		else
			ElitistGroup.modules.Scan:InspectUnit("player")
			playerID = ElitistGroup.playerName
		end

		local userData = playerID and ElitistGroup.userData[playerID]
		if( userData ) then
			ElitistGroup.modules.Users:LoadData(userData)
		end
		return
	end
	
	local data
	local search = not string.match(cmd, "%-") and string.format("^%s%%-", cmd)
	for name in pairs(ElitistGroup.db.faction.users) do
		if( ( search and string.match(string.lower(name), search) ) or ( string.lower(name) == cmd ) ) then
			data = ElitistGroup.userData[name]
			break
		end
	end
	
	if( not data ) then
		ElitistGroup:Print(string.format(L["Cannot find record of %s in your saved database."], msg))
		return
	end
	
	ElitistGroup.modules.Users:LoadData(data)
end

local register = CreateFrame("Frame", nil, InterfaceOptionsFrame)
register:SetScript("OnShow", function(self)
	self:SetScript("OnShow", nil)
 
	local AceConfig = LibStub("AceConfig-3.0")
	local AceConfigDialog = LibStub("AceConfigDialog-3.0")
	local AceConfigRegistery = LibStub("AceConfigRegistry-3.0")
	
	loadOptions()

	AceConfigRegistery:RegisterOptionsTable("ElitistGroup", options)
	AceConfigDialog:AddToBlizOptions("ElitistGroup", "Elitist Group")
	
	local profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(ElitistGroup.db, true)
	AceConfigRegistery:RegisterOptionsTable("ElitistGroup-Profile", profile)
	AceConfigDialog:AddToBlizOptions("ElitistGroup-Profile", profile.name, "Elitist Group")
end)
