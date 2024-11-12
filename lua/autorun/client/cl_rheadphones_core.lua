rHeadphones = rHeadphones or {}

local currentStation = nil
local isPlaying = false
local currentVolume = 0.5
local currentStatus = "STOPPED"
local currentStationData = nil

function rHeadphones.CreateChannel()
    if IsValid(rHeadphones.Channel) then
        rHeadphones.Channel:Stop()
        rHeadphones.Channel = nil
    end
    
    rHeadphones.Channel = CreateSound(LocalPlayer(), "")
    return rHeadphones.Channel
end

function rHeadphones.PlayStation(stationData)
    if not stationData or not stationData.url then return end
    
    if currentStation then
        rHeadphones.StopPlayback()
    end
    
    currentStatus = "TUNING"
    currentStationData = stationData
    
    sound.PlayURL(stationData.url, "noblock noplay", function(station, errorID, errorName)
        if IsValid(station) then
            currentStation = station
            station:SetVolume(currentVolume)
            station:Play()
            isPlaying = true
            currentStatus = "PLAYING"

            if rHeadphones.Config and rHeadphones.Config.sounds then
                LocalPlayer():EmitSound(
                    rHeadphones.Config.sounds.play or "items/battery_pickup.wav",
                    75,
                    rHeadphones.Config.sounds.playPitch or 100,
                    rHeadphones.Config.sounds.playVolume or 0.3
                )
            end
        else
            currentStatus = "ERROR"
            notification.AddLegacy("Error loading station: " .. (errorName or "Unknown error"), NOTIFY_ERROR, 3)
        end
    end)
end

function rHeadphones.StopPlayback()
    if currentStation then
        currentStation:Stop()
        currentStation = nil
        isPlaying = false
        currentStatus = "STOPPED"
        currentStationData = nil
        
        -- Play sound effect with error handling
        if rHeadphones.Config and rHeadphones.Config.sounds then
            LocalPlayer():EmitSound(
                rHeadphones.Config.sounds.stop or "items/battery_pickup.wav",
                75,
                rHeadphones.Config.sounds.stopPitch or 85,
                rHeadphones.Config.sounds.stopVolume or 0.3
            )
        end
    end
end

function rHeadphones.SetVolume(volume)
    if not rHeadphones.Config then return end
    
    volume = math.Clamp(volume, 0, rHeadphones.Config.maxVolume)
    currentVolume = volume
    
    if currentStation then
        currentStation:SetVolume(volume)
    end
end

hook.Add("InitPostEntity", "rHeadphones_InitVolume", function()
    if rHeadphones.Config then
        currentVolume = rHeadphones.Config.defaultVolume
    end
end)

function rHeadphones.GetStatus()
    return {
        state = currentStatus,
        station = currentStationData
    }
end

function rHeadphones.TogglePlayPause()
    if currentStatus == "PLAYING" then
        rHeadphones.StopPlayback()
    elseif currentStatus == "STOPPED" and currentStationData then
        rHeadphones.PlayStation(currentStationData)
    end
end

concommand.Add("rheadphones_toggle", function()
    rHeadphones.TogglePlayPause()
end)