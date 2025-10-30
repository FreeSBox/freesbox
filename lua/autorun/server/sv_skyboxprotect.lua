local skybox_zones =
{
	["gm_bigcity"] = {Vector(3072, -3072, 4416), Vector(-3072, 3072, 5632)},
	["gm_construct"] = {Vector(-15100, -15100, 10431.25), Vector(15100, 15100, 15300)}
}
local current_zone = skybox_zones[game.GetMap()]
if current_zone == nil then
	print("FIXME: Current map has no skybox!")
	return
end

hook.Add("Think", "check_spawnzone_ents", function()
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