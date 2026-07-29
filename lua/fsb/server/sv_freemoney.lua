--sql.Query("DROP TABLE fsb_transactions")

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

-- Account ID for the infinite money printer account
-- This is where the server gives money from
local SERVER_MONEYPRINTER = 24

---@param ply Player|string Player or string object
---@return string SteamID
---@return boolean|Player Player or false if player was not found
local function getSteamIDandPlayer(ply)
	if isstring(ply) then
		---@diagnostic disable-next-line: param-type-mismatch
		local ply_on_srv = player.GetBySteamID64(ply)
		---@diagnostic disable-next-line: return-type-mismatch
		return ply, ply_on_srv
	elseif IsValid(ply) then
		---@diagnostic disable-next-line: param-type-mismatch, return-type-mismatch
		return ply:SteamID64(), ply
	end

	return tostring(SERVER_MONEYPRINTER), false
end

---@param ply string|Player SteamID64 or player class
---@param use_cache boolean Should we check online players, this will avoid DB access if the player is online
---@return number balance
function FSB.GetPlayerBalance(ply, use_cache)
	local steamid64, ply = getSteamIDandPlayer(ply)

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
---@return boolean success
function FSB.TranferMoney(source, dest, amount, persist)
	assert(amount >= 0.01, "Too little or negative money")
	local source, source_ply = getSteamIDandPlayer(source)
	local dest, dest_ply = getSteamIDandPlayer(dest)

	if source == dest then
		return false
	end

	local balance
	-- We are using SERVER_MONEYPRINTER, skip balance checks
	if source == nil or source == tostring(SERVER_MONEYPRINTER) then goto SUCCESS end

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
			source or SERVER_MONEYPRINTER,
			dest or SERVER_MONEYPRINTER
		)
	end

	if IsValid(dest_ply) then
		dest_ply:SetBalance(dest_ply:GetBalance() + amount)
	end
	if IsValid(source_ply) then
		source_ply:SetBalance(source_ply:GetBalance() - amount)
	end
	if IsValid(dest_ply) and IsValid(source_ply) then
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
