local spawnzone_color = Color(0, 255, 0)

local spawnzones =
{
	["gm_construct"] = {Vector(1024, -896, -144), Vector(640, 800, 64)},
	["gm_york_remaster"] = {Vector(384, -6272, 8), Vector(2880, -7960, 820)},
}

local fsb_draw_spawnzone = CreateClientConVar("fsb_draw_spawnzone", "1", true, false)

local current_zone = spawnzones[game.GetMap()]
if current_zone == nil then
	print("FIXME: Current map has no spawnzone!")
	return
end

if SERVER then
	local allowed_classes = {
		["gmod_hands"] = true,
		["predicted_viewmodel"] = true,
		["physgun_beam"] = true,
	}
	local disallowed_classes = {
		["monster_snark"] = true,
	}

	local function isEntityDisallowedAtSpawn(ent)
		local class = ent:GetClass()
		return (ent:CPPIGetOwner() ~= nil and not ent:CreatedByMap() and not ent:IsWeapon() and not allowed_classes[class]) or disallowed_classes[class] == true
	end

	hook.Add("Think", "check_spawnzone_ents", function()
		for _, ent in ipairs(ents.FindInBox(current_zone[1], current_zone[2])) do
			if isEntityDisallowedAtSpawn(ent) then
				print("Bad entity at spawn, removing:", ent)
				ent:Remove()
			end
		end
	end)

	hook.Add("PlayerSpawnObject", "block_spawn_in_spawnzone", function(ply, model, skin)
		if ply:GetPos():WithinAABox(current_zone[1], current_zone[2]) then
			return false
		end
	end)

	hook.Add("EntityTakeDamage", "block_spawn_in_spawnzone", function(target, dmg)
		local attacker = dmg:GetAttacker()
		if attacker:IsPlayer() and attacker:GetPos():WithinAABox(current_zone[1], current_zone[2]) then
			return true
		end
		if target:GetPos():WithinAABox(current_zone[1], current_zone[2]) then
			return true
		end
	end)
else
	hook.Add("PostDrawTranslucentRenderables", "draw_spawnzone", function(bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)
		if fsb_draw_spawnzone:GetBool() then
			render.DrawWireframeBox(vector_origin, angle_zero, current_zone[1], current_zone[2], spawnzone_color, true)
		end
	end)
end