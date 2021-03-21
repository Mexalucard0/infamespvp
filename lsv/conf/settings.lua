Settings = { }
Settings.__index = Settings

-- General
Settings.rewardMultiplier = { cash = 1., exp = 1. }
Settings.worldModifierDistance = 350.
Settings.allowMultipleAccounts = false
Settings.pingThreshold = 300
Settings.maxPlayerNameLength = 24
Settings.serverTimeZone = '(GMT-8)'

-- Moderation
Settings.moderator = {
	levels = {
		['Moderator'] = 1,
		['Administrator'] = 2,
	},
	maxMessageLength = 140,
}
