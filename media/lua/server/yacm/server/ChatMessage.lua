local Character = require('yacm/shared/utils/Character')
local SendServer = require('yacm/server/network/SendServer')
local StringParser = require('yacm/shared/utils/StringParser')
local World = require('yacm/shared/utils/World')

local ChatMessage = {}

local function PlayersDistance(source, target)
    local stupidDistance = source:DistTo(target:getX(), target:getY())
    local accurateDistance = math.max(stupidDistance - 1, 0)
    return math.floor(accurateDistance + 0.5)
end

local function DistanceManhatten(source, target)
    return math.abs(target:getX() - source:getX()) + math.abs(target:getY() - source:getY())
end

local AuthorHasAccessByType = {
    ['whisper']   = function(author, args, sendError) return true end,
    ['low']       = function(author, args, sendError) return true end,

    ['say']       = function(author, args, sendError) return true end,

    ['yell']      = function(author, args, sendError) return true end,
    ['pm']        = function(author, args, sendError)
        if args.target == nil or World.getPlayerByUsername(args.target) == nil then
            if args.target ~= nil then
                if sendError then
                    SendServer.ChatErrorMessage(author, args.type, 'unknown player "' .. args.target .. '".')
                end
            else
                print('yacm error: YACM: Received a private message from "' ..
                    author:getUsername() .. '" without a contact name')
            end
            return false
        end
        return true
    end,
    ['faction']   = function(author, args, sendError)
        local hasFaction = Faction.getPlayerFaction(author) ~= nil
        if not hasFaction and sendError then
            SendServer.ChatErrorMessage(author, args.type, 'you are not part of a faction.')
        end
        return hasFaction
    end,
    ['safehouse'] = function(author, args, sendError)
        local hasSafeHouse = SafeHouse.hasSafehouse(author) ~= nil
        if not hasSafeHouse and sendError then
            SendServer.ChatErrorMessage(author, args.type, 'you are not part of a safe house.')
        end
        return hasSafeHouse
    end,
    ['general']   = function(author, args, sendError) return true end,
    ['admin']     = function(author, args, sendError)
        return author:getAccessLevel() == 'Admin'
    end,
    ['ooc']       = function(author, args, sendError) return true end,
}

