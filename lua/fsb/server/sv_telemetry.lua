local fsb_telemetry_zabbix_enable  = CreateConVar("fsb_telemetry_zabbix_enable", "0", FCVAR_ARCHIVE, "Should we try to send telemetry to zabbix")
local fsb_telemetry_zabbix_host   = CreateConVar("fsb_telemetry_zabbix_host", "Zabbix server", FCVAR_ARCHIVE, "Zabbix host")
local fsb_telemetry_zabbix_token   = CreateConVar("fsb_telemetry_zabbix_token", "0", FCVAR_ARCHIVE, "Zabbix API token")
local fsb_telemetry_zabbix_address = CreateConVar("fsb_telemetry_zabbix_address", "http://192.168.1.1:80/api_jsonrpc.php", FCVAR_ARCHIVE,
	[[Zabbix server address. Ex.: http://192.168.1.1:80/api_jsonrpc.php
	Note that for this example the server must be launched with the -allowlocalhttp argument]]
)

function FSB.MakeZabbixParam(key, value)
	return {
		key=key,
		value=value,
		host=fsb_telemetry_zabbix_host:GetString()
	}
end

sql.Query([[CREATE TABLE IF NOT EXISTS fsb_telemetry (
	type TEXT,
	data TEXT,
	time BIGINT
)]])

--#region Verbose logging
local fmt = string.format

--- Max size in bytes
MAX_VERBOSE_LOG_FILESIZE = 5*1024*1024
local current_file = "log1.txt"

local function selectLogFile()
	if not file.Exists("fsb_short_logs/log2.txt", "DATA") then
		current_file = "log1.txt"
		return
	end

	local file1_time = file.Time("fsb_short_logs/log1.txt", "DATA")
	local file2_time = file.Time("fsb_short_logs/log2.txt", "DATA")

	if file1_time > file2_time then
		current_file = "log1.txt"
	else
		current_file = "log2.txt"
	end
end

selectLogFile()

local function logWrite(content)
	---@type File
	---@diagnostic disable-next-line: assign-type-mismatch
	local f = file.Open("fsb_short_logs/" .. current_file, "ab", "DATA")
	if not f then
		return false
	end

	f:Write(content)
	local filesize = f:Size()
	f:Close()

	if filesize > MAX_VERBOSE_LOG_FILESIZE then
		MsgN("Switching log file")
		if current_file == "log1.txt" then
			file.Delete("fsb_short_logs/log2.txt")
			current_file = "log2.txt"
		else
			file.Delete("fsb_short_logs/log1.txt")
			current_file = "log1.txt"
		end
	end
end

---Log data that would be too anoying to spam into the console, yet usefull when debugging an issue
---@param format string
---@param ... any
function FSB.PushLog(format, ...)
	local msg = fmt("%i | %f | %s | %s\n", engine.TickCount(), SysTime(), os.date("%m-%d %H:%M:%S"), fmt(format, ...))
	logWrite(msg)
end

---@param format string
---@param ... any
function FSB.PushLogWithConsole(format, ...)
	local base = fmt(format, ...)
	MsgN(base)

	local msg = fmt("%i | %f | %s | %s\n", engine.TickCount(), SysTime(), os.date("%m-%d %H:%M:%S"), base)
	logWrite(msg)
end

hook.Add("OnLuaError", "log_lua_errors", function (error, realm, stack, name, id)
	FSB.PushLog("Lua error, realm: %s | addon: %s | wsid: %s | error: %s | stack: %s", realm, name, id, error, util.TableToJSON(stack))
end)

hook.Add("OnClientLuaError", "log_client_lua_errors", function (error, ply, stack, name)
	FSB.PushLog("Client Lua error, ply: %s | plysteam: %s | addon: %s | error: %s | stack: %s", ply:Name(), ply:SteamID(), name, error, util.TableToJSON(stack))
end)

hook.Add("PlayerSpawnObject", "log_object_spawn", function (ply, model)
	FSB.PushLog("Object spawned, ply: %s | plysteam: %s | model: %s", ply:Name(), ply:SteamID(), model)
end)

hook.Add("CanTool", "log_tool_use", function (ply, tr, toolname, tool, button)
	if toolname == "inflator" or toolname == "paint" then
		return
	end

	local hit_ent = "World"
	if tr.HitNonWorld then
		hit_ent = tostring(tr.Entity)
	end

	if button == nil then
		button = -1
	end

	FSB.PushLog("Tool use, ply: %s | plysteam: %s | tool: %s | button: %i | target: %s", ply:Name(), ply:SteamID(), toolname, button, hit_ent)
end)

hook.Add("PlayerSay", "log_chat_msgs", function (ply, text)
	FSB.PushLog("Chat msg, ply: %s | plysteam: %s | msg: %s", ply:Name(), ply:SteamID(), text)
end)

--#endregion

---Converts the data table to json and saves it in the database.
---@param type string
---@param data table
function FSB.TelemetryWrite(type, data)
	assert(isstring(type), "telemetry type must be a string")
	assert(istable(data), "telemetry data must be a table")

	local json_data = util.TableToJSON(data, false)
	sql.QueryTyped([[INSERT INTO fsb_telemetry(
			type,
			data,
			time
		) VALUES (?, ?, ?)
		]],
		type,
		json_data,
		os.time()
	)
	FSB.PushLog("Telemetry, type: %s | data: %s", type, json_data)
end

