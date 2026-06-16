
local FONT = "TargetID"
local HEALTH_FONT = "TargetIDSmall"

--Facepunch code below, not GPL licensed
hook.Add("HUDDrawTargetID", "render_player_tag", function ()
	local trace = LocalPlayer():GetEyeTrace()
	if not trace.Hit then return end
	if not trace.HitNonWorld then return end
	local ent = trace.Entity
	if not ent then return end
	if not ent:IsPlayer() then return end

	local nick = trace.Entity:GetName()
	surface.SetFont(FONT)
	local w, h = surface.GetTextSize(nick)

	local mouse_x, mouse_y = input.GetCursorPos()

	if (mouse_x == 0 and mouse_y == 0) or not vgui.CursorVisible() then
		mouse_x = ScrW() / 2
		mouse_y = ScrH() / 2
	end

	local x = mouse_x
	local y = mouse_y

	x = x - w / 2
	y = y + 30

	-- The fonts internal drop shadow looks lousy with AA on
	draw.SimpleText(nick, FONT, x + 1, y + 1, Color(0, 0, 0, 120))
	draw.SimpleText(nick, FONT, x + 2, y + 2, Color(0, 0, 0, 50))
	draw.SimpleText(nick, FONT, x, y, GAMEMODE:GetTeamColor(ent))

	y = y + h + 5

	-- Draw the health
	local text = ent:InPVPMode() and ent:Health() .. "%" or "BUILD"

	surface.SetFont(HEALTH_FONT)
	w, h = surface.GetTextSize(text)
	x = mouse_x - w / 2

	draw.SimpleText(text, HEALTH_FONT, x + 1, y + 1, Color(0, 0, 0, 120))
	draw.SimpleText(text, HEALTH_FONT, x + 2, y + 2, Color(0, 0, 0, 50))
	draw.SimpleText(text, HEALTH_FONT, x, y, GAMEMODE:GetTeamColor(ent))

	return false
end)
