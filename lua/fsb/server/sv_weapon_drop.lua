local DESPAWN_DELAY = 60

-- Source:
-- https://wiki.facepunch.com/gmod/Player:DropWeapon#example
concommand.Add( "+drop", function( ply )
	if ( ply:IsValid() ) then
		local weapon = ply:GetActiveWeapon()
		ply:DropWeapon(weapon)
		weapon.SpawnedOnGround = true

		timer.Simple(DESPAWN_DELAY, function ()
			if IsValid(weapon) and not IsValid(weapon:GetParent()) then
				weapon:Remove()
			end
		end)
	end
end )
