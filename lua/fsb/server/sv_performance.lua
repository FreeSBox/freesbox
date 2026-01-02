timer.Create("update_server_performance", 0.5, 0, function ()
	SetGlobalFloat("serverTPS", FSB.GetAverageTPS())
end)
