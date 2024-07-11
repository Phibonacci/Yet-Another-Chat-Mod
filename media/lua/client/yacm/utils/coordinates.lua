local coordinates = {}

-- function coordinates.CenterTopOfSquare(square, width, height)
--     if square == nil then
--         return nil
--     end

--     local zoom = coordinates.GetZoom()
--     local squareWidth = 128 / zoom
--     local squareHeight = 64 / zoom

--     local x, y = coordinates.CenterFeetOfPlayer(getPlayer(), width, height)
--     local squareOffsetX = getPlayer():getX() - math.floor(getPlayer():getX())
--     local squareOffsetY = getPlayer():getY() - math.floor(getPlayer():getY())
--     local xOffset = (squareOffsetX - squareOffsetY) * (width / 2)
--     local yOffset = (squareOffsetX + squareOffsetY) * (height / 2) - (height / 2)

--     x = x - xOffset
--     y = y - yOffset

--     local squareX = math.floor(getPlayer():getX())

--     local xTile = j * width / 2 + i * width / 2
--     local yTile = -j * height / 2 + i * height / 2

--     -- todo

--     local zoom = getCore():getZoom(getPlayer():getPlayerNum())
--     x = x / zoom - width / 2
--     y = y / zoom - height
--     local bodyHeight = 120 / zoom
--     y = y - bodyHeight - 10
--     return x, y
-- end

function coordinates.CenterTopOfPlayer(player, width, height)
    if player == nil then
        return nil
    end
    local x, y = coordinates.CenterTopOfObject(player, width, height)
    local zoom = coordinates.GetZoom()
    local bodyHeight = 120 / zoom
    y = y - bodyHeight - 10
    return x, y
end

function coordinates.CenterTopOfObject(object, width, height)
    if object == nil then
        return nil
    end
    local x, y = ISCoordConversion.ToScreen(object:getX(), object:getY(), object:getZ(), nil)
    local zoom = getCore():getZoom(getPlayer():getPlayerNum())
    x = x / zoom - width / 2
    y = y / zoom - height
    return x, y
end

function coordinates.CenterFeetOfPlayer(player, width, height)
    local x, y = ISCoordConversion.ToScreen(player:getX(), player:getY(), player:getZ(), nil)
    local zoom = getCore():getZoom(getPlayer():getPlayerNum())
    x = x / zoom - width / 2
    y = y / zoom - height / 2
    return x, y
end

function coordinates.GetZoom()
    return getCore():getZoom(getPlayer():getPlayerNum())
end

return coordinates
