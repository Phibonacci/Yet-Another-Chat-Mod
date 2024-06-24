local coordinates = require('yacm/utils/coordinates')

local RangeIndicator = ISUIElement:derive("RangeIndicator")

-- draw a square at the center and parts of losanges on the borders to avoid
-- drawing too many losanges and hurt the performances
function RangeIndicator:render()
    local zoom = coordinates.GetZoom()
    local width = 128 / zoom
    local height = 64 / zoom
    local alpha = 0.20
    local x, y = coordinates.CenterFeetOfPlayer(getPlayer(), width, height)
    local squareOffsetX = getPlayer():getX() - math.floor(getPlayer():getX())
    local squareOffsetY = getPlayer():getY() - math.floor(getPlayer():getY())

    local xOffset = (squareOffsetX - squareOffsetY) * (width / 2)
    local yOffset = (squareOffsetX + squareOffsetY) * (height / 2) - (height / 2)

    x = x - xOffset
    y = y - yOffset

    self:setX(x)
    self:setY(y)

    local tileTextureTop = getTexture('media/ui/yacm/indicator/white-tile-top.png')
    local tileTextureTopLeft = getTexture('media/ui/yacm/indicator/white-tile-top-left.png')
    local tileTextureTopRight = getTexture('media/ui/yacm/indicator/white-tile-top-right.png')
    local tileTextureBot = getTexture('media/ui/yacm/indicator/white-tile-bot.png')
    local tileTextureBotLeft = getTexture('media/ui/yacm/indicator/white-tile-bot-left.png')
    local tileTextureBotRight = getTexture('media/ui/yacm/indicator/white-tile-bot-right.png')
    local tileTextureLeft = getTexture('media/ui/yacm/indicator/white-tile-left.png')
    local tileTextureRight = getTexture('media/ui/yacm/indicator/white-tile-right.png')

    if self.range <= 120 then
        for j = -self.range, self.range do
            local i = -self.range + math.abs(j)
            local xTile = j * width / 2 + i * width / 2
            local yTile = -j * height / 2 + i * height / 2
            local texture
            if j == -self.range then
                texture = tileTextureBotLeft
            elseif j < 0 then
                texture = tileTextureLeft
            elseif j == 0 then
                texture = tileTextureTopLeft
            elseif j == self.range then
                texture = tileTextureTopRight
            else
                texture = tileTextureTop
            end
            self:drawTextureScaled(texture, xTile, yTile,
                width, height, alpha,
                self.color[1] / 255, self.color[2] / 255, self.color[3] / 255)
            if i ~= self.range - math.abs(j) then
                i = self.range - math.abs(j)
                xTile = j * width / 2 + i * width / 2
                yTile = -j * height / 2 + i * height / 2
                if j == 0 then
                    texture = tileTextureBotRight
                elseif j > 0 then
                    texture = tileTextureRight
                else
                    texture = tileTextureBot
                end
                self:drawTextureScaled(texture, xTile, yTile,
                    width, height, alpha,
                    self.color[1] / 255, self.color[2] / 255, self.color[3] / 255)
            end
        end
    end
    local range = math.min(120, self.range)
    local xTile, yTile = coordinates.CenterFeetOfPlayer(getPlayer(),
        width * range, height * range)
    self:setX(xTile - xOffset)
    self:setY(yTile - yOffset)
    self:drawRectStatic(0, 0,
        width * range, height * range, alpha,
        self.color[1] / 255, self.color[2] / 255, self.color[3] / 255)
end

function RangeIndicator:new(range, color)
    RangeIndicator.__index = self
    local x, y = coordinates.CenterTopOfPlayer(getPlayer(), 20, 6)
    setmetatable(RangeIndicator, { __index = ISUIElement })
    local o = ISUIElement:new(x, y, 20, 6)
    setmetatable(o, RangeIndicator)

    o.range = range
    o.color = color
    o.indicator = nil
    o.keepOnScreen = false
    o:instantiate()
    return o
end

return RangeIndicator
