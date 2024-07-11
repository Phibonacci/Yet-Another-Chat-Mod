require('yacm/parser/StringBuilder')

local ABubble = require('yacm/ui/bubble/ABubble')
local coordinates = require('yacm/utils/coordinates')

local PlayerBubble = ISUIElement:derive("PlayerBubble")

function PlayerBubble:render()
    if self.dead then
        return
    end
    local x, y = coordinates.CenterTopOfPlayer(self.player, self:getWidth(), self:getHeight())
    if x == nil then
        return
    end
    self:drawBubble(x, y)
end

function PlayerBubble:new(player, text, rawText, timer, opacity)
    local textLength = getTextManager():MeasureStringX(UIFont.medium, rawText)
    local width = math.min(textLength * 1.25, 162) + 40
    local height = 0
    local x, y = coordinates.CenterTopOfPlayer(player, width, height)
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
