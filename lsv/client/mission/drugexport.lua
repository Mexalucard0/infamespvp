local _vehicleNet = nil
local _vehicle = nil

local _vehicleBlip = nil
local _buyerBlip = nil

local _productName = nil

RegisterNetEvent('lsv:drugExportFinished')
AddEventHandler('lsv:drugExportFinished', function(success, reason)
	MissionManager.FinishMission(success)

	World.EnableWanted(false)

	Network.DeleteVehicle(_vehicleNet, 5000)
	_vehicleNet = nil

	_vehicle = nil

	RemoveBlip(_vehicleBlip)
	_vehicleBlip = nil

	RemoveBlip(_buyerBlip)
	_buyerBlip = nil

	if success then
		reason = _productName..' fue entregado al comprador.'
	end

	_productName = nil

	Gui.FinishMission(Settings.drugBusiness.export.missionName, success, reason)
end)

AddEventHandler('lsv:finishDrugExport', function(success, reason)
	TriggerServerEvent('lsv:finishDrugExport', success, reason)
end)

AddEventHandler('lsv:startDrugExport', function(data)
	local vehicleModel = table.irandom(Settings.drugBusiness.export.vehicles[data.type])
	local vehiclePosition = Settings.drugBusiness.businesses[Player.DrugBusiness[data.type].id].vehicleLocation

	Streaming.RequestModelAsync(vehicleModel)
	_vehicleNet = Network.CreateVehicle(vehicleModel, vehiclePosition, vehiclePosition.heading)
	_vehicle = NetToVeh(_vehicleNet)

	SetVehicleModKit(_vehicle, 0)
	SetVehicleMod(_vehicle, 16, 4)
	SetVehicleTyresCanBurst(_vehicle, false)
	SetEntityLoadCollisionFlag(_vehicle, true, 1)

	_productName = Settings.drugBusiness.types[data.type].productName

	_vehicleBlip = Map.CreateEntityBlip(_vehicle, Blip.CARGO, _productName, Color.BLIP_BLUE)
	SetBlipAlpha(_vehicleBlip, 0)
	Map.SetBlipFlashes(_vehicleBlip)

	_buyerBlip = Map.CreatePlaceBlip(nil, data.location.x, data.location.y, data.location.z, 'Comprador', Color.BLIP_YELLOW)
	SetBlipAsShortRange(_buyerBlip, false)
	SetBlipAlpha(_buyerBlip, 0)

	Gui.StartMission(Settings.drugBusiness.export.missionName, 'Entrega la '.._productName..' al comprador.')

	local missionTimer = Timer.New()
	local isInVehicle = false
	local routeBlip = nil

	Citizen.CreateThread(function()
		while true do
			Citizen.Wait(0)

			if not MissionManager.Mission then
				return
			end

			SetBlipAlpha(_vehicleBlip, isInVehicle and 0 or 255)
			SetBlipAlpha(_buyerBlip, isInVehicle and 255 or 0)

			if Player.IsActive() then
				if not isInVehicle then
					Gui.DisplayObjectiveText('Recoge la ~b~'.._productName..'~w~.')
				elseif GetPlayerWantedLevel(PlayerId()) ~= 0 then
					Gui.DisplayObjectiveText('Pierde a los policias.')
				else
					Gui.DisplayObjectiveText('Entrega la ~b~'.._productName..'~w~ al ~y~Comprador~w~.')
				end

				Gui.DrawBar('BENEFICIO TOTAL', '$'..data.totalProfit, 2)
				Gui.DrawTimerBar('TIEMPO DE MISION', Settings.drugBusiness.export.time - missionTimer:elapsed(), 1)
			end
		end
	end)

	if not Player.DrugBusiness[data.type].upgrades.security then
		World.EnableWanted(true)
	end

	while true do
		Citizen.Wait(0)

		if not MissionManager.Mission then
			return
		end

		if missionTimer:elapsed() >= Settings.drugBusiness.export.time then
			TriggerEvent('lsv:finishDrugExport', false, 'El tiempo se acabo.')
			return
		end

		if Network.DoesEntityExistWithNetworkId(_vehicleNet) then
			_vehicle = NetToVeh(_vehicleNet)
		else
			_vehicle = nil
			isInVehicle = false
		end

		if _vehicle then
			if not IsVehicleDriveable(_vehicle, false) then
				TriggerEvent('lsv:finishDrugExport', false, "La ".._productName..' ha sido destruida.')
				return
			end

			isInVehicle = IsPedInVehicle(PlayerPedId(), _vehicle, false)

			if isInVehicle then
				if Player.DistanceTo(data.location, true) <= Settings.drugBusiness.export.dropRadius and GetPlayerWantedLevel(PlayerId()) == 0 then
					TriggerEvent('lsv:finishDrugExport', true)
					return
				end

				Gui.DrawPlaceMarker(data.location, Color.YELLOW)

				if routeBlip ~= _buyerBlip then
					SetBlipRoute(_buyerBlip, true)
					routeBlip = _buyerBlip
				end
			elseif routeBlip ~= _vehicleBlip then
				SetBlipRoute(_vehicleBlip, true)
				routeBlip = _vehicleBlip
			end
		end
	end
end)
