local spawnzone_color = Color(0, 255, 0)

local spawnzones =
{
	["gm_construct"] = {Vector(1024, -896, -144), Vector(640, 800, 64)}
}

local current_zone = spawnzones[game.GetMap()]
if current_zone == nil then
	print("FIXME: Current map has no spawnzone!")
	return
end

if SERVER then
	--[[
	Turns out we need CPPI for this, otherwise it deletes half the player.
	hook.Add("Think", "check_spawnzone_ents", function()
		for _, ent in ipairs(ents.FindInBox(current_zone[1], current_zone[2])) do
			if not ent:IsPlayer() and not ent:IsWeapon() and not ent:CreatedByMap() then
				print(ent)
				ent:Remove()
			end
		end
	end)
	--]]

	hook.Add("PlayerSpawnObject", "block_spawn_in_spawnzone", function(ply, model, skin)
		if ply:GetPos():WithinAABox(current_zone[1], current_zone[2]) then
			return false
		end
	end)

	hook.Add("EntityTakeDamage", "block_spawn_in_spawnzone", function(target, dmg)
		if target:GetPos():WithinAABox(current_zone[1], current_zone[2]) then
			return true
		end
	end)
else
	hook.Add("PostDrawTranslucentRenderables", "draw_spawnzone", function(bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)
		render.DrawWireframeBox(vector_origin, angle_zero, current_zone[1], current_zone[2], spawnzone_color, true)
	end)
end