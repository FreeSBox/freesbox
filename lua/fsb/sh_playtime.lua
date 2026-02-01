--[[
An implementation of https://github.com/TeamUlysses/utime
]]

---@class Player
local PLAYER = FindMetaTable("Player")

---Playtime that doesn't count the current session.
---@return integer playtime
function PLAYER:GetUTime()
	return self:GetNWInt("UTime")
end

---Playtime that doesn't count the current session.
---@param time integer
function PLAYER:SetUTime(time)
	self:SetNWInt("UTime", time)
end

---`CurTime` at the moment of `PlayerInitialSpawn`.
---@return number join_time
function PLAYER:GetUTimeStart()
	return self:GetNWFloat("UJoinTime")
end

---`CurTime` at the moment of `PlayerInitialSpawn`.
---@param join_time number
function PLAYER:SetUTimeStart(join_time)
	self:SetNWFloat("UJoinTime", join_time)
end

---Playtime this session.
---Similar to `Player:TimeConnected()`
---@return number
function PLAYER:GetUTimeSessionTime()
	return CurTime() - self:GetUTimeStart()
end

---Total playtime.
---@return number
function PLAYER:GetUTimeTotalTime()
	return self:GetUTime() + self:GetUTimeSessionTime()
end

if SERVER then
	---@param player Player
	local function savePlaytime(player)
		local new_time = player:GetUTimeTotalTime()
		local old_time = tonumber(player:GetPData("TotalPlayTime", 0))

		assert(new_time >= old_time, string.format("playtime decreased somehow. old_time = %f; UTime = %f; UTimeTotalTime = %f; UTimeSessionTime = %f; UTimeStart = %f;", old_time, player:GetUTime(), player:GetUTimeTotalTime(), player:GetUTimeSessionTime(), player:GetUTimeStart()))

		player:SetPData("TotalPlayTime", new_time)
	end

	-- We need to save the playtime outside of the disconnect hook in case the server crashes.
	timer.Create("save_playtime", 60, 0, function ()
		for _, value in ipairs(player.GetHumans()) do
			if value:IsConnected() then
				savePlaytime(value)
			end
		end
	end)

	hook.Add("PlayerInitialSpawn", "init_playtime", function (player, transition)
		player:SetUTimeStart(CurTime())
		local total_playtime = tonumber(player:GetPData("TotalPlayTime", 0))
		assert(total_playtime, "total_playtime is nil")
		player:SetUTime(total_playtime)
	end)

	hook.Add("PlayerDisconnected", "playtime_save_disconnect", savePlaytime)
end
