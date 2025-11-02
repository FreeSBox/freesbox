

---@param name string
---@return string
function GetFSBResource(name)
	return include("resources/" .. name .. ".lua")
end