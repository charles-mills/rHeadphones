local PANEL = {}

local COLORS = rHeadphones.Config.colors

local STATUS = {
    STOPPED = {
        text = "Ready to Play",
        color = COLORS.accent,
        icon = "rammel/icons/pause.png",
        subtext = "Select a station to begin"
    },
    PLAYING = {text = "Playing", color = COLORS.success, icon = "rammel/icons/play.png"},
    TUNING = {
        text = "Tuning in...", 
        color = COLORS.warning, 
        icon = "rammel/icons/hourglass.png",
        subtext = "Establishing connection"
    },
    ERROR = {text = "Error", color = COLORS.error, icon = "rammel/icons/error.png"}
}

surface.CreateFont("rHeadphones_Header", {
    font = "Roboto",
    size = 40,
    weight = 700
})

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

local function GetRandomVibrantColor()
    local h = math.random()
    local s = 0.8
    local v = 1.0
    
    local hi = math.floor(h * 6)
    local f = h * 6 - hi
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    
    local r, g, b
    
    if hi == 0 then r, g, b = v, t, p
    elseif hi == 1 then r, g, b = q, v, p
    elseif hi == 2 then r, g, b = p, v, t
    elseif hi == 3 then r, g, b = p, q, v
    elseif hi == 4 then r, g, b = t, p, v
    else r, g, b = v, p, q end
    
    return Color(r * 255, g * 255, b * 255)
end

local function LerpColor(t, c1, c2)
    return Color(
        Lerp(t, c1.r, c2.r),
        Lerp(t, c1.g, c2.g),
        Lerp(t, c1.b, c2.b),
        Lerp(t, c1.a or 255, c2.a or 255)
    )
end

local function DrawGlowingIcon(material, x, y, size, color, glowSize, glowAlpha)
    for i = 3, 1, -1 do
        local currentSize = size + ((glowSize or 4) * i)
        surface.SetMaterial(material)
        surface.SetDrawColor(ColorAlpha(color, (glowAlpha or 20) / i))
        surface.DrawTexturedRect(x, y - 2, currentSize, currentSize)
    end

    surface.SetMaterial(material)
    surface.SetDrawColor(color)
    surface.DrawTexturedRect(x, y, size, size)
end

local function DrawCircularPattern(cx, cy, radius, color, segments, rotation, scale)
    segments = segments or 32
    scale = scale or 1
    
    for i = 1, segments do
        local angle1 = math.rad(i * (360 / segments) + (rotation or 0))
        local angle2 = math.rad((i + 1) * (360 / segments) + (rotation or 0))
        
        local x1 = cx + math.cos(angle1) * (radius * scale)
        local y1 = cy + math.sin(angle1) * (radius * scale)
        local x2 = cx + math.cos(angle2) * (radius * scale)
        local y2 = cy + math.sin(angle2) * (radius * scale)
        
        surface.SetDrawColor(color)
        surface.DrawLine(x1, y1, x2, y2)
    end
end

local function DrawProgressLine(x, y, width, color, progress, dotColor)
    -- Background line
    draw.RoundedBox(1, x, y, width, 2, ColorAlpha(color, 10))
    
    -- Progress dot
    local dotX = x + progress * width
    draw.RoundedBox(4, dotX - 2, y - 1, 4, 4, dotColor or color)
end

local function DrawTextWithShadow(text, font, x, y, color, alignX, alignY, shadowColor)
    shadowColor = shadowColor or Color(0, 0, 0, 100)
    draw.SimpleText(text, font, x, y + 1, shadowColor, alignX, alignY)
    draw.SimpleText(text, font, x, y, color, alignX, alignY)
end

