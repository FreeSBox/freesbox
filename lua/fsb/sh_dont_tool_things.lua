hook.Add("CanTool", "dont_tool_players", function (ply, tr, toolname, tool, button)
	if tr.Entity and tr.Entity:IsPlayer() then
		return false
	end
end)
-- Petition #1702
local unprotectedClasses = {
    ["func_breakable"] = true,
	["func_physbox"] = true,
	["prop_physics"] = true,
	["prop_dynamic"] = true,
	["prop_static"] = true,
	["static_prop"] = true,
}
hook.Add("CanTool", "dont_tool_world", function (_, tr)
   if tr.Entity and tr.Entity ~= Entity(0) and tr.Entity:CPPIGetOwner() == game.GetWorld() and not unprotectedClasses[tr.Entity:GetClass()] then return false end 
end)
hook.Add("PhysgunPickup","dont_physgun_world",function(_,ent)
   if ent and ent:CPPIGetOwner() == game.GetWorld() and not unprotectedClasses[ent:GetClass()] then return false end
end)
