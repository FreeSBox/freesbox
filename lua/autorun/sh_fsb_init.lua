
-- `FSB` as in Free SandBox, not Федеральная Служба Безопасности...
---@class FSB
FSB = FSB or {}

local shared_files = {
	"fsb/sh_anti_noclip_pvp.lua",
	"fsb/sh_limit_duplicator.lua",
	"fsb/sh_custom_name.lua",
	"fsb/sh_dont_tool_players.lua",
	"fsb/sh_has_focus.lua",
	"fsb/sh_localization.lua",
	"fsb/sh_netmsg_hook.lua",
	"fsb/sh_on_screen_timer.lua",
	"fsb/sh_playermodels.lua",
	"fsb/sh_playtime.lua",
	"fsb/sh_resources.lua",
	"fsb/sh_rules.lua",
	"fsb/sh_spawnprotect.lua",
	"fsb/sh_timing_out.lua",
	"vote/sh_vote.lua",
}

local server_files = {
	"fsb/server/sv_anti_net_msg_spam.lua",
	"fsb/server/sv_cleanup.lua",
	"fsb/server/sv_crash_detect.lua",
	"fsb/server/sv_gcc_exploit_radhat.lua",
	"fsb/server/sv_infammo.lua",
	"fsb/server/sv_lagdetect.lua",
	"fsb/server/sv_performance.lua",
	"fsb/server/sv_player_menu_v2.lua",
	"fsb/server/sv_remove_restrictions.lua",
	"fsb/server/sv_servershutdown.lua",
	"fsb/server/sv_skyboxprotect.lua",
	"fsb/server/sv_workshop_dl.lua",
	"fsb/server/sv_weapon_drop.lua",
}

local client_files ={
	"fsb/client/cl_concommands_v2.lua",
	"fsb/client/cl_gcc_exploit_radhat.lua",
	"fsb/client/cl_nametags.lua",
	"fsb/client/cl_player_menu_v2.lua",
	"fsb/client/cl_rules.lua",
	"fsb/client/cl_freecam.lua",
	"fsb/client/cl_crash_detect.lua",
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
