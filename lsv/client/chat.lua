local function registerEmoteSuggestion(command, withoutParam)
	local param = nil
	if not withoutParam then
		param = { { name = 'playerid', help = 'Opcional' } }
	end

	TriggerEvent('chat:addSuggestion', command, '', param)
end

RegisterNetEvent('lsv:playerMuteChanged')
AddEventHandler('lsv:playerMuteChanged', function(player, muted)
	MumbleSetVolumeOverrideByServerId(player, muted and 0. or -1.)
end)

AddEventHandler('lsv:init', function()
	TriggerEvent('chat:addSuggestion', '/t', 'Enviar privado a un jugador', {
		{ name = 'playerid' },
		{ name = 'mensaje' },
	})

	TriggerEvent('chat:addSuggestion', '/c', 'Enviar mensaje a tu Crew', {
		{ name = 'mensaje' },
	})

	if Player.Moderator and Player.Moderator == Settings.moderator.levels.Administrator then
		TriggerEvent('chat:addSuggestion', '/unban', 'Desbanea a un jugador', {
			{ name = 'playerid' },
		})
	end

	registerEmoteSuggestion('/acordar')
	registerEmoteSuggestion('/asombrar')
	registerEmoteSuggestion('/enojado')
	registerEmoteSuggestion('/disculparse')
	registerEmoteSuggestion('/aplaudir')
	registerEmoteSuggestion('/atacar')

	registerEmoteSuggestion('/ladrar')
	registerEmoteSuggestion('/vergonzoso')
	registerEmoteSuggestion('/llamar')
	registerEmoteSuggestion('/rogar')
	registerEmoteSuggestion('/sangrar', true)
	registerEmoteSuggestion('/morder')
	registerEmoteSuggestion('/besar')
	registerEmoteSuggestion('/sonrojar')
	registerEmoteSuggestion('/aburrido')
	registerEmoteSuggestion('/rebota')
	registerEmoteSuggestion('/reverencia')
	registerEmoteSuggestion('/vuelvo')
	registerEmoteSuggestion('/adios')

	registerEmoteSuggestion('/reirse')
	registerEmoteSuggestion('/calma')
	registerEmoteSuggestion('/gato')
	registerEmoteSuggestion('/cargar', true)
	registerEmoteSuggestion('/animar')
	registerEmoteSuggestion('/mascar')
	registerEmoteSuggestion('/gallina')
	registerEmoteSuggestion('/risita')
	registerEmoteSuggestion('/aplaudir')
	registerEmoteSuggestion('/frio')
	registerEmoteSuggestion('/cariño')
	registerEmoteSuggestion('/elogiar')
	registerEmoteSuggestion('/confundido')
	registerEmoteSuggestion('/felicitar')
	registerEmoteSuggestion('/toser')
	registerEmoteSuggestion('/acobardarse')
	registerEmoteSuggestion('/tronar')
	registerEmoteSuggestion('/encogerse')
	registerEmoteSuggestion('/llorar')
	registerEmoteSuggestion('/acurrucarse')
	registerEmoteSuggestion('/curioso')

	registerEmoteSuggestion('/bailar')
	registerEmoteSuggestion('/decepcionado')
	registerEmoteSuggestion('/condenar')
	registerEmoteSuggestion('/beber')
	registerEmoteSuggestion('/agacharse')

	registerEmoteSuggestion('/cubrircara')

	registerEmoteSuggestion('/ayudenme', true)
	registerEmoteSuggestion('/hola')

	registerEmoteSuggestion('/broma')

	registerEmoteSuggestion('/reir')

	registerEmoteSuggestion('/mute') -- Not an emote at all
	registerEmoteSuggestion('/unmute') -- Not an emote at all

	registerEmoteSuggestion('/id') -- Not an emote at all
	registerEmoteSuggestion('/ping') -- Not an emote at all

	registerEmoteSuggestion('/ayuda', true) -- Not an emote at all
	registerEmoteSuggestion('/municion', true) -- Not an emote at all
	registerEmoteSuggestion('/report', true) -- Not an emote at all
	registerEmoteSuggestion('/skin', true) -- Not an emote at all
	registerEmoteSuggestion('/dinero', true) -- Not an emote at all
	registerEmoteSuggestion('/vehiculos', true) -- Not an emote at all
	registerEmoteSuggestion('/misiones', true) -- Not an emote at all
	registerEmoteSuggestion('/pasivo', true) -- Not an emote at all
	registerEmoteSuggestion('/armas', true) -- Not an emote at all
end)

AddEventHandler('lsv:setupHud', function(hud)
	if hud.discordUrl ~= '' then
		TriggerEvent('chat:addSuggestion', '/discord', 'Obten el enlace de invitación a Discord', {
			{ name = hud.discordUrl },
		})
	end
end)
