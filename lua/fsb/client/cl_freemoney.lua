local last_transaction
local submit_btn

local DEFAULT_COLOR = Color(82, 82, 82)
local FAIL_COLOR = Color(200, 20, 20)
local SUCCESS_COLOR = Color(20, 200, 20)

function FSB.OpenMoneySendDialog(ply)
	local window = FSB.CreateWindow(FSB.Translate("money.transfer_window"), 220, 80, true)

	local panel = window:Add("DPanel")
	panel:Dock(FILL)
	function panel:Paint(w,h)
		draw.RoundedBox(2, 0, 0, w, h, Color(30, 30, 30))
	end

	local input = panel:Add("DNumberWang")
	submit_btn = panel:Add("DButton")
	local balance = panel:Add("DLabel")
	local sendMoney = function ()
		last_transaction = FSB.SendMoney(ply, input:GetValue())
		balance:SetText(FSB.Translate("money.your_balance", LocalPlayer():GetBalance()))
		submit_btn:SetEnabled(false)
		if last_transaction == -1 then
			submit_btn:SetColor(FAIL_COLOR)
		end
		timer.Simple(MONEY_RATELIMIT, function ()
			if submit_btn:IsValid() then
				submit_btn:SetEnabled(true)
				submit_btn:SetColor(DEFAULT_COLOR)
			end
		end)
	end
	input:Dock(FILL)
	input:SetMin(MONEY_MIN_TRANSFER)
	input:SetValue(1)
	input.OnEnter = sendMoney

	submit_btn:Dock(RIGHT)
	submit_btn:SetWidth(48)
	submit_btn:GetColor(DEFAULT_COLOR)
	submit_btn.DoClick = sendMoney
	submit_btn:SetText(FSB.Translate("money.button_send"))

	balance:Dock(BOTTOM)
	balance:SetText(FSB.Translate("money.your_balance", LocalPlayer():GetBalance()))
end

hook.Add("FSBTransactionAck", "pay_menu_transaction_hook", function (tmp_transaction_id, transaction_id, success)
	if tmp_transaction_id ~= last_transaction then return end

	if submit_btn:IsValid() then
		submit_btn:SetColor(success and SUCCESS_COLOR or FAIL_COLOR)
	end
end)

function FSB.SendMoney(target, amount, send_notifications)
	if LocalPlayer():GetBalance() < amount then
		return -1
	end
	local steamid, ply = FSB.GetSteamIDAndPlayer(target)

	local temp_transaction_id = math.random(0, 2147483648)
	net.Start(MONEY_NET_MSG)
		net.WriteUInt(eMoneyMsg.SendMoney, 8)
		net.WriteUInt(temp_transaction_id, 32) -- temp transaction id
		net.WriteUInt64(steamid)
		net.WriteFloat(amount)
		net.WriteBool(send_notifications or true)
	net.SendToServer()

	return temp_transaction_id
end

net.Receive(MONEY_NET_MSG, function (len, ply)
	local type = net.ReadUInt(8)

	if type == eMoneyMsg.SendMoneyAck then
		local tmp_transaction_id = net.ReadUInt(32)
		local transaction_id
		local success = net.ReadBool()
		if success then
			transaction_id = net.ReadUInt(32)
		end

		hook.Run("FSBTransactionAck", tmp_transaction_id, transaction_id, success)
	elseif type == eMoneyMsg.RecieveTransaction then
		local source = net.ReadUInt64()
		local transaction_id = net.ReadUInt(32)
		local amount = net.ReadFloat()

		hook.Run("FSBTransactionReceive", source, transaction_id, amount)
	end
end)
