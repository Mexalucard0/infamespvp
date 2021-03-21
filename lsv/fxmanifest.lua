-- Manifest
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

dependencies {
	'warmenu',
	'vSql',
}

-- WarMenu resource
client_script '@warmenu/warmenu.lua'

-- vSql library
server_script '@vSql/vSql.lua'

files {
	'files/weapons.meta',
	'files/weaponautoshotgun.meta',
	'files/weapondbshotgun.meta',
	'files/weapons_heavysniper_mk2.meta',
	'files/weapons_doubleaction.meta',
	'files/weapons_combatmg_mk2.meta',
	'files/weapons_pumpshotgun_mk2.meta',
}

data_file 'WEAPONINFO_FILE_PATCH' 'files/weapons.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'files/weaponautoshotgun.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'files/weapondbshotgun.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'files/weapons_heavysniper_mk2.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'files/weapons_doubleaction.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'files/weapons_combatmg_mk2.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'files/weapons_pumpshotgun_mk2.meta'

-- Shared scripts
shared_scripts {
	'lib/utils/*.lua',
	'lib/*.lua',
}

-- Server config files
server_scripts {
	'conf/settings.lua',
	'conf/pvp.lua',
	'conf/challenge.lua',
	'conf/crate.lua',
	'conf/crew.lua',
	'conf/drug.lua',
	'conf/enviroment.lua',
	'conf/event.lua',
	'conf/garage.lua',
	'conf/guard.lua',
	'conf/hud.lua',
	'conf/mission.lua',
	'conf/patreon.lua',
	'conf/player.lua',
	'conf/rank.lua',
	'conf/server.lua',
	'conf/spawn.lua',
	'conf/travel.lua',
	'conf/voice.lua',
	'conf/loot.lua',
	'conf/event/castle.lua',
	'conf/event/gun.lua',
	'conf/event/property.lua',
	'conf/event/beast.lua',
	'conf/event/stockpiling.lua',
	'conf/event/sharpshooter.lua',
	'conf/event/penned.lua',
	'conf/event/highway.lua',
	'conf/event/simeon.lua',
	'conf/event/gang.lua',
	'conf/mission/assetrecovery.lua',
	'conf/mission/headhunter.lua',
	'conf/mission/heist.lua',
	'conf/mission/mostwanted.lua',
	'conf/mission/velocity.lua',
	'conf/mission/sightseer.lua',
	'conf/mission/survival.lua',
	'conf/mission/timetrial.lua',
	'conf/mission/drugexport.lua',
	'conf/mission/import.lua',
	'conf/mission/hostile.lua',
	'conf/shop/ammunation.lua',
	'conf/shop/skinshop.lua',
	'conf/shop/vehicleshop.lua',
	'mysettings.lua',
}

-- Server files
server_scripts {
	'lib/server/db.lua',
	'lib/server/guard.lua',
	'lib/server/stat.lua',
	'lib/server/discord.lua',
	'lib/server/crate.lua',
	'lib/server/playerdata.lua',
	'lib/server/eventscheduler.lua',
	'lib/server/missionmanager.lua',
	'lib/server/crew.lua',
	'lib/server/network.lua',
	'lib/server/challenge.lua',
}

server_scripts {
	'server/save.lua',
	'server/hud.lua',
	'server/weather.lua',
	'server/pvp.lua',
	'server/session.lua',
	'server/patreon.lua',
	'server/guard.lua',
	'server/chat.lua',
	'server/report.lua',
	'server/moderator.lua',
	'server/pingkick.lua',
	'server/travel.lua',
	'server/garage.lua',
	'server/tebex.lua',
	'server/drug.lua',
	'server/loot.lua',
	'server/main.lua',

	'server/event/castle.lua',
	'server/event/gun.lua',
	'server/event/property.lua',
	'server/event/beast.lua',
	'server/event/stockpiling.lua',
	'server/event/sharpshooter.lua',
	'server/event/penned.lua',
	'server/event/highway.lua',
	'server/event/simeon.lua',
	'server/event/gang.lua',

	'server/shop/ammunation.lua',
	'server/shop/skinshop.lua',
	'server/shop/vehicle.lua',

	'server/mission/assetrecovery.lua',
	'server/mission/headhunter.lua',
	'server/mission/heist.lua',
	'server/mission/mostwanted.lua',
	'server/mission/velocity.lua',
	'server/mission/sightseer.lua',
	'server/mission/survival.lua',
	'server/mission/timetrial.lua',
	'server/mission/drugexport.lua',
	'server/mission/import.lua',
	'server/mission/hostile.lua',
}

