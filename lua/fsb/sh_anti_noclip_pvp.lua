local time_until_pvp_ends = 100 -- seconds until we can use noclip again

local function isInNoclip(player)
	return player:GetMoveType() == MOVETYPE_NOCLIP and not player:InVehicle()
end

if SERVER then
	hook.Add("EntityTakeDamage", "set_pvp_mode", function (target, dmg)
		local attacker = dmg:GetAttacker()
		if not attacker:IsPlayer() or (not target:IsPlayer() and target:CPPIGetOwner() == attacker) or attacker == target then return end

		attacker:SetNWFloat("PVPModeEnd", CurTime()+time_until_pvp_ends)
		if isInNoclip(attacker) then
			attacker:SetMoveType(MOVETYPE_WALK)
		end
	end)
end

local lastmsg = 0
hook.Add("PlayerNoClip", "prevent_noclip_in_pvp", function (ply, enable_noclip)
	if not SERVER and ply ~= LocalPlayer() then return end

	local pvp_mode_end_time = ply:GetNWFloat("PVPModeEnd")
	local curtime = CurTime()
	if enable_noclip and pvp_mode_end_time > curtime then
		if CLIENT and not math.IsNearlyEqual(lastmsg, curtime, 1) then
			chat.AddText(string.format(FSB.Translate("no_noclip_in_pvp"), pvp_mode_end_time-curtime))
			lastmsg = curtime
		end
		return false
	end
end)
