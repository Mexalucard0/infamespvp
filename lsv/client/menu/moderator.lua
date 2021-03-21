local _reportedPlayers = { }
local _target = nil

local _moderationEventName = nil
local _moderationReasons = { 'Nombre inapropiado', 'Acoso', 'Cheating', 'Spam', 'Abuso de mecanicas de juego' }
local _banDurations = { 1, 3, 7, 30 }
local _banReason = nil

local function setSpectatorModeEnabled(enabled)
	local targetPed = enabled and GetPlayerPed(GetPlayerFromServerId(_target)) or PlayerPedId()

	local targetPedCoords = GetEntityCoords(targetPed)
	RequestCollisionAtCoord(targetPedCoords.x, targetPedCoords.y, targetPedCoords.z)

	NetworkSetInSpectatorModeExtended(enabled, targetPed, true)
	SetMinimapInSpectatorMode(enabled, targetPed)
	Player.SetPassiveMode(enabled)
end

RegisterNetEvent('lsv:playerBanned')
AddEventHandler('lsv:playerBanned', function(name, cheatName)
	Gui.DisplayNotification('<C>'..name..'</C> ~r~fue baneado por '..cheatName..'.')
end)

AddEventHandler('lsv:init', function()
	while true do
		Citizen.Wait(0)

		if Player.IsActive() and not Player.IsInInterior then
			if IsControlJustReleased(0, 305) then
				Gui.OpenMenu(Player.Moderator and 'moderatorMenu' or 'reportMenu')
			end
		end
	end
end)

-- Report Menu
AddEventHandler('lsv:init', function()
	if Player.Moderator then
		return
	end

	Gui.CreateMenu('reportMenu', 'Reportar Jugador')
	WarMenu.SetSubTitle('reportMenu', 'Selecciona Jugador A Reportar')
	WarMenu.SetTitleColor('reportMenu', table.unpack(Color.WHITE))
	WarMenu.SetTitleBackgroundColor('reportMenu', table.unpack(Color.PURPLE))

	WarMenu.CreateSubMenu('reportMenu_reason', 'reportMenu')
	WarMenu.SetSubTitle('reportMenu_reason', 'Selecciona Razon Del Reporte')

	while true do
		Citizen.Wait(0)

		if WarMenu.IsMenuOpened('reportMenu') then
			for _, id in ipairs(GetActivePlayers()) do
				if id ~= PlayerId() then
					local playerName = GetPlayerName(id)
					local serverId = GetPlayerServerId(id)

					if not _reportedPlayers[serverId] and WarMenu.MenuButton(playerName, 'reportMenu_reason') then
						_target = serverId
						WarMenu.SetSubTitle('reportMenu_reason', 'Selecciona Razon Del Reporte Para '..playerName)
					end
				end
			end

			WarMenu.Display()
		elseif WarMenu.IsMenuOpened('reportMenu_reason') then
			for _, reason in ipairs(_moderationReasons) do
				if WarMenu.Button(reason) then
					local message = Gui.GetTextInputResultAsync('FMMC_SMS4', Settings.moderator.maxMessageLength)
					TriggerServerEvent('lsv:reportPlayer', _target, reason, message or '')
					_reportedPlayers[_target] = true
					_target = nil
					_moderationEventName = nil
					WarMenu.CloseMenu()
					PlaySoundFrontend(-1, 'CONFIRM_BEEP', 'HUD_MINI_GAME_SOUNDSET', true)
					Gui.DisplayPersonalNotification('Tu reporte ha sido enviado. Gracias!')
				end
			end

			WarMenu.Display()
		end
	end
end)

