local _discordUrl = nil

local _killstreak = 0
local _lastKillTimer = Timer.New()

local _killDetailsTimer = Timer.New()
local _killDetailsScale = Animated.New(0.30, 250, 0.55)
local _killDetailsAlpha = Animated.New(255, 250)
local _lastKillDetails = nil

local _lastEventTime = nil

local _weaponUnlocks = { }

RegisterNetEvent('lsv:setupHud')
AddEventHandler('lsv:setupHud', function(hud)
	if hud.pauseMenuTitle ~= '' then
		AddTextEntry('FE_THDR_GTAO', hud.pauseMenuTitle)
	end

	if hud.discordUrl ~= '' then
		_discordUrl = hud.discordUrl

		if Player.PatreonTier ~= 0 then return end

		while true do
			Citizen.Wait(Settings.discordNotificationInterval)
			PlaySoundFrontend(-1, 'EVENT_START_TEXT', 'GTAO_FM_EVENTS_SOUNDSET', true)
			FlashMinimapDisplay()
			Gui.DisplayPersonalNotification('Unete a nuestro Discord para leer todas las noticias y actualizaciones!.', 'CHAR_MP_STRIPCLUB_PR', 'Invitacion VIP', _discordUrl, 2)

			Citizen.Wait(Settings.discordNotificationInterval)
			PlaySoundFrontend(-1, 'EVENT_START_TEXT', 'GTAO_FM_EVENTS_SOUNDSET', true)
			FlashMinimapDisplay()
			Gui.DisplayPersonalNotification('Gana más recompensas y obtén bonificaciones exclusivas en el juego. \nTodos los detalles en nuestro Discord.', 'CHAR_MP_STRIPCLUB_PR', 'Conviértete en VIP', _discordUrl, 2)
		end
	end
end)

RegisterNetEvent('lsv:updateLastEventTime')
AddEventHandler('lsv:updateLastEventTime', function(time)
	_lastEventTime = time
end)

RegisterNetEvent('lsv:playerDisconnected')
AddEventHandler('lsv:playerDisconnected', function(name, player, reason)
	local message = '<C>'..name..'</C> salio.'
	if Player.Moderator then
		message = message..' ~m~('..reason..')'
	end

	Gui.DisplayNotification(message)
end)

RegisterNetEvent('lsv:playerConnected')
AddEventHandler('lsv:playerConnected', function(player)
	local playerId = GetPlayerFromServerId(player)
	if PlayerId() ~= playerId and NetworkIsPlayerActive(playerId) then
		Gui.DisplayNotification(Gui.GetPlayerName(player)..' conecto.')
		Map.SetBlipFlashes(GetBlipFromEntity(GetPlayerPed(playerId)))
	end
end)

RegisterNetEvent('lsv:onPlayerDied')
AddEventHandler('lsv:onPlayerDied', function(player, suicide)
	if not Player.IsInInterior and not Player.Settings.disableKillFeed and NetworkIsPlayerActive(GetPlayerFromServerId(player)) then
		if suicide then
			Gui.DisplayNotification(Gui.GetPlayerName(player)..' se suicido.')
		else
			Gui.DisplayNotification(Gui.GetPlayerName(player)..' murio.')
		end
	end

	if player ~= Player.ServerId() then
		return
	end

	Player.Deaths = Player.Deaths + 1
	Player.Deathstreak = Player.Deathstreak + 1
	Player.Killstreak = 0
	_killstreak = 0
end)

