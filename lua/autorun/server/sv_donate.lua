require("chttp")
local aeza_token = "ac2c9061003cf6150b4c6bf486fc41e6"
local aeza_service = 669329

--TODO
--CreateConVar("aeza_get_service_id_from_server_ip", "0", FCVAR_ARCHIVE, "Should we try to get the aeza service from our IP address or just use the hardcoded one")

local current_balance
local server_info = {
	month_price,
	expires_at
}
local compressed_methods

CHTTP( {
	failed = function( reason )
		print( "HTTP request failed", reason )
	end,
	success = function( code, body, headers )
		local body_table = util.JSONToTable(body)
		server_info.expires_at = body_table.data.items[1].timestamps.expiresAt
		server_info.month_price = body_table.data.items[1].individualPrices.month
	end,
	method = "GET",
	headers = {
		["X-API-Key"] = aeza_token
	},
	url = "https://my.aeza.net/api/services/" .. tostring(aeza_service),
	type = "application/json"
})
CHTTP( {
	failed = function( reason )
		print( "HTTP request failed", reason )
	end,
	success = function( code, body, headers )
		local body_table = util.JSONToTable(body)
		current_balance = body_table.data.rawBalance
	end,
	method = "GET",
	headers = {
		["X-API-Key"] = aeza_token
	},
	url = "https://my.aeza.net/api/desktop",
	type = "application/json"
})
CHTTP( {
	failed = function( reason )
		print( "HTTP request failed", reason )
	end,
	success = function( code, body, headers )
		compressed_methods = util.Compress(body)
	end,
	method = "GET",
	headers = {
		["X-API-Key"] = aeza_token
	},
	url = "https://my.aeza.net/api/payment/methods",
	type = "application/json"
})



util.AddNetworkString("aeza_donate")
util.AddNetworkString("aeza_invoice")
util.AddNetworkString("aeza_server_info")
util.AddNetworkString("aeza_payment_methods")
util.AddNetworkString("aeza_request_server_info")
util.AddNetworkString("aeza_request_payment_methods")

local function send_server_info(ply)
	if(current_balance ~= nil or server_info.month_price ~= nil or server_info.expires_at ~= nil) then
		net.Start("aeza_server_info")
			net.WriteInt(server_info.month_price, 16)
			net.WriteInt(50, 16)
			net.WriteUInt(server_info.expires_at, 32)
		net.Send(ply)
	end
end
net.Receive("aeza_request_server_info", function(len, ply)
	send_server_info(ply)
end)

local function send_payment_methods(ply)
	if(compressed_methods ~= nil) then
		net.Start("aeza_payment_methods")
			net.WriteUInt(#compressed_methods, 16)
			net.WriteData(compressed_methods)
		net.Send(ply)
	end
end
net.Receive("aeza_request_payment_methods", function(len, ply)
	send_payment_methods(ply)
end)


local function send_invoice_to_client(ply, invoice_table)
	if invoice_table.data ~= nil then
		local url = invoice_table.data.transaction.invoice.link
		net.Start("aeza_invoice")
			net.WriteString(url)
		net.Send(ply)
	else
		ply:ChatPrint(invoice_table.error)
	end
end
local function create_invoice(method, amount, ply)
	CHTTP( {
		failed = function( reason )
			print( "HTTP request failed", reason )
		end,
		success = function( code, body, headers )
			local body_table = util.JSONToTable(body)
			PrintTable(body_table)
			send_invoice_to_client(ply, body_table)
		end,
		body = util.TableToJSON({
			["method"] = method,
			["amount"] = amount
		}),
		method = "POST",
		headers = {
			["X-API-Key"] = aeza_token,
			["Content-Type"] = "application/json"
		},
		url = "https://my.aeza.net/api/payment/invoices",
		type = "application/json"
	})
end
net.Receive("aeza_donate", function(len, ply)
	local amount = net.ReadUInt(24)
	local method = net.ReadString()

	create_invoice(method, amount, ply)
end)