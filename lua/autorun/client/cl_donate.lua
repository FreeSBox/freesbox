-- Maybe use an existing font.
surface.CreateFont("donate_menu_title", {font="Roboto", size=18, antialias=true, extended=true})

local current_balance
local server_info = {
	month_price,
	expires_at
}
local progress
local progress_label
local expire_info
local selected_payment_method
local payment_methods
local payment_selector

net.Receive("aeza_server_info", function(len, ply)
	server_info.month_price = net.ReadInt(16)
	current_balance = net.ReadInt(16)
	server_info.expires_at = net.ReadUInt(32) -- Using uint here so this should work until 2106


	if(progress ~= nil) then
		progress:SetFraction(current_balance/server_info.month_price)
	end
	if(progress_label ~= nil) then
		progress_label:SetText(current_balance/100 .. "€ / " .. server_info.month_price/100 .. "€")
		progress_label:SizeToContents()
		progress_label:Center()
	end
	if(expire_info ~= nil) then
		expire_info:SetText(os.date("Server paid for until: %B %d %Y", server_info.expires_at))
	end
end)

local function request_server_info()
	net.Start("aeza_request_server_info")
	net.SendToServer()
end


local function populate_payment_selector()
	if(payment_selector ~= nil) then
		for k,v in ipairs(payment_methods.data.items) do
			payment_selector:AddChoice(v.name)
		end
	end
end
net.Receive("aeza_payment_methods", function(len, ply)
	local data_len = net.ReadUInt(16)
	local data = net.ReadData(data_len)
	payment_methods = util.JSONToTable(util.Decompress(data))
	populate_payment_selector()
end)
local function request_payment_methods()
	print("Requesting")
	net.Start("aeza_request_payment_methods")
	net.SendToServer()
end


net.Receive("aeza_invoice", function(len, ply)
	surface.PlaySound("ambient/water/rain_drip4.wav")
	notification.AddLegacy("Invoice created", NOTIFY_HINT, 3)

	local invoice_url = net.ReadString()
	MsgN(invoice_url)
	gui.OpenURL(invoice_url)
end)

local function create_window(name, size_x, size_y, is_popup)
	local menu = vgui.Create("DFrame")
	menu:SetSize(size_x, size_y)
	menu:SetSizable(false)
	menu:SetTitle("")
	gui.EnableScreenClicker(true)
	menu:SetKeyboardInputEnabled(true)
	menu:MakePopup()
	menu:ShowCloseButton(true)
	menu:Center()
	if is_popup then menu:MakePopup() end
	function menu:Paint(w,h)
		--draw.RoundedBox(4, 2, 3, w - 2, h -2, Color(180,177,177,150))
		draw.RoundedBox(4, 0, 0, w - 2, h - 2, Color(26, 26, 26))
		draw.DrawText(name, "donate_menu_title", 5, 5, Color(219, 219, 219))
	end

	menu.OnClose = function()
		gui.EnableScreenClicker(false)
	end

	local window = vgui.Create("DPanel", menu)
	window:Dock( FILL )
	function window:Paint(w,h)
		draw.RoundedBox(2, 0, 0, w, h, Color(30, 30, 30))
	end
	return window
end

concommand.Add("donate", function()
	local window_width = 300
	local window_hight = 300
	local window = create_window("Donate", window_width, window_hight, false)

	--local info = window:Add("DLabel")
	--info:Dock(TOP)
	--info:SetText("Paid for next month:")

	progress = window:Add("DProgress")
	progress:Dock(TOP)
	progress:SetTall(25)


	progress_label = progress:Add("DLabel")
	progress_label:SetText("")
	progress_label:SizeToContents()
	progress_label:Center()
	progress_label:SetPaintBackground(false)
	progress_label:SetDark(true)
	
	expire_info = window:Add("DLabel")
	expire_info:Dock(TOP)

	request_server_info()

	payment_selector = window:Add("DComboBox")
	payment_selector:Dock(TOP)
	payment_selector:SetValue("Payment method")

	-- This is pretty large so only call this once.
	if payment_methods == nil then
		request_payment_methods()
	else
		populate_payment_selector()
	end

	local pay_button
	local info_text
	local amount_input
	payment_selector.OnSelect = function(self, index, value)
		selected_payment_method = payment_methods.data.items[index]
		if pay_button ~= nil then pay_button:Remove() end
		if info_text ~= nil then info_text:Remove() end
		if amount_input ~= nil then amount_input:Remove() end

		info_text = window:Add("DLabel")
		info_text:SetText(
			"Enter a value in euro(€)\n" ..
			"Minimum is: " .. selected_payment_method.min/100 .. "€\n" ..
			"Fee: " .. selected_payment_method.fee .. "%"
		)
		info_text:SizeToContents()
		info_text:Dock(TOP)

		amount_input = window:Add("DNumberWang")
		amount_input:Dock(TOP)
		amount_input:SetDecimals(2)
		amount_input:SetValue(1)
		if selected_payment_method.max ~= nil then
			amount_input:SetMax(selected_payment_method.max)
		end

		-- If someone wants to set this lower then the minimum, I don't check for it server side,
		-- But don't expect for it to work.
		amount_input:SetMin(selected_payment_method.min/100)

		pay_button = window:Add("DButton")
		pay_button:Dock(TOP)
		pay_button:SetText("Pay")
		pay_button.DoClick = function()
			if(amount_input:GetValue()*100 >= selected_payment_method.min) then
				net.Start("aeza_donate")
					net.WriteUInt(amount_input:GetValue()*100,24)
					net.WriteString(selected_payment_method.slug)
				net.SendToServer()

				notification.AddLegacy("Creating invoice", NOTIFY_HINT, 3)
				surface.PlaySound("buttons/button3.wav")
			else
				notification.AddLegacy("You are not donating enought!", NOTIFY_ERROR, 3)
				surface.PlaySound("buttons/button11.wav")
			end
		end

	end

end)
