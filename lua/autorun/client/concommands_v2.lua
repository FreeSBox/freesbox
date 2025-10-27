local cl_disable_render_on_focus_loss = CreateClientConVar("cl_disable_render_on_focus_loss", "0", true, false, "Prevents game rendering when it isn't focused")
hook.Add("PreRender", "disable_render", function()
	if cl_disable_render_on_focus_loss:GetBool() and not system.HasFocus() then
		return true
	end
end)

local auto_jump = CreateClientConVar("auto_jump", "0", true, false, "Auto jump")
local last_move_was_jump = false
hook.Add("CreateMove", "autojump", function(cmd)
	if auto_jump:GetBool() then
		local lp = LocalPlayer()
		local button_bits = cmd:GetButtons()
		local is_jump = bit.band(button_bits, IN_JUMP) ~= 0
		if is_jump and lp:GetMoveType() ~= MOVETYPE_NOCLIP and lp:WaterLevel() <= 1 then
			if last_move_was_jump then
				cmd:SetButtons(bit.band(button_bits, bit.bnot(IN_JUMP)))
			end
			last_move_was_jump = not last_move_was_jump
		end
	end
end)
