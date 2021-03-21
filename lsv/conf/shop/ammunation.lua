-- AmmuNation weapons
Settings.ammuNationWeapons = {
	['Melee'] = {
		'WEAPON_FLASHLIGHT',
		'WEAPON_KNIFE',
		'WEAPON_HAMMER',
		'WEAPON_SWITCHBLADE',
		'WEAPON_BAT',
		'WEAPON_POOLCUE',
		'WEAPON_MACHETE',
		'WEAPON_BATTLEAXE',
		'WEAPON_GOLFCLUB',
		'WEAPON_HATCHET',
		'WEAPON_CROWBAR',
		'WEAPON_KNUCKLE',
	},
	['Pistolas'] = {
		'WEAPON_PISTOL', --1
		'WEAPON_COMBATPISTOL', --3
		'WEAPON_FLAREGUN', --5
		'WEAPON_APPISTOL', --15
		'WEAPON_HEAVYPISTOL', --29
		'WEAPON_PISTOL50', --35
		'WEAPON_DOUBLEACTION', --47
		'WEAPON_PISTOL_MK2',
	},
	['Escopetas'] = {
		'WEAPON_SAWNOFFSHOTGUN', --1
		'WEAPON_DBSHOTGUN', --3
		'WEAPON_PUMPSHOTGUN', --7
		'WEAPON_AUTOSHOTGUN', --17
		'WEAPON_ASSAULTSHOTGUN', --39
		'WEAPON_PUMPSHOTGUN_MK2',
	},
	['Metralletas y Ametralladoras Ligeras'] = {
		'WEAPON_MICROSMG', --1
		'WEAPON_SMG', --5
		'WEAPON_MACHINEPISTOL', --13
		'WEAPON_MG', --21
		'WEAPON_MINISMG', --31
		'WEAPON_COMBATMG', --41
		'WEAPON_SMG_MK2',
		'WEAPON_COMBATMG_MK2',
	},
	['Rifles de Asalto'] = {
		'WEAPON_ASSAULTRIFLE', --11
		'WEAPON_CARBINERIFLE', --19
		'WEAPON_SPECIALCARBINE', --25
		'WEAPON_BULLPUPRIFLE', --33
		'WEAPON_ADVANCEDRIFLE', --37
		'WEAPON_COMPACTRIFLE', --43
		'WEAPON_ASSAULTRIFLE_MK2',
		'WEAPON_CARBINERIFLE_MK2',
		'WEAPON_BULLPUPRIFLE_MK2',
		'WEAPON_SPECIALCARBINE_MK2',
	},
	['Rifles de Francotirador'] = {
		'WEAPON_SNIPERRIFLE', --27
		'WEAPON_HEAVYSNIPER', --45
		'WEAPON_HEAVYSNIPER_MK2',
	},
	['Armas Pesadas'] = {
		'WEAPON_RPG', --27
		'WEAPON_MINIGUN', --48
		'WEAPON_GRENADELAUNCHER', --49
		'WEAPON_HOMINGLAUNCHER', --50
	},
	['Lanzables'] = {
		'WEAPON_SMOKEGRENADE', --1
		'WEAPON_GRENADE', --5
		'WEAPON_MOLOTOV', --9
		'WEAPON_STICKYBOMB', --23
		'WEAPON_PROXMINE', --23
	},
	['Especiales'] = {
		'WEAPON_FIREWORK', --1
		'WEAPON_PETROLCAN', --1
	},
}

