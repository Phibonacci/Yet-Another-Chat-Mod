local ABubble = require('yacm/client/ui/bubble/ABubble')
local Coordinates = require('yacm/client/utils/Coordinates')

local PlayerBubble = ISUIElement:derive("PlayerBubble")

function PlayerBubble:loadTextures()
    self.bubbleTop = getTexture("media/ui/yacm/bubble/simple/bubble-top.png")
    self.bubbleTopLeft = getTexture("media/ui/yacm/bubble/simple/bubble-top-left.png")
    self.bubbleTopRight = getTexture("media/ui/yacm/bubble/simple/bubble-top-right.png")
    self.bubbleCenter = getTexture("media/ui/yacm/bubble/simple/bubble-center.png")
    self.bubbleCenterLeft = getTexture("media/ui/yacm/bubble/simple/bubble-left.png")
    self.bubbleCenterRight = getTexture("media/ui/yacm/bubble/simple/bubble-right.png")
    self.bubbleBot = getTexture("media/ui/yacm/bubble/simple/bubble-bot.png")
    self.bubbleBotLeft = getTexture("media/ui/yacm/bubble/simple/bubble-bot-left.png")
    self.bubbleBotRight = getTexture("media/ui/yacm/bubble/simple/bubble-bot-right.png")
    self.bubbleArrow = getTexture("media/ui/yacm/bubble/simple/bubble-arrow.png")
end

function PlayerBubble:render()
    if self.dead then
        return
    end
    local x, y = Coordinates.CenterTopOfPlayer(self.player, self:getWidth(), self:getHeight())
    if x == nil then
        return
    end
    self:drawBubble(x, y)
end

function PlayerBubble:new(player, text, rawText, timer, opacity)
    local textLength = getTextManager():MeasureStringX(UIFont.medium, rawText)
    local width = math.min(textLength * 1.25, 162) + 40
    local height = 0
    local x, y = Coordinates.CenterTopOfPlayer(player, width, height)
    if x == nil then
        x, y = 0, 0
    end
    PlayerBubble.__index = self
    setmetatable(PlayerBubble, { __index = ABubble })
    local o = ABubble:new(x, y, text, rawText, timer, opacity)
    if x == nil then
        self.dead = true
    end
    setmetatable(o, PlayerBubble)
    o.player = player
    return o
end

return PlayerBubble
