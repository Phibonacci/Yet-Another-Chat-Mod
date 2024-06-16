require('yacm/parser/StringBuilder')
local coordinates = require('yacm/utils/coordinates')

local Bubble = ISUIElement:derive("ISPanel")

function Bubble:initialise()
    ISUIElement.initialise(self)
    -- self:addToUIManager()
end

function Bubble:delete()
    self:removeFromUIManager()
end

function Bubble:render()
    if self.dead then
        return
    end
    local time = Calendar.getInstance():getTimeInMillis()
    local elapsedTime = time - self.startTime
    local x, y = coordinates.CenterTopOfPlayer(self.player, self:getWidth(), self:getHeight(), false)
    self:setX(x)
    self:setY(y)
    local bubbleTop = getTexture("media/ui/yacm/bubble/bubble-top.png")
    local bubbleTopLeft = getTexture("media/ui/yacm/bubble/bubble-top-left.png")
    local bubbleTopRight = getTexture("media/ui/yacm/bubble/bubble-top-right.png")
    local bubbleCenter = getTexture("media/ui/yacm/bubble/bubble-center.png")
    local bubbleCenterLeft = getTexture("media/ui/yacm/bubble/bubble-left.png")
    local bubbleCenterRight = getTexture("media/ui/yacm/bubble/bubble-right.png")
    local bubbleBot = getTexture("media/ui/yacm/bubble/bubble-bot.png")
    local bubbleBotLeft = getTexture("media/ui/yacm/bubble/bubble-bot-left.png")
    local bubbleBotRight = getTexture("media/ui/yacm/bubble/bubble-bot-right.png")
    local bubbleArrow = getTexture("media/ui/yacm/bubble/bubble-arrow.png")

    local scale = 1
    local alpha
    if self.timer - elapsedTime > 1000 then
        alpha = 1
    elseif self.timer - elapsedTime > 0 then
        local fadingTime = elapsedTime - (self.timer - 1000)
        alpha = (1000 - fadingTime) / 1000
    else
        self.dead = true
        self:delete()
        return
    end

    local leftX = 0
    local leftW = math.floor(10 * 1 / scale)
    local rightW = math.floor(10 * 1 / scale)
    local centerW = math.floor(self:getWidth()) - rightW - leftW
    local centerX = leftW
    local rightX = centerX + centerW
    local topH = math.floor(10 * 1 / scale)
    self:drawTexture(bubbleTopLeft, leftX, 0, alpha)
    self:drawTextureScaled(bubbleTop, centerX, 0, centerW, topH, alpha)
    self:drawTexture(bubbleTopRight, rightX, 0, alpha)

    local centerY = topH
    local botH = math.floor(10 * 1 / scale)
    local centerH = math.floor(self:getHeight()) - botH - topH
    local botY = centerY + centerH

    self:drawTextureScaled(bubbleCenterLeft, leftX, centerY, leftW, centerH, alpha)
    self:drawTextureScaled(bubbleCenter, centerX, centerY, centerW, centerH, alpha)
    self:drawTextureScaled(bubbleCenterRight, rightX, centerY, rightW, centerH, alpha)

    self:drawTexture(bubbleBotLeft, leftX, botY, alpha)
    self:drawTextureScaled(bubbleBot, centerX, botY, centerW, botH, alpha)
    self:drawTexture(bubbleBotRight, rightX, botY, alpha)

    if x > 0 and y > 0
        and x + self:getWidth() < getCore():getScreenWidth()
        and y + self:getHeight() < getCore():getScreenHeight()
    then
        self:drawTexture(bubbleArrow, centerX + centerW / 2 + 5, botY + 3 * botH / 4, alpha)
    end

    ISRichTextPanel.render(self)
    self.previousTime = time
end

function Bubble:prerender()
end

function Bubble:new(player, text, length, timer)
    local width = math.min(length * 6.24, 162) + 40
    local height = 0
    local x, y = coordinates.CenterTopOfPlayer(player, width, height, true)
    Bubble.__index = self
    setmetatable(Bubble, { __index = ISRichTextPanel })
    local o = ISRichTextPanel:new(x, y, width, height)
    setmetatable(o, Bubble)
    o.player = player
    o.text = BuildFontSizeString('medium') .. text
    o.timer = timer * 1000
    o.background = true
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.5 }
    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
    o.anchorLeft = true
    o.anchorRight = false
    o.anchorTop = true
    o.anchorBottom = false
    o.moveWithMouse = false
    o.startTime = Calendar.getInstance():getTimeInMillis()
    o.previousTime = o.startTime
    o.dead = false
    o:initialise()
    o:paginate()
    return o
end

return Bubble