local ListenerHasAccessByType = {
    ['whisper']   = function(author, player, args) return true end,
    ['low']       = function(author, player, args) return true end,

    ['say']       = function(author, player, args) return true end,

    ['yell']      = function(author, player, args) return true end,
    ['pm']        = function(author, player, args)
        return args.target ~= nil and args.author ~= nil and
            (player:getUsername():lower() == args.target:lower() or player:getUsername():lower() == args.author:lower())
    end,
    ['faction']   = function(author, player, args)
        local authorFaction = Faction.getPlayerFaction(author)
        local playerFaction = Faction.getPlayerFaction(player)
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
    local rgb = StringParser.hexaStringToRGB(colorString)
    if rgb == nil then
        print('yacm error: invalid color string: "' .. colorString .. '"')
        return defaultColor
    end
    return rgb
end

local function GetColorSandbox(name)
    local colorString = SandboxVars.YetAnotherChatMod[name .. 'Color']
    return GetColorFromString(colorString)
end

ChatMessage.MessageTypeSettings = nil

local function SetMessageTypeSettings()
    ChatMessage.MessageTypeSettings = {
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
            ['aliveOnly'] = true,
        },
        ['low'] = {
            ['range'] = SandboxVars.YetAnotherChatMod.LowRange,
            ['zombieRange'] = SandboxVars.YetAnotherChatMod.LowZombieRange,
            ['enabled'] = SandboxVars.YetAnotherChatMod.LowEnabled,
            ['color'] = GetColorSandbox('Low'),
            ['radio'] = true,
            ['aliveOnly'] = true,
        },
        ['say'] = {
            ['range'] = SandboxVars.YetAnotherChatMod.SayRange,
            ['zombieRange'] = SandboxVars.YetAnotherChatMod.SayZombieRange,
            ['enabled'] = SandboxVars.YetAnotherChatMod.SayEnabled,
            ['color'] = GetColorSandbox('Say'),
            ['radio'] = true,
            ['aliveOnly'] = true,
        },
        ['yell'] = {
            ['range'] = SandboxVars.YetAnotherChatMod.YellRange,
            ['zombieRange'] = SandboxVars.YetAnotherChatMod.YellZombieRange,
            ['enabled'] = SandboxVars.YetAnotherChatMod.YellEnabled,
            ['color'] = GetColorSandbox('Yell'),
            ['radio'] = true,
            ['aliveOnly'] = true,
        },
        ['pm'] = {
            ['range'] = -1,
            ['zombieRange'] = -1,
            ['enabled'] = SandboxVars.YetAnotherChatMod.PrivateMessageEnabled,
            ['color'] = GetColorSandbox('PrivateMessage'),
            ['radio'] = false,
            ['aliveOnly'] = true,
        },
        ['faction'] = {
            ['range'] = -1,
            ['zombieRange'] = -1,
            ['enabled'] = SandboxVars.YetAnotherChatMod.FactionMessageEnabled,
            ['color'] = GetColorSandbox('FactionMessage'),
            ['radio'] = false,
            ['aliveOnly'] = true,
        },
        ['safehouse'] = {
            ['range'] = -1,
            ['zombieRange'] = -1,
            ['enabled'] = SandboxVars.YetAnotherChatMod.SafeHouseMessageEnabled,
            ['color'] = GetColorSandbox('SafeHouseMessage'),
            ['radio'] = false,
            ['aliveOnly'] = true,
        },
        ['general'] = {
            ['range'] = -1,
            ['zombieRange'] = -1,
            ['enabled'] = SandboxVars.YetAnotherChatMod.GeneralMessageEnabled,
            ['color'] = GetColorSandbox('GeneralMessage'),
            ['radio'] = false,
            ['aliveOnly'] = true,
            ['discord'] = SandboxVars.YetAnotherChatMod.GeneralDiscordEnabled,
        },
        ['admin'] = {
            ['range'] = -1,
            ['zombieRange'] = -1,
            ['enabled'] = SandboxVars.YetAnotherChatMod.AdminMessageEnabled,
            ['color'] = GetColorSandbox('AdminMessage'),
            ['radio'] = false,
            ['aliveOnly'] = false,
        },
        ['ooc'] = {
            ['range'] = SandboxVars.YetAnotherChatMod.OutOfCharacterMessageRange,
            ['zombieRange'] = -1,
            ['enabled'] = SandboxVars.YetAnotherChatMod.OutOfCharacterMessageEnabled,
            ['color'] = GetColorSandbox('OutOfCharacterMessage'),
            ['radio'] = false,
        },
        ['server'] = {
            ['color'] = { 255, 86, 64 },
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
                ['discord'] = SandboxVars.YetAnotherChatMod.RadioDiscordEnabled,
                ['frequency'] = SandboxVars.YetAnotherChatMod.RadioDiscordFrequency,
                ['color'] = GetColorFromString(SandboxVars.YetAnotherChatMod.RadioColor),
            },
            ['hideCallout'] = SandboxVars.YetAnotherChatMod.HideCallout,
        },
    }
end

local function GetRangeForMessageType(type)
    local messageSettings = ChatMessage.MessageTypeSettings[type]
    if messageSettings ~= nil then
        return messageSettings['range']
    end
    error('unknown message type "' .. type .. '"')
    return nil
end

local function IsAllowedToTalk(author, args, sendError)
    if args.type == nil then
        print('yacm error: args.type is null')
        return false
    end
    if ChatMessage.MessageTypeSettings[args.type] == nil then
        print('yacm error: ChatMessage.MessageTypeSettings of ' .. args.type .. ' is null')
        return false
    end
    if AuthorHasAccessByType[args.type] == nil then
        print('yacm error: AuthorHasAccessByType has no method for ' .. args.type)
        return false
    end
    return ChatMessage.MessageTypeSettings[args.type]['enabled'] == true
        and (not ChatMessage.MessageTypeSettings[args.type]['aliveOnly'] or author:getBodyDamage():getHealth() > 0)
        and AuthorHasAccessByType[args.type](author, args, sendError)
