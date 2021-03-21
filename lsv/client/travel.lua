local _currentTravelIndex = nil
local _travelBlips = { }

RegisterNetEvent('lsv:useFastTravel')
AddEventHandler('lsv:useFastTravel', function(travelIndex)
	if travelIndex then
		if WarMenu.IsMenuOpened('fastTravel') then
			WarMenu.CloseMenu()
		end

		Player.SetPassiveMode(true)
		Player.TeleportAsync(Settings.travel.places[travelIndex].outPosition)
		Player.SetPassiveMode(true, true)
		Citizen.Wait(Settings.spawnProtectionTime)
		Player.SetPassiveMode(false)
	else
		Gui.DisplayPersonalNotification('No tienes suficiente dinero.')
	end

	Prompt.Hide()
end)

AddEventHandler('lsv:init', function()
	table.iforeach(Settings.travel.places, function(place)
		local blip = Map.CreatePlaceBlip(Blip.FAST_TRAVEL, place.inPosition.x, place.inPosition.y, place.inPosition.z, place.name)
		SetBlipScale(blip, 1.2)
		SetBlipCategory(blip, 1)
		table.insert(_travelBlips, blip)
	end)

	Gui.CreateMenu('fastTravel', 'Viaje rapido')
	WarMenu.SetTitleColor('fastTravel', table.unpack(Color.WHITE))
	WarMenu.SetTitleBackgroundColor('fastTravel', table.unpack(Color.DARK_BLUE))
	WarMenu.SetSubTitle('fastTravel', 'Selecciona tu destino')
	WarMenu.SetMenuButtonPressedSound('fastTravel', 'WEAPON_PURCHASE', 'HUD_AMMO_SHOP_SOUNDSET')

	while true do
		Citizen.Wait(0)

		if WarMenu.IsMenuOpened('fastTravel') then
			for travelIndex, place in ipairs(Settings.travel.places) do
				local isHere = _currentTravelIndex == travelIndex
				if WarMenu.Button(place.name, isHere and 'Aqui' or '$'..Settings.travel.cash) then
					if isHere then
						Gui.DisplayPersonalNotification('Ya estas aqui.')
					else
						TriggerServerEvent('lsv:useFastTravel', travelIndex)
						Prompt.ShowAsync()
					end
				end
			end

			WarMenu.Display()
		end
	end
end)

AddEventHandler('lsv:init', function()
	local fastTravelColor = Color.DARK_BLUE

	while true do
		Citizen.Wait(0)

		local isPlayerInFreeroam = Player.IsInFreeroam()
		local playerPosition = Player.Position()

		for travelIndex, place in ipairs(Settings.travel.places) do
			SetBlipAlpha(_travelBlips[travelIndex], isPlayerInFreeroam and 255 or 0)

			if isPlayerInFreeroam and not Player.IsInAnyEvent() then
				Gui.DrawPlaceMarker(place.inPosition, fastTravelColor)

				if World.GetDistance(playerPosition, place.inPosition, true) <= Settings.placeMarker.radius then
					if not WarMenu.IsAnyMenuOpened() then
						Gui.DisplayHelpText('Presiona ~INPUT_TALK~ para viajar rapido.')

						if IsControlJustReleased(0, 46) then
							_currentTravelIndex = travelIndex
							Gui.OpenMenu('fastTravel')
						end
					end
				elseif WarMenu.IsMenuOpened('fastTravel') and travelIndex == _currentTravelIndex then
					WarMenu.CloseMenu()
					Prompt.Hide()
				end
			end
		end
	end
end)
