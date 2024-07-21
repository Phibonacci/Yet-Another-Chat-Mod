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

return Character