end

local function IsAllowedToListen(author, player, args)
    if ListenerHasAccessByType[args.type] == nil then
        print('yacm error: IsAllowedToListen: MessageHasAccessByType has no method for ' .. args.type)
        return false
    end
    return ListenerHasAccessByType[args.type](author, player, args)
end

local function IsInRadioEmittingRange(radioEmitters, receiver)
    if radioEmitters == nil then
        return false
    end
    for _, radioEmitter in pairs(radioEmitters) do
        local radioData = radioEmitter:getDeviceData()
        if radioData ~= nil then
            local transmitRange = radioData:getTransmitRange()
            local distance = DistanceManhatten(radioEmitter, receiver)
            if distance <= transmitRange then
                return true
            end
        end
    end
    return false
end

local function GetSquaresRadios(player, args, radioFrequencies, range)
    local radiosByFrequency = {}
    local radioMaxRange = range
    local radios = World.getItemsInRangeByGroup(player, radioMaxRange, 'IsoRadio')
    local found = false
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
            -- TODO find a way to use volume in a non confusing way
            -- local radioRange = math.abs(volume * radioMaxRange + 0.5)
            -- local playerDistance = PlayersDistance(player, radio)
            if turnedOn and frequency ~= nil and radioFrequencies[frequency] ~= nil
                -- and playerDistance <= radioRange
                and IsInRadioEmittingRange(radioFrequencies[frequency], radio)
            then
                if radiosByFrequency[frequency] == nil then
                    radiosByFrequency[frequency] = {}
                end
                table.insert(radiosByFrequency[frequency], pos)
                found = true
            end
        end
    end
    return radiosByFrequency, found
end

local function GetPlayerRadios(player, args, radioFrequencies, range)
    local radiosByFrequency = {}
    local radio = Character.getHandItemByGroup(player, 'Radio')
    local found = false
    if radio == nil then
        return radiosByFrequency
    end
    local radioData = radio and radio:getDeviceData() or nil
    if radioData then
        local frequency = radioData:getChannel()
        if radioData:getIsTurnedOn()
            and frequency ~= nil and radioFrequencies[frequency] ~= nil
            and IsInRadioEmittingRange(radioFrequencies[frequency], radio)
        then
            if radiosByFrequency[frequency] == nil then
                radiosByFrequency[frequency] = {}
            end
            table.insert(radiosByFrequency[frequency], player:getUsername())
            found = true
        end
    end
    return radiosByFrequency, found
end

local function GetVehiclesRadios(player, args, radioFrequencies, range)
    local vehiclesByFrequency = {}
    local radioMaxRange = range
    local vehicles = World.getVehiclesInRange(player, radioMaxRange)
    local found = false
    for _, vehicle in pairs(vehicles) do
        local radio = vehicle:getPartById('Radio')
        if radio ~= nil then
            local radioData = radio:getDeviceData()
            if radioData ~= nil then
                local frequency = radioData:getChannel()
                if radioData:getIsTurnedOn()
                    and frequency ~= nil and radioFrequencies[frequency] ~= nil
                    and IsInRadioEmittingRange(radioFrequencies[frequency], radio)
                then
                    if vehiclesByFrequency[frequency] == nil then
                        vehiclesByFrequency[frequency] = {}
                    end
                    table.insert(vehiclesByFrequency[frequency], vehicle:getKeyId())
                    found = true
                end
            end
        end
    end
    return vehiclesByFrequency, found
end

