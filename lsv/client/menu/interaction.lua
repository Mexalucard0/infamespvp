local _actions = {
	{ name = 'Ole', scenario = 'WORLD_HUMAN_CHEERING' },
	{ name = 'Impactante', scenario = 'WORLD_HUMAN_MOBILE_FILM_SHOCKING' },
	{ name = 'Apoyarse', scenario = 'WORLD_HUMAN_LEANING' },
	{ name = 'Fumar', scenario = 'WORLD_HUMAN_SMOKING' },
	{ name = 'Beber', scenario = 'WORLD_HUMAN_DRINKING' },
	{ name = 'Flexiones', scenario = 'WORLD_HUMAN_MUSCLE_FLEX' },
	{ name = 'Fiesta', scenario = 'WORLD_HUMAN_PARTYING' },
	{ name = 'Musico', scenario = 'WORLD_HUMAN_MUSICIAN' },
	{ name = 'Paparazzi', scenario = 'WORLD_HUMAN_PAPARAZZI' },
	{ name = 'Reloj', scenario = 'WORLD_HUMAN_STRIP_WATCH_STAND' },
	{ name = 'Pescando', scenario = 'WORLD_HUMAN_STAND_FISHING' },
	{ name = 'Yoga', scenario = 'WORLD_HUMAN_YOGA' },
	{ name = 'Tomar Sol', scenario = 'WORLD_HUMAN_SUNBATHE' },
	{ name = 'Picnic', scenario = 'WORLD_HUMAN_PICNIC' },
	{ name = 'Binoculares', scenario = 'WORLD_HUMAN_BINOCULARS' },
	{ name = 'Investigar', scenario = 'CODE_HUMAN_POLICE_INVESTIGATE' },
	{ name = 'Tiempo de Muerto', scenario = 'CODE_HUMAN_MEDIC_TIME_OF_DEATH' },
	{ name = 'Disparar', scenario = 'WORLD_HUMAN_STAND_FIRE' },
}

local _crewRace = { }
local _crewFinishRadius = 10.

local function resetCrewRace()
	if _crewRace.blip then
		RemoveBlip(_crewRace.blip)
	end

	_crewRace = { }
end

local function weaponTintPrice(tint, weaponHash)
	if GetPedWeaponTintIndex(PlayerPedId(), weaponHash) == tint.index then
		return 'Equipado'
	end

	if Player.Kills < tint.kills then
		return 'Asesina '..tint.kills..' jugadores'
	end

	return '$'..tint.cash
end

local function weaponComponentPrice(componentIndex, weapon, componentHash)
	local weaponHash = GetHashKey(weapon)
	if HasPedGotWeaponComponent(PlayerPedId(), weaponHash, componentHash) then
		return ''
	end

	local component = Weapon[weapon].components[componentIndex]
	if component.rank and Player.Rank < component.rank then
		return 'Rango '..component.rank
	end

	if component.kills and Player.GetWeaponStats(weaponHash) < component.kills then
		return 'Asesina '..component.kills..' jugadores'
	end

	return '$'..component.cash
end

local function weaponPrice(weapon)
	if HasPedGotWeapon(PlayerPedId(), GetHashKey(weapon), false) then
		return ''
	end

	local weapon = Weapon[weapon]
	if weapon.rank and Player.Rank < weapon.rank then
		return 'Rango '..weapon.rank
	end

	if weapon.prestige and Player.Prestige < weapon.prestige then
		return 'Prestigio '..weapon.prestige
	end

	if weapon.cash then
		return '$'..weapon.cash
	end

	return nil
end

local function weaponAmmoPrice(ammoType, ammo, maxAmmo)
	if ammo == maxAmmo then
		return 'Completo'
	end

	local price = Settings.ammuNationRefillAmmo[ammoType].price
	if Player.PatreonTier ~= 0 then
		price = math.floor(price * Settings.patreon.ammo[Player.PatreonTier])
	end

	return '$'..price
end

local function fullWeaponAmmoPrice(ammoType, ammoClipCount)
	if ammoClipCount == 0 then
		return 'Completo'
	end

	return '$'..tostring(ammoClipCount * Settings.ammuNationRefillAmmo[ammoType].price)
end

