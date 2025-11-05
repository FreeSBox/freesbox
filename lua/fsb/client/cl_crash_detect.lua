
local timout_time = 4
local timing_out = false

hook.Add("StartCommand", "init_crash_detect", function (ply, ucmd)
	--[[
	timer.Create("CrashDetect", timout_time, 0, function ()
		if FSB.LAST_NETMSG_TIME < RealTime()-timout_time and not timing_out then
			timing_out = true
			FSB.EnableFreecam()
			print("Server not responding")
		elseif timing_out then
			timing_out = false
			FSB.DisableFreecam()
		end
	end)
	--]]
	timer.Remove("CrashDetect")
	hook.Remove("StartCommand", "init_crash_detect")
end)

