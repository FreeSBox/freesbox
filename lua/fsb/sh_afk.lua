local ACTIVITY_TIMEOUT = 120 -- If the player doesn't press any key for this number of seconds - consider them AFK

if SERVER then
	util.AddNetworkString("set_has_focus")
	net.Receive("set_has_focus", function (len, ply)
		local focus_loss_time
		if net.ReadBool() then
			focus_loss_time = 0
		else
			focus_loss_time = CurTime()
		end
		ply:SetNWFloat("focus_loss_time", focus_loss_time)
	end)

	hook.Add("PlayerButtonDown", "check_player_activity", function (ply, button)
		if not ply:IsActive() then
			if button == KEY_LWIN then return end
			if button == KEY_RWIN then return end
			if button == KEY_LALT then return end
		end
		ply:SetNWFloat("last_activity_time", CurTime())
	end)
else
	local function sendHasFocus(focused)
		net.Start("set_has_focus")
		net.WriteBool(focused)
		net.SendToServer()
	end

	local last_focus = true
	timer.Create("update_focus", 0.5, 0, function ()
		local current_focus = system.HasFocus()
		if last_focus ~= current_focus then
			last_focus = current_focus
			sendHasFocus(current_focus)
		end
	end)
end

---@class Player
local PLAYER = FindMetaTable("Player")

--Basically a networked version of `system.HasFocus()`
function PLAYER:HasFocus()
	return self:GetNWFloat("focus_loss_time") == 0
end

---@return number focus_loss_time CurTime based timestamp of when the focus was lost. 0 if we have focus
function PLAYER:GetFocusLossTime()
	return self:GetNWFloat("focus_loss_time")
end

---@return boolean True if the player is not AFK
function PLAYER:IsActive()
	return self:HasFocus() and CurTime()-self:GetNWFloat("last_activity_time") < ACTIVITY_TIMEOUT
end

---@return number CurTime based timestamp of the last activity from the player. 0 if we are active right now.
function PLAYER:GetLastActiveTime()
	if self:IsActive() then
		return 0
	end
	local focus_time = self:GetNWFloat("focus_loss_time")
	focus_time = focus_time == 0 and CurTime() or focus_time
	return math.min(focus_time, self:GetNWFloat("last_activity_time"))
end
