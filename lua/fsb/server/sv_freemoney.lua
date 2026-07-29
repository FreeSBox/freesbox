util.AddNetworkString("fsb_money_msg")

sql.Query[[CREATE TABLE IF NOT EXISTS fsb_transactions (
	id INTEGER PRIMARY KEY,
	amount INTEGER,
	time BIGINT,
	source BIGINT,
	destination BIGINT,
	comment TEXT
)]]

---@class Player
local PLAYER = FindMetaTable("Player")

local getSteamIDAndPlayer = FSB.GetSteamIDAndPlayer

---@param ply string|Player SteamID64 or player class
---@param use_cache boolean Should we check online players, this will avoid DB access if the player is online
---@return number balance
function FSB.GetPlayerBalance(ply, use_cache)
	local steamid64, ply = getSteamIDAndPlayer(ply)

	if use_cache then
		if IsValid(ply) then
			---@diagnostic disable-next-line: param-type-mismatch
			return ply:GetBalance()
		end
	end

	local results = sql.QueryTyped("SELECT amount, destination, source FROM fsb_transactions WHERE destination = ? OR source = ?", steamid64, steamid64)
	assert(results ~= false, "The SQL Query is broken in 'PLAYER:RecalculatePlayerBalance'")

	local balance = 0
	for i = 1, #results do
		local res = results[i]
		if tostring(res.destination) == steamid64 then
			balance = balance + res.amount
		else
			balance = balance - res.amount
		end
	end

	return balance
end

---@param source Player|string?
---@param dest Player|string?
---@param amount number
---@param persist boolean
---@param send_notifications? boolean False by deafult
---@return boolean success
function FSB.TranferMoney(source, dest, amount, persist, send_notifications)
	assert(amount >= MONEY_MIN_TRANSFER, "Too little or negative money")
	local source, source_ply = getSteamIDAndPlayer(source)
	local dest, dest_ply = getSteamIDAndPlayer(dest)

	if source == dest then
		return false
	end

	local balance
	-- We are using SERVER_MONEYPRINTER, skip balance checks
	if source == nil or source == tostring(MONEY_SERVER_MONEYPRINTER) then goto SUCCESS end

	balance = FSB.GetPlayerBalance(source, true)
	if balance < amount then
		return false
	end

	::SUCCESS::

	if persist then
		sql.QueryTyped(
			"INSERT INTO fsb_transactions(amount, time, source, destination) VALUES (?, ?, ?, ?)",
			amount,
			os.time(),
			source or MONEY_SERVER_MONEYPRINTER,
			dest or MONEY_SERVER_MONEYPRINTER
		)
	end

	if IsValid(dest_ply) then
		dest_ply:SetBalance(dest_ply:GetBalance() + amount)
	end
	if IsValid(source_ply) then
		source_ply:SetBalance(source_ply:GetBalance() - amount)
	end
	if IsValid(dest_ply) and IsValid(source_ply) and send_notifications then
		dest_ply:SendLocalizedHint("money.transfer", NOTIFY_GENERIC, 3, source_ply:GetName(), amount, dest_ply:GetName())
		source_ply:SendLocalizedHint("money.transfer", NOTIFY_GENERIC, 3, source_ply:GetName(), amount, dest_ply:GetName())
	end


	return true
end

-- Loads balance information from the database for all players
function FSB.RecalculatePlayerBalances()
	local results = sql.QueryTyped("SELECT amount, destination, source FROM fsb_transactions")
	assert(results ~= false, "The SQL Query is broken in 'FSB.RecalculatePlayerBalances'")

	local balances = {}
	for i = 1, #results do
		local res = results[i]
		local amount = res.amount
		local destination = res.destination
		local source = res.source

		balances[destination] = (balances[destination] or 0) + amount
		balances[source] = (balances[source] or 0) - amount
	end

	for _,ply in player.Iterator() do
		local balance = balances[ply:SteamID64()]
		if balance == nil then
			balance = 0
		end
		ply:SetBalance(balance)
	end
end

-- Loads balance information from the database for this player
function PLAYER:RecalculatePlayerBalance()
	local balance = FSB.GetPlayerBalance(self:SteamID64(), false)
	self:SetBalance(balance)
end

---Sets the new balance without saving in the database.
---It will be reset the next time RecalculatePlayerBalances is called
---@param new_balance number
function PLAYER:SetBalance(new_balance)
	self:SetNWFloat("FSBBalance", new_balance)
end

---@param amount number
---@param source? string SteamID64 that sent the money, if nil money will be sent from SERVER_MONEYPRINTER
---@param persist? boolean Save this transaction in the database, default true
---Note that if you provide the source parameter it will take the money from that player, if the player exists
function PLAYER:AddMoney(amount, source, persist)
	return FSB.TranferMoney(source, self, amount, persist or true)
end

---@param amount integer
---@param destination? string SteamID64 of a player to send the money to, if nil sends to SERVER_MONEYPRINTER
---@param persist? boolean Save this transaction in the database, default true
---@return boolean True if we have enough money to withdraw
function PLAYER:WithdrawMoney(amount, destination, persist)
	return FSB.TranferMoney(self, destination, amount, persist or true)
end

hook.Add("PlayerInitialSpawn", "init_money", function (player, transition)
	player:RecalculatePlayerBalance()
end)

timer.Create("give_out_free_money", 60, 0, function ()
	for _, ply in ipairs(player.GetAll()) do
		if ply:IsConnected() and ply:IsActive() and ply:IsFullyAuthenticated() then
			ply:AddMoney(1)
		end
	end
end)

local transaction_ratelimit = {}

net.Receive("fsb_money_msg", function (len, ply)
	local type = net.ReadUInt(8)
	if type == eMoneyMsg.SendMoney then
		if not FSB.Ratelimit(transaction_ratelimit, ply, MONEY_RATELIMIT) then
			ply:SendLocalizedHint("ratelimit", NOTIFY_ERROR, 3, MONEY_RATELIMIT)
			return
		end

		local dest = net.ReadUInt64()
		local amount = net.ReadFloat()
		local send_notifications = net.ReadBool()
		FSB.TranferMoney(ply, dest, amount, true, send_notifications)
	end
end)
