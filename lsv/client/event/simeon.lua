local _instructionsText = 'Encuentra y entrega los vehículos solicitados a Simeon.'
local _titles = { 'GANADOR', '2DO PUESTO', '3ER PUESTO' }
local _playerColors = { Color.YELLOW, Color.GREY, Color.BROWN }
local _playerPositions = { '1ro: ', '2do: ', '3ro: ' }

local _simeonData = nil

local function getPlayerPoints()
	local player = table.ifind_if(_simeonData.players, function(player)
		return player.id == Player.ServerId()
	end)

	return player and #player.vehicles or nil
end

RegisterNetEvent('lsv:startSimeonExport')
AddEventHandler('lsv:startSimeonExport', function(data, passedTime)
	if _simeonData then
		return
	end

	-- Preparations
	_simeonData = { }

	_simeonData.startTime = GetGameTimer()
	if passedTime then
		_simeonData.startTime = _simeonData.startTime - passedTime
	end
	_simeonData.vehicles = data.vehicles
	_simeonData.players = data.players

	_simeonData.blip = Map.CreatePlaceBlip(Blip.SIMEON, Settings.simeon.location.x, Settings.simeon.location.y, Settings.simeon.location.z, 'Simeon')
	SetBlipAsShortRange(_simeonData.blip, false)
	Map.SetBlipFlashes(_simeonData.blip)

	_simeonData.vehicleBlips = { }

	local currentVehicleName = nil

	-- GUI
	Citizen.CreateThread(function()
		if Player.IsInFreeroam() and not passedTime then
			Gui.StartEvent('Exportación de Simeon', _instructionsText)
		end

		while true do
			Citizen.Wait(0)

			if not _simeonData then
				return
			end

			local isPlayerInFreeroam = Player.IsInFreeroam()
			SetBlipAlpha(_simeonData.blip, isPlayerInFreeroam and 255 or 0)

			if isPlayerInFreeroam then
				if currentVehicleName then
					Gui.DisplayObjectiveText('Entrega un '..currentVehicleName..' a Simeon.')
				else
					local vehicles = { }
					for _, vehicle in ipairs(_simeonData.vehicles) do
						table.insert(vehicles, vehicle.name)
					end

					Gui.DisplayObjectiveText('Encuentra un '..table.concat(vehicles, ' o un ')..'.')
				end

				Gui.DrawTimerBar('FIN DEL EVENTO', math.max(0, Settings.simeon.duration - GetGameTimer() + _simeonData.startTime), 1)

				local points = getPlayerPoints() or 0
				Gui.DrawBar('VEHICULOS ENTREGADOS', points, 2)

				local barPosition = 3
				for i = barPosition - 1, 1, -1 do
					local data = _simeonData.players[i]
					if data then
						Gui.DrawBar(_playerPositions[i]..GetPlayerName(GetPlayerFromServerId(data.id)), #data.vehicles, barPosition, _playerColors[i], true)
						barPosition = barPosition + 1
					end
				end
			end
		end
	end)

	-- Logic
	Citizen.CreateThread(function()
		while true do
			Citizen.Wait(0)

			if not _simeonData then
				return
			end

			local playerPos = Player.Position()

			table.iremove_if(_simeonData.vehicleBlips, function(blip)
				return World.GetDistance(playerPos, GetBlipCoords(blip), true) > Settings.simeon.blipRadius
			end, RemoveBlip)

			local playerPed = PlayerPedId()
			currentVehicleName = nil

			if IsPedInAnyVehicle(playerPed) then
				local vehicle = GetVehiclePedIsIn(playerPed, false)

				if GetPedInVehicleSeat(vehicle, -1) == playerPed and not IsEntityAMissionEntity(vehicle) then
					local vehicleHash = GetEntityModel(vehicle)
					local vehicleData, vehicleIndex = table.ifind_if(_simeonData.vehicles, function(vehicleData)
						return vehicleData.hash == vehicleHash
					end)

					if vehicleIndex then
						currentVehicleName = vehicleData.name
						Gui.DrawPlaceMarker(Settings.simeon.location, Color.YELLOW, Settings.simeon.dropRadius)

						if World.GetDistance(playerPos, Settings.simeon.location, true) <= Settings.simeon.dropRadius then
							PlaySoundFrontend(-1, 'Mission_Pass_Notify', 'DLC_HEISTS_GENERAL_FRONTEND_SOUNDS', true)
							table.remove(_simeonData.vehicles, vehicleIndex)
							World.DeleteEntity(vehicle)
							TriggerServerEvent('lsv:simeonVehicleDelivered', vehicleHash)
						end
					end
				end
			end
		end
	end)
end)

RegisterNetEvent('lsv:updateSimeonExportPlayers')
AddEventHandler('lsv:updateSimeonExportPlayers', function(players, player)
	if not _simeonData then
		return
	end

	_simeonData.players = players

	if player == Player.ServerId() then
		Gui.DisplayPersonalNotification('Entregaste un vehiculo solicitado a Simeon.')
	end
end)

RegisterNetEvent('lsv:finishSimeonExport')
AddEventHandler('lsv:finishSimeonExport', function(winners)
	if not _simeonData then
		return
	end

	RemoveBlip(_simeonData.blip)

	table.iforeach(_simeonData.vehicleBlips, function(blip)
		RemoveBlip(blip)
	end)

	local playerPoints = getPlayerPoints()
	_simeonData = nil

	if not winners then
		return
	end

	local playerPosition = nil
	for i = 1, math.min(3, #winners) do
		if winners[i] == Player.ServerId() then
			playerPosition = i
			break
		end
	end

	local messageText = playerPosition and 'Ganaste Exportación de Simeon con una puntuacion de '..playerPoints or Gui.GetPlayerName(winners[1], '~p~')..' gano Exportación de Simeon.'

	if Player.IsInFreeroam() and playerPoints then
		if playerPosition then
			PlaySoundFrontend(-1, 'Mission_Pass_Notify', 'DLC_HEISTS_GENERAL_FRONTEND_SOUNDS', true)
		else
			PlaySoundFrontend(-1, 'ScreenFlash', 'MissionFailedSounds', true)
		end

		local scaleform = Scaleform.NewAsync('MIDSIZED_MESSAGE')
		scaleform:call('SHOW_SHARD_MIDSIZED_MESSAGE', playerPosition and _titles[playerPosition] or 'PERDISTE', messageText, 21)
		scaleform:renderFullscreenTimed(10000)
	else
		Gui.DisplayNotification(messageText)
	end
end)

AddEventHandler('lsv:init', function()
	World.AddVehicleHandler(function(vehicle)
		if not _simeonData or not IsVehicleDriveable(vehicle) or IsEntityAMissionEntity(vehicle) then
			return
		end

		local driver = GetPedInVehicleSeat(vehicle, -1)
		if IsPedAPlayer(driver) or DoesBlipExist(GetBlipFromEntity(vehicle)) then
			return
		end

		local vehicleHash = GetEntityModel(vehicle)
		if not table.ifind_if(_simeonData.vehicles, function(vehicleData)
			return vehicleData.hash == vehicleHash
		end) then
			return
		end

		local blip = Map.CreateEntityBlip(vehicle, Blip.SIMEON_VEHICLE, 'Objetivo de Simeon', Color.BLIP_PURPLE)
		Map.SetBlipFlashes(blip)
		table.insert(_simeonData.vehicleBlips, blip)
	end)
end)
