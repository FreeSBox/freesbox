-- Implemented because of petition:
-- уберите возможность ставить пропы неживым игрокам
-- Index: 96

hook.Add("PlayerSpawnObject", "block_spawn_when_dead", function (ply, model, skin)
	if not ply:Alive() then
		return false
	end
end)
