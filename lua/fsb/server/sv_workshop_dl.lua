-- Add workshop content for the clients.
local WORKSHOP_ITEMS = {
	"737640184", -- Tank track
	"160250458", -- Wiremod
	"2802133674", -- Petition swep content
	--#region Petitioned addons
	"3389728250", -- Glide
	"3389795738", -- Glide // GTAV: Helicopters
	"3673232532", -- Glide // Extra Details
	"3620753374", -- Left 4 Dead // Glide
	"246756300", -- 3D Stream Radio
	"2675972006", -- Custom Loadout
	"3318060741", -- rRadio
	"104575630", -- Ragdoll Mover
	"109643223", -- 3D2D Textscreens
	"2840295308", -- Primitive
	"2458909924", -- Prop2Mesh
	"287012681", -- Track Assembly Tool
	"2639959090", -- Manable Emplacements
	"3687687491", -- Glide // Oppressor Mk2
	"3001397905", -- Media Player (Updated Edition)
	"104691717", -- PAC3
	"2656563609", -- Musical Keyboard
	"173482196", -- SProps Workshop Edition
	"2821862386", -- Simple Weapons: Base
	"2821865508", -- Simple Weapons: CS:S
	"2775687029", -- [ ULTRA GUNS ] ГАНТЕЛЯ 2-4 КИЛЛОГРАММА!!!!!! swep
	"3620516732", -- Glide // Styled's Experiments
	"2175553724", -- Wiremod Extras
	"3442302711", -- [G]VRMod: Ultimate
	"1517464837", -- ttt_cigarette
	"2853616849", -- Heineken Beer SWEP
	"2962299500", -- Synergy Elite Buggy [Vehicle]
	--#endregion
}
for _,id in ipairs(WORKSHOP_ITEMS) do
	resource.AddWorkshop(id)
end
