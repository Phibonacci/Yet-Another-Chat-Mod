local coordinates = {}

function coordinates.CenterTopOfPlayer(player, width, height)
    local x, y = ISCoordConversion.ToScreen(player:getX(), player:getY(), player:getZ(), player:getPlayerNum())
    local zoom = getCore():getZoom(player:getPlayerNum())
    x = x / zoom - width / 2
    y = y / zoom - height
    local bodyHeight = 120 / zoom
    y = y - bodyHeight - 10
    return x, y
end

function coordinates.CenterFeetOfPlayer(player, width, height)
    local x, y = ISCoordConversion.ToScreen(player:getX(), player:getY(), player:getZ(), player:getPlayerNum())
    local zoom = getCore():getZoom(player:getPlayerNum())
    x = x / zoom - width / 2
    y = y / zoom - height / 2
    return x, y
end

function coordinates.GetZoom()
    return getCore():getZoom(getPlayer():getPlayerNum())
end

return coordinates
