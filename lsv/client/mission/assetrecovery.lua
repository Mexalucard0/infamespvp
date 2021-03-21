local _assetRecoveryData = nil

local function isAnyPedInVehicle(vehicle)
	for i = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 2 do
		if not IsVehicleSeatFree(vehicle, i) then
			return true
		end
	end

	return false
end

RegisterNetEvent('lsv:finishAssetRecovery')
AddEventHandler('lsv:finishAssetRecovery', function(success, reason)
	MissionManager.FinishMission(success)

	World.EnableWanted(false)

	if _assetRecoveryData.vehNetId and _assetRecoveryData.creator == Player.ServerId() then
		Network.DeleteVehicle(_assetRecoveryData.vehNetId, 5000)
	end

	RemoveBlip(_assetRecoveryData.vehicleBlip)

	if _assetRecoveryData.dropOffBlip then
		RemoveBlip(_assetRecoveryData.dropOffBlip)
	end

	_assetRecoveryData = nil

	Gui.FinishMission('Recuperacion de Activos', success, reason)
end)

RegisterNetEvent('lsv:assetRecoveryVehicleSpawned')
AddEventHandler('lsv:assetRecoveryVehicleSpawned', function(vehNetId)
	if not _assetRecoveryData then
		return
	end

	_assetRecoveryData.vehNetId = vehNetId
end)

RegisterNetEvent('lsv:startAssetRecovery')
AddEventHandler('lsv:startAssetRecovery', function(data)
	local isMissionHost = data.creator == Player.ServerId()

	if not isMissionHost then
		MissionManager.JoinMission('AssetRecovery', data.creator) --TODO: Ugliest thing ever
	end

	_assetRecoveryData = data
	_assetRecoveryData.missionTimer = Timer.New()
	_assetRecoveryData.location = Settings.assetRecovery.locations[_assetRecoveryData.locationIndex]

	_assetRecoveryData.vehicleBlip = Map.CreatePlaceBlip(nil, _assetRecoveryData.location.vehicle.x, _assetRecoveryData.location.vehicle.y, _assetRecoveryData.location.vehicle.z, nil, Color.BLIP_YELLOW)
	SetBlipAsShortRange(_assetRecoveryData.vehicleBlip, false)
	Map.SetBlipFlashes(_assetRecoveryData.vehicleBlip)

	World.EnableWanted(true)

	local wasWantedLevelSet = false
	local wasVehicleBlipCreated = false

	Citizen.CreateThread(function()
		Gui.StartMission('Recuperacion de Activos', 'Roba el vehículo y dejalo en el lugar de entrega..')

		while true do
			Citizen.Wait(0)

			if not MissionManager.Mission then
				return
			end

			if wasVehicleBlipCreated then
				local isInVehicle = IsPedInVehicle(PlayerPedId(), _assetRecoveryData.vehicle, false)
				SetBlipAlpha(_assetRecoveryData.vehicleBlip, isInVehicle and 0 or 255)
			end

			if Player.IsActive() then
				if not _assetRecoveryData.vehNetId then
					Gui.DisplayObjectiveText('Ve a la ~y~ubicacion~w~.')
				else
					Gui.DisplayObjectiveText('Entrega el ~g~vehiculo~w~ en el ~y~punto de entrega~w~.')
					Gui.DrawPlaceMarker(_assetRecoveryData.location.dropOff, Color.YELLOW)
				end

				Gui.DrawTimerBar('TIEMPO DE MISION', Settings.assetRecovery.time - _assetRecoveryData.missionTimer:elapsed(), 1)
			end
		end
	end)

	while true do
		Citizen.Wait(0)

		if not MissionManager.Mission then
			return
		end

		if isMissionHost then
			if _assetRecoveryData.missionTimer:elapsed() >= Settings.assetRecovery.time then
				TriggerServerEvent('lsv:finishAssetRecovery', false, 'El tiempo se acabo.')
				return
			end
		end

		if not _assetRecoveryData.vehNetId then
			if isMissionHost then
				if Player.DistanceTo(_assetRecoveryData.location.vehicle, true) <= Settings.worldModifierDistance then
					Streaming.RequestModelAsync(_assetRecoveryData.vehicleHash)

					local vehNetId = Network.CreateVehicle(_assetRecoveryData.vehicleHash, _assetRecoveryData.location.vehicle, _assetRecoveryData.location.vehicle.heading)
					if vehNetId then
						local vehicle = NetToVeh(vehNetId)
						SetVehicleModKit(vehicle, 0)
						SetVehicleMod(vehicle, 16, 4)
						SetVehicleTyresCanBurst(vehicle, false)
						SetModelAsNoLongerNeeded(_assetRecoveryData.vehicleHash)

						_assetRecoveryData.vehNetId = vehNetId

						TriggerServerEvent('lsv:assetRecoveryVehicleSpawned', vehNetId)
					end
				end
			end
		elseif Network.DoesEntityExistWithNetworkId(_assetRecoveryData.vehNetId) then
			_assetRecoveryData.vehicle = NetToVeh(_assetRecoveryData.vehNetId)

			if not wasVehicleBlipCreated then
				RemoveBlip(_assetRecoveryData.vehicleBlip)
				_assetRecoveryData.vehicleBlip = Map.CreateEntityBlip(_assetRecoveryData.vehicle, Blip.CAR, 'Vehiculo', Color.BLIP_GREEN)

				_assetRecoveryData.dropOffBlip = Map.CreatePlaceBlip(nil, _assetRecoveryData.location.dropOff.x, _assetRecoveryData.location.dropOff.y, _assetRecoveryData.location.dropOff.z, nil, Color.BLIP_YELLOW)
				SetBlipAsShortRange(_assetRecoveryData.dropOffBlip, false)
				Map.SetBlipFlashes(_assetRecoveryData.dropOffBlip)

				wasVehicleBlipCreated = true
			end

			if isMissionHost then
				if not IsVehicleDriveable(_assetRecoveryData.vehicle, false) then
					TriggerServerEvent('lsv:finishAssetRecovery', false, 'El vehiculo ha sido destruido.')
					return
				end

				if not wasWantedLevelSet then
					if isAnyPedInVehicle(_assetRecoveryData.vehicle) then
						local players = _assetRecoveryData.isInCrewMode and _assetRecoveryData.crewMembers or { Player.ServerId() }
						table.iforeach(players, function(player)
							World.SetWantedLevel(3, 5, false, GetPlayerFromServerId(player))
						end)
						wasWantedLevelSet = true
					end
				end

				if World.GetDistance(GetEntityCoords(_assetRecoveryData.vehicle), _assetRecoveryData.location.dropOff, true) <= Settings.assetRecovery.dropRadius then
					TriggerServerEvent('lsv:finishAssetRecovery', true)
					return
				end
			end
		end
	end
end)
