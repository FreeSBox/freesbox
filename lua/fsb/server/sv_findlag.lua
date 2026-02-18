
local RATELIMIT = 5
local ratelimit_table = {}

local function cmd_out(ply, msg)
	if IsValid(ply) then
		ply:PrintMessage(HUD_PRINTCONSOLE, msg)
	else
		MsgN(msg)
	end
end

local function getSFCPUAverage(chip)
	if chip.instance.perf ~= nil then
		return chip.instance.perf.cpuAverage
	else -- Support older versions of starfall.
		return chip.instance.cpu_average
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

		local class = entity:GetClass()

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

		if class == "gmod_wire_gate" then
			ent_score = ent_score + 1
		elseif class == "gmod_wire_expression2" then
			if not entity.context then continue end
			ent_score = ent_score + entity.context.timebench*2000
		elseif class == "gmod_wire_fpga" then
			if not entity.timebench then continue end
			ent_score = ent_score + entity.timebench*2000
		elseif class == "starfall_processor" then
			if not entity.instance then continue end
			ent_score = ent_score + getSFCPUAverage(entity)*2000
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

local function getE2DataForPrint(chip, owner_name)
	local exec_time = 0
	local name = tostring(chip.name)

	if chip.context ~= nil then
		exec_time = chip.context.timebench*1000
	end

	return string.format("| %-24s | E2    | %-32s | %.1fms	|", owner_name, name, exec_time)
end

local function getFPGADataForPrint(chip, owner_name)
	local exec_time = 0
	local name = tostring(chip.name)

	if chip.timebench ~= nil then
		exec_time = chip.timebench*1000
	end

	return string.format("| %-24s | FPGA  | %-32s | %.1fms	|", owner_name, name, exec_time)
end

local function getSFDataForPrint(chip, owner_name)
	local exec_time = 0
	local name = chip.name and tostring(chip.name) or "errored"

	if chip.instance ~= nil then
		exec_time = getSFCPUAverage(chip)
	end

	return string.format("| %-24s | SF    | %-32s | %.1fms	|", owner_name, name, exec_time)
end

---@param chip Entity
local function getChipDataForPrint(chip)
	local owner = chip:CPPIGetOwner()
	local owner_name = IsValid(owner) and owner:Nick() or "Disconnected/World"
	local class = chip:GetClass()

	if class == "gmod_wire_expression2" then
		return getE2DataForPrint(chip, owner_name)
	elseif class == "gmod_wire_fpga" then
		return getFPGADataForPrint(chip, owner_name)
	elseif class == "starfall_processor" then
		return getSFDataForPrint(chip, owner_name)
	end

	return "!invalid chip!"
end

local chip_classes =
{
	["gmod_wire_expression2"] = true,
	["gmod_wire_fpga"] = true,
	["starfall_processor"] = true,
}

concommand.Add("findchips", function (ply, cmd, args, arg_str)
	if not FSB.Ratelimit(ratelimit_table, ply, RATELIMIT) then
		ply:SendLocalizedMessage("ratelimit", RATELIMIT)
		return
	end

	local chips = {}

	for _, entity in ipairs(ents.GetAll()) do
		if chip_classes[entity:GetClass()] then
			chips[#chips+1] = entity
		end
	end

	for _, chip in ipairs(chips) do
		cmd_out(ply, getChipDataForPrint(chip))
	end
end)
