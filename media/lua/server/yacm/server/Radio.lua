local SendServer = require('yacm/server/network/SendServer')

local Radio = {}

function Radio.MuteRadio(radio, state)
    if radio == nil then
        print('error: Radio.MuteRadio: radio is nil')
        return
    end
    if state == nil then
        print('error: Radio.MuteRadio: state is nil')
        return
    end
    local radioData = radio:getDeviceData()
    radioData:setMicIsMuted(state)
end

function Radio.SyncSquare(radio, player)
    print('SyncSquare')
    if radio == nil then
        print('error: Radio.SyncSquare: radio is nil')
        return
    end
    local radioData = radio:getDeviceData()
    if radioData == nil or radioData:isIsoDevice() ~= true then
        print('error: Radio.SyncSquare: radio is not on a square')
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

function Radio.SyncHand(radio, player, id)
    if radio == nil then
        print('error: Radio.SyncHand: radio is nil')
        return
    end
    local radioData = radio:getDeviceData()
    if radioData == nil then
        print('error: Radio.SyncHand: radio has no device data')
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