local function DrawScaledText(text, font, x, y, w, h, color)
    local textW, textH
    surface.SetFont(font)
    textW, textH = surface.GetTextSize(text)
    
    -- Calculate scale factor to fit width and height
    local scaleW = (w * 0.8) / textW
    local scaleH = (h * 0.8) / textH
    local scale = math.min(scaleW, scaleH)
    
    local scaledFont = "rHeadphones_Scaled_" .. scale
    if not _G[scaledFont] then
        surface.CreateFont(scaledFont, {
            font = "Roboto",
            size = math.Round(select(2, surface.GetTextSize(text)) * scale),
            weight = 700,
            antialias = true
        })
    end
    
    draw.SimpleText(text, scaledFont, x, y, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function PANEL:Init()
    self:SetSize(700, 800)
    self:Center()
    self:SetTitle("")
    self:MakePopup()
    self:ShowCloseButton(false)
    self:DockPadding(0, 0, 0, 0)
    
    self.Paint = function(s, w, h)
        draw.RoundedBox(16, 0, 0, w, h, COLORS.background)
    end
    
    self.mainContainer = vgui.Create("DPanel", self)
    self.mainContainer:Dock(FILL)
    self.mainContainer:DockPadding(15, 15, 15, 15)
    self.mainContainer.Paint = function() end
    
    self:InitializeHeader()
    
    self.contentContainer = vgui.Create("DPanel", self.mainContainer)
    self.contentContainer:Dock(FILL)
    self.contentContainer:DockMargin(0, 15, 0, 0)
    self.contentContainer.Paint = function() end
    
    self:InitializeStatusPanel()
    self:InitializeSearchBar()
    self:InitializeCountryList()
    self:InitializeControls()
    
    self:RefreshCountries()
end

function PANEL:InitializeHeader()
    if IsValid(self.header) then
        self.header:Remove()
    end

    self.header = vgui.Create("DPanel", self)
    self.header:Dock(TOP)
    self.header:SetTall(60)
    self.header.Paint = function(s, w, h)
        draw.RoundedBoxEx(12, 0, 0, w, h, COLORS.header, true, true, false, false)
        surface.SetMaterial(Material("rammel/icons/earbuds.png"))
        surface.SetDrawColor(COLORS.text)
        surface.DrawTexturedRect(10, 10, 40, 40)
        draw.SimpleText("rHeadphones", "rHeadphones_Header", 60, h/2, COLORS.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    
    local headerButtons = vgui.Create("DPanel", self.header)
    headerButtons:Dock(RIGHT)
    headerButtons:SetWide(160)
    headerButtons.Paint = function() end
    
    self.closeBtn = vgui.Create("DButton", headerButtons)
    self.closeBtn:SetSize(50, 60)
    self.closeBtn:Dock(RIGHT)
    self.closeBtn:DockMargin(0, 0, 15, 0)
    self.closeBtn:SetText("")
    self.closeBtn.Paint = function(s, w, h)
        surface.SetMaterial(Material("rammel/icons/close.png"))
        surface.SetDrawColor(s:IsHovered() and COLORS.error or COLORS.text)
        surface.DrawTexturedRect(5, 10, 40, 40)
    end
    self.closeBtn.DoClick = function() self:Remove() end

    self.header.headerButtons = headerButtons
    hook.Run("rHeadphones_InitializeHeader", self.header)

    if self.currentCountry then
        self.backBtn = vgui.Create("DButton", headerButtons)
        self.backBtn:SetSize(50, 60)
        self.backBtn:Dock(RIGHT)
        self.backBtn:DockMargin(0, 0, 0, 0)
        self.backBtn:SetText("")
        self.backBtn.Paint = function(s, w, h)
            surface.SetMaterial(Material("rammel/icons/back.png"))
            surface.SetDrawColor(s:IsHovered() and COLORS.accent or COLORS.text)
            surface.DrawTexturedRect(5, 10, 40, 40)
        end
        self.backBtn.DoClick = function()
            self:RefreshCountries()
        end
    end
end

function PANEL:InitializeStatusPanel()
    if IsValid(self.status) then
        if self.analyzer then
        if self.analyzer then
            if type(self.analyzer.Remove) == "function" then
                self.analyzer:Remove()
            end
            self.analyzer = nil
        end
        
        self.status:Remove()
    end
    
    self.status = vgui.Create("DPanel", self.contentContainer)
    self.status:Dock(TOP)
    self.status:SetTall(100)
    self.status:DockMargin(0, 0, 0, 15)
    
    self.particles = {}
    self.analyzer = nil
    
    self.analyzer = nil
    
    local PARTICLE_LIFETIME = 3
    local MAX_PARTICLES = 25
    local SPAWN_RATE = 0.15
    local lastSpawn = 0
    
    self.status.Think = function()
        local status = rHeadphones.GetStatus()
        if status.state == "PLAYING" and IsValid(currentStation) then
            if not self.analyzer then
                timer.Simple(0.1, function()
                    if IsValid(currentStation) then
                        pcall(function()
                            self.analyzer = SoundAnalyze(currentStation)
                            currentStation:FFT({}, 6)
                        end)
                    end
                end)
            end
        else
            if self.analyzer then
                if type(self.analyzer.Remove) == "function" then
                    self.analyzer:Remove()
                end
                self.analyzer = nil
            end
        end
    end
    
    self.status.Paint = function(s, w, h)
        draw.RoundedBox(12, 0, 0, w, h, Color(25, 25, 25))
        
        local status = rHeadphones.GetStatus()
        local statusInfo = STATUS[status.state]
        local iconSize = 50
        
        if status.state == "STOPPED" then
            local floatOffset = math.sin(CurTime() * 1.5) * 3
            
            local patternTime = CurTime() * 0.2
            local patternPoints = {}
            local segments = 32
            local radius = 80
            
            for i = 1, segments do
                local angle1 = math.rad(i * (360 / segments) + patternTime)
                local angle2 = math.rad((i + 1) * (360 / segments) + patternTime)
                
                table.insert(patternPoints, {
                    x1 = 35 + math.cos(angle1) * radius,
                    y1 = h/2 + math.sin(angle1) * radius,
                    x2 = 35 + math.cos(angle2) * radius,
                    y2 = h/2 + math.sin(angle2) * radius
                })
            end
            
            surface.SetDrawColor(ColorAlpha(COLORS.accent, 20))
            for _, points in ipairs(patternPoints) do
                surface.DrawLine(points.x1, points.y1, points.x2, points.y2)
            end
            
            local glowColor = ColorAlpha(statusInfo.color, 20)
            surface.SetMaterial(Material(statusInfo.icon))
            
            surface.SetDrawColor(glowColor)
            surface.DrawTexturedRect(13, (h-iconSize)/2 - 4 + floatOffset, iconSize + 4, iconSize + 4)
            surface.DrawTexturedRect(17, (h-iconSize)/2 + floatOffset, iconSize - 4, iconSize - 4)
            
            surface.SetDrawColor(statusInfo.color)
            surface.DrawTexturedRect(15, (h-iconSize)/2 + floatOffset, iconSize, iconSize)
            
            DrawTextWithShadow(
                statusInfo.text,
                "rHeadphones_Title",
                80,
                h/2 - 12,
                statusInfo.color,
                TEXT_ALIGN_LEFT,
                TEXT_ALIGN_CENTER
            )
            
            local lineWidth = w - 160
            local lineX = 80
            local lineY = h - 20
            local progress = (math.sin(CurTime()) + 1) * 0.5
            
            draw.RoundedBox(1, lineX, lineY, lineWidth, 2, ColorAlpha(COLORS.accent, 10))
            draw.RoundedBox(4, lineX + progress * lineWidth - 2, lineY - 1, 4, 4, COLORS.accent)
        elseif status.state == "TUNING" then
            local rotation = CurTime() * 180
            local pulseScale = math.sin(CurTime() * 4) * 0.1 + 1.0
            
            local accentColor = ColorAlpha(COLORS.warning, 20)
            local circleRadius = 80
            local cx, cy = 35, h/2
            
            for i = 1, 3 do
                local radius = (circleRadius - (i * 15)) * pulseScale
                local segments = 32
                local startAngle = CurTime() * (0.2 * i) + rotation
                
                for j = 1, segments do
                    local angle1 = math.rad(j * (360 / segments) + startAngle)
                    local angle2 = math.rad((j + 1) * (360 / segments) + startAngle)
                    
                    local x1, y1 = cx + math.cos(angle1) * radius, cy + math.sin(angle1) * radius
                    local x2, y2 = cx + math.cos(angle2) * radius, cy + math.sin(angle2) * radius
                    
                    surface.SetDrawColor(accentColor)
                    surface.DrawLine(x1, y1, x2, y2)
                end
            end
            
            local x = 15 + iconSize/2
            local y = (h-iconSize)/2 + iconSize/2
            
            for i = 3, 1, -1 do
                local glowSize = iconSize + (i * 4 * pulseScale)
                surface.SetMaterial(Material(statusInfo.icon))
                surface.SetDrawColor(ColorAlpha(statusInfo.color, 20 / i))
                surface.DrawTexturedRectRotated(x, y - 2, glowSize, glowSize, rotation)
            end
            
            surface.SetDrawColor(statusInfo.color)
            surface.DrawTexturedRectRotated(x, y, iconSize, iconSize, rotation)
            
            draw.SimpleText(statusInfo.text, "rHeadphones_Title", 80, h/2 - 12, statusInfo.color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(statusInfo.subtext, "rHeadphones_Regular", 80, h/2 + 12, COLORS.textDark, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            
            local lineWidth = w - 160
            local lineX = 80
            local lineY = h - 20
            draw.RoundedBox(1, lineX, lineY, lineWidth, 2, ColorAlpha(COLORS.warning, 10))
            
            local dotProgress = (CurTime() % 2) / 2
            local dotX = lineX + dotProgress * lineWidth
            draw.RoundedBox(4, dotX - 2, lineY - 1, 4, 4, COLORS.warning)
        else
            local iconSize = 50
            
            if self.analyzer then
                local bassIntensity = self.analyzer:GetSoundPower(1, 10) or 0
                local pulseScale = bassIntensity * 0.5 + 1.0
                
                for i = 1, 3 do
                    local radius = (80 - (i * 15)) * pulseScale
                    local segments = 32
                    local startAngle = CurTime() * (0.2 * i)
                    
                    DrawCircularPattern(35, h/2, radius, ColorAlpha(COLORS.success, 20), segments, startAngle)
                end
            end
            
            local bounceOffset = math.sin(CurTime() * 2) * 2
            DrawGlowingIcon(
                Material(statusInfo.icon),
                15,
                (h-iconSize)/2 + bounceOffset,
                iconSize,
                statusInfo.color,
                4,
                30
            )
            
            DrawTextWithShadow(
                statusInfo.text,
                "rHeadphones_Title",
                80,
                h/2 - 15,
                statusInfo.color,
                TEXT_ALIGN_LEFT,
                TEXT_ALIGN_CENTER
            )
            
            if status.station then
                DrawTextWithShadow(
                    status.station.name,
                    "rHeadphones_Title",
                    80,
                    h/2 + 15,
                    COLORS.text,
                    TEXT_ALIGN_LEFT,
                    TEXT_ALIGN_CENTER
                )
                
                local formattedCountry = rHeadphones.FormatCountryName(status.station.country)
                local countryAlpha = math.abs(math.sin(CurTime())) * 100 + 155
                draw.SimpleText(
                    formattedCountry,
                    "rHeadphones_Regular",
                    w - 20,
                    h/2 + 15,
                    ColorAlpha(COLORS.textDark, countryAlpha),
                    TEXT_ALIGN_RIGHT,
                    TEXT_ALIGN_CENTER
                )
                
                if self.analyzer then
                    local lineWidth = w - 160
                    local lineX = 80
                    local lineY = h - 20
                    
                    draw.RoundedBox(1, lineX, lineY, lineWidth, 2, ColorAlpha(COLORS.success, 10))
                    
                    local segmentCount = 48
                    local segmentWidth = lineWidth / segmentCount
                    
                    for i = 1, segmentCount do
                        local fftValue = (self.analyzer:GetFFT()[i] or 0) * 2
                        local height = math.Clamp(fftValue * 25, 2, 25)
                        
                        draw.RoundedBox(
                            0,
                            lineX + (i-1) * segmentWidth,
                            lineY,  -- Start at line position
                            segmentWidth - 1,
                            height,  -- Extend downward
                            ColorAlpha(COLORS.success, 150)
                        )
                    end
                end
            end
        end
    end
end

local function HSVToColor(h, s, v)
    if not h or not s or not v then return Color(255, 255, 255) end
    
    h = h % 360
    h = h / 360
    
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    
    i = i % 6
    
    local r, g, b = 0, 0, 0
    
    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q end
    
    return Color(r * 255, g * 255, b * 255)
end

function PANEL:InitializeSearchBar()
    self.search = vgui.Create("DTextEntry", self.contentContainer)
    self.search:Dock(TOP)
    self.search:DockMargin(0, 0, 0, 15)
    self.search:SetTall(45)
    self.search:SetFont("rHeadphones_Regular")
    self.search:SetPlaceholderText("Search countries or stations...")
    self.search:SetPlaceholderColor(COLORS.textDark)
    self.search:SetTextColor(COLORS.text)
    self.search:SetPaintBackground(false)

    self.search.focused = false
    self.search.animStart = 0
    self.search.animDuration = 0.2
    
    self.search.Paint = function(s, w, h)
        local progress = 1
        if s.animStart > 0 then
            progress = math.Clamp((SysTime() - s.animStart) / s.animDuration, 0, 1)
            if s.focused then
                progress = 1 - (1 - progress) * (1 - progress)
            else
                progress = progress * progress
            end
        end
        
        local padding = s.focused and Lerp(progress, 0, 4) or Lerp(progress, 4, 0)
        draw.RoundedBox(12, padding, padding, w - padding * 2, h - padding * 2, Color(25, 25, 25))
        
        if s.focused then
            local alpha = math.floor(255 * progress)
            surface.SetDrawColor(ColorAlpha(COLORS.accent, alpha * 0.5))
            draw.RoundedBox(12, 0, 0, w, h, ColorAlpha(COLORS.accent, alpha * 0.15))
        end
        
        surface.SetMaterial(Material("rammel/icons/search.png"))
        local iconColor = s.focused and COLORS.accent or COLORS.textDark
        if s.animStart > 0 then
            iconColor = s.focused and 
                LerpColor(progress, COLORS.textDark, COLORS.accent) or 
                LerpColor(progress, COLORS.accent, COLORS.textDark)
        end
        surface.SetDrawColor(iconColor)
        surface.DrawTexturedRect(15, (h-20)/2, 20, 20)
        
        s:SetTextInset(45, 0)
        
        if s:GetText() == "" then
            draw.SimpleText(s:GetPlaceholderText(), "rHeadphones_Regular", 45, h/2, COLORS.textDark, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        else
            local textColor = s:IsEditing() and COLORS.accent or COLORS.text
            s:DrawTextEntryText(textColor, COLORS.accent, COLORS.text)
        end
    end
    
    self.search.OnGetFocus = function(s)
        s.focused = true
        s.animStart = SysTime()
        self.isSearching = true
    end
    
    self.search.OnLoseFocus = function(s)
        s.focused = false
        s.animStart = SysTime()
        self.isSearching = false
    end
    
    self.search.OnChange = function()
        if self.currentCountry then
            self:RefreshStations(self.currentCountry)
        else
            self:RefreshCountries()
        end
    end
end

function PANEL:InitializeCountryList()
    self.countryList = vgui.Create("DScrollPanel", self.contentContainer)
    self.countryList:Dock(FILL)
    self.countryList:DockMargin(0, 0, 0, 10)
    
    local sbar = self.countryList:GetVBar()
    sbar:SetWide(8)
    sbar:SetHideButtons(true)
    
    sbar.Paint = function(_, w, h)
        draw.RoundedBox(2, 0, 0, w, h, ColorAlpha(COLORS.searchBg, 50))
    end
    
    sbar.btnGrip.Paint = function(s, w, h)
        local alpha = s:IsHovered() and 180 or 120
        local gripColor = ColorAlpha(COLORS.accent, alpha)
        
        if s.lastAlpha ~= alpha then
            s.lastAlpha = s.lastAlpha or alpha
            s.lastAlpha = Lerp(FrameTime() * 10, s.lastAlpha, alpha)
            gripColor = ColorAlpha(COLORS.accent, s.lastAlpha)
        end
        
        draw.RoundedBox(2, 0, 0, w, h, gripColor)
    end
    
    sbar.btnUp.Paint = function() end
    sbar.btnDown.Paint = function() end
end

function PANEL:InitializeControls()
    self.controls = vgui.Create("DPanel", self.contentContainer)
    self.controls:Dock(BOTTOM)
    self.controls:SetTall(90)
    self.controls:DockMargin(0, 0, 0, 0)
    self.controls.Paint = function(s, w, h)
        draw.RoundedBox(12, 0, 0, w, h, COLORS.statusBg)
    end
    
    local stopBtn = vgui.Create("DButton", self.controls)
    stopBtn:SetSize(160, 70)
    stopBtn:Dock(LEFT)
    stopBtn:DockMargin(15, 10, 0, 10)
    stopBtn:SetText("")
    stopBtn.Paint = function(s, w, h)
        local bgColor = s:IsHovered() and COLORS.buttonHover or COLORS.button
        draw.RoundedBox(8, 0, 0, w, h, bgColor)
        
        if s:IsHovered() then
            surface.SetDrawColor(ColorAlpha(COLORS.accent, 30))
            draw.RoundedBox(8, 0, 0, w, h, ColorAlpha(COLORS.accent, 30))
        end
        
        DrawScaledText("STOP", "rHeadphones_Regular", w/2, h/2, w, h, COLORS.text)
    end
    stopBtn.DoClick = function() rHeadphones.StopPlayback() end
    
    local divider = vgui.Create("DPanel", self.controls)
    divider:SetWide(2)
    divider:Dock(LEFT)
    divider:DockMargin(15, 15, 15, 15)
    divider.Paint = function(s, w, h)
        draw.RoundedBox(1, 0, 0, w, h, ColorAlpha(COLORS.text, 10))
    end
    
    local volumeContainer = vgui.Create("DPanel", self.controls)
    volumeContainer:Dock(FILL)
    volumeContainer:DockMargin(0, 10, 15, 10)
    volumeContainer.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, ColorAlpha(COLORS.button, 50))
    end
    
    local isDragging = false
    local slideX = rHeadphones.Config.defaultVolume / rHeadphones.Config.maxVolume
    
    local volumeIcon = vgui.Create("DPanel", volumeContainer)
    volumeIcon:SetSize(60, 60)
    volumeIcon:Dock(LEFT)
    volumeIcon:DockMargin(15, -5, 20, -5)
    volumeIcon.Paint = function(s, w, h)
        local icon = "rammel/icons/volume_mute.png"
        if slideX > 0.66 then
            icon = "rammel/icons/volume_full.png"
        elseif slideX > 0.33 then
            icon = "rammel/icons/volume_down.png"
        end
        
        surface.SetMaterial(Material(icon))
        surface.SetDrawColor(COLORS.text)
        surface.DrawTexturedRect(0, 0, w, h)
    end
    
    self.volumeSlider = vgui.Create("DPanel", volumeContainer)
    self.volumeSlider:Dock(FILL)
    self.volumeSlider:DockMargin(0, 15, 40, 15)
    
    self.volumeSlider.GetSlideX = function()
        return slideX
    end
    
    self.volumeSlider.Paint = function(s, w, h)
        local sliderY = h/2
        local sliderHeight = 6
        local knobSize = 18
        
        draw.RoundedBox(sliderHeight/2, 0, sliderY - sliderHeight/2, w, sliderHeight, ColorAlpha(COLORS.button, 120))
        
        local fillWidth = w * slideX
        draw.RoundedBox(sliderHeight/2, 0, sliderY - sliderHeight/2, fillWidth, sliderHeight, COLORS.accent)
        
        local knobX = fillWidth - knobSize/2
        local knobY = sliderY - knobSize/2
        local knobColor = (isDragging or s:IsHovered()) and COLORS.accent or COLORS.text
        
        draw.RoundedBox(knobSize/2, knobX + 1, knobY + 1, knobSize, knobSize, ColorAlpha(Color(0, 0, 0), 50))
        draw.RoundedBox(knobSize/2, knobX, knobY, knobSize, knobSize, knobColor)
        
        local textColor = s:IsHovered() and COLORS.accent or COLORS.text
        draw.SimpleText(math.floor(slideX * 100) .. "%", "rHeadphones_Regular", w + 30, sliderY, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    
    self.volumeSlider.OnMousePressed = function(s, keyCode)
        if keyCode == MOUSE_LEFT then
            isDragging = true
            s:MouseCapture(true)
            s:OnCursorMoved(s:CursorPos())
        end
    end
    
    self.volumeSlider.OnMouseReleased = function(s, keyCode)
        if keyCode == MOUSE_LEFT then
            isDragging = false
            s:MouseCapture(false)
        end
    end
    
    self.volumeSlider.OnCursorMoved = function(s, x, y)
        if isDragging then
            local newX = math.Clamp(x / s:GetWide(), 0, 1)
            slideX = newX
            rHeadphones.SetVolume(newX * rHeadphones.Config.maxVolume)
        end
    end
end

function PANEL:RefreshCountries()
    self.countryList:Clear()
    self.currentCountry = nil
    self:InitializeHeader()
    
    if IsValid(self.search) then
        self.search:SetValue("")
    end
    
    local favoriteCountries = {}
    local regularCountries = {}
    
    for country, _ in pairs(rHeadphones.Stations) do
        local formattedCountry = rHeadphones.FormatCountryName(country)
        if rHeadphones.Favorites.IsCountryFavorite(country) then
            table.insert(favoriteCountries, {raw = country, formatted = formattedCountry})
        else
            table.insert(regularCountries, {raw = country, formatted = formattedCountry})
        end
    end
    
    table.sort(favoriteCountries, function(a, b) return a.formatted < b.formatted end)
    table.sort(regularCountries, function(a, b) return a.formatted < b.formatted end)
    
    local allCountries = {}
    for _, country in ipairs(favoriteCountries) do
        table.insert(allCountries, country)
    end
    for _, country in ipairs(regularCountries) do
        table.insert(allCountries, country)
    end
    
    local favButton = self:CreateCountryButton("Favorite Stations", true)
    favButton.star:SetTextColor(COLORS.star)
    self.countryList:AddItem(favButton)
    
    for _, countryData in ipairs(allCountries) do
        self.countryList:AddItem(self:CreateCountryButton(countryData.raw, false, countryData.formatted))
    end
end

function PANEL:CreateCountryButton(country, isFavorite, formattedName)
    local button = vgui.Create("DButton")
    button:SetTall(50)
    button:Dock(TOP)
    button:DockMargin(10, 0, 18, 2)
    button:SetText("")
    
    button.star = vgui.Create("DButton", button)
    button.star:SetSize(50, 50)
    button.star:Dock(LEFT)
    button.star:SetText("")
    button.star.Paint = function(s, w, h)
        local isFav = isFavorite or rHeadphones.Favorites.IsCountryFavorite(country)
        local color = isFav and COLORS.star or COLORS.starInactive
        draw.SimpleText("★", "rHeadphones_Title", w/2, h/2, s:IsHovered() and COLORS.star or color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    button.star.DoClick = function(s)
        if not isFavorite then
            rHeadphones.Favorites.ToggleCountry(country)
            s:GetParent():GetParent():GetParent():RefreshCountries()
        end
    end
    
    button.Paint = function(s, w, h)
        local bgColor = s:IsHovered() and COLORS.listHover or COLORS.listBg
        draw.RoundedBox(8, 0, 0, w, h, bgColor)
        draw.SimpleText(formattedName or country, "rHeadphones_Regular", 60, h/2, COLORS.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    
    button.DoClick = function()
        if isFavorite then
            self:ShowStations("Favorite Stations")
        else
            self:ShowStations(country)
        end
    end
    
    button:SetTooltip(formattedName or country)
    
    return button
end

function PANEL:ShowStations(country)
    self.countryList:Clear()
    self.currentCountry = country
    self:InitializeHeader()
    
    if IsValid(self.search) then
        self.search:SetValue("")
    end
    
    if country == "Favorite Stations" then
        local stations = rHeadphones.Favorites.GetFavoriteStations()
        if #stations == 0 then
            local label = vgui.Create("DLabel")
            label:SetText("No favorite stations yet")
            label:SetFont("rHeadphones_Regular")
            label:SetTextColor(COLORS.textDark)
            label:SetContentAlignment(5)
            label:SetTall(50)
            label:Dock(TOP)
            label:DockMargin(0, 10, 0, 0)
            self.countryList:AddItem(label)
            return
        else
            table.sort(stations, function(a, b)
                if a.country == b.country then
                    return a.name < b.name
                end
                return rHeadphones.FormatCountryName(a.country) < rHeadphones.FormatCountryName(b.country)
            end)
            
            local currentCountry = ""
            for _, station in ipairs(stations) do
                if currentCountry ~= station.country then
                    currentCountry = station.country
                    local countryLabel = vgui.Create("DLabel")
                    countryLabel:SetText(rHeadphones.FormatCountryName(station.country))
                    countryLabel:SetFont("rHeadphones_Title")
                    countryLabel:SetTextColor(COLORS.textDark)
                    countryLabel:SetTall(30)
                    countryLabel:Dock(TOP)
                    countryLabel:DockMargin(10, 10, 0, 5)
                    self.countryList:AddItem(countryLabel)
                end
                
                self:AddStationButton(station, country)
            end
        end
    else
        self:RefreshStations(country)
    end
end

function PANEL:AddStationButton(station, country)
    local button = vgui.Create("DButton")
    button:SetTall(50)
    button:Dock(TOP)
    button:DockMargin(10, 0, 18, 2)
    button:SetText("")
    
    button.star = vgui.Create("DButton", button)
    button.star:SetSize(50, 50)
    button.star:Dock(LEFT)
    button.star:SetText("")
    button.star.Paint = function(s, w, h)
        local isFav = rHeadphones.Favorites.IsStationFavorite(station)
        local color = isFav and COLORS.star or COLORS.starInactive
        draw.SimpleText("★", "rHeadphones_Title", w/2, h/2, s:IsHovered() and COLORS.star or color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    button.star.DoClick = function()
        rHeadphones.Favorites.ToggleStation(station)
        if country == "Favorite Stations" then
            timer.Simple(0, function()
                self:ShowStations(country)
            end)
        end
    end
    
    button.Paint = function(s, w, h)
        local bgColor = s:IsHovered() and COLORS.listHover or COLORS.listBg
        local status = rHeadphones.GetStatus()
        if status.station and status.station.name == station.name and status.station.country == station.country then
            bgColor = COLORS.nowPlaying
        end
        draw.RoundedBox(8, 0, 0, w, h, bgColor)
        draw.SimpleText(station.name, "rHeadphones_Regular", 60, h/2, COLORS.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        
        if country == "Favorite Stations" then
            local formattedCountry = rHeadphones.FormatCountryName(station.country)
            draw.SimpleText(formattedCountry, "rHeadphones_Regular", w - 10, h/2, COLORS.textDark, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end
    
    button.DoClick = function()
        rHeadphones.PlayStation(station)
        self:SmoothScrollTo(button)
    end
    
    button:SetTooltip(station.name)
    
    self.countryList:AddItem(button)
end

function PANEL:RefreshStations(country)
    self.countryList:Clear()
    
    local searchText = self.search:GetValue():lower()
    local stations = rHeadphones.Stations[country]
    
    if not stations then return end
    
    local favoriteStations = {}
    local regularStations = {}
    
    for _, station in ipairs(stations) do
        if searchText == "" or station.name:lower():find(searchText, 1, true) then
            if rHeadphones.Favorites.IsStationFavorite(station) then
                table.insert(favoriteStations, station)
            else
                table.insert(regularStations, station)
            end
        end
    end
    
    table.sort(favoriteStations, function(a, b) return a.name < b.name end)
    table.sort(regularStations, function(a, b) return a.name < b.name end)
    
    for _, station in ipairs(favoriteStations) do
        self:AddStationButton(station, country)
    end
    for _, station in ipairs(regularStations) do
        self:AddStationButton(station, country)
    end
end

function PANEL:SmoothScrollTo(panel)
    local _, y = panel:GetPos()
    local targetY = y - self.countryList:GetTall() / 2 + panel:GetTall() / 2
    
    local startY = self.countryList:GetVBar():GetScroll()
    local distance = targetY - startY
    local duration = 0.3
    local startTime = SysTime()
    
    timer.Create("SmoothScroll", 0, 0, function()
        local t = (SysTime() - startTime) / duration
        if t >= 1 then
            self.countryList:GetVBar():SetScroll(targetY)
            timer.Remove("SmoothScroll")
        else
            local ease = 1 - (1 - t) * (1 - t)
            self.countryList:GetVBar():SetScroll(startY + distance * ease)
        end
    end)
end

vgui.Register("rHeadphones_Menu", PANEL, "DFrame")

function rHeadphones.OpenMenu()
    if IsValid(rHeadphones.Menu) then
        if not rHeadphones.Menu.isSearching then
            rHeadphones.Menu:Remove()
        end
    else
        rHeadphones.Menu = vgui.Create("rHeadphones_Menu")
    end
end

hook.Add("Think", "rHeadphones_MenuBind", function()
    if input.IsKeyDown(rHeadphones.Config.hotkey) and not rHeadphones.keyPressed then
        rHeadphones.keyPressed = true
        rHeadphones.OpenMenu()
    elseif not input.IsKeyDown(rHeadphones.Config.hotkey) then
        rHeadphones.keyPressed = false
    end
end) 

function PANEL:OnRemove()
    if self.analyzer then
        if type(self.analyzer.Remove) == "function" then
            self.analyzer:Remove()
        end
        self.analyzer = nil
    end
    
    if timer.Exists("SmoothScroll") then
        timer.Remove("SmoothScroll")
    end
end