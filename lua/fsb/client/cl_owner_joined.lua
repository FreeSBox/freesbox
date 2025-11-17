
hook.Add("FSBPlayerJoined", "owner_join_notify", function (userid, networkid, name)
	-- It would be really nice to check `IsFullyAuthenticated()`, but we can't yet.
	if networkid == "STEAM_0:1:95820409" then

		chat.AddText(Color(255, 50, 0), FSB.Translate("owner_joined"))

		FSB.DownloadFile("owner_joined_1.mp3", function (path)
			sound.PlayFile("data/" .. path, "mono noblock", function (channel, errorID, errorName)
				if ( IsValid( channel ) ) then
					channel:SetPos(LocalPlayer():GetPos())
					channel:Play()
				else
					print( "Error playing sound!", errorID, errorName )
				end
			end)
		end)
	end
end)
