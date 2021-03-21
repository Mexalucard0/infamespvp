-- Player
Settings.disableCrosshair = false
Settings.disableCrosshairForVehicleDriver = false
Settings.forceFirstPersonViewWhenAiming = false
Settings.disableHealthRegen = false
Settings.giveArmorAtSpawn = true
Settings.giveParachuteAtSpawn = true
Settings.infinitePlayerStamina = true
Settings.weaponClipCount = 10
Settings.defaultPlayerWeapons = {
	{ id = 'WEAPON_KNIFE', ammo = 0, components = { } },
	{ id = 'WEAPON_PISTOL', ammo = 12 * 10, components = { } },
	{ id = 'WEAPON_MICROSMG', ammo = 16 * 10, components = { }, selected = true },
	{ id = 'WEAPON_SAWNOFFSHOTGUN', ammo = 8 * 10, components = { } },
}
Settings.defaultPlayerModel = {
	model = 'a_m_y_hipster_01',
	components = { },
}
Settings.stats = {
	strength = { min = 75, max = 80 },
	shooting = { min = 60, max = 80 },
	flying = { min = 60, max = 80 },
	driving = { min = 60, max = 80 },
	lung = { min = 60 , max = 80 },
	stealth = { min = 80 , max = 100 },
	stamina = { min = 100, max = 100 },
}
Settings.armour = {
	max = 100,
}
Settings.maxPlayerHealth = 200

Settings.afkTimeout = 300 -- in seconds
Settings.autoSavingInterval = 180000
Settings.killYourselfInterval = 60000

-- Player settings
Settings.player = {
	['enableFirstPersonAiming'] = 'Primera Persona Al Apuntar',
	['showKillDetails'] = 'Mostrar Detalles De Muertes',
	['disableCrosshair'] = 'Desactivar Punto De Mira',
	['disableKillFeed'] = 'Desactivar Kill Feed',
	['disableTips'] = 'Desactivar Consejos',
	['disableEventTimer'] = 'Desactivar El Temporizador De Eventos',
}

-- Personal Vehicles
Settings.personalVehicle = {
	maxDistance = 50.0,
	rentPrice = 250,
	rentTimeout = 15000,
}
