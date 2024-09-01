local World = require('yacm/shared/utils/World')
local Character = require('yacm/shared/utils/Character')

local Radio = {}

function Radio.SyncSquare(turnedOn, mute, power, volume, frequency, x, y, z)
    if turnedOn == nil then
        print('error: Radio.SyncSquare: nil id parameter')
    end
    if mute == nil then
        print('error: Radio.SyncSquare: nil id parameter')
    end
    if power == nil then
        print('error: Radio.SyncSquare: nil power parameter')
    end
    if volume == nil then
        print('error: Radio.SyncSquare: nil volume parameter')
    end
    if frequency == nil then
        print('error: Radio.SyncSquare: nil frequency parameter')
    end
    if x == nil then
        print('error: Radio.SyncSquare: nil x parameter')
    end
    if y == nil then
        print('error: Radio.SyncSquare: nil y parameter')
    end
    if z == nil then
        print('error: Radio.SyncSquare: nil z parameter')
    end
    local square = getSquare(x, y, z)
    if square == nil then -- legitimate error, when a client is too far away
        return
    end
    local radios = World.getSquareItemsByGroup(square, 'IsoRadio')
    if radios == nil or #radios <= 0 then
        print('error: Radio.SyncSquare: no radio found at ' .. x .. ', ' .. y .. ', ' .. z)
        return
    end
    local radio = radios[1]
    local radioData = radio:getDeviceData()
    if radioData == nil then
        print('error: Radio.SyncSquare: radio has not device data')
        return
    end
    if radioData.setIsTurnedOn ~= nil then
        radioData:setIsTurnedOn(turnedOn)
    end
    radioData:setMicIsMuted(mute)
end

function Radio.SyncInHand(id, turnedOn, mute, power, volume, frequency)
    if id == nil then
        print('error: Radio.SyncSquare: nil id parameter')
    end
    if turnedOn == nil then
        print('error: Radio.SyncSquare: nil id parameter')
    end
    if mute == nil then
        print('error: Radio.SyncSquare: nil id parameter')
    end
    if power == nil then
        print('error: Radio.SyncSquare: nil power parameter')
    end
    if volume == nil then
        print('error: Radio.SyncSquare: nil volume parameter')
    end
    if frequency == nil then
        print('error: Radio.SyncSquare: nil frequency parameter')
    end
    local radio = Character.getItemById(getPlayer(), id)
    if radio == nil then
        print('error: Radio.SyncInHand: no radio found on player')
        return
    end
    local radioData = radio:getDeviceData()
    if radioData == nil then
        print('error: Radio.SyncInHand: radio has not device data')
        return
    end
    if radioData.setIsTurnedOn ~= nil then
        radioData:setIsTurnedOn(turnedOn)
    end
    radioData:setMicIsMuted(mute)
end

return Radio
