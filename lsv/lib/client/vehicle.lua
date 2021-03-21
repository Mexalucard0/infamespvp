Vehicle = { }
Vehicle.__index = Vehicle

local function getRandomColor()
	local colors = Settings.vehicleShop.colorGroups[math.random(#Settings.vehicleShop.colorGroups)].colors
	return colors[math.random(#colors)].index
end

function Vehicle.GetModelName(modelHash)
	return GetLabelText(GetDisplayNameFromVehicleModel(modelHash))
end

function Vehicle.GenerateRandomMods(vehicle)
	local vehicleMods = { }

	vehicleMods.mods = { }
	for modType = 0, 49 do
		if modType ~= 16 then
			local modNum = GetNumVehicleMods(vehicle, modType)
			if modNum ~= 0 then
				local modIndex = math.random(0, modNum)
				vehicleMods.mods[tostring(modType)] = modIndex
			end
		end
	end

	vehicleMods.mods['10'] = nil -- Weapons?

	vehicleMods.colors = { }
	vehicleMods.colors.primary = getRandomColor()
	vehicleMods.colors.secondary = getRandomColor()

	-- if math.random(0, 2) ~= 0 then
	-- 	vehicleMods.neons = true
	-- 	vehicleMods.colors.neon = Color.GetRandomRgb()
	-- end

	-- if getRandomToggableMod(vehicleMods, 20) then -- Tyre Smoke
	-- 	vehicleMods.colors.tyreSmoke = Color.GetRandomRgb()
	-- end

	return vehicleMods
end

function Vehicle.ApplyMods(vehicle, vehicleMods)
	SetVehicleModKit(vehicle, 0)

	SetVehicleMod(vehicle, 10, -1) -- Weapons?

	local primaryColor = vehicleMods.colors and vehicleMods.colors.primary or nil
	local secondaryColor = vehicleMods.colors and vehicleMods.colors.secondary or nil

	SetVehicleColours(vehicle, primaryColor or 0, secondaryColor or 0)

	if vehicleMods.wheels then
		SetVehicleWheelType(vehicle, vehicleMods.wheels.type)
	end

	if vehicleMods.mods then
		for modType, modIndex in pairs(vehicleMods.mods) do
			SetVehicleMod(vehicle, tonumber(modType), modIndex)
		end

		ToggleVehicleMod(vehicle, 22, vehicleMods.mods['22'] == 0) -- Xenon Headlights
		ToggleVehicleMod(vehicle, 18, vehicleMods.mods['18'] == 1) -- Turbo

		local windowTintModType = '46'
		if vehicleMods.mods[windowTintModType] then
			SetVehicleWindowTint(vehicle, Settings.vehicleShop.windowTints[vehicleMods.mods[windowTintModType]])
		end
	end
	--
	-- if vehicleMods.plate then
	-- 	SetVehicleNumberPlateText(vehicle, vehicleMods.plate)
	-- end
	--
	-- if vehicleMods.neons then
	-- 	for neonIndex = 0, 3 do
	-- 		SetVehicleNeonLightEnabled(vehicle, neonIndex, true)
	-- 	end
	-- 	SetVehicleNeonLightsColour(vehicle, unpackRgb(vehicleMods.colors.neon))
	-- end
	--
	-- if tryApplyToggableMod(vehicle, vehicleMods, 20) then -- Tyre Smoke
	-- 	SetVehicleTyreSmokeColor(vehicle, unpackRgb(vehicleMods.colors.tyreSmoke))
	-- end
	--
end

function Vehicle.IsDestroyed(vehicle)
	return GetVehicleEngineHealth(vehicle) == -4000.
end
