-- Just so we have chat bindings for build mode.

local function buildmodeULXWrapper(calling_ply)
	calling_ply:PutIntoBUILD()
end

local cleanupplayer = ulx.command("FSB", "ulx build", buildmodeULXWrapper, "!build")
cleanupplayer:defaultAccess( ULib.ACCESS_ALL )
cleanupplayer:help( "Removes your weapons and puts you into build mode." )
