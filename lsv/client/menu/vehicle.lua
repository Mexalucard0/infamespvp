local _vehicleAccessItems = { 'Nadie', 'Crew', 'Todos' }
local _vehicleAccessCurrentIndex = 1
local _vehiclePosition = { }

local _vehicleIndex = nil
local _vehicleData = nil

local _rentTimer = nil

local function updateDoorsLock(vehicle)
	SetVehicleDoorsLockedForAllPlayers(vehicle, _vehicleAccessCurrentIndex ~= 3)
	if _vehicleAccessCurrentIndex == 2 then
		table.foreach(Player.CrewMembers, function(_, member)
			SetVehicleDoorsLockedForPlayer(vehicle, GetPlayerFromServerId(member), false)
		end)
	end

	SetVehicleDoorsLockedForPlayer(vehicle, PlayerId(), false)
end

local function updateVehicle(vehicle)
	updateDoorsLock(vehicle)
end

local function getRentTimer()
	if _rentTimer then
		local rentElapsed = Settings.personalVehicle.rentTimeout - _rentTimer:elapsed()
		if rentElapsed >= 0 then
			return string.from_ms(rentElapsed)
		end
	end

	return nil
end

local function getRentPrice()
	local price = Settings.personalVehicle.rentPrice
	if Player.PatreonTier ~= 0 then
		price = math.floor(price * Settings.patreon.rent[Player.PatreonTier])
	end

	return '$'..price
end

local function requestVehicleAsync(vehicleData)
	Player.DestroyPersonalVehicle()

	local modelHash = vehicleData.model
	Streaming.RequestModelAsync(modelHash)

	Player.VehicleHandle = Network.CreateVehicle(modelHash, _vehiclePosition.position, _vehiclePosition.heading, { personal = true })

	local vehicle = NetToVeh(Player.VehicleHandle)

	Vehicle.ApplyMods(vehicle, vehicleData)
	updateVehicle(vehicle)

	SetVehicleNumberPlateText(vehicle, GetPlayerName(PlayerId()))
	SetEntityLoadCollisionFlag(vehicle, true, 1)
	SetVehicleOnGroundProperly(vehicle)

	local vehicleBlip = AddBlipForEntity(vehicle)
	SetBlipSprite(vehicleBlip, Blip.CAR)
	SetBlipHighDetail(vehicleBlip, true)
	Map.SetBlipText(vehicleBlip, 'Vehiculo Personal')
	Map.SetBlipFlashes(vehicleBlip)
end

RegisterNetEvent('lsv:vehicleRented')
AddEventHandler('lsv:vehicleRented', function(vehicleIndex)
	if vehicleIndex then
		_vehicleIndex = vehicleIndex
		_vehicleData = Player.Vehicles[_vehicleIndex]

		requestVehicleAsync(_vehicleData)

		WarMenu.SetSubTitle('vehicle', Player.GetVehicleName(vehicleIndex))

		PlaySoundFrontend(-1, 'WEAPON_PURCHASE', 'HUD_AMMO_SHOP_SOUNDSET')
		WarMenu.CloseMenu()

		if not _rentTimer then
			_rentTimer = Timer.New()
		else
			_rentTimer:restart()
		end
	else
		Gui.DisplayPersonalNotification('No tienes suficiente dinero.')
	end

	Prompt.Hide()
end)

AddEventHandler('lsv:init', function()
	while true do
		Citizen.Wait(0)

		if Player.IsActive() and not Player.IsInInterior then
			if IsControlJustReleased(0, 246) then
				if not Player.HasAnyGarage() then
					Gui.DisplayPersonalNotification('Necesitas comprar un garaje primero.')
				else
					Gui.OpenMenu('vehicle')
				end
			end
		end
	end
end)

AddEventHandler('lsv:init', function()
	World.AddVehicleHandler(function(vehicle)
		if not NetworkGetEntityIsNetworked(vehicle) then
			return
		end

		local netId = VehToNet(vehicle)
		if not Network.DoesEntityExistWithNetworkId(netId) or not Network.GetData(netId, 'personal') or Network.GetCreator(netId) ~= Player.ServerId() then
			return
		end

		local blip = GetBlipFromEntity(vehicle)

		if Vehicle.IsDestroyed(vehicle) then
			if DoesBlipExist(blip) then
				RemoveBlip(blip)
			end

			Network.DeleteVehicle(netId, 5000)

			Gui.DisplayPersonalNotification('Tu vehiculo personal fue destruido.')

			if Player.VehicleHandle == netId then
				Player.VehicleHandle = nil
			end
		else
			SetBlipAlpha(blip, IsPedInVehicle(PlayerPedId(), vehicle) and 0 or 255)
		end
	end)
end)

AddEventHandler('lsv:init', function()
	Gui.CreateMenu('vehicle', '')
	WarMenu.SetSubTitle('vehicle', 'Menu Vehiculo Personal')
	WarMenu.SetTitleColor('vehicle', table.unpack(Color.WHITE))
	WarMenu.SetTitleBackgroundColor('vehicle', table.unpack(Color.WHITE))
	WarMenu.SetTitleBackgroundSprite('vehicle', 'shopui_title_carmod', 'shopui_title_carmod')

	local needToUpdateSlots = true
	local showVehicleList = false

	while true do
		Citizen.Wait(0)

		if WarMenu.IsMenuOpened('vehicle') then
			if needToUpdateSlots then
				if not Player.VehicleHandle then
					WarMenu.SetSubTitle('vehicle', table.length(Player.Vehicles)..' de '..Player.GetGaragesCapacity()..' slots de garaje usados')
				end
				needToUpdateSlots = false
			end

			if Player.VehicleHandle and not showVehicleList then
				if WarMenu.Button('Solicitar Vehiculo Personal', getRentTimer()) then
					if not _rentTimer or _rentTimer:elapsed() >= Settings.personalVehicle.rentTimeout then
						showVehicleList = true
					end
				else
					if WarMenu.ComboBox('Acceso de Vehiculo', _vehicleAccessItems, _vehicleAccessCurrentIndex, _vehicleAccessCurrentIndex, function(currentIndex)
						if currentIndex ~= _vehicleAccessCurrentIndex then
							_vehicleAccessCurrentIndex = currentIndex
							updateDoorsLock(NetToVeh(Player.VehicleHandle))
						end
					end) then
					end
				end
			else
				local rentElapsed = getRentTimer()

				for vehicleIndex, vehicle in ipairs(Player.Vehicles) do
					if WarMenu.Button(Player.GetVehicleName(vehicleIndex), rentElapsed or getRentPrice()) then
						if not _rentTimer or _rentTimer:elapsed() >= Settings.personalVehicle.rentTimeout then
							if not IsPedOnFoot(PlayerPedId()) then
								Gui.DisplayPersonalNotification('Necesitar estar a pie.')
							else
								_vehiclePosition = World.TryGetClosestVehicleNode(Player.Position(), Settings.personalVehicle.maxDistance)
								if _vehiclePosition then
									TriggerServerEvent('lsv:rentVehicle', vehicleIndex)
									Prompt.ShowAsync()
								else
									Gui.DisplayPersonalNotification('No se puede entregar el vehículo personal a tu ubicación.')
								end
							end
						end
					end
				end
			end

			WarMenu.Display()
		else
			needToUpdateSlots = true
			showVehicleList = false
		end
	end
end)
