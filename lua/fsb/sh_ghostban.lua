

---@class Player
local PLAYER = FindMetaTable("Player")

if SERVER then
	function PLAYER:SetGhostBanned(is_banned, unban_time)
		self:SetPlayerNameNoSave("")
		if is_banned then
			self:SetNameTagNoSave("<color=255,0,0>[BANNED]")
		else
			self:InitNameAndTag()
			unban_time = 0
		end
		self:SetNWFloat("GhostUnBanTime", unban_time)
	end
end

function PLAYER:IsGhostBanned()
	return self:GetNWFloat("GhostUnBanTime") > os.time()
end

local TAG = "ghost_ban_check"
local function checkCanSpawn(ply)
	if IsValid(ply) and ply:IsPlayer() and ply:IsGhostBanned() then
		return false
	end
end
hook.Add("PlayerSpawnEffect", TAG, checkCanSpawn)
hook.Add("PlayerSpawnNPC", TAG, checkCanSpawn)
hook.Add("PlayerSpawnObject", TAG, checkCanSpawn)
hook.Add("PlayerSpawnProp", TAG, checkCanSpawn)
hook.Add("PlayerSpawnRagdoll", TAG, checkCanSpawn)
hook.Add("PlayerSpawnSENT", TAG, checkCanSpawn)
hook.Add("PlayerSpawnSWEP", TAG, checkCanSpawn)
hook.Add("PlayerSpawnVehicle", TAG, checkCanSpawn)

hook.Add("EntityFireBullets", TAG, checkCanSpawn)
hook.Add("PhysgunPickup", TAG, checkCanSpawn)

hook.Add("CanTool", TAG, checkCanSpawn)
hook.Add("CanProperty", TAG, checkCanSpawn)

hook.Add("PlayerNoClip", TAG, checkCanSpawn)

hook.Add("StartCommand", "init_ghostban", function (ply, ucmd)
	-- Hook this because ULX doesn't provide a better way to stop someone from running commands.
	FSB.HOOKS.ucl_query = FSB.HOOKS.ucl_query or ULib.ucl.query
	local og_ucl_query = FSB.HOOKS.ucl_query
	ULib.ucl.query = function ( ply, access, hide )
		if IsValid(ply) and ply:IsGhostBanned() then return false end

		return og_ucl_query(ply, access, hide)
	end
	hook.Remove("StartCommand", "init_ghostban")
end)

if SERVER then
	hook.Add("CanEditVariables", TAG, checkCanSpawn)
	hook.Add("PlayerCanPickupWeapon", TAG, checkCanSpawn)
	hook.Add("CanPlayerSuicide", TAG, checkCanSpawn)

	hook.Add("EntityTakeDamage", TAG, function (target, dmg)
		local attacker = dmg:GetAttacker()
		if not IsValid(attacker) then return end
		if attacker:IsPlayer() and attacker:IsGhostBanned() then
			return true
		end
	end)

	hook.Add("PlayerSayTransform", TAG, function (ply, datapack, is_team, is_local)
		if ply:IsGhostBanned() then
			datapack[3] = true -- is_local = true
		end
	end)

	hook.Add("PlayerSay", TAG, function (ply, text, is_team, is_local)
		if ply:IsGhostBanned() and not is_local then
			return ""
		end
	end)

	function FSB.GhostBan(ply, unban_time)
		assert(IsValid(ply), "Ply is invalid.")
		unban_time = unban_time or 0

		ply:SetPData("ghost_unban_time", unban_time)
		ply:SetGhostBanned(true, unban_time)
	end

	function FSB.GhostUnBan(ply)
		assert(IsValid(ply), "Ply is invalid.")
		ply:RemovePData("ghost_unban_time")
		ply:SetGhostBanned(false)
	end

	hook.Add("PlayerInitialSpawn", "apply_ghost_ban", function (ply, transition)
		local unban_time = tonumber(ply:GetPData("ghost_unban_time", nil))
		if unban_time == nil then return end
		if os.time() > unban_time then
			ply:RemovePData("ghost_unban_time")
			return
		end
		ply:SetGhostBanned(true, unban_time)
	end)

	timer.Create("remove_passed_bans", 10, 0, function ()
		for _, ply in ipairs(player.GetAll()) do
			local unban_time = ply:GetNWFloat("GhostUnBanTime")
			if unban_time > 0 and unban_time < os.time() then
				ply:SetGhostBanned(false)
			end
		end
	end)
else
	hook.Add("CreateMove", "init_ghostban_timer", function (cmd)
		timer.Create("notify_ghost_banned", 10, 0, function ()
			local lp = LocalPlayer()
			if not lp:IsGhostBanned() then return end

			local date = os.date("%d/%m/%Y %X", math.floor(lp:GetNWFloat("GhostUnBanTime", 0)))
			chat.AddText(Color(255,0,0), string.format(FSB.Translate("advert.ghostbanned"), date))
		end)
		hook.Remove("CreateMove", "init_ghostban_timer")
	end)
end
