local DESPAWN_DELAY = 60

-- Source:
-- https://wiki.facepunch.com/gmod/Player:DropWeapon#example
concommand.Add("+drop", function(ply)
	if not IsValid(ply) then return end

	local weapon = ply:GetActiveWeapon()
	if not IsValid(weapon) then return end

	ply:DropWeapon(weapon)

	timer.Simple(DESPAWN_DELAY, function ()
		if IsValid(weapon) and not IsValid(weapon:GetParent()) then
			weapon:Remove()
		end
	end)
end)
