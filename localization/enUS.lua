local SexyGroup = select(2, ...)
SexyGroup.L = {
	[" (%d-man)"] = " (%d-man)",
	["%d days"] = "%d days",
	["%d days old"] = "%d days old",
	["%d hours"] = "%d hours",
	["%d hours old"] = "%d hours old",
	["%d minutes"] = "%d minutes",
	["%d minutes old"] = "%d minutes old",
	["%d notes found"] = "%d notes found",
	["%s - %s item"] = "%s - %s item",
	["%s - %s, level %s %s."] = "%s - %s, level %s %s.",
	["%s - %s, level %s, unknown class."] = "%s - %s, level %s, unknown class.",
	["%s - Missing belt buckle or gem"] = "%s - Missing belt buckle or gem",
	["%s - Missing gems"] = "%s - Missing gems",
	["%s - Unenchanted"] = "%s - Unenchanted",
	["%s - |cffffffff%s|r enchant"] = "%s - |cffffffff%s|r enchant",
	["%s - |cffffffff%s|r gem"] = "%s - |cffffffff%s|r gem",
	["%s - |cffffffff%s|r quality gem"] = "%s - |cffffffff%s|r quality gem",
	["%s, %s role."] = "%s, %s role.",
	["%s, %s role.\n\nThis player has not spent all of their talent points!"] = "%s, %s role.\n\nThis player has not spent all of their talent points!",
	["%s: %d/%d in %d-man %s (%s)"] = "%s: %d/%d in %d-man %s (%s)",
	["/rate - Opens the rating panel for your group"] = "/rate - Opens the rating panel for your group",
	["/sexygroup <name> - When <name> is passed opens up the player viewer for that person, otherwise it opens it on yourself"] = "/sexygroup <name> - When <name> is passed opens up the player viewer for that person, otherwise it opens it on yourself",
	["/sexygroup config - Opens the configuration"] = "/sexygroup config - Opens the configuration",
	["/sexygroup gear <name> - Requests gear from another Sexy Group user without inspecting"] = "/sexygroup gear <name> - Requests gear from another Sexy Group user without inspecting",
	["/sexygroup notes <for> - Requests all notes that people have for the name entered"] = "/sexygroup notes <for> - Requests all notes that people have for the name entered",
	["/sexygroup summary - Displays the summary page for your party"] = "/sexygroup summary - Displays the summary page for your party",
	["Addon communication"] = "Addon communication",
	["Affliction"] = "Affliction",
	["After completing a dungeon through the Looking For Dungeon system, automatically popup the /rate frame so you can set notes and rating on your group members."] = "After completing a dungeon through the Looking For Dungeon system, automatically popup the /rate frame so you can set notes and rating on your group members.",
	["All"] = "All",
	["Allow gear requests"] = "Allow gear requests",
	["Always bad"] = "Always bad",
	["Arcane"] = "Arcane",
	["Archavon the Stone Watcher"] = "Archavon the Stone Watcher",
	["Archavon, Vault"] = "Archavon, Vault",
	["Arms"] = "Arms",
	["Assassination"] = "Assassination",
	["Auto request notes"] = "Auto request notes",
	["Automatically requests notes on your group from other Sexy Group users. Only sends requests once per session, and you have to be in a guild."] = "Automatically requests notes on your group from other Sexy Group users. Only sends requests once per session, and you have to be in a guild.",
	["Balance"] = "Balance",
	["Battleground channel"] = "Battleground channel",
	["Beast Mastery"] = "Beast Mastery",
	["Blood"] = "Blood",
	["Cannot find item data for item id %s."] = "Cannot find item data for item id %s.",
	["Cannot find record of %s in your saved database."] = "Cannot find record of %s in your saved database.",
	["Caster (All)"] = "Caster (All)",
	["Caster DPS"] = "Caster DPS",
	["Click to open and close the database viewer."] = "Click to open and close the database viewer.",
	["Combat"] = "Combat",
	["Comment"] = "Comment",
	["Completed %s! Type /rate to rate this group."] = "Completed %s! Type /rate to rate this group.",
	["DPS (All)"] = "DPS (All)",
	["DPS (Caster)"] = "DPS (Caster)",
	["DPS (Melee)"] = "DPS (Melee)",
	["DPS (Physical)"] = "DPS (Physical)",
	["DPS (Ranged)"] = "DPS (Ranged)",
	["Data for this player is from a verified source and can be trusted."] = "Data for this player is from a verified source and can be trusted.",
	["Database"] = "Database",
	["Defaulting to no comment on %d players, type /rate to set a specific comment."] = "Defaulting to no comment on %d players, type /rate to set a specific comment.",
	["Demonology"] = "Demonology",
	["Destruction"] = "Destruction",
	["Discipline"] = "Discipline",
	["Do not require players who are below the given level."] = "Do not require players who are below the given level.",
	["Dungeons"] = "Dungeons",
	["Elemental"] = "Elemental",
	["Emalon the Storm Watcher"] = "Emalon the Storm Watcher",
	["Emalon, Vault"] = "Emalon, Vault",
	["Enable comms"] = "Enable comms",
	["Enabled channels"] = "Enabled channels",
	["Enchant information is still loading, you need to be within inspection range for data to become available."] = "Enchant information is still loading, you need to be within inspection range for data to become available.",
	["Enchants"] = "Enchants",
	["Enchants: |cffffffff%d bad|r"] = "Enchants: |cffffffff%d bad|r",
	["Enchants: |cffffffffAll good|r"] = "Enchants: |cffffffffAll good|r",
	["Enchants: |cffffffffNo enchants found. Either the player has no enchants or the enchant data was not found.|r"] = "Enchants: |cffffffffNo enchants found. Either the player has no enchants or the enchant data was not found.|r",
	["Enhancement"] = "Enhancement",
	["Equipment"] = "Equipment",
	["Equipment: |cffffffff%d bad items found|r"] = "Equipment: |cffffffff%d bad items found|r",
	["Equipment: |cffffffffAll good|r"] = "Equipment: |cffffffffAll good|r",
	["Equipped gear"] = "Equipped gear",
	["Experience"] = "Experience",
	["Experienced"] = "Experienced",
	["Feral"] = "Feral",
	["Fire"] = "Fire",
	["Frost"] = "Frost",
	["Fury"] = "Fury",
	["Gear and achievement data for this player has been pruned to reduce database size.\nNotes and basic data have been kept, you can view gear and achievements again by inspecting the player.\n\n\nIf you do not want data to be pruned or you want to increase the time before pruning, go to /sexygroup and change the value."] = "Gear and achievement data for this player has been pruned to reduce database size.\nNotes and basic data have been kept, you can view gear and achievements again by inspecting the player.\n\n\nIf you do not want data to be pruned or you want to increase the time before pruning, go to /sexygroup and change the value.",
	["Gems"] = "Gems",
	["Gems: |cffffffff%d bad|r"] = "Gems: |cffffffff%d bad|r",
	["Gems: |cffffffffAll good|r"] = "Gems: |cffffffffAll good|r",
	["Gems: |cffffffffNo gems found. Either the player has no enchants or the enchant data was not found.|r"] = "Gems: |cffffffffNo gems found. Either the player has no enchants or the enchant data was not found.|r",
	["General"] = "General",
	["Great"] = "Great",
	["Guild channel"] = "Guild channel",
	["Hard"] = "Hard",
	["Healer"] = "Healer",
	["Healer (All)"] = "Healer (All)",
	["Healer/DPS"] = "Healer/DPS",
	["Heroic"] = "Heroic",
	["Holy"] = "Holy",
	["How many days before removing all data on a player. This includes comments and ratings, even your own!"] = "How many days before removing all data on a player. This includes comments and ratings, even your own!",
	["How many days equipment and achievement data should remain in the database before being removed, in days.\n\nComments and ratings will not be removed!"] = "How many days equipment and achievement data should remain in the database before being removed, in days.\n\nComments and ratings will not be removed!",
	["Icecrown Citadel"] = "Icecrown Citadel",
	["Ignore below level"] = "Ignore below level",
	["Inexperienced"] = "Inexperienced",
	["Instance: %s"] = "Instance: %s",
	["Invalid name entered."] = "Invalid name entered.",
	["Just now"] = "Just now",
	["Koralon the Flame Watcher"] = "Koralon the Flame Watcher",
	["Koralon, Vault"] = "Koralon, Vault",
	["Loading..."] = "Loading...",
	["Malygos"] = "Malygos",
	["Marksmanship"] = "Marksmanship",
	["Melee (All)"] = "Melee (All)",
	["Melee DPS"] = "Melee DPS",
	["Naxxramas"] = "Naxxramas",
	["Nearly-experienced"] = "Nearly-experienced",
	["No comment"] = "No comment",
	["No item equipped"] = "No item equipped",
	["No name found for unit."] = "No name found for unit.",
	["No notes found"] = "No notes found",
	["No notes were found for this player."] = "No notes were found for this player.",
	["Normal"] = "Normal",
	["Notes (%d)"] = "Notes (%d)",
	["Onyxia's Lair"] = "Onyxia's Lair",
	["Other players have left a note on this person."] = "Other players have left a note on this person.",
	["PVP"] = "PVP",
	["Party channel"] = "Party channel",
	["Physical (All)"] = "Physical (All)",
	["Player info"] = "Player info",
	["Pops up the summary window when you first zone into an instance using the Looking for Dungeon system showing you info on your group."] = "Pops up the summary window when you first zone into an instance using the Looking for Dungeon system showing you info on your group.",
	["Protection"] = "Protection",
	["Prune all data (days)"] = "Prune all data (days)",
	["Prune basic data (days)"] = "Prune basic data (days)",
	["Raid channel"] = "Raid channel",
	["Raids"] = "Raids",
	["Ranged DPS"] = "Ranged DPS",
	["Rate and comment on the players in your group."] = "Rate and comment on the players in your group.",
	["Rated %d of %d"] = "Rated %d of %d",
	["Restoration"] = "Restoration",
	["Retribution"] = "Retribution",
	["Sartharion"] = "Sartharion",
	["Score unavailable"] = "Score unavailable",
	["Search..."] = "Search...",
	["Seen as %s - %s:\n|cffffffff%s|r"] = "Seen as %s - %s:\n|cffffffff%s|r",
	["Semi-experienced"] = "Semi-experienced",
	["Shadow"] = "Shadow",
	["Show rating after dungeon"] = "Show rating after dungeon",
	["Show summary on dungeon start"] = "Show summary on dungeon start",
	["Slash commands"] = "Slash commands",
	["Subtlety"] = "Subtlety",
	["Successfully got data on %s, type /sexygroup %s to view!"] = "Successfully got data on %s, type /sexygroup %s to view!",
	["Suggested dungeons"] = "Suggested dungeons",
	["Survival"] = "Survival",
	["T10 Dungeons"] = "T10 Dungeons",
	["T10 Raids"] = "T10 Raids",
	["T7 Dungeons"] = "T7 Dungeons",
	["T7 Raids"] = "T7 Raids",
	["T8 Raids"] = "T8 Raids",
	["T9 Dungeons"] = "T9 Dungeons",
	["T9 Raids"] = "T9 Raids",
	["Tank"] = "Tank",
	["Tank/DPS"] = "Tank/DPS",
	["Tank/PVP"] = "Tank/PVP",
	["Terrible"] = "Terrible",
	["Toravon the Ice Watcher"] = "Toravon the Ice Watcher",
	["Trial of the Crusader"] = "Trial of the Crusader",
	["Trial of the Grand Crusader"] = "Trial of the Grand Crusader",
	["Trusted"] = "Trusted",
	["Ulduar"] = "Ulduar",
	["Unchecking this disables other Sexy Group users from requesting your gear without inspecting."] = "Unchecking this disables other Sexy Group users from requesting your gear without inspecting.",
	["Unchecking this will completely disable all communications in Sexy Group.\n\nYou will not be able to send or receive notes on players, or check gear without inspecting."] = "Unchecking this will completely disable all communications in Sexy Group.\n\nYou will not be able to send or receive notes on players, or check gear without inspecting.",
	["Unholy"] = "Unholy",
	["Unknown"] = "Unknown",
	["Untrusted"] = "Untrusted",
	["Vault of Archavon"] = "Vault of Archavon",
	["Welcome! Type /sexygroup help to see a list of available slash commands."] = "Welcome! Type /sexygroup help to see a list of available slash commands.",
	["While the player data should be accurate, it is not guaranteed as the source is unverified."] = "While the player data should be accurate, it is not guaranteed as the source is unverified.",
	["You can choose which channels communication is accepted over. As long as communications are enabled, whisper is accepted. Communications are queued while in combat regardless."] = "You can choose which channels communication is accepted over. As long as communications are enabled, whisper is accepted. Communications are queued while in combat regardless.",
	["You must be in a party to use this."] = "You must be in a party to use this.",
	["You need to be in a guild to request notes on players."] = "You need to be in a guild to request notes on players.",
	["You need to currently be in a group, or have been in a group to use the rating tool."] = "You need to currently be in a group, or have been in a group to use the rating tool.",
	["You wrote %s ago:\n|cffffffff%s|r"] = "You wrote %s ago:\n|cffffffff%s|r",
	["score"] = "score",
	["unspent points"] = "unspent points",
	["|T%s:14:14|t Enchants"] = "|T%s:14:14|t Enchants",
	["|T%s:14:14|t Gems"] = "|T%s:14:14|t Gems",
	["|cff%02x%02x00%d|r score, %s-man (%s)"] = "|cff%02x%02x00%d|r score, %s-man (%s)",
	["|cfffed000Item Type:|r %s"] = "|cfffed000Item Type:|r %s",
}