---People keep trying to use chat commands, explain them what they should do instead.

local chatcmds =
{
	["+drop"] = "chatcmd.use_console_dumbass",
	["!build"] = "chatcmd.custom_build_on_server",
}

hook.Add("PlayerSay", "explain_commands", function (sender, text, teamChat)
	if sender ~= LocalPlayer() then return end

	text = string.Trim(text)
	text = string.lower(text)

	local explanation = chatcmds[text]
	if explanation then
		chat.AddText(FSB.Translate(explanation))
		return ""
	end
end)
