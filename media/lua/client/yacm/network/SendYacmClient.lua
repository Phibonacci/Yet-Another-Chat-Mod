local YacmClientSendCommands = {}

function SendYacmClientCommand(commandName, args)
    sendClientCommand('YACM', commandName, args)
end

function YacmClientSendCommands.sendChatMessage(message, playerColor, type)
    if not isClient() then return end
    SendYacmClientCommand('ChatMessage', {
        author = getPlayer():getUsername(),
        message = message,
        type = type,
        color = playerColor,
    })
end

function YacmClientSendCommands.sendPrivateMessage(message, playerColor, target)
    if not isClient() then return end
    SendYacmClientCommand('ChatMessage', {
        author = getPlayer():getUsername(),
        message = message,
        type = 'pm',
        target = target,
        color = playerColor,
    })
end

function YacmClientSendCommands.sendTyping(author, type)
    if not isClient() then return end
    SendYacmClientCommand('Typing', {
        author = author,
        type = type,
    })
end

function YacmClientSendCommands.sendAskSandboxVars()
    if not isClient() then return end
    SendYacmClientCommand('AskSandboxVars', {})
end

return YacmClientSendCommands
