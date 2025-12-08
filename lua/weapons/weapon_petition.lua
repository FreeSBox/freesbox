---@diagnostic disable: inject-field

AddCSLuaFile()

SWEP.PrintName = "Petition"
SWEP.Author = "Me"
SWEP.Purpose = "A weapon that can show others your petition, press R to set the petition index"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Base = "weapon_base"

SWEP.Primary.TakeAmmo = 0
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Spread = 0
SWEP.Primary.Recoil = 0
SWEP.Primary.Delay = 0
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = "none"
SWEP.DrawAmmo = false

SWEP.ViewModelFlip = false
SWEP.ViewModelFOV = 60
SWEP.ViewModel =  Model("models/postal/c_petition.mdl")
SWEP.WorldModel = Model("models/postal/clipboard.mdl")
SWEP.UseHands = true
SWEP.HoldType = "slam"


function SWEP:SetupDataTables()
	self:NetworkVar("Int",  0, "PetitionIndex")
end

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
	self:SetPetitionIndex(0)
end

function SWEP:Deploy()
	self:SetHoldType(self.HoldType)
end

function SWEP:PrimaryAttack()

end

function SWEP:SecondaryAttack()
end


if SERVER then
	util.AddNetworkString("select_petition_for_swep")
end

net.Receive("select_petition_for_swep", function (len, ply)
	local petition = ply:GetActiveWeapon()
	if petition:GetClass() ~= "weapon_petition" then
		return
	end

	petition:SetPetitionIndex(net.ReadUInt(PETITION_ID_BITS))
end)

local function updatePetition(self, index)
	index = tonumber(index)
	if not index then return end
	net.Start("select_petition_for_swep")
	net.WriteUInt(index, PETITION_ID_BITS)
	net.SendToServer()
end

function SWEP:Reload()
	if SERVER then return end

	if self.SelectionOpen then return end

	self.SelectionOpen = true

	local window = FSB.CreateWindow(FSB.Translate("petition.set_index"), 200, 60, true)
	function window.OnClose()
		self.SelectionOpen = false
	end

	local panel = window:Add("DPanel")
	panel:Dock(FILL)
	function panel:Paint(w,h)
		draw.RoundedBox(2, 0, 0, w, h, Color(30, 30, 30))
	end

	local input = panel:Add("DNumberWang")
	input:Dock(FILL)
	input:SetMin(1)
	input:SetMax(FSB.GetLastPetition())
	input.OnEnter = updatePetition

	local submit = panel:Add("DButton")
	submit:Dock(RIGHT)
	function submit.DoClick()
		updatePetition(self, input:GetValue())
	end
	submit:SetText(FSB.Translate("set"))
end

--#region CLIENT
if SERVER then return end

--#region Paste
-- A utilty for drawing paragraphs on 2d planes (derma, vgui/hud etc..)
-- Original file found at https://gist.github.com/Khubajsn/5482298 (2013)
-- Modified/fixed/updated by ParaPhoenix/Jabami/PyroPhoe
-- Feel free to use/modify/republish

--[[
	Break up a long string into lines <= the mWidth provided
			
	text -> The text to seperate into lines	
	font -> The font you will be using to draw the text
	mWidth -> The maximum width of each line (GetTextSize(n))
--]]
local function toLines(text, font, mWidth)
	surface.SetFont(font)

	local buffer = { }
	local nLines = { }

	for word in string.gmatch(text, "%S+") do
		local w,h = surface.GetTextSize(table.concat(buffer, " ").." "..word)
		if w > mWidth then
			table.insert(nLines, table.concat(buffer, " "))
			buffer = { }
		end
		table.insert(buffer, word)
	end

	if #buffer > 0 then -- If still words to add.
		table.insert(nLines, table.concat(buffer, " "))
	end

	return nLines
end

