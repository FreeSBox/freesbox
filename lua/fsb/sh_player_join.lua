
local TAG = "fsb_player_joined_or_left"

if SERVER then
	util.AddNetworkString(TAG)

	local function sendMessage(data, is_joining)
		net.Start(TAG)
		net.WriteBool(is_joining)
		net.WriteUInt(data.userid, 32)
		net.WriteString(data.networkid)
		net.WriteString(data.name)
		if not is_joining then
			net.WriteString(data.reason)
		end
		net.Broadcast()
	end

	gameevent.Listen("player_connect")
	hook.Add("player_connect", TAG, function(data)
		sendMessage(data, true)
	end)

	gameevent.Listen( "player_disconnect" )
	hook.Add( "player_disconnect", TAG, function( data )
		sendMessage(data, false)
	end)
else
	net.Receive(TAG, function (len, ply)
		local is_joining = net.ReadBool()
		local userid = net.ReadUInt(32)
		local networkid = net.ReadString()
		local name = net.ReadString()
		local reason
		if not is_joining then
			reason = net.ReadString()
			hook.Run("FSBPlayerLeft", userid, networkid, name, reason)
		else
			hook.Run("FSBPlayerJoined", userid, networkid, name)
		end

	end)
end
