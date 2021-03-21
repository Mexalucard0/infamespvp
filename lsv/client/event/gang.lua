local _instructionsText = 'Mata a la mayor cantidad de jugadores de las Crews opuestas..'
local _titles = { 'GANADOR', '2DO PUESTO', '3ER PUESTO' }
local _crewColors = { Color.YELLOW, Color.GREY, Color.BROWN }
local _crewPositions = { '1ra: ', '2da: ', '3ra: ' }

local _gangData = nil

local function getCrewPoints()
	if not Player.CrewLeader then
		return nil
	end

	local crew = table.ifind_if(_gangData.crews, function(crewData)
		return crewData.id == Player.CrewLeader
	end)

	return crew and crew.points or nil
end

RegisterNetEvent('lsv:startGangWars')
AddEventHandler('lsv:startGangWars', function(data, passedTime)
	if _gangData then
		return
	end

	-- Preparations
	_gangData = { }

	_gangData.startTime = GetGameTimer()
	if passedTime then
		_gangData.startTime = _gangData.startTime - passedTime
	end

	_gangData.crews = data.crews

	-- GUI
	Citizen.CreateThread(function()
		if Player.IsInFreeroam() and not passedTime then
			Gui.StartEvent('Guerra De Bandas', _instructionsText)
		end

		while true do
			Citizen.Wait(0)

			if not _gangData then
				return
			end

			if Player.IsInFreeroam() then
				local isInCrew = Player.CrewLeader ~= nil
				Gui.DisplayObjectiveText(isInCrew and _instructionsText or 'Unete a una Crew para participar en la Guerra de Bandas.')

				if isInCrew then
					Gui.DrawTimerBar('FIN DEL EVENTO', math.max(0, Settings.gangWars.duration - GetGameTimer() + _gangData.startTime), 1)
					Gui.DrawBar('PUNTAJE DE TU CREW ', getCrewPoints() or 0, 2)

					local barPosition = 3
					for i = barPosition, 1, -1 do
						local data = _gangData.crews[i]
						if data then
							Gui.DrawBar(_crewPositions[i]..GetPlayerName(GetPlayerFromServerId(data.id))..' Crew', data.points, barPosition, _crewColors[i], true)
							barPosition = barPosition + 1
						end
					end
				end
			end
		end
	end)
end)

RegisterNetEvent('lsv:updateGangWarsCrews')
AddEventHandler('lsv:updateGangWarsCrews', function(crews)
	if _gangData then
		_gangData.crews = crews
	end
end)

RegisterNetEvent('lsv:finishGangWars')
AddEventHandler('lsv:finishGangWars', function(winners)
	if not _gangData then
		return
	end

	if not winners then
		_gangData = nil
		return
	end

	local crewPoints = getCrewPoints()
	_gangData = nil

	local crewPosition = nil
	for i = 1, math.min(3, #winners) do
		if winners[i] == Player.CrewLeader then
			crewPosition = i
			break
		end
	end

	local messageText = crewPosition and 'Tu Crew gano la Guerra de Bandas con una puntuacion de '..crewPoints or Gui.GetPlayerName(winners[1], '~p~')..' Crew gano la Guerra de Bandas.'

	if Player.IsInFreeroam() and crewPoints then
		if crewPosition then
			PlaySoundFrontend(-1, 'Mission_Pass_Notify', 'DLC_HEISTS_GENERAL_FRONTEND_SOUNDS', true)
		else
			PlaySoundFrontend(-1, 'ScreenFlash', 'MissionFailedSounds', true)
		end

		local scaleform = Scaleform.NewAsync('MIDSIZED_MESSAGE')
		scaleform:call('SHOW_SHARD_MIDSIZED_MESSAGE', crewPosition and _titles[crewPosition] or 'TU CREW PERDIO', messageText, 21)
		scaleform:renderFullscreenTimed(10000)
	else
		Gui.DisplayNotification(messageText)
	end
end)
