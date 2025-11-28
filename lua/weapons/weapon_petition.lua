AddCSLuaFile()

SWEP.PrintName = "Petition"
SWEP.Author = "Me"
SWEP.Purpose = "A weapon that can show others your petition"
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


SWEP.PetitionIndex = 229

function SWEP:Initialize()
	self:SetWeaponHoldType(self.HoldType)
end

function SWEP:Deploy()
	self:GetOwner():SetAnimation( PLAYER_IDLE );
	self:SendWeaponAnim( ACT_VM_IDLE );
end

function SWEP:PrimaryAttack()

end

function SWEP:SecondaryAttack()
end


function SWEP:Reload()
	-- Run petition select code here.
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

local offset_vec = Vector(4, -6, -3.4)
local cam_offset_vec = Vector(7, 2, -11)
local cam_offset_ang = Angle(162, 91.5, 100)
local cam_size_x = 150
local cam_size_y = 196
local offset_ang = Angle(160, 90, 90)
local worldModel = ClientsideModel(SWEP.WorldModel)
if worldModel then
	worldModel:SetNoDraw(true)
	function SWEP:DrawWorldModel()
		local owner = self:GetOwner()
		if (IsValid(owner)) then
			local boneid = owner:LookupBone("ValveBiped.Bip01_R_Hand") -- Right Hand
			if !boneid then return end

			local matrix = owner:GetBoneMatrix(boneid)
			if !matrix then return end

			local new_pos, new_ang = LocalToWorld(offset_vec, offset_ang, matrix:GetTranslation(), matrix:GetAngles())
			worldModel:SetPos(new_pos)
			worldModel:SetAngles(new_ang)
			worldModel:SetModelScale(2)

			worldModel:SetupBones()
			worldModel:DrawModel()
			local new_pos, new_ang = LocalToWorld(cam_offset_vec, cam_offset_ang, matrix:GetTranslation(), matrix:GetAngles())
			local petition = FSB.GetPetition(self.PetitionIndex)
			if petition then
				cam.Start3D2D( new_pos, new_ang, 0.1 )
					draw.RoundedBox(0, 0, 0, cam_size_x, cam_size_y, color_white)
					--draw.DrawText( , "Default", cam_size_x/2, 30, color_black, TEXT_ALIGN_CENTER )
					local y_len = drawMultiLine(petition.name, "HudDefault", cam_size_x, 16, cam_size_x/2, 30, color_black, TEXT_ALIGN_CENTER)
					draw.DrawText( "Press E to open this petition", "Default", cam_size_x/2, 50+y_len, color_black, TEXT_ALIGN_CENTER )
				cam.End3D2D()
			end
		else
			worldModel:SetPos(self:GetPos())
			worldModel:SetAngles(self:GetAngles())
			worldModel:DrawModel()
		end

	end
end
--#endregion
