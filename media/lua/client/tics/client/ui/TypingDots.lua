local Coordinates = require('tics/client/utils/Coordinates')

local TypingDots = ISUIElement:derive('TypingDots');

function TypingDots:render()
    local typingDots1 = getTexture('media/ui/tics/typing-dots/typing-dots-1.png')
    local typingDots2 = getTexture('media/ui/tics/typing-dots/typing-dots-2.png')
    local typingDots3 = getTexture('media/ui/tics/typing-dots/typing-dots-3.png')

    local time = Calendar.getInstance():getTimeInMillis()
    if time - self.startingTime > self.timer then
        self.dead = true
        return
    end
    local elapsedTime = time - self.lastStepTime
    if elapsedTime >= self.stepTime then
        self.lastStepTime = time
        self.step = (self.step) % 3 + 1
    end
    local texture
    if self.step == 1 then
        texture = typingDots1
    elseif self.step == 2 then
        texture = typingDots2
    else
        texture = typingDots3
    end
    local x, y = Coordinates.CenterTopOfPlayer(self.player, 20, 6)
    if x == nil then
        return
    end
    self:setX(x)
    self:setY(y - 6)
    self:drawTexture(texture, 0, 0, 1)
end

function TypingDots:refresh()
    self.startingTime = Calendar.getInstance():getTimeInMillis()
end

function TypingDots:new(player, timer)
    TypingDots.__index = self
    local x, y = Coordinates.CenterTopOfPlayer(player, 20, 6)
    if x == nil then
        x, y = 0, 0
    end
    setmetatable(TypingDots, { __index = ISUIElement })
    local o = ISUIElement:new(x, y, 20, 6)
    setmetatable(o, TypingDots)
    local time = Calendar.getInstance():getTimeInMillis()
    o.player = player
    o.startingTime = time
    o.lastStepTime = time
    o.stepTime = 250
    o.step = 1
    o.timer = timer * 1000
    o.dead = false
    o:instantiate()
    return o
end

return TypingDots
