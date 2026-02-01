
local MIN_TIME = 60*60*20

hook.Add("CanArmDupe", "limit_duplicator", function (ply)
	local playtime = ply:GetUTimeTotalTime()
	if playtime < MIN_TIME then
		if CLIENT then
			chat.AddText(Color(255,0,0), string.format(FSB.Translate("cant_use_yet"), (MIN_TIME-playtime)/60/60))
		end
		return false
	end
end)
