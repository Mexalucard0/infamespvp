Gui = { }
Gui.__index = Gui

local _menuStyle = {
	subTitleColor = Color.WHITE,
}

function Gui.GetPlayerName(serverId, color, lowercase)
	if Player.ServerId() == serverId then
		if lowercase then
			return 'tu'
		else
			return 'tu'
		end
	else
		if not color then
			if Player.CrewMembers[serverId] then
				color = '~b~'
			elseif serverId == World.BeastPlayer or serverId == World.HotPropertyPlayer or serverId == World.KingOfTheCastlePlayer then
				color = '~r~'
			else
				color = '~w~'
			end
		end

		local playerName = PlayerData.IsExists(serverId) and PlayerData.GetName(serverId) or GetPlayerName(GetPlayerFromServerId(serverId))
		return color..'<C>'..playerName..'</C>~w~'
	end
end

function Gui.CreateMenu(id, title)
	WarMenu.CreateMenu(id, title)
	WarMenu.SetMenuStyle(id, _menuStyle)
	WarMenu.SetMenuMaxOptionCountOnScreen(id, Settings.maxMenuOptionCount)
end

function Gui.OpenMenu(id)
	if not WarMenu.IsAnyMenuOpened() and Player.IsActive() then
		WarMenu.OpenMenu(id)
	end
end

function Gui.ToolTip(text, width, flipHorizontal)
	if Player.Settings.disableTips then
		return
	end

	WarMenu.ToolTip(text, width, flipHorizontal)
end

function Gui.GetTextInputResultAsync(titleLabel, maxInputLength, defaultText)
	DisplayOnscreenKeyboard(1, titleLabel or 'FMMC_MPM_NA', '', defaultText or '', '', '', '', maxInputLength)

	while true do
		Citizen.Wait(0)
		DisableAllControlActions(0)

		local status = UpdateOnscreenKeyboard()
		if status == 2 then
			return nil
		elseif status == 1 then
			return GetOnscreenKeyboardResult()
		end
	end
end

function Gui.DisplayHelpText(text)
	BeginTextCommandDisplayHelp('TWOSTRINGS')
	AddTextComponentString(tostring(text))
	EndTextCommandDisplayHelp(0, 0, 1, -1)
end

function Gui.DisplayNotification(text, pic, title, subtitle, icon)
	BeginTextCommandThefeedPost('TWOSTRINGS')
	AddTextComponentString(tostring(text))

	if pic then
		EndTextCommandThefeedPostMessagetext(pic, pic, false, icon or 4, title or '', subtitle or '')
	else
		EndTextCommandThefeedPostTicker(true, true)
	end
end

function Gui.DisplayPersonalNotification(text, pic, title, subtitle, icon, backgroundColor)
	BeginTextCommandThefeedPost('TWOSTRINGS')
	AddTextComponentString(tostring(text))
	ThefeedNextPostBackgroundColor(backgroundColor or 200)

	if pic then
		EndTextCommandThefeedPostMessagetext(pic, pic, false, icon or 4, title or '', subtitle or '')
	else
		EndTextCommandThefeedPostTicker(true, true)
	end
end

function Gui.DrawRect(position, width, height, color)
	DrawRect(position[1], position[2], width, height, color[1], color[2], color[3], color[4] or 255)
end

function Gui.SetTextParams(font, color, scale, shadow, outline, center)
	SetTextFont(font)
	SetTextColour(color[1], color[2], color[3], color[4] or 255)
	SetTextScale(scale, scale)

	if shadow then
		SetTextDropShadow()
	end

	if outline then
		SetTextOutline()
	end

	if center then
		SetTextCentre(true)
	end
end

function Gui.DrawText(text, x, y, width)
	BeginTextCommandDisplayText('TWOSTRINGS')
	AddTextComponentString(tostring(text))

	if width then
		SetTextRightJustify(true)
		SetTextWrap(x - width, x)
	end

	EndTextCommandDisplayText(x, y)
end

function Gui.DrawTextEntry(entry, x, y, ...)
	BeginTextCommandDisplayText(entry)

	local params = { ... }
	for _, param in ipairs(params) do
		local paramType = type(param)
		if paramType == 'string' then
			AddTextComponentString(param)
		elseif paramType == 'number' then
			if math.is_integer(param) then
				AddTextComponentInteger(param)
			else
				AddTextComponentFloat(param, 2)
			end
		end
	end

	EndTextCommandDisplayText(x, y)
end

function Gui.DrawNumeric(number, x, y)
	Gui.DrawTextEntry('NUMBER', x, y, number)
end

function Gui.DisplayObjectiveText(text)
	BeginTextCommandPrint('TWOSTRINGS')
	AddTextComponentString('<C>'..text..'</C>')
	EndTextCommandPrint(1, true)
end

function Gui.DrawMarker(type, position, color, radius, height, bobUpAndDown)
	if not radius then
		radius = Settings.placeMarker.radius
	end

	if IsSphereVisible(position.x, position.y, position.z, radius) then
		DrawMarker(type, position.x, position.y, position.z - 1, 0, 0, 0, 0, 0, 0, radius * 2, radius * 2, height or radius * 2, color[1], color[2], color[3], color[4] or Settings.placeMarker.opacity, bobUpAndDown, true, nil, false)
	end
end

function Gui.DrawEntityMarker(position, color, heightOffset)
	heightOffset = heightOffset or 0.25
	DrawMarker(20, position.x, position.y, position.z + heightOffset, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.85, 0.85, 0.85, color[1], color[2], color[3], 96, true, true)
end

function Gui.DrawPlaceMarker(position, color, radius, height)
	Gui.DrawMarker(1, position, color, radius, height)
end

function Gui.StartEvent(name, message)
	PlaySoundFrontend(-1, 'MP_5_SECOND_TIMER', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)

	Citizen.CreateThread(function()
		local scaleform = Scaleform.NewAsync('MIDSIZED_MESSAGE')
		scaleform:call('SHOW_SHARD_MIDSIZED_MESSAGE', name..' ha iniciado', message)
		scaleform:renderFullscreenTimed(10000)
	end)

	FlashMinimapDisplay()
end

function Gui.StartMission(name, message)
	PlaySoundFrontend(-1, 'EVENT_START_TEXT', 'GTAO_FM_EVENTS_SOUNDSET', true)

	Citizen.CreateThread(function()
		local scaleform = Scaleform.NewAsync('MIDSIZED_MESSAGE')
		scaleform:call('SHOW_SHARD_MIDSIZED_MESSAGE', name, message or '')
		scaleform:renderFullscreenTimed(10000)
	end)

	FlashMinimapDisplay()
end

function Gui.FinishMission(name, success, reason)
	if success then
		PlaySoundFrontend(-1, 'Mission_Pass_Notify', 'DLC_HEISTS_GENERAL_FRONTEND_SOUNDS', true)
	else
		PlaySoundFrontend(-1, 'ScreenFlash', 'MissionFailedSounds', true)
	end

	if not reason then
		return
	end

	if Player.IsActive() then
		local status = success and 'TERMINADO' or 'FALLIDO'
		local scaleform = Scaleform.NewAsync('MIDSIZED_MESSAGE')
		scaleform:call('SHOW_SHARD_MIDSIZED_MESSAGE', string.upper(name)..' '..status, reason)
		scaleform:renderFullscreenTimed(7000)
	else
		local message = name
		if success then
			message = message..' Terminado'
		else
			message = message..' Fallido'
		end

		if string.len(reason) ~= 0 then
			message = message..'\n'..reason
		end

		Gui.DisplayPersonalNotification(message)
	end
end
