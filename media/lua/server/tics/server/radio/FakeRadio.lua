local FakeDeviceData = require('tics/server/radio/FakeDeviceData')

local FakeRadio = {}

function FakeRadio:getDeviceData()
    return self.data
end

function FakeRadio:getX()
    return self.x
end

function FakeRadio:getY()
    return self.y
end

function FakeRadio:getZ()
    return self.z
end

function FakeRadio:setX(x)
    self.x = x
end

function FakeRadio:setY(y)
    self.y = y
end

function FakeRadio:setZ(z)
    self.z = z
end

function FakeRadio:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.data = FakeDeviceData:new()
    return o
end

return FakeRadio
