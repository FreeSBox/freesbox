local spawnzone_color = Color(0, 255, 0)

local spawnzones =
{
	["gm_construct"] = {
		min = Vector(1024, -896, -144),
		max = Vector(640, 800, 64),
		shoud_draw = true
	},
	["gm_construct_in_flatgrass"] = {
		min = Vector(1664, -224, -8600),
		max = Vector(2048, -1920, -8380),
		shoud_draw = true
	},
	["gm_york_remaster"] = {
		min = Vector(384, -6272, 8),
		max = Vector(2880, -7960, 820),
		shoud_draw = true
	},
	["gm_mobenix_v3_final"] = {
		min = Vector(-9900, -1064, 10760),
		max = Vector(-8900, -2779, 10370),
		shoud_draw = false
	},
	["gm_mobenix_winter"] = {
		min = Vector(-9900, -1064, 10760),
		max = Vector(-8900, -2779, 10370),
		shoud_draw = false
	},
	["gm_genesis"] = {
		min = Vector(2640, -10352, -8832),
		max = Vector(432, -7856, -8321),
		shoud_draw = true
	},
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
		return (ent:CPPIGetOwner() ~= nil and not ent:CreatedByMap() and not ent.NoDeleting and not ent:IsWeapon() and not allowed_classes[class]) or disallowed_classes[class] == true
	end

	hook.Add("Think", "check_spawnzone_ents", function()
		for _, ent in ipairs(ents.FindInBox(current_zone.min, current_zone.max)) do
			if isEntityDisallowedAtSpawn(ent) then
				print("Bad entity at spawn, removing:", ent)
				ent:Remove()
			end
		end
	end)

	hook.Add("PlayerSpawnObject", "block_spawn_in_spawnzone", function(ply, model, skin)
		if ply:GetPos():WithinAABox(current_zone.min, current_zone.max) then
			return false
		end
	end)

	hook.Add("EntityTakeDamage", "block_spawn_in_spawnzone", function(target, dmg)
		local attacker = dmg:GetAttacker()
		if attacker:IsPlayer() and attacker:GetPos():WithinAABox(current_zone.min, current_zone.max) then
			return true
		end
		if target:GetPos():WithinAABox(current_zone.min, current_zone.max) then
			return true
		end
	end)
else
	hook.Add("PreDrawTranslucentRenderables", "draw_spawnzone", function(bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)
		if current_zone.shoud_draw and fsb_draw_spawnzone:GetBool() and not isDraw3DSkybox then
			render.DrawWireframeBox(vector_origin, angle_zero, current_zone.min, current_zone.max, spawnzone_color, true)
		end
	end)
end