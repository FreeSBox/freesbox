util.AddNetworkString("vote_on")

util.AddNetworkString("create_petition")

util.AddNetworkString("request_petition")
util.AddNetworkString("request_petition_list")
util.AddNetworkString("receive_petition")
util.AddNetworkString("receive_patition_list")

local petition_no_limit = CreateConVar("petition_no_limit", "0", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Remove the limit of petitions per day")

sql.m_strError = nil -- This is required to invoke __newindex

setmetatable( sql, { __newindex = function( table, k, v )
	if ( k == "m_strError" and v and #v > 0 ) then
		print("[SQL Error] " .. v )
	end
end } )

sql.Query([[CREATE TABLE IF NOT EXISTS petitions (
	id INTEGER PRIMARY KEY,
	name TEXT,
	description TEXT,
	creation_time BIGINT,
	expires_at BIGINT,
	author_name TEXT,
	author_steamid BIGINT
)]])

sql.Query([[CREATE TABLE IF NOT EXISTS votes (
	id INTEGER PRIMARY KEY,
	petition_id INTEGER,
	creation_time BIGINT,
	vote_status INTEGER,
	author_steamid BIGINT
)]])

net.Receive("create_petition", function(len, ply)
	if not ply:IsFullyAuthenticated() then
		-- We cannot verify this players' identity.
		ply:PrintMessage(HUD_PRINTTALK, "You are not fully authenticated, petition discarded.")
		return
	end

	local player_id = ply:OwnerSteamID64()
	local name = net.ReadString()
	if #name > PETITION_NAME_MAX_LENGTH then return end
	local description_length = net.ReadUInt(19)
	local description_compressed = net.ReadData(description_length)
	local description_text = util.Decompress(description_compressed)
	if #description_text > PETITION_DESCRIPTION_MAX_LENGTH then
		ply:PrintMessage(HUD_PRINTTALK, "Your description is longer then the maximum allowed length (" .. tostring(description_length) .. "/" .. tostring(PETITION_DESCRIPTION_MAX_LENGTH) .. ").")
		return
	end

	local one_day_ago = os.time() - 60*60*24
	local results = sql.QueryTyped("SELECT * FROM petitions WHERE creation_time > ? AND author_steamid = ?", one_day_ago, player_id)
	if #results >= MAX_PETITIONS_PER_DAY and not petition_no_limit:GetBool() then
		ply:PrintMessage(HUD_PRINTTALK, "You can only create " .. MAX_PETITIONS_PER_DAY .. " petitions per day.")
		return
	end

	local petition_end_time = os.time() + 60*60*24

	sql.QueryTyped([[INSERT INTO petitions(
			name,
			description,
			creation_time,
			author_name,
			author_steamid,
			expires_at
		) VALUES (?, ?, ?, ?, ?, ?)]],
		name,
		description_text,
		os.time(),
		ply:GetName(),
		player_id,
		petition_end_time
	)
end)

net.Receive("vote_on", function (len, ply)
	if not ply:IsFullyAuthenticated() then
		-- We cannot verify this players' identity.
		ply:PrintMessage(HUD_PRINTTALK, "You are not fully authenticated, vote discarded.")
		return
	end

	local player_id = ply:OwnerSteamID64()
	local petition_id = net.ReadUInt(PETITION_ID_BITS)
	local dislike = net.ReadBool()

	local vote_status_ = dislike and eVoteStatus.DISLIKE or eVoteStatus.LIKE

	local results = sql.QueryTyped("SELECT expires_at FROM petitions WHERE id = ?", petition_id)
	if results == false then return end
	if #results == 0 then
		ply:PrintMessage(HUD_PRINTTALK, "The petition you are voting for does not exist.")
		return
	end
	if results[1].expires_at < os.time() then
		ply:PrintMessage(HUD_PRINTTALK, "You can no longer vote on this petition.")
		return
	end

	local results = sql.QueryTyped("SELECT * FROM votes WHERE petition_id = ? AND author_steamid = ?", petition_id, player_id)
	if results == false then return end
	if #results >= 1 then
		ply:PrintMessage(HUD_PRINTTALK, "You can only vote once.")
		return
	end

	sql.QueryTyped([[INSERT INTO votes(
			petition_id,
			creation_time,
			vote_status,
			author_steamid
		) VALUES (?, ?, ?, ?)]],
		petition_id,
		os.time(),
		vote_status_,
		player_id
	)

	net.Start("vote_on")
		net.WriteUInt(petition_id, PETITION_ID_BITS)
		net.WriteBool(dislike)
	net.Send(ply)
end)

net.Receive("request_petition_list", function (len, ply)
	local results = sql.QueryTyped("SELECT id, name FROM petitions")
	net.Start("receive_patition_list")
		net.WriteTable(results)
	net.Send(ply)
end)

net.Receive("request_petition", function (len, ply)
	local petition_id = net.ReadUInt(PETITION_ID_BITS)
	local results = sql.QueryTyped("SELECT * FROM petitions WHERE id = ?", petition_id)
	if results == false then return end
	local result = results[1]
	if result == nil then
		print(ply:GetName(), "Requested an invalid petition:", petition_id)
		return
	end

	local votes = sql.QueryTyped("SELECT vote_status FROM votes WHERE petition_id = ?", petition_id)

	local num_likes = 0
	local num_dislikes = 0
	if votes ~= false then
		---@diagnostic disable-next-line: param-type-mismatch
		for index, value in ipairs(votes) do
			if value.vote_status == eVoteStatus.LIKE then
				num_likes = num_likes + 1
			elseif value.vote_status == eVoteStatus.DISLIKE then
				num_dislikes = num_dislikes + 1
			end
		end
	end

	local description_compressed = util.Compress(result.description)
	local description_compressed_len = #description_compressed


	net.Start("receive_petition")
		net.WriteUInt(petition_id, PETITION_ID_BITS)
		net.WriteString(result.name)
		net.WriteUInt(num_likes, 16)
		net.WriteUInt(num_dislikes, 16)
		net.WriteUInt(description_compressed_len, 19)
		net.WriteData(description_compressed, description_compressed_len)
		net.WriteString(result.author_name)
		net.WriteString(result.author_steamid)
	net.Send(ply)
end)
