
local function cleanupULXWrapper(calling_ply, time)
	FSB.CleanUpMap(time)

	ulx.fancyLogAdmin( calling_ply, "#A started a map cleanup" )
end
local function cancelCleanupULXWrapper(calling_ply)
	FSB.CancelCleanUp()

	ulx.fancyLogAdmin( calling_ply, "#A stopped the cleanup" )
end

local function freezeAllULXWrapper(calling_ply)
	FSB.FreezeAllProps()

	ulx.fancyLogAdmin( calling_ply, "#A froze all props" )
end

local function freezePlayerProps(calling_ply, target_ply)
	for _, ent in ipairs(ents.GetAll()) do
		if IsValid(ent) and ent:CPPIGetOwner() == target_ply then
			local phys_object = ent:GetPhysicsObject()
			if IsValid(phys_object) then
				phys_object:EnableMotion(false)
			end
		end
	end

	ulx.fancyLogAdmin( calling_ply, "#A froze #T's props", target_ply )
end

local cleanup = ulx.command("FSB", "ulx cleanup", cleanupULXWrapper, "!cleanup")
cleanup:addParam{ type=ULib.cmds.NumArg, min=10, max=120, default=60, hint="seconds to wait before cleaning up", ULib.cmds.round, ULib.cmds.optional }
cleanup:defaultAccess( ULib.ACCESS_ADMIN )
cleanup:help( "Cleans up the map with a visual timer." )

local stopcleanup = ulx.command("FSB", "ulx stopcleanup", cancelCleanupULXWrapper, "!stopcleanup")
stopcleanup:defaultAccess( ULib.ACCESS_ADMIN )
stopcleanup:help( "Cancels the cleanup if started." )

local freezeall = ulx.command("FSB", "ulx freezeall", freezeAllULXWrapper, "!freezeall")
freezeall:defaultAccess( ULib.ACCESS_ADMIN )
freezeall:help( "Freezes all player props." )

local freezeprops = ulx.command("FSB", "ulx freezeprops", freezePlayerProps, "!freezeprops")
freezeprops:addParam{ type=ULib.cmds.PlayerArg }
freezeprops:defaultAccess( ULib.ACCESS_ADMIN )
freezeprops:help( "Freezes props owned by a player." )

