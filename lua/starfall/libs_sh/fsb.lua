---@class Entity
local ENT_META = FindMetaTable("Entity")
---@class Player
local PLY_META = FindMetaTable("Player")

local Ply_GetGhostBanDescription, Ply_GetGhostBannedBySteamID64, Ply_IsGhostBanned, Ply_InPVPMode, Ply_GetOriginalName, Ply_PVPModeEndTime, Ply_GetNameTag, Ply_GetUTimeTotalTime, Ply_GetUTimeSessionTime, Ply_GetUTime = PLY_META.GetGhostBanDescription, PLY_META.GetGhostBannedBySteamID64, PLY_META.IsGhostBanned, PLY_META.InPVPMode, PLY_META.GetOriginalName, PLY_META.PVPModeEndTime, PLY_META.GetNameTag, PLY_META.GetUTimeTotalTime, PLY_META.GetUTimeSessionTime, PLY_META.GetUTime
local Ent_IsValid = ENT_META.IsValid
local add = SF.hookAdd

--- Called when a player changes their name through FSB's custom name feature.
-- @name FSBPlayerChangeNameTag
-- @class hook
-- @server
-- @param Player ply Player that changed their name.
-- @param string old_name Old name.
-- @param string new_name New name.
-- @param boolean persistent Will this new name be saved after re-logging.
add("FSBPlayerChangeName")

--- Called when a player changes their tag.
-- @name FSBPlayerChangeNameTag
-- @class hook
-- @server
-- @param Player ply Player that changed their tag.
-- @param string old_tag Old tag.
-- @param string new_tag New tag.
-- @param boolean persistent Will this new tag be saved after re-logging.
add("FSBPlayerChangeNameTag")

return function(instance)
local player_methods, player_meta = instance.Types.Player.Methods, instance.Types.Player
-- Internal validity check just for SF. Returns ent if it's valid, errors the chip if it's not. Use this instead of just directly using self.
local function getply(self)
	local ent = player_meta.sf2sensitive[self]
	if Ent_IsValid(ent) then
		return ent
	else
		SF.Throw("Entity is not valid.", 3)
	end
end

--- Checks if the player is in build mode.
-- @shared
-- @return boolean
function player_methods:isBUILD()
	return not Ply_InPVPMode(getply(self))
end

--- Checks if the player is in pvp mode.
-- @shared
-- @return boolean
function player_methods:isPVP()
	return Ply_InPVPMode(getply(self))
end

--- Checks if the player is ghostbanned.
-- @shared
-- @return boolean
function player_methods:isGhostBanned()
	return Ply_IsGhostBanned(getply(self))
end

--- Returns the steamid64 of the admin that ghostbanned this player.
-- @shared
-- @return string
function player_methods:getGhostBannedBySteamID64()
	return Ply_GetGhostBannedBySteamID64(getply(self))
end

--- Returns the reason for the ghostban.
-- @shared
-- @return string
function player_methods:getGhostBanDescription()
	return Ply_GetGhostBanDescription(getply(self))
end

--- Gets the time when the player will leave PVP mode.
-- Do Player:getPVPModeEndTime()-timer.curtime() to get time until we switch to build mode.
-- This will return 0xFFAAAC if we won't switch to build yet.
-- @shared
-- @return number Time of PVP mode end.
function player_methods:getPVPModeEndTime()
	return Ply_PVPModeEndTime(getply(self))
end

--- Returns the original name of the player.
-- If the name is not modified the result will be the same as Player:getName().
-- @shared
-- @return string The unmodified name of the player.
function player_methods:getOriginalName()
	return Ply_GetOriginalName(getply(self))
end

--- Returns the nametag of the player.
-- Will be an empty string if the player doesn't have a nametag.
-- @shared
-- @return string The nametag of the player.
function player_methods:getNameTag()
	return Ply_GetNameTag(getply(self))
end
--- Returns the total amount of time the player has played on the server.
-- Convert this to hours with UNIT.GMOD_TIME.
-- @shared
-- @return number Total playtime.
function player_methods:getTotalPlaytime()
	return Ply_GetUTimeTotalTime(getply(self))
end
--- Returns the time played on the server this session. Similar to Player:getTimeConnnected().
-- @shared
-- @return number Session playtime.
function player_methods:getSessionPlaytime()
	return Ply_GetUTimeSessionTime(getply(self))
end
--- Returns playtime that doesn't count the current session.
-- @shared
-- @return number Before-session playtime.
function player_methods:getBeforeSessionPlaytime()
	return Ply_GetUTime(getply(self))
end
end
