local _hostile = nil

AddEventHandler('lsv:finishHostileTakeover', function(success, reason)
	TriggerServerEvent('lsv:finishHostileTakeover', success, reason)
end)

RegisterNetEvent('lsv:hostileTakeoverFinished')
AddEventHandler('lsv:hostileTakeoverFinished', function(success, reason)
	MissionManager.FinishMission(success)

	World.EnableWanted(false)

	table.iforeach(_hostile.location.models, function(modelHash)
		SetModelAsNoLongerNeeded(modelHash)
	end)

	table.iforeach(_hostile.pedNetIds, function(netId)
		Network.DeletePed(nedId)
	end)

	if _hostile.briefcase then
		RemovePickup(_hostile.briefcase)
	end

	RemoveBlip(_hostile.blip)

	_hostile = nil

	Gui.FinishMission('Toma El Control', success, reason)
end)

RegisterNetEvent('lsv:startHostileTakeover')
AddEventHandler('lsv:startHostileTakeover', function()
	Gui.StartMission('Toma El Control', 'Recupera el maletín y dejalo en el lugar de entrega..')

	_hostile = { }
	_hostile.packageRetrieved = false

	_hostile.location = table.irandom(Settings.hostile.locations)
	_hostile.blip = Map.CreatePlaceBlip(nil, _hostile.location.blip.x, _hostile.location.blip.y, _hostile.location.blip.z, nil, Color.BLIP_YELLOW)
	SetBlipAsShortRange(_hostile.blip, false)
	Map.SetBlipFlashes(_hostile.blip)

	_hostile.dropOff = table.irandom(Settings.hostile.dropOffs)

	_hostile.pedNetIds = { }
	_hostile.pedsCount = #_hostile.location.peds
	_hostile.pedBriefcaseIndex = math.random(_hostile.pedsCount)
	_hostile.briefcase = nil
	_hostile.missionTimer = Timer.New()

	World.EnableWanted(true)

	Citizen.CreateThread(function()
		while true do
			Citizen.Wait(0)

			if not MissionManager.Mission then
				return
			end

			if Player.IsActive() then
				Gui.DrawTimerBar('TIEMPO DE MISION', Settings.hostile.time - _hostile.missionTimer:elapsed(), 1)

				if _hostile.packageRetrieved then
					Gui.DisplayObjectiveText('Entrega el maletin en el ~y~lugar de entrega~w~.')
				elseif not _hostile.pedNetIds[_hostile.pedBriefcaseIndex] then
					Gui.DisplayObjectiveText('Ve a la ~y~ubicacion~w~.')
				else
					Gui.DisplayObjectiveText('Recupera el ~r~maletin~w~.')
				end
			end
		end
	end)

	while true do
		Citizen.Wait(0)

		if not MissionManager.Mission then
			return
		end

		if _hostile.missionTimer:elapsed() >= Settings.hostile.time then
			TriggerEvent('lsv:finishHostileTakeover', false, 'El tiempo se acabo.')
			return
		end

		if _hostile.pedsCount ~= table.length(_hostile.pedNetIds) then
			if Player.DistanceTo(_hostile.location.blip, true) <= Settings.worldModifierDistance then
				for locationIndex, location in ipairs(_hostile.location.peds) do
					if not _hostile.pedNetIds[locationIndex] then
						local modelHash = _hostile.location.models[#_hostile.location.models]
						Streaming.RequestModelAsync(modelHash)

						local netId = Network.CreatePed(11, modelHash, location, location.heading)
						if netId then
							local ped = NetToPed(netId)

							SetPedRandomComponentVariation(ped, false)
							SetEntityLoadCollisionFlag(ped, true, 1)
							PlaceObjectOnGroundProperly(ped)

							local weaponHash = table.irandom(_hostile.location.weapons)
							GiveWeaponToPed(ped, weaponHash, 99999, false, true)
							SetPedInfiniteAmmo(ped, true, weaponHash)
							SetPedArmour(ped, 50)

							if locationIndex == _hostile.pedBriefcaseIndex then
								SetPedSuffersCriticalHits(ped, false)
								RemoveBlip(_hostile.blip)
								_hostile.blip = Map.CreateEntityBlip(ped, Blip.HOSTILE_BRIEFCASE, 'Maletin', Color.BLIP_RED)
								Map.SetBlipFlashes(_hostile.blip)
							end

							SetPedDropsWeaponsWhenDead(ped, false)
							SetPedFleeAttributes(ped, 0, false)
							SetPedCombatRange(ped, 2)
							SetPedCombatMovement(ped, 2)
							SetPedCombatAttributes(ped, 46, true)
							SetPedCombatAttributes(ped, 20, true)
							SetPedCombatAbility(ped, 3)
							SetRagdollBlockingFlags(ped, 1)

							SetPedAsEnemy(ped, true)
							SetPedRelationshipGroupHash(ped, `HATES_PLAYER`)

							_hostile.pedNetIds[locationIndex] = netId
						end
					end
				end
			end
		else
			if _hostile.briefcase then
				if not _hostile.packageRetrieved then
					if HasPickupBeenCollected(_hostile.briefcase) then
						_hostile.packageRetrieved = true
						Gui.DisplayPersonalNotification('Recogiste el maletin.')
						World.SetWantedLevel(4)
						RemoveBlip(_hostile.blip)
						_hostile.blip = Map.CreatePlaceBlip(nil, _hostile.dropOff.x, _hostile.dropOff.y, _hostile.dropOff.z, nil, Color.BLIP_YELLOW)
						SetBlipAsShortRange(_hostile.blip, false)
						SetBlipRouteColour(_hostile.blip, Color.BLIP_YELLOW)
						SetBlipRoute(_hostile.blip, true)
					else
						local coords = GetPickupCoords(_hostile.briefcase)
						Gui.DrawEntityMarker(coords, Color.RED)
					end
				else
					Gui.DrawPlaceMarker(_hostile.dropOff, Color.YELLOW)

					if Player.DistanceTo(_hostile.dropOff, true) <= Settings.hostile.dropRadius then
						TriggerEvent('lsv:finishHostileTakeover', true)
						return
					end
				end
			else
				local pedBriefcaseNetId = _hostile.pedNetIds[_hostile.pedBriefcaseIndex]

				if NetworkDoesEntityExistWithNetworkId(pedBriefcaseNetId) then
					local ped = NetToPed(pedBriefcaseNetId)
					local coords = GetEntityCoords(ped)

					if IsEntityDead(ped) then
						_hostile.briefcase = CreatePickupRotate(`PICKUP_MONEY_SECURITY_CASE`, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 8, false, true)
					end
				end
			end
		end
	end
end)
