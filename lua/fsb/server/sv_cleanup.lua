
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
