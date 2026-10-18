
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
local function voteGhostBanDone2( t,target_ply, nick, steamid, time, ply, reason ) -- ULX fucking sucks.
	local shouldBan = false

	if t.results[ 1 ] and t.results[ 1 ] > 0 then
		ulx.fancyLogAdmin( ply, "#A approved the voteban against #s (#s minutes) (#s))", nick, time, reason or "dota2" )
		shouldBan = true
	else
		ulx.fancyLogAdmin( ply, "#A denied the voteban against #s", nick )
	end

	if IsValid(target_ply) and shouldBan then
		FSB.GhostBan(target_ply, os.time()+time*60, reason, ply)
	else
		FSB.GhostBan(steamid,os.time()+time*60,reason,ply)
	end
end
local function voteGhostBanDone( t, target_ply, nick, steamid, time, ply, reason )
	local results = t.results
	local winner
	local winnernum = 0
	for id, numvotes in pairs( results ) do
		if numvotes > winnernum then
			winner = id
			winnernum = numvotes
		end
	end

	local ratioNeeded = GetConVarNumber( "ulx_votebanSuccessratio" )
	local minVotes = GetConVarNumber( "ulx_votebanMinvotes" )
	local str
	if winner ~= 1 or winnernum < minVotes or winnernum / t.voters < ratioNeeded then
		str = "Vote results: User will not be ghostbanned. (" .. (results[ 1 ] or "0") .. "/" .. t.voters .. ")"
	else
		reason = ("[voteghostban] " .. (reason or "unspecified")):Trim()
		if ply:IsValid() then
			str = "Vote results: User will now be ghostbanned, pending approval. (" .. winnernum .. "/" .. t.voters .. ")"
			ulx.doVote( "Accept result and ghostban " .. nick .. "?", { "Yes", "No" }, voteGhostBanDone2, 30000, { ply }, true, target_ply, nick, steamid, time, ply, reason )
		else -- Vote from server console, roll with it
			str = "Vote results: User will now be ghostbanned. (" .. winnernum .. "/" .. t.voters .. ")"
			if IsValid(target_ply) then
				FSB.GhostBan(target_ply, os.time()+time*60, reason, ply)
			else
				FSB.GhostBan(steamid,os.time()+time*60,reason,ply)
			end
		end
	end

	ULib.tsay( _, str )
	ulx.logString( str )
	Msg( str .. "\n" )
end

function ulx.voteghostban( calling_ply, target_ply, minutes, reason )
	if target_ply:IsListenServerHost() or target_ply:IsBot() then
		ULib.tsayError( calling_ply, "This player is immune to banning", true )
		return
	end
	if ulx.voteInProgress then
		ULib.tsayError( calling_ply, "There is already a vote in progress. Please wait for the current one to end.", true )
		return
	end

	local msg = "Ghostban " .. target_ply:Nick() .. " for " .. minutes .. " minutes?"
	if reason and reason ~= "" then
		msg = msg .. " (" .. reason .. ")"
	end

	ulx.doVote( msg, { "Yes", "No" }, voteGhostBanDone, _, _, _, target_ply,target_ply:Nick(), target_ply:SteamID(), minutes, calling_ply, reason )
	if reason and reason ~= "" then
		ulx.fancyLogAdmin( calling_ply, "#A started a voteghostban of #i minute(s) against #T (#s)", minutes, target_ply, reason )
	else
		ulx.fancyLogAdmin( calling_ply, "#A started a voteghostban of #i minute(s) against #T", minutes, target_ply )
	end
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


local voteghostban = ulx.command("FSB","ulx voteghostban",ulx.voteghostban,"!voteghostban")
voteghostban:addParam{ type=ULib.cmds.PlayerArg }
voteghostban:addParam{ type=ULib.cmds.NumArg, min=0, default=1440, hint="minutes", ULib.cmds.allowTimeString, ULib.cmds.optional }
voteghostban:addParam{ type=ULib.cmds.StringArg, hint="reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_kick_reasons }
voteghostban:defaultAccess( ULib.ACCESS_ADMIN )
voteghostban:help( "Starts a public ghostban vote against target." )
