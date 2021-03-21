local _sightseer = nil

RegisterNetEvent('lsv:finishSightseer')
AddEventHandler('lsv:finishSightseer', function(success, reason)
	MissionManager.FinishMission(success)

	World.EnableWanted(false)

	table.iforeach(_sightseer, function(data)
		data.hasPackage = nil

		if data.pickup.id then
			RemovePickup(data.pickup.id)
			data.pickup.id = nil
		end

		if data.blip.id then
			RemoveBlip(data.blip.id)
			data.blip.id = nil
		end

		if data.areaBlip then
			RemoveBlip(data.areaBlip)
			data.areaBlip = nil
		end
	end)

	_sightseer = nil

	Gui.FinishMission('Excursionista', success, reason)
end)

RegisterNetEvent('lsv:startSightseer')
AddEventHandler('lsv:startSightseer', function()
	local missionTimer = Timer.New()

	Gui.StartMission('Excursionista', 'Encuentra y recupera el paquete en el tiempo dado.')

	_sightseer = table.irandom_n(Settings.sightseer.locations, Settings.sightseer.count)
	local packageLocationIndex = math.random(Settings.sightseer.count)

	table.iforeach(_sightseer, function(data, index)
		if packageLocationIndex == index then
			data.hasPackage = true
			data.areaBlip = Map.CreateRadiusBlip(data.blip.x, data.blip.y, data.blip.z, Settings.sightseer.radius, Color.BLIP_GREEN)
			SetBlipAlpha(data.areaBlip, 0)
		end

		data.blip.id = Map.CreatePlaceBlip(Blip.SIGHTSEER, data.blip.x, data.blip.y, data.blip.z, 'Paquete', Color.BLIP_GREEN)
		SetBlipAsShortRange(data.blip.id, false)
		Map.SetBlipFlashes(data.blip.id)
	end)

	World.EnableWanted(true)

	Citizen.CreateThread(function()
		while true do
			Citizen.Wait(0)

			if not MissionManager.Mission then
				return
			end

			if Player.IsActive() then
				Gui.DrawTimerBar('TIEMPO DE MISION', Settings.sightseer.time - missionTimer:elapsed(), 1)
				Gui.DisplayObjectiveText('Encuentra y recupera el ~g~paquete~w~.')
			end
		end
	end)

	while true do
		Citizen.Wait(0)

		if not MissionManager.Mission then
			return
		end

		if missionTimer:elapsed() >= Settings.heist.time then
			TriggerEvent('lsv:finishSightseer', false, 'El tiempo se acabo.')
			return
		end

		if Player.IsActive() then
			local playerPosition = Player.Position()

			for i = #_sightseer, 1, -1 do
				local data = _sightseer[i]
				local distance = World.GetDistance(playerPosition, data.blip, true)

				if distance < Settings.sightseer.radius then
					if data.hasPackage then
						if not data.pickup.id then
							data.pickup.id = CreatePickupRotate(`PICKUP_MONEY_CASE`, data.pickup.x, data.pickup.y, data.pickup.z, 0.0, 0.0, 0.0, 8, false, true)
							SetBlipAlpha(data.areaBlip, 96)
							Map.SetBlipFlashes(data.blip.id)
						elseif HasPickupBeenCollected(data.pickup.id) then
							TriggerServerEvent('lsv:finishSightseer')
							return
						else
							Gui.DrawProgressBar('DISTANCIA AL PAQUETE', 1.0 - World.GetDistance(playerPosition, data.pickup) / Settings.sightseer.radius, 3, Color.GREEN)
							DrawMarker(20, data.pickup.x, data.pickup.y, data.pickup.z + 0.25, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.85, 0.85, 0.85, 114, 204, 114, 96, true, true)
						end
					elseif data.blip.id then
						Gui.DisplayHelpText('Tu paquete esta en otra ubicacion.')
						RemoveBlip(data.blip.id)
						data.blip.id = nil
					end
				end
			end
		end
	end
end)
