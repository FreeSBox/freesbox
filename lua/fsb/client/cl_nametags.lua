-- https://gist.github.com/Earu/b437be27eb75780f108ac6cad58eecde#file-easychat_nametags-lua-L26

local cl_nametags_enable = CreateClientConVar("cl_nametags_enable", "1", true)
local cl_nametags_localplayer = CreateClientConVar("cl_nametags_localplayer", "1", true)

surface.CreateFont("NameTagFont", { font = "Roboto Bold", extended = true, size = 180, weight = 880, blursize = 0.5, additive = false })
surface.CreateFont("NameTagShadowFont", { font = "Roboto Bold", extended = true, size = 180, weight = 880, blursize = 5 })
surface.CreateFont("AFKFont", { font = "Roboto Bold", extended = true, size = 100, weight = 880, blursize = 0.5, additive = false })
surface.CreateFont("AFKShadowFont", { font = "Roboto Bold", extended = true, size = 100, weight = 880, blursize = 5 })

local nametag = {
	Nick = "",
	DefaultColor = color_white,
	Markup = nil,
	NameTag = "",
	MarkupTag = nil
}

function nametag:ParseNick(ply)
	local team_col, nick, nametag = team.GetColor(ply:Team()), ply:RichName(), ply:GetNameTag()
	if nick ~= self.Nick or team_col ~= self.DefaultColor or not self.Markup then
		self.Markup = ec_markup.AdvancedParse(nick, {
			nick = true,
			default_color = team_col,
			default_font = "NameTagFont",
			default_shadow_font = "NameTagShadowFont",
			shadow_intensity = 1,
		})
		self.DefaultColor = team_col
		self.Nick = nick
	end
	if nametag ~= self.NameTag or not self.MarkupTag then
		self.MarkupTag = ec_markup.AdvancedParse(nametag, {
			default_color = color_white,
			default_font = "AFKFont",
			default_shadow_font = "AFKShadowFont",
			shadow_intensity = 1,
		})
		self.NameTag = nametag
	end
end

function nametag:Draw(ply)
	self:ParseNick(ply)

	self.Markup:SetPos(-self.Markup:GetWide() / 2, 0)
	self.MarkupTag:SetPos(-self.MarkupTag:GetWide() / 2, 165)

	--render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	--render.PushFilterMin(TEXFILTER.ANISOTROPIC)
	self.Markup:Draw()
	self.MarkupTag:Draw()
	--render.PopFilterMag()
	--render.PopFilterMin()
end

-- actual drawing after this
local player_GetAll, ipairs, LocalPlayer = _G.player.GetAll, _G.ipairs, _G.LocalPlayer
local IsValid, EyeAngles, Vector = _G.IsValid, _G.EyeAngles, _G.Vector

local cam_Start3D2D, cam_End3D2D = _G.cam.Start3D2D, _G.cam.End3D2D
local draw_SimpleText = _G.draw.SimpleText
local table_copy = _G.table.Copy

-- Reset tags for live reloading.
for _, ply in ipairs(player_GetAll()) do
	if ply.Nametag ~= nil then
		ply.Nametag = nil
	end
end

---@param lp Player
---@param local_pos Vector
---@param ply Player
local function shouldRender(lp, local_pos, ply)
	if lp == ply and ( not lp:ShouldDrawLocalPlayer() or not cl_nametags_localplayer:GetBool() ) then return false end
	if ply:IsDormant() then return false end
	if ply:Crouching() then return false end
	if ply:InVehicle() then return false end
	if local_pos:DistToSqr(ply:GetPos()) > 5000 * 5000 then return false end

	return true
end

---@param ply Player
local function getOverheadPos(ply)
	local bone = 6
	local pos = ply:GetBonePosition(bone) or ply:EyePos()

	if not ply:GetBoneName(bone):lower():find("head") and ply:GetBoneCount() >= bone then
		for i = 1, ply:GetBoneCount() do
			if ply:GetBoneName(i):lower():find("head") then
				pos = ply:GetBonePosition(i)
				bone = i
			end
		end
	end

	if not ply:Alive() then
		local rag = ply:GetRagdollEntity()
		if IsValid(rag) then
			pos = rag:GetBonePosition(bone)
		end
	end

	return pos
end

local function createNewNametag(ply)
	local nt = table_copy(nametag)
	ply.Nametag = nt
end

hook.Add("PrePlayerDraw", "player_name_tags", function(ply, flags)
	if not cl_nametags_enable:GetBool() then return end
	local lp = LocalPlayer()
	local local_pos = lp:GetPos()
	if not shouldRender(lp, local_pos, ply) then return end
	local pos = getOverheadPos(ply)
	if pos then
		local ang = EyeAngles()
		ang:RotateAroundAxis(ang:Right(), 90)
		ang:RotateAroundAxis(ang:Up(), -90)
		local scale = ply:GetModelScale() * 0.03
		scale = scale < 0.01 and 0.01 or scale > 5 and 5 or scale
		cam_Start3D2D(pos + Vector(0, 0, 18), ang, scale)
			-- create a nametag object for each player
			if not ply.Nametag then
				createNewNametag(ply)
			end

			ply.Nametag:Draw(ply)

			local cur_time = CurTime()
			local timing_out = ply:IsTimingOut()
			if timing_out then
				draw_SimpleText("[ Timing Out ]", "AFKFont", 6, -100, Color(255,0,0), TEXT_ALIGN_CENTER)
			end
			local focus_loss_time = ply:GetFocusLossTime()
			if not timing_out and focus_loss_time ~= 0 then
				local afk_time = cur_time-focus_loss_time
				local afk_time_table = string.FormattedTime(afk_time)
				local text = ""
				if afk_time_table.h == 0 then
					text = string.format("[ AFK: %02i:%02i ]", afk_time_table.m, afk_time_table.s)
				else
					text = string.format("[ AFK: %02i:%02i:%02i ]", afk_time_table.h, afk_time_table.m, afk_time_table.s)
				end
				draw_SimpleText(text, "AFKFont", 6, -100, HSVToColor(cur_time*16, 1, 1), TEXT_ALIGN_CENTER)
			end
		cam_End3D2D()
	end
end)
