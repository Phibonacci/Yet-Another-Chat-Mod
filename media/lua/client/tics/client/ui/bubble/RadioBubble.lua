local ABubble     = require('tics/client/ui/bubble/ABubble')
local Coordinates = require('tics/client/utils/Coordinates')
local Parser      = require('tics/client/parser/Parser')
local RadioVoice  = require('tics/client/voice/RadioVoice')

local RadioBubble = ISUIElement:derive("RadioBubble")

function RadioBubble:loadTextures()
    self.bubbleTop = getTexture("media/ui/tics/bubble/radio/bubble-top.png")
    self.bubbleTopLeft = getTexture("media/ui/tics/bubble/radio/bubble-top-left.png")
    self.bubbleTopRight = getTexture("media/ui/tics/bubble/radio/bubble-top-right.png")
    self.bubbleCenter = getTexture("media/ui/tics/bubble/radio/bubble-center.png")
    self.bubbleCenterLeft = getTexture("media/ui/tics/bubble/radio/bubble-left.png")
    self.bubbleCenterRight = getTexture("media/ui/tics/bubble/radio/bubble-right.png")
    self.bubbleBot = getTexture("media/ui/tics/bubble/radio/bubble-bot.png")
    self.bubbleBotLeft = getTexture("media/ui/tics/bubble/radio/bubble-bot-left.png")
    self.bubbleBotRight = getTexture("media/ui/tics/bubble/radio/bubble-bot-right.png")
    self.bubbleArrow = getTexture("media/ui/tics/bubble/radio/bubble-arrow.png")
end

function RadioBubble:render()
    if self.dead then
        return
    end
    if not self.texturesLoaded then
        self:loadTextures()
        self.texturesLoaded = true
    end
    local x, y = RadioBubble.CenterTop(self.type, self.object, self:getWidth(), self:getHeight())
    y = y - self.offsetY * Core.getTileScale() / (Coordinates.GetZoom())
    if x == nil then
        return
    end
    self:updateText(x, y)
    self:drawBubble()
end

function RadioBubble.CenterTop(type, object, width, height)
    if type == RadioBubble.types.square then
        return Coordinates.CenterTopOfObject(object, width, height)
    elseif type == RadioBubble.types.player then
        local x, y = Coordinates.CenterTopOfPlayer(object, width, height)
        x = x + 30
        y = y - 30
        return x, y
    elseif type == RadioBubble.types.vehicle then
        return Coordinates.CenterTopOfPlayer(object, width, height)
    else
        error('tried to initialize RadioBubble without a type')
    end
end

RadioBubble.types = {
    square = 1,
    player = 2,
    vehicle = 3,
}

function RadioBubble:new(object, message, messageColor, timer, opacity, type, isVoicesEnabled, voicePitch, offsetY)
    local parsedMessages = Parser.ParseTicsMessage(message, messageColor, 20, 200)
    local textLength = getTextManager():MeasureStringX(UIFont.medium, parsedMessages['rawMessage'])
    local width = math.min(textLength * 1.25, 162) + 40
    local height = 0
    local x, y = RadioBubble.CenterTop(type, object, width, height)
    if x == nil then
        x, y = 0, 0
    end
    RadioBubble.__index = self
    setmetatable(RadioBubble, { __index = ABubble })
    local o = ABubble:new(
        x, y, parsedMessages['bubble'], parsedMessages['rawMessage'],
        message, messageColor, timer, opacity, 20)
    if x == nil then
        self.dead = true
    end
    setmetatable(o, RadioBubble)
    o.type = type
    o.object = object
    if isVoicesEnabled then
        o.voice = RadioVoice:new(parsedMessages['rawMessage'], object, voicePitch)
    end
    o.message = message
    o.color = messageColor
    o.offsetY = offsetY or 0
    return o
end

return RadioBubble
