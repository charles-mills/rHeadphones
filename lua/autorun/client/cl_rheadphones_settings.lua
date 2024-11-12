local COLORS = rHeadphones.Config.colors

local function CreateStyledCheckbox(parent, x, y, text, value, onChange)
    local container = vgui.Create("DPanel", parent)
    container:SetPos(x, y)
    container:SetSize(300, 30)
    container.Paint = function() end
    
    local checkbox = vgui.Create("DCheckBox", container)
    checkbox:SetPos(0, 5)
    checkbox:SetSize(20, 20)
    checkbox:SetValue(value)
    checkbox.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, COLORS.button)
        
        if s:GetChecked() then
            draw.RoundedBox(4, 2, 2, w-4, h-4, COLORS.accent)
        end
    end
    checkbox.OnChange = onChange
    
    local label = vgui.Create("DLabel", container)
    label:SetPos(30, 0)
    label:SetSize(270, 30)
    label:SetText(text)
    label:SetTextColor(COLORS.text)
    label:SetFont("rHeadphones_Regular")
    
    return container
end

local function CreateStyledComboBox(parent, x, y, width, height, options, selected, onChange)
    local container = vgui.Create("DPanel", parent)
    container:SetPos(x, y)
    container:SetSize(width, height)
    container.Paint = function() end
    
    local combobox = vgui.Create("DComboBox", container)
    combobox:Dock(FILL)
    combobox:SetTextColor(COLORS.text)
    combobox:SetFont("rHeadphones_Regular")
    
    local optionsArray = {}
    for name, data in pairs(options) do
        if type(data) == "table" and type(data.Draw) == "function" then
            table.insert(optionsArray, {
                id = name,
                name = data.name or name,
                description = data.description
            })
        end
    end
    
    table.sort(optionsArray, function(a, b)
        return a.name < b.name
    end)
    
    for _, option in ipairs(optionsArray) do
        combobox:AddChoice(option.name, option.id)
        
        if option.id == selected then
            combobox:SetValue(option.name)
        end
    end
    
    combobox.Paint = function(s, w, h)
        draw.RoundedBox(6, 0, 0, w, h, s:IsHovered() and COLORS.buttonHover or COLORS.button)
    end
    
    local oldPaint = combobox.GetMenu
    combobox.GetMenu = function(s)
        local menu = oldPaint(s)
        if IsValid(menu) then
            menu.Paint = function(_, w, h)
                draw.RoundedBox(6, 0, 0, w, h, COLORS.background)
                draw.RoundedBox(6, 1, 1, w-2, h-2, COLORS.button)
            end
        end
        return menu
    end
    
    combobox.OnSelect = function(_, _, _, value)
        onChange(value)
    end
    
    return container
end

local PANEL = {}

function PANEL:Init()
    self:SetSize(400, 500)
    self:DockPadding(15, 15, 15, 15)
    
    -- Title
    self.title = vgui.Create("DLabel", self)
    self.title:Dock(TOP)
    self.title:SetTall(40)
    self.title:SetText("Settings")
    self.title:SetFont("rHeadphones_Title")
    self.title:SetTextColor(COLORS.text)
    
    -- Settings container with scroll
    self.scroll = vgui.Create("DScrollPanel", self)
    self.scroll:Dock(FILL)
    self.scroll:DockMargin(0, 10, 0, 0)
    
    -- Style the scrollbar
    local sbar = self.scroll:GetVBar()
    sbar:SetWide(8)
    sbar:SetHideButtons(true)
    sbar.Paint = function(_, w, h)
        draw.RoundedBox(2, 0, 0, w, h, ColorAlpha(COLORS.searchBg, 50))
    end
    sbar.btnGrip.Paint = function(s, w, h)
        draw.RoundedBox(2, 0, 0, w, h, ColorAlpha(COLORS.accent, s:IsHovered() and 180 or 120))
    end
    
    -- Add settings
    self:AddSettings()
end

function PANEL:AddSettings()
end

function PANEL:Paint(w, h)
    local shadowSize = 2
    local shadowAlpha = 100
    for i = 1, shadowSize do
        local alpha = shadowAlpha * (1 - (i / shadowSize))
        draw.RoundedBox(8, -i, -i, w + i*2, h + i*2, ColorAlpha(COLORS.accent, alpha))
    end
    
    draw.RoundedBox(8, 0, 0, w, h, COLORS.header)
    
    surface.SetDrawColor(ColorAlpha(COLORS.accent, 50))
    surface.DrawOutlinedRect(1, 1, w-2, h-2, 1)
end

vgui.Register("rHeadphones_Settings", PANEL, "DPanel")

hook.Add("rHeadphones_InitializeHeader", "AddSettingsButton", function(header)
    local settingsBtn = vgui.Create("DButton", header.headerButtons)
    settingsBtn:SetSize(50, 60)
    settingsBtn:Dock(RIGHT)
    settingsBtn:DockMargin(0, 0, 5, 0)
    settingsBtn:SetText("")
    settingsBtn.Paint = function(s, w, h)
        surface.SetMaterial(Material("rammel/icons/cogs.png"))
        surface.SetDrawColor(s:IsHovered() and COLORS.accent or COLORS.text)
        surface.DrawTexturedRect(5, 10, 40, 40)
    end
    
    local settingsPanel = nil
    settingsBtn.DoClick = function()
        if IsValid(settingsPanel) then
            settingsPanel:Remove()
            settingsPanel = nil
        else
            settingsPanel = vgui.Create("rHeadphones_Settings", header:GetParent())
            settingsPanel:SetPos(header:GetWide() - 415, 70)
        end
    end
end) 