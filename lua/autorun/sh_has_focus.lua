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

function PLAYER:HasFocus()
	return self:GetNWFloat("focus_loss_time") == 0
end

function PLAYER:GetFocusLossTime()
	return self:GetNWFloat("focus_loss_time")
end
