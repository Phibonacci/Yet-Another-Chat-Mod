local StringParser = require('yacm/utils/StringParser')
local World = require('yacm/utils/world')

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
    local stupidDistance = source:DistTo(target:getX(), target:getY())
    local accurateDistance = math.max(stupidDistance - 1, 0)
    return math.floor(accurateDistance + 0.5)
end

local MessageHasAccessByType = {
    ['whisper']   = function(author, player, args) return true end,
    ['low']       = function(author, player, args) return true end,

    ['say']       = function(author, player, args) return true end,

    ['yell']      = function(author, player, args) return true end,
    ['pm']        = function(author, player, args)
        return args.target ~= nil and args.author ~= nil and
            (player:getUsername():lower() == args.target:lower() or player:getUsername():lower() == args.author:lower())
    end,
    ['faction']   = function(author, player, args)
        local playerFaction = Faction.getPlayerFaction(player)
        local authorFaction = Faction.getPlayerFaction(author)
        return playerFaction ~= nil and authorFaction ~= nil and playerFaction:getName() == authorFaction:getName()
    end,
    ['safehouse'] = function(author, player, args)
        local playerSafeHouse = SafeHouse.hasSafehouse(player)
        local authorSafeHouse = SafeHouse.hasSafehouse(author)
        return playerSafeHouse ~= nil and authorSafeHouse ~= nil and
            playerSafeHouse:getTitle() == authorSafeHouse:getTitle()
    end,
    ['general']   = function(author, player, args) return true end,
    ['admin']     = function(author, player, args)
        return player:getAccessLevel() == 'Admin'
    end,
    ['ooc']       = function(author, player, args) return true end,
}

local function GetColorFromString(colorString)
    local defaultColor = { 255, 0, 255 }
    local rgb = StringParser.hexaToRGB(colorString)
    if rgb == nil then
        print('error: invalid string for Sandbox Variable: "' .. name .. '"')
        return defaultColor
    end
    return rgb
end

local function GetColorSandbox(name)
    local colorString = SandboxVars.YetAnotherChatMod[name .. 'Color']
    return GetColorFromString(colorString)
end

local MessageTypeSettings