---@param frame_dump table
function FSB.TelemetryLagDetected(frame_dump)
	local metric = {}

	metric["average_mspt"] = FSB.GetAverageMSPT()
	metric["last_mspt"] = GetFrameDelta()
	metric["phys_delta"] = physenv.GetLastSimulationTime()*1000
	metric["ent_count"] = ents.GetCount()
	metric["ply_count"] = player.GetCount()
	metric["last_frames"] = frame_dump

	FSB.TelemetryWrite("lag_detected", metric)
end

function FSB.GetAveragePing()
	local players = player.GetHumans()
	local ping_sum = 0
	for _, ply in ipairs(players) do
		ping_sum = ping_sum + ply:Ping()
	end
	return ping_sum/#players
end

function FSB.GetNumNetStrings()
	local num_net_strings = 1
	while util.NetworkIDToString(num_net_strings) do
		num_net_strings = num_net_strings + 1
	end
	return num_net_strings
end

function FSB.TelemetryGeneric()
	local metric = {}

	metric["average_mspt"] = FSB.GetAverageMSPT()
	metric["ent_count"] = ents.GetCount()

	local players = player.GetHumans()
	metric["ply_count"] = #players
	metric["ping_average"] = FSB.GetAveragePing()
	metric["net_strings"] = FSB.GetNumNetStrings()

	FSB.TelemetryWrite("generic", metric)
end
timer.Create("telemetry_generic", 60*5, 0, FSB.TelemetryGeneric)

function FSB.TelemetryRestart(automatic)
	local metric = {}

	metric["automatic"] = automatic

	FSB.TelemetryWrite("restart", metric)
end

---@param ply Player
---@param penetrating_count number
function FSB.TelemetryLikelyCrasher(ply, penetrating_count)
	local metric = {}

	metric["player_name"]   = ply:Nick()
	metric["steamid"]       = ply:SteamID64()
	metric["penetrating_count"] = penetrating_count

	FSB.TelemetryWrite("likely_crasher", metric)
end

function FSB.TelemetryGCCExploit(ply)
	local metric = {}

	metric["player_name"] = ply:Nick()
	metric["steamid"]     = ply:SteamID64()

	FSB.TelemetryWrite("gcc_exploit", metric)
end

function FSB.TelemetryStart()
	local metric = {}

	metric["map"] = game.GetMap()

	FSB.TelemetryWrite("start", metric)
end

hook.Add("Initialize", "telemetry_server_start", FSB.TelemetryStart)


--#region Chip logging

hook.Add("Expression2_CanCompile", "log_e2_spawn", function (ply, chip, buffer, filepath, files)
	FSB.PushLog("E2 spawn attempted by %s, not compiled yet", ply:Name())
	timer.Simple(0, function ()
		Msg(string.format("%s compiled E2: %s\n", ply:Name(), tostring(chip.name)))
	end)
end)

hook.Add("StarfallCanCompile", "log_sf_spawn", function (code, mainfile, ply, chip)
	local message = string.format("%s compiled SF: %s\n", ply:Name(), tostring(mainfile))
	Msg(message)
	FSB.PushLog(message)
end)

--#endregion

--#region NetMessage Logging
hook.Add("NetIncoming", "log_net_msgs", function (net_index, name, len, ply)
	FSB.PushLog("Recieved netmsg, idx: %i | name: %s | len: %i | ply: %s | plysteam: %s", net_index, name, len, ply:Name(), ply:SteamID())
end)
--#endregion

--#region LuaRun Logging
local STAGE_PREPROCESS = 1
local STAGE_POST = 3
hook.Add("LuaDevProcess", "log_luadev", function (stage, script, info, extra)
	if stage ~= STAGE_PREPROCESS then return end

	assert(isstring(script), "log_luadev: script is not a string")

	local ply = nil
	if extra and IsValid(extra.ply) then
		ply = extra.ply
	end

	local metric = {}
	metric["player_name"]    = ply ~= nil and extra.ply:GetName() or "Unknown"
	metric["player_steamid"] = ply ~= nil and extra.ply:SteamID64() or "Unknown"
	metric["script"] = script

	FSB.TelemetryWrite("lua_run", metric)
end)
--#endregion

--#region Crash Handler

local function backupLogs()
	local crash_name = os.date("crash_%Y-%m-%d_%H-%M-%S")
	if file.Exists("fsb_short_logs/log1.txt", "DATA") then
		file.Rename("fsb_short_logs/log1.txt", "fsb_short_logs/"..crash_name.."-log1.txt")
	end
	if file.Exists("fsb_short_logs/log2.txt", "DATA") then
		file.Rename("fsb_short_logs/log2.txt", "fsb_short_logs/"..crash_name.."-log2.txt")
	end
end

hook.Add("HolyLib:OnServerCrash", "holylib_crash_detect", function (crashed_module)
	local server_crash_msg = "THE SERVER CRASHED IN " .. crashed_module .. " MODULE, LUA TRACE BELOW\n"

	local level = 1
	while true do
		local info = debug.getinfo(level, "Sln")
		if ( !info ) then break end

		if ( info.what ) == "C" then
			server_crash_msg = server_crash_msg .. string.format("%i: C function\t\"%s\"\n", level, info.name)
		else
			server_crash_msg = server_crash_msg .. string.format("%i: Line %d\t\"%s\"\t\t%s\n", level, info.currentline, info.name, info.short_src)
		end

		level = level + 1
	end

	FSB.PushLogWithConsole(server_crash_msg)

	backupLogs()
end)
--#endregion

FSB.PushLog("TELEMETRY LOADED")
