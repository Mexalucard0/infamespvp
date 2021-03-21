-- Server restart
-- Keep it sorted!
Settings.serverRestart = {
	times = {
		{ hour = 6, min = 0 },
		{ hour = 12, min = 0 },
		{ hour = 18, min = 0 },
		{ hour = 24, min = 0 },
	},
	warnBeforeMs = 15 * 60 * 1000,
}

Settings.maxMenuOptionCount = 7
Settings.discordNotificationInterval = 900000

Settings.rewardNotificationTime = 5000

-- Speedometer
Settings.enableSpeedometer = true

-- Event
Settings.nextEventTime = 120000

-- Killstreak
Settings.killstreakTimeout = 5000

-- GTA2 Cam
Settings.gta2Cam = {
	min = 24.,
	max = 48.,
	step = 0.25,
	minSpeed = 24.,
	key = { code = 171, name = 'INPUT_SPECIAL_ABILITY_PC' }, -- CAPS LOCK
}

-- Place markers
Settings.placeMarker = {
	radius = 0.625,
	opacity = 196,
}

-- Scoreboard
Settings.kdRatioMinStat = 100
Settings.minKillstreakNotification = 10
Settings.maxPlayersOnPage = 32
