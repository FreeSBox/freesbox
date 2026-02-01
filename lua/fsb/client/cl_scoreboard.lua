---@diagnostic disable: inject-field
local T = FSB.Translate

surface.CreateFont( "ScoreboardHeader", { font = "DermaLarge", extended = true, size = 35, weight = 200, antialias = true, bold = true } )
local nickname_font_size = 20
surface.CreateFont( "Nickname", { font = "Roboto", extended = true, size = nickname_font_size, antialias = true, bold = false, additive = true } )
surface.CreateFont( "NicknameShadow", { font = "Roboto", extended = true, size = nickname_font_size, antialias = true, bold = false, blursize = 5 } )
--surface.CreateFont("font_scoreboard", {font="Corbel", size=36, weight = 800, antialias=true, extended=true})

local avatar_size = 32
local player_padding = 4
local player_height = 32 + player_padding*2
local right_info_padding = 10
local collumn_padding = 32

---@class ScoreboardPlayerName
---@field Markup MarkupObject
---@field Nick string
---@field DefaultColor Color

-- Keep it local for now, but we may want to make it global at some point.
local scoreboard =
{
	open = false,
	size = { w=0, h=0 },

	players = {},
	---@type table<integer, ScoreboardPlayerName>
	player_names = {},
	extended_infos = {},

	ent_counts = {},
	ctx_menu = nil,

	player_button_right_info = {
		function (ply, right_pad, w, h) -- ping
			surface.SetTextColor(255,255,255)
			local ping = string.format(T"scoreboard.ping", ply:Ping())
			local ping_x, ping_y = surface.GetTextSize(ping)
			surface.SetTextPos(w-right_pad-ping_x, player_padding)
			surface.DrawText(ping)
			return ping_x
		end,
		function (ply, right_pad, w, h) -- playtime
			surface.SetTextColor(255,255,255)
			local hours = string.format(T"scoreboard.playtime", ply:GetUTimeTotalTime()/60/60)
			local hours_x, hours_y = surface.GetTextSize(hours)
			surface.SetTextPos(w-right_pad-hours_x, player_padding)
			surface.DrawText(hours)
			return hours_x
		end,
	},
}

---@param ply Player
function scoreboard:ParseNick(ply)
	local team_col, nick = team.GetColor(ply:Team()), ply:RichName()
	local name = self.player_names[ply:UserID()]
	if not name or nick ~= name.Nick or team_col ~= name.DefaultColor or not name.Markup then
		name =
		{
			Markup = ec_markup.AdvancedParse(ply:RichNick(),
			{
				nick = true,
				default_color = team_col,
				default_font = "Nickname",
				default_shadow_font = "NicknameShadow",
				shadow_intensity = 2,
			}),
			DefaultColor = team_col,
			Nick = nick,
		}
		self.player_names[ply:UserID()] = name
	end
end

function scoreboard:Paint(w,h)
	surface.SetDrawColor(24,24,24,255)
	surface.DrawRect(0, 32, w, h)
end

function scoreboard:DrawPlayerButtonRightInfo(ply, width, height)
	local offset = player_padding
	for index, value in ipairs(scoreboard.player_button_right_info) do
		offset = value(ply, offset, width, height) + right_info_padding
	end
end

local function updateEntityCount()
	scoreboard.ent_counts = {}
	for k,v in pairs(NADMOD.PropOwners) do 
		scoreboard.ent_counts[v] = (scoreboard.ent_counts[v] or 0) + 1
	end
	local dccount = 0
	for k,v in pairs(scoreboard.ent_counts) do
		if k ~= "World" and k ~= "Ownerless" then dccount = dccount + v end
	end
end

hook.Add("OnEntityCreated", "update_ent_counter", updateEntityCount)
hook.Add("EntityRemoved", "update_ent_counter", updateEntityCount)

---How many network string are registered right now.
---@return integer
function FSB.GetStringTableSize()
	local i = 1
	while true do
		if util.NetworkIDToString(i) == nil then
			break
		end
		i = i + 1
	end
	return i
end

function scoreboard:ReloadPlayers()
	self.players = player.GetAll()
	table.sort(self.players, function (a, b)
		return a:GetUTimeTotalTime() > b:GetUTimeTotalTime()
	end)
end

