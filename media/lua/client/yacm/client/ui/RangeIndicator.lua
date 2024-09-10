local coordinates = require('yacm/client/utils/coordinates')

local RangeIndicator = ISUIElement:derive("RangeIndicator")

local RectTexturePath = 'media/ui/yacm/indicator/white-rectangle.png'
local function PreLoadTextures()
    getTexture(RectTexturePath)
end

-- draw a square at the center and parts of losanges on the borders to avoid
-- drawing too many losanges and hurt the performances
function RangeIndicator:render(z)
    if not self.enabled or (z ~= nil and z ~= 0) then
        return
    end
    local width         = 128
    local height        = 64
    local alpha         = 0.02
    local squareOffsetX = getPlayer():getX() - math.floor(getPlayer():getX())
    local squareOffsetY = getPlayer():getY() - math.floor(getPlayer():getY())


    local xOffset = (squareOffsetX - squareOffsetY) * (width / 2)
    local yOffset = (squareOffsetX + squareOffsetY) * (height / 2) - (height / 2)


    local rectTexture = getTexture(RectTexturePath)


    local x, y = coordinates.CenterBaseOfObjectNoZoom(getPlayer())
    x          = math.floor(x - xOffset)
    y          = math.floor(y - yOffset)
    if self.range <= 120 then
        for j = 0, self.range do
            local i = -self.range + math.abs(j)
            local xTTile = j * width / 2 + i * width / 2
            local yTTile = -j * height / 2 + i * height / 2

            i = self.range - math.abs(j)
            local xBTile = j * width / 2 + i * width / 2
            local yBTile = -j * height / 2 + i * height / 2

            self:drawTextureAllPoint(rectTexture,
                x + xTTile - 2,
                y + yTTile - height / 2,
                x + xTTile + 2,
                y + yTTile - height / 2 - 2,

                x + xBTile + width / 2 + 4,
                y + yBTile - 1,
                x + xBTile + width / 2,
                y + yBTile + 1,
                self.color[1] / 255, self.color[2] / 255, self.color[3] / 255,
                alpha)
            self:drawTextureAllPoint(rectTexture,
                x - (xTTile - 2),
                y - (yTTile - height / 2),
                x - (xTTile + 2),
                y - (yTTile - height / 2 - 2),

                x - (xBTile + width / 2 + 2),
                y - (yBTile - 1),
                x - (xBTile + width / 2),
                y - (yBTile + 1),
                self.color[1] / 255, self.color[2] / 255, self.color[3] / 255,
                alpha)
            self:drawTextureAllPoint(rectTexture,
                x + xTTile - 2,
                y - (yTTile - height / 2),
                x + xTTile + 2,
                y - (yTTile - height / 2 - 2),

                x + xBTile + width / 2 + 4,
                y - (yBTile - 1),
                x + xBTile + width / 2,
                y - (yBTile + 1),
                self.color[1] / 255, self.color[2] / 255, self.color[3] / 255,
                alpha)
            self:drawTextureAllPoint(rectTexture,
                x - (xTTile - 2),
                y + yTTile - height / 2,
                x - (xTTile + 2),
                y + yTTile - height / 2 - 2,

                x - (xBTile + width / 2 + 4),
                y + yBTile - 1,
                x - (xBTile + width / 2),
                y + yBTile + 1,
                self.color[1] / 255, self.color[2] / 255, self.color[3] / 255,
                alpha)
        end
    end
end

function RangeIndicator:subscribe()
    if self.event ~= nil then
        return
    end
    self.event = function()
        self:render()
    end
    -- OnPostRender is buggy and will sometimes fail to draw at the right coordinates
    -- The UI drawing events are limited to 10FPS
    -- OnPostFloorLayerDraw is called once for every layer, contrary to
    -- OnPostRender it does not allow us to draw over the squares before the
    -- character is drawn but it looks that's the most PZ has to offer to us.
    Events.OnPostFloorLayerDraw.Add(self.event)
end

function RangeIndicator:unsubscribe()
    if self.event == nil then
        return
    end
    Events.OnPostFloorLayerDraw.Remove(self.event)
    self.event = nil
end

function RangeIndicator:new(range, color)
    RangeIndicator.__index = self
    local x, y = coordinates.CenterTopOfPlayer(getPlayer(), 20, 6)
    if x == nil then
        x, y = 0, 0
    end
    setmetatable(RangeIndicator, { __index = ISUIElement })
    local o = ISUIElement:new(x, y, 20, 6)
    setmetatable(o, RangeIndicator)

    o:setX(0)
    o:setY(0)
    o.range = range
    o.color = color
    o.keepOnScreen = false
    o.enabled = false
    o:instantiate()

    -- TODO: try to use of the non documented events with missleading names to do that
    PreLoadTextures()
    return o
end

return RangeIndicator
