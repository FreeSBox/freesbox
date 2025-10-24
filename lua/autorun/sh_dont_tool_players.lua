
hook.Add("CanTool", "dont_tool_players", function (ply, tr, toolname, tool, button)
	if tr.Entity and tr.Entity:IsPlayer() then
		return false
	end
end)