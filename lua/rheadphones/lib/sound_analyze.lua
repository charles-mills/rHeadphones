-- https://github.com/Pika-Software/sound_analyze/

local ipairs = ipairs
local _G = _G

local function averageList(tbl)
    if not tbl or #tbl == 0 then return 0 end
    
    local sum = 0
    for _, number in ipairs(tbl) do
        sum = sum + (number or 0)
    end
    
    return sum / #tbl
end

local Sizes = {
    [0] = FFT_256,      -- 0 - 128 levels
    [1] = FFT_512,      -- 1 - 256 levels
    [2] = FFT_1024,     -- 2 - 512 levels
    [3] = FFT_2048,     -- 3 - 1024 levels
    [4] = FFT_4096,     -- 4 - 2048 levels
    [5] = FFT_8192,     -- 5 - 4096 levels
    [6] = FFT_16384,    -- 6 - 8192 levels
    [7] = FFT_32768     -- 7 - 16384 levels
}

local Analysis = {}
Analysis.__index = Analysis

function _G.SoundAnalyze(channel)
    if not IsValid(channel) then return nil end
    
    local meta = setmetatable({
        ['Channel'] = channel,
        ['FFT'] = {},
        ['Events'] = {
            ['beat_1'] = {},
            ['beat_2'] = {},
            ['AllBeat'] = {}
        },
        ['History'] = {},
        ['PeakHistory'] = { {}, {} },
        ['Peak'] = { false, false },
        ['BPM'] = {},
        ['BPMlist'] = {{},{}},
        ['BPMbuffer'] = {{},{}},
        ['Beat'] = { false, false },
        ['PeakHistorySize'] = { 220, 220 },
        ['AdaptiveSize'] = { 0, 0 }
    }, Analysis)
    
    meta:Init()
    return meta
end

function Analysis:Init()
    if not IsValid(self.Channel) then return end
    
    self:SetSize(6)
    
    hook.Add('Think', tostring(self:GetChannel()), function()
        if not IsValid(self.Channel) then
            hook.Remove('Think', tostring(self:GetChannel()))
            return
        end
        
        pcall(function()
            self.Channel:FFT(self.FFT, 6)
            self:GetPeaks()
        end)
    end)
end

function Analysis:GetChannel()
    return self.Channel
end

function Analysis:GetSize()
    return self.Size
end

function Analysis:SetSize(size)
    self.Size = Sizes[math.Clamp(size, 0, 7)]
end

function Analysis:GetFFT()
    return self.FFT or {}
end

function Analysis:GetSoundPower(min, max)
    if not min or not max then return 0 end
    
    local power = 0
    local counter = 0
    local fft = self:GetFFT()
    
    for i = min, max do
        local value = fft[i]
        if value then
            power = math.max(0, power, value)
            counter = counter + 1
        end
    end
    
    return counter > 0 and power / counter or 0
end

function Analysis:GetSoundEnergy(min, max)
    if not min or not max then return 0 end
    
    local power = 0
    local fft = self:GetFFT()
    
    for i = min, max do
        local value = fft[i]
        if value then
            power = math.max(0, power, value)
        end
    end
    
    return power
end

function Analysis:OnEvent(name, func)
    if self.Events[name] then
        table.insert(self.Events[name], func)
    end
end

function Analysis:GetPeaks()
    if not self.FFT then return end
    
    local Peaks = {{}, {}}
    local fft = self:GetFFT()
    local size = #fft
    
    if size == 0 then return end
    
    for i = 1, math.floor(size / 100 * 20) do
        if i < size / 100 * 5 then
            table.insert(Peaks[1], fft[i] or 0)
        elseif i > size / 100 * 5 then
            table.insert(Peaks[2], fft[i] or 0)
        end
    end
    
    local SoundPower = {
        (self:GetSoundEnergy(1, math.floor(size / 100 * 5)) or 0) * 200,
        (self:GetSoundEnergy(math.floor(size / 100 * 5), math.floor(size / 100 * 20)) or 0) * 1333
    }
    
    for i = 1, 2 do
        self.AdaptiveSize[i] = math.max(self.AdaptiveSize[i] or 0, SoundPower[i] or 0)
        self:SetPeakHistorySize(i, ((self.AdaptiveSize[i] or 0) + 20) - (SoundPower[i] or 0))
    end
    
    for num, value in ipairs(Peaks) do
        local avg = averageList(value)
        if avg then
            table.insert(self.PeakHistory[num], avg)
        end
        
        while #self.PeakHistory[num] > self:GetPeakHistorySize(num) do
            table.remove(self.PeakHistory[num], 1)
        end
    end
    
    for i = 1, 2 do
        self.Beat[i] = false
        local last = self.PeakHistory[i][#self.PeakHistory[i]]
        local aver = averageList(self.PeakHistory[i])
        
        if last and aver and not self.Peak[i] and last > aver * 1.1 then
            self.Peak[i] = true
            self.Beat[i] = true
            
            table.insert(self.BPMbuffer[i], SysTime())
            if #self.BPMbuffer[i] > 2 then
                table.remove(self.BPMbuffer[i], 1)
            end
            
            if #self.BPMbuffer[i] == 2 then
                table.insert(self.BPMlist[i], self.BPMbuffer[i][2] - self.BPMbuffer[i][1])
                if #self.BPMlist[i] > 14 then
                    table.remove(self.BPMlist[i], 1)
                end
                
                local avgBPM = averageList(self.BPMlist[i])
                self.BPM[i] = avgBPM and math.max(0, (1 - avgBPM) * 256) or 0
            end
            
            if self.Events['beat_' .. i] then
                for _, func in ipairs(self.Events['beat_' .. i]) do
                    pcall(func, SoundPower[i])
                end
            end
        end
        
        if self.Peak[i] and last and aver and last <= aver * 0.99 then
            self.Peak[i] = false
        end
    end
end

function Analysis:Remove()
    if self.Channel then
        hook.Remove('Think', tostring(self:GetChannel()))
    end
end