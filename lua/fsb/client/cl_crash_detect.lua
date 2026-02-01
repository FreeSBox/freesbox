
local TIMEOUT_TIME = 0.5
local was_timing_out = false

hook.Add("StartCommand", "init_crash_detect", function (ply, ucmd)
	-- Will only apply on the next join.
	-- But it's better then assuming the player has enough timeout time.
	RunConsoleCommand("cl_timeout", "600")

	timer.Create("CrashDetect", TIMEOUT_TIME, 0, function ()
		local timing_out, last_ping = GetTimeoutInfo()
		if timing_out then
			if not was_timing_out then
				FSB.EnableFreecam()
				chat.AddText(Color(255,0,0), FSB.Translate("lag.timing_out"))
			end
			was_timing_out = true
		elseif was_timing_out then
			was_timing_out = false
			FSB.DisableFreecam()
		end
	end)
	hook.Remove("StartCommand", "init_crash_detect")
end)

