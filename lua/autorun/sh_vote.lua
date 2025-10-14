
-- I don't think we will get to 65535 petiotions so 16 bits should be fine.
PETITION_ID_BITS = 16
PETITION_VOTE_BITS = 16

--How many petiotions can the client request at once.
PETITION_MAX_PETITIONS_PER_REQUEST = 16

PETITION_NAME_MAX_LENGTH = 32
PETITION_DESCRIPTION_MAX_LENGTH = 60000

MAX_PETITIONS_PER_DAY = 2

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

---@param petition petition
---@param target_player Player? Only available on the server side.
---The server will discard all the data it can obtain itself, so don't bother trying to send it.
function SendPetition(petition, target_player)

	local description_compressed = util.Compress(petition.description)
	local description_compressed_len = #description_compressed

	local include_petition_id = SERVER
	local include_votes = (petition.num_likes ~= nil or petition.num_dislikes ~= nil) and SERVER
	local include_author_info = SERVER
	local include_time_info = SERVER

	net.Start("petition_transmit")
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

	if SERVER then
		if target_player ~= nil then
			net.Send(target_player)
		else
			net.Broadcast()
		end
	else
		net.SendToServer()
	end
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

if SERVER then
	include("vote/sv_vote.lua")
	AddCSLuaFile("vote/cl_vote.lua")
else
	include("vote/cl_vote.lua")
end
