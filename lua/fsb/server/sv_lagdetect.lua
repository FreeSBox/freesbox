local cleanup_threshold = 20 -- tps
local penetration_stopper_threshold = 40 -- tps
local seconds_before_cleanup = 60

local num_frames = 6 -- the avarage of this number of frames is checked against the threashold

local sv_hibernate_think = GetConVar("sv_hibernate_think")
local last_ticktime = 0

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

local function getAverageFramerate()
	local sum = 0
	for i = 1, num_frames do
		sum = sum + last_frames[i]
	end
	return sum/num_frames
end

function FSB.GetAverageTPS()
	return getAverageFramerate()
end

local function handleFindPropPenetration()
	local num_penetrations_per_player = {}
	local num_penetrations = 0
	for _, ent in ipairs(ents.GetAll()) do
		if IsValid(ent) then
			local phys_object = ent:GetPhysicsObject()
			if IsValid(phys_object) and phys_object:IsPenetrating() and phys_object:IsMotionEnabled() then
				phys_object:EnableMotion(false)
				num_penetrations = num_penetrations + 1
				local owner = ent:CPPIGetOwner()
				if owner then
					num_penetrations_per_player[owner] = (num_penetrations_per_player[owner] or 0) + 1
				end
			end
		end
	end
	if num_penetrations > 10 then
		FSB.SendLocalizedMessage("lag.freeze_penetrating")

		-- GPL3 code
		-- https://github.com/PAC3-Server/notagain/blob/3d1d0d0814dde53f2ce46a345b7c8db7d211f2e8/lua/notagain/essential/autorun/server/freeze_penetrating.lua
		local temp = {}
		for k,v in pairs(num_penetrations_per_player) do table.insert(temp, {ply = k, count = v}) end
		table.sort(temp, function(a, b) return a.count > b.count end)
		if temp[1] then
			FSB.SendLocalizedMessage("lag.print_penetrating", temp[1].ply:Nick(), temp[1].count)
		end
	end
end

local function handleCleanUp()
	freezeAllPlayerProps()
	RunConsoleCommand("phys_timescale", "0")
	FSB.SendLocalizedMessage("lag.cleanup", seconds_before_cleanup)
	local cur_time = CurTime()
	Msg("Cleanup forced, dump of the last " .. tostring(num_frames) .. " frames:\n")
	for i = 1, num_frames do
		MsgN(last_frames[i])
	end
	FSB.CleanUpMap(60)
end

hook.Add("Tick", "lag_detect", function()
	local sys_time = SysTime()
	local delta_time = sys_time-last_ticktime
	pushFramerate(1/delta_time)
	local not_from_hybernation = player.GetCount() > 0 -- GetCount doesn't count loading players.
	local should_run_cleanup_logic = ( sv_hibernate_think:GetBool() or not_from_hybernation ) and last_ticktime ~= 0 and not FSB.IsCleanUpInProgress() and game.MaxPlayers() ~= 1
	if should_run_cleanup_logic then
		if getAverageFramerate() < penetration_stopper_threshold then
			handleFindPropPenetration()
		end
		if getAverageFramerate() < cleanup_threshold then
			handleCleanUp()
		end
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

