-- Fixes those stupid fucking elements that map authors thought would be funny to add.
local ihateyou = {
    ["gm_novenka_improved"] = {
        ["trigger_physics_trap"] = true,
    },
}
if not ihateyou[game.GetMap()] then return end
hook.Add("PostCleanupMap","RemoveStupidMapElements",function()
    for _,ent in ents.Iterator() do -- Atleast it's ents.Iterator()...
        for _,entry in ipairs(ihateyou[game.GetMap()]) do
            if ent:GetClass() == entry then
                Msg("The author of this map thought it would be a great idea to add "..tostring(ent).."\n")
                ent:Remove()
                goto EXIT
            end
        end
    end
    ::EXIT::
    Msg("Removed map garbage.\n")
end)
