
local function cleanupULXWrapper(calling_ply, time)
	FSB.CleanUpMap(time)

	ulx.fancyLogAdmin( calling_ply, "#A started a map cleanup" )
end
local function cancelCleanupULXWrapper(calling_ply)
	FSB.CancelCleanUp()

	ulx.fancyLogAdmin( calling_ply, "#A stopped the cleanup" )
end

local cleanup = ulx.command("FSB", "ulx cleanup", cleanupULXWrapper, "!cleanup")
cleanup:addParam{ type=ULib.cmds.NumArg, min=10, max=120, default=60, hint="seconds to wait before cleaning up", ULib.cmds.round, ULib.cmds.optional }
cleanup:defaultAccess( ULib.ACCESS_ADMIN )
cleanup:help( "Cleans up the map with a visual timer." )

local stopcleanup = ulx.command("FSB", "ulx stopcleanup", cancelCleanupULXWrapper, "!stopcleanup")
stopcleanup:defaultAccess( ULib.ACCESS_ADMIN )
stopcleanup:help( "Cancels the cleanup if started." )

