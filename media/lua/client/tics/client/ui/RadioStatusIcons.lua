local Coordinates = require('tics/client/utils/Coordinates')


local RadioStatusIcons = {}


function RadioStatusIcons:update()
    if self.enabled then
        local zoom = Coordinates.GetZoom()
        if zoom > 1 then
            -- the icon is too big when unzooming but a linear reduction in size is too extreme
            -- this is 1/3rd the normal rate
            local width = 13 / (zoom - 2 * (zoom - 1) / 3)
            local height = 13 / (zoom - 2 * (zoom - 1) / 3)
            local x, y = Coordinates.TopLeftOfPlayer(self.player, width, height)
            self:drawTextureScaled(self.radioIcon, x, y, width, height, 0.5)
        else
            local x, y = Coordinates.TopLeftOfPlayer(self.player, 13, 13)
            self:drawTexture(self.radioIcon, x, y, 0.5)
        end
    end
end

function RadioStatusIcons:subscribe()
    if self.event then
        return
    end
    self.event = function()
        self:update()
    end
    Events.OnPreUIDraw.Add(self.event)
end

function RadioStatusIcons:unsubscribe()
    if not self.event then
        return
    end
    Events.OnPreUIDraw.Remove(self.event)
    self.event = nil
end

function RadioStatusIcons:new(player)
    RadioStatusIcons.__index = self
    setmetatable(RadioStatusIcons, { __index = ISUIElement })
    local o = ISUIElement:new(0, 0, 13, 13)
    setmetatable(o, RadioStatusIcons)

    o:setX(0)
    o:setY(0)
    o.player = player
    o.radioIcon = getTexture("media/ui/tics/icons/tics-radio.png")
    o.enabled = false
    o:instantiate()
    return o
end

return RadioStatusIcons
