
local cleanup_in_progress = false

function FSB.CleanUpMap(time_until_cleanup)
	local cur_time = CurTime()
	FSB.BroadcastTimer(cur_time, cur_time+time_until_cleanup, "timer.cleanup")
	cleanup_in_progress = true

	timer.Create("fsb_cleanup_timer", time_until_cleanup, 1, function ()
		game.CleanUpMap()
		RunConsoleCommand("phys_timescale", "1")
		cleanup_in_progress = false
	end)
end

function FSB.CancelCleanUp()
	if not timer.Exists("fsb_cleanup_timer") then return end
	timer.Stop("fsb_cleanup_timer")

	FSB.StopTimer()
	RunConsoleCommand("phys_timescale", "1")
	cleanup_in_progress = false
end

function FSB.IsCleanUpInProgress()
	return cleanup_in_progress
end

-- Manages automatic server cleanup.
-- Wiremod claims that PlayerDisconnected doesn't always run.
hook.Add("EntityRemoved", "empty_server_map_cleanup", function(ent, fullUpdate)
	if ent:IsPlayer() and player.GetCount() == 0 then
		-- Cannot run game.CleanUpMap while deleting entities!
		hook.Add("Tick", "run_map_cleanup", function ()
			hook.Remove("Tick", "run_map_cleanup")
			game.CleanUpMap()
			print("Server is empty, cleaning up the map")
		end)
	end
end)

