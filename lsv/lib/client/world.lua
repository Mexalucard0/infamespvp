World = { }
World.__index = World

World.HotPropertyPlayer = nil
World.BeastPlayer = nil
World.KingOfTheCastlePlayer = nil

local _wantedEnabled = true

local _pedHandlers = { }
local _vehicleHandlers = { }
local _objectHandlers = { }

local function enumerateEntitiesAsync(initFunc, moveFunc, disposeFunc, func, handlers)
	local iter, entity = initFunc()

	if iter == -1 or not entity or entity == 0 then
		disposeFunc(iter)
		return
	end

	local finished = false
	repeat
		func(entity)
		Citizen.Wait(0)
		finished, entity = moveFunc(iter)
	until not finished

	disposeFunc(iter)
end

local function processHandlers(entity, handlers)
	if DoesEntityExist(entity) then
		for _, handlerFunc in ipairs(handlers) do
			handlerFunc(entity)
		end
	end
end

function World.GetDistance(pos1, pos2, useZ)
	return math.sqrt((pos1.x - pos2.x)^2 + (pos1.y - pos2.y)^2 + (useZ and ((pos1.z - pos2.z)^2) or 0))
end

function World.TryGetClosestVehicleNode(coords, maxDistance, nTh)
	local success, position, heading = GetNthClosestVehicleNodeWithHeading(coords.x, coords.y, coords.z, nTh or math.random(2, 5))

	if not success or World.GetDistance(coords, position, true) > maxDistance then
		return nil
	end

	return { position = position, heading = heading }
end

function World.LoadInterior(coords)
	local id = GetInteriorAtCoords(coords.x, coords.y, coords.z)
	if IsValidInterior(id) then
		PinInteriorInMemory(id)
		return id
	end

	return nil
end

function World.UnloadInterior(id)
	if IsValidInterior(id) then
		UnpinInterior(id)
	end
end

function World.EnablePvp(enabled)
	if not Settings.pvp.enabled then
		return
	end

	NetworkSetFriendlyFireOption(enabled)
	SetCanAttackFriendly(PlayerPedId(), enabled, enabled)
end

function World.EnableWanted(enabled)
	local player = PlayerId()

	SetIgnoreLowPriorityShockingEvents(player, not enabled)
	SetPoliceIgnorePlayer(player, not enabled)
	SetDispatchCopsForPlayer(player, enabled)

	if not enabled then
		SetPlayerWantedLevel(player, 0, false)
		SetPlayerWantedLevelNow(player, false)
	end

	SetMaxWantedLevel(enabled and 5 or 0)

	_wantedEnabled = enabled
end

function World.SetWantedLevel(level, maxLevel, permanent, targetPlayer)
	if not _wantedEnabled then
		return
	end

	if not maxLevel then
		maxLevel = 5
	end

	local player = targetPlayer or PlayerId()

	if permanent then
		SetPlayerWantedLevelNoDrop(player, level, false)
	else
		SetPlayerWantedLevel(player, level, false)
	end
	SetPlayerWantedLevelNow(player, false)

	SetMaxWantedLevel(maxLevel)
end

function World.DeleteEntity(entity)
	if not DoesEntityExist(entity) then
		return
	end

	if not IsEntityAMissionEntity(entity) then
		SetEntityAsMissionEntity(entity, false, true)
	end
	DeleteEntity(entity)
end

function World.AddPedHandler(handlerFunc)
	table.insert(_pedHandlers, handlerFunc)
end

function World.AddVehicleHandler(handlerFunc)
	table.insert(_vehicleHandlers, handlerFunc)
end

function World.AddObjectHandler(handlerFunc)
	table.insert(_objectHandlers, handlerFunc)
end

function World.ForEachPedAsync(func)
	enumerateEntitiesAsync(FindFirstPed, FindNextPed, EndFindPed, func)
end

function World.ForEachVehicleAsync(func)
	enumerateEntitiesAsync(FindFirstVehicle, FindNextVehicle, EndFindVehicle, func)
end

function World.ForEachObjectAsync(func)
	enumerateEntitiesAsync(FindFirstObject, FindNextObject, EndFindObject, func)
end

AddEventHandler('lsv:init', function()
	Citizen.CreateThread(function()
		while true do
			Citizen.Wait(0)

			World.ForEachPedAsync(function(ped)
				processHandlers(ped, _pedHandlers)
			end)
		end
	end)

	Citizen.CreateThread(function()
		while true do
			Citizen.Wait(0)

			World.ForEachVehicleAsync(function(vehicle)
				processHandlers(vehicle, _vehicleHandlers)
			end)
		end
	end)

	Citizen.CreateThread(function()
		while true do
			Citizen.Wait(0)

			World.ForEachObjectAsync(function(object)
				processHandlers(object, _objectHandlers)
			end)
		end
	end)
end)
