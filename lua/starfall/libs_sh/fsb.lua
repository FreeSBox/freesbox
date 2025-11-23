---@class Entity
local ENT_META = FindMetaTable("Entity")
---@class Player
local PLY_META = FindMetaTable("Player")

return function(instance)
local player_methods, player_meta = instance.Types.Player.Methods, instance.Types.Player
local Ply_InPVPMode, Ply_GetOriginalName, Ply_PVPModeEndTime, Ply_GetNameTag = PLY_META.InPVPMode, PLY_META.GetOriginalName, PLY_META.PVPModeEndTime, PLY_META.GetNameTag
local Ent_IsValid = ENT_META.IsValid

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

--- Gets the time when the player will leave PVP mode.
-- Do Player:getPVPModeEndTime()-timer.curtime() to get time until we switch to build mode.
-- This will return 0xFFAAAC if we won't switch to PVP yet.
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
end
