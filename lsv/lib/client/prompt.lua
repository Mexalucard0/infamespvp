Prompt = { }
Prompt.__index = Prompt

local _isDisplaying = false

function Prompt.Show(message, type)
	if _isDisplaying then
		return
	end

	BeginTextCommandBusyString('TWOSTRINGS')
	AddTextComponentString(message or 'Transacción pendiente')
	EndTextCommandBusyString(type or 4)
end

function Prompt.ShowAsync(message, type)
	if _isDisplaying then
		return
	end

	Prompt.Show(message, type)

	_isDisplaying = true
	while _isDisplaying do
		Citizen.Wait(0)
	end
end

function Prompt.IsDisplaying()
	return _isDisplaying
end

function Prompt.Hide()
	_isDisplaying = false
	RemoveLoadingPrompt()
end
