-- Sends HTTP request about players joining and leaving through Discord hooks.

-- Author: Princess Celestia <STEAM_0:1:33510194>
-- Last update: 2018-09-28 (YYYY-MM-DD)

if SERVER then
	local SETTINGS_FILE = "discord-settings.txt"
	local SETTINGS = {
		id = "",
		url = "https://discord.com/api/webhooks/351667417849790495/j9gPAhpuB3Co2pb40XTZU3BcbSb_LTOb29cRfHATquXtnsQ2kRr4_1OJOPM6zk1kR0Hv"
	}

	-- Compute the difference in seconds between local time and UTC.
	local function get_timezone()
		local now = os.time()
		return os.difftime(now, os.time(os.date("!*t", now)))
	end

	-- Return a timezone string in ISO 8601:2000 standard form (+hhmm or -hhmm)
	local function get_tzoffset(timezone)
		local h, m = math.modf(timezone / 3600)
		return string.format("%+.4d", 100 * h + 60 * m)
	end

	local function getCurrentDateTime()
		return os.date("%d/%m/%y %H:%M:%S -- %I:%M:%S%p") .. get_tzoffset(get_timezone())
	end

	local function sendMessage(msg)
		local params = {
			content = "`[" .. SETTINGS.id .. "]` `[" .. getCurrentDateTime() .. "]` " .. msg
		}
		http.Post(SETTINGS.url, params)
	end

	local function isSettingsValid()
		-- SETTINGS = {}
		-- SETTINGS.id = ""
		-- SETTINGS.url = ""
	
		return SETTINGS.id and SETTINGS.id ~= "" and SETTINGS.url and SETTINGS.url ~= ""
	end

	local function loadSettings()
		-- SETTINGS = util.JSONToTable(file.Read(SETTINGS_FILE, "DATA"))
		
		-- SETTINGS = {}
		-- SETTINGS.id = ""
		-- SETTINGS.url = ""
	end

	local function saveSettings()
		-- file.Write(SETTINGS_FILE, util.TableToJSON(SETTINGS, true))
		-- SETTINGS = {}
		-- SETTINGS.id = ""
		-- SETTINGS.url = ""
	end

	local function onServerLoaded()
		sendMessage("Server initialized.")
		hook.Remove("Think", "DISCORD_SERVER_LOADED")
	end

	local function onPlayerConnect(name, ip)
		sendMessage("Player `" .. name .. "` is connecting.")
	end

	local function onInitialSpawn(ply)
		sendMessage("Player `" .. ply:GetName() .. " <" .. ply:SteamID() .. ">` spawned in the server.")
	end

	local function onPlayerDisconnected(ply)
		sendMessage("Player `" .. ply:GetName() .. " <" .. ply:SteamID() .. ">` left the server.")
	end

	local function onServerShutdown()
		sendMessage("Server shutting down.")
	end

	local function onPlayerGroupChange(steamid, allows, denies, new_group, old_group)
		-- TODO check if player with SteamID is on the server and add their name
		if old_group ~= nil then
			sendMessage("Player with SteamID `" .. steamid .. "` had their group changed from `" .. old_group .. "` to `" .. new_group .. "`.")
		else
			sendMessage("Player with SteamID `" .. steamid .. "` had their group set to `" .. new_group .. "`.")
		end
	end

	local function onPlayerGroupRemoved(steamid, user_info)
		if user_info ~= nil and user_info.name then
			sendMessage("Player `" .. user_info.name .. " <" .. steamid .. "> had their group (`" .. user_info.group .. "`) removed.")
		else
			-- TODO check if player with SteamID is on the server and add their name
			sendMessage("Player with SteamID `" .. steamid .. "` had their group (`" .. user_info.group .. "`) removed.")
		end
	end

	local function onPlayerKicked(steamid, reason, caller)
		local message = "Player with SteamID `" .. steamid .. "` was kicked from the server"
		if caller ~= nil and IsValid(caller) then
			message = message .. " by `" .. caller:GetName() .. " <" .. caller:SteamID() .. ">`."
		else
			message = message .. " by (Console)."
		end
		if reason ~= nil then
			message = message .. " Reason: `" .. reason .. "`"
		end
		sendMessage(message)
	end

	local function onPlayerBanned(steamid, ban_data)
		local message = ""
		if ban_data.name ~= nil then
			message = "Player `" .. ban_data.name .. " <" .. steamid .. ">` was banned"
		else
			message = "Player with SteamID `" .. steamid .. "` was banned"
		end
		if ban_data.unban ~= 0 then
			message = message .. " for " .. (ban_data.unban - ban_data.time) .. " seconds by `" .. ban_data.admin .. "`."
		else
			message = message .. " permanently by `" .. ban_data.admin .. "`."
		end
		if ban_data.reason ~= nil then
			message = message .. " Reason: `" .. ban_data.reason .. "`"
		else
			message = message .. " No reason was provided."
		end
		sendMessage(message)
	end

	local function onPlayerUnBanned(steamid, caller)
		local message = "Player with SteamID `" .. steamid .. "` was unbanned"
		if caller ~= nil and IsValid(caller) then
			message = message .. " by `" .. caller:GetName() .. " <" .. caller:SteamID() .. ">`"
		else
			message = message .. " by (Console)"
		end
		sendMessage(message)
	end

	if(file.Exists(SETTINGS_FILE, "DATA")) then
		loadSettings()
	else
		saveSettings()
	end

	if isSettingsValid() then
		hook.Add("Think", "DISCORD_SERVER_LOADED", onServerLoaded)
		hook.Add("PlayerConnect", "DISCORD_PLAYER_CONNECTING", onPlayerConnect)
		hook.Add("PlayerInitialSpawn", "DISCORD_PLAYER_INITIAL_SPAWN", onInitialSpawn)
		--hook.Add("PlayerSpawn", "DISCORD_PLAYER_SPAWN", onPlayerSpawn)
		hook.Add("PlayerDisconnected", "DISCORD_PLAYER_DISCONNECTED", onPlayerDisconnected)
		hook.Add("ShutDown", "DISCORD_SERVER_SHUTDOWN", onServerShutdown)
		timer.Simple(5, function()
			if ULib then -- Hook to ULib events if it is on the server
				hook.Add("ULibUserGroupChange", "DISCORD_ULIB_PLAYER_GROUP_CHANGE", onPlayerGroupChange)
				hook.Add("ULibUserGroupRemoved", "DISCORD_ULIB_PLAYER_GROUP_REMOVED", onPlayerGroupRemoved)
				hook.Add("ULibPlayerKicked", "DISCORD_ULIB_PLAYER_KICKED", onPlayerKicked)
				hook.Add("ULibPlayerBanned", "DISCORD_ULIB_PLAYER_BANNED", onPlayerBanned)
				hook.Add("ULibPlayerUnBanned", "DISCORD_ULIB_PLAYER_UNBANNED", onPlayerUnBanned)
			end
		end)
	else
		print("[Discord Logger] File '" .. SETTINGS_FILE .. "' contains empty or invalid configuration - addon is disabled! Make sure your configuration is valid and restart the server.")
	end

end
