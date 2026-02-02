
local function cleanupplayerULXWrapper(calling_ply, target_ply)
	NADMOD.CleanPlayer(calling_ply, target_ply)

	ulx.fancyLogAdmin(calling_ply, "#A cleaned up #T's props", target_ply)
end
local function cleanupdisconnectedULXWrapper(calling_ply)
	-- This is pasted from the NADMOD source because they don't provide a function for it that doen't check admin access.
	local count = 0
	for k,v in pairs(NADMOD.Props) do
		if not v.Ent:IsValid() then
			NADMOD.EntityRemoved(v.Ent)
		elseif not IsValid(v.Owner) and (v.Name ~= "O" and v.Name ~= "W") and not v.Ent:GetPersistent() then
			v.Ent:Remove()
			count = count + 1
		end
	end
	NADMOD.Notify("Disconnected players props ("..count..") have been cleaned up")

	ulx.fancyLogAdmin(calling_ply, "#A cleaned up disconnected props")
end

local function cleanupULXWrapper(calling_ply, time)
	FSB.CleanUpMap(time)

	ulx.fancyLogAdmin(calling_ply, "#A started a map cleanup")
end
local function cancelCleanupULXWrapper(calling_ply)
	FSB.CancelCleanUp()

	ulx.fancyLogAdmin(calling_ply, "#A stopped the cleanup")
end

local function freezeAllULXWrapper(calling_ply)
	FSB.FreezeAllProps()

	ulx.fancyLogAdmin(calling_ply, "#A froze all props")
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

	ulx.fancyLogAdmin(calling_ply, "#A froze #T's props", target_ply)
end

local cleanupplayer = ulx.command("FSB", "ulx cleanplayer", cleanupplayerULXWrapper, "!cleanplayer")
cleanupplayer:addParam{ type=ULib.cmds.PlayerArg }
cleanupplayer:defaultAccess( ULib.ACCESS_ADMIN )
cleanupplayer:help( "Cleans up players props." )

local cleanupdisconnected = ulx.command("FSB", "ulx cdp", cleanupdisconnectedULXWrapper, "!cdp")
cleanupdisconnected:defaultAccess( ULib.ACCESS_ADMIN )
cleanupdisconnected:help( "Cleans up props from disconnected players." )

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
