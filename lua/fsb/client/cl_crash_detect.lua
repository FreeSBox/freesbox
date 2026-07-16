
local TIMEOUT_TIME = 0.5
local MAX_MESSAGE_LENGH = 512-64 -- Reserve 64 bytes for other data.
local CHAT_RELAY_ADDRESS = "http://92.38.92.194/chat/"

local function chatConnectionSuccess()
	chat.AddText(FSB.Translate("http_chat.connected"))
end

local post_crash_chat_active = false
local messages = {}
local latest_time = 0
local function parseChatJSON(message)
	local msgs = util.JSONToTable(message, false, false)
	for index, msg in ipairs(msgs) do
		if msg.time > latest_time then
			latest_time = msg.time
		end
		if messages[msg.id] == nil then
			assert(isnumber(msg.id), "Message id not a number")
			messages[msg.id] = msg
			chat.AddText(Color(102, 230, 255), "[HTTP] ", Color(255,255,255), msg.author, ": ", msg.text)
		end
	end

	-- Remove old messages
	messages = {}
	for _, msg in ipairs(msgs) do
		messages[msg.id] = msg
	end
end

local crash_chat_panel
local function initCrashChat()
	timer.Create("pull_crash_messages", 0.5, 0, function ()
		HTTP{
			method="GET",
			url=CHAT_RELAY_ADDRESS,
			success=function (code, body, headers)
				if code == 200 then
					parseChatJSON(body)
					if not post_crash_chat_active then
						post_crash_chat_active = true
						chatConnectionSuccess()
					end
				end
			end,
			failed=function(error)
				print("Reading failed", error)
			end
		}
	end)
	hook.Add("ECShouldSendMessage", "crash_chat_send", function (msg)
		if #msg >= MAX_MESSAGE_LENGH then
			chat.AddText(Color(255,0,0), FSB.Translate("http_chat.too_long", #msg, MAX_MESSAGE_LENGH))
			return false
		end
		HTTP{
			method="POST",
			url=CHAT_RELAY_ADDRESS,
			body=util.TableToJSON({author = LocalPlayer():RichName(), text = msg}, false),
			success=function() end,
			failed=function(error)
				print("Sending failed", error)
			end
		}
	end)
end

local function destroyCrashChat()
	if crash_chat_panel then
		crash_chat_panel:Remove()
		crash_chat_panel = nil
	end
	timer.Remove("pull_crash_messages")
	hook.Remove("ECShouldSendMessage", "crash_chat_send")
	post_crash_chat_active = false
end

hook.Add("FSBTimingOut", "fsb_timeout_actions", function (is_timing_out)
	print("FSBTimingOut", is_timing_out)
	if is_timing_out then
		FSB.EnableFreecam()
		initCrashChat()
		chat.AddText(Color(255,0,0), FSB.Translate("lag.timing_out"))
	else
		FSB.DisableFreecam()
		destroyCrashChat()
	end
end)

--This must not be inside a hook or it will not apply
RunConsoleCommand("cl_timeout", "600")

local was_timing_out = false
hook.Add("StartCommand", "init_crash_detect", function (ply, ucmd)
	hook.Remove("StartCommand", "init_crash_detect")

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
