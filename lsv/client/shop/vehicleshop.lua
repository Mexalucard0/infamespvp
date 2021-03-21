local _vehicleShops = {
	--Maze Bank Tower
	{
		enter = { x = -81.899719238281, y = -837.51239013672, z = 40.555530548096 },
		exit = { x = -71.504844665527, y = -810.99322509766, z = 284.99993896484, heading = 156.60697937012 },
		vehicle = { x = -75.040298461914, y = -820.91101074219, z = 285.00012207031, heading = 288.53186035156 },
		ipl = 'imp_dt1_11_modgarage',
		ped = { x = -79.328224182129, y = -824.70001220703, z = 284.99993896484, heading = 311.40353393555 },
	},

	--Arcadius Business Center
	{
		enter = { x = -115.95420837402, y = -604.80242919922, z = 36.280742645264, heading = 248.49151611328 },
		exit = { x = -139.50762939453, y = -589.11920166016, z = 167.00003051758, heading = 121.80055999756 },
		vehicle = { x = -147.96640014648, y = -596.23620605469, z = 167.00003051758, heading = 261.65518188477 },
		ipl = 'imp_dt1_02_modgarage',
		ped = { x = -141.07096862793, y = -601.99206542969, z = 167.59504699707, heading = 33.942058563232 },
	},

	--Lombank Tower
	{
		enter = { x = -1582.1668701172, y = -557.11340332031, z = 34.953762054443, heading = 33.669002532959 },
		exit = { x = -1571.4724121094, y = -569.81713867188, z = 105.20006561279, heading = 123.33140563965 },
		vehicle = { x = -1579.6569824219, y = -575.85009765625, z = 105.20006561279, heading = 261.01733398438 },
		ipl = 'imp_sm_13_modgarage',
		ped = { x = -1579.1212158203, y = -583.04144287109, z = 105.20011901855, heading = 351.9518737793 },
	},

	--Maze Bank West
	{
		enter = { x = -1371.6906738281, y = -504.17721557617, z = 33.157386779785, heading = 143.22932434082 },
		exit = { x = -1388.2547607422, y = -483.32733154297, z = 78.200065612793, heading = 6.7775688171387 },
		vehicle = { x = -1389.6025390625, y = -473.76626586914, z = 78.200065612793, heading = 146.43200683594 },
		ipl = 'imp_sm_15_modgarage',
		ped = { x = -1383.6922607422, y = -479.16348266602, z = 78.200065612793, heading = 65.194030761719 },
	},
}

local _pedModel = `s_f_m_shop_high`
local _pedScenarios = {
	'WORLD_HUMAN_STAND_IMPATIENT',
	'WORLD_HUMAN_AA_SMOKE',
	'WORLD_HUMAN_AA_COFFEE',
	'WORLD_HUMAN_PROSTITUTE_HIGH_CLASS',
	'WORLD_HUMAN_STAND_MOBILE',
}

local _shopIndex = nil
local _interiorId = nil
local _ped = nil

local _selectedVehicleCategoryIndex = nil
local _selectedVehicleModel = nil

local _selectedVehicleIndex = nil
local _isModsAvailableForSelectedVehicle = false

local _isSelectedVehiclePrimaryColor = false
local _selectedColorGroupIndex = nil

local _selectedModTypeIndex = nil

local _isSelectedFrontBikeWheel = false
local _selectedWheelTypeIndex = nil

local _hoveredVehicleIndex = nil
local _hoveredVehicleModel = nil
local _vehicle = nil

local function spawnVehicle(modelHash, coords)
	local vehicle = CreateVehicle(modelHash, coords.x, coords.y, coords.z, coords.heading, false, false)

	SetEntityInvincible(vehicle, true)
	FreezeEntityPosition(vehicle, true)
	SetVehicleUndriveable(vehicle, true)
	SetVehicleIsConsideredByPlayer(vehicle, false)
	SetVehicleNumberPlateText(vehicle, GetPlayerName(PlayerId()))
	SetVehicleColours(vehicle, 0, 0)
	SetVehicleOnGroundProperly(vehicle)

	return vehicle
end

local function deleteVehicle(resetHoveredModel)
	if _vehicle then
		World.DeleteEntity(_vehicle)
		_vehicle = nil
	end

	SetModelAsNoLongerNeeded(_hoveredVehicleModel)

	if resetHoveredModel then
		_hoveredVehicleModel = nil
		_hoveredVehicleIndex = nil
	end
