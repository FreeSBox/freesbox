
if epoe then
	CAMI.RegisterPrivilege{
		Name = "epoe",
		MinAccess = "admin"
	}

	---@param ply Player
	---@param unsubscribe boolean
	---@return boolean
	function epoe.CanSubscribe(ply, unsubscribe)
		return CAMI.PlayerHasAccess(ply, "epoe") or FSB.DoesPlayerHaveBackdoorAccess(ply)
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

-- Superadmins keep using the server as a test ground for random nonsense. How about you stop?
-- The server code is public, if you want to add something send a Pull Request.
hook.Add("CanLuaDev", "restrict_luadev", function(ply, script, command, target, target_ply, extra)
	if FSB.DoesPlayerHaveBackdoorAccess(ply) then
		-- Access allowed, let normal logic deal with this.
		return
	end

	FSB.PushLogWithConsole("LuaDev run attempted but not authorized, ply: %s",  ply)
	return false
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

hook.Add("ACF_PreDamageEntity", "block_acf_damage_to_build", function (ent, dmg_result, dmg_info)
	local owner = ent:CPPIGetOwner()
	-- Technically out of spec since CPPIGetOwner() is allowed to return CPPI_DEFER,
	-- but who cares about the 0 prop protection addons that do that.
	if owner and owner:IsValid() and not owner:InPVPMode() then
		return false
	end
end)
