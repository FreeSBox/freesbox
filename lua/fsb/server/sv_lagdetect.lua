if util.IsBinaryModuleInstalled("tickrate") then
	require("tickrate")
else
	MsgN("gmsv_tickrate is not installed, MSPT display may not be accurate")
	local last_ticktime = 0
	local last_delta = 0

	--This implementation is worse then the tickrate module
	--because if it took less then `engine.TickInterval()` to process the tick
	--this will still return `engine.TickInterval()`,
	function GetFrameDelta()
		return last_delta*1000
	end

	hook.Add("Tick", "mspt_counter", function()
		local sys_time = SysTime()
		last_delta = sys_time-last_ticktime
		last_ticktime = sys_time
	end)
end

---@diagnostic disable: inject-field
local CLEANUP_THRESHOLD = 800 -- milliseconds
local PENETRATION_STOPPER_THRESHOLD = 50 -- milliseconds
local PENETRATION_LIMIT = 8 -- how many penetrating props a player is allowed to have
local SECONDS_BEFORE_CLEANUP = 60
local MAX_ENTITIES_PER_TICK = 15 -- How many entities can a player spawn in 1 tick.
local AUTOBAN_INFRACTIONS = 3 -- How many times does a player need to trigger the anti-lag to get auto banned
local AUTOBAN_TIME = 300 -- For how many seconds do we automatically ban a suspected crasher?
local NUM_FRAMES = 6 -- the avarage of this number of frames is checked against the threashold


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

local function resetLastFrames()
	for i = 1, NUM_FRAMES do
		last_frames[i] = engine.TickInterval()*1000
	end
end

-- Fill the structure with ideal data initially.
resetLastFrames()

local function pushMSPT(framerate)
	for i = 1, NUM_FRAMES-1 do
		last_frames[i] = last_frames[i+1]
	end
	last_frames[NUM_FRAMES] = framerate
end

local function getAverageMSPT()
	local sum = 0
	for i = 1, NUM_FRAMES do
		sum = sum + last_frames[i]
	end
	return sum/NUM_FRAMES
end

function FSB.GetAverageMSPT()
	return getAverageMSPT()
end

local function stopAllChips()
	local chips = FSB.FindChips()

	for _, chip in ipairs(chips) do
		local class = chip:GetClass()
		if class == "gmod_wire_expression2" then
			chip:Error("Stopping chip due to server lag", "stopped due to server lag")
		elseif class == "gmod_wire_fpga" then
			chip:ThrowExecutionError("Stopping chip due to server lag", "stopped due to server lag")
		elseif class == "starfall_processor" then
			chip:Error({message="stopped due to server lag", traceback=""})
		end
	end
end

local function handleCleanUp()
	physenv.SetPhysicsPaused(true)
	stopAllChips()
	FSB.SendLocalizedMessage("lag.cleanup", SECONDS_BEFORE_CLEANUP)
	Msg("Cleanup forced, dump of the last " .. tostring(NUM_FRAMES) .. " frames:\n")
	for i = 1, NUM_FRAMES do
		MsgN(last_frames[i])
	end
	FSB.CleanUpMap(SECONDS_BEFORE_CLEANUP)
end


local lag_detected = false
hook.Add("Think", "lag_detect", function()
	local sys_time = SysTime()
	pushMSPT(GetFrameDelta())
	local not_from_hybernation = player.GetCount() > 0 -- GetCount doesn't count loading players.
	local should_run_cleanup_logic = ( sv_hibernate_think:GetBool() or not_from_hybernation ) and last_ticktime ~= 0 and not FSB.IsCleanUpInProgress() and game.MaxPlayers() ~= 1
	if should_run_cleanup_logic then
		if getAverageMSPT() > CLEANUP_THRESHOLD then
			FSB.TelemetryLagDetected(last_frames)
			-- This whole lag_detected nonsence is done so that we need more then one frame of lag to cause a cleanup
			-- there is no point in cleaning up if the lag is already gone
			resetLastFrames()
			lag_detected = true
			timer.Create("remove_lag_detected_flag", 0.5, 1, function ()
				lag_detected = false
			end)
		end
		if lag_detected and getAverageMSPT() > CLEANUP_THRESHOLD then
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
	if ply.ents_this_tick > MAX_ENTITIES_PER_TICK then
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
			Msg(string.format("%s spawned more them %i entities in one tick\n", v:Nick(), MAX_ENTITIES_PER_TICK))
			v.spawns_blocked = false
		end
	end
end)

