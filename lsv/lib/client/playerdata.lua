PlayerData = { }
PlayerData.__index = PlayerData

local _playerData = { }

function PlayerData.IsExists(player)
	return _playerData[player] ~= nil
end

function PlayerData.GetPlayers()
	return _playerData
end

function PlayerData.Get(player)
	return _playerData[player]
end

function PlayerData.GetName(player)
	return _playerData[player].name
end

function PlayerData.GetPatreonTier(player)
	return _playerData[player].patreonTier
end

function PlayerData.GetRank(player)
	return _playerData[player].rank
end

function PlayerData.GetKillstreak(player)
	return _playerData[player].killstreak
end

function PlayerData.GetDeathstreak(player)
	return _playerData[player].deathstreak
end

function PlayerData.GetCrewLeader(player)
	return _playerData[player].crewLeader
end

RegisterNetEvent('lsv:initPlayerData')
AddEventHandler('lsv:initPlayerData', function(data)
	_playerData = data
	TriggerEvent('lsv:playerDataWasModified')
end)

RegisterNetEvent('lsv:addPlayerData')
AddEventHandler('lsv:addPlayerData', function(data)
	if not _playerData[data.id] then
		_playerData[data.id] = data
		TriggerEvent('lsv:playerDataWasModified')
	end
end)

RegisterNetEvent('lsv:removePlayerData')
AddEventHandler('lsv:removePlayerData', function(id)
	if _playerData[id] then
		_playerData[id] = nil
		TriggerEvent('lsv:playerDataWasModified')
	end
end)

RegisterNetEvent('lsv:updatePlayerData')
AddEventHandler('lsv:updatePlayerData', function(id, data)
	if _playerData[id] then
		table.foreach(data, function(v, k)
			_playerData[id][k] = v
		end)

		TriggerEvent('lsv:playerDataWasModified')
	end
end)
