
-- `FSB` as in Free SandBox, not Федеральная Служба Безопасности...
---@class FSB
FSB = FSB or {}

--Store the original functions between file reloads.
FSB.HOOKS = FSB.HOOKS or {}

local shared_files = file.Find("fsb/*.lua", "LUA")
local server_files = file.Find("fsb/server/*.lua", "LUA")
local client_files = file.Find("fsb/client/*.lua", "LUA")

for _, file in ipairs(shared_files) do
		include("fsb/" .. file)
		AddCSLuaFile("fsb/" .. file)
end

if SERVER then
	for _, file in ipairs(server_files) do
		include("fsb/server/" .. file)
	end
	for _, file in ipairs(client_files) do
		AddCSLuaFile("fsb/client/" .. file)
	end
else
	for _, file in ipairs(client_files) do
		include("fsb/client/" .. file)
	end
end

print("FreeSBox initialized.")

-- Load clientside extensions
if CLIENT then
	local lua_files = file.Find("fsb/*.lua", "LuaMenu")
	local lua_client_files = file.Find("fsb/client/*.lua", "LuaMenu")
	local addon_files = file.Find("lua/fsb/*.lua", "THIRDPARTY")
	local addon_client_files = file.Find("lua/fsb/client/*.lua", "THIRDPARTY")

	for _, file in ipairs(lua_files) do
		include("fsb/" .. file)
	end
	for _, file in ipairs(lua_client_files) do
		include("fsb/client/" .. file)
	end

	for _, file in ipairs(addon_files) do
		include("fsb/" .. file)
	end
	for _, file in ipairs(addon_client_files) do
		include("fsb/client/" .. file)
	end

	print("Custom client side lua scripts loaded")
end
