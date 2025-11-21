local PVP_TIMER = 50 -- seconds until we can use noclip again

local BUILD_WEAPONS =
{
	["gmod_tool"] = true,
	["gmod_camera"] = true,
	["weapon_medkit"] = true,
	["weapon_armorkit"] = true,
	["weapon_physgun"] = true,
	["weapon_physcannon"] = true,
	["weapon_hands"] = true,
	["weapon_lookathands"] = true,
	["none"] = true,
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

	self:SetNWFloat(PVP_NET_FLOAT, IN_PVP_MAGIC_VALUE)
	if isInNoclip(self) then
		self:SetMoveType(MOVETYPE_WALK)
	end

	self:SendLocalizedMessage("pvp.entered_pvp")
end

---This will set the PVP timer to 50 seconds in the future.
function PLAYER:MarkAsReadyForBuild()
	if self:GetNWFloat(PVP_NET_FLOAT) ~= IN_PVP_MAGIC_VALUE then
		return
	end

	self:SetNWFloat(PVP_NET_FLOAT, CurTime()+PVP_TIMER)
end

if SERVER then
	---@param target Player
	hook.Add("EntityTakeDamage", "block_damage_to_build", function (target, dmg)
		if not target:IsPlayer() then return end

		local attacker = dmg:GetAttacker()
		if not attacker:IsPlayer() then
			attacker = attacker:CPPIGetOwner()
		end
		if attacker == target then return end
		if dmg:IsFallDamage() then return end

		if not target:InPVPMode() then
			return true
		end
	end)

	hook.Add("EntityTakeDamage", "block_damage_to_pvp", function (target, dmg)
		local attacker = dmg:GetAttacker()
		if not attacker:IsPlayer() then
			attacker = attacker:CPPIGetOwner()
		end
		if attacker == target then return end
		if not attacker:InPVPMode() then
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

	---@param owner Player
	hook.Add("PlayerDroppedWeapon", "deactivate_pvp", function (owner, dropped_weapon)
		if not owner:IsPlayer() then return end

		local dropped_class = dropped_weapon:GetClass()

		for _, weapon in ipairs(owner:GetWeapons()) do
			local class = weapon:GetClass()
			if not BUILD_WEAPONS[class] and class ~= dropped_class then
				return
			end
		end

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
		if CLIENT and not math.IsNearlyEqual(lastmsg, curtime, 1) then
			local end_time = ply:PVPModeEndTime()
			if end_time == IN_PVP_MAGIC_VALUE then
				chat.AddText(T"pvp.no_noclip")
			else
				chat.AddText(string.format(T"pvp.no_noclip_time", ply:PVPModeEndTime()-curtime))
			end
			lastmsg = curtime
		end
		return false
	end
end)
