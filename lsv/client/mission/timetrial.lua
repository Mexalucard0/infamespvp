local _missionName = 'Contrarreloj'

local _markerRadius = 5.0
local _markerHeight = 2.0
local _markerScale = 2.0
local _markerColor = { Color.YELLOW[1], Color.YELLOW[2], Color.YELLOW[3], 72 }

local _checkpointRadius = 3.5
local _checkpointThreshold = 2.0
local _checkpointScale = 5.0
local _checkpointColor = { Color.BLUE[1], Color.BLUE[2], Color.BLUE[3], 228 }

local _trialRecords = { }
local _trialBlips = { }

local _trialId = nil
local _trialCheckpoint = nil

local _places = {
	{ title = 'ORO', color = Color.YELLOW },
	{ title = 'PLATA', color = Color.GREY },
	{ title = 'BRONCE', color = Color.BROWN },
}

local function getTrialPlace(time)
	local places = Settings.timeTrial.tracks[_trialId].time

	for place = 1, 2 do
		if time <= places[place] then
			return place
		end
	end

	return 3
end

local function drawMissionTimeBar(time)
	local place = getTrialPlace(time)
	Gui.DrawTimerBar(_places[place].title, time, 1, false, _places[place].color, true)
end

local function getTrialRecord(trialId)
	local recordData = _trialRecords[trialId]
	if recordData then
		return recordData.PlayerName..' | '..string.from_ms(recordData.Time, true)
	else
		return '-'
	end
end

local function getPlayerTrialBest(trialId)
	local record = Player.Records[trialId]

	if record then
		return string.from_ms(record, true)
	else
		return '-'
	end
end

local function clearCheckpoint()
	if not _trialCheckpoint then
		return
	end

	DeleteCheckpoint(_trialCheckpoint.id)
	table.iforeach(_trialCheckpoint.blips, function(blip)
		RemoveBlip(blip)
	end)

	_trialCheckpoint = nil
end

local function createCheckpoint(index)
	local isFinish = index == #Settings.timeTrial.tracks[_trialId].checkpoints

	local checkpoint1 = Settings.timeTrial.tracks[_trialId].checkpoints[index]
	local checkpoint2 = isFinish and checkpoint1 or Settings.timeTrial.tracks[_trialId].checkpoints[index + 1]

	local blipSprite = isFinish and Blip.CREW_RACE_FINISH or Blip.STANDARD
	local blipColour = isFinish and Color.BLIP_WHITE or Color.BLIP_YELLOW

	_trialCheckpoint = { }
	_trialCheckpoint.id = CreateCheckpoint(isFinish and 19 or checkpoint1.type, checkpoint1.x, checkpoint1.y, checkpoint1.z + 3.0, checkpoint2.x, checkpoint2.y, checkpoint2.z, _checkpointScale, table.unpack(_checkpointColor))

	_trialCheckpoint.blips = { }
	local blip = Map.CreatePlaceBlip(blipSprite, checkpoint1.x, checkpoint1.y, checkpoint1.z, nil, blipColour)
	SetBlipAsShortRange(blip, false)
	table.insert(_trialCheckpoint.blips, blip)

	if not isFinish then
		local blip = Map.CreatePlaceBlip(blipSprite, checkpoint2.x, checkpoint2.y, checkpoint2.z, nil, Color.BLIP_YELLOW)
		SetBlipScale(blip, 0.65)
		SetBlipAsShortRange(blip, false)
		table.insert(_trialCheckpoint.blips, blip)
	end
end

local function updateCheckpoint(index)
	clearCheckpoint()
	createCheckpoint(index)
end

RegisterNetEvent('lsv:initTimeTrialRecords')
AddEventHandler('lsv:initTimeTrialRecords', function(records)
	_trialRecords = records
end)

RegisterNetEvent('lsv:updateTimeTrialRecord')
AddEventHandler('lsv:updateTimeTrialRecord', function(trialId, data)
	_trialRecords[trialId] = data
end)

RegisterNetEvent('lsv:finishTimeTrial')
AddEventHandler('lsv:finishTimeTrial', function(success, reason)
	MissionManager.FinishMission(success)

	clearCheckpoint()

	if success then
		AnimpostfxPlay('SuccessMichael', 0, false)
	end

	Gui.FinishMission(_missionName, success, reason)
end)

