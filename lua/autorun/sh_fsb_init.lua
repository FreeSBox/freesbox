
-- `FSB` as in Free SandBox, not Федеральная Служба Безопасности...
---@class FSB
FSB = FSB or {}

--Store the original functions between file reloads.
FSB.HOOKS = FSB.HOOKS or {}

local shared_files = {
	"fsb/sh_buildmode.lua",
	"fsb/sh_custom_name.lua",
	"fsb/sh_dont_tool_players.lua",
	"fsb/sh_ghostban.lua",
	"fsb/sh_has_focus.lua",
	"fsb/sh_localization.lua",
	"fsb/sh_netmsg_hook.lua",
	"fsb/sh_notify.lua",
	"fsb/sh_player_join.lua",
	"fsb/sh_on_screen_timer.lua",
	"fsb/sh_playtime.lua",
	"fsb/sh_ratelimit.lua",
	"fsb/sh_resources.lua",
	"fsb/sh_rules.lua",
	"fsb/sh_spawnprotect.lua",
	"fsb/sh_streaming.lua",
	"fsb/sh_timing_out.lua",
	"vote/sh_vote.lua",
}

local server_files = {
	"fsb/server/sv_anti_net_msg_spam.lua",
	"fsb/server/sv_block_spawn_when_dead.lua",
	"fsb/server/sv_cleanup.lua",
	"fsb/server/sv_findlag.lua",
	"fsb/server/sv_gcc_exploit_radhat.lua",
	"fsb/server/sv_infammo.lua",
	"fsb/server/sv_lagdetect.lua",
	"fsb/server/sv_performance.lua",
	"fsb/server/sv_player_menu_v2.lua",
	"fsb/server/sv_remove_restrictions.lua",
	"fsb/server/sv_servershutdown.lua",
	"fsb/server/sv_skyboxprotect.lua",
	"fsb/server/sv_usergroups.lua",
	"fsb/server/sv_workshop_dl.lua",
	"fsb/server/sv_weapon_drop.lua",
}

local client_files ={
	"fsb/client/cl_advertise.lua",
	"fsb/client/cl_chatcmmands.lua",
	"fsb/client/cl_concommands_v2.lua",
	"fsb/client/cl_gcc_exploit_radhat.lua",
	"fsb/client/cl_nametags.lua",
	"fsb/client/cl_nocensor.lua",
	"fsb/client/cl_owner_joined.lua",
	"fsb/client/cl_player_menu_v2.lua",
	"fsb/client/cl_rules.lua",
	"fsb/client/cl_freecam.lua",
	"fsb/client/cl_crash_detect.lua",
	"fsb/client/cl_scoreboard.lua",
	"fsb/client/cl_window.lua",
}

for index, value in ipairs(shared_files) do
		include(value)
		AddCSLuaFile(value)
end

if SERVER then
	for index, value in ipairs(server_files) do
		include(value)
	end
	for index, value in ipairs(client_files) do
		AddCSLuaFile(value)
	end
else
	for index, value in ipairs(client_files) do
		include(value)
	end
end

print("FreeSBox initialized.")
