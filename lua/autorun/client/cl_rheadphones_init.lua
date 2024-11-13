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
    local stationData = include("rheadphones/stations.lua")

    for country, stations in pairs(stationData) do
        local cleanCountry = StripCountrySuffix(country)
        rHeadphones.Stations[cleanCountry] = rHeadphones.Stations[cleanCountry] or {}

        for _, station in ipairs(stations) do
            table.insert(rHeadphones.Stations[cleanCountry], {
                name = station.n,
                url = station.u,
                country = cleanCountry
            })
        end
        
        -- Sort stations by name
        table.sort(rHeadphones.Stations[cleanCountry], function(a, b)
            return a.name < b.name
        end)
    end
end

include("rheadphones/config.lua")
LoadStationData() 