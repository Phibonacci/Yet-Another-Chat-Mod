local Coordinates = {}

function Coordinates.CenterTopOfPlayer(player, width, height)
    if player == nil then
        print('TICS error: CenterTopOfPlayer: nil player parameter')
        return nil
    end
    local x, y = Coordinates.CenterTopOfObject(player, width, height)
    local zoom = Coordinates.GetZoom()
    local bodyHeight = 129 / zoom
    y = y - bodyHeight - 21
    return x, y
end

function Coordinates.TopLeftOfPlayer(player, width, height)
    if player == nil then
        print('TICS error: CenterTopOfPlayer: nil player parameter')
        return nil
    end
    local x, y = Coordinates.CenterTopOfObject(player, width, height)
    local zoom = Coordinates.GetZoom()
    local shoulderHeight = 116 / zoom
    x = x - 38 / zoom - width / 2
    y = y - shoulderHeight + height
    return x, y
end

function Coordinates.CenterTopOfObject(object, width, height)
    if object == nil then
        print('TICS error: CenterTopOfObject: nil player parameter')
        return nil
    end
    local x, y = IsoUtils.XToScreenExact(object:getX(), object:getY(), object:getZ(), 0),
        IsoUtils.YToScreenExact(object:getX(), object:getY(), object:getZ(), 0)
    local zoom = getCore():getZoom(getPlayer():getPlayerNum())
    x = x / zoom - width / 2
    y = y / zoom - height
    return x, y
end

function Coordinates.CenterBaseOfObjectNoZoom(object, width, height)
    if object == nil then
        print('TICS error: CenterBaseOfObjectNoZoom: nil object parameter')
        return nil
    end
    local x, y = ISCoordConversion.ToScreen(object:getX(), object:getY(), object:getZ(), nil)
    if width ~= nil and height ~= nil then
        x = x - width / 2
        y = y - height / 2
    end
    return x, y
end

function Coordinates.CenterFeetOfPlayer(player, width, height)
    if player == nil then
        print('TICS error: CenterFeetOfPlayer: nil player parameter')
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
