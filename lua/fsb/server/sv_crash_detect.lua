
-- Send a message to the client, so it knows that it's not timing out.
timer.Create("client_keepalive", 1, 0, function ()
	--[[
	We use a name from exploit messages here to avoid another net string.
	These messages shouldn't do anything when sent to the client.
	]]
	net.Start("aze46aez67z67z64dcv4bt")
	net.Broadcast()
end)
