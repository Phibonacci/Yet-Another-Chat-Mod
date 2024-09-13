local RangeIndicator = require('yacm/client/ui/RangeIndicator')
local World          = require('yacm/shared/utils/World')


local RadioRangeIndicator = {}

function RadioRangeIndicator:freeIndicators()
    for _, indicator in pairs(self.indicators) do
        indicator:unsubscribe()
    end
    self.indicators = {}
end

local Colors = {
    { 235, 255, 000 },
    { 000, 235, 255 },
    { 255, 000, 235 },
    { 255, 235, 000 },
    { 000, 255, 235 },
    { 235, 000, 255 },
}
local NextColorIndex = 1
function RadioRangeIndicator:registerRadio(object, radio)
    local radioData = radio:getDeviceData()
    if radioData ~= nil then
        if radioData:getIsTurnedOn() then
            print('#### create radio indicator and subscribe')
            -- TODO range depending on the volume
            -- this isn't even accurate as it should use the /say range which can but customized through sandbox
            local indicator = RangeIndicator:new(object, 4, Colors[NextColorIndex])
            NextColorIndex = (NextColorIndex) % #Colors + 1
            indicator:subscribe()
            indicator.enabled = true
            table.insert(self.indicators, indicator)
        end
    end
end

function RadioRangeIndicator:discoverRadios()
    local radios = World.getListeningRadios(self.player, self.range)
    if radios == nil then
        return
    end
    for _, radio in pairs(radios.squares) do
        self:registerRadio(radio, radio)
    end
    for _, info in pairs(radios.players) do
        local player = info['player']
        local radio = info['radio']
        self:registerRadio(player, radio)
    end
    for _, info in pairs(radios.vehicles) do
        local vehicle = info['vehicle']
        local radio = info['radio']
        self:registerRadio(vehicle, radio)
    end
end

function RadioRangeIndicator:update()
    local currentTime = Calendar.getInstance():getTimeInMillis()
    local elapsed = currentTime - self.previousTime
    if elapsed < 1000 then
        return
    end
    self:freeIndicators()
    self:discoverRadios()
    self.previousTime = currentTime
end

function RadioRangeIndicator:subscribe()
    if self.event then
        return
    end
    self.event = function()
        self:update()
    end
    Events.OnTick.Add(self.event)
end

function RadioRangeIndicator:unsubscribe()
    if not self.event then
        return
    end
    self:freeIndicators()
    Events.OnTick.Remove(self.event)
    self.event = nil
end

function RadioRangeIndicator:new(range)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.player = getPlayer()
    o.range = range
    o.indicators = {}
    o.previousTime = 0
    return o
end

return RadioRangeIndicator
