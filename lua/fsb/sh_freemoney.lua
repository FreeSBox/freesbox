--It's money, but you get it for free
--You are also free to use it for anything
--More can be read in petition #823

--Let's hope we won't have to face players that want multiple money accouts.
--TODO Add integration with the !халява command

---@class Player
local PLAYER = FindMetaTable("Player")

function PLAYER:GetBalance()
	return self:GetNWFloat("FSBBalance")
end

-- Account ID for the infinite money printer account
-- This is where the server gives money from
MONEY_SERVER_MONEYPRINTER = 24
MONEY_RATELIMIT = 2
MONEY_MIN_TRANSFER = 0.1


---@param ply Player|string Player or string object
---@return string SteamID
---@return boolean|Player Player or false if player was not found
function FSB.GetSteamIDAndPlayer(ply)
	if isstring(ply) then
		---@diagnostic disable-next-line: param-type-mismatch
		local ply_on_srv = player.GetBySteamID64(ply)
		---@diagnostic disable-next-line: return-type-mismatch
		return ply, ply_on_srv
	elseif IsValid(ply) then
		---@diagnostic disable-next-line: param-type-mismatch, return-type-mismatch
		return ply:SteamID64(), ply
	end

	return tostring(MONEY_SERVER_MONEYPRINTER), false
end

eMoneyMsg = {
	-- client->server
	SendMoney = 1,
}
