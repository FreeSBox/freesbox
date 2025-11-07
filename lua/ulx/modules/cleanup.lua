
local function cleanupULXWrapper(calling_ply, time)
	FSB.CleanUpMap(time)
end
local function cancelCleanupULXWrapper(calling_ply)
	FSB.CancelCleanUp()
end

local cleanup = ulx.command("FreeSBox", "ulx cleanup", cleanupULXWrapper, "!cleanup")
cleanup:addParam{ type=ULib.cmds.NumArg, min=10, max=120, default=60, hint="seconds to wait before cleaning up", ULib.cmds.round, ULib.cmds.optional }
cleanup:defaultAccess( ULib.ACCESS_ADMIN )
cleanup:help( "Cleans up the map with a visual timer." )

local stopcleanup = ulx.command("FreeSBox", "ulx stopcleanup", cancelCleanupULXWrapper, "!stopcleanup")
stopcleanup:defaultAccess( ULib.ACCESS_ADMIN )
stopcleanup:help( "Cancels the cleanup if started." )

