
---@param name string
---@return string
function FSB.GetResource(name)
	return include("resources/" .. name .. ".lua")
end
