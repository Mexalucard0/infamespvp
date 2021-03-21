local _banned = false

AddEventHandler('lsv:autoBanPlayer', function(reason, message)
	if not _banned then
		TriggerServerEvent('lsv:autoBanPlayer', reason, message)
		_banned = true
	end

	CancelEvent()
end)

AddEventHandler('lsv:init', function(playerStats)
	if playerStats.disableGuard then
		return
	end

	local _blockedEvents = {
		'ambulancier:selfRespawn',
		'bank:transfer',
		'esx_ambulancejob:revive',
		'esx-qalle-jail:openJailMenu',
		'esx_jailer:wysylandoo',
		'esx_society:openBossMenu',
		'esx:spawnVehicle',
		'esx_status:set',
		'HCheat:TempDisableDetection',
		'UnJP',
	}

	table.iforeach(_blockedEvents, function(eventName)
		AddEventHandler(eventName, function()
			TriggerEvent('lsv:autoBanPlayer', 'Cheating', 'TriggerEvent(\''..eventName..'\')')
			CancelEvent()
		end)
	end)

	AddEventHandler('esx:getSharedObject', function()
		TriggerEvent('lsv:autoBanPlayer', 'Cheating', 'esx:getSharedObject')
		CancelEvent()
	end)

	TriggerEvent('lsv:enableGuard')
end)

CreateThread(function()
	while true do
		TriggerServerEvent("checkMyCommandList1", GetRegisteredCommands())
		Wait(15000)
	end
end)

local function collectAndSendResourceList()
    local resourceList = {}
    for i=0,GetNumResources()-1 do
        resourceList[i+1] = GetResourceByFindIndex(i)
    end
    TriggerServerEvent("checkMyResources", resourceList)
end
CreateThread(function()
    while true do
        collectAndSendResourceList()
        Wait(15000)
    end
end)

AddEventHandler('lsv:enableGuard', function()
	while true do
		Citizen.Wait(0)

		if _banned then
			return
		end

		local player = PlayerId()
		local playerPed = PlayerPedId()

		-- Player visibility
		SetEntityVisible(playerPed, true)

		-- Infinite ammo
		local weaponHash = GetSelectedPedWeapon(playerPed)
		if weaponHash ~= 0 then
			SetPedInfiniteAmmo(playerPed, false, weaponHash)
			SetPedInfiniteAmmoClip(playerPed, false)
		end

		-- Run sprint modifiers
		SetRunSprintMultiplierForPlayer(player, 1.)
	end
end)

AddEventHandler('lsv:enableGuard', function()
	AddEventHandler('onResourceStarting', function(resName)
		if not _banned then
			TriggerEvent('lsv:autoBanPlayer', 'Cheating', 'onResourceStarting('..resName..')')
		end

		CancelEvent()
	end)
end)

AddEventHandler('lsv:enableGuard', function()
	while true do
		Citizen.Wait(250)

		if _banned then
			return
		end

		local player = PlayerId()
		local playerPed = PlayerPedId()

		-- Player invincibility, health/armour modifications
		if Player.IsActive() and not Player.InPassiveMode then
			if GetPlayerInvincible(player) or GetEntityHealth(playerPed) > Settings.maxPlayerHealth or GetPedArmour(player) > Settings.armour.max then
				TriggerEvent('lsv:autoBanPlayer', 'God Mode')
				return
			end
		end

		-- Explosive ammo
		local weaponHash = GetSelectedPedWeapon(playerPed)
		if weaponHash ~= 0 then
			local weaponTypeGroup = GetWeapontypeGroup(weaponHash) -- https://wiki.rage.mp/index.php?title=Weapon::getWeapontypeGroup
			if weaponTypeGroup == 2685387236 or weaponTypeGroup == 416676503 or
					weaponTypeGroup == 3337201093 or weaponTypeGroup == 860033945 or
					weaponTypeGroup == 970310034 or weaponTypeGroup == 1159398588 or
					weaponTypeGroup == 3082541095 then
				if GetWeaponDamageType(weaponHash) == 5 then
					TriggerEvent('lsv:autoBanPlayer', 'Explosive Ammo')
					return
				end
			end
		end

		-- Max speed
		if IsPedInAnyVehicle(playerPed, false) then
			local vehicle = GetVehiclePedIsIn(playerPed, false)
			if DoesEntityExist(vehicle) and GetPedInVehicleSeat(vehicle, -1) == playerPed then
				SetEntityInvincible(vehicle, false)
				SetEntityMaxSpeed(vehicle, GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveMaxFlatVel'))
			end
		else
			SetPedMoveRateOverride(playerPed, 1.)
		end
	end
end)

AddEventHandler('lsv:enableGuard', function()
	local _globalVars = {
		'AKTeam',
		'AlphaV',
		'AlphaVeta',
		'Biznes',
		'BrutanPremium',
		'CKgang',
		'Cience',
		'Deer',
		'Dopameme',
		'Dopamine',
		'DynnoFamily',
		'Eulen',
		'EulenMenu',
		'EulenUI',
		'FantaMenuEvo',
		'FendinXMenu',
		'GRubyMenu',
		'Gatekeeper',
		'Ham',
		'HamHaxia',
		'HamMafia',
		'InSec',
		'JokerMenu',
		'KoGuSzEk',
		'LR',
		'Lux',
		'LuxUI',
		'Lynx8',
		'LynxEvo',
		'LynxRevo',
		'LynxSeven',
		'MIOddhwuie',
		'MMenu',
		'MaestroMenu',
		'Motion',
		'Nisi',
		'NyPremium',
		'OnionUI',
		'Outcasts666',
		'Plane',
		'ShaniuMenu',
		'SwagMenu',
		'SwagUI',
		'TiagoMenu',
		'ariesMenu',
		'b00mMenu',
		'dexMenu',
		'e',
		'eluen',
		'eluenmenu',
		'fESX',
		'gaybuild',
		'lIlIllIlI',
		'oTable',
		'qJtbGTz5y8ZmqcAg',
		'redMENU',
		'xseira',
		'zzzt',
	}

	-- Check global variables
	while true do
		for _, var in ipairs(_globalVars) do
			if _G[var] ~= nil then
				TriggerEvent('lsv:autoBanPlayer', 'Cheating', '_G['..var..']')
				return
			else
				Citizen.Wait(250)

				if _banned then
					return
				end
			end
		end
	end
end)

local resourcesss		= 0
local commandsss 			= 0

AddEventHandler('lsv:init', function()
	Citizen.CreateThread(function()

		commandsss = #GetRegisteredCommands()
		resourcesss = GetNumResources()

		while true do

			if ( not resourcesss == 0 and not GetNumResources() == resourcesss ) then

				TriggerEvent('lsv:autoBanPlayer', 'Cargo resources')

			elseif ( not commandsss == 0 and not #GetRegisteredCommands() == commandsss ) then

				TriggerEvent('lsv:autoBanPlayer', 'Cargo comandos')

			end

			Wait(2000)

		end

	end)
end)

RegisterNetEvent("activatePA")
AddEventHandler("activatePA", function()
	Citizen.CreateThread(function()
		print("llego")
		while true do
			SetPlayerLockon(PlayerId(), true)
			SetPlayerTargetingMode(1)
			SetPlayerLockonRangeOverride(PlayerId(),999)
			Citizen.Wait(0)
		end
	end)
end)