RegisterNetEvent('lsv:weaponTintUpdated')
AddEventHandler('lsv:weaponTintUpdated', function(weaponHash, tintIndex)
	if weaponHash then
		SetPedWeaponTintIndex(PlayerPedId(), weaponHash, tintIndex)
		Player.SaveWeapons()

		PlaySoundFrontend(-1, 'WEAPON_ATTACHMENT_EQUIP', 'HUD_AMMO_SHOP_SOUNDSET', true)
	else
		Gui.DisplayPersonalNotification('No tienes suficiente dinero.')
	end

	Prompt.Hide()
end)

RegisterNetEvent('lsv:weaponComponentUpdated')
AddEventHandler('lsv:weaponComponentUpdated', function(weapon, componentIndex)
	if weapon then
		GiveWeaponComponentToPed(PlayerPedId(), GetHashKey(weapon), Weapon[weapon].components[componentIndex].hash)
		Player.SaveWeapons()

		PlaySoundFrontend(-1, 'WEAPON_ATTACHMENT_EQUIP', 'HUD_AMMO_SHOP_SOUNDSET', true)
	else
		Gui.DisplayPersonalNotification('No tienes suficiente dinero.')
	end

	Prompt.Hide()
end)

RegisterNetEvent('lsv:weaponPurchased')
AddEventHandler('lsv:weaponPurchased', function(weapon)
	if weapon then
		local weaponHash = GetHashKey(weapon)
		GiveWeaponToPed(PlayerPedId(), weaponHash, WeaponUtility.GetSpawningAmmo(weaponHash), false, true)
		Player.SaveWeapons()

		PlaySoundFrontend(-1, 'WEAPON_PURCHASE', 'HUD_AMMO_SHOP_SOUNDSET', true)
	else
		Gui.DisplayPersonalNotification('No tienes suficiente dinero.')
	end

	Prompt.Hide()
end)

RegisterNetEvent('lsv:ammoRefilled')
AddEventHandler('lsv:ammoRefilled', function(weapon, amount, fullAmmo)
	if amount then
		if not fullAmmo then
			AddAmmoToPed(PlayerPedId(), GetHashKey(weapon), amount)
		else
			local weaponHash = GetHashKey(weapon)
			local _, maxAmmo = GetMaxAmmo(PlayerPedId(), weaponHash)
			SetPedAmmo(PlayerPedId(), weaponHash, maxAmmo)
		end

		PlaySoundFrontend(-1, 'WEAPON_AMMO_PURCHASE', 'HUD_AMMO_SHOP_SOUNDSET', true)
	else
		Gui.DisplayPersonalNotification('No tienes suficiente dinero.')
	end

	Prompt.Hide()
end)

RegisterNetEvent('lsv:finishCrewRace')
AddEventHandler('lsv:finishCrewRace', function(winner)
	if not Player.IsInCrew() then
		return
	end

	Gui.DisplayPersonalNotification(Gui.GetPlayerName(winner)..' gano Carrera de Crew.')

	resetCrewRace()

	if Player.ServerId() == winner then
		PlaySoundFrontend(-1, 'RACE_PLACED', 'HUD_AWARDS', true)

		local scaleform = Scaleform.NewAsync('MIDSIZED_MESSAGE')
		scaleform:call('SHOW_SHARD_MIDSIZED_MESSAGE', 'GANASTE', '')
		scaleform:renderFullscreenTimed(7000)
	end
end)

RegisterNetEvent('lsv:crewRaceStarted')
AddEventHandler('lsv:crewRaceStarted', function(finishCoords)
	if not Player.IsInCrew() then
		return
	end

	_crewRace.inProgress = true

	_crewRace.blip = Map.CreatePlaceBlip(Blip.CREW_RACE_FINISH, finishCoords.x, finishCoords.y, finishCoords.z)
	SetBlipAsShortRange(_crewRace.blip, false)
	SetBlipRoute(_crewRace.blip, true)
	Map.SetBlipFlashes(_crewRace.blip)

	_crewRace.finishCoords = finishCoords

	if Player.IsACrewLeader() then
		DeleteWaypoint()
		WarMenu.CloseMenu()
		Prompt.Hide()
	end

	local countdownMessages = { '3...', '2...', '1...' }
	while #countdownMessages ~= 0 do
		PlaySoundFrontend(-1, '3_2_1', 'HUD_MINI_GAME_SOUNDSET', true)
		Gui.DisplayPersonalNotification(countdownMessages[1])
		Citizen.Wait(1000)
		table.remove(countdownMessages, 1)
	end

	PlaySoundFrontend(-1, 'GO', 'HUD_MINI_GAME_SOUNDSET', true)
	Gui.DisplayPersonalNotification('GO!')

	while true do
		Citizen.Wait(0)

		if not _crewRace.inProgress then
			return
		end

		if Player.DistanceTo(_crewRace.finishCoords) < _crewFinishRadius then
			TriggerServerEvent('lsv:finishCrewRace', Player.ServerId())
			return
		end
	end
end)

