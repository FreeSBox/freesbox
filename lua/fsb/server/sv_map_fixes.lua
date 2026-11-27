-- Fixes those stupid fucking elements that map authors thought would be funny to add.
local ihateyou = {
    ["gm_novenka_improved"] = {
        ["trigger_physics_trap"] = true,
    },
}
local badMap = ihateyou[game.GetMap()]
if not badMap then return end
local function cleanupBad()
    for _,ent in ents.Iterator() do
        if badMap[ent:GetClass()] then
            Msg("The author of this map thought it would be a great idea to add "..tostring(ent).."\n")
            ent:Remove()
            goto EXIT
        end
    end
    ::EXIT::
    Msg("Removed map garbage.\n")
end
hook.Add("PostCleanupMap","RemoveStupidMapElementsOnCleanup",cleanupBad)
hook.Add("InitPostEntity","RemoveStupidMapElementsOnInit",cleanupBad)
