local _skinshops = {
	{ x = 72.071105957031, y = -1399.3981933594, z = 29.376142501831 },
	{ x = 428.79281616211, y = -800.67486572266, z = 29.491132736206 },
	{ x = 121.04691314697, y = -225.82836914063, z = 54.55782699585 },
	{ x = -167.84260559082, y = -299.65042114258, z = 39.733276367188 },
	{ x = -704.68463134766, y = -151.84358215332, z = 37.415134429932 },
	{ x = -1447.6271972656, y = -242.27815246582, z = 49.820835113525 },
	{ x = -1187.9968261719, y = -768.77459716797, z = 17.32541847229 },
	{ x = -829.22619628906, y = -1073.8569335938, z = 11.328105926514 },
	{ x = -3175.4289550781, y = 1042.0402832031, z = 20.863210678101 },
	{ x = -1107.6646728516, y = 2708.447265625, z = 19.107870101929 },
	{ x = 617.60980224609, y = 2766.5490722656, z = 42.088138580322 },
	{ x = 1190.5170898438, y = 2712.6530761719, z = 38.222595214844 },
	{ x = 1695.5983886719, y = 4829.2368164063, z = 42.063117980957 },
	{ x = 11.053486824036, y = 6514.693359375, z = 31.877849578857 },
}

local _components = {
	{ id = 0, name = 'Cabeza' },
	{ id = 1, name = 'Mascara' },
	{ id = 2, name = 'Pelo' },
	{ id = 3, name = 'Torso' },
	{ id = 4, name = 'Piernas' },
	{ id = 5, name = 'Bolsas y paracaídas' },
	{ id = 6, name = 'Zapatos' },
	{ id = 7, name = 'Accesorios' },
	{ id = 8, name = 'Camiseta' },
	{ id = 9, name = 'Armadura' },
	{ id = 10, name = 'Calcos' },
	{ id = 11, name = 'Top' },
}

local function getSkinRequirements(skin)
	if skin.model == Player.SkinModel.model then
		return 'Equipado'
	end

	if skin.rank and Player.Rank < skin.rank then
		return 'Rango '..skin.rank
	end

	if skin.prestige and Player.Prestige < skin.prestige then
		return 'Prestigio '..skin.prestige
	end

	return ''
end

RegisterNetEvent('lsv:playerSkinUpdated')
AddEventHandler('lsv:playerSkinUpdated', function(skinModel)
	if skinModel then
		Player.SetModelAsync(skinModel)
		WarMenu.CloseMenu()
	else
		Gui.DisplayPersonalNotification('No puedes usar esta Skin.')
	end

	Prompt.Hide()
end)

