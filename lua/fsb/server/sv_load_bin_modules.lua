if util.IsBinaryModuleInstalled("remove_restrictions") then
	--Load this binary module: https://github.com/FreeSBox/gmsv_remove_restrictions
	require("remove_restrictions")
else
	MsgN("gmsv_remove_restrictions is not installed, shutdown will not work properly")
end

if util.IsBinaryModuleInstalled("kill_on_hang") then
	--Load this binary module: https://github.com/FreeSBox/gmsv_kill_on_hang
	require("kill_on_hang")
else
	MsgN("gmsv_kill_on_hang is not installed, if the server hangs it will remain this way until you notice")
end

