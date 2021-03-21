Scoreboard = { }
Scoreboard.__index = Scoreboard

local _scoreboard = { }
local _needUpdate = true

local _headerTableSpacing = 0.0075

local _tableSpacing = 0.001875
local _tableHeight = 0.02625
local _tablePositionWidth = 0.175
local _tableCashWidth = 0.095
local _tableKdRatioWidth = 0.095
local _tableKillsWidth = 0.095
local _tableTextVerticalMargin = 0.00245
local _playerNameMargin = 0.00225
local _playerStatusWidth = 0.00325
local _voiceIndicatorWidth = Settings.voice.enabled and 0.01 or 0
local _voiceIndicatorMargin = Settings.voice.enabled and _playerNameMargin or 0
local _rankWidth = 0.0190
local _rankHeight = 0.0325

local _tableWidth = _tablePositionWidth + _tableCashWidth + _tableKdRatioWidth + _tableKillsWidth

local _headerScale = 0.2675
local _positionScale = 0.375
local _idScale = 0.2725
local _rankScale = 0.325
local _cashScale = 0.2625
local _kdRatioScale = 0.2625
local _killsScale = 0.2625

-- Colors
local _tableHeaderColor = { 25, 118, 210, 255 }
local _tableHeaderTextColor = { 255, 255, 255, 255 }

local _tablePositionTextColor = { 255, 255, 255, 255 }
local _tableRowColor = { 0, 0, 0 }

local _tableCashTextColor = { 255, 255, 255, 255 }
local _tableKdRatioTextColor = { 255, 255, 255, 255 }
local _tableKillsTextColor = { 255, 255, 255, 255 }

local _activeVoiceIndicatorColor = { 255, 255, 255, 255 }
local _inactiveVoiceIndicatorColor = { 10, 10, 10, 255 }

local _rankColor = { 44, 109, 184, 255 }
local _rankBackgroundColor = { 0, 0, 0, 255 }
local _rankTextColor = { 255, 255, 255, 255 }

local _prestigeColor = { 240, 200, 80, 255 }
local _prestigeTextColor = { 0, 0, 0, 255 }

local _visible = false
local _pageIndex = 1

local function sortScoreboard(l, r)
	if not l then return false end
	if not r then return true end

	if l.patreonTier > r.patreonTier then return true end
	if l.patreonTier < r.patreonTier then return false end

	if l.prestige > r.prestige then return true end
	if l.prestige < r.prestige then return false end

	if l.rank > r.rank then return true end
	if l.rank < r.rank then return false end

	if l.cash > r.cash then return true end
	if l.cash < r.cash then return false end

	if not l.kdRatio then return false end
	if not r.kdRatio then return true end

	if l.kdRatio > r.kdRatio then return true end
	if l.kdRatio < r.kdRatio then return false end

	if l.kills > r.kills then return true end
	if l.kills < r.kills then return false end

	return l.name < r.name
end

