local Character = {}

function Character.getHandItemByGroup(player, group)
    local primary = player:getPrimaryHandItem()
    local secondary = player:getSecondaryHandItem()
    if primary and instanceof(primary, group) then
        return primary
    elseif secondary and instanceof(secondary, group) then
        return secondary
    end
    return nil
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

function Character.getItemById(player, id)
    local primary = player:getPrimaryHandItem()
    local secondary = player:getSecondaryHandItem()
    if primary and primary:getID() == id then
        return primary
    elseif secondary and secondary:getID() == id then
        return secondary
    else
        return Character.getAttachedItemById(player, id)
    end
end

function Character.AreInSameVehicle(player1, player2)
    local v1 = player1:getVehicle()
    local v2 = player2:getVehicle()
    return v1 ~= nil and v2 ~= nil and v1:getKeyId() == v2:getKeyId()
end

return Character
