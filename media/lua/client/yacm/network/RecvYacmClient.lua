local YacmClientRecvCommands = {}

YacmClientRecvCommands['ChatMessage'] = function(args)
    ISChat.onMessagePacket(args)
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

function OnServerCommand(module, command, args)
    if module == 'YACM' and YacmClientRecvCommands[command] then
        YacmClientRecvCommands[command](args)
    end
end

Events.OnServerCommand.Add(OnServerCommand)

return YacmClientRecvCommands
