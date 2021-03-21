local _loot = nil

local function removeLoot()
	if _loot.pickup then
		RemovePickup(_loot.pickup)
	end

	RemoveBlip(_loot.blip)

	_loot = nil
end

RegisterNetEvent('lsv:spawnLoot')
AddEventHandler('lsv:spawnLoot', function(victim, loot)
	if _loot then
		return
	end

	_loot = loot

	_loot.blip = Map.CreatePlaceBlip(_loot.ammo and Blip.LOOT_AMMO or Blip.LOOT, _loot.position.x, _loot.position.y, _loot.position.z, 'Loot', _loot.ammo and Color.BLIP_RED or Color.BLIP_GREEN)
	SetBlipAsShortRange(_loot.blip, false)
	SetBlipScale(_loot.blip, _loot.ammo and 0.85 or 1.35)
	Gui.DisplayNotification(Gui.GetPlayerName(victim)..' has dropped loot.')

	while true do
		Citizen.Wait(0)

		if Player.DistanceTo(_loot.position, true) >= Settings.loot.maxKillDistance then
			TriggerServerEvent('lsv:lootStatusChanged', false)
			removeLoot()
			return
		end

		if _loot.pickup then
			if HasPickupBeenCollected(_loot.pickup) then
				local playerPed = PlayerPedId()

				if _loot.ammo then
					local weaponHash = GetSelectedPedWeapon(playerPed)
					if weaponHash ~= 0 then
						local ammo = math.min(100, math.max(1, GetWeaponClipSize(weaponHash))) * _loot.ammo
						AddAmmoToPed(playerPed, weaponHash, ammo)
						-- Player.SaveWeapons()
					end
				end

				if _loot.giveArmour then
					SetPedArmour(playerPed, Settings.armour.max)
				end

				TriggerServerEvent('lsv:lootStatusChanged', true)
				removeLoot()
				return
			else
				Gui.DrawEntityMarker(_loot.position, _loot.ammo and Color.RED or Color.GREEN)
			end
		else
			local pickup = CreatePickupRotate(`PICKUP_MONEY_CASE`, _loot.position.x, _loot.position.y, _loot.position.z, 0.0, 0.0, 0.0, 8, false, true)
			if DoesPickupExist(pickup) then
				_loot.pickup = pickup
			end
		end
	end
end)
