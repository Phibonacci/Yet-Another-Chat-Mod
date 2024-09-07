---@diagnostic disable: trailing-space
local Character = require('yacm/shared/utils/Character')
local World = require('yacm/shared/utils/World')

local RadioManager = {}

local function FormatCache(squares, vehicles)
    local cacheSquares = {}
    for key, square in pairs(squares) do
        table.insert(
            cacheSquares,
            { x = square:getX(), y = square:getY(), z = square:getZ() }
        )
    end
    local cacheVehicles = {}
    for key, vehicle in pairs(vehicles) do
        cacheVehicles[key] = { x = vehicle:getX(), y = vehicle:getY(), z = vehicle:getZ() }
    end
    return {
        squares = cacheSquares,
        vehicles = cacheVehicles,
    }
end

function RadioManager:save()
    local cacheData = FormatCache(self.squares, self.vehicles)
    ModData.add('yacmRadioCache', cacheData)
end

local function ReadCache(cache)
    local squares = {}
    local cacheSquares = cache['squares']
    if cacheSquares == nil then
        print('yacm error: ReadCache: received cache data without squares object')
        return
    end
    local squaresCount = 0
    for _, pos in pairs(cacheSquares) do
        local square = getSquare(pos['x'], pos['y'], pos['z'])
        if square ~= nil then
            local key = math.abs(pos['x']) .. ',' .. math.abs(pos['y']) .. ',' .. math.abs(pos['z'])
            squares[key] = square
            squaresCount = squaresCount + 1
        else
            print(
                'yacm error: ReadCache: found null square in radio cache file at: (' ..
                pos['x'] .. ', ' .. pos['y'] .. ', ' .. pos['z'] .. ')')
        end
    end
    print('yacm info: ' .. squaresCount .. ' squares found in cache')

    local vehicles = {}
    local cacheVehicles = cache['vehicles']
    if cacheVehicles == nil then
        print('yacm error: ReadCache: received cache data without vehicles object')
        return
    end
    local vehiclesCount = 0
    for key, pos in pairs(cacheVehicles) do
        local square = getSquare(pos['x'], pos['y'], pos['z'])
        if square ~= nil then
            local vehicle = square:getVehicleContainer()
            if vehicle ~= nil then
                local vehicleId = vehicle:getKeyId()
                if vehicleId == key then
                    vehicles[key] = vehicle
                    vehiclesCount = vehiclesCount + 1
                else
                    print(
                        'yacm error: ReadCache: vehicle has unexpected key id ' ..
                        vehicleId .. ' on square in radio cache file at: (' ..
                        pos['x'] .. ', ' .. pos['y'] .. ', ' .. pos['z'] .. ') ' .. key .. ' was expected')
                end
            else
                print(
                    'yacm error: ReadCache: no vehicle found on square in radio cache file at: (' ..
                    pos['x'] .. ', ' .. pos['y'] .. ', ' .. pos['z'] .. ')')
            end
        else
            print(
                'yacm error: ReadCache: found null vehicle square in radio cache file at: (' ..
                pos['x'] .. ', ' .. pos['y'] .. ', ' .. pos['z'] .. ')')
        end
    end
    print('yacm info: ' .. vehiclesCount .. ' vehicles found in cache')

    return squares, vehicles
end

function RadioManager:load()
    local cache = ModData.getOrCreate('yacmRadioCache')
    print('yacm info: loading cache')
    if cache == nil then
        print('yacm info: no cache found')
        return
    end
    local squares, vehicles = ReadCache(cache)

    self.squares = squares or {}
    self.vehicles = vehicles or {}
    self.loaded = true
end

function RadioManager:subscribeSquare(square)
    if not self.loaded then
        self:load()
    end
    local key = math.abs(square:getX()) .. ',' .. math.abs(square:getY()) .. ',' .. math.abs(square:getZ())
    local squareWasUnassigned = self.squares[key] == nil
    self.squares[key] = square
    if squareWasUnassigned then
        self:save()
    end
end

function RadioManager:subscribeVehicle(vehicle)
    if not self.loaded then
        self:load()
    end
    local key = vehicle:getKeyId()
    local vehicleWasUnassigned = self.vehicles[key] == nil
    self.vehicles[key] = vehicle
    if vehicleWasUnassigned then
        self:save()
    end
end

function RadioManager:executeSquare(action)
    local radiosToDelete = {}
    for key, square in pairs(self.squares) do
        if square == nil then
            table.insert(radiosToDelete, key)
        else
            local radio = World.getFirstSquareItem(square, 'IsoRadio')
            if radio == nil then
                table.insert(radiosToDelete, key)
            else
                action(radio, radio)
            end
        end
    end
    for _, key in pairs(radiosToDelete) do
        self.squares[key] = nil
    end
    if #radiosToDelete > 0 then
        return true
    end
    return false
end

function RadioManager:executeVehicle(action)
    local radiosToDelete = {}
    for key, vehicle in pairs(self.vehicles) do
        if vehicle == nil then
            table.insert(radiosToDelete, key)
        else
            local radio = vehicle:getPartById('Radio')
            if radio == nil then
                table.insert(radiosToDelete, key)
            else
                action(vehicle, radio)
            end
        end
    end
    for _, key in pairs(radiosToDelete) do
        self.vehicles[key] = nil
    end
    if #radiosToDelete > 0 then
        return true
    end
    return false
end

function RadioManager:execute(action)
    if not self.loaded then
        self:load()
    end
    local squareDeleted = self:executeSquare(action)
    local vehicleDeleted = self:executeVehicle(action)
    if squareDeleted or vehicleDeleted then
        self:save()
    end
end

function RadioManager:makeNoise(frequency, range)
    if not self.loaded then
        self:load()
    end
    self:execute(
        function(source, radio)
            local radioData = radio:getDeviceData()
            if radioData ~= nil then
                local radioFrequency = radioData:getChannel()

                -- -1 nothing
                --  0 headphones
                --  1 earbuds
                local hasHeadphones = radioData:getHeadphoneType() >= 0

                if radioData:getIsTurnedOn()
                    and radioFrequency == frequency
                    and not hasHeadphones
                then
                    addSound(source, source:getX(), source:getY(), source:getZ(), range, range)
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

                    -- -1 nothing
                    --  0 headphones
                    --  1 earbuds
                    local hasHeadphones = radioData:getHeadphoneType() >= 0

                    if turnedOn and radioFrequency == frequency and not hasHeadphones then
                        addSound(player, player:getX(), player:getY(), player:getZ(), range, range)
                    end
                end
            end
        end
    )
end

local function CreateRadioManager()
    local o = {}
    setmetatable(o, RadioManager)
    RadioManager.__index = RadioManager
    o.squares = {}
    o.vehicles = {}
    o.loaded = false
    return o
end

local instance = CreateRadioManager()

-- Since a lua file is only read once, this file will always return the same
-- value. Making this a singleton that cannot be missused.
return instance
