E2Lib.RegisterExtension("fsb", true, "Functions from the FreeSBox server.")

__e2setcost(2)

e2function number entity:isBUILD()
	if not IsValid(this) then return self:throw("Invalid entity!", "") end
	if not this:IsPlayer() then return self:throw("Expected a Player but got an Entity!", "") end

	if this:InPVPMode() then return 0 else return 1 end
end

e2function number entity:isPVP()
	if not IsValid(this) then return self:throw("Invalid entity!", "") end
	if not this:IsPlayer() then return self:throw("Expected a Player but got an Entity!", "") end

	if this:InPVPMode() then return 1 else return 0 end
end

e2function number entity:isGhostBanned()
	if not IsValid(this) then return self:throw("Invalid entity!", "") end
	if not this:IsPlayer() then return self:throw("Expected a Player but got an Entity!", "") end

	if this:IsGhostBanned() then return 1 else return 0 end
end
e2function string entity:ghostBannedBySteamID64()
	if not IsValid(this) then return self:throw("Invalid entity!", "") end
	if not this:IsPlayer() then return self:throw("Expected a Player but got an Entity!", "") end

	return this:GetGhostBannedBySteamID()
end

e2function string entity:ghostBanDescription()
	if not IsValid(this) then return self:throw("Invalid entity!", "") end
	if not this:IsPlayer() then return self:throw("Expected a Player but got an Entity!", "") end

	return this:GetGhostBanDescription()
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
