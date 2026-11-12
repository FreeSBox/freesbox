
local SECONDS_BEFORE_SHUTDOWN = 60

function FSB.StopServer()
	Msg("The server is shutting down. Well at least it should, if -allowquit is set up properly.")
	if player.GetCountConnecting() + player.GetCount() == 0 then
		engine.CloseServer()
	end

	FSB.TelemetryRestart(false)

	local cur_time = CurTime()
	FSB.BroadcastTimer(cur_time, cur_time+SECONDS_BEFORE_SHUTDOWN, "timer.shutdown")

	timer.Create("server_shutdown", 60, 1, function()
		-- Needs -allowquit cmdline
		engine.CloseServer()
	end)
end
