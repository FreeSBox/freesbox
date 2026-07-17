local CATEGORY_NAME = "FSB"

function ulx.cleardecals(calling_ply)
	for _, ply in ipairs(player.GetHumans()) do
		if IsValid(ply) then
			ply:ConCommand("r_cleardecals")
		end
	end

	ulx.fancyLogAdmin(calling_ply, "#A clean decals for everyone")
end

local cleardecals = ulx.command( CATEGORY_NAME, "ulx cleardecals", ulx.cleardecals, "!cleardecals" )
cleardecals:defaultAccess( ULib.ACCESS_ADMIN )
cleardecals:help( "Clean decals for everyone." )

function ulx.stopsound(calling_ply)
	for _, ply in ipairs(player.GetHumans()) do
		if IsValid(ply) then
			ply:ConCommand("stopsound")
		end
	end

	ulx.fancyLogAdmin(calling_ply, "#A stops all sounds for everyone")
end

local stopsoundCmd = ulx.command( CATEGORY_NAME, "ulx stopsound", ulx.stopsound, "!stopsound" )
stopsoundCmd:defaultAccess( ULib.ACCESS_ADMIN )
stopsoundCmd:help( "Run stopsound for everyone." )
