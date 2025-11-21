local fsb_enable_censorship = CreateClientConVar("fsb_enable_censorship", "0", true)

FSB.HOOKS.FilterText = FSB.HOOKS.FilterText or util.FilterText
function util.FilterText(str, ...)
	if fsb_enable_censorship:GetBool() then
		return FSB.HOOKS.FilterText(str, ...)
	else
		return str
	end
end