-- AmmuNation Refill Ammo
Settings.ammuNationRefillAmmo = {
	['Municion de Pistola'] = {
		weapons = {
			'WEAPON_PISTOL',
			'WEAPON_COMBATPISTOL',
			'WEAPON_APPISTOL',
			'WEAPON_HEAVYPISTOL',
			'WEAPON_PISTOL50',
			'WEAPON_DOUBLEACTION',
			'WEAPON_PISTOL_MK2',
		},
		ammo = 24,
		price = 0,
	},

	['Cartuchos de escopeta'] = {
		weapons = {
			'WEAPON_ASSAULTSHOTGUN',
			'WEAPON_AUTOSHOTGUN',
			'WEAPON_DBSHOTGUN',
			'WEAPON_PUMPSHOTGUN',
			'WEAPON_SAWNOFFSHOTGUN',
			'WEAPON_PUMPSHOTGUN_MK2',
		},
		ammo = 8,
		price = 54,
	},

	['Municion de SMG'] = {
		weapons = {
			'WEAPON_SMG',
			'WEAPON_MICROSMG',
			'WEAPON_MACHINEPISTOL',
			'WEAPON_MINISMG',
			'WEAPON_SMG_MK2',
		},
		ammo = 30,
		price = 169,
	},

	['Municion de MG'] = {
		weapons = {
			'WEAPON_COMBATMG',
			'WEAPON_MG',
			'WEAPON_COMBATMG_MK2',
		},
		ammo = 100,
		price = 325,
	},

	['Municion de Rifles de Asalto'] = {
		weapons = {
			'WEAPON_ASSAULTRIFLE',
			'WEAPON_CARBINERIFLE',
			'WEAPON_SPECIALCARBINE',
			'WEAPON_BULLPUPRIFLE',
			'WEAPON_ADVANCEDRIFLE',
			'WEAPON_COMPACTRIFLE',
			'WEAPON_ASSAULTRIFLE_MK2',
			'WEAPON_SPECIALCARBINE_MK2',
			'WEAPON_BULLPUPRIFLE_MK2',
			'WEAPON_CARBINERIFLE_MK2',
		},
		ammo = 60,
		price = 243,
	},

	['Municion de Rifle de Francotirador'] = {
		weapons = {
			'WEAPON_SNIPERRIFLE',
			'WEAPON_HEAVYSNIPER',
			'WEAPON_HEAVYSNIPER_MK2',
		},
		ammo = 20,
		price = 390,
	},

	['Unidades de gas lacrimógeno'] = {
		weapons = {
			'WEAPON_SMOKEGRENADE',
		},
		ammo = 1,
		price = 150,
	},

	['Unidades de granadas'] = {
		weapons = {
			'WEAPON_GRENADE',
		},
		ammo = 1,
		price = 300,
	},

	['Unidades de cóctel molotov'] = {
		weapons = {
			'WEAPON_MOLOTOV',
		},
		ammo = 1,
		price = 200,
	},

	['Unidades de bombas pegajosas'] = {
		weapons = {
			'WEAPON_STICKYBOMB',
		},
		ammo = 1,
		price = 400,
	},

	['Unidades de minas de proximidad'] = {
		weapons = {
			'WEAPON_PROXMINE',
		},
		ammo = 1,
		price = 600,
	},

	['Municion de pistola de bengalas'] = {
		weapons = {
			'WEAPON_FLAREGUN',
		},
		ammo = 2,
		price = 100,
	},

	['Fuegos artificiales'] = {
		weapons = {
			'WEAPON_FIREWORK',
		},
		ammo = 2,
		price = 250,
	},
}

-- AmmuNation Special Weapons Ammo
Settings.ammuNationSpecialAmmo = {
	['WEAPON_GRENADELAUNCHER'] = {
		ammo = 1 * 2,
		price = 500,
		type = 'Granadas',
	},
	['WEAPON_RPG'] = {
		ammo = 1 * 2,
		price = 750,
		type = 'Misiles',
	},
	['WEAPON_HOMINGLAUNCHER'] = {
		ammo = 1 * 2,
		price = 1000,
		type = 'Misiles',
	},
	['WEAPON_MINIGUN'] = {
		ammo = 1 * 150,
		price = 500,
		type = 'Municion',
	},
}

-- Weapon tints
Settings.weaponTints = {
	{
		index = 0,
		name = 'Normal',
		kills = 0,
		cash = 0,
	},

	{
		index = 4,
		kills = 100,
		cash = 5000,
	},

	{
		index = 1,
		kills = 200,
		cash = 5250,
	},

	{
		index = 6,
		kills = 400,
		cash = 5500,
	},

	{
		index = 5,
		kills = 600,
		cash = 5750,
	},

	{
		index = 3,
		kills = 1000,
		cash = 7500,
	},

	{
		index = 2,
		kills = 1500,
		cash = 10000,
	},

	{
		index = 7,
		kills = 2500,
		cash = 12500,
	},
}

Settings.weaponTintNames = {
	'Verde',
	'Oro',
	'Rosa',
	'Army',
	'LSPD',
	'Naranja',
	'Plateado',
}
