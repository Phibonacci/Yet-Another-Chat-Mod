local ProcessYacmPackets = {}

function SendYacmServerCommand(player, commandName, args)
    sendServerCommand(player, 'YACM', commandName, args)
end

function ServerPrint(player, message)
    SendYacmServerCommand(player, 'ServerPrint', { message = message })
end

function PlayersDistance(source, target)
    return source:DistTo(target:getX(), target:getY())
end

function ProcessRangeMessage(player, args)
    if type == nil then
        return
    end
    local range = GetRangeForMessageType(args.type)
    local connectedPlayers = getOnlinePlayers()
    for i = 0, connectedPlayers:size() - 1 do
        local connectedPlayer = connectedPlayers:get(i)
        if connectedPlayer:getOnlineID() == player:getOnlineID()
            or PlayersDistance(player, connectedPlayer) < range then
            SendYacmServerCommand(connectedPlayer, 'RangeMessage', args)
        end
    end
end

function GetRangeForMessageType(type)
    if type == 'whisper' then
        return SandboxVars.YetAnotherChatMod.WhisperRange
    elseif type == 'low' then
        return SandboxVars.YetAnotherChatMod.LowRange
    elseif type == 'say' then
        return SandboxVars.YetAnotherChatMod.SayRange
    elseif type == 'yell' then
        return SandboxVars.YetAnotherChatMod.YellRange
    else
        error('unknown message type "' .. type .. '"')
    end
end

ProcessYacmPackets['RangeMessage'] = function(player, args)
    local range = SandboxVars.YetAnotherChatMod.YellRange
    ProcessRangeMessage(player, args)
end

local function OnClientCommand(module, command, player, args)
    ServerPrint(player, 'module is ' .. module)
    if module == 'YACM' and ProcessYacmPackets[command] then
        ProcessYacmPackets[command](player, args)
    end
end

Events.OnClientCommand.Add(OnClientCommand)

return ProcessYacmPackets
