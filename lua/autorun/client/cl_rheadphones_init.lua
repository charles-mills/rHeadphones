rHeadphones = rHeadphones or {}
rHeadphones.Config = rHeadphones.Config or {}
rHeadphones.Stations = rHeadphones.Stations or {}

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

local function LoadStationData()
    local files, _ = file.Find("rheadphones/stations/data_*.lua", "LUA")
    
    for _, f in ipairs(files) do
        local stationData = include("rheadphones/stations/" .. f)
        for country, stations in pairs(stationData) do
            rHeadphones.Stations[country] = rHeadphones.Stations[country] or {}

            for _, station in ipairs(stations) do
                table.insert(rHeadphones.Stations[country], {
                    name = station.n,
                    url = station.u,
                    country = country
                })
            end
        end
    end
end

include("rheadphones/config.lua")
LoadStationData() 