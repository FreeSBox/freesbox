---@diagnostic disable: inject-field

if SERVER then
	util.AddNetworkString("on_screen_timer")

	---Runs `FSB.CreateTimer` on all clients.
	---@param start_time number
	---@param end_time number
	---@param translation_label string
	function FSB.BroadcastTimer(start_time, end_time, translation_label)
		net.Start("on_screen_timer")
			net.WriteBool(false) --stoptimer.
			net.WriteFloat(start_time)
			net.WriteFloat(end_time)
			net.WriteString(translation_label)
		net.Broadcast()
	end

	function FSB.StopTimer()
		net.Start("on_screen_timer")
			net.WriteBool(true) --stoptimer.
		net.Broadcast()
	end

else

	local timer = {
		panel = nil,
		bar = nil,

		start_time = 0,
		end_time = 0,
		label_text = nil,
	}

	---Creates a progress bar on the screen that goes down as the time runs out.
	---**Only 1 timer can exist at a time.**
	---@param start_time number
	---@param end_time number
	---@param translation_label string
	function FSB.CreateTimer(start_time, end_time, translation_label)
		if timer.panel then
			timer.panel:Remove()
			timer.bar:Remove()
		end

		timer.panel = vgui.Create("DPanel")
		local screen_width, screen_height = ScrW(), ScrH()
		timer.panel:SetWidth(screen_width/3)
		timer.panel:SetPos(screen_width/2-timer.panel:GetWide()/2, screen_height/3)

		timer.bar = timer.panel:Add("DProgress")
		timer.bar:Dock(FILL)

		timer.start_time = start_time
		timer.end_time = end_time
		timer.label_text = translation_label

		local og_paint = timer.bar.Paint
		timer.bar.Paint = function (self, width, height)

			-- This handles drawing the actual progress bar.
			og_paint(self, width, height)

			local cur_time = CurTime()
			local time_left = end_time-cur_time

			if time_left <= 0 then
				timer.panel:Remove()
				timer.bar:Remove()
				return
			end

			local formatted_text = string.format(FSB.Translate(timer.label_text), time_left)
			surface.SetFont("CloseCaption_Bold")
			surface.SetTextColor(0,0,0)
			local text_w, text_h = surface.GetTextSize(formatted_text)
			surface.SetTextPos(width/2-text_w/2, 0)
			surface.DrawText(formatted_text)

			timer.bar:SetFraction(math.TimeFraction(timer.end_time, timer.start_time, cur_time))
		end

	end

	net.Receive("on_screen_timer", function(len, ply)
		if net.ReadBool() then
			FSB.StopTimer()
			return
		end

		local start_time = net.ReadFloat()
		local end_time = net.ReadFloat()
		local label_text = net.ReadString()

		FSB.CreateTimer(start_time, end_time, label_text)
	end)


	function FSB.StopTimer()
		if timer.panel == nil then return end
		timer.panel:Remove()
		timer.bar:Remove()
	end
end

