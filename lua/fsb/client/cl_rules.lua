---@diagnostic disable: inject-field

local function createWindow(name, size_x, size_y, is_popup)
	local menu = vgui.Create("DFrame")
	menu:SetSize(size_x, size_y)
	menu:SetSizable(true)
	menu:SetTitle("")
	menu:SetKeyboardInputEnabled(true)
	menu:ShowCloseButton(true)
	menu:Center()
	if is_popup then menu:MakePopup() end
	function menu:Paint(w,h)
		draw.RoundedBox(4, 0, 0, w - 2, h - 2, Color(26, 26, 26))
		draw.DrawText(name, "player_menu_title", size_x/2, 5, Color(219, 219, 219), TEXT_ALIGN_CENTER)
	end

	return menu
end

concommand.Add("rules", function()
	local window_width = 800
	local window_hight = 600
	local window = createWindow(FSB.Translate("rules"), window_width, window_hight, true)

	local html = window:Add("DHTML")
	html:Dock(FILL)
	html:SetHTML(FSB.GetResource("rules.html"))
	html.OnDocumentReady = function (self, url)
		html:AddFunction("gmod", "OpenURL", gui.OpenURL)
	end

end)
