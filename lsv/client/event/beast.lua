local _titles = { 'GANADOR', '2DO PUESTO', '3ER PUESTO' }
local _playerColors = { Color.YELLOW, Color.GREY, Color.BROWN }
local _playerPositions = { '1ro: ', '2do: ', '3ro: ' }

local _beastData = nil

local function getPlayerPoints()
	local player = table.ifind_if(_beastData.players, function(player)
		return player.id == Player.ServerId()
	end)

	return player and player.points or nil
end

RegisterNetEvent('lsv:startHuntTheBeast')
AddEventHandler('lsv:startHuntTheBeast', function(data, passedTime)
	if _beastData then
		return
	end

	_beastData = { }

	_beastData.startTime = GetGameTimer()
	if passedTime then
		_beastData.startTime = _beastData.startTime - passedTime
	end

	_beastData.players = data.players
	World.BeastPlayer = data.beast

	-- GUI
	Citizen.CreateThread(function()
		if Player.IsInFreeroam() and not passedTime then
			Gui.StartEvent('Caza a la Bestia', 'Consigue la mayor cantidad de muertes mientras seas la Bestia.')
		end

		while true do
			Citizen.Wait(0)

			if not _beastData then
				return
			end

			if Player.IsInFreeroam() then
				Gui.DisplayObjectiveText(World.BeastPlayer == Player.ServerId() and 'MATALOS A TODOS.' or 'Caza a la ~r~Bestia~w~.')

				Gui.DrawTimerBar('FIN DEL EVENTO', math.max(0, Settings.huntTheBeast.duration - GetGameTimer() + _beastData.startTime), 1)
				Gui.DrawBar('TU PUNTUACION', getPlayerPoints() or 0, 2)

				local barPosition = 3
				for i = barPosition, 1, -1 do
					local data = _beastData.players[i]
					if data then
						Gui.DrawBar(_playerPositions[i]..GetPlayerName(GetPlayerFromServerId(data.id)), data.points, barPosition, _playerColors[i], true)
						barPosition = barPosition + 1
					end
				end
			end
		end
	end)
end)

RegisterNetEvent('lsv:finishHuntTheBeast')
AddEventHandler('lsv:finishHuntTheBeast', function(winners)
	if not _beastData then
		return
	end

	World.BeastPlayer = nil

	if not winners then
		_beastData = nil
		return
	end

	local playerPoints = getPlayerPoints()

	_beastData = nil

	local playerPosition = nil
	for i = 1, math.min(3, #winners) do
		if winners[i] == Player.ServerId() then
			playerPosition = i
			break
		end
	end

	local messageText = playerPosition and 'Ganaste la Caza de la Bestia con una puntacion de '..playerPoints or Gui.GetPlayerName(winners[1], '~p~')..' ha ganado la Caza de la Bestia.'

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

RegisterNetEvent('lsv:updateHuntTheBeastPlayers')
AddEventHandler('lsv:updateHuntTheBeastPlayers', function(players)
	if _beastData then
		_beastData.players = players
	end
end)

RegisterNetEvent('lsv:updateBeastPlayer')
AddEventHandler('lsv:updateBeastPlayer', function(beast)
	if _beastData then
		World.BeastPlayer = beast
	end
end)
