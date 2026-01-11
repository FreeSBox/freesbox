
local function ghostBanULXWrapper(calling_ply, target_ply, minutes, reason)
	if target_ply:IsListenServerHost() or target_ply:IsBot() then
		ULib.tsayError(calling_ply, "This player is immune to banning", true)
		return
	end

	local str = "#A ghostbanned #T for #s"
	if reason and reason ~= "" then str = str .. " (#s)" end
	ulx.fancyLogAdmin(calling_ply, str, target_ply, minutes ~= 0 and ULib.secondsToStringTime(minutes*60) or reason, reason)

	FSB.GhostBan(target_ply, os.time()+minutes*60, reason, calling_ply)
end

local function ghostUnBanULXWrapper(calling_ply, target_ply)
	ulx.fancyLogAdmin(calling_ply, "#A unghostbanned #T", target_ply)
	FSB.GhostUnBan(target_ply)
end

local function ghostBanIDULXWrapper(calling_ply, steamid, minutes, reason)
	steamid = steamid:upper()
	if not ULib.isValidSteamID(steamid) then
		ULib.tsayError(calling_ply, "Invalid steamid.")
		return
	end

	local target_ply = player.GetBySteamID(steamid)
	if IsValid(target_ply) then
		ghostBanULXWrapper(calling_ply, target_ply, minutes, reason)
		return
	end

	local str = "#A ghostbanned steamid #s for #s"
	if reason and reason ~= "" then str = str .. " (#s)" end
	ulx.fancyLogAdmin(calling_ply, str, steamid, minutes ~= 0 and ULib.secondsToStringTime(minutes*60) or reason, reason)

	FSB.GhostBan(steamid, os.time()+minutes*60, reason, calling_ply)
end

local function ghostUnBanIDULXWrapper(calling_ply, steamid)
	steamid = steamid:upper()
	if not ULib.isValidSteamID(steamid) then
		ULib.tsayError(calling_ply, "Invalid steamid.")
		return
	end

	ulx.fancyLogAdmin(calling_ply, "#A unghostbanned steamid #s", steamid)

	FSB.GhostUnBan(steamid)
end

local ghostban = ulx.command("FSB", "ulx ghostban", ghostBanULXWrapper, "!ghostban")
ghostban:addParam{ type=ULib.cmds.PlayerArg }
ghostban:addParam{ type=ULib.cmds.NumArg, hint="minutes", ULib.cmds.optional, ULib.cmds.allowTimeString, min=1 }
ghostban:addParam{ type=ULib.cmds.StringArg, hint="reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_kick_reasons }
ghostban:defaultAccess( ULib.ACCESS_ADMIN )
ghostban:help( "Ghost bans target (Can still walk around, but can't do almost anything)." )

local ghostbanid = ulx.command("FSB", "ulx ghostbanid", ghostBanIDULXWrapper, "!ghostbanid")
ghostbanid:addParam{ type=ULib.cmds.StringArg, hint="steamid" }
ghostbanid:addParam{ type=ULib.cmds.NumArg, hint="minutes", ULib.cmds.optional, ULib.cmds.allowTimeString, min=1 }
ghostbanid:addParam{ type=ULib.cmds.StringArg, hint="reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_kick_reasons }
ghostbanid:defaultAccess( ULib.ACCESS_ADMIN )
ghostbanid:help( "Ghost bans target (Can still walk around, but can't do almost anything). Uses steamid in the STEAM_0:0:0 format." )


local ghostunban = ulx.command("FSB", "ulx unghostban", ghostUnBanULXWrapper, "!unghostban")
ghostunban:addParam{ type=ULib.cmds.PlayerArg }
ghostunban:defaultAccess( ULib.ACCESS_ADMIN )
ghostunban:help( "Removes the ghost ban effect from player." )

local ghostunbanid = ulx.command("FSB", "ulx unghostbanid", ghostUnBanIDULXWrapper, "!unghostbanid")
ghostunbanid:addParam{ type=ULib.cmds.StringArg, hint="steamid" }
ghostunbanid:defaultAccess( ULib.ACCESS_ADMIN )
ghostunbanid:help( "Removes the ghost ban effect from player. Uses steamid in the STEAM_0:0:0 format." )


