local threshold = 1.6
local notification = "Big lag detected! Clean up in 1 minute."
local seconds_before_cleanup = 60

local sv_hibernate_think = GetConVar("sv_hibernate_think")
local last_ticktime = 0
local clean_up_started = false

hook.Add("Tick", "lag_detect", function()
	local sys_time = SysTime()
	local delta_time = sys_time-last_ticktime
	local not_from_hybernation = player.GetCount() > 0 -- GetCount doesn't count loading players.
	if delta_time > threshold and ( sv_hibernate_think:GetBool() or not_from_hybernation ) and last_ticktime ~= 0 and not clean_up_started then
		RunConsoleCommand("phys_timescale", "0")
		PrintMessage(HUD_PRINTTALK, notification)
		local cur_time = CurTime()
		FSBBroadcastTimer(cur_time, cur_time+seconds_before_cleanup, "timer.cleanup")
		print("Frozen for:", sys_time-last_ticktime, "seconds")

		timer.Simple(60, function()
			game.CleanUpMap()
			RunConsoleCommand("phys_timescale", "1")
			clean_up_started = false
		end)
	end
	last_ticktime = sys_time
end)


local model_blacklist =
{
	["models/props_combine/combine_citadel001.mdl"] = true,
}


local function handle_prop_spawn_attempt(ply, model, skin)
	if model_blacklist[model] then
		return false
	end
end

hook.Add("PlayerSpawnObject", "blocked_props", handle_prop_spawn_attempt)

