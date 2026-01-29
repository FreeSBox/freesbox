
local min_time = 60*60*20

hook.Add("CanArmDupe", "limit_duplicator", function (ply)
	local playtime = ply:GetUTimeTotalTime()
	if playtime < min_time then
		if CLIENT then
			chat.AddText(Color(255,0,0), string.format(FSB.Translate("cant_use_yet"), (min_time-playtime)/60/60))
		end
		return false
	end
end)
