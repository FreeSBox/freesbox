local cl_disable_render_on_focus_loss = CreateClientConVar("cl_disable_render_on_focus_loss", "0", true, false, "Prevents game rendering when it isn't focused")
hook.Add("PreRender", "disable_render", function()
	if cl_disable_render_on_focus_loss:GetBool() and not system.HasFocus() then
		return true
	end
end)

local auto_jump = CreateClientConVar("auto_jump", "0", true, false, "Auto jump")
hook.Add("CreateMove", "autojump", function(cmd)
	if auto_jump:GetBool() then
		if bit.band(cmd:GetButtons(), IN_JUMP) ~= 0 then
			if not LocalPlayer():IsOnGround() and LocalPlayer():GetMoveType() ~= MOVETYPE_NOCLIP and LocalPlayer():WaterLevel() <= 1 then
				cmd:SetButtons(bit.band(cmd:GetButtons(), bit.bnot(IN_JUMP)))
			end
		end
	end
end)
