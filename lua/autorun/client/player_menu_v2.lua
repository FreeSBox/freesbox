---@diagnostic disable: inject-field

local buttons =  {
	{ Text=FTranslate("vote.petitions"), Func=function(menu) RunConsoleCommand("vote") menu:Close() end },
	{ Text=FTranslate("rules"), Func=function(menu) RunConsoleCommand("rules") menu:Close() end },
}

local checkboxes = {
	{Text=FTranslate("pi_menu.no_render_on_lost_focus"), ConVar="cl_disable_render_on_focus_loss" },
	{Text=FTranslate("pi_menu.enable_auto_jump"), ConVar="auto_jump" },
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
	gui.EnableScreenClicker(true)
	menu:ShowCloseButton(true)
	menu:Center()
	if is_popup then menu:MakePopup() end
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
	local window_width = 600
	local window_hight = 400
	local window = create_window(FTranslate("pi_menu.title"), window_width, window_hight, false)

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

