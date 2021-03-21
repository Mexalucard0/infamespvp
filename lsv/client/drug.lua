local _businessData = {
	['weed'] = {
		blip = Blip.BUSINESS_WEED,
		blipColour = Color.BLIP_DARK_GREEN,
		color = Color.DARK_GREEN,
	},

	['cocaine'] = {
		blip = Blip.BUSINESS_COCAINE,
		blipColour = Color.BLIP_LIGHT_BLUE,
		color = Color.LIGHT_BLUE,
	},

	['meth'] = {
		blip = Blip.BUSINESS_METH,
		blipColour = Color.BLIP_LIGHT_GREY,
		color = Color.LIGHT_GREY,
	},
}

local _businessBlips = { }

local _businessId = nil
local _businessType = nil

RegisterNetEvent('lsv:drugBusinessPurchased')
AddEventHandler('lsv:drugBusinessPurchased', function(id)
	WarMenu.CloseMenu()
	Prompt.Hide()

	if id then
		PlaySoundFrontend(-1, 'PROPERTY_PURCHASE', 'HUD_AWARDS')

		local blip = _businessBlips[id]
		local businessType = Settings.drugBusiness.businesses[id].type
		local businessName = Settings.drugBusiness.types[businessType].name
		Map.SetBlipText(blip, businessName)
		SetBlipCategory(blip, 11)
		Map.SetBlipFlashes(blip)

		table.foreach(_businessBlips, function(blip, id)
			local type = Settings.drugBusiness.businesses[id].type
			if Player.HasDrugBusiness(type) and Player.DrugBusiness[type].id ~= id then
				SetBlipAlpha(blip, 0)
			end
		end)

		local scaleform = Scaleform.NewAsync('MIDSIZED_MESSAGE')
		scaleform:call('SHOW_SHARD_MIDSIZED_MESSAGE', string.upper(businessName)..' COMPRADO', '')
		scaleform:renderFullscreenTimed(7000)
	else
		Gui.DisplayPersonalNotification('No tienes suficiente dinero.')
	end
end)

RegisterNetEvent('lsv:drugBusinessUpgraded')
AddEventHandler('lsv:drugBusinessUpgraded', function(name)
	Prompt.Hide()

	if name then
		Gui.DisplayPersonalNotification(name..' Instalado')
	else
		Gui.DisplayPersonalNotification('No tienes suficiente dinero.')
	end
end)

RegisterNetEvent('lsv:drugBusinessSupplyPurchased')
AddEventHandler('lsv:drugBusinessSupplyPurchased', function(success)
	Prompt.Hide()

	if not success then
		Gui.DisplayPersonalNotification('No tienes suficiente dinero.')
	end
end)

RegisterNetEvent('lsv:drugBusinessSold')
AddEventHandler('lsv:drugBusinessSold', function(type)
	Prompt.Hide()
	PlaySoundFrontend(-1, 'WEAPON_PURCHASE', 'HUD_AMMO_SHOP_SOUNDSET', true)

	table.foreach(_businessBlips, function(blip, id)
		if Settings.drugBusiness.businesses[id].type == type then
			SetBlipAlpha(blip, 255)
			SetBlipCategory(blip, 10)
		end
	end)
end)

RegisterNetEvent('lsv:drugBusinessSupplyRewarded')
AddEventHandler('lsv:drugBusinessSupplyRewarded', function(type)
	Gui.DisplayPersonalNotification('+ 1 Unidad de suministro para '..Settings.drugBusiness.types[type].name)
end)

RegisterNetEvent('lsv:drugExportStarted')
AddEventHandler('lsv:drugExportStarted', function(data)
	WarMenu.CloseMenu()
	Prompt.Hide()

	MissionManager.StartMission('DrugExport', Settings.drugBusiness.export.missionName)
	TriggerEvent('lsv:startDrugExport', data)
end)

-- Production cycle
AddEventHandler('lsv:init', function()
	while true do
		Citizen.Wait(1000)

		for type, business in pairs(Player.DrugBusiness) do
			if business.supplies == 0 or business.stock == Settings.drugBusiness.limits.stock then
				business.timer = nil
			else
				if not business.timer then
					business.timer = Timer.New()
				end

				local productionTime = business.upgrades.equip and Settings.drugBusiness.types[type].time.upgraded or Settings.drugBusiness.types[type].time.default
				if business.timer:elapsed() >= productionTime then
					if business.stock == Settings.drugBusiness.limits.stock - 1 then
						Gui.DisplayPersonalNotification('Tu stock de '..Settings.drugBusiness.types[type].productName..' esta lleno.\nCompleta la misión de exportación de drogas para venderlo..', 'CHAR_DEVIN')
						PlaySoundFrontend(-1, 'CONFIRM_BEEP', 'HUD_MINI_GAME_SOUNDSET', true)
						FlashMinimapDisplay()
					end

					TriggerServerEvent('lsv:drugBusinessProduced', type)
					business.timer:restart()
				end
			end
		end
	end
end)

