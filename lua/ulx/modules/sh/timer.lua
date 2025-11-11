
local function broadcastTimerULXWrapper(calling_ply, time, message)
	local curtime = CurTime()
	FSB.BroadcastTimer(curtime, curtime+time, message)

	ulx.fancyLogAdmin( calling_ply, "#A started a timer (#s)", message )
end
local function stopTimerULXWrapper(calling_ply)
	FSB.StopTimer()
	ulx.fancyLogAdmin( calling_ply, "#A stopped the timer" )
end

local timer = ulx.command("FSB", "ulx timer", broadcastTimerULXWrapper, "!timer")
timer:addParam{ type=ULib.cmds.NumArg, min=5, max=120, default=60, hint="seconds", ULib.cmds.round, ULib.cmds.optional }
timer:addParam{ type=ULib.cmds.StringArg, hint="Dota in %.1f seconds." }
timer:defaultAccess( ULib.ACCESS_ADMIN )
timer:help( "Starts a timer on all players screens." )

local stoptimer = ulx.command("FSB", "ulx stoptimer", stopTimerULXWrapper, "!stoptimer")
stoptimer:defaultAccess( ULib.ACCESS_ADMIN )
stoptimer:help( "Cancels the timer if started. It will also stop the cleanup timer, but will NOT prevent the cleanup!" )
