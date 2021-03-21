local _instructionsText = 'Compite para obtener la mayor cantidad de puntos en el tiempo restante.'
local _titles = { 'GANADOR', '2DO PUESTO', '3ER PUESTO' }
local _playerColors = { Color.YELLOW, Color.GREY, Color.BROWN }
local _playerPositions = { '1ro: ', '2do: ', '3ro: ' }
local _markerColor = Color.YELLOW

local _stockData = nil

local function getPlayerPoints()
	local player = table.ifind_if(_stockData.players, function(player)
		return player.id == Player.ServerId()
	end)

	return player and player.points or nil
end

RegisterNetEvent('lsv:startStockPiling')
AddEventHandler('lsv:startStockPiling', function(data, passedTime)
	if _stockData then
		return
	end

	-- Preparations
	_stockData = { }

	_stockData.startTime = GetGameTimer()
	if passedTime then
		_stockData.startTime = _stockData.startTime - passedTime
	end

	_stockData.players = data.players

	_stockData.checkPoints = data.checkPoints
	table.iforeach(_stockData.checkPoints, function(checkPoint)
		if checkPoint.picked then
			return
		end

		checkPoint.blip = Map.CreateEventBlip(Blip.CHECKPOINT, checkPoint.position.x, checkPoint.position.y, checkPoint.position.z, 'Checkpoint', Color.BLIP_YELLOW)
		Map.SetBlipFlashes(checkPoint.blip)
	end)

	_stockData.totalCheckPoints = data.totalCheckPoints
	_stockData.checkPointsCollected = data.checkPointsCollected

	-- GUI
	Citizen.CreateThread(function()
		if Player.IsInFreeroam() and not passedTime then
			Gui.StartEvent('Acumulador', _instructionsText)
		end

		while true do
			Citizen.Wait(0)

			if not _stockData then
				return
			end

			if Player.IsInFreeroam() then
				Gui.DisplayObjectiveText('Recoge mas ~y~checkpoints~w~.')

				Gui.DrawTimerBar('FIN DEL EVENTO', math.max(0, Settings.stockPiling.duration - GetGameTimer() + _stockData.startTime), 1)
				Gui.DrawBar('TU PUNTUACION', getPlayerPoints() or 0, 2)
				Gui.DrawBar('RESTANTE', (_stockData.totalCheckPoints - _stockData.checkPointsCollected)..'/'.._stockData.totalCheckPoints, 3)

				local barPosition = 4
				for i = barPosition - 1, 1, -1 do
					local data = _stockData.players[i]
					if data then
						Gui.DrawBar(_playerPositions[i]..GetPlayerName(GetPlayerFromServerId(data.id)), data.points, barPosition, _playerColors[i], true)
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

			if not _stockData then
				return
			end

			local playerPosition = Player.Position(true)
			local checkPoint, index = table.ifind_if(_stockData.checkPoints, function(checkPoint)
				return not checkPoint.picked and World.GetDistance(playerPosition, checkPoint.position, true) <= Settings.stockPiling.radius
			end)
			if checkPoint then
				checkPoint.picked = true
				TriggerServerEvent('lsv:stockPilingCheckPointCollected', index)
			else
				for _, checkPoint in ipairs(_stockData.checkPoints) do
					if not checkPoint.picked then
						Gui.DrawPlaceMarker(checkPoint.position, _markerColor, Settings.stockPiling.radius)

						if IsSphereVisible(checkPoint.position.x, checkPoint.position.y, checkPoint.position.z, Settings.stockPiling.radius) then
							DrawMarker(29, checkPoint.position.x, checkPoint.position.y, checkPoint.position.z + 1, 0., 0., 0., 0., 0.,0., 2.5, 2.5, 2.5, _markerColor[1], _markerColor[2], _markerColor[3], Settings.placeMarker.opacity, false, true)
						end
					end
				end
			end
		end
	end)
end)

RegisterNetEvent('lsv:updateStockPilingPlayers')
AddEventHandler('lsv:updateStockPilingPlayers', function(players, index, player)
	if not _stockData then
		return
	end

	_stockData.players = players

	if index then
		_stockData.checkPoints[index].picked = true

		RemoveBlip(_stockData.checkPoints[index].blip)
		_stockData.checkPoints[index].blip = nil

		_stockData.checkPointsCollected = _stockData.checkPointsCollected + 1

		if player == Player.ServerId() then
			PlaySoundFrontend(-1, 'CHECKPOINT_AHEAD', 'HUD_MINI_GAME_SOUNDSET', false)
			Gui.DisplayPersonalNotification('Recogiste un checkpoint.')
		end
	end
end)

RegisterNetEvent('lsv:finishStockPiling')
AddEventHandler('lsv:finishStockPiling', function(winners)
	if not _stockData then
		return
	end

	table.iforeach(_stockData.checkPoints, function(checkPoint)
		if checkPoint.blip then
			RemoveBlip(checkPoint.blip)
		end
	end)

	if not winners then
		_stockData = nil
		return
	end

	local playerPoints = getPlayerPoints()
	_stockData = nil

	local playerPosition = nil
	for i = 1, math.min(3, #winners) do
		if winners[i] == Player.ServerId() then
			playerPosition = i
			break
		end
	end

	local messageText = playerPosition and 'Ganaste Acumulador con una puntuacion de '..playerPoints or Gui.GetPlayerName(winners[1], '~p~')..' gano Acumulador.'

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
