
if FSB.HTTP_SRV then
	FSB.HTTP_SRV:Stop()
end

FSB.HTTP_SRV = httpserver.Create()

local HTTP_SRV = FSB.HTTP_SRV


HTTP_SRV:Get("/generic.json", function (request)
	local info = {
		map = game.GetMap(),
		num_players = player.GetCount(),
		num_entities = ents.GetCount(),
		num_connecting = player.GetCountConnecting(),
		map_uptime = CurTime(),
		mspt = FSB.GetAverageMSPT(),
	}

	local players = {}
	for _, ply in player.Iterator() do
		players[#players+1] = {
			steamid = ply:SteamID64(),
			rich_name = ply:RichName(),
			name = ply:Name(),
			real_name = ply:GetOriginalName(),
			pvp = ply:InPVPMode(),
			pos = ply:GetPos(),
			ang = ply:EyeAngles(),
			vel = ply:GetVelocity(),
			time_connected = ply:TimeConnected(),
			time_total = ply:GetUTimeTotalTime(),
			afk_since = ply:GetLastActiveTime(),
			group = ply:GetUserGroup(),
			ping = ply:Ping(),
			model = ply:GetModel(),
			player_color = ply:GetPlayerColor(),
			weapon_color = ply:GetWeaponColor(),
		}
	end
	info.players = players

	request:SetContent(util.TableToJSON(info), "application/json")
end, false)

HTTP_SRV:Start("127.0.0.1", 8086)
MsgN("HTTP server started")
