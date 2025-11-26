local PVP_TIMER = 20 -- seconds until we can use noclip again

local BUILD_WEAPONS =
{
	["gmod_tool"] = true,
	["gmod_camera"] = true,
	["weapon_medkit"] = true,
	["weapon_armorkit"] = true,
	["weapon_physgun"] = true,
	["weapon_physcannon"] = true,
	["laserpointer"] = true,
	["remotecontroller"] = true,
	["weapon_bugbait"] = true,
	["weapon_hands"] = true,
	["weapon_lookathands"] = true,
	["none"] = true,
}

local BUILD_VEHICLES =
{
	--Glide
	["gtav_airbus"] = true,
	["gtav_bati801"] = true,
	["gtav_blazer"] = true,
	["gtav_dinghyq"] = true,
	["gtav_dukes"] = true,
	["gtav_trailer_flat"] = true,
	["gtav_gauntlet_classic"] = true,
	["gtav_hauler"] = true,
	["gtav_infernus"] = true,
	["gtav_stunt"] = true,
	["gtav_police_cruiser"] = true,
	["gtav_sanchez"] = true,
	["gtav_seashark"] = true,
	["gtav_speedo"] = true,
	["gtav_wolfsbane"] = true,

	--GTAV Helicopters
	["glide_gtav_blimp"] = true,
	["glide_gtav_blimp2"] = true,
	["glide_gtav_buzzard"] = true,
	["glide_gtav_cargobob"] = true,
	["glide_gtav_frogger"] = true,
	["glide_gtav_havok"] = true,
	["glide_gtav_maverick"] = true,
	["glide_gtav_polmav2"] = true,
	["glide_gtav_polmav"] = true,
	["glide_gtav_skylift"] = true,
	["glide_gtav_skylift2"] = true,
	["glide_gtav_supervol"] = true,
	["glide_gtav_swift"] = true,
	["glide_gtav_swiftdeluxe"] = true,
	["glide_gtav_thruster"] = true,

	--Vanilla
	["prop_vehicle_prisoner_pod"] = true,
	["prop_vehicle_airboat"] = true,
	["prop_vehicle_jeep"] = true,

}

local IN_PVP_MAGIC_VALUE = 0xFFAAAC -- Don't push this value too far, it's transmited as a 32bit float.
local PVP_NET_FLOAT = "PVPModeEnd"

---@class Player
local PLAYER = FindMetaTable("Player")

---@return boolean
function PLAYER:InPVPMode()
	return self:GetNWFloat(PVP_NET_FLOAT) > CurTime()
end

---@return number
function PLAYER:PVPModeEndTime()
	return self:GetNWFloat(PVP_NET_FLOAT)
end

local function isInNoclip(player)
	return player:GetMoveType() == MOVETYPE_NOCLIP and not player:InVehicle()
end

---This will throw the player into the PVP mode, it will not deactivate until the player drops a PVP weapon,
---or abuses the backdoor(buildmode_button)
function PLAYER:PutIntoPVP()
	local old_value = self:GetNWFloat(PVP_NET_FLOAT)
	if old_value == IN_PVP_MAGIC_VALUE then return end

	if hook.Run("FSBEnterPVP", self) == false then return end

	self:SetNWFloat(PVP_NET_FLOAT, IN_PVP_MAGIC_VALUE)
	if isInNoclip(self) then
		self:SetMoveType(MOVETYPE_WALK)
	end

	self:SendLocalizedHint("pvp.entered_pvp", NOTIFY_GENERIC, 3)
end

---This will set the PVP timer to 50 seconds in the future.
function PLAYER:MarkAsReadyForBuild()
	if self:GetNWFloat(PVP_NET_FLOAT) ~= IN_PVP_MAGIC_VALUE then
		return
	end

	if hook.Run("FSBReadyForBuild", self) == false then return end

	self:SetNWFloat(PVP_NET_FLOAT, CurTime()+PVP_TIMER)
end


function PLAYER:HasPVPWeapons(excluded_class)
	for _, weapon in ipairs(self:GetWeapons()) do
		local class = weapon:GetClass()
		if not BUILD_WEAPONS[class] and class ~= excluded_class then
			return true
		end
	end

	return false
end

---@param veh Vehicle
---@return Vehicle vehicle Glide vehicle if this is a seat, otherwise the veh passed in.
function FSB.GetGlideVehicleFromSeat(veh)
	if veh:GetClass() == "prop_vehicle_prisoner_pod" and veh.GlideSeatIndex ~= nil then
		local parent = veh:GetParent()
		---@diagnostic disable-next-line: return-type-mismatch
		return IsValid(parent) and parent or veh
	end

	return veh
