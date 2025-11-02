local localization_data
if SERVER then
	localization_data = include("resources/localization.lua")
	AddCSLuaFile("resources/localization.lua")
else
	localization_data = include("resources/localization.lua")
end

local gmod_language = GetConVar("gmod_language")

local english_data = localization_data["en"]

---FreeSBox's internal translation function.
---@param label string
---@return string localized_string
function FTranslate(label)
	local lang = localization_data[gmod_language:GetString()]
	if lang then
		return lang[label] or label
	end

	return english_data[label] or label
end