local function SetMessageTypeSettings()
    MessageTypeSettings = {
        ['markdown'] = {
            ['italic'] = {
                ['color'] = GetColorSandbox('MarkdownOneAsterisk')
            },
            ['bold'] = {
                ['color'] = GetColorSandbox('MarkdownTwoAsterisks')
            },
        },
        ['whisper'] = {
            ['range'] = SandboxVars.YetAnotherChatMod.WhisperRange,
            ['zombieRange'] = SandboxVars.YetAnotherChatMod.WhisperZombieRange,
            ['enabled'] = SandboxVars.YetAnotherChatMod.WhisperEnabled,
            ['color'] = GetColorSandbox('Whisper'),
            ['radio'] = true,
        },
        ['low'] = {
            ['range'] = SandboxVars.YetAnotherChatMod.LowRange,
            ['zombieRange'] = SandboxVars.YetAnotherChatMod.LowZombieRange,
            ['enabled'] = SandboxVars.YetAnotherChatMod.LowEnabled,
            ['color'] = GetColorSandbox('Low'),
            ['radio'] = true,
        },
        ['say'] = {
            ['range'] = SandboxVars.YetAnotherChatMod.SayRange,
            ['zombieRange'] = SandboxVars.YetAnotherChatMod.SayZombieRange,
            ['enabled'] = SandboxVars.YetAnotherChatMod.SayEnabled,
            ['color'] = GetColorSandbox('Say'),
            ['radio'] = true,
        },
        ['yell'] = {
            ['range'] = SandboxVars.YetAnotherChatMod.YellRange,
            ['zombieRange'] = SandboxVars.YetAnotherChatMod.YellZombieRange,
            ['enabled'] = SandboxVars.YetAnotherChatMod.YellEnabled,
            ['color'] = GetColorSandbox('Yell'),
            ['radio'] = true,
        },
        ['pm'] = {
            ['range'] = -1,
            ['zombieRange'] = -1,
            ['enabled'] = SandboxVars.YetAnotherChatMod.PrivateMessageEnabled,
            ['color'] = GetColorSandbox('PrivateMessage'),
            ['radio'] = false,
        },
        ['faction'] = {
            ['range'] = -1,
            ['zombieRange'] = -1,
            ['enabled'] = SandboxVars.YetAnotherChatMod.FactionMessageEnabled,
            ['color'] = GetColorSandbox('FactionMessage'),
            ['radio'] = false,
        },
        ['safehouse'] = {
            ['range'] = -1,
            ['zombieRange'] = -1,
            ['enabled'] = SandboxVars.YetAnotherChatMod.SafeHouseMessageEnabled,
            ['color'] = GetColorSandbox('SafeHouseMessage'),
            ['radio'] = false,
        },
        ['general'] = {
            ['range'] = -1,
            ['zombieRange'] = -1,
            ['enabled'] = SandboxVars.YetAnotherChatMod.GeneralMessageEnabled,
            ['color'] = GetColorSandbox('GeneralMessage'),
            ['radio'] = false,
        },
        ['admin'] = {
            ['range'] = -1,
            ['zombieRange'] = -1,
            ['enabled'] = SandboxVars.YetAnotherChatMod.AdminMessageEnabled,
            ['color'] = GetColorSandbox('AdminMessage'),
            ['radio'] = false,
        },
        ['ooc'] = {
            ['range'] = SandboxVars.YetAnotherChatMod.OutOfCharacterMessageRange,
            ['zombieRange'] = -1,
            ['enabled'] = SandboxVars.YetAnotherChatMod.OutOfCharacterMessageEnabled,
            ['color'] = GetColorSandbox('OutOfCharacterMessage'),
            ['radio'] = false,
        },
        ['scriptedRadio'] = {
            ['enabled'] = true,
            ['color'] = GetColorFromString(SandboxVars.YetAnotherChatMod.RadioColor),
        },
        ['options'] = {
            ['verb'] = SandboxVars.YetAnotherChatMod.VerbEnabled,
            ['bubble'] = {
                ['timer'] = SandboxVars.YetAnotherChatMod.BubbleTimerInSeconds,
                ['opacity'] = SandboxVars.YetAnotherChatMod.BubbleOpacity,
            },
            ['radio'] = {
                ['chatEnabled'] = SandboxVars.YetAnotherChatMod.RadioChatEnabled,
                ['color'] = GetColorFromString(SandboxVars.YetAnotherChatMod.RadioColor),
            },
        },
    }
end


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
        if connectedPlayer:getUsername():lower() == username:lower() then
            return connectedPlayer
        end
    end
    return nil
end

local function IsAllowed(author, player, args)
    if args.type == nil or MessageTypeSettings[args.type] == nil
        or MessageTypeSettings[args.type]['enabled'] ~= true
        or MessageHasAccessByType[args.type] == nil
    then
        return false
    end
    return MessageHasAccessByType[args.type](author, player, args)
end

local ProcessYacmPackets = {}

