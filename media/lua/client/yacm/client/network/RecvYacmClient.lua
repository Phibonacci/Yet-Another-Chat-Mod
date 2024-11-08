local AvatarManager = require('yacm/client/AvatarManager')
local Radio = require('yacm/client/Radio')

local YacmClientRecvCommands = {}

YacmClientRecvCommands['ChatMessage'] = function(args)
    ISChat.onMessagePacket(args['type'], args['author'], args['characterName'],
        args['message'], args['color'], args['hideInChat'],
        args['target'], false, args['pitch'], args['disableVerb'])
end

YacmClientRecvCommands['RadioMessage'] = function(args)
    ISChat.onRadioPacket(
        args['type'], args['author'], args['characterName'], args['message'], args['color'],
        args['radios'], args['pitch'], args['disableVerb'])
end

YacmClientRecvCommands['RadioEmittingMessage'] = function(args)
    ISChat.onRadioEmittingPacket(
        args['type'], args['author'], args['characterName'], args['message'], args['color'],
        args['frequency'], args['disableVerb'])
end

YacmClientRecvCommands['DiscordMessage'] = function(args)
    ISChat.onDiscordPacket(args['message'])
end

YacmClientRecvCommands['Typing'] = function(args)
    ISChat.onTypingPacket(args['author'], args['type'])
end

YacmClientRecvCommands['ChatError'] = function(args)
    ISChat.onChatErrorPacket(args['type'], args['message'])
end

YacmClientRecvCommands['ServerPrint'] = function(args)
    print('Server: ' .. args.message)
end

YacmClientRecvCommands['SendSandboxVars'] = function(args)
    ISChat.onRecvSandboxVars(args)
end

YacmClientRecvCommands['RadioSquareState'] = function(args)
    Radio.SyncSquare(
        args.turnedOn, args.mute, args.power, args.volume,
        args.frequency, args.x, args.y, args.z)
end

YacmClientRecvCommands['RadioInHandState'] = function(args)
    Radio.SyncInHand(
        args.id, args.turnedOn, args.mute, args.power, args.volume,
        args.frequency)
end

YacmClientRecvCommands['ApprovedAvatar'] = function(args)
    local username  = args['username']
    local firstName = args['firstName']
    local lastName  = args['lastName']
    local extension = args['extension']
    local checksum  = args['checksum']
    local data      = args['data']

    if type(username) ~= 'string' then
        print('yacm error: ApprovedAvatar packet does not contain a valid "username"')
        return
    end
    if type(firstName) ~= 'string' then
        print('yacm error: ApprovedAvatar packet does not contain a valid "firstName"')
        return
    end
    if type(lastName) ~= 'string' then
        print('yacm error: ApprovedAvatar packet does not contain a valid "lastName"')
        return
    end
    if type(extension) ~= 'string' then
        print('yacm error: ApprovedAvatar packet does not contain a valid "extension"')
        return
    end
    if type(checksum) ~= 'number' then
        print('yacm error: ApprovedAvatar packet does not contain a valid "checksum"')
        return
    end
    if type(data) ~= 'table' then
        print('yacm error: ApprovedAvatar packet does not contain a valid "data"')
        return
    end

    AvatarManager:saveApprovedAvatar(username, firstName, lastName, extension, checksum, data)
end

YacmClientRecvCommands['PendingAvatar'] = function(args)
    local username  = args['username']
    local firstName = args['firstName']
    local lastName  = args['lastName']
    local extension = args['extension']
    local checksum  = args['checksum']
    local data      = args['data']

    if type(username) ~= 'string' then
        print('yacm error: PendingAvatar packet does not contain a valid "username"')
        return
    end
    if type(firstName) ~= 'string' then
        print('yacm error: PendingAvatar packet does not contain a valid "firstName"')
        return
    end
    if type(lastName) ~= 'string' then
        print('yacm error: PendingAvatar packet does not contain a valid "lastName"')
        return
    end
    if type(extension) ~= 'string' then
        print('yacm error: PendingAvatar packet does not contain a valid "extension"')
        return
    end
    if type(checksum) ~= 'number' then
        print('yacm error: PendingAvatar packet does not contain a valid "checksum"')
        return
    end
    if type(data) ~= 'table' then
        print('yacm error: PendingAvatar packet does not contain a valid "data"')
        return
    end

    AvatarManager:savePendingAvatar(username, firstName, lastName, extension, checksum, data)
end

YacmClientRecvCommands['AvatarProcessed'] = function(args)
    local username  = args['username']
    local firstName = args['firstName']
    local lastName  = args['lastName']
    local checksum  = args['checksum']

    if type(username) ~= 'string' then
        print('yacm error: PendingAvatar packet does not contain a valid "username"')
        return
    end
    if type(firstName) ~= 'string' then
        print('yacm error: PendingAvatar packet does not contain a valid "firstName"')
        return
    end
    if type(lastName) ~= 'string' then
        print('yacm error: PendingAvatar packet does not contain a valid "lastName"')
        return
    end
    if type(checksum) ~= 'number' then
        print('yacm error: PendingAvatar packet does not contain a valid "checksum"')
        return
    end
    AvatarManager:removeAvatarPending(username, firstName, lastName, checksum)
end

function OnServerCommand(module, command, args)
    if module == 'YACM' and YacmClientRecvCommands[command] then
        YacmClientRecvCommands[command](args)
    end
end

Events.OnServerCommand.Add(OnServerCommand)

return YacmClientRecvCommands
