
local ratelimit = 5
local ratelimit_table = {}

concommand.Add("findlag", function (ply, cmd, args, arg_str)
	if not FSB.Ratelimit(ratelimit_table, ply, 5) then
		ply:SendLocalizedMessage("ratelimit", ratelimit)
		return
	end

	local lag_scores = {}

	for _, entity in ipairs(ents.GetAll()) do
		local ent_score = 0
		local owner = entity:CPPIGetOwner()
		if not IsValid( owner ) then
			continue
		end

		local frozen = true
		for i = 0, entity:GetPhysicsObjectCount()-1 do
			local phys_obj = entity:GetPhysicsObjectNum(i)

			if phys_obj:IsMotionEnabled() then
				frozen = false
				ent_score = ent_score + 0.5

				if phys_obj:IsPenetrating() then
					ent_score = ent_score + 16
				end
			end
		end

		-- The entity.Constraints table is undocumented magic.
		if not frozen and entity.Constraints then
			ent_score = ent_score + #entity.Constraints * 0.5
		end

		if entity:GetClass() == "gmod_wire_gate" then
			ent_score = ent_score + 1
		end

		if entity:GetClass() == "gmod_wire_expression2" then
			local data = entity:GetOverlayData()
			if not data then continue end

			ent_score = ent_score + data.prfbench/150
		end

		if entity:GetClass() == "starfall_processor" then
			ent_score = ent_score + entity:GetNWFloat("CPUpercent", 0)
		end

		lag_scores[owner] = lag_scores[owner] and lag_scores[owner] + ent_score or ent_score
	end

	ply:SendLocalizedMessage("findlag.note")
	for index, value in pairs(lag_scores) do
		ply:PrintMessage(HUD_PRINTTALK, string.format("%s: %i", index:Nick(), math.floor(value)))
	end
end)
