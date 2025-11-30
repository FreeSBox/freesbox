
local SysTime = SysTime

---@param limit_table table A table that is used to store all identifiers.
---@param identifier any A unique identifier, every identifier has it's own interval.
---@param interval number Interval in seconds.
---@return boolean interval_passed Will return true, the first time this function is called, then false for the specified ammount of seconds, then true again.
function FSB.Ratelimit(limit_table, identifier, interval)
	local ratelimit = limit_table[identifier]
	if ratelimit == nil then
		limit_table[identifier] = SysTime()
		return true
	elseif ratelimit+interval <= SysTime() then
		limit_table[identifier] = SysTime()
		return true
	end

	return false
end
