local skybox_zones =
{
	["gm_bigcity"] = {Vector(3072, -3072, 4416), Vector(-3072, 3072, 5632)},
	["gm_bigcity_improved"] = {Vector(3072, -3072, 4416), Vector(-3072, 3072, 5632)},
	["gm_bigcity_winter"] = {Vector(3072, -3072, 4416), Vector(-3072, 3072, 5632)},
	["gm_york_remaster"] = {Vector(15690, 15690, -9240), Vector(-15690, -15690, -7008)},
	["gm_mobenix_v3_final"] = {Vector(-10218, -2890, 12042), Vector(-15272, 458, 11062)},
	["gm_construct"] = {Vector(-15100, -15100, 10431.25), Vector(15100, 15100, 15300)},
	["gm_construct_in_flatgrass"] = {Vector(8192, -8192, -11263), Vector(-8192, 8192, -15360)},
}
local current_zone = skybox_zones[game.GetMap()]
if current_zone == nil then
	print("FIXME: Current map has no skybox!")
	return
end

hook.Add("Think", "check_skybox_ents", function()
	for _, ent in ipairs(ents.FindInBox(current_zone[1], current_zone[2])) do
		if ent:IsPlayer() then
			ent:Spawn()
		elseif not ent:CreatedByMap() then
			ent:Remove()
		end
	end
end)

hook.Add("PlayerSpawnObject", "block_spawn_in_spawnzone", function(ply, model, skin)
	if ply:GetPos():WithinAABox(current_zone[1], current_zone[2]) then
		return false
	end
end)