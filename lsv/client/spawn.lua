-- TODO Make me module?
local _isSpawnInProcess = false

local _deathTimer = nil
local _deathDetails = nil

function spawnPlayer(spawnPoint)
	if _isSpawnInProcess then
		return
	end

	_isSpawnInProcess = true

	if spawnPoint then
		spawnPoint.z = spawnPoint.z - 1.0
	else
		local playerPos = Player.Position()
		local startingPosition = nil

		if Player.CrewLeader and Player.CrewLeader ~= Player.ServerId() then
			local leaderCoords = GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(Player.CrewLeader)))
			if World.GetDistance(playerPos, leaderCoords, true) <= Settings.crew.spawnDistance then
				startingPosition = leaderCoords
			end
		end

		if not startingPosition then
			startingPosition = playerPos
		end

		local radius = Settings.spawn.radius.min
		local z = 1500.
		local tryCount = 0
		local startSpawnTimer = Timer.New()

		while true do
			Citizen.Wait(0)

			local diff = { r = radius * math.sqrt(math.random(0., 1.)), theta = math.random(0., 1.) * 2 * math.pi }
			local xDiff = diff.r * math.cos(diff.theta)
			if xDiff >= 0 then
				xDiff = math.max(radius, xDiff)
			else
				xDiff = math.min(-radius, xDiff)
			end

			local yDiff = diff.r * math.sin(diff.theta)
			if yDiff >= 0 then
				yDiff = math.max(radius, yDiff)
			else
				yDiff = math.min(-radius, yDiff)
			end

			local x = startingPosition.x + xDiff
			local y = startingPosition.y + yDiff

			local _, groundZ = GetGroundZFor_3dCoord(x, y, z)
			local validCoords, coords = GetSafeCoordForPed(x, y, groundZ + 1., false, 16)

			if validCoords then
				for _, i in ipairs(GetActivePlayers()) do
					if i ~= PlayerId() then
						local ped = GetPlayerPed(i)

						if DoesEntityExist(ped) then
							local pedCoords = GetEntityCoords(ped)
							if World.GetDistance(coords, pedCoords, true) < Settings.spawn.radius.minDistanceToPlayer then
								validCoords = false
								break
							end
						end
					end
				end
			end

			if validCoords then
				spawnPoint = { }
				spawnPoint.x, spawnPoint.y, spawnPoint.z = coords.x, coords.y, coords.z
			else
				if tryCount ~= Settings.spawn.tryCount then
					tryCount = tryCount + 1
				else
					radius = radius + Settings.spawn.radius.increment
					tryCount = 0
				end
			end

			if spawnPoint then
				break
			end

			if startSpawnTimer:elapsed() >= Settings.spawn.timeout then
				spawnPoint = table.irandom(Settings.spawn.points)
				Gui.DisplayPersonalNotification('No se pudo encontrar un lugar adecuado para reaparecer.')
			end
		end
	end

	local ped = PlayerPedId()

	RequestCollisionAtCoord(spawnPoint.x, spawnPoint.y, spawnPoint.z)

	SetEntityCoordsNoOffset(ped, spawnPoint.x, spawnPoint.y, spawnPoint.z, false, false, false, true)
	NetworkResurrectLocalPlayer(spawnPoint.x, spawnPoint.y, spawnPoint.z, math.random(0., 360.), true, true, false)

	local collisionTimer = Timer.New()
	while not HasCollisionLoadedAroundEntity(ped) and collisionTimer:elapsed() <= 5000 do
		Citizen.Wait(0)
	end
	PlaceObjectOnGroundProperly(ped)

	ClearPedTasksImmediately(ped)
	StopEntityFire(ped)
	ClearPedEnvDirt(ped)
	ClearPedBloodDamage(ped)
	ClearPedWetness(ped)
	ClearAllPedProps(ped)

	if Settings.giveArmorAtSpawn then
		SetPedArmour(ped, Settings.armour.max)
	end

	if Settings.giveParachuteAtSpawn then
		GiveWeaponToPed(ped, `GADGET_PARACHUTE`, 1, false, false)
	end

	_isSpawnInProcess = false
end

