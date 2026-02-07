---Not actual telemetry we just write data to a local database.

sql.Query([[CREATE TABLE IF NOT EXISTS fsb_telemetry (
	type TEXT,
	data TEXT,
	time BIGINT
)]])

---Converts the data table to json and saves it in the database.
---@param type string
---@param data table
function FSB.TelemetryWrite(type, data)
	assert(isstring(type), "telemetry type must be a string")
	assert(istable(data), "telemetry data must be a table")

	sql.QueryTyped([[INSERT INTO fsb_telemetry(
			type,
			data,
			time
		) VALUES (?, ?, ?)
		]],
		type,
		util.TableToJSON(data, false),
		os.time()
	)
end

---@param frame_dump table
function FSB.TelemetryLagDetected(frame_dump)
	local metric = {}

	metric["average_mspt"] = FSB.GetAverageMSPT()
	metric["ent_count"] = ents.GetCount()
	metric["ply_count"] = player.GetCount()
	metric["last_frames"] = frame_dump

	FSB.TelemetryWrite("lag_detected", metric)
end

function FSB.TelemetryGeneric()
	local metric = {}

	metric["average_mspt"] = FSB.GetAverageMSPT()
	metric["ent_count"] = ents.GetCount()

	local players = player.GetHumans()
	metric["ply_count"] = #players

	local ping_sum = 0
	for _, ply in ipairs(players) do
		ping_sum = ping_sum + ply:Ping()
	end
	metric["ping_average"] = ping_sum/#players

	local num_net_strings = 1
	while util.NetworkIDToString(num_net_strings) do
		num_net_strings = num_net_strings + 1
	end
	metric["net_strings"] = num_net_strings


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
