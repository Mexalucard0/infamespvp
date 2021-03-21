local _instructionsText = 'Alcanza la mayor velocidad en un vehículo terrestre.'
local _titles = { 'GANADOR', '2DO PUESTO', '3ER PUESTO' }
local _playerColors = { Color.YELLOW, Color.GREY, Color.BROWN }
local _playerPositions = { '1ro: ', '2do: ', '3ro: ' }

local _highwayData = nil

local function getPlayerSpeed()
	local player = table.ifind_if(_highwayData.players, function(player)
		return player.id == Player.ServerId()
	end)

	return player and player.speed or nil
end

RegisterNetEvent('lsv:startHighway')
AddEventHandler('lsv:startHighway', function(data, passedTime)
	if _highwayData then
		return
	end

	-- Preparations
	_highwayData = { }

	_highwayData.startTime = GetGameTimer()
	if passedTime then
		_highwayData.startTime = _highwayData.startTime - passedTime
	end

	_highwayData.players = data.players

	_highwayData.attemptTimer = Timer.New()
	_highwayData.currentAttempt = 0
	_highwayData.bestAttempt = 0
	_highwayData.lastAttempt = 0

	-- GUI
	Citizen.CreateThread(function()
		if Player.IsInFreeroam() and not passedTime then
			Gui.StartEvent('Highway', _instructionsText)
		end

		while true do
			Citizen.Wait(0)

			if not _highwayData then
				return
			end

			if Player.IsInFreeroam() then
				Gui.DisplayObjectiveText(_instructionsText)

				Gui.DrawTimerBar('FIN DEL EVENTO', math.max(0, Settings.highway.duration - GetGameTimer() + _highwayData.startTime), 1)
				Gui.DrawBar('TU MEJOR', string.to_speed(_highwayData.bestAttempt), 2)
				Gui.DrawBar('INTENTO ACTUAL', string.to_speed(_highwayData.currentAttempt), 3)

				local barPosition = 4
				for i = barPosition - 1, 1, -1 do
					local data = _highwayData.players[i]
					if data then
						Gui.DrawBar(_playerPositions[i]..GetPlayerName(GetPlayerFromServerId(data.id)), string.to_speed(data.speed), barPosition, _playerColors[i], true)
						barPosition = barPosition + 1
					end
				end
			end
		end
	end)

	while true do
		Citizen.Wait(100)

		if not _highwayData then
			return
		end

		local playerPed = PlayerPedId()

		if IsPedInAnyVehicle(playerPed) and not IsPedInAnyHeli(playerPed) and not IsPedInAnyPlane(playerPed) then
			local vehicle = GetVehiclePedIsIn(playerPed)
			if not IsEntityInAir(vehicle) then
				local speed = GetEntitySpeed(vehicle)
				if speed ~= 0 then
					_highwayData.currentAttempt = speed

					if speed > _highwayData.bestAttempt then
						_highwayData.bestAttempt = speed
					end
				end
			end
		end

		if _highwayData.bestAttempt ~= _highwayData.lastAttempt and _highwayData.attemptTimer:elapsed() >= 1000 then
			TriggerServerEvent('lsv:highwayNewSpeedRecord', _highwayData.bestAttempt)
			_highwayData.attemptTimer:restart()
			_highwayData.lastAttempt = _highwayData.bestAttempt
		end
	end
end)

RegisterNetEvent('lsv:updateHighwayPlayers')
AddEventHandler('lsv:updateHighwayPlayers', function(players)
	if _highwayData then
		_highwayData.players = players
	end
end)

RegisterNetEvent('lsv:finishHighway')
AddEventHandler('lsv:finishHighway', function(winners)
	if not _highwayData then
		return
	end

	if not winners then
		_highwayData = nil
		return
	end

	local playerSpeed = getPlayerSpeed()
	_highwayData = nil

	local playerPosition = nil
	for i = 1, math.min(3, #winners) do
		if winners[i] == Player.ServerId() then
			playerPosition = i
			break
		end
	end

	local messageText = playerPosition and 'Ganaste el evento Highway con una puntuacion de '..string.to_speed(playerSpeed) or Gui.GetPlayerName(winners[1], '~p~')..' gano el evento Highway.'

	if Player.IsInFreeroam() and playerSpeed then
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