-- Client config files
client_scripts {
	'conf/settings.lua',
	'conf/pvp.lua',
	'conf/challenge.lua',
	'conf/crate.lua',
	'conf/crew.lua',
	'conf/drug.lua',
	'conf/enviroment.lua',
	'conf/event.lua',
	'conf/garage.lua',
	'conf/hud.lua',
	'conf/mission.lua',
	'conf/patreon.lua',
	'conf/player.lua',
	'conf/rank.lua',
	'conf/server.lua',
	'conf/spawn.lua',
	'conf/travel.lua',
	'conf/voice.lua',
	'conf/loot.lua',
	'conf/event/castle.lua',
	'conf/event/gun.lua',
	'conf/event/property.lua',
	'conf/event/beast.lua',
	'conf/event/stockpiling.lua',
	'conf/event/sharpshooter.lua',
	'conf/event/penned.lua',
	'conf/event/highway.lua',
	'conf/event/simeon.lua',
	'conf/event/gang.lua',
	'conf/mission/assetrecovery.lua',
	'conf/mission/headhunter.lua',
	'conf/mission/heist.lua',
	'conf/mission/mostwanted.lua',
	'conf/mission/velocity.lua',
	'conf/mission/sightseer.lua',
	'conf/mission/survival.lua',
	'conf/mission/timetrial.lua',
	'conf/mission/drugexport.lua',
	'conf/mission/import.lua',
	'conf/mission/hostile.lua',
	'conf/shop/ammunation.lua',
	'conf/shop/skinshop.lua',
	'conf/shop/vehicleshop.lua',
	'mysettings.lua',
}

-- Client files
client_scripts {
	'lib/client/prompt.lua',

	'lib/client/gui/safezone.lua',
	'lib/client/gui/animated.lua',
	'lib/client/gui/gui.lua',
	'lib/client/gui/bar.lua',
	'lib/client/gui/helpqueue.lua',
	'lib/client/gui/scoreboard.lua',
	'lib/client/gui/screen.lua',

	'lib/client/world.lua',
	'lib/client/streaming.lua',
	'lib/client/scaleform.lua',
	'lib/client/player.lua',
	'lib/client/map.lua',
	'lib/client/playerdata.lua',
	'lib/client/missionmanager.lua',
	'lib/client/vehicle.lua',
	'lib/client/network.lua',
	'lib/client/decor.lua',
}

client_scripts {
	'client/spawn.lua',
	'client/enviroment.lua',
	'client/guard.lua',
	'client/afk.lua',
	'client/session.lua',
	'client/chat.lua',
	'client/hud.lua',
	'client/playertags.lua',
	'client/pingkick.lua',
	'client/crew.lua',
	'client/travel.lua',
	'client/garage.lua',
	'client/drug.lua',
	'client/crate.lua',
	'client/loot.lua',

	'client/event/castle.lua',
	'client/event/gun.lua',
	'client/event/property.lua',
	'client/event/beast.lua',
	'client/event/stockpiling.lua',
	'client/event/sharpshooter.lua',
	'client/event/penned.lua',
	'client/event/highway.lua',
	'client/event/simeon.lua',
	'client/event/gang.lua',

	'client/menu/interaction.lua',
	'client/menu/moderator.lua',
	'client/menu/vehicle.lua',

	'client/shop/skinshop.lua',
	'client/shop/ammunation.lua',
	'client/shop/vehicleshop.lua',

	'client/mission/assetrecovery.lua',
	'client/mission/headhunter.lua',
	'client/mission/heist.lua',
	'client/mission/mostwanted.lua',
	'client/mission/velocity.lua',
	'client/mission/sightseer.lua',
	'client/mission/survival.lua',
	'client/mission/timetrial.lua',
	'client/mission/drugexport.lua',
	'client/mission/import.lua',
	'client/mission/hostile.lua',
}

ui_page {
	'html/ui.html'
}

files {
	'html/*.png',
	'html/*.gif',
	'html/*.html',
	'html/ui.html',
	'html/css/main.css',
}