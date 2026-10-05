-- Petition #1316+#1671
-- This uses literally the same code with the print function removed, although it seems correct
hook.Add("InitPostEntity", "init_phys_perf", function()
	hook.Remove("InitPostEntity", "init_phys_perf")
	local TAB = physenv.GetPerformanceSettings()

	TAB.MaxFrictionMass = 99999
	TAB.MaxVelocity = 99999
	TAB.MaxAngularVelocity = 99999

	physenv.SetPerformanceSettings(TAB)
end)
