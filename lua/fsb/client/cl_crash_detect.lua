
local timout_time = 4
local timing_out = false

hook.Add("StartCommand", "init_crash_detect", function (ply, ucmd)
	-- Will only apply on the next join.
	-- But it's better then assuming the player has enough timeout time.
	RunConsoleCommand("cl_timeout", "600")

	timer.Create("CrashDetect", timout_time, 0, function ()
		if FSB.LAST_NETMSG_TIME < RealTime()-timout_time then
			if not timing_out then
				FSB.EnableFreecam()
				chat.AddText(Color(255,0,0), FSB.Translate("lag.timing_out"))
			end
			timing_out = true
		elseif timing_out then
			timing_out = false
			FSB.DisableFreecam()
		end
	end)
	hook.Remove("StartCommand", "init_crash_detect")
end)

