rHeadphones = rHeadphones or {}
rHeadphones.Config = rHeadphones.Config or {}
rHeadphones.Stations = rHeadphones.Stations or {}

surface.CreateFont("rHeadphones_Title", {
    font = "Roboto",
    size = 28,
    weight = 700
})

surface.CreateFont("rHeadphones_Regular", {
    font = "Roboto",
    size = 20,
    weight = 400
})

surface.CreateFont("rHeadphones_Small", {
    font = "Roboto",
    size = 16,
    weight = 400
})

include("rheadphones/lib/sound_analyze.lua")

function rHeadphones.FormatCountryName(name)
    name = name:gsub("_", " ")
    
    local words = {}
    for word in name:gmatch("%S+") do
        if word:upper() == word then
            table.insert(words, word)
        else
            -- Title case
            table.insert(words, word:sub(1,1):upper() .. word:sub(2):lower())
        end
    end
    
    return table.concat(words, " ")
end

rHeadphones.Config = { -- Default config in-case anything goes wrong with config.lua, do not modify.
    defaultVolume = 0.5,
    maxVolume = 1.0,
    hotkey = KEY_H,
    fadeTime = 0.5,
    
    -- UI settings
    ui = {
        width = 500,
        height = 600,
        buttonHeight = 30,
        margin = 5
    },
    
    -- Sound settings
    sounds = {
        play = "items/battery_pickup.wav",
        stop = "items/battery_pickup.wav",
        playVolume = 0.3,
        stopVolume = 0.3,
        playPitch = 100,
        stopPitch = 85
    }
}

local function StripCountrySuffix(country)
    return string.gsub(country, "_%d+$", "")
end

local function LoadStationData()
    local files, _ = file.Find("rheadphones/stations/data_*.lua", "LUA")
    local tempStations = {}
    
    -- First pass: Load all data into temporary table
    for _, f in ipairs(files) do
        local stationData = include("rheadphones/stations/" .. f)
        for country, stations in pairs(stationData) do
            -- Strip any numeric suffix from country name
            local cleanCountry = StripCountrySuffix(country)
            tempStations[cleanCountry] = tempStations[cleanCountry] or {}

            for _, station in ipairs(stations) do
                table.insert(tempStations[cleanCountry], {
                    name = station.n,
                    url = station.u,
                    country = cleanCountry
                })
            end
        end
    end
    
    -- Second pass: Remove duplicates and sort
    for country, stations in pairs(tempStations) do
        local seen = {}
        local uniqueStations = {}
        
        for _, station in ipairs(stations) do
            local key = station.name .. station.url
            if not seen[key] then
                seen[key] = true
                table.insert(uniqueStations, station)
            end
        end
        
        table.sort(uniqueStations, function(a, b)
            return a.name < b.name
        end)

        rHeadphones.Stations[country] = uniqueStations
    end
end

include("rheadphones/config.lua")
LoadStationData() 