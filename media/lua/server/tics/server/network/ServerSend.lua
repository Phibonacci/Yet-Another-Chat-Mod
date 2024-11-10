local ServerSend = {}

function ServerSend.Command(player, commandName, args)
    sendServerCommand(player, 'TICS', commandName, args)
end

function ServerSend.Print(player, message)
    ServerSend.Command(player, 'ServerPrint', { message = message })
end

function ServerSend.ChatErrorMessage(player, type, message)
    ServerSend.Command(player, 'ChatError', { message = message, type = type })
end

function ServerSend.SquareRadioState(player, turnedOn, mute, power, volume, frequency, x, y, z)
    ServerSend.Command(player, 'RadioSquareState', {
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

function ServerSend.InHandRadioState(player, radioId, turnedOn, mute, power, volume, frequency, x, y, z)
    ServerSend.Command(player, 'RadioInHandState', {
        id = radioId,
        turnedOn = turnedOn,
        mute = mute,
        power = power,
        volume = volume,
        frequency = frequency,
    })
end

function ServerSend.ApprovedAvatar(player, checksum, username, firstName, lastName, data, extension)
    ServerSend.Command(player, 'ApprovedAvatar', {
        username = username,
        firstName = firstName,
        lastName = lastName,
        checksum = checksum,
        data = data,
        extension = extension,
    })
end

function ServerSend.PendingAvatar(player, checksum, username, firstName, lastName, data, extension)
    ServerSend.Command(player, 'PendingAvatar', {
        username = username,
        firstName = firstName,
        lastName = lastName,
        checksum = checksum,
        data = data,
        extension = extension,
    })
end

function ServerSend.AvatarProcessed(player, username, firstName, lastName, checksum)
    ServerSend.Command(player, 'AvatarProcessed', {
        username = username,
        firstName = firstName,
        lastName = lastName,
        checksum = checksum,
    })
end

return ServerSend
