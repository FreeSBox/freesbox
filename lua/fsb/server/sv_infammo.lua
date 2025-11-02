hook.Add("PlayerSwitchWeapon", "give_inf_ammo", function (player, oldWeapon, newWeapon)
	player:SetAmmo(99999, newWeapon:GetPrimaryAmmoType())
end)