end

if SERVER then
	---@param target Player
	hook.Add("EntityTakeDamage", "block_damage_to_build", function (target, dmg)
		local is_player = target:IsPlayer()
		if not is_player then
			if target.IsGlideVehicle and not BUILD_VEHICLES[target:GetClass()] then
				return
			end
			target = target:CPPIGetOwner()
		end
		if not IsValid( target ) then return end
		if target:IsGhostBanned() then return end

		local attacker = dmg:GetAttacker()
		if attacker == target then return end
		if not attacker:IsPlayer() then
			attacker = attacker:CPPIGetOwner()
		end
		if attacker == target then return end
		if dmg:IsFallDamage() then return end

		if not target:InPVPMode() then
			return true
		end
	end)

	hook.Add("EntityTakeDamage", "block_damage_from_build", function (target, dmg)
		local attacker = dmg:GetAttacker()
		if not attacker:IsPlayer() then
			attacker = attacker:CPPIGetOwner()
		end
		if not target:IsPlayer() then
			target = target:CPPIGetOwner()
		end
		if not IsValid( attacker ) then return end
		if not IsValid( target ) then return end
		if attacker == target then return end
		if target:IsGhostBanned() then return end
		if attacker:IsPlayer() and not attacker:InPVPMode() then
			return true
		end
	end)

	-- Malicious compliance with #143
	hook.Add("PlayerButtonDown", "buildmode_button", function (ply, button)
		if button == KEY_XBUTTON_DOWN then
			ply:SetNWFloat(PVP_NET_FLOAT, CurTime())
		end
	end)

	hook.Add("WeaponEquip", "activate_pvp", function (weapon, owner)
		if BUILD_WEAPONS[weapon:GetClass()] then return end

		owner:PutIntoPVP()
	end)

	hook.Add("PlayerLeaveVehicle", "deactivate_glide_pvp", function (ply, veh)
		if ply:HasPVPWeapons() then return end

		ply:MarkAsReadyForBuild()
	end)

	hook.Add("PlayerEnteredVehicle", "activate_glide_pvp", function (ply, veh, role)
		if BUILD_VEHICLES[FSB.GetGlideVehicleFromSeat(veh):GetClass()] then return end

		ply:PutIntoPVP()
	end)

	---@param owner Player
	hook.Add("PlayerDroppedWeapon", "deactivate_pvp", function (owner, dropped_weapon)
		if not owner:IsPlayer() then return end

		local dropped_class = dropped_weapon:GetClass()
		if owner:HasPVPWeapons(dropped_class) then return end

		owner:MarkAsReadyForBuild()
	end)

	hook.Add("PlayerCanPickupWeapon", "block_build_pickups", function (ply, weapon)
		if ply:InPVPMode() then return end
		if not weapon.SpawnedOnGround then return end

		return false
	end)

	hook.Add("PlayerSpawnedSWEP", "mark_weapon_as_given", function (ply, weapon)
		weapon.SpawnedOnGround = true
	end)

	hook.Add("AllowPlayerPickup", "pickup_weapon_in_build", function (ply, ent)
		if ply:InPVPMode() then return end
		if not ent:IsWeapon() then return end

		return false
	end)

	hook.Add("PostPlayerDeath", "reset_pvp_on_death", function (ply)
		ply:MarkAsReadyForBuild()
	end)

	concommand.Add("build", function (ply, cmd, args, argStr)
		local player_weapons = ply:GetWeapons()
		for _, weapon in ipairs(player_weapons) do
			if not BUILD_WEAPONS[weapon:GetClass()] then
				weapon:Remove()
			end
		end

		ply:MarkAsReadyForBuild()
	end)
end

local lastmsg = 0
hook.Add("PlayerNoClip", "prevent_noclip_in_pvp", function (ply, enable_noclip)
	if not SERVER and ply ~= LocalPlayer() then return end
	local T = FSB.Translate
	local curtime = CurTime()

	if enable_noclip and ply:InPVPMode() then
		if CLIENT and not math.IsNearlyEqual(lastmsg, curtime, 4) then
			local end_time = ply:PVPModeEndTime()
			if end_time == IN_PVP_MAGIC_VALUE then
				FSB.Notify("pvp.no_noclip", NOTIFY_ERROR, 10)
			else
				FSB.Notify("pvp.no_noclip_time", NOTIFY_GENERIC, 5, ply:PVPModeEndTime()-curtime)
			end
			lastmsg = curtime
		end
		return false
	end
end)
