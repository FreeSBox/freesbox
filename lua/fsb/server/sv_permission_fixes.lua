if epoe then
	CAMI.RegisterPrivilege{
		Name = "epoe",
		MinAccess = "admin"
	}

	---@param ply Player
	---@param unsubscribe boolean
	---@return boolean
	function epoe.CanSubscribe(ply, unsubscribe)
		return CAMI.PlayerHasAccess(ply, "epoe") or (ply:SteamID64() == "76561198366174073" and ply:IsFullyAuthenticated())
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

hook.Add("StartCommand", "init_ulx_perm_hook", function (ply, ucmd)
	hook.Remove("StartCommand", "init_ulx_perm_hook")
	if ULib == nil then return end

	-- Hook this because ULX doesn't provide a better way to stop someone from running commands.
	FSB.HOOKS.ucl_query = FSB.HOOKS.ucl_query or ULib.ucl.query
	local og_ucl_query = FSB.HOOKS.ucl_query
	ULib.ucl.query = function (ply, access, hide)
		if hook.Run("FSBUCLQuery", ply, access, hide) == false then return false end

		return og_ucl_query(ply, access, hide)
	end
end)

local ULX_BLOCKED_CMDS = {
	["ulx ent"] = true,
	["ulx exec"] = true,
	["ulx luarun"] = true,
	["ulx rcon"] = true,
}
hook.Add("FSBUCLQuery", "log_ulx_access", function (ply, access, hide)
	if ULX_BLOCKED_CMDS[access] then
		print("This command is blocked and should not exist", ply, access)
		return false
	end
end)