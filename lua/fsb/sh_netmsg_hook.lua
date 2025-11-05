-- Overrides net.Incoming so we can hook it later.

---RealTime of the last netmsg
FSB.LAST_NETMSG_TIME = RealTime()

net.Incoming = function(len, ply)
	local i = net.ReadHeader()
	local strName = util.NetworkIDToString( i )


	FSB.LAST_NETMSG_TIME = RealTime()

	if hook.Run("NetIncoming", i, strName, len, ply) ~= nil then return end

	if ( !strName ) then return end

	local func = net.Receivers[ strName:lower() ]
	if ( !func ) then return end

	--
	-- len includes the 16 bit int which told us the message name
	--
	len = len - 16

	func( len, ply )

end

