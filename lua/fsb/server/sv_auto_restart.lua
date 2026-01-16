local TIME_TO_RESTART = 15*60*60 -- Seconds until the server will restart the current map.

FSB.MAP_START_TIME = FSB.MAP_START_TIME or SysTime()

-- Manages automatic server restart.
-- Wiremod claims that PlayerDisconnected doesn't always run.
hook.Add("EntityRemoved", "empty_server_map_cleanup", function(ent, fullUpdate)
	local map_uptime = SysTime()-FSB.MAP_START_TIME
	if ent:IsPlayer() and player.GetCount() == 0 and map_uptime > TIME_TO_RESTART then
		print("Map was up for", map_uptime, " restarting the map.")
		RunConsoleCommand("changelevel", game.GetMap())
	end
end)