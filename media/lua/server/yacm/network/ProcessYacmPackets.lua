local StringParser = require('yacm/utils/StringParser')
local Character = require('yacm/utils/Character')
local World = require('yacm/utils/World')

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

local function DistanceManhatten(source, target)
    return math.abs(target:getX() - source:getX()) + math.abs(target:getY() - source:getY())
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
            ['hideCallout'] = SandboxVars.YetAnotherChatMod.HideCallout,
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

local function IsInRadioEmittingRange(radioEmitters, receiver)
    if radioEmitters == nil then
        return false
    end
    for _, radioEmitter in pairs(radioEmitters) do
        local radioData = radioEmitter:getDeviceData()
        if radioData ~= nil then
            local transmitRange = radioData:getTransmitRange()
            print('emitter')
            print(radioEmitter)
            print(receiver)
            local distance = DistanceManhatten(radioEmitter, receiver)
            print('transmitRange: ' .. transmitRange .. ', distance: ' .. distance)
            if distance <= transmitRange then
                return true
            end
        end
    end
    return false
end

local function SendRadioPackets(author, player, args, radioFrequencies)
    local radiosByFrequency = {}
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
            print('radio infos')
            print(playerDistance <= radioRange)
            print(IsInRadioEmittingRange(radioFrequencies[frequency], radio))
            if turnedOn and frequency ~= nil and radioFrequencies[frequency] ~= nil
                and playerDistance <= radioRange
                and IsInRadioEmittingRange(radioFrequencies[frequency], radio)
            then
                if radiosByFrequency[frequency] == nil then
                    radiosByFrequency[frequency] = {}
                end
                table.insert(radiosByFrequency[frequency], pos)
            end
        end
    end
    local radio = Character.getHandItemByGroup(player, 'Radio')
    local radioData = radio and radio:getDeviceData() or nil
    if radioData then
        ServerPrint(player, 'target radioData found')
        local frequency = radioData:getChannel()
        if radioData and radioData:getIsTwoWay() and radioData:getIsTurnedOn()
            and frequency ~= nil and radioFrequencies[frequency] ~= nil
            and IsInRadioEmittingRange(radioFrequencies[frequency], radio)
        then
            if radiosByFrequency[frequency] == nil then
                radiosByFrequency[frequency] = {}
            end
            ServerPrint(player, 'radio added to command')
            table.insert(radiosByFrequency[frequency], radio)
        end
    end
    SendYacmServerCommand(player, 'RadioMessage', {
        author = args.author,
        message = args.message,
        color = args.color,
        type = args.type,
        radios = radiosByFrequency,
    })
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
        local radios = World.getItemsInRangeByGroup(player, range, 'IsoRadio')
        for _, radio in pairs(radios) do
            local radioData = radio:getDeviceData()
            if radioData ~= nil then
                local frequency = radioData:getChannel()
                ServerPrint(player, 'radio is muted: ' .. (radioData:getMicIsMuted() and 'true' or 'false'))
                if radioData:getIsTwoWay() and radioData:getIsTurnedOn()
                    and not radioData:getMicIsMuted() and frequency ~= nil
                then
                    if radioFrequencies[frequency] == nil then
                        radioFrequencies[frequency] = {}
                    end
                    table.insert(radioFrequencies[frequency], radio)
                    radioEmission = true
                end
            end
        end
        local radio = Character.getHandItemByGroup(player, 'Radio')
        ServerPrint(player, 'Radio in hand? ' .. (radio ~= nil and 'true' or 'false'))
        local isoRadio = Character.getHandItemByGroup(player, 'IsoRadio')
        ServerPrint(player, 'IsoRadio in hand? ' .. (isoRadio ~= nil and 'true' or 'false'))
        local radioData = radio and radio:getDeviceData() or nil
        if radioData then
            local frequency = radioData:getChannel()
            if radioData and radioData:getIsTwoWay() and radioData:getIsTurnedOn()
                and not radioData:getMicIsMuted() and frequency ~= nil
            then
                if radioFrequencies[frequency] == nil then
                    radioFrequencies[frequency] = {}
                end
                ServerPrint(player, 'Radio found on author')
                table.insert(radioFrequencies[frequency], radio)
                radioEmission = true
            end
        end
    end
    local connectedPlayers = getOnlinePlayers()
    for i = 0, connectedPlayers:size() - 1 do
        local connectedPlayer = connectedPlayers:get(i)
        if IsAllowed(player, connectedPlayer, args)
        then
            ServerPrint(player, 'found target player #' .. i)
            if (connectedPlayer:getOnlineID() == player:getOnlineID()
                    or range == -1 or PlayersDistance(player, connectedPlayer) < range + 0.001)
            then
                SendYacmServerCommand(connectedPlayer, packetType, args)
            end
            if radioEmission then
                SendRadioPackets(player, connectedPlayer, args, radioFrequencies)
            end
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
