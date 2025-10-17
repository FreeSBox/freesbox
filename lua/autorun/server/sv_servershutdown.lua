
local notification = "Server is shutting down in %u seconds."

function StopServer()

	timer.Create("server_shutdown", 1, 60, function()
		local reps_left = timer.RepsLeft("server_shutdown")
		local text = string.format(notification, reps_left)
		PrintMessage(HUD_PRINTTALK, text)
		PrintMessage(HUD_PRINTCENTER, text)

		if reps_left == 0 then
			--We can run this command because of the [remove_restrictions](https://github.com/FreeSBox/gmsv_remove_restrictions) binary module.
			RunConsoleCommand("exit")
		end
	end)
end
