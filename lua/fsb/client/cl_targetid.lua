
local FONT = "TargetID"
local HEALTH_FONT = "TargetIDSmall"
local TEXT_OFFSET = 30

hook.Add("HUDDrawTargetID", "render_player_tag", function ()
	local trace = LocalPlayer():GetEyeTrace()
	if not trace.Hit then return end
	if trace.HitWorld then return end
	---@type Player
	---@diagnostic disable-next-line: assign-type-mismatch
	local ply = trace.Entity
	if not ply then return end
	if not ply:IsValid() then return false end -- return false here, or the GAMEMODE code will throw a lua error
	if not ply:IsPlayer() then return end

	local screen_w, screen_h = ScrW(), ScrH()
	local team_color = team.GetColor(ply:Team())

	--Draw name
	surface.SetFont(FONT)
	local name_text = ply:GetName()
	local name_w, name_h = surface.GetTextSize(name_text)
	draw.SimpleText(name_text, FONT, screen_w/2-name_w/2, screen_h/2+TEXT_OFFSET, team_color)

	--Draw health
	surface.SetFont(HEALTH_FONT)
	local health_text = ply:InPVPMode() and ply:Health() .. "%" or "BUILD"
	local health_w, health_h = surface.GetTextSize(health_text)
	draw.SimpleText(health_text, HEALTH_FONT, screen_w/2-health_w/2, screen_h/2+name_h+TEXT_OFFSET, team_color)

	return false
end)
