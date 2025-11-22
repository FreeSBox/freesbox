if SERVER then
	util.AddNetworkString("SendLocalizedHint")

	---@class Player
	local PLAYER = FindMetaTable("Player")

	---@param text string Text in the notification, supports fsb localization.
	---@param type integer? Use NOTIFY_* enum
	---@param length integer? For how long should the notification be on the screen. Must be less then 511.
	function PLAYER:SendLocalizedHint(text, type, length)
		type = type or NOTIFY_GENERIC
		length = length or 5

		assert(isstring(text))
		assert(isnumber(type))
		assert(isnumber(length))

		net.Start("SendLocalizedHint")
			net.WriteString(text)
			net.WriteUInt(type, 3)
			net.WriteUInt(length, 9)
		net.Send(self)
	end
else
	local fsb_enable_notifications = CreateClientConVar("fsb_enable_notifications", "1", true, false, "Shoud the hints about the server be displayed.")

	---@param text string Text in the notification, supports fsb localization.
	---@param type integer? Use NOTIFY_* enum
	---@param length integer? For how long should the notification be on the screen.
	function FSB.Notify(text, type, length)
		if not fsb_enable_notifications:GetBool() then return end

		type = type or NOTIFY_GENERIC
		length = length or 5

		assert(isstring(text))
		assert(isnumber(type))
		assert(isnumber(length))

		notification.AddLegacy(FSB.Translate(text), type , length)
		surface.PlaySound("ambient/water/drip" .. math.random( 1, 4 ) .. ".wav")
	end

	net.Receive("SendLocalizedHint", function (len, ply)
		local text = net.ReadString()
		local type = net.ReadUInt(3)
		local length = net.ReadUInt(9)

		FSB.Notify(text, type, length)
	end)
end