RegisterNetEvent('lsv:onPlayerVsUpdated')
AddEventHandler('lsv:onPlayerVsUpdated', function(killer, victim, killerScore, victimScore)
	if Player.Settings.disableKillFeed then
		return
	end

	local killerPlayer = GetPlayerFromServerId(killer)
	local victimPlayer = GetPlayerFromServerId(victim)
	if not NetworkIsPlayerActive(killerPlayer) or not NetworkIsPlayerActive(victimPlayer) then
		return
	end

	local killerPedshot = Streaming.RegisterPedheadshotAsync(GetPlayerPed(killerPlayer))
	local victimPedshot = Streaming.RegisterPedheadshotAsync(GetPlayerPed(victimPlayer))

	local killerTxd = GetPedheadshotTxdString(killerPedshot)
	local victimTxd = GetPedheadshotTxdString(victimPedshot)

	BeginTextCommandThefeedPost('')
	Citizen.InvokeNative(0xB6871B0555B02996, killerTxd, killerTxd, killerScore, victimTxd, victimTxd, victimScore, 6, 9) -- END_TEXT_COMMAND_THEFEED_POST_VERSUS_TU

	UnregisterPedheadshot(killerPedshot)
	UnregisterPedheadshot(victimPedshot)
end)

RegisterNetEvent('lsv:onPlayerKilled')
AddEventHandler('lsv:onPlayerKilled', function(player, killer, killstreak, deathMessageIndex)
	if not Player.IsInInterior and not Player.Settings.disableKillFeed and NetworkIsPlayerActive(GetPlayerFromServerId(player)) and NetworkIsPlayerActive(GetPlayerFromServerId(killer)) then
		local deathMessage = deathMessageIndex and Settings.pvp.messages[deathMessageIndex] or 'le diste un headshot a'
		local notificationMessage = Gui.GetPlayerName(killer)..' '..deathMessage..' '..Gui.GetPlayerName(player, nil, true)
		if killstreak then
			notificationMessage = notificationMessage..' (Racha de muertes '..killstreak..')'
		end
		Gui.DisplayNotification(notificationMessage)
	end

	if player == Player.ServerId() then
		Player.Deaths = Player.Deaths + 1
		Player.Deathstreak = Player.Deathstreak + 1
		Player.Killstreak = 0
		_killstreak = 0
		return
	elseif killer ~= Player.ServerId() then
		return
	end

	Player.Deathstreak = 0

	Player.Kills = Player.Kills + 1
	Player.Killstreak = Player.Killstreak + 1

	if Player.Killstreak == Settings.pvp.bounty.killstreak then
		FlashMinimapDisplay()
		Gui.DisplayPersonalNotification('Cuidado, alguien ha puesto una recompensa en ti.', 'CHAR_LESTER_DEATHWISH', 'Unknown', '', 2)
	end

	if _lastKillTimer:elapsed() > Settings.killstreakTimeout then
		_killstreak = 1
		_lastKillTimer:restart()
		return
	end

	_killstreak = _killstreak + 1
	_lastKillTimer:restart()

	if _killstreak < 2 or not Player.IsInFreeroam() then
		return
	end

	local killstreakMessage = 'DOUBLE KILL'
	if _killstreak == 3 then killstreakMessage = 'TRIPLE KILL'
	elseif _killstreak == 4 then killstreakMessage = 'MEGA KILL'
	elseif _killstreak == 5 then killstreakMessage = 'ULTRA KILL'
	elseif _killstreak == 6 then killstreakMessage = 'MONSTER KILL'
	elseif _killstreak == 7 then killstreakMessage = 'LUDICROUS KILL'
	elseif _killstreak == 8 then killstreakMessage = 'HOLY SHIT'
	elseif _killstreak == 9 then killstreakMessage = 'RAMPAGE'
	elseif _killstreak > 9 then killstreakMessage = 'GODLIKE' end

	local scaleform = Scaleform.NewAsync('MIDSIZED_MESSAGE')
	scaleform:call('SHOW_SHARD_MIDSIZED_MESSAGE', killstreakMessage)
	scaleform:renderFullscreenTimed(5000)
end)

RegisterNetEvent('lsv:bountyWasSet')
AddEventHandler('lsv:bountyWasSet', function(player)
	if player ~= Player.ServerId() and NetworkIsPlayerActive(player) then
		FlashMinimapDisplay()
		Gui.DisplayNotification('Se ha puesto una recompensa en '..Gui.GetPlayerName(player)..'.')
	end
end)

