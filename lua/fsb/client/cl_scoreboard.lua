
surface.CreateFont( "ScoreboardHeader", { font = "DermaLarge", extended = true, size = 35, weight = 200, antialias = true, bold = true } )
local nickname_font_size = 20
surface.CreateFont( "Nickname", { font = "Roboto", extended = true, size = nickname_font_size, antialias = true, bold = false } )
--surface.CreateFont("font_scoreboard", {font="Corbel", size=36, weight = 800, antialias=true, extended=true})

-- Keep it local for now, but we may want to make it global at some point.
local scoreboard = 
{
	open = false,
	size = { w=0, h=0 }
}

function scoreboard:Paint(w,h)
	surface.SetDrawColor(24,24,24,255)
	surface.DrawRect(0, 32, w, h)
end

---@return number height height this item's height
function scoreboard:DrawHeader(h,w)
	draw.SimpleText(GetHostName(), "ScoreboardHeader", w / 2, h / 15 / 7, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)
end

function scoreboard:DrawPlayer(ply, pos_x, pos_y, width)
	local closed_height = 34
	local current_height = closed_height
	surface.SetDrawColor(42,42,42,255)
	surface.DrawRect(pos_x, pos_y, width, current_height)

	draw.SimpleText(ply:NameWithoutTags(), "Nickname", pos_x+width/2, pos_y+nickname_font_size/2, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)

	return current_height
end

function scoreboard:Open()
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
	--self.header:SetPos()
	self.header:SetSize(self.size.w, 50)
	self.header:SetText(GetHostName())
	self.header:SetFont("ScoreboardHeader")
	--self.header:Center()
	self.header:Dock( TOP )
	--self.header.Paint = self.DrawHeader

	self.scroll = self.panel:Add("DScrollPanel")
	self.scroll:Dock( FILL )

	for _, player in ipairs(player.GetAll()) do
		local player_btn = self.scroll:Add("DButton")
		player_btn:Dock(TOP)
		player_btn:SetText(player:GetName())
		player_btn:SetSize(0, 32)
		local avatar = player_btn:Add("AvatarImage")
		avatar:SetSize(32,32)
		avatar:Dock(LEFT)
		avatar:SetPlayer(player, 32)
	end

end

function scoreboard:Close()
	self.open = false
	self.panel:SetVisible(false)
	self.panel:Remove()

	gui.EnableScreenClicker(false)
end

function scoreboard:IsOpen()
	return self.open
end

hook.Add("KeyPress", "ScoreboardToggleMouse", function( ply, key )
	if key == IN_ATTACK2 and scoreboard:IsOpen() then
		gui.EnableScreenClicker(true)
	end
end)

function GAMEMODE:ScoreboardShow()
	scoreboard:Open()
end

function GAMEMODE:ScoreboardHide()
	scoreboard:Close()
end
