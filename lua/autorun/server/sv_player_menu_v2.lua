hook.Add("ShowTeam", "player_menu_trigger", function(ply)
	ply:ConCommand("menu")
end)

hook.Add("PlayerInitialSpawn", "advertise_f2_menu", function(player, transition)
	player:PrintMessage(HUD_PRINTTALK, "Press F2 to access the server menu")
end)
