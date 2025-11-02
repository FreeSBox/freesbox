-- Source:
-- https://wiki.facepunch.com/gmod/Player:DropWeapon#example
concommand.Add( "+drop", function( ply )
	if ( ply:IsValid() ) then
		ply:DropWeapon()
	end
end )
