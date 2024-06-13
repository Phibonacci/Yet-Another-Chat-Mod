local function SendYacmServerCommand(player, commandName, args)
    sendServerCommand(player, 'YACM', commandName, args)
end

local function ServerPrint(player, message)
    SendYacmServerCommand(player, 'ServerPrint', { message = message })
end

local function PlayersDistance(source, target)
    return source:DistTo(target:getX(), target:getY())
end

local function GetRangeForMessageType(type)
    print('Message type is: ')
    print(type)
    if type == 'whisper' then
        return SandboxVars.YetAnotherChatMod.WhisperRange
    elseif type == 'low' then
        return SandboxVars.YetAnotherChatMod.LowRange
    elseif type == 'say' then
        return SandboxVars.YetAnotherChatMod.SayRange
    elseif type == 'yell' then
        return SandboxVars.YetAnotherChatMod.YellRange
    elseif type == 'pm' then
        return -1
    elseif type == 'faction' then
        return -1
    elseif type == 'safehouse' then
        return -1
    elseif type == 'general' then
        return -1
    elseif type == 'admin' then
        return -1
    else
        error('unknown message type "' .. type .. '"')
    end
end

function GetConnectedPlayer(username)
    local connectedPlayers = getOnlinePlayers()
    for i = 0, connectedPlayers:size() - 1 do
        local connectedPlayer = connectedPlayers:get(i)
        if connectedPlayer:getUsername() == username then
            return connectedPlayer
        end
    end
    return nil
end

local MessageTypeSettings = {
    ['whisper'] = {
        ['range'] = SandboxVars.YetAnotherChatMod.WhisperRange,
        ['enabled'] = SandboxVars.YetAnotherChatMod.WhisperEnabled,
        ['check'] = function(author, player, args) return true end,
    },
    ['low'] = {
        ['range'] = SandboxVars.YetAnotherChatMod.LowRange,
        ['enabled'] = SandboxVars.YetAnotherChatMod.LowEnabled,
        ['check'] = function(author, player, args) return true end,
    },
    ['say'] = {
        ['range'] = SandboxVars.YetAnotherChatMod.SayRange,
        ['enabled'] = SandboxVars.YetAnotherChatMod.SayEnabled,
        ['check'] = function(author, player, args) return true end,
    },
    ['yell'] = {
        ['range'] = SandboxVars.YetAnotherChatMod.YellRange,
        ['enabled'] = SandboxVars.YetAnotherChatMod.YellEnabled,
        ['check'] = function(author, player, args) return true end,
    },
    ['pm'] = {
        ['range'] = -1,
        ['enabled'] = SandboxVars.YetAnotherChatMod.PrivateMessageEnabled,
        ['check'] = function(author, player, args)
            return args.target ~= nil and args.author ~= nil and
                (player:getUsername() == args.target or player:getUsername() == args.author)
        end,
    },
    ['faction'] = {
        ['range'] = -1,
        ['enabled'] = SandboxVars.YetAnotherChatMod.FactionMessageEnabled,
        ['check'] = function(author, player, args)
            local playerFaction = Faction.getPlayerFaction(player)
            local authorFaction = Faction.getPlayerFaction(author)
            return playerFaction ~= nil and authorFaction ~= nil and playerFaction:getName() == authorFaction:getName()
        end,
    },
    ['safehouse'] = {
        ['range'] = -1,
        ['enabled'] = SandboxVars.YetAnotherChatMod.SafeHouseMessageEnabled,
        ['check'] = function(author, player, args)
            local playerSafeHouse = SafeHouse.hasSafehouse(player)
            local authorSafeHouse = SafeHouse.hasSafehouse(author)
            if playerSafeHouse == nil then
                ServerPrint(player, 'playerSafeHouse is nil')
            else
                ServerPrint(player, 'playerSafeHouse is "' .. playerSafeHouse:getTitle() .. '"')
            end
            if authorSafeHouse == nil then
                ServerPrint(player, 'authorSafeHouse is nil')
            else
                ServerPrint(player, 'authorSafeHouse is "' .. authorSafeHouse:getTitle() .. '"')
            end
            return playerSafeHouse ~= nil and authorSafeHouse ~= nil and
                playerSafeHouse:getTitle() == authorSafeHouse:getTitle()
        end,
    },
    ['general'] = {
        ['range'] = -1,
        ['enabled'] = SandboxVars.YetAnotherChatMod.GeneralMessageEnabled,
        ['check'] = function(author, player, args) return true end,
    },
    ['admin'] = {
        ['range'] = -1,
        ['enabled'] = SandboxVars.YetAnotherChatMod.AdminMessageEnabled,
        ['check'] = function(author, player, args)
            ServerPrint(player, 'CHECK access: ' .. player:getAccessLevel())
            return player:getAccessLevel() == 'Admin'
        end,
    },
}

