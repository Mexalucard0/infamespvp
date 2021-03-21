local _wantedData = nil

RegisterNetEvent('lsv:mostWantedFinished')
AddEventHandler('lsv:mostWantedFinished', function(success, reason)
	MissionManager.FinishMission(success)

	World.EnableWanted(false)

	Gui.FinishMission('El Mas Buscado', success, reason)
end)

AddEventHandler('lsv:finishMostWanted', function(success)
	TriggerServerEvent('lsv:finishMostWanted', success)
end)

RegisterNetEvent('lsv:startMostWanted')
AddEventHandler('lsv:startMostWanted', function(data)
	local isMissionHost = data.creator == Player.ServerId()

	if not isMissionHost then
		MissionManager.JoinMission('MostWanted', data.creator) --TODO: Ugliest thing ever
	end

	_wantedData = data
	_wantedData.missionTimer = Timer.New()

	Gui.StartMission('El Mas Buscado', 'Sobrevive el tiempo requerido con el nivel de busqueda.')

	Citizen.CreateThread(function()
		while true do
			Citizen.Wait(0)

			if not MissionManager.Mission then
				return
			end

			if Player.IsActive() then
				Gui.DrawTimerBar('TIEMPO DE MISION', Settings.mostWanted.time - _wantedData.missionTimer:elapsed(), 1)
				Gui.DisplayObjectiveText('Sobrevive con el nivel de busqueda.')
			end
		end
	end)

	World.EnableWanted(true)
	World.SetWantedLevel(5, 5, true)

	while true do
		Citizen.Wait(0)

		if not MissionManager.Mission then
			return
		end

		if isMissionHost and _wantedData.missionTimer:elapsed() >= Settings.mostWanted.time then
			TriggerEvent('lsv:finishMostWanted', true)
			return
		end
	end
end)
