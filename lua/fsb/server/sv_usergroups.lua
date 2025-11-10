
sql.Query([[CREATE TABLE IF NOT EXISTS fsb_groups (
	steamid STRING NOT NULL PRIMARY KEY,
	usergroup STRING NOT NULL DEFAULT "user"
)]])


hook.Add("PlayerInitialSpawn", "give_usergroup", function (ply, transition)
	if ply:IsFullyAuthenticated() then
		local result = sql.QueryTyped("SELECT usergroup FROM fsb_groups WHERE steamid = ?", ply:SteamID64())
		assert(result ~= false, "The SQL Query is broken in 'give_usergroup'")
		if #result == 1 then
			ply:SetUserGroup(result[1])
		end
	end
end)

---Sets the usergroup in the database.
---Made to replace the ULX system, as it doesn't account for SteamID spoofing, which is possible on FreeSBox.
---@param steamid string SteamID or SteamID64.
---@param usergroup string
function FSB.SetGroupBySteamID(steamid, usergroup)
	assert(isstring(steamid), "SteamID is not a string")
	assert(isstring(usergroup), "Usergroup is not a string")

	if string.StartsWith(steamid, "STEAM_") then
		steamid = util.SteamIDTo64(steamid)
	end

	sql.QueryTyped("INSERT OR REPLACE INTO fsb_groups(steamid, usergroup) VALUES(?, ?)", steamid, usergroup);
end
