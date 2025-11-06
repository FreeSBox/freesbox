local fsb_enable_adverts = CreateClientConVar("fsb_enable_adverts", "1", true)

local adverts =
{
	"advert.pi_menu",
	"advert.petitions",
}
local function getRandomAdvert()
	return FSB.Translate(adverts[math.random(#adverts)])
end

timer.Create("advertise_petitions", 5*60, 0, function ()
	if fsb_enable_adverts:GetBool() then
		chat.AddText(Color(185, 185, 185), getRandomAdvert())
	end
end)
