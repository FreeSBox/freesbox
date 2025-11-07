
local function ghostBanULXWrapper(calling_ply, target_ply, minutes)
	if target_ply:IsListenServerHost() or target_ply:IsBot() then
		ULib.tsayError(calling_ply, "This player is immune to banning", true)
		return
	end

	ulx.fancyLogAdmin(calling_ply, "#A ghostbanned #T for #s", target_ply, ULib.secondsToStringTime( minutes * 60 ))

	FSB.GhostBan(target_ply, os.time()+minutes*60)
end
local function ghostUnBanULXWrapper(calling_ply, target_ply)
	ulx.fancyLogAdmin(calling_ply, "#A unghostbanned #T", target_ply)
	FSB.GhostUnBan(target_ply)
end

local function ghostUnBanIDULXWrapper(calling_ply, steamid)
	steamid = steamid:upper()
	if not ULib.isValidSteamID( steamid ) then
		ULib.tsayError( calling_ply, "Invalid steamid." )
		return
	end

	ulx.fancyLogAdmin(calling_ply, "#A unghostbanned steamid #s", steamid)

	util.RemovePData(steamid, "ghost_unban_time")
end

local ghostban = ulx.command("FSB", "ulx ghostban", ghostBanULXWrapper, "!ghostban")
ghostban:addParam{ type=ULib.cmds.PlayerArg }
ghostban:addParam{ type=ULib.cmds.NumArg, hint="minutes", ULib.cmds.optional, ULib.cmds.allowTimeString, min=1 }
ghostban:defaultAccess( ULib.ACCESS_ADMIN )
ghostban:help( "Ghost bans target (Can still walk around, but can't do almost anything)." )

local ghostunban = ulx.command("FSB", "ulx unghostban", ghostUnBanULXWrapper, "!unghostban")
ghostunban:addParam{ type=ULib.cmds.PlayerArg }
ghostunban:defaultAccess( ULib.ACCESS_ADMIN )
ghostunban:help( "Removes the ghost ban effect from player." )

local ghostunbanid = ulx.command("FSB", "ulx unghostbanid", ghostUnBanIDULXWrapper, "!unghostbanid")
ghostunbanid:addParam{ type=ULib.cmds.StringArg, hint="steamid" }
ghostunbanid:defaultAccess( ULib.ACCESS_ADMIN )
ghostunbanid:help( "Removes the ghost ban effect from player. Uses steamid in the STEAM_0:0:0 format." )