RegisterNetEvent('lsv:crewMemberLeft')
AddEventHandler('lsv:crewMemberLeft', function(player)
	if not Player.IsInCrew() or player ~= Player.ServerId() then
		return
	end

	resetCrewRace()
end)

RegisterNetEvent('lsv:crewDisbanded')
AddEventHandler('lsv:crewDisbanded', function()
	if not Player.IsInCrew() then
		return
	end

	resetCrewRace()
end)

AddEventHandler('lsv:init', function(playerData)
	local serverRestartTimer = nil
	if playerData.ServerRestartIn then
		serverRestartTimer = Timer.New(playerData.ServerRestartIn * 1000)
	end

	local killYourselfTimer = Timer.New()

	local selectedWeapon = nil
	local selectedWeaponHash = nil
	local selectedWeaponCategory = nil
	local selectedWeaponComponent = nil
	local selectedAmmoType = nil

	Gui.CreateMenu('interaction', GetPlayerName(PlayerId()))
	WarMenu.SetTitleColor('interaction', 255, 255, 255)
	WarMenu.SetTitleBackgroundColor('interaction', table.unpack(Color.WHITE))
	WarMenu.SetTitleBackgroundSprite('interaction', 'commonmenu', 'interaction_bgd')

	WarMenu.CreateSubMenu('interaction_confirm', 'interaction', 'Estas seguro?')

	WarMenu.CreateSubMenu('actions', 'interaction', 'Acciones')

	WarMenu.CreateSubMenu('challenges', 'interaction', 'Desafíos')

	WarMenu.CreateSubMenu('crew', 'interaction', 'Crew')
	WarMenu.CreateSubMenu('inviteToCrew', 'crew', 'Invitar a Crew')

	WarMenu.CreateSubMenu('drugBusiness', 'interaction', 'Negocio de Drogas (Suministros/Stock)')

	WarMenu.CreateSubMenu('stats', 'interaction', 'Estadisticas')
	WarMenu.CreateSubMenu('stats_weapons', 'stats', 'Asesinatos con arma')
	WarMenu.CreateSubMenu('stats_prestige', 'stats', 'Bonus de prestigio')

	WarMenu.CreateSubMenu('settings', 'interaction', 'Configuracion')

	WarMenu.CreateSubMenu('ammunition', 'interaction', 'Municion')
	WarMenu.SetTitleColor('ammunition', 0, 0, 0, 0)
	WarMenu.SetTitleBackgroundSprite('ammunition', 'shopui_title_gr_gunmod', 'shopui_title_gr_gunmod')

	WarMenu.CreateSubMenu('ammunition_ammo', 'ammunition', 'Municion')

	WarMenu.CreateSubMenu('ammunation', 'interaction', 'Ammu-Nation')
	WarMenu.SetTitleColor('ammunation', 0, 0, 0, 0)
	WarMenu.SetTitleBackgroundSprite('ammunation', 'shopui_title_gunclub', 'shopui_title_gunclub')

	WarMenu.CreateSubMenu('ammunation_weapons', 'ammunation', '')

	WarMenu.CreateSubMenu('ammunation_discard', 'ammunation_weapons')
	WarMenu.CreateSubMenu('ammunation_weaponUpgrades', 'ammunation_weapons', '')

	WarMenu.CreateSubMenu('ammunation_removeUpgradeConfirm', 'ammunation_weaponUpgrades', '')

	local prestigeBonus = math.min(Settings.prestige.maxBaseLevel, Player.Prestige) * Settings.prestige.expMultiplier
	local prestigeBonusStr = '+'..string.format('%02.1f', prestigeBonus * 100)..'%'

	while true do
		if WarMenu.IsMenuOpened('interaction') then
			local killYourselfLeft = Settings.killYourselfInterval - killYourselfTimer:elapsed()

			if IsPlayerDead(PlayerId()) then
				WarMenu.CloseMenu()
				Prompt.Hide()
			else
				if IsPedActiveInScenario(PlayerPedId()) and WarMenu.Button('~r~Cancelar Accion') then
					ClearPedTasks(PlayerPedId())
					WarMenu.CloseMenu()
				end

				WarMenu.MenuButton('Municion', 'ammunition')

				WarMenu.MenuButton('Ammu-Nation', 'ammunation')
				if WarMenu.IsItemHovered() then
					Gui.ToolTip('Compra o modifica tus armas.')
				end

				WarMenu.MenuButton('Desafíos', 'challenges', serverRestartTimer and string.from_ms(math.abs(serverRestartTimer:elapsed())) or '')
				if WarMenu.IsItemHovered() then
					Gui.ToolTip('Los desafíos se restablecen después de cada reinicio del servidor.')
				end

				if (Player.IsACrewLeader() or not Player.IsInCrew()) and WarMenu.MenuButton('Crew', 'crew') then
				elseif Player.IsInCrew() and not Player.IsACrewLeader() and WarMenu.Button('Salir de la Crew') then
					TriggerServerEvent('lsv:leaveCrew')
					Prompt.ShowAsync()
					WarMenu.CloseMenu()
				elseif Player.HasAnyDrugBusiness() and WarMenu.MenuButton('Negocio de Drogas', 'drugBusiness') then
				elseif not IsPedActiveInScenario(PlayerPedId()) and WarMenu.MenuButton('Acciones', 'actions') then
				elseif WarMenu.MenuButton('Estadisticas', 'stats') then
				elseif WarMenu.MenuButton('Configuracion', 'settings') then
				elseif WarMenu.Button('Suicidarse', killYourselfLeft > 0 and string.from_ms(killYourselfLeft) or '') then
					if killYourselfLeft <= 0 then
						SetEntityHealth(PlayerPedId(), 0)
						WarMenu.CloseMenu()
						killYourselfTimer:restart()
					end
				elseif Player.Rank >= Settings.prestige.minRank and WarMenu.MenuButton('~o~Sube el nivel de prestigio a '..(Player.Prestige + 1), 'interaction_confirm') then
				elseif MissionManager.MissionHost == Player.ServerId() and WarMenu.Button('~r~Abortar mision') then
					MissionManager.AbortMission()
					WarMenu.CloseMenu()
				end
			end

			WarMenu.Display()
		elseif WarMenu.IsMenuOpened('challenges') then
			for id, progress in pairs(Player.Challenges) do
				local challenge = Settings.challenges.ids[id]
				WarMenu.Button(challenge.name, progress..'/'..challenge.count)
			end

			WarMenu.Display()
		elseif WarMenu.IsMenuOpened('actions') then
			local playerPed = PlayerPedId()
			for _, actionData in ipairs(_actions) do
				if WarMenu.Button(actionData.name) then
					if IsPedInAnyVehicle(playerPed, true) or not IsPedStill(playerPed) then
						Gui.DisplayPersonalNotification('No puedes realizar ninguna animacion ahora.')
					else
						TaskStartScenarioInPlace(playerPed, actionData.scenario, 0, true)
						WarMenu.CloseMenu()
					end
				end
			end

			WarMenu.Display()
		elseif WarMenu.IsMenuOpened('crew') then
			if Player.IsACrewLeader() or not Player.IsInCrew() then
				WarMenu.MenuButton('Invitar a tu Crew', 'inviteToCrew')
			end

			if Player.IsACrewLeader() then
				if not _crewRace.inProgress and WarMenu.Button('Iniciar Carrera') then
					local blip = Player.GetWaypoint()
					if DoesBlipExist(blip) then
						TriggerServerEvent('lsv:startCrewRace', GetBlipCoords(blip))
						Prompt.ShowAsync()
					else
						Gui.DisplayPersonalNotification('Primero debes colocar un punto en tu mapa.')
					end
				end

				if WarMenu.Button('~r~Disolver Crew') then
					TriggerServerEvent('lsv:disbandCrew')
					WarMenu.CloseMenu()
					Prompt.ShowAsync()
				end
			end

			WarMenu.Display()
		elseif WarMenu.IsMenuOpened('interaction_confirm') then
			if WarMenu.MenuButton('No', 'interaction') then
			elseif WarMenu.Button('~r~Si') then
				if Player.Rank < Settings.prestige.minRank then
					Gui.DisplayPersonalNotification('Debes tener al menos rango '..Settings.prestige.minRank..'.')
				else
					TriggerServerEvent('lsv:upPrestigeLevel')
					Prompt.ShowAsync()
				end
			end

			WarMenu.Display()
		elseif WarMenu.IsMenuOpened('stats') then
			local timePlayedMin = Player.TimePlayed / (1000 * 60)

			if WarMenu.MenuButton('Asesinatos con Arma', 'stats_weapons') then
			elseif Player.Prestige ~= 0 and WarMenu.MenuButton('Bonus de Prestigio', 'stats_prestige') then
			elseif WarMenu.Button('Tiempo Jugado', string.format('%02d:%02d', math.floor(timePlayedMin / 60), math.floor(timePlayedMin % 60))) then
			elseif WarMenu.Button('Dinero Gastado', '$'..Player.MoneyWasted) then
			elseif WarMenu.Button('Asesinatos', Player.Kills) then
			elseif WarMenu.Button('Muertes', Player.Deaths) then
			elseif WarMenu.Button('Headshots', Player.Headshots..' ('..string.format('%02.2f', (Player.Kills ~= 0 and (Player.Headshots / Player.Kills) or 0) * 100)..'%)') then
			elseif WarMenu.Button('Racha De Muertes Mas Alta', Player.MaxKillstreak) then
			elseif WarMenu.Button('Asesinatos Con Vehiculo', Player.VehicleKills) then
			elseif WarMenu.Button('Distancia De Muerte Más Larga', string.format('%dm', Player.LongestKillDistance)) then
			elseif WarMenu.Button('Misiones Realizadas', Player.MissionsDone) then
			elseif WarMenu.Button('Eventos Ganados', Player.EventsWon) then
			end

			WarMenu.Display()
		elseif WarMenu.IsMenuOpened('drugBusiness') then
			for type, data in pairs(Settings.drugBusiness.types) do
				if Player.HasDrugBusiness(type) then
					WarMenu.Button(data.name, Player.DrugBusiness[type].supplies..'/'..Player.DrugBusiness[type].stock)
				end
			end

			WarMenu.Display()
		elseif WarMenu.IsMenuOpened('stats_weapons') then
			for weaponHash, count in pairs(Player.WeaponStats) do
				WarMenu.Button(WeaponUtility.GetNameByHash(tonumber(weaponHash)), count)
			end

			WarMenu.Display()
		elseif WarMenu.IsMenuOpened('stats_prestige') then
			WarMenu.Button('Nivel De Prestigio', Player.Prestige)
			WarMenu.Button('Bonus De EXP', prestigeBonusStr)

			WarMenu.Display()
		elseif WarMenu.IsMenuOpened('settings') then
			for id, name in pairs(Settings.player) do
				if not (Settings.disableCrosshair and id == 'disableCrosshair') and not (Settings.forceFirstPersonViewWhenAiming and id == 'enableFirstPersonAiming') then
					local value = Player.Settings[id]
					if WarMenu.CheckBox(name, value) then
						TriggerServerEvent('lsv:updatePlayerSetting', id, not value)
						Prompt.ShowAsync()
					end
				end
			end

			WarMenu.Display()
		elseif WarMenu.IsMenuOpened('ammunition') then
			local playerPed = PlayerPedId()

			for ammoType, data in pairs(Settings.ammuNationRefillAmmo) do
				local playerWeaponByAmmoType = table.ifind_if(data.weapons, function(weapon)
					return HasPedGotWeapon(playerPed, GetHashKey(weapon), false)
				end)

				if playerWeaponByAmmoType and WarMenu.MenuButton(ammoType, 'ammunition_ammo') then
					WarMenu.SetSubTitle('ammunition_ammo', ammoType)
					selectedWeapon = playerWeaponByAmmoType
					selectedAmmoType = ammoType
					SetCurrentPedWeapon(playerPed, selectedWeapon, true)
				end
			end

			WarMenu.Display()
		elseif WarMenu.IsMenuOpened('ammunition_ammo') then
			local weaponHash = GetHashKey(selectedWeapon)
			local _, maxAmmo = GetMaxAmmo(PlayerPedId(), weaponHash)
			local weaponAmmoType = GetPedAmmoTypeFromWeapon(PlayerPedId(), weaponHash)
			local playerAmmo = GetPedAmmoByType(PlayerPedId(), weaponAmmoType)

			local ammoClipCount = 0
			if playerAmmo ~= maxAmmo then
				ammoClipCount = math.max(1, math.floor((maxAmmo - playerAmmo) / Settings.ammuNationRefillAmmo[selectedAmmoType].ammo))
			end

			if WarMenu.Button('Municion Completa', fullWeaponAmmoPrice(selectedAmmoType, ammoClipCount)) then
				if playerAmmo == maxAmmo then
					Gui.DisplayPersonalNotification('Ya tienes tu municion al maximo.')
				else
					TriggerServerEvent('lsv:refillAmmo', selectedAmmoType, selectedWeapon, ammoClipCount)
					Prompt.ShowAsync()
				end
			elseif WarMenu.Button(selectedAmmoType..' x'..Settings.ammuNationRefillAmmo[selectedAmmoType].ammo,
				weaponAmmoPrice(selectedAmmoType, playerAmmo, maxAmmo)) then
				if playerAmmo == maxAmmo then
					Gui.DisplayPersonalNotification('Ya tienes tu municion al maximo.')
				else
					TriggerServerEvent('lsv:refillAmmo', selectedAmmoType, selectedWeapon)
					Prompt.ShowAsync()
				end
			end

			WarMenu.Display()
		elseif WarMenu.IsMenuOpened('ammunation') then
			for weaponCategory, _ in pairs(Settings.ammuNationWeapons) do
				if WarMenu.MenuButton(weaponCategory, 'ammunation_weapons') then
					WarMenu.SetSubTitle('ammunation_weapons', weaponCategory)
					selectedWeaponCategory = weaponCategory
				end
			end

			WarMenu.Display()
		elseif WarMenu.IsMenuOpened('ammunation_weapons') then
			local playerPed = PlayerPedId()

			for _, weapon in ipairs(Settings.ammuNationWeapons[selectedWeaponCategory]) do
				local weaponData = Weapon[weapon]
				local weaponHash = GetHashKey(weapon)
				if HasPedGotWeapon(playerPed, weaponHash, false) then
					if WarMenu.MenuButton(weaponData.name, 'ammunation_weaponUpgrades') then
						WarMenu.SetSubTitle('ammunation_weaponUpgrades', 'MEJORAS DE '..weaponData.name)
						SetCurrentPedWeapon(playerPed, weaponHash, true)
						selectedWeapon = weapon
						selectedWeaponHash = weaponHash
					end
				else
					local price = weaponPrice(weapon)
					if price and WarMenu.Button(weaponData.name, price) then
						if weaponData.rank and weaponData.rank > Player.Rank then
							Gui.DisplayPersonalNotification('Tu Rango es demasiado bajo.')
						elseif weaponData.prestige and weaponData.prestige > Player.Prestige then
							Gui.DisplayPersonalNotification('Tu Prestigio es demasiado bajo.')
						else
							TriggerServerEvent('lsv:purchaseWeapon', weapon, selectedWeaponCategory)
							Prompt.ShowAsync()
						end
					end
				end
			end

			WarMenu.Display()
		elseif WarMenu.IsMenuOpened('ammunation_weaponUpgrades') then
			Gui.SetTextParams(7, Color.WHITE, 0.5, true, true)
			Gui.DrawText('Asesinatos con Arma: '..Player.GetWeaponStats(GetSelectedPedWeapon(PlayerPedId())), SafeZone.Right(), SafeZone.Top() + 0.0275, 1.0)

			if WarMenu.MenuButton('~r~Descartar', 'ammunation_discard') then
				WarMenu.SetSubTitle('ammunation_discard', 'Quieres descartar tu '..Weapon[selectedWeapon].name..'?')
			else
				local playerPed = PlayerPedId()

				for componentIndex, component in ipairs(Weapon[selectedWeapon].components) do
					if HasPedGotWeaponComponent(playerPed, selectedWeaponHash, component.hash) then
						if WarMenu.MenuButton(component.name, 'ammunation_removeUpgradeConfirm') then
							selectedWeaponComponent = component.hash
							WarMenu.SetSubTitle('ammunation_removeUpgradeConfirm', 'Remover '..component.name..'?')
						end
					elseif WarMenu.Button(component.name, weaponComponentPrice(componentIndex, selectedWeapon, component.hash)) then
						if component.rank and component.rank > Player.Rank then
							Gui.DisplayPersonalNotification('Tu Rango es demasiado bajo.')
						elseif component.kills and component.kills > Player.GetWeaponStats(selectedWeaponHash) then
							Gui.DisplayPersonalNotification('No tienes suficientes asesinatos con este arma.')
						else
							TriggerServerEvent('lsv:updateWeaponComponent', selectedWeapon, componentIndex)
							Prompt.ShowAsync()
						end
					end
				end

				if GetWeaponTintCount(selectedWeaponHash) == table.length(Settings.weaponTints) then
					for tintIndex, tint in ipairs(Settings.weaponTints) do
						if WarMenu.Button(tint.name or Settings.weaponTintNames[tint.index], weaponTintPrice(tint, selectedWeaponHash)) then
							if GetPedWeaponTintIndex(playerPed, selectedWeaponHash) == tint.index then
								Gui.DisplayPersonalNotification('Ya estas usando este tinte.')
							elseif tint.kills > Player.Kills then
								Gui.DisplayPersonalNotification('No tienes suficientes asesinatos.')
							else
								TriggerServerEvent('lsv:updateWeaponTint', selectedWeaponHash, tintIndex)
								Prompt.ShowAsync()
							end
						end
					end
				end
			end

			WarMenu.Display()
		elseif WarMenu.IsMenuOpened('ammunation_discard') then
			if WarMenu.MenuButton('Si', 'ammunation_weapons') then
				RemoveWeaponFromPed(PlayerPedId(), selectedWeaponHash)
				Player.SaveWeapons()
			elseif WarMenu.MenuButton('No', 'ammunation_weapons') then
			end

			WarMenu.Display()
		elseif WarMenu.IsMenuOpened('ammunation_removeUpgradeConfirm') then
			if WarMenu.MenuButton('Si', 'ammunation_weaponUpgrades') then
				RemoveWeaponComponentFromPed(PlayerPedId(), selectedWeaponHash, selectedWeaponComponent)
				Player.SaveWeapons()
				PlaySoundFrontend(-1, 'WEAPON_ATTACHMENT_UNEQUIP', 'HUD_AMMO_SHOP_SOUNDSET', true)
			elseif WarMenu.MenuButton('No', 'ammunation_weaponUpgrades') then
			end

			WarMenu.Display()
		elseif WarMenu.IsMenuOpened('inviteToCrew') then
			for _, i in ipairs(GetActivePlayers()) do
				if i ~= PlayerId() then
					local player = GetPlayerServerId(i)
					if not Player.CrewMembers[player] and WarMenu.Button(GetPlayerName(i)) then
						Gui.DisplayPersonalNotification('Has invitado a tu Crew a '..Gui.GetPlayerName(player))
						TriggerServerEvent('lsv:inviteToCrew', player)
						WarMenu.CloseMenu()
					end
				end
			end

			WarMenu.Display()
		end

		Citizen.Wait(0)
	end
end)

AddEventHandler('lsv:init', function()
	while true do
		Citizen.Wait(0)

		if Player.IsActive() and not Player.IsInInterior then
			if IsControlJustReleased(0, 244) then
				Gui.OpenMenu('interaction')
			end
		end
	end
end)

AddEventHandler('lsv:settingUpdated', function()
	Prompt.Hide()
end)
