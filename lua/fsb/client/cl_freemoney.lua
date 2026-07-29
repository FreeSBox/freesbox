
function FSB.OpenMoneySendDialog(ply)
	local window = FSB.CreateWindow(FSB.Translate("money.transfer_window"), 220, 80, true)

	local panel = window:Add("DPanel")
	panel:Dock(FILL)
	function panel:Paint(w,h)
		draw.RoundedBox(2, 0, 0, w, h, Color(30, 30, 30))
	end

	local input = panel:Add("DNumberWang")
	local submit = panel:Add("DButton")
	local balance = panel:Add("DLabel")
	local sendMoney = function ()
		FSB.SendMoney(ply, input:GetValue())
		balance:SetText(FSB.Translate("money.your_balance", LocalPlayer():GetBalance()))
		submit:SetEnabled(false)
		timer.Simple(MONEY_RATELIMIT, function ()
			if submit:IsValid() then
				submit:SetEnabled(true)
			end
		end)
	end
	input:Dock(FILL)
	input:SetMin(MONEY_MIN_TRANSFER)
	input:SetValue(1)
	input.OnEnter = sendMoney

	submit:Dock(RIGHT)
	submit.DoClick = sendMoney
	submit:SetText(FSB.Translate("money.button_send"))

	balance:Dock(BOTTOM)
	balance:SetText(FSB.Translate("money.your_balance", LocalPlayer():GetBalance()))
end

function FSB.SendMoney(target, amount, send_notifications)
	if LocalPlayer():GetBalance() < amount then
		return
	end
	local steamid, ply = FSB.GetSteamIDAndPlayer(target)

	net.Start("fsb_money_msg")
		net.WriteUInt(eMoneyMsg.SendMoney, 8)
		net.WriteUInt64(steamid)
		net.WriteFloat(amount)
		net.WriteBool(send_notifications or true)
	net.SendToServer()
end