local radioSprites = {
    'appliances_com_01_0', -- Premium Technologies Ham Radio
    'appliances_com_01_1',
    'appliances_com_01_2',
    'appliances_com_01_3',
    'appliances_com_01_4',
    'appliances_com_01_5',
    'appliances_com_01_6',
    'appliances_com_01_7',
    'appliances_com_01_8', -- US Army Ham Radio
    'appliances_com_01_9',
    'appliances_com_01_10',
    'appliances_com_01_11',
    'appliances_com_01_12',
    'appliances_com_01_13',
    'appliances_com_01_14',
    'appliances_com_01_15',
    'appliances_com_01_16', -- Toy-R-Mine Walkie Talkie
    'appliances_com_01_17',
    'appliances_com_01_18',
    'appliances_com_01_19',
    'appliances_com_01_24', -- ValueTech Walkie Talkie
    'appliances_com_01_25',
    'appliances_com_01_26',
    'appliances_com_01_27',
    'appliances_com_01_32', -- Premium Technologies Walkie Talkie
    'appliances_com_01_33',
    'appliances_com_01_34',
    'appliances_com_01_35',
    'appliances_com_01_40', -- Tactical Walkie Talkie
    'appliances_com_01_41',
    'appliances_com_01_42',
    'appliances_com_01_43',
    'appliances_com_01_48', -- US Army Walkie Talkie
    'appliances_com_01_49',
    'appliances_com_01_50',
    'appliances_com_01_51',
    'appliances_com_01_56', -- Makeshift Ham Radio
    'appliances_com_01_57',
    'appliances_com_01_58',
    'appliances_com_01_59',
    'appliances_com_01_60',
    'appliances_com_01_61',
    'appliances_com_01_62',
    'appliances_com_01_63',
    'appliances_com_01_64', -- Makeshift Walkie Talkie
    'appliances_com_01_65',
    'appliances_com_01_66',
    'appliances_com_01_67',
}

local function SendRadioPackets(player, args, radioFrequencies)
    local radioMaxRange = 10
    local radios = World.getItemsInRangeByGroup(player, radioMaxRange, 'IsoRadio')
    for _, radio in pairs(radios) do
        local pos = {
            x = radio:getX(),
            y = radio:getY(),
            z = radio:getZ(),
        }
        local radioData = radio:getDeviceData()
        if radioData ~= nil then
            local frequency = radioData:getChannel()
            local turnedOn = radioData:getIsTurnedOn()
            local volume = radioData:getDeviceVolume()
            if volume == nil then
                volume = 0
            end
            volume = math.abs(volume)
            local radioRange = math.abs(volume * radioMaxRange + 0.5)
            local playerDistance = PlayersDistance(player, radio)
            if turnedOn and frequency ~= nil and radioFrequencies[frequency] == true
                and playerDistance <= radioRange
            then
                SendYacmServerCommand(player, 'RadioMessage', {
                    author = args.author,
                    message = args.message,
                    color = args.color,
                    type = args.type,
                    pos = pos,
                    frequency = frequency,
                })
            end
        end
    end
end

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
    local radioEmission = false
    local radioFrequencies = {}
    if MessageTypeSettings[args.type] and MessageTypeSettings[args.type]['radio'] == true
        and packetType == 'ChatMessage' and range > 0
    then
        local items = World.getItemsInRangeByGroup(player, range, 'IsoRadio')
        radioEmission = #items > 0
        for _, item in pairs(items) do
            local radioData = item:getDeviceData()
            if radioData ~= nil then
                local frequency = radioData:getChannel()
                local turnedOn = radioData:getIsTurnedOn()
                if turnedOn and frequency ~= nil then
                    radioFrequencies[frequency] = true
                end
            end
        end
    end
    local connectedPlayers = getOnlinePlayers()
    for i = 0, connectedPlayers:size() - 1 do
        local connectedPlayer = connectedPlayers:get(i)
        if (connectedPlayer:getOnlineID() == player:getOnlineID()
                or range == -1 or PlayersDistance(player, connectedPlayer) <= range + 0.001)
            and IsAllowed(player, connectedPlayer, args)
        then
            if radioEmission then
                SendRadioPackets(connectedPlayer, args, radioFrequencies)
            end
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

ProcessYacmPackets['AskSandboxVars'] = function(player, args)
    SendYacmServerCommand(player, 'SendSandboxVars', MessageTypeSettings)
end

local function OnClientCommand(module, command, player, args)
    if module == 'YACM' and ProcessYacmPackets[command] then
        ProcessYacmPackets[command](player, args)
    end
end

Events.OnClientCommand.Add(OnClientCommand)
Events.OnServerStarted.Add(SetMessageTypeSettings)
