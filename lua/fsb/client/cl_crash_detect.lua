
local TIMEOUT_TIME = 0.5
local MAX_MESSAGE_LENGH = 512-64 -- Reserve 64 bytes for other data.
local CHAT_RELAY_ADDRESS = "92.38.92.194:8765"

local function wsConnectionSuccess()
	chat.AddText(FSB.Translate("ws_chat.connected"))
end
local function wsConnectionClosed(reason)
	chat.AddText(FSB.Translate("ws_chat.disconnected", reason))
end

local function wsConnectionError(error)
	chat.AddText(FSB.Translate("ws_chat.error"))
end

local function wsRecievedMessage(message)
	chat.AddText(Color(102, 230, 255), "[WS] ", Color(255,255,255), message)
end

local crash_chat_panel
local function initCrashChat()
	assert(crash_chat_panel == nil, "Creating crash chat when it already exists")
	crash_chat_panel = vgui.Create("DHTML", GetHUDPanel())
	crash_chat_panel:Dock(FILL)
	crash_chat_panel:SetHTML("")

	crash_chat_panel.OnDocumentReady = function (self, url)
		crash_chat_panel:AddFunction("gmod", "connectionSuccess", wsConnectionSuccess)
		crash_chat_panel:AddFunction("gmod", "connectionClosed", wsConnectionClosed)
		crash_chat_panel:AddFunction("gmod", "connectionError", wsConnectionError)
		crash_chat_panel:AddFunction("gmod", "recievedMessage", wsRecievedMessage)

		crash_chat_panel:QueueJavascript([[
			console.log("UserAgent", navigator.userAgent);
			console.log("WebSocket", WebSocket);
			const socket = new WebSocket("ws://]] .. CHAT_RELAY_ADDRESS .. [[");
			socket.onopen = gmod.connectionSuccess;
			socket.onclose = function(event) {
				gmod.connectionClosed(event.reason);
			};
			socket.onerror = gmod.connectionError;
			socket.onmessage = function(event) {
				const message = event.data;
				gmod.recievedMessage(message);
			};

			function sendMessage(message)
			{
				socket.send(message);
			}
		]])

		chat.AddText("Crash chat created panel")

		hook.Add("ECShouldSendMessage", "crash_chat_send", function (msg)
			if #msg >= MAX_MESSAGE_LENGH then
				chat.AddText(Color(255,0,0), FSB.Translate("ws_chat.too_long", #msg, MAX_MESSAGE_LENGH))
				return false
			end
			crash_chat_panel:QueueJavascript(string.format(
				"sendMessage('%s<stop>: %s')",
				string.JavascriptSafe(LocalPlayer():RichName()),
				string.JavascriptSafe(msg)
			))
		end)
	end
end

local function destroyCrashChat()
	if crash_chat_panel then
		crash_chat_panel:Remove()
		crash_chat_panel = nil
	end
	hook.Remove("ECShouldSendMessage", "crash_chat_send")
end

hook.Add("FSBTimingOut", "fsb_timeout_actions", function (is_timing_out)
	if is_timing_out then
		FSB.EnableFreecam()
		initCrashChat()
		chat.AddText(Color(255,0,0), FSB.Translate("lag.timing_out"))
	else
		FSB.DisableFreecam()
		destroyCrashChat()
	end
end)

local was_timing_out = false
hook.Add("StartCommand", "init_crash_detect", function (ply, ucmd)
	hook.Remove("StartCommand", "init_crash_detect")

	-- Will only apply on the next join.
	-- But it's better then assuming the player has enough timeout time.
	RunConsoleCommand("cl_timeout", "600")

	timer.Create("CrashDetect", TIMEOUT_TIME, 0, function ()
		local timing_out, last_ping = GetTimeoutInfo()
		if timing_out then
			if not was_timing_out then
				hook.Run("FSBTimingOut", timing_out)
			end
			was_timing_out = true
			hook.Add("Tick", "is_server_up", function ()
				local timing_out, last_ping = GetTimeoutInfo()
				if timing_out then return end
				hook.Remove("Tick", "is_server_up")
				was_timing_out = timing_out
				hook.Run("FSBTimingOut", timing_out)
			end)
		end
	end)
end)
