E2Lib.RegisterExtension("fsb", true, "Functions from the FreeSBox server.")

__e2setcost(2)

e2function number entity:isBUILD()
	if not IsValid(this) then return self:throw("Invalid entity!", "") end
	if not this:IsPlayer() then return self:throw("Expected a Player but got an Entity!", "") end

	return not this:InPVPMode()
end

e2function number entity:isPVP()
	if not IsValid(this) then return self:throw("Invalid entity!", "") end
	if not this:IsPlayer() then return self:throw("Expected a Player but got an Entity!", "") end

	return this:InPVPMode()
end

e2function number entity:pvpModeEndTime()
	if not IsValid(this) then return self:throw("Invalid entity!", "") end
	if not this:IsPlayer() then return self:throw("Expected a Player but got an Entity!", "") end

	return this:PVPModeEndTime()
end

e2function number entity:originalName()
	if not IsValid(this) then return self:throw("Invalid entity!", "") end
	if not this:IsPlayer() then return self:throw("Expected a Player but got an Entity!", "") end

	return this:GetOriginalName()
end

e2function number entity:nameTag()
	if not IsValid(this) then return self:throw("Invalid entity!", "") end
	if not this:IsPlayer() then return self:throw("Expected a Player but got an Entity!", "") end

	return this:GetNameTag()
end
