local function setGroupBySteamIDULXWrapper(calling_ply, steamid, usergroup)
	steamid = steamid:upper()
	if not ULib.isValidSteamID(steamid) then
		ULib.tsayError(calling_ply, "Invalid steamid.")
		return
	end

	ulx.fancyLogAdmin(calling_ply, "#A gave steamid #s group #s", steamid,usergroup)

	FSB.SetGroupBySteamID(steamid,usergroup)
end
local fsbadduser = ulx.command("FSB", "ulx fsbadduser", setGroupBySteamIDULXWrapper, "!fsbadduser")
fsbadduser:addParam{ type=ULib.cmds.StringArg, hint="steamid" }
fsbadduser:addParam{ type=ULib.cmds.StringArg, hint="usergroup"}
fsbadduser:defaultAccess( ULib.ACCESS_SUPERADMIN )
fsbadduser:help( "Gives a SteamID this usergroup via FSB's own system. Uses steamid in the STEAM_0:0:0 format. Use this over ulx adduser.")
