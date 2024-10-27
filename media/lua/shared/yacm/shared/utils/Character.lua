local World = require('yacm/shared/utils/World')


local Character = {}

function Character.getFirstAndLastName(player)
    return player:getDescriptor():getForename(), player:getDescriptor():getSurname()
end

function Character.getFirstHandItemByGroup(player, group)
    local primary = player:getPrimaryHandItem()
    local secondary = player:getSecondaryHandItem()
    if primary and instanceof(primary, group) then
        return primary
    elseif secondary and instanceof(secondary, group) then
        return secondary
    end
    return nil
end

function Character.getFirstAttachedItemByGroup(player, group)
    local inventoryItems = player:getAttachedItems()
    if inventoryItems == nil or inventoryItems:size() <= 0 then
        return nil
    end
    for i = 0, inventoryItems:size() - 1 do
        local inventoryItem = inventoryItems:getItemByIndex(i)
        if instanceof(inventoryItem, group) then
            return inventoryItem
        end
    end
    return nil
end

function Character.getFirstAttachedItemByType(player, type)
    local inventoryItems = player:getAttachedItems()
    if inventoryItems == nil or inventoryItems:size() <= 0 then
        return nil
    end
    for i = 0, inventoryItems:size() - 1 do
        local inventoryItem = inventoryItems:getItemByIndex(i)
        if inventoryItem:getType() == type then
            return inventoryItem
        end
    end
    return nil
end

function Character.getFirstHandOrBeltItemByGroup(player, group)
    local item = Character.getFirstHandItemByGroup(player, group)
    if item == nil then
        item = Character.getFirstAttachedItemByGroup(player, group)
    end
    return item
end

function Character.getAllHandItemsByGroup(player, group)
    local items = {}
    local primary = player:getPrimaryHandItem()
    local secondary = player:getSecondaryHandItem()
    if primary and instanceof(primary, group) then
        table.insert(items, primary)
    elseif secondary and instanceof(secondary, group) then
        table.insert(items, secondary)
    end
    return items
end

function Character.getAllHandAndBeltItemsByGroup(player, group)
    local items = Character.getAllHandItemsByGroup(player, group)
    local inventoryItems = player:getAttachedItems()
    if inventoryItems == nil or inventoryItems:size() <= 0 then
        return items
    end
    for i = 0, inventoryItems:size() - 1 do
        local inventoryItem = inventoryItems:getItemByIndex(i)
        if instanceof(inventoryItem, group) then
            table.insert(items, inventoryItem)
        end
    end
    return items
end

function Character.isItemOnBeltAndNotInHand(player, item)
    return item.getID ~= nil and item:getAttachedSlot() ~= -1
        and not Character.getHandItemById(player, item:getID())
end

function Character.getAttachedItemById(player, id)
    local inventoryItems = player:getAttachedItems()
    if inventoryItems == nil or inventoryItems:size() <= 0 then
        return nil
    end
    for i = 0, inventoryItems:size() - 1 do
        local inventoryItem = inventoryItems:getItemByIndex(i)
        if inventoryItem:getID() == id then
            return inventoryItem
        end
    end
    return nil
end

function Character.getAttachedItemByIndex(player, index)
    if index == nil then
        print('yacm error: Character.getAttachedItemByIndex: tried to access attached item with a null index')
        return nil
    end
    local inventoryItems = player:getAttachedItems()
    if inventoryItems == nil or inventoryItems:size() <= 0 then
        return nil
    end
    return inventoryItems:getItemByIndex(index)
end

function Character.getHandItemById(player, id)
    local primary = player:getPrimaryHandItem()
    local secondary = player:getSecondaryHandItem()
    if primary and primary:getID() == id then
        return primary
    elseif secondary and secondary:getID() == id then
        return secondary
    end
    return nil
end

function Character.getItemById(player, id)
    local item = Character.getHandItemById(player, id)
    if item == nil then
        item = Character.getAttachedItemById(player, id)
        if item == nil then
            local inventory = player:getInventory()
            item = inventory:getItemById(id)
        end
    end
    return item
end

function Character.areInSameVehicle(player1, player2)
    local v1 = player1:getVehicle()
    local v2 = player2:getVehicle()
    return v1 ~= nil and v2 ~= nil and v1:getKeyId() == v2:getKeyId()
end

function Character.getRadioRange(radioData, radioMaxRange)
    local hasHeadphones = radioData:getHeadphoneType() >= 0
    local volume = radioData:getDeviceVolume() -- from 0.0 to 1.0

    local maxSoundRange = radioMaxRange
    if hasHeadphones then
        maxSoundRange = maxSoundRange * 2 / 3
    end
    local soundRange = math.floor(maxSoundRange * volume + 0.5)
    return soundRange
end

function Character.canHearRadioSound(player, source, radioData, radioMaxRange)
    local distance = World.distanceManhatten(player, source)
    local soundRange = Character.getRadioRange(radioData, radioMaxRange)
    return distance <= soundRange
end

local function GetSquaresRadios(player, range, frequency)
    local radiosResult = {}
    local radioMaxRange = range
    local radios = World.getItemsInRangeByGroup(player, radioMaxRange, 'IsoRadio')
    local found = false
    for _, radio in pairs(radios) do
        local radioData = radio:getDeviceData()
        if radioData ~= nil then
            local radioFrequency = radioData:getChannel()
            local turnedOn = radioData:getIsTurnedOn()
            if turnedOn and (frequency == nil or radioFrequency == frequency)
            then
                table.insert(radiosResult, radio)
                found = true
            end
        end
    end
    return radiosResult, found
end

-- TODO check other player radio without headphones
local function GetPlayerRadios(player, range, frequency)
    local radiosResult = {}
    local radio = Character.getFirstHandItemByGroup(player, 'Radio')
    local found = false
    if radio == nil then
        return radiosResult
    end
    local radioData = radio and radio:getDeviceData() or nil
    if radioData then
        local radioFrequency = radioData:getChannel()
        if radioData:getIsTurnedOn() and (frequency == nil or radioFrequency == frequency)
        then
            table.insert(radiosResult, {
                player = player,
                radio = radio,
            })
            found = true
        end
    end
    return radiosResult, found
end

local function GetVehiclesRadios(player, range, frequency)
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
                if radioData:getIsTurnedOn() and (frequency == nil or radioFrequency == frequency)
                then
                    table.insert(radiosResult, {
                        vehicle = vehicle,
                        radio = radio
                    })
                    found = true
                end
            end
        end
    end
    return radiosResult, found
end

function Character.getRunningRadiosInRange(player, range, frequency)
    if player == nil then
        print('yacm error: Character.getListeningRadios: player is null')
        return nil
    end
    if range == nil then
        print('yacm error: Character.getListeningRadios: range is null')
        return nil
    end
    local squaresRadios, squaresRadiosFound = GetSquaresRadios(player, range, frequency)
    local playersRadios, playersRadiosFound = GetPlayerRadios(player, range, frequency)
    local vehiclesRadios, vehiclesRadiosFound = GetVehiclesRadios(player, range, frequency)

    if not squaresRadiosFound and not playersRadiosFound and not vehiclesRadiosFound then
        return nil
    end

    return {
        squares = squaresRadios or {},
        players = playersRadios or {},
        vehicles = vehiclesRadios or {},
    }
end

return Character