--[[
	Draw a paragraph. Supports DrawSimpleTextOutlined.
	
	Text -> The text(to-be-paragraphed) to draw
	Font -> The font to use
	mWidth -> The maximum width per line
	Spacing -> the spacing between lines
	X/Y -> X/Y for the drawing. Y will +Spacing on each line
	Color -> The text color
	AlignX/AlignY -> Text alignment. Required however you can modify this if wanted
	oWidth -> The outline width --> Not required but if both provided you will get SimpleTextOutlined
	oColor -> The outline color -^ 
	EDIT: Returns the Y size of the paragraph, so you can put things underneath it by using it as a Y offset.
]]
local function drawMultiLine(text, font, mWidth, spacing, x, y, color, alignX, alignY, oWidth, oColor)
	local mLines = toLines(text, font, mWidth)

	for i,line in pairs(mLines) do
		if oWidth and oColor then
			draw.SimpleTextOutlined(line, font, x, y + (i - 1) * spacing, color, alignX, alignY, oWidth, oColor)
		else
			draw.SimpleText(line, font, x, y + (i - 1) * spacing, color, alignX, alignY)
		end
	end

	return (#mLines - 1) * spacing
	-- return #mLines * spacing
end
--#endregion

local PETITION_SIZE_X = 75
local PETITION_SIZE_Y = 98

surface.CreateFont("PetitionViewmodelFont", { font = "Roboto Bold", extended = true, size = 14, weight = 500, blursize = 0.5, additive = false })
surface.CreateFont("PetitionWorldmodelFont", { font = "Roboto Bold", extended = true, size = 20, weight = 500, blursize = 0.5, additive = false })
local function draw3DPetition(petition, new_pos, new_ang, scale, font, draw_fineprint)
	local size_x = PETITION_SIZE_X*scale
	local size_y = PETITION_SIZE_Y*scale
	cam.Start3D2D( new_pos, new_ang, 0.05*scale )
		draw.RoundedBox(0, 0, 0, size_x, size_y, color_white)
		--draw.DrawText( , "Default", cam_size_x/2, 30, color_black, TEXT_ALIGN_CENTER )
		local y_len = drawMultiLine(petition.name, font, size_x, size_y/14, size_x/2, size_y/16, color_black, TEXT_ALIGN_CENTER)
		if draw_fineprint then
			draw.DrawText(FSB.Translate("petition.open_hint"), "Default", size_x/2, size_y-32, color_black, TEXT_ALIGN_CENTER)
		end
	cam.End3D2D()
end

local OFFSET_VEC = Vector(3.4, -5.8, -3.6)
local OFFSET_ANG = Angle(160, 90, 90)
local CAM_OFFSET_VEC = Vector(OFFSET_VEC.x+3, OFFSET_VEC.y+8, OFFSET_VEC.z-7.6)
local CAM_OFFSET_ANG = Angle(OFFSET_ANG.x+2, OFFSET_ANG.y+1.5, OFFSET_ANG.z+10)

local world_model = ClientsideModel(SWEP.WorldModel)
if world_model then
	world_model:SetNoDraw(true)
	function SWEP:DrawWorldModel()
		local owner = self:GetOwner()
		if (IsValid(owner)) then
			local boneid = owner:LookupBone("ValveBiped.Bip01_R_Hand") -- Right Hand
			if !boneid then return end

			local matrix = owner:GetBoneMatrix(boneid)
			if !matrix then return end

			local new_pos, new_ang = LocalToWorld(OFFSET_VEC, OFFSET_ANG, matrix:GetTranslation(), matrix:GetAngles())
			world_model:SetPos(new_pos)
			world_model:SetAngles(new_ang)
			world_model:SetModelScale(2)

			world_model:SetupBones()
			world_model:DrawModel()
			local new_pos, new_ang = LocalToWorld(CAM_OFFSET_VEC, CAM_OFFSET_ANG, matrix:GetTranslation(), matrix:GetAngles())
			local petition = FSB.GetPetition(self:GetPetitionIndex())
			if petition then
				draw3DPetition(petition, new_pos, new_ang, 2, "PetitionWorldmodelFont", true)
			end
		else
			world_model:SetPos(self:GetPos())
			world_model:SetAngles(self:GetAngles())
			world_model:SetModelScale(1)
			world_model:DrawModel()
		end

	end
end

local CAM_OFFSET_VEC = Vector(3.4, 3.95, 2.69)
local CAM_OFFSET_ANG = Angle(-20.7, -115, 67.8)
function SWEP:PostDrawViewModel(vm, weapon, ply)
	local boneid = vm:LookupBone("Petition")
	if !boneid then return end

	local matrix = vm:GetBoneMatrix(boneid)
	if !matrix then return end

	local new_pos, new_ang = LocalToWorld(CAM_OFFSET_VEC, CAM_OFFSET_ANG, matrix:GetTranslation(), matrix:GetAngles())

	local petition = FSB.GetPetition(self:GetPetitionIndex())
	if petition then
		draw3DPetition(petition, new_pos, new_ang, 1.43, "PetitionViewmodelFont")
	end
end

hook.Add("KeyPress", "open_petition", function (ply, key)
	if ply ~= LocalPlayer() then return end
	if key ~= IN_USE then return end

	local tr = util.TraceLine({
		start = ply:GetShootPos(),
		endpos = ply:GetShootPos()+ply:GetAimVector()*80,
		filter = ply
	})

	---@type Player
	---@diagnostic disable-next-line: assign-type-mismatch
	local target_ply = tr.Entity
	if not target_ply:IsPlayer() then return end

	local petition = target_ply:GetActiveWeapon()
	if petition:GetClass() ~= "weapon_petition" then return end

	local petition_id = petition:GetPetitionIndex()
	if FSB.IsPetitionValid(petition_id) then
		FSB.OpenPetition(petition_id)
	end
end)
--#endregion
