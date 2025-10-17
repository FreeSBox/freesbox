local threshold = 1.5
local notification = "Big lag detected! Clean up in 1 minute."

local sv_hibernate_think = GetConVar("sv_hibernate_think")
local last_ticktime = 0
local clean_up_started = false

hook.Add("Tick", "lag_detect", function()
	local cur_time = SysTime()
	local delta_time = cur_time-last_ticktime
	local not_from_hybernation = player.GetCount() > 0 -- GetCount doesn't count loading players.
	if delta_time > threshold and ( sv_hibernate_think:GetBool() or not_from_hybernation ) and last_ticktime ~= 0 and not clean_up_started then
		RunConsoleCommand("phys_timescale", "0")
		PrintMessage(HUD_PRINTTALK, notification)
		PrintMessage(HUD_PRINTCENTER, notification)
		print("Frozen for:", cur_time-last_ticktime, "seconds")

		timer.Simple(60, function()
			game.CleanUpMap()
			RunConsoleCommand("phys_timescale", "1")
			clean_up_started = false
		end)
	end
	last_ticktime = cur_time
end)