function scoreboard:ReloadPlayerList()
	for _, old_button in ipairs(self.scroll:GetCanvas():GetChildren()) do
		old_button:Remove()
	end
	for _, player in ipairs(self.players) do
		local player_btn = self.scroll:Add("DButton")
		player_btn:SetName("player_btn")
		player_btn:DockMargin(0,2,0,0)
		player_btn:Dock(TOP)
		player_btn:SetText("")
		player_btn.ply = player
		player_btn:SetSize(0, scoreboard.extended_infos[player:UserID()] and player_height*2 or player_height)
		function player_btn:Paint(w,h)
			if not IsValid(self.ply) then return end
			if self:IsHovered() then
				surface.SetDrawColor(60,60,60,255)
			else
				surface.SetDrawColor(50,50,50,255)
			end
			surface.DrawRect(0, 0, w, h)

			local userid = self.ply:UserID()

			scoreboard:ParseNick(self.ply)
			local markup = scoreboard.player_names[userid].Markup

			markup:Draw(avatar_size+player_padding*2, player_height/2-nickname_font_size/2)

			surface.SetFont("Nickname")
			surface.SetTextPos(avatar_size+player_padding*2+markup:GetWidth(), player_height/2-nickname_font_size/2)
			surface.SetTextColor(255,0,0)

			local focus_loss_time = self.ply:GetFocusLossTime()
			if self.ply:IsTimingOut() then
				surface.DrawText(" | Timing Out")
			elseif focus_loss_time ~= 0 then
				local afk_time = CurTime()-focus_loss_time
				local afk_time_table = string.FormattedTime(afk_time)
				local afk_text
				if afk_time_table.h == 0 then
					afk_text = string.format(" | AFK: %02i:%02i", afk_time_table.m, afk_time_table.s)
				else
					afk_text = string.format(" | AFK: %02i:%02i:%02i", afk_time_table.h, afk_time_table.m, afk_time_table.s)
				end
				surface.DrawText(afk_text)
			end

			scoreboard:DrawPlayerButtonRightInfo(self.ply, w, h)

			if scoreboard.extended_infos[userid] then
				surface.SetTextColor(255,255,255)
				local group = string.format(T"scoreboard.group", self.ply:GetUserGroup())
				local group_x, group_y = surface.GetTextSize(group)
				surface.SetTextPos(player_padding, player_padding*2+avatar_size)
				surface.DrawText(group)

				surface.SetTextColor(255,255,255)
				local num_ents = scoreboard.ent_counts[self.ply:SteamID()]
				num_ents = num_ents or 0
				local num_entities = string.format(T"scoreboard.ent_count", num_ents)
				local num_entities_x, num_entities_y = surface.GetTextSize(num_entities)
				surface.SetTextPos(player_padding, group_y+player_padding*2+avatar_size)
				surface.DrawText(num_entities)

				local second_collumn_x = math.max(group_x, num_entities_x) + collumn_padding

				surface.SetTextColor(255,255,255)
				local frags = self.ply:Frags()
				local frags_text = string.format(T"scoreboard.kill_count", frags)
				local frags_text_x, frags_text_y = surface.GetTextSize(frags_text)
				surface.SetTextPos(player_padding+second_collumn_x, player_padding*2+avatar_size)
				surface.DrawText(frags_text)

				surface.SetTextColor(255,255,255)
				local deaths = self.ply:Deaths()
				local deaths_text = string.format(T"scoreboard.death_count", deaths)
				local deaths_text_x, deaths_text_y = surface.GetTextSize(deaths_text)
				surface.SetTextPos(player_padding+second_collumn_x, frags_text_y+player_padding*2+avatar_size)
				surface.DrawText(deaths_text)
			end
		end
		function player_btn:DoRightClick()
			scoreboard.ctx_menu = DermaMenu()
			scoreboard.ctx_menu:AddOption(T"scoreboard.copy_real_name", function ()
				SetClipboardText(self.ply:GetOriginalName())
			end):SetIcon("icon16/report_user.png")
			scoreboard.ctx_menu:AddOption(T"scoreboard.copy_steamid", function ()
				SetClipboardText(self.ply:SteamID())
			end):SetIcon("icon16/tag_blue.png")
			scoreboard.ctx_menu:AddOption(T"scoreboard.open_profile", function ()
				self.ply:ShowProfile()
			end):SetIcon("icon16/application.png")

			scoreboard.ctx_menu:AddSpacer()

			local slider = vgui.Create( "DSlider", scoreboard.ctx_menu )
			slider:SetSlideX(math.sqrt(self.ply:GetVoiceVolumeScale()))
			function slider:Paint(w,h)
				surface.SetDrawColor(0,255,0)
				surface.DrawRect(0,0, slider:GetSlideX()*w, h)

				surface.SetFont("HudSelectionText")
				surface.SetTextColor(0,0,0)
				local vol = T"scoreboard.voice_volume"
				local size_x, size_y = surface.GetTextSize(vol)
				surface.SetTextPos(w/2-size_x/2,h/2-size_y/2)
				surface.DrawText(vol)
			end
			function slider.Knob:Paint(w,h) end
			function slider.OnValueChanged(self_, x,y)
				--x^2 is pretty bad, but much better then linear, so whatever.
				self.ply:SetVoiceVolumeScale(x^2)
			end

			scoreboard.ctx_menu:Open()
		end
		function player_btn:DoClick()
			local userid = self.ply:UserID()
			local is_open = not scoreboard.extended_infos[userid]
			scoreboard.extended_infos[userid] = is_open
			if is_open then
				player_btn:SetSize(0, player_height*2)
			else
				player_btn:SetSize(0, player_height)
			end
		end
		local avatar = player_btn:Add("AvatarImage")
		avatar:SetSize(avatar_size,avatar_size)
		avatar:SetPos(player_padding,player_padding)
		avatar:SetPlayer(player, avatar_size)
	end