local function displayThisFrame()
	if _needUpdate then
		_scoreboard = { }

		for id, data in pairs(PlayerData.GetPlayers()) do
			table.insert(_scoreboard, data)
		end

		table.sort(_scoreboard, sortScoreboard)

		_needUpdate = false
	end

	local scoreboardPosition = { (1.0 - _tableWidth) / 2, SafeZone.Top() }

	local tableHeaderY = scoreboardPosition[2] + _tableHeight / 2
	local tableHeaderTextY = tableHeaderY - _tableHeight / 2 + _tableTextVerticalMargin

	local tableAvatarPositionWidth = _tableHeight / GetAspectRatio()
	local tablePageHeaderTextX = scoreboardPosition[1] + tableAvatarPositionWidth / 2
	local tablePositionHeader = { scoreboardPosition[1] + _tablePositionWidth / 2, tableHeaderY }
	local tableCashHeader = { scoreboardPosition[1] + _tablePositionWidth + _tableCashWidth / 2, tableHeaderY }
	local tableKdRatioHeader = { tableCashHeader[1] + _tableCashWidth / 2 + _tableKdRatioWidth / 2, tableHeaderY }
	local tableKillsHeader = { tableKdRatioHeader[1] + _tableKdRatioWidth / 2 + _tableKillsWidth / 2, tableHeaderY }
	local tablePositionY = tablePositionHeader[2] + _tableHeight + _headerTableSpacing

	-- Draw 'POSITION' header
	Gui.DrawRect(tablePositionHeader, _tablePositionWidth, _tableHeight, _tableHeaderColor)
	Gui.SetTextParams(0, _tableHeaderTextColor, _headerScale)
	Gui.DrawText('PAGINA '.._pageIndex..' DE '..Scoreboard.GetPagesCount(), tablePageHeaderTextX, tableHeaderTextY)

	-- Draw 'CASH' header
	Gui.DrawRect(tableCashHeader, _tableCashWidth, _tableHeight, _tableHeaderColor)
	Gui.SetTextParams(0, _tableHeaderTextColor, _headerScale, false, false, true)
	Gui.DrawText('DINERO', tableCashHeader[1], tableHeaderTextY)

	-- Draw 'KILLSTREAK' header
	Gui.DrawRect(tableKdRatioHeader, _tableKdRatioWidth, _tableHeight, _tableHeaderColor)
	Gui.SetTextParams(0, _tableHeaderTextColor, _headerScale, false, false, true)
	Gui.DrawText('K/D', tableKdRatioHeader[1], tableHeaderTextY)

	-- Draw 'KILLS' header
	Gui.DrawRect(tableKillsHeader, _tableKillsWidth, _tableHeight, _tableHeaderColor)
	Gui.SetTextParams(0, _tableHeaderTextColor, _headerScale, false, false, true)
	Gui.DrawText('ASESINATOS', tableKillsHeader[1], tableHeaderTextY)

	-- Draw table
	local lastPlayerIndex = (_pageIndex - 1) * Settings.maxPlayersOnPage
	for i = lastPlayerIndex + 1, math.min(#_scoreboard, lastPlayerIndex + Settings.maxPlayersOnPage) do
		local player = _scoreboard[i]
		local avatarPosition = { scoreboardPosition[1] + tableAvatarPositionWidth / 2, tablePositionY }
		local playerPosition = { avatarPosition[1] + _tablePositionWidth / 2, tablePositionY }
		local playerStatusPosition = { avatarPosition[1] + tableAvatarPositionWidth / 2 + _playerStatusWidth / 2, tablePositionY }
		local voiceIndicatorPosition = { playerStatusPosition[1] + _playerStatusWidth / 2 + _voiceIndicatorWidth / 2 + _playerNameMargin, tablePositionY }
		local playerNamePosition = { voiceIndicatorPosition[1] + _voiceIndicatorWidth / 2 + _voiceIndicatorMargin, tablePositionY }
		local cashPosition = { tableCashHeader[1], tablePositionY }
		local kdRatioPosition = { tableKdRatioHeader[1], tablePositionY }
		local killsPosition = { tableKillsHeader[1], tablePositionY }
		local rankPosition = { scoreboardPosition[1] + tableAvatarPositionWidth + _tablePositionWidth - _rankWidth - _playerNameMargin * 2, tablePositionY + 0.001 }
		local prestigePosition = { rankPosition[1] - _rankWidth / 2 - _playerNameMargin * 2, rankPosition[2] }
		local tableTextY = tablePositionY - _tableHeight / 2

		local isMe = player.id == Player.ServerId()
		_tableRowColor[4] = isMe and 255 or 160

		-- Draw player id
		Gui.DrawRect(avatarPosition, tableAvatarPositionWidth, _tableHeight, _tableRowColor)

		local idColor = Color.WHITE
		if player.moderator then idColor = Color.PURPLE end
		Gui.SetTextParams(0, idColor, _idScale, false, false, true)
		Gui.DrawNumeric(player.id, avatarPosition[1], tableTextY + _tableTextVerticalMargin)

		-- Draw player name
		local isPatron = player.patreonTier ~= 0
		local isCrewMember = Player.CrewMembers[player.id] ~= nil

		local playerColor = Color.DARK_BLUE
		if isPatron then
			playerColor = Color.ORANGE
		end
		local tablePositionColor = { playerColor[1], playerColor[2], playerColor[3], 160 }

		Gui.DrawRect(playerPosition, _tablePositionWidth - tableAvatarPositionWidth, _tableHeight, tablePositionColor)
		Gui.SetTextParams(4, _tablePositionTextColor, _positionScale, false, isPatron)
		Gui.DrawText(player.name, playerNamePosition[1], tableTextY)

		-- Draw voice chat indicator
		if Settings.voice.enabled then
			local localPlayerId = GetPlayerFromServerId(player.id)
			local isPlayerTalking = NetworkIsPlayerTalking(localPlayerId)
			local voiceIndicatorColor = isPlayerTalking and _activeVoiceIndicatorColor or _inactiveVoiceIndicatorColor
			DrawSprite('mpleaderboard', isPlayerTalking and 'leaderboard_audio_3' or 'leaderboard_audio_inactive', voiceIndicatorPosition[1], voiceIndicatorPosition[2], _voiceIndicatorWidth, _voiceIndicatorWidth * GetAspectRatio(), 0.0, table.unpack(voiceIndicatorColor))
		end

		-- Draw rank
		DrawSprite('mprankbadge', 'globe_bg', rankPosition[1], rankPosition[2], _rankWidth, _rankHeight, 0.0, table.unpack(_rankBackgroundColor))
		DrawSprite('mprankbadge', 'globe', rankPosition[1], rankPosition[2], _rankWidth, _rankHeight, 0.0, table.unpack(_rankColor))
		Gui.SetTextParams(4, _rankTextColor, _rankScale, false, false, true)
		Gui.DrawNumeric(player.rank, rankPosition[1], tableTextY + 0.002)

		-- Draw prestige
		if player.prestige ~= 0 then
			DrawSprite('mpleaderboard', 'leaderboard_bikers_icon', prestigePosition[1], prestigePosition[2], _rankWidth, _rankHeight, 0.0, table.unpack(_prestigeColor))
			Gui.SetTextParams(4, _prestigeTextColor, _rankScale, false, false, true)
			Gui.DrawNumeric(player.prestige, prestigePosition[1], tableTextY + 0.002)
		end

		-- Draw player status
		local playerStatusColor = Color.DARK_BLUE
		if isCrewMember or isMe then
			playerStatusColor = Color.BLUE
		elseif isPatron then
			playerStatusColor = Color.ORANGE
		end
		Gui.DrawRect(playerStatusPosition, _playerStatusWidth, _tableHeight, playerStatusColor)

		-- Draw cash
		Gui.DrawRect(cashPosition, _tableCashWidth, _tableHeight, _tableRowColor)
		Gui.SetTextParams(0, _tableCashTextColor, _cashScale, false, false, true)
		Gui.DrawTextEntry('MONEY_ENTRY', tableCashHeader[1], tableTextY + _tableTextVerticalMargin, player.cash)

		-- Draw kdRatio
		Gui.DrawRect(kdRatioPosition, _tableKdRatioWidth, _tableHeight, _tableRowColor)
		Gui.SetTextParams(0, _tableKdRatioTextColor, _kdRatioScale, false, false, true)
		local kdRatio = '-'
		if player.kdRatio then
			kdRatio = string.format('%.2f', player.kdRatio)
		end
		Gui.DrawText(kdRatio, tableKdRatioHeader[1], tableTextY + _tableTextVerticalMargin)

		-- Draw kills
		Gui.DrawRect(killsPosition, _tableKillsWidth, _tableHeight, _tableRowColor)
		Gui.SetTextParams(0, _tableKillsTextColor, _killsScale, false, false, true)
		Gui.DrawNumeric(player.kills, tableKillsHeader[1], tableTextY + _tableTextVerticalMargin)

		-- Update table position
		tablePositionY = tablePositionY + _tableSpacing + _tableHeight
	end
end

function Scoreboard.ToggleVisibility()
	if Scoreboard.IsVisible() then
		Scoreboard.Hide()
	else
		Scoreboard.Show()
	end
end

function Scoreboard.Show()
	_visible = true
end

function Scoreboard.Hide()
	_visible = false
	_pageIndex = 1
end

function Scoreboard.IsVisible()
	return _visible
end

function Scoreboard.PrevPage()
	_pageIndex = math.max(1, _pageIndex - 1)
end

function Scoreboard.NextPage()
	local maxPlayerIndex = _pageIndex * Settings.maxPlayersOnPage
	if #_scoreboard > maxPlayerIndex then
		_pageIndex = _pageIndex + 1
	end
end

function Scoreboard.GetPagesCount()
	return math.max(1, math.ceil(#_scoreboard / Settings.maxPlayersOnPage))
end

Citizen.CreateThread(function()
	AddTextEntry('MONEY_ENTRY', '$~1~')

	Streaming.RequestStreamedTextureDictAsync('mpleaderboard')
	Streaming.RequestStreamedTextureDictAsync('mprankbadge')
end)

AddEventHandler('lsv:init', function()
	while true do
		Citizen.Wait(0)

		if _visible then
			displayThisFrame()
		end
	end
end)

AddEventHandler('lsv:playerDataWasModified', function()
	_needUpdate = true
end)