AddEventHandler('lsv:init', function()
	table.iforeach(_skinshops, function(skinshop)
		Map.CreatePlaceBlip(Blip.CLOTHING_STORE, skinshop.x, skinshop.y, skinshop.z)
	end)

	Gui.CreateMenu('skinshop', '')
	WarMenu.SetSubTitle('skinshop', 'Seleccion Categoria')
	WarMenu.SetTitleBackgroundColor('skinshop', table.unpack(Color.WHITE))
	WarMenu.SetTitleBackgroundSprite('skinshop', 'shopui_title_lowendfashion', 'shopui_title_lowendfashion')

	WarMenu.CreateSubMenu('skinshop_skins', 'skinshop')

	WarMenu.CreateSubMenu('skinshop_skin_components', 'skinshop_skins', 'Personalización de Skin')
	WarMenu.CreateSubMenu('skinshop_skin_customize_component', 'skinshop_skin_components', '')

	local selectedCategory = nil
	local selectedSkinIndex = nil
	local selectedComponent = nil
	local playerPed = nil

	while true do
		Citizen.Wait(0)

		if WarMenu.IsMenuOpened('skinshop') then
			for category, _ in pairs(Settings.skins) do
				if WarMenu.MenuButton(category, 'skinshop_skins') then
					selectedCategory = category
					WarMenu.SetSubTitle('skinshop_skins', selectedCategory)
				end
			end

			WarMenu.Display()
		elseif WarMenu.IsMenuOpened('skinshop_skins') then
			for skinIndex, skin in ipairs(Settings.skins[selectedCategory]) do
				if WarMenu.MenuButton(skin.name, 'skinshop_skin_components', getSkinRequirements(skin)) then
					if skin.rank and skin.rank > Player.Rank then
						Gui.DisplayPersonalNotification('Tu Rango es demasiado bajo.')
						WarMenu.OpenMenu('skinshop_skins')
					elseif skin.prestige and skin.prestige > Player.Prestige then
						Gui.DisplayPersonalNotification('Tu Prestigio es demasiado bajo.')
						WarMenu.OpenMenu('skinshop_skins')
					elseif skin.patreonTier and skin.patreonTier > Player.PatreonTier then
						Gui.DisplayPersonalNotification('Requiere nivel '..skin.patreonTier.. ' de Patreon')
						WarMenu.OpenMenu('skinshop_skins')
					else
						local skinModel = skin.model == Player.SkinModel.model and Player.SkinModel or skin
						Player.SetModelAsync(skinModel, true)
						selectedSkinIndex = skinIndex
						playerPed = PlayerPedId()
					end
				end
			end

			WarMenu.Display()
		elseif WarMenu.IsMenuOpened('skinshop_skin_components') then
			if WarMenu.Button('~r~Confirmar') then
				TriggerServerEvent('lsv:updatePlayerSkin', Player.GetModel(), selectedSkinIndex, selectedCategory)
				Prompt.ShowAsync()
			else
				for _, component in ipairs(_components) do
					if GetNumberOfPedDrawableVariations(playerPed, component.id) > 1 then
						if WarMenu.MenuButton(component.name, 'skinshop_skin_customize_component') then
							selectedComponent = component.id
							WarMenu.SetSubTitle('skinshop_skin_customize_component', 'Personalizar '..component.name)
						end
					end
				end
			end

			WarMenu.Display()
		elseif WarMenu.IsMenuOpened('skinshop_skin_customize_component') then
			local drawableId = GetPedDrawableVariation(playerPed, selectedComponent)
			local textureId = GetPedTextureVariation(playerPed, selectedComponent)
			local paletteId = 0

			if WarMenu.Button('Modelo', drawableId) then
				drawableId = (drawableId + 1) % GetNumberOfPedDrawableVariations(playerPed, selectedComponent)
				textureId = 0
			elseif WarMenu.Button('Textura', textureId) then
				textureId = (textureId + 1) % GetNumberOfPedTextureVariations(playerPed, selectedComponent, drawableId)
			end

			SetPedPreloadVariationData(playerPed, selectedComponent, drawableId, textureId)
			SetPedComponentVariation(playerPed, selectedComponent, drawableId, textureId, paletteId)

			WarMenu.Display()
		end
	end
end)

AddEventHandler('lsv:init', function()
	local skinshopOpenedMenuIndex = nil
	local skinshopColor = Color.GREEN

	while true do
		Citizen.Wait(0)

		if Player.IsActive() then
			local playerPos = Player.Position()

			for skinshopIndex, skinshop in ipairs(_skinshops) do
				Gui.DrawPlaceMarker(skinshop, skinshopColor)

				if World.GetDistance(playerPos, skinshop, true) <= Settings.placeMarker.radius then
					if not WarMenu.IsAnyMenuOpened() then
						Gui.DisplayHelpText('Presiona ~INPUT_TALK~ para cambiar skin.')

						if IsControlJustReleased(0, 46) then
							skinshopOpenedMenuIndex = skinshopIndex
							Gui.OpenMenu('skinshop')
						end
					end
				elseif skinshopIndex == skinshopOpenedMenuIndex then
					Player.ResetModelAsync()
					skinshopOpenedMenuIndex = nil

					if WarMenu.IsMenuOpened('skinshop') or WarMenu.IsMenuOpened('skinshop_skins') or WarMenu.IsMenuOpened('skinshop_skin_components') or WarMenu.IsMenuOpened('skinshop_skin_customize_component') then
						ReleasePedPreloadVariationData(PlayerPedId())
						WarMenu.CloseMenu()
						Prompt.Hide()
					end
				end
			end
		end
	end
end)
