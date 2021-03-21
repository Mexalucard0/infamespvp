local _ammunations = {
	{ x = 251.37934875488, y = -48.90043258667, z = 69.941062927246 },
	{ x = 843.44445800781, y = -1032.1590576172, z = 28.194854736328 },
	{ x = 810.82800292969, y = -2156.3671875, z = 29.619010925293 },
	{ x = 20.719049453735, y = -1108.0506591797, z = 29.797027587891 },
	{ x = -662.86431884766, y = -936.32116699219, z = 21.829231262207 },
	{ x = -1306.2987060547, y = -393.93954467773, z = 36.695774078369 },
	{ x = -3171.1555175781, y = 1086.576171875, z = 20.838750839233 },
	{ x = -1117.4243164063, y = 2697.328125, z = 18.554145812988 },
	{ x = -329.94900512695, y = 6082.3178710938, z = 31.454774856567 },
	{ x = 2568.3815917969, y = 295.02661132813, z = 108.73487854004 },
	{ x = 1693.8348388672, y = 3759.2829589844, z = 34.705318450928 },
}

local _selectedWeapon = nil
local _selectedAmmoType = nil

local function specialWeaponAmmoPrice(weapon, ammo, maxAmmo)
	if ammo == maxAmmo then
		return 'Completo'
	end

	local price = Settings.ammuNationSpecialAmmo[weapon].price
	if Player.PatreonTier ~= 0 then
		price = math.floor(price * Settings.patreon.ammo[Player.PatreonTier])
	end

	return '$'..price
end

local function fullSpecialWeaponAmmoPrice(weapon, ammoClipCount)
	if ammoClipCount == 0 then
		return 'Completo'
	end

	return '$'..tostring(ammoClipCount * Settings.ammuNationSpecialAmmo[weapon].price)
end

RegisterNetEvent('lsv:specialAmmoRefilled')
AddEventHandler('lsv:specialAmmoRefilled', function(weapon, amount, fullAmmo)
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

AddEventHandler('lsv:init', function()
	table.iforeach(_ammunations, function(ammunation)
		Map.CreatePlaceBlip(Blip.AMMU_NATION, ammunation.x, ammunation.y, ammunation.z)
	end)

	Gui.CreateMenu('ammunation_special', '')
	WarMenu.SetSubTitle('ammunation_special', 'Municion Para Armas Especiales')
	WarMenu.SetTitleBackgroundColor('ammunation_special', table.unpack(Color.WHITE))
	WarMenu.SetTitleBackgroundSprite('ammunation_special', 'shopui_title_gunclub', 'shopui_title_gunclub')

	WarMenu.CreateSubMenu('ammunation_special_ammo', 'ammunation_special', '')

	while true do
		Citizen.Wait(0)

		if WarMenu.IsMenuOpened('ammunation_special') then
			for weapon, data in pairs(Settings.ammuNationSpecialAmmo) do
				local weaponHash = GetHashKey(weapon)
				if HasPedGotWeapon(PlayerPedId(), weaponHash, false) then
					if WarMenu.MenuButton(data.type..' de '..Weapon[weapon].name, 'ammunation_special_ammo') then
						_selectedWeapon = weapon
						_selectedAmmoType = data.type
						WarMenu.SetSubTitle('ammunation_special_ammo', Weapon[weapon].name..' '..data.type)
					end
				end
			end

			WarMenu.Display()
		elseif WarMenu.IsMenuOpened('ammunation_special_ammo') then
			local weaponHash = GetHashKey(_selectedWeapon)
			local _, maxAmmo = GetMaxAmmo(PlayerPedId(), weaponHash)
			local weaponAmmoType = GetPedAmmoTypeFromWeapon(PlayerPedId(), weaponHash)
			local playerAmmo = GetPedAmmoByType(PlayerPedId(), weaponAmmoType)

			local ammoClipCount = 0
			if playerAmmo ~= maxAmmo then
				ammoClipCount = math.max(1, math.floor((maxAmmo - playerAmmo) / Settings.ammuNationSpecialAmmo[_selectedWeapon].ammo))
			end

			if WarMenu.Button('Llenar municion', fullSpecialWeaponAmmoPrice(_selectedWeapon, ammoClipCount)) then
				if playerAmmo == maxAmmo then
					Gui.DisplayPersonalNotification('Ya tienes tu municion al maximo.')
				else
					TriggerServerEvent('lsv:refillSpecialAmmo', _selectedWeapon, ammoClipCount)
					Prompt.ShowAsync()
				end
			elseif WarMenu.Button(_selectedAmmoType..' x'..Settings.ammuNationSpecialAmmo[_selectedWeapon].ammo, specialWeaponAmmoPrice(_selectedWeapon, playerAmmo, maxAmmo)) then
				if playerAmmo == maxAmmo then
					Gui.DisplayPersonalNotification('Ya tienes tu municion al maximo.')
				else
					TriggerServerEvent('lsv:refillSpecialAmmo', _selectedWeapon)
					Prompt.ShowAsync()
				end
			end

			WarMenu.Display()
		end
	end
end)

AddEventHandler('lsv:init', function()
	local ammunationOpenedMenuIndex = nil
	local ammunationColor = Color.RED

	while true do
		Citizen.Wait(0)

		if Player.IsActive() then
			local playerPos = Player.Position()

			for ammunationIndex, ammunation in ipairs(_ammunations) do
				Gui.DrawPlaceMarker(ammunation, ammunationColor)

				if World.GetDistance(playerPos, ammunation, true) <= Settings.placeMarker.radius then
					if not WarMenu.IsAnyMenuOpened() then
						Gui.DisplayHelpText('Presiona ~INPUT_TALK~ para buscar municion de armas especiales.')

						if IsControlJustReleased(0, 46) then
							ammunationOpenedMenuIndex = ammunationIndex
							openedFromInteractionMenu = false
							Gui.OpenMenu('ammunation_special')
						end
					end
				elseif ammunationIndex == ammunationOpenedMenuIndex and (WarMenu.IsMenuOpened('ammunation_special') or WarMenu.IsMenuOpened('ammunation_special_ammo')) then
					WarMenu.CloseMenu()
					Player.SaveWeapons()
					Prompt.Hide()
				end
			end
		end
	end
end)
