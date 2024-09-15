local FakeDeviceData = {}

function FakeDeviceData:getIsTurnedOn()
    return self.turnedOn
end

function FakeDeviceData:getMicIsMuted()
    return self.muted
end

function FakeDeviceData:getPower()
    return self.power
end

function FakeDeviceData:getDeviceVolume()
    return self.volume
end

function FakeDeviceData:getChannel()
    return self.frequency
end

function FakeDeviceData:getIsTwoWay()
    return self.isTwoWay
end

function FakeDeviceData:getTransmitRange()
    return self.transmitRange
end

function FakeDeviceData:setIsTurnedOn(turnedOn)
    self.turnedOn = turnedOn
end

function FakeDeviceData:setMicIsMuted(muteState)
    self.muted = muteState
end

function FakeDeviceData:setDeviceVolume(volume)
    self.volume = volume
end

function FakeDeviceData:setChannel(frequency)
    self.frequency = frequency
end

function FakeDeviceData:setHeadphoneType(headphone)
    self.headphoneType = headphone
end

function FakeDeviceData:setPower(battery)
    self.power = battery
end

function FakeDeviceData:setIsTwoWay(isTwoWay)
    self.isTwoWay = isTwoWay
end

function FakeDeviceData:setTransmitRange(transmitRange)
    self.transmitRange = transmitRange
end

function FakeDeviceData:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.turnedOn = false
    o.power = 0
    o.muted = true
    o.volume = 0
    o.frequency = 0
    o.headphoneType = -1
    o.isTwoWay = false
    o.transmitRange = 0
    return o
end

return FakeDeviceData
