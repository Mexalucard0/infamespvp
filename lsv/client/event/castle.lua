local _titles = { 'GANADOR', '2DO PUESTO', '3ER PUESTO' }
local _instructionsText = 'Mantén el área del castillo solo para convertirte en el rey y ganar recompensas.'
local _playerColors = { Color.YELLOW, Color.GREY, Color.BROWN }
local _playerPositions = { '1ro: ', '2do: ', '3ro: ' }

local _castleData = nil

local function getPlayerPoints()
	local player = table.ifind_if(_castleData.players, function(player)
		return player.id == Player.ServerId()
	end)

	return player and player.points or nil
end

RegisterNetEvent('lsv:startCastle')
AddEventHandler('lsv:startCastle', function(data, passedTime)
	if _castleData then
		return
	end

	-- Preparations
	local place = Settings.castle.places[data.placeIndex]

	_castleData = { }

	_castleData.place = place
	_castleData.radius = place.radius or Settings.castle.radius

	_castleData.startTime = GetGameTimer()
	if passedTime then
		_castleData.startTime = _castleData.startTime - passedTime
	end

	_castleData.players = data.players

	-- GUI
	Citizen.CreateThread(function()
		if Player.IsInFreeroam() and not passedTime then
			Gui.StartEvent('Rey Del Castillo', _instructionsText)
		end

		_castleData.zoneBlip = Map.CreateRadiusBlip(place.x, place.y, place.z, _castleData.radius, Color.BLIP_PURPLE)
		_castleData.blip = Map.CreateEventBlip(Blip.CASTLE, place.x, place.y, place.z, nil, Color.BLIP_PURPLE)
		Map.SetBlipFlashes(_castleData.blip)

		while true do
			Citizen.Wait(0)

			if not _castleData then
				return
			end

			local isPlayerInFreeroam = Player.IsInFreeroam()

			SetBlipAlpha(_castleData.blip, isPlayerInFreeroam and 255 or 0)
			SetBlipAlpha(_castleData.zoneBlip, isPlayerInFreeroam and 128 or 0)

			if isPlayerInFreeroam then
				local objectiveText = ''
				if not World.KingOfTheCastlePlayer then
					objectiveText = 'Entra en el ~p~área del Castillo~w~ para convertirte en el Rey.'
				else
					if World.KingOfTheCastlePlayer == Player.ServerId() then
						objectiveText = 'Defiende el ~p~área del Castillo~w~.'
					else
						objectiveText = Gui.GetPlayerName(World.KingOfTheCastlePlayer, '~w~')..'<C> es el ~r~Rey~w~. Eliminalo.</C>'
					end
				end
				Gui.DisplayObjectiveText(objectiveText)

				Gui.DrawTimerBar('FIN DEL EVENTO', math.max(0, Settings.castle.duration - GetGameTimer() + _castleData.startTime), 1)
				Gui.DrawBar('TU PUNTUACION', getPlayerPoints() or 0, 2)

				local barPosition = 3
				for i = barPosition, 1, -1 do
					local data = _castleData.players[i]
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
		local pointTimer = nil
		local isInCastleArea = false

		while true do
			Citizen.Wait(0)

			if not _castleData then
				return
			end

			if Player.IsActive() and Player.DistanceTo(_castleData.place, true) <= _castleData.radius then
				if World.KingOfTheCastlePlayer == Player.ServerId() then
					if not pointTimer then
						pointTimer = Timer.New()
					elseif pointTimer:elapsed() >= 1000 then
						pointTimer:restart()
						TriggerServerEvent('lsv:castleAddPointToKing')
					end
				elseif not isInCastleArea and not World.KingOfTheCastlePlayer then
					isInCastleArea = true
					TriggerServerEvent('lsv:playerInCastleArea')
				end
			else
				isInCastleArea = false
				if World.KingOfTheCastlePlayer == Player.ServerId() then
					World.KingOfTheCastlePlayer = nil
					pointTimer = nil
					TriggerServerEvent('lsv:kingLeftCastleArea')
				end
			end
		end
	end)
end)

RegisterNetEvent('lsv:updateCastlePlayers')
AddEventHandler('lsv:updateCastlePlayers', function(players)
	if _castleData then
		_castleData.players = players
	end
end)

RegisterNetEvent('lsv:updateCastleKing')
AddEventHandler('lsv:updateCastleKing', function(king)
	if _castleData then
		World.KingOfTheCastlePlayer = king

		if not king and Player.DistanceTo(_castleData.place, true) <= _castleData.radius then
			TriggerServerEvent('lsv:playerInCastleArea')
		end
	end
end)

RegisterNetEvent('lsv:finishCastle')
AddEventHandler('lsv:finishCastle', function(winners)
	if not _castleData then
		return
	end

	RemoveBlip(_castleData.blip)
	RemoveBlip(_castleData.zoneBlip)

	World.KingOfTheCastlePlayer = nil

	if not winners then
		_castleData = nil
		return
	end

	local playerPoints = getPlayerPoints()
	_castleData = nil

	local playerPosition = nil
	for i = 1, math.min(3, #winners) do
		if winners[i] == Player.ServerId() then
			playerPosition = i
			break
		end
	end

	local messageText = playerPosition and 'Haz ganado Rey Del Castillo con una puntuacion de '..playerPoints or Gui.GetPlayerName(winners[1], '~p~')..' se ha convertido en el Rey del Castillo.'

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
