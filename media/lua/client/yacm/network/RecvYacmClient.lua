local YacmClientRecvCommands = {}

YacmClientRecvCommands['RangeMessage'] = function(args)
    ISChat.addCustomLineInChat(args)
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
