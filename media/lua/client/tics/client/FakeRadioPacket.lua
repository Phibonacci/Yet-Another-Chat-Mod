local Character = require('tics/shared/utils/Character')
local World     = require('tics/shared/utils/World')


local FakeRadioPacket = {}

local function GetSquaresRadiosPositions(player, range, frequency)
    local radiosResult = {}
    local radioMaxRange = range
    local radios = World.getItemsInRangeByGroup(player, radioMaxRange, 'IsoRadio')
    local found = false
    for _, radio in pairs(radios) do
        local pos = {
            x = radio:getX(),
            y = radio:getY(),
            z = radio:getZ(),
        }
        local radioData = radio:getDeviceData()
        if radioData ~= nil then
            local radioFrequency = radioData:getChannel()
            local turnedOn = radioData:getIsTurnedOn()
            if turnedOn and radioFrequency == frequency
                and Character.canHearRadioSound(player, radio, radioData, range)
            then
                table.insert(radiosResult, {
                    position = pos,
                })
                found = true
            end
        end
    end
    return radiosResult, found
end

local function GetPlayerRadiosPositions(player, range, frequency)
    local radiosResult = {}
    local radio = Character.getFirstHandOrBeltItemByGroup(player, 'Radio')
    local found = false
    if radio == nil then
        return radiosResult
    end
    local radioData = radio and radio:getDeviceData() or nil
    if radioData then
        -- -1 nothing
        --  0 headphones
        --  1 earbuds
        local hasHeadphones = radioData:getHeadphoneType() >= 0
        local radioFrequency = radioData:getChannel()
        if radioData:getIsTurnedOn() and radioFrequency == frequency
            and not hasHeadphones
        then
            table.insert(radiosResult, {
                username = player:getUsername()
            })
            found = true
        end
    end
    return radiosResult, found
end

local function GetVehiclesRadiosPositions(player, range, frequency)
    local radiosResult = {}
    local radioMaxRange = range
    local vehicles = World.getVehiclesInRange(player, radioMaxRange)
    local found = false
    for _, vehicle in pairs(vehicles) do
        local radio = vehicle:getPartById('Radio')
        if radio ~= nil then
            local radioData = radio:getDeviceData()
            if radioData ~= nil then
                local radioFrequency = radioData:getChannel()
                if radioData:getIsTurnedOn() and radioFrequency == frequency
                    and Character.canHearRadioSound(player, vehicle, radioData, range)
                then
                    table.insert(radiosResult, {
                        key = vehicle:getKeyId()
                    })
                    found = true
                end
            end
        end
    end
    return radiosResult, found
end

-- return positions of turned on radios in range
-- this one is really only useful to create a fake radio packet in case of
-- a discord message sent through the Java client
function FakeRadioPacket.getListeningRadiosPositions(player, range, frequency)
    local radios = {}
    if player == nil then
        print('TICS error: FakeRadioPacket.getListeningRadiosPositions: player is null')
        return nil
    end
    if range == nil then
        print('TICS error: FakeRadioPacket.getListeningRadiosPositions: range is null')
        return nil
    end
    if frequency == nil then
        print('TICS error: FakeRadioPacket.getListeningRadiosPositions: frequency is null')
        return nil
    end
    local squaresRadios, squaresRadiosFound = GetSquaresRadiosPositions(player, range, frequency)
    local playersRadios, playersRadiosFound = GetPlayerRadiosPositions(player, range, frequency)
    local vehiclesRadios, vehiclesRadiosFound = GetVehiclesRadiosPositions(player, range, frequency)

    if not squaresRadiosFound and not playersRadiosFound and not vehiclesRadiosFound then
        return nil
    end

    return {
        squares = squaresRadios or {},
        players = playersRadios or {},
        vehicles = vehiclesRadios or {},
    }
end

return FakeRadioPacket
