---@diagnostic disable: inject-field

local max_net_msgs_per_second = 100

timer.Create("reset_net_count", 1, 0, function()
	for _, ply in ipairs(player.GetHumans()) do
		ply.net_msgs_this_second = 0
		ply.net_msgs_drop = false
	end
end)


hook.Add("PlayerInitialSpawn", "init_net_msg_count", function(ply)
	ply.net_msgs_this_second = 0
	ply.net_msgs_drop = false
end)

net.Incoming = function(len, ply)
	local i = net.ReadHeader()
	local strName = util.NetworkIDToString( i )

	if ply.net_msgs_this_second == nil or ply.net_msgs_drop then return end
	if ply.net_msgs_this_second > max_net_msgs_per_second then
		print("[net] " .. ply:Name() .. " is sending more than " .. max_net_msgs_per_second .. " net messages a second; last net: " .. strName)
		ply.net_msgs_drop = true
		return
	end
	ply.net_msgs_this_second = ply.net_msgs_this_second+1

	if ( !strName ) then return end

	local func = net.Receivers[ strName:lower() ]
	if ( !func ) then return end

	--
	-- len includes the 16 bit int which told us the message name
	--
	len = len - 16

	func( len, ply )

end