RegisterNetEvent('lsv:tebexPackagePurchased')
AddEventHandler('lsv:tebexPackagePurchased', function()
	FlashMinimapDisplay()
	PlaySoundFrontend(-1, 'WEAPON_PURCHASE', 'HUD_AMMO_SHOP_SOUNDSET', true)
	Gui.DisplayNotification('Gracias por tu compra!', 'CHAR_SOCIAL_CLUB', 'Infames PVP', 'Tienda Tebex', 4)
end)

RegisterNetEvent('lsv:updateLastKillDetails')
AddEventHandler('lsv:updateLastKillDetails', function(killDetails)
	_lastKillDetails = nil

	if killDetails then
		if table.length(killDetails) == 0 then
			_lastKillDetails = 'JUGADOR ASESINADO'
		else
			_lastKillDetails = { }

			if killDetails.killstreak then
				table.insert(_lastKillDetails, 'RACHA DE MUERTES x'..killDetails.killstreak)
			end

			if killDetails.headshot then
				table.insert(_lastKillDetails, 'HEADSHOT')
			end

			if killDetails.meleeKill then
				table.insert(_lastKillDetails, 'ASESINATO MELEE')
			end

			if killDetails.bountyHunter then
				table.insert(_lastKillDetails, 'CAZARECOMPENSAS')
			end

			if killDetails.kingSlayer then
				table.insert(_lastKillDetails, 'ASESINO DE REYES')
			end

			if killDetails.revenge then
				table.insert(_lastKillDetails, 'VENGANZA')
			end

			if killDetails.patreonBonus then
				table.insert(_lastKillDetails, 'PATREON BONUS x'..killDetails.patreonBonus)
			end

			_lastKillDetails = table.concat(_lastKillDetails, '\n')
		end

		_killDetailsTimer:restart()
		_killDetailsAlpha:restart()
		_killDetailsScale:restart()
	end
end)

RegisterNetEvent('lsv:challengeComplete')
AddEventHandler('lsv:challengeComplete', function(id, allChallengesComplete)
	FlashMinimapDisplay()
	PlaySoundFrontend(-1, 'EVENT_START_TEXT', 'GTAO_FM_EVENTS_SOUNDSET', true)
	Gui.DisplayPersonalNotification(allChallengesComplete and 'Todos Los Desafíos Completados!' or 'Desafio Completado!\n'..Settings.challenges.ids[id].name)
end)

Citizen.CreateThread(function()
	local eventTimer = Timer.New()

	while true do
		Citizen.Wait(500)

		if _lastEventTime then
			_lastEventTime = _lastEventTime + eventTimer:elapsed()
		end

		eventTimer:restart()
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		RemoveMultiplayerBankCash()
		RemoveMultiplayerHudCash()
	end
end)

