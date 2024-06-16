local function SendYacmServerCommand(player, commandName, args)
    sendServerCommand(player, 'YACM', commandName, args)
end

local function ServerPrint(player, message)
    SendYacmServerCommand(player, 'ServerPrint', { message = message })
end

local function SendErrorMessage(player, type, message)
    SendYacmServerCommand(player, 'ChatError', { message = message, type = type })
end

local function PlayersDistance(source, target)
    return source:DistTo(target:getX(), target:getY())
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
            return player:getAccessLevel() == 'Admin'
        end,
    },
    ['ooc'] = {
        ['range'] = SandboxVars.YetAnotherChatMod.OutOfCharacterMessageRange,
        ['enabled'] = SandboxVars.YetAnotherChatMod.OutOfCharacterMessageEnabled,
        ['check'] = function(author, player, args) return true end,
    },
}

local function GetRangeForMessageType(type)
    local messageSettings = MessageTypeSettings[type]
    if messageSettings ~= nil then
        return messageSettings['range']
    end
    error('unknown message type "' .. type .. '"')
    return nil
end

local function GetConnectedPlayer(username)
    local connectedPlayers = getOnlinePlayers()
    for i = 0, connectedPlayers:size() - 1 do
        local connectedPlayer = connectedPlayers:get(i)
        if connectedPlayer:getUsername() == username then
            return connectedPlayer
        end
    end
    return nil
end

local function IsAllowed(author, player, args)
    if args.type == nil or MessageTypeSettings[args.type] == nil
        or MessageTypeSettings[args.type]['enabled'] ~= true
    then
        return false
    end
    return MessageTypeSettings[args.type]['check'](author, player, args)
end

local ProcessYacmPackets = {}

local function ProcessYacmPacket(player, args, packetType, sendError)
    if args.type == nil then
        error('error: YACM: Received a message from "' .. player:getUsername() .. '" with no type')
        return
    end
    if args.type == "faction" then
        if Faction.getPlayerFaction(player) == nil then
            if sendError then
                SendErrorMessage(player, args.type, 'you are not part of a faction.')
            end
            return
        end
    elseif args.type == 'safehouse' then
        if SafeHouse.hasSafehouse(player) == nil then
            if sendError then
                SendErrorMessage(player, args.type, 'you are not part of a safe house.')
            end
            return
        end
    elseif args.type == 'pm' then
        if args.target == nil or GetConnectedPlayer(args.target) == nil then
            if args.target ~= nil then
                if sendError then
                    SendErrorMessage(player, args.type, 'unknown player "' .. args.target .. '".')
                end
            else
                error('error: YACM: Received a private message from "' .. player:getUsername() .. '" without a contact.')
            end
            return
        end
    end
    local range = GetRangeForMessageType(args.type)
    if range == nil then
        error('error: YACM: No range for message type "' .. args.type .. '".')
        return
    end
    local connectedPlayers = getOnlinePlayers()
    for i = 0, connectedPlayers:size() - 1 do
        local connectedPlayer = connectedPlayers:get(i)
        if (connectedPlayer:getOnlineID() == player:getOnlineID()
                or range == -1 or PlayersDistance(player, connectedPlayer) < range)
            and IsAllowed(player, connectedPlayer, args)
        then
            SendYacmServerCommand(connectedPlayer, packetType, args)
        end
    end
end

ProcessYacmPackets['ChatMessage'] = function(player, args)
    ProcessYacmPacket(player, args, 'ChatMessage', true)
end

ProcessYacmPackets['Typing'] = function(player, args)
    ProcessYacmPacket(player, args, 'Typing', false)
end

local function OnClientCommand(module, command, player, args)
    if module == 'YACM' and ProcessYacmPackets[command] then
        ProcessYacmPackets[command](player, args)
    end
end

Events.OnClientCommand.Add(OnClientCommand)
