local StringBuilder = require('yacm/client/parser/StringBuilder')

local ABubble = ISUIElement:derive("ABubble")

function ABubble:loadTextures()
    error('loadTextures not implemented in child class')
end

function ABubble:drawBubble(x, y)
    if not self.texturesLoaded then
        self:loadTextures()
        self.texturesLoaded = true
    end
    local time = Calendar.getInstance():getTimeInMillis()
    local elapsedTime = time - self.startTime

    self:setX(x)
    self:setY(y)

    local scale = 1
    local alpha
    if self.timer - elapsedTime > 1000 then
        alpha = self.opacity
    elseif self.timer - elapsedTime > 0 then
        local fadingTime = elapsedTime - (self.timer - 1000)
        alpha = (1000 - fadingTime) / 1000 * self.opacity
    else
        self.dead = true
        return
    end

    local leftX = 0
    local leftW = math.floor(10 * 1 / scale)
    local rightW = math.floor(10 * 1 / scale)
    local centerW = math.floor(self:getWidth()) - rightW - leftW
    local centerX = leftW
    local rightX = centerX + centerW
    local topH = math.floor(10 * 1 / scale)
    self:drawTexture(self.bubbleTopLeft, leftX, 0, alpha)
    self:drawTextureScaled(self.bubbleTop, centerX, 0, centerW, topH, alpha)
    self:drawTexture(self.bubbleTopRight, rightX, 0, alpha)

    local centerY = topH
    local botH = math.floor(10 * 1 / scale)
    local centerH = math.floor(self:getHeight()) - botH - topH
    local botY = centerY + centerH

    self:drawTextureScaled(self.bubbleCenterLeft, leftX, centerY, leftW, centerH, alpha)
    self:drawTextureScaled(self.bubbleCenter, centerX, centerY, centerW, centerH, alpha)
    self:drawTextureScaled(self.bubbleCenterRight, rightX, centerY, rightW, centerH, alpha)

    self:drawTexture(self.bubbleBotLeft, leftX, botY, alpha)
    self:drawTextureScaled(self.bubbleBot, centerX, botY, centerW, botH, alpha)
    self:drawTexture(self.bubbleBotRight, rightX, botY, alpha)

    if x > 0 and y > 0
        and x + self:getWidth() < getCore():getScreenWidth()
        and y + self:getHeight() < getCore():getScreenHeight()
    then
        self:drawTexture(self.bubbleArrow, centerX + centerW / 2 + 5, botY + 4 * botH / 5, alpha)
    end

    ISRichTextPanel.render(self)
end

function ABubble:render()
    if self.dead then
        return
    end
    self:drawBubble(x, y)
end

function ABubble:prerender()
end

function ABubble:new(x, y, text, rawText, timer, opacity)
    local textLength = getTextManager():MeasureStringX(UIFont.medium, rawText)
    local width = math.min(textLength * 1.25, 162) + 40
    local height = 0
    ABubble.__index = self
    setmetatable(ABubble, { __index = ISRichTextPanel })
    local o = ISRichTextPanel:new(x, y, width, height)
    setmetatable(o, ABubble)
    o.text = StringBuilder.BuildFontSizeString('medium') .. text
    o.timer = timer * 1000
    o.opacity = opacity / 100
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
    ISUIElement.initialise(o)
    o:paginate()
    o.texturesLoaded = false
    return o
end

return ABubble