AddEventHandler('lsv:init', function()
	while true do
		Citizen.Wait(0)

		if Settings.disableCrosshair or Player.Settings.disableCrosshair then
			local _, weaponHash = GetCurrentPedWeapon(PlayerPedId(), true)
			if weaponHash ~= `WEAPON_SNIPERRIFLE` and weaponHash ~= `WEAPON_HEAVYSNIPER` and weaponHash ~= `WEAPON_HEAVYSNIPER_MK2` then
				HideHudComponentThisFrame(14)
			end
		elseif Settings.disableCrosshairForVehicleDriver then
			local playerPed = PlayerPedId()
			local vehicle = GetVehiclePedIsIn(playerPed, false)
			if DoesEntityExist(vehicle) then
				if GetPedInVehicleSeat(vehicle, -1) == playerPed then
					HideHudComponentThisFrame(14)
				end
			end
		end

		if not WarMenu.IsAnyMenuOpened() then
			if IsControlJustReleased(0, 20) then
				Scoreboard.ToggleVisibility()
				PlaySoundFrontend(-1, Scoreboard.IsVisible() and 'SELECT' or 'QUIT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
			elseif Scoreboard.IsVisible() then
				if IsControlJustReleased(0, 207) then
					Scoreboard.NextPage()
					PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
				elseif IsControlJustReleased(0, 208) then
					Scoreboard.PrevPage()
					PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
				end
			end
		end
	end
end)

AddEventHandler('lsv:init', function(playerData)
	if not playerData.ServerRestartIn then
		return
	end

	local serverRestartTimer = Timer.New(playerData.ServerRestartIn * 1000)

	while true do
		Citizen.Wait(0)
		local serverRestartIn = math.abs(serverRestartTimer:elapsed())

		if serverRestartIn <= Settings.serverRestart.warnBeforeMs then
			Gui.DrawTimerBar('EL SERVIDOR SE REINICIA EN', serverRestartIn, 17)
		end
	end
end)

AddEventHandler('lsv:init', function()
	local cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', GetGameplayCamCoord(), 0., 0., 0., GetGameplayCamFov())
	local activated = false
	local wasTipDisplayed = false
	local relZ = nil

	while true do
		Citizen.Wait(0)

		local veh = GetVehiclePedIsIn(PlayerPedId())
		if veh ~= 0 then
			if not wasTipDisplayed then
				Gui.DisplayHelpText('Presiona ~'..Settings.gta2Cam.key.name..'~ para activar la cámara de GTA 2.')
				wasTipDisplayed = true
			end

			if IsControlJustReleased(0, Settings.gta2Cam.key.code) then
				activated = not activated
			end
		else
			activated = false
		end

		if activated then
			if not IsCamActive(cam) then
				SetCamActive(cam, true)
				RenderScriptCams(true, true, 1000, true, false)
				relZ = Settings.gta2Cam.min
			end

			local speed = GetEntitySpeed(veh) * 3.6 -- kmh
			if speed > Settings.gta2Cam.minSpeed then
				if relZ < Settings.gta2Cam.max then
					relZ = relZ + Settings.gta2Cam.step
				end
			elseif relZ > Settings.gta2Cam.min then
				relZ = relZ - Settings.gta2Cam.step
			end

			local pos = Player.Position()
			SetCamCoord(cam, pos.x, pos.y, pos.z + relZ)
			PointCamAtCoord(cam, pos.x, pos.y, pos.z + 0.5)
		else
			if IsCamActive(cam) then
				SetCamActive(cam, false)
				RenderScriptCams(false, false, 0)
				relZ = nil
			end
		end
	end
end)

AddEventHandler('lsv:init', function()
	if Settings.voice.enabled then
		return
	end

	while true do
		Citizen.Wait(0)
		DisableControlAction(0, 249, true)
	end
end)

AddEventHandler('lsv:init', function()
	while true do
		Citizen.Wait(0)

		if not Player.Settings.disableEventTimer and _lastEventTime then
			if Player.IsInFreeroam() then
				local timePassed = Settings.event.interval - _lastEventTime
				if timePassed > 0 and timePassed <= Settings.nextEventTime then
					Gui.DrawTimerBar('SIGUIENTE EVENTO EN', timePassed, 1)
				end
			end
		end
	end
end)

AddEventHandler('lsv:cashUpdated', function(cash)
	local backgroundColor = nil
	if cash < 0 then
		backgroundColor = 6
	end

	Gui.DisplayPersonalNotification('<C>$'..math.abs(cash)..'</C>', nil, nil, nil, nil, backgroundColor)
end)

AddEventHandler('lsv:showExperience', function(exp)
	local rank = Player.Rank
	local playerExp = Player.Experience

	local scaleform = 19
	RequestScaleformScriptHudMovie(scaleform)
	while not HasHudScaleformLoaded(scaleform) do
		Citizen.Wait(0)
	end

	BeginScaleformMovieMethodHudComponent(scaleform, 'SET_RANK_SCORES')
	PushScaleformMovieFunctionParameterInt(Rank.GetRequiredExperience(rank))
	PushScaleformMovieFunctionParameterInt(Rank.GetRequiredExperience(rank + 1))
	PushScaleformMovieFunctionParameterInt(playerExp - exp)
	PushScaleformMovieFunctionParameterInt(playerExp)
	PushScaleformMovieFunctionParameterInt(rank)
	EndScaleformMovieMethodReturn()

	BeginScaleformMovieMethodHudComponent(scaleform, 'SET_COLOUR')
	PushScaleformMovieFunctionParameterInt(116)
	EndScaleformMovieMethodReturn()

	BeginScaleformMovieMethodHudComponent(scaleform, 'OVERRIDE_ANIMATION_SPEED')
	PushScaleformMovieFunctionParameterInt(2000)
	EndScaleformMovieMethodReturn()
end)

AddEventHandler('lsv:rankUp', function(rank)
	local wasWeaponUnlocksEmpty = next(_weaponUnlocks) == nil

	table.foreach(Weapon, function(weapon, id)
		if weapon.rank and weapon.rank > Player.Rank and weapon.rank <= rank and not HasPedGotWeapon(PlayerPedId(), GetHashKey(id), false) then
			_weaponUnlocks[id] = weapon.name
		end
	end)

	if not wasWeaponUnlocksEmpty then
		return
	end

	for id, name in pairs(_weaponUnlocks) do
		PlaySoundFrontend(-1, 'CHALLENGE_UNLOCKED', 'HUD_AWARDS', true)
		Gui.DisplayNotification(name, 'CHAR_AMMUNATION', 'Arma Desbloqueada')

		Citizen.Wait(30000)

		_weaponUnlocks[id] = nil
	end
end)

AddEventHandler('lsv:rankUp', function(rank)
	PlaySoundFrontend(-1, 'MP_RANK_UP', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false)

	local scaleform = Scaleform.NewAsync('MIDSIZED_MESSAGE')
	scaleform:call('SHOW_SHARD_MIDSIZED_MESSAGE', 'SUBISTE DE RANGO', 'Rango '..rank, 21)
	scaleform:renderFullscreenTimed(10000)
end)

AddEventHandler('lsv:init', function()
	while true do
		Citizen.Wait(0)

		if _lastKillDetails and Player.Settings.showKillDetails then
			if Player.IsActive() and _killDetailsTimer:elapsed() < Settings.rewardNotificationTime then
				Gui.SetTextParams(0, { Color.WHITE[1], Color.WHITE[2], Color.WHITE[3], _killDetailsAlpha:get() }, _killDetailsScale:get(), true, true, true)
				Gui.DrawText(_lastKillDetails, 0.5, 0.60)
			else
				_lastKillDetails = nil
			end
		end
	end
end)

AddEventHandler('lsv:init', function()
	if Player.Settings.disableTips then
		return
	end

	--https://pastebin.com/amtjjcHb
	local tips = {
		'Realizar misiones y eliminar jugadores enemigos te dará dinero y experiencia.',
		'Presiona ~INPUT_MULTIPLAYER_INFO~ para ver el marcador.',
		'Visita ~BLIP_GUN_SHOP~ para comprar munición de Armas Especiales.',
		'Presiona ~INPUT_ENTER_CHEAT_CODE~ para agrandar el radar.',
		'Presiona ~INPUT_DUCK~ para entrar en modo sigilo y esconderte del radar.',
		'Visita ~BLIP_CLOTHES_STORE~ para cambiar la apariencia de tu personaje.',
		'Utiliza el menu de interacción para administrar tu Crew.',
	}

	table.iforeach(tips, function(tip)
		HelpQueue.PushBack(tip)
	end)
end)

AddEventHandler('lsv:init', function()
	local speedColor = { 202, 202, 201 }
	local discordUrlColor = { 254, 254, 254, 128 }

	while true do
		Citizen.Wait(0)

		local minimapWidth = IsBigmapActive() and 0.225 or 0.14
		local minimapCenter = minimapWidth / 2

		local safeZoneLeft = SafeZone.Left()
		local safeZoneTop = SafeZone.Top()

		if Player.PatreonTier == 0 and _discordUrl and not Player.Settings.disableTips then
			Gui.SetTextParams(7, discordUrlColor, 0.45, true, true, true)
			Gui.DrawText(_discordUrl, safeZoneLeft + 0.85, safeZoneTop, 1.0)
		end

		if Settings.enableSpeedometer then
			local playerPed = PlayerPedId()

			if IsPedInAnyVehicle(playerPed, true) then
				Gui.SetTextParams(4, speedColor, 0.425, true, true)
				Gui.DrawText(string.to_speed(GetEntitySpeed(GetVehiclePedIsUsing(playerPed))), safeZoneLeft + minimapWidth - 0.0045, SafeZone.Bottom() - 0.04725, 1.0)
			end
		end

		local y = SafeZone.Bottom() - 0.004

		Gui.SetTextParams(7, Color.WHITE, 0.3, true, true, false)

		local expForCurrentRank = Rank.GetRequiredExperience(Player.Rank)
		local expToNextRank = Rank.GetRequiredExperience(Player.Rank + 1)
		Gui.DrawText('~b~EXP~w~ '..math.floor(((Player.Experience - expForCurrentRank) / (expToNextRank - expForCurrentRank)) * 100)..'% ('..Player.Rank..')', safeZoneLeft, y)
		Gui.SetTextParams(7, Color.WHITE, 0.3, true, true, false)
		Gui.DrawText(math.floor(Player.Cash)..' ~g~$~w~', safeZoneLeft + minimapWidth, y, 1.0)
	end
end)

AddEventHandler('lsv:init', function()
	local scaleform = Scaleform.NewAsync('INSTRUCTIONAL_BUTTONS')
	local lastState = nil

	while true do
		Citizen.Wait(0)

		if not Player.Settings.disableTips then
			if Player.IsActive() then
				if WarMenu.IsAnyMenuOpened() then
					if lastState ~= 1 then
						scaleform:call('CLEAR_ALL')
						scaleform:call('SET_DATA_SLOT', 0, '~INPUT_FRONTEND_RRIGHT~', 'Cerrar Menu')
						lastState = 1
					end
				elseif Scoreboard.IsVisible() then
					if lastState ~= 2 then
						scaleform:call('CLEAR_ALL')
						scaleform:call('SET_DATA_SLOT', 0, '~INPUT_FRONTEND_LT~', 'Siguiente')
						scaleform:call('SET_DATA_SLOT', 1, '~INPUT_FRONTEND_RT~', 'Anterior')
						scaleform:call('SET_DATA_SLOT', 2, '~INPUT_MULTIPLAYER_INFO~', 'Ocultar Marcador')
						lastState = 2
					end
				else
					if lastState ~= 3 then
						scaleform:call('CLEAR_ALL')
						scaleform:call('SET_DATA_SLOT', 0, '~INPUT_REPLAY_STARTPOINT~', Player.Moderator and 'Menu de moderador' or 'Reportar Jugador')
						scaleform:call('SET_DATA_SLOT', 1, '~INPUT_MP_TEXT_CHAT_TEAM~', 'Menu de Vehículo Personal')
						scaleform:call('SET_DATA_SLOT', 2, '~INPUT_INTERACTION_MENU~', 'Menu de Interaccion')
						lastState = 3
					end
				end

				scaleform:call('DRAW_INSTRUCTIONAL_BUTTONS')
				scaleform:renderFullscreen()
			else
				lastState = nil
			end
		end
	end
end)

AddEventHandler('lsv:init', function()
	while true do
		Citizen.Wait(0)

		if IsControlJustReleased(0, 243) then -- `
			SetBigmapActive(not IsBigmapActive(), false)
		end
	end
end)
