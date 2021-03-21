Screen = { }
Screen.__index = Screen

function Screen.FadeOutAsync(ms)
	if IsScreenFadedIn() then
		DoScreenFadeOut(ms)
		while not IsScreenFadedOut() do
			Citizen.Wait(0)
		end
	end
end

function Screen.FadeInAsync(ms)
	if IsScreenFadedOut() then
		DoScreenFadeIn(ms)
		while not IsScreenFadedIn() do
			Citizen.Wait(0)
		end
	end
end
