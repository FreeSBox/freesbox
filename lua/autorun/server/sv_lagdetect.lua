local threshold = 1.5
local notification = "Big lag detected! Clean up in 1 minute."

local last_ticktime = 0
local clean_up_started = false

hook.Add("Tick", "lag_detect", function()
	local cur_time = SysTime()
	if cur_time-last_ticktime > threshold and last_ticktime ~= 0 and not clean_up_started then
		RunConsoleCommand("phys_timescale", "0")
		PrintMessage(HUD_PRINTTALK, notification)
		PrintMessage(HUD_PRINTCENTER, notification)

		timer.Simple(60, function ()
			game.CleanUpMap()
			RunConsoleCommand("phys_timescale", "1")
			clean_up_started = false
		end)
	end
	last_ticktime = cur_time
end)