-- Moderator Menu
AddEventHandler('lsv:init', function()
	if not Player.Moderator then
		return
	end

	Gui.CreateMenu('moderatorMenu', 'Menu de Moderador')
	WarMenu.SetSubTitle('moderatorMenu', 'Selecciona Opcion')
	WarMenu.SetTitleColor('moderatorMenu', table.unpack(Color.WHITE))
	WarMenu.SetTitleBackgroundColor('moderatorMenu', table.unpack(Color.PURPLE))

	WarMenu.CreateSubMenu('moderatorMenu_players', 'moderatorMenu', 'Selecciona Jugador Para Moderar')
	WarMenu.CreateSubMenu('moderatorMenu_moderation', 'moderatorMenu_players')
	WarMenu.CreateSubMenu('moderatorMenu_reason', 'moderatorMenu_moderation')
	WarMenu.CreateSubMenu('moderatorMenu_banDuration', 'moderatorMenu_reason')

	WarMenu.CreateSubMenu('moderatorMenu_actions', 'moderatorMenu', 'Acciones')

	while true do
		Citizen.Wait(0)

		if WarMenu.IsMenuOpened('moderatorMenu') then
			WarMenu.MenuButton('Jugadores', 'moderatorMenu_players')
			WarMenu.MenuButton('Acciones', 'moderatorMenu_actions')

			WarMenu.Display()
		elseif WarMenu.IsMenuOpened('moderatorMenu_players') then
			for _, id in ipairs(GetActivePlayers()) do
				if id ~= PlayerId() then
					local playerName = GetPlayerName(id)

					if WarMenu.MenuButton(playerName, 'moderatorMenu_moderation') then
						_target = GetPlayerServerId(id)
						WarMenu.SetSubTitle('moderatorMenu_moderation', 'Selecciona Accion Para '..playerName)
					end
				end
			end

			WarMenu.Display()
		elseif WarMenu.IsMenuOpened('moderatorMenu_moderation') then
			if WarMenu.MenuButton('Kick', 'moderatorMenu_reason') then
				_moderationEventName = 'lsv:kickPlayer'
				WarMenu.SetSubTitle('moderatorMenu_reason', 'Seleccion Razon De Kick Para '..GetPlayerName(GetPlayerFromServerId(_target)))
			elseif WarMenu.MenuButton('Ban Temporal', 'moderatorMenu_reason') then
				_moderationEventName = 'lsv:tempBanPlayer'
				WarMenu.SetSubTitle('moderatorMenu_reason', 'Seleccion Razon De Ban Temporal Para '..GetPlayerName(GetPlayerFromServerId(_target)))
			elseif WarMenu.Button('espectear') then
				setSpectatorModeEnabled(true)
				while not IsControlJustReleased(3, 177) do
					Gui.DisplayHelpText(Gui.GetPlayerName(_target, '~w~')..' ('.._target..')\nPresiona ~INPUT_CELLPHONE_CANCEL~ para dejar de espectear.')
					Citizen.Wait(0)
				end
				setSpectatorModeEnabled(false)
			elseif Player.Moderator == Settings.moderator.levels.Administrator and WarMenu.MenuButton('~r~Ban', 'moderatorMenu_reason') then
				_moderationEventName = 'lsv:banPlayer'
				WarMenu.SetSubTitle('moderatorMenu_reason', 'Seleccion Razon De Ban Para '..GetPlayerName(GetPlayerFromServerId(_target)))
			end

			WarMenu.Display()
		elseif WarMenu.IsMenuOpened('moderatorMenu_reason') then
			for _, reason in ipairs(_moderationReasons) do
				if _moderationEventName ~= 'lsv:tempBanPlayer' then
					if WarMenu.Button(reason) then
						TriggerServerEvent(_moderationEventName, _target, reason)
						_target = nil
						_moderationEventName = nil
						WarMenu.CloseMenu()
					end
				else
					if WarMenu.MenuButton(reason, 'moderatorMenu_banDuration') then
						WarMenu.SetSubTitle('moderatorMenu_banDuration', 'Selecciona Duracion Del Ban Temporal Para '..GetPlayerName(GetPlayerFromServerId(_target)))
						_banReason = reason
					end
				end
			end

			WarMenu.Display()
		elseif WarMenu.IsMenuOpened('moderatorMenu_banDuration') then
			for _, days in ipairs(_banDurations) do
				if WarMenu.Button(days..' Dia(s)') then
					TriggerServerEvent(_moderationEventName, _target, _banReason, days)
					_target = nil
					_moderationEventName = nil
					_banReason = nil
					WarMenu.CloseMenu()
				end
			end

			WarMenu.Display()
		elseif WarMenu.IsMenuOpened('moderatorMenu_actions') then
			if WarMenu.Button('Eliminar Objetos No Deseados') then
				Prompt.Show('Eliminando Objetos No Deseados')

				World.ForEachObjectAsync(function(object)
					if not NetworkGetEntityIsNetworked(object) then
						return
					end

					local netId = ObjToNet(object)

					if Network.DoesEntityExistWithNetworkId(netId) then
						return
					end

					if NetworkDoesEntityExistWithNetworkId(netId) and Network.RequestControlOfNetworkId(netId) then
						World.DeleteEntity(object)
					end
				end)

				Prompt.Hide()
			end

			if WarMenu.Button('Eliminar NPCs No Deseados') then
				Prompt.Show('Eliminando NPCs No Deseados')

				World.ForEachPedAsync(function(ped)
					if not NetworkGetEntityIsNetworked(ped) or IsPedAPlayer(ped) then
						return
					end

					local netId = PedToNet(ped)

					if Network.DoesEntityExistWithNetworkId(netId) then
						return
					end

					if NetworkDoesEntityExistWithNetworkId(netId) and Network.RequestControlOfNetworkId(netId) then
						World.DeleteEntity(ped)
					end
				end)

				Prompt.Hide()
			end

			if WarMenu.Button('Eliminar Vehiculos No Deseados') then
				Prompt.Show('Eliminando Vehiculos No Deseados')

				World.ForEachVehicleAsync(function(vehicle)
					if not NetworkGetEntityIsNetworked(vehicle) then
						return
					end

					local netId = VehToNet(vehicle)

					if Network.DoesEntityExistWithNetworkId(netId) then
						return
					end

					if NetworkDoesEntityExistWithNetworkId(netId) and Network.RequestControlOfNetworkId(netId) then
						World.DeleteEntity(vehicle)
					end
				end)

				Prompt.Hide()
			end

			WarMenu.Display()
		end
	end
end)

AddEventHandler('lsv:playerDisconnected', function(_, player)
	_reportedPlayers[player] = nil
end)
