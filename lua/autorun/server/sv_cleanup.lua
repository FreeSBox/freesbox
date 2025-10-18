-- Manages automatic server cleanup.
-- Not all cleanup is done through here, cleanup will also occur in sv_lagdetect.

-- Wiremod claims that PlayerDisconnected doesn't always run.
hook.Add("EntityRemoved", "empty_server_map_cleanup", function(ent, fullUpdate)
	if ent:IsPlayer() and player.GetCount() == 0 then
		-- Cannot run game.CleanUpMap while deleting entities!
		hook.Add("Tick", "run_map_cleanup", function ()
			hook.Remove("Tick", "run_map_cleanup")
			game.CleanUpMap()
			print("Server is empty, cleaning up the map")
		end)
	end
end)

