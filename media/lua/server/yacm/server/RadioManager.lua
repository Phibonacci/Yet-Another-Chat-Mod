local Character = require('yacm/shared/utils/Character')
local World = require('yacm/shared/utils/World')

local RadioManager = {}

function RadioManager:subscribeSquare(square)
    local key = math.abs(square:getX()) .. ',' .. math.abs(square:getY()) .. ',' .. math.abs(square:getZ())
    self.squares[key] = square
end

function RadioManager:subscribeVehicle(vehicle)
    local key = vehicle:getKeyId()
    self.vehicles[key] = square
end

function RadioManager:executeSquare(action)
    local radiosToDelete = {}
    for key, square in pairs(self.squares) do
        local radio = World.getFirstSquareItem(square, 'IsoRadio')
        if radio == nil then
            table.insert(radiosToDelete, key)
        else
            action(radio)
        end
    end
    for _, key in pairs(radiosToDelete) do
        self.squares[key] = nil
    end
end

function RadioManager:executeVehicle(action)
    local radiosToDelete = {}
    for key, vehicle in pairs(self.vehicles) do
        local radio = vehicle:getPartById('Radio')
        if radio == nil then
            table.insert(radiosToDelete, key)
        else
            action(radio)
        end
    end
    for _, key in pairs(radiosToDelete) do
        self.vehicles[key] = nil
    end
end

function RadioManager:execute(action)
    self:executeSquare(action)
    self:executeVehicle(action)
end

function RadioManager:makeNoise(frequency, range)
    self:execute(
        function(radio)
            local radioData = radio:getDeviceData()
            if radioData ~= nil then
                local radioFrequency = radioData:getChannel()
                if radioData:getIsTurnedOn()
                    and radioFrequency == frequency
                then
                    addSound(radio, radio:getX(), radio:getY(), radio:getZ(), range, range)
                end
            end
        end
    )
    World.forAllPlayers(
        function(player)
            local radio = Character.getHandItemByGroup(player, 'Radio')
            if radio ~= nil then
                local radioData = radio:getDeviceData()
                if radioData ~= nil then
                    local radioFrequency = radioData:getChannel()
                    local turnedOn = radioData:getIsTurnedOn()
                    -- TODO
                    -- local volume = radioData:getDeviceVolume()
                    if turnedOn and radioFrequency == frequency
                    then
                        addSound(player, player:getX(), player:getY(), player:getZ(), range, range)
                    end
                end
            end
        end)
end

local function CreateRadioManager()
    local o = {}
    setmetatable(o, RadioManager)
    RadioManager.__index = RadioManager
    o.squares = {}
    o.vehicles = {}
    return o
end

-- Since a lua file is only read once, this file will always return the same
-- value. Making this a singleton that cannot be missused.
return CreateRadioManager()
