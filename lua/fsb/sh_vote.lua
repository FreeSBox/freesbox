
-- I don't think we will get to 65535 petiotions so 16 bits should be fine.
PETITION_ID_BITS = 16
PETITION_VOTE_BITS = 16

--How many petiotions can the client request at once.
PETITION_MAX_PETITIONS_PER_REQUEST = 32

PETITION_NAME_MAX_LENGTH = 128
PETITION_DESCRIPTION_MAX_LENGTH = 30000

MAX_PETITIONS_PER_DAY = 2

local NETMSG_MAX_BYTES = 65533

---@class petition
---@field index integer?
---@field name string
---@field description string
---@field num_likes integer?
---@field num_dislikes integer?
---@field author_name string?
---@field author_steamid string? Author's steamid64.
---@field creation_time number?
---@field expire_time number? When can we no longer vote on the petition.
---@field our_vote_status number? Client side eVoteStatus.

---@param index integer
---@return petition
function FSB.GetInvalidPetition(index)
	return {
		index = index,
		name = "invalid",
		description = "invalid petition",
		num_likes = 0,
		num_dislikes = 0,
		author_name = "invalid",
		author_steamid = "STEAM_0:0:0",
		creation_time = 0,
		expire_time = 0,
		our_vote_status = eVoteStatus.NOT_VOTED
	}
end

---@param petitions table<integer,petition> Petitions array.
---@param target_player Player? Only available on the server side.
---The server will discard all the data it can obtain itself, so don't bother trying to send it.  
---The client can only send one petition at a time,
---if you send more then one the server will discard everything after first petition.
function FSB.SendPetitions(petitions, target_player)
	assert(#petitions <= PETITION_MAX_PETITIONS_PER_REQUEST, "Tried to send too many petitions")

	local overflow_petitions = {}

	net.Start("petition_transmit")
	for _, petition in ipairs(petitions) do
		local description_compressed = util.Compress(petition.description)
		local description_compressed_len = #description_compressed
		if NETMSG_MAX_BYTES-net.BytesWritten() <= description_compressed_len+PETITION_NAME_MAX_LENGTH+1000 then
			overflow_petitions[#overflow_petitions+1] = petition
			net.WriteBool(false) -- No petitions left
			goto CONTINUE
		end
		net.WriteBool(true)
		local include_petition_id = SERVER
		local include_votes = (petition.num_likes ~= nil or petition.num_dislikes ~= nil) and SERVER
		local include_author_info = SERVER
		local include_time_info = SERVER
		net.WriteBool(include_petition_id)
		if include_petition_id then
			net.WriteUInt(petition.index, PETITION_ID_BITS)
		end
		net.WriteString(petition.name)
		net.WriteBool(include_votes)
		if include_votes then
			net.WriteUInt(petition.num_likes, PETITION_VOTE_BITS)
			net.WriteUInt(petition.num_dislikes, PETITION_VOTE_BITS)
			net.WriteUInt(petition.our_vote_status, 2)
		end
		net.WriteBool(include_author_info)
		if include_author_info then
			net.WriteString(petition.author_name)
			net.WriteString(petition.author_steamid)
		end
		net.WriteBool(include_time_info)
		if include_time_info then
			net.WriteUInt(petition.creation_time, 32)
			net.WriteUInt(petition.expire_time, 32)
		end

		net.WriteUInt(description_compressed_len, 19)
		net.WriteData(description_compressed, description_compressed_len)

		::CONTINUE::
	end


	if #overflow_petitions == 0 then
		net.WriteBool(false)
	end

	local bytes_used = net.BytesWritten()

	if SERVER then
		if target_player ~= nil then
			net.Send(target_player)
		else
			net.Broadcast()
		end
	else
		net.SendToServer()
	end

	if #overflow_petitions > 0 then
		MsgN(string.format("SendPetitions petitions packet too large, splitting. (%d petitions left to send, %d bytes written)", #overflow_petitions, bytes_used))
		FSB.SendPetitions(overflow_petitions, target_player)
	end
end

---**Internal** not intended for use outside petition networking code.
---Reads 1 petition from the petition_transmit netmsg
---@return petition
function FSB.ReadOnePetition()
	---@type petition
	---@diagnostic disable-next-line: missing-fields
	local petition = {}

	if net.ReadBool() then -- include_petition_id
		petition.index = net.ReadUInt(PETITION_ID_BITS)
	end
	petition.name = net.ReadString()

	if net.ReadBool() then -- include_votes
		petition.num_likes       = net.ReadUInt(PETITION_VOTE_BITS)
		petition.num_dislikes    = net.ReadUInt(PETITION_VOTE_BITS)
		petition.our_vote_status = net.ReadUInt(2)
	end

	if net.ReadBool() then -- include_author_info
		petition.author_name    = net.ReadString()
		petition.author_steamid = net.ReadString()
	end

	if net.ReadBool() then -- include_time_info
		petition.creation_time = net.ReadUInt(32)
		petition.expire_time   = net.ReadUInt(32)
	end

	local description_length = net.ReadUInt(19)
	local description_compressed = net.ReadData(description_length)
	---@diagnostic disable-next-line: assign-type-mismatch
	petition.description = util.Decompress(description_compressed)

	return petition
end

function string.IsOnlyWhiteSpace(inputStr)
	return string.match(inputStr, "^%s*$")
end

eVoteStatus =
{
	NOT_VOTED = 0,
	LIKE = 1,
	DISLIKE = 2,
}
