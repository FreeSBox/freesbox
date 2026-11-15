local SECONDS_BEFORE_SHUTDOWN = 60

---Will restart the server once all players leave
function FSB.ScheduleRestartWhenEmpty()
	timer.Remove("checkRestart")
	SetGlobal2Bool("restartOnEmpty", true)
end

---@param time number unix timestamp
---@param restart_when_empty boolean? Should we restart early if all players leave, default true
function FSB.ScheduleRestart(time, restart_when_empty)
	if time < os.time() then
		Msg("Can't schedule restart for a time in the past\n")
		return
	end

	SetGlobal2Bool("restartOnEmpty", restart_when_empty or true)
	SetGlobalInt("serverRestartTime", time)
	timer.Create("checkRestart", 1, 0, function ()
		local minutes_until_restart = (GetGlobalInt("serverRestartTime")-os.time())/60
		if minutes_until_restart < 10 and (minutes_until_restart % 1) == 0 then
			FSB.SendLocalizedMessage("timer.restart_chat", minutes_until_restart)
			FSB.SendLocalizedMessage("timer.restart_chat", minutes_until_restart)
			FSB.PushLogWithConsole("The server will restart in %i minutes!", minutes_until_restart)
		end
		if minutes_until_restart < 1 then
			FSB.StopServer(true)
			timer.Remove("checkRestart")
		end
	end)

	Msg(os.date("Restart scheduled for %d/%m/%Y %H:%M:%S\n", time))
end

function FSB.CancelRestart()
	SetGlobalInt("serverRestartTime", 0)
	SetGlobal2Bool("restartOnEmpty", false)
	timer.Remove("checkRestart")
	Msg("Restart cancelled")
end

---@param automatic boolean? Was this an automated action, default false
function FSB.StopServer(automatic)
	Msg("Server shutdown started!\n")
	if player.GetCountConnecting() + player.GetCount() == 0 then
		engine.CloseServer()
	end

	FSB.TelemetryRestart(automatic or false)

	local cur_time = CurTime()
	FSB.BroadcastTimer(cur_time, cur_time+SECONDS_BEFORE_SHUTDOWN, "timer.shutdown")

	timer.Create("server_shutdown", 60, 1, function()
		Msg("The server is shutting down. Well at least it should, if -allowquit is set up properly.\n")
		-- Needs -allowquit cmdline
		engine.CloseServer()
	end)
end

-- Manages automatic server restart.
-- Wiremod claims that PlayerDisconnected doesn't always run.
hook.Add("EntityRemoved", "empty_server_map_cleanup", function(ent, fullUpdate)
	if ent:IsPlayer() and player.GetCount() == 0 and (GetGlobal2Bool("restartOnEmpty") or timer.Exists("server_shutdown")) then
		FSB.TelemetryRestart(true)
		engine.CloseServer()
	end
end)
