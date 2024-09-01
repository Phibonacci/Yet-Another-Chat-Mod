local Coordinates = {}

function Coordinates.CenterTopOfPlayer(player, width, height)
    if player == nil then
        print('yacm error: CenterTopOfPlayer: nil player parameter')
        return nil
    end
    local x, y = Coordinates.CenterTopOfObject(player, width, height)
    local zoom = Coordinates.GetZoom()
    local bodyHeight = 129 / zoom
    y = y - bodyHeight - 21
    return x, y
end

function Coordinates.CenterTopOfObject(object, width, height)
    if object == nil then
        print('yacm error: CenterTopOfObject: nil player parameter')
        return nil
    end
    local x, y = IsoUtils.XToScreenExact(object:getX(), object:getY(), object:getZ(), 0),
        IsoUtils.YToScreenExact(object:getX(), object:getY(), object:getZ(), 0)
    local zoom = getCore():getZoom(getPlayer():getPlayerNum())
    x = x / zoom - width / 2
    y = y / zoom - height
    return x, y
end

function Coordinates.CenterFeetOfPlayer(player, width, height)
    if player == nil then
        print('yacm error: CenterFeetOfPlayer: nil player parameter')
        return nil
    end
    local x, y = ISCoordConversion.ToScreen(player:getX(), player:getY(), player:getZ(), nil)
    local zoom = getCore():getZoom(getPlayer():getPlayerNum())
    x = x / zoom - width / 2
    y = y / zoom - height / 2
    return x, y
end

function Coordinates.GetZoom()
    return getCore():getZoom(getPlayer():getPlayerNum())
end

return Coordinates
