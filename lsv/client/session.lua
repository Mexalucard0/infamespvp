Citizen.CreateThread(function()
	NetworkSetVoiceActive(Settings.voice.enabled)
	if Settings.voice.enabled then
		NetworkSetTalkerProximity(Settings.voice.proximity)
	end

	while not NetworkIsPlayerActive(PlayerId()) do
		Citizen.Wait(0)
	end

	StartAudioScene('MP_LEADERBOARD_SCENE')
	DoScreenFadeOut(0)
	Prompt.Show('Cargando perfil')

	TriggerServerEvent('lsv:loadPlayer')
end)

RegisterNetEvent('lsv:playerLoaded')
AddEventHandler('lsv:playerLoaded', function(playerData, isRegistered)
	ShutdownLoadingScreen()
	ShutdownLoadingScreenNui()

	Player.Init(playerData)

	Player.SetModelAsync(playerData.SkinModel)
	Player.GiveWeapons(playerData.Weapons)

	Player.SetPassiveMode(true)
	spawnPlayer(playerData.SpawnPoint) -- TODO: Module ?

	Player.Loaded = true

	TriggerEvent('lsv:init', playerData)
	TriggerServerEvent('lsv:playerInitialized')

	Prompt.Hide()
	DoScreenFadeIn(750)
	StopAudioScene('MP_LEADERBOARD_SCENE')

	Player.SetPassiveMode(true, true)
	Citizen.Wait(Settings.spawnProtectionTime)
	Player.SetPassiveMode(false)
end)

AddEventHandler('lsv:init', function()
	World.EnablePvp(true)
	World.EnableWanted(false)

	if Settings.disableHealthRegen then
		SetPlayerHealthRechargeMultiplier(PlayerId(), 0.)
	else
		SetPlayerHealthRechargeLimit(PlayerId(), 1.)
	end

	if Settings.giveArmorAtSpawn then
		SetPedArmour(PlayerPedId(), Settings.armour.max)
	end

	if Settings.infinitePlayerStamina then
		while true do
			Citizen.Wait(0)

			ResetPlayerStamina(PlayerId())
		end
	end
end)

AddEventHandler('lsv:init', function()
	local lastCamView = GetFollowPedCamViewMode()
	local needToUpdateView = true

	while true do
		Citizen.Wait(0)

		if Settings.forceFirstPersonViewWhenAiming or Player.Settings.enableFirstPersonAiming then
			local playerPed = PlayerPedId()

			if IsPlayerFreeAiming(PlayerId()) and not IsPedInCover(playerPed, false) then
				if needToUpdateView then
					lastCamView = GetFollowPedCamViewMode()
					SetFollowPedCamViewMode(4)
					needToUpdateView = false
				end

				DisableControlAction(0, 0, true) -- INPUT_NEXT_CAMERA
			else
				if not needToUpdateView and not IsPedStrafing(playerPed) then
					SetFollowPedCamViewMode(lastCamView)
					needToUpdateView = true
				end
			end
		end
	end
end)

AddEventHandler('lsv:init', function()
	local lastVehicle = nil

	while true do
		Citizen.Wait(0)

		local vehicle = GetVehiclePedIsTryingToEnter(PlayerPedId())
		local vehicleClass = GetVehicleClass(vehicle)

		if DoesEntityExist(vehicle) and (vehicleClass == 19 or vehicleClass == 15 or vehicleClass == 16) and GetSeatPedIsTryingToEnter(PlayerPedId()) == -1 then
			local isPlayerAbleToUseIt = Player.Rank >= Settings.specialVehicleMinRank -- This is vunerable for cheaters

			if not isPlayerAbleToUseIt and lastVehicle ~= vehicle then
				Gui.DisplayHelpText('Necesitas tener rango '..Settings.specialVehicleMinRank..' o superior para usar este vehículo.')
			end

			SetVehicleDoorsLockedForPlayer(vehicle, PlayerId(), not isPlayerAbleToUseIt)
			lastVehicle = vehicle
		end
	end
end)