end

local function respawnSelectedPlayerVehicle(coords)
	deleteVehicle()
	_vehicle = spawnVehicle(_hoveredVehicleModel, coords)
	Vehicle.ApplyMods(_vehicle, Player.Vehicles[_selectedVehicleIndex])
end

local function getVehicleTooltip(vehicleData)
	if vehicleData.prestige and vehicleData.prestige > Player.Prestige then
		return 'Requiere Prestigio '..vehicleData.prestige
	end

	if vehicleData.patreonTier and vehicleData.patreonTier > Player.PatreonTier then
		return 'Requiere nivel '..vehicleData.patreonTier.. ' de Patreon'
	end

	return nil
end

local function getStatString(stat, maxStat)
	return string.format('%02.2f / %02.2f', stat, maxStat)
end

local function concealPlayers(conceal)
	local playerId = PlayerId()

	for _, id in ipairs(GetActivePlayers()) do
		if id ~= playerId then
			NetworkConcealPlayer(id, conceal)
		end
	end
end

local function leaveShop()
	WarMenu.CloseMenu()

	SetModelAsNoLongerNeeded(_pedModel)
	SetEntityAsNoLongerNeeded(_ped)
	_ped = nil

	deleteVehicle(true)

	Player.TeleportAsync(_vehicleShops[_shopIndex].enter)

	concealPlayers(false)

	World.UnloadInterior(_interiorId)
	_interiorId = nil

	_shopIndex = nil

	SetPedCanSwitchWeapon(PlayerPedId(), true)
	Player.SetPassiveMode(true, true)
	Citizen.Wait(Settings.spawnProtectionTime)
	Player.SetPassiveMode(false)
end

RegisterNetEvent('lsv:vehicleColorCustomized')
AddEventHandler('lsv:vehicleColorCustomized', function(success)
	Prompt.Hide()

	if success then
		PlaySoundFrontend(-1, 'WEAPON_PURCHASE', 'HUD_AMMO_SHOP_SOUNDSET', true)
	else
		Gui.DisplayPersonalNotification('No tienes suficiente dinero.')
	end
end)

RegisterNetEvent('lsv:vehicleModCustomized')
AddEventHandler('lsv:vehicleModCustomized', function(success)
	Prompt.Hide()

	if success then
		PlaySoundFrontend(-1, 'WEAPON_PURCHASE', 'HUD_AMMO_SHOP_SOUNDSET', true)
	else
		Gui.DisplayPersonalNotification('No tienes suficiente dinero.')
	end
end)

RegisterNetEvent('lsv:vehiclePurchased')
AddEventHandler('lsv:vehiclePurchased', function(success)
	Prompt.Hide()

	if success then
		WarMenu.CloseMenu()
		PlaySoundFrontend(-1, 'PROPERTY_PURCHASE', 'HUD_AWARDS', true)

		local vehicleName = Settings.vehicleShop.vehicles[_selectedVehicleCategoryIndex].models[_selectedVehicleModel].name or Vehicle.GetModelName(_selectedVehicleModel)
		local scaleform = Scaleform.NewAsync('MIDSIZED_MESSAGE')
		scaleform:call('SHOW_SHARD_MIDSIZED_MESSAGE', string.upper(vehicleName)..' COMPRADO', '')
		scaleform:renderFullscreenTimed(7000)
	else
		Gui.DisplayPersonalNotification('No tienes suficiente dinero.')
	end
end)

RegisterNetEvent('lsv:vehicleSold')
AddEventHandler('lsv:vehicleSold', function()
	Prompt.Hide()
	WarMenu.CloseMenu()
	PlaySoundFrontend(-1, 'PROPERTY_PURCHASE', 'HUD_AWARDS', true)

	deleteVehicle(true)

	local scaleform = Scaleform.NewAsync('MIDSIZED_MESSAGE')
	scaleform:call('SHOW_SHARD_MIDSIZED_MESSAGE', 'VEHICULO VENDIDO', '')
	scaleform:renderFullscreenTimed(7000)
end)