-- This won't save us, as we need at least one prop to unfreeze
-- before phys:IsPenetrating starts working
-- but it may prevent someone from unfreezing a house or something
local ratelimit_table = {}
hook.Add("CanPlayerUnfreeze", "prevent_crash_dupe", function (player, entity, phys)
	if entity.CFW_GetContraption == nil then return end
	if not FSB.RatelimitCheck(ratelimit_table, player, 0.5) then
		return false
	end
	local contraption = entity:CFW_GetContraption()
	if contraption == nil then return end
	local num_penetrating = phys:IsPenetrating() and 1 or 0
	for ent in pairs(contraption.ents) do
		if not IsValid(ent) then goto CONTINUE end
		local phys_object = ent:GetPhysicsObject()
		if IsValid(phys_object) and phys_object:IsPenetrating() then
			num_penetrating = num_penetrating + 1
		end
		::CONTINUE::
	end
	local allow = num_penetrating < PENETRATION_LIMIT
	if not allow then
		FSB.RatelimitSet(ratelimit_table, player)
	end
	return allow
end)

physenv.SetLagThreshold(PENETRATION_STOPPER_THRESHOLD)
hook.Add("HolyLib:OnPhysicsLag", "holy_lag_detect", function (delta, phys1, phys2, recalcPhys, callerFunc)
	return physenv.IVP_SkipSimulation
end)
hook.Add("HolyLib:PostPhysicsLag", "holy_lag_prevent", function(delta)
	local num_penetrations_per_player = {}
	local num_penetrations = 0
	for _, ent in ents.Iterator() do
		if IsValid(ent) then
			local phys_object = ent:GetPhysicsObject()
			if IsValid(phys_object) and phys_object:IsPenetrating() and phys_object:IsMotionEnabled() then
				ent:SetCollisionGroup(COLLISION_GROUP_WORLD)
				num_penetrations = num_penetrations + 1
				local owner = ent:CPPIGetOwner()
				if owner then
					num_penetrations_per_player[owner] = (num_penetrations_per_player[owner] or 0) + 1
					Msg(string.format("Nocolliding penetrating prop: %s owned by: %s\n", ent:GetModel(), owner:Nick()))
				end
			end
		end
	end
	for ply, penetrations in pairs(num_penetrations_per_player) do
		ply:SendLocalizedHint("lag.you_have_penetrating_props", NOTIFY_GENERIC)
		Msg(string.format("%s has %i penetrating props\n", tostring(ply), penetrations))
		if penetrations > PENETRATION_LIMIT then
			ply.likely_crasher = (ply.likely_crasher or 0) + 1
			Msg(string.format("%s likely_crasher status increased to %i\n", tostring(ply), ply.likely_crasher))
			FSB.SendLocalizedMessage("lag.print_penetrating", ply:Nick(), penetrations)

			if ply.likely_crasher >= AUTOBAN_INFRACTIONS then
				FSB.GhostBan(ply, os.time()+AUTOBAN_TIME, "lag autoban")
				FSB.SendLocalizedMessage("lag.autobanned", ply:Nick(), AUTOBAN_TIME)
				NADMOD.CleanPlayer(Player(0), ply)
				FSB.TelemetryLikelyCrasher(ply, penetrations)
				MsgN("Anticrash automatically banned " .. ply:Nick() .. " for " .. AUTOBAN_TIME .. " seconds")
			end
		end
	end
end)
