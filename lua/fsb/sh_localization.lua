local localization_data
if SERVER then
	localization_data = include("resources/localization.lua")
	AddCSLuaFile("resources/localization.lua")
else
	localization_data = include("resources/localization.lua")
end

local gmod_language = GetConVar("gmod_language")

local english_data = localization_data["en"]

---FreeSBox's internal translation function.
---@param label string
---@return string localized_string
function FSB.Translate(label)
	local lang = localization_data[gmod_language:GetString()]
	if lang then
		return lang[label] or label
	end

	return english_data[label] or label
end

if SERVER then
	util.AddNetworkString("SendLocalizedMessage")

	---@class Player
	local PLAYER = FindMetaTable("Player")

	---Sends a localized chat message to the player
	---@param string string Localized string.
	---@param ... any
	function PLAYER:SendLocalizedMessage(string, ...)
		local args = table.Pack(...)
		net.Start("SendLocalizedMessage")
			net.WriteString(string)
			net.WriteBool(args ~= nil)
			if args ~= nil then
				net.WriteTable(args)
			end
		net.Send(self)
	end

	---Sends a localized chat message to all players
	---@param string string Localized string.
	---@param ... any
	function FSB.SendLocalizedMessage(string, ...)
		local args = table.Pack(...)
		for _, ply in ipairs(player.GetHumans()) do
			net.Start("SendLocalizedMessage")
				net.WriteString(string)
				net.WriteBool(args ~= nil)
				if args ~= nil then
					net.WriteTable(args)
				end
			net.Send(ply)
		end
	end
else
	net.Receive("SendLocalizedMessage", function (len, ply)
		local string = net.ReadString()
		local args
		local has_args = net.ReadBool()
		if has_args then
			args = net.ReadTable()
		end

		if has_args then
			chat.AddText(string.format(FSB.Translate(string), unpack(args)))
		else
			chat.AddText(string.format(FSB.Translate(string)))
		end
	end)
end
