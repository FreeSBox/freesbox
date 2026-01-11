
if SERVER then
	sql.Query([[CREATE TABLE IF NOT EXISTS fsb_ghostbans (
		steamid TEXT PRIMARY KEY,
		description TEXT,
		creation_time BIGINT,
		expire_time BIGINT,
		banned_by_steamid TEXT
	)]])
end

local whitelisted_nets = {
	["WireLib.SyncBinds"] = true,
	["EASY_CHAT_SEND_SERVER_CONFIG"] = true,
	["EASY_CHAT_SYNC_BLOCKED"] = true,
	["EASY_CHAT_START_CHAT"] = true,
	["EASY_CHAT_RECEIVE_MSG"] = true,
	["set_has_focus"] = true,
	["petition_list_request"] = true,
	["petition_request"] = true,
}

---@class Player
local PLAYER = FindMetaTable("Player")

if SERVER then
	function PLAYER:SetGhostBanned(is_banned, unban_time, description, banned_by_steamid)
		self:SetPlayerNameNoSave("")
		if is_banned then
			description = description and "\n" .. description or ""
			self:SetNameTagNoSave("<color=255,0,0>[BANNED]<stop>" .. description)
		else
			self:InitNameAndTag()
			unban_time = 0
			banned_by_steamid = ""
		end
		self:SetNWFloat("GhostUnBanTime", unban_time)
		self:SetNWString("GhostBannedBySteamID", banned_by_steamid)
		self:SetNWString("GhostBanDesc", description)
	end
end

function PLAYER:IsGhostBanned()
	return self:GetNWFloat("GhostUnBanTime") > os.time()
end
function PLAYER:GetGhostBannedBySteamID64()
	return self:GetNWString("GhostBannedBySteamID")
end
function PLAYER:GetGhostBanDescription()
	return self:GetNWString("GhostBanDesc")
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


	---@param ply Player|string Player or steamid or steamid64.
	---@param unban_time number
	---@param description string
	---@param banned_by Player? Admin that caused this ban. NULL player or nil for console.
	function FSB.GhostBan(ply, unban_time, description, banned_by)
		local banned_by_steamid
		if IsValid(banned_by) then
			banned_by_steamid = banned_by:SteamID64()
		end

		local steamid64
		if isentity(ply) then
			assert(IsValid(ply), "Player is invalid")
			assert(ply:IsPlayer(), "Player is not a player?")

			steamid64 = ply:SteamID64()
			ply:SetGhostBanned(true, unban_time, description, banned_by_steamid)
		elseif isstring(ply) then
			if string.StartsWith(ply, "STEAM_") then
				steamid64 = util.SteamIDTo64(ply)
			else
				steamid64 = ply
			end
		end

		description = description or "not specified"
		unban_time = unban_time or 0

		sql.QueryTyped([[INSERT INTO fsb_ghostbans(
			steamid,
			description,
			creation_time,
			expire_time,
			banned_by_steamid
		) VALUES (?, ?, ?, ?, ?)
		]], steamid64, description, os.time(), unban_time, banned_by_steamid)

	end

	---@param ply Player|string Player or steamid or steamid64.
	function FSB.GhostUnBan(ply)
		local steamid64
		if isentity(ply) then
			assert(IsValid(ply), "Player is invalid")
			assert(ply:IsPlayer(), "Player is not a player?")

			steamid64 = ply:SteamID64()
			ply:SetGhostBanned(false)
		elseif isstring(ply) then
			if string.StartsWith(ply, "STEAM_") then
				steamid64 = util.SteamIDTo64(ply)
			else
				steamid64 = ply
			end
		end

		sql.QueryTyped("DELETE FROM fsb_ghostbans WHERE steamid = ?", steamid64)
	end

	hook.Add("PlayerInitialSpawn", "apply_ghost_ban", function (ply, transition)
		local results = sql.QueryTyped("SELECT expire_time, description, banned_by_steamid FROM fsb_ghostbans WHERE steamid = ?", ply:SteamID64())
		assert(results ~= false, "The SQL Query is broken in 'apply_ghost_ban'")

		local result = results[1]
		if result == nil then return end

		local unban_time = result["expire_time"]
		if unban_time == nil then return end

		if os.time() > unban_time then
			sql.QueryTyped("DELETE FROM fsb_ghostbans WHERE steamid = ?", ply:SteamID64())
			return
		end

		local description = result["description"]
		local banned_by_steamid = result["banned_by_steamid"]
		ply:SetGhostBanned(true, unban_time, description, banned_by_steamid)
	end)

	local net_ratelimit = {}
	hook.Add("NetIncoming", "block_ghostbanned_nets", function (net_index, name, len, ply)
		if not ply:IsGhostBanned() then return end

		if whitelisted_nets[name] then
			if FSB.Ratelimit(net_ratelimit, ply, 1) then
				return
			end
		end

		return false
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
