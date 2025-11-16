-- Custom player names.

local MAX_NAME_LENGTH = 100
local MAX_TAG_LENGTH = 150

---@class Player
local PLAYER = FindMetaTable("Player")
local orig_name = PLAYER.Name

function PLAYER:GetOriginalName()
	return orig_name(self)
end

-- Don't care about tags, easychat will hook this and fix them
PLAYER.Name = function(self)
	if not IsValid(self) then return "Invalid" end
	local name = self:GetNWString("nickname")
	if name == "" then
		return orig_name(self)
	else
		return name
	end
end
PLAYER.GetName = PLAYER.Name
PLAYER.Nick = PLAYER.Name

---@param name string
function PLAYER:SetPlayerName(name)
	if self:IsGhostBanned() then return end

	name = name:Trim()
	if #name > MAX_NAME_LENGTH then return end
	if SERVER then
		self:SetPData("nickname", name)
		self:SetNWString("nickname", name)
	else
		net.Start("change_nickname")
			net.WriteBool(true) -- should_save
			net.WriteString(name)
		net.SendToServer()
	end
end

---@param name string
function PLAYER:SetPlayerNameNoSave(name)
	if self:IsGhostBanned() then return end

	name = name:Trim()
	if #name > MAX_NAME_LENGTH then return end

	if SERVER then
		self:SetNWString("nickname", name)
	else
		net.Start("change_nickname")
			net.WriteBool(false) -- should_save
			net.WriteString(name)
		net.SendToServer()
	end
end

------ Nametags ------

function PLAYER:SetNameTag(name_tag)
	if self:IsGhostBanned() then return end

	name_tag = name_tag:Trim()
	if #name_tag > MAX_TAG_LENGTH then return end

	if SERVER then
		self:SetPData("nametag", name_tag)
		self:SetNWString("nametag", name_tag)
	else
		net.Start("change_nametag")
			net.WriteBool(true) -- should_save
			net.WriteString(name_tag)
		net.SendToServer()
	end
end
function PLAYER:SetNameTagNoSave(name_tag)
	if self:IsGhostBanned() then return end

	name_tag = name_tag:Trim()
	if #name_tag > MAX_TAG_LENGTH then return end

	if SERVER then
		self:SetNWString("nametag", name_tag)
	else
		net.Start("change_nametag")
			net.WriteBool(false) -- should_save
			net.WriteString(name_tag)
		net.SendToServer()
	end
end
if CLIENT then
	-- Wrapper function for uyutniy compatibility
	function setcustomtitle(nametag) LocalPlayer():SetNameTag(nametag) end
end

function PLAYER:GetNameTag()
	return self:GetNWString("nametag")
end

function PLAYER:InitNameAndTag()
	self:SetNWString("nickname", self:GetPData("nickname"))
	self:SetNWString("nametag", self:GetPData("nametag"))
end

------ Server code ------

if SERVER then
	hook.Add("PlayerAuthed", "apply_custom_name", function(ply, steamid, uniqueid)
		ply:InitNameAndTag()
	end)

	util.AddNetworkString("change_nametag")
	net.Receive("change_nametag", function(len, ply)
		if ply:IsGhostBanned() then return end

		local should_save = net.ReadBool()
		local name_tag = string.Trim(net.ReadString())
		if #name_tag > MAX_TAG_LENGTH then return end

		if should_save then
			ply:SetPData("nametag", name_tag)
		end
		ply:SetNWString("nametag", name_tag)
	end)

	util.AddNetworkString("change_nickname")
	net.Receive("change_nickname", function(len, ply)
		if ply:IsGhostBanned() then return end

		local should_save = net.ReadBool()
		local new_name = string.Trim(net.ReadString())
		if #new_name > MAX_NAME_LENGTH then return end

		if should_save then
			ply:SetPData("nickname", new_name)
		end
		ply:SetNWString("nickname", new_name)
	end)
end