AddEventHandler('lsv:startTimeTrial', function(trialId)
	_trialId = trialId

	local startingPosition = Settings.timeTrial.tracks[trialId].position

	local vehicle = GetVehiclePedIsIn(PlayerPedId())
	FreezeEntityPosition(vehicle, true)
	SetEntityCoords(vehicle, startingPosition.x, startingPosition.y, startingPosition.z)
	SetEntityHeading(vehicle, startingPosition.heading)

	local checkpoints = Settings.timeTrial.tracks[trialId].checkpoints
	local totalCheckpoints = #checkpoints

	local checkpointIndex = 1

	local wasTrialStarted = false
	local countdownScaleform = Scaleform.NewAsync('COUNTDOWN')
	local countdownMessages = { '3', '2', '1', 'GO' }
	local countdownTimer = Timer.New()

	local missionTimer = nil

	while true do
		Citizen.Wait(0)

		if not MissionManager.Mission then
			return
		end

		if IsPlayerDead(PlayerId()) then
			TriggerEvent('lsv:finishTimeTrial', false)
			return
		end

		if not IsPedInAnyVehicle(PlayerPedId()) then
			TriggerEvent('lsv:finishTimeTrial', false, 'Has dejado el vehiculo.')
			return
		end

		if not IsVehicleDriveable(GetVehiclePedIsIn(PlayerPedId())) then
			TriggerEvent('lsv:finishTimeTrial', false, 'Tu vehiculo ha sido destruido.')
			return
		end

		local playerPosition = Player.Position()
		if not wasTrialStarted and World.GetDistance(playerPosition, startingPosition, true) > _markerRadius then
			TriggerEvent('lsv:finishTimeTrial', false, 'Has salido de la posicion inicial.')
			return
		end

		if not wasTrialStarted then
			if countdownTimer:elapsed() > 1000 then
				local isGo = #countdownMessages == 1
				local color = isGo and Color.RED or Color.WHITE

				PlaySoundFrontend(-1, isGo and 'GO' or '3_2_1', 'HUD_MINI_GAME_SOUNDSET', true)
				countdownScaleform:call('SET_MESSAGE', countdownMessages[1], color[1], color[2], color[3], false)

				if isGo then
					AnimpostfxPlay('SuccessMichael', 0, false)

					missionTimer = Timer.New()

					Citizen.CreateThread(function()
						while true do
							Citizen.Wait(0)

							if not MissionManager.Mission then
								return
							end

							if Player.IsActive() then
								local barIndex = 3

								if Player.Records[trialId] then
									Gui.DrawTimerBar('RECORD PERSONAL', Player.Records[trialId], barIndex, false, Color.WHITE, true)
									barIndex = barIndex + 1
								end

								if _trialRecords[trialId] then
									Gui.DrawTimerBar('MEJOR DEL SERVER', _trialRecords[trialId].Time, barIndex, false, Color.WHITE, true)
									barIndex = barIndex + 1
								end

								Gui.DrawBar('CHECKPOINTS TOTALES', tostring(checkpointIndex - 1)..'/'..totalCheckpoints, 2)
								drawMissionTimeBar(missionTimer:elapsed())
							end
						end
					end)

					countdownTimer:restart()
					FreezeEntityPosition(vehicle, false)
					updateCheckpoint(checkpointIndex)
					wasTrialStarted = true
				else
					table.remove(countdownMessages, 1)
					countdownTimer:restart()
				end
			end

			countdownScaleform:render(0.5, 0.25, 1.0, 1.0)
		else
			if countdownTimer:elapsed() < 1000 then
				countdownScaleform:render(0.5, 0.25, 1.0, 1.0)
			end

			Gui.DrawPlaceMarker(checkpoints[checkpointIndex], _markerColor, _checkpointRadius)

			if World.GetDistance(playerPosition, checkpoints[checkpointIndex], true) < _checkpointRadius + _checkpointThreshold then
				if checkpointIndex == #checkpoints then
					TriggerServerEvent('lsv:finishTimeTrial', _trialId, missionTimer:elapsed(), getTrialPlace(missionTimer:elapsed()))
					return
				else
					PlaySoundFrontend(-1, 'CHECKPOINT_NORMAL', 'HUD_MINI_GAME_SOUNDSET', true)
					checkpointIndex = checkpointIndex + 1
					updateCheckpoint(checkpointIndex)
				end
			end
		end
	end
end)

AddEventHandler('lsv:init', function()
	local _timeTrialMenuId = nil

	Gui.CreateMenu('timeTrial', 'Contrarreloj')
	WarMenu.SetTitleBackgroundColor('timeTrial', table.unpack(Color.PURPLE))

	table.foreach(Settings.timeTrial.tracks, function(track, id)
		_trialBlips[id] = Map.CreatePlaceBlip(Blip.TIME_TRIAL, track.position.x,  track.position.y,  track.position.z, _missionName, Color.BLIP_PURPLE)
	end)

	while true do
		Citizen.Wait(0)

		local isPlayerInFreeroam = Player.IsInFreeroam()
		local playerPosition = Player.Position()

		for trialId, track in pairs(Settings.timeTrial.tracks) do
			SetBlipAlpha(_trialBlips[trialId], isPlayerInFreeroam and 255 or 0)

			if isPlayerInFreeroam then
				Gui.DrawPlaceMarker(track.position, Color.PURPLE, _markerRadius, _markerHeight)
				Gui.DrawMarker(36, { x = track.position.x, y = track.position.y, z = track.position.z + _markerHeight }, Color.PURPLE, _markerScale, nil, true)

				if World.GetDistance(playerPosition, track.position, true) < _markerRadius then
					if not WarMenu.IsMenuOpened() then
						local playerPed = PlayerPedId()
						if not IsPedInAnyVehicle(playerPed) or IsPedInAnyHeli(playerPed) or IsPedInAnyPlane(playerPed) then
							Gui.DisplayHelpText('Necesitas estar en un vehículo adecuado para comenzar Contrarreloj~w~..')
						else
							local vehicle = GetVehiclePedIsIn(playerPed)
							if GetPedInVehicleSeat(vehicle, -1) == playerPed then
								Gui.DisplayHelpText('Presiona ~INPUT_TALK~ para iniciar '.._missionName..'.')

								if IsControlJustReleased(0, 46) then
									_timeTrialMenuId = trialId
									WarMenu.SetSubTitle('timeTrial', track.name)
									Gui.OpenMenu('timeTrial')
								end
							end
						end
					end
				elseif WarMenu.IsMenuOpened('timeTrial') and _timeTrialMenuId == trialId then
					WarMenu.CloseMenu()
				end
			end
		end

		if WarMenu.IsMenuOpened('timeTrial') then
			if WarMenu.Button('Iniciar') then
				WarMenu.CloseMenu()
				MissionManager.StartMission('TimeTrial', _missionName)
				TriggerEvent('lsv:startTimeTrial', _timeTrialMenuId)
			elseif WarMenu.Button('Mejor del servidor', getTrialRecord(_timeTrialMenuId)) then
			elseif WarMenu.Button('Record personal', getPlayerTrialBest(_timeTrialMenuId)) then
			end

			WarMenu.Display()
		end
	end
end)
