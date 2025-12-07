---@diagnostic disable: inject-field

concommand.Add("rules", function()
	local window_width = 800
	local window_hight = 600
	local window = FSB.CreateWindow(FSB.Translate("rules"), window_width, window_hight, true)

	local html = window:Add("DHTML")
	html:Dock(FILL)
	html:SetHTML(FSB.GetResource("rules.html"))
	html.OnDocumentReady = function (self, url)
		html:AddFunction("gmod", "OpenURL", gui.OpenURL)
	end

end)