local function IsAllowed(author, player, args)
    print('is allowed?')
    print(SandboxVars.YetAnotherChatMod.SafeHouseMessageEnabled)
    if args.type == nil or MessageTypeSettings[args.type] == nil
        or MessageTypeSettings[args.type]['enabled'] ~= true
    then
        print('is NOT allowed')
        return false
    end
    return MessageTypeSettings[args.type]['check'](author, player, args)
end

local ProcessYacmPackets = {}

ProcessYacmPackets['ChatMessage'] = function(player, args)
    ServerPrint(player, 'A ChatMessage')
    if args.type == nil then
        return
    end
    if args.type == "faction" then
        if Faction.getPlayerFaction(player) == nil then
            return
        end
    elseif args.type == 'safehouse' then
        if SafeHouse.hasSafehouse(player) == nil then
            return
        end
    elseif args.type == 'pm' then
        if args.target == nil or GetConnectedPlayer(args.target) == nil then
            return
        end
    end
    ServerPrint(player, 'B ChatMessage')
    local range = GetRangeForMessageType(args.type)
    local connectedPlayers = getOnlinePlayers()
    for i = 0, connectedPlayers:size() - 1 do
        local connectedPlayer = connectedPlayers:get(i)
        ServerPrint(player, 'C ChatMessage player: ' .. connectedPlayer:getUsername())
        ServerPrint(player, 'C ChatMessage range: ' .. range)
        local allowed = IsAllowed(player, connectedPlayer, args) and 'true' or 'false'
        ServerPrint(player, 'C ChatMessage allowed: ' .. allowed)
        if (connectedPlayer:getOnlineID() == player:getOnlineID()
                or range == -1 or PlayersDistance(player, connectedPlayer) < range)
            and IsAllowed(player, connectedPlayer, args)
        then
            ServerPrint(player, 'D ChatMessage')
            SendYacmServerCommand(connectedPlayer, 'ChatMessage', args)
        end
    end
end

ProcessYacmPackets['Typing'] = function(player, args)
    if args.type == nil then
        return
    end
    if args.type == "faction" then
        if Faction.getPlayerFaction(player) == nil then
            return
        end
    elseif args.type == 'safehouse' then
        if SafeHouse.hasSafehouse(player) == nil then
            return
        end
    elseif args.type == 'pm' then
        if args.target == nil or GetConnectedPlayer(args.target) == nil then
            return
        end
    end
    local range = GetRangeForMessageType(args.type)
    local connectedPlayers = getOnlinePlayers()
    for i = 0, connectedPlayers:size() - 1 do
        local connectedPlayer = connectedPlayers:get(i)
        if (connectedPlayer:getOnlineID() == player:getOnlineID()
                or range == -1 or PlayersDistance(player, connectedPlayer) < range)
            and IsAllowed(player, connectedPlayer, args)
        then
            SendYacmServerCommand(connectedPlayer, 'Typing', args)
        end
    end
end

local function OnClientCommand(module, command, player, args)
    ServerPrint(player, 'module is ' .. module)
    ServerPrint(player, 'command is ' .. command)
    ServerPrint(player, 'player is ' .. player:getUsername())
    ServerPrint(player, 'args')
    if args == nil then
        ServerPrint(player, '  nil')
    else
        for k, v in pairs(args) do
            ServerPrint(player, '  ["' .. k .. '"] = ' .. v)
        end
    end
    if module == 'YACM' and ProcessYacmPackets[command] then
        ProcessYacmPackets[command](player, args)
    end
end

Events.OnClientCommand.Add(OnClientCommand)
