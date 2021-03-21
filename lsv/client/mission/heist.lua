local _heist = nil

local function spawnMoneyPickup(coords)
	_heist.moneyPicked = false
	_heist.moneyPickup = CreatePickupRotate(`PICKUP_MONEY_CASE`, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 8, false, true)
	_heist.moneyPickupBlip = Map.CreatePickupBlip(_heist.moneyPickup, Blip.HOSTILE_BRIEFCASE, 'Money Case', Color.BLIP_GREEN)
	Map.SetBlipFlashes(_heist.moneyPickupBlip)
end

AddEventHandler('lsv:finishHeist', function(success, reason)
	TriggerServerEvent('lsv:finishHeist', success, reason)
end)

RegisterNetEvent('lsv:heistFinished')
AddEventHandler('lsv:heistFinished', function(success, reason)
	MissionManager.FinishMission(success)

	World.EnableWanted(false)

	SetModelAsNoLongerNeeded(`stockade`)
	table.iforeach(Settings.heist.peds.models, function(modelHash)
		SetModelAsNoLongerNeeded(modelHash)
	end)

	if _heist.vehNetId then
		Network.DeleteVehicle(_heist.vehNetId, 5000)
	end

	if _heist.pedNetIds then
		table.iforeach(_heist.pedNetIds, function(pedNetId)
			Network.DeletePed(pedNetId)
		end)
	end

	RemoveBlip(_heist.blip)

	if _heist.moneyPickup then
		RemovePickup(_heist.moneyPickup)

		if _heist.moneyPickupBlip then
			RemoveBlip(_heist.moneyPickupBlip)
		end
	end

	_heist = nil

	Gui.FinishMission('Atraco', success, reason)
end)