AddEventHandler('lsv:init', function()
	table.foreach(Settings.drugBusiness.businesses, function(business, id)
		local blip = Map.CreatePlaceBlip(_businessData[business.type].blip, business.location.x, business.location.y, business.location.z, Settings.drugBusiness.types[business.type].name, _businessData[business.type].blipColour)

		local hasDrugBusiness = Player.HasDrugBusiness(business.type)
		if hasDrugBusiness then
			if Player.DrugBusiness[business.type].id ~= id then
				SetBlipAlpha(blip, 0)
				SetBlipCategory(blip, 10)
			else
				SetBlipCategory(blip, 11)
			end
		else
			SetBlipCategory(blip, 10)
		end

		_businessBlips[id] = blip
	end)

	--TODO:
	-- while true do
	-- 	Citizen.Wait(0)
	--
	-- 	local blipAlpha = Player.IsInFreeroam() and 255 or 0
	-- 	for _, blip in pairs(_businessBlips) do
	-- 		if GetBlipAlpha(blip) ~= blipAlpha then
	-- 			SetBlipAlpha(blip, blipAlpha)
	-- 		end
	-- 	end
	-- end
end)

AddEventHandler('lsv:init', function()
	Gui.CreateMenu('drug_business_purchase', 'Negocio de Drogas')

	while true do
		Citizen.Wait(0)

		if WarMenu.IsMenuOpened('drug_business_purchase') then
			local business = Settings.drugBusiness.businesses[_businessId]

			WarMenu.Button('Comprar', '$'..business.price)

			if WarMenu.IsItemHovered() then
				Gui.ToolTip('Gastar suministros para producir '..Settings.drugBusiness.types[business.type].productName..' para exportar.')

				if WarMenu.IsItemSelected() then
					TriggerServerEvent('lsv:purchaseDrugBusiness', _businessId)
					Prompt.ShowAsync()
				end
			end

			WarMenu.Display()
		end
	end
end)

