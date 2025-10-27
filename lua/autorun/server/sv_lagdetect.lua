local threshold = 30 -- tps
local notification = "Big lag detected! Clean up in 1 minute."
local seconds_before_cleanup = 60

local num_frames = 3 -- the avarage of this number of frames is checked against the threashold

local sv_hibernate_think = GetConVar("sv_hibernate_think")
local last_ticktime = 0
local clean_up_started = false

local function freezeAllPlayerProps()
	for _, ent in ipairs(ents.GetAll()) do
		if IsValid(ent) and ent:CPPIGetOwner() then
			local phys_object = ent:GetPhysicsObject()
			if IsValid(phys_object) then
				phys_object:EnableMotion(false)
			end
		end
	end
end

hook.Add("PlayerSpawnObject", "lag_detect_stop_spawn", function (ply, model, skin)
	if clean_up_started then
		print(ply:GetName() .. " tried to spawn: \"" .. model .. "\" while lag cleanup was in progress")
		return false
	end
end)

local last_frames = {}

-- Fill the structure with ideal data initially.
for i = 1, num_frames do
	last_frames[i] = 1/engine.TickInterval()
end

local function pushFramerate(framerate)
	for i = 1, num_frames-1 do
		last_frames[i] = last_frames[i+1]
	end
	last_frames[num_frames] = framerate
end

local function getAvarageFramerate()
	local sum = 0
	for i = 1, num_frames do
		sum = sum + last_frames[i]
	end
	return sum/num_frames
end

hook.Add("Tick", "lag_detect", function()
	local sys_time = SysTime()
	local delta_time = sys_time-last_ticktime
	pushFramerate(1/delta_time)
	local not_from_hybernation = player.GetCount() > 0 -- GetCount doesn't count loading players.
	if getAvarageFramerate() < threshold and ( sv_hibernate_think:GetBool() or not_from_hybernation ) and last_ticktime ~= 0 and not clean_up_started and game.MaxPlayers() ~= 1 then
		clean_up_started = true
		freezeAllPlayerProps()
		RunConsoleCommand("phys_timescale", "0")
		PrintMessage(HUD_PRINTTALK, notification)
		local cur_time = CurTime()
		Msg("Cleanup forced, dump of the last " .. tostring(num_frames) .. " frames:\n")
		for i = 1, num_frames do
			MsgN(last_frames[i])
		end
		FSBBroadcastTimer(cur_time, cur_time+seconds_before_cleanup, "timer.cleanup")

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

