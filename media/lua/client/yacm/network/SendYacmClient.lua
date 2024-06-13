local YacmClientSendCommands = {}

function SendYacmClientCommand(commandName, args)
    sendClientCommand('YACM', commandName, args)
end

function YacmClientSendCommands.sendChatMessage(message, type)
    if not isClient() then return end
    SendYacmClientCommand('ChatMessage', {
        author = getPlayer():getUsername(),
        message = message,
        type = type,
    })
end

function YacmClientSendCommands.sendPrivateMessage(message, target)
    if not isClient() then return end
    SendYacmClientCommand('ChatMessage', {
        author = getPlayer():getUsername(),
        message = message,
        type = 'pm',
        target = target,
    })
end

function YacmClientSendCommands.sendTyping(author, type)
    if not isClient() then return end
    SendYacmClientCommand('Typing', {
        author = author,
        type = type
    })
end

return YacmClientSendCommands
