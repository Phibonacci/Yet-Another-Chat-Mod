local YacmClientSendCommands = {}

function SendYacmClientCommand(commandName, args)
    sendClientCommand('YACM', commandName, args)
end

function YacmClientSendCommands.sendRangeMessage(author, message, type)
    if not isClient() then return end
    SendYacmClientCommand('RangeMessage', {
        author = author,
        message = message,
        type = type
    })
end

return YacmClientSendCommands
