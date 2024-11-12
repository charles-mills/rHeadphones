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

-- Color settings
rHeadphones.Config.colors = {
    background = Color(18, 18, 18),
    header = Color(24, 24, 24),
    accent = Color(66, 165, 245),
    text = Color(255, 255, 255),
    textDark = Color(170, 170, 170),
    button = Color(38, 38, 38),
    buttonHover = Color(48, 48, 48),
    buttonActive = Color(66, 165, 245),
    searchBg = Color(30, 30, 30),
    star = Color(255, 193, 7),
    starInactive = Color(100, 100, 100),
    success = Color(76, 175, 80),
    error = Color(244, 67, 54),
    warning = Color(255, 152, 0),
    statusBg = Color(24, 24, 24),
    listBg = Color(24, 24, 24),
    listHover = Color(38, 38, 38),
    nowPlaying = Color(66, 165, 245, 100)
}