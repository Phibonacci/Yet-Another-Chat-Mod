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

function SendServer.ApprovedAvatar(player, checksum, username, firstName, lastName, data, extension)
    SendServer.Command(player, 'ApprovedAvatar', {
        username = username,
        firstName = firstName,
        lastName = lastName,
        checksum = checksum,
        data = data,
        extension = extension,
    })
end

function SendServer.PendingAvatar(player, checksum, username, firstName, lastName, data, extension)
    SendServer.Command(player, 'PendingAvatar', {
        username = username,
        firstName = firstName,
        lastName = lastName,
        checksum = checksum,
        data = data,
        extension = extension,
    })
end

function SendServer.AvatarProcessed(player, username, firstName, lastName, checksum)
    SendServer.Command(player, 'AvatarProcessed', {
        username = username,
        firstName = firstName,
        lastName = lastName,
        checksum = checksum,
    })
end

return SendServer