end

function scoreboard:Open()
	if self.open then return end
	if vgui.CursorVisible() then return end

	self.open = true
	self.size = { w = ScrW() / 2.5, h = ScrH() / 1.5 }

	self.panel = vgui.Create( 'DFrame' )
	self.panel:SetSize(self.size.w, self.size.h)
	self.panel:Center()
	self.panel:SetTitle('')
	self.panel:SetDraggable(false)
	self.panel:SetVisible(true)
	self.panel:ShowCloseButton(false)
	self.panel.Paint = self.Paint

	self.header = self.panel:Add("DLabel")
	self.header:SetSize(self.size.w, 50)
	self.header:SetText(GetHostName())
	self.header:SetFont("ScoreboardHeader")
	--self.header:Center()
	self.header:Dock( TOP )

	self:ReloadPlayers()

	self.info = self.panel:Add("DPanel")
	self.info:SetSize(self.size.w, 25)
	self.info:Dock( TOP )
	function self.info:Paint(w,h)
		surface.SetDrawColor(50,50,50,255)
		surface.DrawRect(0, 0, w, h)

		surface.SetTextColor(255,255,255)
		surface.SetFont("Nickname")
		local mspt = GetGlobalFloat("serverMSPT")
		local tps = string.format("TPS: %.1f | MSPT: %.1f", 1000/math.max(engine.TickInterval()*1000, mspt), mspt)
		local tps_x, tps_y = surface.GetTextSize(tps)
		surface.SetTextPos(player_padding, h/2-tps_y/2)
		surface.DrawText(tps)

		surface.SetTextColor(255,255,255)
		surface.SetFont("Nickname")
		local player_count = string.format(T"scoreboard.player_count", #scoreboard.players, game.MaxPlayers())
		local player_count_x, player_count_y = surface.GetTextSize(player_count)
		surface.SetTextPos(w-player_padding-player_count_x, h/2-player_count_y/2)
		surface.DrawText(player_count)
	end

	self.scroll = self.panel:Add("DScrollPanel")
	self.scroll:Dock( FILL )
	updateEntityCount()

	for index, ply in ipairs(self.players) do
		scoreboard.extended_infos[ply:UserID()] = false
	end
	self:ReloadPlayerList()
end

function scoreboard:Close()
	if not self.open then return end

	self.open = false
	self.panel:SetVisible(false)
	self.panel:Remove()

	if scoreboard.ctx_menu then
		scoreboard.ctx_menu:Remove()
		scoreboard.ctx_menu = nil
	end

	gui.EnableScreenClicker(false)
end

function scoreboard:IsOpen()
	return self.open
end

hook.Add("PlayerBindPress", "block_alt_fire_in_tab", function (ply, bind, pressed, code)
	if ply ~= LocalPlayer() then return end
	if string.find(bind, "attack2") and scoreboard:IsOpen() then
		gui.EnableScreenClicker(true)
		return true
	end
end)

hook.Add("StartCommand", "init_scoreboard", function()
	function GAMEMODE:ScoreboardShow()
		scoreboard:Open()
	end

	function GAMEMODE:ScoreboardHide()
		scoreboard:Close()
	end

	hook.Remove("StartCommand", "init_scoreboard")
end)

hook.Add("FSBPlayerJoined", "add_player", function (userid, index, networkid, name)
	if not scoreboard:IsOpen() then return end

	scoreboard:ReloadPlayers()
	scoreboard:ReloadPlayerList()
end)
hook.Add("FSBPlayerLeft", "remove_player", function (userid, index, networkid, name, reason)
	if not scoreboard:IsOpen() then return end

	scoreboard:ReloadPlayers()
	scoreboard.player_names[userid] = nil
	scoreboard.extended_infos[userid] = nil
	scoreboard:ReloadPlayerList()
end)
