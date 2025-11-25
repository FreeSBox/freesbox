---@diagnostic disable: undefined-field
AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Anti-Noclip"
ENT.Author = "Me"
ENT.Category = "Other"
ENT.Purpose = "Block noclip in an area"
ENT.Spawnable = true
ENT.AdminOnly = true

local DEFAULT_RADIUS = 600
local MAX_RADIUS = 2000

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "Radius")
	self:NetworkVar("Float", 1, "SizeX")
	self:NetworkVar("Float", 2, "SizeY")
	self:NetworkVar("Float", 3, "SizeZ")

	if CLIENT then
		self:NetworkVarNotify("Radius", self.OnVarChanged)
		self:NetworkVarNotify("SizeX", self.OnVarChanged)
		self:NetworkVarNotify("SizeY", self.OnVarChanged)
		self:NetworkVarNotify("SizeZ", self.OnVarChanged)
	end
end

function ENT:Initialize()
	if SERVER then
		self:SetModel("models/hunter/blocks/cube025x025x025.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self.Inputs = Wire_CreateInputs(self, {"Radius", "SizeX", "SizeY", "SizeZ"})
		self:SetRadius(DEFAULT_RADIUS) -- Default radius.
		self:SetSizeX(0)
		self:SetSizeY(0)
		self:SetSizeZ(0)

		local phys = self:GetPhysicsObject()
		if phys:IsValid() then
			phys:Wake()
		end
	else
		self:SetRenderBounds(Vector(DEFAULT_RADIUS,DEFAULT_RADIUS,DEFAULT_RADIUS), Vector(-DEFAULT_RADIUS,-DEFAULT_RADIUS,-DEFAULT_RADIUS))
	end
end

--Pasted from sh_buildmode
local function isInNoclip(player)
	return player:GetMoveType() == MOVETYPE_NOCLIP and not player:InVehicle()
end

---@param ent Entity
---@return boolean
function ENT:IsPosAffected(ent)
	local pos = ent:GetPos()
	local size_x, size_y, size_z = self:GetSizeX(), self:GetSizeY(), self:GetSizeZ()
	local our_pos = self:GetPos()
	if size_x ~= 0 and size_y ~= 0 and size_z ~= 0 then
		local min = Vector(size_x, size_y, size_z)
		if not pos:WithinAABox(our_pos-min, our_pos+min) then
			return false
		end
	else
		if pos:Distance(our_pos) > self:GetRadius() then
			return false
		end
	end

	local tr = util.TraceEntityHull({
		start = pos,
		endpos = pos,-- + dir * LEN,
		filter = ent,
		mask = MASK_PLAYERSOLID,
		collisiongroup = COLLISION_GROUP_PLAYER
	}, ent)
	return not tr.Hit
end

if SERVER then
	function ENT:Think()
		for _, ply in ipairs(player.GetHumans()) do
			if isInNoclip(ply) and self:IsPosAffected(ply) then
				ply:SetMoveType(MOVETYPE_WALK)
			end
		end

		self:NextThink(CurTime())
		return true
	end
end

hook.Add("PlayerNoClip", "block_noclip_enter", function (ply, desiredState)
	local ents = ents.FindByClass("anti_noclip")
	for _, ent in ipairs(ents) do
		if ent:IsPosAffected(ply) then
			return false
		end
	end
end)

function ENT:TriggerInput(iname, value)
	if iname == "Radius" and value ~= 0 then
		self:SetRadius(math.Clamp(value, 1, MAX_RADIUS))
	end
	if iname == "SizeX" then
		self:SetSizeX(math.Clamp(value, 0, MAX_RADIUS))
	elseif iname == "SizeY" then
		self:SetSizeY(math.Clamp(value, 0, MAX_RADIUS))
	elseif iname == "SizeZ" then
		self:SetSizeZ(math.Clamp(value, 0, MAX_RADIUS))
	end
end

--#region Client
if not CLIENT then return end

function ENT:Draw(flags)
	self:DrawModel(flags)

	local size_x, size_y, size_z = self:GetSizeX(), self:GetSizeY(), self:GetSizeZ()
	if size_x ~= 0 and size_y ~= 0 and size_z ~= 0 then
		local min = Vector(size_x, size_y, size_z)
		render.DrawWireframeBox(self:GetPos(), angle_zero, -min, min, self:GetColor(), true)
	else
		render.DrawWireframeSphere(self:GetPos(), self:GetRadius(), 16, 16, self:GetColor(), true)
	end
end

function ENT:OnVarChanged(name, old, new)
	if name == "Radius" then
		self:SetRenderBounds(Vector(new,new,new), Vector(-new,-new,-new))
	elseif name == "SizeX" then
		local min = Vector(new, self:GetSizeY(), self:GetSizeZ())
		self:SetRenderBounds(min, -min)
	elseif name == "SizeY" then
		local min = Vector(self:GetSizeX(), new, self:GetSizeZ())
		self:SetRenderBounds(min, -min)
	elseif name == "SizeZ" then
		local min = Vector(self:GetSizeX(), self:GetSizeY(), new)
		self:SetRenderBounds(min, -min)
	end
end

--#endregion
