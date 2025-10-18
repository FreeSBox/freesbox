
local function log_spawn(ply, model, ent)
	print(ent, model, ply:GetName())
end

hook.Add("PlayerSpawnedEffect", "effect_spawn_log", log_spawn)
hook.Add("PlayerSpawnedProp", "prop_spawn_log", log_spawn)
hook.Add("PlayerSpawnedRagdoll", "ragdoll_spawn_log", log_spawn)

