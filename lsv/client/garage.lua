local _ownedGarage = { blip = Blip.GARAGE_OWNED, color = Color.GREEN, blipColour = Color.BLIP_GREEN }
local _lockedGarage = { blip = Blip.GARAGE_LOCKED, color = Color.BLUE }

local _garageBlips = { }
local _garageId = nil

local _garageTypes = {
	['low'] = {
		name = 'Chico',
	},
	['medium'] = {
		name = 'Intermedio',
	},
}

RegisterNetEvent('lsv:garageUpdated')
AddEventHandler('lsv:garageUpdated', function(garage)
	local blip = _garageBlips[garage]
	SetBlipSprite(blip, _ownedGarage.blip)
	SetBlipColour(blip, _ownedGarage.blipColour)
	SetBlipCategory(blip, 11)
	Map.SetBlipText(blip, 'Garaje')
	Map.SetBlipFlashes(blip)
end)

RegisterNetEvent('lsv:garagePurchased')
AddEventHandler('lsv:garagePurchased', function(success)
	WarMenu.CloseMenu()
	Prompt.Hide()

	if success then
		PlaySoundFrontend(-1, 'PROPERTY_PURCHASE', 'HUD_AWARDS')

		local scaleform = Scaleform.NewAsync('MIDSIZED_MESSAGE')
		scaleform:call('SHOW_SHARD_MIDSIZED_MESSAGE', 'GARAJE COMPRADO', '')
		scaleform:renderFullscreenTimed(7000)
	else
		Gui.DisplayPersonalNotification('No tienes suficiente dinero.')
	end
end)

AddEventHandler('lsv:init', function(playerData)
	table.foreach(Settings.garages, function(garage, id)
		local isOwnedGarage = Player.HasGarage(id)
		local blip = isOwnedGarage and _ownedGarage.blip or _lockedGarage.blip
		local blipText = isOwnedGarage and 'Garaje' or' Garaje '.. _garageTypes[garage.type].name
		_garageBlips[id] = Map.CreatePlaceBlip(blip, garage.location.x, garage.location.y, garage.location.z, blipText)
		if isOwnedGarage then
			SetBlipColour(_garageBlips[id], _ownedGarage.blipColour)
		end
		SetBlipCategory(_garageBlips[id], isOwnedGarage and 11 or 10)
	end)
end)

AddEventHandler('lsv:init', function()
	Gui.CreateMenu('garage_purchase')
	WarMenu.SetTitleBackgroundColor('garage_purchase', table.unpack(Color.WHITE))
	WarMenu.SetTitleBackgroundSprite('garage_purchase', 'shopui_title_carmod2', 'shopui_title_carmod2')

	while true do
		Citizen.Wait(0)

		if WarMenu.IsMenuOpened('garage_purchase') then
			if WarMenu.Button('Comprar', '$'..Settings.garages[_garageId].price) then
				TriggerServerEvent('lsv:purchaseGarage', _garageId)
				Prompt.ShowAsync()
			end

			WarMenu.Display()
		end
	end
end)

AddEventHandler('lsv:init', function()
	while true do
		Citizen.Wait(0)

		local isPlayerInFreeroam = Player.IsInFreeroam()

		local playerPos = Player.Position()

		for id, garage in pairs(Settings.garages) do
			SetBlipAlpha(_garageBlips[id], isPlayerInFreeroam and 255 or 0)

			if isPlayerInFreeroam and not Player.HasGarage(id) then
				Gui.DrawPlaceMarker(garage.location, _lockedGarage.color)

				if World.GetDistance(playerPos, garage.location, true) <= Settings.placeMarker.radius then
					if not WarMenu.IsAnyMenuOpened() then
						Gui.DisplayHelpText('Presiona ~INPUT_TALK~ para abrir el menu de garaje.')

						if IsControlJustReleased(0, 46) then
							_garageId = id
							WarMenu.SetSubTitle('garage_purchase', '('..garage.capacity..'-Vehiculos) '..garage.name)
							Gui.OpenMenu('garage_purchase')
						end
					end
				elseif _garageId == id and WarMenu.IsMenuOpened('garage_purchase') then
					WarMenu.CloseMenu()
					Prompt.Hide()
				end
			end
		end
	end
end)
