
hook.Add("CanArmDupe", "limit_duplicator", function (ply)
	if ply:GetUTimeTotalTime() < 60*60*20 then
		return false
	end
end)
