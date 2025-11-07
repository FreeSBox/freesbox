-- Custom player names.

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
	if name:Trim() == "" then
		return orig_name(self)
	else
		return name
	end
end
PLAYER.GetName = PLAYER.Name
PLAYER.Nick = PLAYER.Name

function PLAYER:SetName(name)
	if self:IsGhostBanned() then return end
	if SERVER then
		if #name > 100 then return end
		self:SetPData("nickname", name)
		self:SetNWString("nickname", name)
	else
		net.Start("change_nickname")
			net.WriteString(name)
		net.SendToServer()
	end
end

---comment
---@param name string
function PLAYER:SetNameNoSave(name)
	self:SetNWString("nickname", name)
end

------ Nametags ------

function PLAYER:SetNameTag(name_tag)
	if self:IsGhostBanned() then return end
	if SERVER then
		if #name_tag > 256 then return end
		self:SetPData("nametag", name_tag)
		self:SetNWString("nametag", name_tag)
	else
		net.Start("change_nametag")
			net.WriteString(name_tag)
		net.SendToServer()
	end
end
function PLAYER:SetNameTagNoSave(name)
	self:SetNWString("nametag", name)
end
if CLIENT then
	-- Wrapper function for uyutniy compatibility
	function setcustomtitle(nametag) LocalPlayer():SetNameTag(nametag) end
end

function PLAYER:GetNameTag()
	return self:GetNWString("nametag")
end

------ Server code ------

if SERVER then
	hook.Add("PlayerAuthed", "apply_custom_name", function(ply, steamid, uniqueid)
		ply:SetNWString("nickname", ply:GetPData("nickname"))
		ply:SetNWString("nametag", ply:GetPData("nametag"))
	end)

	util.AddNetworkString("change_nametag")
	net.Receive("change_nametag", function(len, ply)
		local name_tag = net.ReadString()
		if #name_tag > 100 then return end
		ply:SetPData("nametag", name_tag)
		ply:SetNWString("nametag", name_tag)
	end)

	util.AddNetworkString("change_nickname")
	net.Receive("change_nickname", function(len, ply)
		local new_name = net.ReadString()
		if #new_name > 100 then return end
		ply:SetPData("nickname", new_name)
		ply:SetNWString("nickname", new_name)
	end)
end
