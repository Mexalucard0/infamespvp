MissionManager = { }
MissionManager.__index = MissionManager

MissionManager.Mission = nil
MissionManager.MissionHost = nil

local _missionPlaces = { }

local _missionPlaceIndex = nil

local _players = { }

local _crewMissions = { 'MostWanted', 'AssetRecovery' } --TODO: Remove me

local function startSelectedMission(isInCrewMode)
	local mission = _missionPlaces[_missionPlaceIndex]
	mission.finished = true
	SetBlipColour(mission.blip, Color.BLIP_GREY)
	MissionManager.StartMission(mission.id, nil, isInCrewMode)
end

local function finishMission(success)
	if not success and _missionPlaces[MissionManager.Mission] then
		_missionPlaces[MissionManager.Mission].finished = false
		SetBlipColour(_missionPlaces[MissionManager.Mission].blip, Color.BLIP_BLUE)
	end

	MissionManager.Mission = nil
	MissionManager.MissionHost = nil
end

function MissionManager.StartMission(id, name, isInCrewMode)
	if MissionManager.Mission then
		return
	end

	MissionManager.Mission = id
	MissionManager.MissionHost = Player.ServerId()

	SetPedArmour(PlayerPedId(), Settings.armour.max)
	TriggerServerEvent('lsv:startMission', id, isInCrewMode or false, name)
end

function MissionManager.JoinMission(id, missionHost)
	if MissionManager.Mission then
		return
	end

	MissionManager.Mission = id
	MissionManager.MissionHost = missionHost

	SetPedArmour(PlayerPedId(), Settings.armour.max)
end

function MissionManager.AbortMission()
	if not MissionManager.Mission or MissionManager.MissionHost ~= Player.ServerId() then
		return
	end

	TriggerEvent('lsv:finish'..MissionManager.Mission)
end

function MissionManager.FinishMission(success)
	if not MissionManager.Mission then
		return
	end

	TriggerServerEvent('lsv:finishMission', success)
	finishMission(success)
end

function MissionManager.IsPlayerOnMission(player)
	return _players[player]
end

RegisterNetEvent('lsv:missionStarted')
AddEventHandler('lsv:missionStarted', function(player, id)
	_players[player] = id
end)

RegisterNetEvent('lsv:missionFinished')
AddEventHandler('lsv:missionFinished', function(player)
	_players[player] = nil
end)

RegisterNetEvent('lsv:initMissions')
AddEventHandler('lsv:initMissions', function(missions, players)
	_missionPlaces = Settings.mission.places

	table.iforeach(_missionPlaces, function(mission, i)
		mission.id = missions[i].id
		mission.blip = Map.CreatePlaceBlip(Blip.MISSION, mission.x, mission.y, mission.z, Settings.mission.ids[mission.id], Color.BLIP_BLUE)
		mission.finished = false
	end)

	if players then
		table.foreach(players, function(_, player)
			_players[player] = true
		end)
	end
end)

RegisterNetEvent('lsv:resetMissions')
AddEventHandler('lsv:resetMissions', function()
	table.iforeach(_missionPlaces, function(mission)
		if mission.finished then
			mission.finished = false
			SetBlipColour(mission.blip, Color.BLIP_BLUE)
		end
	end)
end)

AddEventHandler('lsv:init', function()
	local closestMissionBlip = nil
	local missionColor = Color.BLUE

	while true do
		Citizen.Wait(0)

		local isPlayerInFreeroam = Player.IsInFreeroam()
		local playerPosition = Player.Position()
		local closestBlip = nil
		local closestBlipDistance = nil

		for missionIndex, mission in ipairs(_missionPlaces) do
			SetBlipAlpha(mission.blip, isPlayerInFreeroam and 255 or 0)

			if isPlayerInFreeroam and not mission.finished then
				local missionDistance = World.GetDistance(mission, playerPosition, true)

				if not closestBlipDistance or missionDistance < closestBlipDistance then
					closestBlipDistance = missionDistance
					closestBlip = mission.blip
				end

				Gui.DrawPlaceMarker(mission, missionColor)

				if missionDistance <= Settings.placeMarker.radius then
					if not WarMenu.IsAnyMenuOpened() then
						local missionName = Settings.mission.ids[mission.id]

						Gui.DisplayHelpText('Presiona ~INPUT_TALK~ para iniciar '..missionName..'.')

						if IsControlJustReleased(0, 46) then
							_missionPlaceIndex = missionIndex
							WarMenu.SetSubTitle('mission', missionName)
							Gui.OpenMenu('mission')
						end
					end
				elseif WarMenu.IsMenuOpened('mission') and _missionPlaceIndex == missionIndex then
					WarMenu.CloseMenu()
				end
			end
		end

		if closestBlip then
			if closestMissionBlip ~= closestBlip then
				if closestMissionBlip then
					SetBlipAsShortRange(closestMissionBlip, true)
				end

				SetBlipAsShortRange(closestBlip, false)
				closestMissionBlip = closestBlip
			end
		end
	end
end)

AddEventHandler('lsv:init', function()
	Gui.CreateMenu('mission', 'Mision')
	WarMenu.SetTitleBackgroundColor('mission', table.unpack(Color.BLUE))

	while true do
		Citizen.Wait(0)

		if WarMenu.IsMenuOpened('mission') then
			if WarMenu.Button('Solo') then
				startSelectedMission()
				WarMenu.CloseMenu()
			elseif WarMenu.Button('Crew') then
				local mission = _missionPlaces[_missionPlaceIndex]

				if not table.ifind(_crewMissions, mission.id) then
					Gui.DisplayPersonalNotification('Solo el modo Solo está disponible para esta misión en este momento.') --TODO: Remove me
				elseif not Player.IsInCrew() then
					Gui.DisplayPersonalNotification('No estas en una Crew.')
				elseif not Player.IsACrewLeader() then
					Gui.DisplayPersonalNotification('No eres el lider de la Crew.')
				elseif Player.GetCrewMembersCount() < Settings.mission.minCrewSize then
					Gui.DisplayPersonalNotification('El tamaño de tu Crew debe ser igual a '..Settings.mission.minCrewSize..' o mayor.')
				elseif table.find_if(Player.CrewMembers, function(_, member) return MissionManager.IsPlayerOnMission(member) end) then
					Gui.DisplayPersonalNotification('Un miembro de tu Crew se encuentra en una mision.')
				else --TODO: Check for distance?
					startSelectedMission(true)
					WarMenu.CloseMenu()
				end
			end

			WarMenu.Display()
		end
	end
end)

AddEventHandler('lsv:playerDisconnected', function(_, player)
	_players[player] = nil
end)
