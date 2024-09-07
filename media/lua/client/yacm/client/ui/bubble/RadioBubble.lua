local ABubble     = require('yacm/client/ui/bubble/ABubble')
local Coordinates = require('yacm/client/utils/Coordinates')
local Parser      = require('yacm/client/parser/Parser')
local RadioVoice  = require('yacm/client/voice/RadioVoice')

local RadioBubble = ISUIElement:derive("RadioBubble")

function RadioBubble:loadTextures()
    self.bubbleTop = getTexture("media/ui/yacm/bubble/radio/bubble-top.png")
    self.bubbleTopLeft = getTexture("media/ui/yacm/bubble/radio/bubble-top-left.png")
    self.bubbleTopRight = getTexture("media/ui/yacm/bubble/radio/bubble-top-right.png")
    self.bubbleCenter = getTexture("media/ui/yacm/bubble/radio/bubble-center.png")
    self.bubbleCenterLeft = getTexture("media/ui/yacm/bubble/radio/bubble-left.png")
    self.bubbleCenterRight = getTexture("media/ui/yacm/bubble/radio/bubble-right.png")
    self.bubbleBot = getTexture("media/ui/yacm/bubble/radio/bubble-bot.png")
    self.bubbleBotLeft = getTexture("media/ui/yacm/bubble/radio/bubble-bot-left.png")
    self.bubbleBotRight = getTexture("media/ui/yacm/bubble/radio/bubble-bot-right.png")
    self.bubbleArrow = getTexture("media/ui/yacm/bubble/radio/bubble-arrow.png")
end

function RadioBubble:render()
    if self.dead then
        return
    end
    local x, y = RadioBubble.CenterTop(self.type, self.object, self:getWidth(), self:getHeight())
    if x == nil then
        return
    end
    self:drawBubble(x, y)
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

function RadioBubble:new(object, message, messageColor, timer, opacity, type, isVoicesEnabled, voicePitch)
    local parsedMessages = Parser.ParseYacmMessage(message, messageColor, 20, 200)
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
    return o
end

return RadioBubble
