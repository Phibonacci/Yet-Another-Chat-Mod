local RangeIndicator      = require('tics/client/ui/RangeIndicator')
local Character           = require('tics/shared/utils/Character')
local World               = require('tics/shared/utils/World')
local RadioStatusIcons    = require('tics/client/ui/RadioStatusIcons')

local RadioRangeIndicator = {}


local Colors = {
    { 235, 255, 000 },
    { 000, 235, 255 },
    { 255, 000, 235 },
    { 255, 235, 000 },
    { 000, 255, 235 },
    { 235, 000, 255 },
}

local NextColorIndex = 1


function RadioRangeIndicator:freeIndicators()
    for _, indicator in pairs(self.indicators) do
        indicator:unsubscribe()
    end
    self.indicators = {}
    self.radios = {}
    NextColorIndex = 1
end

function RadioRangeIndicator:registerRadio(object, radio)
    local radioData = radio:getDeviceData()
    if radioData ~= nil then
        if radioData:getIsTurnedOn() then
            local range = Character.getRadioRange(radioData, self.radioMaxRange)
            local indicator = RangeIndicator:new(object, range, Colors[NextColorIndex])
            NextColorIndex = (NextColorIndex) % #Colors + 1
            indicator:subscribe()
            table.insert(self.indicators, indicator)
            table.insert(self.radios, { object = object, radio = radio, range = range })
        end
    end
end

function RadioRangeIndicator:discoverRadios()
    local radios = Character.getRunningRadiosInRange(self.player, self.range)
    if radios == nil then
        return
    end
    for _, radio in pairs(radios.squares) do
        self:registerRadio(radio, radio)
    end
    -- TODO: hear radio from other players with no headphones
    -- for _, info in pairs(radios.players) do
    --     local player = info['player']
    --     local radio = info['radio']
    --     self:registerRadio(player, radio)
    -- end
    for _, info in pairs(radios.vehicles) do
        local vehicle = info['vehicle']
        local radio = info['radio']
        self:registerRadio(vehicle, radio)
    end
end

function RadioRangeIndicator:update()
    local currentTime = Calendar.getInstance():getTimeInMillis()
    local elapsed = currentTime - self.previousTime
    if elapsed < 500 then
        return
    end
    self:freeIndicators()
    self:discoverRadios()
    self.previousTime = currentTime
end

function RadioRangeIndicator:updateIcons()
    local radios = Character.getAllHandAndBeltItemsByGroup(self.player, 'Radio')
    for _, radio in pairs(radios) do
        local radioData = radio:getDeviceData()
        if radioData then
            if radioData:getIsTurnedOn() then
                self.radioStatusIcons.enabled = self.showIcon
                return
            end
        end
    end
    for _, info in pairs(self.radios) do
        local object   = info['object']
        local range    = info['range']

        local distance = World.distanceManhatten(object, self.player)
        if distance <= range then
            self.radioStatusIcons.enabled = self.showIcon
            return
        end
    end
    self.radioStatusIcons.enabled = false
end

function RadioRangeIndicator:subscribe()
    self:subscribeIndicators()
    if self.event then
        return
    end
    self.event = function()
        self:update()
    end
    Events.OnTick.Add(self.event)
    self.iconEvent = function()
        self:updateIcons()
    end
    Events.OnPreUIDraw.Add(self.iconEvent)
    self.radioStatusIcons:subscribe()
end

function RadioRangeIndicator:unsubscribe()
    self:unsubscribeIndicators()
    if not self.event then
        return
    end
    self:freeIndicators()
    Events.OnTick.Remove(self.event)
    self.event = nil
    Events.OnPreUIDraw.Remove(self.iconEvent)
    self.iconEvent = nil
    self.radioStatusIcons:unsubscribe()
end

function RadioRangeIndicator:subscribeIndicators()
    for _, indicator in pairs(self.indicators) do
        indicator:subscribe()
    end
end

function RadioRangeIndicator:unsubscribeIndicators()
    for _, indicator in pairs(self.indicators) do
        indicator:unsubscribe()
    end
end

function RadioRangeIndicator:new(discoveringRange, radioMaxRange, showIcon)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.player = getPlayer()
    o.range = discoveringRange
    o.radioMaxRange = radioMaxRange
    o.showIcon = showIcon
    o.indicators = {}
    o.radios = {}
    o.previousTime = 0
    o.radioStatusIcons = RadioStatusIcons:new(o.player)
    return o
end

return RadioRangeIndicator
