local PANEL = {}

local COLORS = {
    background = Color(30, 30, 30),
    header = Color(40, 40, 40),
    accent = Color(52, 152, 219),
    text = Color(236, 240, 241),
    textDark = Color(189, 195, 199),
    button = Color(44, 62, 80),
    buttonHover = Color(52, 73, 94),
    buttonActive = Color(41, 128, 185),
    searchBg = Color(50, 50, 50),
    star = Color(241, 196, 15),
    starInactive = Color(127, 140, 141),
    success = Color(46, 204, 113),
    error = Color(231, 76, 60),
    warning = Color(241, 196, 15),
    statusBg = Color(35, 35, 35)
}

local STATUS = {
    STOPPED = {text = "Stopped", color = COLORS.textDark, icon = "rammel/icons/pause.png"},
    PLAYING = {text = "Playing", color = COLORS.success, icon = "rammel/icons/play.png"},
    TUNING = {text = "Tuning in...", color = COLORS.warning, icon = "rammel/icons/hourglass.png"},
    ERROR = {text = "Error", color = COLORS.error, icon = "rammel/icons/error.png"}
}

surface.CreateFont("US_Heavy", {
    font = "us_heavy",
    size = 24,
    weight = 700
})

surface.CreateFont("US_Reg", {
    font = "us_reg",
    size = 18,
    weight = 500
})

function PANEL:Init()
    self:SetSize(700, 800)
    self:Center()
    self:SetTitle("")
    self:MakePopup()
    self:ShowCloseButton(false)
    
    self.Paint = function(s, w, h)
        draw.RoundedBox(12, 0, 0, w, h, COLORS.background)
    end
    
    self:InitializeHeader()
    self:InitializeStatusPanel()
    self:InitializeSearchBar()
    self:InitializeCountryList()
    self:InitializeControls()
    
    self:RefreshCountries()
end

