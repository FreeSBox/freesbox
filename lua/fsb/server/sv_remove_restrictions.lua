if util.IsBinaryModuleInstalled("remove_restrictions") then
	--Load this binary module: https://github.com/FreeSBox/gmsv_remove_restrictions
	require("remove_restrictions")
else
	MsgN("gmsv_remove_restrictions is not installed, shutdown will not work properly")
end
