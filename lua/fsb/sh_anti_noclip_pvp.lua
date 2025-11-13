local time_until_pvp_ends = 50 -- seconds until we can use noclip again

---@class Player
local PLAYER = FindMetaTable("Player")

---@return boolean
function PLAYER:InPVPMode()
	return self:GetNWFloat("PVPModeEnd") > CurTime()
end

---@return number
function PLAYER:PVPModeEndTime()
	return self:GetNWFloat("PVPModeEnd")
end

local function isInNoclip(player)
	return player:GetMoveType() == MOVETYPE_NOCLIP and not player:InVehicle()
end

if SERVER then
	hook.Add("EntityTakeDamage", "set_pvp_mode", function (target, dmg)
		local attacker = dmg:GetAttacker()
		if not attacker:IsPlayer() then
			attacker = attacker:CPPIGetOwner()
		end
		if not IsValid(attacker) then return end
		if not attacker:IsPlayer() then return end
		if attacker == target then return end
		if target:IsPlayer() then
			if target:IsGhostBanned() then return end -- Feel free to kill ghost banned players.
		else
			if target:Health() == 0 then return end
			if target:CPPIGetOwner() == attacker then return end
		end

		attacker:SetNWFloat("PVPModeEnd", CurTime()+time_until_pvp_ends)
		if isInNoclip(attacker) then
			attacker:SetMoveType(MOVETYPE_WALK)
			return true
		end

		if target:IsPlayer() and not target:InPVPMode() then
			return true
		end
	end)
end

local lastmsg = 0
hook.Add("PlayerNoClip", "prevent_noclip_in_pvp", function (ply, enable_noclip)
	if not SERVER and ply ~= LocalPlayer() then return end
	local curtime = CurTime()

	if enable_noclip and ply:InPVPMode() then
		if CLIENT and not math.IsNearlyEqual(lastmsg, curtime, 1) then
			chat.AddText(string.format(FSB.Translate("no_noclip_in_pvp"), ply:PVPModeEndTime()-curtime))
			lastmsg = curtime
		end
		return false
	end
end)
