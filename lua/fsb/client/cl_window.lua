---@diagnostic disable: inject-field

---@param name string
---@param size_x number
---@param size_y number
---@param is_popup boolean
---@return DFrame
function FSB.CreateWindow(name, size_x, size_y, is_popup)
	local menu = vgui.Create("DFrame")
	menu:SetSize(size_x, size_y)
	menu:SetSizable(true)
	menu:SetTitle("")
	menu:SetKeyboardInputEnabled(true)
	menu:ShowCloseButton(true)
	menu:Center()
	if is_popup then menu:MakePopup() end
	surface.SetFont("player_menu_title")
	local name_size_x = surface.GetTextSize(name)
	function menu:Paint(w,h)
		draw.RoundedBox(4, 0, 0, w - 2, h - 2, Color(26, 26, 26))

		if name_size_x >= size_x/2 then
			draw.DrawText(name, "player_menu_title", 0, 5, Color(219, 219, 219), TEXT_ALIGN_LEFT)
		else
			draw.DrawText(name, "player_menu_title", size_x/2, 5, Color(219, 219, 219), TEXT_ALIGN_CENTER)
		end
	end

	return menu
end