AddEventHandler('lsv:init', function()
	Gui.CreateMenu('drug_business', 'Negocio de Drogas')
	WarMenu.SetTitleBackgroundColor('drug_business', table.unpack(Color.GREEN))

	WarMenu.CreateSubMenu('drug_business_upgrades', 'drug_business')
	WarMenu.SetMenuButtonPressedSound('drug_business_upgrades', 'WEAPON_PURCHASE', 'HUD_AMMO_SHOP_SOUNDSET')

	WarMenu.CreateSubMenu('drug_business_sell', 'drug_business', 'estas seguro?')

	while true do
		Citizen.Wait(0)

		if WarMenu.IsMenuOpened('drug_business') then
			local profitPerUnit = Player.DrugBusiness[_businessType].upgrades.staff and Settings.drugBusiness.types[_businessType].price.upgraded or Settings.drugBusiness.types[_businessType].price.default
			local stockCount = Player.DrugBusiness[_businessType].stock

			WarMenu.Button('Exportar '..Settings.drugBusiness.types[_businessType].productName, '$'..(profitPerUnit * stockCount))
			if WarMenu.IsItemHovered() then
				Gui.ToolTip('Entrega el producto al comprador.')

				if WarMenu.IsItemSelected() then
					if stockCount == 0 then
						Gui.DisplayPersonalNotification('Nada para exportar.')
					else
						TriggerServerEvent('lsv:startDrugExport', _businessType)
						Prompt.ShowAsync()
					end
				end
			end

			if WarMenu.Button('Compra 1 unidad de suministro', '$'..Settings.drugBusiness.types[_businessType].price.supply) then
				if Player.DrugBusiness[_businessType].supplies == Settings.drugBusiness.limits.supplies then
					Gui.DisplayPersonalNotification('Los suministros están llenos.')
				else
					TriggerServerEvent('lsv:purchaseDrugBusinessSupply', _businessType)
					Prompt.ShowAsync()
				end
			end

			if WarMenu.MenuButton('Comprar Mejoras', 'drug_business_upgrades') then
				local businessColor = _businessData[_businessType].color
				WarMenu.SetTitleBackgroundColor('drug_business_upgrades', table.unpack(businessColor))
				WarMenu.SetSubTitle('drug_business_upgrades', 'MEJORAS DE '..Settings.drugBusiness.types[_businessType].name..'')
			end

			WarMenu.Button('Cantidad de suministros', Player.DrugBusiness[_businessType].supplies..' de '..Settings.drugBusiness.limits.supplies)
			if WarMenu.IsItemHovered() then
				WarMenu.ToolTip('Necesitas suministros para fabricar un producto. \nCómpralos o completa actividades en el juego.')
			end

			WarMenu.Button('Cantidad de Stock', Player.DrugBusiness[_businessType].stock..' de '..Settings.drugBusiness.limits.stock)
			if WarMenu.IsItemHovered() then
				local productionTime = Player.DrugBusiness[_businessType].upgrades.equip and Settings.drugBusiness.types[_businessType].time.upgraded or Settings.drugBusiness.types[_businessType].time.default
				WarMenu.ToolTip('La tasa de producción es 1 de '..Settings.drugBusiness.types[_businessType].productName..' en '..math.floor(productionTime / 1000)..' segundos.')
			end

			if WarMenu.MenuButton('~r~Vender Negocio', 'drug_business_sell', '$'..math.floor(Settings.drugBusiness.businesses[_businessId].price * Settings.drugBusiness.sellMultiplier)) then
				local businessColor = _businessData[_businessType].color
				WarMenu.SetTitleBackgroundColor('drug_business_sell', table.unpack(businessColor))
			end

			WarMenu.Display()
		elseif WarMenu.IsMenuOpened('drug_business_sell') then
			WarMenu.MenuButton('No', 'drug_business')

			if WarMenu.Button('Si') then
				TriggerServerEvent('lsv:sellDrugBusiness', _businessId)
				WarMenu.CloseMenu()
				Prompt.ShowAsync()
			end

			WarMenu.Display()
		elseif WarMenu.IsMenuOpened('drug_business_upgrades') then
			for id, data in pairs(Settings.drugBusiness.upgrades) do
				local isOwned = Player.DrugBusiness[_businessType].upgrades[id] ~= nil
				WarMenu.Button(data.name, isOwned and 'Comprado' or '$'..data.prices[_businessType])
				if WarMenu.IsItemHovered() then
					Gui.ToolTip(data.toolTip)

					if WarMenu.IsItemSelected() then
						if not isOwned then
							TriggerServerEvent('lsv:upgradeDrugBusiness', _businessType, id)
							Prompt.ShowAsync()
						end
					end
				end
			end

			WarMenu.Display()
		end
	end
end)

AddEventHandler('lsv:init', function()
	while true do
		Citizen.Wait(0)

		local isPlayerInFreeroam = Player.IsInFreeroam()

		for id, business in pairs(Settings.drugBusiness.businesses) do
			local isOwnedBusiness = Player.HasDrugBusiness(business.type)

			if (not isOwnedBusiness or Player.DrugBusiness[business.type].id == id) and isPlayerInFreeroam then
				Gui.DrawPlaceMarker(business.location, _businessData[business.type].color)

				if Player.DistanceTo(business.location, true) <= Settings.placeMarker.radius then
					if not WarMenu.IsAnyMenuOpened() then
						Gui.DisplayHelpText('Presiona ~INPUT_TALK~ para abrir menu del '..Settings.drugBusiness.types[business.type].name..'.')

						if IsControlJustReleased(0, 46) then
							_businessId = id
							_businessType = business.type

							local businessColor = _businessData[_businessType].color
							local businessName = Settings.drugBusiness.types[_businessType].name

							if isOwnedBusiness then
								WarMenu.SetSubTitle('drug_business', businessName)
								WarMenu.SetTitleBackgroundColor('drug_business', table.unpack(businessColor))
								Gui.OpenMenu('drug_business')
							else
								WarMenu.SetSubTitle('drug_business_purchase', businessName)
								WarMenu.SetTitleBackgroundColor('drug_business_purchase', table.unpack(businessColor))
								Gui.OpenMenu('drug_business_purchase')
							end
						end
					end
				elseif (WarMenu.IsMenuOpened('drug_business_purchase') or WarMenu.IsMenuOpened('drug_business') or WarMenu.IsMenuOpened('drug_business_upgrades')) and _businessId == id then
					WarMenu.CloseMenu()
					Prompt.Hide()
				end
			end
		end
	end
end)
