local World = {}

local function MatchStringInList(list, element)
    for _, s in ipairs(list) do
        if s == element then
            return true
        end
    end
    return false
end

-- insert b values in a
local function ConcatListValues(a, b)
    if a == nil or b == nil then
        return a
    end
    for _, v in ipairs(b) do
        table.insert(a, v)
    end
end

local filterTypeEnum = {}
filterTypeEnum.sprite = 1
filterTypeEnum.group = 2

local function getSquareItemsByFilter(square, filterType, filterData)
    local items = {}
    if square == nil then
        return items
    end
    local itemList = square:getObjects()
    for i = 0, square:getObjects():size() - 1 do
        local item = itemList:get(i)
        if item ~= nil then
            if filterType == filterTypeEnum.sprite then
                local sprite = item:getSprite()
                if sprite then
                    local spriteName = sprite:getName()
                    if MatchStringInList(filterData, spriteName) then
                        table.insert(items, item)
                    end
                end
            elseif filterType == filterTypeEnum.group then
                if instanceof(item, filterData) then
                    table.insert(items, item)
                end
            end
        end
    end
    return items
end

function World.getSquareItemsBySprites(square, spriteList)
    return getSquareItemsByFilter(square, filterTypeEnum.sprite, spriteList)
end

function World.getSquareItemsByGroup(square, groupName)
    return getSquareItemsByFilter(square, filterTypeEnum.group, groupName)
end

-- from nearest to further
local function getItemsInRangeByFilter(player, range, filterType, filterData)
    if range < 1 then
        return {}
    end
    local items = {}
    -- we want to list items on the player floor first
    local zList = { player:getZ(), player:getZ() + 1 }
    if player:getZ() > 0 then
        table.insert(zList, player:getZ() - 1)
    end
    for currentRange = 0, range do
        for _, z in pairs(zList) do
            for yOffset = -currentRange, currentRange do
                local xOffset = currentRange - math.abs(yOffset)
                local x = player:getX() + xOffset
                local y = player:getY() + yOffset
                local square = getSquare(x, y, z)
                local newItems = getSquareItemsByFilter(square, filterType, filterData)
                ConcatListValues(items, newItems)
                if xOffset ~= 0 then
                    x = player:getX() - xOffset
                    square = getSquare(x, y, z)
                    newItems = getSquareItemsByFilter(square, filterType, filterData)
                    ConcatListValues(items, newItems)
                end
            end
        end
    end
    return items
end

function World.getItemsInRangeBySprites(player, range, spriteList)
    return getItemsInRangeByFilter(player, range, filterTypeEnum.sprite, spriteList)
end

function World.getItemsInRangeByGroup(player, range, groupName)
    return getItemsInRangeByFilter(player, range, filterTypeEnum.group, groupName)
end

function World.getVehiclesInRange(player, range)
    if range < 1 then
        return {}
    end
    local vehicles = {}
    -- we want to list vehicles on the player floor first
    local zList = { player:getZ(), player:getZ() + 1 }
    if player:getZ() > 0 then
        table.insert(zList, player:getZ() - 1)
    end
    for currentRange = 0, range do
        for _, z in pairs(zList) do
            for yOffset = -currentRange, currentRange do
                local y = player:getY() + yOffset
                local xOffset = currentRange - math.abs(yOffset)
                local xList = { player:getX() + xOffset }
                if xOffset ~= 0 then
                    table.insert(xList, player:getX() - xOffset)
                end

                for _, x in pairs(xList) do
                    local square = getSquare(x, y, z)
                    if square ~= nil then
                        local vehicle = square:getVehicleContainer()
                        if vehicle ~= nil then
                            local vehicleId = vehicle:getKeyId()
                            if vehicleId == nil then
                                print('yacm error: World.getVehiclesInRange: impossible error: vehicle key ID is null')
                            else
                                vehicles[vehicleId] = vehicle
                            end
                        end
                    end
                end
            end
        end
    end
    return vehicles
end

function World.getPlayerByUsername(username)
    local connectedPlayers = getOnlinePlayers()
    for i = 0, connectedPlayers:size() - 1 do
        local connectedPlayer = connectedPlayers:get(i)
        if username:lower() == connectedPlayer:getUsername():lower() then
            return connectedPlayer
        end
    end
    return nil
end

function World.forAllPlayers(action)
    local result = false
    local connectedPlayers = getOnlinePlayers()
    for i = 0, connectedPlayers:size() - 1 do
        local connectedPlayer = connectedPlayers:get(i)
        if action(connectedPlayer) == true then
            result = true
        end
    end
    return result
end

function World.distanceManhatten(source, target)
    return math.abs(math.floor(target:getX()) - math.floor(source:getX())) +
        math.abs(math.floor(target:getY()) - math.floor(source:getY()))
end

function World.getFirstSquareItem(square, category)
    if square == nil then
        return nil
    end
    local itemList = square:getObjects()
    for i = 0, square:getObjects():size() - 1 do
        local item = itemList:get(i)
        if item ~= nil and instanceof(item, category) then
            return item
        end
    end
    return nil
end

return World
