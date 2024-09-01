local ABubble = require('yacm/client/ui/bubble/ABubble')
local Coordinates = require('yacm/client/utils/Coordinates')

local RadioBubble = ISUIElement:derive("RadioBubble")

function RadioBubble:render()
    if self.dead then
        return
    end
    local x, y = Coordinates.CenterTopOfObject(self.square, self:getWidth(), self:getHeight())
    if x == nil then
        return
    end
    self:drawBubble(x, y)
end

function RadioBubble:new(square, text, rawText, timer, opacity)
    local textLength = getTextManager():MeasureStringX(UIFont.medium, rawText)
    local width = math.min(textLength * 1.25, 162) + 40
    local height = 0
    local x, y = Coordinates.CenterTopOfObject(square, width, height)
    if x == nil then
        x, y = 0, 0
    end
    RadioBubble.__index = self
    setmetatable(RadioBubble, { __index = ABubble })
    local o = ABubble:new(x, y, text, rawText, timer, opacity)
    if x == nil then
        self.dead = true
    end
    setmetatable(o, RadioBubble)
    o.square = square
    return o
end

return RadioBubble
