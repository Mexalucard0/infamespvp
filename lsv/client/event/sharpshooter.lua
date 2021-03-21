local _instructionsText = 'Consigue la mayor cantidad de Headshots en el tiempo restante.'
local _titles = { 'GANADOR', '2DO PUESTO', '3ER PUESTO' }
local _playerColors = { Color.YELLOW, Color.GREY, Color.BROWN }
local _playerPositions = { '1ro: ', '2do: ', '3ro: ' }

local _sharpShooterData = nil

local function getPlayerPoints()
	local player = table.ifind_if(_sharpShooterData.players, function(player)
		return player.id == Player.ServerId()
	end)

	return player and player.points or nil
end

RegisterNetEvent('lsv:startSharpShooter')
AddEventHandler('lsv:startSharpShooter', function(data, passedTime)
	if _sharpShooterData then
		return
	end

	-- Preparations
	_sharpShooterData = { }

	_sharpShooterData.startTime = GetGameTimer()
	if passedTime then
		_sharpShooterData.startTime = _sharpShooterData.startTime - passedTime
	end

	_sharpShooterData.players = data.players

	-- GUI
	Citizen.CreateThread(function()
		if Player.IsInFreeroam() and not passedTime then
			Gui.StartEvent('Francotirador', _instructionsText)
		end

		while true do
			Citizen.Wait(0)

			if not _sharpShooterData then
				return
			end

			if Player.IsInFreeroam() then
				Gui.DisplayObjectiveText('Compite por la mayor cantidad de Headshots.')

				Gui.DrawTimerBar('FIN DEL EVENTO', math.max(0, Settings.sharpShooter.duration - GetGameTimer() + _sharpShooterData.startTime), 1)
				Gui.DrawBar('TU PUNTUACION', getPlayerPoints() or 0, 2)

				local barPosition = 3
				for i = barPosition, 1, -1 do
					local data = _sharpShooterData.players[i]
					if data then
						Gui.DrawBar(_playerPositions[i]..GetPlayerName(GetPlayerFromServerId(data.id)), data.points, barPosition, _playerColors[i], true)
						barPosition = barPosition + 1
					end
				end
			end
		end
	end)
end)

RegisterNetEvent('lsv:updateSharpShooterPlayers')
AddEventHandler('lsv:updateSharpShooterPlayers', function(players)
	if _sharpShooterData then
		_sharpShooterData.players = players
	end
end)

RegisterNetEvent('lsv:finishSharpShooter')
AddEventHandler('lsv:finishSharpShooter', function(winners)
	if not _sharpShooterData then
		return
	end

	if not winners then
		_sharpShooterData = nil
		return
	end

	local playerPoints = getPlayerPoints()
	_sharpShooterData = nil

	local playerPosition = nil
	for i = 1, math.min(3, #winners) do
		if winners[i] == Player.ServerId() then
			playerPosition = i
			break
		end
	end

	local messageText = playerPosition and 'Ganaste Francotirador con una puntuacion de '..playerPoints or Gui.GetPlayerName(winners[1], '~p~')..' gano Francotirador.'

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
