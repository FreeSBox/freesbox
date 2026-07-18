local SPAWNZONE_COLOR = Color(0, 255, 0)

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
		max = Vector(432, -7856, -8340),
		shoud_draw = true
	},
	["gm_excess_construct_13"] = {
		min = Vector(1792, 3328, 0),
		max = Vector(1344, 2624, 208),
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

		if allowed_classes[class] then
			return false
		end
		if disallowed_classes[class] then
			return true
		end

		return ent:CPPIGetOwner() ~= nil and
			not ent:CreatedByMap() and
			not ent.NoDeleting and
			not ent:IsWeapon()
	end

	timer.Create("check_spawnzone_ents", 0.5, 0, function()
		for _, ent in ipairs(ents.FindInBox(current_zone.min, current_zone.max)) do
			if isEntityDisallowedAtSpawn(ent) then
				print("Bad entity at spawn, removing:", ent)
				ent:Remove()
			end
		end
	end)

	--HACK: For some reason this hook doesn't work until we reload the file.
	--I don't know why, but this is an attemt to make it work adding this hook on a loaded server.
	--Every other hook in this file works fine. What the fuck?
	hook.Add("PlayerInitialSpawn", "init_block_check", function (player, transition)
		hook.Remove("PlayerInitialSpawn", "init_block_check")
		hook.Add("PlayerSpawnObject", "block_spawn_in_spawnzone", function(ply, model, skin)
			if ply:GetPos():WithinAABox(current_zone.min, current_zone.max) then
				return false
			end
		end)
	end)

	hook.Add("EntityTakeDamage", "block_damage_in_spawnzone", function(target, dmg)
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
			render.DrawWireframeBox(vector_origin, angle_zero, current_zone.min, current_zone.max, SPAWNZONE_COLOR, true)
		end
	end)
end
