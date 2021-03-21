local _crateData = nil

RegisterNetEvent('lsv:spawnSpecialCrate')
AddEventHandler('lsv:spawnSpecialCrate', function(crate)
	if _crateData then
		return
	end

	PlaySoundFrontend(-1, 'CONFIRM_BEEP', 'HUD_MINI_GAME_SOUNDSET', true)
	Gui.DisplayPersonalNotification('Hemos dejado una caja especial para ti.', 'CHAR_AMMUNATION', 'Ammu-Nation', '', 2)

	_crateData = { }

	_crateData.position = crate.position
	_crateData.location = crate.location
	_crateData.areaBlip = Map.CreateRadiusBlip(crate.location.x, crate.location.y, crate.location.z, Settings.crate.radius, Color.BLIP_YELLOW)

	_crateData.blip = Map.CreatePlaceBlip(Blip.CRATE_DROP, crate.location.x, crate.location.y, crate.location.z, nil, Color.BLIP_YELLOW)
	SetBlipAsShortRange(_crateData.blip, false)
	SetBlipScale(_crateData.blip, 1.5)
	Map.SetBlipFlashes(_crateData.blip)

	FlashMinimapDisplay()

	while true do
		Citizen.Wait(0)

		if Player.DistanceTo(_crateData.location) <= Settings.crate.radius then
			if not _crateData.pickup then
				_crateData.pickup = CreatePickupRotate(`PICKUP_PORTABLE_CRATE_UNFIXED`, crate.position.x, crate.position.y, crate.position.z, 0.0, 0.0, 0.0, 512, false, true)
			elseif HasPickupBeenCollected(_crateData.pickup) then
				TriggerServerEvent('lsv:specialCratePickedUp')
				return
			end

			if Player.IsInFreeroam() then
				Gui.DrawProgressBar('DISTANCIA DE LA CAJA', 1.0 - Player.DistanceTo(_crateData.position) / Settings.crate.radius, 7, Color.YELLOW)
			end
		end
	end
end)

RegisterNetEvent('lsv:specialCratePickedUp')
AddEventHandler('lsv:specialCratePickedUp', function(crate)
	local playerPed = PlayerPedId()

	GiveWeaponToPed(playerPed, GetHashKey(crate.weapon.id), crate.weapon.ammo, false, true)
	SetPedArmour(playerPed, Settings.armour.max)
	Player.SaveWeapons()

	Gui.DisplayPersonalNotification('Contenido de la caja:~w~\n+ $'..Settings.crate.reward.cash..'\n+ '..crate.weapon.name..'\n+ Armadura')

	RemoveBlip(_crateData.areaBlip)
	RemoveBlip(_crateData.blip)

	_crateData = nil
end)
