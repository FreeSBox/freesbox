
local SECONDS_BEFORE_SHUTDOWN = 60

function FSB.StopServer()
	if player.GetCountConnecting() + player.GetCount() == 0 then
		RunConsoleCommand("exit")
	end

	FSB.TelemetryRestart(false)

	local cur_time = CurTime()
	FSB.BroadcastTimer(cur_time, cur_time+SECONDS_BEFORE_SHUTDOWN, "timer.shutdown")

	timer.Create("server_shutdown", 60, 1, function()
		--We can run this command because of the [remove_restrictions](https://github.com/FreeSBox/gmsv_remove_restrictions) binary module.
		RunConsoleCommand("quit", "keep_players")
	end)
end