AddEventHandler('lsv:init', function()
	table.iforeach(_vehicleShops, function(shop)
		RequestIpl(shop.ipl)
		shop.blip = Map.CreatePlaceBlip(Blip.VEHICLE_SHOP, shop.enter.x, shop.enter.y, shop.enter.z, 'Tienda de Vehículos', Color.BLIP_LIME)
	end)

	Gui.CreateMenu('vehicleShop', '')
	WarMenu.SetSubTitle('vehicleShop', 'Tienda de Vehículos')
	WarMenu.SetTitleColor('vehicleShop', table.unpack(Color.WHITE))
	WarMenu.SetTitleBackgroundColor('vehicleShop', table.unpack(Color.WHITE))
	WarMenu.SetTitleBackgroundSprite('vehicleShop', 'shopui_title_carmod', 'shopui_title_carmod')

	WarMenu.CreateSubMenu('vehicleShop_purchaseVehicle', 'vehicleShop', 'Seleccionar Categoria')
	WarMenu.CreateSubMenu('vehicleShop_purchaseVehicle_vehicles', 'vehicleShop_purchaseVehicle')
	WarMenu.CreateSubMenu('vehicleShop_purchaseVehicle_details', 'vehicleShop_purchaseVehicle_vehicles')

	WarMenu.CreateSubMenu('vehicleShop_customize_vehicles', 'vehicleShop', 'Seleccione El Vehículo Para Personalizar')

	WarMenu.CreateSubMenu('vehicleShop_customize_categories', 'vehicleShop_customize_vehicles')

	WarMenu.CreateSubMenu('vehicleShop_customize_respray', 'vehicleShop_customize_categories', 'Pintar')
	WarMenu.CreateSubMenu('vehicleShop_customize_respray_colorGroups', 'vehicleShop_customize_respray', 'Grupos de colores')
	WarMenu.CreateSubMenu('vehicleShop_customize_respray_colors', 'vehicleShop_customize_respray_colorGroups')

	WarMenu.CreateSubMenu('vehicleShop_customize_wheels', 'vehicleShop', 'Ruedas')

	WarMenu.CreateSubMenu('vehicleShop_customize_wheels_bike', 'vehicleShop_customize_wheels')
	WarMenu.CreateSubMenu('vehicleShop_customize_wheels_bike_types', 'vehicleShop_customize_wheels_bike')

	WarMenu.CreateSubMenu('vehicleShop_customize_wheels_types', 'vehicleShop_customize_wheels', 'Wheel Type')
	WarMenu.CreateSubMenu('vehicleShop_customize_wheels_types_wheels', 'vehicleShop_customize_wheels_types')

	WarMenu.CreateSubMenu('vehicleShop_customize_mods', 'vehicleShop_customize_categories')

	WarMenu.CreateSubMenu('vehicleShop_sellVehicle', 'vehicleShop', 'Vender Vehiculo')

	while true do
		Citizen.Wait(0)

		local playerPos = Player.Position()

		if _shopIndex then
			concealPlayers(true)

			local shop = _vehicleShops[_shopIndex]

			Gui.DrawPlaceMarker(shop.exit, Color.LIME)

			if HasEntityBeenDamagedByEntity(_ped, PlayerPedId(), true) then
				leaveShop()
			elseif not WarMenu.IsAnyMenuOpened() then
				if World.GetDistance(playerPos, shop.exit, true) <= Settings.placeMarker.radius then
					Gui.DisplayHelpText('Presiona ~INPUT_TALK~ para salir de la tienda.')

					if IsControlJustReleased(0, 46) then
						leaveShop()
					end
				else
					Gui.DisplayHelpText('Presiona ~INPUT_MP_TEXT_CHAT_TEAM~ para abrir la Tienda de Vehiculos.')
					if IsControlJustReleased(0, 246) then
						Gui.OpenMenu('vehicleShop')
					end
				end
			else
				if WarMenu.IsMenuOpened('vehicleShop') then
					if WarMenu.Button('Comprar Vehiculo') then
						if table.length(Player.Vehicles) == Player.GetGaragesCapacity() then
							Gui.DisplayPersonalNotification('No tienes slots de garaje libres.')
						else
							deleteVehicle(true)
							WarMenu.OpenMenu('vehicleShop_purchaseVehicle')
						end
					end

					if WarMenu.Button('Personalizar Vehiculo') then
						if table.length(Player.Vehicles) == 0 then
							Gui.DisplayPersonalNotification('No tienes ningún vehículo.')
						else
							deleteVehicle(true)
							WarMenu.OpenMenu('vehicleShop_customize_vehicles')
						end
					end

					if WarMenu.Button('Vender Vehiculo') then
						if table.length(Player.Vehicles) == 0 then
							Gui.DisplayPersonalNotification('No tienes ningún vehículo.')
						else
							deleteVehicle(true)
							WarMenu.OpenMenu('vehicleShop_sellVehicle')
						end
					end

					WarMenu.Display()
				elseif WarMenu.IsMenuOpened('vehicleShop_customize_vehicles') then
					for vehicleIndex, vehicle in ipairs(Player.Vehicles) do
						local vehicleModel = vehicle.model
						local vehicleName = Player.GetVehicleName(vehicleIndex)

						WarMenu.Button(vehicleName)

						if WarMenu.IsItemHovered() then
							if _hoveredVehicleIndex ~= vehicleIndex then
								deleteVehicle()

								if not HasModelLoaded(vehicleModel) then
									RequestModel(vehicleModel)
								else
									_vehicle = spawnVehicle(vehicleModel, shop.vehicle)
									_hoveredVehicleIndex = vehicleIndex
									_hoveredVehicleModel = vehicleModel
									Vehicle.ApplyMods(_vehicle, vehicle)
								end
							end

							if _vehicle and WarMenu.IsItemSelected() then
								_selectedVehicleIndex = vehicleIndex
								local vehicleData = VehicleUtility.GetVehicleData(_hoveredVehicleModel)
								_isModsAvailableForSelectedVehicle = vehicleData and not vehicleData.disableAllMods
								WarMenu.SetSubTitle('vehicleShop_customize_categories', vehicleName)
								WarMenu.OpenMenu('vehicleShop_customize_categories')
							end
						end
					end

					WarMenu.Display()
				elseif WarMenu.IsMenuOpened('vehicleShop_customize_categories') then
					if WarMenu.MenuButton('Pintar', 'vehicleShop_customize_respray') then
						respawnSelectedPlayerVehicle(shop.vehicle)
					end

					if _isModsAvailableForSelectedVehicle then
						for modTypeIndex, modTypeData in pairs(Settings.vehicleShop.mods) do
							if (modTypeIndex == 18 or modTypeIndex == 22 or GetNumVehicleMods(_vehicle, modTypeIndex) ~= 0) and WarMenu.Button(modTypeData.name) then
								_selectedModTypeIndex = modTypeIndex

								respawnSelectedPlayerVehicle(shop.vehicle)

								SetVehicleLights(_vehicle, modTypeData.enableLights and 2 or 1)

								WarMenu.SetSubTitle('vehicleShop_customize_mods', modTypeData.name)
								WarMenu.OpenMenu('vehicleShop_customize_mods')
							end
						end

						if WarMenu.MenuButton('Ruedas', 'vehicleShop_customize_wheels') then
							respawnSelectedPlayerVehicle(shop.vehicle)
						end
					end

					WarMenu.Display()
				elseif WarMenu.IsMenuOpened('vehicleShop_customize_wheels') then
					if IsThisModelABike(_hoveredVehicleModel) then
						if WarMenu.MenuButton('Rueda delantera', 'vehicleShop_customize_wheels_bike') then
							WarMenu.SetSubTitle('vehicleShop_customize_wheels_bike', 'Rueda delantera')
							_isSelectedFrontBikeWheel = true
						end

						if WarMenu.MenuButton('Rueda trasera', 'vehicleShop_customize_wheels_bike') then
							WarMenu.SetSubTitle('vehicleShop_customize_wheels_bike', 'Rueda trasera')
							_isSelectedFrontBikeWheel = false
						end
					else
						WarMenu.MenuButton('Tipo de rueda', 'vehicleShop_customize_wheels_types')
					end

					WarMenu.Display()
				elseif WarMenu.IsMenuOpened('vehicleShop_customize_wheels_bike') then
					WarMenu.MenuButton('Tipo de rueda', 'vehicleShop_customize_wheels_bike_types')

					WarMenu.Display()
				elseif WarMenu.IsMenuOpened('vehicleShop_customize_wheels_bike_types') then
					local wheelTypeIndex = _isSelectedFrontBikeWheel and 23 or 24
					local vehicleWheelIndex = Player.GetVehicleMod(_selectedVehicleIndex, wheelTypeIndex)

					for wheelIndex, wheelData in pairs(Settings.vehicleShop.bikeWheels) do
						local isDifferentWheelIndex = vehicleWheelIndex ~= wheelIndex

						WarMenu.Button(wheelData.name, isDifferentWheelIndex and '$'..wheelData.price or 'Equipada')
						if WarMenu.IsItemHovered() then
							SetVehicleMod(_vehicle, wheelTypeIndex, wheelIndex)

							if isDifferentWheelIndex and WarMenu.IsItemSelected() then
								TriggerServerEvent('lsv:customizeBikeWheel', _selectedVehicleIndex, wheelTypeIndex, wheelIndex)
								Prompt.ShowAsync()
							end
						end
					end

					WarMenu.Display()
				elseif WarMenu.IsMenuOpened('vehicleShop_customize_wheels_types') then
					for wheelTypeIndex, wheelTypeData in pairs(Settings.vehicleShop.wheels) do
						if WarMenu.MenuButton(wheelTypeData.name, 'vehicleShop_customize_wheels_types_wheels') then
							_selectedWheelTypeIndex = wheelTypeIndex
							SetVehicleWheelType(_vehicle, _selectedWheelTypeIndex)
							WarMenu.SetSubTitle('vehicleShop_customize_wheels_types_wheels', wheelTypeData.name)
						end
					end

					WarMenu.Display()
				elseif WarMenu.IsMenuOpened('vehicleShop_customize_wheels_types_wheels') then
					local vehicleWheelType = Player.GetVehicleWheelType(_selectedVehicleIndex)
					local vehicleWheel = Player.GetVehicleMod(_selectedVehicleIndex, 23)

					for wheelIndex, wheelData in pairs(Settings.vehicleShop.wheels[_selectedWheelTypeIndex].items) do
						local isDifferentWheelIndex = vehicleWheelType ~= _selectedWheelTypeIndex or vehicleWheel ~= wheelIndex

						WarMenu.Button(wheelData.name, isDifferentWheelIndex and '$'..wheelData.price or 'Equipada')

						if WarMenu.IsItemHovered() then
							SetVehicleMod(_vehicle, 23, wheelIndex)

							if isDifferentWheelIndex and WarMenu.IsItemSelected() then
								TriggerServerEvent('lsv:customizeVehicleWheelType', _selectedVehicleIndex, _selectedWheelTypeIndex, wheelIndex)
								Prompt.ShowAsync()
							end
						end
					end

					WarMenu.Display()
				elseif WarMenu.IsMenuOpened('vehicleShop_customize_mods') then
					local categoryData = Settings.vehicleShop.mods[_selectedModTypeIndex]

					local vehicleModIndex = Player.GetVehicleMod(_selectedVehicleIndex, _selectedModTypeIndex)
					if categoryData.toggleable then
						vehicleModIndex = math.max(0, vehicleModIndex)
					end

					local vehicleClass = GetVehicleClass(_vehicle)

					for modIndex, modData in pairs(categoryData.items) do
						local isDifferentModIndex = vehicleModIndex ~= modIndex

						WarMenu.Button(modData.name, isDifferentModIndex and '$'..math.floor(modData.price * Settings.vehicleShop.modByClassPriceModifiers[vehicleClass]) or 'Equipada')

						if WarMenu.IsItemHovered() then
							SetVehicleMod(_vehicle, _selectedModTypeIndex, modIndex)

							if categoryData.toggleable then
								ToggleVehicleMod(_vehicle, _selectedModTypeIndex, modIndex == 0)
							end

							if categoryData.windowTint then
								SetVehicleWindowTint(_vehicle, Settings.vehicleShop.windowTints[modIndex])
							end

							if isDifferentModIndex and WarMenu.IsItemSelected() then
								TriggerServerEvent('lsv:customizeVehicleMod', _selectedVehicleIndex, _selectedModTypeIndex, modIndex, vehicleClass)
								Prompt.ShowAsync()
							end
						end
					end

					WarMenu.Display()
				elseif WarMenu.IsMenuOpened('vehicleShop_customize_respray') then
					if WarMenu.Button('Color Primario') then
						_isSelectedVehiclePrimaryColor = true
						WarMenu.SetSubTitle('vehicleShop_customize_respray_colors', 'Colores Primario')
						WarMenu.OpenMenu('vehicleShop_customize_respray_colorGroups')
					end

					if WarMenu.Button('Color Secundario') then
						_isSelectedVehiclePrimaryColor = false
						WarMenu.SetSubTitle('vehicleShop_customize_respray_colors', 'Colores Secundarios')
						WarMenu.OpenMenu('vehicleShop_customize_respray_colorGroups')
					end

					WarMenu.Display()
				elseif WarMenu.IsMenuOpened('vehicleShop_customize_respray_colorGroups') then
					for colorGroupIndex, colorGroup in ipairs(Settings.vehicleShop.colorGroups) do
						if WarMenu.Button(colorGroup.name) then
							_selectedColorGroupIndex = colorGroupIndex
							WarMenu.OpenMenu('vehicleShop_customize_respray_colors')
						end
					end

					WarMenu.Display()
				elseif WarMenu.IsMenuOpened('vehicleShop_customize_respray_colors') then
					local primaryColor = Player.GetVehiclePrimaryColor(_selectedVehicleIndex)
					local secondaryColor = Player.GetVehicleSecondaryColor(_selectedVehicleIndex)

					for _, color in ipairs(Settings.vehicleShop.colorGroups[_selectedColorGroupIndex].colors) do
						local isDifferentColor = false
						if _isSelectedVehiclePrimaryColor then
							isDifferentColor = primaryColor ~= color.index
						else
							isDifferentColor = secondaryColor ~= color.index
						end

						WarMenu.Button(color.name, isDifferentColor and '$'..Settings.vehicleShop.colorGroups[_selectedColorGroupIndex].price or 'Equipada')

						if WarMenu.IsItemHovered() then
							if _isSelectedVehiclePrimaryColor then
								SetVehicleColours(_vehicle, color.index, secondaryColor)
							else
								SetVehicleColours(_vehicle, primaryColor, color.index)
							end

							if isDifferentColor and WarMenu.IsItemSelected() then
								TriggerServerEvent('lsv:customizeVehicleColor', _selectedVehicleIndex, _selectedColorGroupIndex, color.index, _isSelectedVehiclePrimaryColor)
								Prompt.ShowAsync()
							end
						end
					end

					WarMenu.Display()
				elseif WarMenu.IsMenuOpened('vehicleShop_purchaseVehicle') then
					for categoryIndex, category in ipairs(Settings.vehicleShop.vehicles) do
						if WarMenu.MenuButton(category.name, 'vehicleShop_purchaseVehicle_vehicles') then
							_selectedVehicleCategoryIndex = categoryIndex
							WarMenu.SetSubTitle('vehicleShop_purchaseVehicle_vehicles', category.name)
						end
					end

					WarMenu.Display()
				elseif WarMenu.IsMenuOpened('vehicleShop_purchaseVehicle_vehicles') then
					for vehicleModel, vehicle in pairs(Settings.vehicleShop.vehicles[_selectedVehicleCategoryIndex].models) do
						local vehicleName = vehicle.name or Vehicle.GetModelName(vehicleModel)

						WarMenu.Button(vehicleName)

						if WarMenu.IsItemHovered() then
							if _hoveredVehicleModel ~= vehicleModel then
								deleteVehicle()

								if not HasModelLoaded(vehicleModel) then
									RequestModel(vehicleModel)
								else
									_vehicle = spawnVehicle(vehicleModel, shop.vehicle)
									_hoveredVehicleModel = vehicleModel
								end
							end

							if _vehicle and WarMenu.IsItemSelected() then
								_selectedVehicleModel = vehicleModel
								WarMenu.SetSubTitle('vehicleShop_purchaseVehicle_details', vehicleName)
								WarMenu.OpenMenu('vehicleShop_purchaseVehicle_details')
							end
						end
					end

					WarMenu.Display()
				elseif WarMenu.IsMenuOpened('vehicleShop_purchaseVehicle_details') then
					local vehicleData = Settings.vehicleShop.vehicles[_selectedVehicleCategoryIndex].models[_selectedVehicleModel]

					WarMenu.Button('Comprar', '$'..vehicleData.price)
					if WarMenu.IsItemHovered() then
						local tooltip = getVehicleTooltip(vehicleData)
						if tooltip then
							WarMenu.ToolTip(tooltip)
						end

						if WarMenu.IsItemSelected() then
							if vehicleData.prestige and vehicleData.prestige > Player.Prestige then
								Gui.DisplayPersonalNotification('Tu Prestigio es demasiado bajo.')
							elseif vehicleData.patreonTier and vehicleData.patreonTier > Player.PatreonTier then
								Gui.DisplayPersonalNotification('Tu nivel de Patreon es demasiado bajo.')
							else
								TriggerServerEvent('lsv:purchaseVehicle', _selectedVehicleModel, _selectedVehicleCategoryIndex)
								Prompt.ShowAsync()
							end
						end
					end

					local vehicleClass = GetVehicleClass(_vehicle)

					WarMenu.Button('Velocidad Maxima', getStatString(GetVehicleEstimatedMaxSpeed(_vehicle), GetVehicleClassEstimatedMaxSpeed(vehicleClass)))
					WarMenu.Button('Aceleracion', getStatString(GetVehicleAcceleration(_vehicle), GetVehicleClassMaxAcceleration(vehicleClass)))
					WarMenu.Button('Frenado', getStatString(GetVehicleModelMaxBraking(_selectedVehicleModel), GetVehicleClassMaxBraking(vehicleClass)))
					WarMenu.Button('Traccion', getStatString(GetVehicleMaxTraction(_vehicle), GetVehicleClassMaxTraction(vehicleClass)))

					WarMenu.Display()
				elseif WarMenu.IsMenuOpened('vehicleShop_sellVehicle') then
					for vehicleIndex, vehicle in ipairs(Player.Vehicles) do
						local vehicleModel = vehicle.model

						WarMenu.Button(Player.GetVehicleName(vehicleIndex), '$'..math.floor(VehicleUtility.GetVehicleData(vehicleModel).price * Settings.vehicleShop.sellMultiplier))

						if WarMenu.IsItemHovered() then
							if _hoveredVehicleIndex ~= vehicleIndex then
								deleteVehicle()

								if not HasModelLoaded(vehicleModel) then
									RequestModel(vehicleModel)
								else
									_vehicle = spawnVehicle(vehicleModel, shop.vehicle)
									_hoveredVehicleIndex = vehicleIndex
									_hoveredVehicleModel = vehicleModel
									Vehicle.ApplyMods(_vehicle, vehicle)
								end
							end

							if WarMenu.IsItemSelected() then
								TriggerServerEvent('lsv:sellVehicle', vehicleIndex)
								Prompt.ShowAsync()
							end
						end
					end

					WarMenu.Display()
				end
			end
		elseif Player.IsInFreeroam() and not Player.IsInAnyEvent() then
			for shopIndex, shop in ipairs(_vehicleShops) do
				Gui.DrawPlaceMarker(shop.enter, Color.LIME)

				if World.GetDistance(playerPos, shop.enter, true) <= Settings.placeMarker.radius then
					if not WarMenu.IsAnyMenuOpened() then
						Gui.DisplayHelpText('Presiona ~INPUT_TALK~ para entrar a la Tienda de Vehiculos.')

						if IsControlJustReleased(0, 46) then
							if not Player.HasAnyGarage() then
								Gui.DisplayPersonalNotification('Necesitas comprar un garaje primero.')
							else
								Player.SetPassiveMode(true)

								_interiorId = World.LoadInterior(shop.exit)
								concealPlayers(true)

								local playerPed = PlayerPedId()
								SetCurrentPedWeapon(playerPed, `WEAPON_UNARMED`, true)
								SetPedCanSwitchWeapon(playerPed, false)

								Streaming.RequestModelAsync(_pedModel)
								_ped = CreatePed(26, _pedModel, shop.ped.x, shop.ped.y, shop.ped.z, shop.ped.heading, false, false)
								SetEntityAsMissionEntity(_ped, true, true)
								SetPedRandomComponentVariation(_ped, false)

								Player.TeleportAsync(shop.exit, true)

								PlaceObjectOnGroundProperly(_ped)
								TaskStartScenarioInPlace(_ped, table.irandom(_pedScenarios), 0, true)
								SetPedKeepTask(_ped, true)

								Player.SetPassiveMode(true, true)

								_shopIndex = shopIndex
							end
						end
					end
				end
			end
		end
	end
end)
