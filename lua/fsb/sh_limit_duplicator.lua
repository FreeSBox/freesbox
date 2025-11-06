
local min_time = 60*60*20

hook.Add("CanArmDupe", "limit_duplicator", function (ply)
	local playtime = ply:GetUTimeTotalTime()
	if playtime < min_time then
		if SERVER then
			ply:SendLocalizedMessage("cant_use_yet", (min_time-playtime)/60/60)
		end
		return false
	end
end)