function PANEL:InitializeHeader()
    self.header = vgui.Create("DPanel", self)
    self.header:Dock(TOP)
    self.header:SetTall(60)
    self.header.Paint = function(s, w, h)
        draw.RoundedBoxEx(12, 0, 0, w, h, COLORS.header, true, true, false, false)
        surface.SetMaterial(Material("rammel/icons/earbuds.png"))
        surface.SetDrawColor(COLORS.text)
        surface.DrawTexturedRect(10, 10, 40, 40)
        draw.SimpleText("rHeadphones Radio", "US_Heavy", 60, h/2, COLORS.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    
    local headerButtons = vgui.Create("DPanel", self.header)
    headerButtons:Dock(RIGHT)
    headerButtons:SetWide(100)
    headerButtons.Paint = function() end
    
    self.settingsBtn = vgui.Create("DButton", headerButtons)
    self.settingsBtn:SetSize(50, 60)
    self.settingsBtn:Dock(LEFT)
    self.settingsBtn:SetText("")
    self.settingsBtn.Paint = function(s, w, h)
        surface.SetMaterial(Material("rammel/icons/cogs.png"))
        surface.SetDrawColor(s:IsHovered() and COLORS.accent or COLORS.text)
        surface.DrawTexturedRect(5, 10, 40, 40)
    end
    
    self.closeBtn = vgui.Create("DButton", headerButtons)
    self.closeBtn:SetSize(50, 60)
    self.closeBtn:Dock(RIGHT)
    self.closeBtn:SetText("")
    self.closeBtn.Paint = function(s, w, h)
        surface.SetMaterial(Material("rammel/icons/close.png"))
        surface.SetDrawColor(s:IsHovered() and COLORS.error or COLORS.text)
        surface.DrawTexturedRect(5, 10, 40, 40)
    end
    self.closeBtn.DoClick = function() self:Remove() end
end

function PANEL:InitializeStatusPanel()
    self.status = vgui.Create("DPanel", self)
    self.status:Dock(TOP)
    self.status:SetTall(100)
    self.status:DockMargin(10, 10, 10, 0)
    self.status.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, COLORS.statusBg)
        
        local status = rHeadphones.GetStatus()
        local statusInfo = STATUS[status.state]
        
        surface.SetMaterial(Material(statusInfo.icon))
        surface.SetDrawColor(statusInfo.color)
        surface.DrawTexturedRect(10, 20, 60, 60)
        
        local textX = math.sin(CurTime() * 2) * 5 + 80
        draw.SimpleText(statusInfo.text, "US_Reg", textX, h/2, statusInfo.color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        
        if status.station then
            draw.SimpleText(status.station.name, "US_Heavy", 80, h/2 + 20, COLORS.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            local formattedCountry = rHeadphones.FormatCountryName(status.station.country)
            draw.SimpleText(formattedCountry, "US_Reg", w - 20, h/2 + 20, COLORS.textDark, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end
end

function PANEL:InitializeSearchBar()
    self.search = vgui.Create("DTextEntry", self)
    self.search:Dock(TOP)
    self.search:DockMargin(10, 10, 10, 10)
    self.search:SetTall(50)
    self.search:SetFont("US_Reg")
    self.search:SetPlaceholderText("Search countries or stations...")
    self.search:SetPlaceholderColor(COLORS.textDark)
    self.search:SetTextColor(COLORS.text)
    self.search:SetPaintBackground(false)
    self.search.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, COLORS.searchBg)
        
        surface.SetMaterial(Material("rammel/icons/search.png"))
        surface.SetDrawColor(COLORS.accent)
        surface.DrawTexturedRect(10, 15, 20, 20)
        
        s:SetTextInset(40, 0)
        
        if s:GetText() == "" then
            draw.SimpleText(s:GetPlaceholderText(), "US_Reg", 40, h/2, COLORS.textDark, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        else
            local textColor = s:IsEditing() and COLORS.accent or COLORS.text
            s:DrawTextEntryText(textColor, COLORS.accent, COLORS.text)
        end
    end
    
    self.search.OnGetFocus = function() self.isSearching = true end
    self.search.OnLoseFocus = function() self.isSearching = false end
    
    self.search.OnChange = function()
        if self.currentCountry then
            self:RefreshStations(self.currentCountry)
        else
            self:RefreshCountries()
        end
    end
end

function PANEL:InitializeCountryList()
    self.countryList = vgui.Create("DScrollPanel", self)
    self.countryList:Dock(FILL)
    self.countryList:DockMargin(10, 0, 10, 10)
    
    local sbar = self.countryList:GetVBar()
    sbar:SetWide(8)
    sbar.Paint = function(_, w, h) draw.RoundedBox(4, 0, 0, w, h, COLORS.searchBg) end
    sbar.btnUp.Paint = function() end
    sbar.btnDown.Paint = function() end
    sbar.btnGrip.Paint = function(_, w, h) draw.RoundedBox(4, 0, 0, w, h, COLORS.accent) end
end

function PANEL:InitializeControls()
    self.controls = vgui.Create("DPanel", self)
    self.controls:Dock(BOTTOM)
    self.controls:SetTall(70)
    self.controls:DockMargin(10, 0, 10, 10)
    self.controls.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, COLORS.statusBg)
    end
    
    local stopBtn = vgui.Create("DButton", self.controls)
    stopBtn:SetSize(120, 50)
    stopBtn:Dock(LEFT)
    stopBtn:DockMargin(10, 10, 10, 10)
    stopBtn:SetText("")
    stopBtn.Paint = function(s, w, h)
        local bgColor = s:IsHovered() and COLORS.buttonHover or COLORS.button
        draw.RoundedBox(8, 0, 0, w, h, bgColor)
        draw.SimpleText("STOP", "US_Reg", w/2, h/2, COLORS.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    stopBtn.DoClick = function() rHeadphones.StopPlayback() end
    
    self.volumeSlider = vgui.Create("DSlider", self.controls)
    self.volumeSlider:Dock(FILL)
    self.volumeSlider:DockMargin(0, 10, 40, 10)
    self.volumeSlider:SetSlideX(rHeadphones.Config.defaultVolume / rHeadphones.Config.maxVolume)
    self.volumeSlider.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, h/2-2, w, 4, COLORS.button)
        draw.RoundedBox(4, 0, h/2-2, w * s:GetSlideX(), 4, COLORS.accent)
        
        local volumeIcon = "rammel/icons/volume_mute.png"
        if s:GetSlideX() > 0.66 then
            volumeIcon = "rammel/icons/volume_full.png"
        elseif s:GetSlideX() > 0.33 then
            volumeIcon = "rammel/icons/volume_down.png"
        end
        
        surface.SetMaterial(Material(volumeIcon))
        surface.SetDrawColor(COLORS.text)
        surface.DrawTexturedRect(w - 30, h/2 - 10, 20, 20)
    end
    self.volumeSlider.OnValueChanged = function(s, value)
        rHeadphones.SetVolume(value * rHeadphones.Config.maxVolume)
    end
end

function PANEL:RefreshCountries()
    self.countryList:Clear()
    self.currentCountry = nil
    
    local searchText = self.search:GetValue():lower()
    local countries = {}
    
    for country, _ in pairs(rHeadphones.Stations) do
        local formattedCountry = rHeadphones.FormatCountryName(country)
        if searchText == "" or formattedCountry:lower():find(searchText, 1, true) then
            table.insert(countries, {
                raw = country,
                formatted = formattedCountry
            })
        end
    end
    
    table.sort(countries, function(a, b) 
        return a.formatted < b.formatted 
    end)
    
    local favButton = self:CreateCountryButton("Favorite Stations", true)
    favButton.star:SetTextColor(COLORS.star)
    self.countryList:AddItem(favButton)
    
    for _, countryData in ipairs(countries) do
        self.countryList:AddItem(self:CreateCountryButton(countryData.raw, false, countryData.formatted))
    end
end

function PANEL:CreateCountryButton(country, isFavorite, formattedName)
    local button = vgui.Create("DButton")
    button:SetTall(50)
    button:Dock(TOP)
    button:DockMargin(0, 0, 0, 2)
    button:SetText("")
    
    button.star = vgui.Create("DButton", button)
    button.star:SetSize(50, 50)
    button.star:Dock(LEFT)
    button.star:SetText("")
    button.star.Paint = function(s, w, h)
        local isFav = isFavorite or rHeadphones.Favorites.IsCountryFavorite(country)
        local color = isFav and COLORS.star or COLORS.starInactive
        draw.SimpleText("★", "US_Heavy", w/2, h/2, s:IsHovered() and COLORS.star or color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    button.star.DoClick = function(s)
        if not isFavorite then
            rHeadphones.Favorites.ToggleCountry(country)
            s:GetParent():GetParent():GetParent():RefreshCountries()
        end
    end
    
    button.Paint = function(s, w, h)
        local bgColor = s:IsHovered() and COLORS.buttonHover or COLORS.button
        draw.RoundedBox(8, 0, 0, w, h, bgColor)
        draw.SimpleText(formattedName or country, "US_Reg", 60, h/2, COLORS.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    
    button.DoClick = function()
        if isFavorite then
            -- Show favorites (TODO)
        else
            self:ShowStations(country)
        end
    end
    
    return button
end

function PANEL:ShowStations(country)
    self.countryList:Clear()
    self.currentCountry = country
    
    local backBtn = self:CreateCountryButton("← Back to Countries")
    backBtn.DoClick = function()
        self:RefreshCountries()
    end
    self.countryList:AddItem(backBtn)
    
    self:RefreshStations(country)
end

function PANEL:RefreshStations(country)
    self.countryList:Clear()
    
    local searchText = self.search:GetValue():lower()
    local stations = country == "Favorite Stations" 
        and rHeadphones.Favorites.GetFavoriteStations()
        or rHeadphones.Stations[country]
    
    if not stations then return end
    
    table.sort(stations, function(a, b) return a.name < b.name end)
    
    for _, station in ipairs(stations) do
        if searchText == "" or station.name:lower():find(searchText, 1, true) then
            local button = vgui.Create("DButton")
            button:SetTall(50)
            button:Dock(TOP)
            button:DockMargin(0, 0, 0, 2)
            button:SetText("")

            button.star = vgui.Create("DButton", button)
            button.star:SetSize(50, 50)
            button.star:Dock(LEFT)
            button.star:SetText("")
            button.star.Paint = function(s, w, h)
                local isFav = rHeadphones.Favorites.IsStationFavorite(station)
                local color = isFav and COLORS.star or COLORS.starInactive
                draw.SimpleText("★", "US_Heavy", w/2, h/2, s:IsHovered() and COLORS.star or color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            button.star.DoClick = function()
                rHeadphones.Favorites.ToggleStation(station)
            end

            button.Paint = function(s, w, h)
                local bgColor = s:IsHovered() and COLORS.buttonHover or COLORS.button
                draw.RoundedBox(8, 0, 0, w, h, bgColor)
                draw.SimpleText(station.name, "US_Reg", 60, h/2, COLORS.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                
                if country == "Favorite Stations" then
                    local formattedCountry = rHeadphones.FormatCountryName(station.country)
                    draw.SimpleText(formattedCountry, "US_Reg", w - 10, h/2, COLORS.textDark, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                end
            end
            
            button.DoClick = function()
                rHeadphones.PlayStation(station)
            end
            
            self.countryList:AddItem(button)
        end
    end
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