rHeadphones = rHeadphones or {}
rHeadphones.Favorites = {
    countries = {},
    stations = {},
    loaded = false
}

local SAVE_DEBOUNCE_TIME = 1 -- Save after 1 second of no changes
local saveTimer = nil

function rHeadphones.Favorites.Load()
    if rHeadphones.Favorites.loaded then return end
    
    if not file.Exists("rheadphones", "DATA") then
        file.CreateDir("rheadphones")
    end
    
    if file.Exists("rheadphones/favorites.json", "DATA") then
        local data = file.Read("rheadphones/favorites.json", "DATA")
        local success, favorites = pcall(util.JSONToTable, data)
        
        if success and favorites then
            rHeadphones.Favorites.countries = favorites.countries or {}
            rHeadphones.Favorites.stations = favorites.stations or {}
        end
    end
    
    rHeadphones.Favorites.loaded = true
end

function rHeadphones.Favorites.Save()
    if saveTimer then timer.Remove(saveTimer) end
    
    saveTimer = "rHeadphones_SaveFavorites_" .. CurTime()
    timer.Create(saveTimer, SAVE_DEBOUNCE_TIME, 1, function()
        local data = util.TableToJSON({
            countries = rHeadphones.Favorites.countries,
            stations = rHeadphones.Favorites.stations
        }, true)
        
        file.Write("rheadphones/favorites.json", data)
    end)
end

function rHeadphones.Favorites.ToggleCountry(country)
    if not rHeadphones.Favorites.loaded then rHeadphones.Favorites.Load() end
    
    if rHeadphones.Favorites.countries[country] then
        rHeadphones.Favorites.countries[country] = nil
    else
        rHeadphones.Favorites.countries[country] = true
    end
    
    rHeadphones.Favorites.Save()
end

function rHeadphones.Favorites.ToggleStation(station)
    if not rHeadphones.Favorites.loaded then rHeadphones.Favorites.Load() end
    
    local stationKey = string.format("%s:%s", station.country, station.name)
    
    if rHeadphones.Favorites.stations[stationKey] then
        rHeadphones.Favorites.stations[stationKey] = nil
    else
        rHeadphones.Favorites.stations[stationKey] = {
            name = station.name,
            url = station.url,
            country = station.country
        }
    end
    
    rHeadphones.Favorites.Save()
end

function rHeadphones.Favorites.IsCountryFavorite(country)
    return rHeadphones.Favorites.countries[country] or false
end

function rHeadphones.Favorites.IsStationFavorite(station)
    local stationKey = string.format("%s:%s", station.country, station.name)
    return rHeadphones.Favorites.stations[stationKey] ~= nil
end

function rHeadphones.Favorites.GetFavoriteStations()
    local stations = {}
    for _, station in pairs(rHeadphones.Favorites.stations) do
        table.insert(stations, station)
    end
    return stations
end

hook.Add("InitPostEntity", "rHeadphones_LoadFavorites", function()
    rHeadphones.Favorites.Load()
end) 