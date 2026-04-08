
hook.Add("PlayerInitialSpawn", "KillULXRemoveCheck", function (player, transition)
	--This shit will try to recreate ULX entities,
	--the problem is, they are sometimes outside the map
	--and the game will delete them in C++ code,
	--so it will just spam the console every fucking tick.
	--I'm tired if this, also I don't see why the fuck this even exists.
	hook.Remove("EntityRemoved", "ULibEntRemovedCheck")

	hook.Remove("PlayerInitialSpawn", "KillULXRemoveCheck")
end)
