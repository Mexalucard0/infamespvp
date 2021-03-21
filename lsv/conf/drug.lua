-- Drug Business
Settings.drugBusiness = {
	sellMultiplier = 0.5,
	types = {
		['weed'] = {
			name = 'Laboratorio de Marihuana',
			productName = 'Marihuana',
			price = {
				supply = 3240, -- 0.4 from default
				default = 7290,
				upgraded = 10935, -- 1.5 from default
			},
			time = {
				default = 126000,
				upgraded = 90000,
			},
		},
		['cocaine'] = {
			name = 'Laboratorio de Cocaina',
			productName = 'Cocaina',
			price = {
				supply = 4320,
				default = 9720,
				upgraded = 14580,
			},
			time = {
				default = 168000,
				upgraded = 120000,
			},
		},
		['meth'] = {
			name = 'Laboratorio de Meta',
			productName = 'Metanfetamina',
			price = {
				supply = 6480,
				default = 14580,
				upgraded = 21870,
			},
			time = {
				default = 252000,
				upgraded = 180000,
			},
		},
	},

	limits = {
		stock = 10,
		supplies = 10,
	},

	businesses = {
		['weed_chianski'] = {
			type = 'weed',
			price = 715000,
			location = { x = 2856.5283203125, y = 4459.6982421875, z = 48.498035430908 },
			vehicleLocation = { x = 2870.0515136719, y = 4470.06640625, z = 48.200050354004, heading = 47.266815185547 },
		},
		['weed_chiliad'] = {
			type = 'weed',
			price = 805200,
			location = { x = 417.62976074219, y = 6520.7631835938, z = 27.717031478882 },
			vehicleLocation = { x = 435.55755615234, y = 6526.6489257812, z = 27.723098754883, heading = 40.130340576172 },
		},
		['weed_elysian'] = {
			type = 'weed',
			price = 1072500,
			location = { x = 137.66839599609, y = -2473.3046875, z = 5.9999890327454 },
			vehicleLocation = { x = 146.44578552246, y = -2476.8327636719, z = 5.7800230979919, heading = 169.13246154785 },
		},
		['weed_downtown'] = {
			type = 'weed',
			price = 1358500,
			location = { x = 163.40872192383, y = 151.35762023926, z = 105.17762756348 },
			vehicleLocation = { x = 144.10664367676, y = 151.73318481445, z = 104.39183807373, heading = 247.93951416016 },
		},
		['cocaine_alamo'] = {
			type = 'cocaine',
			price = 975000,
			location = { x = 388.23907470703, y = 3586.1882324219, z = 33.292274475098 },
			vehicleLocation = { x = 378.21655273438, y = 3590.7204589844, z = 33.040554046631, heading = 290.12533569336 },
		},
		['cocaine_paleto'] = {
			type = 'cocaine',
			price = 1098000,
			location = { x = 52.597595214844, y = 6486.4926757812, z = 31.429975509644 },
			vehicleLocation = { x = 58.431941986084, y = 6462.5322265625, z = 31.088090896606, heading = 151.82548522949 },
		},
		['cocaine_elysian'] = {
			type = 'cocaine',
			price = 1462500,
			location = { x = -254.45875549316, y = -2589.7253417969, z = 6.0006284713745 },
			vehicleLocation = { x = -251.04306030273, y = -2569.0297851562, z = 5.7482309341431, heading = 90.192520141602 },
		},
		['cocaine_morning'] = {
			type = 'cocaine',
			price = 1852500,
			location = { x = -1401.6412353516, y = -453.37533569336, z = 34.482559204102 },
			vehicleLocation = { x = -1384.7030029297, y = -457.83236694336, z = 34.224586486816, heading = 72.654716491699 },
		},
	},

	upgrades = {
		['security'] = {
			name = 'Mejora de Seguridad',
			toolTip = 'Inhabilita policías durante la misión de exportación de drogas.',
			prices = {
				['weed'] = 627000,
				['cocaine'] = 1026000,
				['meth'] = 1140000,
			},
		},
		['staff'] = {
			name = 'Mejora de Personal',
			toolTip = 'Incrementa el valor de tu producto.',
			prices = {
				['weed'] = 546000,
				['cocaine'] = 663000,
				['meth'] = 780000,
			},
		},
		['equip'] = {
			name = 'Mejora de Equipo',
			toolTip = 'Acelerar el tiempo de producción.',
			prices = {
				['weed'] = 935000,
				['cocaine'] = 990000,
				['meth'] = 1100000,
			},
		},
	},

	export = {
		missionName = 'Exportación de Drogas',
		time = 1200000,
		dropRadius = 10.,
		expRate = 0.2,
		locations = {
			{ x = -1055.5090332031, y = -2017.0299072266, z = 13.161571502686 },
			{ x = -306.30072021484, y = -2699.01953125, z = 6.0002951622009 },
			{ x = 264.00634765625, y = -3020.0100097656, z = 5.7394118309021 },
			{ x = 1006.5920410156, y = -2518.396484375, z = 28.303230285645 },
			{ x = 1564.9898681641, y = -2149.2104492188, z = 77.581161499023 },
			{ x = 1017.9209594727, y = -1861.7778320313, z = 30.889822006226 },
		},
		vehicles = {
			['weed'] = { `pony`, `pony2` },
			['cocaine'] = { `speedo`, `speedo2` },
			['meth'] = { `boxville`, `boxville2`, `boxville3`, `boxville4` },
		},
	},
}
