-- Petition #1316
-- This uses literally the same code with the print function removed, although it seems correct
hook.Add("Think", "init_phys_perf", function()
  hook.Remove("Think", "init_phys_perf")
  local TAB = physenv.GetPerformanceSettings()

  TAB.MaxFrictionMass = 1000000
  TAB.MaxVelocity = 1000000
  TAB.MaxAngularVelocity = 1000000

  physenv.SetPerformanceSettings(TAB)
end)