local function SendRadioPackets(author, player, args, sourceRadioByFrequencies)
    if ChatMessage.MessageTypeSettings['say'] == nil then -- the radio volume range is always set to 'say'
        print('yacm error: SendRadioPackets: no setting for type "say"')
        return
    end
    if ChatMessage.MessageTypeSettings['say']['range'] == nil or ChatMessage.MessageTypeSettings[args.type]['range'] <= -1 then
        print('yacm error: SendRadioPackets: no range for type "say"')
        return
    end
    local range = ChatMessage.MessageTypeSettings['say']['range']
    local squaresRadios, squaresRadiosFound = GetSquaresRadios(player, args, sourceRadioByFrequencies, range)
    local playersRadios, playersRadiosFound = GetPlayerRadios(player, args, sourceRadioByFrequencies, range)
    local vehiclesRadios, vehiclesRadiosFound = GetVehiclesRadios(player, args, sourceRadioByFrequencies, range)

    if not squaresRadiosFound and not playersRadiosFound and not vehiclesRadiosFound then
        return
    end

    local targetRadiosByFrequencies = {}
    for frequency, _ in pairs(sourceRadioByFrequencies) do
        targetRadiosByFrequencies[frequency] = {
            squares = squaresRadios[frequency] or {},
            players = playersRadios[frequency] or {},
            vehicles = vehiclesRadios[frequency] or {},
        }
    end

    SendServer.Command(player, 'RadioMessage', {
        author = args.author,
        message = args.message,
        color = args.color,
        type = args.type,
        radios = targetRadiosByFrequencies,
    })
end

local function GetEmittingRadios(player, packetType, messageType, range)
    local radioEmission = false
    local radioFrequencies = {}
    if ChatMessage.MessageTypeSettings[messageType] and ChatMessage.MessageTypeSettings[messageType]['radio'] == true
        and packetType == 'ChatMessage' and range > 0
    then
        local radios = World.getItemsInRangeByGroup(player, range, 'IsoRadio')
        for _, radio in pairs(radios) do
            local radioData = radio:getDeviceData()
            if radioData ~= nil then
                local frequency = radioData:getChannel()
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
        local radioData = radio and radio:getDeviceData() or nil
        if radioData then
            local frequency = radioData:getChannel()
            if radioData and radioData:getIsTwoWay() and radioData:getIsTurnedOn()
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
    return radioEmission, radioFrequencies
end

local function SendRadioEmittingPackets(player, args, radioFrequencies)
    for frequency, _ in pairs(radioFrequencies) do
        if ChatMessage.MessageTypeSettings and ChatMessage.MessageTypeSettings['options']['radio']['discord']
            and frequency == ChatMessage.MessageTypeSettings['options']['radio']['frequency']
        then
            SendServer.Command(player, 'DiscordMessage', {
                message = args.message,
            })
        end
        SendServer.Command(player, 'RadioEmittingMessage', {
            type = args.type,
            author = args.author,
            message = args.message,
            color = args.color,
            frequency = frequency,
        })
    end
end

function ChatMessage.ProcessMessage(player, args, packetType, sendError)
    if args.type == nil then
        print('yacm error: Received a message from "' .. player:getUsername() .. '" with no type')
        return
    end

    if AuthorHasAccessByType[args.type] == nil then
        print('yacm error: AuthorHasAccessByType has not method for type ' .. args.type)
        return
    end

    if not IsAllowedToTalk(player, args, sendError) then
        return
    end

    if args.type == 'general' and
        ChatMessage.MessageTypeSettings and ChatMessage.MessageTypeSettings['general']['discord']
    then
        SendServer.Command(player, 'DiscordMessage', {
            message = args.message,
        })
    end

    local range = GetRangeForMessageType(args.type)
    if range == nil then
        error('yacm error: No range for message type "' .. args.type .. '".')
        return
    end
    local radioEmission, radioFrequencies = GetEmittingRadios(player, packetType, args['type'], range)
    SendRadioEmittingPackets(player, args, radioFrequencies)
    local connectedPlayers = getOnlinePlayers()
    for i = 0, connectedPlayers:size() - 1 do
        local connectedPlayer = connectedPlayers:get(i)
        if IsAllowedToListen(player, connectedPlayer, args)
        then
            if connectedPlayer:getOnlineID() == player:getOnlineID()
                or range == -1 or PlayersDistance(player, connectedPlayer) < range + 0.001
                or Character.areInSameVehicle(player, connectedPlayer)
            then
                SendServer.Command(connectedPlayer, packetType, args)
            end
            if radioEmission then
                SendRadioPackets(player, connectedPlayer, args, radioFrequencies)
            end
        end
    end
end

Events.OnServerStarted.Add(SetMessageTypeSettings)

return ChatMessage
