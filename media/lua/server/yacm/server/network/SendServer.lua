local SendServer = {}

function SendServer.Command(player, commandName, args)
    sendServerCommand(player, 'YACM', commandName, args)
end

function SendServer.Print(player, message)
    SendServer.Command(player, 'ServerPrint', { message = message })
end

function SendServer.ChatErrorMessage(player, type, message)
    SendServer.Command(player, 'ChatError', { message = message, type = type })
end

function SendServer.SquareRadioState(player, turnedOn, mute, power, volume, frequency, x, y, z)
    SendServer.Command(player, 'RadioSquareState', {
        turnedOn = turnedOn,
        mute = mute,
        power = power,
        volume = volume,
        frequency = frequency,
        x = x,
        y = y,
        z = z,
    })
end

function SendServer.InHandRadioState(player, radioId, turnedOn, mute, power, volume, frequency, x, y, z)
    SendServer.Command(player, 'RadioInHandState', {
        id = radioId,
        turnedOn = turnedOn,
        mute = mute,
        power = power,
        volume = volume,
        frequency = frequency,
    })
end

return SendServer
