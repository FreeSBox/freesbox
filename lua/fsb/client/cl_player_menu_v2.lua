---@diagnostic disable: inject-field

local buttons =  {
	{ Text=FSB.Translate("vote.petitions"), Func=function(menu) RunConsoleCommand("vote") menu:Close() end },
	{ Text=FSB.Translate("rules"), Func=function(menu) RunConsoleCommand("rules") menu:Close() end },
	{ Text=FSB.Translate("pi_menu.ulx_menu"), Func=function(menu) RunConsoleCommand("ulx", "menu") menu:Close() end },
	{ Text=FSB.Translate("pi_menu.change_name"), Func=function(menu) RunConsoleCommand("setnamegui") menu:Close() end },
	{ Text=FSB.Translate("pi_menu.change_nametag"), Func=function(menu) RunConsoleCommand("setnametaggui") menu:Close() end }
}

local checkboxes = {
	{Text=FSB.Translate("pi_menu.no_render_on_lost_focus"), ConVar="cl_disable_render_on_focus_loss" },
	{Text=FSB.Translate("pi_menu.enable_auto_jump"), ConVar="auto_jump" },
	{Text=FSB.Translate("pi_menu.draw_spawnzone"), ConVar="fsb_draw_spawnzone" },
	{Text=FSB.Translate("pi_menu.nametag_toggle"), ConVar="cl_nametags_enable" },
	{Text=FSB.Translate("pi_menu.nametags_localplayer"), ConVar="cl_nametags_localplayer" },
	{Text=FSB.Translate("pi_menu.enable_adverts"), ConVar="fsb_enable_adverts" },
}

local clr_hover = Color(60, 60, 60, 255)
local clr_nothover = Color(50, 50, 50, 255)

surface.CreateFont("player_menu_title", {font="Roboto", size=18, antialias=true, extended=true})

---@return DPanel
local function create_window(name, size_x, size_y, is_popup)
	local menu = vgui.Create("DFrame")
	menu:SetSize(size_x, size_y)
	menu:SetSizable(false)
	menu:SetTitle("")
	menu:ShowCloseButton(true)
	menu:Center()
	if is_popup then
		menu:MakePopup()
	else
		gui.EnableScreenClicker(true)
	end
	function menu:Paint(w,h)
		draw.RoundedBox(4, 0, 0, w - 2, h - 2, Color(26, 26, 26))
		draw.DrawText(name, "player_menu_title", 5, 5, Color(219, 219, 219))
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

local function create_button(name, margin_left, margin_top, margin_right, margin_bottom, panel)
	local button = vgui.Create("DButton", panel)
	button:Dock( TOP )
	button:SetText("")
	button:DockMargin( margin_left, margin_top, margin_right, margin_bottom )
	function button:Paint(w, h)
		if(button:IsHovered()) then
			draw.RoundedBox(5,2, 0, w - 4, h, clr_hover)
		else
			draw.RoundedBox(5,2, 0, w - 4, h, clr_nothover)
		end
		draw.SimpleText(name, "player_menu_title", button:GetWide() / 2, 2, color_white, TEXT_ALIGN_CENTER)
	end
	return button
end

concommand.Add("menu", function()
	if vgui.CursorVisible() then return end

	local window_width = 600
	local window_hight = 400
	local window = create_window(FSB.Translate("pi_menu.title"), window_width, window_hight, false)

	for i=1, #buttons do
		--button:DockMargin( 0, 7, 300, -4 )
		local button = create_button(buttons[i].Text, 0,7,window_width/2,-4, window)
		button.DoClick = function() buttons[i].Func(window:GetParent()) end
	end

	local dsp = vgui.Create("DScrollPanel", window )
	local sbar = dsp:GetVBar()
	function sbar:Paint(w, h)end
	function sbar.btnUp:Paint(w, h) end
	function sbar.btnDown:Paint(w, h) end
	function sbar.btnGrip:Paint(w, h) end
	dsp:SetSize(window_width/2,365)
	dsp:SetPos(window_width/2,0)

	local cy = 0
	for i=1, #checkboxes do
		local checkbox = dsp:Add( "DCheckBoxLabel" )
		checkbox:SetPos( 0, cy)
		checkbox:SetText(checkboxes[i].Text)
		checkbox:SetConVar(checkboxes[i].ConVar)
		checkbox:SetFont("player_menu_title")
		cy = cy + 16
	end
end)

local function createNameChangeUI(window_name, placeholder_text, current_name, submit_function)
	local window = create_window(window_name, 200, 100, true)
	local name_input = vgui.Create( "DTextEntry", window )
	local name_display = vgui.Create( "DLabel", window )
	local name_markup = ec_markup.Parse(current_name)

	local on_click = function()
		submit_function(name_input:GetText())
		window:GetParent():Close()
	end

	name_input:SetPlaceholderText(placeholder_text)
	name_input:SetText(current_name)
	name_input:RequestFocus()
	name_input:Dock( TOP )
	name_input.OnEnter = on_click
	name_input.OnChange = function()
		name_markup = ec_markup.Parse(name_input:GetText())
	end

	name_display:Dock( FILL )
	name_display:SetText("")
	function name_display:Paint(w, h)
		name_markup:Draw(w/2-name_markup:GetWide()/2, h/6)
	end

	local name_submit = create_button(FSB.Translate("set"), 0,0,0,1, window)
	name_submit:Dock( BOTTOM )
	name_submit.DoClick = on_click
end

concommand.Add("setnamegui", function()
	local local_player = LocalPlayer()
	createNameChangeUI(FSB.Translate("player_name"), FSB.Translate("new_name"), local_player:GetRichName(), function (text)
		local_player:SetName(text)
	end)
end)
concommand.Add("setnametaggui", function()
	local local_player = LocalPlayer()
	createNameChangeUI(FSB.Translate("player_nametag"), FSB.Translate("new_tag"), local_player:GetNameTag(), function (text)
		local_player:SetNameTag(text)
	end)
end)

hook.Add("InitPostEntity", "advertise_f2_menu", function()
	chat.AddText(FSB.Translate("pi_menu.advert"))
end)

