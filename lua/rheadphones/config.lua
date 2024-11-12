rHeadphones.Config = rHeadphones.Config or {}

-- Core settings
rHeadphones.Config.hotkey = KEY_H -- Change the hotkey to open radio
rHeadphones.Config.defaultVolume = 0.5 -- Default volume (0-1)
rHeadphones.Config.maxVolume = 1.0 -- Maximum volume limit
rHeadphones.Config.fadeTime = 0.5 -- Fade effect duration in seconds

-- UI settings
rHeadphones.Config.ui = {
    width = 500,
    height = 600,
    buttonHeight = 30,
    margin = 5
}

-- Sound settings
rHeadphones.Config.sounds = {
    play = "items/battery_pickup.wav",
    stop = "items/battery_pickup.wav",
    playVolume = 0.3,
    stopVolume = 0.3,
    playPitch = 100,
    stopPitch = 85
}