AddEventHandler('lsv:init', function()
	RequestScriptAudioBank('MP_WASTED')

	local scaleform = Scaleform.NewAsync('MP_BIG_MESSAGE_FREEMODE')

	local instructionalButtonsScaleform = Scaleform.NewAsync('INSTRUCTIONAL_BUTTONS')

	while true do
		Citizen.Wait(0)

		local playerPed = PlayerPedId()

		if IsPedFatallyInjured(playerPed) then
			if not _deathTimer then
				local player = PlayerId()
				local deathSource, weaponHash = NetworkGetEntityKillerOfPlayer(player)

				local killer = nil
				if deathSource == playerPed then
					killer = player
				elseif deathSource ~= -1 and IsEntityAPed(deathSource) and IsPedAPlayer(deathSource) then
					killer = NetworkGetPlayerIndexFromPed(deathSource)
				end

				local playerPos = Player.Position()

				if not killer then
					TriggerServerEvent('lsv:onPlayerDied', false, playerPos)
				elseif killer == player then
					TriggerServerEvent('lsv:onPlayerDied', true, playerPos)
				else
					local killData = { }

					killData.killer = GetPlayerServerId(killer)
					killData.position = playerPos
					killData.killerPosition = GetEntityCoords(deathSource)

					if IsPedInAnyVehicle(deathSource, false) then
						killData.isKillerInVehicle = true
					end

					if IsPedInAnyVehicle(playerPed, false) then
						killData.isVictimInVehicle = true
					end

					killData.killDistance = math.floor(World.GetDistance(playerPos, killData.killerPosition, true))
					_deathDetails = string.format('Distancia: %dm', killData.killDistance)..'\nVida del enemigo: '..GetEntityHealth(deathSource)

					local hasDamagedBone, damagedBone = GetPedLastDamageBone(playerPed)
					if hasDamagedBone and damagedBone == 31086 then
						killData.headshot = true
					end

					if IsWeaponValid(weaponHash) then
						killData.weaponHash = weaponHash
						killData.weaponGroup = GetWeapontypeGroup(weaponHash)

						local weaponName = WeaponUtility.GetNameByHash(weaponHash)
						if weaponName then
							local tint = GetPedWeaponTintIndex(deathSource, weaponHash)
							local tintName = Settings.weaponTintNames[tint]
							if tintName then
								weaponName = weaponName..' ('..tintName..')'
							end
							_deathDetails = 'Asesinado con '..weaponName..'\n'.._deathDetails
						end
					end

					TriggerServerEvent('lsv:onPlayerKilled', killData)
				end

				_deathTimer = GetGameTimer()
			else
				if IsControlJustReleased(0, 24) then
					_deathTimer = math.max(0, _deathTimer - Settings.spawn.respawnFasterPerControlPressed)
					PlaySoundFrontend(-1, _deathTimer > 0 and 'Faster_Click' or 'Faster_Bar_Full', 'RESPAWN_ONLINE_SOUNDSET', true)
				end

				local deathTime = GetTimeDifference(GetGameTimer(), _deathTimer)

				if deathTime <= 1500 then
					if not AnimpostfxIsRunning('DeathFailNeutralIn') then
						AnimpostfxPlay('DeathFailNeutralIn', 0, true)

						instructionalButtonsScaleform:call('CLEAR_ALL')
						instructionalButtonsScaleform:call('SET_DATA_SLOT', 0, '~INPUT_ATTACK~', 'Reaparecer más rápido')
						instructionalButtonsScaleform:call('DRAW_INSTRUCTIONAL_BUTTONS')
					end
				else
					if AnimpostfxIsRunning('DeathFailNeutralIn') then
						AnimpostfxStop('DeathFailNeutralIn')

						ShakeGameplayCam('DEATH_FAIL_IN_EFFECT_SHAKE', 1.0)

						scaleform:call('SHOW_SHARD_WASTED_MP_MESSAGE', '~r~WASTED', _deathDetails)

						PlaySoundFrontend(-1, 'MP_Flash', 'WastedSounds', true)

						AnimpostfxPlay('DeathFailOut', 0, true)
					end

					scaleform:renderFullscreen()
				end

				instructionalButtonsScaleform:renderFullscreen()

				Gui.DrawProgressBar('REAPARICION', deathTime / Settings.spawn.deathTime, 2, Color.RED)

				if deathTime >= Settings.spawn.deathTime then
					Screen.FadeOutAsync(500)
					Player.SetPassiveMode(true, true)
					spawnPlayer()
					Citizen.Wait(Settings.spawnProtectionTime)
					AnimpostfxStop('DeathFailOut')
					StopGameplayCamShaking(true)
					Screen.FadeInAsync(500)
					Player.SetPassiveMode(false)
				end
			end
		elseif _deathTimer then
			_deathTimer = nil
			_deathDetails = nil
		end
	end
end)
