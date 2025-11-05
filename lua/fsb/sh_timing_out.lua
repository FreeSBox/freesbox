
if SERVER then
	timer.Create("update_timing_out", 0.5, 0, function ()
		for index, value in ipairs(player.GetHumans()) do
			value:SetNWBool("TimingOut", value:IsTimingOut())

		end
	end)
else
	---@class Player
	local PLAYER = FindMetaTable("Player")
	---@return boolean
	function PLAYER:IsTimingOut()
		return self:GetNWBool("TimingOut")
	end
end