RegisterNetEvent('lsv:startHeist')
AddEventHandler('lsv:startHeist', function()
	Gui.StartMission('Atraco', 'Roba el dinero de la furgoneta blindada y pierde a la policía.')

	_heist = { }
	_heist.location = table.irandom(Settings.heist.locations)
	_heist.blip = Map.CreatePlaceBlip(nil, _heist.location.x, _heist.location.y, _heist.location.z, nil, Color.BLIP_YELLOW)
	SetBlipAsShortRange(_heist.blip, false)
	Map.SetBlipFlashes(_heist.blip)

	_heist.missionTimer = Timer.New()

	World.EnableWanted(true)

	Citizen.CreateThread(function()
		while true do
			Citizen.Wait(0)

			if not MissionManager.Mission then
				return
			end

			if Player.IsActive() then
				Gui.DrawTimerBar('TIEMPO DE MISION', Settings.heist.time - _heist.missionTimer:elapsed(), 1)

				if not _heist.vehNetId then
					Gui.DisplayObjectiveText('Ve a la ~y~Ubicación De La Furgoneta Blindada~w~.')
				elseif not _heist.doorsWereOpened then
					Gui.DisplayObjectiveText('Usa bombas adhesivas para abrir las puertas traseras de la furgoneta blindada.')
				elseif not _heist.moneyPicked then
					Gui.DisplayObjectiveText('Recoge el ~g~maletin de dinero~w~.')
				else
					Gui.DisplayObjectiveText('Pierde a la policia.')
				end
			end
		end
	end)

	while true do
		Citizen.Wait(0)

		if not MissionManager.Mission then
			return
		end

		if _heist.missionTimer:elapsed() > Settings.heist.time then
			TriggerEvent('lsv:finishHeist', false, 'El tiempo se acabo.')
			return
		end

		if _heist.vehNetId and not _heist.moneyPickup then
			if NetworkDoesEntityExistWithNetworkId(_heist.vehNetId) then
				local vehicle = NetToVeh(_heist.vehNetId)
				if not IsVehicleDriveable(vehicle) then
					TriggerEvent('lsv:finishHeist', false, 'La Furgoneta Blindada Fue Destruida.')
					return
				end
			end
		end

		if not _heist.vehNetId then
			Streaming.RequestModelAsync(`stockade`)
			if Player.DistanceTo(_heist.location, true) <= Settings.worldModifierDistance then
				local coords = World.TryGetClosestVehicleNode(_heist.location, Settings.heist.radius, math.random(25, 42)) or _heist.location
				local vehNetId = Network.CreateVehicle(`stockade`, coords.position, coords.heading)
				if vehNetId then
					_heist.vehNetId = vehNetId

					GiveWeaponToPed(PlayerPedId(), `WEAPON_STICKYBOMB`, Settings.heist.stickyBombCount, false)
				end
			end
		elseif not _heist.pedNetIds then
			if NetworkDoesEntityExistWithNetworkId(_heist.vehNetId) then
				local vehicle = NetToVeh(_heist.vehNetId)
				SetVehicleDoorsLockedForAllPlayers(vehicle, true)

				RemoveBlip(_heist.blip)
				_heist.blip = Map.CreateEntityBlip(vehicle, Blip.ARMOURED_VAN)
				Map.SetBlipFlashes(_heist.blip)

				_heist.pedNetIds = { }
				_heist.pedSeatIndex = 1
			end
		elseif _heist.pedSeatIndex <= #Settings.heist.peds.seatIndexes then
			if NetworkDoesEntityExistWithNetworkId(_heist.vehNetId) and Network.RequestControlOfNetworkId(_heist.vehNetId) then
				local vehSeatIndex = Settings.heist.peds.seatIndexes[_heist.pedSeatIndex]

				if _heist.pedNetIds[_heist.pedSeatIndex] then
					local pedNetId = _heist.pedNetIds[_heist.pedSeatIndex]
					if NetworkDoesEntityExistWithNetworkId(pedNetId) and Network.RequestControlOfNetworkId(pedNetId) then
						local ped = NetToPed(pedNetId)

						SetPedRandomComponentVariation(ped, false)
						SetEntityLoadCollisionFlag(ped, true, 1)

						local weaponHash = table.irandom(Settings.heist.peds.weapons)
						GiveWeaponToPed(ped, weaponHash, 99999, false, true)
						SetPedInfiniteAmmo(ped, true, weaponHash)
						SetPedArmour(ped, 100)
						SetPedDropsWeaponsWhenDead(ped, false)
						SetPedFleeAttributes(ped, 0, false)
						SetPedCombatRange(ped, 2)
						SetPedCombatMovement(ped, 2)
						SetPedCombatAttributes(ped, 46, true)
						SetPedCombatAttributes(ped, 20, true)
						SetPedCombatAbility(ped, 3)
						SetRagdollBlockingFlags(ped, 1)

						SetPedAsEnemy(ped, true)
						SetPedRelationshipGroupHash(ped, `SECURITY_GUARD`)

						if vehSeatIndex == -1 then -- driver
							_heist.driverNetId = pedNetId
							TaskVehicleDriveWander(ped, NetToVeh(_heist.vehNetId), 20., 319)
						end

						_heist.pedSeatIndex = _heist.pedSeatIndex + 1
					end
				else
					local modelHash = table.irandom(Settings.heist.peds.models)
					Streaming.RequestModelAsync(modelHash)
					local pedNetId = Network.CreatePedInsideVehicle(_heist.vehNetId, 11, modelHash, vehSeatIndex)
					if pedNetId then
						table.insert(_heist.pedNetIds, pedNetId)
					end
				end
			end
		elseif not _heist.moneyPickup then
			if NetworkDoesEntityExistWithNetworkId(_heist.vehNetId) then
				local vehicle = NetToVeh(_heist.vehNetId)
				if GetVehicleDoorAngleRatio(vehicle, 2) > 0. and GetVehicleDoorAngleRatio(vehicle, 3) > 0. then
					if NetworkDoesEntityExistWithNetworkId(_heist.driverNetId) then
						local ped = NetToPed(_heist.driverNetId)
						if not IsEntityDead(ped) then
							if Network.RequestControlOfNetworkId(_heist.driverNetId) then
								local seq = OpenSequenceTask()
								TaskLeaveVehicle(-1, vehicle, 1)
								TaskCombatPed(-1, PlayerPedId(), 0, 16)
								CloseSequenceTask(seq)

								TaskPerformSequence(ped, seq)
							end
						end
					end

					_heist.doorsWereOpened = true

					spawnMoneyPickup(GetOffsetFromEntityInWorldCoords(vehicle, 0., -5., 0))
				end
			end
		elseif not _heist.moneyPicked then
			if HasPickupBeenCollected(_heist.moneyPickup) then
				World.SetWantedLevel(3)
				Gui.DisplayPersonalNotification('Has recogido el maletin con dinero.')
				RemoveBlip(_heist.moneyPickupBlip)
				_heist.moneyPickupBlip = nil
				_heist.moneyPicked = true
			else
				local coords = GetPickupCoords(_heist.moneyPickup)
				Gui.DrawEntityMarker(coords, Color.GREEN)
			end
		else
			local player = PlayerId()

			if IsPlayerDead(player) then
				spawnMoneyPickup(Player.Position())
			elseif GetPlayerWantedLevel(player) == 0 then
				TriggerEvent('lsv:finishHeist', true)
				return
			end
		end
	end
end)
