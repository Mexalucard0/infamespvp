RegisterNetEvent('lsv:finishVehicleImport')
AddEventHandler('lsv:finishVehicleImport', function(success, reason)
	MissionManager.FinishMission(success)

	World.EnableWanted(false)

	if _importData.vehNetId then
		Player.LeaveVehicle(_importData.vehicle)
		SetVehicleDoorsLockedForAllPlayers(_importData.vehicle, true)
		Network.DeleteVehicle(_importData.vehNetId, 5000)
	end

	RemoveBlip(_importData.vehicleBlip)

	if _importData.dropOffBlip then
		RemoveBlip(_importData.dropOffBlip)
	end

	_importData = nil

	Gui.FinishMission('Importacion De Vehiculos', success, reason)
end)

RegisterNetEvent('lsv:startVehicleImport')
AddEventHandler('lsv:startVehicleImport', function()
	_importData = { }

	_importData.model = table.irandom(Settings.vehicleImport.vehicles)
	Streaming.RequestModelAsync(_importData.model)
	_importData.modelName = Vehicle.GetModelName(_importData.model)

	_importData.vehicleLocation = table.irandom(Settings.vehicleImport.locations.vehicle)

	_importData.vehicleBlip = Map.CreatePlaceBlip(Blip.IMPORT_CAR, _importData.vehicleLocation.x, _importData.vehicleLocation.y, _importData.vehicleLocation.z, 'Vehiculo', Color.BLIP_BLUE)
	SetBlipAsShortRange(_importData.vehicleBlip, false)
	Map.SetBlipFlashes(_importData.vehicleBlip)

	_importData.dropOffLocation = table.irandom(Settings.vehicleImport.locations.dropOff)

	World.EnableWanted(true)
	_importData.missionTimer = Timer.New()

	local wasVehicleBlipCreated = false

	Citizen.CreateThread(function()
		Gui.StartMission('Importacion De Vehiculos', 'Recoge el vehículo y entregalo al Comprador.')

		while true do
			Citizen.Wait(0)

			if not MissionManager.Mission then
				return
			end

			if wasVehicleBlipCreated then
				local isInVehicle = IsPedInVehicle(PlayerPedId(), _importData.vehicle, false)
				SetBlipAlpha(_importData.vehicleBlip, isInVehicle and 0 or 255)
			end

			if Player.IsActive() then
				if not _importData.vehNetId then
					Gui.DisplayObjectiveText('Recoge el ~b~vehiculo~w~.')
				else
					Gui.DisplayObjectiveText('Entrega el ~b~'.._importData.modelName..'~w~ al ~y~Comprador~w~.')
					Gui.DrawPlaceMarker(_importData.dropOffLocation, Color.YELLOW)
				end

				Gui.DrawTimerBar('TIEMPO DE MISION', Settings.vehicleImport.time - _importData.missionTimer:elapsed(), 1)
			end
		end
	end)

	while true do
		Citizen.Wait(0)

		if not MissionManager.Mission then
			return
		end

		if _importData.missionTimer:elapsed() > Settings.vehicleImport.time then
			TriggerEvent('lsv:finishVehicleImport', false, 'El tiempo se acabo.')
			return
		end

		if not _importData.vehNetId then
			if Player.DistanceTo(_importData.vehicleLocation, true) <= Settings.worldModifierDistance then
				local vehNetId = Network.CreateVehicle(_importData.model, _importData.vehicleLocation, _importData.vehicleLocation.heading)
				if vehNetId then
					local vehicle = NetToVeh(vehNetId)
					Vehicle.ApplyMods(vehicle, Vehicle.GenerateRandomMods(vehicle))
					SetVehicleTyresCanBurst(vehicle, false)
					SetVehicleNumberPlateText(vehicle, table.irandom(Settings.vehicleImport.plates))

					_importData.vehNetId = vehNetId
				end
			end
		elseif Network.DoesEntityExistWithNetworkId(_importData.vehNetId) then
			_importData.vehicle = NetToVeh(_importData.vehNetId)

			if not IsVehicleDriveable(_importData.vehicle, false) then
				TriggerEvent('lsv:finishVehicleImport', false, _importData.modelName..' fue destruido.')
				return
			end

			if not wasVehicleBlipCreated then
				RemoveBlip(_importData.vehicleBlip)
				_importData.vehicleBlip = Map.CreateEntityBlip(_importData.vehicle, Blip.IMPORT_CAR, _importData.modelName, Color.BLIP_BLUE)
				Map.SetBlipFlashes(_importData.vehicleBlip)

				_importData.dropOffBlip = Map.CreatePlaceBlip(nil, _importData.dropOffLocation.x, _importData.dropOffLocation.y, _importData.dropOffLocation.z, nil, Color.BLIP_YELLOW)
				SetBlipAsShortRange(_importData.dropOffBlip, false)

				wasVehicleBlipCreated = true
			end

			if World.GetDistance(GetEntityCoords(_importData.vehicle), _importData.dropOffLocation, true) <= Settings.vehicleImport.dropRadius then
				TriggerServerEvent('lsv:finishVehicleImport')
				return
			end
		end
	end
end)
