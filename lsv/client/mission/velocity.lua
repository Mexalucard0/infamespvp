local _vehicle = nil
local _vehicleNet = nil
local _vehicleBlip = nil
local _detonationSound = nil

local _helpHandler = nil

RegisterNetEvent('lsv:finishVelocity')
AddEventHandler('lsv:finishVelocity', function(success, reason)
	if _helpHandler then
		_helpHandler:cancel()
	end

	MissionManager.FinishMission(success)

	if not HasSoundFinished(_detonationSound) then
		StopSound(_detonationSound)
	end
	ReleaseSoundId(_detonationSound)
	_detonationSound = nil

	if _vehicleNet then
		_vehicle = NetToVeh(_vehicleNet)
	end

	if not success and not IsPedInVehicle(PlayerPedId(), _vehicle, false) then
		if _vehicleNet then
			_vehicle = NetToVeh(_vehicleNet)
			SetVehicleDoorsLockedForAllPlayers(_vehicle, true)
			Network.DeleteVehicle(_vehicleNet, 5000)
		else
			World.DeleteEntity(_vehicle)
		end
	end
	_vehicle = nil
	_vehicleNet = nil

	RemoveBlip(_vehicleBlip)
	_vehicleBlip = nil

	Gui.FinishMission('Velocity', success, reason)
end)

RegisterNetEvent('lsv:startVelocity')
AddEventHandler('lsv:startVelocity', function()
	local location = table.irandom(Settings.velocity.locations)

	Streaming.RequestModelAsync(`voltic2`)
	_vehicle = CreateVehicle(`voltic2`, location.x, location.y, location.z, location.heading, false, true)
	SetVehicleModKit(_vehicle, 0)
	SetVehicleMod(_vehicle, 16, 4)
	SetVehicleTyresCanBurst(_vehicle, false)
	SetModelAsNoLongerNeeded(`voltic2`)

	_detonationSound = GetSoundId()

	local isInVehicle = false
	local preparationStage = nil
	local detonationStage = nil

	local missionTimer = GetGameTimer()
	local startTimeToDetonate = GetGameTimer()
	local startPreparationStageTime = GetGameTimer()
	local almostDetonated = 0

	_vehicleBlip = Map.CreateEntityBlip(_vehicle, Blip.ROCKET_VOLTIC, nil, Color.BLIP_GREEN)
	SetBlipRoute(_vehicleBlip, true)
	Map.SetBlipFlashes(_vehicleBlip)

	Gui.StartMission('Velocity', 'Entra en el Rocket Voltic y mantente a máxima velocidad para evitar la detonación..')

	Citizen.CreateThread(function()
		while true do
			Citizen.Wait(0)

			if not MissionManager.Mission then
				return
			end

			SetBlipAlpha(_vehicleBlip, isInVehicle and 0 or 255)

			if Player.IsActive() then
				local totalTime = Settings.velocity.enterVehicleTime

				if preparationStage then
					totalTime = Settings.velocity.preparationTime
				elseif isInVehicle then
					totalTime = Settings.velocity.driveTime
				end

				if isInVehicle then
					if _vehicleNet then
						_vehicle = NetToVeh(_vehicleNet)
					end

					Gui.DrawBar('VELOCIDAD', string.to_speed(GetEntitySpeed(_vehicle)), 2)

					if detonationStage then
						Gui.DrawProgressBar('DETONANTE', 1.0 - (Settings.velocity.detonationTime - GetGameTimer() + startTimeToDetonate) / Settings.velocity.detonationTime, 3, Color.RED)
					end
				end

				local title = preparationStage and 'BOMBA ACTIVA EN' or 'TIEMPO DE MISION'
				local startTime = preparationStage and startPreparationStageTime or missionTimer
				local timeLeft = totalTime - GetGameTimer() + startTime

				Gui.DrawTimerBar(title, timeLeft, 1)

				Gui.DisplayObjectiveText(isInVehicle and 'Mantente arriba de '..string.to_speed(Settings.velocity.minSpeed)..' para evitar la detonacion.' or 'Entra en el ~g~Rocket Voltic~w~.')
			end
		end
	end)

	while true do
		Citizen.Wait(0)

		if not MissionManager.Mission then
			return
		end

		if not DoesEntityExist(_vehicle) or not IsVehicleDriveable(_vehicle, false) then
			TriggerEvent('lsv:finishVelocity', false, 'El vehiculo ha sido destruido.')
			return
		end

		if _vehicleNet then
			_vehicle = NetToVeh(_vehicleNet)
		end

		isInVehicle = IsPedInVehicle(PlayerPedId(), _vehicle, false)
		if isInVehicle then
			if not _vehicleNet then
				_vehicleNet = Network.RegisterVehicle(_vehicle)
			else
				if preparationStage == nil then
					preparationStage = true
					startPreparationStageTime = GetGameTimer()
				elseif preparationStage then
					if GetTimeDifference(GetGameTimer(), startPreparationStageTime) >= Settings.velocity.preparationTime then
						preparationStage = false
						missionTimer = GetGameTimer()
						_helpHandler = HelpQueue.PushFront('Evite el estado casi detonado para obtener una recompensa adicional.')
					end
				elseif GetTimeDifference(GetGameTimer(), missionTimer) < Settings.velocity.driveTime then
					local vehicleSpeed = GetEntitySpeed(_vehicle)

					if vehicleSpeed < Settings.velocity.minSpeed then
						if not detonationStage then
							detonationStage = true
							startTimeToDetonate = GetGameTimer()
							TriggerServerEvent('lsv:velocityAboutToDetonate')
							almostDetonated = almostDetonated + 1
							PlaySoundFrontend(_detonationSound, '5s_To_Event_Start_Countdown', 'GTAO_FM_Events_Soundset', false)
						end

						if GetTimeDifference(GetGameTimer(), startTimeToDetonate) >= Settings.velocity.detonationTime then
							NetworkExplodeVehicle(_vehicle, true, false, false)
							Network.DeleteVehicle(_vehicleNet, 5000)

							TriggerEvent('lsv:finishVelocity', false, 'La bomba ha detonado.')
							return
						end
					elseif detonationStage then
						if not HasSoundFinished(_detonationSound) then StopSound(_detonationSound) end
						detonationStage = false
					end
				else
					TriggerServerEvent('lsv:finishVelocity')
					return
				end
			end
		else
			if _vehicleNet then
				TriggerEvent('lsv:finishVelocity', false, 'Has dejado el vehiculo.')
				return
			end

			if GetTimeDifference(GetGameTimer(), missionTimer) >= Settings.velocity.enterVehicleTime then
				TriggerEvent('lsv:finishVelocity', false, 'El tiempo se acabo.')
				return
			end
		end
	end
end)
