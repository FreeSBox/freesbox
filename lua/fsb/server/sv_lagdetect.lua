require("tickrate")

---@diagnostic disable: inject-field
local cleanup_threshold = 800 -- milliseconds
local penetration_stopper_threshold = 60 -- milliseconds
local seconds_before_cleanup = 60
local max_entities_per_tick = 15 -- How many entities can a player spawn in 1 tick.
local autoban_time = 300 -- For how many seconds do we automatically ban a suspected crasher?
local num_frames = 6 -- the avarage of this number of frames is checked against the threashold


local tickrate = 1/engine.TickInterval()
local sv_hibernate_think = GetConVar("sv_hibernate_think")
local last_ticktime = 0

---This will freeze all props that are owned by players.
function FSB.FreezeAllProps()
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
	last_frames[i] = engine.TickInterval()*1000
end

local function pushMSPT(framerate)
	for i = 1, num_frames-1 do
		last_frames[i] = last_frames[i+1]
	end
	last_frames[num_frames] = framerate
end

local function getAverageMSPT()
	local sum = 0
	for i = 1, num_frames do
		sum = sum + last_frames[i]
	end
	return sum/num_frames
end

function FSB.GetAverageMSPT()
	return getAverageMSPT()
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
			temp[1].ply.likely_crasher = (temp[1].ply.likely_crasher or 0) + 1
			FSB.SendLocalizedMessage("lag.print_penetrating", temp[1].ply:Nick(), temp[1].count)
			print(temp[1].ply:Nick(), "has", temp[1].count, "penetrating props!")

			if temp[1].ply.likely_crasher > 6 then
				FSB.GhostBan(temp[1].ply, os.time()+autoban_time, "lag autoban")
				FSB.SendLocalizedMessage("lag.autobanned", temp[1].ply:Nick(), autoban_time)
				NADMOD.CleanPlayer(Player(0), temp[1].ply)
				MsgN("Anticrash automatically banned " .. temp[1].ply:Nick() .. " for " .. autoban_time .. " seconds")
			end
		end
	end
end

local function handleCleanUp()
	physenv.SetPhysicsPaused(true)
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
	pushMSPT(GetFrameDelta())
	local not_from_hybernation = player.GetCount() > 0 -- GetCount doesn't count loading players.
	local should_run_cleanup_logic = ( sv_hibernate_think:GetBool() or not_from_hybernation ) and last_ticktime ~= 0 and not FSB.IsCleanUpInProgress() and game.MaxPlayers() ~= 1
	if should_run_cleanup_logic then
		if physenv.GetLastSimulationTime()*1000 > penetration_stopper_threshold then
			handleFindPropPenetration()
		end
		if physenv.GetLastSimulationTime()*1000 > penetration_stopper_threshold and getAverageMSPT() > cleanup_threshold then
			handleCleanUp()
		end
	end
	last_ticktime = sys_time

	for _, v in ipairs(player.GetHumans()) do
		v.ents_this_tick = 0
	end
end)


local model_blacklist =
{
	["models/props_combine/combine_citadel001.mdl"] = true,
}


local function handle_blacklist(ply, model, skin)
	if model_blacklist[model] then
		return false
	end
end

hook.Add("PlayerSpawnObject", "blocked_props", handle_blacklist)

local function handle_ratelimit(ply)
	if ply.spawns_blocked then return false end
	if ply.ents_this_tick > max_entities_per_tick then
		ply.spawns_blocked = true
		return false
	end
	ply.ents_this_tick = ply.ents_this_tick + 1
end


hook.Add("PlayerSpawnProp", "blocked_props", handle_ratelimit)
hook.Add("PlayerSpawnRagdoll", "blocked_props", handle_ratelimit)
hook.Add("PlayerSpawnNPC", "blocked_props", handle_ratelimit)
hook.Add("PlayerSpawnVehicle", "blocked_props", handle_ratelimit)

hook.Add("PlayerSpawnSENT", "blocked_props", handle_ratelimit)

hook.Add("PlayerInitialSpawn", "init_ent_counter", function (player, transition)
	player.likely_crasher = 0
	player.ents_this_tick = 0
	player.spawns_blocked = false
end)

timer.Create("reset_likely_crasher", 300, 0, function ()
	for _, ply in ipairs(player.GetHumans()) do
		ply.likely_crasher = 0
	end
end)

timer.Create("reset_spawn_blocked", 1, 0, function ()
	for _, v in ipairs(player.GetHumans()) do
		if v.spawns_blocked then
			FSB.SendLocalizedMessage("lag.too_many_props", v:Nick())
			v.spawns_blocked = false
		end
	end
end)
