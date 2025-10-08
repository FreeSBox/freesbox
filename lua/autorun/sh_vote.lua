
-- I don't think we will get to 65535 petiotions so 16 bits should be fine.
PETITION_ID_BITS = 16

PETITION_NAME_MAX_LENGTH = 32
PETITION_DESCRIPTION_MAX_LENGTH = 64000

MAX_PETITIONS_PER_DAY = 2

---@class petition
---@field index integer
---@field name string
---@field description string
---@field num_likes integer
---@field num_dislikes integer
---@field author_name string
---@field author_steamid string Author steamid64
---@field loaded boolean? The petition is fully recieved from the server.

---@param petition petition
---@param target_player Player? Only available on the server side.
function SendPetition(petition, target_player)

	local description_compressed = util.Compress(petition.description)
	local description_compressed_len = #description_compressed

	net.Start("petition_transmit")
		net.WriteUInt(petition.index, PETITION_ID_BITS)
		net.WriteString(petition.name)
		net.WriteUInt(petition.num_likes, 16)
		net.WriteUInt(petition.num_dislikes, 16)
		net.WriteString(petition.author_name)
		net.WriteString(petition.author_steamid)
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

eVoteStatus =
{
	NOT_VOTED = 0,
	LIKE = 1,
	DISLIKE = 2,
}


