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

hook.Add("NetIncoming", "net_ratelimit", function(index, strName, len, ply)
	if ply.net_msgs_this_second == nil or ply.net_msgs_drop then return false end
	if ply.net_msgs_this_second > max_net_msgs_per_second then
		print("[net] " .. ply:Name() .. " is sending more than " .. max_net_msgs_per_second .. " net messages a second; last net: " .. strName)
		ply.net_msgs_drop = true
		return true
	end
	ply.net_msgs_this_second = ply.net_msgs_this_second+1
end)
