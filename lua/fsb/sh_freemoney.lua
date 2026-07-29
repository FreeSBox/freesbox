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

