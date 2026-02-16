
local RATELIMIT = 5
local ratelimit_table = {}

local function cmd_out(ply, msg)
	if IsValid(ply) then
		ply:PrintMessage(HUD_PRINTCONSOLE, msg)
	else
		MsgN(msg)
	end
end

concommand.Add("findlag", function (ply, cmd, args, arg_str)
	if not FSB.Ratelimit(ratelimit_table, ply, RATELIMIT) then
		ply:SendLocalizedMessage("ratelimit", RATELIMIT)
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
			if not data.context then continue end

			ent_score = ent_score + data.context.timebench*2000
		end

		if entity:GetClass() == "starfall_processor" then
			if not entity.instance then continue end

			ent_score = ent_score + entity.instance.cpu_average*2000
		end

		lag_scores[owner] = lag_scores[owner] and lag_scores[owner] + ent_score or ent_score
	end

	local sorted_scores = table.SortByKey(lag_scores, false)

	if IsValid(ply) then
		ply:SendLocalizedMessage("findlag.note")
	end
	for _, index in ipairs(sorted_scores) do
		cmd_out(ply, string.format("%s: %i", index:Nick(), math.floor(lag_scores[index])))
	end
end)

---@param chip Entity
local function getChipDataForPrint(chip)
	local is_e2 = chip:GetClass() == "gmod_wire_expression2"

	local name = "errored"
	local exec_time = 0
	local chip_type = is_e2 and "E2" or "SF"

	if is_e2 and chip.context ~= nil then
		name = chip.name
		exec_time = chip.context.timebench*1000
	elseif chip.instance ~= nil then -- Assume starfall
		name = chip.name
		exec_time = chip.instance.cpu_average*1000
	end

	local owner = chip:CPPIGetOwner()
	local owner_text = IsValid(owner) and owner:Nick() or "Disconnected/World"

	return string.format("| %-24s | %s | %-32s | %.1fms	|", owner_text, chip_type, name, exec_time)
end

concommand.Add("findchips", function (ply, cmd, args, arg_str)
	if not FSB.Ratelimit(ratelimit_table, ply, RATELIMIT) then
		ply:SendLocalizedMessage("ratelimit", RATELIMIT)
		return
	end

	local chips = {}

	for _, entity in ipairs(ents.GetAll()) do
		if entity:GetClass() == "gmod_wire_expression2" then
			chips[#chips+1] = entity
		end

		if entity:GetClass() == "starfall_processor" then
			chips[#chips+1] = entity
		end
	end

	for _, chip in ipairs(chips) do
		cmd_out(ply, getChipDataForPrint(chip))
	end
end)
