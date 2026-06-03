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

---Saves the new balance in the database  
---**Should only be called on the server.**
---@param new_balance number
function PLAYER:SetBalance(new_balance)
	self:SetNWFloat("FSBBalance", new_balance)
	if SERVER then
		self:SetPData("FSBBalance", new_balance)
	end
end

---**Should only be called on the server.**
function PLAYER:AddMoney(amount)
	assert(amount > 0, "Attempt to add negative money")
	self:SetBalance(self:GetBalance() + amount)
end

---@param amount integer
---@return boolean True if we have enough money to withdraw
function PLAYER:WithdrawMoney(amount)
	local corrent_balance = self:GetBalance()
	if corrent_balance < amount then
		return false
	end

	self:SetBalance(corrent_balance - amount)

	return true
end

function PLAYER:TranferMoney(recieving_player, amount)
	if not IsValid(recieving_player) then return false end
	if not isentity(recieving_player) then return false end
	if not recieving_player:IsPlayer() then return false end

	if hook.Run("FSBCanTransferMoney", self, recieving_player, amount) == false then return false end

	if not self:WithdrawMoney(amount) then return false end
	recieving_player:AddMoney(amount)

	hook.Run("FSBTransferredMoney", self, recieving_player, amount)
	self:SendLocalizedHint("money.transfer", NOTIFY_GENERIC, 3, self:GetName(), amount, recieving_player:GetName())
	recieving_player:SendLocalizedHint("money.transfer", NOTIFY_GENERIC, 3, self:GetName(), amount, recieving_player:GetName())

	return true
end


if SERVER then
	hook.Add("PlayerInitialSpawn", "init_money", function (player, transition)
		local balance = tonumber(player:GetPData("FSBBalance", 0))
		assert(balance, "FSBBalance is nil")
		player:SetBalance(balance)
	end)

	timer.Create("give_out_free_money", 60, 0, function ()
		for _, ply in ipairs(player.GetAll()) do
			if ply:IsConnected() and ply:IsActive() then
				ply:AddMoney(1)
			end
		end
	end)
end
