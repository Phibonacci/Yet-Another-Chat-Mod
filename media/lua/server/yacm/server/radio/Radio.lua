local RadioManager = require('yacm/server/radio/RadioManager')
local SendServer = require('yacm/server/network/SendServer')

local Radio = {}

function Radio.MuteRadio(radio, state)
    if radio == nil then
        print('yacm error: Radio.MuteRadio: radio is nil')
        return
    end
    if state == nil then
        print('yacm error: Radio.MuteRadio: state is nil')
        return
    end
    local radioData = radio:getDeviceData()
    radioData:setMicIsMuted(state)
end

function Radio.SyncSquare(radio, player)
    if radio == nil then
        print('yacm error: Radio.SyncSquare: radio is nil')
        return
    end
    RadioManager:subscribeSquare(radio:getSquare())
    local radioData = radio:getDeviceData()
    if radioData == nil or radioData:isIsoDevice() ~= true then
        print('yacm error: Radio.SyncSquare: radio is not on a square')
        return
    end
    local turnedOn = radioData:getIsTurnedOn()
    local mute = radioData:getMicIsMuted()
    local power = radioData:getPower()
    local volume = radioData:getDeviceVolume()
    local frequency = radioData:getChannel()
    local connectedPlayers = getOnlinePlayers()
    local x, y, z = radio:getX(), radio:getY(), radio:getZ()
    if player == nil then
        for i = 0, connectedPlayers:size() - 1 do
            local connectedPlayer = connectedPlayers:get(i)
            SendServer.SquareRadioState(
                connectedPlayer, turnedOn, mute, power, volume,
                frequency, x, y, z)
        end
    else
        SendServer.SquareRadioState(
            player, turnedOn, mute, power, volume, frequency, x, y, z)
    end
end

function Radio.SyncBelt(radio, player, turnedOn, muteState, volume, frequency,
                        battery, headphone, isTwoWay, transmitRange)
    if radio == nil then
        print('yacm error: Radio.SyncBelt: radio is nil')
        return
    end
    if player == nil then
        print('yacm error: Radio.SyncBelt: player is nil')
        return
    end
    if turnedOn == nil then
        print('yacm error: Radio.SyncBelt: turnedOn is nil')
        return
    end
    if muteState == nil then
        print('yacm error: Radio.SyncBelt: muteState is nil')
        return
    end
    if volume == nil then
        print('yacm error: Radio.SyncBelt: volume is nil')
        return
    end
    if frequency == nil then
        print('yacm error: Radio.SyncBelt: frequency is nil')
        return
    end
    if battery == nil then
        print('yacm error: Radio.SyncBelt: battery is nil')
        return
    end
    if headphone == nil then
        print('yacm error: Radio.SyncBelt: headphone is nil')
        return
    end
    if transmitRange == nil then
        print('yacm error: Radio.SyncBelt: transmitRange is nil')
        return
    end
    local radioData = radio:getDeviceData()
    if radioData == nil then
        print('yacm error: Radio.SyncHand: radio has no device data')
        return
    end
    radioData:setIsTurnedOn(turnedOn)
    radioData:setMicIsMuted(muteState)
    radioData:setDeviceVolume(volume)
    radioData:setChannel(frequency)
    radioData:setHeadphoneType(headphone)
    radioData:setPower(battery)
    radioData:setIsTwoWay(isTwoWay)
    radioData:setTransmitRange(transmitRange)
    radio:setX(player:getX())
    radio:setY(player:getY())
    radio:setZ(player:getZ())
end

function Radio.SyncHand(radio, player, id)
    if radio == nil then
        print('yacm error: Radio.SyncHand: radio is nil')
        return
    end
    local radioData = radio:getDeviceData()
    if radioData == nil then
        print('yacm error: Radio.SyncHand: radio has no device data')
        return
    end
    local turnedOn = radioData:getIsTurnedOn()
    local mute = radioData:getMicIsMuted()
    local power = radioData:getPower()
    local volume = radioData:getDeviceVolume()
    local frequency = radioData:getChannel()
    SendServer.InHandRadioState(
        player, id, turnedOn, mute, power, volume, frequency, x, y, z)
end

return Radio
